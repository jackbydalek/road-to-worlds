extends RefCounted
class_name CombatService

const STARTING_LIFE := 20
const OPENING_HAND_SIZE := 5
const MAX_FOCUS := 8
const MAX_HAND_SIZE := 8
const MAX_BOARD_SIZE := 5
const MAX_ENGINES := 3
const MAX_TURNS := 24

var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var rng := RandomNumberGenerator.new()
var next_unit_id := 1


func setup(card_database: Dictionary, archetype_database: Dictionary) -> void:
	cards_by_id = card_database
	archetypes_by_id = archetype_database


func auto_play_game(player_deck: Dictionary, player_archetype: String, opponent_deck: Dictionary, opponent_archetype: String, seed_value: int = 0) -> Dictionary:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	next_unit_id = 1
	var state := _create_game_state(player_deck, player_archetype, opponent_deck, opponent_archetype)
	_log(state, "Combat test begins: %s vs %s." % [_archetype_name(player_archetype), _archetype_name(opponent_archetype)])

	for i in range(OPENING_HAND_SIZE):
		_draw_card(state, state["player"], false, false)
		_draw_card(state, state["opponent"], false, false)

	_log(state, "Opening hands drawn. Player has %d cards; opponent has %d." % [state["player"]["hand"].size(), state["opponent"]["hand"].size()])

	while not bool(state["game_over"]) and int(state["turn"]) <= MAX_TURNS:
		_take_turn(state, "player")
		if bool(state["game_over"]):
			break
		_take_turn(state, "opponent")
		state["turn"] = int(state["turn"]) + 1

	if not bool(state["game_over"]):
		_break_stalemate(state)

	_log(state, "Combat test finished. Winner: %s." % String(state["winner"]).capitalize())
	return state


func start_manual_game(player_deck: Dictionary, player_archetype: String, opponent_deck: Dictionary, opponent_archetype: String, seed_value: int = 0) -> Dictionary:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	next_unit_id = 1
	var state := _create_game_state(player_deck, player_archetype, opponent_deck, opponent_archetype)
	state["mode"] = "manual"
	state["phase"] = "player_main"
	state["active_side"] = "player"
	state["seed"] = seed_value
	_log(state, "Manual battle begins: %s vs %s." % [_archetype_name(player_archetype), _archetype_name(opponent_archetype)])

	for i in range(OPENING_HAND_SIZE):
		_draw_card(state, state["player"], false, false)
		_draw_card(state, state["opponent"], false, false)

	_log(state, "Opening hands drawn. Your first turn begins.")
	_begin_manual_player_turn(state)
	return state


func manual_play_card(state: Dictionary, card_id: String) -> Dictionary:
	return manual_play_card_with_target(state, card_id, "auto", -1)


func manual_play_card_with_target(state: Dictionary, card_id: String, target_type: String, target_instance_id: int = -1) -> Dictionary:
	if not _manual_state_accepts_player_action(state):
		return state

	var player: Dictionary = state["player"]
	var opponent: Dictionary = state["opponent"]
	if not _validate_manual_card_play(state, player, opponent, card_id, target_type, target_instance_id):
		return state

	_play_card(state, player, opponent, card_id, target_type, target_instance_id)
	_set_manual_phase_after_action(state)
	return state


func manual_attack(state: Dictionary, instance_id: int, target_mode: String) -> Dictionary:
	if not _manual_state_accepts_player_action(state):
		return state

	var player: Dictionary = state["player"]
	var opponent: Dictionary = state["opponent"]
	var attacker := _find_unit_by_instance_id(player, instance_id)
	if attacker.is_empty():
		_log(state, "That threat is no longer on your board.")
		return state
	if not bool(attacker.get("ready", false)):
		_log(state, "%s is not ready to attack." % attacker.get("name", "That threat"))
		return state

	var target := {}
	if target_mode == "best":
		target = _choose_attack_target(player, opponent, attacker)
	else:
		var guard := _find_guard(opponent)
		if not guard.is_empty():
			target = guard

	_resolve_single_attack(state, player, opponent, attacker, target)
	_set_manual_phase_after_action(state)
	return state


func manual_attack_target(state: Dictionary, instance_id: int, target_type: String, target_instance_id: int = -1) -> Dictionary:
	if not _manual_state_accepts_player_action(state):
		return state

	var player: Dictionary = state["player"]
	var opponent: Dictionary = state["opponent"]
	var attacker := _find_unit_by_instance_id(player, instance_id)
	if attacker.is_empty():
		_log(state, "That threat is no longer on your board.")
		return state
	if not bool(attacker.get("ready", false)):
		_log(state, "%s is not ready to attack." % attacker.get("name", "That threat"))
		return state

	var target: Dictionary = {}
	match target_type:
		"face":
			var guard := _find_guard(opponent)
			if not guard.is_empty():
				_log(state, "%s blocks attacks on the opponent." % guard.get("name", "A guard"))
				return state
		"unit":
			target = _find_unit_by_instance_id(opponent, target_instance_id)
			if target.is_empty():
				_log(state, "That target is no longer on the opposing board.")
				return state
		_:
			_log(state, "Choose a valid attack target.")
			return state

	_resolve_single_attack(state, player, opponent, attacker, target)
	_set_manual_phase_after_action(state)
	return state


func manual_activate_unit_ability(state: Dictionary, instance_id: int, ability_index: int) -> Dictionary:
	if not _manual_state_accepts_player_action(state):
		return state

	var player: Dictionary = state["player"]
	var opponent: Dictionary = state["opponent"]
	var unit := _find_unit_by_instance_id(player, instance_id)
	if unit.is_empty():
		_log(state, "That threat is no longer on your board.")
		return state

	if not _activate_unit_ability(state, player, opponent, unit, ability_index):
		return state

	_set_manual_phase_after_action(state)
	return state


func manual_end_player_turn(state: Dictionary) -> Dictionary:
	if bool(state.get("game_over", false)):
		return state
	if String(state.get("active_side", "")) != "player":
		return state

	state["phase"] = "opponent_turn"
	_log(state, "You end the turn.")
	_end_turn(state, state["player"])
	_discard_to_hand_size(state, state["player"])
	_check_game_over(state)
	if bool(state["game_over"]):
		state["phase"] = "game_over"
		return state

	_take_turn(state, "opponent")
	if bool(state["game_over"]):
		state["phase"] = "game_over"
		return state

	state["turn"] = int(state["turn"]) + 1
	_begin_manual_player_turn(state)
	return state


func _create_game_state(player_deck: Dictionary, player_archetype: String, opponent_deck: Dictionary, opponent_archetype: String) -> Dictionary:
	return {
		"turn": 1,
		"game_over": false,
		"winner": "",
		"log": [],
		"player": _create_combatant("You", player_archetype, player_deck),
		"opponent": _create_combatant("Opponent", opponent_archetype, opponent_deck)
	}


func _create_combatant(display_name: String, archetype_id: String, deck_counts: Dictionary) -> Dictionary:
	var deck := _expand_deck(deck_counts)
	_shuffle_deck(deck)
	return {
		"name": display_name,
		"archetype": archetype_id,
		"life": STARTING_LIFE,
		"max_focus": 0,
		"focus": 0,
		"restricted_focus": {},
		"turns_taken": 0,
		"deck": deck,
		"hand": [],
		"discard": [],
		"board": [],
		"engines": [],
		"fatigue": 0
	}


func _expand_deck(deck_counts: Dictionary) -> Array:
	var deck: Array = []
	for card_id in deck_counts.keys():
		for i in range(int(deck_counts[card_id])):
			deck.append(String(card_id))
	return deck


