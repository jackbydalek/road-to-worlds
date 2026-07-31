extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.cards_by_id.size() == 58, "Season shell did not load all 58 kitchen cards.")
	_expect(String(main._difficulty_data("white").get("name", "")) == "Black" and String(main._difficulty_data("white").get("border_color", "")) == "#090909", "The standard difficulty did not display the new Black border.")
	_expect(main.archetypes_by_id.size() == 3, "Season shell did not build the three starter archetypes.")
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
	_expect(main.current_screen == "start", "Season shell did not open on the boot landing.")
	_expect(main.find_child("GameStartButton", true, false) != null, "The boot landing did not offer Game Start.")
	_expect(main.find_child("OpenDebugMenuButton", true, false) != null, "The title screen did not preserve the direct Debug Menu link.")
	main._show_game_start()
	await process_frame
	_expect(main.find_child("ContinueRunButton", true, false) != null, "Game Start did not offer Continue.")
	var new_game := main.find_child("NewGameButton", true, false) as Button
	_expect(new_game != null, "Game Start did not offer New Game.")
	if new_game != null:
		new_game.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "season_setup" and main.DEMO_STARTER_ORDER == ["spicy", "hearty", "sweet", "draft_night"], "New Game did not open the starter / Draft Night wheel.")
	main._show_start()
	await process_frame
	var start_tutorial := main.find_child("StartTutorialButton", true, false) as Button
	_expect(start_tutorial != null, "The opening screen did not offer the Tutorial.")
	if start_tutorial != null:
		start_tutorial.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "tutorial", "The opening Tutorial action did not open the walkthrough.")
	var guided_tutorial := main.find_child("Tabletop3DPrototype", true, false)
	_expect(guided_tutorial != null and bool(guided_tutorial.tutorial_mode), "The title-screen Tutorial did not open its standalone guided practice table.")
	_expect(main.find_child("GuidedTutorialPanel", true, false) != null, "The guided Tutorial did not render its written lesson panel.")
	_expect(main.run.is_empty(), "Opening How to Play unexpectedly created or entered a Season Run.")
	main._show_start()
	await process_frame

	main._start_new_run_with_mode("spicy", "debug", "white")
	await process_frame
	_expect(main.current_screen == "shop", "Debug run did not open the shop.")
	_expect(main._deck_total(main.run.deck) == main.MAIN_DECK_SIZE, "Kitchen starter deck is not 20 cards.")
	_expect(main.run.shop.size() == 8, "Shop did not generate eight singles.")

	var collection_before: int = main._deck_total(main.run.collection)
	var sealed_pack: Array = main._generate_pack("base_standard_pack")
	main._start_pack(sealed_pack)
	main._show_packs()
	await process_frame
	await process_frame
	var pack_scroll := main.scroll as ScrollContainer
	_expect(pack_scroll != null and not pack_scroll.get_v_scroll_bar().visible and not pack_scroll.get_h_scroll_bar().visible, "The pack-opening table did not fit in the standard viewport without scrolling.")
	var sealed_exit := main.find_child("PackExitToStoreButton", true, false) as Button
	_expect(sealed_exit != null, "The pack table did not render its return-to-store button.")
	if sealed_exit != null:
		sealed_exit.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "Returning from an unopened pack did not reach the shop.")
	_expect(not bool(main.run.get("pack_opened", false)) and main.run.get("current_pack", []) == sealed_pack, "Returning from an unopened pack changed or opened the sealed pack.")
	_expect(main._deck_total(main.run.collection) == collection_before, "Returning from an unopened pack added cards to the collection.")

	main._show_packs()
	await process_frame
	await process_frame
	var sealed_pack_button := main.find_child("PackButton", true, false) as Button
	_expect(sealed_pack_button != null, "The preserved sealed pack was not available when the pack table reopened.")
	_expect(sealed_pack_button != null and sealed_pack_button.text == "I haven't made the pack art yet", "The pack table did not render the unfinished-art placeholder.")
	if sealed_pack_button != null:
		_click_control(sealed_pack_button)
	await process_frame
	await process_frame
	_expect(bool(main.run.get("pack_opened", false)), "Clicking the preserved sealed pack did not open its wrapper.")
	var first_pack_card := main.find_child("PackCardSlot0", true, false) as TextureButton
	_expect(first_pack_card != null and first_pack_card.visible and first_pack_card.size == Vector2(210, 295), "Opened pack cards did not use the enlarged card size.")
	var first_pack_card_back := main.find_child("PackCardBack0", true, false) as TextureRect
	_expect(first_pack_card_back != null and first_pack_card_back.texture != null and first_pack_card_back.texture.resource_path == "res://assets/cards/card_backs/living_table.png", "The pack-opening table did not use the Living Table card back for face-down cards.")
	var pack_frame := main.find_child("PackOpeningSceneFrame", true, false) as Control
	var pack_canvas := main.find_child("PackOpeningSceneHost", true, false) as Control
	var pack_card_fan := main.find_child("CardFan", true, false) as Control
	var pack_done_button := main.find_child("DoneButton", true, false) as Button
	var pack_reveal_all_button := main.find_child("RevealAllButton", true, false) as Button
	if pack_frame != null and pack_canvas != null and pack_card_fan != null:
		var authored_fan_midpoint: float = pack_card_fan.position.x + float(main.pack_opening_screen.FAN_CENTER_X) + float(main.pack_opening_screen.CARD_SLOT_SIZE.x) * 0.5
		_expect(absf(authored_fan_midpoint - pack_canvas.size.x * 0.5) <= 1.0, "The opened card fan was not centered in the pack table.")
		_expect(absf(pack_frame.get_global_rect().get_center().x - pack_scroll.get_global_rect().get_center().x) <= 1.0, "The pack table was not centered in the available viewport.")
	_expect(pack_done_button != null and pack_reveal_all_button != null and pack_done_button.position == pack_reveal_all_button.position and pack_done_button.size == pack_reveal_all_button.size, "Done and Reveal All did not share the same pack-table action slot.")
	var opened_exit := main.find_child("PackExitToStoreButton", true, false) as Button
	if opened_exit != null:
		opened_exit.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "Returning from an opened pack did not reach the shop.")
	_expect(main.run.get("current_pack", []).is_empty() and main.run.get("revealed_pack", []).is_empty() and not bool(main.run.get("pack_opened", false)), "Returning from an opened pack did not clear the completed pack state.")
	_expect(main._deck_total(main.run.collection) == collection_before + sealed_pack.size(), "Returning from an opened pack did not safely collect every card before clearing it.")

	collection_before = main._deck_total(main.run.collection)
	var pack: Array = main._generate_pack("base_standard_pack")
	_expect(pack.size() == 5, "Base booster did not generate five cards.")
	main._start_pack(pack)
	main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
	_expect(main._deck_total(main.run.collection) == collection_before + 5, "Revealed booster cards did not enter the collection.")

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
	_expect(main.find_child("Tabletop3DPrototype", true, false) != null and main.find_child("KitchenGameRoot", true, false) == null, "The default debug match did not retire the classic renderer in favor of Living Table.")
	_expect(String(main.run.get("kitchen_match", {}).get("presentation", "")) == "living_table", "The default debug match did not persist the Living Table presentation.")
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
	var tabletop_prototype = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "kitchen_match" and tabletop_prototype != null, "The Debug Sandbox did not launch the production Living Table match.")
	if tabletop_prototype != null:
		_expect(bool(tabletop_prototype.production_match) and tabletop_prototype.configured_player_deck == main.run.deck, "The Living Table practice match did not receive the selected run deck.")
		_expect(_deck_total(tabletop_prototype.configured_opponent_deck) == main.MAIN_DECK_SIZE and String(tabletop_prototype.configured_ai_difficulty) == "easy", "The Living Table practice match did not receive its generated opponent deck and AI tier.")
		_expect(not bool(tabletop_prototype.configured_match_context.get("tournament_round", true)) and String(tabletop_prototype.configured_match_context.get("event_name", "")) == "Practice Match", "The Living Table practice match received incorrect production context.")
		var player_hand_card := tabletop_prototype.find_child("PlayerHandCard_0", true, false) as Node3D
		var opponent_hand_card := tabletop_prototype.find_child("OpponentHandCard_0", true, false) as Node3D
		var full_card_face := tabletop_prototype.find_child("PrototypeFullCardFace_*", true, false) as Control
		_expect(player_hand_card != null and opponent_hand_card != null and full_card_face != null and tabletop_prototype.art_frames.size() > 1, "The Living Table prototype did not build upright player cards, opponent card backs, and animated art support.")
		_expect(player_hand_card != null and player_hand_card.rotation_degrees.x > 55.0 and opponent_hand_card != null and opponent_hand_card.rotation_degrees.x > 60.0, "The Living Table hands were not held upright toward the camera.")
		_expect(opponent_hand_card != null and opponent_hand_card.position.z < -5.0, "The rival hand was not moved behind its Prep bench.")
		_expect(tabletop_prototype.find_children("Slot*", "MeshInstance3D", true, false).size() >= 10, "The Living Table did not build separate physical boxes for its three Prep and two Plated slots on both sides.")
		for auxiliary_zone in ["PlayerDeckZone", "PlayerDiscardZone", "PlayerEnvironmentZone", "OpponentDeckZone", "OpponentDiscardZone", "OpponentEnvironmentZone"]:
			_expect(tabletop_prototype.find_child(auxiliary_zone, true, false) != null, "The Living Table did not build its %s physical zone." % auxiliary_zone)
		for removed_zone in ["PlayerChefZone", "PlayerToolZone", "OpponentChefZone", "OpponentToolZone"]:
			_expect(tabletop_prototype.find_child(removed_zone, true, false) == null, "The obsolete %s physical zone was still present." % removed_zone)
		var player_environment_zone := tabletop_prototype.find_child("PlayerEnvironmentZone", true, false) as Node3D
		var player_deck_zone := tabletop_prototype.find_child("PlayerDeckZone", true, false) as Node3D
		var player_discard_zone := tabletop_prototype.find_child("PlayerDiscardZone", true, false) as Node3D
		var opponent_deck_zone := tabletop_prototype.find_child("OpponentDeckZone", true, false) as Node3D
		var opponent_discard_zone := tabletop_prototype.find_child("OpponentDiscardZone", true, false) as Node3D
		_expect(player_environment_zone != null and player_environment_zone.position.x < -4.5, "The player Environment was not moved to the upper-left edge of their field.")
		_expect(player_deck_zone != null and player_discard_zone != null and player_deck_zone.position.x > 4.5 and player_discard_zone.position.x > 4.5, "The player deck and discard were not aligned with the field's right edge.")
		_expect(opponent_deck_zone != null and opponent_discard_zone != null and opponent_deck_zone.position.x < -4.5 and opponent_discard_zone.position.x < -4.5, "The rival deck and discard were not aligned with the field's left edge.")
		_expect(tabletop_prototype.player_chef.position.x < -4.5 and tabletop_prototype.player_chef.position.z > 3.0, "The player life counter was not moved to the bottom-left corner.")
		_expect(tabletop_prototype.opponent_chef.position.x > 4.5 and tabletop_prototype.opponent_chef.position.z < -4.0, "The rival life counter was not moved to the top-right corner.")
		_expect(tabletop_prototype.find_children("PlayerDeckCard_*", "Node3D", true, false).size() > 0 and tabletop_prototype.find_children("OpponentDeckCard_*", "Node3D", true, false).size() > 0, "The Living Table did not render both physical deck stacks.")
		var battle_log_button := tabletop_prototype.find_child("BattleLogButton", true, false) as Button
		var battle_log_panel := tabletop_prototype.find_child("BattleLogPanel", true, false) as PanelContainer
		var battle_log_text := tabletop_prototype.find_child("LogText", true, false) as RichTextLabel
		_expect(battle_log_button != null and battle_log_panel != null and not battle_log_panel.visible and battle_log_text != null and "cook-off begins" in battle_log_text.text, "The Living Table battle log was not populated and hidden by default.")
		if battle_log_button != null:
			battle_log_button.emit_signal("pressed")
		_expect(battle_log_panel != null and battle_log_panel.visible, "The side Battle Log button did not open its drawer.")
		var battle_log_close := tabletop_prototype.find_child("CloseButton", true, false) as Button
		if battle_log_close != null:
			battle_log_close.emit_signal("pressed")
		_expect(battle_log_panel != null and not battle_log_panel.visible, "The Battle Log drawer did not close.")
		var middle_end_turn := tabletop_prototype.find_child("EndTurnButton", true, false) as Button
		_expect(middle_end_turn != null and middle_end_turn.get_parent().name == "Interface" and is_equal_approx(middle_end_turn.anchor_top, 0.5), "End Turn was not moved to the middle-right table control.")
		if player_hand_card != null:
			tabletop_prototype._handle_card_click(player_hand_card)
			_expect(tabletop_prototype.action_panel.visible and tabletop_prototype.find_child("LivingTableInfoCardFace", true, false) != null, "Clicking a Living Table card did not restore the full card-information window.")
			tabletop_prototype._close_info_window()
		tabletop_prototype.state.player.hand = ["spicy_hot_honey_bee"]
		tabletop_prototype.state.player.prep = []
		tabletop_prototype.state.player.plated = []
		tabletop_prototype.state.phase = "player_main"
		tabletop_prototype._render_match()
		var starting_hand_size: int = tabletop_prototype.state.player.hand.size()
		tabletop_prototype._play_hand_card(0, "prep", 2)
		await create_timer(1.2).timeout
		for unused_wait in range(30):
			if not bool(tabletop_prototype.animation_busy):
				break
			await create_timer(0.1).timeout
		_expect(tabletop_prototype.state.player.hand.size() == starting_hand_size - 1 and tabletop_prototype.state.player.prep.size() == 1, "The Living Table did not route a 3D hand play through the production combat rules.")
		var field_card := tabletop_prototype.find_child("PlayerPrepCard_*", true, false) as Node3D
		_expect(field_card != null and field_card.find_child("FloatingArt", true, false) != null, "A played Living Table card did not lay flat with looping artwork above it.")
		_expect(not tabletop_prototype.state.player.prep.is_empty() and int(tabletop_prototype.state.player.prep[0].table_slot) == 2 and field_card != null and field_card.position.x > 1.6, "A card played to the right Prep box was recentered instead of remaining in that exact slot.")
		tabletop_prototype.state.player.prep[0].spices = ["spice_cayenne_crunch"]
		tabletop_prototype.state.player.environment = "environment_blazing_wok"
		tabletop_prototype.state.player.discard = ["chef_mary", "item_wooden_spoon"]
		tabletop_prototype._render_match()
		var seasoned_card := tabletop_prototype.find_child("PlayerPrepCard_*", true, false) as Node3D
		_expect(seasoned_card != null and seasoned_card.find_child("SpiceAttachment_0", true, false) != null, "An attached Spice did not receive its own physical 3D card.")
		_expect(tabletop_prototype.find_child("PlayerEnvironmentCard", true, false) != null, "The active Environment did not appear in its 3D zone.")
		_expect(tabletop_prototype.find_child("PlayerDiscardTop", true, false) != null, "The discard pile did not show its face-up top card.")
		_expect(tabletop_prototype.find_child("PlayerChefActionCard", true, false) == null and tabletop_prototype.find_child("PlayerToolActionCard", true, false) == null, "Chef or Item cards still created dedicated action-bay objects instead of using the discard pile.")
		tabletop_prototype._open_discard_tray("player")
		var card_tray_overlay := tabletop_prototype.find_child("CardTrayOverlay", true, false) as Control
		var discard_tray_cards := tabletop_prototype.find_children("CardTrayCard_*", "Button", true, false)
		_expect(card_tray_overlay != null and card_tray_overlay.visible and discard_tray_cards.size() == 2, "Clicking the discard pile did not open both cards in the full-card tray.")
		_expect(discard_tray_cards.all(func(card_button) -> bool: return card_button.find_child("FullCardFace", true, false) != null), "The discard tray did not render full card faces.")
		tabletop_prototype._close_card_tray()
		_expect(card_tray_overlay != null and not card_tray_overlay.visible, "The discard card tray did not close.")
		tabletop_prototype.state.player.deck = ["spicy_hot_honey_bee", "item_wooden_spoon"]
		tabletop_prototype.state.pending_search = {"effect": {"card_type": "ingredient"}, "prompt": "Choose an Ingredient from your deck."}
		tabletop_prototype._render_match()
		var search_tray_cards := tabletop_prototype.find_children("CardTrayCard_*", "Button", true, false)
		_expect(card_tray_overlay != null and card_tray_overlay.visible and search_tray_cards.size() == 1 and not tabletop_prototype.prompt_panel.visible, "A deck search did not use the full-card tray in place of the old button prompt.")
		if not search_tray_cards.is_empty():
			(search_tray_cards[0] as Button).emit_signal("pressed")
		await process_frame
		_expect(tabletop_prototype.state.pending_search.is_empty() and tabletop_prototype.state.player.hand.has("spicy_hot_honey_bee") and not card_tray_overlay.visible, "Clicking a deck-search card did not add it to hand and close the tray.")
		for unused_wait in range(20):
			if not bool(tabletop_prototype.animation_busy):
				break
			await create_timer(0.05).timeout
		tabletop_prototype.state.player.hand = ["item_recipe_prep", "chef_mary", "spicy_hot_honey_bee", "item_wooden_spoon"]
		tabletop_prototype.state.pending_discard = {
			"hand_index": 0,
			"card_id": "item_recipe_prep",
			"required": 2,
			"selected_indices": []
		}
		tabletop_prototype.state.message = "Select 2 cards from your hand to discard for Recipe Prep."
		tabletop_prototype._render_match()
		var discard_confirm := tabletop_prototype.find_child("ConfirmChoiceButton", true, false) as Button
		var discard_cancel := tabletop_prototype.find_child("CancelChoiceButton", true, false) as Button
		_expect(not tabletop_prototype.prompt_panel.visible and discard_confirm != null and discard_confirm.visible and discard_confirm.disabled and discard_cancel != null and discard_cancel.visible, "Discard payment still opened the old card-name popup instead of using the physical hand.")
		var locked_item := tabletop_prototype.find_child("PlayerHandCard_0", true, false) as Node3D
		var first_discard := tabletop_prototype.find_child("PlayerHandCard_1", true, false) as Node3D
		if locked_item != null:
			tabletop_prototype._handle_card_click(locked_item)
		_expect(tabletop_prototype.state.pending_discard.get("selected_indices", []).is_empty(), "The Item paying the discard cost could select itself.")
		if first_discard != null:
			tabletop_prototype._handle_card_click(first_discard)
		var selected_hand_card := tabletop_prototype.find_child("PlayerHandCard_1", true, false) as Node3D
		var selected_hand_body := selected_hand_card.find_child("CardBody", true, false) as MeshInstance3D if selected_hand_card != null else null
		_expect(tabletop_prototype.state.pending_discard.get("selected_indices", []).has(1) and selected_hand_body != null and selected_hand_body.material_override is StandardMaterial3D and bool((selected_hand_body.material_override as StandardMaterial3D).emission_enabled), "Clicking a physical hand card did not select and highlight it for discard.")
		var second_discard := tabletop_prototype.find_child("PlayerHandCard_2", true, false) as Node3D
		if second_discard != null:
			tabletop_prototype._handle_card_click(second_discard)
		discard_confirm = tabletop_prototype.find_child("ConfirmChoiceButton", true, false) as Button
		_expect(discard_confirm != null and not discard_confirm.disabled and tabletop_prototype.status_label.text == "Select 2 cards from your hand to discard: 2/2 selected.", "The physical-hand discard controls did not enable Confirm after the exact cost was selected.")
		if discard_cancel != null:
			discard_cancel.emit_signal("pressed")
		await process_frame
		_expect(tabletop_prototype.state.pending_discard.is_empty() and tabletop_prototype.state.player.hand.size() == 4 and not discard_confirm.visible, "Cancelling hand-native discard payment did not preserve the hand and close its controls.")
		tabletop_prototype.state.player.turns_started = 2
		tabletop_prototype.state.player.meal_served = false
		tabletop_prototype.state.player.hand = ["spicy_sriracharrow"]
		tabletop_prototype.state.player.prep = []
		tabletop_prototype.state.player.plated = []
		var selected_recipe_ingredient: Dictionary
		for slot_index in range(tabletop_prototype.service.PREP_SLOTS):
			var ingredient_id := "spicy_hot_honey_bee" if slot_index == 2 else "spicy_red_pepper_panda"
			var prep_ingredient: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.player, tabletop_prototype.service.card(ingredient_id), "prep", "player")
			prep_ingredient.table_slot = slot_index
			prep_ingredient.recipe_ready_on_turn = 0
			tabletop_prototype.state.player.prep.append(prep_ingredient)
			if slot_index == 2:
				selected_recipe_ingredient = prep_ingredient
		for slot_index in range(tabletop_prototype.service.PLATED_SLOTS):
			var plated_ingredient: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.player, tabletop_prototype.service.card("spicy_jalapeno_panther"), "plated", "player")
			plated_ingredient.table_slot = slot_index
			plated_ingredient.recipe_ready_on_turn = 0
			tabletop_prototype.state.player.plated.append(plated_ingredient)
		tabletop_prototype.state.selected_ingredients = []
		tabletop_prototype.state.phase = "player_main"
		tabletop_prototype._render_match()
		var meal_data: Dictionary = tabletop_prototype.service.card("spicy_sriracharrow")
		_expect(not tabletop_prototype._slot_is_open("player", "prep", 2) and tabletop_prototype._slot_can_receive_hand_card(meal_data, "player", "prep", 2), "A recipe-ready Ingredient's occupied slot was not offered as a legal Meal destination.")
		tabletop_prototype._play_hand_card(0, "prep", 2)
		var meal_confirm := tabletop_prototype.find_child("ConfirmChoiceButton", true, false) as Button
		_expect(not tabletop_prototype.state.pending_meal.is_empty() and tabletop_prototype.state.player.hand == ["spicy_sriracharrow"] and not tabletop_prototype.prompt_panel.visible and meal_confirm != null and meal_confirm.visible and meal_confirm.disabled, "Attempting to serve a Meal did not pause on the table for physical Ingredient selection.")
		var recipe_ingredient_card: Node3D
		for candidate_card in tabletop_prototype.interactive_cards:
			if int(candidate_card.get_meta("instance_id", -1)) == int(selected_recipe_ingredient.instance_id):
				recipe_ingredient_card = candidate_card
				break
		if recipe_ingredient_card != null:
			tabletop_prototype._handle_card_click(recipe_ingredient_card)
		meal_confirm = tabletop_prototype.find_child("ConfirmChoiceButton", true, false) as Button
		_expect(tabletop_prototype.state.selected_ingredients == [int(selected_recipe_ingredient.instance_id)] and meal_confirm != null and not meal_confirm.disabled, "Clicking the highlighted physical Ingredient did not satisfy and enable the Meal recipe.")
		if meal_confirm != null:
			meal_confirm.emit_signal("pressed")
		for unused_wait in range(30):
			if not bool(tabletop_prototype.animation_busy):
				break
			await create_timer(0.05).timeout
		var replacement_meal: Dictionary
		for unit in tabletop_prototype.state.player.prep:
			if String(unit.get("card_id", "")) == "spicy_sriracharrow":
				replacement_meal = unit
				break
		_expect(tabletop_prototype.state.player.prep.size() == tabletop_prototype.service.PREP_SLOTS and tabletop_prototype.state.player.plated.size() == tabletop_prototype.service.PLATED_SLOTS and not replacement_meal.is_empty() and int(replacement_meal.get("table_slot", -1)) == 2, "Serving a Meal on a full Living Table did not replace the sacrificed Ingredient in its exact slot.")
		tabletop_prototype.state.player.hand = ["spicy_hot_honey_bee"]
		tabletop_prototype.state.player.prep = []
		tabletop_prototype.state.player.plated = []
		tabletop_prototype.state.player.environment = ""
		tabletop_prototype.state.player.discard = []
		tabletop_prototype.state.opponent.life = 20
		tabletop_prototype._render_match()
		tabletop_prototype._play_hand_card(0, "prep", 2)
		await create_timer(0.08).timeout
		var arriving_bee := tabletop_prototype.find_child("PlayerPrepCard_*", true, false) as Node3D
		_expect(bool(tabletop_prototype.animation_busy) and arriving_bee != null and tabletop_prototype.effect_layer.get_child_count() > 0 and int(tabletop_prototype.state.opponent.life) == 19, "Hot Honey Bee animation state was busy=%s card=%s effects=%d rival_life=%d." % [str(tabletop_prototype.animation_busy), str(arriving_bee != null), tabletop_prototype.effect_layer.get_child_count(), int(tabletop_prototype.state.opponent.life)])
		await create_timer(1.2).timeout
		for unused_wait in range(30):
			if not bool(tabletop_prototype.animation_busy):
				break
			await create_timer(0.1).timeout
		tabletop_prototype.state.player.prep = []
		var firecracker: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.player, tabletop_prototype.service.card("spicy_firecracker_shrimp"), "plated", "player")
		var prep_target_a: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.opponent, tabletop_prototype.service.card("hearty_bagver"), "prep", "opponent")
		var prep_target_b: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.opponent, tabletop_prototype.service.card("hearty_macaroni_manatee"), "prep", "opponent")
		var plated_target: Dictionary = tabletop_prototype.service._make_unit(tabletop_prototype.state, tabletop_prototype.state.opponent, tabletop_prototype.service.card("hearty_stewoose"), "plated", "opponent")
		firecracker.ready = true
		firecracker.table_slot = 1
		tabletop_prototype.state.player.plated = [firecracker]
		tabletop_prototype.state.opponent.prep = [prep_target_a, prep_target_b]
		tabletop_prototype.state.opponent.plated = [plated_target]
		tabletop_prototype.state.turn = 2
		tabletop_prototype.state.player.turns_started = 2
		tabletop_prototype.state.phase = "player_main"
		tabletop_prototype.service.select_attacker(tabletop_prototype.state, int(firecracker.instance_id))
		tabletop_prototype.service.attack(tabletop_prototype.state, int(plated_target.instance_id))
		tabletop_prototype._render_match()
		var cancel_targeting := tabletop_prototype.find_child("CancelChoiceButton", true, false) as Button
		var targeting_prompt := tabletop_prototype.find_child("StatusLabel", true, false) as Label
		var right_plated_card := tabletop_prototype.find_child("PlayerPlatedCard_*", true, false) as Node3D
		_expect(right_plated_card != null and right_plated_card.position.x > 0.8, "A lone card assigned to the right Plated box was moved back to the center.")
		_expect(not tabletop_prototype.prompt_panel.visible and cancel_targeting != null and cancel_targeting.visible, "Firecracker Shrimp's Prep targeting still covered the Living Table.")
		_expect(String(tabletop_prototype.highlighted_zone) == "opponent_prep" and targeting_prompt != null and targeting_prompt.text == "Choose which prepped card to do 2 damage to.", "Firecracker Shrimp did not highlight the rival Prep bench with the requested instruction.")
		if cancel_targeting != null:
			cancel_targeting.emit_signal("pressed")
		await process_frame
		_expect(tabletop_prototype.state.pending_choice.is_empty() and bool(firecracker.ready), "Cancelling Firecracker Shrimp targeting spent the attacker or left the choice open.")
		tabletop_prototype.service.attack(tabletop_prototype.state, int(plated_target.instance_id))
		tabletop_prototype._render_match()
		tabletop_prototype._choose_effect_target_animated(int(prep_target_a.instance_id))
		_expect(bool(tabletop_prototype.animation_busy), "The Living Table did not begin an attack animation when Firecracker Shrimp's target resolved.")
		await create_timer(0.58).timeout
		_expect(tabletop_prototype.effect_layer.get_child_count() > 0, "The Living Table attack did not produce impact or damage feedback.")
		await create_timer(1.3).timeout
		_expect(not bool(tabletop_prototype.animation_busy), "The Living Table attack animation did not finish cleanly.")
		tabletop_prototype.exit_requested.emit()
	await process_frame
	_expect(main.current_screen == "shop", "The Living Table prototype did not return safely to the debug shell.")
	main._show_greybox_camera_demo()
	await process_frame
	await process_frame
	var camera_demo = main.find_child("GreyboxCameraDemo", true, false)
	_expect(main.current_screen == "camera_demo" and camera_demo != null, "The Debug Sandbox did not launch the graybox camera demonstration.")
	if camera_demo != null:
		_expect(camera_demo.find_children("CounterDisplayCard*", "Node3D", true, false).size() >= 6, "The card-store counters did not display their individual 3D card props.")
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
	if shop_overworld != null:
		_expect(shop_overworld.find_children("CounterDisplayCard*", "Node3D", true, false).size() >= 6, "The card-store overworld counters did not display their individual 3D card props.")
		_expect(shop_overworld.find_children("CardBody", "MeshInstance3D", true, false).size() >= 6, "The counter card props did not include physical rectangular bodies.")
	var shop_environment := main.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_expect(shop_environment != null and shop_environment.environment.background_color.is_equal_approx(Color("#e9dfc9")), "The card-store diorama void is not using the menu's #e9dfc9 background.")
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
	var shopkeeper_arrow := main.find_child("ShopkeeperArrow", true, false) as Control
	var shopkeeper_arrow_fill := main.find_child("ArrowFill", true, false) as Polygon2D
	_expect(shopkeeper_arrow != null and shopkeeper_arrow.visible and shopkeeper_arrow.mouse_filter == Control.MOUSE_FILTER_IGNORE and shopkeeper_arrow_fill != null and shopkeeper_arrow_fill.polygon.size() == 7, "The zoomed-out store is missing its vector-drawn floating shopkeeper arrow.")
	var shopkeeper_meshes := shopkeeper_model.find_children("*", "MeshInstance3D", true, false) if shopkeeper_model != null else []
	if shopkeeper_hotspot != null:
		shopkeeper_hotspot.emit_signal("mouse_entered")
	_expect(not shopkeeper_meshes.is_empty() and shopkeeper_meshes.all(func(mesh) -> bool: return mesh.material_overlay == shop_overworld.shopkeeper_highlight_material), "Hovering Clerk 1 did not highlight the full animated model.")
	if shopkeeper_hotspot != null:
		shopkeeper_hotspot.emit_signal("mouse_exited")
	_expect(shopkeeper_meshes.all(func(mesh) -> bool: return mesh.material_overlay == null), "Clerk 1's hover highlight did not clear when the pointer left.")
	_expect(main.find_child("ShotButtons", true, false) == null and main.find_child("TradingHotspot", true, false) == null and main.find_child("MetaHotspot", true, false) == null and main.find_child("DeckHotspot", true, false) == null, "The old store navigation buttons are still present.")
	var cash_hud := main.find_child("ShopHudCashButton", true, false) as Button
	var deck_hud := main.find_child("ShopHudDeckButton", true, false) as Button
	var save_hud := main.find_child("ShopHudSaveButton", true, false) as Button
	var settings_hud := main.find_child("ShopHudSettingsButton", true, false) as Button
	_expect(cash_hud != null and cash_hud.text == "$%d" % int(main.run.money), "The store HUD does not display the player's current cash.")
	_expect(deck_hud != null and deck_hud.icon != null and save_hud != null and save_hud.icon != null and settings_hud != null and settings_hud.icon != null, "The Deck Edit, Save, or Settings icon is missing from the store HUD.")
	var shopkeeper_meta_button := main.find_child("Meta", true, false) as Button
	_expect(main.find_child("Trade", true, false) == null and main.find_child("Deck", true, false) == null and main.find_child("Settings", true, false) == null, "The redundant Trade, Deck, or Settings option is still in the shopkeeper menu.")
	_expect(shopkeeper_meta_button != null, "The shopkeeper menu is missing Meta Analysis.")
	if shopkeeper_hotspot != null:
		shopkeeper_hotspot.emit_signal("pressed")
	_expect(shopkeeper_arrow != null and not shopkeeper_arrow.visible, "The shopkeeper arrow remained visible after leaving the zoomed-out store.")
	await create_timer(0.8).timeout
	_expect(shop_overworld != null and shop_overworld.menu_panel.visible, "Clicking Clerk 1 did not open her menu.")
	if shopkeeper_hotspot != null:
		shopkeeper_hotspot.emit_signal("mouse_entered")
	_expect(not shop_overworld.shopkeeper_hover_enabled and shopkeeper_meshes.all(func(mesh) -> bool: return mesh.material_overlay == null), "Clerk 1 remained highlighted while the shopkeeper menu was zoomed in.")
	var clerk_focus: Vector3 = shopkeeper_model.global_position + Vector3(0, shop_overworld.SHOPKEEPER_FOCUS_HEIGHT, 0) if shop_overworld != null and shopkeeper_model != null else Vector3.ZERO
	var clerk_camera_position: Vector3 = clerk_focus + shop_overworld.SHOPKEEPER_CAMERA_OFFSET if shop_overworld != null else Vector3.ZERO
	var clerk_camera_forward: Vector3 = -shop_overworld.camera_rig.global_basis.z if shop_overworld != null else Vector3.ZERO
	var clerk_camera_is_centered: bool = shop_overworld != null and shop_overworld.camera_rig.global_position.distance_to(clerk_camera_position) < 0.01 and clerk_camera_forward.dot(shop_overworld.camera_rig.global_position.direction_to(clerk_focus)) > 0.999
	_expect(clerk_camera_is_centered, "The shopkeeper camera did not finish slightly above and angled while keeping Clerk 1 centered.")
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
	_expect(in_scene_meta_entries != null and in_scene_meta_entries.get_child_count() == 3, "The in-scene Meta Analysis did not render all three archetype shares.")
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
	_expect(main.tournament_service.ai_difficulty_for_round(main, cup_event, 1) == "hard" and main.tournament_service.ai_difficulty_for_round(main, cup_event, 3) == "expert", "The League Cup does not ramp from Hard to Expert AI.")
	var original_difficulty := String(main.run.difficulty)
	main.run.difficulty = "blue"
	_expect(main.tournament_service.ai_difficulty_for_round(main, locals_event, 1) == "medium" and main.tournament_service.ai_difficulty_for_round(main, cup_event, 1) == "expert", "Blue difficulty does not promote opponents one AI tier earlier.")
	main.run.difficulty = original_difficulty
	for archetype_id in ["spicy", "hearty", "sweet", "fresh", "funky"]:
		var starter_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id[archetype_id].starterDeck)
		var easy_deck: Dictionary = main._opponent_deck_for_round(archetype_id, 1, {}, "easy")
		var medium_deck: Dictionary = main._opponent_deck_for_round(archetype_id, 1, {}, "medium")
		var hard_deck: Dictionary = main._opponent_deck_for_round(archetype_id, 1, {}, "hard")
		var expert_deck: Dictionary = main._opponent_deck_for_round(archetype_id, 1, {}, "expert")
		_expect(_deck_total(easy_deck) == main.MAIN_DECK_SIZE and _opponent_deck_score(main, easy_deck) > _opponent_deck_score(main, starter_deck), "%s Easy AI did not receive its deck upgrade." % archetype_id.capitalize())
		_expect(_deck_total(medium_deck) == main.MAIN_DECK_SIZE and _deck_total(hard_deck) == main.MAIN_DECK_SIZE and _deck_total(expert_deck) == main.MAIN_DECK_SIZE, "%s upgraded AI deck changed size." % archetype_id.capitalize())
		_expect(_deck_change_count(starter_deck, medium_deck) >= 4, "%s Medium AI did not receive four deck upgrades." % archetype_id.capitalize())
		_expect(_deck_change_count(starter_deck, hard_deck) >= 7, "%s Hard AI did not receive seven deck upgrades." % archetype_id.capitalize())
		_expect(_deck_change_count(starter_deck, expert_deck) >= 8, "%s Expert AI did not receive at least eight deck upgrades." % archetype_id.capitalize())
		var starter_score := _opponent_deck_score(main, starter_deck)
		_expect(_opponent_deck_score(main, medium_deck) > starter_score and _opponent_deck_score(main, hard_deck) > _opponent_deck_score(main, medium_deck) and _opponent_deck_score(main, expert_deck) > _opponent_deck_score(main, hard_deck), "%s opponent decks do not improve with each AI tier." % archetype_id.capitalize())
		_expect(_deck_respects_copy_limits(main, medium_deck) and _deck_respects_copy_limits(main, hard_deck) and _deck_respects_copy_limits(main, expert_deck), "%s upgraded AI deck exceeded a copy limit." % archetype_id.capitalize())

	main._start_season_tournament()
	await process_frame
	await process_frame
	var shop_before_completed_round: Array = main.run.shop.duplicate()
	_expect(main.current_screen == "kitchen_match", "Tournament round did not launch a Kitchen Match.")
	_expect(main._season_tournament_active(), "Tournament state was not created.")
	var opening_kitchen_game = main.find_child("Tabletop3DPrototype", true, false)
	_expect(opening_kitchen_game != null and bool(opening_kitchen_game.production_match), "The opening Locals match did not use the production Living Table view.")
	_expect(opening_kitchen_game != null and opening_kitchen_game.configured_player_deck == main.run.deck and _deck_total(opening_kitchen_game.configured_opponent_deck) == main.MAIN_DECK_SIZE, "The opening Locals match did not receive the selected and generated tournament decks.")
	_expect(opening_kitchen_game != null and String(opening_kitchen_game.state.get("ai_difficulty", "")) == "easy", "The opening Locals match did not receive its Easy AI tier.")
	_expect(opening_kitchen_game != null and bool(opening_kitchen_game.configured_match_context.get("tournament_round", false)) and int(opening_kitchen_game.configured_match_context.get("round", 0)) == 1 and String(opening_kitchen_game.configured_match_context.get("event_name", "")) == "Weekly Locals", "The Living Table did not receive its tournament event and round configuration.")
	_expect(String(main.run.get("kitchen_match", {}).get("presentation", "")) == "living_table", "The active tournament match did not persist its Living Table presentation configuration.")

	opening_kitchen_game.state.game_over = true
	opening_kitchen_game.state.winner = "opponent"
	opening_kitchen_game.state.turn = 5
	opening_kitchen_game.state.player.life = 0
	opening_kitchen_game.state.opponent.life = 8
	opening_kitchen_game._render_match()
	for unused_pacing_wait in range(30):
		if main.find_child("SeasonRoundResultHeading", true, false) != null:
			break
		await create_timer(0.1).timeout
	var loss_heading := main.find_child("SeasonRoundResultHeading", true, false) as Label
	var loss_action := main.find_child("SeasonRoundResultAction", true, false) as Button
	_expect(loss_heading != null and loss_heading.text == "YOU LOST", "The loss popup did not display its loss message.")
	_expect(loss_action != null and loss_action.text == "View Game Over", "The loss popup did not end the sudden-death run.")
	_expect(not opening_kitchen_game.outcome_overlay.visible and opening_kitchen_game.outcome_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The production victory/defeat overlay kept blocking the result controls.")
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
			var overview_next_round := main.find_child("StoreOverviewRoundButton", true, false) as Button
			_expect(overview_next_round != null and overview_next_round.visible and overview_next_round.text == "Start Round 2", "The store overview did not offer the pending next round.")
			if overview_next_round != null:
				overview_next_round.emit_signal("pressed")
			await process_frame
			await process_frame
			_expect(main.current_screen == "kitchen_match" and int(main.run.active_tournament.round) == 2, "The store overview did not launch the pending tournament round.")
		elif continue_action != null:
			continue_action.emit_signal("pressed")
		await process_frame
		await process_frame

	_expect(main._season_event_completed("weekly_locals"), "A 3-0 Locals result did not advance the calendar.")
	_expect(main._season_event_unlocked("monthly_regionals"), "Monthly Regionals did not unlock.")
	_expect(not main._season_tournament_active(), "Completed tournament remained active.")
	_expect(main.current_screen == "result", "Completed tournament did not show its result screen.")
	_expect(int(main.run.get("last_event_result", {}).get("reward_money", 0)) == 14 and int(main.run.get("last_event_result", {}).get("reward_packs", 0)) == 1 and int(main.run.get("prize_packs", 0)) == 1, "The Living Table tournament callback did not preserve the Locals reward payout.")

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
	_expect(
		main.current_screen == "thanks"
		and main.find_child("ThanksMainMenuButton", true, false) != null
		and main.find_child("FinaleChampionTitle", true, false) != null
		and main.find_child("FinaleTeaser", true, false) != null
		and main.find_child("FinaleDeckButton", true, false) != null,
		"Opening the League Cup prizes did not reach the composed season finale."
	)

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


func _click_control(control: Control) -> void:
	var click_position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = click_position
	motion.global_position = click_position
	root.push_input(motion)
	var press := InputEventMouseButton.new()
	press.position = click_position
	press.global_position = click_position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press)
	var release := InputEventMouseButton.new()
	release.position = click_position
	release.global_position = click_position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release)


func _deck_total(deck: Dictionary) -> int:
	var total := 0
	for count in deck.values():
		total += int(count)
	return total


func _deck_change_count(original: Dictionary, upgraded: Dictionary) -> int:
	var card_ids: Array = original.keys()
	for card_id in upgraded.keys():
		if not card_ids.has(card_id):
			card_ids.append(card_id)
	var absolute_change := 0
	for card_id in card_ids:
		absolute_change += absi(int(original.get(card_id, 0)) - int(upgraded.get(card_id, 0)))
	return absolute_change / 2


func _opponent_deck_score(main, deck: Dictionary) -> float:
	var score := 0.0
	for card_id in deck:
		score += main.tournament_service._opponent_card_upgrade_score(main, String(card_id)) * float(int(deck[card_id]))
	return score


func _deck_respects_copy_limits(main, deck: Dictionary) -> bool:
	for card_id in deck:
		if int(deck[card_id]) > main._deck_limit(String(card_id)):
			return false
	return true
