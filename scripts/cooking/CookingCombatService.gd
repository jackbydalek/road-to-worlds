extends RefCounted
class_name CookingCombatService

const STARTING_LIFE := 25
const OPENING_HAND := 5
const PREP_SLOTS := 3
const PLATED_SLOTS := 2

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
	var state := {
		"turn": 1,
		"phase": "player_main" if has_playable_content() else "awaiting_cards",
		"first_player": first_side,
		"ai_difficulty": ai_difficulty if ai_difficulty in ["easy", "medium", "hard"] else "easy",
		"game_over": false,
		"winner": "",
		"next_instance_id": 1,
		"selected_ingredients": [],
		"selected_attacker": -1,
		"selected_spice_target": -1,
		"pending_discard": {},
		"pending_ability": {},
		"pending_search": {},
		"pending_choice": {},
		"pending_resume": {},
		"pending_reaction": {},
		"opponent_sequence": {},
		"visual_action_serial": 0,
		"last_visual_action": {},
		"reaction_skip": "",
		"search_queue": [],
		"message": "Add cards to data/cards.json to begin testing." if not has_playable_content() else "Play units to Prep or Plated. Only Plated cards can attack or be attacked.",
		"log": [],
		"player": _make_combatant(player_deck_id),
		"opponent": _make_combatant(opponent_deck_id)
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
	_log(state, "The cook-off begins. The opening chef cannot attack on their first turn.")
	return state


func play_card(state: Dictionary, hand_index: int, destination: String = "prep", target_instance_id: int = -1) -> Dictionary:
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
	var hand: Array = state.player.hand
	if hand_index < 0 or hand_index >= hand.size():
		return _message(state, "That card is no longer in your hand.")
	var data := card(String(hand[hand_index]))
	match String(data.get("card_type", "")):
		"ingredient":
			_play_ingredient(state, "player", hand_index, destination)
		"meal":
			_serve_meal(state, "player", hand_index, state.get("selected_ingredients", []), destination)
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
	if _ai_hand_trap_stops(state, "enemy_tool", "player"):
		_log(state, "%s is negated." % data.name)
		return state
	_resolve_effects(state, "player", data.get("effects", []), {})
	return state


func cancel_discard_cost(state: Dictionary) -> Dictionary:
	if state.get("pending_discard", {}).is_empty():
		return state
	state.pending_discard = {}
	return _message(state, "Discard payment cancelled. The Item remains in your hand.")


func activate_ability(state: Dictionary, source_instance_id: int, ability_id: String = "") -> Dictionary:
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
	state.player.hand.append(card_id)
	_shuffle(state.player.deck)
	state.pending_search = {}
	_log(state, "You add %s to your hand, then shuffle your deck." % String(card(card_id).get("name", card_id)))
	_advance_search_queue(state)
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
	else:
		for card_id in selected_cards:
			state[side].deck.append(card_id)
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
	if selected.has(instance_id):
		selected.erase(instance_id)
	else:
		selected.append(instance_id)
	state.selected_ingredients = selected
	state.selected_attacker = -1
	state.selected_spice_target = -1
	return _message(state, "%d recipe-ready ingredient%s selected." % [selected.size(), "" if selected.size() == 1 else "s"])


func select_attacker(state: Dictionary, instance_id: int) -> Dictionary:
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


func move_unit(state: Dictionary, instance_id: int, destination: String) -> Dictionary:
	if not _can_player_act(state) or (destination != "prep" and destination != "plated"):
		return state
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
	var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if state.player[destination].size() >= capacity:
		return _message(state, "%s is full." % destination.capitalize())
	var unit := _remove_unit(state.player, instance_id)
	if unit.is_empty():
		return state
	unit.ready = (destination == "plated" or bool(card(String(unit.card_id)).get("can_attack_from_prep", false))) and not _opening_attack_lock(state, "player")
	state.player[destination].append(unit)
	state.player.zone_move_used = true
	if destination == "plated":
		_resolve_effects(state, "player", card(String(unit.card_id)).get("on_move_to_plated", []), unit)
	_refresh_stat_auras(state)
	_clear_selections(state)
	return _message(state, "%s moves from %s to %s." % [unit.name, source_zone.capitalize(), destination.capitalize()])


func attack(state: Dictionary, target_instance_id: int = -1) -> Dictionary:
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
		var taunt_unit := _first_plated_with_keyword(state.opponent, "taunt")
		if not taunt_unit.is_empty() and int(taunt_unit.instance_id) != target_instance_id:
			return _message(state, "%s has Taunt and must be attacked first." % taunt_unit.name)
	state.pending_resume = {
		"type": "player_attack",
		"attacker_instance_id": attacker_id,
		"target_instance_id": target_instance_id
	}
	_resolve_effects(state, "player", card(String(attacker.card_id)).get("on_attack", []), attacker)
	if state.get("pending_choice", {}).is_empty():
		_resume_pending_action(state)
	return state


func end_player_turn(state: Dictionary, defer_opponent_turn: bool = false) -> Dictionary:
	if not _can_player_act(state):
		return state
	if not state.get("pending_discard", {}).is_empty():
		return _message(state, "Finish or cancel the pending discard cost before ending the turn.")
	if not state.get("pending_ability", {}).is_empty():
		return _message(state, "Choose a target or cancel the pending ability before ending the turn.")
	if not state.get("pending_search", {}).is_empty():
		return _message(state, "Choose a card from your deck or skip the pending search before ending the turn.")
	if not state.get("pending_choice", {}).is_empty():
		return _message(state, "Finish the highlighted card choice before ending the turn.")
	_resolve_end_turn_triggers(state, "player")
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
		var recipe_text := " + ".join(recipe)
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
		"life": STARTING_LIFE,
		"deck": deck_list,
		"hand": [],
		"prep": [],
		"plated": [],
		"environment": "",
		"discard": [],
		"meal_served": false,
		"chef_used": false,
		"zone_move_used": false,
		"chefs_disabled": false,
		"items_disabled": false,
		"hand_trap_used": false,
		"fatigue": 0,
		"turns_started": 0
	}


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
	var hand_index := int(eligible[0])
	var trap_id := String(state[defending_side].hand[hand_index])
	state[defending_side].hand.remove_at(hand_index)
	state[defending_side].discard.append(trap_id)
	state[defending_side].hand_trap_used = true
	if _consume_hand_trap_guard(state, acting_side):
		_log(state, "%s's Hand Trap is negated." % _side_name(defending_side))
		return false
	_log(state, "%s uses %s from hand." % [_side_name(defending_side), card(trap_id).get("name", trap_id)])
	return true


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
	if action_kind == "chef":
		state[side].chef_used = true
	elif action_kind == "tool":
		for unused in range(mini(int(data.get("discard_cost", 0)), state[side].hand.size())):
			state[side].discard.append(String(state[side].hand.pop_back()))


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
	var token := _make_unit(state, state[side], card("token_fresh_ingredient"), "prep", side)
	token.is_token = true
	state[side].prep.append(token)
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
	_log(state, "%s plays %s to %s." % [_side_name(side), data.name, destination.capitalize()])
	_resolve_effects(state, side, data.get("on_play", []), unit)
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
			_discard_unit_attachments(state.player, destroyed)
			_discard_unit_card(state.player, destroyed)
			_log(state, "%s is destroyed by the response." % data.name)
	return true