func _shuffle_deck(deck: Array) -> void:
	for index in range(deck.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held_card = deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = held_card


func _take_turn(state: Dictionary, side: String) -> void:
	var active: Dictionary = state[side]
	var enemy_side := "opponent" if side == "player" else "player"
	var enemy: Dictionary = state[enemy_side]

	_prepare_turn(state, active)
	_play_main_phase(state, active, enemy)
	_activate_abilities_phase(state, active, enemy)
	_play_main_phase(state, active, enemy)
	_attack_phase(state, active, enemy)
	_end_turn(state, active)
	_discard_to_hand_size(state, active)
	_check_game_over(state)


func _begin_manual_player_turn(state: Dictionary) -> void:
	if int(state["turn"]) > MAX_TURNS:
		_break_stalemate(state)
		state["phase"] = "game_over"
		return

	state["active_side"] = "player"
	state["phase"] = "player_main"
	_prepare_turn(state, state["player"])
	_check_game_over(state)
	_set_manual_phase_after_action(state)


func _prepare_turn(state: Dictionary, active: Dictionary) -> void:
	active["turns_taken"] = int(active["turns_taken"]) + 1
	active["max_focus"] = min(MAX_FOCUS, int(active["max_focus"]) + 1)
	active["focus"] = int(active["max_focus"])
	active["restricted_focus"] = {}

	for unit in active["board"]:
		if int(unit.get("stunned_turns", 0)) > 0:
			unit["ready"] = false
			unit["stunned_turns"] = int(unit.get("stunned_turns", 0)) - 1
		else:
			unit["ready"] = true

	_log(state, "%s turn %d: %d focus." % [active["name"], int(active["turns_taken"]), int(active["focus"])])
	_resolve_engine_triggers(state, active, "start_turn")
	_resolve_unit_triggers(state, active, "start_turn")
	_draw_card(state, active, true)


func _end_turn(state: Dictionary, active: Dictionary) -> void:
	_resolve_engine_triggers(state, active, "end_turn")
	_resolve_unit_triggers(state, active, "end_turn")
	_expire_temporary_effects(state, active)
	_cleanup_dead_units(state, active)


func _resolve_engine_triggers(state: Dictionary, active: Dictionary, timing: String = "start_turn") -> void:
	for engine in active["engines"]:
		var card: Dictionary = cards_by_id[engine["card_id"]]
		var combat: Dictionary = _combat_data(card)
		var resolved_trigger := false
		var trigger_index := 0
		for trigger in combat.get("triggers", []):
			if String(trigger.get("timing", "start_turn")) != timing:
				trigger_index += 1
				continue
			var enemy: Dictionary = _enemy_for_combatant(state, active)
			if not _trigger_condition_met(trigger, card, active, enemy, {}, {}):
				trigger_index += 1
				continue
			if not _mark_trigger_ready(engine, trigger, timing, trigger_index, active):
				trigger_index += 1
				continue
			_resolve_effects(state, active, enemy, trigger.get("effects", []), {}, card, {}, {})
			resolved_trigger = true
			trigger_index += 1

		if timing == "start_turn" and not resolved_trigger and combat.get("triggers", []).is_empty():
			var stats: Dictionary = card.get("stats", {})
			var advantage := int(max(1.0, ceil(float(stats.get("advantage", 1)) / 3.0)))
			for i in range(advantage):
				_draw_card(state, active, false)
			_log(state, "%s engine %s draws %d." % [active["name"], card.get("name", engine["card_id"]), advantage])


func _resolve_unit_triggers(state: Dictionary, active: Dictionary, timing: String, context: Dictionary = {}) -> void:
	var units: Array = active["board"].duplicate()
	for unit in units:
		if not active["board"].has(unit):
			continue
		var card_id := String(unit.get("card_id", ""))
		if not cards_by_id.has(card_id):
			continue
		var card: Dictionary = cards_by_id[card_id]
		_resolve_card_triggers(state, active, card, unit, timing, context)


func _resolve_card_triggers(state: Dictionary, active: Dictionary, card: Dictionary, source_unit: Dictionary, timing: String, context: Dictionary = {}) -> void:
	var combat: Dictionary = _combat_data(card)
	var trigger_index := 0
	for trigger in combat.get("triggers", []):
		if String(trigger.get("timing", "")) != timing:
			trigger_index += 1
			continue
		var enemy: Dictionary = _enemy_for_combatant(state, active)
		if not _trigger_condition_met(trigger, card, active, enemy, source_unit, context):
			trigger_index += 1
			continue
		if not _mark_trigger_ready(source_unit, trigger, timing, trigger_index, active):
			trigger_index += 1
			continue
		_resolve_effects(state, active, enemy, trigger.get("effects", []), {}, card, source_unit, context)
		trigger_index += 1


func _resolve_played_card_triggers(state: Dictionary, active: Dictionary, played_card: Dictionary) -> void:
	var context := {
		"played_card_id": String(played_card.get("id", "")),
		"played_card_cost": int(played_card.get("cost", 0)),
		"played_card_archetype": String(played_card.get("archetype", "")),
		"played_card_role": String(played_card.get("role", ""))
	}
	_resolve_engine_triggers_with_context(state, active, "on_card_played", context)
	_resolve_unit_triggers(state, active, "on_card_played", context)


func _resolve_engine_triggers_with_context(state: Dictionary, active: Dictionary, timing: String, context: Dictionary) -> void:
	for engine in active["engines"]:
		var card: Dictionary = cards_by_id[engine["card_id"]]
		var combat: Dictionary = _combat_data(card)
		var trigger_index := 0
		for trigger in combat.get("triggers", []):
			if String(trigger.get("timing", "")) != timing:
				trigger_index += 1
				continue
			var enemy: Dictionary = _enemy_for_combatant(state, active)
			if not _trigger_condition_met(trigger, card, active, enemy, {}, context):
				trigger_index += 1
				continue
			if not _mark_trigger_ready(engine, trigger, timing, trigger_index, active):
				trigger_index += 1
				continue
			_resolve_effects(state, active, enemy, trigger.get("effects", []), {}, card, {}, context)
			trigger_index += 1


func _mark_trigger_ready(permanent: Dictionary, trigger: Dictionary, timing: String, trigger_index: int, active: Dictionary) -> bool:
	if not bool(trigger.get("oncePerTurn", false)):
		return true

	var fired: Dictionary = permanent.get("fired_triggers", {})
	var trigger_id := String(trigger.get("id", "%s_%d" % [timing, trigger_index]))
	var key := "%s:%d" % [trigger_id, int(active.get("turns_taken", 0))]
	if fired.has(key):
		return false
	fired[key] = true
	permanent["fired_triggers"] = fired
	return true


func _trigger_condition_met(trigger: Dictionary, source_card: Dictionary, active: Dictionary, enemy: Dictionary, source_unit: Dictionary = {}, context: Dictionary = {}) -> bool:
	if not trigger.has("condition"):
		return true
	return _effect_condition_met(trigger, source_card, active, enemy, source_unit, context)


func _play_main_phase(state: Dictionary, active: Dictionary, enemy: Dictionary) -> void:
	var played_any := true
	var safety := 0
	while played_any and safety < 20:
		safety += 1
		played_any = false
		var card_id := _choose_card_to_play(active, enemy)
		if card_id == "":
			break
		if _play_card(state, active, enemy, card_id):
			played_any = true


func _activate_abilities_phase(state: Dictionary, active: Dictionary, enemy: Dictionary) -> void:
	var safety := 0
	var activated_any := true
	while activated_any and safety < 20:
		safety += 1
		activated_any = false
		var best_unit := {}
		var best_index := -1
		var best_score := 0.0
		for unit in active["board"]:
			var card_id := String(unit.get("card_id", ""))
			if not cards_by_id.has(card_id):
				continue
			var card: Dictionary = cards_by_id[card_id]
			var abilities: Array = _combat_data(card).get("abilities", [])
			for index in range(abilities.size()):
				var ability: Dictionary = abilities[index]
				if not _ability_can_activate(state, active, enemy, unit, card, ability, index, false):
					continue
				var score := _ability_score(active, enemy, unit, card, ability)
				if score > best_score:
					best_score = score
					best_unit = unit
					best_index = index
		if best_index >= 0 and not best_unit.is_empty():
			activated_any = _activate_unit_ability(state, active, enemy, best_unit, best_index)


func _choose_card_to_play(active: Dictionary, enemy: Dictionary) -> String:
	var best_card := ""
	var best_score := -9999.0
	for card_id in active["hand"]:
		var card: Dictionary = cards_by_id[card_id]
		if int(card.get("cost", 0)) > _available_focus_for_card(active, card):
			continue
		if _combat_type(card) == "threat" and active["board"].size() >= MAX_BOARD_SIZE:
			continue
		if _combat_type(card) == "engine" and active["engines"].size() >= MAX_ENGINES:
			continue
		if _combat_type(card) == "action" and not _action_auto_target_available(card, enemy):
			continue

		var score := _play_score(card, active, enemy)
		if score > best_score:
			best_score = score
			best_card = String(card_id)
	return best_card


func _play_score(card: Dictionary, active: Dictionary, enemy: Dictionary) -> float:
	var stats: Dictionary = card.get("stats", {})
	var combat: Dictionary = _combat_data(card)
	var score := float(card.get("value", 1)) * 0.8 - float(card.get("cost", 0)) * 0.35
	match _combat_type(card):
		"threat":
			var attack := float(combat.get("attack", stats.get("power", 0)))
			var health := float(combat.get("health", stats.get("resilience", 0)))
			score += attack + health * 0.7
			score += _effects_play_score(active, enemy, combat.get("onPlay", []), card)
			if active["archetype"] == "redline_aggro":
				score += float(stats.get("speed", 0)) * 1.4
			if active["archetype"] == "verdant_midrange":
				score += float(stats.get("resilience", 0)) * 0.8
		"action":
			score += _effects_play_score(active, enemy, combat.get("effects", []), card)
			score += float(stats.get("interaction", 0)) * 0.7 + float(stats.get("consistency", 0)) * 0.5
			if enemy["board"].size() > 0:
				score += 3.0
			if _action_target_mode(card) != "enemy_unit" and int(enemy["life"]) <= _action_damage(card, enemy):
				score += 100.0
		"engine":
			for trigger in combat.get("triggers", []):
				score += _effects_play_score(active, enemy, trigger.get("effects", []), card) * 0.8
			score += float(stats.get("advantage", 0)) * 1.2
			if active["archetype"] == "lantern_control":
				score += 2.0
	return score


func _combat_data(card: Dictionary) -> Dictionary:
	return card.get("combat", {})


func _action_target_mode(card: Dictionary) -> String:
	var combat: Dictionary = _combat_data(card)
	if combat.has("targetMode"):
		return String(combat.get("targetMode", "none"))

	var role := String(card.get("role", "answer"))
	match role:
		"answer", "tech":
			return "any_enemy"
		"filter":
			return "none"
		_:
			return "enemy_player"


func _action_auto_target_available(card: Dictionary, enemy: Dictionary) -> bool:
	match _action_target_mode(card):
		"enemy_unit":
			return not enemy["board"].is_empty()
		_:
			return true


func _effects_play_score(active: Dictionary, enemy: Dictionary, effects: Array, source_card: Dictionary) -> float:
	var score := 0.0
	for effect_value in effects:
		var effect: Dictionary = effect_value
		if not _effect_condition_met(effect, source_card, active, enemy):
			continue

		var amount := float(_effect_amount(effect, active, enemy, source_card))
		match String(effect.get("type", "")):
			"damage":
				score += _damage_effect_score(active, enemy, effect)
			"draw":
				score += amount * 2.2
			"heal":
				var missing_life: int = STARTING_LIFE - int(active.get("life", STARTING_LIFE))
				score += min(amount, float(missing_life)) * 1.5
			"summon":
				score += float(effect.get("attack", 1)) + float(effect.get("health", 1)) * 0.8
			"buff":
				if not active["board"].is_empty():
					var attack_delta := float(effect.get("amount_attack", effect.get("amount", 0)))
					var health_delta := float(effect.get("amount_health", effect.get("amount", 0)))
					score += (attack_delta * 1.4 + health_delta) * max(1, active["board"].size())
			"debuff":
				if not enemy["board"].is_empty():
					score += (float(effect.get("amount_attack", effect.get("amount", 0))) * 1.4 + float(effect.get("amount_health", effect.get("amount", 0)))) * 1.2
			"destroy":
				var target := _choose_action_target(enemy)
				if not target.is_empty():
					score += 8.0 + float(target.get("attack", 0)) + float(target.get("health", 0))
			"exhaust":
				var target := _choose_action_target(enemy)
				if not target.is_empty():
					score += float(target.get("attack", 0)) * 1.6 + 2.0
			"discard":
				score += min(amount, float(enemy["hand"].size())) * 2.0
			"recover":
				score += min(amount, float(active["discard"].size())) * 1.8
			"grant_keyword":
				if not active["board"].is_empty():
					score += 2.5
			"gain_focus":
				score += amount * 2.2
	return score


func _damage_effect_score(active: Dictionary, enemy: Dictionary, effect: Dictionary) -> float:
	var amount := float(_effect_amount(effect, active, enemy))
	match String(effect.get("target", "selected")):
		"enemy_player":
			var score := amount * 2.0
			if int(enemy.get("life", STARTING_LIFE)) <= int(amount):
				score += 100.0
			return score
		"self_player":
			return -amount * 1.5
		"all_enemy_units":
			return amount * max(1, enemy["board"].size()) * 1.8
		"selected", "best_enemy_unit", "weakest_enemy_unit":
			if enemy["board"].is_empty():
				return 0.0
			var target := _choose_action_target(enemy)
			var target_value := float(target.get("attack", 0)) * 1.7 + float(target.get("health", 0))
			if int(target.get("health", 0)) <= int(amount):
				target_value += 4.0
			return min(amount * 2.0 + target_value, 18.0)
		_:
			return amount


func _validate_manual_card_play(state: Dictionary, player: Dictionary, opponent: Dictionary, card_id: String, target_type: String, target_instance_id: int) -> bool:
	if not player["hand"].has(card_id):
		_log(state, "That card is not in your hand.")
		return false
	if not cards_by_id.has(card_id):
		_log(state, "Unknown card: %s." % card_id)
		return false

	var card: Dictionary = cards_by_id[card_id]
	if int(card.get("cost", 0)) > _available_focus_for_card(player, card):
		_log(state, "Not enough focus to play %s." % card.get("name", card_id))
		return false
	if _combat_type(card) == "threat" and player["board"].size() >= MAX_BOARD_SIZE:
		_log(state, "Your board is full.")
		return false
	if _combat_type(card) == "engine" and player["engines"].size() >= MAX_ENGINES:
		_log(state, "Your engine row is full.")
		return false
	if _combat_type(card) == "action" and not _action_target_is_valid(state, card, opponent, target_type, target_instance_id):
		return false
	return true


func _action_target_is_valid(state: Dictionary, card: Dictionary, enemy: Dictionary, target_type: String, target_instance_id: int) -> bool:
	var target_mode := _action_target_mode(card)
	match target_mode:
		"none":
			if target_type == "auto" or target_type == "none":
				return true
			_log(state, "%s does not need a target." % card.get("name", "That card"))
			return false
		"enemy_player":
			if target_type == "auto" or target_type == "face":
				return true
			_log(state, "%s can only target the opponent." % card.get("name", "That card"))
			return false
		"enemy_unit":
			if target_type == "auto":
				if enemy["board"].is_empty():
					_log(state, "%s needs an opposing unit." % card.get("name", "That card"))
					return false
				return true
			if target_type == "unit" and not _find_unit_by_instance_id(enemy, target_instance_id).is_empty():
				return true
			_log(state, "%s needs an opposing unit target." % card.get("name", "That card"))
			return false
		"any_enemy":
			if target_type == "auto" or target_type == "face":
				return true
			if target_type == "unit" and not _find_unit_by_instance_id(enemy, target_instance_id).is_empty():
				return true
			_log(state, "Choose a valid target for %s." % card.get("name", "that card"))
			return false
		_:
			_log(state, "Unsupported target mode for %s." % card.get("name", "that card"))
			return false


func _action_uses_damage_target(card: Dictionary) -> bool:
	return _action_target_mode(card) != "none"


func _available_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	return int(combatant.get("focus", 0)) + _restricted_focus_for_card(combatant, card)


func _restricted_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	var archetype := String(card.get("archetype", ""))
	if archetype == "" or archetype == "neutral":
		return 0
	var restricted: Dictionary = combatant.get("restricted_focus", {})
	return int(restricted.get(archetype, 0))


func _spend_focus_for_card(combatant: Dictionary, card: Dictionary, cost: int) -> void:
	var remaining: int = max(0, cost)
	var archetype := String(card.get("archetype", ""))
	if archetype != "" and archetype != "neutral":
		var restricted: Dictionary = combatant.get("restricted_focus", {})
		var available_restricted: int = int(restricted.get(archetype, 0))
		var restricted_spent: int = min(available_restricted, remaining)
		if restricted_spent > 0:
			restricted[archetype] = available_restricted - restricted_spent
			remaining -= restricted_spent
			combatant["restricted_focus"] = restricted
	combatant["focus"] = max(0, int(combatant.get("focus", 0)) - remaining)


func _activate_unit_ability(state: Dictionary, active: Dictionary, enemy: Dictionary, unit: Dictionary, ability_index: int) -> bool:
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		_log(state, "%s has no card data for abilities." % unit.get("name", "That threat"))
		return false

	var card: Dictionary = cards_by_id[card_id]
	var abilities: Array = _combat_data(card).get("abilities", [])
	if ability_index < 0 or ability_index >= abilities.size():
		_log(state, "%s has no such ability." % card.get("name", card_id))
		return false

	var ability: Dictionary = abilities[ability_index]
	if not _ability_can_activate(state, active, enemy, unit, card, ability, ability_index, true):
		return false

	var cost := int(ability.get("cost", 0))
	_spend_focus_for_card(active, card, cost)
	_mark_ability_used(unit, ability, ability_index, active)

	if bool(ability.get("preventAttack", false)) or bool(ability.get("exhaust", false)):
		unit["ready"] = false

	var label := String(ability.get("label", "ability"))
	_log(state, "%s activates %s." % [unit.get("name", card.get("name", card_id)), label])
	_resolve_effects(state, active, enemy, ability.get("effects", []), {}, card, unit, { "ability_index": ability_index })
	_check_game_over(state)
	return true


func _ability_can_activate(state: Dictionary, active: Dictionary, enemy: Dictionary, unit: Dictionary, card: Dictionary, ability: Dictionary, ability_index: int, log_failure: bool) -> bool:
	if bool(ability.get("requiresReady", false)) and not bool(unit.get("ready", false)):
		if log_failure:
			_log(state, "%s is not ready to use that ability." % unit.get("name", "That threat"))
		return false

	if bool(ability.get("oncePerTurn", false)) and _ability_was_used(unit, ability, ability_index, active):
		if log_failure:
			_log(state, "%s already used that ability this turn." % unit.get("name", "That threat"))
		return false

	var cost := int(ability.get("cost", 0))
	if cost > _available_focus_for_card(active, card):
		if log_failure:
			_log(state, "Not enough focus to activate %s." % card.get("name", "that ability"))
		return false

	if String(ability.get("targetMode", "none")) != "none":
		if log_failure:
			_log(state, "%s has an unsupported activated ability target." % card.get("name", "That card"))
		return false

	return true


func _ability_score(active: Dictionary, enemy: Dictionary, unit: Dictionary, card: Dictionary, ability: Dictionary) -> float:
	var score := _effects_play_score(active, enemy, ability.get("effects", []), card)
	score -= float(ability.get("cost", 0)) * 0.5
	if bool(ability.get("preventAttack", false)) and bool(unit.get("ready", false)):
		score -= float(unit.get("attack", 0)) * 1.2
	if bool(ability.get("exhaust", false)) and bool(unit.get("ready", false)):
		score -= float(unit.get("attack", 0)) * 1.2
	return score


func _ability_was_used(unit: Dictionary, ability: Dictionary, ability_index: int, active: Dictionary) -> bool:
	var used: Dictionary = unit.get("used_abilities", {})
	var key := _ability_usage_key(ability, ability_index, active)
	return used.has(key)


func _mark_ability_used(unit: Dictionary, ability: Dictionary, ability_index: int, active: Dictionary) -> void:
	if not bool(ability.get("oncePerTurn", false)):
		return
	var used: Dictionary = unit.get("used_abilities", {})
	used[_ability_usage_key(ability, ability_index, active)] = true
	unit["used_abilities"] = used


func _ability_usage_key(ability: Dictionary, ability_index: int, active: Dictionary) -> String:
	return "%s:%d" % [String(ability.get("id", "ability_%d" % ability_index)), int(active.get("turns_taken", 0))]


func _play_card(state: Dictionary, active: Dictionary, enemy: Dictionary, card_id: String, target_type: String = "auto", target_instance_id: int = -1) -> bool:
	var card: Dictionary = cards_by_id[card_id]
	var cost := int(card.get("cost", 0))
	if cost > _available_focus_for_card(active, card):
		return false
	if _combat_type(card) == "action" and not _action_target_is_valid(state, card, enemy, target_type, target_instance_id):
		return false

	_spend_focus_for_card(active, card, cost)
	active["hand"].erase(card_id)

	match _combat_type(card):
		"threat":
			var unit := _create_unit(card_id)
			active["board"].append(unit)
			_log(state, "%s plays %s as a %d/%d threat." % [active["name"], card.get("name", card_id), int(unit["attack"]), int(unit["health"])])
			var combat: Dictionary = _combat_data(card)
			if not combat.get("onPlay", []).is_empty():
				_resolve_effects(state, active, enemy, combat.get("onPlay", []), {}, card, unit, {})
		"engine":
			active["engines"].append({ "card_id": card_id })
			_log(state, "%s plays engine %s." % [active["name"], card.get("name", card_id)])
		"action":
			_resolve_action_with_target(state, active, enemy, card_id, target_type, target_instance_id)
			active["discard"].append(card_id)

	if not bool(state["game_over"]):
		_resolve_played_card_triggers(state, active, card)

	_check_game_over(state)
	return true


func _create_unit(card_id: String) -> Dictionary:
	var card: Dictionary = cards_by_id[card_id]
	var stats: Dictionary = card.get("stats", {})
	var tags: Array = card.get("tags", [])
	var combat: Dictionary = _combat_data(card)
	var fallback_attack: int = max(1, int(round(float(stats.get("power", 1)) + float(stats.get("speed", 0)) * 0.30)))
	var fallback_health: int = max(1, int(round(float(stats.get("resilience", 1)) + float(stats.get("power", 1)) * 0.45 + max(0, int(card.get("cost", 0)) - 1) * 0.35)))
	var attack: int = int(combat.get("attack", fallback_attack))
	var health: int = int(combat.get("health", fallback_health))
	var unit_tags: Array = tags.duplicate()
	for keyword in combat.get("keywords", []):
		if not unit_tags.has(keyword):
			unit_tags.append(keyword)
	for tag in combat.get("tags", []):
		if not unit_tags.has(tag):
			unit_tags.append(tag)
	var fast: bool = bool(combat.get("ready", tags.has("fast") or unit_tags.has("fast") or float(stats.get("speed", 0)) >= 4.0))
	var unit: Dictionary = {
		"instance_id": next_unit_id,
		"card_id": card_id,
		"name": card.get("name", card_id),
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": fast,
		"tags": unit_tags
	}
	next_unit_id += 1
	return unit


func _resolve_action(state: Dictionary, active: Dictionary, enemy: Dictionary, card_id: String) -> void:
	_resolve_action_with_target(state, active, enemy, card_id, "auto", -1)


func _resolve_action_with_target(state: Dictionary, active: Dictionary, enemy: Dictionary, card_id: String, target_type: String, target_instance_id: int) -> void:
	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = _combat_data(card)
	if not combat.get("effects", []).is_empty():
		var selected_target := _selected_action_target(card, active, enemy, target_type, target_instance_id)
		_resolve_effects(state, active, enemy, combat.get("effects", []), selected_target, card, {}, {})
		return

	var role := String(card.get("role", "answer"))
	var damage := _action_damage(card, enemy)
	match role:
		"answer", "tech":
			var target: Dictionary = {}
			if target_type == "unit":
				target = _find_unit_by_instance_id(enemy, target_instance_id)
			elif target_type == "auto":
				target = _choose_action_target(enemy)

			if target.is_empty():
				enemy["life"] = int(enemy["life"]) - damage
				_log(state, "%s casts %s for %d damage to %s." % [active["name"], card.get("name", card_id), damage, enemy["name"]])
			else:
				target["health"] = int(target["health"]) - damage
				_log(state, "%s casts %s for %d damage to %s." % [active["name"], card.get("name", card_id), damage, target["name"]])
				_cleanup_dead_units(state, enemy)
			if role == "tech" and _has_relevant_tech(card, enemy):
				_draw_card(state, active, false)
				_log(state, "%s tech lines up and draws a card." % card.get("name", card_id))
		"filter":
			_draw_card(state, active, false)
			_log(state, "%s casts %s and draws a card." % [active["name"], card.get("name", card_id)])
		"finisher":
			enemy["life"] = int(enemy["life"]) - max(damage, 4)
			_log(state, "%s fires finisher %s at %s." % [active["name"], card.get("name", card_id), enemy["name"]])
		_:
			_draw_card(state, active, false)
			_log(state, "%s casts %s for tempo." % [active["name"], card.get("name", card_id)])


func _selected_action_target(card: Dictionary, active: Dictionary, enemy: Dictionary, target_type: String, target_instance_id: int) -> Dictionary:
	if target_type == "unit":
		return _find_unit_by_instance_id(enemy, target_instance_id)
	if target_type == "auto":
		match _action_target_mode(card):
			"any_enemy":
				if _action_should_go_face(card, active, enemy):
					return {}
				return _choose_action_target_for_card(card, enemy)
			"enemy_unit":
				return _choose_action_target_for_card(card, enemy)
	return {}


func _action_should_go_face(card: Dictionary, active: Dictionary, enemy: Dictionary) -> bool:
	if _action_target_mode(card) == "enemy_player":
		return true
	if _action_target_mode(card) != "any_enemy":
		return false

	var damage := _action_damage(card, enemy)
	if int(enemy.get("life", STARTING_LIFE)) <= damage:
		return true
	if String(active.get("archetype", "")) == "redline_aggro" and int(enemy.get("life", STARTING_LIFE)) <= 10 and damage >= 2:
		return true
	return enemy["board"].is_empty()


func _choose_action_target_for_card(card: Dictionary, enemy: Dictionary) -> Dictionary:
	var combat: Dictionary = _combat_data(card)
	for effect in combat.get("effects", []):
		match String(effect.get("type", "")):
			"destroy", "exhaust", "debuff":
				return _choose_action_target(enemy)
			"damage":
				return _choose_action_target_for_damage(enemy, int(effect.get("amount", 1)))
	return _choose_action_target(enemy)


func _action_damage(card: Dictionary, enemy: Dictionary) -> int:
	var combat: Dictionary = _combat_data(card)
	for effect in combat.get("effects", []):
		if String(effect.get("type", "")) == "damage":
			return int(effect.get("amount", 1))

	var stats: Dictionary = card.get("stats", {})
	var damage := int(max(1.0, round(float(stats.get("interaction", 0)) * 0.75 + float(stats.get("power", 0)) * 0.45 + 1.0)))
	if _has_relevant_tech(card, enemy):
		damage += 1
	return damage


func _has_relevant_tech(card: Dictionary, enemy: Dictionary) -> bool:
	var enemy_tags: Array = _archetype_tags(String(enemy["archetype"]))
	for modifier in card.get("matchupModifiers", []):
		if enemy_tags.has(modifier.get("target", "")):
			return true
	return false


func _choose_action_target(enemy: Dictionary) -> Dictionary:
	var best_target := {}
	var best_score := -9999
	for unit in enemy["board"]:
		var score := int(unit["attack"]) * 2 + int(unit["health"])
		if score > best_score:
			best_score = score
			best_target = unit
	return best_target


func _choose_action_target_for_damage(enemy: Dictionary, damage: int) -> Dictionary:
	var best_target := {}
	var best_score := -9999
	for unit in enemy["board"]:
		var kills := damage >= int(unit.get("health", 0))
		var score := int(unit.get("attack", 0)) * 2 + int(unit.get("health", 0))
		if kills:
			score += 8
		if unit.get("tags", []).has("guard") or unit.get("tags", []).has("stabilizer"):
			score += 5
		if score > best_score:
			best_score = score
			best_target = unit
	return best_target


func _resolve_effects(state: Dictionary, active: Dictionary, enemy: Dictionary, effects: Array, selected_target: Dictionary, source_card: Dictionary, source_unit: Dictionary = {}, context: Dictionary = {}) -> void:
	var source_name := String(source_card.get("name", "Effect"))
	for effect_value in effects:
		var effect: Dictionary = effect_value
		if not _effect_condition_met(effect, source_card, active, enemy, source_unit, context):
			continue

		match String(effect.get("type", "")):
			"damage":
				_resolve_damage_effect(state, active, enemy, effect, selected_target, source_name, source_card, source_unit, context)
			"draw":
				_resolve_draw_effect(state, active, effect, source_name)
			"heal":
				_resolve_heal_effect(state, active, enemy, effect, source_name, source_unit, context)
			"summon":
				_resolve_summon_effect(state, active, effect, source_name)
			"buff":
				_resolve_stat_effect(state, active, enemy, effect, selected_target, source_name, 1, source_unit, context)
			"debuff":
				_resolve_stat_effect(state, active, enemy, effect, selected_target, source_name, -1, source_unit, context)
			"destroy":
				_resolve_destroy_effect(state, active, enemy, effect, selected_target, source_name, source_unit)
			"exhaust":
				_resolve_exhaust_effect(state, active, enemy, effect, selected_target, source_name, source_unit)
			"grant_keyword":
				_resolve_grant_keyword_effect(state, active, enemy, effect, selected_target, source_name, source_unit)
			"discard":
				_resolve_discard_effect(state, active, enemy, effect, source_name)
			"recover":
				_resolve_recover_effect(state, active, enemy, effect, source_name)
			"gain_focus":
				_resolve_gain_focus_effect(state, active, effect, source_name, source_unit, context)
			_:
				_log(state, "%s has an unsupported combat effect." % source_name)

	_cleanup_dead_units(state, active)
	_cleanup_dead_units(state, enemy)
	_check_game_over(state)


func _effect_condition_met(effect: Dictionary, source_card: Dictionary, active: Dictionary, enemy: Dictionary, source_unit: Dictionary = {}, context: Dictionary = {}) -> bool:
	match String(effect.get("condition", "")):
		"", "always":
			return true
		"relevant_tech":
			return _has_relevant_tech(source_card, enemy)
		"controls_tool":
			return _controls_tool(active)
		"enemy_hand_at_least":
			return enemy["hand"].size() >= int(effect.get("conditionAmount", 1))
		"enemy_discard_at_least":
			return enemy["discard"].size() >= int(effect.get("conditionAmount", 1))
		"played_card_cost":
			return int(context.get("played_card_cost", -1)) == int(effect.get("conditionAmount", -2))
		"played_card_archetype":
			return String(context.get("played_card_archetype", "")) == String(effect.get("conditionValue", ""))
		_:
			return false


func _effect_amount(effect: Dictionary, active: Dictionary, enemy: Dictionary, source_card: Dictionary = {}, source_unit: Dictionary = {}, context: Dictionary = {}) -> int:
	var amount := int(effect.get("amount", 1))
	match String(effect.get("amountSource", "")):
		"source_attack":
			if not source_unit.is_empty():
				amount = int(source_unit.get("attack", amount))
			elif not source_card.is_empty():
				var combat: Dictionary = _combat_data(source_card)
				amount = int(combat.get("attack", amount))
		"enemy_hand_size":
			amount = enemy["hand"].size()
		"enemy_discard_size":
			amount = enemy["discard"].size()
		"own_discard_size":
			amount = active["discard"].size()
		"current_focus":
			amount = int(active.get("focus", amount))
		"played_card_cost":
			amount = int(context.get("played_card_cost", amount))

	amount *= int(effect.get("multiplier", 1))
	if effect.has("minimum"):
		amount = max(amount, int(effect.get("minimum", amount)))
	if effect.has("maximum"):
		amount = min(amount, int(effect.get("maximum", amount)))
	return max(0, amount)


func _controls_tool(combatant: Dictionary) -> bool:
	for engine in combatant["engines"]:
		var card_id := String(engine.get("card_id", ""))
		if cards_by_id.has(card_id):
			var card: Dictionary = cards_by_id[card_id]
			var tags: Array = card.get("tags", [])
			if tags.has("tool") or tags.has("artifact"):
				return true
	for unit in combatant["board"]:
		var tags: Array = unit.get("tags", [])
		if tags.has("tool") or tags.has("artifact"):
			return true
	return false


func _damage_unit(state: Dictionary, unit: Dictionary, amount: int, source_name: String) -> void:
	if _unit_is_invincible(unit):
		_log(state, "%s prevents damage from %s." % [unit.get("name", "That unit"), source_name])
		return
	unit["health"] = int(unit.get("health", 0)) - amount


func _unit_is_invincible(unit: Dictionary) -> bool:
	var tags: Array = unit.get("tags", [])
	return tags.has("invincible")


func _expire_temporary_effects(state: Dictionary, combatant: Dictionary) -> void:
	for unit in combatant["board"]:
		var temporary_effects: Array = unit.get("temporary_effects", [])
		if temporary_effects.is_empty():
			continue
		for temporary in temporary_effects:
			var attack_delta := int(temporary.get("amount_attack", 0))
			var health_delta := int(temporary.get("amount_health", 0))
			unit["attack"] = max(0, int(unit.get("attack", 0)) - attack_delta)
			unit["max_health"] = max(1, int(unit.get("max_health", unit.get("health", 1))) - health_delta)
			unit["health"] = min(int(unit.get("health", 1)) - health_delta, int(unit.get("max_health", 1)))
		unit["temporary_effects"] = []
		_log(state, "%s's temporary bonuses expire." % unit.get("name", "A unit"))


func _resolve_damage_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_name: String, source_card: Dictionary, source_unit: Dictionary = {}, context: Dictionary = {}) -> void:
	var amount := _effect_amount(effect, active, enemy, source_card, source_unit, context)
	match String(effect.get("target", "selected")):
		"selected":
			if selected_target.is_empty():
				enemy["life"] = int(enemy["life"]) - amount
				_log(state, "%s deals %d to %s." % [source_name, amount, enemy["name"]])
			else:
				_damage_unit(state, selected_target, amount, source_name)
				_log(state, "%s deals %d to %s." % [source_name, amount, selected_target["name"]])
		"enemy_player":
			enemy["life"] = int(enemy["life"]) - amount
			_log(state, "%s deals %d to %s." % [source_name, amount, enemy["name"]])
		"self_player":
			active["life"] = int(active["life"]) - amount
			_log(state, "%s deals %d to %s." % [source_name, amount, active["name"]])
		"source_unit":
			if source_unit.is_empty():
				_log(state, "%s finds no source unit." % source_name)
				return
			_damage_unit(state, source_unit, amount, source_name)
			_log(state, "%s deals %d to %s." % [source_name, amount, source_unit["name"]])
		"all_enemy_units":
			if enemy["board"].is_empty():
				_log(state, "%s finds no opposing units." % source_name)
				return
			for unit in enemy["board"]:
				_damage_unit(state, unit, amount, source_name)
			_log(state, "%s deals %d to each opposing unit." % [source_name, amount])
		"best_enemy_unit":
			var target := _choose_action_target(enemy)
			if target.is_empty():
				_log(state, "%s finds no opposing unit." % source_name)
				return
			_damage_unit(state, target, amount, source_name)
			_log(state, "%s deals %d to %s." % [source_name, amount, target["name"]])
		_:
			_log(state, "%s has an unsupported damage target." % source_name)


