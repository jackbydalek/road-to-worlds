extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "/private/tmp/topdeck_to_worlds_game_start_flow_test.json"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_test_saves()
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	main.run_state_service.save_path = TEST_SAVE_PATH

	var title := main.find_child("BootLanding", true, false) as Control
	if title != null:
		title.configure(false, false, false)
	await process_frame
	var new_game := main.find_child("GameStartButton", true, false) as Button
	var empty_continue := main.find_child("ContinueRunButton", true, false) as Button
	var how_to_play := main.find_child("TitleHowToPlayButton", true, false) as Button
	var credits := main.find_child("CreditsPosterButton", true, false) as Button
	_expect(main.current_screen == "start", "The game did not boot to the title screen.")
	_expect(new_game != null and new_game.text == "NEW GAME", "The title did not offer New Game.")
	_expect(empty_continue != null and not empty_continue.visible and empty_continue.disabled, "Continue appeared without a valid autosave.")
	_expect(how_to_play != null and credits != null, "The centered title lost How to Play or Credits.")
	_expect(main.find_child("GameStartGateway", true, false) == null, "The retired saved-run gateway still exists in the title flow.")
	_expect(not main.has_method("_play_menu_circle_wipe"), "The retired title-menu wipe remained in Main.")
	_expect(not main.has_method("_play_shop_door_bell"), "The retired storefront ding remained in Main.")
	if title != null:
		var title_center_x: float = title.get_global_rect().get_center().x
		for button in [new_game, how_to_play, credits]:
			_expect(
				button != null and absf(button.get_global_rect().get_center().x - title_center_x) < 1.0,
				"%s was not centered beneath the title logo." % button.name if button != null else "A title action was missing."
			)

	if new_game != null:
		new_game.emit_signal("pressed")
	await create_timer(0.4).timeout
	await _settle()
	_expect(main.current_screen == "season_setup", "New Game did not go directly to starter selection.")
	_expect(main.find_child("SeasonRegistration", true, false) != null, "Starter selection did not render after New Game.")

	main._start_new_run_with_mode("spicy", "season", "white")
	await _settle()
	_expect(main.current_screen == "route_map", "The test route run did not reach Starter City.")
	var saved: Dictionary = main.run_state_service.save_run(main.run, "route_map")
	_expect(bool(saved.get("ok", false)), "The flow test could not create its isolated autosave.")

	main._show_start()
	await _settle()
	var continue_button := main.find_child("ContinueRunButton", true, false) as Button
	var saved_title := main.find_child("BootLanding", true, false) as Control
	_expect(main.current_screen == "start", "Returning from Starter City did not restore the title.")
	_expect(continue_button != null and continue_button.visible and not continue_button.disabled, "Continue did not appear on the title for a valid autosave.")
	_expect(saved_title != null and main.find_child("GameStartGateway", true, false) == null, "Continue was not kept on the title itself.")
	if continue_button != null and saved_title != null:
		_expect(
			absf(continue_button.get_global_rect().get_center().x - saved_title.get_global_rect().get_center().x) < 1.0,
			"Continue was not centered with the other title actions."
		)
		continue_button.emit_signal("pressed")
	await create_timer(0.4).timeout
	await _settle()
	_expect(main.current_screen == "route_map", "Continue did not restore the saved Starter City route.")

	main.run.run_over = true
	saved = main.run_state_service.save_run(main.run, "route_map")
	_expect(bool(saved.get("ok", false)), "The flow test could not save a completed run.")
	main._show_start()
	await _settle()
	var finished_continue := main.find_child("ContinueRunButton", true, false) as Button
	_expect(
		finished_continue != null and not finished_continue.visible and finished_continue.disabled,
		"Continue remained available for a completed run."
	)

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await _settle()
	_remove_test_saves()
	if failed:
		quit(1)
		return
	print("Game start flow smoke test passed.")
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _remove_test_saves() -> void:
	for path in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".bak", TEST_SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
