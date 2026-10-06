extends "res://scripts/cooking/RouteCampaignSimulation.gd"
## Four-round diagnostic, using the actual hub seeds, opponent deck builder,
## card catalog and combat AI. Acquisition is a heuristic, not human play.

const FOOD := preload("res://scripts/FoodPrototype.gd")
var main
var policy := "value"
var focus_affinity := ""
var tuning := "full"


func _run() -> void:
	var count := 12
	var seed_base := 920100
	var output := "/private/tmp/food-prototype-simulation.json"
	var modes := ["prototype", "standard"]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			count = maxi(1, int(argument.trim_prefix("--runs=")))
		elif argument.begins_with("--seed="):
			seed_base = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument.begins_with("--mode="):
			modes = [argument.trim_prefix("--mode=")]
		elif argument.begins_with("--policy="):
			policy = argument.trim_prefix("--policy=")
		elif argument.begins_with("--tuning="):
			tuning = argument.trim_prefix("--tuning=")
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.autosave_enabled = false
	main.ui_sound_controller.enabled = false
	main.player_settings.reduced_motion = true
	var results: Array = []
	for mode in modes:
		main._set_food_prototype_mode(mode == "prototype")
		catalog = main.content_catalog
		route_service = main.route_run_service
		shop_service = main.shop_economy_service
		combat_service = COMBAT_SCRIPT.new()
		combat_service.load_content()
		combat_service.cards_by_id.merge(catalog.cards_by_id.duplicate(true), true)
		var wins := 0
		var reached := [0, 0, 0, 0]
		for index in range(count):
			var seed_value := seed_base + index
			if mode == "prototype":
				main._start_food_prototype(seed_value)
				if tuning == "legacy":
					main.run.food_balance = {"encounters": {}, "synergy_rewards": false}
				elif tuning == "encounters":
					main.run.food_balance.synergy_rewards = false
				var opening: Array = main.run.food_opening_offer.duplicate()
				focus_affinity = ""
				_sort_cards(opening)
				focus_affinity = String(catalog.cards_by_id[opening[0]].archetype)
				main._choose_food_prototype_opening(String(opening[0]))
			else:
				main.rng.seed = seed_value
				var starter := String(["spicy", "hearty", "sweet"][index % 3])
				var deck: Dictionary = catalog.deck_entries_to_dict(catalog.archetypes_by_id[starter].starterDeck)
				main.run = main.run_state_service.create_run(starter, deck, "spicy", "season", "white")
				route_service.initialize_run(main.run, seed_value)
				main.run.demo_weeks = 1
				focus_affinity = starter
				main._generate_shop_inventory()
				main._ensure_hub_shop()
			await process_frame
			var run: Dictionary = main.run
			var battles: Array = []
			for round_number in range(1, 5):
				run.hub_round = round_number
				reached[round_number - 1] += 1
				_shop(run)
				var battle := _battle(run, round_number)
				battles.append(battle)
				if not bool(battle.won):
					break
				main._ensure_hub_shop(true)
				var node_type := String(main._hub_round_node(round_number).type)
				run.money += 8 if round_number == 4 else 5 if round_number == 3 else 2
				var offers: Array = route_service.generate_reward_offer(String(run.starter), node_type, int(battle.seed) + 97, [], run)
				battle.reward_offer = offers.duplicate()
				_sort_cards(offers)
				battle.picks = []
				for id in offers.slice(0, mini(2, offers.size())):
					run.deck[id] = int(run.deck.get(id, 0)) + 1
					run.collection[id] = int(run.collection.get(id, 0)) + 1
					battle.picks.append(id)
				if round_number == 4:
					wins += 1
			results.append({"mode": mode, "policy": policy, "tuning": tuning, "seed": seed_value, "opening": run.get("food_opening_pick", ""), "battles": battles, "deck": run.deck.duplicate(true), "life": run.life})
			print("%s seed %d: %d wins, %d life, %d cards" % [mode, seed_value, battles.filter(func(b): return b.won).size(), run.life, route_service.deck_total(run.deck)])
		print("SUMMARY %s %s: %d/%d complete; reached rounds %s" % [mode, policy, wins, count, str(reached)])
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"policy": policy, "tuning": tuning, "player_ai": "hard", "acquisition": "Two highest-scored rewards; up to two affordable shop cards; one bye upgrade or heal; no paid rerolls/removals.", "results": results}, "\t"))
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	quit(0)


