extends RefCounted
class_name RunStateService

var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var archetype_order: Array = []
var main_deck_size := 30
var sideboard_size := 6
var starting_money := 20
var save_path := ""


func setup(
	card_database: Dictionary,
	archetype_database: Dictionary,
	ordered_archetypes: Array,
	main_size: int,
	side_size: int,
	initial_money: int,
	run_save_path: String
) -> void:
	cards_by_id = card_database
	archetypes_by_id = archetype_database
	archetype_order = ordered_archetypes
	main_deck_size = main_size
	sideboard_size = side_size
	starting_money = initial_money
	save_path = run_save_path


func create_run(archetype_id: String, starter_deck: Dictionary, combat_lab_opponent: String) -> Dictionary:
	var starter_collection := {}
	for card_id in starter_deck.keys():
		starter_collection[card_id] = starter_deck[card_id]

	return {
		"week": 1,
		"money": starting_money,
		"starter": archetype_id,
		"collection": starter_collection,
		"deck": starter_deck.duplicate(true),
		"sideboard": {},
		"meta": {
			"flightless_birds": 0.24,
			"snake": 0.22,
			"oxen": 0.22,
			"glires": 0.17,
			"insect": 0.15
		},
		"reports": [
			"Opening week: Flightless Birds Aggro is cheap and everywhere.",
			"Oxen Ramp is picking up because players want to go over fair boards.",
			"Snake Control players are happy to coil around fair creature decks."
		],
		"shop": [],
		"current_pack": [],
		"revealed_pack": [],
		"pack_index": 0,
		"prize_packs": 0,
		"run_over": false,
		"last_result": [],
		"combat_lab_opponent": combat_lab_opponent,
		"manual_selection": {},
		"manual_inspect": {},
		"manual_battle_log_open": false,
		"manual_animation": {},
		"manual_animation_queue": [],
		"manual_pending_action": {},
		"manual_combat": {},
		"last_combat": {}
	}


func deck_is_legal(target_run: Dictionary) -> Dictionary:
	if deck_total(target_run.get("deck", {})) != main_deck_size:
		return { "ok": false, "reason": "Main deck must contain exactly %d cards." % main_deck_size }
	if deck_total(target_run.get("sideboard", {})) > sideboard_size:
		return { "ok": false, "reason": "Sideboard cannot exceed %d cards." % sideboard_size }
	for card_id in target_run.get("deck", {}).keys():
		if deck_count(target_run, card_id) > deck_limit(card_id):
			return { "ok": false, "reason": "Too many copies of " + _card_name(card_id) + "." }
		if deck_count(target_run, card_id) + sideboard_count(target_run, card_id) > owned_count(target_run, card_id):
			return { "ok": false, "reason": "Deck uses more copies than owned: " + _card_name(card_id) + "." }
	for card_id in target_run.get("sideboard", {}).keys():
		if sideboard_count(target_run, card_id) > deck_limit(card_id):
			return { "ok": false, "reason": "Too many sideboard copies of " + _card_name(card_id) + "." }
		if deck_count(target_run, card_id) + sideboard_count(target_run, card_id) > owned_count(target_run, card_id):
			return { "ok": false, "reason": "Sideboard uses more copies than owned: " + _card_name(card_id) + "." }
	return { "ok": true, "reason": "Legal" }


func owned_count(target_run: Dictionary, card_id: String) -> int:
	return int(target_run.get("collection", {}).get(card_id, 0))


func deck_count(target_run: Dictionary, card_id: String) -> int:
	return int(target_run.get("deck", {}).get(card_id, 0))


func sideboard_count(target_run: Dictionary, card_id: String) -> int:
	return int(target_run.get("sideboard", {}).get(card_id, 0))


func available_count(target_run: Dictionary, card_id: String) -> int:
	return owned_count(target_run, card_id) - deck_count(target_run, card_id) - sideboard_count(target_run, card_id)


func deck_limit(card_id: String) -> int:
	return int(cards_by_id[card_id].get("deckLimit", 3))


func deck_total(deck: Dictionary) -> int:
	var total := 0
	for card_id in deck.keys():
		total += int(deck[card_id])
	return total


func add_to_collection(target_run: Dictionary, card_id: String, count: int) -> void:
	target_run.collection[card_id] = owned_count(target_run, card_id) + count


func add_to_deck(target_run: Dictionary, card_id: String) -> Dictionary:
	if available_count(target_run, card_id) <= 0:
		return { "ok": false, "message": "No available copies of " + _card_name(card_id) + "." }
	if deck_total(target_run.deck) >= main_deck_size:
		return { "ok": false, "message": "Main deck is already full." }
	if deck_count(target_run, card_id) >= deck_limit(card_id):
		return { "ok": false, "message": "Deck copy limit reached for " + _card_name(card_id) + "." }
	target_run.deck[card_id] = deck_count(target_run, card_id) + 1
	return { "ok": true, "message": "" }


func remove_from_deck(target_run: Dictionary, card_id: String) -> bool:
	if not target_run.deck.has(card_id):
		return false
	target_run.deck[card_id] = int(target_run.deck[card_id]) - 1
	if int(target_run.deck[card_id]) <= 0:
		target_run.deck.erase(card_id)
	return true


