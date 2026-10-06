extends SceneTree
## Pointer navigation must not paint stale return focus; keyboard keeps it.
const AREAS := [
	["seller", "HubSellerButton", "HubShopkeeper"],
	["counter", "HubShopButton", "HubShopDesk"],
	["machine", "HubMachineButton", "VendingMachineBody"],
]
var failures: Array[String] = []
var last_pointer := Vector2.ZERO

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main.run_state_service.save_path = "/private/tmp/locals-room-highlight-%d.json" % OS.get_process_id()
	root.size = Vector2i(1280, 720)
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "blue")
	main.route_run_service.initialize_run(main.run, 20260915)
	main.run.money = 16
	main.run.life = 25
	main._show_tournament_hub()
	await _settle()
	var hub = main.find_child("TournamentHub", true, false)
	var empty_point := Vector2(1260, 180)
	for index in AREAS.size():
		var area: Array = AREAS[index]
		var other: Array = AREAS[(index + 1) % AREAS.size()]
		var button := hub.find_child(String(area[1]), true, false) as Button
		var other_button := hub.find_child(String(other[1]), true, false) as Button
		var context := String(area[0])
		_click(button)
		await _settle()
		_check_closeup(hub, context, "pointer entry")
		_click(hub._shop_back)
		await _settle()
		_expect(main.current_screen == "route_hub", context + ": actual Back did not return to the room")
		_expect(root.gui_get_focus_owner() == button, context + ": Back lost the accessible return focus")
		# Deliberately retain focus from Back, as a player does. No release_focus.
		_move_pointer(other_button.get_global_rect().get_center())
		await _settle()
		_expect(other_button.is_hovered(), context + ": the new physical target was not hovered")
		_check_highlight(hub, String(other[0]), context + ": hover another area after Back")
		_move_pointer(empty_point)
		await _settle()
		_check_highlight(hub, "", context + ": empty room after Back")
		_key(KEY_TAB)
		await _settle()
		var next_focus: Control = button.get_node(button.focus_next) as Control
		_expect(root.gui_get_focus_owner() == next_focus, context + ": Tab did not continue from the saved focus")
		_check_highlight(hub, _area_for_button(next_focus), context + ": Tab navigation")
		_key(KEY_TAB, true)
		await _settle()
		_expect(root.gui_get_focus_owner() == button, context + ": Shift-Tab did not return to the area")
		_check_highlight(hub, context, context + ": Shift-Tab navigation")
		_key(KEY_ENTER)
		await _settle()
		_check_closeup(hub, context, "keyboard entry")
		_key(KEY_ESCAPE)
		await _settle()
		_expect(main.current_screen == "route_hub" and root.gui_get_focus_owner() == button, context + ": Escape lost the room or saved focus")
		_check_highlight(hub, context, context + ": Escape return")
		# Mouse takeover must also clear the restored keyboard highlight.
		_move_pointer(empty_point + Vector2(1, 0))
		await _settle()
		_check_highlight(hub, "", context + ": mouse takeover after Escape")
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Hub room highlight input smoke test: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _check_closeup(hub: Control, area: String, context: String) -> void:
	var property := "_shop_open" if area == "counter" else "_seller_open" if area == "seller" else "_machine_open"
	_expect(bool(hub.get(property)) and not bool(hub.get("_transitioning")), "%s: %s did not open the intended close-up" % [area, context])
	_check_highlight(hub, "", area + ": " + context + " close-up")

func _check_highlight(hub: Control, active: String, context: String) -> void:
	for area in AREAS:
		var button := hub.find_child(String(area[1]), true, false) as Button
		var artwork := hub.find_child(String(area[2]), true, false) as CanvasItem
		var expected := String(area[0]) == active
		_expect(bool(button.get_meta("highlight_active", false)) == expected, "%s: incorrect %s highlight" % [context, area[0]])
		var material := artwork.material as ShaderMaterial
		_expect(material != null and is_equal_approx(float(material.get_shader_parameter("highlight_strength")), 1.0 if expected else 0.0), "%s: incorrect %s painted highlight" % [context, area[0]])

func _area_for_button(button: Control) -> String:
	for area in AREAS:
		if button.name == area[1]:
			return String(area[0])
	return ""

func _settle() -> void:
	for frame in range(4):
		await process_frame

func _move_pointer(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - last_pointer
	last_pointer = point
	root.push_input(event, true)

func _click(button: Control) -> void:
	var point := button.get_global_rect().get_center()
	_move_pointer(point)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _key(code: Key, shifted: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shifted
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
