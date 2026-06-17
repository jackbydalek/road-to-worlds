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

	print("Run state smoke covered create, mutate, save/load, and legacy migration.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