func _sort_cards(ids: Array) -> void:
	ids.sort_custom(func(a, b): return _score(String(a)) > _score(String(b)))


func _score(id: String) -> float:
	var score := _card_score(id, "")
	if policy == "affinity" and String(catalog.cards_by_id[id].archetype) == focus_affinity:
		score += 5.0
	if policy == "synergy":
		var best_connection := 0.0
		for package in FOOD.config().get("reward_packages", {}).values():
			for role in ["enablers", "payoffs"]:
				if not package[role].has(id):
					continue
				var opposite := "payoffs" if role == "enablers" else "enablers"
				var partners := 0
				for partner in package[opposite]:
					partners += mini(2, int(main.run.deck.get(partner, 0)))
				best_connection = maxf(best_connection, float(mini(2, partners)) * 6.0)
		score += best_connection
	return score


func _shop(run: Dictionary) -> void:
	var inventory: Array = run.hub_shop.inventory.duplicate()
	_sort_cards(inventory)
	var bought := 0
	for id in inventory:
		if bought >= 2:
			break
		var price: int = shop_service.card_price(run, id)
		if price <= int(run.money):
			run.money -= price
			run.deck[id] = int(run.deck.get(id, 0)) + 1
			run.collection[id] = int(run.collection.get(id, 0)) + 1
			bought += 1
	if not run.hub_break_used:
		if int(run.life) <= 30:
			run.life = mini(int(run.max_life), int(run.life) + 5)
			run.hub_break_used = true
		elif int(run.hub_round) >= 2:
			var candidates: Array = route_service.upgradeable_card_ids(run)
			_sort_cards(candidates)
			if not candidates.is_empty():
				route_service.upgrade_card(run, candidates[0])
				run.hub_break_used = true


func _battle(run: Dictionary, round_number: int) -> Dictionary:
	var node: Dictionary = main._hub_round_node(round_number)
	var seed_value := int(run.route_seed) ^ hash(String(node.id))
	var affinity := String(main.ARCHETYPE_ORDER[posmod(seed_value, main.ARCHETYPE_ORDER.size())])
	if affinity == String(run.starter):
		affinity = main._predator_archetype(affinity)
	var opponent_ai: String = route_service.encounter_ai(String(node.type))
	var settings := FOOD.encounter_settings(run, String(node.type))
	var battle := {"opponent_affinity": affinity, "ai": opponent_ai}
	if settings.has("deck_upgrades"):
		battle.deck_upgrades = settings.deck_upgrades
	var rival: Dictionary = main._route_rival_deck(battle)
	var prepared: Dictionary = route_service.prepare_player_combat_deck(run, run.deck)
	combat_service.cards_by_id.merge(prepared.cards, true)
	combat_service.decks["food_sim_player"] = {"name": "Player", "archetype": "", "cards": prepared.deck}
	combat_service.decks["food_sim_rival"] = {"name": "Rival", "archetype": "", "cards": rival}
	var life: int = int(settings.get("life", route_service.encounter_life(String(node.type))))
	var state: Dictionary = combat_service.start_game("food_sim_player", "food_sim_rival", seed_value, "player", false, opponent_ai, {"player_life": run.life, "player_max_life": 40, "opponent_life": life, "opponent_max_life": life, "turn_hand_floor": 3, "reshuffle_pressure": true, "reshuffle_damage": [3, 5, 7], "special_serve_enabled": false})
	while not state.game_over and int(state.turn) <= 100:
		state.ai_difficulty = "hard"
		_run_production_ai_turn(state, "player")
		if state.game_over:
			break
		combat_service._start_turn(state, "opponent")
		if state.game_over:
			break
		state.ai_difficulty = opponent_ai
		_run_production_ai_turn(state, "opponent")
		if state.game_over:
			break
		state.turn += 1
		combat_service._start_turn(state, "player")
	run.life = maxi(0, int(state.player.life))
	return {"round": round_number, "seed": seed_value, "affinity": affinity, "opponent_life": life, "opponent_deck": rival, "player_deck": run.deck.duplicate(true), "won": state.game_over and state.winner == "player", "turns": state.turn, "life": run.life, "capped": not state.game_over, "reshuffles": state.player.get("fatigue", 0), "log": state.log}
