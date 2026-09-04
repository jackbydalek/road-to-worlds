extends Node
class_name MenuSparkleController

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var enabled := true


func _ready() -> void:
	if not enabled:
		return
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_controls")


func _bind_existing_controls() -> void:
	var tree_root := get_tree().root
	for node in tree_root.find_children("*", "Control", true, false):
		_bind_control(node as Control)


func _on_node_added(node: Node) -> void:
	if enabled and node is Control:
		call_deferred("_bind_control_by_id", node.get_instance_id())


func _bind_control_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Control:
		_bind_control(node as Control)


func _bind_control(control: Control) -> void:
	if not is_instance_valid(control) or _belongs_to_tabletop(control):
		return
	if control is BaseButton:
		_bind_button(control as BaseButton)


func _bind_button(button: BaseButton) -> void:
	if bool(button.get_meta("menu_press_feedback_bound", false)):
		return
	button.set_meta("menu_press_feedback_bound", true)
	button.button_down.connect(func() -> void: _play_button_press(button))


func _play_button_press(button: BaseButton) -> void:
	if not _can_play_for(button) or button.disabled:
		return
	_spawn_edge_flash(button, _button_accent(button))


func _spawn_edge_flash(button: BaseButton, accent: Color) -> void:
	if not enabled or not is_instance_valid(button):
		return
	var reduced_motion := bool(get_tree().root.get_meta("reduced_motion", false))
	var feedback := Node2D.new()
	feedback.name = "MenuPressEdgeFlash"
	feedback.z_index = 20
	button.add_child(feedback)
	var width := maxf(1.0, button.size.x)
	var height := maxf(1.0, button.size.y)
	feedback.add_child(_edge_line(PackedVector2Array([
		Vector2(2, minf(12.0, height * 0.25)),
		Vector2(2, 2),
		Vector2(maxf(34.0, width * 0.38), 2),
	]), accent))
	if not reduced_motion:
		feedback.add_child(_edge_line(PackedVector2Array([
			Vector2(width - 2, height - minf(12.0, height * 0.25)),
			Vector2(width - 2, height - 2),
			Vector2(minf(width - 34.0, width * 0.62), height - 2),
		]), PALETTE.COOL_WHITE))
	var duration := 0.12 if reduced_motion else 0.20
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, duration * 0.58).set_delay(duration * 0.42)
	tween.finished.connect(feedback.queue_free)


func _button_accent(button: BaseButton) -> Color:
	match String(button.get_meta("ui_button_variant", "default")):
		"danger": return PALETTE.ACTION_DANGER
		"confirm": return PALETTE.ACTION_CONFIRM
		"special": return PALETTE.ACTION_SPECIAL
		"primary": return PALETTE.ACTION_PRIMARY
		_: return PALETTE.FOCUS_EDGE


func _edge_line(points: PackedVector2Array, color: Color) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = 3.0
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_BOX
	line.antialiased = true
	return line


func _can_play_for(control: Control) -> bool:
	return enabled and is_instance_valid(control) and control.is_visible_in_tree() and not _belongs_to_tabletop(control)


func _belongs_to_tabletop(node: Node) -> bool:
	var cursor := node
	while cursor != null:
		if cursor.name == "Tabletop3DPrototype":
			return true
		cursor = cursor.get_parent()
	return false
