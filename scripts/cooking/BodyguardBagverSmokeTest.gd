extends SceneTree

const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")
var service: RefCounted
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	service = SERVICE.new()
	assert(service.load_content())
	service.cards_by_id["test_combat_attacker"] = {
		"id": "test_combat_attacker", "name": "Combat Probe", "card_type": "ingredient",
		"archetype": "spicy", "attack": 6, "health": 10, "keywords": [],
		"on_combat_damage_to_chef": [{"type": "draw", "amount": 1}],
	}
	# Both seats, both stances, and Piercing: Bodyguard is unconditional overflow
	# protection, while ordinary defending units remain vulnerable to Piercing.
	for side in ["player", "opponent"]:
		for guarding in [false, true]:
			for defending in [false, true]:
				for piercing in [false, true]:
					_test_overflow(side, guarding, defending, piercing)
		for starting_life in [35, 39]:
			_test_sacrifice(side, starting_life, false)
		_test_sacrifice(side, 35, true)
	_test_stalwart_and_effect_damage()
	_expect(service.card("hearty_bagver").text == "When sacrificed, heal your Chef for 2.", "Bagver's printed healing text is stale.")
	if not failures.is_empty():
		for message in failures:
			push_error(message)
		quit(1)
		return
	print("BODYGUARD_BAGVER_SMOKE_TEST_OK: 16 overflow cases, 6 sacrifice cases, Stalwart, and effect damage.")
	quit(0)

func _state() -> Dictionary:
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 61003, "player", false, "hard", {
		"player_life": 40, "player_max_life": 40, "opponent_life": 40, "opponent_max_life": 40,
	})
	for side in ["player", "opponent"]:
		state[side].turns_started = 2
		state[side].hand = []
		state[side].prep = []
		state[side].plated = []
	state.animation_events.clear()
	return state

func _unit(state: Dictionary, side: String, id: String, zone: String = "plated") -> Dictionary:
	var unit: Dictionary = service._make_unit(state, state[side], service.card(id), zone, side)
	unit.recipe_ready_on_turn = 0
	state[side][zone].append(unit)
	return unit

func _test_overflow(side: String, guarding: bool, defending: bool, piercing: bool) -> void:
	service.cards_by_id.test_combat_attacker.keywords = ["piercing"] if piercing else []
	var state := _state()
	var target_side := "opponent" if side == "player" else "player"
	var attacker := _unit(state, side, "test_combat_attacker")
	var defender := _unit(state, target_side, "sweet_soft_serve_crab" if guarding else "hearty_macaroni_manatee")
	defender.defending = defending
	var expected_damage := 0 if guarding or (defending and not piercing) else 6 - int(defender.health)
	var expected_retaliation := int(defender.attack)
	service._resolve_unit_battle(state, side, attacker, defender)
	var context := "%s bodyguard=%s defending=%s piercing=%s" % [side, guarding, defending, piercing]
	_expect(int(state[target_side].life) == 40 - expected_damage, "Wrong Chef overflow: " + context)
	_expect(state[target_side].plated.is_empty(), "Bodyguard incorrectly prevented damage to the defending unit: " + context)
	_expect(int(attacker.health) == 10 - expected_retaliation, "Combat retaliation changed: " + context)
	_expect(state[side].hand.size() == (1 if expected_damage > 0 else 0), "Chef-hit trigger fired without damage, or failed after damage: " + context)
	var chef_events := 0
	for event in state.animation_events:
		if event.get("type", "") == "damage" and event.get("target_kind", "") == "chef":
			chef_events += 1
	_expect(chef_events == (1 if expected_damage > 0 else 0), "Incorrect Chef damage animation: " + context)

func _test_sacrifice(side: String, starting_life: int, healing_tax: bool) -> void:
	var state := _state()
	var other := "opponent" if side == "player" else "player"
	state[side].life = starting_life
	state[side].hand = ["hearty_lasagnama"]
	var bagver := _unit(state, side, "hearty_bagver", "prep")
	if healing_tax:
		_unit(state, other, "sweet_cinnamon_snail")
		# Cinnamon Snail also adds one Ingredient to the Meal recipe.
		_unit(state, side, "hearty_macaroni_manatee", "prep")
	var ingredients: Array[int] = []
	for ingredient in state[side].prep:
		ingredients.append(int(ingredient.instance_id))
	_expect(service._serve_meal(state, side, 0, ingredients, "plated"), "Could not serve a Meal with Bagver.")
	var expected_life := starting_life if healing_tax else mini(40, starting_life + 2)
	_expect(int(state[side].life) == expected_life, "Bagver healing did not respect amount, cap, or suppression for " + side)
	_expect(state[side].discard.count("hearty_bagver") == 1, "Bagver was not sacrificed exactly once.")
	_expect(state[side].plated.size() == 1 and state[side].plated[0].card_id == "hearty_lasagnama", "Bagver's sacrifice broke Meal creation.")

func _test_stalwart_and_effect_damage() -> void:
	var state := _state()
	var attacker := _unit(state, "player", "spicy_wasabi_wasp")
	_unit(state, "opponent", "sweet_soft_serve_crab")
	_expect(service.can_attack_opposing_chef(state, int(attacker.instance_id)), "Bodyguard incorrectly stopped Stalwart's direct attack.")
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, -1)
	_expect(int(state.opponent.life) == 38, "Bodyguard incorrectly absorbed a direct Chef attack.")
	state.player.hand = ["spicy_hot_honey_bee"]
	service.play_card(state, 0, "prep")
	_expect(int(state.opponent.life) == 37, "Bodyguard incorrectly prevented card-effect damage to the Chef.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
