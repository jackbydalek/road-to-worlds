extends SceneTree
## Three-place overview, delayed machine controls, shared bye, and saved focus.
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
	main.run_state_service.save_path = "/private/tmp/locals-machine-%d.json" % OS.get_process_id()
	main.player_settings.reduced_motion = false
	root.size = Vector2i(1280, 720)
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260908)
	main.run.money = 12
	main.run.life = 28
	main._show_tournament_hub()
	await process_frame
	var hub = main.find_child("TournamentHub", true, false)
	var inventory: Array = main.run.hub_shop.inventory.duplicate()
	_expect(hub._seller_art.get_meta("asset_origin") == "user_supplied_animation", "The clerk did not use the supplied Mina pixels.")
	for name in ["HubRoomArtwork", "HubShopDesk", "VendingMachineBody"]:
		var drawing = hub.find_child(name, true, false)
		_expect(drawing.get_script() != null and drawing.get_script().resource_path == "res://scripts/ui/PeachSodaShopIllustration.gd", "%s did not use the registered shop layer renderer." % name)
	_expect(not hub._heal_button.is_visible_in_tree() and not hub._upgrade_button.is_visible_in_tree() and hub._heal_button.disabled and hub._upgrade_button.disabled, "The overview exposed free-bye actions.")
	_expect(not hub._seller_view.visible and not hub._shop_view.visible and not hub._machine_view.visible, "The overview exposed a service panel.")
	for button in [hub._seller_button, hub.find_child("HubShopButton", true, false), hub._machine_button]:
		_expect(button.is_visible_in_tree() and not button.disabled and button.focus_mode == Control.FOCUS_ALL, "A shop destination is inaccessible in overview.")
	_click(hub._machine_button)
	_expect(main.current_screen == "route_shop" and hub._machine_open and hub._transitioning, "Clicking the cabinet did not begin its saved focus view.")
	_expect(not hub._machine_view.visible and hub._heal_button.disabled and hub._upgrade_button.disabled, "Machine actions appeared during travel.")
	await create_timer(0.3).timeout
	_expect(hub._machine_zoom > 0 and hub._machine_zoom < 1, "The machine camera did not move continuously.")
	await create_timer(0.46).timeout
	_expect(not hub._machine_view.visible, "Machine controls appeared before the post-camera settling pause.")
	await create_timer(0.15).timeout
	_expect(hub._machine_zoom == 1 and not hub._transitioning and hub._machine_view.visible, "Machine focus did not settle and reveal its options.")
	_expect(main.find_child("TournamentHub", true, false) == hub and main.run.pending_route_node.inventory == inventory, "Focusing the machine replaced the room or rerolled cards.")
	_expect(main.run.pending_route_node.hub_view == "machine", "Machine focus was not recorded in existing shop state.")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for frame in range(4): await process_frame
		for control in hub._snack_view.focus_controls() + [hub._shop_back]:
			_expect(control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect()), "Machine option clipped at %s: %s" % [viewport_size, control.name])
	_expect(not hub._heal_button.visible and not hub._upgrade_button.visible, "An action appeared before selecting a snack.")
	# A hidden confirmation cannot be triggered, and hover follows the pointer.
	hub._heal_button.pressed.emit()
	hub._upgrade_button.pressed.emit()
	_expect(main.run.life == 28 and not main.run.hub_break_used and main.current_screen == "route_shop", "A hidden snack confirmation changed the run.")
	_move(hub._snack_view._offers.heal.hit.get_global_rect().get_center())
	await process_frame
	_expect(hub._snack_view._offers.heal.hit.get_meta("highlight_active", false), "Heart Bites did not highlight on hover.")
	_click(hub._snack_view._offers.heal.hit)
	await create_timer(0.2).timeout
	_move(hub._snack_view._offers.upgrade.hit.get_global_rect().get_center())
	await process_frame
	_expect(not hub._snack_view._offers.heal.hit.get_meta("highlight_active", false) and hub._snack_view._offers.upgrade.hit.get_meta("highlight_active", false), "Hovering a different snack left the old packet highlighted.")
	_click(hub._snack_view._offers.upgrade.hit)
	await create_timer(0.2).timeout
	_expect(hub._upgrade_button.visible and not hub._heal_button.visible and not main.run.hub_break_used and main.current_screen == "route_shop", "First snack click did not just preview the packet.")
	_expect(hub._upgrade_button.text == "Upgrade a card", "Upgrade action has the wrong label.")
	# Cancelling the real free-upgrade picker must not consume the shared use.
	_click(hub._upgrade_button)
	await process_frame
	_expect(main.current_screen == "route_break_upgrade", "The machine did not open the existing free-upgrade picker.")
	_escape()
	for frame in range(4): await process_frame
	_expect(main.current_screen == "route_shop" and hub._machine_open and hub._machine_zoom == 1 and not main.run.hub_break_used, "Cancel lost machine focus or consumed the bye.")
	_expect(main.run.money == 12 and main.run.life == 28, "Cancelling changed currency or health.")
	_click(hub._snack_view._offers.heal.hit)
	await create_timer(0.2).timeout
	_expect(hub._heal_button.visible and not hub._upgrade_button.visible and hub._heal_button.text == "Heal 5 HP", "Switching snacks did not reveal only Heal 5 HP.")
	_expect(hub._heal_button.get_global_rect().position.y > hub._snack_view._offers.heal.visual.get_global_rect().end.y, "Heal confirmation is not underneath its packet.")
	_click(hub._heal_button)
	for frame in range(4): await process_frame
	_expect(main.current_screen == "route_shop" and hub._machine_open and hub._machine_view.visible, "Healing lost the machine close-up.")
	_expect(main.run.life == 33 and main.run.money == 12 and main.run.hub_break_used and main.run.hub_break_choice == "heal", "The shared bye did not heal exactly5 without charging money.")
	_expect(hub._out_of_order.is_visible_in_tree() and not hub._heal_button.is_visible_in_tree() and not hub._upgrade_button.is_visible_in_tree(), "The used cabinet still exposed either shared-bye action.")
	main._save_run()
	var loaded: Dictionary = main.run_state_service.load_run()
	_expect(loaded.get("ok", false) and loaded.run.pending_route_node.hub_view == "machine" and loaded.run.hub_break_used, "Saving lost machine focus or the consumed bye.")
	(main.find_child("HubSettingsButton", true, false) as Button).pressed.emit()
	await process_frame
	(main.find_child("SettingsBackButton", true, false) as Button).pressed.emit()
	for frame in range(4): await process_frame
	hub = main.find_child("TournamentHub", true, false)
	_expect(main.current_screen == "route_shop" and hub._machine_open and hub._machine_zoom == 1 and hub._out_of_order.is_visible_in_tree(), "Settings did not restore the used machine view.")
	main.player_settings.reduced_motion = true
	hub.configure(main._tournament_hub_snapshot(), true)
	_escape()
	for frame in range(4): await process_frame
	_expect(main.current_screen == "route_hub" and hub._machine_zoom == 0 and root.gui_get_focus_owner() == hub._machine_button, "Escape did not restore overview and machine focus.")
	_expect(hub._machine_used_sign.visible and main.run.hub_shop.inventory == inventory, "Leaving the machine reset its use or stock.")
	_click(hub._machine_button)
	_expect(hub._machine_zoom == 1 and not hub._transitioning, "Reduced Motion still animated machine travel.")
	var repeated: Dictionary = main.route_run_service.use_hub_break_heal(main.run)
	_expect(not repeated.ok and main.run.life == 33 and main.run.money == 12, "The spent machine could be used twice.")
	main._leave_hub_shop()
	main.player_settings.reduced_motion = false
	hub.configure(main._tournament_hub_snapshot(), false)
	_click(hub._machine_button)
	await create_timer(0.16).timeout
	main._leave_hub_shop()
	await create_timer(0.10).timeout
	main._open_hub_view("machine")
	await create_timer(0.85).timeout
	_expect(hub._machine_zoom == 1 and not hub._transitioning, "Reversing machine travel stranded the camera or panel.")
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	for message in errors: push_error(message)
	print("Hub machine focus smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func _click(control: Control) -> void:
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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		print("FAILED: ", message)

func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)
