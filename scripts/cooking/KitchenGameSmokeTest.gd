extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const GAME_SCENE := preload("res://scenes/KitchenGame.tscn")
const ARENA_GAME_SCENE := preload("res://scenes/KitchenGame3D.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	service.setup_content(_fixture_cards(), _fixture_decks())
	var state: Dictionary = service.start_game("test_a", "test_b", 12345)
	if state.player.hand.size() != 5 or int(state.player.turns_started) != 1 or int(state.player.life) != 25 or int(state.opponent.life) != 25:
		_fail("Two-zone combat did not deal an opening hand and begin turn one.")
		return

	# The combat service exposes formal, drainable animation events instead of
	# requiring a presentation to compare old and new state snapshots.
	var event_state: Dictionary = service.start_game("test_a", "test_b", 12001)
	event_state.player.hand = ["test_veg"]
	event_state.player.prep = []
	event_state.player.plated = []
	service.play_card(event_state, 0, "prep")
	var play_events: Array[Dictionary] = service.take_animation_events(event_state)
	if _events_of_type(play_events, "play").size() != 1 or not event_state.animation_events.is_empty():
		_fail("Playing a card did not enqueue and drain one formal play event.")
		return
	event_state.player.deck = ["test_tool"]
	service._draw(event_state, "player")
	if _events_of_type(service.take_animation_events(event_state), "draw").size() != 1:
		_fail("Drawing a card did not enqueue a formal draw event.")
		return
	event_state.player.deck = ["test_protein"]
	event_state.pending_search = {"effect": {"card_type": "ingredient"}, "prompt": "Choose."}
	service.select_search_card(event_state, "test_protein")
	if _events_of_type(service.take_animation_events(event_state), "search").size() != 1:
		_fail("Selecting a searched card did not enqueue a formal search event.")
		return
	var recipe_event_state: Dictionary = service.start_game("test_a", "test_b", 12002)
	recipe_event_state.player.prep = [_test_unit(501, "test_veg", "Vegetable", "ingredient", 3, 2, true, 0)]
	recipe_event_state.player.plated = [_test_unit(502, "test_protein", "Protein", "ingredient", 1, 1, true, 0)]
	recipe_event_state.player.hand = ["test_meal"]
	recipe_event_state.player.turns_started = 2
	service.play_card(recipe_event_state, 0, "plated")
	if recipe_event_state.pending_meal.is_empty() or not service.take_animation_events(recipe_event_state).is_empty():
		_fail("Playing a Meal did not pause for ingredient selection before creating animation events.")
		return
	service.toggle_ingredient_selection(recipe_event_state, 501)
	service.toggle_ingredient_selection(recipe_event_state, 502)
	if not service.meal_selection_is_ready(recipe_event_state):
		_fail("A valid Meal recipe did not enable confirmation after its Ingredients were selected.")
		return
	service.confirm_meal_play(recipe_event_state)
	var recipe_events: Array[Dictionary] = service.take_animation_events(recipe_event_state)
	if _events_of_type(recipe_events, "sacrifice").size() != 2 or _events_of_type(recipe_events, "play").size() != 1:
		_fail("Serving a Meal did not queue its sacrifices before its play event.")
		return
	var effect_event_state: Dictionary = service.start_game("test_a", "test_b", 12003)
	effect_event_state.player.life = 20
	var friendly_target := _test_unit(601, "test_veg", "Friendly", "ingredient", 2, 1, true, 0)
	friendly_target.max_health = 3
	effect_event_state.player.prep = [friendly_target]
	effect_event_state.opponent.prep = [
		_test_unit(602, "test_veg", "Target A", "ingredient", 1, 1, true, 0),
		_test_unit(603, "test_protein", "Target B", "ingredient", 1, 1, true, 0)
	]
	effect_event_state.opponent.plated = []
	service._resolve_effects(effect_event_state, "player", [
		{"type": "heal_player", "amount": 2},
		{"type": "heal_unit", "amount": 1},
		{"type": "buff_friendly_unit", "attack": 1, "health": 1},
		{"type": "damage_all_enemy_units", "amount": 1}
	], friendly_target, 601)
	var effect_events: Array[Dictionary] = service.take_animation_events(effect_event_state)
	var multi_hit_events := _events_of_type(effect_events, "damage")
	if _events_of_type(effect_events, "heal").size() != 2 or _events_of_type(effect_events, "buff").size() != 1 or _events_of_type(effect_events, "destroy").size() != 2:
		_fail("Healing, buffing, or destruction did not produce formal animation events.")
		return
	if multi_hit_events.size() != 2 or int(multi_hit_events[0].group_id) <= 0 or int(multi_hit_events[0].group_id) != int(multi_hit_events[1].group_id):
		_fail("A multi-hit effect did not give its damage events one shared animation group.")
		return

	# Turn draws are always exactly one card, even when the hand starts below five.
	var draw_state: Dictionary = service.start_game("test_a", "test_b", 12346)
	draw_state.player.hand = []
	draw_state.player.deck = ["test_veg", "test_protein"]
	service._start_turn(draw_state, "player")
	if draw_state.player.hand.size() != 1 or draw_state.player.deck.size() != 1:
		_fail("A low hand refilled instead of drawing exactly one card.")
		return
	draw_state.player.hand = ["test_veg", "test_veg", "test_veg", "test_veg", "test_veg"]
	draw_state.player.deck = ["test_protein"]
	service._start_turn(draw_state, "player")
	if draw_state.player.hand.size() != 6 or not draw_state.player.deck.is_empty():
		_fail("A five-card hand did not draw exactly one card for the turn.")
		return

	# The first player can Plate a card, but cannot attack with it on turn one.
	state.player.hand = ["test_veg"]
	service.play_card(state, 0, "plated")
	if state.player.plated.size() != 1 or bool(state.player.plated[0].ready):
		_fail("First player's opening Plated card was incorrectly attack-ready.")
		return
	service.select_attacker(state, int(state.player.plated[0].instance_id))
	if int(state.selected_attacker) >= 0:
		_fail("First player was allowed to select an opening-turn attacker.")
		return
	service._start_turn(state, "player", false)
	if not bool(state.player.plated[0].ready):
		_fail("Plated card did not become ready on its controller's next turn.")
		return

	# Prep capacity is three and Plated capacity is two.
	var capacity_state: Dictionary = service.start_game("test_a", "test_b", 222)
	capacity_state.player.hand = ["test_veg", "test_veg", "test_veg", "test_veg", "test_veg"]
	for unused in range(5):
		service.play_card(capacity_state, 0, "prep")
	if capacity_state.player.prep.size() != 3 or capacity_state.player.hand.size() != 2:
		_fail("Prep did not enforce its three-card capacity.")
		return
	capacity_state.player.hand = ["test_protein", "test_protein", "test_protein"]
	for unused in range(3):
		service.play_card(capacity_state, 0, "plated")
	if capacity_state.player.plated.size() != 2 or capacity_state.player.hand.size() != 1:
		_fail("Plated did not enforce its two-card capacity.")
		return

	# Ingredients in either zone must survive a full turn before a recipe can use them.
	var recipe_state: Dictionary = service.start_game("test_a", "test_b", 333)
	recipe_state.player.hand = ["test_veg", "test_protein", "test_meal"]
	service.play_card(recipe_state, 0, "prep")
	service.play_card(recipe_state, 0, "plated")
	var veg_id := int(recipe_state.player.prep[0].instance_id)
	var protein_id := int(recipe_state.player.plated[0].instance_id)
	recipe_state.player.prep[0].table_slot = 2
	recipe_state.player.plated[0].table_slot = 1
	service.toggle_ingredient_selection(recipe_state, veg_id)
	if not recipe_state.selected_ingredients.is_empty():
		_fail("A newly played ingredient was recipe-ready too early.")
		return
	service._start_turn(recipe_state, "player", false)
	var unselected_plated := _test_unit(799, "test_veg", "Unselected Plated Card", "ingredient", 3, 2, true, 3)
	unselected_plated.table_slot = 0
	recipe_state.player.plated.append(unselected_plated)
	service.play_card(recipe_state, 0, "plated")
	service.toggle_ingredient_selection(recipe_state, veg_id)
	service.toggle_ingredient_selection(recipe_state, protein_id)
	service.confirm_meal_play(recipe_state)
	if not recipe_state.player.prep.is_empty() or recipe_state.player.plated.size() != 2:
		_fail("A valid aged recipe did not replace its ingredients with a Plated meal.")
		return
	var plated_meal := _first_unit_of_type(recipe_state.player.plated, "meal")
	if plated_meal.is_empty() or not bool(plated_meal.ready):
		_fail("Meal did not enter Plated attack-ready after the opening turn.")
		return
	if int(plated_meal.get("table_slot", -1)) != 1:
		_fail("A Meal served into a full zone did not inherit its sacrificed ingredient's exact slot.")
		return

	# A player may serve only one meal per turn, even with another valid recipe available.
	var multi_meal_state: Dictionary = service.start_game("test_a", "test_b", 3331)
	multi_meal_state.player.hand = ["test_veg", "test_protein", "test_veg", "test_protein", "test_meal", "test_meal"]
	for unused in range(3):
		service.play_card(multi_meal_state, 0, "prep")
	service.play_card(multi_meal_state, 0, "plated")
	service._start_turn(multi_meal_state, "player", false)
	var first_recipe_ids := [int(multi_meal_state.player.prep[0].instance_id), int(multi_meal_state.player.plated[0].instance_id)]
	service.play_card(multi_meal_state, 0, "plated")
	for ingredient_id in first_recipe_ids:
		service.toggle_ingredient_selection(multi_meal_state, ingredient_id)
	service.confirm_meal_play(multi_meal_state)
	service.play_card(multi_meal_state, 0, "plated")
	if multi_meal_state.player.plated.size() != 1 or multi_meal_state.player.prep.size() != 2 or multi_meal_state.player.hand != ["test_meal"]:
		_fail("The game allowed a second Meal to be served during the same turn.")
		return
	service._start_turn(multi_meal_state, "player", false)
	service.play_card(multi_meal_state, 0, "plated")
	var second_recipe_ids := [int(multi_meal_state.player.prep[0].instance_id), int(multi_meal_state.player.prep[1].instance_id)]
	for ingredient_id in second_recipe_ids:
		service.toggle_ingredient_selection(multi_meal_state, ingredient_id)
	service.confirm_meal_play(multi_meal_state)
	if multi_meal_state.player.plated.size() != 2 or not multi_meal_state.player.prep.is_empty() or not multi_meal_state.player.hand.is_empty():
		_fail("The Meal serving limit did not reset on the next turn.")
		return
	var move_state: Dictionary = service.start_game("test_a", "test_b", 334)
	move_state.player.turns_started = 2
	move_state.player.hand = ["test_veg"]
	service.play_card(move_state, 0, "prep")
	var moving_id := int(move_state.player.prep[0].instance_id)
	service.move_unit(move_state, moving_id, "plated")
	if not move_state.player.prep.is_empty() or move_state.player.plated.size() != 1 or not bool(move_state.player.plated[0].ready):
		_fail("Prep-to-Plated movement did not move and ready the unit.")
		return
	service.move_unit(move_state, moving_id, "prep")
	if not move_state.player.prep.is_empty():
		_fail("A second zone move was allowed during the same turn.")
		return
	var opponent_move_state: Dictionary = service.start_game("test_a", "test_b", 3341)
	opponent_move_state.phase = "opponent_turn"
	opponent_move_state.opponent.zone_move_used = false
	opponent_move_state.opponent.prep = [_test_unit(3341, "test_veg", "Carrot", "ingredient", 1, 2, false, 2)]
	opponent_move_state.opponent.plated = []
	opponent_move_state.opponent_sequence = {"stage": "move", "attack_ids": []}
	service.clear_animation_events(opponent_move_state)
	service.advance_opponent_turn(opponent_move_state)
	var opponent_move_events: Array[Dictionary] = service.take_animation_events(opponent_move_state)
	if opponent_move_events.size() != 1 or String(opponent_move_events[0].get("type", "")) != "move" or String(opponent_move_events[0].get("side", "")) != "opponent" or String(opponent_move_events[0].get("from", "")) != "prep" or String(opponent_move_events[0].get("to", "")) != "plated" or int(opponent_move_events[0].get("instance_id", -1)) != 3341:
		_fail("The opponent Prep-to-Plated move did not queue its physical-card animation event.")
		return
	var chef_state: Dictionary = service.start_game("test_a", "test_b", 335)
	chef_state.player.hand = ["test_chef", "test_chef"]
	service.play_card(chef_state, 0)
	service.play_card(chef_state, 0)
	if chef_state.player.hand.size() != 1 or chef_state.player.discard.count("test_chef") != 1:
		_fail("Chef limit did not allow exactly one Chef per turn.")
		return

	# Items with discard costs wait for the player to select and confirm exact cards.
	var discard_state: Dictionary = service.start_game("test_a", "test_b", 336)
	discard_state.player.hand = ["test_discard_tool", "test_veg", "test_protein", "test_meal"]
	service.play_card(discard_state, 0)
	if discard_state.player.hand.size() != 4 or not discard_state.player.discard.is_empty() or int(discard_state.pending_discard.required) != 2:
		_fail("A discard-cost Item resolved before the player selected payment cards.")
		return
	service.toggle_discard_card(discard_state, 1)
	service.confirm_discard_cost(discard_state)
	if discard_state.player.hand.size() != 4 or discard_state.pending_discard.is_empty():
		_fail("An incomplete discard payment was incorrectly confirmed.")
		return
	service.toggle_discard_card(discard_state, 3)
	service.confirm_discard_cost(discard_state)
	if not discard_state.pending_discard.is_empty() or discard_state.player.hand != ["test_protein"]:
		_fail("The selected cards were not used as the discard payment.")
		return
	if discard_state.player.discard.count("test_discard_tool") != 1 or discard_state.player.discard.count("test_veg") != 1 or discard_state.player.discard.count("test_meal") != 1:
		_fail("The Item and selected payment cards did not enter the discard pile.")
		return
	discard_state.player.hand = ["test_discard_tool", "test_veg", "test_protein"]
	service.play_card(discard_state, 0)
	service.toggle_discard_card(discard_state, 1)
	service.cancel_discard_cost(discard_state)
	if not discard_state.pending_discard.is_empty() or discard_state.player.hand != ["test_discard_tool", "test_veg", "test_protein"]:
		_fail("Cancelling a discard payment did not preserve the hand.")
		return

	# Prep cards are untargetable. Plated cards protect face and receive piercing attacks.
	var combat_state: Dictionary = service.start_game("test_a", "test_b", 444)
	combat_state.player.turns_started = 2
	combat_state.player.hand = ["test_veg"]
	service.play_card(combat_state, 0, "plated")
	var attacker_id := int(combat_state.player.plated[0].instance_id)
	combat_state.opponent.prep = [_test_unit(800, "test_protein", "Prep Target", "ingredient", 1, 1, false, 2)]
	combat_state.opponent.plated = [_test_unit(801, "test_protein", "Plated Target", "ingredient", 1, 1, false, 2)]
	service.select_attacker(combat_state, attacker_id)
	service.attack(combat_state, 800)
	if int(combat_state.opponent.prep[0].health) != 1 or not bool(combat_state.player.plated[0].ready):
		_fail("Prep card was targetable or invalid targeting spent the attacker.")
		return
	var face_life_before := int(combat_state.opponent.life)
	service.attack(combat_state, -1)
	if int(combat_state.opponent.life) != face_life_before or not bool(combat_state.player.plated[0].ready):
		_fail("Plated protection did not block a face attack.")
		return
	service.attack(combat_state, 801)
	if not combat_state.opponent.plated.is_empty() or int(combat_state.opponent.life) != face_life_before - 2:
		_fail("Plated battle did not clear the defender and apply excess piercing damage.")
		return

	# Exercise several turns with the production catalog and its structured effects.
	var production_service: RefCounted = SERVICE_SCRIPT.new()
	if not production_service.load_content():
		_fail("Production card catalog did not load.")
		return

	# Stalwart attackers may bypass occupied Plated zones and hit the opposing chef.
	var stalwart_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 698)
	stalwart_state.player.turns_started = 2
	stalwart_state.player.plated = [_test_unit(890, "spicy_red_pepper_panda", "Red Pepper Panda", "ingredient", 1, 2, true, 2)]
	stalwart_state.opponent.plated = [_test_unit(891, "hearty_french_bread_dog", "French Bread Dog", "ingredient", 1, 2, false, 2)]
	production_service.select_attacker(stalwart_state, 890)
	if not production_service.can_attack_opposing_chef(stalwart_state):
		_fail("A selected Stalwart attacker was not allowed to attack through Plated cards.")
		return
	production_service.attack(stalwart_state, -1)
	if int(stalwart_state.opponent.life) != 24 or int(stalwart_state.opponent.plated[0].health) != 2 or bool(stalwart_state.player.plated[0].ready):
		_fail("Stalwart did not damage the opposing chef directly while leaving its Plated card untouched.")
		return
	var ai_stalwart_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 6981)
	ai_stalwart_state.player.plated = [_test_unit(892, "hearty_french_bread_dog", "French Bread Dog", "ingredient", 1, 2, false, 2)]
	ai_stalwart_state.opponent.plated = [_test_unit(893, "spicy_red_pepper_panda", "Red Pepper Panda", "ingredient", 1, 2, false, 2)]
	ai_stalwart_state.opponent.hand = []
	ai_stalwart_state.opponent.deck = []
	production_service._ai_turn(ai_stalwart_state)
	if int(ai_stalwart_state.player.life) != 24 or int(ai_stalwart_state.player.plated[0].health) != 2:
		_fail("The opponent AI did not use Stalwart to bypass the player's Plated card.")
		return

	# Single-target on-play effects let the player choose among only legal board cards.
	var ramen_target_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 6982)
	ramen_target_state.player.plated = [
		_test_unit(894, "hearty_bagver", "Bagver", "ingredient", 1, 2, false, 2),
		_test_unit(895, "hearty_macaroni_manatee", "Macaronatee", "ingredient", 2, 3, false, 2)
	]
	ramen_target_state.player.hand = ["hearty_ramen_ram"]
	production_service.play_card(ramen_target_state, 0, "prep")
	if not production_service.choice_target_ids(ramen_target_state).has(895):
		_fail("Ramen did not pause for a friendly board target.")
		return
	production_service.choose_effect_target(ramen_target_state, 895)
	if int(ramen_target_state.player.plated[0].attack) != 1 or int(ramen_target_state.player.plated[1].attack) != 3:
		_fail("Ramen did not buff the chosen friendly card exclusively.")
		return
	var bacon_target_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 6983)
	bacon_target_state.player.plated = [
		_test_unit(896, "hearty_bagver", "Healthy Bagver", "ingredient", 1, 2, false, 2),
		_test_unit(897, "hearty_macaroni_manatee", "Damaged Macaronatee", "ingredient", 2, 1, false, 2)
	]
	bacon_target_state.player.plated[1].max_health = 3
	bacon_target_state.player.hand = ["hearty_bird_beakon"]
	production_service.play_card(bacon_target_state, 0, "prep")
	if production_service.choice_target_ids(bacon_target_state) != [897]:
		_fail("Bacon offered a full-health card instead of only damaged friendly cards.")
		return
	production_service.choose_effect_target(bacon_target_state, 897)
	if int(bacon_target_state.player.plated[1].health) != 3:
		_fail("Bacon did not heal the selected card.")
		return
	var jelly_target_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 6984)
	jelly_target_state.opponent.hand = []
	jelly_target_state.opponent.prep = [_test_unit(898, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1, false, 2)]
	jelly_target_state.opponent.plated = [
		_test_unit(899, "spicy_jalapeno_panther", "Jalapeño Panther", "ingredient", 2, 3, false, 2),
		_test_unit(900, "spicy_sriracharrow", "Sriracharrow", "meal", 5, 4, false, 2)
	]
	jelly_target_state.player.hand = ["sweet_jellyfish"]
	production_service.play_card(jelly_target_state, 0, "prep")
	if production_service.choice_target_ids(jelly_target_state) != [898, 899]:
		_fail("Jellyfish did not offer exactly the opposing Ingredients.")
		return
	production_service.choose_effect_target(jelly_target_state, 899)
	if jelly_target_state.opponent.hand != ["spicy_jalapeno_panther"] or jelly_target_state.opponent.plated.size() != 1:
		_fail("Jellyfish did not return the chosen opposing Ingredient.")
		return

	# Firecracker Shrimp pauses its attack for a Prep target, then resumes combat.
	var firecracker_target_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6985)
	firecracker_target_state.player.turns_started = 2
	firecracker_target_state.player.plated = [_test_unit(901, "spicy_firecracker_shrimp", "Firecracker Shrimp", "meal", 7, 5, true, 2)]
	firecracker_target_state.opponent.prep = [
		_test_unit(902, "hearty_bagver", "Bagver", "ingredient", 1, 2, false, 2),
		_test_unit(903, "hearty_macaroni_manatee", "Macaronatee", "ingredient", 2, 3, false, 2)
	]
	firecracker_target_state.opponent.plated = [_test_unit(904, "hearty_stewoose", "Stewoose", "meal", 1, 10, false, 2)]
	production_service.select_attacker(firecracker_target_state, 901)
	production_service.attack(firecracker_target_state, 904)
	if production_service.choice_target_ids(firecracker_target_state) != [902, 903] or firecracker_target_state.pending_resume.is_empty():
		_fail("Firecracker Shrimp did not pause combat for its Prep target.")
		return
	production_service.cancel_pending_attack_choice(firecracker_target_state)
	if not firecracker_target_state.pending_choice.is_empty() or not firecracker_target_state.pending_resume.is_empty() or int(firecracker_target_state.selected_attacker) != 901 or not bool(firecracker_target_state.player.plated[0].ready):
		_fail("Cancelling Firecracker Shrimp's Prep targeting did not safely return to attack selection.")
		return
	production_service.attack(firecracker_target_state, 904)
	production_service.choose_effect_target(firecracker_target_state, 903)
	if int(firecracker_target_state.opponent.prep[0].health) != 2 or int(firecracker_target_state.opponent.prep[1].health) != 1 or int(firecracker_target_state.opponent.plated[0].health) != 3 or bool(firecracker_target_state.player.plated[0].ready):
		_fail("Firecracker Shrimp did not damage the chosen Prep card and resume combat.")
		return
	var firecracker_animation_events: Array[Dictionary] = production_service.take_animation_events(firecracker_target_state)
	var firecracker_attack_index := -1
	var plated_hit_index := -1
	var prep_hit_index := -1
	for event_index in range(firecracker_animation_events.size()):
		var animation_event: Dictionary = firecracker_animation_events[event_index]
		if String(animation_event.get("type", "")) == "attack" and int(animation_event.get("source_instance_id", -1)) == 901:
			firecracker_attack_index = event_index
		elif String(animation_event.get("type", "")) == "damage" and int(animation_event.get("target_instance_id", -1)) == 904:
			plated_hit_index = event_index
		elif String(animation_event.get("type", "")) == "damage" and int(animation_event.get("target_instance_id", -1)) == 903:
			prep_hit_index = event_index
	if firecracker_attack_index < 0 or plated_hit_index <= firecracker_attack_index or prep_hit_index <= plated_hit_index:
		_fail("Firecracker Shrimp did not animate its selected Prep hit after the Plated combat hit.")
		return

	# Board-target Tools and Blow Torch's sequential choices resolve selected targets.
	var mixer_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6986)
	mixer_state.player.prep = [_test_unit(905, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1, false, 2)]
	mixer_state.opponent.plated = [_test_unit(906, "hearty_dumpling_tortoise", "Dumpling-Backed Tortoise", "meal", 4, 5, false, 2)]
	mixer_state.player.hand = ["item_hand_mixer"]
	production_service.play_card(mixer_state, 0)
	production_service.choose_effect_target(mixer_state, 906)
	if int(mixer_state.opponent.plated[0].attack) != 5 or int(mixer_state.opponent.plated[0].health) != 4:
		_fail("Hand Mixer did not swap the chosen card's Attack and Health.")
		return
	var grater_state: Dictionary = production_service.start_game("spicy_test_kitchen", "sweet_test_kitchen", 6987)
	grater_state.opponent.plated = [_test_unit(907, "sweet_marshmallow_swallow", "Marshmallow Swallows", "ingredient", 3, 4, false, 2)]
	grater_state.opponent.plated[0].max_health = 4
	grater_state.opponent.plated[0].spices = ["spice_sugar_glaze"]
	grater_state.player.hand = ["item_grater"]
	production_service.play_card(grater_state, 0)
	if production_service.choice_target_ids(grater_state) != [907]:
		_fail("Grater did not offer the opposing seasoned card.")
		return
	production_service.choose_effect_target(grater_state, 907)
	if int(grater_state.opponent.plated[0].attack) != 2 or int(grater_state.opponent.plated[0].health) != 3 or not grater_state.opponent.plated[0].spices.is_empty() or not grater_state.opponent.discard.has("spice_sugar_glaze"):
		_fail("Grater did not remove the chosen Spice and its bonuses.")
		return
	var blow_torch_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6988)
	blow_torch_state.player.plated = [
		_test_unit(908, "spicy_red_pepper_panda", "Red Pepper Panda", "ingredient", 1, 2, true, 2),
		_test_unit(909, "hearty_bagver", "Bagver", "ingredient", 1, 2, true, 2)
	]
	blow_torch_state.opponent.prep = [_test_unit(910, "hearty_macaroni_manatee", "Macaronatee", "ingredient", 2, 3, false, 2)]
	blow_torch_state.opponent.plated = [_test_unit(911, "hearty_dumpling_tortoise", "Dumpling-Backed Tortoise", "meal", 4, 5, false, 2)]
	blow_torch_state.player.hand = ["item_blow_torch"]
	production_service.play_card(blow_torch_state, 0)
	if production_service.choice_target_ids(blow_torch_state) != [908]:
		_fail("Blow Torch did not begin with only a friendly Spicy Plated target.")
		return
	production_service.choose_effect_target(blow_torch_state, 908)
	if production_service.choice_target_ids(blow_torch_state) != [910, 911] or blow_torch_state.player.prep.size() != 1:
		_fail("Blow Torch did not move the chosen Spicy card and advance to its enemy target.")
		return
	production_service.choose_effect_target(blow_torch_state, 911)
	if not blow_torch_state.pending_choice.is_empty() or not blow_torch_state.opponent.plated.is_empty() or not blow_torch_state.opponent.discard.has("hearty_dumpling_tortoise"):
		_fail("Blow Torch did not destroy its second selected target.")
		return

	# Discard recovery and Tongs use explicit card pickers instead of automatic choices.
	var strainer_choice_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6989)
	strainer_choice_state.player.hand = ["item_strainer"]
	strainer_choice_state.player.deck = []
	strainer_choice_state.player.discard = ["spicy_sriracharrow", "item_wooden_spoon", "spicy_hot_honey_bee"]
	production_service.play_card(strainer_choice_state, 0)
	production_service.toggle_discard_choice(strainer_choice_state, 0)
	production_service.toggle_discard_choice(strainer_choice_state, 2)
	production_service.confirm_discard_choice(strainer_choice_state)
	if strainer_choice_state.player.deck.size() != 2 or not strainer_choice_state.player.deck.has("spicy_sriracharrow") or not strainer_choice_state.player.deck.has("spicy_hot_honey_bee") or strainer_choice_state.player.discard.has("spicy_sriracharrow"):
		_fail("Strainer did not recycle the two explicitly selected discard cards.")
		return
	var chef_carl_choice_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 6990)
	chef_carl_choice_state.player.hand = ["chef_carl"]
	chef_carl_choice_state.player.discard = ["hearty_dumpling_tortoise", "hearty_stewoose", "hearty_bagver"]
	production_service.play_card(chef_carl_choice_state, 0)
	if production_service.discard_choice_indices(chef_carl_choice_state) != [0, 1]:
		_fail("Chef Carl did not offer only Meals from the discard pile.")
		return
	production_service.toggle_discard_choice(chef_carl_choice_state, 0)
	production_service.confirm_discard_choice(chef_carl_choice_state)
	if chef_carl_choice_state.player.hand != ["hearty_dumpling_tortoise"]:
		_fail("Chef Carl did not return the selected Meal.")
		return
	var measuring_choice_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 69900)
	measuring_choice_state.player.hand = ["item_measuring_cup", "spicy_hot_honey_bee", "item_wooden_spoon"]
	measuring_choice_state.player.discard = ["spicy_sriracharrow", "sweet_pup_tart"]
	production_service.play_card(measuring_choice_state, 0)
	production_service.toggle_discard_card(measuring_choice_state, 1)
	production_service.toggle_discard_card(measuring_choice_state, 2)
	production_service.confirm_discard_cost(measuring_choice_state)
	if production_service.discard_choice_indices(measuring_choice_state) != [0, 1, 3]:
		_fail("Measuring Cup did not offer all eligible Foods after its selected discard payment.")
		return
	production_service.toggle_discard_choice(measuring_choice_state, 0)
	production_service.toggle_discard_choice(measuring_choice_state, 1)
	production_service.confirm_discard_choice(measuring_choice_state)
	if measuring_choice_state.player.hand != ["spicy_sriracharrow", "sweet_pup_tart"]:
		_fail("Measuring Cup did not recover the two selected Foods.")
		return
	var tongs_choice_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 69901)
	tongs_choice_state.player.hand = ["item_tongs"]
	tongs_choice_state.opponent.hand = ["item_wooden_spoon", "hearty_bagver", "hearty_dumpling_tortoise"]
	production_service.play_card(tongs_choice_state, 0)
	if production_service.opponent_hand_choice_indices(tongs_choice_state) != [1, 2]:
		_fail("Tongs did not reveal only selectable opposing-hand units.")
		return
	production_service.choose_opponent_hand_card(tongs_choice_state, 2)
	if tongs_choice_state.opponent.hand != ["item_wooden_spoon", "hearty_bagver"] or tongs_choice_state.opponent.prep.size() != 1 or String(tongs_choice_state.opponent.prep[0].card_id) != "hearty_dumpling_tortoise" or bool(tongs_choice_state.opponent.prep[0].ready):
		_fail("Tongs did not put the selected opposing-hand unit into Prep.")
		return

	# Production Spices attach real bonuses and each Environment applies its authored engine effect.
	var spice_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 69902)
	spice_state.player.prep = [_test_unit(912, "sweet_marshmallow_swallow", "Marshmallow Swallows", "ingredient", 2, 3, false, 2)]
	spice_state.player.hand = ["spice_sugar_glaze"]
	production_service.select_spice_target(spice_state, 912)
	production_service.play_card(spice_state, 0)
	if int(spice_state.player.prep[0].attack) != 3 or int(spice_state.player.prep[0].health) != 4 or spice_state.player.prep[0].spices != ["spice_sugar_glaze"]:
		_fail("Sugar Glaze did not attach and grant its production +1/+1 bonus.")
		return
	var blazing_wok_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 69903)
	blazing_wok_state.player.turns_started = 2
	blazing_wok_state.player.environment = "environment_blazing_wok"
	blazing_wok_state.player.prep = [_test_unit(913, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1, false, 2)]
	blazing_wok_state.player.hand = ["spicy_sriracharrow"]
	production_service.play_card(blazing_wok_state, 0, "plated")
	production_service.toggle_ingredient_selection(blazing_wok_state, 913)
	production_service.confirm_meal_play(blazing_wok_state)
	if int(blazing_wok_state.player.plated[0].attack) != 6:
		_fail("Blazing Wok did not give a served Meal +1 Attack.")
		return
	var slow_cooker_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 69904)
	slow_cooker_state.player.environment = "environment_slow_cooker"
	slow_cooker_state.player.prep = [_test_unit(914, "hearty_bagver", "Bagver", "ingredient", 1, 2, false, 2)]
	production_service._start_turn(slow_cooker_state, "player", false)
	if int(slow_cooker_state.player.prep[0].attack) != 2 or int(slow_cooker_state.player.prep[0].health) != 3:
		_fail("Slow Cooker did not grow friendly Ingredients at turn start.")
		return
	var dessert_display_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 69905)
	dessert_display_state.player.turns_started = 2
	dessert_display_state.player.environment = "environment_dessert_display"
	dessert_display_state.player.prep = [_test_unit(915, "sweet_sugar_glider", "Sugar Glider", "ingredient", 1, 2, false, 2)]
	dessert_display_state.player.hand = ["sweet_pup_tart"]
	production_service.play_card(dessert_display_state, 0, "plated")
	production_service.toggle_ingredient_selection(dessert_display_state, 915)
	production_service.confirm_meal_play(dessert_display_state)
	if int(dessert_display_state.player.plated[0].health) != 6 or int(dessert_display_state.player.plated[0].max_health) != 6:
		_fail("Dessert Display did not give a served Meal +1 Health.")
		return

	# Discard-cost searches transition from payment into a filtered deck choice.
	var shopping_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 699)
	shopping_state.player.hand = ["item_spicy_shopping_list", "hearty_bagver"]
	shopping_state.player.deck = ["hearty_kale_whale", "spicy_sriracharrow", "spicy_hot_honey_bee"]
	production_service.play_card(shopping_state, 0)
	production_service.toggle_discard_card(shopping_state, 1)
	production_service.confirm_discard_cost(shopping_state)
	if production_service.search_candidates(shopping_state) != ["spicy_hot_honey_bee"]:
		_fail("Spicy Shopping List did not offer only Spicy Ingredients after payment.")
		return
	var shopping_search_rng_state: int = production_service.rng.state
	production_service.select_search_card(shopping_state, "spicy_hot_honey_bee")
	if shopping_state.player.hand != ["spicy_hot_honey_bee"] or not shopping_state.pending_search.is_empty() or production_service.rng.state == shopping_search_rng_state or "shuffle your deck" not in String(shopping_state.message).to_lower():
		_fail("Spicy Shopping List did not add the selected Ingredient and shuffle the deck.")
		return

	# Tool Drawer reveals exactly the top four cards and can take only a Tool among them.
	var tool_drawer_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6991)
	tool_drawer_state.player.hand = ["item_tool_drawer"]
	tool_drawer_state.player.deck = ["item_wooden_spoon", "hearty_bagver", "item_recipe_prep", "sweet_pup_tart", "item_strainer"]
	production_service.play_card(tool_drawer_state, 0)
	var expected_reveal := ["item_strainer", "sweet_pup_tart", "item_recipe_prep", "hearty_bagver"]
	if production_service.search_display_cards(tool_drawer_state) != expected_reveal:
		_fail("Tool Drawer did not reveal exactly the top four cards in top-first order.")
		return
	if production_service.search_candidates(tool_drawer_state) != ["item_strainer", "item_recipe_prep"]:
		_fail("Tool Drawer offered a non-Tool or a Tool below the top four cards.")
		return
	var drawer_search_rng_state: int = production_service.rng.state
	production_service.select_search_card(tool_drawer_state, "item_recipe_prep")
	var expected_drawer_deck := ["item_wooden_spoon", "hearty_bagver", "sweet_pup_tart", "item_strainer"]
	var actual_drawer_deck: Array = tool_drawer_state.player.deck.duplicate()
	expected_drawer_deck.sort()
	actual_drawer_deck.sort()
	if tool_drawer_state.player.hand != ["item_recipe_prep"] or actual_drawer_deck != expected_drawer_deck or production_service.rng.state == drawer_search_rng_state or "shuffle your deck" not in String(tool_drawer_state.message).to_lower():
		_fail("Tool Drawer did not take the chosen Tool and shuffle the remaining deck.")
		return
	var empty_drawer_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 6992)
	empty_drawer_state.player.hand = ["item_tool_drawer"]
	empty_drawer_state.player.deck = ["hearty_bagver", "sweet_pup_tart", "spicy_hot_honey_bee", "sweet_sugar_glider"]
	production_service.play_card(empty_drawer_state, 0)
	if empty_drawer_state.pending_search.is_empty() or not production_service.search_candidates(empty_drawer_state).is_empty():
		_fail("Tool Drawer did not show its four revealed cards when none was a Tool.")
		return
	var empty_drawer_rng_state: int = production_service.rng.state
	production_service.skip_search(empty_drawer_state)
	var expected_empty_drawer_deck := ["hearty_bagver", "sweet_pup_tart", "spicy_hot_honey_bee", "sweet_sugar_glider"]
	var actual_empty_drawer_deck: Array = empty_drawer_state.player.deck.duplicate()
	expected_empty_drawer_deck.sort()
	actual_empty_drawer_deck.sort()
	if not empty_drawer_state.pending_search.is_empty() or actual_empty_drawer_deck != expected_empty_drawer_deck or production_service.rng.state == empty_drawer_rng_state or "shuffle your deck" not in String(empty_drawer_state.message).to_lower():
		_fail("Closing a Tool Drawer reveal without taking a card did not shuffle the deck.")
		return

	# Production activated abilities support sacrifice, targeting, and once-per-turn use.
	var jakapeno_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 700)
	jakapeno_state.player.hand = ["spicy_jalapeno_jackal"]
	jakapeno_state.player.deck = ["hearty_bagver", "spicy_sriracharrow", "spicy_hot_honey_bee"]
	production_service.play_card(jakapeno_state, 0, "prep")
	var jakapeno_id := int(jakapeno_state.player.prep[0].instance_id)
	production_service.activate_ability(jakapeno_state, jakapeno_id, "jakapeno_search")
	var spicy_search_candidates: Array[String] = production_service.search_candidates(jakapeno_state)
	if not jakapeno_state.player.prep.is_empty() or jakapeno_state.pending_search.is_empty() or spicy_search_candidates.size() != 2 or spicy_search_candidates.has("hearty_bagver") or jakapeno_state.player.discard.count("spicy_jalapeno_jackal") != 1:
		_fail("Jakapeno did not sacrifice itself and offer only viable Spicy search choices.")
		return
	production_service.select_search_card(jakapeno_state, "spicy_sriracharrow")
	if not jakapeno_state.pending_search.is_empty() or jakapeno_state.player.hand != ["spicy_sriracharrow"] or not jakapeno_state.player.deck.has("spicy_hot_honey_bee"):
		_fail("Jakapeno did not add the selected Spicy card to the hand.")
		return

	# Multiple searches queue and resolve in printed order.
	var chef_bill_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 7001)
	chef_bill_state.player.hand = ["chef_bill"]
	chef_bill_state.player.deck = ["item_wooden_spoon", "spicy_sriracharrow", "spicy_hot_honey_bee"]
	production_service.play_card(chef_bill_state, 0)
	if production_service.search_candidates(chef_bill_state) != ["spicy_hot_honey_bee"] or chef_bill_state.search_queue.size() != 1:
		_fail("Chef Bill did not begin with an Ingredient-only deck choice.")
		return
	production_service.select_search_card(chef_bill_state, "spicy_hot_honey_bee")
	if production_service.search_candidates(chef_bill_state) != ["spicy_sriracharrow"]:
		_fail("Chef Bill did not advance to a Meal-only deck choice.")
		return
	production_service.select_search_card(chef_bill_state, "spicy_sriracharrow")
	if not chef_bill_state.pending_search.is_empty() or not chef_bill_state.search_queue.is_empty() or chef_bill_state.player.hand != ["spicy_hot_honey_bee", "spicy_sriracharrow"]:
		_fail("Chef Bill's queued searches did not add both selected cards.")
		return

	# Revised production stats and simple effect amounts load exactly as authored.
	var vanilla_data: Dictionary = production_service.card("sweet_vanilla_gorilla")
	var strawberry_data: Dictionary = production_service.card("sweet_strawberry_sharkcake")
	var pandacake_data: Dictionary = production_service.card("sweet_pandacake")
	var cinnamon_data: Dictionary = production_service.card("sweet_cinnamon_snail")
	var pup_tart_data: Dictionary = production_service.card("sweet_pup_tart")
	var stewoose_data: Dictionary = production_service.card("hearty_stewoose")
	if int(vanilla_data.attack) != 1 or int(vanilla_data.health) != 2 or int(strawberry_data.attack) != 5 or int(strawberry_data.health) != 6:
		_fail("Vanilla Extract Gorilla or Strawberry Sharkcake did not load its revised stats.")
		return
	if int(pandacake_data.health) != 6 or int(cinnamon_data.attack) != 4 or int(cinnamon_data.health) != 6 or int(pup_tart_data.attack) != 4:
		_fail("Pandacake, Cinnamon Snail, or Pup Tart did not load its revised stats.")
		return
	if int(stewoose_data.attack) != 4 or int(stewoose_data.health) != 8:
		_fail("Stewoose did not load its revised 4/8 stats.")
		return
	if int(production_service.card("sweet_sugar_glider").on_sacrifice[0].amount) != 1 or int(production_service.card("spicy_firecracker_shrimp").on_attack[0].amount) != 2 or int(production_service.card("hearty_baked_potato_pangolin").on_play[0].attack) != 2 or int(production_service.card("hearty_bagver").on_sacrifice[0].amount) != 1:
		_fail("Sugar Glider, Firecracker Shrimp, Baked Potangolin, or Bagver kept an old effect amount.")
		return

	# Wastabi damages only the opposing Plated zone.
	var wastabi_state: Dictionary = production_service.start_game("spicy_test_kitchen", "sweet_test_kitchen", 70015)
	wastabi_state.player.hand = ["spicy_wasabi_wasp"]
	wastabi_state.player.plated = [_test_unit(950, "spicy_hot_honey_bee", "Friendly Bee", "ingredient", 1, 1, false, 2)]
	wastabi_state.opponent.prep = [_test_unit(951, "sweet_caramel_camel", "Prep Camel", "ingredient", 1, 1, false, 2)]
	wastabi_state.opponent.plated = [_test_unit(952, "sweet_toffee_collie", "Plated Collie", "ingredient", 1, 1, false, 2)]
	production_service.play_card(wastabi_state, 0, "prep")
	if int(wastabi_state.player.plated[0].health) != 1 or int(wastabi_state.opponent.prep[0].health) != 1 or not wastabi_state.opponent.plated.is_empty():
		_fail("Wastabi did not damage only opposing Plated units.")
		return

	# Vanilla draws one normally and two with three other Sweet units.
	var vanilla_low_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 7002)
	vanilla_low_state.player.hand = ["sweet_vanilla_gorilla"]
	vanilla_low_state.player.deck = ["sweet_pup_tart", "sweet_sugar_glider", "sweet_caramel_camel"]
	production_service.play_card(vanilla_low_state, 0, "prep")
	if vanilla_low_state.player.hand.size() != 1 or vanilla_low_state.player.deck.size() != 2:
		_fail("Vanilla Extract Gorilla did not draw exactly one without three other Sweet units.")
		return
	var vanilla_high_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 7003)
	vanilla_high_state.player.prep = [
		_test_unit(910, "sweet_sugar_glider", "Sugar Glider", "ingredient", 1, 2, false, 2),
		_test_unit(911, "sweet_caramel_camel", "Choco Bat", "ingredient", 1, 1, false, 2),
		_test_unit(912, "sweet_toffee_collie", "Toffee Collie", "ingredient", 1, 1, false, 2)
	]
	vanilla_high_state.player.hand = ["sweet_vanilla_gorilla"]
	vanilla_high_state.player.deck = ["sweet_pup_tart", "sweet_marshmallow_swallow", "sweet_nutmeg_newt"]
	production_service.play_card(vanilla_high_state, 0, "plated")
	if vanilla_high_state.player.hand.size() != 2 or vanilla_high_state.player.deck.size() != 1:
		_fail("Vanilla Extract Gorilla did not draw two with three other Sweet units.")
		return

	# Ghost Pepython draws only if its play effect actually discarded a card.
	var ghost_empty_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 7004)
	ghost_empty_state.player.hand = ["spicy_ghost_pepper_python"]
	ghost_empty_state.player.deck = ["spicy_sriracharrow", "spicy_hot_honey_bee", "spicy_jalapeno_panther"]
	production_service.play_card(ghost_empty_state, 0, "prep")
	if not ghost_empty_state.player.hand.is_empty() or ghost_empty_state.player.deck.size() != 3:
		_fail("Ghost Pepython drew cards despite discarding no cards.")
		return
	var ghost_discard_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 7005)
	ghost_discard_state.player.hand = ["spicy_ghost_pepper_python", "hearty_bagver"]
	ghost_discard_state.player.deck = ["spicy_sriracharrow", "spicy_hot_honey_bee", "spicy_jalapeno_panther"]
	production_service.play_card(ghost_discard_state, 0, "prep")
	if ghost_discard_state.player.hand.size() != 3 or not ghost_discard_state.player.deck.is_empty() or ghost_discard_state.player.discard.count("hearty_bagver") != 1:
		_fail("Ghost Pepython did not discard at least one card and then draw three.")
		return

	# Prep auras apply their revised bonuses to Plated units and disappear when inactive.
	var bison_aura_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 7006)
	bison_aura_state.player.prep = [_test_unit(920, "hearty_bison_burrito", "Bison Burrito", "meal", 3, 3, false, 2)]
	bison_aura_state.player.plated = [_test_unit(921, "hearty_stewoose", "Stewoose", "meal", 5, 8, true, 2)]
	production_service._refresh_stat_auras(bison_aura_state)
	if int(bison_aura_state.player.plated[0].attack) != 6 or int(bison_aura_state.player.plated[0].health) != 9:
		_fail("Bison Burrito did not grant its revised +1/+1 Prep aura.")
		return
	production_service.move_unit(bison_aura_state, 920, "plated")
	if int(bison_aura_state.player.plated[0].attack) != 5 or int(bison_aura_state.player.plated[0].health) != 8:
		_fail("Bison Burrito's aura did not turn off after leaving Prep.")
		return
	var panda_aura_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 7007)
	panda_aura_state.player.prep = [
		_test_unit(922, "sweet_pandacake", "Pandacake", "meal", 5, 6, false, 2),
		_test_unit(923, "sweet_sugar_glider", "Sugar Glider", "ingredient", 1, 2, false, 2)
	]
	panda_aura_state.player.plated = [_test_unit(924, "sweet_pup_tart", "Pup Tart", "meal", 4, 5, true, 2)]
	production_service._refresh_stat_auras(panda_aura_state)
	if int(panda_aura_state.player.plated[0].health) != 7 or int(panda_aura_state.player.prep[1].health) != 2:
		_fail("Pandacake did not give only other Plated units +2 Health.")
		return

	# Mastiff Potato grows only on its first Prep-to-Plated move.
	var mastiff_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 7008)
	mastiff_state.player.prep = [_test_unit(925, "hearty_mastiff_potato", "Mastiff Potato", "meal", 4, 6, false, 2)]
	production_service.move_unit(mastiff_state, 925, "plated")
	if int(mastiff_state.player.plated[0].attack) != 6 or int(mastiff_state.player.plated[0].health) != 8:
		_fail("Mastiff Potato did not gain +2/+2 on its first move to Plated.")
		return
	production_service._start_turn(mastiff_state, "player", false)
	production_service.move_unit(mastiff_state, 925, "prep")
	production_service._start_turn(mastiff_state, "player", false)
	production_service.move_unit(mastiff_state, 925, "plated")
	if int(mastiff_state.player.plated[0].attack) != 6 or int(mastiff_state.player.plated[0].health) != 8:
		_fail("Mastiff Potato gained +2/+2 more than once.")
		return

	# Cinnamon taxes opposing recipes only while it is Plated.
	var cinnamon_state: Dictionary = production_service.start_game("sweet_test_kitchen", "hearty_test_kitchen", 7009)
	cinnamon_state.opponent.plated = [_test_unit(926, "sweet_cinnamon_snail", "Cinnamon Snail", "meal", 5, 6, false, 2)]
	if production_service._effective_recipe(cinnamon_state, "player", strawberry_data).size() != 3:
		_fail("Plated Cinnamon Snail did not add an Ingredient to the opposing recipe.")
		return
	cinnamon_state.opponent.prep.append(cinnamon_state.opponent.plated.pop_front())
	if production_service._effective_recipe(cinnamon_state, "player", strawberry_data).size() != 2:
		_fail("Cinnamon Snail continued taxing recipes while in Prep.")
		return

	# Baked Potangolin's +2 Attack expires at the end of the turn.
	var baked_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 7010)
	baked_state.player.plated = [_test_unit(927, "hearty_stewoose", "Stewoose", "meal", 5, 8, true, 2)]
	baked_state.player.hand = ["hearty_baked_potato_pangolin"]
	production_service.play_card(baked_state, 0, "prep")
	if production_service.choice_target_ids(baked_state) != [927]:
		_fail("Baked Potangolin did not request a friendly Plated target.")
		return
	production_service.choose_effect_target(baked_state, 927)
	if int(baked_state.player.plated[0].attack) != 7:
		_fail("Baked Potangolin did not grant +2 Attack for the turn.")
		return
	production_service._clear_temporary_buffs(baked_state.player)
	if int(baked_state.player.plated[0].attack) != 5:
		_fail("Baked Potangolin's temporary Attack did not expire.")
		return

	# Toffee Collie and Donutphin trigger only after damaging the opposing chef.
	var chef_damage_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 7011)
	chef_damage_state.player.turns_started = 2
	chef_damage_state.player.plated = [_test_unit(928, "sweet_toffee_collie", "Toffee Collie", "ingredient", 1, 1, true, 2)]
	chef_damage_state.opponent.plated = [_test_unit(929, "spicy_jalapeno_panther", "Jalapeño Panther", "ingredient", 2, 3, false, 2)]
	production_service.select_attacker(chef_damage_state, 928)
	production_service.attack(chef_damage_state, 929)
	if bool(chef_damage_state.opponent.items_disabled):
		_fail("Toffee Collie disabled Items without damaging the opposing chef.")
		return
	var direct_damage_state: Dictionary = production_service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 7012)
	direct_damage_state.player.turns_started = 2
	direct_damage_state.player.plated = [
		_test_unit(930, "sweet_toffee_collie", "Toffee Collie", "ingredient", 1, 1, true, 2),
		_test_unit(931, "sweet_donutphin", "Donutphin", "meal", 3, 4, true, 2)
	]
	production_service.select_attacker(direct_damage_state, 930)
	production_service.attack(direct_damage_state, -1)
	production_service.select_attacker(direct_damage_state, 931)
	production_service.attack(direct_damage_state, -1)
	if not bool(direct_damage_state.opponent.items_disabled) or not bool(direct_damage_state.opponent.chefs_disabled):
		_fail("Toffee Collie or Donutphin did not trigger after damaging the opposing chef.")
		return

	var vindaloo_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 701)
	vindaloo_state.player.prep = [_test_unit(900, "spicy_vindaloo_beluga", "Vindaloo Beluga", "meal", 3, 3, false, 2)]
	vindaloo_state.opponent.prep = [_test_unit(904, "hearty_bagver", "Prep Bagver", "ingredient", 1, 2, false, 2)]
	vindaloo_state.opponent.plated = [_test_unit(901, "hearty_stewoose", "Stewoose", "meal", 6, 5, false, 2)]
	production_service.activate_ability(vindaloo_state, 900, "vindaloo_sacrifice")
	if vindaloo_state.pending_ability.is_empty() or String(vindaloo_state.pending_ability.target_zone) != "plated" or vindaloo_state.player.prep.is_empty():
		_fail("Vindaloo Beluga did not wait for a Plated enemy target before paying its cost.")
		return
	production_service.choose_ability_target(vindaloo_state, 904)
	if vindaloo_state.pending_ability.is_empty() or vindaloo_state.player.prep.is_empty():
		_fail("Vindaloo Beluga accepted a Prep target or paid its sacrifice for an invalid target.")
		return
	production_service.choose_ability_target(vindaloo_state, 901)
	if not vindaloo_state.pending_ability.is_empty() or not vindaloo_state.player.prep.is_empty() or int(vindaloo_state.opponent.plated[0].health) != 1 or vindaloo_state.opponent.prep.is_empty():
		_fail("Vindaloo Beluga did not sacrifice itself and deal 4 to the selected Plated target.")
		return

	var polar_state: Dictionary = production_service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 702)
	polar_state.player.prep = [_test_unit(903, "hearty_bagver", "Bagver", "ingredient", 1, 1, false, 2)]
	polar_state.player.plated = [_test_unit(902, "hearty_polar_pot_pie_bear", "Polar Pot Pie Bear", "meal", 8, 6, false, 2)]
	polar_state.player.prep[0].max_health = 3
	polar_state.player.plated[0].max_health = 8
	production_service.activate_ability(polar_state, 902, "pot_pie_heal")
	if int(polar_state.player.prep[0].health) != 2 or int(polar_state.player.plated[0].health) != 6:
		_fail("Plated Polar Pot Pie Bear did not heal each other unit for exactly 1 while excluding itself.")
		return
	polar_state.player.prep[0].health = 1
	production_service.activate_ability(polar_state, 902, "pot_pie_heal")
	if int(polar_state.player.prep[0].health) != 1:
		_fail("Polar Pot Pie Bear used its once-per-turn ability twice.")
		return
	production_service._start_turn(polar_state, "player", false)
	production_service.activate_ability(polar_state, 902, "pot_pie_heal")
	if int(polar_state.player.prep[0].health) != 2:
		_fail("Polar Pot Pie Bear's ability did not reset on the next turn.")
		return
	polar_state.player.prep.append(polar_state.player.plated.pop_front())
	production_service._start_turn(polar_state, "player", false)
	polar_state.player.prep[0].health = 1
	production_service.activate_ability(polar_state, 902, "pot_pie_heal")
	if int(polar_state.player.prep[0].health) != 1:
		_fail("Polar Pot Pie Bear used its ability while it was in Prep.")
		return

	var production_state: Dictionary = production_service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 777)
	for unused in range(5):
		if bool(production_state.game_over):
			break
		production_service.end_player_turn(production_state)
	if int(production_state.turn) < 2:
		_fail("Production card game did not progress through AI turns.")
		return

	# The production catalog must load into the complete game board.
	var prototype := GAME_SCENE.instantiate()
	root.add_child(prototype)
	await process_frame
	await process_frame
	# The service also registers one non-collectible Fresh token at runtime.
	if String(prototype.state.phase) != "player_main" or prototype.service.cards_by_id.size() != 89:
		_fail("Production card catalog did not load into a playable game.")
		return
	if _count_prefix(prototype, "CookingPlayerPrepSlot_") != 3 or _count_prefix(prototype, "CookingPlayerPlatedSlot_") != 2:
		_fail("Player board did not render three Prep and two Plated slots.")
		return
	if _count_prefix(prototype, "CookingOpponentPrepSlot_") != 3 or _count_prefix(prototype, "CookingOpponentPlatedSlot_") != 2:
		_fail("Opponent board did not render three Prep and two Plated slots.")
		return
	var player_life_badge := prototype.find_child("CookingPlayerLifeBadge", true, false) as Control
	var opponent_life_badge := prototype.find_child("CookingOpponentLifeBadge", true, false) as Control
	if player_life_badge == null or opponent_life_badge == null:
		_fail("The tabletop presentation did not render standalone Chef life badges.")
		return
	if prototype.find_child("CookingPlayerLifeIcon", true, false) == null or prototype.find_child("CookingOpponentLifeIcon", true, false) == null:
		_fail("The tabletop presentation did not render the font-independent Chef life icons.")
		return
	var combat_font_line := TextLine.new()
	combat_font_line.add_string("1🌶️2🧊3🍋‍🟩4", prototype.card_font, 32)
	var combat_glyphs := TextServerManager.get_primary_interface().shaped_text_get_glyphs(combat_font_line.get_rid())
	if combat_glyphs.size() != 7 or int(combat_glyphs[0].index) <= 16 or int(combat_glyphs[1].index) > 16 or int(combat_glyphs[3].index) > 16 or int(combat_glyphs[5].index) > 16:
		_fail("The combat card font did not preserve normal numbers while routing type symbols through the Noto subset.")
		return
	var player_plated_lane := prototype.find_child("CookingPlayerPlatedZone", true, false) as Control
	var player_prep_lane := prototype.find_child("CookingPlayerPrepZone", true, false) as Control
	var opponent_plated_lane := prototype.find_child("CookingOpponentPlatedZone", true, false) as Control
	var opponent_prep_lane := prototype.find_child("CookingOpponentPrepZone", true, false) as Control
	if player_plated_lane == null or player_prep_lane == null or opponent_plated_lane == null or opponent_prep_lane == null or player_plated_lane.get_index() >= player_prep_lane.get_index() or opponent_prep_lane.get_index() >= opponent_plated_lane.get_index():
		_fail("The mirrored tabletop did not place both Plated lanes toward the center.")
		return
	if _count_prefix(prototype, "CookingOpponentHandCard_") != prototype.state.opponent.hand.size():
		_fail("The opponent hand fan did not show one card back per hidden card.")
		return
	var opponent_half := prototype.find_child("CookingOpponentTableHalf", true, false) as Control
	var message_strip := prototype.find_child("CookingMessagePanel", true, false) as Control
	var player_half := prototype.find_child("CookingPlayerTableHalf", true, false) as Control
	if opponent_half == null or message_strip == null or player_half == null or not (opponent_half.get_index() < message_strip.get_index() and message_strip.get_index() < player_half.get_index()):
		_fail("The message strip was not centered between the mirrored table halves.")
		return
	var end_turn := prototype.find_child("CookingEndTurnButton", true, false) as Button
	if end_turn == null or end_turn.disabled:
		_fail("Loaded game board did not enable gameplay.")
		return

	# The experimental authored board remains isolated in its own scene and keeps
	# the stable Kitchen Match procedural layout untouched.
	var arena_prototype := ARENA_GAME_SCENE.instantiate()
	root.add_child(arena_prototype)
	await process_frame
	await process_frame
	var arena_player_plated := arena_prototype.find_child("PlayerPlatedZone", true, false) as Control
	var arena_player_prep := arena_prototype.find_child("PlayerPrepZone", true, false) as Control
	var arena_opponent_plated := arena_prototype.find_child("OpponentPlatedZone", true, false) as Control
	var arena_opponent_prep := arena_prototype.find_child("OpponentPrepZone", true, false) as Control
	var arena_message := arena_prototype.find_child("CenterMessageAnchor", true, false) as Control
	var arena_opponent_area := arena_prototype.find_child("OpponentArea", true, false) as Control
	var arena_player_area := arena_prototype.find_child("PlayerArea", true, false) as Control
	if arena_player_plated == null or arena_player_prep == null or arena_opponent_plated == null or arena_opponent_prep == null or arena_message == null or arena_opponent_area == null or arena_player_area == null:
		_fail("The isolated 3D Arena scene did not populate all authored board anchors.")
		return
	if not (arena_opponent_prep.global_position.y < arena_opponent_plated.global_position.y and arena_opponent_plated.global_position.y < arena_message.global_position.y and arena_message.global_position.y < arena_player_plated.global_position.y and arena_player_plated.global_position.y < arena_player_prep.global_position.y) or arena_opponent_area.scale.x >= arena_player_area.scale.x:
		_fail("The isolated 3D Arena lost its mirrored perspective layout.")
		return
	var interface_overlay := arena_prototype.find_child("InterfaceOverlay", true, false) as Control
	var result_anchor := arena_prototype.find_child("ResultPopupAnchor", true, false) as Control
	if interface_overlay == null or result_anchor == null or interface_overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE or result_anchor.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("An inactive 3D Arena overlay can still intercept board clicks.")
		return
	arena_prototype.state.player.hand = ["spicy_hot_honey_bee"]
	arena_prototype.state.player.prep = [_test_unit(942, "spicy_hot_honey_bee", "Hot Honey Bee", "ingredient", 1, 1, false, 2)]
	arena_prototype._refresh()
	await process_frame
	await process_frame
	var arena_card := arena_prototype.find_child("CookingHandCard_0", true, false) as Control
	var arena_hand_face := arena_prototype.find_child("CookingHandAuthoredFace_0", true, false) as Control
	var arena_board_face := arena_prototype.find_child("CookingPlayerPrepAuthoredFace_0", true, false) as Control
	var arena_card_icon := arena_hand_face.find_child("CardAffinityIcon", true, false) as Label if arena_hand_face != null else null
	var arena_hand_rules := arena_hand_face.find_child("CardRules", true, false) as Label if arena_hand_face != null else null
	if arena_hand_face == null or arena_board_face == null:
		_fail("Spicy Ingredient card faces did not render in the playable hand and board zones.")
		return
	if arena_hand_rules == null or not arena_hand_rules.visible:
		_fail("The playable hand used a compact placeholder instead of the full card face.")
		return
	if arena_card_icon == null or not arena_card_icon.get_theme_font("font").has_char(0x1F336):
		_fail("The playable card's top-left affinity icon did not use the Noto emoji subset.")
		return
	var full_drag_preview := arena_prototype._make_drag_preview("spicy_hot_honey_bee", "From your hand") as Control
	var drag_preview_rules := full_drag_preview.find_child("CardRules", true, false) as Label if full_drag_preview != null else null
	if full_drag_preview == null or full_drag_preview.name != "CookingFullCardDragPreview" or drag_preview_rules == null or not drag_preview_rules.visible:
		_fail("Dragging an authored card still used a temporary text preview instead of the full card.")
		return
	full_drag_preview.free()
	var arena_press := InputEventMouseButton.new()
	arena_press.button_index = MOUSE_BUTTON_LEFT
	arena_press.position = Vector2(20, 20)
	arena_press.pressed = true
	arena_card.gui_input.emit(arena_press)
	var arena_release := InputEventMouseButton.new()
	arena_release.button_index = MOUSE_BUTTON_LEFT
	arena_release.position = Vector2(20, 20)
	arena_release.pressed = false
	arena_card.gui_input.emit(arena_release)
	await process_frame
	await process_frame
	var arena_actions := arena_prototype.find_child("CookingHandActions_0", true, false) as PanelContainer
	var arena_action_buttons := arena_actions.find_children("*", "Button", true, false) if arena_actions != null else []
	var arena_play_button := arena_action_buttons[0] as Button if not arena_action_buttons.is_empty() else null
	var arena_button_style := arena_play_button.get_theme_stylebox("normal") as StyleBoxFlat if arena_play_button != null else null
	var arena_inspector := arena_prototype.find_child("CookingInspectPanel", true, false) as PanelContainer
	if arena_actions == null or arena_play_button == null or arena_button_style == null or arena_button_style.corner_radius_top_left < 8 or arena_inspector == null or String(arena_prototype.inspected_card.get("card_id", "")) != "spicy_hot_honey_bee":
		_fail("Clicking the full hand card did not immediately open details and reveal rounded play buttons above it.")
		return
	if arena_prototype.find_child("CookingHandDetails_0", true, false) != null:
		_fail("The hand action strip still rendered a redundant Details button.")
		return
	arena_prototype.queue_free()
	await process_frame

	# Live matches reveal one opponent action per beat instead of resolving the full turn synchronously.
	prototype.state.opponent.hand = ["hearty_bagver", "hearty_macaroni_manatee"]
	prototype.state.opponent.deck = []
	prototype.state.opponent.prep = []
	prototype.state.opponent.plated = []
	prototype._end_player_turn_with_sequence()
	if String(prototype.state.phase) != "opponent_turn" or not prototype.state.opponent.prep.is_empty():
		_fail("The live board resolved opponent actions immediately after End Turn.")
		return
	await create_timer(1.15).timeout
	if not prototype.state.opponent.prep.is_empty():
		_fail("The opponent draw beat also played a card instead of pausing for presentation.")
		return
	await create_timer(1.15).timeout
	if prototype.state.opponent.prep.size() != 1 or prototype.state.opponent.hand.size() != 1:
		_fail("The live opponent sequence did not reveal exactly one card play on its next beat.")
		return
	await process_frame
	await process_frame
	var opponent_hand_origin := prototype.find_child("CookingOpponentHandOrigin", true, false) as Control
	var played_card_ghost := prototype.find_child("CookingOpponentPlayedCardGhost", true, false) as Control
	if opponent_hand_origin == null or played_card_ghost == null:
		_fail("The live opponent play did not animate a card from the visible hand origin (origin=%s, ghost=%s)." % [opponent_hand_origin != null, played_card_ghost != null])
		return
	var opponent_wait_safety := 8
	while String(prototype.state.phase) == "opponent_turn" and opponent_wait_safety > 0:
		opponent_wait_safety -= 1
		await create_timer(0.75).timeout
	if String(prototype.state.phase) != "player_main":
		_fail("The paced live opponent sequence did not return control to the player.")
		return

	# Pressing a card must leave it alive long enough for Godot to begin a drag.
	prototype.state.player.hand = ["spicy_hot_honey_bee"]
	prototype._refresh()
	await process_frame
	await process_frame
	var drag_source := prototype.find_child("CookingHandCard_0", true, false) as Control
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(20, 20)
	press.pressed = true
	drag_source.gui_input.emit(press)
	await process_frame
	await process_frame
	if not is_instance_valid(drag_source) or not prototype.inspected_card.is_empty():
		_fail("Pressing a hand card rebuilt the board before a drag could begin.")
		return
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(20, 20)
	release.pressed = false
	drag_source.gui_input.emit(release)
	await process_frame
	await process_frame
	var click_actions := prototype.find_child("CookingHandActions_0", true, false) as PanelContainer
	if click_actions == null or prototype.find_child("CookingHandDetails_0", true, false) != null or String(prototype.inspected_card.get("card_id", "")) != "spicy_hot_honey_bee" or prototype.find_child("CookingInspectPanel", true, false) == null:
		_fail("A click-release did not open card details automatically alongside the play actions.")
		return
	prototype.inspected_card = {}
	prototype._refresh()
	await process_frame
	await process_frame
	var turn_badge := prototype.find_child("CookingTurnOwnerBadge", true, false) as Label
	if turn_badge == null or not turn_badge.text.begins_with("YOUR TURN"):
		_fail("The match UI did not make the active turn owner obvious.")
		return
	drag_source = prototype.find_child("CookingHandCard_0", true, false) as Control
	var highlighted_prep := prototype.find_child("CookingPlayerPrepSlot_0", true, false) as Control
	var dimmed_environment := prototype.find_child("CookingPlayerEnvironment", true, false) as Control
	var dimmed_environment_panel: Control = dimmed_environment.get_meta("zone_panel", dimmed_environment)
	var highlight_payload := {"kind": "hand_card", "hand_index": 0, "card_id": "spicy_hot_honey_bee"}
	prototype._begin_drag_feedback(highlight_payload, drag_source)
	if highlighted_prep.modulate.r <= 1.0 or dimmed_environment_panel.modulate.r >= 0.8:
		_fail("Dragging a unit did not highlight legal unit zones and dim illegal zones.")
		return
	prototype._finish_drag_feedback()
	await process_frame
	if not prototype.active_drag_payload.is_empty() or not is_instance_valid(prototype.floating_feedback):
		_fail("An invalid drag did not snap back with visible error feedback.")
		return

	# The visual-state diff recognizes draws, damage, destruction, entry, and recipe sacrifices.
	var before_visual := {
		"turn": 1, "phase": "player_main", "selected_ingredients": [501],
		"visual_action_serial": 3, "last_visual_action": {},
		"player": {"life": 25, "hand": ["spicy_hot_honey_bee"], "environment": "", "units": {
			501: {"instance_id": 501, "card_id": "spicy_hot_honey_bee", "name": "Hot Honey Bee", "card_type": "ingredient", "zone": "prep", "health": 2, "attack": 1}
		}},
		"opponent": {"life": 25, "hand": ["hearty_bagver"], "environment": "", "units": {
			601: {"instance_id": 601, "card_id": "hearty_bagver", "name": "Bagver", "card_type": "ingredient", "zone": "plated", "health": 2, "attack": 1}
		}}
	}
	var after_visual := before_visual.duplicate(true)
	after_visual.turn = 2
	after_visual.player.hand.append("spice_cayenne_crunch")
	after_visual.player.units.erase(501)
	after_visual.player.units[502] = {"instance_id": 502, "card_id": "spicy_sriracharrow", "name": "Sriracharrow", "card_type": "meal", "zone": "plated", "health": 4, "attack": 5}
	after_visual.visual_action_serial = 4
	after_visual.last_visual_action = {"side": "opponent", "card_id": "hearty_bagver", "action_kind": "ingredient", "target_instance_id": 602}
	after_visual.opponent.hand = []
	after_visual.opponent.units[602] = {"instance_id": 602, "card_id": "hearty_bagver", "name": "Bagver", "card_type": "ingredient", "zone": "prep", "health": 2, "attack": 1}
	after_visual.opponent.units[601].zone = "prep"
	after_visual.opponent.units[601].health = 1
	after_visual.opponent.life = 23
	var visual_events: Array[Dictionary] = prototype._collect_visual_events(before_visual, after_visual)
	if not _has_visual_event(visual_events, "opponent_hand_play") or not _has_visual_event(visual_events, "enter", 602) or not _has_visual_event(visual_events, "move", 601) or not _has_visual_event(visual_events, "draw") or not _has_visual_event(visual_events, "enter", 502) or not _has_visual_event(visual_events, "sacrifice", 501) or not _has_visual_event(visual_events, "damage", 601) or not _has_visual_event(visual_events, "life_damage") or not _has_visual_event(visual_events, "turn"):
		_fail("The presentation layer did not recognize every required combat animation event.")
		return

	# Drag helpers play hand cards, move field cards, attach Spices, set Environments, and battle.
	prototype.state.phase = "player_main"
	prototype.state.player.turns_started = 2
	prototype.state.player.zone_move_used = false
	prototype.state.player.prep = []
	prototype.state.player.plated = []
	prototype.state.player.hand = ["spicy_hot_honey_bee"]
	prototype.state.opponent.life = 25
	var ingredient_drag := {"kind": "hand_card", "hand_index": 0, "card_id": "spicy_hot_honey_bee"}
	if not prototype._can_drop_on_unit_slot(ingredient_drag, {}, "prep", true):
		_fail("A hand Ingredient was not accepted by an open Prep drag target.")
		return
	prototype._drop_on_unit_slot(ingredient_drag, {}, "prep", true)
	await process_frame
	await process_frame
	if prototype.state.player.prep.size() != 1 or String(prototype.state.player.prep[0].card_id) != "spicy_hot_honey_bee":
		_fail("Dragging an Ingredient from hand did not play it to Prep.")
		return
	var dragged_unit_id := int(prototype.state.player.prep[0].instance_id)
	var move_drag := {"kind": "unit", "instance_id": dragged_unit_id, "card_id": "spicy_hot_honey_bee", "from_zone": "prep"}
	if not prototype._can_drop_on_unit_slot(move_drag, {}, "plated", true):
		_fail("A Prep card was not accepted by an open Plated drag target.")
		return
	prototype._drop_on_unit_slot(move_drag, {}, "plated", true)
	await process_frame
	await process_frame
	if not prototype.state.player.prep.is_empty() or prototype.state.player.plated.size() != 1:
		_fail("Dragging a field card did not move it from Prep to Plated.")
		return
	if prototype.find_child("CookingZoneMoveGhost", true, false) == null:
		_fail("A Prep/Plated move did not create its visible traveling-card animation.")
		return
	await create_timer(0.7).timeout
	prototype.state.player.hand = ["spice_cayenne_crunch"]
	var spice_drag := {"kind": "hand_card", "hand_index": 0, "card_id": "spice_cayenne_crunch"}
	if not prototype._can_drop_on_unit_slot(spice_drag, prototype.state.player.plated[0], "plated", true):
		_fail("A hand Spice was not accepted by an unseasoned friendly card.")
		return
	prototype._drop_on_unit_slot(spice_drag, prototype.state.player.plated[0], "plated", true)
	await process_frame
	await process_frame
	if int(prototype.state.player.plated[0].attack) != 2 or prototype.state.player.plated[0].spices != ["spice_cayenne_crunch"]:
		_fail("Dragging a Spice did not attach it and apply its bonus.")
		return
	prototype.state.player.hand = ["environment_blazing_wok"]
	var environment_drag := {"kind": "hand_card", "hand_index": 0, "card_id": "environment_blazing_wok"}
	if not prototype._can_drop_environment(environment_drag):
		_fail("A hand Environment was not accepted by the Environment drag target.")
		return
	prototype._drop_environment(environment_drag)
	await process_frame
	await process_frame
	if String(prototype.state.player.environment) != "environment_blazing_wok":
		_fail("Dragging an Environment did not establish it.")
		return
	prototype.state.player.plated[0].ready = true
	prototype.state.opponent.plated = [_test_unit(937, "hearty_bagver", "Bagver", "ingredient", 0, 2, false, 2)]
	prototype._refresh()
	await process_frame
	await process_frame
	var ready_badge := prototype.find_child("CookingReadyBadge_%d" % dragged_unit_id, true, false) as Label
	if ready_badge == null:
		_fail("A ready Plated attacker did not render its readiness badge.")
		return
	prototype.service.select_attacker(prototype.state, dragged_unit_id)
	prototype._refresh()
	await process_frame
	await process_frame
	var target_badge := prototype.find_child("CookingLegalTarget_937", true, false) as Label
	if target_badge == null:
		_fail("Selecting an attacker did not mark its legal defender target.")
		return
	var battle_drag := {"kind": "unit", "instance_id": dragged_unit_id, "card_id": "spicy_hot_honey_bee", "from_zone": "plated"}
	if not prototype._can_drop_on_unit_slot(battle_drag, prototype.state.opponent.plated[0], "plated", false):
		_fail("A ready Plated attacker was not accepted by an opposing Plated drag target.")
		return
	prototype._drop_on_unit_slot(battle_drag, prototype.state.opponent.plated[0], "plated", false)
	await process_frame
	await process_frame
	if not prototype.state.opponent.plated.is_empty() or bool(prototype.state.player.plated[0].ready):
		_fail("Dragging an attacker onto a defender did not resolve battle.")
		return

	# The rendered face-attack action recognizes Stalwart while defenders remain Plated.
	prototype.state.opponent.life = 25
	prototype.state.player.turns_started = 2
	prototype.state.player.plated = [_test_unit(939, "spicy_red_pepper_panda", "Red Pepper Panda", "ingredient", 1, 2, true, 2)]
	prototype.state.opponent.plated = [_test_unit(938, "hearty_french_bread_dog", "French Bread Dog", "ingredient", 1, 2, false, 2)]
	prototype.service.select_attacker(prototype.state, 939)
	prototype._refresh()
	await process_frame
	await process_frame
	var stalwart_face_attack := prototype.find_child("CookingAttackChefButton", true, false) as Button
	if stalwart_face_attack == null or stalwart_face_attack.disabled or not stalwart_face_attack.text.contains("Stalwart"):
		_fail("The kitchen UI did not enable or identify Stalwart's direct chef attack.")
		return
	var stalwart_drag := {"kind": "unit", "instance_id": 939, "card_id": "spicy_red_pepper_panda", "from_zone": "plated"}
	if not prototype._can_drop_on_opponent_face(stalwart_drag):
		_fail("A Stalwart attacker was not accepted by the opposing-chef drag target through Plated cards.")
		return
	prototype._drop_on_opponent_face(stalwart_drag)
	await process_frame
	await process_frame
	if int(prototype.state.opponent.life) != 24 or int(prototype.state.opponent.plated[0].health) != 2:
		_fail("The rendered Stalwart attack did not bypass the opposing Plated card.")
		return

	# Board, discard, and revealed-hand choices all render their legal interactive targets.
	prototype.state.player.prep = []
	prototype.state.player.plated = [_test_unit(941, "hearty_bagver", "Bagver", "ingredient", 1, 2, false, 2)]
	prototype.state.opponent.prep = []
	prototype.state.opponent.plated = []
	prototype.state.player.hand = ["hearty_ramen_ram"]
	prototype.service.play_card(prototype.state, 0, "prep")
	prototype._refresh()
	await process_frame
	await process_frame
	var choose_ramen_target := prototype.find_child("CookingEffectTarget_941", true, false) as Button
	if choose_ramen_target == null:
		_fail("The kitchen UI did not render Ramen's legal board target.")
		return
	choose_ramen_target.emit_signal("pressed")
	await process_frame
	await process_frame
	if int(prototype.state.player.plated[0].attack) != 2 or not prototype.state.pending_choice.is_empty():
		_fail("The rendered board-target picker did not resolve Ramen on the chosen card.")
		return
	prototype.state.player.hand = ["chef_carl"]
	prototype.state.player.discard = ["hearty_dumpling_tortoise", "hearty_stewoose", "hearty_bagver"]
	prototype.state.player.chef_used = false
	prototype.service.play_card(prototype.state, 0)
	prototype._refresh()
	await process_frame
	await process_frame
	var choose_discard_meal := prototype.find_child("CookingSelectDiscardPile_1", true, false) as Button
	var confirm_discard_pile := prototype.find_child("CookingConfirmDiscardPileButton", true, false) as Button
	if choose_discard_meal == null or confirm_discard_pile == null or not confirm_discard_pile.disabled:
		_fail("The kitchen UI did not render Chef Carl's discard-pile picker.")
		return
	choose_discard_meal.emit_signal("pressed")
	await process_frame
	await process_frame
	confirm_discard_pile = prototype.find_child("CookingConfirmDiscardPileButton", true, false) as Button
	if confirm_discard_pile == null or confirm_discard_pile.disabled:
		_fail("Chef Carl's discard confirmation did not enable after one selection.")
		return
	confirm_discard_pile.emit_signal("pressed")
	await process_frame
	await process_frame
	if prototype.state.player.hand != ["hearty_stewoose"]:
		_fail("Chef Carl's rendered picker did not return the selected Meal.")
		return
	prototype.state.player.hand = ["item_tongs"]
	prototype.state.opponent.hand = ["item_wooden_spoon", "hearty_bagver"]
	prototype.state.opponent.prep = []
	prototype.state.opponent.plated = []
	prototype.service.play_card(prototype.state, 0)
	prototype._refresh()
	await process_frame
	await process_frame
	var blocked_opponent_tool := prototype.find_child("CookingChooseOpponentHand_0", true, false) as Button
	var choose_opponent_unit := prototype.find_child("CookingChooseOpponentHand_1", true, false) as Button
	if blocked_opponent_tool == null or not blocked_opponent_tool.disabled or choose_opponent_unit == null or choose_opponent_unit.disabled:
		_fail("Tongs did not reveal the opponent's hand with only its unit enabled.")
		return
	choose_opponent_unit.emit_signal("pressed")
	await process_frame
	await process_frame
	if prototype.state.opponent.prep.size() != 1 or String(prototype.state.opponent.prep[0].card_id) != "hearty_bagver":
		_fail("Tongs' rendered hand picker did not deploy the selected unit.")
		return

	# The kitchen card inspector explains live zone rules and follows a card when it moves.
	prototype.state.player.prep = [_test_unit(940, "sweet_pandacake", "Pandacake", "meal", 5, 6, false, 2)]
	prototype.state.player.plated = []
	prototype.state.opponent.plated = []
	prototype._refresh()
	await process_frame
	await process_frame
	var inspect_pandacake := prototype.find_child("CookingInspectCard_Player_Prep_940", true, false) as Button
	if inspect_pandacake == null:
		_fail("A field card did not render its inspect control.")
		return
	inspect_pandacake.emit_signal("pressed")
	await process_frame
	await process_frame
	var inspect_panel := prototype.find_child("CookingInspectPanel", true, false) as PanelContainer
	var inspect_name := prototype.find_child("CookingInspectName", true, false) as Label
	var inspect_zone := prototype.find_child("CookingInspectZoneStatus", true, false) as Label
	var inspect_effects := prototype.find_child("CookingInspectZoneEffects", true, false) as Label
	if inspect_panel == null or inspect_name == null or inspect_name.text != "🍬 Pandacake":
		_fail("The kitchen card inspect popout did not open with the selected card.")
		return
	if inspect_zone == null or not inspect_zone.text.contains("Prep zone") or inspect_effects == null or not inspect_effects.text.contains("ACTIVE"):
		_fail("The inspect popout did not mark Pandacake's Prep effect as active.")
		return
	prototype.state.player.plated = [prototype.state.player.prep.pop_front()]
	prototype._refresh()
	await process_frame
	await process_frame
	inspect_zone = prototype.find_child("CookingInspectZoneStatus", true, false) as Label
	inspect_effects = prototype.find_child("CookingInspectZoneEffects", true, false) as Label
	if inspect_zone == null or not inspect_zone.text.contains("Plated zone") or inspect_effects == null or not inspect_effects.text.contains("INACTIVE — REQUIRES PREP"):
		_fail("The inspect popout did not follow the card and deactivate its Prep-only effect in Plated.")
		return
	var close_inspect := prototype.find_child("CookingInspectCloseButton", true, false) as Button
	if close_inspect == null:
		_fail("The kitchen card inspect popout did not render its close control.")
		return
	close_inspect.emit_signal("pressed")
	await process_frame
	await process_frame
	if prototype.find_child("CookingInspectPanel", true, false) != null:
		_fail("The kitchen card inspect popout did not close.")
		return
	prototype.state.player.prep = []
	prototype.state.player.plated = []

	# Tool Drawer uses the rendered picker, showing all four cards but enabling only Tools.
	prototype.state.player.hand = ["item_tool_drawer"]
	prototype.state.player.deck = ["item_wooden_spoon", "hearty_bagver", "item_recipe_prep", "sweet_pup_tart", "item_strainer"]
	prototype._refresh()
	await process_frame
	await process_frame
	var tool_drawer_card := prototype.find_child("CookingHandCard_0", true, false) as Control
	prototype._toggle_hand_card_actions(tool_drawer_card, 0, "item_tool_drawer")
	var play_tool_drawer := prototype.find_child("CookingPlayHandCard_0_item_tool_drawer", true, false) as Button
	if play_tool_drawer == null:
		_fail("Tool Drawer did not reveal its play button above the clicked full card.")
		return
	play_tool_drawer.emit_signal("pressed")
	await process_frame
	await process_frame
	var take_top_tool := prototype.find_child("CookingTakeSearchCard_item_strainer", true, false) as Button
	var blocked_non_tool := prototype.find_child("CookingTakeSearchCard_sweet_pup_tart", true, false) as Button
	var hidden_fifth_card := prototype.find_child("CookingTakeSearchCard_item_wooden_spoon", true, false) as Button
	if take_top_tool == null or take_top_tool.disabled or blocked_non_tool == null or not blocked_non_tool.disabled or hidden_fifth_card != null:
		_fail("Tool Drawer's picker did not show exactly four cards with only revealed Tools enabled.")
		return
	take_top_tool.emit_signal("pressed")
	await process_frame
	await process_frame
	if not prototype.state.pending_search.is_empty() or prototype.state.player.hand != ["item_strainer"]:
		_fail("Tool Drawer's rendered picker did not add the selected Tool to hand.")
		return

	# Exercise the discard picker through the rendered production UI.
	prototype.state.player.hand = ["item_recipe_prep", "spicy_hot_honey_bee", "spicy_jalapeno_panther", "spicy_sriracharrow"]
	prototype.state.player.deck = []
	prototype._refresh()
	await process_frame
	await process_frame
	var recipe_prep_card := prototype.find_child("CookingHandCard_0", true, false) as Control
	prototype._toggle_hand_card_actions(recipe_prep_card, 0, "item_recipe_prep")
	var play_discard_item := prototype.find_child("CookingPlayHandCard_0_item_recipe_prep", true, false) as Button
	if play_discard_item == null:
		_fail("The discard-cost Item did not reveal a play button above the clicked full card.")
		return
	play_discard_item.emit_signal("pressed")
	await process_frame
	await process_frame
	var first_discard_card := prototype.find_child("CookingHandCard_1", true, false) as Control
	prototype._toggle_hand_card_actions(first_discard_card, 1, "spicy_hot_honey_bee")
	var first_discard_choice := prototype.find_child("CookingDiscardChoice_1", true, false) as Button
	var confirm_discard := prototype.find_child("CookingConfirmDiscardButton", true, false) as Button
	var cancel_discard := prototype.find_child("CookingCancelDiscardButton", true, false) as Button
	if first_discard_choice == null or confirm_discard == null or cancel_discard == null or not confirm_discard.disabled:
		_fail("The discard selection prompt did not reveal a selection button above the clicked card.")
		return
	first_discard_choice.emit_signal("pressed")
	await process_frame
	await process_frame
	var second_discard_card := prototype.find_child("CookingHandCard_3", true, false) as Control
	prototype._toggle_hand_card_actions(second_discard_card, 3, "spicy_sriracharrow")
	var second_discard_choice := prototype.find_child("CookingDiscardChoice_3", true, false) as Button
	if second_discard_choice == null:
		_fail("The discard prompt disappeared after selecting one card.")
		return
	second_discard_choice.emit_signal("pressed")
	await process_frame
	await process_frame
	confirm_discard = prototype.find_child("CookingConfirmDiscardButton", true, false) as Button
	if confirm_discard == null or confirm_discard.disabled:
		_fail("Confirm did not enable after selecting the exact discard cost.")
		return
	confirm_discard.emit_signal("pressed")
	await process_frame
	await process_frame
	if not prototype.state.pending_discard.is_empty() or prototype.state.player.hand != ["spicy_jalapeno_panther"]:
		_fail("The discard picker did not discard the chosen production cards.")
		return

	# Activated field abilities render and can be used from the board.
	prototype.state.player.hand = ["spicy_jalapeno_jackal"]
	prototype.state.player.deck = ["hearty_bagver", "spicy_sriracharrow", "spicy_hot_honey_bee"]
	prototype.service.play_card(prototype.state, 0, "prep")
	var ui_jakapeno_id := int(prototype.state.player.prep[0].instance_id)
	prototype._refresh()
	await process_frame
	await process_frame
	var activate_jakapeno := prototype.find_child("CookingActivateAbility_%d_jakapeno_search" % ui_jakapeno_id, true, false) as Button
	if activate_jakapeno == null or activate_jakapeno.disabled:
		_fail("Jakapeno did not render an enabled Activate button on the field.")
		return
	activate_jakapeno.emit_signal("pressed")
	await process_frame
	await process_frame
	var take_sriracharrow := prototype.find_child("CookingTakeSearchCard_spicy_sriracharrow", true, false) as Button
	var invalid_hearty_choice := prototype.find_child("CookingTakeSearchCard_hearty_bagver", true, false) as Button
	if take_sriracharrow == null or invalid_hearty_choice != null or prototype.state.pending_search.is_empty():
		_fail("Jakapeno's rendered search did not show only viable deck choices.")
		return
	take_sriracharrow.emit_signal("pressed")
	await process_frame
	await process_frame
	if not prototype.state.player.prep.is_empty() or prototype.state.player.hand != ["spicy_sriracharrow"] or not prototype.state.pending_search.is_empty():
		_fail("Jakapeno's deck picker did not add the chosen card to the hand.")
		return

	print("Kitchen Table TCG smoke test passed.")
	quit(0)


