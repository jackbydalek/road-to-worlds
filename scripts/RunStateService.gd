extends RefCounted
class_name RunStateService

var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var archetype_order: Array = []
var main_deck_size := 30
var sideboard_size := 6
var starting_money := 20
var save_path := ""
const DEFAULT_SEASON_CALENDAR := ["weekly_locals", "monthly_regionals", "state_championship", "nationals", "worlds"]
const DEFAULT_SEASON_GOAL := "Win Worlds before your season lives run out."


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


func create_run(archetype_id: String, starter_deck: Dictionary, combat_lab_opponent: String, run_mode: String = "debug", difficulty_id: String = "white") -> Dictionary:
	var starter_collection := {}
	for card_id in starter_deck.keys():
		starter_collection[card_id] = starter_deck[card_id]
	var lives := starting_lives_for_difficulty(difficulty_id)

	return {
		"week": 1,
		"run_mode": run_mode,
		"difficulty": difficulty_id,
		"money": starting_money_for_difficulty(difficulty_id),
		"season_lives": lives,
		"max_season_lives": lives,
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
		"season_goal": DEFAULT_SEASON_GOAL,
		"season_calendar": default_season_calendar(),
		"calendar_unlocked_index": 0,
		"calendar_completed": [],
		"selected_event_id": "weekly_locals",
		"season_champion": false,
		"season_notice": "Weekly Locals is open. Tune your starter deck, check the shop, then register when ready.",
		"last_result": [],
		"last_event_result": {},
		"combat_lab_opponent": combat_lab_opponent,
		"manual_selection": {},
		"manual_inspect": {},
		"manual_battle_log_open": false,
		"manual_animation": {},
		"manual_animation_queue": [],
		"manual_pending_action": {},
		"manual_opponent_pending_state": {},
		"manual_combat": {},
		"last_combat": {},
		"active_tournament": {}
	}


func default_season_calendar() -> Array:
	return DEFAULT_SEASON_CALENDAR.duplicate()


func starting_money_for_difficulty(difficulty_id: String) -> int:
	if difficulty_id == "yellow":
		return max(0, int(round(float(starting_money) * 0.65)))
	return starting_money


func starting_lives_for_difficulty(difficulty_id: String) -> int:
	if difficulty_id == "silver":
		return 1
	return 3


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
	if not target_run.has("manual_opponent_pending_state"):
		target_run.manual_opponent_pending_state = {}
	if not target_run.has("run_mode"):
		target_run.run_mode = "debug"
	if not target_run.has("difficulty"):
		target_run.difficulty = "white"
	if not target_run.has("max_season_lives"):
		target_run.max_season_lives = starting_lives_for_difficulty(String(target_run.get("difficulty", "white")))
	if not target_run.has("season_lives"):
		target_run.season_lives = int(target_run.get("max_season_lives", starting_lives_for_difficulty(String(target_run.get("difficulty", "white")))))
	if not target_run.has("active_tournament"):
		target_run.active_tournament = {}
	if not target_run.has("season_goal"):
		target_run.season_goal = DEFAULT_SEASON_GOAL
	target_run.season_calendar = _normalized_season_calendar(target_run.get("season_calendar", []))
	target_run.calendar_completed = _normalized_completed_events(target_run.get("calendar_completed", []), target_run.season_calendar)
	target_run.calendar_unlocked_index = _normalized_unlocked_index(target_run)
	var selected_event_id := String(target_run.get("selected_event_id", ""))
	var selected_event_index: int = target_run.season_calendar.find(selected_event_id)
	if selected_event_index < 0 or selected_event_index > int(target_run.calendar_unlocked_index) or target_run.calendar_completed.has(selected_event_id):
		target_run.selected_event_id = _first_available_calendar_event(target_run)
	if not target_run.has("season_champion"):
		target_run.season_champion = false
	if not target_run.has("season_notice"):
		target_run.season_notice = ""
	if not target_run.has("last_event_result"):
		target_run.last_event_result = {}
	target_run.manual_pending_action = {}
	target_run.manual_opponent_pending_state = {}
	migrate_legacy_run_archetypes(target_run)


func _normalized_season_calendar(value: Variant) -> Array:
	var normalized: Array = []
	if value is Array:
		for raw_event_id in value:
			var event_id := String(raw_event_id)
			if event_id != "" and not normalized.has(event_id):
				normalized.append(event_id)
	if normalized.is_empty():
		return default_season_calendar()
	return normalized


func _normalized_completed_events(value: Variant, calendar: Array) -> Array:
	var normalized: Array = []
	if value is Array:
		for raw_event_id in value:
			var event_id := String(raw_event_id)
			if calendar.has(event_id) and not normalized.has(event_id):
				normalized.append(event_id)
	return normalized


func _normalized_unlocked_index(target_run: Dictionary) -> int:
	var calendar: Array = target_run.get("season_calendar", default_season_calendar())
	if calendar.is_empty():
		return 0
	var completed_unlocked := _calendar_unlocked_index_from_completed(target_run)
	var requested := int(target_run.get("calendar_unlocked_index", completed_unlocked))
	return clamp(max(requested, completed_unlocked), 0, calendar.size() - 1)


func _calendar_unlocked_index_from_completed(target_run: Dictionary) -> int:
	var calendar: Array = target_run.get("season_calendar", default_season_calendar())
	var completed: Array = target_run.get("calendar_completed", [])
	var unlocked := 0
	for index in range(calendar.size()):
		if completed.has(String(calendar[index])):
			unlocked = min(index + 1, calendar.size() - 1)
	return unlocked


func _first_available_calendar_event(target_run: Dictionary) -> String:
	var calendar: Array = target_run.get("season_calendar", default_season_calendar())
	var completed: Array = target_run.get("calendar_completed", [])
	var unlocked := int(target_run.get("calendar_unlocked_index", 0))
	for index in range(calendar.size()):
		var event_id := String(calendar[index])
		if index <= unlocked and not completed.has(event_id):
			return event_id
	return String(calendar[max(0, min(unlocked, calendar.size() - 1))])


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
