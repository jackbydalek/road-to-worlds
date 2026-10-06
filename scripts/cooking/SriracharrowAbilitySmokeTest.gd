extends SceneTree

const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")
const ROUTE := preload("res://scripts/RouteRunService.gd")
const CARD_ID := "spicy_sriracharrow"
var service := SERVICE.new()
var failures: Array[String] = []


func _init() -> void:
	service.load_content()
	var data: Dictionary = service.card(CARD_ID)
	_expect(int(data.attack) == 6 and int(data.health) == 4 and data.recipe == ["spicy"], "Stats or recipe changed.")
	_expect(data.text == "When this attacks, deal 1 damage to a target Prep unit." and not data.get("keywords", []).has("stalwart"), "Printed ability was not replaced.")
	_expect(data.get("art_frames", []).size() == 6 and String(data.art_frames[0]) == "res://assets/cards/art/spicy_sriracharrow/frame_00.png", "Original card artwork changed.")
	var route := ROUTE.new()
	route.cards_by_id = service.cards_by_id.duplicate(true)
	var upgraded: Dictionary = route.upgraded_card_data(CARD_ID)
	service.cards_by_id[upgraded.id] = upgraded
	_expect(int(upgraded.attack) == 7 and int(upgraded.health) == 5 and upgraded.art_frames == data.art_frames, "Upgrade lost its stat increase or original artwork.")
	for card_id in [CARD_ID, String(upgraded.id)]:
		_test_player_attack(card_id)
	_test_no_prep_targets()
	_test_friendly_lethal_target()
	_test_ai_attack()
	for failure in failures:
		push_error(failure)
	print("Sriracharrow attack ability smoke test: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)


func _test_player_attack(card_id: String) -> void:
	var state := _state()
	var friendly := _unit(state, "player", "prep", "hearty_bagver")
	var enemy_a := _unit(state, "opponent", "prep", "hearty_bagver")
	var enemy_b := _unit(state, "opponent", "prep", "hearty_macaroni_manatee")
	var friendly_plated := _unit(state, "player", "plated", "spicy_wasabi_wasp")
	var defender := _defender(state, "opponent")
	_serve(state, card_id, "plated")
	var attacker: Dictionary = state.player.plated.back()
	var attack := int(attacker.attack)
	var health := int(attacker.health)
	_expect(state.pending_choice.is_empty() and _damage_events(state).is_empty(), "%s triggered an ability when served." % card_id)
	_expect(int(friendly.health) == 2 and int(enemy_a.health) == 2 and int(enemy_b.health) == 3, "Serving damaged a Prep unit.")
	_expect(not service.can_attack_opposing_chef(state, int(attacker.instance_id)), "Sriracharrow retained Stalwart's bypass.")
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, int(enemy_a.instance_id))
	service.attack(state, -1)
	_expect(state.pending_choice.is_empty() and bool(attacker.ready) and _damage_events(state).is_empty(), "An illegal normal attack triggered the Prep ability.")
	service.attack(state, int(defender.instance_id))
	var targets: Array = service.choice_target_ids(state)
	_expect(targets.size() == 3 and targets.has(friendly.instance_id) and targets.has(enemy_a.instance_id) and targets.has(enemy_b.instance_id), "Choice does not contain exactly the Prep units on both sides.")
	_expect(not state.pending_resume.is_empty() and int(defender.health) == 10 and bool(attacker.ready), "Combat did not pause for its Prep target.")
	for invalid_target in [int(attacker.instance_id), int(defender.instance_id), int(friendly_plated.instance_id), -1]:
		service.choose_effect_target(state, invalid_target)
		_expect(not state.pending_choice.is_empty() and int(enemy_b.health) == 3 and int(defender.health) == 10, "A Plated unit or Chef was accepted as the ability target.")
	service.cancel_pending_attack_choice(state)
	_expect(state.pending_choice.is_empty() and state.pending_resume.is_empty() and bool(attacker.ready) and _damage_events(state).is_empty(), "Cancelling the target choice dealt damage or consumed the attack.")
	service.attack(state, int(defender.instance_id))
	service.attack(state, int(defender.instance_id))
	service.choose_effect_target(state, int(enemy_b.instance_id))
	_expect(state.pending_choice.is_empty() and state.pending_resume.is_empty(), "The attack stayed pending after its target was chosen.")
	_expect(int(enemy_b.health) == 2 and int(enemy_a.health) == 2 and int(friendly.health) == 2, "%s did not deal exactly 1 damage to only its chosen Prep unit." % card_id)
	_expect(int(defender.health) == 10 - attack and int(attacker.health) == health - 1 and not bool(attacker.ready), "Normal Plated combat did not resume exactly once.")
	_expect(int(friendly_plated.health) == 1 and int(state.player.life) == 20 and int(state.opponent.life) == 20, "The ability damaged another Plated unit or a Chef.")
	var prep_damage_events: Array = _damage_events(state).filter(func(event): return int(event.get("target_instance_id", -1)) in [int(friendly.instance_id), int(enemy_a.instance_id), int(enemy_b.instance_id)])
	_expect(prep_damage_events.size() == 1 and int(prep_damage_events[0].amount) == 1 and int(prep_damage_events[0].target_instance_id) == int(enemy_b.instance_id), "Damage animation does not identify the single chosen Prep target.")
	service.choose_effect_target(state, int(enemy_a.instance_id))
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, int(defender.instance_id))
	_expect(state.pending_choice.is_empty() and int(enemy_a.health) == 2 and int(enemy_b.health) == 2 and int(defender.health) == 10 - attack and _damage_events(state).is_empty(), "An extra click or exhausted attack repeated the ability.")


