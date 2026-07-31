extends RefCounted
class_name RunStateService

const SAVE_VERSION := 1

var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var archetype_order: Array = []
var main_deck_size := 20
var max_main_deck_size := 20
var sideboard_size := 6
var starting_money := 20
var save_path := ""
const DEFAULT_SEASON_CALENDAR := ["weekly_locals", "monthly_regionals", "state_championship", "nationals", "worlds"]
const DEMO_SEASON_CALENDAR := ["weekly_locals", "monthly_regionals"]
const DEFAULT_SEASON_GOAL := "Win Worlds before your season lives run out."


func setup(
	card_database: Dictionary,
	archetype_database: Dictionary,
	ordered_archetypes: Array,
	main_size: int,
	side_size: int,
	initial_money: int,
	run_save_path: String,
	maximum_main_size: int = -1
) -> void:
	cards_by_id = card_database
	archetypes_by_id = archetype_database
	archetype_order = ordered_archetypes
	main_deck_size = main_size
	max_main_deck_size = maxi(main_size, maximum_main_size)
	sideboard_size = side_size
	starting_money = initial_money
	save_path = run_save_path


func create_run(archetype_id: String, starter_deck: Dictionary, kitchen_opponent: String, run_mode: String = "debug", difficulty_id: String = "white") -> Dictionary:
	var starter_collection := {}
	for card_id in starter_deck.keys():
		starter_collection[card_id] = starter_deck[card_id]
	var lives := 1 if run_mode == "season" else starting_lives_for_difficulty(difficulty_id)
	var calendar := DEMO_SEASON_CALENDAR.duplicate() if run_mode == "season" else default_season_calendar()

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
		"meta": _initial_meta(),
		"reports": [
			"Opening week: Spicy decks are setting the pace with early Plated pressure.",
			"Hearty chefs are leaning on durable Ingredients and life gain.",
			"Sweet lists are trading speed for draw and flexible Prep support.",
			"Fresh and Funky pilots are testing token swarms, discard engines, and Hand Traps."
		],
		"shop": [],
		"current_pack": [],
		"revealed_pack": [],
		"pack_index": 0,
		"prize_packs": 0,
		"run_over": false,
		"season_goal": "Win Weekly Locals and the League Cup without losing a match." if run_mode == "season" else DEFAULT_SEASON_GOAL,
		"season_calendar": calendar,
		"calendar_unlocked_index": 0,
		"calendar_completed": [],
		"selected_event_id": "weekly_locals",
		"season_champion": false,
		"demo_complete": false,
		"season_notice": "Weekly Locals is open. Tune your starter deck, check the shop, then register when ready.",
		"last_result": [],
		"last_event_result": {},
		"kitchen_opponent": kitchen_opponent,
		"kitchen_match": {},
		"kitchen_match_result": {},
		"active_tournament": {}
	}


func default_season_calendar() -> Array:
	return DEFAULT_SEASON_CALENDAR.duplicate()


func _initial_meta() -> Dictionary:
	var result := {}
	var share := 1.0 / float(maxi(1, archetype_order.size()))
	for archetype_id in archetype_order:
		result[String(archetype_id)] = share
	return result


func starting_money_for_difficulty(difficulty_id: String) -> int:
	if difficulty_id == "yellow":
		return max(0, int(round(float(starting_money) * 0.65)))
	return starting_money


func starting_lives_for_difficulty(difficulty_id: String) -> int:
	if difficulty_id == "silver":
		return 1
	return 3


func deck_is_legal(target_run: Dictionary) -> Dictionary:
	var main_total := deck_total(target_run.get("deck", {}))
	if main_total < main_deck_size:
		return { "ok": false, "reason": "Main deck must contain at least %d cards." % main_deck_size }
	if main_total > max_main_deck_size:
		return { "ok": false, "reason": "Main deck cannot contain more than %d cards." % max_main_deck_size }
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
	if deck_total(target_run.deck) >= max_main_deck_size:
		return { "ok": false, "message": "Main deck is full at %d cards." % max_main_deck_size }
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


func has_saved_run() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(_backup_path())


