extends RefCounted
class_name CookingCombatService

const STARTING_LIFE := 20
const OPENING_HAND := 5
const START_TURN_HAND_FLOOR := 2
const PREP_SLOTS := 3
const PLATED_SLOTS := 2
const EXPERT_LOOKAHEAD_DEPTH := 2
const EXPERT_MIN_PLAY_GAIN := 1.5
const AI_DECK_RESERVE := 3
const AI_PERSONALITIES := ["pressure", "defensive", "value"]
const AI_POLICY_PRODUCTION := "production"
const AI_POLICY_FACE_RACE := "face_race"

var cards_by_id: Dictionary = {}
var decks: Dictionary = {}
var rng := RandomNumberGenerator.new()


func load_content(path: String = "res://data/cards.json") -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	setup_content(parsed.get("cards", []), parsed.get("decks", {}))
	return true


func setup_content(card_list: Array, deck_data: Dictionary) -> void:
	cards_by_id.clear()
	for card_data in card_list:
		var card_id := String(card_data.get("id", ""))
		if card_id != "":
			cards_by_id[card_id] = card_data.duplicate(true)
	cards_by_id["token_fresh_ingredient"] = {
		"id": "token_fresh_ingredient",
		"name": "Fresh Ingredient Token",
		"card_type": "ingredient",
		"archetype": "fresh",
		"ingredient_types": ["fresh"],
		"attack": 1,
		"health": 1,
		"is_token": true,
		"text": "Token — disappears when it leaves play."
	}
	decks = deck_data.duplicate(true)


func has_playable_content() -> bool:
	return not cards_by_id.is_empty() and not decks.is_empty()


func available_deck_ids() -> Array[String]:
	var result: Array[String] = []
	for deck_id in decks.keys():
		result.append(String(deck_id))
	return result


func card(card_id: String) -> Dictionary:
	return cards_by_id.get(card_id, {})


func deck_name(deck_id: String) -> String:
	return String(decks.get(deck_id, {}).get("name", deck_id if deck_id != "" else "Awaiting Deck"))


func start_game(player_deck_id: String = "", opponent_deck_id: String = "", seed: int = 1, first_side: String = "player", defer_opponent_turn: bool = false, ai_difficulty: String = "easy") -> Dictionary:
	rng.seed = seed
	var deck_ids := available_deck_ids()
	if player_deck_id == "" and not deck_ids.is_empty():
		player_deck_id = deck_ids[0]
	if opponent_deck_id == "" and not deck_ids.is_empty():
		opponent_deck_id = deck_ids[1] if deck_ids.size() > 1 else deck_ids[0]
	var player_combatant := _make_combatant(player_deck_id)
	var opponent_combatant := _make_combatant(opponent_deck_id)
	var state := {
		"turn": 1,
		"phase": "player_main" if has_playable_content() else "awaiting_cards",
		"first_player": first_side,
		"ai_difficulty": ai_difficulty if ai_difficulty in ["easy", "medium", "hard", "expert"] else "easy",
		# Kept for compatibility with older diagnostics. Runtime decisions read the
		# acting combatant's profile, so perspective swaps preserve deck identity.
		"ai_personality": String(opponent_combatant.get("ai_profile", "defensive")),
		"game_over": false,
		"winner": "",
		"next_instance_id": 1,
		"selected_ingredients": [],
		"selected_attacker": -1,
		"selected_spice_target": -1,
		"pending_meal": {},
		"pending_discard": {},
		"pending_ability": {},
		"pending_search": {},
		"pending_choice": {},
		"pending_resume": {},
		"pending_reaction": {},
		"opponent_sequence": {},
		"animation_events": [],
		"next_animation_event_id": 1,
		"next_animation_group_id": 1,
		"active_animation_group_id": 0,
		"visual_action_serial": 0,
		"last_visual_action": {},
		"reaction_skip": "",
		"search_queue": [],
		"message": "Add cards to data/cards.json to begin testing." if not has_playable_content() else "Play units to Prep or Plated. Only Plated cards can attack or be attacked.",
		"log": [],
		"player": player_combatant,
		"opponent": opponent_combatant
	}
	if not has_playable_content():
		return state
	_shuffle(state.player.deck)
	_shuffle(state.opponent.deck)
	for unused in range(OPENING_HAND):
		_draw(state, "player", false)
		_draw(state, "opponent", false)
	if first_side == "opponent":
		state.phase = "opponent_turn"
		if defer_opponent_turn:
			_prepare_opponent_sequence(state, true)
		else:
			_ai_turn(state)
			if not bool(state.game_over) and state.get("pending_reaction", {}).is_empty():
				state.turn = 2
				_start_turn(state, "player")
	else:
		_start_turn(state, "player", false)
	_log(state, "The cook-off begins. The first player skips their opening draw and cannot attack on their first turn.")
	_log(state, "Opponent style: %s." % _ai_profile_label(state))
	# Opening hands and setup are the initial presentation state, not gameplay animations.
	state.animation_events.clear()
	return state


