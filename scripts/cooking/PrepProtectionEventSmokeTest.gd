extends SceneTree

## Prevention is still a rules no-op on health; its event identifies the exact
## protector and target so the table can explain the blocked hit afterward.
const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")
const PROTECTOR := "fresh_salad_shield_skunk"
const TARGET := "fresh_crisp_capybara"
var service := SERVICE.new()
var failures: Array[String] = []


func _init() -> void:
	_expect(service.load_content(), "Production card content did not load.")
	_test_sides_and_attribution()
	_test_unprotected_and_zero_damage()
	_test_multiple_protectors()
	_test_real_sriracharrow_choice()
	for failure in failures:
		push_error(failure)
	print("Prep protection events: both sides, attribution, unchanged damage rules, explicit/current groups, deterministic multiple protectors and real Sriracharrow ordering; %d failures." % failures.size())
	quit(0 if failures.is_empty() else 1)


func _state() -> Dictionary:
	var state := service.start_game("", "", 1611, "player", true, "easy")
	state.turn = 3
	state.phase = "player_main"
	for side in ["player", "opponent"]:
		state[side].prep = []
		state[side].plated = []
		state[side].hand = []
		state[side].deck = []
		state[side].discard = []
		state[side].environment = ""
		state[side].turns_started = 2
	service.clear_animation_events(state)
	return state