func _resolve_draw_effect(state: Dictionary, active: Dictionary, effect: Dictionary, source_name: String) -> void:
	var amount := int(effect.get("amount", 1))
	for i in range(amount):
		_draw_card(state, active, false, true)
	_log(state, "%s draws %d from %s." % [active["name"], amount, source_name])


func _resolve_heal_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, source_name: String, source_unit: Dictionary = {}, context: Dictionary = {}) -> void:
	var amount := _effect_amount(effect, active, enemy, {}, source_unit, context)
	var target: Dictionary = active
	if String(effect.get("target", "self_player")) == "enemy_player":
		target = enemy
	var before := int(target["life"])
	target["life"] = min(STARTING_LIFE, before + amount)
	var healed := int(target["life"]) - before
	_log(state, "%s restores %d life to %s." % [source_name, healed, target["name"]])


func _resolve_summon_effect(state: Dictionary, active: Dictionary, effect: Dictionary, source_name: String) -> void:
	if active["board"].size() >= MAX_BOARD_SIZE:
		_log(state, "%s cannot create a token because the board is full." % source_name)
		return

	var attack := int(effect.get("attack", 1))
	var health := int(effect.get("health", 1))
	var unit := {
		"instance_id": next_unit_id,
		"card_id": String(effect.get("card_id", "")),
		"name": String(effect.get("name", "Token")),
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": bool(effect.get("ready", false)),
		"tags": effect.get("tags", [])
	}
	next_unit_id += 1
	active["board"].append(unit)
	_log(state, "%s creates %s as a %d/%d threat." % [source_name, unit["name"], attack, health])