func _serve_meal(state: Dictionary, side: String, hand_index: int, requested_ids: Array, destination: String = "plated") -> bool:
	var who: Dictionary = state[side]
	if destination != "prep" and destination != "plated":
		destination = "plated"
	if bool(who.meal_served):
		_message(state, "%s has already served a Meal this turn." % _side_name(side))
		return false
	var card_id := String(who.hand[hand_index])
	var data := card(card_id)
	var recipe: Array = _effective_recipe(state, side, data)
	var chosen := requested_ids.duplicate()
	if chosen.is_empty():
		chosen = _find_recipe_ingredients(who, recipe)
	if not _selection_satisfies(who, chosen, recipe):
		_message(state, "Select recipe-ready ingredients matching: %s." % " + ".join(recipe))
		return false
	var required_meal_archetype := String(data.get("required_meal_archetype", ""))
	var recipe_meal := _find_recipe_meal(who, required_meal_archetype) if required_meal_archetype != "" else {}
	if required_meal_archetype != "" and recipe_meal.is_empty():
		_message(state, "Serving %s also requires a %s Meal." % [data.name, required_meal_archetype.capitalize()])
		return false
	var selected_destination_count := 0
	for instance_id in chosen:
		if not _find_unit_in_zone(who, destination, int(instance_id)).is_empty():
			selected_destination_count += 1
	if not recipe_meal.is_empty() and not _find_unit_in_zone(who, destination, int(recipe_meal.instance_id)).is_empty():
		selected_destination_count += 1
	var destination_capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
	if who[destination].size() - selected_destination_count + 1 > destination_capacity:
		_message(state, "%s is full. The recipe must use an ingredient there or an open slot." % destination.capitalize())
		return false
	var sacrificed_names: Array[String] = []
	var sacrificed_attack := 0
	var sacrificed_health := 0
	if not recipe_meal.is_empty():
		var removed_meal := _remove_unit(who, int(recipe_meal.instance_id))
		if not removed_meal.is_empty():
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
		sacrificed_names.append(String(removed.name))
		sacrificed_attack += int(removed.attack)
		sacrificed_health += int(removed.max_health)
		_resolve_effects(state, side, card(String(removed.card_id)).get("on_sacrifice", []), removed)
		_discard_unit_attachments(who, removed)
		_discard_unit_card(who, removed)
	who.hand.remove_at(hand_index)
	var meal := _make_unit(state, who, data, destination, side)
	meal.served_sacrifice_attack = sacrificed_attack
	meal.served_sacrifice_health = sacrificed_health
	if String(who.environment) != "":
		var environment_data := card(String(who.environment))
		meal.attack += int(environment_data.get("meal_attack_bonus", 0))
		meal.health += int(environment_data.get("meal_health_bonus", 0))
		meal.max_health += int(environment_data.get("meal_health_bonus", 0))
	who[destination].append(meal)
	who.meal_served = true
	_record_hand_play(state, side, card_id, "meal", int(meal.instance_id))
	_refresh_stat_auras(state)
	state.selected_ingredients = []
	_log(state, "%s sacrifices %s and serves %s to %s." % [_side_name(side), ", ".join(sacrificed_names), data.name, destination.capitalize()])
	_resolve_effects(state, side, data.get("on_play", []), meal)
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
		who.discard.append(String(who.hand.pop_back()))
	_log(state, "%s uses %s." % [_side_name(side), data.name])
	if side == "player" and _ai_hand_trap_stops(state, "enemy_tool", side):
		_log(state, "%s is negated." % data.name)
		return true
	_resolve_effects(state, side, data.get("effects", []), {})
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
	_log(state, "%s calls on %s." % [_side_name(side), data.name])
	if side == "player" and _ai_hand_trap_stops(state, "enemy_chef", side):
		_log(state, "%s is negated." % data.name)
		return true
	_resolve_effects(state, side, data.get("effects", []), {})
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
	_log(state, "%s seasons %s with %s." % [_side_name(side), target.name, data.name])
	state.selected_spice_target = -1
	return true