func save_run(target_run: Dictionary, resume_screen: String = "") -> Dictionary:
	if target_run.is_empty():
		return { "ok": false, "message": "No run to save." }
	var envelope := {
		"save_version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"resume_screen": resume_screen,
		"run": target_run
	}
	var serialized := JSON.stringify(envelope, "\t")
	var temporary_path := _temporary_path()
	if not _write_save_text(temporary_path, serialized):
		return { "ok": false, "message": "Could not save run." }

	# Only replace the backup with a primary save that we can still decode. This
	# preserves the last known-good checkpoint if the primary was corrupted.
	if FileAccess.file_exists(save_path):
		var primary_payload := _read_save_payload(save_path)
		if bool(primary_payload.get("ok", false)):
			_write_save_text(_backup_path(), FileAccess.get_file_as_string(save_path))

	var absolute_primary := ProjectSettings.globalize_path(save_path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(absolute_primary)
	var rename_error := DirAccess.rename_absolute(absolute_temporary, absolute_primary)
	if rename_error != OK:
		# Some export targets cannot rename user files atomically. Fall back to a
		# direct write while retaining the backup made above.
		if not _write_save_text(save_path, serialized):
			return { "ok": false, "message": "Could not finalize the run save." }
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(absolute_temporary)
	return { "ok": true, "message": "Run saved." }


func load_run() -> Dictionary:
	var payload := _read_save_payload(save_path)
	var recovered_backup := false
	if not bool(payload.get("ok", false)):
		payload = _read_save_payload(_backup_path())
		recovered_backup = bool(payload.get("ok", false))
	if not bool(payload.get("ok", false)):
		return { "ok": false, "message": "No valid saved run found.", "run": {}, "resume_screen": "" }

	var loaded_run: Dictionary = payload.get("run", {})
	normalize_loaded_run(loaded_run)
	return {
		"ok": true,
		"message": "Recovered the backup autosave." if recovered_backup else "Autosave loaded.",
		"run": loaded_run,
		"resume_screen": String(payload.get("resume_screen", "")),
		"save_version": int(payload.get("save_version", 0))
	}


func _read_save_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"ok": false}
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false}
	var dictionary: Dictionary = parsed
	if dictionary.has("run"):
		if typeof(dictionary.get("run")) != TYPE_DICTIONARY:
			return {"ok": false}
		return {
			"ok": true,
			"run": dictionary.get("run", {}),
			"resume_screen": String(dictionary.get("resume_screen", "")),
			"save_version": int(dictionary.get("save_version", 0))
		}
	# Saves from before autosave used the run dictionary as the root object.
	return {"ok": true, "run": dictionary, "resume_screen": "", "save_version": 0}


func _write_save_text(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	return true


func _backup_path() -> String:
	return save_path + ".bak"


func _temporary_path() -> String:
	return save_path + ".tmp"


func normalize_loaded_run(target_run: Dictionary) -> void:
	if not target_run.has("kitchen_match"):
		target_run.kitchen_match = {}
	if not target_run.has("kitchen_match_result"):
		target_run.kitchen_match_result = {}
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
	if not target_run.has("demo_complete"):
		target_run.demo_complete = false
	if not target_run.has("season_notice"):
		target_run.season_notice = ""
	if not target_run.has("last_event_result"):
		target_run.last_event_result = {}
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
	var starter := String(target_run.get("starter", ""))
	if not archetypes_by_id.has(starter):
		starter = String(archetype_order[0])
		target_run.starter = starter
		var starter_deck := {}
		for entry in archetypes_by_id[starter].get("starterDeck", []):
			starter_deck[String(entry.get("cardId", ""))] = int(entry.get("count", 0))
		target_run.deck = starter_deck.duplicate(true)
		target_run.collection = starter_deck.duplicate(true)
		target_run.sideboard = {}
	for field in ["collection", "deck", "sideboard"]:
		var cleaned := {}
		for card_id in target_run.get(field, {}).keys():
			if cards_by_id.has(card_id):
				cleaned[card_id] = int(target_run[field][card_id])
		target_run[field] = cleaned
	var migrated_meta := {}
	for archetype_id in archetype_order:
		migrated_meta[archetype_id] = float(target_run.get("meta", {}).get(archetype_id, 1.0))
	target_run.meta = migrated_meta
	normalize_meta(target_run)
	target_run.kitchen_opponent = predator_archetype(starter)


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
		"spicy":
			return "hearty"
		"hearty":
			return "sweet"
		"sweet":
			return "spicy"
		"fresh":
			return "spicy"
		"funky":
			return "fresh"
		_:
			return String(archetype_order[0])


func _card_name(card_id: String) -> String:
	if not cards_by_id.has(card_id):
		return card_id
	return String(cards_by_id[card_id].get("name", card_id))
