extends SceneTree

## Real counter clicks, save/resume, and match/week reset integration.
## Service probability/content tests and native layout review run separately.
var main
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	main.autosave_enabled = false
	root.add_child(main)
	await _frames()
	main.run_state_service.save_path = "/private/tmp/hub-shop-reroll-%d.json" % OS.get_process_id()
	main.autosave_enabled = true
	main.player_settings.reduced_motion = true
	main.rng.seed = 92731
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 9876)
	main.run.life = 25
	main.run.money = 150
	main._show_tournament_hub()
	main.run.hub_shop.remove_purchased = true
	main.run.hub_shop.upgrade_purchased = true
	main.run.hub_break_used = true
	main.run.hub_break_choice = "heal"
	main._open_hub_shop()
	await _frames()
	_expect(_cost() == 5, "Fresh counter does not begin at $5.")
	for expected in [5, 6, 7]:
		await _paid_click(expected)
	await _check_guards()
	await _check_partial_and_empty()
	await _check_visits_and_reload()
	await _check_match_resets()
	await _check_new_week()
	main.autosave_enabled = false
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	main._release_audio_streams()
	main.queue_free()
	await _frames(2)
	for failure in failures:
		push_error(failure)
	print("Hub shop reroll smoke test: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _paid_click(expected: int) -> void:
	var button := _button()
	_expect(button != null and button.is_visible_in_tree() and not button.disabled, "Paid reroll control is unavailable at $%d." % expected)
	if button == null:
		return
	_expect(button.text.contains("$%d" % expected), "Reroll button does not display its current $%d price." % expected)
	var money: int = main.run.money
	var old_stock: Array = main.run.pending_route_node.inventory.duplicate()
	var protected := _protected_state()
	var hub = main.find_child("TournamentHub", true, false)
	_click(button)
	await _frames()
	_expect(int(main.run.money) == money - expected, "Reroll did not charge exactly $%d." % expected)
	_expect(_cost() == expected + 1, "Paid reroll did not raise the next price by $1.")
	_expect(_protected_state() == protected, "Reroll changed cards, health, upgrades, or a used service.")
	var stock: Array = main.run.pending_route_node.inventory
	_expect(stock.size() == 4 and stock != old_stock, "Reroll did not replace the counter with four offers.")
	for id in stock:
		_expect(not old_stock.has(id), "An old visible offer survived a full-stock reroll.")
	_expect(main.run.hub_shop.inventory == stock and main.run.shop == stock, "Rerolled stock is inconsistent between saved counter and current offers.")
	_expect(main.find_child("TournamentHub", true, false) == hub and hub._shop_zoom == 1.0, "Reroll rebuilt the room or left its counter close-up.")
	_expect((main.find_child("HubFundsLabel", true, false) as Label).text == "$%d" % int(main.run.money), "Visible funds did not reflect the reroll charge.")
	_expect(_button().text.contains("$%d" % (expected + 1)), "Visible reroll price did not update after payment.")
	var snapshot: Dictionary = main._tournament_hub_snapshot()
	_expect(int(snapshot.get("reroll_cost", -1)) == expected + 1 and bool(snapshot.get("can_reroll", false)), "Counter snapshot lost the new reroll price/availability.")
	var loaded: Dictionary = main.run_state_service.load_run()
	var saved: Dictionary = loaded.get("run", {})
	_expect(bool(loaded.get("ok", false)) and saved.get("hub_shop", {}).get("inventory", []) == stock and int(saved.get("money", -1)) == int(main.run.money), "Paid reroll was not autosaved with its funds and inventory.")
	_expect(int(main.shop_economy_service.shop_reroll_cost(saved.get("hub_shop", {}))) == expected + 1, "Autosave lost the increased reroll price.")

func _check_guards() -> void:
	var before := _economy_state()
	main._reroll_hub_shop(_cost() - 1)
	await _frames()
	_expect(_economy_state() == before, "A stale displayed price charged funds or rerolled stock.")
	main.route_shop_purchase_busy = true
	main._reroll_hub_shop(_cost())
	await _frames()
	_expect(_economy_state() == before, "A reroll ran during an active purchase animation.")
	main.route_shop_purchase_busy = false
	var money: int = main.run.money
	main.run.money = _cost() - 1
	main._show_hub_counter()
	await _frames()
	_expect(_button() != null and _button().disabled, "Unaffordable reroll remained enabled.")
	_expect(not bool(main._tournament_hub_snapshot().get("can_reroll", true)), "Unaffordable snapshot still permits reroll.")
	before = _economy_state()
	_button().pressed.emit()
	main._reroll_hub_shop(_cost())
	await _frames()
	_expect(_economy_state() == before, "Insufficient funds were accepted by UI or Main reroll handler.")
	main.run.money = money
	main._show_hub_counter()
	await _frames()

func _check_partial_and_empty() -> void:
	var count_before: int = main.run.pending_route_node.inventory.size()
	await _buy_first()
	_expect(main.run.pending_route_node.inventory.size() == count_before - 1, "Real purchase did not leave partial stock.")
	await _paid_click(_cost())
	for unused in 4:
		await _buy_first()
	_expect(main.run.pending_route_node.inventory.is_empty(), "Purchasing the four offers did not sell out the counter.")
	var empty_label := main.find_child("HubCounterEmptyLabel", true, false) as Label
	_expect(empty_label != null and empty_label.visible, "Sold-out counter lost its empty state.")
	await _paid_click(_cost())
	_expect(not empty_label.visible, "Paid restock did not remove the sold-out message.")

func _buy_first() -> void:
	var stock: Array = main.run.pending_route_node.inventory
	if stock.is_empty():
		_expect(false, "Purchase fixture has no stock.")
		return
	var id := String(stock[0])
	main._route_shop_buy_card(id)
	for unused in 100:
		if not main.route_shop_purchase_busy:
			break
		await process_frame
	await _frames()
	_expect(not main.route_shop_purchase_busy and not main.run.pending_route_node.inventory.has(id), "Purchase fixture did not settle/remove its offer.")

func _check_visits_and_reload() -> void:
	var before := _economy_state()
	main._leave_hub_shop()
	main._open_hub_shop()
	await _frames()
	_expect(_economy_state() == before, "Counter revisit reset reroll cost or stock.")
	(main.find_child("HubSettingsButton", true, false) as Button).pressed.emit()
	await _frames()
	(main.find_child("SettingsBackButton", true, false) as Button).pressed.emit()
	await _frames()
	_expect(main.current_screen == "route_shop" and _economy_state() == before, "Settings return reset paid reroll state or lost the counter.")
	main._save_run()
	main._load_run_from_disk()
	await _frames()
	_expect(main.current_screen == "route_shop" and _economy_state() == before, "Save/reload changed reroll stock, price, funds, or service limits.")
	_expect(_button() != null and _button().text.contains("$%d" % _cost()), "Reloaded counter shows a stale reroll price.")

func _check_match_resets() -> void:
	main._leave_hub_shop()
	var baseline: Dictionary = main.run.duplicate(true)
	for won in [true, false]:
		main.run = baseline.duplicate(true)
		var node: Dictionary = main._hub_round_node(1)
		main.run.pending_route_node = node
		main.run.route_battle = {"active": true, "node_id": node.id, "node_type": "enemy", "label": "Reroll Fixture Rival", "seed": 881}
		var old_stock: Array = main.run.hub_shop.inventory.duplicate()
		main._finish_route_battle(won, 22 if won else 0)
		await _frames()
		_expect(int(main.shop_economy_service.shop_reroll_cost(main.run.hub_shop)) == 5, "A real %s result did not reset the reroll price." % ("win" if won else "loss"))
		if not won:
			_expect(main.run.hub_shop.inventory == old_stock, "Loss unexpectedly refreshed counter stock.")
			main._finish_route_battle(false, 0)
			_expect(main.run.route_round_results.size() == 1, "Duplicate loss recorded another match result.")
			continue
		main._finish_route_reward()
		await _frames()
		main._open_hub_shop()
		await _frames()
		await _paid_click(5)
		var after_paid := _economy_state()
		main._finish_route_battle(true, 1)
		await _frames()
		_expect(_cost() == 6 and _economy_state() == after_paid, "A stale win callback reset a later paid reroll or repeated its reward.")
		_expect(main.run.route_round_results.size() == 1, "Duplicate win recorded another match result.")
	main.run = baseline
	main._show_tournament_hub()
	await _frames()

func _check_new_week() -> void:
	main.run.deckbox = main.route_run_service.weekly.deckbox("padded_picnic")
	main.run.week_transition = "week_intro"
	main._show_week_transition()
	await _frames()
	(main.find_child("WeeklyDemoContinue", true, false) as Button).pressed.emit()
	await _frames()
	_expect(int(main.run.week) == 2, "Week intro did not advance the real run.")
	main._finish_route_reward()
	await _frames()
	main._open_hub_shop()
	await _frames()
	_expect(main.current_screen == "route_shop" and _cost() == 5 and main.run.pending_route_node.inventory.size() == 4, "New week did not open with a fresh $5 counter.")

func _protected_state() -> Dictionary:
	var result := {}
	for key in ["deck", "collection", "card_upgrades", "life", "max_life", "hub_break_used", "hub_break_choice"]:
		result[key] = main.run.get(key)
	var shop: Dictionary = main.run.get("hub_shop", {})
	result.remove_purchased = shop.get("remove_purchased", false)
	result.upgrade_purchased = shop.get("upgrade_purchased", false)
	return result.duplicate(true)

func _economy_state() -> Dictionary:
	var result := _protected_state()
	result.money = int(main.run.money)
	result.stock = main.run.hub_shop.inventory.duplicate()
	result.price = int(main.shop_economy_service.shop_reroll_cost(main.run.hub_shop))
	# Compare the same JSON value types before and after a real disk round-trip.
	return JSON.parse_string(JSON.stringify(result))

func _cost() -> int:
	return int(main._tournament_hub_snapshot().get("reroll_cost", -1))

func _button() -> Button:
	return main.find_child("RouteShopRerollButton", true, false) as Button

func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _frames(count := 4) -> void:
	for unused in count:
		await process_frame

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
