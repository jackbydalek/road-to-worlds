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
	if _count_named_nodes(main, "CombatCardFrameCombatStats") > 0:
		_fail("Card frame smoke rendered the removed center stat line.")
		return
	var rarity_symbol := _find_named_node(main, "CombatCardFrameRarity")
	if rarity_symbol == null or not rarity_symbol is Label or (rarity_symbol as Label).text != "•":
		_fail("Card frame smoke did not render common rarity as a dot.")
		return
	if _count_named_nodes(main, "CombatCardFrameCostHalo") == 0:
		_fail("Card frame smoke did not render the focus orb flair.")
		return
	var printed_card := _find_named_node(main, "CombatCardFramePrintedCard")
	if printed_card == null or not printed_card is Control:
		_fail("Card frame smoke did not render a printed card face.")
		return
	var printed_size: Vector2 = (printed_card as Control).custom_minimum_size
	if printed_size.y <= printed_size.x * 1.20:
		_fail("Card frame smoke rendered a horizontally squashed printed card face.")
		return
	var frame_texture := _find_named_node(main, "CombatCardFrameFrameTexture")
	if frame_texture == null or not frame_texture is TextureRect:
		_fail("Card frame smoke did not render the printed frame texture.")
		return
	if (frame_texture as TextureRect).expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		_fail("Card frame smoke rendered a frame texture that can crop instead of scale.")
		return
	if main.card_frame_factory._printed_frame_texture_path("threat_aggro") != "res://assets/card_frames/threat_aggro_silver.png":
		_fail("Card frame smoke did not route threat cards to the threat frame.")
		return
	if main.card_frame_factory._printed_frame_texture_path("action_engine_aggro") != "res://assets/card_frames/action_or_engine_aggro_silver.png":
		_fail("Card frame smoke did not route action/engine cards to the shared frame.")
		return
	if main.card_frame_factory._printed_frame_texture_path("threat_generic") != "res://assets/card_frames/threat_generic_silver.png":
		_fail("Card frame smoke did not route neutral threat cards to the generic frame.")
		return
	if main.card_frame_factory._printed_frame_texture_path("action_engine_generic") != "res://assets/card_frames/action_or_engine_generic_silver.png":
		_fail("Card frame smoke did not route neutral action/engine cards to the generic frame.")
		return
	if main._card_frame_template_id(main.cards_by_id["red_spark_runner"]) != "threat_aggro":
		_fail("Card frame smoke did not classify threat cards for the aggro threat frame.")
		return
	if main._card_frame_template_id(main.cards_by_id["red_quick_spark"]) != "action_engine_aggro":
		_fail("Card frame smoke did not classify action cards for the aggro action/engine frame.")
		return

	print("Card frame smoke rendered archetype frames in combat UI.")
	quit(0)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _find_named_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named_node(child, target_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
