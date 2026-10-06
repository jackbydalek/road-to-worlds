extends SceneTree
const COMBAT := preload("res://scripts/cooking/CookingCombatService.gd")
var service = COMBAT.new()
var checks := 0

func _initialize() -> void:
	_expect(service.load_content(), "Content failed to load")
	for side in ["player", "opponent"]:
		var state := fresh()
		state[side].hand = ["spicy_quesadillama", "spicy_quesadillama", "spicy_quesadillama", "spicy_sriracharrow"]
		state[side].meals_served = 1
		state[side].meal_served = true
		for index in range(3):
			var ingredient := unit(state, side, "spicy_hot_honey_bee")
			ingredient.attack = 3
			var destination := "plated" if index < 2 else "prep"
			_expect(service._serve_meal(state, side, 0, [ingredient.instance_id], destination, true), "Special Serve %d failed for %s" % [index, side])
			_expect(int(state[side].meals_served) == 1, "Special Serve changed the normal allowance")
		_expect(state[side].hand.size() == 1 and state[side].discard.count("spicy_hot_honey_bee") == 3, "Payments were not consumed once per summon")
		_expect(not service._serve_meal(state, side, 0, [], "prep"), "Special Serve restored the used normal allowance")
	var state := fresh()
	state.player.hand = ["spicy_quesadillama", "spicy_sriracharrow"]
	var ingredient := unit(state, "player", "spicy_hot_honey_bee")
	_expect(not service._serve_meal(state, "player", 0, [ingredient.instance_id], "plated", true), "An unmet stat condition summoned a Meal")
	_expect(state.player.hand.size() == 2 and state.player.prep.size() == 1, "Failed payment consumed cards")
	ingredient.attack = 3
	service.begin_meal_play(state, 0, "plated", 0, true)
	_expect(service.meal_selectable_ingredient_ids(state).has(int(ingredient.instance_id)), "Fresh eligible Ingredient was not selectable")
	service.toggle_ingredient_selection(state, int(ingredient.instance_id))
	_expect(service.meal_selection_is_ready(state), "Special Serve selection not ready")
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	service.confirm_meal_play(restored)
	_expect(restored.player.plated.size() == 1 and int(restored.player.meals_served) == 0, "Saved pending special summon failed or spent normal allowance")
	var normal := unit(restored, "player", "spicy_hot_honey_bee")
	normal.recipe_ready_on_turn = 0
	_expect(service._serve_meal(restored, "player", 0, [normal.instance_id], "plated"), "Normal Meal unavailable after Special Serve")
	_expect(int(restored.player.meals_served) == 1, "Normal summon no longer spends allowance")
	service.cancel_meal_play(state)
	_expect(state.player.hand.size() == 2 and state.player.prep.size() == 1 and state.selected_ingredients.is_empty(), "Cancel consumed payment")
	state.run_rules.special_serve_enabled = false
	_expect(not service._serve_meal(state, "player", 0, [ingredient.instance_id], "plated", true), "Week-one lock bypassed")
	# Check every draft's actual condition and normal recipe independently.
	var drafts: Array = preload("res://scripts/WeeklyDemoService.gd").read_json(preload("res://scripts/WeeklyDemoService.gd").CARDS_PATH).cards
	for draft in drafts:
		state = fresh()
		state.player.hand = [String(draft.id)]
		var filter: Dictionary = draft.special_serve.get("ingredient_filter", {})
		for requirement in draft.special_serve.recipe:
			var base := "sweet_soft_serve_crab" if requirement == "sweet" else "hearty_macaroni_manatee" if requirement == "hearty" else "spicy_hot_honey_bee"
			if bool(filter.get("token", false)):
				base = "token_fresh_ingredient"
			var payment := unit(state, "player", base)
			payment.attack = maxi(int(payment.attack), int(filter.get("min_attack", 0)))
			payment.health = maxi(int(payment.health), int(filter.get("min_health", 0)))
			payment.max_health = payment.health + (1 if bool(filter.get("damaged", false)) else 0)
			if bool(filter.get("spiced", false)):
				payment.spices = ["spice_cayenne_crunch"]
		var ids: Array = service.serve_ingredient_ids(state, "player", draft, true)
		_expect(ids.size() == draft.special_serve.recipe.size(), "%s condition failed" % draft.name)
		_expect(service._serve_meal(state, "player", 0, ids, "plated", true), "%s Special Serve failed" % draft.name)
		_expect(state.player.plated[0].get("special_served", false), "%s lost its special flag" % draft.name)
		state = fresh()
		state.player.hand = [String(draft.id)]
		for requirement in draft.recipe:
			var base: String = {"spicy": "spicy_hot_honey_bee", "sweet": "sweet_caramel_camel", "hearty": "hearty_macaroni_manatee", "fresh": "fresh_sprout_squirrel", "funky": "funky_fondue_ferret"}.get(requirement, "spicy_hot_honey_bee")
			unit(state, "player", base).recipe_ready_on_turn = 0
		_expect(service._serve_meal(state, "player", 0, [], "plated"), "%s normal recipe failed" % draft.name)
	# Occupied slots and duplicate IDs cannot bypass sacrifice costs.
	state = fresh()
	state.player.hand = ["fresh_guacamolemur"]
	var token := unit(state, "player", "token_fresh_ingredient")
	_expect(not service._serve_meal(state, "player", 0, [token.instance_id, token.instance_id], "plated", true), "One token paid twice")
	state.player.hand = ["spicy_quesadillama"]
	token.attack = 3
	token.card_id = "spicy_hot_honey_bee"
	for unused in range(2):
		var blocker := service._make_unit(state, state.player, service.card("spicy_sriracharrow"), "plated", "player")
		state.player.plated.append(blocker)
	_expect(not service._serve_meal(state, "player", 0, [token.instance_id], "plated", true), "Special Serve overfilled Plated")
	# AI must still see the special action after its normal Meal was used.
	state = fresh()
	state.opponent.hand = ["spicy_quesadillama"]
	state.opponent.meals_served = 1
	unit(state, "opponent", "spicy_hot_honey_bee").attack = 3
	var action: Dictionary = service._ai_hand_action(state, 0)
	_expect(bool(action.get("special", false)) and service._ai_execute_hand_action(state, action), "AI cannot Special Serve after normal summon")
	print("Special Serve smoke test passed: %d checks." % checks)
	quit(0)

func fresh() -> Dictionary:
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 107)
	state.player.prep = []
	state.player.plated = []
	state.opponent.prep = []
	state.opponent.plated = []
	state.game_over = false
	return state

func unit(state: Dictionary, side: String, id: String) -> Dictionary:
	var result: Dictionary = service._make_unit(state, state[side], service.card(id), "prep", side)
	state[side].prep.append(result)
	return result

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