func _fixture_cards() -> Array:
	return [
		{
			"id": "test_veg", "name": "Test Vegetable", "card_type": "ingredient",
			"ingredient_types": ["vegetable"], "attack": 3, "health": 2, "text": "Fixture."
		},
		{
			"id": "test_protein", "name": "Test Protein", "card_type": "ingredient",
			"ingredient_types": ["protein"], "attack": 1, "health": 1, "text": "Fixture."
		},
		{
			"id": "test_meal", "name": "Test Meal", "card_type": "meal",
			"recipe": ["vegetable", "protein"], "attack": 5, "health": 4, "text": "Fixture."
		},
		{
			"id": "test_tool", "name": "Test Tool", "card_type": "tool",
			"effects": [{"type": "draw", "amount": 1}], "text": "Fixture."
		},
		{
			"id": "test_discard_tool", "name": "Test Discard Tool", "card_type": "tool",
			"discard_cost": 2, "effects": [], "text": "Discard 2 cards."
		},
		{
			"id": "test_spice", "name": "Test Spice", "card_type": "spice",
			"attack_bonus": 1, "health_bonus": 1, "text": "Fixture."
		},
		{
			"id": "test_environment", "name": "Test Kitchen", "card_type": "environment",
			"ingredient_growth": 1, "text": "Fixture."
		},
		{
			"id": "test_chef", "name": "Test Chef", "card_type": "chef",
			"effects": [], "text": "Fixture."
		}
	]