func _resolve_stat_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_name: String, direction: int, source_unit: Dictionary = {}, context: Dictionary = {}) -> void:
	var targets := _effect_unit_targets(active, enemy, effect, selected_target, source_unit)
	if targets.is_empty():
		_log(state, "%s finds no unit to modify." % source_name)
		return

	var amount := _effect_amount(effect, active, enemy, {}, source_unit, context)
	var attack_delta := int(effect.get("amount_attack", amount)) * direction
	var health_delta := int(effect.get("amount_health", amount)) * direction
	for unit in targets:
		unit["attack"] = max(0, int(unit.get("attack", 0)) + attack_delta)
		unit["max_health"] = max(1, int(unit.get("max_health", unit.get("health", 1))) + health_delta)
		unit["health"] = int(unit.get("health", 1)) + health_delta
		if String(effect.get("duration", "")) == "end_turn":
			var temporary_effects: Array = unit.get("temporary_effects", [])
			temporary_effects.append({
				"amount_attack": attack_delta,
				"amount_health": health_delta
			})
			unit["temporary_effects"] = temporary_effects

	var verb := "buffs" if direction > 0 else "weakens"
	_log(state, "%s %s %d unit(s)." % [source_name, verb, targets.size()])


func _resolve_destroy_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_name: String, source_unit: Dictionary = {}) -> void:
	var targets := _effect_unit_targets(active, enemy, effect, selected_target, source_unit)
	if targets.is_empty():
		_log(state, "%s finds no unit to destroy." % source_name)
		return
	for unit in targets:
		if _unit_is_invincible(unit):
			_log(state, "%s cannot destroy %s." % [source_name, unit.get("name", "that unit")])
		else:
			unit["health"] = 0
	_log(state, "%s destroys %d unit(s)." % [source_name, targets.size()])


