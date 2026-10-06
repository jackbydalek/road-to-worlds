extends SceneTree
## Seller close-up, real pointer actions, paid services, and persistent state.
var errors: Array[String] = []
var main

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.run_state_service.save_path = "/tmp/top-cut-seller-%d.json" % OS.get_process_id()
	main.player_settings.reduced_motion = false
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260905)
	main.run.money = 12
	main.run.life = 28
	main._show_tournament_hub()
	await process_frame
	var hub = main.find_child("TournamentHub", true, false)
	var inventory: Array = main.run.hub_shop.inventory.duplicate()
	_click(hub._seller_button)
	_expect(main.current_screen == "route_shop" and hub._seller_open and hub._transitioning, "Clicking the actual seller did not start her close-up.")
	_expect(hub._seller_upgrade_button.disabled and hub._remove_button.disabled, "Services can be bought during the zoom.")
	await create_timer(0.3).timeout
	_expect(hub._seller_zoom > 0.0 and hub._seller_zoom < 1.0, "Seller close-up cut directly instead of zooming.")
	await _capture("mid_zoom")
	await create_timer(0.6).timeout
	_expect(hub._seller_zoom == 1.0 and hub._shop_zoom == 0.0 and not hub._shop_view._interactive, "Seller zoom did not settle or left counter cards active.")
	_expect(main.find_child("TournamentHub", true, false) == hub, "Opening the seller replaced the room.")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for unused in range(8):
			await process_frame
		for control in [hub._seller_upgrade_button, hub._remove_button, hub._shop_back, hub._view_switch_button]:
			_expect(control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect()), "Seller option is hidden or clipped at %s: %s" % [viewport_size, control.name])
		await _capture("%dx%d" % [viewport_size.x, viewport_size.y])
	root.size = Vector2i(1440, 900)
	await create_timer(0.1).timeout
	var upgrade_id: String = main.route_run_service.upgradeable_card_ids(main.run)[0]
	var deck_before: Dictionary = main.run.deck.duplicate(true)
	_click(hub._seller_upgrade_button)
	await process_frame
	_expect(main.current_screen == "route_upgrade" and hub._seller_zoom == 1.0, "Upgrade did not open over the seller.")
	_expect((main.find_child("RouteUpgradeConfirmButton", true, false) as Button).disabled, "Upgrade starts confirmed without selecting a card.")
	_escape()
	await process_frame
	_expect(main.current_screen == "route_shop" and main.run.money == 12 and main.run.deck == deck_before and main.run.card_upgrades.is_empty(), "Cancelling an upgrade changed the run.")
	_expect(root.gui_get_focus_owner() == hub._seller_upgrade_button, "Cancelling upgrade lost seller focus.")
	_click(hub._seller_upgrade_button)
	await process_frame
	main._select_route_shop_service_card("upgrade", upgrade_id)
	await _capture("upgrade_picker")
	_click(main.find_child("RouteUpgradeConfirmButton", true, false))
	await _wait_for_service()
	_expect(main.run.money == 7 and main.route_run_service.upgrade_count(main.run, upgrade_id) == 1, "Seller upgrade did not charge $5 for exactly one upgrade.")
	_expect(main.current_screen == "route_shop" and hub._seller_open and hub._seller_zoom == 1.0 and hub._seller_upgrade_button.disabled, "Paid upgrade did not return to the seller with Upgrade used.")
	_expect(main.run.hub_shop.get("upgrade_purchased", false) and not main.run.hub_break_used and main.run.life == 28, "Paid upgrade did not persist independently of the bye and health.")
	var repeat_upgrade: Dictionary = main.route_run_service.buy_card_upgrade(main.run, main.run.pending_route_node, upgrade_id)
	_expect(not repeat_upgrade.ok and main.run.money == 7, "A second paid upgrade charged money.")
	_click(hub._remove_button)
	await process_frame
	_escape()
	await process_frame
	_expect(main.current_screen == "route_shop" and main.run.money == 7 and main.run.deck == deck_before and hub._seller_zoom == 1.0, "Cancelling removal changed the run or lost the seller.")
	_click(hub._remove_button)
	await process_frame
	var remove_id: String = main.run.deck.keys()[1]
	main._select_route_shop_service_card("remove", remove_id)
	_click(main.find_child("RouteRemoveConfirmButton", true, false))
	await _wait_for_service()
	_expect(main.run.money == 4 and int(main.run.deck.get(remove_id, 0)) == int(deck_before[remove_id]) - 1, "Seller removal did not charge $3 for exactly one copy.")
	_expect(hub._seller_open and hub._remove_button.disabled and not main.run.hub_break_used, "Removal did not return to the seller or spent the bye.")
	main._save_run()
	var saved: Dictionary = main.run_state_service.load_run()
	_expect(saved.get("ok", false) and saved.get("resume_screen", "") == "route_shop", "Seller state was not saved as a shop visit.")
	var restored: Dictionary = saved.get("run", {})
	_expect(restored.get("pending_route_node", {}).get("hub_view", "") == "seller" and restored.get("hub_shop", {}).get("upgrade_purchased", false) and restored.get("hub_shop", {}).get("remove_purchased", false), "Save lost the seller view or spent services.")
	main.run = restored
	main._show_route_shop()
	_expect(hub._seller_open and hub._seller_upgrade_button.disabled and hub._remove_button.disabled, "Restoring the seller refreshed a paid service.")
	_click(hub._view_switch_button)
	await create_timer(0.85).timeout
	_expect(hub._shop_zoom == 1.0 and hub._seller_zoom == 0.0 and hub._shop_view._interactive, "Browse Cards did not return to the working counter.")
	_expect(main.run.pending_route_node.inventory == inventory, "Switching viewpoints rerolled stock.")
	_click(hub._view_switch_button)
	await create_timer(0.2).timeout
	main._leave_hub_shop()
	await create_timer(0.15).timeout
	main._open_hub_seller()
	await create_timer(0.85).timeout
	_expect(hub._seller_zoom == 1.0 and hub._shop_zoom == 0.0 and not hub._transitioning, "Reversing a seller transition stranded the camera.")
	main._leave_hub_shop()
	await create_timer(0.15).timeout
	main.player_settings.reduced_motion = true
	hub.configure(main._tournament_hub_snapshot(), true)
	_expect(hub._seller_zoom == 0.0 and not hub._transitioning, "Reduced motion did not complete an active seller transition.")
	main._open_hub_seller()
	_expect(hub._seller_zoom == 1.0 and not hub._transitioning, "Reduced motion still animates the seller close-up.")
	(main.find_child("HubSettingsButton", true, false) as Button).pressed.emit()
	await process_frame
	(main.find_child("SettingsBackButton", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	hub = main.find_child("TournamentHub", true, false)
	_expect(main.current_screen == "route_shop" and hub._seller_zoom == 1.0 and main.run.pending_route_node.inventory == inventory, "Settings did not restore the seller and saved stock.")
	_escape()
	await process_frame
	_expect(main.current_screen == "route_hub" and hub._seller_zoom == 0.0 and root.gui_get_focus_owner() == hub._seller_button, "Escape did not return to the room with focus on the seller.")
	var free_upgrade_id: String = main.route_run_service.upgradeable_card_ids(main.run)[0]
	var free_upgrade: Dictionary = main.route_run_service.use_hub_break_upgrade(main.run, free_upgrade_id)
	_expect(free_upgrade.ok and main.run.money == 4 and main.run.hub_break_used, "The paid services consumed or charged for the separate free bye upgrade.")
	main._open_hub_seller()
	main.run.pending_route_node.inventory = []
	main._show_route_shop()
	_expect(hub._seller_open and hub._seller_view.visible, "Sold-out stock prevents visiting the seller.")
	await _capture("services_used")
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	for message in errors:
		push_error(message)
	print("Hub seller smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func _wait_for_service() -> void:
	for unused in range(60):
		await create_timer(0.1).timeout
		if main.current_screen == "route_shop":
			# Let the departing modal and its focus restoration finish before the
			# next click; headless mode can dispatch several actions in one frame.
			for frame in range(4):
				await process_frame
			return
	_expect(false, "Seller service did not finish.")

func _click(control: Control) -> void:
	if control == null:
		_expect(false, "Missing click target.")
		return
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/hub_seller_%s.png" % label))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		print("FAILED: ", message)