func _fixture_decks() -> Dictionary:
	var contents := {
		"test_veg": 6,
		"test_protein": 6,
		"test_meal": 3,
		"test_tool": 2,
		"test_discard_tool": 1,
		"test_spice": 2,
		"test_environment": 1,
		"test_chef": 2
	}
	return {
		"test_a": {"name": "Fixture A", "cards": contents.duplicate(true)},
		"test_b": {"name": "Fixture B", "cards": contents.duplicate(true)}
	}


func _test_unit(instance_id: int, card_id: String, name: String, card_type: String, attack: int, health: int, ready: bool, recipe_ready_on_turn: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": card_id,
		"name": name,
		"card_type": card_type,
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": ready,
		"recipe_ready_on_turn": recipe_ready_on_turn,
		"used_abilities": [],
		"triggered_effects": [],
		"temporary_attack": 0,
		"aura_attack_bonus": 0,
		"aura_health_bonus": 0,
		"spices": []
	}


func _count_prefix(root_node: Node, prefix: String) -> int:
	var count := 0
	for node in root_node.find_children(prefix + "*", "", true, false):
		if String(node.name).begins_with(prefix):
			count += 1
	return count


func _first_unit_of_type(units: Array, card_type: String) -> Dictionary:
	for unit in units:
		if String(unit.get("card_type", "")) == card_type:
			return unit
	return {}


func _has_visual_event(events: Array[Dictionary], event_type: String, instance_id: int = -1) -> bool:
	for event in events:
		if String(event.get("type", "")) != event_type:
			continue
		if instance_id < 0 or int(event.get("instance_id", -1)) == instance_id:
			return true
	return false


func _events_of_type(events: Array[Dictionary], event_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if String(event.get("type", "")) == event_type:
			result.append(event)
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
