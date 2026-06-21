extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._show_season_run_setup()
	await process_frame
	main._confirm_season_run_setup()
	await process_frame
	await process_frame

	if main.current_screen != "season":
		_fail("Season hub smoke did not enter the Season screen.")
		return
	if _count_named_nodes(main, "SeasonHubCardShop") == 0:
		_fail("Season hub smoke did not render the card shop hub.")
		return
	for hotspot in [
		"SeasonHubPackWall",
		"SeasonHubSinglesCase",
		"SeasonHubDeckbuilderTable",
		"SeasonHubRegisterDesk",
		"SeasonHubEventCalendar",
		"SeasonHubMenuBoard"
	]:
		if _count_named_nodes(main, hotspot) == 0:
			_fail("Season hub smoke did not render hotspot: " + hotspot)
			return

	if _count_named_nodes(main, "SeasonHubBoosterPack_0") == 0:
		_fail("Season hub smoke did not render pack wall visuals.")
		return
	if _count_named_nodes(main, "SeasonHubSingleTile") == 0:
		_fail("Season hub smoke did not render singles case previews.")
		return
	if _count_named_nodes(main, "SeasonHubCalendarEvent_weekly_locals") == 0:
		_fail("Season hub smoke did not render Weekly Locals on the calendar.")
		return

	var register_button := _find_node_by_name(main, "SeasonHubRegisterButton") as Button
	if register_button == null:
		_fail("Season hub smoke did not render the register button.")
		return
	if register_button.disabled:
		_fail("Season hub smoke rendered register disabled for a legal starter deck.")
		return

	var worlds_button := _find_node_by_name(main, "SeasonHubCalendarButton_worlds") as Button
	if worlds_button == null:
		_fail("Season hub smoke did not render the Worlds calendar button.")
		return
	if not worlds_button.disabled:
		_fail("Season hub smoke left the locked Worlds button enabled.")
		return

	print("Season hub smoke rendered card shop hotspots and calendar state.")
	quit(0)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if String(node.name).begins_with(target_name) else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
