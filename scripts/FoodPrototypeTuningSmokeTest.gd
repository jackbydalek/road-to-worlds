extends SceneTree

const FOOD := preload("res://scripts/FoodPrototype.gd")
const CATALOG := preload("res://scripts/ContentCatalog.gd")
const ROUTE := preload("res://scripts/RouteRunService.gd")
var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := CATALOG.new()
	catalog.load_all()
	FOOD.apply_catalog(catalog)
	var service := ROUTE.new()
	service.setup(catalog.cards, catalog.cards_by_id)
	var run := {"starter": FOOD.ID, "deck": FOOD.starter_deck(), "collection": {}, "money": 8}
	service.initialize_run(run, 801)
	FOOD.initialize(run, 801, catalog)
	_expect(FOOD.encounter_settings(run, "enemy").is_empty(), "Early encounter curve changed.")
	_expect(int(FOOD.encounter_settings(run, "mini_boss").life) == 16 and int(FOOD.encounter_settings(run, "mini_boss").deck_upgrades) == 4, "Semifinal tuning missing.")
	_expect(int(FOOD.encounter_settings(run, "final_boss").life) == 22 and int(FOOD.encounter_settings(run, "final_boss").deck_upgrades) == 5, "Final tuning missing.")
	_expect(FOOD.encounter_settings({}, "final_boss").is_empty(), "Normal encounter changed.")
	var packages: Dictionary = FOOD.config().reward_packages
	for package in packages.values():
		for id in package.enablers + package.payoffs:
			_expect(catalog.cards_by_id.has(id), "Unknown package card " + id)
		for id in package.enablers:
			_expect(not package.payoffs.has(id), "A synergy pair can duplicate its card.")
	var wildcard_affinities := {}
	for package_key in packages:
		run.deck = FOOD.starter_deck()
		run.deck[String(packages[package_key].enablers[0])] = 1
		for seed_value in range(40):
			for node_type in ["enemy", "mini_boss", "final_boss"]:
				var offer := service.generate_reward_offer(FOOD.ID, node_type, seed_value, [], run)
				_expect(offer.size() == service.reward_pick_count(node_type), "Reward count changed.")
				_expect(offer == service.generate_reward_offer(FOOD.ID, node_type, seed_value, [], run), "Seeded offers are not deterministic.")
				_expect(_is_pair(offer, packages), "Missing compatible Ingredient and payoff pair.")
				var unique := {}
				for index in range(offer.size()):
					var id := offer[index]
					_expect(not unique.has(id), "Duplicate reward.")
					unique[id] = true
					_expect(FOOD.reward_card_eligible(catalog.cards_by_id[id], run, catalog.cards_by_id), "Ineligible reward.")
					if index >= 2:
						wildcard_affinities[String(catalog.cards_by_id[id].archetype)] = true
				var blocked := service.generate_reward_offer(FOOD.ID, node_type, seed_value, [offer[0], offer[1]], run)
				_expect(not blocked.has(offer[0]) and not blocked.has(offer[1]), "Reward exclusions were ignored.")
	for affinity in ["spicy", "sweet", "hearty", "fresh", "funky"]:
		_expect(wildcard_affinities.has(affinity), "Wildcard stopped offering " + affinity)
	run.deck = FOOD.starter_deck()
	_expect(not FOOD.reward_card_eligible(catalog.cards_by_id.item_spicy_shopping_list, run, catalog.cards_by_id), "Tutor with no target offered.")
	run.deck.spicy_jalapeno_jackal = 1
	_expect(FOOD.reward_card_eligible(catalog.cards_by_id.item_spicy_shopping_list, run, catalog.cards_by_id), "Usable tutor excluded.")
	_expect(not FOOD.reward_card_eligible(catalog.cards_by_id.item_grater, run, catalog.cards_by_id), "Spice removal offered in spice-free week.")
	for build in ["discard", "tokens"]:
		run.deck = {"funky_fondue_ferret": 2, "funky_bibimbear": 1, "spicy_ghost_pepper_python": 1} if build == "discard" else {"fresh_sprout_squirrel": 2, "fresh_comeback_corgi": 1, "fresh_crisp_capybara": 1, "fresh_saladmander": 1}
		for seed_value in range(20):
			var offer := service.generate_reward_offer(FOOD.ID, "enemy", seed_value, [], run)
			_expect(packages[build].enablers.has(offer[0]) and packages[build].payoffs.has(offer[1]), "Rewards did not follow the deck's current mechanics.")
	# The old prototype path and normal starter pools stay available unchanged.
	var standard_catalog := CATALOG.new()
	standard_catalog.load_all()
	var standard_service := ROUTE.new()
	standard_service.setup(standard_catalog.cards, standard_catalog.cards_by_id)
	for seed_value in range(40):
		for starter in ["spicy", "hearty", "sweet"]:
			_expect(service.generate_reward_offer(starter, "enemy", seed_value) == standard_service.generate_reward_offer(starter, "enemy", seed_value), "Normal reward generation changed.")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main._start_food_prototype(802)
	main._choose_food_prototype_opening(String(main.run.food_opening_offer[0]))
	await process_frame
	for round_number in [3, 4]:
		main.run.hub_round = round_number
		main.run.pending_route_node = main._hub_round_node(round_number)
		main.run.route_battle = {}
		main._start_route_battle()
		var battle: Dictionary = main.run.route_battle
		_expect(int(battle.opponent_life) == (16 if round_number == 3 else 22), "Live battle uses old rival life.")
		_expect(battle.ai == ("hard" if round_number == 3 else "expert"), "Late rival AI was weakened.")
		var deck: Dictionary = main._route_rival_deck(battle)
		var saved_battle: Dictionary = JSON.parse_string(JSON.stringify(battle))
		var expected: Dictionary = main.tournament_service.opponent_deck_for_round(main, String(battle.opponent_affinity), 1, {}, String(battle.ai), 4 if round_number == 3 else 5)
		for id in expected.keys():
			if not FOOD.WEEKLY.card_available(main.cards_by_id[id], main.run):
				expected.erase(id)
		_expect(deck == expected, "Live rival deck does not use the tuned upgrade count.")
		main.run.food_balance.encounters = {}
		_expect(_same_deck(main._route_rival_deck(saved_battle), deck), "Reload changed an already-called rival deck.")
		main.run.food_balance.encounters = FOOD.config().encounters.duplicate(true)
		main._begin_route_battle_from_intro()
		for unused in range(8):
			await process_frame
		var table = main.find_child("Tabletop3DPrototype", true, false)
		_expect(table != null, "Tuned battle failed to mount.")
		if table != null:
			_expect(int(table.state.opponent.life) == int(battle.opponent_life), "Combat did not receive tuned rival life.")
			_expect(table.state.ai_difficulty == battle.ai, "Combat did not receive the original AI tier.")
		main._clear_kitchen_match_state()
		main._show_run_map(false)
		for unused in range(4):
			await process_frame
	# Loading an older active battle keeps its existing life and deck tier.
	var old_battle := {"opponent_affinity": "spicy", "ai": "expert", "opponent_life": 28}
	var old_deck: Dictionary = main._route_rival_deck(old_battle)
	_expect(old_deck == main._opponent_deck_for_round("spicy", 1, {}, "expert"), "Old active prototype battle was silently retuned.")
	var path := "/private/tmp/food-prototype-reward-tuning-test.json"
	main.run_state_service.save_path = path
	main.run.reward_offer = service.generate_reward_offer(FOOD.ID, "enemy", 901, [], main.run)
	main.run.reward_selected = []
	main.run.reward_picks_remaining = 3
	main.run_state_service.save_run(main.run, "route_reward")
	var loaded: Dictionary = main.run_state_service.load_run()
	_expect(loaded.run.reward_offer == main.run.reward_offer and loaded.run.food_balance == main.run.food_balance, "Saved rewards or encounter settings changed on load.")
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	print("Food prototype tuning smoke test %s." % ("FAILED" if failed else "passed"))
	quit(1 if failed else 0)


func _is_pair(offer: Array, packages: Dictionary) -> bool:
	if offer.size() < 2:
		return false
	for package in packages.values():
		if package.enablers.has(offer[0]) and package.payoffs.has(offer[1]):
			return true
	return false


func _same_deck(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for id in a:
		if int(a[id]) != int(b.get(id, 0)):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
