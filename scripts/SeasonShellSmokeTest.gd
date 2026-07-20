extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.cards_by_id.size() == 88, "Season shell did not load all 88 kitchen cards.")
	_expect(main.archetypes_by_id.size() == 5, "Season shell did not build the five kitchen archetypes.")
	_expect(main._affinity_symbol("fresh") == "🍋‍🟩" and main._affinity_symbol("spicy") == "🌶️", "Fresh or Spicy affinity symbols were not configured.")
	_expect(main._affinity_symbol("funky") == "🥒" and main._affinity_symbol("sweet") == "🍬" and main._affinity_symbol("hearty") == "🍲", "Funky, Sweet, or Hearty affinity symbols were not configured.")
	_expect(main._affinity_symbol("neutral") == "🧊" and main._affinity_label("neutral") == "🧊 Typeless", "Typeless cards did not use the ice-cube symbol.")
	_expect(main._card_type_label("chef") == "🧑‍🍳 Chef" and main._card_type_label("tool") == "🥄 Item", "Chef or Item cards did not use their Noto type symbols.")
	_expect(main._card_type_label("spice") == "✨ Spice" and main._card_type_label("environment") == "🌄 Environment", "Spice or Environment cards did not use their Noto type symbols.")
	_expect(main._card_descriptor({"card_type": "chef", "archetype": "neutral"}) == "🧑‍🍳 Chef" and main._card_descriptor({"card_type": "tool", "archetype": "neutral"}) == "🥄 Item", "Chef or Item cards were still presented as Typeless.")
	_expect(main._card_display_name({"name": "Firecracker Shrimp", "card_type": "meal", "archetype": "spicy"}) == "🌶️ Firecracker Shrimp" and main._card_display_name({"name": "Bagver", "card_type": "ingredient", "archetype": "hearty"}) == "🍲 Bagver", "Unit names did not include their affinity symbols.")
	_expect(main._format_affinity_requirements(["spicy", "sweet"]) == "🌶️ Spicy + 🍬 Sweet", "Recipe requirements did not use the affinity symbols.")
	var emoji_font := load("res://assets/fonts/KitchenAffinitySymbols.ttf") as Font
	_expect(emoji_font != null and emoji_font.has_char(0x2728) and emoji_font.has_char(0x1F304) and emoji_font.has_char(0x1F34B) and emoji_font.has_char(0x1F7E9) and emoji_font.has_char(0x1F336) and emoji_font.has_char(0x1F952) and emoji_font.has_char(0x1F36C) and emoji_font.has_char(0x1F372) and emoji_font.has_char(0x1F9CA) and emoji_font.has_char(0x1F9D1) and emoji_font.has_char(0x1F373) and emoji_font.has_char(0x1F944), "Noto Emoji did not contain all configured type glyphs.")
	_expect(not emoji_font.has_char(0x30) and not emoji_font.has_char(0x31) and not emoji_font.has_char(0x39), "The affinity-symbol font still claimed numeric glyphs.")
	var lime_line := TextLine.new()
	lime_line.add_string("🍋‍🟩", emoji_font, 32)
	_expect(TextServerManager.get_primary_interface().shaped_text_get_glyph_count(lime_line.get_rid()) == 1, "Noto Emoji did not shape the Fresh lime sequence as one glyph.")
	var chef_line := TextLine.new()
	chef_line.add_string("🧑‍🍳", emoji_font, 32)
	_expect(TextServerManager.get_primary_interface().shaped_text_get_glyph_count(chef_line.get_rid()) == 1, "Noto Emoji did not shape the Chef sequence as one glyph.")
	var scoped_ui_line := TextLine.new()
	scoped_ui_line.add_string("1🌶️2🧊3🍋‍🟩4", main.theme.default_font, 32)
	var scoped_glyphs := TextServerManager.get_primary_interface().shaped_text_get_glyphs(scoped_ui_line.get_rid())
	_expect(scoped_glyphs.size() == 7 and int(scoped_glyphs[0].index) > 16 and int(scoped_glyphs[1].index) <= 16 and int(scoped_glyphs[3].index) <= 16 and int(scoped_glyphs[5].index) <= 16, "The UI did not keep numbers in its base font while routing type symbols through the Noto subset.")
	_expect(main.boosters_by_id.size() == 2, "Season shell did not load booster definitions.")
	_expect(main.tournaments_by_id.size() == 5, "Season shell did not load the tournament calendar.")
	_expect(String(main.tournaments_by_id.monthly_regionals.get("name", "")) == "League Cup" and bool(main.tournaments_by_id.monthly_regionals.get("demoEndpoint", false)), "League Cup is not marked as the demo endpoint.")
	_expect(main.current_screen == "start", "Season shell did not open on the season/debug menu.")
	_expect(main.find_child("ContinueRunButton", true, false) != null, "The title screen did not offer Continue.")
	_expect(main.find_child("OpenDebugMenuButton", true, false) != null, "The title screen did not preserve the direct Debug Menu link.")
	var new_game := main.find_child("NewGameButton", true, false) as Button
	_expect(new_game != null, "The title screen did not offer New Run.")
	if new_game != null:
		new_game.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "season_setup" and main.DEMO_STARTER_ORDER == ["spicy", "hearty", "sweet"], "New Run did not open the three-starter frame selection.")
	main._show_start()
	await process_frame
	var start_tutorial := main.find_child("StartTutorialButton", true, false) as Button
	_expect(start_tutorial != null, "The opening screen did not offer the Tutorial.")
	if start_tutorial != null:
		start_tutorial.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "tutorial", "The opening Tutorial action did not open the walkthrough.")
	_expect(main.find_child("TutorialProgress", true, false) != null, "The Tutorial did not render its step progress.")
	for step_number in range(1, main.tutorial_screen.STEPS.size()):
		var next_tutorial_step := main.find_child("TutorialNextButton", true, false) as Button
		_expect(next_tutorial_step != null, "The Tutorial lost its Next action before the final step.")
		if next_tutorial_step != null:
			next_tutorial_step.emit_signal("pressed")
		await process_frame
		await process_frame
	_expect(int(main.tutorial_screen.step_index) == main.tutorial_screen.STEPS.size() - 1, "The Tutorial did not advance through all basic-mechanics steps.")
	_expect(main.find_child("TutorialFinishButton", true, false) != null, "The Tutorial did not offer a Finish action on its final step.")
	main._show_start()
	await process_frame

	main._start_new_run_with_mode("spicy", "debug", "white")
	await process_frame
	_expect(main.current_screen == "shop", "Debug run did not open the shop.")
	_expect(main._deck_total(main.run.deck) == 30, "Kitchen starter deck is not 30 cards.")
	_expect(main.run.shop.size() == 8, "Shop did not generate eight singles.")

	var collection_before: int = main._deck_total(main.run.collection)
	var pack: Array = main._generate_pack("base_standard_pack")
	_expect(pack.size() == 6, "Base booster did not generate six cards.")
	main._start_pack(pack)
	main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
	_expect(main._deck_total(main.run.collection) == collection_before + 6, "Revealed booster cards did not enter the collection.")

	main._show_deckbuilder()
	await process_frame
	_expect(main.current_screen == "deck", "Deckbuilder did not open.")
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) != null and main.find_child("DeckbuilderAddSideButton", true, false) != null, "Debug Deckbuilder did not retain the sideboard controls.")
	main._show_meta()
	await process_frame
	_expect(main.current_screen == "meta", "Metagame screen did not open.")
	main._show_card_effect_lab()
	await process_frame
	_expect(main.current_screen == "card_lab", "Card Effect Lab did not open from the Debug Sandbox.")
	_expect(main.find_child("CardEffectLabScenarioPicker", true, false) != null, "Card Effect Lab did not render its scenario picker.")
	var run_selected := main.find_child("CardEffectLabRunSelected", true, false) as Button
	_expect(run_selected != null, "Card Effect Lab did not render its selected-test action.")
	if run_selected != null:
		run_selected.emit_signal("pressed")
		await process_frame
		await process_frame
		_expect(main.find_child("CardEffectLabResult", true, false) != null and bool(main.card_effect_lab.last_result.get("passed", false)), "Card Effect Lab did not render a passing selected-card result.")
	var lab_results: Array[Dictionary] = main.card_effect_lab.run_all_scenarios()
	var lab_passes := 0
	for lab_result in lab_results:
		if bool(lab_result.get("passed", false)):
			lab_passes += 1
	_expect(lab_results.size() == 19 and lab_passes == 19, "Card Effect Lab did not pass all 19 production scenarios.")

	main._start_debug_kitchen_match()
	await process_frame
	await process_frame
	_expect(main.current_screen == "kitchen_match", "Debug menu did not launch Kitchen Table TCG.")
	_expect(main.find_child("KitchenGameRoot", true, false) != null, "Kitchen match board did not render inside the season shell.")
	main._on_kitchen_match_finished({
		"winner": "player",
		"turn": 4,
		"player_life": 12,
		"opponent_life": 0
	})
	main._on_kitchen_exit_requested()
	await process_frame
	_expect(main.current_screen == "shop", "Debug Kitchen Match did not return to the shell.")
	main._start_debug_3d_arena()
	await process_frame
	await process_frame
	var arena_game = main.find_child("KitchenGame3D", true, false)
	_expect(main.current_screen == "kitchen_match" and arena_game != null and bool(arena_game.use_authored_arena), "The Debug Sandbox did not launch the isolated 3D Arena tab.")
	_expect(main.find_child("PlayerPrepZone", true, false) != null, "The 3D Arena tab did not populate its authored board nodes.")
	main._on_kitchen_exit_requested()
	await process_frame
	_expect(main.current_screen == "shop", "The 3D Arena tab did not return safely to the debug shell.")
	main._show_greybox_camera_demo()
	await process_frame
	await process_frame
	var camera_demo = main.find_child("GreyboxCameraDemo", true, false)
	_expect(main.current_screen == "camera_demo" and camera_demo != null, "The Debug Sandbox did not launch the graybox camera demonstration.")
	if camera_demo != null:
		camera_demo._show_menu()
		_expect(camera_demo.camera_tween != null and camera_demo.camera_tween.is_valid(), "The graybox menu shot did not begin its camera transition.")
		camera_demo.exit_requested.emit()
	await process_frame
	_expect(main.current_screen == "shop", "The graybox camera demonstration did not return safely to the debug shell.")

	main._start_new_run_with_mode("hearty", "season", "white")
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "Season run did not open the 3D card store.")
	_expect(not main.footer_label.visible and main.footer_label.custom_minimum_size.y == 0, "The 3D card store still reserved space for the instruction footer.")
	var shop_overworld = main.find_child("CardShopOverworld", true, false)
	_expect(shop_overworld != null, "The 3D card-store overworld did not render.")
	var shop_environment := main.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_expect(shop_environment != null and shop_environment.environment.background_color.is_equal_approx(Color("#b0cece")), "The card-store diorama void is not using #b0cece.")
	var shop_floor := main.find_child("Floor", true, false) as MeshInstance3D
	var shop_floor_material := shop_floor.mesh.material as StandardMaterial3D if shop_floor != null and shop_floor.mesh != null else null
	_expect(shop_floor_material != null and shop_floor_material.albedo_texture != null and shop_floor_material.albedo_texture.resource_path.ends_with("grey_low_poly_carpet.png"), "The card-store floor is not using the grey low-poly carpet texture.")
	_expect(shop_floor_material != null and int(shop_floor_material.texture_repeat) == 1 and shop_floor_material.uv1_scale.x > 1.0 and shop_floor_material.uv1_scale.y > 1.0, "The carpet texture is not configured to tile across the floor.")
	var shopkeeper_model := main.find_child("ShopkeeperModel", true, false)
	var shopkeeper_animation := shopkeeper_model.find_child("AnimationPlayer", true, false) as AnimationPlayer if shopkeeper_model != null else null
	_expect(shopkeeper_animation != null and shopkeeper_animation.is_playing(), "Clerk 1 did not begin her idle animation when the card store loaded.")
	if shopkeeper_animation != null:
		var active_idle := shopkeeper_animation.get_animation(shopkeeper_animation.current_animation)
		_expect(active_idle != null and active_idle.loop_mode == Animation.LOOP_LINEAR, "Clerk 1's idle animation is not configured to loop.")
	var shopkeeper_hotspot := main.find_child("ShopkeeperHotspot", true, false) as Button
	_expect(shopkeeper_hotspot != null and shopkeeper_hotspot.text == "" and shopkeeper_hotspot.flat and shopkeeper_hotspot.modulate.a == 0.0, "Clerk 1 does not have an invisible direct-click target.")
	_expect(main.find_child("ShotButtons", true, false) == null and main.find_child("TradingHotspot", true, false) == null and main.find_child("MetaHotspot", true, false) == null and main.find_child("DeckHotspot", true, false) == null, "The old store navigation buttons are still present.")
	var cash_hud := main.find_child("ShopHudCashButton", true, false) as Button
	var deck_hud := main.find_child("ShopHudDeckButton", true, false) as Button
	var save_hud := main.find_child("ShopHudSaveButton", true, false) as Button
	var settings_hud := main.find_child("ShopHudSettingsButton", true, false) as Button
	_expect(cash_hud != null and cash_hud.text == "$%d" % int(main.run.money), "The store HUD does not display the player's current cash.")
	_expect(deck_hud != null and deck_hud.icon != null and save_hud != null and save_hud.icon != null and settings_hud != null and settings_hud.icon != null, "The Deck Edit, Save, or Settings icon is missing from the store HUD.")
	var hud_background := cash_hud.get_theme_stylebox("normal") as StyleBoxFlat if cash_hud != null else null
	_expect(hud_background != null and hud_background.bg_color.r == 1.0 and hud_background.bg_color.a > 0.0 and hud_background.bg_color.a < 1.0, "The top-right HUD does not use a translucent white background.")
	var shopkeeper_meta_button := main.find_child("Meta", true, false) as Button
	_expect(main.find_child("Trade", true, false) == null and main.find_child("Deck", true, false) == null and main.find_child("Settings", true, false) == null, "The redundant Trade, Deck, or Settings option is still in the shopkeeper menu.")
	_expect(shopkeeper_meta_button != null, "The shopkeeper menu is missing Meta Analysis.")
	if shopkeeper_hotspot != null:
		shopkeeper_hotspot.emit_signal("pressed")
	await create_timer(0.8).timeout
	_expect(shop_overworld != null and shop_overworld.menu_panel.visible, "Clicking Clerk 1 did not open her menu.")
	_expect(shop_overworld != null and shop_overworld.camera_rig.global_position.y > 3.3, "The shopkeeper camera was not raised for Clerk 1's current position.")
	var shopkeeper_singles_button := main.find_child("BuySingles", true, false) as Button
	if shopkeeper_singles_button != null:
		shopkeeper_singles_button.emit_signal("pressed")
	var in_scene_case = main.find_child("InSceneSinglesCase", true, false)
	var in_scene_grid = main.find_child("InSceneSinglesGrid", true, false)
	_expect(in_scene_case != null and in_scene_case.visible, "The shopkeeper did not open the singles case inside the 3D store.")
	_expect(in_scene_grid != null and in_scene_grid.get_child_count() == 8, "The in-scene singles case did not render all eight live cards.")
	var singles_back := main.find_child("InSceneSinglesCaseBack", true, false) as Button
	if singles_back != null:
		singles_back.emit_signal("pressed")
	await process_frame
	_expect(shop_overworld != null and shop_overworld.menu_panel.visible and shop_overworld.menu_panel.modulate.a < 1.0 and shop_overworld.shot_label.text != "MOVING CAMERA...", "Back to Shopkeeper did not begin its camera-free crossfade.")
	await create_timer(0.22).timeout
	_expect(shop_overworld != null and is_equal_approx(shop_overworld.menu_panel.modulate.a, 1.0) and not in_scene_case.visible, "Back to Shopkeeper did not finish its menu crossfade cleanly.")
	if shopkeeper_singles_button != null:
		shopkeeper_singles_button.emit_signal("pressed")
	var affordable_card_id := ""
	var affordable_price := 999
	for shop_card_id_value in main.run.shop:
		var shop_card_id := String(shop_card_id_value)
		var shop_price: int = main._card_price(shop_card_id)
		if shop_price < affordable_price:
			affordable_card_id = shop_card_id
			affordable_price = shop_price
	var money_before_single := int(main.run.money)
	var owned_before_single: int = main._owned_count(affordable_card_id)
	var shop_before_single: Array = main.run.shop.duplicate()
	main._buy_single_from_overworld(affordable_card_id)
	await process_frame
	_expect(main.current_screen == "shop" and main.find_child("CardShopOverworld", true, false) == shop_overworld, "Buying a single navigated away from the 3D store.")
	_expect(int(main.run.money) == money_before_single - affordable_price and main._owned_count(affordable_card_id) == owned_before_single + 1, "The in-scene single purchase did not update money and ownership.")
	_expect(main.run.shop.size() == shop_before_single.size() - 1 and not main.run.shop.has(affordable_card_id), "Buying a single did not remove only the sold card from the case.")
	var expected_remaining_shop := shop_before_single.duplicate()
	expected_remaining_shop.erase(affordable_card_id)
	_expect(main.run.shop == expected_remaining_shop, "Buying a single rerolled the remaining shop inventory.")
	main.run.collection[affordable_card_id] = main._owned_count(affordable_card_id) + 4
	shop_overworld.update_shop_context(main._shop_overworld_context())
	var trade_context: Dictionary = main._shop_overworld_context()
	var expected_trade_value := 0
	for trade_entry_value in trade_context.get("trade_entries", []):
		expected_trade_value += int((trade_entry_value as Dictionary).get("total_value", 0))
	var money_before_trade := int(main.run.money)
	if cash_hud != null:
		cash_hud.emit_signal("pressed")
	await process_frame
	_expect(main.current_screen == "shop" and main.find_child("CardShopOverworld", true, false) == shop_overworld, "Trading extra copies navigated away from the 3D store.")
	_expect(expected_trade_value > 0 and int(main.run.money) == money_before_trade + expected_trade_value, "The cash HUD did not pay the displayed extra-copy value.")
	_expect(cash_hud != null and cash_hud.text == "$%d" % int(main.run.money), "Selling from the cash HUD did not refresh the displayed balance.")
	if shopkeeper_meta_button != null:
		shopkeeper_meta_button.emit_signal("pressed")
	var in_scene_meta = main.find_child("InSceneMetaAnalysis", true, false)
	var in_scene_meta_entries = main.find_child("InSceneMetaEntries", true, false)
	var in_scene_meta_reports = main.find_child("InSceneMetaReports", true, false)
	_expect(in_scene_meta != null and in_scene_meta.visible and main.find_child("CardShopOverworld", true, false) == shop_overworld, "Meta Analysis did not open inside the existing 3D store.")
	_expect(in_scene_meta_entries != null and in_scene_meta_entries.get_child_count() == 5, "The in-scene Meta Analysis did not render all five archetype shares.")
	_expect(in_scene_meta_reports != null and in_scene_meta_reports.get_child_count() == main.run.reports.size(), "The in-scene Meta Analysis did not render the current shop reports.")
	main._show_deckbuilder()
	await process_frame
	await process_frame
	_expect(main.find_child("DeckbuilderWorkspace", true, false) != null and main.find_child("DeckbuilderCollectionScroll", true, false) != null, "Season Deck Edit did not build its one-screen collection workspace.")
	_expect(main.find_child("DeckbuilderMainDeckScroll", true, false) != null, "Season Deck Edit did not keep the main deck in an internal scroller.")
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) == null and main.find_child("DeckbuilderAddSideButton", true, false) == null, "Season Deck Edit still exposed sideboard controls.")
	_expect("Side" not in main.status_label.text, "The Season status HUD still displayed a sideboard count.")
	_expect(main.scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Season Deck Edit still allows the outer screen to scroll.")
	main._show_shop()
	await process_frame
	await process_frame
	_expect(main._season_calendar_ids().size() == 2, "The demo calendar does not contain exactly two events.")
	_expect(main._selected_season_event_id() == "weekly_locals", "Weekly Locals was not the opening event.")
	var locals_event: Dictionary = main._season_event_by_id("weekly_locals")
	var cup_event: Dictionary = main._season_event_by_id("monthly_regionals")
	_expect(int(locals_event.get("rounds", 0)) == 3 and int(locals_event.get("requiredWins", 0)) == 3, "Weekly Locals is not a sudden-death three-round event.")
	_expect(int(cup_event.get("rounds", 0)) == 3 and int(cup_event.get("requiredWins", 0)) == 3, "The League Cup is not a sudden-death three-round event.")
	_expect(main.tournament_service.ai_difficulty_for_round(main, locals_event, 1) == "easy", "The opening Locals round is not using Easy AI.")
	_expect(main.tournament_service.ai_difficulty_for_round(main, locals_event, 2) == "medium", "Later Locals rounds do not advance to Medium AI.")
	_expect(main.tournament_service.ai_difficulty_for_round(main, cup_event, 1) == "medium" and main.tournament_service.ai_difficulty_for_round(main, cup_event, 3) == "hard", "The League Cup does not ramp from Medium to Hard AI.")

	main._start_season_tournament()
	await process_frame
	await process_frame
	var shop_before_completed_round: Array = main.run.shop.duplicate()
	_expect(main.current_screen == "kitchen_match", "Tournament round did not launch a Kitchen Match.")
	_expect(main._season_tournament_active(), "Tournament state was not created.")
	var opening_kitchen_game = main.find_child("KitchenGame3D", true, false)
	_expect(opening_kitchen_game != null and bool(opening_kitchen_game.use_authored_arena), "The opening Locals match did not use the authored 3D combat view.")
	_expect(opening_kitchen_game != null and String(opening_kitchen_game.state.get("ai_difficulty", "")) == "easy", "The opening Locals match did not receive its Easy AI tier.")

	main._on_kitchen_match_finished({"winner": "opponent", "turn": 5, "player_life": 0, "opponent_life": 8})
	await process_frame
	await process_frame
	var loss_heading := main.find_child("SeasonRoundResultHeading", true, false) as Label
	var loss_action := main.find_child("SeasonRoundResultAction", true, false) as Button
	_expect(loss_heading != null and loss_heading.text == "YOU LOST", "The loss popup did not display its loss message.")
	_expect(loss_action != null and loss_action.text == "View Game Over", "The loss popup did not end the sudden-death run.")
	if loss_action != null:
		loss_action.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.run.shop.size() == 8 and main.run.shop != shop_before_completed_round, "Completing a tournament round did not restock the singles case.")
	_expect(bool(main.run.get("run_over", false)) and main.current_screen == "result", "One tournament loss did not end the demo on the Game Over screen.")

	main._start_new_run_with_mode("hearty", "season", "white")
	await process_frame
	main._start_season_tournament()
	await process_frame
	await process_frame
	for round_number in [1, 2, 3]:
		main._on_kitchen_match_finished({"winner": "player", "turn": 5 + round_number, "player_life": 10, "opponent_life": 0})
		await process_frame
		await process_frame
		var continue_action := main.find_child("SeasonRoundResultAction", true, false) as Button
		_expect(continue_action != null, "A later win did not open its round result popup.")
		var shop_action := main.find_child("SeasonRoundResultShopAction", true, false) as Button
		if round_number < 3:
			_expect(continue_action != null and continue_action.text == "Next Round" and shop_action != null and shop_action.text == "Back to Shop", "A non-final win did not offer both next-round and shop choices.")
		if round_number == 3:
			_expect(continue_action != null and continue_action.text == "View Results" and shop_action == null, "The final-round win popup did not offer only the results action.")
		if round_number == 1 and shop_action != null:
			shop_action.emit_signal("pressed")
			await process_frame
			await process_frame
			_expect(main.current_screen == "shop" and main._season_tournament_active() and int(main.run.active_tournament.round) == 2 and main.run.get("kitchen_match_result", {}).is_empty(), "Returning to the shop did not pause the active tournament before round 2.")
			_expect(main.run.shop.size() == 8, "Returning between rounds did not expose the freshly restocked singles case.")
			shop_overworld = main.find_child("CardShopOverworld", true, false)
			var between_round_shopkeeper := main.find_child("ShopkeeperHotspot", true, false) as Button
			if between_round_shopkeeper != null:
				between_round_shopkeeper.emit_signal("pressed")
			await create_timer(0.8).timeout
			var clerk_next_round := main.find_child("Tournament", true, false) as Button
			_expect(clerk_next_round != null and clerk_next_round.text == "Start Tournament Round 2", "The clerk did not offer the pending next round.")
			if clerk_next_round != null:
				clerk_next_round.emit_signal("pressed")
			await process_frame
			await process_frame
			_expect(main.current_screen == "kitchen_match" and int(main.run.active_tournament.round) == 2, "The clerk did not launch the pending tournament round.")
		elif continue_action != null:
			continue_action.emit_signal("pressed")
		await process_frame
		await process_frame

	_expect(main._season_event_completed("weekly_locals"), "A 3-0 Locals result did not advance the calendar.")
	_expect(main._season_event_unlocked("monthly_regionals"), "Monthly Regionals did not unlock.")
	_expect(not main._season_tournament_active(), "Completed tournament remained active.")
	_expect(main.current_screen == "result", "Completed tournament did not show its result screen.")

	main._open_reward_pack_flow()
	await process_frame
	main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
	main._finish_pack_opening()
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop" and main._selected_season_event_id() == "monthly_regionals", "The Locals prize pack did not return to the store for the League Cup.")

	main._start_season_tournament()
	await process_frame
	await process_frame
	for cup_round in [1, 2, 3]:
		main._on_kitchen_match_finished({"winner": "player", "turn": 7 + cup_round, "player_life": 8, "opponent_life": 0})
		await process_frame
		await process_frame
		var cup_continue := main.find_child("SeasonRoundResultAction", true, false) as Button
		_expect(cup_continue != null, "A League Cup win did not open its round result action.")
		if cup_continue != null:
			cup_continue.emit_signal("pressed")
		await process_frame
		await process_frame
	_expect(bool(main.run.get("demo_complete", false)) and main.current_screen == "result", "A 3-0 League Cup did not open the demo win screen.")

	for prize_index in range(2):
		main._open_reward_pack_flow()
		await process_frame
		main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
		main._finish_pack_opening()
		await process_frame
		await process_frame
	_expect(main.current_screen == "thanks" and main.find_child("ThanksMainMenuButton", true, false) != null, "Opening the League Cup prizes did not reach Thanks for Playing.")

	main.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("Kitchen season shell smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
