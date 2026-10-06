extends SceneTree
## Exercises the real hub, its camera transition, purchases, and paid removal.
## With a display, also saves counter review captures at three window sizes.

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.run_state_service.save_path = "/tmp/top-cut-counter-%d.json" % OS.get_process_id()
	main.player_settings.reduced_motion = false
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 424242)
	main.run.life = 25
	main.run.money = 12
	main.run.hub_shop = {
		"id": "locals_card_shop", "type": "shop", "hub_shop": true,
		"inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"],
	}
	main._show_tournament_hub()
	await process_frame
	var hub := main.find_child("TournamentHub", true, false)
	var room_id: int = hub.get_instance_id()
	# Pointer smoothing must agree across frame rates, stay bounded, and coast
	# through a direction reversal instead of snapping position or velocity.
	hub.set_process(false)
	hub._parallax_position = Vector2.ZERO
	hub._parallax_velocity = Vector2.ZERO
	for unused in range(30):
		hub._advance_parallax(Vector2.ONE, 1.0 / 30.0)
	var at_30: Vector2 = hub._parallax_position
	hub._parallax_position = Vector2.ZERO
	hub._parallax_velocity = Vector2.ZERO
	for unused in range(144):
		hub._advance_parallax(Vector2.ONE, 1.0 / 144.0)
	_expect(at_30.distance_to(hub._parallax_position) < 0.0001, "Parallax changes with frame rate.")
	_expect(at_30.x > 0.99 and at_30.x <= 1.0, "Parallax overshoots or never settles.")
	var before_reversal: Vector2 = hub._parallax_position
	hub._advance_parallax(-Vector2.ONE, 1.0 / 144.0)
	_expect(before_reversal.distance_to(hub._parallax_position) < 0.01, "Pointer reversal snaps the room.")
	hub.set_process(true)
	await _capture("hub_counter_room")
	(main.find_child("HubShopButton", true, false) as Button).emit_signal("pressed")
	_expect(hub._transitioning and not hub._shop_view._interactive, "Zoom starts without guarding purchase input.")
	await create_timer(0.32).timeout
	_expect(hub._shop_zoom > 0.0 and hub._shop_zoom < 1.0, "Browse Cards cut straight to the counter.")
	await _capture("hub_counter_mid_zoom")
	await create_timer(0.6).timeout
	_expect(main.find_child("TournamentHub", true, false).get_instance_id() == room_id, "Zoom replaced the room.")
	_expect(hub._heal_button.focus_mode == Control.FOCUS_NONE and hub._upgrade_button.focus_mode == Control.FOCUS_NONE, "Counter keyboard navigation can activate offscreen bye controls.")
	_expect(is_equal_approx(hub._shop_zoom, 1.0) and hub._shop_view._interactive, "Counter did not finish opening.")
	for buy in main.find_children("RouteShopBuy_*", "Button", true, false):
		_expect(not buy.visible, "Buy is visible before selecting a card.")
	var money_before_selection: int = main.run.money
	var deck_before_selection: Dictionary = main.run.deck.duplicate(true)
	hub._shop_view.select_card("spicy_hot_honey_bee")
	hub._shop_view.select_card("spicy_sriracharrow")
	_expect(not (main.find_child("RouteShopBuy_spicy_hot_honey_bee", true, false) as Button).visible and (main.find_child("RouteShopBuy_spicy_sriracharrow", true, false) as Button).visible, "Switching cards left multiple Buy actions visible.")
	var poor_snapshot: Dictionary = main._tournament_hub_snapshot()
	poor_snapshot.money = 1
	hub.configure(poor_snapshot, true)
	var unaffordable := main.find_child("RouteShopBuy_spicy_sriracharrow", true, false) as Button
	_expect(unaffordable.visible and unaffordable.disabled, "An unaffordable selection allows buying.")
	unaffordable.pressed.emit()
	_expect(main.run.money == money_before_selection and main.run.deck == deck_before_selection, "Selecting or unaffordable Buy changed the run.")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	root.push_input(cancel, true)
	await process_frame
	_expect(hub._shop_view._selected_id.is_empty() and main.current_screen == "route_shop", "Escape should lower the card before leaving the counter.")
	hub.configure(main._tournament_hub_snapshot(), false)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for unused in range(8):
			await process_frame
		var viewport_rect := root.get_visible_rect()
		for control in hub._shop_view.focus_controls() + [hub._shop_back, hub._view_switch_button]:
			_expect(viewport_rect.encloses(control.get_global_rect()), "Counter control clipped at %s: %s" % [viewport_size, control.name])
		await _capture("hub_counter_%dx%d" % [viewport_size.x, viewport_size.y])
		hub._shop_view.select_card("spicy_hot_honey_bee")
		hub._shop_view.set_hovered_card("spicy_hot_honey_bee")
		await create_timer(0.2).timeout
		var buy := main.find_child("RouteShopBuy_spicy_hot_honey_bee", true, false) as Button
		var lifted := main.find_child("HubCounterLiftedCard_spicy_hot_honey_bee", true, false) as Control
		_expect(buy.visible and viewport_rect.encloses(buy.get_global_rect()), "Selected Buy clips at %s" % viewport_size)
		_expect(buy.get_global_rect().position.y > lifted.get_global_rect().end.y, "Buy is not below the lifted card.")
		_expect(lifted.scale.x > 1.1, "Hover does not enlarge the card in place.")
		hub._shop_view.close_inspection()
		await create_timer(0.2).timeout
	root.size = Vector2i(1280, 720)
	for unused in range(8):
		await process_frame
	var purchased_id := "spicy_hot_honey_bee"
	_click(main.find_child("RouteShopCardButton_%s" % purchased_id, true, false))
	await process_frame
	_expect(hub._shop_view._selected_id == purchased_id, "Real card click did not select the card.")
	_expect(main.find_child("HubCardInspection", true, false) == null, "Selecting a card opened a purchase modal.")
	await _capture("hub_counter_inspect")
	var money_before: int = main.run.money
	var copies_before: int = main.run.deck.get(purchased_id, 0)
	_click(main.find_child("RouteShopBuy_%s" % purchased_id, true, false))
	for unused in range(4):
		await process_frame
	_expect(int(main.run.money) == money_before - main._card_price(purchased_id), "Purchase charged the wrong amount.")
	_expect(int(main.run.deck.get(purchased_id, 0)) == copies_before + 1, "Purchase did not add exactly one copy.")
	_expect(not main.run.hub_shop.inventory.has(purchased_id), "Purchased card remained in stock.")
	_expect(hub._shop_view._selected_id.is_empty(), "Purchase did not clear the selection.")
	_expect(main.find_child("TournamentHub", true, false) == hub and hub._shop_zoom == 1.0, "Purchase reset the camera or room.")
	await _capture("hub_counter_purchased")

	# Cancel is free, confirmation removes one copy, and the state survives visits.
	_click(hub._view_switch_button)
	await create_timer(0.85).timeout
	_expect(hub._seller_open and hub._seller_zoom == 1.0, "The counter shortcut did not zoom into the seller.")
	var remove := main.find_child("RouteShopRemoveButton", true, false) as Button
	var deck_before: Dictionary = main.run.deck.duplicate(true)
	money_before = int(main.run.money)
	_click(remove)
	await process_frame
	_expect(main.current_screen == "route_remove", "Shopkeeper did not open removal.")
	_expect((main.find_child("RouteRemoveConfirmButton", true, false) as Button).disabled, "Removal confirmation starts enabled without a selection.")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await process_frame
	_expect(main.current_screen == "route_shop" and main.run.deck == deck_before and int(main.run.money) == money_before, "Cancelling removal changed deck or money, or left the counter.")
	_expect(root.gui_get_focus_owner() == remove, "Cancelling removal lost keyboard focus.")
	_click(remove)
	await process_frame
	var remove_id := String(main.run.deck.keys()[0])
	main._select_route_shop_service_card("remove", remove_id)
	await _capture("hub_counter_removal")
	_click(main.find_child("RouteRemoveConfirmButton", true, false))
	for unused in range(4):
		await process_frame
	_expect(int(main.run.deck.get(remove_id, 0)) == int(deck_before[remove_id]) - 1, "Removal did not remove exactly one copy.")
	_expect(int(main.run.money) == money_before - 3, "Removal did not cost exactly $3.")
	_expect(bool(main.run.hub_shop.get("remove_purchased", false)) and remove.disabled, "Removal did not become used for this round.")
	_expect(not main.run.hub_break_used and int(main.run.life) == 25, "Removal spent the bye or changed health.")
	main._save_run()
	var loaded: Dictionary = main.run_state_service.load_run()
	_expect(bool(loaded.get("ok", false)), "Counter save is not loadable.")
	_expect(loaded.get("resume_screen", "") == "route_shop", "Counter save recorded the wrong resume screen.")
	var saved_run: Dictionary = loaded.get("run", {})
	_expect(bool(saved_run.get("hub_shop", {}).get("remove_purchased", false)) and bool(saved_run.get("pending_route_node", {}).get("remove_purchased", false)), "Save lost the used removal service.")
	_expect(saved_run.get("deck", {}) == main.run.deck and int(saved_run.get("money", 0)) == int(main.run.money), "Save lost the purchased/removed deck or funds.")
	main._leave_hub_shop()
	await create_timer(0.85).timeout
	_expect(hub._shop_zoom == 0.0 and main.find_child("TournamentHub", true, false) == hub, "Leaving did not zoom back into the same room.")
	main._open_hub_shop()
	await create_timer(0.85).timeout
	_expect(remove.disabled and bool(main.run.pending_route_node.get("remove_purchased", false)), "Returning refreshed the removal service.")
	var repeated: Dictionary = main.route_run_service.buy_card_removal(main.run, main.run.pending_route_node, remove_id, 1)
	_expect(not repeated.ok and int(main.run.money) == money_before - 3, "A second removal charged money.")
	var guarded: Dictionary = main.run.duplicate(true)
	guarded.money = 2
	_expect(not main.route_run_service.buy_card_removal(guarded, {}, remove_id, 1).ok, "Insufficient funds allowed removal.")
	guarded.money = 10
	guarded.deck = {remove_id: 1}
	_expect(not main.route_run_service.buy_card_removal(guarded, {}, remove_id, 1).ok and guarded.money == 10, "Removal can empty the deck or charge on failure.")

	# Reversing a transition and switching reduced motion both settle safely.
	main._leave_hub_shop()
	await create_timer(0.22).timeout
	main._open_hub_shop()
	await create_timer(0.85).timeout
	_expect(hub._shop_zoom == 1.0 and not hub._transitioning, "Reversing zoom stranded the camera.")
	main._leave_hub_shop()
	await create_timer(0.15).timeout
	hub.configure(main._tournament_hub_snapshot(), true)
	_expect(hub._shop_zoom == 0.0 and not hub._transitioning, "Reduced motion did not finish an active transition immediately.")
	main.player_settings.reduced_motion = true
	main._open_hub_shop()
	_expect(hub._shop_zoom == 1.0 and not hub._transitioning, "Reduced motion still animates browsing.")
	(main.find_child("HubSettingsButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	(main.find_child("SettingsBackButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	await process_frame
	hub = main.find_child("TournamentHub", true, false)
	_expect(main.current_screen == "route_shop" and hub._shop_zoom == 1.0, "Settings did not restore the counter close-up.")
	_expect(bool(main.run.pending_route_node.get("remove_purchased", false)) and not main.run.pending_route_node.inventory.has(purchased_id), "Settings changed removal or stock.")
	main.run.pending_route_node.inventory = []
	main._show_hub_counter()
	await _capture("hub_counter_sold_out")
	_expect((main.find_child("HubCounterEmptyLabel", true, false) as Label).visible, "Empty counter has no sold-out feedback.")
	main._leave_hub_shop()
	var sold_out_button := main.find_child("HubShopButton", true, false) as Button
	_expect(sold_out_button.visible and not sold_out_button.disabled and sold_out_button.text.is_empty() and sold_out_button.tooltip_text.to_lower().contains("sold out"), "Sold-out stock hides the physical case target or loses its accessible stock status.")
	main._open_hub_shop()
	_expect(main.current_screen == "route_shop", "Sold-out stock prevents visiting the shopkeeper.")
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	if _errors.is_empty():
		print("Hub counter zoom smoke test passed.")
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		quit(1)


func _click(control: Control) -> void:
	if control == null:
		_errors.append("A requested click target is missing.")
		return
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "res://outputs/%s.png" % filename
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "Could not save " + path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
