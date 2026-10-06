extends SceneTree

const COMBAT := preload("res://scripts/cooking/CookingCombatService.gd")
var service := COMBAT.new()
var checks := 0
var errors: Array[String] = []


func _initialize() -> void:
	_expect(service.load_content(), "Production content failed to load.")
	for side in ["player", "opponent"]:
		for resolution in ["extra_ingredient", "moved_to_prep", "defeated"]:
			_test_snail(side, resolution)
		_test_special_serve(side)
		_test_timed_source(side, "sweet_toffee_collie", "tool", "items_disabled", "item_wooden_spoon")
		_test_timed_source(side, "sweet_pudding_puma", "chef", "chefs_disabled", "chef_mary")
	_test_legacy_flags()
	for message in errors:
		push_error(message)
	print("Play restriction feedback smoke test: %d checks, %d failures." % [checks, errors.size()])
	quit(0 if errors.is_empty() else 1)


func _test_snail(side: String, resolution: String) -> void:
	var state := _fresh()
	var enemy := _other(side)
	var snail := _unit(state, enemy, "sweet_cinnamon_snail", "plated")
	var payment := _unit(state, side, "spicy_hot_honey_bee")
	state[side].hand = ["spicy_sriracharrow"]
	var meal := service.card("spicy_sriracharrow")
	var reason := service.play_restriction_reason(state, "meal", side)
	_expect(reason.contains("Cinnamon Snail") and reason.contains("+1 Ingredient") and reason.contains("Plated"), "%s Snail explanation lost its source, amount or active zone." % side)
	var restrictions := service.active_play_restrictions(state, side)
	_expect(restrictions.size() == 1 and int(restrictions[0].instance_id) == int(snail.instance_id), "%s Snail explanation lost its inspectable instance." % side)
	_expect(service.serve_recipe(state, side, meal).size() == 2, "%s Snail failed to add its normal recipe Ingredient." % side)
	_expect(service.serve_ingredient_ids(state, side, meal).is_empty(), "%s base recipe bypassed Cinnamon Snail." % side)
	var before: Dictionary = state[side].duplicate(true)
	if side == "player":
		service.begin_meal_play(state, 0)
		_expect(state.pending_meal.is_empty() and String(state.message).contains("Cinnamon Snail"), "Failed player summon did not name Cinnamon Snail.")
	_expect(not service._serve_meal(state, side, 0, [payment.instance_id]), "%s served a Meal with only its base recipe under Snail." % side)
	_expect(state[side].hand == before.hand and state[side].prep == before.prep and state[side].discard == before.discard and int(state[side].meals_served) == int(before.meals_served), "%s failed recipe spent cards or normal allowance." % side)
	match resolution:
		"extra_ingredient":
			_unit(state, side, "sweet_caramel_camel")
			_expect(not service.play_restriction_reason(state, "meal", side).is_empty(), "An extra payment incorrectly removed the active Snail explanation.")
		"moved_to_prep":
			state[enemy].plated.erase(snail)
			state[enemy].prep.append(snail)
		"defeated":
			service._deal_effect_damage_to_unit(state, side, enemy, snail, 99)
	if resolution != "extra_ingredient":
		_expect(service.play_restriction_reason(state, "meal", side).is_empty(), "%s Snail restriction remained after %s." % [side, resolution])
		_expect(service.serve_recipe(state, side, meal).size() == 1, "%s recipe tax remained after %s." % [side, resolution])
	if side == "player":
		_expect(service.meal_play_block_reason(state, meal).is_empty(), "Player summon remains described as blocked after %s." % resolution)
	_expect(service._serve_meal(state, side, 0, []), "%s could not serve after %s." % [side, resolution])
	_expect(state[side].hand.is_empty() and int(state[side].meals_served) == 1, "%s successful normal serve spent an incorrect allowance." % side)


func _test_special_serve(side: String) -> void:
	var state := _fresh()
	_unit(state, _other(side), "sweet_cinnamon_snail", "plated")
	var payment := _unit(state, side, "spicy_hot_honey_bee")
	payment.attack = 3
	payment.recipe_ready_on_turn = 99
	state[side].hand = ["spicy_quesadillama"]
	state[side].meals_served = 1
	state[side].meal_served = true
	var data := service.card("spicy_quesadillama")
	_expect(service.serve_recipe(state, side, data, true).size() == 1, "%s Special Serve incorrectly inherited Snail's normal recipe tax." % side)
	_expect(service.serve_ingredient_ids(state, side, data, true) == [payment.instance_id], "%s eligible newly played Ingredient could not Special Serve." % side)
	if side == "player":
		_expect(service.meal_play_block_reason(state, data, true).is_empty(), "Eligible Special Serve was described as blocked by the normal allowance or Snail.")
	_expect(service._serve_meal(state, side, 0, [payment.instance_id], "plated", true), "%s could not Special Serve under Snail after its normal Meal." % side)
	_expect(state[side].hand.is_empty() and int(state[side].meals_served) == 1 and bool(state[side].plated[0].special_served), "%s Special Serve lost its marker or changed the normal allowance." % side)