func _make_unit(state: Dictionary, combatant: Dictionary, data: Dictionary, zone: String, side: String) -> Dictionary:
	var unit := {
		"instance_id": int(state.next_instance_id),
		"card_id": String(data.id),
		"name": String(data.name),
		"card_type": String(data.card_type),
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
		"spices": []
	}
	state.next_instance_id = int(state.next_instance_id) + 1
	return unit


func _start_turn(state: Dictionary, side: String, draw_card: bool = true) -> void:
	var who: Dictionary = state[side]
	who.turns_started = int(who.turns_started) + 1
	who.meal_served = false
	who.chef_used = false
	who.zone_move_used = false
	who.hand_trap_used = false
	for unit in who.prep:
		unit.ready = bool(card(String(unit.card_id)).get("can_attack_from_prep", false)) and not _opening_attack_lock(state, side)
		unit.used_abilities = []
	for unit in who.plated:
		unit.ready = not _opening_attack_lock(state, side)
		unit.used_abilities = []
	if String(who.environment) != "":
		var growth := int(card(String(who.environment)).get("ingredient_growth", 0))
		if growth > 0:
			for zone_name in ["prep", "plated"]:
				for unit in who[zone_name]:
					if String(unit.card_type) == "ingredient":
						unit.attack += growth
						unit.health += growth
						unit.max_health += growth
	if draw_card:
		_draw(state, side)
	state.phase = "player_main" if side == "player" else "opponent_turn"


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
				_start_turn(state, "opponent")
				sequence.stage = "main"
				_log(state, "Opponent draws for their turn.")
				return state
			"main":
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
				if not bool(state.opponent.zone_move_used) and state.opponent.plated.size() < PLATED_SLOTS and not state.opponent.prep.is_empty():
					var moved: Dictionary = _ai_unit_to_plate(state)
					state.opponent.prep.erase(moved)
					moved.ready = true
					state.opponent.plated.append(moved)
					state.opponent.zone_move_used = true
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
				_clear_temporary_buffs(state.opponent)
				state.opponent_sequence = {}
				if not bool(state.game_over):
					state.turn = int(state.turn) + 1
					_start_turn(state, "player")
				return state
	return state


