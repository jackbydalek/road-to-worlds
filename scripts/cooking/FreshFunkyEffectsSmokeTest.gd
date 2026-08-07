extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")

var service: RefCounted
var failed := false


func _init() -> void:
	service = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load the production card catalog.")
		quit(1)
		return
	_test_canonical_subset()
	_test_fresh_board_effects()
	_test_funky_effects()
	_test_hand_responses()
	_test_stepwise_opponent_turn()
	if failed:
		quit(1)
	else:
		print("Canonical Fresh and Funky effect smoke test passed.")
		quit(0)


func _test_canonical_subset() -> void:
	var expected_cards := {
		"funky_beat_beetle": ["ingredient", 1, 2],
		"funky_fondue_ferret": ["ingredient", 1, 1],
		"funky_eggplant_ant": ["ingredient", 1, 1],
		"fresh_salad_shield_skunk": ["ingredient", 1, 3],
		"fresh_comeback_corgi": ["ingredient", 1, 1],
		"fresh_harvest_hydra": ["meal", 2, 2],
		"fresh_saladmander": ["meal", 4, 4],
		"fresh_garden_gorilla": ["meal", 2, 4],
		"fresh_spicy_yolke_bowl": ["meal", 6, 6]
	}
	for card_id in expected_cards:
		var expected: Array = expected_cards[card_id]
		var data: Dictionary = service.card(card_id)
		_expect(String(data.get("card_type", "")) == String(expected[0]) and int(data.get("attack", -1)) == int(expected[1]) and int(data.get("health", -1)) == int(expected[2]), "%s has the wrong canonical type or stats." % card_id)
	var removed_prototype_ids := [
		"spicy_chili_cicada",
		"funky_remix_raccoon",
		"funky_leftover_lynx",
		"sweet_bottomless_trifle_tern",
		"funky_trap_jam_tapir"
	]
	for card_id in removed_prototype_ids:
		_expect(service.card(card_id).is_empty(), "Removed prototype card %s is still registered." % card_id)
	_expect(service.card("fresh_harvest_hydra").get("recipe", []) == ["fresh", "any"] and String(service.card("fresh_harvest_hydra").get("required_meal_archetype", "")) == "fresh", "Harvest Hydra lost its canonical Ingredient recipe or Fresh Meal sacrifice.")
	_expect(service.card("fresh_saladmander").get("recipe", []) == ["fresh"], "Saladmander lost its one-Fresh recipe.")


func _test_fresh_board_effects() -> void:
	var state := _clean_state()
	state.player.hand = ["fresh_sprout_squirrel"]
	service._play_ingredient(state, "player", 0, "plated")
	_expect(_has_card(state.player.plated, "fresh_sprout_squirrel") and _has_card(state.player.prep, "token_fresh_ingredient"), "Sprout Squirrel did not create a Fresh token in Prep.")

	state = _clean_state()
	_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
	var protected := _add_unit(state, "player", "fresh_crisp_capybara", "prep")
	service._deal_effect_damage_to_unit(state, "opponent", "player", protected, 3)
	_expect(int(protected.health) == 1, "Iceberg Skunkuce did not protect another Prep unit from effect damage.")

	state = _clean_state()
	var saladmander := _add_unit(state, "player", "fresh_saladmander", "plated")
	service._resolve_effects(state, "player", service.card("fresh_saladmander").on_play, saladmander)
	_expect(state.player.prep.size() == 3 and _count_card(state.player.prep, "token_fresh_ingredient") == 3, "Saladmander did not fill the empty Prep slots with Fresh tokens.")

	state = _clean_state()
	var gardenrilla := _add_unit(state, "player", "fresh_garden_gorilla", "plated")
	_add_unit(state, "player", "fresh_crisp_capybara", "prep")
	_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
	service._refresh_stat_auras(state)
	_expect(int(gardenrilla.attack) == 6, "Spicy Gardenrilla did not gain +2 Attack for each other Fresh Prep unit.")

	state = _clean_state()
	var yolke := _add_unit(state, "player", "fresh_spicy_yolke_bowl", "plated")
	_add_unit(state, "opponent", "hearty_bagver", "prep")
	_add_unit(state, "opponent", "hearty_lasagnama", "plated")
	var opposing_life_before := int(state.opponent.life)
	service._resolve_effects(state, "player", service.card("fresh_spicy_yolke_bowl").on_play, yolke)
	_expect(state.opponent.prep.is_empty() and int(state.opponent.plated[0].health) == 3 and int(state.opponent.life) == opposing_life_before - 2, "Yolke Bowl did not deal 2 damage to every opposing unit and Chef.")

	state = _clean_state()
	state.player.environment = "environment_fresh_greensweet"
	service._start_turn(state, "player", false)
	_expect(_has_card(state.player.prep, "token_fresh_ingredient"), "fresh greensweet did not create its turn-start Fresh token.")