func take_animation_events(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_value in state.get("animation_events", []):
		result.append((event_value as Dictionary).duplicate(true))
	state.animation_events = []
	return result


func clear_animation_events(state: Dictionary) -> void:
	state.animation_events = []


func _next_animation_group(state: Dictionary) -> int:
	var group_id := int(state.get("next_animation_group_id", 1))
	state.next_animation_group_id = group_id + 1
	return group_id


func _queue_animation_event(state: Dictionary, event_type: String, payload: Dictionary = {}, group_id: int = -1) -> Dictionary:
	if not state.has("animation_events"):
		state.animation_events = []
	if not state.has("next_animation_event_id"):
		state.next_animation_event_id = 1
	var resolved_group_id := group_id
	if resolved_group_id < 0:
		resolved_group_id = int(state.get("active_animation_group_id", 0))
	var event := payload.duplicate(true)
	event.id = int(state.next_animation_event_id)
	event.type = event_type
	event.group_id = resolved_group_id
	state.next_animation_event_id = int(state.next_animation_event_id) + 1
	state.animation_events.append(event)
	if state.animation_events.size() > 256:
		state.animation_events.pop_front()
	return event


func _take_animation_events_from(state: Dictionary, first_event_id: int) -> Array[Dictionary]:
	var deferred: Array[Dictionary] = []
	var retained: Array = []
	for event_value in state.get("animation_events", []):
		var event: Dictionary = event_value
		if int(event.get("id", 0)) >= first_event_id:
			deferred.append(event)
		else:
			retained.append(event)
	state.animation_events = retained
	return deferred


func _append_animation_events(state: Dictionary, events: Array[Dictionary]) -> void:
	for event in events:
		state.animation_events.append(event)


func _with_animation_group(state: Dictionary, group_id: int) -> int:
	var previous_group_id := int(state.get("active_animation_group_id", 0))
	state.active_animation_group_id = group_id
	return previous_group_id


func _restore_animation_group(state: Dictionary, previous_group_id: int) -> void:
	state.active_animation_group_id = previous_group_id


func play_card(state: Dictionary, hand_index: int, destination: String = "prep", target_instance_id: int = -1) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var hand: Array = state.player.hand
	if hand_index < 0 or hand_index >= hand.size():
		return _message(state, "That card is no longer in your hand.")
	var data := card(String(hand[hand_index]))
	match String(data.get("card_type", "")):
		"ingredient":
			_play_ingredient(state, "player", hand_index, destination)
		"meal":
			begin_meal_play(state, hand_index, destination)
		"tool":
			_play_tool(state, "player", hand_index)
		"chef":
			_play_chef(state, "player", hand_index)
		"environment":
			_play_environment(state, "player", hand_index)
		"spice":
			var chosen_target := target_instance_id if target_instance_id >= 0 else int(state.get("selected_spice_target", -1))
			_play_spice(state, "player", hand_index, chosen_target)
	return state


func begin_meal_play(state: Dictionary, hand_index: int, destination: String = "plated", destination_slot: int = -1) -> Dictionary:
	if not _can_player_act(state) or not state.get("pending_meal", {}).is_empty():
		return state
	if destination not in ["prep", "plated"]:
		destination = "plated"
	if hand_index < 0 or hand_index >= state.player.hand.size():
		return _message(state, "That Meal is no longer in your hand.")
	var card_id := String(state.player.hand[hand_index])
	var data := card(card_id)
	if String(data.get("card_type", "")) != "meal":
		return _message(state, "Only a Meal starts recipe selection.")
	if not _can_serve_meal(state.player):
		return _message(state, "You have already served a Meal this turn.")
	var recipe: Array = _effective_recipe(state, "player", data)
	if _find_recipe_ingredients(state.player, recipe).is_empty():
		return _message(state, "No recipe-ready Ingredients currently match: %s." % _recipe_text(recipe))
	var required_meal_archetype := String(data.get("required_meal_archetype", ""))
	if required_meal_archetype != "" and _find_recipe_meal(state.player, required_meal_archetype).is_empty():
		return _message(state, "Serving %s also requires a %s Meal." % [data.name, required_meal_archetype.capitalize()])
	state.selected_ingredients = []
	state.selected_attacker = -1
	state.selected_spice_target = -1
	state.pending_meal = {
		"hand_index": hand_index,
		"card_id": card_id,
		"destination": destination,
		"destination_slot": destination_slot,
		"required": recipe.size()
	}
	return _message(state, _meal_selection_message(state))


func meal_selectable_ingredient_ids(state: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var pending: Dictionary = state.get("pending_meal", {})
	if pending.is_empty():
		return result
	var data := card(String(pending.get("card_id", "")))
	var recipe: Array = _effective_recipe(state, "player", data)
	for zone_name in ["prep", "plated"]:
		for unit in state.player[zone_name]:
			if String(unit.get("card_type", "")) != "ingredient" or not _ingredient_is_recipe_ready(state.player, unit):
				continue
			for requirement in recipe:
				if _ingredient_matches_requirement(card(String(unit.get("card_id", ""))), String(requirement)):
					result.append(int(unit.instance_id))
					break
	return result


func meal_selection_is_ready(state: Dictionary) -> bool:
	var pending: Dictionary = state.get("pending_meal", {})
	if pending.is_empty():
		return false
	var hand_index := int(pending.get("hand_index", -1))
	if hand_index < 0 or hand_index >= state.player.hand.size() or String(state.player.hand[hand_index]) != String(pending.get("card_id", "")):
		return false
	var data := card(String(pending.card_id))
	var selected: Array = state.get("selected_ingredients", [])
	var recipe: Array = _effective_recipe(state, "player", data)
	if not _selection_satisfies(state.player, selected, recipe):
		return false
	var destination := String(pending.get("destination", "plated"))
	var selected_destination_count := 0
	for instance_id in selected:
		if not _find_unit_in_zone(state.player, destination, int(instance_id)).is_empty():
			selected_destination_count += 1
	var recipe_meal := _find_recipe_meal(state.player, String(data.get("required_meal_archetype", "")))
	if not recipe_meal.is_empty() and not _find_unit_in_zone(state.player, destination, int(recipe_meal.instance_id)).is_empty():
		selected_destination_count += 1
	var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if state.player[destination].size() - selected_destination_count + 1 > capacity:
		return false
	var destination_slot := int(pending.get("destination_slot", -1))
	if destination_slot >= 0:
		for unit in state.player[destination]:
			if int(unit.get("table_slot", -1)) != destination_slot:
				continue
			var occupant_is_selected := selected.has(int(unit.instance_id))
			var occupant_is_recipe_meal := not recipe_meal.is_empty() and int(recipe_meal.instance_id) == int(unit.instance_id)
			if not occupant_is_selected and not occupant_is_recipe_meal:
				return false
	return true


func confirm_meal_play(state: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_meal", {})
	if pending.is_empty():
		return state
	if not meal_selection_is_ready(state):
		return _message(state, _meal_selection_message(state))
	var hand_index := int(pending.hand_index)
	var destination := String(pending.destination)
	var selected: Array = state.get("selected_ingredients", []).duplicate()
	state.pending_meal = {}
	_serve_meal(state, "player", hand_index, selected, destination)
	return state


func cancel_meal_play(state: Dictionary) -> Dictionary:
	if state.get("pending_meal", {}).is_empty():
		return state
	var meal_name := String(card(String(state.pending_meal.get("card_id", ""))).get("name", "Meal"))
	state.pending_meal = {}
	state.selected_ingredients = []
	return _message(state, "%s remains in your hand." % meal_name)


func _meal_selection_message(state: Dictionary) -> String:
	var pending: Dictionary = state.get("pending_meal", {})
	var data := card(String(pending.get("card_id", "")))
	var recipe: Array = _effective_recipe(state, "player", data)
	var selected_count: int = state.get("selected_ingredients", []).size()
	return "Choose Ingredients for %s (%s): %d/%d selected." % [String(data.get("name", "Meal")), _recipe_text(recipe), selected_count, recipe.size()]


func toggle_discard_card(state: Dictionary, hand_index: int) -> Dictionary:
	var pending: Dictionary = state.get("pending_discard", {})
	if pending.is_empty():
		return state
	if hand_index < 0 or hand_index >= state.player.hand.size() or hand_index == int(pending.hand_index):
		return state
	var selected: Array = pending.get("selected_indices", [])
	if selected.has(hand_index):
		selected.erase(hand_index)
	elif selected.size() < int(pending.required):
		selected.append(hand_index)
	pending.selected_indices = selected
	state.pending_discard = pending
	return _message(state, "Select %d card%s to discard: %d/%d selected." % [pending.required, "" if int(pending.required) == 1 else "s", selected.size(), pending.required])


func confirm_discard_cost(state: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_discard", {})
	if pending.is_empty():
		return state
	var selected: Array = pending.get("selected_indices", [])
	if selected.size() != int(pending.required):
		return _message(state, "Select exactly %d card%s to pay the discard cost." % [pending.required, "" if int(pending.required) == 1 else "s"])
	var played_index := int(pending.hand_index)
	if played_index < 0 or played_index >= state.player.hand.size():
		state.pending_discard = {}
		return _message(state, "The pending Item is no longer in your hand.")
	var data := card(String(state.player.hand[played_index]))
	var removal_indices := selected.duplicate()
	removal_indices.append(played_index)
	removal_indices.sort()
	removal_indices.reverse()
	for removal_index in removal_indices:
		var index := int(removal_index)
		if index < 0 or index >= state.player.hand.size():
			continue
		state.player.discard.append(String(state.player.hand[index]))
		state.player.hand.remove_at(index)
	state.pending_discard = {}
	_log(state, "You discard %d card%s and use %s." % [pending.required, "" if int(pending.required) == 1 else "s", data.name])
	var play_group_id := _queue_play_event(state, "player", String(data.id), "tool")
	if _ai_hand_trap_stops(state, "enemy_tool", "player"):
		_log(state, "%s is negated." % data.name)
		return state
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, "player", data.get("effects", []), {})
	_restore_animation_group(state, previous_animation_group)
	return state


func cancel_discard_cost(state: Dictionary) -> Dictionary:
	if state.get("pending_discard", {}).is_empty():
		return state
	state.pending_discard = {}
	return _message(state, "Discard payment cancelled. The Item remains in your hand.")


func activate_ability(state: Dictionary, source_instance_id: int, ability_id: String = "") -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var source := _find_unit(state.player, source_instance_id)
	if source.is_empty():
		return _message(state, "That card is no longer on your field.")
	var ability := _find_activated_ability(card(String(source.card_id)), ability_id)
	if ability.is_empty():
		return _message(state, "%s has no activated ability." % source.name)
	var active_zone := String(ability.get("active_zone", ""))
	if active_zone != "" and _unit_zone(state.player, source_instance_id) != active_zone:
		return _message(state, "%s's ability can only be used while it is %s." % [source.name, active_zone.capitalize()])
	var resolved_ability_id := String(ability.get("id", "activated"))
	if bool(ability.get("once_per_turn", false)) and source.get("used_abilities", []).has(resolved_ability_id):
		return _message(state, "%s has already used that ability this turn." % source.name)
	if _ability_needs_target(ability):
		var target_spec: Dictionary = ability.get("target", {})
		var target_zone := String(target_spec.get("zone", ""))
		var target_side := String(target_spec.get("side", "enemy"))
		state.pending_ability = {
			"source_instance_id": source_instance_id,
			"ability_id": resolved_ability_id,
			"target_zone": target_zone,
			"target_side": target_side,
			"target_spec": target_spec.duplicate(true)
		}
		_clear_selections(state)
		var zone_text := target_zone.capitalize() if target_zone != "" else "Prep or Plated"
		var side_text := "friendly" if target_side == "friendly" else "opposing"
		return _message(state, "Choose a %s %s card for %s's ability." % [side_text, zone_text, source.name])
	return _resolve_activated_ability(state, source_instance_id, ability, -1)


func activate_environment_ability(state: Dictionary, ability_id: String = "") -> Dictionary:
	if not _can_player_act(state) or not state.get("pending_ability", {}).is_empty():
		return state
	var card_id := String(state.player.get("environment", ""))
	var data := card(card_id)
	var ability := _find_activated_ability(data, ability_id)
	if card_id == "" or ability.is_empty() or String(ability.get("active_zone", "")) != "environment":
		return _message(state, "Your active Environment has no usable ability.")
	var resolved_id := String(ability.get("id", "activated"))
	var used: Array = state.player.get("environment_used_abilities", [])
	if bool(ability.get("once_per_turn", false)) and used.has(resolved_id):
		return _message(state, "%s has already used that ability this turn." % data.get("name", "This Environment"))
	if bool(ability.get("once_per_turn", false)):
		used.append(resolved_id)
		state.player.environment_used_abilities = used
	_log(state, "Player activates %s's ability." % data.get("name", "Environment"))
	_resolve_effects(state, "player", ability.get("effects", []), {})
	_refresh_stat_auras(state)
	return state


func choose_ability_target(state: Dictionary, target_instance_id: int) -> Dictionary:
	var pending: Dictionary = state.get("pending_ability", {})
	if pending.is_empty():
		return state
	var source_instance_id := int(pending.get("source_instance_id", -1))
	var source := _find_unit(state.player, source_instance_id)
	if source.is_empty():
		state.pending_ability = {}
		return _message(state, "The ability's source is no longer on your field.")
	var ability := _find_activated_ability(card(String(source.card_id)), String(pending.get("ability_id", "")))
	if ability.is_empty():
		state.pending_ability = {}
		return _message(state, "That ability is no longer available.")
	var target_spec: Dictionary = pending.get("target_spec", {})
	if not _ability_target_is_valid(state, "player", source, target_instance_id, target_spec):
		return _message(state, "Choose a legal target for %s's ability." % source.name)
	state.pending_ability = {}
	return _resolve_activated_ability(state, source_instance_id, ability, target_instance_id)


func cancel_ability_target(state: Dictionary) -> Dictionary:
	if state.get("pending_ability", {}).is_empty():
		return state
	state.pending_ability = {}
	return _message(state, "Ability targeting cancelled.")


func search_candidates(state: Dictionary) -> Array[String]:
	var pending: Dictionary = state.get("pending_search", {})
	if pending.is_empty():
		return []
	if pending.has("revealed_cards"):
		return _matching_card_ids(pending.get("revealed_cards", []), pending.get("effect", {}))
	return _matching_deck_cards(state.player, pending.get("effect", {}))


func search_display_cards(state: Dictionary) -> Array[String]:
	var pending: Dictionary = state.get("pending_search", {})
	if pending.is_empty():
		return []
	if pending.has("revealed_cards"):
		var revealed: Array[String] = []
		for card_id in pending.get("revealed_cards", []):
			revealed.append(String(card_id))
		return revealed
	return search_candidates(state)


func select_search_card(state: Dictionary, card_id: String) -> Dictionary:
	var pending: Dictionary = state.get("pending_search", {})
	if pending.is_empty():
		return state
	if not search_candidates(state).has(card_id):
		return _message(state, "That card is not a valid choice for this search.")
	var deck_index: int = state.player.deck.rfind(card_id)
	if deck_index < 0:
		return _message(state, "That card is no longer in your deck.")
	state.player.deck.remove_at(deck_index)
	var destination := String(pending.get("effect", {}).get("destination", "hand"))
	if destination == "prep":
		_deploy_searched_ingredient(state, "player", card_id)
	else:
		state.player.hand.append(card_id)
		_queue_animation_event(state, "search", {
			"side": "player",
			"card_id": card_id,
			"from": "deck",
			"to": "hand",
			"hand_index": state.player.hand.size() - 1
		}, _next_animation_group(state))
	_shuffle(state.player.deck)
	state.pending_search = {}
	if destination == "prep":
		_log(state, "You put %s into Prep, then shuffle your deck." % String(card(card_id).get("name", card_id)))
	else:
		_log(state, "You add %s to your hand, then shuffle your deck." % String(card(card_id).get("name", card_id)))
	_advance_search_queue(state)
	return state


func can_play_discard_ingredient(state: Dictionary) -> bool:
	if not _can_player_act(state) or bool(state.player.get("discard_ingredient_play_used", false)) or state.player.prep.size() >= PREP_SLOTS:
		return false
	for card_id in state.player.discard:
		if bool(card(String(card_id)).get("play_from_discard_to_prep", false)):
			return true
	return false


func play_discard_ingredient(state: Dictionary) -> Dictionary:
	if not can_play_discard_ingredient(state):
		return _message(state, "You cannot play an Ingredient from your discard pile right now.")
	for discard_index in range(state.player.discard.size() - 1, -1, -1):
		var card_id := String(state.player.discard[discard_index])
		if not bool(card(card_id).get("play_from_discard_to_prep", false)):
			continue
		state.player.discard.remove_at(discard_index)
		state.player.discard_ingredient_play_used = true
		var unit := _make_unit(state, state.player, card(card_id), "prep", "player")
		state.player.prep.append(unit)
		var play_group_id := _queue_play_event(state, "player", card_id, "ingredient", int(unit.instance_id))
		var previous_animation_group := _with_animation_group(state, play_group_id)
		_resolve_effects(state, "player", card(card_id).get("on_play", []), unit)
		_restore_animation_group(state, previous_animation_group)
		_log(state, "You play %s from your discard pile to Prep." % String(card(card_id).get("name", card_id)))
		return state
	return state


func skip_search(state: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_search", {})
	if pending.is_empty():
		return state
	_shuffle(state.player.deck)
	state.pending_search = {}
	_log(state, "You take no card from the revealed cards, then shuffle your deck." if pending.has("revealed_cards") else "You skip the deck search, then shuffle your deck.")
	_advance_search_queue(state)
	return state


func choice_target_ids(state: Dictionary) -> Array[int]:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "board":
		return []
	return _valid_board_target_ids(state, String(pending.get("side", "player")), pending.get("effect", {}))


func choose_effect_target(state: Dictionary, target_instance_id: int) -> Dictionary:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "board":
		return state
	if not choice_target_ids(state).has(target_instance_id):
		return _message(state, "Choose one of the highlighted cards.")
	var pending_effect: Dictionary = pending.get("effect", {})
	var pending_effect_type := String(pending_effect.get("type", ""))
	if pending_effect_type in ["switch_friendly_zones", "switch_enemy_zones"] and not pending_effect.has("plated_instance_id"):
		pending_effect = pending_effect.duplicate(true)
		pending_effect.plated_instance_id = target_instance_id
		pending.effect = pending_effect
		pending.prompt = (
			"Choose one of your opponent's Prep foods to switch with it."
			if pending_effect_type == "switch_enemy_zones"
			else "Choose one of your Prep foods to switch with it."
		)
		state.pending_choice = pending
		return _message(state, String(pending.prompt))
	state.pending_choice = {}
	var side := String(pending.get("side", "player"))
	var source := _choice_source(state, side, int(pending.get("source_instance_id", -1)))
	_resolve_effects(state, side, [pending.get("effect", {})], source, target_instance_id)
	if state.get("pending_choice", {}).is_empty():
		_resolve_effects(state, side, pending.get("remaining_effects", []), source)
	if state.get("pending_choice", {}).is_empty():
		_resume_pending_action(state)
	return state


func discard_choice_indices(state: Dictionary) -> Array[int]:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "discard":
		return []
	return _valid_discard_indices(state[String(pending.get("side", "player"))], pending.get("effect", {}))


func toggle_discard_choice(state: Dictionary, discard_index: int) -> Dictionary:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "discard":
		return state
	if not discard_choice_indices(state).has(discard_index):
		return _message(state, "Choose an eligible card from the discard pile.")
	var selected: Array = pending.get("selected_indices", [])
	if selected.has(discard_index):
		selected.erase(discard_index)
	elif selected.size() < int(pending.get("required", 0)):
		selected.append(discard_index)
	pending.selected_indices = selected
	state.pending_choice = pending
	return _message(state, "%s %d/%d selected." % [String(pending.get("prompt", "Choose cards.")), selected.size(), int(pending.required)])


func confirm_discard_choice(state: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "discard":
		return state
	var selected: Array = pending.get("selected_indices", [])
	if selected.size() != int(pending.get("required", 0)):
		return _message(state, "Select exactly %d eligible card%s." % [int(pending.required), "" if int(pending.required) == 1 else "s"])
	var side := String(pending.get("side", "player"))
	var effect: Dictionary = pending.get("effect", {})
	var selected_cards: Array[String] = []
	var removal_indices := selected.duplicate()
	removal_indices.sort()
	for discard_index in removal_indices:
		selected_cards.append(String(state[side].discard[int(discard_index)]))
	removal_indices.reverse()
	for discard_index in removal_indices:
		state[side].discard.remove_at(int(discard_index))
	if String(effect.get("type", "")) == "recover":
		for card_id in selected_cards:
			state[side].hand.append(card_id)
			_queue_animation_event(state, "search", {
				"side": side,
				"card_id": card_id,
				"from": "discard",
				"to": "hand",
				"hand_index": state[side].hand.size() - 1
			}, _next_animation_group(state))
	elif String(effect.get("type", "")) == "revive":
		for card_id in selected_cards:
			_deploy_revived_unit(state, side, card_id)
	else:
		for card_id in selected_cards:
			state[side].deck.append(card_id)
			_queue_animation_event(state, "search", {
				"side": side,
				"card_id": card_id,
				"from": "discard",
				"to": "deck"
			}, _next_animation_group(state))
		_shuffle(state[side].deck)
	state.pending_choice = {}
	_log(state, "You choose %s from the discard pile." % ", ".join(_card_names(selected_cards)))
	_continue_after_choice(state, pending)
	return state


func opponent_hand_choice_indices(state: Dictionary) -> Array[int]:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "opponent_hand":
		return []
	return _valid_opponent_hand_indices(state, String(pending.get("side", "player")), pending.get("effect", {}))


func choose_opponent_hand_card(state: Dictionary, hand_index: int) -> Dictionary:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty() or String(pending.get("choice_kind", "")) != "opponent_hand":
		return state
	if not opponent_hand_choice_indices(state).has(hand_index):
		return _message(state, "Choose a highlighted unit from the revealed hand.")
	var side := String(pending.get("side", "player"))
	_deploy_enemy_hand_unit(state, side, hand_index)
	state.pending_choice = {}
	_continue_after_choice(state, pending)
	return state


func skip_effect_choice(state: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_choice", {})
	if pending.is_empty():
		return state
	state.pending_choice = {}
	_log(state, "You skip that effect.")
	_continue_after_choice(state, pending)
	return state


func cancel_pending_attack_choice(state: Dictionary) -> Dictionary:
	var pending_choice: Dictionary = state.get("pending_choice", {})
	var pending_resume: Dictionary = state.get("pending_resume", {})
	if pending_choice.is_empty() or String(pending_choice.get("choice_kind", "")) != "board":
		return state
	if String(pending_resume.get("type", "")) != "player_attack":
		return _message(state, "That card effect must be completed or skipped.")
	var attacker_id := int(pending_resume.get("attacker_instance_id", -1))
	state.pending_choice = {}
	state.pending_resume = {}
	state.selected_attacker = attacker_id if not _find_unit(state.player, attacker_id).is_empty() else -1
	return _message(state, "Attack cancelled. Choose a defender or the opposing chef.")


func toggle_ingredient_selection(state: Dictionary, instance_id: int) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var unit := _find_unit(state.player, instance_id)
	if unit.is_empty() or String(unit.get("card_type", "")) != "ingredient":
		return _message(state, "Only ingredients can be used in recipes.")
	if not _ingredient_is_recipe_ready(state.player, unit):
		return _message(state, "%s must survive until your next turn before it can be used in a recipe." % unit.name)
	var selected: Array = state.get("selected_ingredients", [])
	var pending_meal: Dictionary = state.get("pending_meal", {})
	if not pending_meal.is_empty() and not meal_selectable_ingredient_ids(state).has(instance_id):
		return _message(state, "%s cannot satisfy this Meal's recipe." % unit.name)
	if selected.has(instance_id):
		selected.erase(instance_id)
	else:
		if not pending_meal.is_empty() and selected.size() >= int(pending_meal.get("required", 0)):
			return _message(state, "Deselect an Ingredient before choosing another one.")
		selected.append(instance_id)
	state.selected_ingredients = selected
	state.selected_attacker = -1
	state.selected_spice_target = -1
	if not pending_meal.is_empty():
		return _message(state, _meal_selection_message(state))
	return _message(state, "%d recipe-ready ingredient%s selected." % [selected.size(), "" if selected.size() == 1 else "s"])


func select_attacker(state: Dictionary, instance_id: int) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var unit := _find_unit(state.player, instance_id)
	if unit.is_empty():
		return _message(state, "That unit cannot attack.")
	var attacker_zone := _unit_zone(state.player, instance_id)
	if attacker_zone != "plated" and not bool(card(String(unit.card_id)).get("can_attack_from_prep", false)):
		return _message(state, "Only Plated cards can attack unless their text says otherwise.")
	if _opening_attack_lock(state, "player"):
		return _message(state, "The first player cannot attack during their first turn.")
	if not bool(unit.get("ready", false)):
		return _message(state, "%s has already attacked this turn." % unit.name)
	state.selected_ingredients = []
	state.selected_spice_target = -1
	state.selected_attacker = instance_id
	var stalwart_note := " Stalwart allows it to attack the opposing chef through Plated cards." if _unit_has_keyword(unit, "stalwart") else ""
	return _message(state, "%s is attacking. Choose a Plated defender or the opposing chef.%s" % [unit.name, stalwart_note])


func can_attack_opposing_chef(state: Dictionary, attacker_instance_id: int = -1) -> bool:
	var resolved_attacker_id := attacker_instance_id if attacker_instance_id >= 0 else int(state.get("selected_attacker", -1))
	var attacker := _find_unit(state.player, resolved_attacker_id)
	if attacker.is_empty():
		return false
	if _unit_zone(state.player, resolved_attacker_id) != "plated" and not bool(card(String(attacker.card_id)).get("can_attack_from_prep", false)):
		return false
	return state.opponent.plated.is_empty() or _unit_has_keyword(attacker, "stalwart")


func select_spice_target(state: Dictionary, instance_id: int) -> Dictionary:
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var unit := _find_unit(state.player, instance_id)
	if unit.is_empty():
		return state
	state.selected_spice_target = instance_id
	state.selected_attacker = -1
	state.selected_ingredients = []
	return _message(state, "%s selected for a spice." % unit.name)


func move_unit(state: Dictionary, instance_id: int, destination: String, destination_slot: int = -1) -> Dictionary:
	if not _can_player_act(state) or (destination != "prep" and destination != "plated"):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	if bool(state.player.zone_move_used):
		return _message(state, "You have already moved a unit between zones this turn.")
	var source_zone := "plated" if not _find_unit_in_zone(state.player, "plated", instance_id).is_empty() else "prep"
	if source_zone == destination:
		return state
	var source_unit: Dictionary = _find_unit_in_zone(state.player, source_zone, instance_id)
	var source_slot := int(source_unit.get("table_slot", -1))
	if source_slot < 0:
		source_slot = state.player[source_zone].find(source_unit)
	var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	var destination_unit: Dictionary = {}
	if destination_slot >= 0:
		for destination_index in range(state.player[destination].size()):
			var candidate: Dictionary = state.player[destination][destination_index]
			var candidate_slot := int(candidate.get("table_slot", destination_index))
			if candidate_slot == destination_slot:
				destination_unit = candidate
				break
	if destination_unit.is_empty() and state.player[destination].size() >= capacity:
		return _message(state, "%s is full." % destination.capitalize())
	var unit := _remove_unit(state.player, instance_id)
	if unit.is_empty():
		return state
	var move_group_id := _next_animation_group(state)
	if not destination_unit.is_empty():
		state.player[destination].erase(destination_unit)
		unit.table_slot = destination_slot
		destination_unit.table_slot = source_slot
		unit.ready = (destination == "plated" or bool(card(String(unit.card_id)).get("can_attack_from_prep", false))) and not _opening_attack_lock(state, "player")
		destination_unit.ready = (source_zone == "plated" or bool(card(String(destination_unit.card_id)).get("can_attack_from_prep", false))) and not _opening_attack_lock(state, "player")
		state.player[destination].append(unit)
		state.player[source_zone].append(destination_unit)
		state.player.zone_move_used = true
		_queue_animation_event(state, "move", {
			"side": "player",
			"instance_id": int(unit.instance_id),
			"card_id": String(unit.card_id),
			"from": source_zone,
			"to": destination
		}, move_group_id)
		_queue_animation_event(state, "move", {
			"side": "player",
			"instance_id": int(destination_unit.instance_id),
			"card_id": String(destination_unit.card_id),
			"from": destination,
			"to": source_zone
		}, move_group_id)
		if destination == "plated":
			_resolve_effects(state, "player", card(String(unit.card_id)).get("on_move_to_plated", []), unit)
		if source_zone == "plated":
			_resolve_effects(state, "player", card(String(destination_unit.card_id)).get("on_move_to_plated", []), destination_unit)
		_refresh_stat_auras(state)
		_clear_selections(state)
		return _message(state, "%s and %s switch zones." % [unit.name, destination_unit.name])
	if destination_slot >= 0:
		unit.table_slot = destination_slot
	unit.ready = (destination == "plated" or bool(card(String(unit.card_id)).get("can_attack_from_prep", false))) and not _opening_attack_lock(state, "player")
	state.player[destination].append(unit)
	state.player.zone_move_used = true
	_queue_animation_event(state, "move", {
		"side": "player",
		"instance_id": int(unit.instance_id),
		"card_id": String(unit.card_id),
		"from": source_zone,
		"to": destination
	}, move_group_id)
	if destination == "plated":
		_resolve_effects(state, "player", card(String(unit.card_id)).get("on_move_to_plated", []), unit)
	_refresh_stat_auras(state)
	_clear_selections(state)
	return _message(state, "%s moves from %s to %s." % [unit.name, source_zone.capitalize(), destination.capitalize()])


func attack(state: Dictionary, target_instance_id: int = -1) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal first.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost first.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability first.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search first.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice first.")
	var attacker_id := int(state.get("selected_attacker", -1))
	var attacker := _find_unit(state.player, attacker_id)
	if attacker.is_empty() or not bool(attacker.get("ready", false)):
		return _message(state, "Select a ready attacker first.")
	if _unit_zone(state.player, attacker_id) != "plated" and not bool(card(String(attacker.card_id)).get("can_attack_from_prep", false)):
		return _message(state, "That Prep unit cannot attack.")
	if _opening_attack_lock(state, "player"):
		return _message(state, "The first player cannot attack during their first turn.")
	if target_instance_id < 0:
		if not can_attack_opposing_chef(state, attacker_id):
			return _message(state, "You must clear all opposing Plated cards before attacking face.")
	else:
		var defender := _find_unit_in_zone(state.opponent, "plated", target_instance_id)
		if defender.is_empty():
			return _message(state, "Only opposing Plated cards can be attacked.")
		if not _first_plated_with_keyword(state.opponent, "taunt").is_empty() and not _unit_has_keyword(defender, "taunt"):
			return _message(state, "A Plated unit with Taunt must be attacked first.")
	var attacker_data := card(String(attacker.card_id))
	state.pending_resume = {
		"type": "player_attack",
		"attacker_instance_id": attacker_id,
		"target_instance_id": target_instance_id,
		"defer_on_attack_animation": bool(attacker_data.get("on_attack_animation_after_combat", false)),
		"on_attack_animation_start_id": int(state.get("next_animation_event_id", 1))
	}
	_resolve_effects(state, "player", attacker_data.get("on_attack", []), attacker)
	if state.get("pending_choice", {}).is_empty():
		_resume_pending_action(state)
	return state


func end_player_turn(state: Dictionary, defer_opponent_turn: bool = false) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_meal", {}).is_empty():
		return _message(state, "Choose ingredients or cancel the pending Meal before ending the turn.")
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost before ending the turn.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability before ending the turn.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search before ending the turn.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice before ending the turn.")
	_resolve_end_turn_triggers(state, "player")
	_set_defense_positions(state, "player")
	_clear_selections(state)
	_clear_temporary_buffs(state.player)
	state.player.chefs_disabled = false
	state.player.items_disabled = false
	state.phase = "opponent_turn"
	if defer_opponent_turn:
		_prepare_opponent_sequence(state, true)
		return state
	_ai_turn(state)
	if not state.get("pending_reaction", {}).is_empty():
		return state
	if not bool(state.game_over):
		state.turn = int(state.turn) + 1
		_start_turn(state, "player")
	return state


func recipe_status(state: Dictionary, card_id: String) -> String:
	var data := card(card_id)
	var recipe: Array = _effective_recipe(state, "player", data)
	var meal_requirement := String(data.get("required_meal_archetype", ""))
	var selected: Array = state.get("selected_ingredients", [])
	if selected.is_empty():
		var recipe_text := _recipe_text(recipe)
		if meal_requirement != "":
			recipe_text += " + %s Meal" % meal_requirement.capitalize()
		return "Recipe: " + recipe_text
	var ready := _selection_satisfies(state.player, selected, recipe)
	if meal_requirement != "":
		ready = ready and not _find_recipe_meal(state.player, meal_requirement).is_empty()
	return "Selected recipe: %s" % ("ready" if ready else "does not match")


func ingredient_recipe_status(combatant: Dictionary, unit: Dictionary) -> String:
	if String(unit.get("card_type", "")) != "ingredient":
		return ""
	return "RECIPE READY" if _ingredient_is_recipe_ready(combatant, unit) else "PREPARING"


func _make_combatant(deck_id: String) -> Dictionary:
	var deck_list: Array = []
	for card_id in decks.get(deck_id, {}).get("cards", {}):
		for unused in range(int(decks[deck_id].cards[card_id])):
			deck_list.append(String(card_id))
	return {
		"deck_id": deck_id,
		"ai_profile": _ai_profile_for_deck(deck_id),
		"ai_policy": AI_POLICY_PRODUCTION,
		"life": STARTING_LIFE,
		"deck": deck_list,
		"hand": [],
		"prep": [],
		"plated": [],
		"environment": "",
		"environment_used_abilities": [],
		"discard": [],
		"meal_served": false,
		"meals_served": 0,
		"chef_used": false,
		"zone_move_used": false,
		"chefs_disabled": false,
		"items_disabled": false,
		"hand_trap_used": false,
		"discard_ingredient_play_used": false,
		"fatigue": 0,
		"turns_started": 0
	}


func _ai_profile_for_deck(deck_id: String) -> String:
	match String(decks.get(deck_id, {}).get("archetype", "")).to_lower():
		"spicy":
			return "pressure"
		"hearty":
			return "defensive"
		"sweet":
			return "value"
	# Custom or mixed decks receive a stable profile instead of inheriting the
	# other seat's seed-derived personality.
	return String(AI_PERSONALITIES[posmod(deck_id.hash(), AI_PERSONALITIES.size())])


func reaction_hand_indices(state: Dictionary) -> Array[int]:
	var pending: Dictionary = state.get("pending_reaction", {})
	var result: Array[int] = []
	for hand_index in pending.get("eligible_indices", []):
		var index := int(hand_index)
		if index >= 0 and index < state.player.hand.size():
			result.append(index)
	return result


func resolve_reaction(state: Dictionary, hand_index: int = -1, resume_opponent_turn: bool = true) -> Dictionary:
	var pending: Dictionary = state.get("pending_reaction", {})
	if pending.is_empty():
		return state
	var use_reaction := reaction_hand_indices(state).has(hand_index)
	var reaction_kind := String(pending.get("reaction_kind", "hand_trap"))
	var action_negated := false
	if use_reaction:
		var reaction_card_id := String(state.player.hand[hand_index])
		state.player.hand.remove_at(hand_index)
		state.player.discard.append(reaction_card_id)
		if reaction_kind == "hand_trap":
			_queue_play_event(state, "player", reaction_card_id, "reaction")
			state.player.hand_trap_used = true
			if _consume_hand_trap_guard(state, String(pending.get("acting_side", "opponent"))):
				_log(state, "%s negates %s." % [card(String(_guard_source_card_id(state, String(pending.get("acting_side", "opponent"))))).get("name", "A guard"), card(reaction_card_id).get("name", reaction_card_id)])
			else:
				action_negated = true
				_log(state, "%s answers the opposing action." % card(reaction_card_id).get("name", reaction_card_id))
		else:
			_deploy_damage_trigger_card(state, "player", reaction_card_id)
	state.pending_reaction = {}
	var action_kind := String(pending.get("action_kind", ""))
	if reaction_kind == "hand_trap":
		if action_negated:
			_resolve_negated_opponent_action(state, pending)
		else:
			_resolve_opponent_action_after_pass(state, pending)
	elif not use_reaction:
		_log(state, "You pass the reaction window.")
	if resume_opponent_turn:
		_resume_opponent_turn_after_reaction(state)
	return state


func _offer_player_reaction(state: Dictionary, trigger: String, action: Dictionary, reaction_kind: String = "hand_trap") -> bool:
	if not state.get("pending_reaction", {}).is_empty():
		return true
	if reaction_kind == "hand_trap" and bool(state.player.get("hand_trap_used", false)):
		return false
	var eligible := _hand_reaction_indices(state.player, trigger, reaction_kind)
	if eligible.is_empty():
		return false
	action["trigger"] = trigger
	action["reaction_kind"] = reaction_kind
	action["eligible_indices"] = eligible
	state.pending_reaction = action
	state.phase = "opponent_turn"
	_message(state, "You may respond from your hand or pass.")
	return true


func _hand_reaction_indices(combatant: Dictionary, trigger: String, reaction_kind: String = "hand_trap") -> Array[int]:
	var result: Array[int] = []
	for hand_index in range(combatant.hand.size()):
		var data := card(String(combatant.hand[hand_index]))
		var definition: Dictionary = data.get("hand_trap", {}) if reaction_kind == "hand_trap" else data.get("hand_trigger", {})
		if String(definition.get("trigger", "")) == trigger:
			result.append(hand_index)
	return result


func _ai_hand_trap_stops(state: Dictionary, trigger: String, acting_side: String) -> bool:
	var defending_side := "opponent" if acting_side == "player" else "player"
	if bool(state[defending_side].get("hand_trap_used", false)):
		return false
	var eligible := _hand_reaction_indices(state[defending_side], trigger)
	if eligible.is_empty():
		return false
	if defending_side == "opponent" and _ai_level(state) >= 3 and not _expert_should_use_hand_trap(state, trigger, int(eligible[0])):
		return false
	var hand_index := int(eligible[0])
	var trap_id := String(state[defending_side].hand[hand_index])
	state[defending_side].hand.remove_at(hand_index)
	state[defending_side].discard.append(trap_id)
	_queue_play_event(state, defending_side, trap_id, "reaction")
	state[defending_side].hand_trap_used = true
	if _consume_hand_trap_guard(state, acting_side):
		_log(state, "%s's Hand Trap is negated." % _side_name(defending_side))
		return false
	_log(state, "%s uses %s from hand." % [_side_name(defending_side), card(trap_id).get("name", trap_id)])
	return true


func _expert_should_use_hand_trap(state: Dictionary, trigger: String, trap_hand_index: int) -> bool:
	var trap_value := _ai_card_hold_value(String(state.opponent.hand[trap_hand_index]))
	var threat_value := 0.0
	match trigger:
		"enemy_tool", "enemy_chef":
			if not state.player.discard.is_empty():
				threat_value = _ai_card_hold_value(String(state.player.discard[-1]))
		"enemy_ingredient_played":
			var newest_unit: Dictionary = {}
			for zone_name in ["prep", "plated"]:
				for unit in state.player[zone_name]:
					if newest_unit.is_empty() or int(unit.instance_id) > int(newest_unit.instance_id):
						newest_unit = unit
			if not newest_unit.is_empty():
				threat_value = float(int(newest_unit.attack) * 4 + int(newest_unit.health) * 3) + _ai_card_effect_value(card(String(newest_unit.card_id)))
		"enemy_activated_ability":
			for zone_name in ["prep", "plated"]:
				for unit in state.player[zone_name]:
					for ability in card(String(unit.card_id)).get("abilities", []):
						threat_value = maxf(threat_value, _ai_effect_list_value(ability.get("effects", [])))
	# Preserve a scarce answer for a more consequential action. Lethal-range plays
	# still get answered even if their raw card score is modest.
	if int(state.opponent.life) <= 7 and trigger in ["enemy_ingredient_played", "enemy_activated_ability"]:
		return true
	return threat_value >= maxf(10.0, trap_value * 0.72)


func _ai_effect_list_value(effects: Array) -> float:
	return _ai_card_effect_value({"effects": effects})


func _consume_hand_trap_guard(state: Dictionary, protected_side: String) -> bool:
	for unit in state[protected_side].plated:
		var data := card(String(unit.card_id))
		if not bool(data.get("hand_trap_guard", false)):
			continue
		var guard_id := "hand_trap_guard"
		if unit.get("used_abilities", []).has(guard_id):
			continue
		unit.used_abilities.append(guard_id)
		state["last_hand_trap_guard_card_id"] = String(unit.card_id)
		return true
	return false


func _guard_source_card_id(state: Dictionary, _side: String) -> String:
	return String(state.get("last_hand_trap_guard_card_id", ""))


func _resolve_negated_opponent_action(state: Dictionary, pending: Dictionary) -> void:
	match String(pending.get("action_kind", "")):
		"chef":
			_pay_negated_card_from_hand(state, "opponent", String(pending.get("card_id", "")), "chef")
		"tool":
			_pay_negated_card_from_hand(state, "opponent", String(pending.get("card_id", "")), "tool")
		"destroy_ingredient":
			var destroyed := _remove_unit(state.opponent, int(pending.get("source_instance_id", -1)))
			if not destroyed.is_empty():
				_queue_unit_event(state, "destroy", "opponent", destroyed, "reaction", 0)
				_discard_unit_attachments(state.opponent, destroyed)
				_discard_unit_card(state.opponent, destroyed)
		"activated_ability":
			pass


func _resolve_opponent_action_after_pass(state: Dictionary, pending: Dictionary) -> void:
	var card_id := String(pending.get("card_id", ""))
	var hand_index: int = state.opponent.hand.find(card_id)
	match String(pending.get("action_kind", "")):
		"chef":
			if hand_index >= 0:
				_play_chef(state, "opponent", hand_index, true)
		"tool":
			if hand_index >= 0:
				_play_tool(state, "opponent", hand_index, true)
		"activated_ability":
			_resolve_effects(
				state,
				"opponent",
				pending.get("effects", []),
				pending.get("source", {}),
				int(pending.get("target_instance_id", -1))
			)
		"destroy_ingredient":
			pass


func _pay_negated_card_from_hand(state: Dictionary, side: String, card_id: String, action_kind: String) -> void:
	var hand_index: int = state[side].hand.find(card_id)
	if hand_index < 0:
		return
	var data := card(card_id)
	state[side].hand.remove_at(hand_index)
	state[side].discard.append(card_id)
	_queue_play_event(state, side, card_id, action_kind)
	if action_kind == "chef":
		state[side].chef_used = true
	elif action_kind == "tool":
		for unused in range(mini(int(data.get("discard_cost", 0)), state[side].hand.size())):
			var discard_index: int = state[side].hand.size() - 1
			if side == "opponent" and _ai_level(state) >= 3:
				discard_index = _ai_lowest_value_hand_index(state[side].hand)
			state[side].discard.append(String(state[side].hand[discard_index]))
			state[side].hand.remove_at(discard_index)


func _resume_opponent_turn_after_reaction(state: Dictionary) -> void:
	if bool(state.game_over) or not state.get("pending_reaction", {}).is_empty():
		return
	_ai_turn(state, false)
	if bool(state.game_over) or not state.get("pending_reaction", {}).is_empty():
		return
	state.turn = int(state.turn) + 1
	_start_turn(state, "player")


func _deploy_damage_trigger_card(state: Dictionary, side: String, card_id: String) -> void:
	if state[side].plated.size() >= PLATED_SLOTS or state[side].prep.size() >= PREP_SLOTS:
		return
	var data := card(card_id)
	var played := _make_unit(state, state[side], data, "plated", side)
	state[side].plated.append(played)
	_queue_play_event(state, side, card_id, String(data.get("card_type", "ingredient")), int(played.instance_id))
	var token := _make_unit(state, state[side], card("token_fresh_ingredient"), "prep", side)
	token.is_token = true
	state[side].prep.append(token)
	_queue_play_event(state, side, "token_fresh_ingredient", "token", int(token.instance_id))
	_log(state, "%s springs into Plated and creates a Fresh Ingredient token." % data.name)


func _trigger_friendly_chef_damaged(state: Dictionary, target_side: String) -> void:
	if bool(state.game_over) or state[target_side].plated.size() >= PLATED_SLOTS or state[target_side].prep.size() >= PREP_SLOTS:
		return
	if target_side == "player":
		_offer_player_reaction(state, "friendly_chef_damaged", {"action_kind":"chef_damage_trigger","acting_side":"opponent"}, "hand_trigger")
	else:
		var eligible := _hand_reaction_indices(state[target_side], "friendly_chef_damaged", "hand_trigger")
		if not eligible.is_empty():
			var index := int(eligible[0])
			var card_id := String(state[target_side].hand[index])
			state[target_side].hand.remove_at(index)
			_deploy_damage_trigger_card(state, target_side, card_id)


func _play_ingredient(state: Dictionary, side: String, hand_index: int, destination: String) -> bool:
	if destination != "prep" and destination != "plated":
		return false
	var who: Dictionary = state[side]
	var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if who[destination].size() >= capacity:
		_message(state, "%s is full." % destination.capitalize())
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	who.hand.remove_at(hand_index)
	var unit := _make_unit(state, who, data, destination, side)
	who[destination].append(unit)
	_record_hand_play(state, side, card_id, "ingredient", int(unit.instance_id))
	var play_group_id := _queue_play_event(state, side, card_id, "ingredient", int(unit.instance_id))
	_log(state, "%s plays %s to %s." % [_side_name(side), data.name, destination.capitalize()])
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, side, data.get("on_play", []), unit)
	_restore_animation_group(state, previous_animation_group)
	if side == "opponent" and not _find_unit(state.opponent, int(unit.instance_id)).is_empty():
		_offer_player_reaction(state, "enemy_ingredient_played", {
			"action_kind": "destroy_ingredient",
			"acting_side": "opponent",
			"source_instance_id": int(unit.instance_id),
			"card_id": card_id
		})
	elif side == "player" and _ai_hand_trap_stops(state, "enemy_ingredient_played", side):
		var destroyed := _remove_unit(state.player, int(unit.instance_id))
		if not destroyed.is_empty():
			_queue_unit_event(state, "destroy", "player", destroyed, "reaction", 0)
			_discard_unit_attachments(state.player, destroyed)
			_discard_unit_card(state.player, destroyed)
			_log(state, "%s is destroyed by the response." % data.name)
	return true


func _serve_meal(state: Dictionary, side: String, hand_index: int, requested_ids: Array, destination: String = "plated") -> bool:
	var who: Dictionary = state[side]
	if destination != "prep" and destination != "plated":
		destination = "plated"
	if not _can_serve_meal(who):
		_message(state, "%s has already served a Meal this turn." % _side_name(side))
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	var recipe: Array = _effective_recipe(state, side, data)
	var chosen := requested_ids.duplicate()
	if chosen.is_empty():
		chosen = _find_recipe_ingredients(who, recipe)
	if not _selection_satisfies(who, chosen, recipe):
		_message(state, "Select recipe-ready ingredients matching: %s." % _recipe_text(recipe))
		return false
	var required_meal_archetype := String(data.get("required_meal_archetype", ""))
	var recipe_meal := _find_recipe_meal(who, required_meal_archetype) if required_meal_archetype != "" else {}
	if required_meal_archetype != "" and recipe_meal.is_empty():
		_message(state, "Serving %s also requires a %s Meal." % [data.name, required_meal_archetype.capitalize()])
		return false
	var selected_destination_count := 0
	var replacement_table_slot := -1
	for instance_id in chosen:
		var selected_destination_unit := _find_unit_in_zone(who, destination, int(instance_id))
		if not selected_destination_unit.is_empty():
			selected_destination_count += 1
			if replacement_table_slot < 0:
				replacement_table_slot = int(selected_destination_unit.get("table_slot", -1))
	if not recipe_meal.is_empty() and not _find_unit_in_zone(who, destination, int(recipe_meal.instance_id)).is_empty():
		selected_destination_count += 1
		if replacement_table_slot < 0:
			replacement_table_slot = int(recipe_meal.get("table_slot", -1))
	var destination_capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if who[destination].size() - selected_destination_count + 1 > destination_capacity:
		_message(state, "%s is full. The recipe must use an ingredient there or an open slot." % destination.capitalize())
		return false
	var sacrificed_names: Array[String] = []
	var sacrificed_attack := 0
	var sacrificed_health := 0
	var sacrifice_group_id := _next_animation_group(state)
	if not recipe_meal.is_empty():
		var removed_meal := _remove_unit(who, int(recipe_meal.instance_id))
		if not removed_meal.is_empty():
			_queue_unit_event(state, "sacrifice", side, removed_meal, "meal_recipe", sacrifice_group_id)
			sacrificed_names.append(String(removed_meal.name))
			sacrificed_attack += int(removed_meal.attack)
			sacrificed_health += int(removed_meal.max_health)
			_resolve_effects(state, side, card(String(removed_meal.card_id)).get("on_sacrifice", []), removed_meal)
			_discard_unit_attachments(who, removed_meal)
			_discard_unit_card(who, removed_meal)
	for instance_id in chosen:
		var removed := _remove_unit(who, int(instance_id))
		if removed.is_empty():
			continue
		_queue_unit_event(state, "sacrifice", side, removed, "meal_recipe", sacrifice_group_id)
		sacrificed_names.append(String(removed.name))
		sacrificed_attack += int(removed.attack)
		sacrificed_health += int(removed.max_health)
		_resolve_effects(state, side, card(String(removed.card_id)).get("on_sacrifice", []), removed)
		_discard_unit_attachments(who, removed)
		_discard_unit_card(who, removed)
	who.hand.remove_at(hand_index)
	var meal := _make_unit(state, who, data, destination, side)
	if replacement_table_slot >= 0:
		meal.table_slot = replacement_table_slot
	meal.served_sacrifice_attack = sacrificed_attack
	meal.served_sacrifice_health = sacrificed_health
	if String(who.environment) != "":
		var environment_data := card(String(who.environment))
		meal.attack += int(environment_data.get("meal_attack_bonus", 0))
		meal.health += int(environment_data.get("meal_health_bonus", 0))
		meal.max_health += int(environment_data.get("meal_health_bonus", 0))
	who[destination].append(meal)
	who.meals_served = int(who.get("meals_served", 0)) + 1
	who.meal_served = int(who.meals_served) >= _meal_limit(who)
	_record_hand_play(state, side, card_id, "meal", int(meal.instance_id))
	var play_group_id := _queue_play_event(state, side, card_id, "meal", int(meal.instance_id))
	_refresh_stat_auras(state)
	state.selected_ingredients = []
	_log(state, "%s sacrifices %s and serves %s to %s." % [_side_name(side), ", ".join(sacrificed_names), data.name, destination.capitalize()])
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, side, data.get("on_play", []), meal)
	_restore_animation_group(state, previous_animation_group)
	return true


func _play_tool(state: Dictionary, side: String, hand_index: int, skip_reaction: bool = false) -> bool:
	var who: Dictionary = state[side]
	if bool(who.items_disabled):
		_message(state, "%s cannot use Items this turn." % _side_name(side))
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	var discard_cost := int(data.get("discard_cost", 0))
	if who.hand.size() - 1 < discard_cost:
		_message(state, "Not enough cards to pay %s's discard cost." % data.name)
		return false
	if not skip_reaction:
		_record_hand_play(state, side, card_id, "tool")
	if side == "player" and discard_cost > 0:
		state.pending_discard = {
			"hand_index": hand_index,
			"card_id": card_id,
			"required": discard_cost,
			"selected_indices": []
		}
		_clear_selections(state)
		_message(state, "Select %d card%s from your hand to discard for %s." % [discard_cost, "" if discard_cost == 1 else "s", data.name])
		return true
	if side == "opponent" and not skip_reaction and _offer_player_reaction(state, "enemy_tool", {
		"action_kind": "tool",
		"acting_side": "opponent",
		"card_id": card_id
	}):
		return true
	who.hand.remove_at(hand_index)
	who.discard.append(card_id)
	for unused in range(discard_cost):
		var discard_index: int = who.hand.size() - 1
		if side == "opponent" and _ai_level(state) >= 3:
			discard_index = _ai_lowest_value_hand_index(who.hand)
		who.discard.append(String(who.hand[discard_index]))
		who.hand.remove_at(discard_index)
	var play_group_id := _queue_play_event(state, side, card_id, "tool")
	_log(state, "%s uses %s." % [_side_name(side), data.name])
	if side == "player" and _ai_hand_trap_stops(state, "enemy_tool", side):
		_log(state, "%s is negated." % data.name)
		return true
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, side, data.get("effects", []), {})
	_restore_animation_group(state, previous_animation_group)
	return true


func _play_chef(state: Dictionary, side: String, hand_index: int, skip_reaction: bool = false) -> bool:
	var who: Dictionary = state[side]
	if bool(who.chef_used):
		_message(state, "%s has already used a Chef this turn." % _side_name(side))
		return false
	if bool(who.chefs_disabled):
		_message(state, "%s cannot use a Chef this turn." % _side_name(side))
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	if not skip_reaction:
		_record_hand_play(state, side, card_id, "chef")
	if side == "opponent" and not skip_reaction and _offer_player_reaction(state, "enemy_chef", {
		"action_kind": "chef",
		"acting_side": "opponent",
		"card_id": card_id
	}):
		return true
	who.hand.remove_at(hand_index)
	who.discard.append(card_id)
	who.chef_used = true
	var play_group_id := _queue_play_event(state, side, card_id, "chef")
	_log(state, "%s calls on %s." % [_side_name(side), data.name])
	if side == "player" and _ai_hand_trap_stops(state, "enemy_chef", side):
		_log(state, "%s is negated." % data.name)
		return true
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, side, data.get("effects", []), {})
	_restore_animation_group(state, previous_animation_group)
	return true


func _play_environment(state: Dictionary, side: String, hand_index: int) -> bool:
	var who: Dictionary = state[side]
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	who.hand.remove_at(hand_index)
	if String(who.environment) != "":
		who.discard.append(String(who.environment))
	who.environment = card_id
	_record_hand_play(state, side, card_id, "environment")
	_queue_play_event(state, side, card_id, "environment")
	_log(state, "%s establishes %s." % [_side_name(side), data.name])
	return true


func _play_spice(state: Dictionary, side: String, hand_index: int, target_instance_id: int) -> bool:
	var who: Dictionary = state[side]
	var target := _find_unit(who, target_instance_id)
	if target.is_empty():
		_message(state, "Select a Prep or Plated card before playing a spice.")
		return false
	if not target.get("spices", []).is_empty():
		_message(state, "%s already has a spice." % target.name)
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	who.hand.remove_at(hand_index)
	target.attack += int(data.get("attack_bonus", 0))
	target.health += int(data.get("health_bonus", 0))
	target.max_health += int(data.get("health_bonus", 0))
	target.spices.append(card_id)
	_record_hand_play(state, side, card_id, "spice", int(target.instance_id))
	var play_group_id := _queue_play_event(state, side, card_id, "spice", -1, int(target.instance_id))
	_queue_buff_event(state, side, target, int(data.get("attack_bonus", 0)), int(data.get("health_bonus", 0)), play_group_id)
	_log(state, "%s seasons %s with %s." % [_side_name(side), target.name, data.name])
	state.selected_spice_target = -1
	return true


func _make_unit(state: Dictionary, combatant: Dictionary, data: Dictionary, zone: String, side: String) -> Dictionary:
	var unit := {
		"instance_id": int(state.next_instance_id),
		"card_id": String(data.id),
		"name": String(data.name),
		"card_type": String(data.card_type),
		"is_token": bool(data.get("is_token", false)),
		"attack": int(data.get("attack", 0)),
		"health": int(data.get("health", 1)),
		"max_health": int(data.get("health", 1)),
		"ready": (zone == "plated" or bool(data.get("can_attack_from_prep", false))) and not _opening_attack_lock(state, side),
		"recipe_ready_on_turn": int(combatant.turns_started) + 1,
		"used_abilities": [],
		"triggered_effects": [],
		"temporary_attack": 0,
		"aura_attack_bonus": 0,
		"aura_health_bonus": 0,
		"spices": [],
		"defending": false
	}
	state.next_instance_id = int(state.next_instance_id) + 1
	return unit


func _start_turn(state: Dictionary, side: String, draw_card: bool = true) -> bool:
	var who: Dictionary = state[side]
	var opening_draw_is_skipped := (
		draw_card
		and String(state.get("first_player", "")) == side
		and int(who.get("turns_started", 0)) == 0
	)
	var should_draw := draw_card and not opening_draw_is_skipped
	who.turns_started = int(who.turns_started) + 1
	who.meal_served = false
	who.meals_served = 0
	who.chef_used = false
	who.zone_move_used = false
	who.hand_trap_used = false
	who.discard_ingredient_play_used = false
	who.environment_used_abilities = []
	for unit in who.prep:
		unit.ready = bool(card(String(unit.card_id)).get("can_attack_from_prep", false)) and not _opening_attack_lock(state, side)
		unit.used_abilities = []
	var defense_release_group_id := -1
	for unit in who.plated:
		var was_defending := bool(unit.get("defending", false))
		unit.ready = not _opening_attack_lock(state, side)
		unit.defending = false
		unit.used_abilities = []
		if was_defending:
			if defense_release_group_id < 0:
				defense_release_group_id = _next_animation_group(state)
			_queue_animation_event(state, "defense_position", {
				"side": side,
				"instance_id": int(unit.instance_id),
				"card_id": String(unit.card_id),
				"defending": false
			}, defense_release_group_id)
	if String(who.environment) != "":
		var growth := int(card(String(who.environment)).get("ingredient_growth", 0))
		if growth > 0:
			var growth_group_id := _next_animation_group(state)
			for zone_name in ["prep", "plated"]:
				for unit in who[zone_name]:
					if String(unit.card_type) == "ingredient":
						unit.attack += growth
						unit.health += growth
						unit.max_health += growth
						_queue_buff_event(state, side, unit, growth, growth, growth_group_id)
	if should_draw:
		_draw(state, side)
		while who.hand.size() < START_TURN_HAND_FLOOR and not who.deck.is_empty():
			_draw(state, side)
	state.phase = "player_main" if side == "player" else "opponent_turn"
	return should_draw


func _prepare_opponent_sequence(state: Dictionary, start_turn: bool) -> void:
	state.opponent_sequence = {
		"stage": "start" if start_turn else "main",
		"attack_ids": []
	}
	state.phase = "opponent_turn"


func advance_opponent_turn(state: Dictionary) -> Dictionary:
	if bool(state.game_over) or not state.get("pending_reaction", {}).is_empty():
		return state
	if String(state.get("phase", "")) != "opponent_turn":
		return state
	if state.get("opponent_sequence", {}).is_empty():
		_prepare_opponent_sequence(state, true)
	var transition_safety := 8
	while transition_safety > 0:
		transition_safety -= 1
		var sequence: Dictionary = state.opponent_sequence
		match String(sequence.get("stage", "start")):
			"start":
				var drew_for_turn := _start_turn(state, "opponent")
				sequence.stage = "main"
				_log(
					state,
					"Opponent draws for their turn."
					if drew_for_turn
					else "Opponent goes first and skips their opening draw."
				)
				return state
			"main":
				if _ai_play_discard_ingredient(state):
					return state
				if _ai_play_one_hand_card(state):
					return state
				sequence.stage = "abilities"
			"abilities":
				if _ai_activate_one_ability(state):
					return state
				sequence.stage = "move"
			"move":
				sequence.stage = "attacks"
				sequence.attack_ids = _ai_attack_ids(state)
				if _ai_should_move_to_plated(state):
					var moved: Dictionary = _ai_unit_to_plate(state)
					state.opponent.prep.erase(moved)
					moved.ready = true
					state.opponent.plated.append(moved)
					state.opponent.zone_move_used = true
					_queue_animation_event(state, "move", {
						"side": "opponent",
						"instance_id": int(moved.instance_id),
						"card_id": String(moved.card_id),
						"from": "prep",
						"to": "plated"
					}, _next_animation_group(state))
					_resolve_effects(state, "opponent", card(String(moved.card_id)).get("on_move_to_plated", []), moved)
					_refresh_stat_auras(state)
					sequence.attack_ids = _ai_attack_ids(state)
					_log(state, "Opponent moves %s from Prep to Plated." % moved.name)
					return state
			"attacks":
				var attack_ids: Array = sequence.get("attack_ids", [])
				while not attack_ids.is_empty():
					var attacker_id := int(attack_ids.pop_front())
					sequence.attack_ids = attack_ids
					var attacker := _find_unit(state.opponent, attacker_id)
					if attacker.is_empty() or not bool(attacker.ready):
						continue
					_ai_attack_with_unit(state, attacker)
					return state
				sequence.stage = "end"
			"end":
				state.opponent.chefs_disabled = false
				state.opponent.items_disabled = false
				_resolve_end_turn_triggers(state, "opponent")
				_set_defense_positions(state, "opponent")
				_clear_temporary_buffs(state.opponent)
				state.opponent_sequence = {}
				if not bool(state.game_over):
					state.turn = int(state.turn) + 1
					_start_turn(state, "player")
				return state
	return state


func _ai_play_discard_ingredient(state: Dictionary) -> bool:
	if bool(state.opponent.get("discard_ingredient_play_used", false)) or state.opponent.prep.size() >= PREP_SLOTS:
		return false
	for discard_index in range(state.opponent.discard.size() - 1, -1, -1):
		var card_id := String(state.opponent.discard[discard_index])
		if not bool(card(card_id).get("play_from_discard_to_prep", false)):
			continue
		state.opponent.discard.remove_at(discard_index)
		state.opponent.discard_ingredient_play_used = true
		var unit := _make_unit(state, state.opponent, card(card_id), "prep", "opponent")
		state.opponent.prep.append(unit)
		var play_group_id := _queue_play_event(state, "opponent", card_id, "ingredient", int(unit.instance_id))
		var previous_animation_group := _with_animation_group(state, play_group_id)
		_resolve_effects(state, "opponent", card(card_id).get("on_play", []), unit)
		_restore_animation_group(state, previous_animation_group)
		_log(state, "Opponent plays %s from the discard pile to Prep." % String(card(card_id).get("name", card_id)))
		return true
	return false


func _ai_play_one_hand_card(state: Dictionary) -> bool:
	if _ai_policy(state) == AI_POLICY_FACE_RACE:
		return _ai_play_face_race_hand_card(state)
	if _ai_level(state) >= 3:
		return _ai_play_lookahead_hand_card(state)
	if _ai_level(state) > 0:
		return _ai_play_best_hand_card(state)
	return _ai_play_first_hand_card(state)


func _ai_play_first_hand_card(state: Dictionary) -> bool:
	for hand_index in range(state.opponent.hand.size() - 1, -1, -1):
		var data := card(String(state.opponent.hand[hand_index]))
		var card_type := String(data.get("card_type", ""))
		if card_type == "environment":
			return _play_environment(state, "opponent", hand_index)
		if card_type == "meal" and _can_serve_meal(state.opponent):
			var recipe_units := _find_recipe_ingredients(state.opponent, _effective_recipe(state, "opponent", data))
			var required_meal := String(data.get("required_meal_archetype", ""))
			var has_required_meal := required_meal == "" or not _find_recipe_meal(state.opponent, required_meal).is_empty()
			if not recipe_units.is_empty() and has_required_meal:
				var meal_destination := _ai_deployment_zone(state, "meal")
				return _serve_meal(state, "opponent", hand_index, recipe_units, meal_destination)
		if card_type == "ingredient":
			var destination := _ai_deployment_zone(state, "ingredient")
			var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
			if state.opponent[destination].size() < capacity:
				return _play_ingredient(state, "opponent", hand_index, destination)
		if card_type == "spice":
			var spice_target := _first_unspiced_unit(state.opponent)
			if not spice_target.is_empty():
				return _play_spice(state, "opponent", hand_index, int(spice_target.instance_id))
		if card_type == "tool":
			return _play_tool(state, "opponent", hand_index)
		if card_type == "chef":
			return _play_chef(state, "opponent", hand_index)
	return false


func _ai_play_face_race_hand_card(state: Dictionary) -> bool:
	var best_action: Dictionary = {}
	var best_score := -INF
	for hand_index in range(state.opponent.hand.size()):
		var action := _ai_hand_action(state, hand_index)
		if action.is_empty():
			continue
		var score := _ai_face_race_card_score(state, card(String(action.card_id)))
		if score > best_score:
			best_score = score
			best_action = action
	if best_action.is_empty():
		return false
	return _ai_execute_hand_action(state, best_action)


func _ai_face_race_card_score(state: Dictionary, data: Dictionary) -> float:
	var score := 0.0
	match String(data.get("card_type", "")):
		"meal":
			score += 40.0 + float(int(data.get("attack", 0)) * 8)
		"ingredient":
			score += 25.0 + float(int(data.get("attack", 0)) * 8)
		"spice":
			score += 20.0 + float(int(data.get("attack_bonus", 0)) * 10)
		"environment":
			score += float(int(data.get("meal_attack_bonus", 0)) * 12)
		_:
			score += 5.0
	if data.get("keywords", []).has("stalwart"):
		score += 60.0
	for effect_group in [data.get("effects", []), data.get("on_play", [])]:
		for effect in effect_group:
			var amount := maxi(1, int(effect.get("amount", 1)))
			match String(effect.get("type", "")):
				"damage_enemy_player":
					score += float(amount * 120)
				"damage_all_enemy_units", "damage_all_enemy_plated", "damage_enemy_unit", "damage_enemy_plated":
					score += float(amount * 20)
				"return_enemy_plated_unit", "destroy_enemy_unit":
					if not state.player.plated.is_empty():
						score += 50.0
				"draw", "search", "look_and_take":
					score += float(amount * 3)
	return score


func _ai_play_best_hand_card(state: Dictionary) -> bool:
	var best_action: Dictionary = {}
	var best_score := -INF
	for hand_index in range(state.opponent.hand.size()):
		var action := _ai_hand_action(state, hand_index)
		if action.is_empty():
			continue
		var score := float(action.get("score", 0.0))
		if score > best_score:
			best_score = score
			best_action = action
	if best_action.is_empty():
		return false
	return _ai_execute_hand_action(state, best_action)


func _ai_play_lookahead_hand_card(state: Dictionary) -> bool:
	var best_action := _ai_best_lookahead_action(state, EXPERT_LOOKAHEAD_DEPTH)
	if best_action.is_empty() or float(best_action.get("lookahead_score", 0.0)) <= EXPERT_MIN_PLAY_GAIN:
		return false
	return _ai_execute_hand_action(state, best_action)


func _ai_best_lookahead_action(state: Dictionary, depth: int) -> Dictionary:
	var baseline := _ai_position_value(state)
	var best_action: Dictionary = {}
	var best_score := 0.0
	for hand_index in range(state.opponent.hand.size()):
		var action := _ai_hand_action(state, hand_index)
		if action.is_empty():
			continue
		var simulated_state: Dictionary = state.duplicate(true)
		var saved_rng_state := rng.state
		var played := _ai_execute_hand_action(simulated_state, action)
		if played:
			_ai_resolve_predicted_reaction(simulated_state)
		var score := -INF
		if played:
			score = _ai_position_value(simulated_state) - baseline
			score -= _expert_overextension_penalty(state, action)
			score += float(action.get("score", 0.0)) * 0.015
			if depth > 1 and not bool(simulated_state.game_over) and simulated_state.get("pending_reaction", {}).is_empty():
				var follow_up := _ai_best_lookahead_action(simulated_state, depth - 1)
				score += maxf(0.0, float(follow_up.get("lookahead_score", 0.0))) * 0.65
		rng.state = saved_rng_state
		if score > best_score:
			best_score = score
			best_action = action.duplicate(true)
			best_action.lookahead_score = score
	return best_action


func _ai_resolve_predicted_reaction(state: Dictionary) -> void:
	if state.get("pending_reaction", {}).is_empty():
		return
	var eligible := reaction_hand_indices(state)
	resolve_reaction(state, int(eligible[0]) if not eligible.is_empty() else -1, false)


func _ai_execute_hand_action(state: Dictionary, action: Dictionary) -> bool:
	var hand_index := int(action.hand_index)
	match String(action.action_kind):
		"environment":
			return _play_environment(state, "opponent", hand_index)
		"meal":
			return _serve_meal(state, "opponent", hand_index, action.get("recipe_units", []), String(action.get("destination", "plated")))
		"ingredient":
			return _play_ingredient(state, "opponent", hand_index, String(action.destination))
		"spice":
			return _play_spice(state, "opponent", hand_index, int(action.target_instance_id))
		"tool":
			return _play_tool(state, "opponent", hand_index)
		"chef":
			return _play_chef(state, "opponent", hand_index)
	return false


func _ai_hand_action(state: Dictionary, hand_index: int) -> Dictionary:
	var card_id := String(state.opponent.hand[hand_index])
	var data := card(card_id)
	var card_type := String(data.get("card_type", ""))
	var base := {
		"hand_index": hand_index,
		"card_id": card_id,
		"action_kind": card_type,
		"score": 0.0
	}
	var deck_demand := _ai_card_deck_demand(data)
	if deck_demand > 0:
		var deck_cards: int = state.opponent.deck.size()
		# Do not voluntarily consume the last cards in the deck. Keeping a small
		# reserve also prevents chained draw/search cards from emptying it in one turn.
		if deck_cards <= AI_DECK_RESERVE and deck_demand >= deck_cards:
			return {}
		base.score = -float(maxi(0, AI_DECK_RESERVE + deck_demand - deck_cards)) * 24.0
	match card_type:
		"environment":
			base.score += 38.0 if String(state.opponent.environment) == "" else 10.0
			return base
		"meal":
			if not _can_serve_meal(state.opponent):
				return {}
			var recipe := _effective_recipe(state, "opponent", data)
			var recipe_units := _find_low_value_recipe_ingredients(state.opponent, recipe) if _ai_level(state) >= 2 else _find_recipe_ingredients(state.opponent, recipe)
			var required_meal := String(data.get("required_meal_archetype", ""))
			if recipe_units.is_empty() or (required_meal != "" and _find_recipe_meal(state.opponent, required_meal).is_empty()):
				return {}
			var destination := _ai_deployment_zone(state, "meal")
			var capacity := PLATED_SLOTS if destination == "plated" else PREP_SLOTS
			if state.opponent[destination].size() >= capacity and not _recipe_uses_zone_unit(state.opponent, recipe_units, destination):
				return {}
			base.recipe_units = recipe_units
			base.destination = destination
			base.score += 90.0 + float(int(data.get("attack", 0)) * 3 + int(data.get("health", 0))) + _ai_card_effect_value(data)
			if _ai_level(state) >= 2:
				base.score -= float(_unit_ids_board_value(state.opponent, recipe_units)) * 0.35
			return base
		"ingredient":
			var destination := _ai_deployment_zone(state, "ingredient")
			var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
			if state.opponent[destination].size() >= capacity:
				return {}
			base.destination = destination
			base.score += 45.0 + float(int(data.get("attack", 0)) + int(data.get("health", 0))) + _ai_card_effect_value(data)
			return base
		"spice":
			var target := _best_unspiced_unit(state.opponent)
			if target.is_empty():
				return {}
			base.target_instance_id = int(target.instance_id)
			base.score += 58.0 + float(int(target.attack) * 2 + int(data.get("attack_bonus", 0)) * 5 + int(data.get("health_bonus", 0)) * 4)
			return base
		"tool":
			if bool(state.opponent.items_disabled) or state.opponent.hand.size() - 1 < int(data.get("discard_cost", 0)):
				return {}
			base.score += 68.0 + _ai_card_effect_value(data) - float(int(data.get("discard_cost", 0)) * 8)
			return base
		"chef":
			if bool(state.opponent.chef_used) or bool(state.opponent.chefs_disabled):
				return {}
			base.score += 72.0 + _ai_card_effect_value(data)
			return base
	return {}


func _ai_card_deck_demand(data: Dictionary) -> int:
	var demand := 0
	for effect_group in [data.get("effects", []), data.get("on_play", [])]:
		for effect in effect_group:
			var effect_type := String(effect.get("type", ""))
			if effect_type in ["draw", "search", "look_and_take", "discard_hand_then_draw", "discard_hand_then_draw_if_any"]:
				demand += maxi(1, int(effect.get("amount", 1)))
			elif effect_type == "discard_top":
				demand += 1
	return demand


func _ai_card_effect_value(data: Dictionary) -> float:
	var value := 0.0
	for effect_group in [data.get("effects", []), data.get("on_play", []), data.get("on_attack", [])]:
		for effect in effect_group:
			var amount := int(effect.get("amount", 1))
			match String(effect.get("type", "")):
				"draw", "search", "look_and_take", "recover":
					value += 10.0 * amount
				"damage_enemy_player", "damage_enemy_unit", "damage_enemy_prep", "damage_all_enemy_units", "damage_all_enemy_plated":
					value += 8.0 * amount
				"heal_player", "heal_unit", "heal_all_friendly_units":
					value += 5.0 * amount
				"buff_self", "buff_friendly_unit", "buff_friendly_plated":
					value += float(int(effect.get("attack", 0)) * 5 + int(effect.get("health", 0)) * 4)
	return value


func _ai_position_value(state: Dictionary) -> float:
	if bool(state.get("game_over", false)):
		return 100000.0 if String(state.get("winner", "")) == "opponent" else -100000.0
	var value := float(int(state.opponent.life) - int(state.player.life)) * 11.0
	value += _ai_board_value(state.opponent)
	value -= _ai_board_value(state.player)
	for card_id in state.opponent.hand:
		value += _ai_card_hold_value(String(card_id)) * 0.42
	for card_id in state.player.hand:
		value -= _ai_card_hold_value(String(card_id)) * 0.5
	value += _ai_environment_value(String(state.opponent.environment))
	value -= _ai_environment_value(String(state.player.environment))
	value -= float(int(state.opponent.fatigue)) * 5.0
	value += float(int(state.player.fatigue)) * 5.0
	# Expert knows the next two opposing draws. This gives its search a real
	# information advantage without valuing every unseen card as immediately live.
	if _ai_level(state) >= 4:
		for offset in range(1, mini(2, state.player.deck.size()) + 1):
			value -= _ai_card_hold_value(String(state.player.deck[-offset])) * (0.12 / float(offset))
	return value


func _ai_board_value(combatant: Dictionary) -> float:
	var value := 0.0
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			var unit_value := float(int(unit.attack) * 4 + int(unit.health) * 3)
			unit_value += 6.0 if zone_name == "plated" else 2.0
			if bool(unit.get("ready", false)):
				unit_value += float(int(unit.attack)) * 1.5
			unit_value += _ai_card_effect_value(card(String(unit.card_id))) * 0.18
			value += unit_value
	return value


func _ai_card_hold_value(card_id: String) -> float:
	var data := card(card_id)
	if data.is_empty():
		return 0.0
	var value := 5.0 + float(int(data.get("attack", 0)) * 2 + int(data.get("health", 0)) * 1.5)
	value += _ai_card_effect_value(data) * 0.45
	match String(data.get("card_type", "")):
		"meal":
			value += 9.0
		"chef", "tool":
			value += 6.0
		"environment":
			value += _ai_environment_value(card_id)
	if not data.get("hand_trap", {}).is_empty() or not data.get("hand_trigger", {}).is_empty():
		value += 12.0
	return value


func _ai_lowest_value_hand_index(hand: Array) -> int:
	var best_index := 0
	var best_value := INF
	for hand_index in range(hand.size()):
		var value := _ai_card_hold_value(String(hand[hand_index]))
		if value < best_value:
			best_value = value
			best_index = hand_index
	return best_index


func _ai_environment_value(card_id: String) -> float:
	if card_id == "":
		return 0.0
	var data := card(card_id)
	return float(
		int(data.get("meal_attack_bonus", 0)) * 7
		+ int(data.get("meal_health_bonus", 0)) * 5
		+ int(data.get("ingredient_growth", 0)) * 9
	) + _ai_card_effect_value(data) * 0.25


func _expert_overextension_penalty(state: Dictionary, action: Dictionary) -> float:
	var action_kind := String(action.get("action_kind", ""))
	if action_kind == "environment":
		var current_id := String(state.opponent.environment)
		var new_id := String(action.get("card_id", ""))
		if current_id == new_id:
			return 100.0
		if current_id != "" and _ai_environment_value(new_id) <= _ai_environment_value(current_id) + 2.0:
			return 35.0
	if action_kind not in ["ingredient", "meal"]:
		return 0.0
	var board_count: int = state.opponent.prep.size() + state.opponent.plated.size()
	if board_count < 3:
		return 0.0
	var sweep_damage := _expert_known_sweep_damage(state)
	if sweep_damage <= 0:
		return 0.0
	var exposed_units := 0
	for zone_name in ["prep", "plated"]:
		for unit in state.opponent[zone_name]:
			if int(unit.health) <= sweep_damage:
				exposed_units += 1
	return float(8 + exposed_units * 7)


func _expert_known_sweep_damage(state: Dictionary) -> int:
	var known_cards: Array[String] = []
	for card_id in state.player.hand:
		known_cards.append(String(card_id))
	if _ai_level(state) >= 4:
		for offset in range(1, mini(2, state.player.deck.size()) + 1):
			known_cards.append(String(state.player.deck[-offset]))
	var result := 0
	for card_id in known_cards:
		var data := card(card_id)
		for effect_group in [data.get("effects", []), data.get("on_play", []), data.get("on_attack", [])]:
			for effect in effect_group:
				if String(effect.get("type", "")) in ["damage_all_enemy_units", "damage_all_enemy_plated", "damage_all_plated_units"]:
					result = maxi(result, int(effect.get("amount", 0)))
	return result


func _find_low_value_recipe_ingredients(combatant: Dictionary, recipe: Array) -> Array:
	var requirements := recipe.duplicate()
	requirements.sort_custom(func(a, b) -> bool: return String(a) != "any" and String(b) == "any")
	var result: Array = []
	var used: Dictionary = {}
	for requirement in requirements:
		var best: Dictionary = {}
		var best_value := 999999
		for zone_name in ["prep", "plated"]:
			for ingredient in combatant[zone_name]:
				var instance_id := int(ingredient.instance_id)
				if used.has(instance_id) or String(ingredient.card_type) != "ingredient" or not _ingredient_is_recipe_ready(combatant, ingredient):
					continue
				if not _ingredient_matches_requirement(card(String(ingredient.card_id)), String(requirement)):
					continue
				var board_value := int(ingredient.attack) + int(ingredient.health)
				if board_value < best_value:
					best_value = board_value
					best = ingredient
		if best.is_empty():
			return []
		result.append(int(best.instance_id))
		used[int(best.instance_id)] = true
	return result


func _recipe_uses_zone_unit(combatant: Dictionary, recipe_units: Array, zone_name: String) -> bool:
	for instance_id in recipe_units:
		if not _find_unit_in_zone(combatant, zone_name, int(instance_id)).is_empty():
			return true
	return false


func _unit_ids_board_value(combatant: Dictionary, instance_ids: Array) -> int:
	var result := 0
	for instance_id in instance_ids:
		var unit := _find_unit(combatant, int(instance_id))
		if not unit.is_empty():
			result += int(unit.attack) + int(unit.health)
	return result


func _best_unspiced_unit(combatant: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -999999
	for zone_name in ["plated", "prep"]:
		for unit in combatant[zone_name]:
			if not unit.get("spices", []).is_empty():
				continue
			var score := int(unit.attack) * 3 + int(unit.health) + (8 if zone_name == "plated" else 0)
			if score > best_score:
				best_score = score
				best = unit
	return best


func _ai_activate_one_ability(state: Dictionary) -> bool:
	for zone_name in ["plated", "prep"]:
		for source in state.opponent[zone_name].duplicate():
			for ability in card(String(source.card_id)).get("abilities", []):
				if String(ability.get("timing", "")) != "activated":
					continue
				var active_zone := String(ability.get("active_zone", ""))
				if active_zone != "" and active_zone != zone_name:
					continue
				var ability_id := String(ability.get("id", "activated"))
				if source.get("used_abilities", []).has(ability_id):
					continue
				var target_id := -1
				if _ability_needs_target(ability):
					target_id = _best_ability_target_id(state, source, ability) if _ai_level(state) > 0 else _first_ability_target_id(state, "opponent", source, ability.get("target", {}))
					if target_id < 0:
						continue
				_resolve_activated_ability_for_side(state, "opponent", int(source.instance_id), ability, target_id, true)
				return true
	return false


func _ai_attack_ids(state: Dictionary) -> Array[int]:
	var attackers: Array[Dictionary] = []
	for unit in state.opponent.plated:
		attackers.append(unit)
	for unit in state.opponent.prep:
		if bool(card(String(unit.card_id)).get("can_attack_from_prep", false)):
			attackers.append(unit)
	if _ai_level(state) >= 2:
		attackers.sort_custom(func(a, b) -> bool: return int(a.attack) > int(b.attack))
	var result: Array[int] = []
	for unit in attackers:
		if _ai_should_attack(state, unit):
			result.append(int(unit.instance_id))
	return result


func _ai_attack_with_unit(state: Dictionary, unit: Dictionary) -> void:
	unit.ready = false
	var target := {} if _unit_has_keyword(unit, "stalwart") else _ai_attack_target(state, unit)
	var unit_data := card(String(unit.card_id))
	var defer_on_attack_animation := bool(unit_data.get("on_attack_animation_after_combat", false))
	var on_attack_animation_start_id := int(state.get("next_animation_event_id", 1))
	_queue_animation_event(state, "attack", {
		"side": "opponent",
		"source_instance_id": int(unit.instance_id),
		"target_kind": "chef" if target.is_empty() else "unit",
		"target_side": "player",
		"target_instance_id": -1 if target.is_empty() else int(target.instance_id)
	}, 0)
	# Keep the attack event in front; only animation events produced by the on-attack effect are deferred.
	on_attack_animation_start_id = int(state.get("next_animation_event_id", 1))
	if target.is_empty():
		_resolve_effects(state, "opponent", unit_data.get("on_attack", []), unit)
		var deferred_direct_events: Array[Dictionary] = []
		if defer_on_attack_animation:
			deferred_direct_events = _take_animation_events_from(state, on_attack_animation_start_id)
		_deal_chef_damage(state, "player", int(unit.attack), "opponent", true)
		if not state.get("pending_reaction", {}).is_empty():
			_append_animation_events(state, deferred_direct_events)
			return
		if int(unit.attack) > 0:
			_resolve_effects(state, "opponent", unit_data.get("on_combat_damage_to_chef", []), unit)
		_log(state, "%s hits you for %d." % [unit.name, unit.attack])
		_append_animation_events(state, deferred_direct_events)
	else:
		_resolve_effects(state, "opponent", unit_data.get("on_attack", []), unit)
		var deferred_battle_events: Array[Dictionary] = []
		if defer_on_attack_animation:
			deferred_battle_events = _take_animation_events_from(state, on_attack_animation_start_id)
		_resolve_unit_battle(state, "opponent", unit, target)
		_append_animation_events(state, deferred_battle_events)
	_check_game_over(state)


func _ai_level(state: Dictionary) -> int:
	match String(state.get("ai_difficulty", "easy")):
		"expert":
			return 4
		"hard":
			return 3
		"medium":
			return 2
	return 1


func _ai_is_aggressive(state: Dictionary) -> bool:
	return _ai_profile(state) in ["pressure", "aggressive"]


func _ai_profile(state: Dictionary) -> String:
	return String(state.get("opponent", {}).get("ai_profile", state.get("ai_personality", "defensive")))


func _ai_policy(state: Dictionary) -> String:
	return String(state.get("opponent", {}).get("ai_policy", AI_POLICY_PRODUCTION))


func _ai_profile_label(state: Dictionary) -> String:
	match _ai_profile(state):
		"pressure":
			return "aggressive pressure"
		"value":
			return "patient value"
	return "defensive positioning"


func _ai_deployment_zone(state: Dictionary, _card_type: String) -> String:
	if _ai_policy(state) == AI_POLICY_FACE_RACE:
		return "plated" if state.opponent.plated.size() < PLATED_SLOTS else "prep"
	if _ai_profile(state) == "defensive" and _ai_faces_lethal_next_turn(state):
		return "plated" if state.opponent.plated.size() < PLATED_SLOTS else "prep"
	var preferred_zone := "plated" if _ai_is_aggressive(state) else "prep"
	var fallback_zone := "prep" if preferred_zone == "plated" else "plated"
	var preferred_capacity := PLATED_SLOTS if preferred_zone == "plated" else PREP_SLOTS
	if state.opponent[preferred_zone].size() < preferred_capacity:
		return preferred_zone
	# Defensive rivals still put a Meal in Plated when Prep is full, ensuring
	# they can establish a defender rather than refusing to develop entirely.
	var fallback_capacity := PLATED_SLOTS if fallback_zone == "plated" else PREP_SLOTS
	return fallback_zone if state.opponent[fallback_zone].size() < fallback_capacity else preferred_zone


func _ai_should_move_to_plated(state: Dictionary) -> bool:
	if bool(state.opponent.zone_move_used) or state.opponent.plated.size() >= PLATED_SLOTS or state.opponent.prep.is_empty():
		return false
	if _ai_policy(state) == AI_POLICY_FACE_RACE:
		return true
	if _ai_is_aggressive(state):
		return true
	if _ai_faces_lethal_next_turn(state):
		return true
	# Defensive rivals establish a blocker first, then commit a second attacker
	# when the board is stable instead of indefinitely holding every threat back.
	return state.opponent.plated.is_empty() or (
		state.opponent.plated.size() < 2
		and state.player.plated.size() <= state.opponent.plated.size()
	)


func _ai_should_attack(state: Dictionary, attacker: Dictionary) -> bool:
	if _ai_is_aggressive(state):
		return true
	if state.player.plated.is_empty():
		# An undefended Chef is free pressure; defensive rivals should take it.
		return true
	var target := _ai_attack_target(state, attacker)
	if target.is_empty():
		return false
	# Favor clean trades, but trade up into an equal-or-larger opposing threat
	# rather than leaving it unchecked just to preserve the attacker.
	var can_ko := int(attacker.attack) >= int(target.health)
	var survives := int(attacker.health) > int(target.attack)
	var favorable_trade := int(target.attack) >= int(attacker.attack)
	return can_ko and (survives or favorable_trade)


func _ai_unit_to_plate(state: Dictionary) -> Dictionary:
	if state.opponent.prep.is_empty() or _ai_level(state) == 0:
		return state.opponent.prep[0] if not state.opponent.prep.is_empty() else {}
	var best: Dictionary = state.opponent.prep[0]
	var best_score := -999999
	var needs_emergency_blocker := _ai_profile(state) == "defensive" and _ai_faces_lethal_next_turn(state)
	for unit in state.opponent.prep:
		var score := int(unit.attack) + int(unit.health) * 5 if needs_emergency_blocker else int(unit.attack) * 4 + int(unit.health)
		if String(unit.card_type) == "meal":
			score += 12
		if needs_emergency_blocker and (_unit_has_keyword(unit, "taunt") or _unit_has_keyword(unit, "bodyguard")):
			score += 18
		if bool(card(String(unit.card_id)).get("can_attack_from_prep", false)):
			score -= 8
		if score > best_score:
			best_score = score
			best = unit
	return best


func _best_ability_target_id(state: Dictionary, source: Dictionary, ability: Dictionary) -> int:
	var target_spec: Dictionary = ability.get("target", {})
	var friendly := String(target_spec.get("side", "enemy")) == "friendly"
	var target_side := "opponent" if friendly else "player"
	var best_id := -1
	var best_score := -999999
	var effects: Array = ability.get("effects", [])
	for zone_name in ["plated", "prep"]:
		for target in state[target_side][zone_name]:
			if not _ability_target_is_valid(state, "opponent", source, int(target.instance_id), target_spec):
				continue
			var score := 0
			for effect in effects:
				var effect_type := String(effect.get("type", ""))
				var amount := int(effect.get("amount", 0))
				if effect_type in ["heal_unit", "heal_self"]:
					score += (int(target.max_health) - int(target.health)) * 12
				elif effect_type in ["damage_enemy_unit", "damage_enemy_plated", "damage_enemy_prep"]:
					score += int(target.attack) * 5 + (80 if int(target.health) <= amount else -int(target.health))
				elif effect_type in ["buff_friendly_unit", "buff_friendly_plated"]:
					score += int(target.attack) * 4 + (10 if zone_name == "plated" else 0)
			if score > best_score:
				best_score = score
				best_id = int(target.instance_id)
	return best_id


func _ai_attack_target(state: Dictionary, attacker: Dictionary) -> Dictionary:
	if state.player.plated.is_empty():
		return {}
	var candidates: Array[Dictionary] = _plated_units_with_keyword(state.player, "taunt")
	if candidates.is_empty():
		for plated_unit in state.player.plated:
			candidates.append(plated_unit)
	if _ai_policy(state) == AI_POLICY_FACE_RACE:
		var cheapest: Dictionary = candidates[0]
		for target in candidates:
			if int(target.health) < int(cheapest.health) or (
				int(target.health) == int(cheapest.health)
				and int(target.attack) < int(cheapest.attack)
			):
				cheapest = target
		return cheapest
	if _ai_level(state) == 0:
		return _weakest_plated_unit(state.player)
	var best: Dictionary = candidates[0]
	var best_score := -999999
	for target in candidates:
		var can_ko := int(attacker.attack) >= int(target.health)
		var survives := int(attacker.health) > int(target.attack)
		var score := int(target.attack) * 7 - int(target.health)
		if can_ko:
			score += 100
		if survives:
			score += 20
		if _ai_level(state) >= 2 and not can_ko and int(attacker.health) <= int(target.attack):
			score -= 55
		if score > best_score:
			best_score = score
			best = target
	return best


func _ai_faces_lethal_next_turn(state: Dictionary) -> bool:
	return _ai_estimated_incoming_face_damage(state) >= int(state.opponent.life)


func _ai_estimated_incoming_face_damage(state: Dictionary) -> int:
	var blockable_attacks: Array[int] = []
	var unavoidable_damage := 0
	for unit in state.player.plated:
		var attack := maxi(0, int(unit.get("attack", 0)))
		if _unit_has_keyword(unit, "stalwart"):
			unavoidable_damage += attack
		else:
			blockable_attacks.append(attack)
	for unit in state.player.prep:
		if not bool(card(String(unit.get("card_id", ""))).get("can_attack_from_prep", false)):
			continue
		var prep_attack := maxi(0, int(unit.get("attack", 0)))
		if _unit_has_keyword(unit, "stalwart"):
			unavoidable_damage += prep_attack
		else:
			blockable_attacks.append(prep_attack)
	# This intentionally errs toward defense: each Plated blocker is credited with
	# absorbing one of the opponent's smallest attacks, preserving their largest
	# threats for face in the worst plausible attack order.
	blockable_attacks.sort()
	var blocked_attacks := mini(state.opponent.plated.size(), blockable_attacks.size())
	var estimated_damage := unavoidable_damage
	for index in range(blocked_attacks, blockable_attacks.size()):
		estimated_damage += int(blockable_attacks[index])
	return estimated_damage


func _ai_turn(state: Dictionary, start_turn: bool = true) -> void:
	if start_turn:
		_start_turn(state, "opponent")
	if bool(state.game_over):
		return
	var safety := 30
	while safety > 0 and _ai_play_one_hand_card(state):
		safety -= 1
		if not state.get("pending_reaction", {}).is_empty():
			return
	safety = 20
	while safety > 0 and _ai_activate_one_ability(state):
		safety -= 1
		if not state.get("pending_reaction", {}).is_empty():
			return
	if _ai_should_move_to_plated(state):
		var moved: Dictionary = _ai_unit_to_plate(state)
		state.opponent.prep.erase(moved)
		moved.ready = true
		state.opponent.plated.append(moved)
		state.opponent.zone_move_used = true
		_queue_animation_event(state, "move", {
			"side": "opponent",
			"instance_id": int(moved.instance_id),
			"card_id": String(moved.card_id),
			"from": "prep",
			"to": "plated"
		}, _next_animation_group(state))
		_resolve_effects(state, "opponent", card(String(moved.card_id)).get("on_move_to_plated", []), moved)
		_refresh_stat_auras(state)
	for attacker_id in _ai_attack_ids(state):
		var unit := _find_unit(state.opponent, int(attacker_id))
		if unit.is_empty():
			continue
		if not bool(unit.ready) or bool(state.game_over):
			continue
		_ai_attack_with_unit(state, unit)
		if not state.get("pending_reaction", {}).is_empty():
			return
	state.opponent.chefs_disabled = false
	state.opponent.items_disabled = false
	_resolve_end_turn_triggers(state, "opponent")
	_set_defense_positions(state, "opponent")
	_clear_temporary_buffs(state.opponent)


func _resolve_end_turn_triggers(state: Dictionary, side: String) -> void:
	for zone_name in ["prep", "plated"]:
		for unit in state[side][zone_name].duplicate():
			var data := card(String(unit.card_id))
			var required_zone := String(data.get("end_turn_zone", ""))
			if required_zone != "" and required_zone != zone_name:
				continue
			_resolve_effects(state, side, data.get("on_end_turn", []), unit)


func _resolve_unit_battle(state: Dictionary, attacker_side: String, attacker: Dictionary, defender: Dictionary) -> void:
	var defender_side := "opponent" if attacker_side == "player" else "player"
	var attack_value := int(attacker.attack)
	var defense_value := int(defender.attack)
	var defender_health_before := int(defender.health)
	var overflow_damage := maxi(0, attack_value - defender_health_before)
	if bool(defender.get("defending", false)) and not _unit_has_keyword(attacker, "piercing"):
		overflow_damage = 0
	var combat_group_id := _next_animation_group(state)
	if attack_value > 0:
		_queue_animation_event(state, "damage", {
			"source_side": attacker_side,
			"source_instance_id": int(attacker.instance_id),
			"target_kind": "unit",
			"target_side": defender_side,
			"target_instance_id": int(defender.instance_id),
			"amount": attack_value,
			"combat": true
		}, combat_group_id)
	if defense_value > 0:
		_queue_animation_event(state, "damage", {
			"source_side": defender_side,
			"source_instance_id": int(defender.instance_id),
			"target_kind": "unit",
			"target_side": attacker_side,
			"target_instance_id": int(attacker.instance_id),
			"amount": defense_value,
			"combat": true
		}, combat_group_id)
	defender.health -= attack_value
	attacker.health -= defense_value
	_deal_chef_damage(state, defender_side, overflow_damage, attacker_side, true, combat_group_id)
	if overflow_damage > 0:
		_resolve_effects(state, attacker_side, card(String(attacker.card_id)).get("on_combat_damage_to_chef", []), attacker, -1, false)
	if attack_value > 0:
		_resolve_effects(state, defender_side, card(String(defender.card_id)).get("on_damaged", []), defender, -1, false)
	if defense_value > 0:
		_resolve_effects(state, attacker_side, card(String(attacker.card_id)).get("on_damaged", []), attacker, -1, false)
	var overflow_text := ""
	if overflow_damage > 0:
		overflow_text = " and pierces for %d" % overflow_damage if bool(defender.get("defending", false)) else " and deals %d overflow damage" % overflow_damage
	_log(state, "%s battles %s%s." % [attacker.name, defender.name, overflow_text])
	_remove_defeated(state, attacker_side, defender_side, defender)
	_remove_defeated(state, defender_side, attacker_side, attacker)
	_refresh_stat_auras(state)


func _set_defense_positions(state: Dictionary, side: String) -> void:
	var group_id := -1
	for unit in state[side].plated:
		var should_defend := bool(unit.get("ready", false))
		var was_defending := bool(unit.get("defending", false))
		unit.defending = should_defend
		if should_defend and not was_defending:
			if group_id < 0:
				group_id = _next_animation_group(state)
			_queue_animation_event(state, "defense_position", {
				"side": side,
				"instance_id": int(unit.instance_id),
				"card_id": String(unit.card_id),
				"defending": true
			}, group_id)
			_log(state, "%s takes a defensive position." % unit.name)


func _resolve_effects(
	state: Dictionary,
	side: String,
	effects: Array,
	source: Dictionary = {},
	target_instance_id: int = -1,
	refresh_after: bool = true
) -> void:
	var enemy_side := "opponent" if side == "player" else "player"
	for effect_index in range(effects.size()):
		var effect: Dictionary = effects[effect_index]
		if String(effect.get("type", "")) == "revive" and state[side].prep.size() >= PREP_SLOTS:
			_log(state, "%s has no room in Prep for a revived unit." % _side_name(side))
			continue
		if side == "player" and target_instance_id < 0 and String(effect.get("type", "")) in ["recover", "recycle", "revive"]:
			var discard_candidates := _valid_discard_indices(state[side], effect)
			if discard_candidates.is_empty():
				_log(state, "%s has no eligible cards in the discard pile." % _effect_label(effect))
				continue
			var required_count := mini(int(effect.get("amount", 1)), discard_candidates.size())
			state.pending_choice = {
				"choice_kind": "discard",
				"side": side,
				"effect": effect.duplicate(true),
				"source_instance_id": int(source.get("instance_id", -1)),
				"remaining_effects": effects.slice(effect_index + 1),
				"selected_indices": [],
				"required": required_count,
				"prompt": "Choose %d card%s from your discard pile." % [required_count, "" if required_count == 1 else "s"]
			}
			_clear_selections(state)
			_message(state, String(state.pending_choice.prompt))
			return
		if side == "player" and target_instance_id < 0 and String(effect.get("type", "")) == "deploy_enemy_hand_unit":
			var hand_candidates := _valid_opponent_hand_indices(state, side, effect)
			if hand_candidates.is_empty():
				_log(state, "Tongs finds no unit that can enter the opposing field.")
				continue
			state.pending_choice = {
				"choice_kind": "opponent_hand",
				"side": side,
				"effect": effect.duplicate(true),
				"source_instance_id": int(source.get("instance_id", -1)),
				"remaining_effects": effects.slice(effect_index + 1),
				"prompt": "The opponent reveals their hand. Choose a unit to put onto their field."
			}
			_clear_selections(state)
			_message(state, String(state.pending_choice.prompt))
			return
		if side == "player" and target_instance_id < 0 and _effect_needs_board_choice(effect):
			var valid_targets := _valid_board_target_ids(state, side, effect)
			if valid_targets.is_empty():
				_log(state, "%s has no valid target." % _effect_label(effect))
				continue
			state.pending_choice = {
				"choice_kind": "board",
				"side": side,
				"effect": effect.duplicate(true),
				"source_instance_id": int(source.get("instance_id", -1)),
				"remaining_effects": effects.slice(effect_index + 1),
				"prompt": _board_choice_prompt(effect)
			}
			_clear_selections(state)
			_message(state, String(state.pending_choice.prompt))
			return
		if bool(effect.get("first_time_only", false)) and not source.is_empty():
			var trigger_key := String(effect.get("type", "effect"))
			var triggered_effects: Array = source.get("triggered_effects", [])
			if triggered_effects.has(trigger_key):
				continue
			triggered_effects.append(trigger_key)
			source.triggered_effects = triggered_effects
		if bool(effect.get("once_per_turn", false)) and not source.is_empty():
			var turn_trigger_key := "trigger_%s" % String(effect.get("type", "effect"))
			var used_abilities: Array = source.get("used_abilities", [])
			if used_abilities.has(turn_trigger_key):
				continue
			used_abilities.append(turn_trigger_key)
			source.used_abilities = used_abilities
		var amount := int(effect.get("amount", 0))
		var effect_type := String(effect.get("type", ""))
		var multi_hit_group_id := -1
		if effect_type in ["damage_all_enemy_units", "damage_all_enemy_plated", "damage_all_plated_units", "heal_all_friendly_units"]:
			multi_hit_group_id = int(state.get("active_animation_group_id", 0))
			if multi_hit_group_id <= 0:
				multi_hit_group_id = _next_animation_group(state)
		match effect_type:
			"draw":
				for unused in range(amount):
					_draw(state, side)
			"heal_player":
				var player_healing := _healing_amount(state, side, amount)
				var life_before := int(state[side].life)
				state[side].life = mini(STARTING_LIFE, int(state[side].life) + player_healing)
				_queue_heal_event(state, side, "chef", -1, int(state[side].life) - life_before)
			"damage_enemy_player":
				_deal_chef_damage(state, enemy_side, amount, side, false)
			"discard_hand":
				for discarded_card in state[side].hand:
					state[side].discard.append(String(discarded_card))
				state[side].hand.clear()
			"shuffle_both_hands_then_draw":
				# Chef Duff follows Pokémon TCG's Judge pattern: both hands are
				# shuffled away before either player receives their replacement cards.
				for affected_side in [side, enemy_side]:
					state[affected_side].deck.append_array(state[affected_side].hand)
					state[affected_side].hand.clear()
					_shuffle(state[affected_side].deck)
				for affected_side in [side, enemy_side]:
					for unused in range(amount):
						_draw(state, affected_side)
			"discard_hand_then_draw":
				for discarded_card in state[side].hand:
					state[side].discard.append(String(discarded_card))
				state[side].hand.clear()
				for unused in range(amount):
					_draw(state, side)
			"discard_hand_then_draw_if_any":
				var discarded_count: int = state[side].hand.size()
				for discarded_card in state[side].hand:
					state[side].discard.append(String(discarded_card))
				state[side].hand.clear()
				if discarded_count > 0:
					for unused in range(amount):
						_draw(state, side)
			"discard_top":
				if not state[side].deck.is_empty():
					var discarded_id := String(state[side].deck.pop_back())
					state[side].discard.append(discarded_id)
					_log(state, "%s discards %s from the top of the deck." % [_side_name(side), card(discarded_id).get("name", discarded_id)])
			"damage_enemy_prep":
				if not state[enemy_side].prep.is_empty():
					var prep_target: Dictionary = {}
					if String(effect.get("target", "")) == "random":
						prep_target = state[enemy_side].prep[rng.randi_range(0, state[enemy_side].prep.size() - 1)]
					elif target_instance_id >= 0:
						prep_target = _find_unit_in_zone(state[enemy_side], "prep", target_instance_id)
					else:
						prep_target = state[enemy_side].prep[0]
					if not prep_target.is_empty():
						_deal_effect_damage_to_unit(state, side, enemy_side, prep_target, amount, source)
			"damage_all_enemy_units":
				for zone_name in ["prep", "plated"]:
					for unit in state[enemy_side][zone_name].duplicate():
						_deal_effect_damage_to_unit(state, side, enemy_side, unit, amount, source, false, multi_hit_group_id)
				_remove_defeated(state, enemy_side, side, source)
			"damage_all_enemy_plated":
				for unit in state[enemy_side].plated.duplicate():
					_deal_effect_damage_to_unit(state, side, enemy_side, unit, amount, source, false, multi_hit_group_id)
				_remove_defeated(state, enemy_side, side, source)
			"damage_all_plated_units":
				for affected_side in ["player", "opponent"]:
					for unit in state[affected_side].plated.duplicate():
						_deal_effect_damage_to_unit(state, side, affected_side, unit, amount, source, false, multi_hit_group_id)
					_remove_defeated(state, affected_side, side, source)
			"heal_all_friendly_units":
				var group_healing := _healing_amount(state, side, amount)
				for zone_name in ["prep", "plated"]:
					for unit in state[side][zone_name]:
						if bool(effect.get("exclude_self", false)) and not source.is_empty() and int(unit.instance_id) == int(source.instance_id):
							continue
						var health_before := int(unit.health)
						unit.health = mini(int(unit.max_health), int(unit.health) + group_healing)
						_queue_heal_event(state, side, "unit", int(unit.instance_id), int(unit.health) - health_before, multi_hit_group_id)
			"search":
				if String(effect.get("destination", "hand")) == "prep" and state[side].prep.size() >= PREP_SLOTS:
					_log(state, "%s has no room in Prep for the searched Ingredient." % _side_name(side))
				elif side == "player":
					_queue_player_search(state, effect)
				else:
					_search_deck(state, side, effect)
			"look_and_take":
				if side == "player":
					_queue_player_search(state, effect, true)
				else:
					_look_and_take(state, side, effect)
			"deploy_enemy_hand_unit":
				var enemy_hand_candidates := _valid_opponent_hand_indices(state, side, effect)
				if not enemy_hand_candidates.is_empty():
					_deploy_enemy_hand_unit(state, side, int(enemy_hand_candidates[0]))
			"recover":
				_recover_from_discard(state, side, effect)
			"revive":
				_revive_from_discard(state, side, effect)
			"recycle":
				_recycle_from_discard(state, side, amount)
			"draw_for_friendly_archetype":
				var matching_count: int = _count_controlled_archetype(state[side], String(effect.get("archetype", "")))
				if bool(effect.get("exclude_self", false)):
					matching_count = maxi(0, matching_count - 1)
				for unused in range(matching_count):
					_draw(state, side)
			"conditional_draw":
				var controlled_count := _count_controlled_archetype(state[side], String(effect.get("archetype", "")))
				if not source.is_empty():
					controlled_count = maxi(0, controlled_count - 1)
				var draw_amount := int(effect.get("if_met_amount", amount)) if controlled_count >= int(effect.get("other_units_required", 0)) else amount
				for unused in range(draw_amount):
					_draw(state, side)
			"return_enemy_ingredient":
				_return_enemy_ingredient(state, enemy_side, target_instance_id)
			"return_enemy_plated_unit":
				_return_enemy_plated_unit(state, enemy_side, target_instance_id)
			"disable_enemy_chefs_next_turn":
				state[enemy_side].chefs_disabled = true
			"disable_enemy_items_next_turn":
				state[enemy_side].items_disabled = true
			"buff_self":
				if not source.is_empty():
					var attack_bonus := int(effect.get("attack", 0))
					var health_bonus := int(effect.get("health", 0))
					source.attack += attack_bonus
					source.health += health_bonus
					source.max_health += health_bonus
					_queue_buff_event(state, side, source, attack_bonus, health_bonus)
			"buff_self_from_discard_attack":
				if not source.is_empty():
					var total_attack := 0
					var allowed_types: Array = effect.get("card_types", [])
					for discarded_card_id in state[side].discard:
						var discarded_data := card(String(discarded_card_id))
						if not allowed_types.is_empty() and not allowed_types.has(String(discarded_data.get("card_type", ""))):
							continue
						total_attack += int(discarded_data.get("attack", 0))
					var capped_attack := mini(total_attack, int(effect.get("cap", total_attack)))
					source.attack += capped_attack
					_queue_buff_event(state, side, source, capped_attack, 0)
			"buff_friendly_unit":
				var buff_target := _find_unit(state[side], target_instance_id) if target_instance_id >= 0 else _first_friendly_unit(state[side])
				if not buff_target.is_empty():
					var attack_bonus := int(effect.get("attack", 0))
					var health_bonus := int(effect.get("health", 0))
					buff_target.attack += attack_bonus
					buff_target.health += health_bonus
					buff_target.max_health += health_bonus
					_queue_buff_event(state, side, buff_target, attack_bonus, health_bonus)
			"buff_friendly_plated":
				if not state[side].plated.is_empty():
					var plated_buff_target: Dictionary = _find_unit_in_zone(state[side], "plated", target_instance_id) if target_instance_id >= 0 else state[side].plated[0]
					var attack_bonus := int(effect.get("attack", 0))
					plated_buff_target.attack += attack_bonus
					_queue_buff_event(state, side, plated_buff_target, attack_bonus, 0)
					if String(effect.get("duration", "")) == "end_turn":
						plated_buff_target.temporary_attack = int(plated_buff_target.get("temporary_attack", 0)) + attack_bonus
			"heal_unit":
				var heal_target := _find_unit(state[side], target_instance_id) if target_instance_id >= 0 else _most_damaged_friendly_unit(state[side])
				if not heal_target.is_empty():
					var health_before := int(heal_target.health)
					heal_target.health = mini(int(heal_target.max_health), int(heal_target.health) + _healing_amount(state, side, amount))
					_queue_heal_event(state, side, "unit", int(heal_target.instance_id), int(heal_target.health) - health_before)
			"heal_self":
				if not source.is_empty() and not _find_unit(state[side], int(source.get("instance_id", -1))).is_empty():
					var health_before := int(source.health)
					source.health = mini(int(source.max_health), int(source.health) + _healing_amount(state, side, amount))
					_queue_heal_event(state, side, "unit", int(source.instance_id), int(source.health) - health_before)
			"discard_top_then_buff_if_unit":
				if not state[side].deck.is_empty():
					var discarded_id := String(state[side].deck.pop_back())
					state[side].discard.append(discarded_id)
					_log(state, "%s discards %s from the top of the deck." % [_side_name(side), card(discarded_id).get("name", discarded_id)])
					if String(card(discarded_id).get("card_type", "")) in ["ingredient", "meal"] and not source.is_empty():
						var attack_bonus := int(effect.get("attack", 0))
						var health_bonus := int(effect.get("health", 0))
						source.attack += attack_bonus
						source.health += health_bonus
						source.max_health += health_bonus
						_queue_buff_event(state, side, source, attack_bonus, health_bonus)
			"draw_to_hand_size":
				while state[side].hand.size() < amount and not bool(state.game_over):
					_draw(state, side)
			"create_token":
				var token_zone := String(effect.get("zone", "prep"))
				var token_capacity := PREP_SLOTS if token_zone == "prep" else PLATED_SLOTS
				var token_id := String(effect.get("token_id", "token_fresh_ingredient"))
				var token_data := card(token_id)
				if token_zone not in ["prep", "plated"] or token_data.is_empty():
					_log(state, "The token effect has no valid destination or token definition.")
				elif state[side][token_zone].size() >= token_capacity:
					_log(state, "%s has no room for a token in %s." % [_side_name(side), token_zone.capitalize()])
				else:
					var created_token := _make_unit(state, state[side], token_data, token_zone, side)
					created_token.is_token = true
					state[side][token_zone].append(created_token)
					_queue_play_event(state, side, token_id, "token", int(created_token.instance_id))
					_log(state, "%s creates %s in %s." % [_side_name(side), token_data.name, token_zone.capitalize()])
			"fill_prep_with_tokens":
				while state[side].prep.size() < PREP_SLOTS:
					var fill_token_id := String(effect.get("token_id", "token_fresh_ingredient"))
					var fill_token_data := card(fill_token_id)
					var fill_token := _make_unit(state, state[side], fill_token_data, "prep", side)
					fill_token.is_token = true
					state[side].prep.append(fill_token)
					_queue_play_event(state, side, fill_token_id, "token", int(fill_token.instance_id))
			"damage_enemy_unit":
				var any_damage_target := _find_unit(state[enemy_side], target_instance_id) if target_instance_id >= 0 else _first_enemy_unit(state[enemy_side], effect)
				if not any_damage_target.is_empty():
					_deal_effect_damage_to_unit(state, side, enemy_side, any_damage_target, amount, source)
			"sacrifice_friendly_then_damage_all_enemy_units_by_attack":
				var sacrifice_target := _find_unit(state[side], target_instance_id)
				if not sacrifice_target.is_empty() and (source.is_empty() or int(sacrifice_target.instance_id) != int(source.instance_id)):
					var damage_amount := int(sacrifice_target.attack)
					var sacrificed_unit := _remove_unit(state[side], int(sacrifice_target.instance_id))
					_queue_unit_event(state, "sacrifice", side, sacrificed_unit, "ability_cost", _next_animation_group(state))
					_resolve_effects(state, side, card(String(sacrificed_unit.card_id)).get("on_sacrifice", []), sacrificed_unit)
					_discard_unit_attachments(state[side], sacrificed_unit)
					_discard_unit_card(state[side], sacrificed_unit)
					var damage_group_id := _next_animation_group(state)
					for enemy_unit in state[enemy_side].prep.duplicate() + state[enemy_side].plated.duplicate():
						_deal_effect_damage_to_unit(state, side, enemy_side, enemy_unit, damage_amount, source, false, damage_group_id)
					_remove_defeated(state, enemy_side, side, source)
			"destroy_all_plated_units":
				var destroy_group_id := _next_animation_group(state)
				for affected_side in ["player", "opponent"]:
					for plated_unit in state[affected_side].plated.duplicate():
						var destroyed_unit := _remove_unit(state[affected_side], int(plated_unit.instance_id))
						if destroyed_unit.is_empty():
							continue
						_queue_unit_event(state, "destroy", affected_side, destroyed_unit, "card_effect", destroy_group_id)
						_discard_unit_attachments(state[affected_side], destroyed_unit)
						_discard_unit_card(state[affected_side], destroyed_unit)
			"absorb_all_friendly_units":
				if not source.is_empty():
					var absorbed_attack := int(source.get("served_sacrifice_attack", 0))
					var absorbed_health := int(source.get("served_sacrifice_health", 0))
					var absorb_ids: Array[int] = []
					var sacrifice_group_id := _next_animation_group(state)
					for zone_name in ["prep", "plated"]:
						for unit in state[side][zone_name]:
							if int(unit.instance_id) != int(source.instance_id):
								absorb_ids.append(int(unit.instance_id))
					for absorb_id in absorb_ids:
						var absorbed := _remove_unit(state[side], absorb_id)
						if absorbed.is_empty():
							continue
						_queue_unit_event(state, "sacrifice", side, absorbed, "absorb", sacrifice_group_id)
						absorbed_attack += int(absorbed.attack)
						absorbed_health += int(absorbed.max_health)
						_resolve_effects(state, side, card(String(absorbed.card_id)).get("on_sacrifice", []), absorbed)
						_discard_unit_attachments(state[side], absorbed)
						_discard_unit_card(state[side], absorbed)
					source.attack += absorbed_attack
					source.health += absorbed_health
					source.max_health += absorbed_health
					_queue_buff_event(state, side, source, absorbed_attack, absorbed_health)
			"copy_prep_activated_ability":
				var copied_target := _find_unit_in_zone(state[side], "prep", target_instance_id)
				if not copied_target.is_empty():
					var copied_ability := _first_copyable_ability(card(String(copied_target.card_id)))
					if not copied_ability.is_empty():
						if bool(copied_ability.get("cost", {}).get("sacrifice_self", false)) and not source.is_empty():
							var copied_cost_unit := _remove_unit(state[side], int(source.instance_id))
							if not copied_cost_unit.is_empty():
								_queue_unit_event(state, "sacrifice", side, copied_cost_unit, "ability_cost", _next_animation_group(state))
								_resolve_effects(state, side, card(String(copied_cost_unit.card_id)).get("on_sacrifice", []), copied_cost_unit)
								_discard_unit_attachments(state[side], copied_cost_unit)
								_discard_unit_card(state[side], copied_cost_unit)
						_resolve_effects(state, side, copied_ability.get("effects", []), source)
			"move_friendly_to_prep":
				var moving_target := _find_unit_in_zone(state[side], "plated", target_instance_id)
				if not moving_target.is_empty() and state[side].prep.size() < PREP_SLOTS:
					state[side].plated.erase(moving_target)
					moving_target.ready = false
					state[side].prep.append(moving_target)
					_log(state, "%s moves %s to Prep." % [_side_name(side), moving_target.name])
			"switch_friendly_zones":
				var plated_target_id := int(effect.get("plated_instance_id", -1))
				var prep_target_id := target_instance_id
				if side != "player" and plated_target_id < 0 and not state[side].plated.is_empty() and not state[side].prep.is_empty():
					plated_target_id = int(state[side].plated[0].instance_id)
					prep_target_id = int(state[side].prep[0].instance_id)
				var plated_target := _find_unit_in_zone(state[side], "plated", plated_target_id)
				var prep_target := _find_unit_in_zone(state[side], "prep", prep_target_id)
				if not plated_target.is_empty() and not prep_target.is_empty():
					var plated_index: int = state[side].plated.find(plated_target)
					var prep_index: int = state[side].prep.find(prep_target)
					var plated_slot := int(plated_target.get("table_slot", -1))
					var prep_slot := int(prep_target.get("table_slot", -1))
					state[side].plated[plated_index] = prep_target
					state[side].prep[prep_index] = plated_target
					if plated_slot >= 0:
						prep_target.table_slot = plated_slot
					if prep_slot >= 0:
						plated_target.table_slot = prep_slot
					prep_target.ready = not _opening_attack_lock(state, side)
					plated_target.ready = bool(card(String(plated_target.card_id)).get("can_attack_from_prep", false)) and not _opening_attack_lock(state, side)
					var switch_group_id := _next_animation_group(state)
					_queue_animation_event(state, "move", {
						"side": side,
						"instance_id": int(plated_target.instance_id),
						"card_id": String(plated_target.card_id),
						"from": "plated",
						"to": "prep"
					}, switch_group_id)
					_queue_animation_event(state, "move", {
						"side": side,
						"instance_id": int(prep_target.instance_id),
						"card_id": String(prep_target.card_id),
						"from": "prep",
						"to": "plated"
					}, switch_group_id)
					_resolve_effects(state, side, card(String(prep_target.card_id)).get("on_move_to_plated", []), prep_target)
					_log(state, "%s switches %s with %s without using the turn's switch." % [_side_name(side), plated_target.name, prep_target.name])
			"switch_enemy_zones":
				var switched_side := enemy_side
				var enemy_plated_target_id := int(effect.get("plated_instance_id", -1))
				var enemy_prep_target_id := target_instance_id
				if side != "player" and enemy_plated_target_id < 0 and not state[switched_side].plated.is_empty() and not state[switched_side].prep.is_empty():
					enemy_plated_target_id = int(state[switched_side].plated[0].instance_id)
					enemy_prep_target_id = int(state[switched_side].prep[0].instance_id)
				var enemy_plated_target := _find_unit_in_zone(state[switched_side], "plated", enemy_plated_target_id)
				var enemy_prep_target := _find_unit_in_zone(state[switched_side], "prep", enemy_prep_target_id)
				if not enemy_plated_target.is_empty() and not enemy_prep_target.is_empty():
					var enemy_plated_index: int = state[switched_side].plated.find(enemy_plated_target)
					var enemy_prep_index: int = state[switched_side].prep.find(enemy_prep_target)
					var enemy_plated_slot := int(enemy_plated_target.get("table_slot", -1))
					var enemy_prep_slot := int(enemy_prep_target.get("table_slot", -1))
					state[switched_side].plated[enemy_plated_index] = enemy_prep_target
					state[switched_side].prep[enemy_prep_index] = enemy_plated_target
					if enemy_plated_slot >= 0:
						enemy_prep_target.table_slot = enemy_plated_slot
					if enemy_prep_slot >= 0:
						enemy_plated_target.table_slot = enemy_prep_slot
					enemy_prep_target.ready = not _opening_attack_lock(state, switched_side)
					enemy_plated_target.ready = bool(card(String(enemy_plated_target.card_id)).get("can_attack_from_prep", false)) and not _opening_attack_lock(state, switched_side)
					var enemy_switch_group_id := _next_animation_group(state)
					_queue_animation_event(state, "move", {
						"side": switched_side,
						"instance_id": int(enemy_plated_target.instance_id),
						"card_id": String(enemy_plated_target.card_id),
						"from": "plated",
						"to": "prep"
					}, enemy_switch_group_id)
					_queue_animation_event(state, "move", {
						"side": switched_side,
						"instance_id": int(enemy_prep_target.instance_id),
						"card_id": String(enemy_prep_target.card_id),
						"from": "prep",
						"to": "plated"
					}, enemy_switch_group_id)
					_resolve_effects(state, switched_side, card(String(enemy_prep_target.card_id)).get("on_move_to_plated", []), enemy_prep_target)
					_log(state, "%s uses Tongs to switch %s with %s." % [_side_name(side), enemy_plated_target.name, enemy_prep_target.name])
			"swap_attack_health":
				var swap_target := _find_unit(state.player, target_instance_id)
				if swap_target.is_empty():
					swap_target = _find_unit(state.opponent, target_instance_id)
				if not swap_target.is_empty():
					var old_attack := int(swap_target.attack)
					swap_target.attack = int(swap_target.health)
					swap_target.health = old_attack
					swap_target.max_health = maxi(int(swap_target.max_health), int(swap_target.health))
			"remove_enemy_spice":
				var spice_target := _find_unit(state[enemy_side], target_instance_id)
				if not spice_target.is_empty() and not spice_target.get("spices", []).is_empty():
					var removed_spice_id := String(spice_target.spices.pop_back())
					var removed_spice := card(removed_spice_id)
					spice_target.attack -= int(removed_spice.get("attack_bonus", 0))
					spice_target.health -= int(removed_spice.get("health_bonus", 0))
					spice_target.max_health -= int(removed_spice.get("health_bonus", 0))
					state[enemy_side].discard.append(removed_spice_id)
			"destroy_enemy_unit":
				var destroyed := _remove_unit(state[enemy_side], target_instance_id)
				if not destroyed.is_empty():
					_queue_unit_event(state, "destroy", enemy_side, destroyed, "card_effect", 0)
					_discard_unit_attachments(state[enemy_side], destroyed)
					_discard_unit_card(state[enemy_side], destroyed)
					_log(state, "%s destroys %s." % [_side_name(side), destroyed.name])
			"damage_enemy_plated":
				var damage_target := _find_unit_in_zone(state[enemy_side], "plated", target_instance_id)
				if not damage_target.is_empty():
					_log(state, "%s deals %d damage to %s." % [_side_name(side), amount, damage_target.name])
					_deal_effect_damage_to_unit(state, side, enemy_side, damage_target, amount, source)
	if refresh_after:
		_refresh_stat_auras(state)
	_check_game_over(state)


func _effect_needs_board_choice(effect: Dictionary) -> bool:
	var effect_type := String(effect.get("type", ""))
	if effect_type == "damage_enemy_prep":
		return String(effect.get("target", "")) != "random"
	return effect_type in [
		"buff_friendly_unit",
		"buff_friendly_plated",
		"heal_unit",
		"damage_enemy_unit",
		"damage_enemy_plated",
		"return_enemy_ingredient",
		"return_enemy_plated_unit",
		"move_friendly_to_prep",
		"switch_friendly_zones",
		"switch_enemy_zones",
		"destroy_enemy_unit",
		"swap_attack_health",
		"remove_enemy_spice"
	]


func _valid_discard_indices(combatant: Dictionary, effect: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	for discard_index in range(combatant.discard.size()):
		var candidate_type := String(card(String(combatant.discard[discard_index])).get("card_type", ""))
		if required_type != "" and candidate_type != required_type:
			continue
		if not allowed_types.is_empty() and not allowed_types.has(candidate_type):
			continue
		result.append(discard_index)
	return result


func _valid_opponent_hand_indices(state: Dictionary, side: String, _effect: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var enemy_side := "opponent" if side == "player" else "player"
	if state[enemy_side].prep.size() >= PREP_SLOTS and state[enemy_side].plated.size() >= PLATED_SLOTS:
		return result
	for hand_index in range(state[enemy_side].hand.size()):
		if String(card(String(state[enemy_side].hand[hand_index])).get("card_type", "")) in ["ingredient", "meal"]:
			result.append(hand_index)
	return result


func _deploy_enemy_hand_unit(state: Dictionary, side: String, hand_index: int) -> void:
	var enemy_side := "opponent" if side == "player" else "player"
	if hand_index < 0 or hand_index >= state[enemy_side].hand.size():
		return
	var card_id := String(state[enemy_side].hand[hand_index])
	var data := card(card_id)
	if String(data.get("card_type", "")) not in ["ingredient", "meal"]:
		return
	var destination := "prep" if state[enemy_side].prep.size() < PREP_SLOTS else "plated"
	var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if state[enemy_side][destination].size() >= capacity:
		return
	state[enemy_side].hand.remove_at(hand_index)
	var unit := _make_unit(state, state[enemy_side], data, destination, enemy_side)
	unit.ready = false
	state[enemy_side][destination].append(unit)
	_log(state, "%s uses Tongs to put %s into %s's %s zone." % [_side_name(side), data.name, _side_name(enemy_side), destination.capitalize()])


func _valid_board_target_ids(state: Dictionary, side: String, effect: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var enemy_side := "opponent" if side == "player" else "player"
	var effect_type := String(effect.get("type", ""))
	var target_side := side
	var zones := ["prep", "plated"]
	match effect_type:
		"buff_friendly_plated":
			zones = ["plated"]
		"move_friendly_to_prep":
			zones = ["plated"]
			if state[side].prep.size() >= PREP_SLOTS:
				return result
		"switch_friendly_zones":
			zones = ["prep"] if effect.has("plated_instance_id") else ["plated"]
		"switch_enemy_zones":
			target_side = enemy_side
			if not effect.has("plated_instance_id") and state[target_side].prep.is_empty():
				return result
			zones = ["prep"] if effect.has("plated_instance_id") else ["plated"]
		"damage_enemy_prep":
			target_side = enemy_side
			zones = ["prep"]
		"damage_enemy_plated":
			target_side = enemy_side
			zones = ["plated"]
		"damage_enemy_unit":
			target_side = enemy_side
		"return_enemy_ingredient", "return_enemy_plated_unit", "destroy_enemy_unit", "remove_enemy_spice":
			target_side = enemy_side
			if effect_type == "return_enemy_plated_unit":
				zones = ["plated"]
		"swap_attack_health":
			for candidate_side in [side, enemy_side]:
				for zone_name in zones:
					for unit in state[candidate_side][zone_name]:
						result.append(int(unit.instance_id))
			return result
	for zone_name in zones:
		for unit in state[target_side][zone_name]:
			if effect_type == "heal_unit" and int(unit.health) >= int(unit.max_health):
				continue
			if effect_type == "return_enemy_ingredient" and String(unit.card_type) != "ingredient":
				continue
			if effect_type == "remove_enemy_spice" and unit.get("spices", []).is_empty():
				continue
			var required_type := String(effect.get("card_type", ""))
			if required_type != "" and String(unit.get("card_type", "")) != required_type:
				continue
			var required_archetype := String(effect.get("archetype", ""))
			if required_archetype != "" and not _card_has_archetype(card(String(unit.card_id)), required_archetype):
				continue
			result.append(int(unit.instance_id))
	return result


func _board_choice_prompt(effect: Dictionary) -> String:
	match String(effect.get("type", "")):
		"buff_friendly_unit":
			return "Choose a friendly card to gain Attack."
		"buff_friendly_plated":
			return "Choose a friendly Plated card to gain Attack this turn."
		"heal_unit":
			return "Choose a damaged friendly card to heal."
		"return_enemy_ingredient":
			return "Choose an opposing Ingredient to return to its owner's hand."
		"return_enemy_plated_unit":
			return "Choose an opposing Plated unit to return to its owner's hand."
		"damage_enemy_prep":
			return "Choose an opposing Prep card to damage."
		"damage_enemy_unit":
			return "Choose an opposing unit to damage."
		"damage_enemy_plated":
			return "Choose an opposing Plated unit to damage."
		"move_friendly_to_prep":
			return "Choose a friendly Spicy Plated card to move to Prep."
		"switch_friendly_zones":
			return "Choose one of your Plated foods to switch."
		"switch_enemy_zones":
			return "Choose one of your opponent's Plated foods to switch."
		"destroy_enemy_unit":
			return "Choose an opposing card to destroy."
		"swap_attack_health":
			return "Choose a card whose Attack and Health will be swapped."
		"remove_enemy_spice":
			return "Choose an opposing card with an attached Spice."
	return "Choose a highlighted card."


func _effect_label(effect: Dictionary) -> String:
	return String(effect.get("type", "effect")).replace("_", " ").capitalize()


func _choice_source(state: Dictionary, side: String, source_instance_id: int) -> Dictionary:
	if source_instance_id < 0:
		return {}
	return _find_unit(state[side], source_instance_id)


func _continue_after_choice(state: Dictionary, pending: Dictionary) -> void:
	var side := String(pending.get("side", "player"))
	var source := _choice_source(state, side, int(pending.get("source_instance_id", -1)))
	_resolve_effects(state, side, pending.get("remaining_effects", []), source)
	if state.get("pending_choice", {}).is_empty():
		_resume_pending_action(state)


func _card_names(card_ids: Array) -> Array[String]:
	var result: Array[String] = []
	for card_id in card_ids:
		result.append(String(card(String(card_id)).get("name", card_id)))
	return result


func _resume_pending_action(state: Dictionary) -> void:
	var pending: Dictionary = state.get("pending_resume", {})
	if pending.is_empty():
		return
	state.pending_resume = {}
	if String(pending.get("type", "")) != "player_attack":
		return
	var attacker := _find_unit(state.player, int(pending.get("attacker_instance_id", -1)))
	if attacker.is_empty() or not bool(attacker.get("ready", false)):
		state.selected_attacker = -1
		return
	var deferred_on_attack_events: Array[Dictionary] = []
	if bool(pending.get("defer_on_attack_animation", false)):
		deferred_on_attack_events = _take_animation_events_from(state, int(pending.get("on_attack_animation_start_id", int(state.get("next_animation_event_id", 1)))))
	var target_instance_id := int(pending.get("target_instance_id", -1))
	attacker.ready = false
	_queue_animation_event(state, "attack", {
		"side": "player",
		"source_instance_id": int(attacker.instance_id),
		"target_kind": "chef" if target_instance_id < 0 else "unit",
		"target_side": "opponent",
		"target_instance_id": target_instance_id
	}, 0)
	if target_instance_id < 0:
		_deal_chef_damage(state, "opponent", int(attacker.attack), "player", true)
		if int(attacker.attack) > 0:
			_resolve_effects(state, "player", card(String(attacker.card_id)).get("on_combat_damage_to_chef", []), attacker)
		_log(state, "%s hits the opposing chef for %d." % [attacker.name, attacker.attack])
	else:
		var defender := _find_unit_in_zone(state.opponent, "plated", target_instance_id)
		if not defender.is_empty():
			_resolve_unit_battle(state, "player", attacker, defender)
	_append_animation_events(state, deferred_on_attack_events)
	state.selected_attacker = -1
	_refresh_stat_auras(state)
	_check_game_over(state)


func _find_activated_ability(data: Dictionary, ability_id: String = "") -> Dictionary:
	for candidate in data.get("abilities", []):
		if String(candidate.get("timing", "")) != "activated":
			continue
		if ability_id == "" or String(candidate.get("id", "")) == ability_id:
			return candidate
	return {}


func _ability_needs_target(ability: Dictionary) -> bool:
	if not ability.get("target", {}).is_empty():
		return true
	for effect in ability.get("effects", []):
		if String(effect.get("target", "")) == "selected":
			return true
	return false


func _ability_enemy_target_zone(ability: Dictionary) -> String:
	if not ability.get("target", {}).is_empty():
		return String(ability.get("target", {}).get("zone", ""))
	for effect in ability.get("effects", []):
		if String(effect.get("target", "")) != "selected":
			continue
		if String(effect.get("type", "")) == "damage_enemy_plated":
			return "plated"
	return ""


func _ability_target_is_valid(state: Dictionary, acting_side: String, source: Dictionary, target_instance_id: int, target_spec: Dictionary) -> bool:
	var target_side_name := String(target_spec.get("side", "enemy"))
	var resolved_side := acting_side if target_side_name == "friendly" else ("opponent" if acting_side == "player" else "player")
	var target := _find_unit(state[resolved_side], target_instance_id)
	if target.is_empty():
		return false
	var zone := String(target_spec.get("zone", ""))
	if zone != "" and _unit_zone(state[resolved_side], target_instance_id) != zone:
		return false
	if bool(target_spec.get("exclude_self", false)) and int(source.get("instance_id", -1)) == target_instance_id:
		return false
	var required_type := String(target_spec.get("card_type", ""))
	if required_type != "" and String(target.get("card_type", "")) != required_type:
		return false
	if bool(target_spec.get("damaged_only", false)) and int(target.health) >= int(target.max_health):
		return false
	if bool(target_spec.get("has_activated_ability", false)):
		var found := false
		for candidate in card(String(target.card_id)).get("abilities", []):
			if String(candidate.get("timing", "")) == "activated" and String(candidate.get("id", "")) != "remix_raccoon_copy":
				found = true
				break
		if not found:
			return false
	return true


func _resolve_activated_ability(state: Dictionary, source_instance_id: int, ability: Dictionary, target_instance_id: int) -> Dictionary:
	return _resolve_activated_ability_for_side(state, "player", source_instance_id, ability, target_instance_id, true)


func _resolve_activated_ability_for_side(
	state: Dictionary,
	side: String,
	source_instance_id: int,
	ability: Dictionary,
	target_instance_id: int,
	allow_reaction: bool
) -> Dictionary:
	var source := _find_unit(state[side], source_instance_id)
	if source.is_empty():
		return _message(state, "That card is no longer on your field.")
	var active_zone := String(ability.get("active_zone", ""))
	if active_zone != "" and _unit_zone(state[side], source_instance_id) != active_zone:
		return _message(state, "%s's ability can only be used while it is %s." % [source.name, active_zone.capitalize()])
	var target_spec: Dictionary = ability.get("target", {})
	if _ability_needs_target(ability) and not _ability_target_is_valid(state, side, source, target_instance_id, target_spec):
		return _message(state, "Choose a legal target for %s's ability." % source.name)
	var source_name := String(source.name)
	var ability_id := String(ability.get("id", "activated"))
	if bool(ability.get("once_per_turn", false)):
		var used_abilities: Array = source.get("used_abilities", [])
		if used_abilities.has(ability_id):
			return _message(state, "%s has already used that ability this turn." % source_name)
		used_abilities.append(ability_id)
		source.used_abilities = used_abilities
	var activation_group_id := _next_animation_group(state)
	_queue_animation_event(state, "ability_activation", {
		"side": side,
		"source_instance_id": source_instance_id,
		"card_id": String(source.get("card_id", "")),
		"activation_label": "ABILITY ACTIVATED",
		"ability_id": ability_id
	}, activation_group_id)
	var sacrificed := false
	if bool(ability.get("cost", {}).get("sacrifice_self", false)):
		var removed := _remove_unit(state[side], source_instance_id)
		if removed.is_empty():
			return _message(state, "%s could not be sacrificed." % source_name)
		_queue_unit_event(state, "sacrifice", side, removed, "ability_cost", _next_animation_group(state))
		_resolve_effects(state, side, card(String(removed.card_id)).get("on_sacrifice", []), removed)
		_discard_unit_attachments(state[side], removed)
		_discard_unit_card(state[side], removed)
		sacrificed = true
	_clear_selections(state)
	_log(state, "%s %s%s's ability." % [_side_name(side), "sacrifices %s and activates " % source_name if sacrificed else "activates ", source_name])
	if side == "player" and _ai_hand_trap_stops(state, "enemy_activated_ability", side):
		_log(state, "%s's ability is negated." % source_name)
		_refresh_stat_auras(state)
		return state
	if side == "opponent" and allow_reaction and _offer_player_reaction(state, "enemy_activated_ability", {
		"action_kind": "activated_ability",
		"acting_side": "opponent",
		"card_id": String(source.get("card_id", "")),
		"source": source,
		"effects": ability.get("effects", []).duplicate(true),
		"target_instance_id": target_instance_id
	}):
		_refresh_stat_auras(state)
		return state
	_resolve_effects(state, side, ability.get("effects", []), source, target_instance_id)
	_refresh_stat_auras(state)
	return state


func _ai_activate_abilities(state: Dictionary) -> bool:
	for zone_name in ["plated", "prep"]:
		for source in state.opponent[zone_name].duplicate():
			for ability in card(String(source.card_id)).get("abilities", []):
				if String(ability.get("timing", "")) != "activated":
					continue
				var active_zone := String(ability.get("active_zone", ""))
				if active_zone != "" and active_zone != zone_name:
					continue
				var ability_id := String(ability.get("id", "activated"))
				if source.get("used_abilities", []).has(ability_id):
					continue
				var target_id := -1
				if _ability_needs_target(ability):
					target_id = _first_ability_target_id(state, "opponent", source, ability.get("target", {}))
					if target_id < 0:
						continue
				_resolve_activated_ability_for_side(state, "opponent", int(source.instance_id), ability, target_id, true)
				if not state.get("pending_reaction", {}).is_empty():
					return true
	return false


func _first_ability_target_id(state: Dictionary, acting_side: String, source: Dictionary, target_spec: Dictionary) -> int:
	var target_side_name := String(target_spec.get("side", "enemy"))
	var resolved_side := acting_side if target_side_name == "friendly" else ("opponent" if acting_side == "player" else "player")
	for zone_name in ["plated", "prep"]:
		for target in state[resolved_side][zone_name]:
			if _ability_target_is_valid(state, acting_side, source, int(target.instance_id), target_spec):
				return int(target.instance_id)
	return -1


func _draw(state: Dictionary, side: String, _fatigue_enabled: bool = true) -> void:
	var who: Dictionary = state[side]
	if who.deck.is_empty():
		return
	var drawn_card_id := String(who.deck.pop_back())
	who.hand.append(drawn_card_id)
	_queue_animation_event(state, "draw", {
		"side": side,
		"card_id": drawn_card_id,
		"hand_index": who.hand.size() - 1,
		"from": "deck",
		"to": "hand"
	})


func _ingredient_is_recipe_ready(combatant: Dictionary, unit: Dictionary) -> bool:
	return int(combatant.turns_started) >= int(unit.get("recipe_ready_on_turn", 999999))


func _find_recipe_ingredients(combatant: Dictionary, recipe: Array) -> Array:
	var result: Array = []
	var used: Dictionary = {}
	for requirement in recipe:
		var found := false
		for zone_name in ["prep", "plated"]:
			for ingredient in combatant[zone_name]:
				var instance_id := int(ingredient.instance_id)
				if used.has(instance_id) or String(ingredient.card_type) != "ingredient":
					continue
				if not _ingredient_is_recipe_ready(combatant, ingredient):
					continue
				if _ingredient_matches_requirement(card(String(ingredient.card_id)), String(requirement)):
					result.append(instance_id)
					used[instance_id] = true
					found = true
					break
			if found:
				break
		if not found:
			return []
	return result


func _find_recipe_meal(combatant: Dictionary, required_archetype: String) -> Dictionary:
	if required_archetype == "":
		return {}
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			if String(unit.get("card_type", "")) != "meal":
				continue
			if _card_has_archetype(card(String(unit.card_id)), required_archetype):
				return unit
	return {}


func _meal_limit(combatant: Dictionary) -> int:
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			if bool(card(String(unit.card_id)).get("extra_meal_each_turn", false)):
				return 2
	return 1


func _can_serve_meal(combatant: Dictionary) -> bool:
	return int(combatant.get("meals_served", 1 if bool(combatant.get("meal_served", false)) else 0)) < _meal_limit(combatant)


func _effective_recipe(state: Dictionary, side: String, data: Dictionary) -> Array:
	var recipe: Array = data.get("recipe", []).duplicate()
	var enemy_side := "opponent" if side == "player" else "player"
	for zone_name in ["prep", "plated"]:
		for source in state[enemy_side][zone_name]:
			for aura in card(String(source.card_id)).get("auras", []):
				if String(aura.get("target", "")) != "opponent_meal_recipes":
					continue
				var active_zone := String(aura.get("active_zone", ""))
				if active_zone != "" and active_zone != zone_name:
					continue
				for unused in range(int(aura.get("extra_any", 0))):
					recipe.append("any")
	return recipe


func _recipe_text(recipe: Array) -> String:
	var parts: Array[String] = []
	for requirement_value in recipe:
		var requirement := String(requirement_value)
		if requirement == "any":
			parts.append("Anything")
		else:
			var options: Array[String] = []
			for option in requirement.split("|"):
				options.append(String(option).capitalize())
			parts.append(" or ".join(options))
	return " + ".join(parts)


func _ingredient_matches_requirement(ingredient_data: Dictionary, requirement: String) -> bool:
	if requirement == "any":
		return true
	var ingredient_types: Array = ingredient_data.get("ingredient_types", [])
	for option in requirement.split("|"):
		if ingredient_types.has(String(option)):
			return true
	return false


func _card_has_archetype(card_data: Dictionary, archetype: String) -> bool:
	if String(card_data.get("archetype", "")) == archetype:
		return true
	return card_data.get("archetypes", []).has(archetype) or card_data.get("ingredient_types", []).has(archetype)


func _selection_satisfies(combatant: Dictionary, selected: Array, recipe: Array) -> bool:
	if selected.size() != recipe.size():
		return false
	var selected_units: Array = []
	for instance_id in selected:
		var unit := _find_unit(combatant, int(instance_id))
		if unit.is_empty() or String(unit.card_type) != "ingredient" or not _ingredient_is_recipe_ready(combatant, unit):
			return false
		selected_units.append(unit)
	var temporary := { "prep": selected_units, "plated": [], "turns_started": combatant.turns_started }
	return not _find_recipe_ingredients(temporary, recipe).is_empty()


func _opening_attack_lock(state: Dictionary, side: String) -> bool:
	return String(state.first_player) == side and int(state[side].turns_started) <= 1


func _find_unit(combatant: Dictionary, instance_id: int) -> Dictionary:
	for zone_name in ["prep", "plated"]:
		var unit := _find_unit_in_zone(combatant, zone_name, instance_id)
		if not unit.is_empty():
			return unit
	return {}


func _unit_zone(combatant: Dictionary, instance_id: int) -> String:
	for zone_name in ["prep", "plated"]:
		if not _find_unit_in_zone(combatant, zone_name, instance_id).is_empty():
			return zone_name
	return ""


func _find_unit_in_zone(combatant: Dictionary, zone_name: String, instance_id: int) -> Dictionary:
	for unit in combatant[zone_name]:
		if int(unit.instance_id) == instance_id:
			return unit
	return {}


func _first_enemy_unit(combatant: Dictionary, effect: Dictionary = {}) -> Dictionary:
	var required_type := String(effect.get("card_type", ""))
	for zone_name in ["plated", "prep"]:
		for unit in combatant[zone_name]:
			if required_type == "" or String(unit.get("card_type", "")) == required_type:
				return unit
	return {}


func _first_copyable_ability(data: Dictionary) -> Dictionary:
	for ability in data.get("abilities", []):
		if String(ability.get("timing", "")) == "activated" and String(ability.get("id", "")) != "remix_raccoon_copy":
			return ability
	return {}


func _deal_chef_damage(state: Dictionary, target_side: String, amount: int, source_side: String = "", combat_damage: bool = false, animation_group_id: int = -1) -> void:
	if amount <= 0:
		return
	_queue_animation_event(state, "damage", {
		"source_side": source_side,
		"target_kind": "chef",
		"target_side": target_side,
		"target_instance_id": -1,
		"amount": amount,
		"combat": combat_damage
	}, animation_group_id)
	state[target_side].life -= amount
	_log(state, "%s takes %d %sdamage." % [_side_name(target_side), amount, "combat " if combat_damage else ""])
	_check_game_over(state)
	if not bool(state.game_over):
		_trigger_friendly_chef_damaged(state, target_side)


func _healing_amount(state: Dictionary, healing_side: String, amount: int) -> int:
	var opposing_side := "opponent" if healing_side == "player" else "player"
	var reduction := 0
	for unit in state[opposing_side].plated:
		reduction = maxi(reduction, int(card(String(unit.card_id)).get("opponent_healing_reduction", 0)))
	return maxi(0, amount - reduction)


func _effect_damage_is_prevented(state: Dictionary, target_side: String, target: Dictionary) -> bool:
	if _unit_zone(state[target_side], int(target.get("instance_id", -1))) != "prep":
		return false
	for protector in state[target_side].prep:
		if int(protector.instance_id) == int(target.get("instance_id", -1)):
			continue
		if bool(card(String(protector.card_id)).get("protect_other_friendly_prep_from_effect_damage", false)):
			return true
	return false


func _deal_effect_damage_to_unit(
	state: Dictionary,
	source_side: String,
	target_side: String,
	target: Dictionary,
	amount: int,
	source: Dictionary = {},
	remove_defeated: bool = true,
	animation_group_id: int = -1
) -> bool:
	if target.is_empty() or amount <= 0:
		return false
	if _effect_damage_is_prevented(state, target_side, target):
		_log(state, "%s protects %s from effect damage." % [_side_name(target_side), target.name])
		return false
	_queue_animation_event(state, "damage", {
		"source_side": source_side,
		"source_instance_id": int(source.get("instance_id", -1)),
		"target_kind": "unit",
		"target_side": target_side,
		"target_instance_id": int(target.instance_id),
		"amount": amount,
		"combat": false
	}, animation_group_id)
	target.health -= amount
	if remove_defeated:
		_remove_defeated(state, target_side, source_side, source)
	return true


func _remove_unit(combatant: Dictionary, instance_id: int) -> Dictionary:
	for zone_name in ["prep", "plated"]:
		var zone: Array = combatant[zone_name]
		for index in range(zone.size()):
			if int(zone[index].instance_id) == instance_id:
				var removed: Dictionary = zone[index]
				zone.remove_at(index)
				return removed
	return {}


func _remove_defeated(state: Dictionary, side: String, ko_source_side: String = "", ko_source: Dictionary = {}) -> bool:
	var who: Dictionary = state[side]
	var removed_any := false
	var defeated_ids: Array[int] = []
	for zone_name in ["prep", "plated"]:
		for unit in who[zone_name]:
			if int(unit.health) <= 0:
				defeated_ids.append(int(unit.instance_id))
	for defeated_id in defeated_ids:
		var defeated_zone := _unit_zone(who, defeated_id)
		var defeated := _remove_unit(who, defeated_id)
		if defeated.is_empty():
			continue
		_discard_unit_attachments(who, defeated)
		_discard_unit_card(who, defeated)
		_queue_unit_event(state, "destroy", side, defeated, "ko", 0, defeated_zone)
		_log(state, "%s's %s is KO'd in %s." % [_side_name(side), defeated.name, defeated_zone.capitalize()])
		_resolve_effects(state, side, card(String(defeated.card_id)).get("on_ko", []), defeated)
		if ko_source_side != "" and ko_source_side != side and not ko_source.is_empty():
			var live_source := _find_unit(state[ko_source_side], int(ko_source.get("instance_id", -1)))
			if not live_source.is_empty():
				_resolve_effects(state, ko_source_side, card(String(live_source.card_id)).get("on_ko_enemy", []), live_source)
		removed_any = true
	return removed_any


func _refresh_stat_auras(state: Dictionary) -> void:
	for unused_iteration in range(4):
		for side in ["player", "opponent"]:
			for zone_name in ["prep", "plated"]:
				for unit in state[side][zone_name]:
					var old_attack_bonus := int(unit.get("aura_attack_bonus", 0))
					var old_health_bonus := int(unit.get("aura_health_bonus", 0))
					unit.attack -= old_attack_bonus
					unit.health -= old_health_bonus
					unit.max_health -= old_health_bonus
					unit.aura_attack_bonus = 0
					unit.aura_health_bonus = 0
		for side in ["player", "opponent"]:
			for source_zone in ["prep", "plated"]:
				for source in state[side][source_zone]:
					for aura in card(String(source.card_id)).get("auras", []):
						var active_zone := String(aura.get("active_zone", ""))
						if active_zone != "" and active_zone != source_zone:
							continue
						var target_kind := String(aura.get("target", ""))
						if target_kind not in ["friendly_plated", "other_friendly_plated"]:
							continue
						for target in state[side].plated:
							if target_kind == "other_friendly_plated" and int(target.instance_id) == int(source.instance_id):
								continue
							_apply_stat_aura(target, aura)
					var per_prep_bonus := int(card(String(source.card_id)).get("self_attack_per_friendly_prep_archetype", 0))
					if per_prep_bonus > 0:
						var counted_archetype := String(card(String(source.card_id)).get("count_archetype", card(String(source.card_id)).get("archetype", "")))
						var matching_prep := 0
						for prep_unit in state[side].prep:
							if int(prep_unit.instance_id) == int(source.instance_id):
								continue
							if _card_has_archetype(card(String(prep_unit.card_id)), counted_archetype):
								matching_prep += 1
						var dynamic_bonus := per_prep_bonus * matching_prep
						source.attack += dynamic_bonus
						source.aura_attack_bonus = int(source.get("aura_attack_bonus", 0)) + dynamic_bonus
		var removed_any := false
		for side in ["player", "opponent"]:
			removed_any = _remove_defeated(state, side) or removed_any
		if not removed_any:
			break


func _apply_stat_aura(target: Dictionary, aura: Dictionary) -> void:
	var attack_bonus := int(aura.get("attack_bonus", 0))
	var health_bonus := int(aura.get("health_bonus", 0))
	target.attack += attack_bonus
	target.health += health_bonus
	target.max_health += health_bonus
	target.aura_attack_bonus = int(target.get("aura_attack_bonus", 0)) + attack_bonus
	target.aura_health_bonus = int(target.get("aura_health_bonus", 0)) + health_bonus


func _clear_temporary_buffs(combatant: Dictionary) -> void:
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			unit.attack -= int(unit.get("temporary_attack", 0))
			unit.temporary_attack = 0


func _discard_unit_attachments(combatant: Dictionary, unit: Dictionary) -> void:
	for spice_id in unit.get("spices", []):
		combatant.discard.append(String(spice_id))


func _discard_unit_card(combatant: Dictionary, unit: Dictionary) -> void:
	if bool(unit.get("is_token", false)):
		return
	combatant.discard.append(String(unit.card_id))


func _first_unspiced_unit(combatant: Dictionary) -> Dictionary:
	for zone_name in ["plated", "prep"]:
		for unit in combatant[zone_name]:
			if unit.get("spices", []).is_empty():
				return unit
	return {}


func _first_plated_with_keyword(combatant: Dictionary, keyword: String) -> Dictionary:
	for unit in combatant.plated:
		if card(String(unit.card_id)).get("keywords", []).has(keyword):
			return unit
	return {}


func _plated_units_with_keyword(combatant: Dictionary, keyword: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for unit in combatant.plated:
		if card(String(unit.card_id)).get("keywords", []).has(keyword):
			matches.append(unit)
	return matches


func _unit_has_keyword(unit: Dictionary, keyword: String) -> bool:
	if unit.is_empty():
		return false
	var data := card(String(unit.get("card_id", "")))
	return data.get("keywords", []).has(keyword)


func _first_friendly_unit(combatant: Dictionary) -> Dictionary:
	if not combatant.plated.is_empty():
		return combatant.plated[0]
	if not combatant.prep.is_empty():
		return combatant.prep[0]
	return {}


func _most_damaged_friendly_unit(combatant: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var largest_damage := 0
	for zone_name in ["plated", "prep"]:
		for unit in combatant[zone_name]:
			var damage := int(unit.max_health) - int(unit.health)
			if result.is_empty() or damage > largest_damage:
				result = unit
				largest_damage = damage
	return result


func _queue_player_search(state: Dictionary, effect: Dictionary, reveal_top: bool = false) -> void:
	var request := {"effect": effect.duplicate(true)}
	if reveal_top:
		request.reveal_top = int(effect.get("count", 0))
	if not state.get("pending_search", {}).is_empty():
		state.search_queue.append(request)
		return
	_start_search_request(state, request)


func _start_search_request(state: Dictionary, request: Dictionary) -> void:
	var effect: Dictionary = request.get("effect", {})
	if int(request.get("reveal_top", 0)) > 0:
		request.revealed_cards = _top_deck_cards(state.player, int(request.reveal_top))
	var display_cards: Array[String] = []
	if request.has("revealed_cards"):
		for card_id in request.revealed_cards:
			display_cards.append(String(card_id))
	else:
		display_cards = _matching_deck_cards(state.player, effect)
	if display_cards.is_empty():
		_shuffle(state.player.deck)
		_log(state, "No cards in your deck match that search. You shuffle your deck.")
		_advance_search_queue(state)
		return
	request.prompt = _search_prompt(effect, display_cards.size() if request.has("revealed_cards") else -1)
	state.pending_search = request
	_clear_selections(state)
	_message(state, String(request.prompt))


func _advance_search_queue(state: Dictionary) -> void:
	state.pending_search = {}
	if state.get("search_queue", []).is_empty():
		return
	var next_request: Dictionary = state.search_queue.pop_front()
	_start_search_request(state, next_request)


func _search_prompt(effect: Dictionary, revealed_count: int = -1) -> String:
	if revealed_count >= 0:
		var requested_count := int(effect.get("count", revealed_count))
		var required_type := String(effect.get("card_type", "card")).capitalize()
		return "Look at the top %d card%s of your deck. Choose a %s to add to your hand." % [mini(requested_count, revealed_count), "" if mini(requested_count, revealed_count) == 1 else "s", required_type]
	var required_archetype := String(effect.get("archetype", ""))
	var required_type := String(effect.get("card_type", ""))
	var allowed_types: Array = effect.get("card_types", [])
	var description_parts: Array[String] = []
	if required_archetype != "":
		description_parts.append(required_archetype.capitalize())
	if required_type != "":
		description_parts.append(required_type.capitalize())
	elif not allowed_types.is_empty():
		var type_names: Array[String] = []
		for allowed_type in allowed_types:
			type_names.append(String(allowed_type).capitalize())
		description_parts.append(" or ".join(type_names))
	else:
		description_parts.append("card")
	return "Choose a %s from your deck." % " ".join(description_parts)


func _matching_deck_cards(combatant: Dictionary, effect: Dictionary) -> Array[String]:
	var deck_cards_top_first: Array[String] = []
	for index in range(combatant.deck.size() - 1, -1, -1):
		deck_cards_top_first.append(String(combatant.deck[index]))
	return _matching_card_ids(deck_cards_top_first, effect)


func _matching_card_ids(card_ids: Array, effect: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_card_id in card_ids:
		var candidate_id := String(raw_card_id)
		if _card_matches_search(candidate_id, effect) and not result.has(candidate_id):
			result.append(candidate_id)
	return result


func _top_deck_cards(combatant: Dictionary, count: int) -> Array[String]:
	var result: Array[String] = []
	var bottom_index := maxi(0, combatant.deck.size() - maxi(0, count))
	for index in range(combatant.deck.size() - 1, bottom_index - 1, -1):
		result.append(String(combatant.deck[index]))
	return result


func _card_matches_search(candidate_id: String, effect: Dictionary) -> bool:
	if candidate_id == String(effect.get("exclude_card_id", "")):
		return false
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	var required_archetype := String(effect.get("archetype", ""))
	var candidate := card(candidate_id)
	var candidate_type := String(candidate.get("card_type", ""))
	if required_type != "" and candidate_type != required_type:
		return false
	if not allowed_types.is_empty() and not allowed_types.has(candidate_type):
		return false
	if required_archetype != "" and not _card_has_archetype(candidate, required_archetype):
		return false
	return true


func _search_deck(state: Dictionary, side: String, effect: Dictionary) -> void:
	var combatant: Dictionary = state[side]
	var candidate_indices: Array[int] = []
	for index in range(combatant.deck.size() - 1, -1, -1):
		if _card_matches_search(String(combatant.deck[index]), effect):
			candidate_indices.append(index)
	var chosen_index := -1
	if not candidate_indices.is_empty():
		chosen_index = int(candidate_indices[0])
		if side == "opponent" and _ai_level(state) >= 3:
			chosen_index = _expert_best_search_index(state, candidate_indices)
	if chosen_index >= 0:
		var chosen_card_id := String(combatant.deck[chosen_index])
		combatant.deck.remove_at(chosen_index)
		if String(effect.get("destination", "hand")) == "prep":
			_deploy_searched_ingredient(state, side, chosen_card_id)
		else:
			combatant.hand.append(chosen_card_id)
			_queue_animation_event(state, "search", {
				"side": side,
				"card_id": chosen_card_id,
				"from": "deck",
				"to": "hand",
				"hand_index": combatant.hand.size() - 1
			}, _next_animation_group(state))
	_shuffle(combatant.deck)


func _deploy_searched_ingredient(state: Dictionary, side: String, card_id: String) -> void:
	if state[side].prep.size() >= PREP_SLOTS:
		state[side].hand.append(card_id)
		return
	var data := card(card_id)
	var unit := _make_unit(state, state[side], data, "prep", side)
	state[side].prep.append(unit)
	var play_group_id := _queue_play_event(state, side, card_id, "ingredient", int(unit.instance_id))
	var previous_animation_group := _with_animation_group(state, play_group_id)
	_resolve_effects(state, side, data.get("on_play", []), unit)
	_restore_animation_group(state, previous_animation_group)


func _look_and_take(state: Dictionary, side: String, effect: Dictionary) -> void:
	var combatant: Dictionary = state[side]
	var candidate_indices: Array[int] = []
	for candidate_id in _top_deck_cards(combatant, int(effect.get("count", 0))):
		if not _card_matches_search(candidate_id, effect):
			continue
		var deck_index: int = combatant.deck.rfind(candidate_id)
		if deck_index >= 0 and not candidate_indices.has(deck_index):
			candidate_indices.append(deck_index)
	var chosen_index := -1
	if not candidate_indices.is_empty():
		chosen_index = int(candidate_indices[0])
		if side == "opponent" and _ai_level(state) >= 3:
			chosen_index = _expert_best_search_index(state, candidate_indices)
	if chosen_index >= 0:
		var chosen_card_id := String(combatant.deck[chosen_index])
		combatant.hand.append(chosen_card_id)
		combatant.deck.remove_at(chosen_index)
		_queue_animation_event(state, "search", {
			"side": side,
			"card_id": chosen_card_id,
			"from": "deck",
			"to": "hand",
			"hand_index": combatant.hand.size() - 1
		}, _next_animation_group(state))
	_shuffle(combatant.deck)


func _expert_best_search_index(state: Dictionary, candidate_indices: Array[int]) -> int:
	var best_index := int(candidate_indices[0])
	var best_value := -INF
	for index in candidate_indices:
		var card_id := String(state.opponent.deck[int(index)])
		var value := _ai_card_hold_value(card_id)
		var data := card(card_id)
		if String(data.get("card_type", "")) == "meal":
			var recipe := _effective_recipe(state, "opponent", data)
			if not _find_recipe_ingredients(state.opponent, recipe).is_empty():
				value += 28.0
		if String(data.get("card_type", "")) == "ingredient" and _expert_ingredient_matches_held_meal(state, data):
			value += 14.0
		if value > best_value:
			best_value = value
			best_index = int(index)
	return best_index


func _expert_ingredient_matches_held_meal(state: Dictionary, ingredient_data: Dictionary) -> bool:
	for held_id in state.opponent.hand:
		var held := card(String(held_id))
		if String(held.get("card_type", "")) != "meal":
			continue
		for requirement in _effective_recipe(state, "opponent", held):
			if _ingredient_matches_requirement(ingredient_data, String(requirement)):
				return true
	return false


func _recover_from_discard(state: Dictionary, side: String, effect: Dictionary) -> void:
	var combatant: Dictionary = state[side]
	var remaining := int(effect.get("amount", 1))
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	var required_archetype := String(effect.get("archetype", ""))
	for index in range(combatant.discard.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var candidate_id := String(combatant.discard[index])
		var candidate_type := String(card(candidate_id).get("card_type", ""))
		if required_type != "" and candidate_type != required_type:
			continue
		if not allowed_types.is_empty() and not allowed_types.has(candidate_type):
			continue
		if required_archetype != "" and not _card_has_archetype(card(candidate_id), required_archetype):
			continue
		combatant.hand.append(candidate_id)
		combatant.discard.remove_at(index)
		_queue_animation_event(state, "search", {
			"side": side,
			"card_id": candidate_id,
			"from": "discard",
			"to": "hand",
			"hand_index": combatant.hand.size() - 1
		})
		remaining -= 1


func _revive_from_discard(state: Dictionary, side: String, effect: Dictionary) -> void:
	if state[side].prep.size() >= PREP_SLOTS:
		return
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	for index in range(state[side].discard.size() - 1, -1, -1):
		var card_id := String(state[side].discard[index])
		var card_type := String(card(card_id).get("card_type", ""))
		if required_type != "" and card_type != required_type:
			continue
		if not allowed_types.is_empty() and not allowed_types.has(card_type):
			continue
		state[side].discard.remove_at(index)
		_deploy_revived_unit(state, side, card_id)
		return


func _deploy_revived_unit(state: Dictionary, side: String, card_id: String) -> void:
	if state[side].prep.size() >= PREP_SLOTS:
		state[side].discard.append(card_id)
		return
	var data := card(card_id)
	var unit := _make_unit(state, state[side], data, "prep", side)
	state[side].prep.append(unit)
	_queue_play_event(state, side, card_id, String(data.get("card_type", "unit")), int(unit.instance_id))
	_log(state, "%s returns %s from the discard pile to Prep." % [_side_name(side), data.get("name", card_id)])


func _recycle_from_discard(state: Dictionary, side: String, amount: int) -> void:
	var combatant: Dictionary = state[side]
	for unused in range(mini(amount, combatant.discard.size())):
		var card_id := String(combatant.discard.pop_back())
		combatant.deck.append(card_id)
		_queue_animation_event(state, "search", {
			"side": side,
			"card_id": card_id,
			"from": "discard",
			"to": "deck"
		})
	_shuffle(combatant.deck)


func _count_controlled_archetype(combatant: Dictionary, archetype: String) -> int:
	var count := 0
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			if _card_has_archetype(card(String(unit.card_id)), archetype):
				count += 1
	return count


func _return_enemy_ingredient(state: Dictionary, target_side: String, target_instance_id: int = -1) -> void:
	var combatant: Dictionary = state[target_side]
	for zone_name in ["prep", "plated"]:
		for index in range(combatant[zone_name].size()):
			var unit: Dictionary = combatant[zone_name][index]
			if String(unit.card_type) == "ingredient":
				if target_instance_id >= 0 and int(unit.instance_id) != target_instance_id:
					continue
				_discard_unit_attachments(combatant, unit)
				combatant[zone_name].remove_at(index)
				if bool(unit.get("is_token", false)):
					_queue_token_evaporation_event(state, target_side, unit, zone_name, "hand", "returned_to_hand")
					_log(state, "%s's %s evaporates instead of returning to hand." % [_side_name(target_side), unit.name])
				else:
					combatant.hand.append(String(unit.card_id))
				return


func _return_enemy_plated_unit(state: Dictionary, target_side: String, target_instance_id: int = -1) -> void:
	var combatant: Dictionary = state[target_side]
	for index in range(combatant.plated.size()):
		var unit: Dictionary = combatant.plated[index]
		if target_instance_id >= 0 and int(unit.instance_id) != target_instance_id:
			continue
		_discard_unit_attachments(combatant, unit)
		combatant.plated.remove_at(index)
		if bool(unit.get("is_token", false)):
			_queue_token_evaporation_event(state, target_side, unit, "plated", "hand", "returned_to_hand")
			_log(state, "%s's %s evaporates instead of returning to hand." % [_side_name(target_side), unit.name])
		else:
			combatant.hand.append(String(unit.card_id))
		return


func _weakest_plated_unit(combatant: Dictionary) -> Dictionary:
	if combatant.plated.is_empty():
		return {}
	var candidates: Array[Dictionary] = _plated_units_with_keyword(combatant, "taunt")
	if candidates.is_empty():
		for plated_unit in combatant.plated:
			candidates.append(plated_unit)
	var weakest: Dictionary = candidates[0]
	for unit in candidates:
		if int(unit.health) < int(weakest.health):
			weakest = unit
	return weakest


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var swap = values[index]
		values[index] = values[swap_index]
		values[swap_index] = swap


func _check_game_over(state: Dictionary) -> void:
	if int(state.player.life) <= 0:
		state.game_over = true
		state.winner = "opponent"
		state.phase = "game_over"
		state.message = "%s wins." % deck_name(String(state.opponent.deck_id))
	elif int(state.opponent.life) <= 0:
		state.game_over = true
		state.winner = "player"
		state.phase = "game_over"
		state.message = "You win!"


func _clear_selections(state: Dictionary) -> void:
	state.selected_ingredients = []
	state.selected_attacker = -1
	state.selected_spice_target = -1


func _can_player_act(state: Dictionary) -> bool:
	return not bool(state.get("game_over", false)) and String(state.get("phase", "")) == "player_main"


func _message(state: Dictionary, value: String) -> Dictionary:
	state.message = value
	return state


func _log(state: Dictionary, value: String) -> void:
	state.log.append(value)
	state.message = value
	if state.log.size() > 50:
		state.log.pop_front()


func _record_hand_play(state: Dictionary, side: String, card_id: String, action_kind: String, target_instance_id: int = -1) -> void:
	if side != "opponent":
		return
	state.visual_action_serial = int(state.get("visual_action_serial", 0)) + 1
	state.last_visual_action = {
		"side": side,
		"card_id": card_id,
		"action_kind": action_kind,
		"target_instance_id": target_instance_id
	}


func _queue_play_event(state: Dictionary, side: String, card_id: String, action_kind: String, instance_id: int = -1, target_instance_id: int = -1) -> int:
	var group_id := _next_animation_group(state)
	var zone := _unit_zone(state[side], instance_id) if instance_id >= 0 else ""
	_queue_animation_event(state, "play", {
		"side": side,
		"card_id": card_id,
		"card_type": action_kind,
		"instance_id": instance_id,
		"target_instance_id": target_instance_id,
		"zone": zone,
		"from": "hand",
		"to": zone if zone != "" else ("attachment" if action_kind == "spice" else "environment" if action_kind == "environment" else "discard")
	}, group_id)
	var data := card(card_id)
	var activation_effects: Array = data.get("on_play", [])
	if action_kind in ["tool", "chef", "reaction"]:
		activation_effects = data.get("effects", [])
	if not activation_effects.is_empty():
		_queue_animation_event(state, "card_text_activation", {
			"side": side,
			"source_instance_id": instance_id,
			"card_id": card_id,
			"card_type": action_kind,
			"activation_label": "CARD EFFECT" if action_kind in ["tool", "chef", "reaction"] else "ON-PLAY EFFECT"
		}, group_id)
	return group_id


func _queue_unit_event(
	state: Dictionary,
	event_type: String,
	side: String,
	unit: Dictionary,
	reason: String,
	group_id: int = -1,
	source_zone: String = ""
) -> void:
	if unit.is_empty():
		return
	var resolved_zone := source_zone
	if resolved_zone == "":
		resolved_zone = _unit_zone(state[side], int(unit.get("instance_id", -1)))
	if bool(unit.get("is_token", false)) and event_type in ["destroy", "sacrifice"]:
		_queue_token_evaporation_event(state, side, unit, resolved_zone, "discard", reason, group_id, event_type)
		return
	_queue_animation_event(state, event_type, {
		"side": side,
		"instance_id": int(unit.get("instance_id", -1)),
		"card_id": String(unit.get("card_id", "")),
		"zone": resolved_zone,
		"reason": reason
	}, group_id)


func _queue_token_evaporation_event(
	state: Dictionary,
	side: String,
	unit: Dictionary,
	source_zone: String,
	attempted_destination: String,
	reason: String,
	group_id: int = -1,
	replaced_event_type: String = "return"
) -> void:
	if unit.is_empty():
		return
	_queue_animation_event(state, "evaporate", {
		"side": side,
		"instance_id": int(unit.get("instance_id", -1)),
		"card_id": String(unit.get("card_id", "")),
		"zone": source_zone,
		"attempted_destination": attempted_destination,
		"reason": reason,
		"replaced_event_type": replaced_event_type,
		"is_token": true
	}, group_id)


func _queue_heal_event(state: Dictionary, side: String, target_kind: String, instance_id: int, amount: int, group_id: int = -1) -> void:
	if amount <= 0:
		return
	_queue_animation_event(state, "heal", {
		"side": side,
		"target_kind": target_kind,
		"target_side": side,
		"target_instance_id": instance_id,
		"amount": amount
	}, group_id)


func _queue_buff_event(state: Dictionary, side: String, target: Dictionary, attack_delta: int, health_delta: int, group_id: int = -1) -> void:
	if target.is_empty() or (attack_delta == 0 and health_delta == 0):
		return
	_queue_animation_event(state, "buff", {
		"side": side,
		"target_kind": "unit",
		"target_side": side,
		"target_instance_id": int(target.get("instance_id", -1)),
		"attack_delta": attack_delta,
		"health_delta": health_delta
	}, group_id)


func _side_name(side: String) -> String:
	return "You" if side == "player" else "Opponent"
