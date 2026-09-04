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

	var starter_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter_deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 424242)
	main.run.life = 25
	main._generate_shop_inventory()
	main._show_tournament_hub()
	await process_frame
	await process_frame

	_expect(main.current_screen == "route_hub", "A route run did not enter the tournament hub.")
	_expect(main.find_child("TournamentHub", true, false) != null, "The hub screen was not mounted in the live Main scene.")
	_expect(main.find_child("ShopKiosk", true, false) != null, "The card shop kiosk is missing from the hub.")
	_expect(main.find_child("VendingMachine", true, false) != null, "The break vending machine is missing from the hub.")
	_expect(main.find_child("MatchTable", true, false) != null, "The background players and match table are missing from the hub.")
	_expect(main.find_child("HubDeckLabel", true, false) != null and "LOCKED DECK" in (main.find_child("HubDeckLabel", true, false) as Label).text, "The persistent deck was not presented as locked.")

	var shop_button := main.find_child("HubShopButton", true, false) as Button
	_expect(shop_button != null and not shop_button.disabled, "The shop kiosk is not interactive.")
	shop_button.emit_signal("pressed")
	await process_frame
	await process_frame
	var services := main.find_child("RouteShopServicesPanel", true, false) as Control
	var leave_shop := main.find_child("RouteShopContinueButton", true, false) as Button
	_expect(main.current_screen == "route_shop", "The hub kiosk did not open the real card shop.")
	_expect(services != null and not services.visible, "The hub shop exposed heal/remove/upgrade services despite the locked-deck rules.")
	_expect(leave_shop != null and leave_shop.text == "Back to Player Area", "The hub shop did not provide a return to the player area.")
	leave_shop.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_hub", "Leaving the kiosk did not return to the tournament hub.")
	_expect(bool(main.run.get("hub_shop", {}).get("hub_shop", false)), "The kiosk visit state was not persisted on the run.")

	var heal_button := main.find_child("HubVendingHealButton", true, false) as Button
	_expect(heal_button != null and not heal_button.disabled, "The heal option should be available while life is missing.")
	heal_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(int(main.run.life) == 33, "The vending machine did not restore exactly 8 life.")
	_expect(bool(main.run.hub_break_used) and String(main.run.hub_break_choice) == "heal", "Healing did not consume the floor's single break.")
	var out_of_order := main.find_child("HubVendingOutOfOrder", true, false) as Control
	_expect(out_of_order != null and out_of_order.visible, "A used vending machine did not switch to OUT OF ORDER.")
	var repeated_heal: Dictionary = main.route_run_service.use_hub_break_heal(main.run)
	_expect(not bool(repeated_heal.get("ok", false)) and int(main.run.life) == 33, "The break machine could be used twice on one floor.")

	# Test the alternate free upgrade choice on a fresh break state. Cancelling and
	# selecting are UI concerns; the service only consumes the break on success.
	main.run.hub_break_used = false
	main.run.hub_break_choice = ""
	var upgrade_id := String(main.route_run_service.upgradeable_card_ids(main.run)[0])
	main._show_tournament_hub()
	await process_frame
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
	var next_round := main.find_child("HubNextRoundButton", true, false) as Button
	_expect(next_round != null and not next_round.disabled, "NEXT ROUND is not available from the hub.")
	next_round.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(main.current_screen == "route_encounter_intro", "NEXT ROUND did not enter the existing battle-intro flow.")
	_expect(bool(main.run.pending_route_node.get("hub_round_node", false)), "NEXT ROUND did not create a tournament-round encounter.")
	_expect(int(main.run.pending_route_node.get("hub_round", 0)) == 1, "The first hub match used the wrong round number.")

	if DisplayServer.get_name() != "headless":
		main.run.pending_route_node = {}
		main.run.route_battle = {}
		main.run.life = 31
		main.run.hub_notice = "Choose the shop, use your one break, or report to the next round."
		main._show_tournament_hub()
		for unused in range(8):
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		_expect(image != null and image.save_png(ProjectSettings.globalize_path(PREVIEW_PATH)) == OK, "Could not capture the tournament hub preview.")

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