func _test_timed_source(affected: String, source_id: String, kind: String, flag: String, blocked_card: String) -> void:
	var state := _fresh()
	var source_side := _other(affected)
	var source := _unit(state, source_side, source_id, "plated")
	var source_name := String(source.name)
	# Trigger the real card through combat damage, including the live AI path.
	if source_side == "player":
		service.select_attacker(state, int(source.instance_id))
		service.attack(state)
	else:
		state.phase = "opponent_turn"
		service._ai_attack_with_unit(state, source)
	_expect(bool(state[affected].get(flag, false)), "%s combat hit did not set %s for %s." % [source_name, kind, affected])
	_expect(service.play_restriction_reason(state, kind, affected).contains(source_name), "%s restriction did not name its combat source for %s." % [kind, affected])
	service._deal_effect_damage_to_unit(state, affected, source_side, source, 99)
	_expect(service._find_unit(state[source_side], int(source.instance_id)).is_empty(), "Timed restriction fixture failed to defeat %s." % source_name)
	_expect(service.play_restriction_reason(state, kind, affected).contains(source_name), "%s attribution disappeared when its source died." % kind)
	# Finishing the source's turn must not expire the other side's restriction.
	if source_side == "player":
		service.end_player_turn(state, true)
	else:
		service._ai_turn(state, false)
	_expect(bool(state[affected].get(flag, false)), "%s restriction expired at the source's turn end." % kind)
	service._start_turn(state, affected, false)
	_expect(bool(state[affected].get(flag, false)), "%s restriction expired at the affected turn's start." % kind)
	# Snapshot restoration must preserve attribution even with no living source.
	state = JSON.parse_string(JSON.stringify(state))
	var reason := service.play_restriction_reason(state, kind, affected)
	_expect(reason.contains(source_name) and reason.contains("until your turn ends"), "%s restored restriction lost its source or duration." % kind)
	state[affected].hand = [blocked_card]
	state[affected].deck = ["spicy_hot_honey_bee", "spicy_hot_honey_bee", "spicy_hot_honey_bee"]
	var before: Dictionary = state[affected].duplicate(true)
	var played: bool = service._play_tool(state, affected, 0) if kind == "tool" else service._play_chef(state, affected, 0)
	_expect(not played and String(state.message).contains(source_name), "%s blocked play did not report %s for %s." % [kind, source_name, affected])
	_expect(state[affected].hand == before.hand and state[affected].discard == before.discard and int(state[affected].meals_served) == int(before.meals_served) and bool(state[affected].chef_used) == bool(before.chef_used), "%s failed %s play consumed a card or allowance." % [affected, kind])
	if affected == "opponent":
		_expect(service._ai_hand_action(state, 0).is_empty(), "AI still offered a blocked %s." % kind)
		var synchronous := state.duplicate(true)
		service._ai_turn(synchronous, false)
		_expect(not bool(synchronous.opponent.get(flag, false)) and service.play_restriction_reason(synchronous, kind, "opponent").is_empty(), "Synchronous AI end-turn failed to expire %s and its source." % kind)
		state.opponent_sequence = {"stage": "end", "attack_ids": []}
		service.advance_opponent_turn(state)
	else:
		service.end_player_turn(state, true)
	_expect(not bool(state[affected].get(flag, false)) and service.play_restriction_reason(state, kind, affected).is_empty(), "%s %s restriction/source outlived the affected turn." % [affected, kind])
	_expect(not state[affected].has("play_restriction_sources"), "%s left stale saved source records at expiry." % affected)
	played = service._play_tool(state, affected, 0) if kind == "tool" else service._play_chef(state, affected, 0)
	_expect(played and state[affected].discard.has(blocked_card), "%s remained unplayable after its restriction expired for %s." % [kind, affected])


func _test_legacy_flags() -> void:
	var state := _fresh()
	state.player.items_disabled = true
	state.player.chefs_disabled = true
	_expect(service.play_restriction_reason(state, "tool").contains("Tools blocked"), "Legacy saved Tool flag has no fallback explanation.")
	_expect(service.play_restriction_reason(state, "chef").contains("Chefs blocked"), "Legacy saved Chef flag has no fallback explanation.")


func _fresh() -> Dictionary:
	var state := service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 1701)
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated", "hand", "deck", "discard"]:
			state[side][zone] = []
		state[side].turns_started = 2
	state.phase = "player_main"
	state.game_over = false
	return state


func _unit(state: Dictionary, side: String, id: String, zone: String = "prep") -> Dictionary:
	var result := service._make_unit(state, state[side], service.card(id), zone, side)
	result.recipe_ready_on_turn = 0
	result.ready = true
	state[side][zone].append(result)
	return result


func _other(side: String) -> String:
	return "opponent" if side == "player" else "player"


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		errors.append(message)