func _resolve_exhaust_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_name: String, source_unit: Dictionary = {}) -> void:
	var targets := _effect_unit_targets(active, enemy, effect, selected_target, source_unit)
	if targets.is_empty():
		_log(state, "%s finds no unit to exhaust." % source_name)
		return
	for unit in targets:
		unit["ready"] = false
		unit["stunned_turns"] = max(int(unit.get("stunned_turns", 0)), int(effect.get("turns", 1)))
	_log(state, "%s exhausts %d unit(s)." % [source_name, targets.size()])


func _resolve_grant_keyword_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_name: String, source_unit: Dictionary = {}) -> void:
	var targets := _effect_unit_targets(active, enemy, effect, selected_target, source_unit)
	var keyword := String(effect.get("keyword", ""))
	if targets.is_empty() or keyword == "":
		_log(state, "%s finds no keyword target." % source_name)
		return
	for unit in targets:
		var tags: Array = unit.get("tags", [])
		if not tags.has(keyword):
			tags.append(keyword)
		unit["tags"] = tags
	_log(state, "%s grants %s to %d unit(s)." % [source_name, keyword, targets.size()])


func _resolve_discard_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, source_name: String) -> void:
	var combatant := enemy if String(effect.get("target", "enemy_player")) == "enemy_player" else active
	var amount := int(effect.get("amount", 1))
	var discarded := 0
	while discarded < amount and not combatant["hand"].is_empty():
		var index := rng.randi_range(0, combatant["hand"].size() - 1)
		var card_id: String = combatant["hand"].pop_at(index)
		combatant["discard"].append(card_id)
		discarded += 1
	_log(state, "%s makes %s discard %d." % [source_name, combatant["name"], discarded])


