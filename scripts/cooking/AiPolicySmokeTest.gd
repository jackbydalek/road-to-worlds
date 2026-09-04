extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load card content.")
		return

	var state: Dictionary = service.start_game(
		"spicy_test_kitchen", "hearty_test_kitchen", 31415, "player", true, "hard"
	)
	if String(state.player.get("ai_profile", "")) != "pressure":
		_fail("Spicy did not receive its pressure profile.")
		return
	if String(state.opponent.get("ai_profile", "")) != "defensive":
		_fail("Hearty did not receive its defensive profile.")
		return

	var original_player: Dictionary = state.player
	var original_opponent: Dictionary = state.opponent
	state.player = state.opponent
	state.opponent = original_player
	if String(service._ai_profile(state)) != "pressure":
		_fail("The acting profile did not follow the combatant after a perspective swap.")
		return
	state.player = original_player
	state.opponent = original_opponent

	state.player.plated.clear()
	state.player.prep.clear()
	state.opponent.plated.clear()
	state.opponent.prep.clear()
	state.opponent.life = 5
	var threat: Dictionary = service._make_unit(state, state.player, service.card("spicy_sriracharrow"), "plated", "player")
	threat.attack = 6
	state.player.plated.append(threat)
	var small_blocker: Dictionary = service._make_unit(state, state.opponent, service.card("hearty_bagver"), "prep", "opponent")
	var large_blocker: Dictionary = service._make_unit(state, state.opponent, service.card("hearty_gravy_gazelle"), "prep", "opponent")
	large_blocker.health = 8
	large_blocker.max_health = 8
	state.opponent.prep.append_array([small_blocker, large_blocker])
	if not service._ai_faces_lethal_next_turn(state):
		_fail("Defensive AI did not recognize incoming lethal damage.")
		return
	if String(service._ai_deployment_zone(state, "ingredient")) != "plated":
		_fail("Defensive AI did not deploy a blocker into Plated under lethal pressure.")
		return
	if int(service._ai_unit_to_plate(state).instance_id) != int(large_blocker.instance_id):
		_fail("Defensive AI did not choose its sturdier emergency blocker.")
		return

	state.opponent.ai_policy = service.AI_POLICY_FACE_RACE
	if String(service._ai_deployment_zone(state, "ingredient")) != "plated":
		_fail("Face-race AI did not prioritize Plated deployment.")
		return
	if service._ai_face_race_card_score(state, service.card("spicy_hot_honey_bee")) <= service._ai_face_race_card_score(state, service.card("hearty_bagver")):
		_fail("Face-race AI did not prioritize direct-damage cards.")
		return
	state.player.plated = [small_blocker, large_blocker]
	var chosen_target: Dictionary = service._ai_attack_target(state, threat)
	if int(chosen_target.instance_id) != int(small_blocker.instance_id):
		_fail("Face-race AI did not choose the cheapest blocker.")
		return

	var switchblade_state: Dictionary = service.start_game(
		"spicy_test_kitchen", "hearty_test_kitchen", 27182, "player", true, "medium"
	)
	switchblade_state.opponent.hand = ["item_switchblade"]
	switchblade_state.opponent.prep.clear()
	switchblade_state.opponent.plated.clear()
	if service._ai_play_one_hand_card(switchblade_state) or not switchblade_state.opponent.discard.is_empty() or switchblade_state.opponent.hand != ["item_switchblade"]:
		_fail("AI spent Switchblade with no Prep and Plated foods to swap.")
		return
	var weak_plated: Dictionary = service._make_unit(switchblade_state, switchblade_state.opponent, service.card("hearty_bagver"), "plated", "opponent")
	weak_plated.attack = 1
	weak_plated.health = 2
	weak_plated.max_health = 2
	var strong_prep: Dictionary = service._make_unit(switchblade_state, switchblade_state.opponent, service.card("hearty_gravy_gazelle"), "prep", "opponent")
	strong_prep.attack = 1
	strong_prep.health = 4
	strong_prep.max_health = 4
	switchblade_state.opponent.plated = [weak_plated]
	switchblade_state.opponent.prep = [strong_prep]
	weak_plated.attack = 5
	if service._ai_play_one_hand_card(switchblade_state) or not switchblade_state.opponent.discard.is_empty() or switchblade_state.opponent.hand != ["item_switchblade"]:
		_fail("AI spent Switchblade on a swap that weakened its Plated zone.")
		return
	weak_plated.attack = 1
	strong_prep.attack = 5
	if not service._ai_play_one_hand_card(switchblade_state):
		_fail("AI did not use Switchblade once it could improve its board.")
		return
	if not switchblade_state.opponent.hand.is_empty() or not switchblade_state.opponent.discard.has("item_switchblade") or int(switchblade_state.opponent.plated[0].instance_id) != int(strong_prep.instance_id):
		_fail("AI did not move the stronger Prep food into Plated with Switchblade.")
		return

	print("AI_POLICY_SMOKE_TEST=PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
