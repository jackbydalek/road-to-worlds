extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TEST_SETTINGS_PATH := "user://road_to_worlds_public_ui_settings_test"
const SETTINGS_PREVIEW_PATH := "/tmp/road-to-worlds-settings.png"

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
		(
			main.find_child("OpenDebugMenuButton", true, false) != null
			and bool(main.find_child("OpenDebugMenuButton", true, false).visible)
		) == development_run,
		"The title's Debug Menu visibility did not match the development flag."
	)
	_expect(main.find_child("TitleSettingsButton", true, false) is Button, "The public title did not expose Settings.")
	var title_attribution := main.find_child("Attribution", true, false) as Label
	var title_discord := main.find_child("DiscordCommunityButton", true, false) as Button
	_expect(
		title_attribution != null
		and "Cozy Café UI Kit" in title_attribution.text
		and "Kenney Casino Audio" in title_attribution.text
		and "CC0" in title_attribution.text,
		"The title credits did not include the complete shipped attribution groups."
	)
	_expect(title_discord != null and not title_discord.disabled, "The title credits did not expose the Discord community link.")

	if not development_run:
		main._show_debug_starter_selection()
		await process_frame
		_expect(main.current_screen == "start", "A public build could enter the debug starter screen.")

	var settings_starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	main.run = main.run_state_service.create_run(
		"spicy",
		settings_starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main.player_settings = main._default_player_settings()
	main._apply_player_settings(false)
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
		"PlaySpeedSelect",
		"BattleTextScaleSelect",
		"HighContrastToggle",
		"ReducedMotionToggle",
		"SettingsBackButton",
		"SettingsResetButton",
		"SettingsAbandonRunButton",
		"AbandonRunConfirmation",
	]:
		_expect(main.find_child(node_name, true, false) != null, "Settings is missing %s." % node_name)
	var text_scale_select := main.find_child("TextScaleSelect", true, false) as OptionButton
	var battle_text_scale_select := main.find_child("BattleTextScaleSelect", true, false) as OptionButton
	_expect(
		text_scale_select != null
		and text_scale_select.get_item_text(text_scale_select.selected) == "100%",
		"The default menu text size was not 100%."
	)
	_expect(
		battle_text_scale_select != null
		and battle_text_scale_select.get_item_text(battle_text_scale_select.selected) == "100%",
		"The default battle text size was not 100%."
	)
	var abandon_button := main.find_child("SettingsAbandonRunButton", true, false) as Button
	var abandon_confirmation := main.find_child("AbandonRunConfirmation", true, false) as HBoxContainer
	_expect(abandon_button != null and not abandon_button.disabled, "An active season could not be abandoned from Settings.")
	if abandon_button != null:
		abandon_button.emit_signal("pressed")
	await process_frame
	_expect(abandon_confirmation != null and abandon_confirmation.visible, "Abandon Run did not require confirmation.")
	var cancel_abandon := main.find_child("CancelAbandonRunButton", true, false) as Button
	if cancel_abandon != null:
		cancel_abandon.emit_signal("pressed")
	await process_frame
	if DisplayServer.get_name() != "headless":
		var preview := root.get_texture().get_image()
		_expect(preview != null and preview.save_png(SETTINGS_PREVIEW_PATH) == OK, "Could not save the Settings preview.")
	_expect(AudioServer.get_bus_index("Music") >= 0, "The Music audio bus was not created.")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "The SFX audio bus was not created.")
	var original_settings: Dictionary = main.player_settings.duplicate(true)
	main.settings_path = TEST_SETTINGS_PATH + ("_dev.json" if development_run else "_public.json")
	main.player_settings.master_volume = 37.0
	main.player_settings.text_scale = 1.1
	main.player_settings.play_speed = "fast"
	main.player_settings.battle_text_scale = 1.5
	main.player_settings.high_contrast = true
	main.player_settings.reduced_motion = true
	main._save_player_settings()
	main.player_settings = main._default_player_settings()
	main._load_player_settings()
	_expect(is_equal_approx(float(main.player_settings.master_volume), 37.0), "Master volume did not persist.")
	_expect(is_equal_approx(float(main.player_settings.text_scale), 1.1), "Text size did not persist.")
	_expect(String(main.player_settings.play_speed) == "fast", "Play speed did not persist.")
	_expect(is_equal_approx(float(main.player_settings.battle_text_scale), 1.5), "Battle text size did not persist.")
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
	var discord_button := main.find_child("FinaleDiscordButton", true, false) as Button
	_expect(
		discord_button != null
		and not discord_button.disabled
		and discord_button.text == "Join the Discord"
		and main.DISCORD_INVITE_URL == "https://discord.gg/EK6AmYgnPZ",
		"The finale does not expose the configured public Discord invite."
	)
	_expect(
		main.find_child("FinaleSteamWishlistButton", true, false) == null,
		"The finale exposed a placeholder Steam action without a configured public URL."
	)

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	for unused_frame in range(4):
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
