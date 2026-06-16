extends SceneTree

const COMBAT_SERVICE_SCRIPT := preload("res://scripts/CombatService.gd")

var cards_by_id := {}
var archetypes_by_id := {}
var combat_service: RefCounted


func _init() -> void:
	var card_data := _load_json("res://data/content/cards.json")
	for card in card_data.get("cards", []):
		cards_by_id[card.get("id", "")] = card

	var archetype_data := _load_json("res://data/content/archetypes.json")
	for archetype in archetype_data.get("archetypes", []):
		archetypes_by_id[archetype.get("id", "")] = archetype

	combat_service = COMBAT_SERVICE_SCRIPT.new()
	combat_service.setup(cards_by_id, archetypes_by_id)

	var checks := [
		_test_death_damage(),
		_test_death_focus(),
		_test_damage_player_buff(),
		_test_damage_player_draw(),
		_test_end_turn_destroy(),
		_test_opponent_draw_trigger(),
		_test_tool_condition(),
		_test_dynamic_hand_damage(),
		_test_once_per_turn_card_play_trigger(),
		_test_restricted_focus_payment(),
		_test_stipend_grants_restricted_focus(),
		_test_lifebloom_activation(),
		_test_gravepath_activation(),
		_test_focus_page_activation()
	]
	for check in checks:
		if not bool(check.get("ok", false)):
			push_error(check.get("reason", "Wave 2 smoke failed."))
			quit(1)
			return

	print("Wave 2 smoke exercised trigger, restricted-focus, and activation hooks.")
	quit(0)


func _test_death_damage() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12001)
	state = _play_from_hand(state, "ver_last_word_brawler")
	var unit := _first_player_unit(state, "ver_last_word_brawler")
	var life_before := int(state["opponent"]["life"])
	unit["health"] = 0
	combat_service._cleanup_dead_units(state, state["player"])
	if int(state["opponent"]["life"]) > life_before - 4:
		return { "ok": false, "reason": "Last-Word Brawler death trigger did not damage the opponent." }
	return { "ok": true }


func _test_death_focus() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12002)
	state = _play_from_hand(state, "ver_refund_beast")
	state["player"]["focus"] = 0
	var unit := _first_player_unit(state, "ver_refund_beast")
	unit["health"] = 0
	combat_service._cleanup_dead_units(state, state["player"])
	if int(state["player"]["focus"]) < 4:
		return { "ok": false, "reason": "Refund Beast death trigger did not grant focus." }
	return { "ok": true }


func _test_damage_player_buff() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12003)
	state = _play_from_hand(state, "ver_growing_duelist")
	state["opponent"]["board"] = []
	var unit := _first_player_unit(state, "ver_growing_duelist")
	unit["ready"] = true
	state = combat_service.manual_attack_target(state, int(unit["instance_id"]), "face", -1)
	unit = _first_player_unit(state, "ver_growing_duelist")
	if int(unit.get("attack", 0)) < 2 or int(unit.get("health", 0)) < 2:
		return { "ok": false, "reason": "Growing Duelist did not grow after damaging the opponent." }
	return { "ok": true }


func _test_damage_player_draw() -> Dictionary:
	var state := _fresh_state("snake", "flightless_birds", 12004)
	state = _play_from_hand(state, "lan_curiosity_harness")
	state["opponent"]["board"] = []
	var unit := _first_player_unit(state, "lan_curiosity_harness")
	unit["ready"] = true
	var hand_before: int = state["player"]["hand"].size()
	state = combat_service.manual_attack_target(state, int(unit["instance_id"]), "face", -1)
	if state["player"]["hand"].size() <= hand_before:
		return { "ok": false, "reason": "Curiosity Harness did not draw after damaging the opponent." }
	return { "ok": true }


func _test_end_turn_destroy() -> Dictionary:
	var state := _fresh_state("flightless_birds", "snake", 12005)
	state = _play_from_hand(state, "red_glass_cannon_sprinter")
	state["opponent"]["deck"] = []
	state["opponent"]["hand"] = []
	state["opponent"]["board"] = []
	state = combat_service.manual_end_player_turn(state)
	if not state["player"]["discard"].has("red_glass_cannon_sprinter"):
		return { "ok": false, "reason": "Glass-Cannon Sprinter did not self-destruct at end of turn." }
	return { "ok": true }


