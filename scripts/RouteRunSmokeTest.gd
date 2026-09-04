extends SceneTree


func _initialize() -> void:
	var content_script := load("res://scripts/ContentCatalog.gd")
	var route_script := load("res://scripts/RouteRunService.gd")
	var combat_script := load("res://scripts/cooking/CookingCombatService.gd")
	var catalog = content_script.new()
	catalog.load_all()
	var service = route_script.new()
	service.setup(catalog.cards, catalog.cards_by_id)
	var starter: Dictionary = catalog.deck_entries_to_dict(catalog.archetypes_by_id.spicy.starterDeck)
	var run := {"deck": starter, "collection": starter.duplicate(true), "starter": "spicy"}
	service.initialize_run(run, 424242)
	_expect(service.deck_total(run.deck) == 15, "Route starters must be compact 15-card decks.")
	_expect(int(run.life) == 40 and int(run.max_life) == 40, "Route health was not initialized to 40.")
	var regular: Array[String] = service.generate_reward_offer("spicy", "enemy", 41)
	var miniboss: Array[String] = service.generate_reward_offer("spicy", "mini_boss", 42)
	var boss: Array[String] = service.generate_reward_offer("spicy", "final_boss", 43)
	_expect(regular.size() == 3 and service.reward_pick_count("enemy") == 3, "Regular encounters must reveal three cards and allow taking all three.")
	_expect(miniboss.size() == 5 and service.reward_pick_count("mini_boss") == 5, "Miniboss encounters must reveal five cards and allow taking all five.")
	_expect(boss.size() == 8 and service.reward_pick_count("final_boss") == 8, "Boss encounters must reveal eight cards and allow taking all eight.")
	for starter_affinity in ["spicy", "sweet", "hearty"]:
		for node_type in ["enemy", "mini_boss", "final_boss"]:
			for card_id in service.generate_reward_offer(starter_affinity, node_type, 101):
				_expect(service.card_is_starter_eligible(catalog.cards_by_id[card_id], starter_affinity), "%s reward offered an out-of-pool card: %s." % [starter_affinity.capitalize(), card_id])
	_expect(service.card_is_starter_eligible(catalog.cards_by_id["fresh_spicy_yolke_bowl"], "spicy"), "Spicy runs must be able to receive Spicy + Fresh dual cards.")
	_expect(not service.card_is_starter_eligible(catalog.cards_by_id["hearty_dumpling_tortoise"], "spicy"), "Spicy runs must not receive Hearty + Fresh dual cards.")

	var combat = combat_script.new()
	combat.load_content()
	var state: Dictionary = combat.start_game(
		"spicy_test_kitchen", "hearty_test_kitchen", 77, "player", true, "easy",
		{"player_life": 40, "player_max_life": 40, "opponent_life": 12, "opponent_max_life": 12, "turn_hand_floor": 3, "reshuffle_pressure": true, "reshuffle_damage": [3, 5, 7]}
	)
	_expect(int(state.player.life) == 40 and int(state.opponent.life) == 12, "Encounter-specific life was not applied.")
	state.player.deck = []
	state.player.hand = []
	state.player.discard = ["spicy_hot_honey_bee"]
	combat._draw(state, "player")
	_expect(int(state.player.life) == 37 and int(state.player.fatigue) == 1, "First reshuffle must deal three pressure damage.")
	_expect(state.player.hand.size() == 1 and state.player.discard.is_empty(), "Reshuffle did not recycle the discard pile.")
	print("ROUTE_RUN_SMOKE_TEST_OK")
	quit(0 if _errors.is_empty() else 1)


var _errors: Array[String] = []


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error(message)
