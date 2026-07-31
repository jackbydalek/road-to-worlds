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

	print("AI_POLICY_SMOKE_TEST=PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
