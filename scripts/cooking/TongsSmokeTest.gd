extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Tongs test could not load the production card catalog.")
		return
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 73001)
	state.player.hand = ["item_tongs"]
	var plated := _test_unit(1001, "hearty_dumpling_tortoise", "Dumpling-Backed Tortoise", "meal", 4, 5, true, 1)
	var prep := _test_unit(1002, "hearty_bagver", "Bagver", "ingredient", 1, 2, false, 2)
	state.opponent.plated = [plated]
	state.opponent.prep = [prep]

	service.play_card(state, 0)
	if service.choice_target_ids(state) != [1001]:
		_fail("Tongs did not ask for an opposing Plated card first.")
		return
	service.choose_effect_target(state, 1001)
	if service.choice_target_ids(state) != [1002]:
		_fail("Tongs did not ask for an opposing Prep card second.")
		return
	service.choose_effect_target(state, 1002)

	if int(state.opponent.plated[0].instance_id) != 1002 or int(state.opponent.prep[0].instance_id) != 1001:
		_fail("Tongs did not exchange the selected opposing cards.")
		return
	if int(state.opponent.plated[0].table_slot) != 1 or int(state.opponent.prep[0].table_slot) != 2:
		_fail("Tongs did not preserve the selected cards' destination slots.")
		return
	var move_events: Array = service.take_animation_events(state).filter(func(event: Dictionary) -> bool:
		return String(event.get("type", "")) == "move"
	)
	if move_events.size() != 2 or int(move_events[0].group_id) != int(move_events[1].group_id):
		_fail("Tongs did not emit one paired movement animation.")
		return

	var no_prep_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 73002)
	no_prep_state.player.hand = ["item_tongs"]
	no_prep_state.opponent.plated = [_test_unit(1003, "hearty_dumpling_tortoise", "Dumpling-Backed Tortoise", "meal", 4, 5, true, 1)]
	no_prep_state.opponent.prep = []
	service.play_card(no_prep_state, 0)
	if not no_prep_state.pending_choice.is_empty():
		_fail("Tongs opened an unfinishable choice without both opposing zones occupied.")
		return
	print("Tongs smoke test passed.")
	quit()


func _test_unit(instance_id: int, card_id: String, name: String, card_type: String, attack: int, health: int, ready: bool, table_slot: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": card_id,
		"name": name,
		"card_type": card_type,
		"attack": attack,
		"health": health,
		"max_health": health,
		"ready": ready,
		"defending": false,
		"table_slot": table_slot,
		"spices": [],
		"used_abilities": [],
		"triggered_effects": [],
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