func _resolve_recover_effect(state: Dictionary, active: Dictionary, enemy: Dictionary, effect: Dictionary, source_name: String) -> void:
	var combatant := active if String(effect.get("target", "self_player")) != "enemy_player" else enemy
	var amount := int(effect.get("amount", 1))
	var recovered := 0
	while recovered < amount and not combatant["discard"].is_empty() and combatant["hand"].size() < MAX_HAND_SIZE:
		var card_id: String = combatant["discard"].pop_back()
		combatant["hand"].append(card_id)
		recovered += 1
	_log(state, "%s recovers %d card(s) for %s." % [source_name, recovered, combatant["name"]])


func _resolve_gain_focus_effect(state: Dictionary, active: Dictionary, effect: Dictionary, source_name: String, source_unit: Dictionary = {}, context: Dictionary = {}) -> void:
	var amount := _effect_amount(effect, active, _enemy_for_combatant(state, active), {}, source_unit, context)
	var restricted_to := String(effect.get("restrictedTo", ""))
	if restricted_to == "":
		active["focus"] = max(0, int(active.get("focus", 0)) + amount)
		_log(state, "%s gains %d focus from %s." % [active["name"], amount, source_name])
	else:
		var restricted: Dictionary = active.get("restricted_focus", {})
		restricted[restricted_to] = int(restricted.get(restricted_to, 0)) + amount
		active["restricted_focus"] = restricted
		_log(state, "%s gains %d %s focus from %s." % [active["name"], amount, _archetype_name(restricted_to), source_name])


