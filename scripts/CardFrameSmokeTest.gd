extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_new_run("flightless_birds")
	main._show_ui_combat()
	main._start_manual_combat_lab_battle()
	await process_frame

	main.run.manual_combat["player"]["board"].append({
		"instance_id": 991,
		"card_id": "red_spark_runner",
		"name": "Smoke Runner",
		"attack": 2,
		"health": 1,
		"max_health": 1,
		"ready": true,
		"tags": ["fast"]
	})
	main.run.manual_combat["player"]["hand"].append("red_quick_spark")
	main._show_ui_combat()
	await process_frame
	await process_frame

	if _count_named_nodes(main, "DeckbuilderPreviewFrame") > 0:
		_fail("Card frame smoke unexpectedly rendered deckbuilder preview in combat.")
		return
	if _count_named_nodes(main, "CombatCardFrameName") == 0:
		_fail("Card frame smoke did not render combat card names.")
		return
	if _count_named_nodes(main, "CombatCardFrameCost") == 0:
		_fail("Card frame smoke did not render combat card cost badges.")
		return
	if _count_named_nodes(main, "CombatCardFrameType") == 0:
		_fail("Card frame smoke did not render combat card type strips.")
		return
	if _count_named_nodes(main, "CombatCardFrameAttackStat") == 0:
		_fail("Card frame smoke did not render combat card attack chips.")
		return
	if _count_named_nodes(main, "CombatCardFrameHealthStat") == 0:
		_fail("Card frame smoke did not render combat card health chips.")
		return

	print("Card frame smoke rendered reusable frames in combat UI.")
	quit(0)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