func _ai_play_one_hand_card(state: Dictionary) -> bool:
	if _ai_level(state) > 0:
		return _ai_play_best_hand_card(state)
	return _ai_play_first_hand_card(state)


func _ai_play_first_hand_card(state: Dictionary) -> bool:
	for hand_index in range(state.opponent.hand.size() - 1, -1, -1):
		var data := card(String(state.opponent.hand[hand_index]))
		var card_type := String(data.get("card_type", ""))
		if card_type == "environment":
			return _play_environment(state, "opponent", hand_index)
		if card_type == "meal" and not bool(state.opponent.meal_served):
			var recipe_units := _find_recipe_ingredients(state.opponent, _effective_recipe(state, "opponent", data))
			var required_meal := String(data.get("required_meal_archetype", ""))
			var has_required_meal := required_meal == "" or not _find_recipe_meal(state.opponent, required_meal).is_empty()
			if not recipe_units.is_empty() and has_required_meal:
				var meal_destination := "plated" if state.opponent.plated.size() < PLATED_SLOTS else "prep"
				return _serve_meal(state, "opponent", hand_index, recipe_units, meal_destination)
		if card_type == "ingredient":
			var destination := "prep" if state.opponent.prep.size() < PREP_SLOTS else "plated"
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
	var hand_index := int(best_action.hand_index)
	match String(best_action.action_kind):
		"environment":
			return _play_environment(state, "opponent", hand_index)
		"meal":
			return _serve_meal(state, "opponent", hand_index, best_action.get("recipe_units", []), String(best_action.get("destination", "plated")))
		"ingredient":
			return _play_ingredient(state, "opponent", hand_index, String(best_action.destination))
		"spice":
			return _play_spice(state, "opponent", hand_index, int(best_action.target_instance_id))
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
	match card_type:
		"environment":
			base.score = 38.0 if String(state.opponent.environment) == "" else 10.0
			return base
		"meal":
			if bool(state.opponent.meal_served):
				return {}
			var recipe := _effective_recipe(state, "opponent", data)
			var recipe_units := _find_low_value_recipe_ingredients(state.opponent, recipe) if _ai_level(state) >= 2 else _find_recipe_ingredients(state.opponent, recipe)
			var required_meal := String(data.get("required_meal_archetype", ""))
			if recipe_units.is_empty() or (required_meal != "" and _find_recipe_meal(state.opponent, required_meal).is_empty()):
				return {}
			var destination := "plated" if state.opponent.plated.size() < PLATED_SLOTS else "prep"
			var capacity := PLATED_SLOTS if destination == "plated" else PREP_SLOTS
			if state.opponent[destination].size() >= capacity and not _recipe_uses_zone_unit(state.opponent, recipe_units, destination):
				return {}
			base.recipe_units = recipe_units
			base.destination = destination
			base.score = 90.0 + float(int(data.get("attack", 0)) * 3 + int(data.get("health", 0))) + _ai_card_effect_value(data)
			if _ai_level(state) >= 2:
				base.score -= float(_unit_ids_board_value(state.opponent, recipe_units)) * 0.35
			return base
		"ingredient":
			var destination := "prep" if state.opponent.prep.size() < PREP_SLOTS else "plated"
			var capacity := PREP_SLOTS if destination == "prep" else PLATED_SLOTS
			if state.opponent[destination].size() >= capacity:
				return {}
			base.destination = destination
			base.score = 45.0 + float(int(data.get("attack", 0)) + int(data.get("health", 0))) + _ai_card_effect_value(data)
			return base
		"spice":
			var target := _best_unspiced_unit(state.opponent)
			if target.is_empty():
				return {}
			base.target_instance_id = int(target.instance_id)
			base.score = 58.0 + float(int(target.attack) * 2 + int(data.get("attack_bonus", 0)) * 5 + int(data.get("health_bonus", 0)) * 4)
			return base
		"tool":
			if bool(state.opponent.items_disabled) or state.opponent.hand.size() - 1 < int(data.get("discard_cost", 0)):
				return {}
			base.score = 68.0 + _ai_card_effect_value(data) - float(int(data.get("discard_cost", 0)) * 8)
			return base
		"chef":
			if bool(state.opponent.chef_used) or bool(state.opponent.chefs_disabled):
				return {}
			base.score = 72.0 + _ai_card_effect_value(data)
			return base
	return {}


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
				if String(requirement) != "any" and not card(String(ingredient.card_id)).get("ingredient_types", []).has(requirement):
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
		result.append(int(unit.instance_id))
	return result