func add_to_sideboard(target_run: Dictionary, card_id: String) -> Dictionary:
	if available_count(target_run, card_id) <= 0:
		return { "ok": false, "message": "No available copies of " + _card_name(card_id) + "." }
	if deck_total(target_run.sideboard) >= sideboard_size:
		return { "ok": false, "message": "Sideboard is already full." }
	target_run.sideboard[card_id] = sideboard_count(target_run, card_id) + 1
	return { "ok": true, "message": "" }


func remove_from_sideboard(target_run: Dictionary, card_id: String) -> bool:
	if not target_run.sideboard.has(card_id):
		return false
	target_run.sideboard[card_id] = int(target_run.sideboard[card_id]) - 1
	if int(target_run.sideboard[card_id]) <= 0:
		target_run.sideboard.erase(card_id)
	return true


func sell_extra_copies(target_run: Dictionary) -> int:
	var total := 0
	for card_id in target_run.collection.keys():
		var owned := owned_count(target_run, card_id)
		var in_use := deck_count(target_run, card_id) + sideboard_count(target_run, card_id)
		var keep: int = max(deck_limit(card_id), in_use)
		if owned > keep:
			var extras: int = owned - keep
			total += extras * max(1, int(floor(float(cards_by_id[card_id].value) * 0.45)))
			target_run.collection[card_id] = keep

	target_run.money += total
	return total


func save_run(target_run: Dictionary) -> Dictionary:
	if target_run.is_empty():
		return { "ok": false, "message": "No run to save." }
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return { "ok": false, "message": "Could not save run." }
	file.store_string(JSON.stringify(target_run, "\t"))
	return { "ok": true, "message": "Run saved." }


func load_run() -> Dictionary:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return { "ok": false, "message": "No saved run found.", "run": {} }
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return { "ok": false, "message": "Saved run is invalid.", "run": {} }

	var loaded_run: Dictionary = parsed
	normalize_loaded_run(loaded_run)
	return { "ok": true, "message": "Run loaded.", "run": loaded_run }


func normalize_loaded_run(target_run: Dictionary) -> void:
	if not target_run.has("last_combat"):
		target_run.last_combat = {}
	if not target_run.has("manual_combat"):
		target_run.manual_combat = {}
	if not target_run.has("manual_selection"):
		target_run.manual_selection = {}
	if not target_run.has("manual_inspect"):
		target_run.manual_inspect = {}
	if not target_run.has("manual_battle_log_open"):
		target_run.manual_battle_log_open = false
	if not target_run.has("manual_animation"):
		target_run.manual_animation = {}
	if not target_run.has("manual_animation_queue"):
		target_run.manual_animation_queue = []
	target_run.manual_pending_action = {}
	migrate_legacy_run_archetypes(target_run)


func migrate_legacy_run_archetypes(target_run: Dictionary) -> void:
	var legacy_map := {
		"redline_aggro": "flightless_birds",
		"lantern_control": "snake",
		"verdant_midrange": "oxen",
		"canine": "oxen"
	}
	if legacy_map.has(String(target_run.get("starter", ""))):
		target_run.starter = legacy_map[String(target_run.starter)]
	if legacy_map.has(String(target_run.get("combat_lab_opponent", ""))):
		target_run.combat_lab_opponent = legacy_map[String(target_run.combat_lab_opponent)]
	if target_run.has("meta"):
		var migrated_meta := {}
		for archetype_id in target_run.meta.keys():
			var id := String(archetype_id)
			id = String(legacy_map.get(id, id))
			migrated_meta[id] = float(migrated_meta.get(id, 0.0)) + float(target_run.meta[archetype_id])
		for archetype_id in archetype_order:
			if not migrated_meta.has(archetype_id):
				migrated_meta[archetype_id] = 0.12
		target_run.meta = migrated_meta
		normalize_meta(target_run)


func normalize_meta(target_run: Dictionary) -> void:
	if not target_run.has("meta"):
		target_run.meta = {}

	var total := 0.0
	for archetype_id in archetype_order:
		total += float(target_run.meta.get(archetype_id, 0.0))

	if total <= 0.0:
		var even_share := 1.0 / float(archetype_order.size())
		for archetype_id in archetype_order:
			target_run.meta[archetype_id] = even_share
		return

	for archetype_id in archetype_order:
		target_run.meta[archetype_id] = float(target_run.meta.get(archetype_id, 0.0)) / total


func dominant_archetype(target_run: Dictionary) -> String:
	var leader := String(archetype_order[0])
	var leader_share := float(target_run.meta.get(leader, 0.0))
	for archetype_id in archetype_order:
		var share := float(target_run.meta.get(archetype_id, 0.0))
		if share > leader_share:
			leader = String(archetype_id)
			leader_share = share
	return leader


func predator_archetype(archetype_id: String) -> String:
	match archetype_id:
		"flightless_birds":
			return "snake"
		"snake":
			return "oxen"
		"oxen":
			return "flightless_birds"
		"glires":
			return "insect"
		"insect":
			return "flightless_birds"
		_:
			return "flightless_birds"


func _card_name(card_id: String) -> String:
	if not cards_by_id.has(card_id):
		return card_id
	return String(cards_by_id[card_id].get("name", card_id))
