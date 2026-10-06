extends SceneTree
const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")
var errors: Array[String] = []
var service = SERVICE.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(service.load_content())
	service.cards_by_id.probe = {"id": "probe", "name": "Probe", "card_type": "ingredient", "archetype": "spicy", "attack": 6, "health": 5, "keywords": []}
	for bodyguard in [false, true]:
		for defending in [false, true]:
			for piercing in [false, true]:
				service.cards_by_id.probe.keywords = ["piercing"] if piercing else []
				var state := fresh()
				var attacker := unit(state, "player", "probe")
				var defender := unit(state, "opponent", "sweet_soft_serve_crab" if bodyguard else "hearty_macaroni_manatee")
				defender.defending = defending
				state.selected_attacker = attacker.instance_id
				var before := JSON.stringify(state)
				var random_before: int = service.rng.state
				var prediction: Dictionary = service.attack_preview(state, attacker.instance_id, defender.instance_id)
				expect(JSON.stringify(state) == before and service.rng.state == random_before, "Preview mutated state or RNG")
				expect(not prediction.is_empty() and not prediction.effects_follow, "Basic exchange unexpectedly conditional")
				service.attack(state, defender.instance_id)
				expect(state.opponent.life == 40 - prediction.overflow, "Overflow preview differs from actual attack")
				expect(maxi(0, attacker.health) == prediction.attacker_health and maxi(0, defender.health) == prediction.defender_health, "Survival preview differs from actual attack")
	var state := fresh()
	var attacker := unit(state, "player", "spicy_wasabi_wasp")
	var defender := unit(state, "opponent", "sweet_soft_serve_crab")
	var direct: Dictionary = service.attack_preview(state, attacker.instance_id, -1)
	expect(direct.direct and direct.damage == 2, "Stalwart direct attack is missing")
	var invalid := unit(state, "opponent", "hearty_macaroni_manatee", "prep")
	expect(service.attack_preview(state, attacker.instance_id, invalid.instance_id).is_empty(), "Prep received an illegal attack preview")
	service.cards_by_id.sweet_soft_serve_crab.keywords = ["taunt"]
	invalid = unit(state, "opponent", "hearty_macaroni_manatee")
	expect(service.attack_preview(state, attacker.instance_id, invalid.instance_id).is_empty(), "Preview ignored Taunt")
	attacker.ready = false
	expect(service.attack_preview(state, attacker.instance_id, -1).is_empty(), "Exhausted attacker had a preview")
	attacker.ready = true
	state.player.turns_started = 1
	expect(service.attack_preview(state, attacker.instance_id, -1).is_empty(), "Opening turn attack preview was allowed")
	state = fresh()
	attacker = unit(state, "player", "spicy_firecracker_shrimp")
	defender = unit(state, "opponent", "sweet_soft_serve_crab")
	expect(service.attack_preview(state, attacker.instance_id, defender.instance_id).get("effect_first", false), "Unresolved attack effects promised a false result")
	for error in errors:
		push_error(error)
	print("Attack preview smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func fresh() -> Dictionary:
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 15012, "player", false, "hard", {"player_life": 40, "opponent_life": 40})
	for side in ["player", "opponent"]:
		state[side].turns_started = 2
		state[side].plated = []
		state[side].prep = []
	state.phase = "player_main"
	return state

func unit(state: Dictionary, side: String, id: String, zone := "plated") -> Dictionary:
	var result: Dictionary = service._make_unit(state, state[side], service.card(id), zone, side)
	state[side][zone].append(result)
	return result

func expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