func _ai_attack_with_unit(state: Dictionary, unit: Dictionary) -> void:
	unit.ready = false
	var target := {} if _unit_has_keyword(unit, "stalwart") else _ai_attack_target(state, unit)
	if target.is_empty():
		_resolve_effects(state, "opponent", card(String(unit.card_id)).get("on_attack", []), unit)
		_deal_chef_damage(state, "player", int(unit.attack), "opponent", true)
		if not state.get("pending_reaction", {}).is_empty():
			return
		if int(unit.attack) > 0:
			_resolve_effects(state, "opponent", card(String(unit.card_id)).get("on_combat_damage_to_chef", []), unit)
		_log(state, "%s hits you for %d." % [unit.name, unit.attack])
	else:
		_resolve_effects(state, "opponent", card(String(unit.card_id)).get("on_attack", []), unit)
		_resolve_unit_battle(state, "opponent", unit, target)
	_check_game_over(state)


func _ai_level(state: Dictionary) -> int:
	match String(state.get("ai_difficulty", "easy")):
		"hard":
			return 2
		"medium":
			return 1
	return 0


func _ai_unit_to_plate(state: Dictionary) -> Dictionary:
	if state.opponent.prep.is_empty() or _ai_level(state) == 0:
		return state.opponent.prep[0] if not state.opponent.prep.is_empty() else {}
	var best: Dictionary = state.opponent.prep[0]
	var best_score := -999999
	for unit in state.opponent.prep:
		var score := int(unit.attack) * 4 + int(unit.health)
		if String(unit.card_type) == "meal":
			score += 12
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
	var taunt_unit := _first_plated_with_keyword(state.player, "taunt")
	if not taunt_unit.is_empty() or _ai_level(state) == 0:
		return taunt_unit if not taunt_unit.is_empty() else _weakest_plated_unit(state.player)
	var best: Dictionary = state.player.plated[0]
	var best_score := -999999
	for target in state.player.plated:
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
	if not bool(state.opponent.zone_move_used) and state.opponent.plated.size() < PLATED_SLOTS and not state.opponent.prep.is_empty():
		var moved: Dictionary = _ai_unit_to_plate(state)
		state.opponent.prep.erase(moved)
		moved.ready = true
		state.opponent.plated.append(moved)
		state.opponent.zone_move_used = true
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
	var piercing_damage: int = maxi(0, attack_value - defender_health_before)
	if card(String(defender.card_id)).get("keywords", []).has("bodyguard"):
		piercing_damage = 0
	defender.health -= attack_value
	attacker.health -= defense_value
	_deal_chef_damage(state, defender_side, piercing_damage, attacker_side, true)
	if piercing_damage > 0:
		_resolve_effects(state, attacker_side, card(String(attacker.card_id)).get("on_combat_damage_to_chef", []), attacker, -1, false)
	if attack_value > 0:
		_resolve_effects(state, defender_side, card(String(defender.card_id)).get("on_damaged", []), defender, -1, false)
	if defense_value > 0:
		_resolve_effects(state, attacker_side, card(String(attacker.card_id)).get("on_damaged", []), attacker, -1, false)
	var piercing_text := " and pierces for %d" % piercing_damage if piercing_damage > 0 else ""
	_log(state, "%s battles %s%s." % [attacker.name, defender.name, piercing_text])
	_remove_defeated(state, attacker_side, defender_side, defender)
	_remove_defeated(state, defender_side, attacker_side, attacker)
	_refresh_stat_auras(state)


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
		if side == "player" and target_instance_id < 0 and String(effect.get("type", "")) in ["recover", "recycle"]:
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
		match String(effect.get("type", "")):
			"draw":
				for unused in range(amount):
					_draw(state, side)
			"heal_player":
				var player_healing := _healing_amount(state, side, amount)
				state[side].life = mini(STARTING_LIFE, int(state[side].life) + player_healing)
			"damage_enemy_player":
				_deal_chef_damage(state, enemy_side, amount, side, false)
			"discard_hand":
				for discarded_card in state[side].hand:
					state[side].discard.append(String(discarded_card))
				state[side].hand.clear()
			"discard_hand_then_draw_if_any":
				var discarded_count: int = state[side].hand.size()
				for discarded_card in state[side].hand:
					state[side].discard.append(String(discarded_card))
				state[side].hand.clear()
				if discarded_count > 0:
					for unused in range(amount):
						_draw(state, side)
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
						_deal_effect_damage_to_unit(state, side, enemy_side, unit, amount, source, false)
				_remove_defeated(state, enemy_side, side, source)
			"damage_all_enemy_plated":
				for unit in state[enemy_side].plated.duplicate():
					_deal_effect_damage_to_unit(state, side, enemy_side, unit, amount, source, false)
				_remove_defeated(state, enemy_side, side, source)
			"damage_all_plated_units":
				for affected_side in ["player", "opponent"]:
					for unit in state[affected_side].plated.duplicate():
						_deal_effect_damage_to_unit(state, side, affected_side, unit, amount, source, false)
					_remove_defeated(state, affected_side, side, source)
			"heal_all_friendly_units":
				var group_healing := _healing_amount(state, side, amount)
				for zone_name in ["prep", "plated"]:
					for unit in state[side][zone_name]:
						if bool(effect.get("exclude_self", false)) and not source.is_empty() and int(unit.instance_id) == int(source.instance_id):
							continue
						unit.health = mini(int(unit.max_health), int(unit.health) + group_healing)
			"search":
				if side == "player":
					_queue_player_search(state, effect)
				else:
					_search_deck(state[side], effect)
			"look_and_take":
				if side == "player":
					_queue_player_search(state, effect, true)
				else:
					_look_and_take(state[side], effect)
			"deploy_enemy_hand_unit":
				var enemy_hand_candidates := _valid_opponent_hand_indices(state, side, effect)
				if not enemy_hand_candidates.is_empty():
					_deploy_enemy_hand_unit(state, side, int(enemy_hand_candidates[0]))
			"recover":
				_recover_from_discard(state[side], effect)
			"recycle":
				_recycle_from_discard(state[side], amount)
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
				_return_enemy_ingredient(state[enemy_side], target_instance_id)
			"disable_enemy_chefs_next_turn":
				state[enemy_side].chefs_disabled = true
			"disable_enemy_items_next_turn":
				state[enemy_side].items_disabled = true
			"buff_self":
				if not source.is_empty():
					source.attack += int(effect.get("attack", 0))
					source.health += int(effect.get("health", 0))
					source.max_health += int(effect.get("health", 0))
			"buff_friendly_unit":
				var buff_target := _find_unit(state[side], target_instance_id) if target_instance_id >= 0 else _first_friendly_unit(state[side])
				if not buff_target.is_empty():
					buff_target.attack += int(effect.get("attack", 0))
					buff_target.health += int(effect.get("health", 0))
					buff_target.max_health += int(effect.get("health", 0))
			"buff_friendly_plated":
				if not state[side].plated.is_empty():
					var plated_buff_target: Dictionary = _find_unit_in_zone(state[side], "plated", target_instance_id) if target_instance_id >= 0 else state[side].plated[0]
					var attack_bonus := int(effect.get("attack", 0))
					plated_buff_target.attack += attack_bonus
					if String(effect.get("duration", "")) == "end_turn":
						plated_buff_target.temporary_attack = int(plated_buff_target.get("temporary_attack", 0)) + attack_bonus
			"heal_unit":
				var heal_target := _find_unit(state[side], target_instance_id) if target_instance_id >= 0 else _most_damaged_friendly_unit(state[side])
				if not heal_target.is_empty():
					heal_target.health = mini(int(heal_target.max_health), int(heal_target.health) + _healing_amount(state, side, amount))
			"heal_self":
				if not source.is_empty() and not _find_unit(state[side], int(source.get("instance_id", -1))).is_empty():
					source.health = mini(int(source.max_health), int(source.health) + _healing_amount(state, side, amount))
			"discard_top_then_buff_if_unit":
				if not state[side].deck.is_empty():
					var discarded_id := String(state[side].deck.pop_back())
					state[side].discard.append(discarded_id)
					_log(state, "%s discards %s from the top of the deck." % [_side_name(side), card(discarded_id).get("name", discarded_id)])
					if String(card(discarded_id).get("card_type", "")) in ["ingredient", "meal"] and not source.is_empty():
						source.attack += int(effect.get("attack", 0))
						source.health += int(effect.get("health", 0))
						source.max_health += int(effect.get("health", 0))
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
					_log(state, "%s creates %s in %s." % [_side_name(side), token_data.name, token_zone.capitalize()])
			"damage_enemy_unit":
				var any_damage_target := _find_unit(state[enemy_side], target_instance_id) if target_instance_id >= 0 else _first_enemy_unit(state[enemy_side], effect)
				if not any_damage_target.is_empty():
					_deal_effect_damage_to_unit(state, side, enemy_side, any_damage_target, amount, source)
			"absorb_all_friendly_units":
				if not source.is_empty():
					var absorbed_attack := int(source.get("served_sacrifice_attack", 0))
					var absorbed_health := int(source.get("served_sacrifice_health", 0))
					var absorb_ids: Array[int] = []
					for zone_name in ["prep", "plated"]:
						for unit in state[side][zone_name]:
							if int(unit.instance_id) != int(source.instance_id):
								absorb_ids.append(int(unit.instance_id))
					for absorb_id in absorb_ids:
						var absorbed := _remove_unit(state[side], absorb_id)
						if absorbed.is_empty():
							continue
						absorbed_attack += int(absorbed.attack)
						absorbed_health += int(absorbed.max_health)
						_resolve_effects(state, side, card(String(absorbed.card_id)).get("on_sacrifice", []), absorbed)
						_discard_unit_attachments(state[side], absorbed)
						_discard_unit_card(state[side], absorbed)
					source.attack += absorbed_attack
					source.health += absorbed_health
					source.max_health += absorbed_health
			"copy_prep_activated_ability":
				var copied_target := _find_unit_in_zone(state[side], "prep", target_instance_id)
				if not copied_target.is_empty():
					var copied_ability := _first_copyable_ability(card(String(copied_target.card_id)))
					if not copied_ability.is_empty():
						if bool(copied_ability.get("cost", {}).get("sacrifice_self", false)) and not source.is_empty():
							var copied_cost_unit := _remove_unit(state[side], int(source.instance_id))
							if not copied_cost_unit.is_empty():
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
		"move_friendly_to_prep",
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
		"damage_enemy_prep":
			target_side = enemy_side
			zones = ["prep"]
		"damage_enemy_plated":
			target_side = enemy_side
			zones = ["plated"]
		"damage_enemy_unit":
			target_side = enemy_side
		"return_enemy_ingredient", "destroy_enemy_unit", "remove_enemy_spice":
			target_side = enemy_side
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
			if required_archetype != "" and String(card(String(unit.card_id)).get("archetype", "")) != required_archetype:
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
		"damage_enemy_prep":
			return "Choose an opposing Prep card to damage."
		"damage_enemy_unit":
			return "Choose an opposing unit to damage."
		"damage_enemy_plated":
			return "Choose an opposing Plated unit to damage."
		"move_friendly_to_prep":
			return "Choose a friendly Spicy Plated card to move to Prep."
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
	var target_instance_id := int(pending.get("target_instance_id", -1))
	attacker.ready = false
	if target_instance_id < 0:
		_deal_chef_damage(state, "opponent", int(attacker.attack), "player", true)
		if int(attacker.attack) > 0:
			_resolve_effects(state, "player", card(String(attacker.card_id)).get("on_combat_damage_to_chef", []), attacker)
		_log(state, "%s hits the opposing chef for %d." % [attacker.name, attacker.attack])
	else:
		var defender := _find_unit_in_zone(state.opponent, "plated", target_instance_id)
		if not defender.is_empty():
			_resolve_unit_battle(state, "player", attacker, defender)
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
	var sacrificed := false
	if bool(ability.get("cost", {}).get("sacrifice_self", false)):
		var removed := _remove_unit(state[side], source_instance_id)
		if removed.is_empty():
			return _message(state, "%s could not be sacrificed." % source_name)
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