func _unit(state: Dictionary, side: String, card_id: String, zone: String, slot: int) -> Dictionary:
	var unit := service._make_unit(state, state[side], service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	unit.recipe_ready_on_turn = 0
	state[side][zone].append(unit)
	return unit


func _test_sides_and_attribution() -> void:
	for target_side in ["player", "opponent"]:
		# The existing protection predicate has no source-side restriction. This
		# visual change must preserve that behavior for same-side effects too.
		for source_side in ["player", "opponent"]:
			var state := _state()
			var protector := _unit(state, target_side, PROTECTOR, "prep", 2)
			var target := _unit(state, target_side, TARGET, "prep", 0)
			var source := _unit(state, source_side, "spicy_sriracharrow", "plated", 0)
			var health_before := int(target.health)
			var previous := int(service._with_animation_group(state, 37))
			_expect(service._effect_damage_is_prevented(state, target_side, target), "Boolean prevention wrapper lost the existing protection.")
			_expect(not service._deal_effect_damage_to_unit(state, source_side, target_side, target, 4, source, true, 83), "Prevented damage incorrectly reported a successful hit.")
			var events := service.take_animation_events(state)
			_expect(events.size() == 1, "A prevented hit must emit exactly one presentation event.")
			if events.size() == 1:
				_expect_event(events[0], source_side, source, target_side, target, protector, 4, 83)
			_expect(int(target.health) == health_before and service._find_unit(state[target_side], int(target.instance_id)) == target, "Prevention altered health or removed the protected unit.")
			_expect(String(state.log.back()) == "%s protects %s from effect damage." % [protector.name, target.name], "The log failed to name the actual protecting card.")
			service._deal_effect_damage_to_unit(state, source_side, target_side, target, 1, source)
			events = service.take_animation_events(state)
			_expect(events.size() == 1 and int(events[0].group_id) == 37, "Default prevention event did not preserve the current animation group.")
			service._restore_animation_group(state, previous)


func _test_unprotected_and_zero_damage() -> void:
	for mode in ["self", "target Plated", "protector Plated", "absent", "zero", "negative", "empty"]:
		var state := _state()
		var protector: Dictionary = {}
		if mode != "absent":
			protector = _unit(state, "player", PROTECTOR, "plated" if mode == "protector Plated" else "prep", 2)
		var target: Dictionary = protector if mode == "self" else _unit(state, "player", TARGET, "plated" if mode == "target Plated" else "prep", 0)
		target.health = 5
		target.max_health = 5
		var amount := 0 if mode == "zero" else -1 if mode == "negative" else 1
		var invalid_hit: bool = mode in ["zero", "negative", "empty"]
		var result := service._deal_effect_damage_to_unit(state, "opponent", "player", {} if mode == "empty" else target, amount)
		var events := service.take_animation_events(state)
		_expect(events.all(func(event: Dictionary) -> bool: return String(event.type) != "damage_prevented"), mode + ": an inapplicable prevention cue was emitted.")
		if invalid_hit:
			_expect(not result and events.is_empty() and int(target.health) == 5, mode + ": invalid/zero damage changed health or emitted a cue.")
		else:
			_expect(result and int(target.health) == 4 and events.size() == 1 and String(events[0].type) == "damage", mode + ": ordinary unprotected damage rules changed.")


func _test_multiple_protectors() -> void:
	var state := _state()
	# Deliberately put slot2 first: select one real protector in existing field
	# order, rather than accidentally sorting or emitting a cue for every copy.
	var first := _unit(state, "opponent", PROTECTOR, "prep", 2)
	var second := _unit(state, "opponent", PROTECTOR, "prep", 0)
	var target := _unit(state, "opponent", TARGET, "prep", 1)
	first.name = "First Iceberg Skunkuce"
	var source := _unit(state, "player", "spicy_sriracharrow", "plated", 0)
	for hit in 3:
		service._deal_effect_damage_to_unit(state, "player", "opponent", target, 2, source, true, 52)
	var events := service.take_animation_events(state)
	_expect(events.size() == 3 and int(target.health) == 1, "Multiple protectors duplicated a cue per hit or failed to prevent repeated damage.")
	for event in events:
		_expect_event(event, "player", source, "opponent", target, first, 2, 52)
	_expect(String(state.log.back()).begins_with(String(first.name)), "Protection log was attributed to a side instead of the selected protector.")
	service._deal_effect_damage_to_unit(state, "player", "opponent", first, 1, source, true, 53)
	events = service.take_animation_events(state)
	_expect(events.size() == 1 and int(events[0].protector_instance_id) == int(second.instance_id), "A second Skunkuce should protect the first; a card must never attribute self-protection.")


func _test_real_sriracharrow_choice() -> void:
	var state := _state()
	var attacker := _unit(state, "player", "spicy_sriracharrow", "plated", 0)
	var next_attacker := _unit(state, "player", "spicy_sriracharrow", "plated", 1)
	var protector := _unit(state, "opponent", PROTECTOR, "prep", 0)
	var target := _unit(state, "opponent", TARGET, "prep", 2)
	var defender := _unit(state, "opponent", "hearty_bagver", "plated", 0)
	defender.health = 20
	defender.max_health = 20
	defender.attack = 1
	service.select_attacker(state, int(attacker.instance_id))
	service.attack(state, int(defender.instance_id))
	_expect(not state.pending_choice.is_empty() and service.choice_target_ids(state).has(int(target.instance_id)), "Real Sriracharrow attack did not offer the protected Prep target.")
	_expect(state.animation_events.is_empty() and int(target.health) == 1, "Pending choice applied a hit before a target was selected.")
	service.choose_effect_target(state, int(target.instance_id))
	var first_events: Array = state.animation_events.duplicate(true)
	var prevention := first_events.filter(func(event: Dictionary) -> bool: return String(event.type) == "damage_prevented")
	_expect(prevention.size() == 1 and int(target.health) == 1, "Real chosen Prep hit did not produce exactly one prevention event with unchanged health.")
	if prevention.size() == 1:
		_expect_event(prevention[0], "player", attacker, "opponent", target, protector, 1, 0)
		_expect(first_events.back() == prevention[0], "Sriracharrow's prevention cue did not retain its authored post-combat effect order.")
	_expect(state.pending_choice.is_empty() and state.pending_resume.is_empty() and int(defender.health) == 14 and int(attacker.health) == 3, "Blocking Prep damage changed the original Plated attack's resolution.")
	service.select_attacker(state, int(next_attacker.instance_id))
	service.attack(state, int(defender.instance_id))
	service.choose_effect_target(state, int(target.instance_id))
	var all_events := service.take_animation_events(state)
	_expect(all_events.size() > first_events.size() and String(all_events[first_events.size()].type) == "attack", "A following attack overtook the prior blocked-effect cue.")
	_expect(all_events.filter(func(event: Dictionary) -> bool: return String(event.type) == "damage_prevented").size() == 2 and int(target.health) == 1, "Repeated real attacks lost/doubled a prevention event or damaged the protected unit.")


func _expect_event(event: Dictionary, source_side: String, source: Dictionary, target_side: String, target: Dictionary, protector: Dictionary, amount: int, group: int) -> void:
	var expected := {
		"type": "damage_prevented", "group_id": group,
		"source_side": source_side, "source_instance_id": int(source.instance_id),
		"target_kind": "unit", "target_side": target_side,
		"target_instance_id": int(target.instance_id), "target_card_id": String(target.card_id),
		"target_table_slot": int(target.table_slot), "target_zone": "prep",
		"protector_side": target_side, "protector_instance_id": int(protector.instance_id),
		"protector_card_id": String(protector.card_id), "protector_table_slot": int(protector.table_slot),
		"protector_zone": "prep", "amount": amount,
	}
	for key in expected:
		_expect(event.get(key) == expected[key], "Prevention event %s expected %s, received %s." % [key, str(expected[key]), str(event.get(key))])
	_expect(int(event.get("id", 0)) > 0, "Prevention cue bypassed the animation event ID allocator.")


func _expect(condition: bool, message: String) -> void:
	if not condition and not failures.has(message):
		failures.append(message)
