extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TEST_SETTINGS_PATH := "user://road_to_worlds_public_ui_settings_test"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var development_run := "--dev" in OS.get_cmdline_user_args()
	_expect(
		main._development_tools_enabled() == development_run,
		"The development flag did not select the expected UI mode."
	)
	_expect(
		(main.find_child("OpenDebugMenuButton", true, false) != null) == development_run,
		"The title's Debug Menu visibility did not match the development flag."
	)
	_expect(main.find_child("TitleSettingsButton", true, false) is Button, "The public title did not expose Settings.")

	if not development_run:
		main._show_debug_starter_selection()
		await process_frame
		_expect(main.current_screen == "start", "A public build could enter the debug starter screen.")

	main._show_settings()
	await process_frame
	_expect(main.current_screen == "settings", "Settings did not open.")
	for node_name in [
		"FullscreenToggle",
		"ResolutionSelect",
		"MasterVolumeSlider",
		"MusicVolumeSlider",
		"SoundeffectsVolumeSlider",
		"TextScaleSelect",
		"HighContrastToggle",
		"ReducedMotionToggle",
		"SettingsBackButton",
		"SettingsResetButton",
	]:
		_expect(main.find_child(node_name, true, false) != null, "Settings is missing %s." % node_name)
	_expect(AudioServer.get_bus_index("Music") >= 0, "The Music audio bus was not created.")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "The SFX audio bus was not created.")
	var original_settings: Dictionary = main.player_settings.duplicate(true)
	main.settings_path = TEST_SETTINGS_PATH + ("_dev.json" if development_run else "_public.json")
	main.player_settings.master_volume = 37.0
	main.player_settings.text_scale = 1.1
	main.player_settings.high_contrast = true
	main.player_settings.reduced_motion = true
	main._save_player_settings()
	main.player_settings = main._default_player_settings()
	main._load_player_settings()
	_expect(is_equal_approx(float(main.player_settings.master_volume), 37.0), "Master volume did not persist.")
	_expect(is_equal_approx(float(main.player_settings.text_scale), 1.1), "Text size did not persist.")
	_expect(bool(main.player_settings.high_contrast), "High-contrast text did not persist.")
	_expect(bool(main.player_settings.reduced_motion), "Reduced menu motion did not persist.")
	main._apply_player_settings(false)
	_expect(bool(root.get_meta("high_contrast", false)), "High-contrast text was not applied.")
	_expect(bool(root.get_meta("reduced_motion", false)), "Reduced menu motion was not applied.")
	main.player_settings = original_settings
	main._apply_player_settings(false)
	if FileAccess.file_exists(main.settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(main.settings_path))

	var starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main._show_autosave_indicator()
	var save_glyph := main.find_child("AutosaveIndicator", true, false) as Label
	_expect(
		save_glyph != null and save_glyph.visible and save_glyph.text == "◆" and save_glyph.size.x <= 40.0,
		"The public save feedback was not reduced to a compact glyph."
	)
	main._show_thanks_for_playing()
	await process_frame
	_expect(main.find_child("FinaleChampionTitle", true, false) != null, "The finale is missing its champion hero.")
	_expect(main.find_child("FinaleTeaser", true, false) != null, "The finale is missing its Road Ahead teaser.")
	_expect(main.find_child("FinaleDeckButton", true, false) != null, "The finale cannot open the winning deck.")
	_expect(main.find_child("ThanksMainMenuButton", true, false) != null, "The finale cannot return to the title.")

	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Public UI smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