func _effect_unit_targets(active: Dictionary, enemy: Dictionary, effect: Dictionary, selected_target: Dictionary, source_unit: Dictionary = {}) -> Array:
	match String(effect.get("target", "selected")):
		"selected":
			return [] if selected_target.is_empty() else [selected_target]
		"source_unit":
			return [] if source_unit.is_empty() else [source_unit]
		"all_enemy_units":
			return enemy["board"].duplicate()
		"all_friendly_units":
			return active["board"].duplicate()
		"best_enemy_unit":
			var best_enemy := _choose_action_target(enemy)
			return [] if best_enemy.is_empty() else [best_enemy]
		"best_friendly_unit":
			var best_friendly := _choose_friendly_unit(active)
			return [] if best_friendly.is_empty() else [best_friendly]
		"weakest_enemy_unit":
			var weakest_enemy := _choose_weakest_unit(enemy)
			return [] if weakest_enemy.is_empty() else [weakest_enemy]
		"weakest_friendly_unit":
			var weakest_friendly := _choose_weakest_unit(active)
			return [] if weakest_friendly.is_empty() else [weakest_friendly]
		_:
			return []


func _choose_friendly_unit(active: Dictionary) -> Dictionary:
	var best_target := {}
	var best_score := -9999
	for unit in active["board"]:
		var score := int(unit["attack"]) * 2 + int(unit["health"])
		if score > best_score:
			best_score = score
			best_target = unit
	return best_target


func _choose_weakest_unit(combatant: Dictionary) -> Dictionary:
	var weakest := {}
	var weakest_score := 9999
	for unit in combatant["board"]:
		var score := int(unit["attack"]) + int(unit["health"])
		if score < weakest_score:
			weakest_score = score
			weakest = unit
	return weakest


