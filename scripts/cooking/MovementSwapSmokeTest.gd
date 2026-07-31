extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")


func _init() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load production card content.")
		return
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 73001)
	state.phase = "player_main"
	state.player.zone_move_used = false
	state.player.prep = []
	state.player.plated = []
	var prep_unit: Dictionary = service._make_unit(state, state.player, service.card("spicy_hot_honey_bee"), "prep", "player")
	prep_unit.table_slot = 1
	var plated_unit: Dictionary = service._make_unit(state, state.player, service.card("hearty_bagver"), "plated", "player")
	plated_unit.table_slot = 0
	state.player.prep.append(prep_unit)
	state.player.plated.append(plated_unit)
	service.clear_animation_events(state)
	service.move_unit(state, int(prep_unit.instance_id), "plated", 0)
	var moved_prep: Dictionary = service._find_unit_in_zone(state.player, "plated", int(prep_unit.instance_id))
	var moved_plated: Dictionary = service._find_unit_in_zone(state.player, "prep", int(plated_unit.instance_id))
	if moved_prep.is_empty() or moved_plated.is_empty() or int(moved_prep.table_slot) != 0 or int(moved_plated.table_slot) != 1 or not bool(state.player.zone_move_used):
		_fail("Moving into an occupied destination did not switch the two units and consume the turn move.")
		return
	var events: Array[Dictionary] = service.take_animation_events(state)
	if events.size() != 2 or String(events[0].get("type", "")) != "move" or String(events[1].get("type", "")) != "move" or int(events[0].get("group_id", -1)) != int(events[1].get("group_id", -2)):
		_fail("A swap did not queue both movement animations together.")
		return
	print("MOVEMENT SWAP SMOKE TEST PASSED")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
