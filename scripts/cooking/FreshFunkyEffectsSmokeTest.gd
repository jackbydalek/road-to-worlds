extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")

var service: RefCounted
var failed := false


func _init() -> void:
	service = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load the production card catalog.")
		return
	_test_card_costs_and_stats()
	_test_board_effects()
	_test_attack_and_protection_effects()
	_test_hand_responses()
	_test_stepwise_opponent_turn()
	_test_ai_difficulty_decisions()
	_test_all_starter_pairings_progress()
	if failed:
		quit(1)
	else:
		print("Fresh, Funky, and expansion effect smoke test passed.")
		quit(0)


func _test_card_costs_and_stats() -> void:
	_assert_card("spicy_chili_cicada", "ingredient", 1, 1)
	_assert_card("funky_beat_beetle", "ingredient", 1, 1)
	_assert_card("fresh_salad_shield_skunk", "ingredient", 1, 2)
	_assert_card("fresh_comeback_corgi", "ingredient", 1, 1)
	_assert_card("fresh_harvest_hydra", "meal", 2, 2)
	_assert_card("fresh_saladmander", "meal", 4, 5)
	_assert_card("funky_remix_raccoon", "meal", 4, 6)
	_assert_card("funky_leftover_lynx", "meal", 4, 6)
	_assert_card("sweet_bottomless_trifle_tern", "meal", 4, 5)
	_assert_card("funky_trap_jam_tapir", "meal", 3, 4)
	var hydra: Dictionary = service.card("fresh_harvest_hydra")
	_expect(hydra.get("recipe", []) == ["fresh"] and String(hydra.get("required_meal_archetype", "")) == "fresh", "Harvest Hydra does not require a Fresh Ingredient plus a Fresh Meal.")
	var tern: Dictionary = service.card("sweet_bottomless_trifle_tern")
	_expect(tern.get("recipe", []) == ["sweet"] and String(tern.get("required_meal_archetype", "")) == "sweet", "Bottomless Trifle Tern does not require a Sweet Ingredient plus a Sweet Meal.")
	_expect(service.card("funky_remix_raccoon").get("recipe", []).size() == 3, "Remix Raccoon is not a three-Ingredient Meal.")
	_expect(service.card("fresh_saladmander").get("recipe", []) == ["fresh"], "Saladmander is not the intended one-Ingredient Fresh Meal.")


