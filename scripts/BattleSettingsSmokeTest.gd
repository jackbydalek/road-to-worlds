extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const BATTLE_OPTIONS_PREVIEW_PATH := "/tmp/topdeck_to_worlds_battle_options.png"
const TEST_SETTINGS_PATH := "/tmp/topdeck_to_worlds_battle_options_test_settings.json"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.settings_path = TEST_SETTINGS_PATH

	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run("spicy", starter, main._predator_archetype("spicy"), "debug", "white")
	main._start_debug_kitchen_match()
	await process_frame
	await process_frame

	var tabletop := main.find_child("Tabletop3DPrototype", true, false) as Control
	var settings_button := main.find_child("SettingsButton", true, false) as Button
	_expect(tabletop != null and settings_button != null, "The battle did not expose its Settings control.")
	if tabletop == null or settings_button == null:
		quit(1)
		return
	var turn_before := int(tabletop.state.get("turn", -1))
	settings_button.emit_signal("pressed")
	await process_frame

	_expect(main.current_screen == "settings", "The battle Settings control did not open the settings screen.")
	_expect(main.suspended_tabletop == tabletop, "Opening Settings did not preserve the live tabletop instance.")
	_expect(not tabletop.visible and tabletop.process_mode == Node.PROCESS_MODE_DISABLED, "The preserved battle did not pause behind Settings.")
	_expect(main.find_child("MusicVolumeSlider", true, false) is HSlider, "The battle did not open the full game settings screen.")
	var settings_display_panel := main.find_child("SettingsDisplayPanel", true, false) as PanelContainer
	var settings_battle_panel := main.find_child("SettingsBattlePanel", true, false) as PanelContainer
	_expect(
		settings_display_panel != null
		and not settings_display_panel.visible
		and settings_display_panel.find_child("SettingsAngularSurface", false, false) != null
		and settings_battle_panel != null
		and settings_battle_panel.visible
		and settings_battle_panel.find_child("SettingsAngularSurface", false, false) != null
		and main.find_child("SettingsCategoryRail", true, false) != null
		and main.find_child("DisplayAccentRule", true, false) is ColorRect,
		"Options did not open directly to its styled Battle category."
	)
	var play_speed_select := main.find_child("PlaySpeedSelect", true, false) as OptionButton
	var battle_text_select := main.find_child("BattleTextScaleSelect", true, false) as OptionButton
	var board_info_toggle := main.find_child("BoardInfoToggle", true, false) as CheckButton
	_expect(play_speed_select != null and battle_text_select != null and board_info_toggle != null, "Options did not expose all battle preferences.")
	_expect(settings_battle_panel != null and settings_battle_panel.visible, "The battle cog did not open Options directly to the Battle category.")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.35).timeout
		var battle_options_preview := root.get_texture().get_image()
		_expect(battle_options_preview.save_png(BATTLE_OPTIONS_PREVIEW_PATH) == OK, "Battle Options preview could not be saved.")
	if play_speed_select != null:
		play_speed_select.emit_signal("item_selected", 0)
	if battle_text_select != null:
		battle_text_select.emit_signal("item_selected", 2)
	if board_info_toggle != null:
		board_info_toggle.emit_signal("toggled", true)

	main._return_from_settings()
	await process_frame
	await process_frame
	_expect(main.current_screen == "kitchen_match", "Back from Settings did not return to the battle.")
	_expect(tabletop.get_parent() == main.content and tabletop.visible, "Back from Settings did not restore the same tabletop instance.")
	_expect(tabletop.process_mode == Node.PROCESS_MODE_INHERIT, "The battle remained paused after leaving Settings.")
	_expect(int(tabletop.state.get("turn", -1)) == turn_before, "Opening Settings changed or restarted the battle turn.")
	_expect(tabletop.rival_pacing_index == 0 and tabletop.text_scale_index == 2 and tabletop.board_info_visible, "Options changes did not apply to the restored battle.")
	_expect(tabletop.find_child("MatchSettingsMenu", true, false) == null, "The obsolete in-battle settings dropdown still exists.")

	await create_timer(1.15).timeout
	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	if failed:
		quit(1)
		return
	print("Battle settings smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
