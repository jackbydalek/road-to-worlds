extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const RUN_STATE_SCRIPT := preload("res://scripts/RunStateService.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("The rebalanced production card pool did not load.")
		return
	if service.cards_by_id.size() != 88:
		_fail("Expected the canonical 87-card demo catalog plus the Fresh token.")
		return
	if service.decks.size() != 4:
		_fail("Expected the Spicy, Sweet, Hearty, and Fresh prebuilt decks.")
		return
	for deck_id in service.decks:
		var deck_total := 0
		for count in service.decks[deck_id].get("cards", {}).values():
			deck_total += int(count)
		if deck_total != 20:
			_fail("%s contains %d cards instead of 20." % [deck_id, deck_total])
			return
		for card_id in service.decks[deck_id].get("cards", {}):
			if service.card(String(card_id)).is_empty():
				_fail("%s references missing card %s." % [deck_id, card_id])
				return

	var run_state: RefCounted = RUN_STATE_SCRIPT.new()
	run_state.setup(service.cards_by_id, {}, [], 1, 6, 20, "")
	var exact_deck: Dictionary = service.decks.spicy_test_kitchen.cards.duplicate(true)
	var exact_collection: Dictionary = exact_deck.duplicate(true)
	if not bool(run_state.deck_is_legal({"deck": exact_deck, "collection": exact_collection, "sideboard": {}}).get("ok", false)):
		_fail("A legal 20-card constructed deck was rejected.")
		return
	var one_card_deck := {"spicy_hot_honey_bee": 1}
	if not bool(run_state.deck_is_legal({"deck": one_card_deck, "collection": one_card_deck.duplicate(true), "sideboard": {}}).get("ok", false)):
		_fail("A one-card constructed deck was rejected.")
		return
	if bool(run_state.deck_is_legal({"deck": {}, "collection": {}, "sideboard": {}}).get("ok", false)):
		_fail("An empty constructed deck was accepted.")
		return
	var oversized_deck: Dictionary = exact_deck.duplicate(true)
	var oversized_collection: Dictionary = exact_collection.duplicate(true)
	oversized_deck.item_strainer = int(oversized_deck.item_strainer) + 1
	oversized_collection.item_strainer = int(oversized_collection.item_strainer) + 1
	if not bool(run_state.deck_is_legal({"deck": oversized_deck, "collection": oversized_collection, "sideboard": {}}).get("ok", false)):
		_fail("A 21-card constructed deck was rejected.")
		return

	var dual_recipe_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 991)
	dual_recipe_state.player.turns_started = 2
	dual_recipe_state.player.prep = [_unit(100, "spicy_ghost_pepper_python", "Ghost Pepython", "ingredient", 1, 1)]
	dual_recipe_state.player.hand = ["spicy_funky_jambaye_aye"]
	service.begin_meal_play(dual_recipe_state, 0, "plated")
	if dual_recipe_state.pending_meal.is_empty() or not service.meal_selectable_ingredient_ids(dual_recipe_state).has(100):
		_fail("A dual-type Ingredient did not satisfy an either/or Meal recipe.")
		return

	var eggplant_state: Dictionary = service.start_game("sweet_test_kitchen", "hearty_test_kitchen", 992)
	eggplant_state.player.prep = []
	eggplant_state.player.discard = ["funky_eggplant_ant"]
	if not service.can_play_discard_ingredient(eggplant_state):
		_fail("Eggplant Ant was not playable from the discard pile.")
		return
	service.play_discard_ingredient(eggplant_state)
	eggplant_state.player.discard = ["funky_eggplant_ant"]
	if eggplant_state.player.prep.size() != 1 or service.can_play_discard_ingredient(eggplant_state):
		_fail("Eggplant Ant's discard play was not limited to once per turn.")
		return

	var crisp_state: Dictionary = service.start_game("hearty_test_kitchen", "sweet_test_kitchen", 993)
	crisp_state.player.hand = ["fresh_crisp_capybara"]
	crisp_state.player.deck = ["spicy_jalapeno_jackal"]
	crisp_state.player.prep = []
	service.play_card(crisp_state, 0, "prep")
	if crisp_state.pending_search.is_empty():
		_fail("Crisp Capybara did not offer an Ingredient from the deck.")
		return
	service.select_search_card(crisp_state, "spicy_jalapeno_jackal")
	if crisp_state.player.prep.size() != 2 or not crisp_state.player.hand.is_empty():
		_fail("Crisp Capybara did not put the chosen Ingredient directly into Prep.")
		return

	var pup_state: Dictionary = service.start_game("sweet_test_kitchen", "hearty_test_kitchen", 994)
	pup_state.player.turns_started = 2
	pup_state.player.plated = [_unit(200, "sweet_pup_tart", "Pup Tart", "meal", 3, 4)]
	pup_state.player.prep = [
		_unit(201, "sweet_caramel_camel", "Choco Bat", "ingredient", 1, 1),
		_unit(202, "sweet_soft_serve_crab", "Soft Serve Crab", "ingredient", 1, 4)
	]
	pup_state.player.hand = ["sweet_strawberry_sharkcake", "sweet_strawberry_sharkcake"]
	service._serve_meal(pup_state, "player", 0, [201], "prep")
	if not service._can_serve_meal(pup_state.player):
		_fail("Pup Tart did not allow a second Meal in the same turn.")
		return
	service._serve_meal(pup_state, "player", 0, [202], "prep")
	if service._can_serve_meal(pup_state.player):
		_fail("Pup Tart allowed more than one additional Meal.")
		return

	var soup_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 995)
	soup_state.player.plated = [_unit(300, "spicy_jalapeno_jackal", "Jakapeno", "ingredient", 3, 2)]
	soup_state.opponent.plated = [_unit(301, "hearty_french_bread_dog", "French Bread Dog", "ingredient", 1, 2)]
	soup_state.player.hand = ["chef_soup"]
	service.play_card(soup_state, 0)
	if not soup_state.player.plated.is_empty() or not soup_state.opponent.plated.is_empty():
		_fail("Chef Soup did not perform the symmetric Plated reset.")
		return

	var non_piercing_state: Dictionary = service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 996)
	non_piercing_state.player.plated = [_unit(400, "hearty_macaroni_manatee", "Macaronatee", "ingredient", 2, 2)]
	non_piercing_state.opponent.plated = [_unit(401, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1)]
	non_piercing_state.opponent.plated[0].defending = true
	service._resolve_unit_battle(non_piercing_state, "player", non_piercing_state.player.plated[0], non_piercing_state.opponent.plated[0])
	if int(non_piercing_state.opponent.life) != 20:
		_fail("Only Piercing cards may deal excess damage through a Defending unit.")
		return

	var exposed_state: Dictionary = service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 997)
	exposed_state.player.plated = [_unit(405, "hearty_macaroni_manatee", "Macaronatee", "ingredient", 2, 2)]
	exposed_state.opponent.plated = [_unit(406, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1)]
	exposed_state.opponent.plated[0].defending = false
	service._resolve_unit_battle(exposed_state, "player", exposed_state.player.plated[0], exposed_state.opponent.plated[0])
	if int(exposed_state.opponent.life) != 19:
		_fail("Combat against an exposed unit did not use the original overflow damage calculation.")
		return

	var wastabi_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 998)
	wastabi_state.player.plated = [_unit(410, "spicy_wasabi_wasp", "Wastabi", "ingredient", 2, 1)]
	wastabi_state.opponent.plated = [_unit(411, "hearty_ramen_ram", "Ramen", "ingredient", 1, 2)]
	if not service.can_attack_opposing_chef(wastabi_state, 410):
		_fail("Wastabi's Stalwart did not allow it to attack through opposing Plated cards.")
		return

	var defense_state: Dictionary = service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 999)
	defense_state.player.plated = [_unit(415, "hearty_french_bread_dog", "French Bread Dog", "ingredient", 1, 2)]
	defense_state.player.hand = []
	service.end_player_turn(defense_state, true)
	if not bool(defense_state.player.plated[0].defending):
		_fail("A Plated unit that did not attack did not enter a defensive position.")
		return
	var defense_events: Array[Dictionary] = service.take_animation_events(defense_state)
	if not _has_defense_event(defense_events, 415, true):
		_fail("Entering Defense did not queue a 90-degree card animation.")
		return
	service._start_turn(defense_state, "player", false)
	var upright_events: Array[Dictionary] = service.take_animation_events(defense_state)
	if bool(defense_state.player.plated[0].defending) or not _has_defense_event(upright_events, 415, false):
		_fail("Starting the next turn did not queue the card's return to upright.")
		return

	var polar_state: Dictionary = service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 9991)
	polar_state.player.prep = [_unit(418, "hearty_polar_pot_pie_bear", "Polar Pot Pie Bear", "meal", 3, 6)]
	service.move_unit(polar_state, 418, "plated")
	if int(polar_state.player.plated[0].attack) != 5 or int(polar_state.player.plated[0].health) != 8:
		_fail("Polar Pot Pie Bear did not inherit Bison Burrito's +2/+2 move effect.")
		return

	var bison_state: Dictionary = service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 9992)
	var bison := _unit(420, "hearty_bison_burrito", "Bison Burrito", "meal", 4, 5)
	bison_state.player.plated = [bison]
	bison_state.player.prep = [
		_unit(421, "hearty_bagver", "Bagver", "ingredient", 1, 2),
		_unit(422, "hearty_ramen_ram", "Ramen Ram", "ingredient", 1, 2)
	]
	service._resolve_effects(bison_state, "player", service.card("hearty_bison_burrito").on_attack, bison)
	if not bison_state.player.prep.is_empty() or int(bison.attack) != 6 or int(bison.health) != 7:
		_fail("Bison Burrito did not discard its Prep units and gain +1/+1 for each.")
		return

	var bodyguard_data: Dictionary = service.card("sweet_soft_serve_crab")
	if not bodyguard_data.get("keywords", []).has("bodyguard") or int(bodyguard_data.health) != 4:
		_fail("Soft Serve Crab did not load its canonical Bodyguard rule and 1/4 stats.")
		return
	print("Rebalanced card pool smoke test passed.")
	quit(0)


func _unit(instance_id: int, card_id: String, card_name: String, card_type: String, attack: int, health: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": card_id,
		"name": card_name,
		"card_type": card_type,
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": true,
		"recipe_ready_on_turn": 0,
		"used_abilities": [],
		"triggered_effects": [],
		"temporary_attack": 0,
		"aura_attack_bonus": 0,
		"aura_health_bonus": 0,
		"spices": [],
		"defending": false
	}


func _has_defense_event(events: Array[Dictionary], instance_id: int, defending: bool) -> bool:
	for event in events:
		if String(event.get("type", "")) == "defense_position" and int(event.get("instance_id", -1)) == instance_id and bool(event.get("defending", false)) == defending:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