func _test_board_effects() -> void:
	var state := _fresh_state()
	_add_unit(state, "player", "sweet_parfait_parrot", "plated")
	state.player.deck = ["item_wooden_spoon"]
	service._resolve_end_turn_triggers(state, "player")
	_expect(state.player.hand == ["item_wooden_spoon"], "Parfait Parrot did not draw at end of turn while Plated.")

	state = _fresh_state()
	var gravy := _add_unit(state, "player", "hearty_gravy_gazelle", "plated")
	service._resolve_activated_ability(state, int(gravy.instance_id), service.card("hearty_gravy_gazelle").abilities[0], int(gravy.instance_id))
	_expect(int(gravy.attack) == 4 and int(gravy.health) == 6 and int(gravy.max_health) == 6, "Gravy Gazelle did not grant +1/+1.")

	state = _fresh_state()
	var cicada := _add_unit(state, "player", "spicy_chili_cicada", "prep")
	var cicada_target := _add_unit(state, "opponent", "hearty_stewoose", "plated")
	cicada.health = 0
	service._remove_defeated(state, "player")
	service.choose_effect_target(state, int(cicada_target.instance_id))
	_expect(int(cicada_target.health) == 5, "Chili Cicada's KO trigger did not deal 3 damage.")

	state = _fresh_state()
	var hydra := _add_unit(state, "player", "fresh_harvest_hydra", "plated")
	hydra.served_sacrifice_attack = 4
	hydra.served_sacrifice_health = 5
	_add_unit(state, "player", "fresh_crisp_capybara", "prep")
	_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
	service._resolve_effects(state, "player", service.card("fresh_harvest_hydra").on_play, hydra)
	_expect(state.player.prep.is_empty() and int(hydra.attack) == 9 and int(hydra.health) == 12, "Harvest Hydra did not absorb its recipe Meal and the rest of the board.")

	state = _fresh_state()
	var gorilla := _add_unit(state, "player", "fresh_garden_gorilla", "plated")
	_add_unit(state, "player", "fresh_crisp_capybara", "prep")
	_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
	service._refresh_stat_auras(state)
	_expect(int(gorilla.attack) == 7, "Garden Gorilla did not gain +2 Attack per other Fresh card in Prep.")

	state = _fresh_state()
	var pike := _add_unit(state, "player", "spicy_pepper_pike", "plated")
	var enemy_meal := _add_unit(state, "opponent", "hearty_stewoose", "plated")
	service._resolve_activated_ability(state, int(pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(enemy_meal.instance_id))
	_expect(int(enemy_meal.health) == 7, "Pepper Pike did not damage an opposing Meal.")

	state = _fresh_state()
	var mole := _add_unit(state, "player", "hearty_meatloaf_mole", "plated")
	mole.health = 3
	var victim := _add_unit(state, "opponent", "spicy_hot_honey_bee", "plated")
	victim.attack = 0
	service._resolve_unit_battle(state, "player", mole, victim)
	_expect(int(mole.health) == 5, "Meatloaf Mole did not heal after KOing a unit (health %d, log %s)." % [int(mole.health), str(state.log)])

	state = _fresh_state()
	var buffalo := _add_unit(state, "player", "hearty_broth_buffalo", "plated")
	var patient := _add_unit(state, "player", "hearty_macaroni_manatee", "prep")
	patient.health = 1
	service._resolve_activated_ability(state, int(buffalo.instance_id), service.card("hearty_broth_buffalo").abilities[0], int(patient.instance_id))
	_expect(int(patient.health) == 3, "Broth Buffalo did not heal a friendly unit by 2.")

	state = _fresh_state()
	_add_unit(state, "opponent", "sweet_cinnamon_snail", "plated")
	var reduced_patient := _add_unit(state, "player", "hearty_macaroni_manatee", "prep")
	reduced_patient.health = 1
	service._resolve_effects(state, "player", [{"type": "heal_unit", "amount": 2}], reduced_patient, int(reduced_patient.instance_id))
	_expect(int(reduced_patient.health) == 1, "Cinnamon Snail did not reduce opposing healing by 2.")

	state = _fresh_state()
	var raccoon := _add_unit(state, "player", "funky_remix_raccoon", "plated")
	var copied := _add_unit(state, "player", "hearty_gravy_gazelle", "prep")
	service._resolve_activated_ability(state, int(raccoon.instance_id), service.card("funky_remix_raccoon").abilities[0], int(copied.instance_id))
	service.choose_effect_target(state, int(raccoon.instance_id))
	_expect(int(raccoon.attack) == 5 and int(raccoon.health) == 7, "Remix Raccoon did not copy the Prep unit's activated ability.")

	state = _fresh_state()
	state.player.deck = ["fresh_crisp_capybara"]
	var beetle := _add_unit(state, "player", "funky_beat_beetle", "prep")
	service._resolve_effects(state, "player", service.card("funky_beat_beetle").on_play, beetle)
	_expect(int(beetle.attack) == 4 and int(beetle.health) == 4 and state.player.discard == ["fresh_crisp_capybara"], "Beat Beetle did not mill a unit and gain +3/+3.")

	state = _fresh_state()
	state.player.hand = ["fresh_sprout_squirrel"]
	service._play_ingredient(state, "player", 0, "plated")
	_expect(_has_card(state.player.plated, "fresh_sprout_squirrel") and _has_card(state.player.prep, "token_fresh_ingredient"), "Sprout Squirrel did not create a Fresh token in Prep.")

	state = _fresh_state()
	var turniptable := _add_unit(state, "player", "funky_turniptable_turtle", "prep")
	state.player.deck = ["fresh_crisp_capybara"]
	service._resolve_activated_ability(state, int(turniptable.instance_id), service.card("funky_turniptable_turtle").abilities[0], -1)
	_expect(int(turniptable.attack) == 2 and int(turniptable.health) == 3 and state.player.discard.has("fresh_crisp_capybara"), "Turniptable Turtle did not provide a copyable discard ability.")

	state = _fresh_state()
	var lynx := _add_unit(state, "player", "funky_leftover_lynx", "plated")
	state.player.discard = ["funky_beat_beetle"]
	service._resolve_effects(state, "player", service.card("funky_leftover_lynx").on_play, lynx)
	service.toggle_discard_choice(state, 0)
	service.confirm_discard_choice(state)
	_expect(state.player.hand.has("funky_beat_beetle") and state.player.discard.is_empty(), "Leftover Lynx did not recover a discarded unit.")


func _test_attack_and_protection_effects() -> void:
	var state := _fresh_state()
	var tern := _add_unit(state, "player", "sweet_bottomless_trifle_tern", "plated")
	tern.ready = true
	state.player.deck = ["item_wooden_spoon", "item_recipe_prep", "chef_mary", "fresh_crisp_capybara", "funky_fondue_ferret", "spicy_hot_honey_bee"]
	service.select_attacker(state, int(tern.instance_id))
	service.attack(state, -1)
	_expect(state.player.hand.size() == 6, "Bottomless Trifle Tern did not draw to six when attacking.")

	state = _fresh_state()
	_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
	var protected := _add_unit(state, "player", "fresh_crisp_capybara", "prep")
	service._deal_effect_damage_to_unit(state, "opponent", "player", protected, 3)
	_expect(int(protected.health) == 3, "Salad Shield Skunk did not prevent effect damage to another Prep unit.")

	state = _fresh_state()
	var puma := _add_unit(state, "player", "sweet_pudding_puma", "prep")
	puma.ready = true
	var life_before := int(state.opponent.life)
	service.select_attacker(state, int(puma.instance_id))
	service.attack(state, -1)
	_expect(int(state.opponent.life) == life_before - 3, "Pudding Puma could not attack from Prep.")


func _test_hand_responses() -> void:
	var state := _fresh_state()
	state.player.hand = ["funky_chef_check_chinchilla"]
	state.opponent.hand = ["chef_mary"]
	service._play_chef(state, "opponent", 0)
	_expect(not state.pending_reaction.is_empty(), "Chef-Check Chinchilla did not open a response window.")
	service.resolve_reaction(state, 0)
	_expect(state.opponent.discard.has("chef_mary") and not state.opponent.hand.has("chef_mary"), "Chef-Check Chinchilla did not negate the Chef.")

	state = _fresh_state()
	state.player.hand = ["spicy_pantry_pouncer"]
	state.opponent.hand = ["hearty_macaroni_manatee"]
	service._play_ingredient(state, "opponent", 0, "prep")
	service.resolve_reaction(state, 0)
	_expect(state.opponent.prep.is_empty() and state.opponent.discard.has("hearty_macaroni_manatee"), "Pantry Pouncer did not destroy the played Ingredient.")

	state = _fresh_state()
	state.player.hand = ["funky_toolbox_toad"]
	state.opponent.hand = ["item_wooden_spoon"]
	service._play_tool(state, "opponent", 0)
	service.resolve_reaction(state, 0)
	_expect(state.opponent.discard.has("item_wooden_spoon") and state.opponent.hand.is_empty(), "Toolbox Toad did not negate the Tool.")

	state = _fresh_state()
	state.player.hand = ["sweet_ability_axolotl"]
	var enemy_pike := _add_unit(state, "opponent", "spicy_pepper_pike", "plated")
	enemy_pike.ready = false
	var friendly_meal := _add_unit(state, "player", "hearty_stewoose", "plated")
	service._resolve_activated_ability_for_side(state, "opponent", int(enemy_pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(friendly_meal.instance_id), true)
	service.resolve_reaction(state, 0)
	_expect(int(friendly_meal.health) == 8, "Ability Axolotl did not negate the opposing activated ability (health %d)." % int(friendly_meal.health))

	state = _fresh_state()
	state.player.hand = ["fresh_comeback_corgi"]
	service._deal_chef_damage(state, "player", 2, "opponent", false)
	_expect(not state.pending_reaction.is_empty(), "Comeback Cucumber Corgi did not open after Chef damage.")
	service.resolve_reaction(state, 0)
	_expect(_has_card(state.player.plated, "fresh_comeback_corgi") and _has_card(state.player.prep, "token_fresh_ingredient"), "Comeback Cucumber Corgi did not enter Plated and create its token.")

	state = _fresh_state()
	var guard := _add_unit(state, "player", "funky_trap_jam_tapir", "plated")
	var guarded_pike := _add_unit(state, "player", "spicy_pepper_pike", "plated")
	var guarded_target := _add_unit(state, "opponent", "hearty_stewoose", "plated")
	state.opponent.hand = ["sweet_ability_axolotl"]
	service._resolve_activated_ability(state, int(guarded_pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(guarded_target.instance_id))
	_expect(int(guarded_target.health) == 7 and guard.get("used_abilities", []).has("hand_trap_guard"), "Trap Jam Tapir did not negate the opposing hand trap once per turn.")


func _test_stepwise_opponent_turn() -> void:
	var state := _fresh_state()
	state.opponent.hand = ["hearty_bagver", "hearty_macaroni_manatee"]
	service.end_player_turn(state, true)
	_expect(String(state.phase) == "opponent_turn" and state.opponent.prep.is_empty(), "Deferred opponent turn performed actions immediately.")
	service.advance_opponent_turn(state)
	_expect(state.opponent.prep.is_empty() and int(state.opponent.turns_started) == 4, "The first opponent step did not only start and draw for the turn.")
	service.advance_opponent_turn(state)
	_expect(state.opponent.prep.size() == 1 and state.opponent.hand.size() == 1, "One opponent step did not produce exactly one visible card play.")
	service.advance_opponent_turn(state)
	_expect(state.opponent.prep.size() == 2 and state.opponent.hand.is_empty(), "The next opponent card play was not deferred to its own step.")
	var safety := 12
	while String(state.phase) == "opponent_turn" and safety > 0:
		safety -= 1
		service.advance_opponent_turn(state)
	_expect(String(state.phase) == "player_main" and safety > 0, "The stepwise opponent sequence did not return control to the player.")


func _test_ai_difficulty_decisions() -> void:
	var easy_state := _fresh_state()
	easy_state.ai_difficulty = "easy"
	var easy_recipe_piece := _add_unit(easy_state, "opponent", "spicy_hot_honey_bee", "prep")
	easy_recipe_piece.recipe_ready_on_turn = 3
	easy_state.opponent.hand = ["spicy_sriracharrow", "hearty_bagver"]
	service._ai_play_one_hand_card(easy_state)
	_expect(_has_card(easy_state.opponent.prep, "hearty_bagver") and not _has_card(easy_state.opponent.plated, "spicy_sriracharrow"), "Easy AI no longer preserves the original first-legal-play behavior.")

	var hard_state := _fresh_state()
	hard_state.ai_difficulty = "hard"
	var hard_recipe_piece := _add_unit(hard_state, "opponent", "spicy_hot_honey_bee", "prep")
	hard_recipe_piece.recipe_ready_on_turn = 3
	hard_state.opponent.hand = ["spicy_sriracharrow", "hearty_bagver"]
	service._ai_play_one_hand_card(hard_state)
	_expect(_has_card(hard_state.opponent.plated, "spicy_sriracharrow") and not _has_card(hard_state.opponent.prep, "spicy_hot_honey_bee"), "Hard AI did not prioritize a ready Meal over a filler Ingredient.")

	var target_state := _fresh_state()
	var attacker := _add_unit(target_state, "opponent", "sweet_pup_tart", "plated")
	var weak_target := _add_unit(target_state, "player", "sweet_caramel_camel", "plated")
	var threat_target := _add_unit(target_state, "player", "spicy_firecracker_shrimp", "plated")
	threat_target.health = 4
	target_state.ai_difficulty = "easy"
	_expect(int(service._ai_attack_target(target_state, attacker).instance_id) == int(weak_target.instance_id), "Easy AI stopped choosing the lowest-health defender.")
	target_state.ai_difficulty = "hard"
	_expect(int(service._ai_attack_target(target_state, attacker).instance_id) == int(threat_target.instance_id), "Hard AI did not remove the more dangerous KO-able defender.")

	var expert_pass_state := _fresh_state()
	expert_pass_state.ai_difficulty = "expert"
	expert_pass_state.opponent.environment = "environment_blazing_wok"
	expert_pass_state.opponent.hand = ["environment_blazing_wok"]
	_expect(not service._ai_play_one_hand_card(expert_pass_state), "Expert AI replaced an established Environment with a duplicate instead of passing.")
	_expect(expert_pass_state.opponent.hand == ["environment_blazing_wok"], "Expert AI spent the card it was supposed to hold.")

	var expert_reaction_state := _fresh_state()
	expert_reaction_state.ai_difficulty = "expert"
	expert_reaction_state.opponent.hand = ["spicy_pantry_pouncer"]
	_add_unit(expert_reaction_state, "player", "token_fresh_ingredient", "prep")
	_expect(not service._ai_hand_trap_stops(expert_reaction_state, "enemy_ingredient_played", "player"), "Expert AI spent a Hand Trap on a low-value token.")
	_expect(expert_reaction_state.opponent.hand == ["spicy_pantry_pouncer"], "Expert AI did not preserve its Hand Trap for a stronger play.")

	var expert_search_state := _fresh_state()
	expert_search_state.ai_difficulty = "expert"
	var ready_piece := _add_unit(expert_search_state, "opponent", "spicy_hot_honey_bee", "prep")
	ready_piece.recipe_ready_on_turn = 3
	expert_search_state.opponent.deck = ["spicy_sriracharrow", "hearty_bagver"]
	service._search_deck(expert_search_state, "opponent", {})
	_expect(expert_search_state.opponent.hand.has("spicy_sriracharrow"), "Expert AI did not use lookahead context to search for its ready Meal.")


func _test_all_starter_pairings_progress() -> void:
	var deck_ids := [
		"spicy_test_kitchen",
		"sweet_test_kitchen",
		"hearty_test_kitchen",
		"fresh_test_kitchen",
		"funky_test_kitchen"
	]
	for player_deck in deck_ids:
		for opponent_deck in deck_ids:
			if player_deck == opponent_deck:
				continue
			var state: Dictionary = service.start_game(player_deck, opponent_deck, 8100 + deck_ids.find(player_deck) * 10 + deck_ids.find(opponent_deck), "opponent")
			_pass_all_reactions(state)
			for unused_turn in range(3):
				if bool(state.game_over):
					break
				if String(state.phase) != "player_main":
					_fail("%s versus %s became stuck outside the player turn." % [player_deck, opponent_deck])
					break
				service.end_player_turn(state)
				_pass_all_reactions(state)
			_expect(bool(state.game_over) or int(state.turn) >= 3, "%s versus %s did not progress through full turns." % [player_deck, opponent_deck])
	for ai_difficulty in ["easy", "medium", "hard", "expert"]:
		var tier_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 9200 + ["easy", "medium", "hard", "expert"].find(ai_difficulty), "player", false, ai_difficulty)
		_pass_all_reactions(tier_state)
		for unused_turn in range(3):
			if bool(tier_state.game_over):
				break
			service.end_player_turn(tier_state)
			_pass_all_reactions(tier_state)
		_expect(bool(tier_state.game_over) or int(tier_state.turn) >= 3, "%s AI did not complete normal production turns." % String(ai_difficulty).capitalize())


func _pass_all_reactions(state: Dictionary) -> void:
	var safety := 20
	while not state.get("pending_reaction", {}).is_empty() and safety > 0:
		safety -= 1
		service.resolve_reaction(state, -1)


func _fresh_state() -> Dictionary:
	var state: Dictionary = service.start_game("fresh_test_kitchen", "funky_test_kitchen", 5001, "player")
	for side in ["player", "opponent"]:
		state[side].hand = []
		state[side].deck = []
		state[side].discard = []
		state[side].prep = []
		state[side].plated = []
		state[side].life = 25
		state[side].fatigue = 0
		state[side].turns_started = 3
		state[side].chef_used = false
		state[side].meal_served = false
		state[side].hand_trap_used = false
	state.phase = "player_main"
	state.first_player = "opponent"
	state.pending_choice = {}
	state.pending_ability = {}
	state.pending_reaction = {}
	state.game_over = false
	state.winner = ""
	return state


func _add_unit(state: Dictionary, side: String, card_id: String, zone: String) -> Dictionary:
	var unit: Dictionary = service._make_unit(state, state[side], service.card(card_id), zone, side)
	state[side][zone].append(unit)
	return unit


func _has_card(units: Array, card_id: String) -> bool:
	for unit in units:
		if String(unit.get("card_id", "")) == card_id:
			return true
	return false


func _assert_card(card_id: String, card_type: String, attack: int, health: int) -> void:
	var data: Dictionary = service.card(card_id)
	_expect(String(data.get("card_type", "")) == card_type and int(data.get("attack", -1)) == attack and int(data.get("health", -1)) == health, "%s has the wrong type or stats." % card_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failed = true
	push_error(message)