func _test_funky_effects() -> void:
	var state := _clean_state()
	var ferret := _add_unit(state, "player", "funky_fondue_ferret", "prep")
	state.player.deck = ["fresh_crisp_capybara"]
	service.activate_ability(state, int(ferret.instance_id), "feta_ferret_mill")
	_expect(int(ferret.attack) == 2 and int(ferret.health) == 2 and state.player.discard == ["fresh_crisp_capybara"], "Feta Ferret did not discard a unit and gain +1/+1.")
	service.activate_ability(state, int(ferret.instance_id), "feta_ferret_mill")
	_expect(int(ferret.attack) == 2 and int(ferret.health) == 2, "Feta Ferret activated more than once in a turn.")

	state = _clean_state()
	state.player.hand = ["funky_beat_beetle", "hearty_bagver"]
	state.player.deck = ["item_wooden_spoon"]
	service.play_card(state, 0, "prep")
	service.toggle_discard_card(state, 1)
	service.confirm_discard_cost(state)
	_expect(_has_card(state.player.prep, "funky_beat_beetle") and state.player.hand == ["item_wooden_spoon"] and state.player.discard.has("hearty_bagver"), "Beet Beetle did not discard one hand card and draw one card (hand=%s, discard=%s, prep=%s, pending=%s)." % [state.player.hand, state.player.discard, state.player.prep, state.pending_discard])

	state = _clean_state()
	state.player.environment = "environment_funky_pickle_stand"
	state.player.discard = ["hearty_bagver", "funky_beat_beetle"]
	service.activate_environment_ability(state, "funky_pickle_recover")
	_expect(service.discard_choice_indices(state) == [1], "Funky Pickle Stand offered a non-Funky discard card.")
	service.toggle_discard_choice(state, 1)
	service.confirm_discard_choice(state)
	_expect(state.player.hand == ["funky_beat_beetle"], "Funky Pickle Stand did not return the selected Funky card.")
	service.activate_environment_ability(state, "funky_pickle_recover")
	_expect(state.pending_choice.is_empty(), "Funky Pickle Stand activated more than once in a turn.")


func _test_hand_responses() -> void:
	var state := _clean_state()
	state.player.hand = ["funky_chef_check_chinchilla"]
	state.opponent.hand = ["hearty_macaroni_manatee"]
	service._play_ingredient(state, "opponent", 0, "prep")
	_expect(not state.pending_reaction.is_empty(), "Chutney Chinchilla did not open a response window for an opposing Ingredient.")
	service.resolve_reaction(state, 0)
	_expect(state.opponent.prep.is_empty() and state.opponent.discard.has("hearty_macaroni_manatee"), "Chutney Chinchilla did not destroy the played Ingredient after its on-play effect.")

	state = _clean_state()
	state.player.hand = ["funky_toolbox_toad"]
	state.opponent.hand = ["chef_mary"]
	service._play_chef(state, "opponent", 0)
	_expect(not state.pending_reaction.is_empty(), "Tamari Toad did not open a response window for an opposing Chef.")
	service.resolve_reaction(state, 0)
	_expect(state.opponent.discard.has("chef_mary") and state.opponent.hand.is_empty(), "Tamari Toad did not negate the opposing Chef.")

	state = _clean_state()
	state.player.hand = ["fresh_comeback_corgi"]
	service._deal_chef_damage(state, "player", 2, "opponent", false)
	_expect(not state.pending_reaction.is_empty(), "Cucorgi did not open its response after friendly Chef damage.")
	service.resolve_reaction(state, 0)
	_expect(_has_card(state.player.plated, "fresh_comeback_corgi") and _has_card(state.player.prep, "token_fresh_ingredient"), "Cucorgi did not enter Plated and create its Fresh token.")


func _test_stepwise_opponent_turn() -> void:
	var state := _clean_state()
	state.opponent.hand = ["hearty_bagver", "hearty_macaroni_manatee"]
	service.end_player_turn(state, true)
	_expect(String(state.phase) == "opponent_turn" and state.opponent.prep.is_empty(), "Deferred opponent turn performed actions immediately.")
	service.advance_opponent_turn(state)
	_expect(state.opponent.prep.is_empty(), "The first opponent beat did more than start and draw.")
	service.advance_opponent_turn(state)
	_expect(state.opponent.prep.size() == 1 and state.opponent.hand.size() == 1, "One opponent beat did not produce exactly one visible card play.")
	var safety := 12
	while String(state.phase) == "opponent_turn" and safety > 0:
		safety -= 1
		service.advance_opponent_turn(state)
	_expect(String(state.phase) == "player_main" and safety > 0, "The stepwise opponent sequence did not return control to the player.")


func _clean_state() -> Dictionary:
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 5001, "player")
	for side in ["player", "opponent"]:
		state[side].hand = []
		state[side].deck = []
		state[side].discard = []
		state[side].prep = []
		state[side].plated = []
		state[side].life = service.STARTING_LIFE
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
	return _count_card(units, card_id) > 0


func _count_card(units: Array, card_id: String) -> int:
	var count := 0
	for unit in units:
		if String(unit.get("card_id", "")) == card_id:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failed = true
	push_error(message)