func _draw(state: Dictionary, side: String, fatigue_enabled: bool = true) -> void:
	var who: Dictionary = state[side]
	if who.deck.is_empty():
		if fatigue_enabled:
			who.fatigue = int(who.fatigue) + 1
			who.life -= int(who.fatigue)
			_log(state, "%s takes %d fatigue damage." % [_side_name(side), who.fatigue])
			_check_game_over(state)
		return
	who.hand.append(who.deck.pop_back())


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
				if String(requirement) == "any" or card(String(ingredient.card_id)).get("ingredient_types", []).has(requirement):
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
			if String(card(String(unit.card_id)).get("archetype", "")) == required_archetype:
				return unit
	return {}


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


func _deal_chef_damage(state: Dictionary, target_side: String, amount: int, source_side: String = "", combat_damage: bool = false) -> void:
	if amount <= 0:
		return
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
	remove_defeated: bool = true
) -> bool:
	if target.is_empty() or amount <= 0:
		return false
	if _effect_damage_is_prevented(state, target_side, target):
		_log(state, "%s protects %s from effect damage." % [_side_name(target_side), target.name])
		return false
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
							if String(card(String(prep_unit.card_id)).get("archetype", "")) == counted_archetype:
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


func _unit_has_keyword(unit: Dictionary, keyword: String) -> bool:
	if unit.is_empty():
		return false
	return card(String(unit.get("card_id", ""))).get("keywords", []).has(keyword)


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
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	var required_archetype := String(effect.get("archetype", ""))
	var candidate := card(candidate_id)
	var candidate_type := String(candidate.get("card_type", ""))
	if required_type != "" and candidate_type != required_type:
		return false
	if not allowed_types.is_empty() and not allowed_types.has(candidate_type):
		return false
	if required_archetype != "" and String(candidate.get("archetype", "")) != required_archetype:
		return false
	return true