func _test_opponent_draw_trigger() -> Dictionary:
	var state := _fresh_state("flightless_birds", "snake", 12006)
	state = _play_from_hand(state, "red_draw_punisher")
	state["opponent"]["deck"] = ["neu_sleeve_luck"]
	var life_before := int(state["opponent"]["life"])
	combat_service._draw_card(state, state["opponent"], false, true)
	if int(state["opponent"]["life"]) >= life_before:
		return { "ok": false, "reason": "Draw Punisher did not trigger on opponent draw." }
	return { "ok": true }


func _test_tool_condition() -> Dictionary:
	var state_without_tool := _fresh_state("canine", "flightless_birds", 12007)
	state_without_tool = _play_from_hand(state_without_tool, "ver_toolfed_scrapper")
	var plain := _first_player_unit(state_without_tool, "ver_toolfed_scrapper")
	if int(plain.get("attack", 0)) != 2:
		return { "ok": false, "reason": "Toolfed Scrapper buffed without a tool." }

	var state_with_tool := _fresh_state("canine", "flightless_birds", 12008)
	state_with_tool["player"]["engines"] = [{ "card_id": "ver_grove_stipend" }]
	state_with_tool["player"]["life"] = 18
	state_with_tool = _play_from_hand(state_with_tool, "ver_toolfed_scrapper")
	var powered := _first_player_unit(state_with_tool, "ver_toolfed_scrapper")
	if int(powered.get("attack", 0)) < 3 or int(state_with_tool["player"]["life"]) < 19:
		return { "ok": false, "reason": "Toolfed Scrapper did not recognize controlled tool." }
	return { "ok": true }


func _test_dynamic_hand_damage() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12009)
	state["opponent"]["hand"] = ["red_spark_runner", "red_live_wire", "red_pure_grave_spark", "red_big_spell_mascot"]
	var life_before := int(state["opponent"]["life"])
	state = _play_from_hand(state, "ver_grip_punisher")
	if int(state["opponent"]["life"]) != life_before - 4:
		return { "ok": false, "reason": "Grip Punisher did not scale with enemy hand size." }
	return { "ok": true }


func _test_once_per_turn_card_play_trigger() -> Dictionary:
	var state := _fresh_state("flightless_birds", "snake", 12010)
	state["player"]["hand"] = ["red_one_drop_reactor", "red_live_wire", "red_pure_grave_spark"]
	state["player"]["focus"] = 12
	state["player"]["max_focus"] = 12
	state = combat_service.manual_play_card(state, "red_one_drop_reactor")
	var life_before := int(state["opponent"]["life"])
	state = combat_service.manual_play_card_with_target(state, "red_live_wire", "face", -1)
	var after_first := int(state["opponent"]["life"])
	state = combat_service.manual_play_card_with_target(state, "red_pure_grave_spark", "face", -1)
	var after_second := int(state["opponent"]["life"])
	if after_first != life_before - 4:
		return { "ok": false, "reason": "One-Drop Reactor did not trigger on the first 1-cost card." }
	if after_second != after_first - 1:
		return { "ok": false, "reason": "One-Drop Reactor fired more than once in a turn." }
	return { "ok": true }


func _test_restricted_focus_payment() -> Dictionary:
	var state := _fresh_state("flightless_birds", "snake", 12011)
	state["player"]["hand"] = ["red_live_wire"]
	state["player"]["focus"] = 0
	state["player"]["restricted_focus"] = { "flightless_birds": 1 }
	var life_before := int(state["opponent"]["life"])
	state = combat_service.manual_play_card_with_target(state, "red_live_wire", "face", -1)
	if state["player"]["hand"].has("red_live_wire") or int(state["opponent"]["life"]) != life_before - 2:
		return { "ok": false, "reason": "Restricted focus did not pay for matching archetype card." }
	if int(state["player"].get("restricted_focus", {}).get("flightless_birds", 0)) != 0:
		return { "ok": false, "reason": "Restricted focus was not spent first." }

	var blocked := _fresh_state("flightless_birds", "snake", 12012)
	blocked["player"]["hand"] = ["lan_null_pupil"]
	blocked["player"]["focus"] = 0
	blocked["player"]["restricted_focus"] = { "flightless_birds": 1 }
	blocked = combat_service.manual_play_card_with_target(blocked, "lan_null_pupil", "unit", 9001)
	if not blocked["player"]["hand"].has("lan_null_pupil"):
		return { "ok": false, "reason": "Restricted focus paid for an off-archetype card." }
	return { "ok": true }


