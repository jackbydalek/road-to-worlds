extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const TEST_SETTINGS_PATH := "user://topdeck_to_worlds_public_ui_settings_test"
const SETTINGS_PREVIEW_PATH := "res://outputs/illustrated_vfx/settings_menu_redesign.png"

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
		and "Case Portman Audio" in title_attribution.text
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
	main.run.run_loop = "route"
	main.run.max_life = 40
	main.run.life = 40
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
		"BoardInfoToggle",
		"HighContrastToggle",
		"ReducedMotionToggle",
		"SettingsBackButton",
		"SettingsResetButton",
		"SettingsAbandonRunButton",
		"AbandonRunConfirmation",
	]:
		_expect(main.find_child(node_name, true, false) != null, "Settings is missing %s." % node_name)
	var text_scale_select := main.find_child("TextScaleSelect", true, false) as OptionButton
	var play_speed_select := main.find_child("PlaySpeedSelect", true, false) as OptionButton
	var battle_text_scale_select := main.find_child("BattleTextScaleSelect", true, false) as OptionButton
	var display_category := main.find_child("SettingsCategoryDisplay", true, false) as Button
	var audio_category := main.find_child("SettingsCategoryAudio", true, false) as Button
	var display_panel := main.find_child("SettingsDisplayPanel", true, false) as Control
	var audio_panel := main.find_child("SettingsAudioPanel", true, false) as Control
	_expect(display_category != null and audio_category != null, "Settings did not expose the Key System category rail.")
	_expect(
		main.find_child("SettingsDescriptionPanel", true, false) == null
		and main.find_child("SettingsDescriptionLabel", true, false) == null,
		"Settings still displayed the removed option guide."
	)
	_expect(display_panel != null and display_panel.visible and audio_panel != null and not audio_panel.visible, "Settings did not open on a single focused Display page.")
	if audio_category != null:
		audio_category.emit_signal("pressed")
	await process_frame
	_expect(audio_panel != null and audio_panel.visible and display_panel != null and not display_panel.visible, "The Audio category did not replace the focused settings page.")
	if display_category != null:
		display_category.emit_signal("pressed")
	await process_frame
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
	var back_button := main.find_child("SettingsBackButton", true, false) as Button
	var reset_button := main.find_child("SettingsResetButton", true, false) as Button
	var header_row := main.find_child("SettingsHeaderRow", true, false) as HBoxContainer
	var settings_actions := main.find_child("SettingsActions", true, false) as HBoxContainer
	var settings_title := main.find_child("SettingsTitle", true, false) as Label
	var battle_category := main.find_child("SettingsCategoryBattle", true, false) as Button
	_expect(
		reset_button != null
		and header_row != null
		and reset_button.get_parent() == header_row
		and reset_button.get_theme_color("icon_normal_color").is_equal_approx(PALETTE.CARBON)
		and settings_actions != null
		and reset_button.get_parent() != settings_actions,
		"Restore Defaults was not moved opposite the Options title in the top header."
	)
	_expect(
		back_button != null
		and abandon_button != null
		and back_button.custom_minimum_size.y >= 50.0
		and abandon_button.custom_minimum_size.y >= 50.0
		and back_button.get_theme_font_size("font_size") >= 21
		and abandon_button.get_theme_font_size("font_size") >= 21,
		"The Back and Abandon Run actions were not made taller and more legible."
	)
	_expect(
		settings_title != null
		and settings_title.get_theme_font_size("font_size") >= 28
		and battle_category != null
		and battle_category.get_theme_font_size("font_size") >= 16
		and play_speed_select != null
		and play_speed_select.get_theme_font_size("font_size") >= 16
		and reset_button != null
		and reset_button.get_theme_font_size("font_size") >= 16,
		"The Options screen did not apply its larger overall text scale (title %d, category %d, select %d, reset %d)." % [
			settings_title.get_theme_font_size("font_size") if settings_title != null else -1,
			battle_category.get_theme_font_size("font_size") if battle_category != null else -1,
			play_speed_select.get_theme_font_size("font_size") if play_speed_select != null else -1,
			reset_button.get_theme_font_size("font_size") if reset_button != null else -1,
		]
	)
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
		_expect(preview != null and preview.save_png(ProjectSettings.globalize_path(SETTINGS_PREVIEW_PATH)) == OK, "Could not save the Settings preview.")
	_expect(AudioServer.get_bus_index("Music") >= 0, "The Music audio bus was not created.")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "The SFX audio bus was not created.")
	var original_settings: Dictionary = main.player_settings.duplicate(true)
	main.settings_path = TEST_SETTINGS_PATH + ("_dev.json" if development_run else "_public.json")
	main.player_settings.master_volume = 37.0
	main.player_settings.text_scale = 1.1
	main.player_settings.play_speed = "fast"
	main.player_settings.battle_text_scale = 1.5
	main.player_settings.show_board_info = true
	main.player_settings.high_contrast = true
	main.player_settings.reduced_motion = true
	main._save_player_settings()
	main.player_settings = main._default_player_settings()
	main._load_player_settings()
	_expect(is_equal_approx(float(main.player_settings.master_volume), 37.0), "Master volume did not persist.")
	_expect(is_equal_approx(float(main.player_settings.text_scale), 1.1), "Text size did not persist.")
	_expect(String(main.player_settings.play_speed) == "fast", "Play speed did not persist.")
	_expect(is_equal_approx(float(main.player_settings.battle_text_scale), 1.5), "Battle text size did not persist.")
	_expect(bool(main.player_settings.show_board_info), "Board-information visibility did not persist.")
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
	var finale_title := main.find_child("FinaleChampionTitle", true, false) as Label
	var finale_hero_detail := main.find_child("FinaleHeroDetail", true, false) as Label
	var finale_road_detail := main.find_child("FinaleRoadDetail", true, false) as Label
	_expect(
		finale_title != null and finale_title.text == "Thanks for Playing the Demo!",
		"The finale is missing its personal demo thank-you title."
	)
	_expect(
		finale_hero_detail != null
		and finale_hero_detail.text == "Hope you liked it! The fact that people are actually getting to the end of my demo is dope so thank you!",
		"The finale is missing its personal thank-you message."
	)
	_expect(
		finale_road_detail != null
		and finale_road_detail.text == "Still working on getting multiple packs in and making the path all the way to worlds. Join the discord or comment your feedback to help make the game better!",
		"The finale is missing the updated Road Ahead message."
	)
	_expect(main.find_child("FinaleTeaser", true, false) != null, "The finale is missing its Road Ahead teaser.")
	_expect(main.find_child("FinaleDeckButton", true, false) != null, "The finale cannot open the winning deck.")
	_expect(main.find_child("ThanksMainMenuButton", true, false) != null, "The finale cannot return to the title.")
	var finale_hero := main.find_child("FinaleHero", true, false) as PanelContainer
	var finale_hero_style := finale_hero.get_theme_stylebox("panel") as StyleBoxFlat if finale_hero != null else null
	_expect(
		finale_hero_style != null
		and finale_hero_style.border_color.is_equal_approx(PALETTE.NAVY)
		and finale_hero_style.corner_radius_top_left >= 16,
		"The finale hero does not use the rounded navy illustrated-card treatment."
	)
	var finale_milestones := main.find_child("FinaleAchievementList", true, false) as GridContainer
	_expect(
		finale_milestones != null and finale_milestones.columns == 2,
		"The finale milestones were not consolidated into the two-column season scrapbook."
	)
	var milestone_statuses := main.find_children("FinaleMilestoneStatus", "Label", true, false)
	var readable_milestone_statuses := milestone_statuses.size() == 4
	for milestone_status_value in milestone_statuses:
		var milestone_status := milestone_status_value as Label
		readable_milestone_statuses = (
			readable_milestone_statuses
			and milestone_status != null
			and milestone_status.get_theme_font_size("font_size") >= 18
		)
	_expect(readable_milestone_statuses, "The finale milestone values are too small to scan.")
	var finale_teaser := main.find_child("FinaleTeaser", true, false) as PanelContainer
	var finale_teaser_style := finale_teaser.get_theme_stylebox("panel") as StyleBoxFlat if finale_teaser != null else null
	_expect(
		finale_teaser_style != null
		and finale_teaser_style.border_color.is_equal_approx(PALETTE.PERIWINKLE)
		and finale_teaser_style.corner_radius_top_left >= 12,
		"The finale Road Ahead panel does not use the lavender/periwinkle illustrated treatment."
	)
	var discord_button := main.find_child("FinaleDiscordButton", true, false) as Button
	var discord_face = discord_button.get_node_or_null("BattleAngularButtonFace") if discord_button != null else null
	_expect(
		discord_button != null
		and not discord_button.disabled
		and discord_button.text == "Join the Discord"
		and discord_face != null
		and discord_face.variant == "primary"
		and discord_face.fill_color_for_state("normal").is_equal_approx(PALETTE.SELECTION_BLUE)
		and main.DISCORD_INVITE_URL == "https://discord.gg/EK6AmYgnPZ",
		"The finale does not expose the configured public Discord invite."
	)
	_expect(
		main.find_child("FinaleSteamWishlistButton", true, false) == null,
		"The finale exposed a placeholder Steam action without a configured public URL."
	)
	var finale_deck_button := main.find_child("FinaleDeckButton", true, false) as Button
	if finale_deck_button != null:
		finale_deck_button.emit_signal("pressed")
		await process_frame
	_expect(main.current_screen == "deck", "The finale Review Winning Deck action did not open the deck view.")
	var finale_deck_back := main.find_child("DeckbuilderBackButton", true, false) as Button
	if finale_deck_back != null:
		finale_deck_back.emit_signal("pressed")
		await process_frame
	_expect(main.current_screen == "thanks", "The winning deck did not return to the finale.")
	var finale_main_menu := main.find_child("ThanksMainMenuButton", true, false) as Button
	if finale_main_menu != null:
		finale_main_menu.emit_signal("pressed")
		await process_frame
	_expect(main.current_screen == "start", "The finale Return to Main Menu action did not open the title screen.")

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