func _test_no_prep_targets() -> void:
	var state := _state()
	_serve(state, CARD_ID)
	_expect(state.pending_choice.is_empty() and state.player.prep.size() == 1, "Serving to Prep got stuck.")
	var attacker: Dictionary = state.player.prep[0]
	service.move_unit(state, int(attacker.instance_id), "plated")
	_expect(state.pending_choice.is_empty() and int(attacker.health) == 4 and _damage_events(state).is_empty(), "Moving into Plated triggered the attack ability.")
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, -1)
	_expect(state.pending_choice.is_empty() and state.pending_resume.is_empty() and int(state.opponent.life) == 14 and not bool(attacker.ready), "Attacking without any Prep targets failed to complete normal Chef combat.")


func _test_friendly_lethal_target() -> void:
	var state := _state()
	var victim := _unit(state, "player", "prep", "spicy_wasabi_wasp")
	var defender := _defender(state, "opponent")
	_serve(state, CARD_ID, "plated")
	var attacker: Dictionary = state.player.plated[0]
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, int(defender.instance_id))
	_expect(service.choice_target_ids(state) == [int(victim.instance_id)], "The sole friendly Prep unit was excluded from legal targets.")
	service.choose_effect_target(state, int(victim.instance_id))
	_expect(state.player.prep.is_empty() and state.player.discard.has("spicy_wasabi_wasp"), "A friendly lethal Prep target was not defeated and discarded.")
	_expect(state.pending_choice.is_empty() and int(defender.health) == 4 and not bool(attacker.ready), "A lethal Prep effect prevented the original attack from completing.")


func _test_ai_attack() -> void:
	var state := _state()
	var friendly := _unit(state, "opponent", "prep", "hearty_bagver")
	var victim := _unit(state, "player", "prep", "spicy_wasabi_wasp")
	var other_prep := _unit(state, "player", "prep", "hearty_bagver")
	var defender := _defender(state, "player")
	_serve(state, CARD_ID, "plated", "opponent")
	var attacker: Dictionary = state.opponent.plated[0]
	_expect(state.pending_choice.is_empty() and state.player.prep.size() == 2 and _damage_events(state).is_empty(), "AI still triggered damage on serve.")
	service._ai_attack_with_unit(state, attacker)
	_expect(state.pending_choice.is_empty() and state.player.prep.size() == 1 and state.player.discard.has(victim.card_id) and int(friendly.health) == 2 and int(other_prep.health) == 2, "AI did not resolve exactly one opposing Prep target without a player prompt.")
	_expect(int(defender.health) == 4 and not bool(attacker.ready) and int(state.player.life) == 20, "AI failed to complete its normal Plated attack after resolving the Prep damage.")


func _state() -> Dictionary:
	var state := service.start_game("", "", 815)
	for side in ["player", "opponent"]:
		state[side].hand = []
		state[side].prep = []
		state[side].plated = []
		state[side].discard = []
		state[side].turns_started = 2
	service.clear_animation_events(state)
	return state


func _unit(state: Dictionary, side: String, zone: String, card_id: String) -> Dictionary:
	var unit: Dictionary = service._make_unit(state, state[side], service.card(card_id), zone, side)
	unit.recipe_ready_on_turn = 0
	state[side][zone].append(unit)
	return unit


func _defender(state: Dictionary, side: String) -> Dictionary:
	var unit := _unit(state, side, "plated", "hearty_bagver")
	unit.health = 10
	unit.max_health = 10
	unit.attack = 1
	return unit


func _serve(state: Dictionary, card_id: String, zone: String = "prep", side: String = "player") -> void:
	var ingredient := _unit(state, side, "prep", "spicy_hot_honey_bee")
	state[side].hand = [card_id]
	if side == "player":
		service.play_card(state, 0, zone)
		service.toggle_ingredient_selection(state, int(ingredient.instance_id))
		service.confirm_meal_play(state)
	else:
		service._serve_meal(state, side, 0, [int(ingredient.instance_id)], zone)


func _damage_events(state: Dictionary) -> Array:
	return service.take_animation_events(state).filter(func(event): return event.type == "damage")


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
