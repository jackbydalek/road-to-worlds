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

	var tested := 0
	for card_id in cards_by_id.keys():
		var card: Dictionary = cards_by_id[card_id]
		var tags: Array = card.get("tags", [])
		if not tags.has("wave1"):
			continue

		tested += 1
		var result := _exercise_card(combat_service, cards_by_id, archetypes_by_id, String(card_id), card, tested)
		if not bool(result.get("ok", false)):
			push_error(result.get("reason", "Wave 1 smoke failed."))
			quit(1)
			return

	if tested != 47:
		push_error("Expected 47 Wave 1 cards, tested %d." % tested)
		quit(1)
		return

	print("Wave 1 smoke exercised %d cards." % tested)
	quit(0)


func _exercise_card(combat_service: RefCounted, cards_by_id: Dictionary, archetypes_by_id: Dictionary, card_id: String, card: Dictionary, seed_offset: int) -> Dictionary:
	var player_archetype := String(card.get("archetype", "neutral"))
	if player_archetype == "neutral":
		player_archetype = "redline_aggro"
	var opponent_archetype := "lantern_control" if player_archetype != "lantern_control" else "redline_aggro"
	var player_deck := _deck_entries_to_dict(archetypes_by_id[player_archetype].get("starterDeck", []))
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var state: Dictionary = combat_service.start_manual_game(player_deck, player_archetype, opponent_deck, opponent_archetype, 9000 + seed_offset)

	state["player"]["hand"] = [card_id]
	state["player"]["focus"] = 12
	state["player"]["max_focus"] = 12
	state["player"]["discard"] = ["neu_sleeve_luck", "neu_pocket_notebook"]
	state["player"]["board"] = [
		_dummy_unit(8001, "Friendly Dummy", 2, 4, [])
	]
	state["player"]["engines"] = []
	state["opponent"]["hand"] = ["red_spark_runner", "red_live_wire"]
	state["opponent"]["board"] = [
		_dummy_unit(9001, "Enemy Dummy", 2, 6, []),
		_dummy_unit(9002, "Enemy Guard", 1, 3, ["guard"])
	]

	var combat: Dictionary = card.get("combat", {})
	if String(combat.get("kind", "")) == "action":
		match String(combat.get("targetMode", "none")):
			"enemy_unit", "any_enemy":
				state = combat_service.manual_play_card_with_target(state, card_id, "unit", 9001)
			"enemy_player":
				state = combat_service.manual_play_card_with_target(state, card_id, "face", -1)
			_:
				state = combat_service.manual_play_card(state, card_id)
	else:
		state = combat_service.manual_play_card(state, card_id)

	if state["player"]["hand"].has(card_id):
		return { "ok": false, "reason": "%s did not play during Wave 1 smoke." % card_id }

	for line in state.get("log", []):
		if String(line).contains("unsupported combat effect") or String(line).contains("Unsupported target mode"):
			return { "ok": false, "reason": "%s produced unsupported combat log: %s" % [card_id, line] }

	if String(combat.get("kind", "")) == "engine":
		state["opponent"]["deck"] = []
		state["opponent"]["hand"] = []
		state["opponent"]["board"] = []
		state = combat_service.manual_end_player_turn(state)
		for line in state.get("log", []):
			if String(line).contains("unsupported combat effect") or String(line).contains("Unsupported target mode"):
				return { "ok": false, "reason": "%s engine trigger produced unsupported combat log: %s" % [card_id, line] }

	return { "ok": true }


func _dummy_unit(instance_id: int, display_name: String, attack: int, health: int, tags: Array) -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": "",
		"name": display_name,
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": false,
		"tags": tags
	}


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
