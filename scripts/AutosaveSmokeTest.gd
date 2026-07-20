extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://road_to_worlds_autosave_smoke.json"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_test_saves()
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.run_state_service.save_path = TEST_SAVE_PATH
	main.autosave_enabled = true
	main.last_autosave_screen = main.current_screen

	main._start_new_run_with_mode("spicy", "season", "white")
	main._show_deckbuilder()
	await process_frame
	await process_frame
	_expect(main.run_state_service.has_saved_run(), "Changing screens did not create an autosave.")
	_expect(main.autosave_label != null and main.autosave_label.visible and main.autosave_label.text == "Autosaving...", "Autosaving did not display the animated top-right indicator.")

	var envelope = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE_PATH))
	_expect(typeof(envelope) == TYPE_DICTIONARY, "The autosave was not valid JSON.")
	if typeof(envelope) == TYPE_DICTIONARY:
		_expect(int(envelope.get("save_version", 0)) == 1, "The autosave did not include its save version.")
		_expect(String(envelope.get("resume_screen", "")) == "deck", "The autosave did not store the current screen.")

	main.run.money = 77
	main._autosave_now("deck")
	_expect(FileAccess.file_exists(TEST_SAVE_PATH + ".bak"), "A second autosave did not preserve a backup checkpoint.")
	var corrupt_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if corrupt_file != null:
		corrupt_file.store_string("{corrupt")
		corrupt_file.close()
	var recovered: Dictionary = main.run_state_service.load_run()
	_expect(bool(recovered.get("ok", false)) and "backup" in String(recovered.get("message", "")).to_lower(), "Loading did not recover from a corrupted primary autosave.")

	# Replace the deliberately corrupted primary, then checkpoint an active match.
	main._autosave_now("deck")
	main._start_season_tournament()
	await process_frame
	await process_frame
	var saved_round := int(main.run.active_tournament.get("round", 0))
	var saved_seed := int(main.run.active_tournament.get("current_seed", 0))
	var saved_opponent := String(main.run.active_tournament.get("current_opponent", {}).get("name", ""))
	main._autosave_now("kitchen_match")
	main.autosave_enabled = false
	main.queue_free()
	await process_frame

	var resumed = MAIN_SCENE.instantiate()
	root.add_child(resumed)
	await process_frame
	await process_frame
	resumed.run_state_service.save_path = TEST_SAVE_PATH
	resumed._load_run_from_disk()
	await process_frame
	await process_frame
	_expect(resumed.current_screen == "kitchen_match", "Continue did not return an interrupted match to the Kitchen Match screen.")
	_expect(int(resumed.run.active_tournament.get("round", 0)) == saved_round, "Continue did not preserve the interrupted tournament round.")
	_expect(int(resumed.run.active_tournament.get("current_seed", 0)) == saved_seed, "Continue did not preserve the interrupted match setup.")
	_expect(String(resumed.run.active_tournament.get("current_opponent", {}).get("name", "")) == saved_opponent, "Continue did not preserve the interrupted opponent.")
	_expect(resumed.find_child("KitchenGameRoot", true, false) != null, "Continue did not rebuild the interrupted Kitchen Match.")

	resumed.queue_free()
	await process_frame
	_cleanup_test_saves()
	if failed:
		quit(1)
	else:
		print("Autosave and resume smoke test passed.")
		quit(0)


func _cleanup_test_saves() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = TEST_SAVE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
