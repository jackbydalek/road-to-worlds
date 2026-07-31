extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://road_to_worlds_game_start_flow_test.json"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_test_saves()
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.run_state_service.save_path = TEST_SAVE_PATH

	_expect(main.current_screen == "start", "The game did not boot to the landing screen.")
	_expect(main.find_child("GameStartButton", true, false) is Button, "The landing screen did not offer Game Start.")
	_expect(main.find_child("StartTutorialButton", true, false) is Button, "The landing screen did not keep How to Play.")
	_expect(main.find_child("OpenDebugMenuButton", true, false) is Button, "The landing screen did not keep the Debug Menu.")
	_expect(main.find_child("TitleSettingsButton", true, false) is Button, "The landing screen did not offer Settings.")
	var title_banner := main.find_child("BootTitleBanner", true, false) as PanelContainer
	var title_style := title_banner.get_theme_stylebox("panel") as StyleBoxTexture if title_banner != null else null
	_expect(
		title_style != null
		and title_style.texture.resource_path == "res://assets/ui/wired_title/title_paper.svg",
		"The landing screen did not use the Wired title treatment."
	)
	_expect(main.find_child("WiredTitleDoodles", true, false) != null, "The landing screen did not render its sketch decorations.")
	var collection_button := main.find_child("TitleCollectionButton", true, false) as Button
	_expect(collection_button != null, "The landing screen did not offer Collection.")
	var options_button := main.find_child("TitleOptionsButton", true, false) as Button
	var options_panel := main.find_child("TitleOptionsPanel", true, false) as PanelContainer
	_expect(options_button != null and options_panel != null and not options_panel.visible, "The landing screen did not keep its collapsed More menu.")
	if options_button != null:
		options_button.emit_signal("pressed")
	await process_frame
	_expect(options_panel != null and options_panel.visible, "The Wired More button did not open its player options.")

	main._show_game_start()
	await process_frame
	_expect(main.current_screen == "game_start", "Game Start did not open the saved-run gateway.")
	var empty_continue := main.find_child("ContinueRunButton", true, false) as Button
	_expect(empty_continue != null and empty_continue.disabled, "Continue was enabled without a valid autosave.")
	_expect(main.find_child("NewGameButton", true, false) is Button, "The saved-run gateway did not offer New Game.")
	var status_banner := main.find_child("GameStatusBanner", true, false) as PanelContainer
	_expect(status_banner != null, "The saved-run gateway did not use the sketch status banner.")

	main._show_season_run_setup()
	await process_frame
	_expect(main.current_screen == "season_setup", "New Game did not open season setup.")
	_expect(main.DEMO_STARTER_ORDER == ["spicy", "hearty", "sweet", "draft_night"], "The starter wheel did not include Draft Night.")
	var starter_card := main.find_child("SeasonStarterCard", true, false)
	var border_card := main.find_child("SeasonBorderCard", true, false)
	_expect(starter_card != null and String(starter_card.get_meta("starter_id", "")) == "spicy", "The setup screen did not expose its selected starter.")
	_expect(border_card != null and String(border_card.get_meta("difficulty_id", "")) == "white", "The setup screen did not expose its selected border.")
	var starter_symbol := main.find_child("StarterDeckSymbol", true, false) as Label
	_expect(starter_symbol != null and starter_symbol.text == "🌶️", "The starter information bar did not use the assigned Noto affinity symbol.")
	_expect(main.find_child("DraftNightStar", true, false) == null, "The Draft Night emblem appeared for a regular starter deck.")
	var contents_button := main.find_child("StarterDeckContentsButton", true, false) as Button
	var starter_index_before_preview: int = main.season_setup_archetype_index
	_expect(contents_button != null, "The starter selector did not offer a deck-contents action.")
	if contents_button != null:
		contents_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.season_setup_archetype_index == starter_index_before_preview, "Opening the deck list unexpectedly changed the selected starter.")
	_expect(main.find_child("StarterDeckPreview", true, false) != null, "The deck-contents icon did not open its popup.")
	var preview_summary := main.find_child("StarterDeckPreviewSummary", true, false) as Label
	_expect(preview_summary != null and preview_summary.text.begins_with("20 cards"), "The starter deck popup did not report the complete 20-card list.")
	var preview_entries := main.find_children("StarterDeckPreviewEntry_*", "", true, false)
	_expect(preview_entries.size() > 0, "The starter deck popup did not render its card entries.")
	if not preview_entries.is_empty():
		var first_entry := preview_entries[0] as Control
		var hover_card_id := String(first_entry.name).trim_prefix("StarterDeckPreviewEntry_")
		main._show_starter_deck_hover_preview(first_entry, hover_card_id)
		await process_frame
		var hovered_face := main.find_child("StarterDeckHoveredCardFace", true, false) as Control
		_expect(hovered_face != null and hovered_face.visible, "Holding over a deck-list entry did not render its full card.")
		main._hide_starter_deck_hover_preview()
		_expect(main.find_child("StarterDeckCardHoverPreview", true, false) != null and not main.find_child("StarterDeckCardHoverPreview", true, false).visible, "Leaving a deck-list entry did not hide its full-card preview.")
	var close_preview := main.find_child("CloseStarterDeckPreviewButton", true, false) as Button
	if close_preview != null:
		close_preview.emit_signal("pressed")
	await process_frame

	main.season_setup_archetype_index = main.DEMO_STARTER_ORDER.find(main.DRAFT_NIGHT_ID)
	main._show_season_run_setup()
	await process_frame
	var draft_star := main.find_child("DraftNightStar", true, false) as TextureRect
	_expect(draft_star != null and draft_star.texture.resource_path == "res://assets/ui/wired_title/draft_star.svg", "Draft Night did not use the sketch star.")
	_expect(main.find_child("StarterDeckSymbol", true, false) == null, "Draft Night displayed a starter affinity symbol instead of its star.")
	var draft_contents := main.find_child("StarterDeckContentsButton", true, false) as Button
	if draft_contents != null:
		draft_contents.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.find_child("DraftNightDeckPreviewEmptyState", true, false) != null, "Draft Night did not explain that its deck is built during the draft.")
	main._close_starter_deck_preview()
	await process_frame

	main.season_setup_archetype_index = 0
	main.season_setup_difficulty_index = main.DIFFICULTY_ORDER.find("silver")
	main._confirm_season_run_setup()
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "Starting with a starter deck did not enter the shop.")
	_expect(String(main.run.get("starter", "")) == "spicy" and String(main.run.get("difficulty", "")) == "silver", "Starter or border selection was not preserved.")

	var saved: Dictionary = main.run_state_service.save_run(main.run, "deck")
	_expect(bool(saved.get("ok", false)), "The flow test could not create its isolated autosave.")
	main._show_start()
	await process_frame
	var saved_collection := main.find_child("TitleCollectionButton", true, false) as Button
	_expect(saved_collection != null and not saved_collection.disabled, "Collection did not enable for a valid autosave.")
	if saved_collection != null:
		saved_collection.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "deck", "Title-screen Collection did not open the saved Deck Workshop.")
	main._show_game_start()
	await process_frame
	var continue_button := main.find_child("ContinueRunButton", true, false) as Button
	_expect(continue_button != null and not continue_button.disabled, "Continue did not enable for a valid autosave.")
	if continue_button != null:
		continue_button.emit_signal("pressed")
	await process_frame
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "Front-door Continue did not route directly to the shop.")
	_expect(main.find_child("CardShopOverworld", true, false) != null, "Continue did not restore the season shop.")

	main.run.run_over = true
	saved = main.run_state_service.save_run(main.run, "result")
	_expect(bool(saved.get("ok", false)), "The flow test could not save a finished run.")
	main._show_game_start()
	await process_frame
	var finished_continue := main.find_child("ContinueRunButton", true, false) as Button
	_expect(finished_continue != null and finished_continue.disabled, "Continue remained enabled for a finished season.")

	main.queue_free()
	await process_frame
	_remove_test_saves()
	if failed:
		quit(1)
	else:
		print("Game start flow smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _remove_test_saves() -> void:
	for path in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".bak", TEST_SAVE_PATH + ".tmp"]:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute_path)