func _attack_phase(state: Dictionary, active: Dictionary, enemy: Dictionary) -> void:
	var attackers: Array = active["board"].duplicate()
	for attacker in attackers:
		if bool(state["game_over"]):
			return
		if not bool(attacker.get("ready", false)):
			continue
		if not active["board"].has(attacker):
			continue

		var target := _choose_attack_target(active, enemy, attacker)
		_resolve_single_attack(state, active, enemy, attacker, target)


func _choose_attack_target(active: Dictionary, enemy: Dictionary, attacker: Dictionary) -> Dictionary:
	if enemy["board"].is_empty():
		return {}

	var guard := _find_guard(enemy)
	if guard.is_empty() and int(enemy["life"]) <= int(attacker["attack"]):
		return {}

	if active["archetype"] == "redline_aggro":
		if not guard.is_empty():
			return guard
		return {}

	var best_target := {}
	var best_score := -9999
	for unit in enemy["board"]:
		var kills := int(attacker["attack"]) >= int(unit["health"])
		var survives := int(attacker["health"]) > int(unit["attack"])
		var score := int(unit["attack"]) * 2 + int(unit["health"])
		if kills:
			score += 5
		if survives:
			score += 3
		if unit.get("tags", []).has("guard"):
			score += 8
		if score > best_score:
			best_score = score
			best_target = unit

	if guard.is_empty() and best_score < int(attacker["attack"]) * 2:
		return {}
	if active["archetype"] == "lantern_control" and int(active["life"]) > 12 and int(attacker["attack"]) >= 4:
		return {}
	return best_target


func _find_guard(combatant: Dictionary) -> Dictionary:
	for unit in combatant["board"]:
		if unit.get("tags", []).has("guard") or unit.get("tags", []).has("stabilizer"):
			return unit
	return {}


func _find_unit_by_instance_id(combatant: Dictionary, instance_id: int) -> Dictionary:
	for unit in combatant["board"]:
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit
	return {}


func _resolve_single_attack(state: Dictionary, active: Dictionary, enemy: Dictionary, attacker: Dictionary, target: Dictionary) -> void:
	attacker["ready"] = false
	if target.is_empty():
		enemy["life"] = int(enemy["life"]) - int(attacker["attack"])
		_log(state, "%s attacks %s for %d." % [attacker["name"], enemy["name"], int(attacker["attack"])])
		var card_id := String(attacker.get("card_id", ""))
		if cards_by_id.has(card_id):
			var source_card: Dictionary = cards_by_id[card_id]
			_resolve_card_triggers(state, active, source_card, attacker, "on_damage_player", { "damage": int(attacker["attack"]) })
	else:
		_damage_unit(state, target, int(attacker["attack"]), String(attacker["name"]))
		_damage_unit(state, attacker, int(target["attack"]), String(target["name"]))
		_log(state, "%s trades with %s." % [attacker["name"], target["name"]])
		_cleanup_dead_units(state, active)
		_cleanup_dead_units(state, enemy)
	_check_game_over(state)


func _cleanup_dead_units(state: Dictionary, combatant: Dictionary) -> void:
	var survivors: Array = []
	var dead_units: Array = []
	for unit in combatant["board"]:
		if int(unit["health"]) <= 0:
			dead_units.append(unit)
		else:
			survivors.append(unit)
	combatant["board"] = survivors
	for unit in dead_units:
		var card_id := String(unit.get("card_id", ""))
		if cards_by_id.has(card_id):
			combatant["discard"].append(card_id)
		_log(state, "%s dies." % unit["name"])
		if cards_by_id.has(card_id):
			var card: Dictionary = cards_by_id[card_id]
			_resolve_card_triggers(state, combatant, card, unit, "on_death", {})


func _discard_to_hand_size(state: Dictionary, combatant: Dictionary) -> void:
	while combatant["hand"].size() > MAX_HAND_SIZE:
		var card_id: String = combatant["hand"].pop_back()
		combatant["discard"].append(card_id)
		_log(state, "%s discards %s to hand size." % [combatant["name"], cards_by_id[card_id].get("name", card_id)])


func _draw_card(state: Dictionary, combatant: Dictionary, log_draw: bool, trigger_draw: bool = true) -> void:
	if combatant["deck"].is_empty():
		combatant["fatigue"] = int(combatant["fatigue"]) + 1
		combatant["life"] = int(combatant["life"]) - int(combatant["fatigue"])
		_log(state, "%s takes %d fatigue." % [combatant["name"], int(combatant["fatigue"])])
		return

	var card_id: String = combatant["deck"].pop_front()
	combatant["hand"].append(card_id)
	if log_draw:
		_log(state, "%s draws %s." % [combatant["name"], cards_by_id[card_id].get("name", card_id)])
	if trigger_draw:
		var opponent: Dictionary = _enemy_for_combatant(state, combatant)
		_resolve_unit_triggers(state, opponent, "opponent_draw", { "drawn_card_id": card_id })
		_resolve_engine_triggers_with_context(state, opponent, "opponent_draw", { "drawn_card_id": card_id })


func _check_game_over(state: Dictionary) -> void:
	if int(state["player"]["life"]) <= 0 and int(state["opponent"]["life"]) <= 0:
		state["game_over"] = true
		state["winner"] = "draw"
	elif int(state["opponent"]["life"]) <= 0:
		state["game_over"] = true
		state["winner"] = "player"
	elif int(state["player"]["life"]) <= 0:
		state["game_over"] = true
		state["winner"] = "opponent"


func _enemy_for_combatant(state: Dictionary, combatant: Dictionary) -> Dictionary:
	if String(combatant.get("name", "")) == String(state["player"].get("name", "")):
		return state["opponent"]
	return state["player"]


func _manual_state_accepts_player_action(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	if bool(state.get("game_over", false)):
		return false
	return String(state.get("active_side", "")) == "player" and String(state.get("phase", "")) == "player_main"


func _set_manual_phase_after_action(state: Dictionary) -> void:
	if bool(state.get("game_over", false)):
		state["phase"] = "game_over"
	elif String(state.get("mode", "")) == "manual":
		state["phase"] = "player_main"


func _break_stalemate(state: Dictionary) -> void:
	var player_score: int = int(state["player"]["life"]) + _board_power(state["player"]) + state["player"]["hand"].size()
	var opponent_score: int = int(state["opponent"]["life"]) + _board_power(state["opponent"]) + state["opponent"]["hand"].size()
	state["game_over"] = true
	if player_score >= opponent_score:
		state["winner"] = "player"
	else:
		state["winner"] = "opponent"
	_log(state, "Turn limit reached; board state breaks the stalemate.")


func _board_power(combatant: Dictionary) -> int:
	var total := 0
	for unit in combatant["board"]:
		total += int(unit["attack"]) + int(unit["health"])
	return total


func _combat_type(card: Dictionary) -> String:
	var combat: Dictionary = _combat_data(card)
	match String(combat.get("kind", "")):
		"unit":
			return "threat"
		"action":
			return "action"
		"engine":
			return "engine"

	var role := String(card.get("role", "threat"))
	match role:
		"threat", "finisher":
			return "threat"
		"engine":
			return "engine"
		_:
			return "action"


func _archetype_tags(archetype_id: String) -> Array:
	if archetypes_by_id.has(archetype_id):
		return archetypes_by_id[archetype_id].get("tags", [])
	return []


func _archetype_name(archetype_id: String) -> String:
	if archetypes_by_id.has(archetype_id):
		return archetypes_by_id[archetype_id].get("name", archetype_id)
	return archetype_id


func _log(state: Dictionary, message: String) -> void:
	state["log"].append(message)
