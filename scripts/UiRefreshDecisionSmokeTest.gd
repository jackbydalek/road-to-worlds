extends SceneTree
const BODYGUARD := "sweet_soft_serve_crab"
var errors: Array[String] = []
var main

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await settle()
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.sweet.starterDeck)
	main.run = main.run_state_service.create_run("sweet", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 4700)
	main.run.deck[BODYGUARD] = 2
	main.run.collection = main.run.deck.duplicate(true)
	main.run.card_upgrades = {BODYGUARD: 1}
	main.run.money = 30
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1728, 1117), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for scale in [1.0, 1.25]:
			main.player_settings.text_scale = scale
			main._show_tournament_hub()
			main._show_hub_break_upgrade()
			await settle()
			main._select_route_shop_service_card("break_upgrade", BODYGUARD, 1)
			await settle()
			var before := main.find_child("RouteServiceBeforeCard", true, false) as Control
			var after := main.find_child("RouteServiceAfterCard", true, false) as Control
			var confirm := main.find_child("RouteUpgradeConfirmButton", true, false) as Button
			expect(before != null and after != null and not confirm.disabled, "No upgrade comparison")
			expect(int(before.get_meta("inspection_card").attack) == 1 and int(after.get_meta("inspection_card").attack) == 2, "Upgrade comparison shows incorrect copy stats")
			for control in [before, after, confirm, main.route_shop_service_overlay.back]:
				expect(root.get_visible_rect().encloses(control.get_global_rect()), "Service control clips at %s/%s" % [viewport_size, scale])
			var original: Dictionary = main.run.duplicate(true)
			key(KEY_ESCAPE)
			await settle()
			expect(main.route_shop_service_overlay == null and main.run.deck == original.deck and main.run.money == original.money and not main.run.hub_break_used, "Cancelling an upgrade changed run data")
	# Explicitly remove the upgraded physical copy while retaining its normal twin.
	main._show_tournament_hub()
	main._open_hub_shop()
	main._show_route_remove_card()
	await settle()
	main._select_route_shop_service_card("remove", BODYGUARD, 0)
	await settle()
	expect(main.find_child("RouteShopServiceSelectionInstruction", true, false).text == "1 upgraded copy", "Removal did not identify the upgraded copy")
	var count_before: int = main._deck_total(main.run.deck)
	var money_before: int = main.run.money
	main.find_child("RouteRemoveConfirmButton", true, false).pressed.emit()
	await settle()
	expect(main.run.deck[BODYGUARD] == 1 and main.route_run_service.upgrade_count(main.run, BODYGUARD) == 0, "Removal destroyed the normal twin or kept its upgrade")
	expect(main._deck_total(main.run.deck) == count_before - 1 and main.run.money == money_before - 3, "Removal charged or removed the wrong amount")
	expect(main.run.hub_shop.remove_purchased and not main.run.hub_break_used, "Removal did not consume the floor service independently of the bye")
	# Pure service path: removing a normal twin must retain its upgraded sibling.
	var copies: Dictionary = main.run.duplicate(true)
	copies.deck[BODYGUARD] = 2
	copies.card_upgrades = {BODYGUARD: 1}
	expect(main.route_run_service.remove_card(copies, BODYGUARD, 1, 1).ok and copies.card_upgrades[BODYGUARD] == 1, "Removing a normal copy removed an upgrade")
	var state_before := JSON.stringify(copies)
	expect(not main.route_run_service.remove_card(copies, BODYGUARD, 1, 99).ok and JSON.stringify(copies) == state_before, "Invalid copy removal mutated the deck")
	main._leave_hub_shop()
	main._show_tournament_hub()
	main._show_hub_break_upgrade()
	await settle()
	main._select_route_shop_service_card("break_upgrade", BODYGUARD, 0)
	main.find_child("RouteUpgradeConfirmButton", true, false).pressed.emit()
	await settle()
	expect(main.current_screen == "route_hub" and main.run.hub_break_used and main.route_run_service.upgrade_count(main.run, BODYGUARD) == 1, "Upgrade confirmation did not complete and consume the bye")
	expect(main.last_card_upgrade_animation_stages == ["focus", "white", "shine", "deck", "complete"], "Upgrade feedback did not use the shared ceremony")
	main._release_audio_streams()
	main.queue_free()
	await settle()
	for error in errors:
		push_error(error)
	print("UI decision smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func settle() -> void:
	for unused in range(8):
		await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)

func expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
