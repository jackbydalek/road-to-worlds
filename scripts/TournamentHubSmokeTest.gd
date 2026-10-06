extends SceneTree

const CONTENT_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const ROUTE_SCRIPT := preload("res://scripts/RouteRunService.gd")
const PREVIEW_PATH := "res://outputs/tournament_hub_greybox.png"

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.run_state_service.save_path = "/tmp/top-cut-hub-smoke-%d.json" % OS.get_process_id()
	main.player_settings.reduced_motion = true

	var starter_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter_deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 424242)
	main.run.life = 25
	main._generate_shop_inventory()
	main._show_tournament_hub()
	await process_frame
	await process_frame

	_expect(main.current_screen == "route_hub", "A route run did not enter the tournament hub.")
	var live_hub := main.find_child("TournamentHub", true, false) as Control
	_expect(live_hub != null, "The hub screen was not mounted in the live Main scene.")
	_expect(live_hub != null and live_hub.scene_file_path == "res://scenes/ui/TournamentHubScreen.tscn", "The live hub was not instantiated from the editable scene.")
	_expect(main.find_child("ShopKiosk", true, false) != null, "The card shop kiosk is missing from the hub.")
	var shop_desk := main.find_child("HubShopDesk", true, false) as Control
	_expect(shop_desk != null, "The supplied card-shop desk is missing from the hub.")
	_expect(shop_desk != null and shop_desk.size.x >= 490.0, "The shop desk is not large enough to anchor the center of the hub.")
	_expect(main.find_child("HubShopkeeper", true, false) != null, "The current shopkeeper is not seated behind the desk.")
	_expect(main.find_child("HubShopChair", true, false) != null, "The shopkeeper chair is missing behind the desk.")
	_expect(main.find_child("HubShopGlass", true, false) != null, "The card display is missing its glass layer.")
	for card_index in range(4):
		_expect(main.find_child("HubDisplayCard%d" % card_index, true, false) != null, "Display card %d is missing from the front of the desk." % card_index)
	var shop_kiosk := main.find_child("ShopKiosk", true, false) as Control
	var shopkeeper := main.find_child("HubShopkeeper", true, false) as Control
	var vending_machine := main.find_child("VendingMachine", true, false) as Control
	var background_match := main.find_child("BackgroundMatch", true, false) as Control
	var match_table := main.find_child("MatchTable", true, false) as Control
	_expect(vending_machine != null, "The break vending machine is missing from the hub.")
	_expect(background_match != null, "The movable background-match group is missing from the hub.")
	_expect(match_table != null, "The background players and match table are missing from the hub.")
	_expect(vending_machine != null and shop_kiosk != null and vending_machine.position.x >= shop_kiosk.position.x + shop_kiosk.size.x and vending_machine.position.x + vending_machine.size.x < 1280, "The vending cabinet is not fully visible beside the card case.")
	var shopkeeper_center_x := shop_kiosk.position.x + (shopkeeper.position.x + shopkeeper.size.x * 0.5) * shop_kiosk.scale.x if shop_kiosk != null and shopkeeper != null else -1000.0
	_expect(shopkeeper_center_x > 260.0 and shopkeeper_center_x < 500.0, "The shopkeeper should sit above the left-hand glass case.")
	_expect(background_match != null and not background_match.visible, "The old background table obscured the enlarged case.")
	for artwork_name in ["HubRoomArtwork", "HubShopDesk", "VendingMachineBody"]:
		var artwork := main.find_child(artwork_name, true, false) as Control
		_expect(artwork != null and artwork.get_script() != null and artwork.is_visible_in_tree(), "%s is missing its supplied production artwork." % artwork_name)
	_expect(main.find_child("HubDeckLabel", true, false) != null and "CARDS" in (main.find_child("HubDeckLabel", true, false) as Label).text.to_upper(), "The persistent deck was not presented as locked.")

	_expect(main.find_child("HubRivalA", true, false) == null and main.find_child("HubRivalB", true, false) == null, "The back-right people were not removed.")
	var displayed_inventory: Array = main.run.hub_shop.inventory.duplicate()
	for index in range(displayed_inventory.size()):
		var face := main.find_child("HubDisplayCard%d" % index, true, false)
		_expect(face.get_meta("card_id") == displayed_inventory[index], "Hub display does not match saved shop stock.")
	var desk_center_x := shop_kiosk.position.x + (shop_desk.position.x + shop_desk.size.x * 0.5) * shop_kiosk.scale.x
	_expect(absf(desk_center_x - shopkeeper_center_x) < shop_desk.size.x * 0.15, "The shopkeeper drifted away from the counter.")
	var shop_button := main.find_child("HubShopButton", true, false) as Button
	_expect(shop_button != null and not shop_button.disabled, "The shop kiosk is not interactive.")
	shop_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.run.pending_route_node.inventory == displayed_inventory, "Opening the shop rerolled the displayed stock.")
	var services := main.find_child("RouteShopServicesPanel", true, false) as Control
	var leave_shop := main.find_child("RouteShopContinueButton", true, false) as Button
	_expect(main.current_screen == "route_shop", "The hub kiosk did not open the real card shop.")
	_expect(services == null, "The old shop scene was mounted over the room.")
	_expect(main.find_child("RouteShopHealButton", true, false) == null and main.find_child("RouteShopUpgradeButton", true, false) == null, "Paid shop healing/upgrading should remain at the bye machine.")
	_expect(main.find_child("TournamentHub", true, false) == live_hub, "Browsing replaced the live hub instance.")
	_expect(live_hub._shop_open and is_equal_approx(live_hub._shop_zoom, 1.0), "Reduced-motion browsing did not arrive at the close-up immediately.")
	_expect((main.find_child("HubShopViewSwitchButton", true, false) as Button).visible, "The counter has no way to reach the seller's services.")
	_expect(leave_shop != null and leave_shop.text == "Back to shop", "The close-up did not provide a return to the shop overview.")
	leave_shop.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_hub", "Leaving the kiosk did not return to the tournament hub.")
	_expect(bool(main.run.get("hub_shop", {}).get("hub_shop", false)), "The kiosk visit state was not persisted on the run.")

	# Exercise the glass display with actual viewport input, as a player would.
	var display := main.find_child("HubShopDisplayWindow", true, false) as Control
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = display.get_global_rect().get_center()
	click.global_position = click.position
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_shop", "Clicking the displayed cards did not open the shop.")
	_expect(main.run.pending_route_node.get("inventory", []) == displayed_inventory, "Clicking the display rerolled its stock.")
	main._leave_hub_shop()
	await process_frame
	await process_frame

	# Save feedback must be visible in the hub; its legacy footer is hidden.
	(main.find_child("HubSaveButton", true, false) as Button).emit_signal("pressed")
	_expect((main.find_child("HubNoticeLabel", true, false) as Label).text == "Run saved.", "The hub did not show its save receipt.")
	var loaded: Dictionary = main.run_state_service.load_run()
	_expect(bool(loaded.get("ok", false)), "The hub's save button did not produce a loadable save.")
	(main.find_child("HubSettingsButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	_expect(main.current_screen == "settings", "Hub settings did not open.")
	(main.find_child("SettingsBackButton", true, false) as Button).emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_hub", "Closing Settings did not return to the hub.")
	_expect(main.run.hub_shop.inventory == displayed_inventory, "Returning from Settings changed shop stock.")


	main._open_hub_shop()
	main.run.money = 999
	var purchased_id := String(displayed_inventory[0])
	main._route_shop_buy_card(purchased_id)
	main._leave_hub_shop()
	await process_frame
	await process_frame
	_expect(not main.run.hub_shop.inventory.has(purchased_id), "Purchased stock returned to the hub display.")
	for index in range(main.run.hub_shop.inventory.size()):
		var face := main.find_child("HubDisplayCard%d" % index, true, false)
		_expect(face.get_meta("card_id") == main.run.hub_shop.inventory[index], "Display did not refresh after purchase.")
	var remaining_inventory: Array = main.run.hub_shop.inventory.duplicate()
	main.run.hub_shop.inventory = []
	main._show_tournament_hub()
	main._open_hub_shop()
	_expect(main.run.pending_route_node.inventory.is_empty(), "An empty shop restocked itself when opened.")
	main.run.pending_route_node.inventory = remaining_inventory
	main._leave_hub_shop()
	await process_frame
	await process_frame
	var heal_button := main.find_child("HubVendingHealButton", true, false) as Button
	(main.find_child("HubMachineButton", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	live_hub = main.find_child("TournamentHub", true, false) as Control
	live_hub._snack_view.select_snack("heal")
	_expect(heal_button != null and not heal_button.disabled, "The heal option should be available while life is missing.")
	heal_button.grab_focus()
	heal_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(int(main.run.life) == 30, "The vending machine did not restore exactly 5 life.")
	_expect(bool(main.run.hub_break_used) and String(main.run.hub_break_choice) == "heal", "Healing did not consume the floor's single break.")
	var out_of_order := main.find_child("HubVendingOutOfOrder", true, false) as Control
	_expect(out_of_order != null and out_of_order.visible, "A used vending machine did not switch to OUT OF ORDER.")
	_expect(root.gui_get_focus_owner() == main.find_child("RouteShopContinueButton", true, false), "Consuming the focused bye action did not move keyboard focus to Back to shop.")
	var repeated_heal: Dictionary = main.route_run_service.use_hub_break_heal(main.run)
	_expect(not bool(repeated_heal.get("ok", false)) and int(main.run.life) == 30, "The break machine could be used twice on one floor.")
	var saved_hub: Dictionary = JSON.parse_string(JSON.stringify(main.run))
	main.run = saved_hub
	main._show_tournament_hub()
	await process_frame
	_expect((main.find_child("HubVendingOutOfOrder", true, false) as Control).visible, "Restoring run data refreshed the used bye.")
	_expect(main.run.hub_shop.inventory == remaining_inventory, "Shop stock changed after restoring run data.")

	# Test the alternate free upgrade choice on a fresh break state. Cancelling and
	# selecting are UI concerns; the service only consumes the break on success.
	main.run.hub_break_used = false
	main.run.hub_break_choice = ""
	var upgrade_id := String(main.route_run_service.upgradeable_card_ids(main.run)[0])
	main._show_tournament_hub()
	await process_frame
	live_hub = main.find_child("TournamentHub", true, false) as Control
	live_hub._snack_view.select_snack("upgrade")
	main._show_hub_break_upgrade()
	await process_frame
	_expect(main.current_screen == "route_break_upgrade", "The vending upgrade option did not open the card picker.")
	main._close_route_shop_service_overlay()
	await process_frame
	_expect(not bool(main.run.hub_break_used), "Cancelling the card picker consumed the floor's break.")
	main._show_hub_break_upgrade()
	await process_frame
	main._select_route_shop_service_card("break_upgrade", upgrade_id)
	main._confirm_route_shop_service_selection("break_upgrade")
	for unused in range(5):
		await process_frame
	_expect(main.route_run_service.upgrade_count(main.run, upgrade_id) == 1, "The free break upgrade was not persisted.")
	_expect(bool(main.run.hub_break_used) and String(main.run.hub_break_choice) == "upgrade", "Upgrading did not consume the single break.")

	main.run.hub_break_used = false
	main.run.hub_break_choice = ""
	main._show_tournament_hub()
	await process_frame
	(main.find_child("RouteShopContinueButton", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	var next_round := main.find_child("HubNextRoundButton", true, false) as Button
	_expect(next_round != null and next_round.is_visible_in_tree() and not next_round.disabled, "NEXT ROUND is not available from the shop overview.")
	next_round.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_encounter_intro", "NEXT ROUND did not enter the existing battle-intro flow.")
	_expect(bool(main.run.pending_route_node.get("hub_round_node", false)), "NEXT ROUND did not create a tournament-round encounter.")
	_expect(int(main.run.pending_route_node.get("hub_round", 0)) == 1, "The first hub match used the wrong round number.")

	# Full life keeps packets inspectable, but excludes the unavailable heal action.
	main.run.pending_route_node = {}
	main.run.route_battle = {}
	main.run.life = main.run.max_life
	main._show_tournament_hub()
	await process_frame
	await process_frame
	heal_button = main.find_child("HubVendingHealButton", true, false) as Button
	shop_button = main.find_child("HubShopButton", true, false) as Button
	var seller_button := main.find_child("HubSellerButton", true, false) as Button
	var machine_button := main.find_child("HubMachineButton", true, false) as Button
	_expect(seller_button.get_node(seller_button.focus_next) == shop_button and shop_button.get_node(shop_button.focus_next) == machine_button, "Overview keyboard focus did not connect the three shop destinations.")
	machine_button.pressed.emit()
	await process_frame
	await process_frame
	live_hub = main.find_child("TournamentHub", true, false) as Control
	live_hub._snack_view.select_snack("heal")
	_expect(heal_button.disabled and heal_button.tooltip_text.contains("already full"), "Full health still offers healing or lost its explanation.")
	leave_shop = main.find_child("RouteShopContinueButton", true, false) as Button
	_expect(leave_shop.get_node(leave_shop.focus_next).name == "HubVendingSnackButton_heal" and not live_hub._snack_view.focus_controls().has(heal_button), "Machine keyboard focus lost snack inspection or includes unavailable healing.")
	main.run.life = 31
	main._show_tournament_hub()
	for unused in range(3):
		await process_frame
	heal_button = main.find_child("HubVendingHealButton", true, false) as Button
	live_hub = main.find_child("TournamentHub", true, false) as Control
	live_hub._snack_view.clear_selection()
	live_hub._snack_view.select_snack("heal")
	_expect(not heal_button.disabled and heal_button.get_theme_color("font_color").is_equal_approx(main.PALETTE.PEACH_PAPER), "Re-enabled healing retained faded disabled text.")
	live_hub = main.find_child("TournamentHub", true, false) as Control
	for layer_name in ["HubBackLayer", "HubMidLayer", "HubFrontLayer"]:
		var layer := live_hub.find_child(layer_name, true, false) as Node2D
		_expect(layer.position.is_zero_approx(), "Reduced motion left parallax movement on %s." % layer_name)


	if DisplayServer.get_name() != "headless":
		main.run.pending_route_node = {}
		main.run.route_battle = {}
		main.run.life = 31
		main.run.money = 12
		main.run.hub_notice = "Prepare for your next match. Your life and deck carry into every round."
		main._show_tournament_hub()
		for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1440, 900)]:
			root.size = viewport_size
			for unused in range(12):
				await process_frame
			RenderingServer.force_draw(false)
			await process_frame
			var viewport_rect := root.get_visible_rect()
			for button_name in ["HubNextRoundButton", "HubShopButton", "HubSellerButton", "HubMachineButton", "HubSaveButton", "HubSettingsButton"]:
				var button := main.find_child(button_name, true, false) as Button
				var button_rect := button.get_global_rect()
				_expect(viewport_rect.encloses(button_rect), "%s is clipped at %s." % [button_name, viewport_size])
				_expect(button_rect.size.y * viewport_size.y / viewport_rect.size.y >= 44.0, "%s is too small at %s." % [button_name, viewport_size])
			var hud := main.find_child("HubTopBar", true, false) as Control
			var action_bar := main.find_child("HubActionBar", true, false) as Control
			_expect(viewport_rect.encloses(hud.get_global_rect()), "The compact painted status group is clipped.")
			_expect(not action_bar.visible and not main.find_child("HubRoundBoard", true, false).visible, "The retired footer or duplicate tournament board still covers the room.")
			var next_button := main.find_child("HubNextRoundButton", true, false) as Button
			_expect(next_button.get_node(next_button.focus_next).name == "HubDeckButton", "Keyboard order does not connect the primary action to the live deck.")
			var preview := root.get_viewport().get_texture().get_image()
			var capture_path := "res://outputs/tournament_hub_%dx%d.png" % [viewport_size.x, viewport_size.y]
			_expect(preview.save_png(ProjectSettings.globalize_path(capture_path)) == OK, "Could not capture %s." % capture_path)
			if viewport_size == Vector2i(1440, 900):
				preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH))
		main.run.hub_round = 3
		main.run.hub_break_used = true
		main.run.hub_break_choice = "heal"
		main._show_tournament_hub()
		for unused in range(8):
			await process_frame
		_expect("DONE" in (main.find_child("HubRoundStep0", true, false) as Label).text, "Completed rounds are not marked on the tracker.")
		var progress := main.find_child("HubRoundProgress", true, false)
		_expect(progress.current_round == 3 and progress.bye_used, "Segmented tracker did not reflect round and bye state.")
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/tournament_hub_used_bye.png"))
		_expect(main.find_child("HubPlayerArtwork", true, false) == null, "Player character is still present in the hub.")

	for suffix in ["", ".bak", ".tmp"]:
		var temp_path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(temp_path)
	main.queue_free()
	await process_frame
	if _errors.is_empty():
		print("Tournament hub smoke test passed.")
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
