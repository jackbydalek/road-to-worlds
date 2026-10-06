extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.run_state_service.save_path = "/tmp/top-cut-stock-refresh-%d.json" % OS.get_process_id()
	main.autosave_enabled = true
	main.player_settings.reduced_motion = true
	main.rng.seed = 92731
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 9876)
	main.run.money = 30
	main._show_tournament_hub()
	main.run.hub_shop.remove_purchased = true
	main.run.hub_shop.upgrade_purchased = true
	main.run.hub_break_used = true
	main.run.hub_break_choice = "heal"
	var initial_run: Dictionary = main.run.duplicate(true)
	# Stock refresh alone must not reset either service before round advancement.
	main.run.hub_shop.inventory = []
	for round_number in range(1, 5):
		var old_stock: Array = main.run.hub_shop.inventory.duplicate()
		var node: Dictionary = main._hub_round_node(round_number)
		main.run.pending_route_node = node
		main.run.route_battle = {"active": true, "node_id": node.id, "node_type": node.type, "seed": 100 + round_number, "label": "Rival %d" % round_number, "opponent_affinity": "sweet"}
		main.run.kitchen_match_result = {"turn": 7 + round_number}
		main._finish_route_battle(true, 40 - round_number * 2)
		_expect(main.run.route_round_results.size() == round_number, "The recap did not record exactly one result per win.")
		var result: Dictionary = main.run.route_round_results.back()
		_expect(int(result.round) == round_number and result.opponent_name == "Rival %d" % round_number and bool(result.won) and int(result.turn) == 7 + round_number, "The recap lost the actual rival, round, or match duration.")
		var new_stock: Array = main.run.hub_shop.inventory.duplicate()
		_expect(new_stock.size() == 4 and new_stock != old_stock, "Win %d did not replace the four shop offers." % round_number)
		_expect(bool(main.run.hub_shop.remove_purchased) and bool(main.run.hub_shop.upgrade_purchased) and bool(main.run.hub_break_used), "Restocking reset a service before the next round.")
		for card_id in new_stock:
			_expect(main.shop_economy_service.card_is_starter_eligible(main.cards_by_id[card_id], "spicy"), "Restock offered a card outside the starter ecosystem.")
		var victory_save: Dictionary = main.run_state_service.load_run()
		_expect(bool(victory_save.get("ok", false)) and victory_save.get("run", {}).get("hub_shop", {}).get("inventory", []) == new_stock, "Victory autosave did not persist the fresh stock.")
		_expect(_history_matches(victory_save.get("run", {}).get("route_round_results", []), main.run.route_round_results), "Victory autosave lost the match history.")
		# Duplicate result callbacks must not create another restock/reward.
		var offers: Array = main.run.reward_offer.duplicate()
		main._finish_route_battle(true, 1)
		_expect(main.run.hub_shop.inventory == new_stock and main.run.reward_offer == offers and int(main.run.life) == 40 - round_number * 2, "Duplicate victory callback processed the win again.")
		_expect(main.run.route_round_results.size() == round_number, "A duplicate victory callback added another recap row.")
		for unused in range(5):
			await process_frame
		main._finish_route_reward()
		for unused in range(3):
			await process_frame
		_expect(main.run.hub_shop.inventory == new_stock, "Completing the reward rerolled the shop a second time.")
		var expected_cash := 8 if node.type == "final_boss" else 5 if node.type == "mini_boss" else 2
		_expect(int(main.run.route_round_results.back().get("cash", 0)) == expected_cash, "The recap did not record the awarded cash.")
		if round_number == 4:
			_expect(not bool(main.run.demo_complete) and String(main.run.get("week_transition", "")) == "deckbox", "The first weekly championship did not lead to deckbox selection.")
			_expect(bool(main.run.hub_shop.remove_purchased) and bool(main.run.hub_shop.upgrade_purchased), "The final win refreshed services without starting another round.")
			continue
		_expect(int(main.run.hub_round) == round_number + 1 and not bool(main.run.hub_shop.remove_purchased), "Advancing to round %d did not refresh card removal." % (round_number + 1))
		_expect(bool(main.run.hub_shop.upgrade_purchased) and bool(main.run.hub_break_used), "Advancing a round restored the floor's upgrade or bye.")
		var next_round_save: Dictionary = main.run_state_service.load_run()
		var saved_shop: Dictionary = next_round_save.get("run", {}).get("hub_shop", {})
		_expect(not bool(saved_shop.get("remove_purchased", true)) and bool(saved_shop.get("upgrade_purchased", false)), "The next-round autosave lost the different service limits.")
		main._open_hub_shop()
		_expect(main.run.pending_route_node.inventory == new_stock, "Opening the shop changed its fresh offers.")
		if round_number == 1:
			main._route_shop_buy_card(String(new_stock[0]))
			new_stock.remove_at(0)
			_expect(main.run.pending_route_node.inventory == new_stock, "Purchasing refreshed all the shop cards.")
		main._open_hub_seller()
		var hub = main.find_child("TournamentHub", true, false)
		_expect(not hub._remove_button.disabled and hub._seller_upgrade_button.disabled, "The seller did not enable only removal for the new round.")
		var remove_id: String = main.run.deck.keys()[0]
		var copies_before := int(main.run.deck[remove_id])
		var money_before := int(main.run.money)
		main._route_remove_card(remove_id)
		_expect(int(main.run.deck.get(remove_id, 0)) == copies_before - 1 and int(main.run.money) == money_before - 3, "The new round's removal did not remove exactly one copy for $3.")
		main._route_remove_card(remove_id)
		main._finish_route_battle(true, 1)
		_expect(int(main.run.deck.get(remove_id, 0)) == copies_before - 1 and int(main.run.money) == money_before - 3 and bool(main.run.hub_shop.remove_purchased), "Repeat removal or a stale victory callback bypassed the round limit.")
		main._leave_hub_shop()
		main._open_hub_seller()
		_expect(hub._remove_button.disabled and hub._seller_upgrade_button.disabled, "Revisiting the seller restored a spent service in the same round.")
		main._leave_hub_shop()
		var saved: Dictionary = main.run_state_service.load_run()
		main.run = saved.run
		main._resume_loaded_screen(String(saved.resume_screen))
		for unused in range(3):
			await process_frame
		_expect(main.run.hub_shop.inventory == new_stock and bool(main.run.hub_shop.remove_purchased) and bool(main.run.hub_shop.upgrade_purchased), "Reload changed stock or restored a paid service.")
		for index in range(new_stock.size()):
			var face := main.find_child("HubDisplayCard%d" % index, true, false)
			_expect(face != null and face.get_meta("card_id") == new_stock[index], "The room display did not show saved restocked cards.")

	main.run = initial_run
	var loss_stock: Array = main.run.hub_shop.inventory.duplicate()
	main.run.pending_route_node = main._hub_round_node(1)
	main.run.route_battle = {"active": true, "node_type": "enemy", "seed": 555}
	main._finish_route_battle(false, 0)
	_expect(main.run.hub_shop.inventory == loss_stock, "Losing refreshed the shop.")
	_expect(bool(main.run.hub_shop.remove_purchased) and bool(main.run.hub_shop.upgrade_purchased), "Losing refreshed a paid service.")
	_expect(main.run.route_round_results.size() == 1 and not bool(main.run.route_round_results[0].won), "The recap did not record the final loss.")
	var loss_save: Dictionary = main.run_state_service.load_run()
	_expect(_history_matches(loss_save.get("run", {}).get("route_round_results", []), main.run.route_round_results), "The ended run did not persist its final match.")
	main.autosave_enabled = false
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = main.run_state_service.save_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Hub shop refresh smoke test passed.")
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _history_matches(saved: Array, expected: Array) -> bool:
	# JSON numbers load as floats; compare the recorded values independently of
	# their in-memory numeric type.
	if saved.size() != expected.size():
		return false
	for index in range(expected.size()):
		for key in expected[index]:
			if not saved[index].has(key) or saved[index][key] != expected[index][key]:
				return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
