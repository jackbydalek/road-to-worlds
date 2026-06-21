extends SceneTree

const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const RUN_STATE_SERVICE_SCRIPT := preload("res://scripts/RunStateService.gd")

const ARCHETYPE_ORDER := ["flightless_birds", "snake", "oxen", "glires", "insect"]
const MAIN_DECK_SIZE := 30
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SMOKE_SAVE_PATH := "user://road_to_worlds_run_state_smoke.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		_fail("Run state smoke could not load content.")
		return

	var service = RUN_STATE_SERVICE_SCRIPT.new()
	service.setup(catalog.cards_by_id, catalog.archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE, SIDEBOARD_SIZE, STARTING_MONEY, SMOKE_SAVE_PATH)

	var starter_deck: Dictionary = catalog.deck_entries_to_dict(catalog.archetypes_by_id["oxen"].starterDeck)
	var run: Dictionary = service.create_run("oxen", starter_deck, service.predator_archetype("oxen"))
	if String(run.get("run_mode", "")) != "debug":
		_fail("Run state smoke did not default new runs to debug mode.")
		return
	if String(run.get("difficulty", "")) != "white":
		_fail("Run state smoke did not default new runs to White difficulty.")
		return
	if int(run.get("season_lives", 0)) != 3 or int(run.get("max_season_lives", 0)) != 3:
		_fail("Run state smoke did not initialize base season lives.")
		return
	if not run.has("active_tournament") or not run.active_tournament.is_empty():
		_fail("Run state smoke did not initialize an empty active tournament state.")
		return
	if not run.has("manual_opponent_pending_state") or not run.manual_opponent_pending_state.is_empty():
		_fail("Run state smoke did not initialize an empty pending opponent state.")
		return
	var legal: Dictionary = service.deck_is_legal(run)
	if not bool(legal.get("ok", false)):
		_fail("Run state smoke starter deck was illegal: " + String(legal.get("reason", "")))
		return

	var card_id := String(starter_deck.keys()[0])
	service.add_to_collection(run, card_id, 1)
	var add_result: Dictionary = service.add_to_sideboard(run, card_id)
	if not bool(add_result.get("ok", false)):
		_fail("Run state smoke could not add a sideboard card: " + String(add_result.get("message", "")))
		return
	if service.sideboard_count(run, card_id) != 1:
		_fail("Run state smoke sideboard count did not update.")
		return
	if not service.remove_from_sideboard(run, card_id):
		_fail("Run state smoke could not remove a sideboard card.")
		return

	var yellow_run: Dictionary = service.create_run("oxen", starter_deck, service.predator_archetype("oxen"), "season", "yellow")
	if int(yellow_run.get("money", 0)) >= STARTING_MONEY:
		_fail("Run state smoke did not apply Yellow Border reduced money.")
		return
	var silver_run: Dictionary = service.create_run("oxen", starter_deck, service.predator_archetype("oxen"), "season", "silver")
	if int(silver_run.get("season_lives", 0)) != 1:
		_fail("Run state smoke did not apply Silver Border reduced lives.")
		return

	var save_result: Dictionary = service.save_run(run)
	if not bool(save_result.get("ok", false)):
		_fail("Run state smoke save failed: " + String(save_result.get("message", "")))
		return
	var load_result: Dictionary = service.load_run()
	if not bool(load_result.get("ok", false)):
		_fail("Run state smoke load failed: " + String(load_result.get("message", "")))
		return
	var loaded_run: Dictionary = load_result.run
	if String(loaded_run.get("starter", "")) != "oxen":
		_fail("Run state smoke loaded the wrong starter.")
		return

	var legacy_run := {
		"starter": "canine",
		"combat_lab_opponent": "canine",
		"meta": { "canine": 1.0 }
	}
	service.normalize_loaded_run(legacy_run)
	if String(legacy_run.get("starter", "")) != "oxen":
		_fail("Run state smoke did not migrate canine starter to oxen.")
		return
	if String(legacy_run.get("combat_lab_opponent", "")) != "oxen":
		_fail("Run state smoke did not migrate canine opponent to oxen.")
		return
	if legacy_run.meta.has("canine") or not legacy_run.meta.has("oxen"):
		_fail("Run state smoke did not migrate canine meta share to oxen.")
		return
	if not legacy_run.has("manual_pending_action"):
		_fail("Run state smoke did not normalize manual pending action.")
		return
	if String(legacy_run.get("run_mode", "")) != "debug":
		_fail("Run state smoke did not default legacy runs to debug mode.")
		return
	if String(legacy_run.get("difficulty", "")) != "white":
		_fail("Run state smoke did not default legacy runs to White difficulty.")
		return
	if int(legacy_run.get("season_lives", 0)) != 3:
		_fail("Run state smoke did not normalize legacy season lives.")
		return
	if not legacy_run.has("active_tournament"):
		_fail("Run state smoke did not normalize active tournament state.")
		return
	if not legacy_run.has("manual_opponent_pending_state") or not legacy_run.manual_opponent_pending_state.is_empty():
		_fail("Run state smoke did not normalize pending opponent state.")
		return

	var malformed_calendar_run := {
		"season_calendar": ["weekly_locals", "monthly_regionals", "monthly_regionals", ""],
		"calendar_completed": ["weekly_locals", "bogus_event", "weekly_locals"],
		"calendar_unlocked_index": -5,
		"selected_event_id": "weekly_locals"
	}
	service.normalize_loaded_run(malformed_calendar_run)
	if malformed_calendar_run.season_calendar.size() != 2 or malformed_calendar_run.season_calendar[0] != "weekly_locals" or malformed_calendar_run.season_calendar[1] != "monthly_regionals":
		_fail("Run state smoke did not deduplicate malformed season calendar data.")
		return
	if malformed_calendar_run.calendar_completed.size() != 1 or malformed_calendar_run.calendar_completed[0] != "weekly_locals":
		_fail("Run state smoke did not remove duplicate or unknown completed events.")
		return
	if int(malformed_calendar_run.get("calendar_unlocked_index", 0)) != 1:
		_fail("Run state smoke did not unlock the next event after a completed calendar entry.")
		return
	if String(malformed_calendar_run.get("selected_event_id", "")) != "monthly_regionals":
		_fail("Run state smoke did not move selected event away from an already cleared event.")
		return

	print("Run state smoke covered create, mutate, save/load, legacy migration, and calendar repair.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
