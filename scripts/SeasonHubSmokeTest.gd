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
		_fail("Season hub smoke did not enter the season calendar screen.")
		return
	if _count_named_nodes(main, "SeasonCalendarMap") == 0:
		_fail("Season hub smoke did not render the season calendar map.")
		return
	for hotspot in [
		"SeasonHubEventCalendar",
		"SeasonHubHeader"
	]:
		if _count_named_nodes(main, hotspot) == 0:
			_fail("Season hub smoke did not render calendar element: " + hotspot)
			return

	if _count_named_nodes(main, "SeasonHubCalendarEvent_weekly_locals") == 0:
		_fail("Season hub smoke did not render Weekly Locals on the calendar.")
		return

	var weekly_button := _find_node_by_name(main, "SeasonHubCalendarButton_weekly_locals") as Button
	if weekly_button == null:
		_fail("Season hub smoke did not render the Weekly Locals prep button.")
		return
	if weekly_button.disabled:
		_fail("Season hub smoke rendered the next event prep button disabled.")
		return
	if weekly_button.text != "Prep":
		_fail("Season hub smoke did not mark the selected next event as Prep.")
		return

	var worlds_button := _find_node_by_name(main, "SeasonHubCalendarButton_worlds") as Button
	if worlds_button == null:
		_fail("Season hub smoke did not render the Worlds calendar button.")
		return
	if not worlds_button.disabled:
		_fail("Season hub smoke left the locked Worlds button enabled.")
		return

	weekly_button.pressed.emit()
	await process_frame
	await process_frame

	if main.current_screen != "shop":
		_fail("Season hub smoke did not route next-event prep into the card shop.")
		return
	if _count_named_nodes(main, "CardShopStatusStrip") == 0:
		_fail("Season hub smoke did not render the card shop prep screen after calendar selection.")
		return

	print("Season hub smoke rendered the calendar map and routed next-event prep to the card shop.")
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