func _test_stipend_grants_restricted_focus() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12013)
	state["player"]["engines"] = [{ "card_id": "ver_grove_stipend" }]
	state["player"]["restricted_focus"] = {}
	combat_service._prepare_turn(state, state["player"])
	if int(state["player"].get("restricted_focus", {}).get("canine", 0)) < 1:
		return { "ok": false, "reason": "Grove Stipend did not grant restricted Verdant focus." }
	return { "ok": true }


func _test_lifebloom_activation() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12014)
	state = _play_from_hand(state, "ver_lifebloom_glider")
	state["player"]["life"] = 18
	state["player"]["focus"] = 1
	var unit := _first_player_unit(state, "ver_lifebloom_glider")
	state = combat_service.manual_activate_unit_ability(state, int(unit["instance_id"]), 0)
	if int(state["player"]["life"]) != 19 or int(state["player"]["focus"]) != 0:
		return { "ok": false, "reason": "Lifebloom Glider ability did not heal and spend focus." }
	return { "ok": true }


func _test_gravepath_activation() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12015)
	state = _play_from_hand(state, "ver_gravepath_guide")
	state["player"]["focus"] = 1
	state["player"]["hand"] = []
	state["player"]["discard"] = ["neu_sleeve_luck"]
	var unit := _first_player_unit(state, "ver_gravepath_guide")
	state = combat_service.manual_activate_unit_ability(state, int(unit["instance_id"]), 0)
	if not state["player"]["hand"].has("neu_sleeve_luck") or int(state["player"]["focus"]) != 0:
		return { "ok": false, "reason": "Gravepath Guide ability did not recover and spend focus." }
	return { "ok": true }


func _test_focus_page_activation() -> Dictionary:
	var state := _fresh_state("canine", "flightless_birds", 12016)
	state = _play_from_hand(state, "ver_focus_page")
	state["player"]["focus"] = 0
	var unit := _first_player_unit(state, "ver_focus_page")
	unit["ready"] = true
	state = combat_service.manual_activate_unit_ability(state, int(unit["instance_id"]), 0)
	unit = _first_player_unit(state, "ver_focus_page")
	if int(state["player"]["focus"]) != 1 or bool(unit.get("ready", true)):
		return { "ok": false, "reason": "Focus Page ability did not add focus and prevent attacking." }
	state = combat_service.manual_activate_unit_ability(state, int(unit["instance_id"]), 0)
	if int(state["player"]["focus"]) != 1:
		return { "ok": false, "reason": "Focus Page ability fired more than once in a turn." }
	return { "ok": true }


func _play_from_hand(state: Dictionary, card_id: String) -> Dictionary:
	state["player"]["hand"] = [card_id]
	state["player"]["focus"] = 12
	state["player"]["max_focus"] = 12
	return combat_service.manual_play_card(state, card_id)


func _first_player_unit(state: Dictionary, card_id: String) -> Dictionary:
	for unit in state["player"]["board"]:
		if String(unit.get("card_id", "")) == card_id:
			return unit
	return {}


func _fresh_state(player_archetype: String, opponent_archetype: String, seed_value: int) -> Dictionary:
	var player_deck := _deck_entries_to_dict(archetypes_by_id[player_archetype].get("starterDeck", []))
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var state: Dictionary = combat_service.start_manual_game(player_deck, player_archetype, opponent_deck, opponent_archetype, seed_value)
	state["player"]["board"] = []
	state["player"]["engines"] = []
	state["player"]["discard"] = ["neu_sleeve_luck", "neu_pocket_notebook"]
	state["opponent"]["board"] = []
	state["opponent"]["discard"] = []
	state["opponent"]["hand"] = ["red_spark_runner", "red_live_wire"]
	return state


func _deck_entries_to_dict(entries: Array) -> Dictionary:
	var result := {}
	for entry in entries:
		result[entry.get("cardId", "")] = int(entry.get("count", 0))
	return result


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not load " + path)
		quit(1)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON at " + path)
		quit(1)
		return {}
	return parsed
