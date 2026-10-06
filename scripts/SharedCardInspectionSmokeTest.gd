extends SceneTree
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const BODYGUARD := "sweet_soft_serve_crab"
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _settle()
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 13579)
	main.run.reward_offer = [BODYGUARD, "spicy_wasabi_wasp"]
	main.run.reward_picks_remaining = 2
	main.run.pending_route_node = main._hub_round_node(1)
	main._show_route_card_reward()
	var deck_before: Dictionary = main.run.deck.duplicate(true)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(1728, 1117)]:
		root.size = viewport_size
		await _settle()
		var reward := main.find_child("RouteRewardCardButton_%s" % BODYGUARD, true, false) as Control
		reward.grab_focus()
		await create_timer(0.45).timeout
		await _settle()
		var hover := root.find_child("SharedCardHoverPreview", true, false) as Control
		_expect(hover != null and root.get_visible_rect().encloses(hover.get_global_rect()), "The shared focus preview is clipped at %s." % viewport_size)
		await _capture("inspection_hover_%dx%d" % [viewport_size.x, viewport_size.y])
		_click(reward, MOUSE_BUTTON_RIGHT)
		await _settle()
		_check_inspection(BODYGUARD)
		await _capture("inspection_reward_%dx%d" % [viewport_size.x, viewport_size.y])
		_key(KEY_ESCAPE)
		await _settle()
		_expect(root.gui_get_focus_owner() == reward, "Closing inspection lost reward focus.")
		_key(KEY_I)
		await _settle()
		_check_inspection(BODYGUARD)
		_click(root.find_child("CardInspectionClose", true, false))
		await _settle()
	_expect(main.run.deck == deck_before and main.run.reward_offer.size() == 2, "Reading a reward changed the run.")
	main._finish_route_reward()
	await _settle()
	var route_run: Dictionary = main.run.duplicate(true)
	# Older pack screens must reveal a card before exposing its inspection data.
	main.run.run_mode = "debug"
	main._start_pack([{"cardId": BODYGUARD, "rarity": "common", "revealed": false}])
	main._show_packs()
	await _settle()
	var slot: Control = main.pack_opening_screen.card_slots[0]
	_click(slot, MOUSE_BUTTON_RIGHT)
	await _settle()
	_expect(_inspection() == null, "A face-down pack card exposed its identity.")
	main.pack_opening_screen._on_reveal_all_pressed(main)
	await _settle()
	_click(slot, MOUSE_BUTTON_RIGHT)
	await _settle()
	_check_inspection(BODYGUARD)
	_key(KEY_ESCAPE)
	await _settle()
	main.pack_opening_screen._render(main)
	await _settle()
	_expect(slot.get_node_or_null("CardInspectionFocus") != null, "Rerendering a pack card removed its keyboard focus edge.")
	main.run = route_run
	main.run.money = 20
	main.run.hub_shop = {"id": "locals_card_shop", "type": "shop", "hub_shop": true, "inventory": [BODYGUARD, "spicy_wasabi_wasp"]}
	main._show_tournament_hub()
	main._open_hub_shop()
	await _settle()
	var shop := main.find_child("RouteShopCardButton_%s" % BODYGUARD, true, false) as Control
	_click(shop, MOUSE_BUTTON_RIGHT)
	await _settle()
	_check_inspection(BODYGUARD)
	_key(KEY_ESCAPE)
	await _settle()
	_click(shop)
	await _settle()
	_expect((main.find_child("RouteShopBuy_%s" % BODYGUARD, true, false) as Button).visible and main.find_child("HubCardInspection", true, false) == null, "Shop selection should reveal Buy in the counter; right-click retains the shared guide.")
	await _capture("inspection_shop")
	(main.find_child("TournamentHub", true, false))._shop_view.close_inspection()
	main._leave_hub_shop()
	main.run.deck[BODYGUARD] = 2
	main.run.card_upgrades = {BODYGUARD: 1}
	main._show_deckbuilder()
	await _settle()
	var tile: Control
	for candidate in main.find_children("InspectedCardFace", "", true, false):
		if candidate.get_meta("card_id", "") == BODYGUARD and int(candidate.get_meta("copy_index", -1)) == 0:
			tile = candidate
	var deck_scroll := main.find_child("DeckbuilderMainDeckScroll", true, false) as ScrollContainer
	deck_scroll.ensure_control_visible(tile)
	await _settle()
	_click(tile, MOUSE_BUTTON_RIGHT)
	await _settle()
	_check_inspection(BODYGUARD)
	var overlay := _inspection()
	_expect(overlay != null and bool(overlay._card.get("upgraded", false)), "Inspection lost the specific copy's upgrade.")
	_expect(overlay != null and int(overlay._card.attack) == 2 and int(overlay._card.health) == 5, "The upgraded copy still displayed printed base stats.")
	var normal_copy: Dictionary = main.deckbuilder_screen._route_display_card_copy(main, BODYGUARD, main.cards_by_id[BODYGUARD], 1)
	_expect(not bool(normal_copy.get("upgraded", false)) and int(normal_copy.attack) == 1 and int(normal_copy.health) == 4, "A normal copy inherited another copy's upgrade.")
	var recipe: Dictionary = main.route_run_service.upgraded_card_data("item_recipe_prep")
	_expect(int(recipe.discard_cost) == 1 and recipe.text == "Discard 1 card; search your deck for a unit.", "The upgraded tool still described its old discard cost.")
	var shopping_list: Dictionary = main.route_run_service.upgraded_card_data("item_spicy_shopping_list")
	_expect(int(shopping_list.discard_cost) == 0 and shopping_list.text == "Search your deck for a Spicy Ingredient.", "A free upgraded tool still described a discard cost.")
	var beetle: Dictionary = main.route_run_service.upgraded_card_data("funky_beat_beetle")
	_expect(beetle.text == "When played, draw 1 card.", "An upgraded unit still described its removed discard cost.")
	await _capture("inspection_deck")
	_key(KEY_ESCAPE)
	await _settle()
	main.run.run_over = true
	main.run.hub_round = 4
	main.run.route_round_results = [
		{"round": 1, "opponent_name": "Cal", "won": true, "cash": 2},
		{"round": 2, "opponent_name": "Priya", "won": true, "cash": 2},
		{"round": 3, "opponent_name": "Mina", "won": true, "cash": 5},
		{"round": 4, "opponent_name": "Tess", "won": false, "player_life": 0},
	]
	main._show_route_game_over()
	await _settle()
	_expect((main.find_child("TournamentResultProgress", true, false) as Label).text == "Defeated", "The defeat banner contains extra copy.")
	_expect(main.find_child("TournamentResultSignatureCard", true, false) != null and main.find_child("TournamentResultDeckShowcase", true, false).get_child_count() == 3, "The run's signature card or final-deck cards are missing.")
	await _capture("ui_consistency_route_results")
	deck_before = main.run.deck.duplicate(true)
	_click(main.find_child("FinalDeckReviewButton", true, false))
	await _settle()
	var grouping := main.find_child("FinalDeckReviewGroupCopies", true, false) as CheckButton
	grouping.button_pressed = false
	await _settle()
	var grid := main.find_child("FinalDeckReviewGrid", true, false) as GridContainer
	_expect(grid != null and grid.get_child_count() == main._deck_total(main.run.deck), "Final review did not show every physical card copy.")
	var final_card := grid.find_child("FinalDeckReviewCard_%s_0" % BODYGUARD, true, false).get_child(0) as Control
	(main.find_child("FinalDeckReviewScroll", true, false) as ScrollContainer).ensure_control_visible(final_card)
	await _settle()
	_click(final_card)
	await _settle()
	_expect(_inspection() != null, "Clicking a final-deck card did not inspect it.")
	_expect(_inspection() != null and int(_inspection()._card.attack) == 2 and int(_inspection()._card.health) == 5, "Final deck inspection lost the upgraded stats.")
	_key(KEY_ESCAPE)
	await _settle()
	_expect(main.find_child("FinalDeckReview", true, false) != null, "Closing card inspection also closed the deck review.")
	await _capture("ui_consistency_final_deck")
	_key(KEY_ESCAPE)
	await _settle()
	_expect(main.find_child("FinalDeckReview", true, false) == null and main.run.deck == deck_before and main.run.run_over, "Reviewing a finished deck changed it or could not close.")
	main.hide()
	var table := (load("res://scenes/Tabletop3DPrototype.tscn") as PackedScene).instantiate()
	table.configure_match(starter, starter, "Player", "Rival", 13579, "player", "Return", "easy", "blue")
	root.add_child(table)
	await create_timer(1.0).timeout
	var unit: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card(BODYGUARD), "plated", "player")
	unit.health = 1
	unit.attack = 7
	table.state.player.plated = [unit]
	table.selected_ref = {"kind": "field", "side": "player", "hand_index": -1, "instance_id": int(unit.instance_id), "zone": "plated", "card_id": BODYGUARD}
	table._refresh_action_panel()
	await _settle()
	var preview_runtime := table.inspector_card_face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
	_expect(preview_runtime != null and preview_runtime.card_border_color.is_equal_approx(PALETTE.CARD_BORDER_BLUE), "The battle left preview lost the chosen blue card border.")
	_expect(is_instance_valid(table.keyword_popout) and table.keyword_popout.size.y < 400 and root.get_visible_rect().encloses(table.keyword_popout.get_global_rect()), "The battle keyword guide stretched or left the viewport.")
	await _capture("inspection_battle_actions")
	_click(table.inspector_card_face, MOUSE_BUTTON_RIGHT)
	await _settle()
	_check_inspection(BODYGUARD, PALETTE.CARD_BORDER_BLUE)
	overlay = _inspection()
	_expect(overlay != null and int(overlay._card.health) == 1 and int(overlay._card.attack) == 7, "Battle inspection replaced live stats with printed stats.")
	await _capture("inspection_battle")
	_key(KEY_ESCAPE)
	await _settle()
	_key(KEY_I)
	await _settle()
	_check_inspection(BODYGUARD, PALETTE.CARD_BORDER_BLUE)
	_key(KEY_ESCAPE)
	await _settle()
	_key(KEY_ESCAPE)
	await _settle()
	_expect(table.selected_ref.is_empty(), "Escape did not close the battle inspector.")
	for tween in get_processed_tweens():
		tween.kill()
	table.queue_free()
	main.queue_free()
	await _settle()
	if _errors.is_empty():
		print("Shared card inspection smoke test passed.")
		quit(0)
	else:
		for error in _errors:
			push_error(error)
		quit(1)