func _search_deck(combatant: Dictionary, effect: Dictionary) -> void:
	for index in range(combatant.deck.size() - 1, -1, -1):
		var candidate_id := String(combatant.deck[index])
		if not _card_matches_search(candidate_id, effect):
			continue
		combatant.hand.append(candidate_id)
		combatant.deck.remove_at(index)
		break
	_shuffle(combatant.deck)


func _look_and_take(combatant: Dictionary, effect: Dictionary) -> void:
	for candidate_id in _top_deck_cards(combatant, int(effect.get("count", 0))):
		if not _card_matches_search(candidate_id, effect):
			continue
		var deck_index: int = combatant.deck.rfind(candidate_id)
		if deck_index >= 0:
			combatant.hand.append(candidate_id)
			combatant.deck.remove_at(deck_index)
		break
	_shuffle(combatant.deck)


func _recover_from_discard(combatant: Dictionary, effect: Dictionary) -> void:
	var remaining := int(effect.get("amount", 1))
	var allowed_types: Array = effect.get("card_types", [])
	var required_type := String(effect.get("card_type", ""))
	for index in range(combatant.discard.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var candidate_id := String(combatant.discard[index])
		var candidate_type := String(card(candidate_id).get("card_type", ""))
		if required_type != "" and candidate_type != required_type:
			continue
		if not allowed_types.is_empty() and not allowed_types.has(candidate_type):
			continue
		combatant.hand.append(candidate_id)
		combatant.discard.remove_at(index)
		remaining -= 1


func _recycle_from_discard(combatant: Dictionary, amount: int) -> void:
	for unused in range(mini(amount, combatant.discard.size())):
		combatant.deck.append(String(combatant.discard.pop_back()))
	_shuffle(combatant.deck)


func _count_controlled_archetype(combatant: Dictionary, archetype: String) -> int:
	var count := 0
	for zone_name in ["prep", "plated"]:
		for unit in combatant[zone_name]:
			if String(card(String(unit.card_id)).get("archetype", "")) == archetype:
				count += 1
	return count


func _return_enemy_ingredient(combatant: Dictionary, target_instance_id: int = -1) -> void:
	for zone_name in ["prep", "plated"]:
		for index in range(combatant[zone_name].size()):
			var unit: Dictionary = combatant[zone_name][index]
			if String(unit.card_type) == "ingredient":
				if target_instance_id >= 0 and int(unit.instance_id) != target_instance_id:
					continue
				_discard_unit_attachments(combatant, unit)
				combatant.hand.append(String(unit.card_id))
				combatant[zone_name].remove_at(index)
				return


func _weakest_plated_unit(combatant: Dictionary) -> Dictionary:
	if combatant.plated.is_empty():
		return {}
	var taunt_unit := _first_plated_with_keyword(combatant, "taunt")
	if not taunt_unit.is_empty():
		return taunt_unit
	var weakest: Dictionary = combatant.plated[0]
	for unit in combatant.plated:
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


func _side_name(side: String) -> String:
	return "You" if side == "player" else "Opponent"
