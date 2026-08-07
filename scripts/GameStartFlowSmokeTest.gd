extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const BOOSTER_BOX_TEXTURE := preload("res://assets/season_setup/booster_box.png")
const TEST_SAVE_PATH := "user://topdeck_to_worlds_game_start_flow_test.json"

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
	_expect(main.find_child("TitleHowToPlayButton", true, false) is Button, "The landing screen did not offer How to Play as a main action.")
	_expect(main.find_child("OpenDebugMenuButton", true, false) is Button, "The landing screen did not keep the Debug Menu.")
	_expect(main.find_child("TitleSettingsButton", true, false) is Button, "The landing screen did not offer Settings.")
	var title_menu := main.find_child("BootLanding", true, false) as Control
	var title_primary := main.find_child("GameStartButton", true, false) as Button
	var storefront_backdrop := main.find_child("StorefrontBackdrop", true, false) as Control
	var storefront_shop := main.find_child("StorefrontShop", true, false) as Node3D
	var storefront_viewport := storefront_backdrop.get_node_or_null("ViewportContainer/SubViewport") as SubViewport if storefront_backdrop != null else null
	_expect(
		title_menu != null
		and title_menu.scene_file_path == "res://scenes/ui/TitleMenu.tscn"
		and title_primary != null
		and storefront_backdrop != null
		and storefront_shop != null,
		"The landing screen did not use the editable 3D storefront title scene."
	)
	_expect(
		storefront_viewport != null and storefront_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"The static title storefront is still rendering every frame."
	)
	_expect(main.find_child("TitleCollectionButton", true, false) == null, "The landing screen still offered Collection.")
	var options_button := main.find_child("TitleOptionsButton", true, false) as Button
	var options_panel := main.find_child("TitleOptionsPanel", true, false) as PanelContainer
	_expect(options_button != null and options_panel != null and not options_panel.visible, "The landing screen did not keep its collapsed More menu.")
	if options_button != null:
		options_button.emit_signal("pressed")
	await process_frame
	_expect(options_panel != null and options_panel.visible, "The Wired More button did not open its player options.")

	if title_primary != null:
		title_primary.emit_signal("pressed")
	await create_timer(0.9).timeout
	await process_frame
	_expect(main.current_screen == "game_start", "Game Start did not open the saved-run gateway.")
	var game_status_scene := main.find_child("GameStartGateway", true, false) as Control
	_expect(game_status_scene != null and game_status_scene.scene_file_path == "res://scenes/ui/GameStatusMenu.tscn", "Game Status was not instantiated from its editable scene.")
	var gateway_storefront := game_status_scene.get_node_or_null("StorefrontBackdrop") as StorefrontBackdrop if game_status_scene != null else null
	var gateway_storefront_viewport := gateway_storefront.get_node_or_null("ViewportContainer/SubViewport") as SubViewport if gateway_storefront != null else null
	_expect(
		gateway_storefront != null
		and gateway_storefront.current_view == "door"
		and gateway_storefront_viewport != null
		and gateway_storefront_viewport.render_target_update_mode in [SubViewport.UPDATE_ALWAYS, SubViewport.UPDATE_ONCE],
		"The saved-season gateway did not keep a live door backdrop through its layout handoff."
	)
	var empty_continue := main.find_child("ContinueRunButton", true, false) as Button
	_expect(empty_continue != null and empty_continue.disabled, "Continue was enabled without a valid autosave.")
	_expect(main.find_child("NewGameButton", true, false) is Button, "The saved-run gateway did not offer New Game.")
	var status_banner := main.find_child("GameStatusBanner", true, false) as PanelContainer
	_expect(status_banner != null, "The saved-run gateway did not use the sketch status banner.")

	if game_status_scene != null:
		game_status_scene.call("_request_back_to_title")
	await create_timer(0.9).timeout
	await process_frame
	await process_frame
	_expect(main.current_screen == "start", "Returning from the saved-season gateway did not restore the title.")
	var returned_title := main.find_child("BootLanding", true, false) as Control
	var returned_storefront := returned_title.get_node_or_null("StorefrontBackdrop") as StorefrontBackdrop if returned_title != null else null
	var returned_storefront_viewport := returned_storefront.get_node_or_null("ViewportContainer/SubViewport") as SubViewport if returned_storefront != null else null
	_expect(
		returned_storefront != null
		and returned_storefront.current_view == "overview"
		and returned_storefront_viewport != null
		and returned_storefront_viewport.render_target_update_mode in [SubViewport.UPDATE_ALWAYS, SubViewport.UPDATE_ONCE],
		"Returning to title froze a transparent storefront frame."
	)
	if "--capture-gateway" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var returned_preview := root.get_texture().get_image()
		_expect(
			returned_preview != null and returned_preview.save_png("/tmp/topdeck-to-worlds-returned-title.png") == OK,
			"The returned-title visual QA capture could not be written."
		)

	main._show_season_run_setup()
	await process_frame
	_expect(main.current_screen == "season_setup", "New Game did not open season setup.")
	var reduced_money: int = main.run_state_service.starting_money_for_difficulty("yellow")
	_expect(
		main.run_state_service.starting_money_for_difficulty("white") == 8
		and main.run_state_service.starting_money_for_difficulty("blue") == 8
		and reduced_money == 5
		and main.run_state_service.starting_money_for_difficulty("silver") == reduced_money
		and main.run_state_service.starting_money_for_difficulty("gold") == reduced_money,
		"Black and Blue did not start at $8, or the $5 modifier did not carry through Yellow, Silver, and Gold."
	)
	_expect(
		main.run_state_service.starting_lives_for_difficulty("blue") == 3
		and main.run_state_service.starting_lives_for_difficulty("yellow") == 3
		and main.run_state_service.starting_lives_for_difficulty("silver") == 1
		and main.run_state_service.starting_lives_for_difficulty("gold") == 1,
		"Silver's one-life modifier did not carry into Gold."
	)
	for stacked_difficulty in ["blue", "yellow"]:
		main.run = {"difficulty": stacked_difficulty}
		_expect(
			main.tournament_service.difficulty_opponent_quality_bonus(main) == 7.0,
			"Blue's opponent-quality modifier did not carry into %s." % stacked_difficulty.capitalize()
		)
	for stacked_difficulty in ["silver", "gold"]:
		main.run = {"difficulty": stacked_difficulty}
		_expect(
			main.tournament_service.difficulty_opponent_quality_bonus(main) == 11.0,
			"Blue and Silver opponent-quality modifiers did not stack in %s." % stacked_difficulty.capitalize()
		)
	main.run = {"difficulty": "gold"}
	_expect(
		main.tournament_service.ai_difficulty_for_round(main, {"id": "weekly_locals"}, 1) == "medium",
		"Blue's earlier AI-tier modifier did not carry into Gold."
	)
	main.run = {}
	var season_setup_scene := main.find_child("SeasonRegistration", true, false) as Control
	_expect(season_setup_scene != null and season_setup_scene.scene_file_path == "res://scenes/ui/SeasonSetupMenu.tscn", "Deck Select was not instantiated from its editable scene.")
	var select_background := main.find_child("PastelSelectBackground", true, false) as ColorRect
	_expect(
		select_background != null and select_background.material is ShaderMaterial,
		"Deck Select did not use the shared pastel card-café background."
	)
	_expect(main.DEMO_STARTER_ORDER == ["spicy", "hearty", "sweet", "draft_night"], "The starter wheel did not include Draft Night.")
	var shelf_viewport := main.find_child("ShelfViewport", true, false) as SubViewport
	var product_viewport := main.find_child("SelectedProductViewport", true, false) as SubViewport
	_expect(
		shelf_viewport != null
		and shelf_viewport.render_target_update_mode in [SubViewport.UPDATE_ONCE, SubViewport.UPDATE_DISABLED],
		"The static starter shelf is still rendering every frame."
	)
	_expect(
		product_viewport != null and product_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"The hidden starter product preview is still rendering continuously."
	)
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
	var preview_panel := main.find_child("StarterDeckPreviewPanel", true, false) as PanelContainer
	var preview_style := preview_panel.get_theme_stylebox("panel") as StyleBoxFlat if preview_panel != null else null
	_expect(
		preview_style != null
		and preview_style.bg_color.is_equal_approx(Color(PALETTE.CREAM, 0.985))
		and preview_style.border_color.is_equal_approx(PALETTE.NAVY),
		"The starter deck list did not use the cream-and-navy card-café panel."
	)
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
	var draft_label := main.find_child("DraftNightLabel", true, false) as Label
	_expect(
		draft_label != null and draft_label.text.contains("DRAFT NIGHT") and draft_label.text.contains("BOOSTER BOX"),
		"The starter shelf did not expose the redesigned Draft Night badge."
	)
	var booster_box_image := BOOSTER_BOX_TEXTURE.get_image()
	var booster_box_decompressed := booster_box_image != null and booster_box_image.decompress() == OK
	_expect(
		booster_box_image != null
		and booster_box_decompressed
		and booster_box_image.get_width() >= 725
		and booster_box_image.get_height() == 720
		and booster_box_image.get_pixel(96, 450).get_luminance() < 0.12,
		"Draft Night loaded the old booster-box atlas instead of the dark-backed display texture."
	)
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
	var title_how_to_play := main.find_child("TitleHowToPlayButton", true, false) as Button
	_expect(title_how_to_play != null, "How to Play disappeared when a valid autosave existed.")
	_expect(main.find_child("TitleCollectionButton", true, false) == null, "Collection returned when a valid autosave existed.")
	if title_how_to_play != null:
		title_how_to_play.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "tutorial", "Title-screen How to Play did not open the guided match.")
	main._show_game_start()
	await process_frame
	game_status_scene = main.find_child("GameStartGateway", true, false) as Control
	var continue_button := main.find_child("ContinueRunButton", true, false) as Button
	_expect(continue_button != null and not continue_button.disabled, "Continue did not enable for a valid autosave.")
	var saved_deck_frame := main.find_child("SavedDeckFrame", true, false) as PanelContainer
	var saved_status_frame := main.find_child("SavedGameStatusFrame", true, false) as PanelContainer
	var saved_deck_style := saved_deck_frame.get_theme_stylebox("panel") as StyleBoxFlat if saved_deck_frame != null else null
	var saved_status_style := saved_status_frame.get_theme_stylebox("panel") as StyleBoxFlat if saved_status_frame != null else null
	_expect(
		saved_deck_style != null
		and _color_rgb_close(saved_deck_style.border_color, PALETTE.PERIWINKLE)
		and saved_deck_style.corner_radius_top_left >= 12,
		"The saved deck art was not presented in the rounded periwinkle cafe card."
	)
	_expect(
		saved_status_style != null
		and _color_rgb_close(saved_status_style.border_color, PALETTE.SKY)
		and saved_status_style.corner_radius_top_left >= 12,
		"The saved season details were not presented in the rounded sky cafe card."
	)
	var saved_deck_button := main.find_child("SavedDeckCollectionButton", true, false) as Button
	var saved_deck_button_style := saved_deck_button.get_theme_stylebox("normal") as StyleBoxFlat if saved_deck_button != null else null
	_expect(
		saved_deck_button_style != null
		and _color_rgb_close(saved_deck_button_style.bg_color, PALETTE.CORAL, 0.006),
		"The saved-season deck action did not use the coral primary treatment."
	)
	var saved_product_art := main.find_child("SavedStarterProductArt", true, false) as TextureRect
	var saved_product_viewport := main.find_child("SavedProductViewportContainer", true, false) as SubViewportContainer
	_expect(
		saved_product_art != null
		and saved_product_art.visible
		and saved_product_art.texture is AtlasTexture
		and saved_product_viewport != null
		and not saved_product_viewport.visible,
		"The saved-season gateway did not replace the edge-on 3D starter with its front-facing product art."
	)
	if "--capture-gateway" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var gateway_preview := root.get_texture().get_image()
		_expect(
			gateway_preview != null and gateway_preview.save_png("/tmp/topdeck-to-worlds-saved-season.png") == OK,
			"The saved-season visual QA capture could not be written."
		)
	game_status_scene.call("_layout_gateway", Vector2(540, 640))
	await process_frame
	await process_frame
	var compact_viewport := Rect2(Vector2.ZERO, Vector2(540, 640))
	for node_name in ["DoorDisplay", "ActionColumn", "GameStartOptionsButton"]:
		var gateway_control := main.find_child(node_name, true, false) as Control
		_expect(
			gateway_control != null and compact_viewport.encloses(Rect2(gateway_control.position, gateway_control.size)),
			"%s overflowed the compact saved-season gateway: %s within %s." % [
				node_name,
				Rect2(gateway_control.position, gateway_control.size) if gateway_control != null else Rect2(),
				compact_viewport,
			]
		)
	game_status_scene.call("_layout_gateway")
	await process_frame
	if continue_button != null:
		continue_button.emit_signal("pressed")
	await process_frame
	await process_frame
	await process_frame
	_expect(main.current_screen == "deck", "Front-door Continue did not restore the saved screen.")
	_expect(main.find_child("DeckbuilderWorkspace", true, false) != null, "Continue did not restore the saved deck editor.")

	main.run.run_over = true
	saved = main.run_state_service.save_run(main.run, "result")
	_expect(bool(saved.get("ok", false)), "The flow test could not save a finished run.")
	main._show_game_start()
	await process_frame
	var finished_continue := main.find_child("ContinueRunButton", true, false) as Button
	_expect(finished_continue != null and finished_continue.disabled, "Continue remained enabled for a finished season.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	for unused_frame in range(4):
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


func _color_rgb_close(a: Color, b: Color, tolerance := 0.002) -> bool:
	return (
		absf(a.r - b.r) < tolerance
		and absf(a.g - b.g) < tolerance
		and absf(a.b - b.b) < tolerance
	)


func _remove_test_saves() -> void:
	for path in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".bak", TEST_SAVE_PATH + ".tmp"]:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute_path)