func _inspection() -> Control:
	for node in get_nodes_in_group("shared_card_inspection"):
		if not node.is_queued_for_deletion():
			return node
	return null

func _check_inspection(card_id: String, expected_border: Color = Color.TRANSPARENT) -> void:
	var overlay := _inspection()
	_expect(overlay != null, "No common inspection opened for %s." % card_id)
	if overlay == null:
		return
	_expect(overlay._card.id == card_id, "Inspected the wrong card.")
	var panel := overlay.find_child("CardInspectionPanel", true, false) as Control
	_expect(root.get_visible_rect().encloses(panel.get_global_rect()), "Inspection is clipped at %s." % root.size)
	_expect(overlay.find_child("CardKeyword_bodyguard", true, false) != null, "Bodyguard explanation is missing.")
	var face := overlay.find_child("InspectedCardFace", true, false) as Control
	_expect(face.size == Vector2(320, 454), "The common card preview changed size between screens.")
	var runtime := face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
	_expect(runtime != null and runtime.peach_soda_frame, "A shared inspection opened with a different card frame.")
	if expected_border.a > 0.0:
		_expect(runtime != null and runtime.card_border_color.is_equal_approx(expected_border), "The enlarged inspection lost the chosen card border.")

func _click(control: Control, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	if control == null:
		_errors.append("Missing click target.")
		return
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event, true)

func _settle() -> void:
	for unused in range(8):
		await process_frame

func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/%s.png" % filename)) == OK, "Could not save inspection capture.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
