extends SceneTree

const COMBAT_SERVICE_SCRIPT := preload("res://scripts/CombatService.gd")


func _init() -> void:
	var cards_by_id := {}
	var archetypes_by_id := {}

	var card_data := _load_json("res://data/content/cards.json")
	for card in card_data.get("cards", []):
		cards_by_id[card.get("id", "")] = card

	var archetype_data := _load_json("res://data/content/archetypes.json")
	for archetype in archetype_data.get("archetypes", []):
		archetypes_by_id[archetype.get("id", "")] = archetype

	var combat_service: RefCounted = COMBAT_SERVICE_SCRIPT.new()
	combat_service.setup(cards_by_id, archetypes_by_id)

	for card_id in cards_by_id.keys():
		var card: Dictionary = cards_by_id[card_id]
		if not card.has("combat"):
			push_error("Card is missing explicit combat data: " + String(card_id))
			quit(1)
			return

	var player_deck := _deck_entries_to_dict(archetypes_by_id["redline_aggro"].get("starterDeck", []))
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id["verdant_midrange"].get("starterDeck", []))
	var result: Dictionary = combat_service.auto_play_game(player_deck, "redline_aggro", opponent_deck, "verdant_midrange", 12345)

	if result.get("winner", "") == "":
		push_error("Combat smoke test produced no winner.")
		quit(1)
		return

	print("Combat smoke test winner: %s" % result.get("winner", ""))
	print("Combat smoke test log lines: %d" % result.get("log", []).size())

	var manual_result: Dictionary = combat_service.start_manual_game(player_deck, "redline_aggro", opponent_deck, "verdant_midrange", 67890)
	if manual_result.get("phase", "") != "player_main":
		push_error("Manual combat did not start in player_main phase.")
		quit(1)
		return

	var playable_card := _first_playable_card(manual_result)
	if playable_card != "":
		manual_result = combat_service.manual_play_card(manual_result, playable_card)

	var target_result: Dictionary = combat_service.start_manual_game(player_deck, "redline_aggro", opponent_deck, "verdant_midrange", 24680)
	target_result["opponent"]["board"].append({
		"instance_id": 9001,
		"card_id": "ver_briarwall_guard",
		"name": "Target Dummy",
		"attack": 1,
		"health": 6,
		"max_health": 6,
		"ready": false,
		"tags": []
	})
	_ensure_hand_card(target_result, "red_quick_spark")
	target_result["player"]["focus"] = max(int(target_result["player"].get("focus", 0)), 1)
	target_result = combat_service.manual_play_card_with_target(target_result, "red_quick_spark", "unit", 9001)
	var damaged_target := _test_unit_by_id(target_result, 9001)
	if damaged_target.is_empty() or int(damaged_target.get("health", 99)) >= 6:
		push_error("Manual targeted action did not damage the selected unit.")
		quit(1)
		return

	_ensure_hand_card(target_result, "red_spark_runner")
	target_result["player"]["focus"] = max(int(target_result["player"].get("focus", 0)), 1)
	target_result = combat_service.manual_play_card_with_target(target_result, "red_spark_runner", "auto", -1)
	var attacker_id := _first_ready_unit_id(target_result)
	if attacker_id == -1:
		push_error("Manual targeted attack test found no ready attacker.")
		quit(1)
		return

	var opponent_life_before := int(target_result["opponent"].get("life", 0))
	target_result = combat_service.manual_attack_target(target_result, attacker_id, "face", -1)
	if int(target_result["opponent"].get("life", 0)) >= opponent_life_before:
		push_error("Manual targeted attack did not damage the opponent.")
		quit(1)
		return

	var token_result: Dictionary = combat_service.start_manual_game(player_deck, "redline_aggro", opponent_deck, "verdant_midrange", 13579)
	token_result["player"]["engines"] = [{ "card_id": "red_crowd_surge" }]
	token_result["opponent"]["deck"] = []
	token_result["opponent"]["hand"] = []
	token_result["opponent"]["board"] = []
	token_result = combat_service.manual_end_player_turn(token_result)
	var token_id := _first_ready_token_id(token_result)
	if token_id == -1:
		push_error("Crowd Surge token was not ready to attack.")
		quit(1)
		return

	var token_attack_life_before := int(token_result["opponent"].get("life", 0))
	token_result = combat_service.manual_attack_target(token_result, token_id, "face", -1)
	if int(token_result["opponent"].get("life", 0)) >= token_attack_life_before:
		push_error("Ready token did not attack successfully.")
		quit(1)
		return

	manual_result = combat_service.manual_end_player_turn(manual_result)
	if not bool(manual_result.get("game_over", false)) and manual_result.get("phase", "") != "player_main":
		push_error("Manual combat did not return to player_main after ending turn.")
		quit(1)
		return

	print("Manual combat smoke phase: %s" % manual_result.get("phase", ""))
	quit(0)


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


func _deck_entries_to_dict(entries: Array) -> Dictionary:
	var deck := {}
	for entry in entries:
		deck[entry.get("cardId", "")] = int(entry.get("count", 0))
	return deck


func _first_playable_card(state: Dictionary) -> String:
	var player: Dictionary = state.get("player", {})
	for card_id in player.get("hand", []):
		var card: Dictionary = _card_by_id(String(card_id))
		if int(card.get("cost", 0)) <= int(player.get("focus", 0)):
			return String(card_id)
	return ""


func _ensure_hand_card(state: Dictionary, card_id: String) -> void:
	var player: Dictionary = state.get("player", {})
	if not player.get("hand", []).has(card_id):
		player["hand"].append(card_id)


func _test_unit_by_id(state: Dictionary, instance_id: int) -> Dictionary:
	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit
	return {}


func _first_ready_unit_id(state: Dictionary) -> int:
	var player: Dictionary = state.get("player", {})
	for unit in player.get("board", []):
		if bool(unit.get("ready", false)):
			return int(unit.get("instance_id", -1))
	return -1


func _first_ready_token_id(state: Dictionary) -> int:
	var player: Dictionary = state.get("player", {})
	for unit in player.get("board", []):
		if bool(unit.get("ready", false)) and unit.get("tags", []).has("token"):
			return int(unit.get("instance_id", -1))
	return -1


func _card_by_id(card_id: String) -> Dictionary:
	var card_data := _load_json("res://data/content/cards.json")
	for card in card_data.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}
