extends Control
class_name CardTargetingArrow

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

const INVALID_COLOR := PALETTE.STRUCTURAL_EDGE
const ATTACK_COLOR := PALETTE.SIGNAL_RED
const SWITCH_COLOR := PALETTE.ELECTRIC_CYAN
const DOT_SPACING := 23.0
const DOT_SPEED := 92.0
const ARROW_HEAD_CLEARANCE := 28.0
const DOTTED_ACTION_KINDS := ["attack", "switch"]

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var action_kind := ""
var valid_target := false
var arrow_color := INVALID_COLOR
var dot_animation_phase := 0.0


func configure(start_value: Vector2, end_value: Vector2, kind: String, is_valid: bool) -> void:
	start_point = start_value
	end_point = end_value
	action_kind = kind
	valid_target = is_valid
	arrow_color = _color_for_state(kind, is_valid)
	visible = true
	set_process(kind in DOTTED_ACTION_KINDS)
	queue_redraw()


func clear() -> void:
	action_kind = ""
	valid_target = false
	visible = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not visible or action_kind not in DOTTED_ACTION_KINDS:
		return
	dot_animation_phase = fmod(dot_animation_phase + delta * DOT_SPEED, DOT_SPACING)
	queue_redraw()


func _color_for_state(kind: String, is_valid: bool) -> Color:
	if not is_valid:
		return INVALID_COLOR
	if kind == "attack":
		return ATTACK_COLOR
	if kind == "switch":
		return SWITCH_COLOR
	return INVALID_COLOR


func _draw() -> void:
	var distance := start_point.distance_to(end_point)
	if not visible or distance < 8.0:
		return
	var direct := (end_point - start_point).normalized()
	var perpendicular := Vector2(-direct.y, direct.x)
	var bend := clampf(distance * 0.11, 12.0, 46.0)
	var control_point := start_point.lerp(end_point, 0.5) + perpendicular * bend
	var path := PackedVector2Array()
	for step in range(19):
		var t := float(step) / 18.0
		var inverse_t := 1.0 - t
		path.append(
			inverse_t * inverse_t * start_point
			+ 2.0 * inverse_t * t * control_point
			+ t * t * end_point
		)
	var tip_direction := (path[-1] - path[-2]).normalized()
	var tip_perpendicular := Vector2(-tip_direction.y, tip_direction.x)
	var outer_head := PackedVector2Array([
		end_point + tip_direction * 2.0,
		end_point - tip_direction * 31.0 + tip_perpendicular * 19.0,
		end_point - tip_direction * 24.0,
		end_point - tip_direction * 31.0 - tip_perpendicular * 19.0,
	])
	var inner_head := PackedVector2Array([
		end_point,
		end_point - tip_direction * 25.0 + tip_perpendicular * 13.0,
		end_point - tip_direction * 19.0,
		end_point - tip_direction * 25.0 - tip_perpendicular * 13.0,
	])
	var carbon := Color(PALETTE.CARBON, 0.94)
	if action_kind in DOTTED_ACTION_KINDS:
		_draw_animated_dots(path, carbon)
	else:
		draw_polyline(path, carbon, 13.0, true)
		draw_polyline(path, Color(arrow_color, 0.96), 7.0, true)
	draw_colored_polygon(outer_head, carbon)
	draw_colored_polygon(inner_head, arrow_color)
	draw_circle(start_point, 8.0, carbon)
	draw_circle(start_point, 4.5, arrow_color)


func _draw_animated_dots(path: PackedVector2Array, carbon: Color) -> void:
	var cumulative_lengths := PackedFloat32Array([0.0])
	var total_length := 0.0
	for point_index in range(1, path.size()):
		total_length += path[point_index - 1].distance_to(path[point_index])
		cumulative_lengths.append(total_length)
	var distance_along := dot_animation_phase + DOT_SPACING * 0.58
	var final_dot_distance := maxf(0.0, total_length - ARROW_HEAD_CLEARANCE)
	while distance_along <= final_dot_distance:
		var dot_position := _point_along_path(path, cumulative_lengths, distance_along)
		draw_circle(dot_position, 7.0, carbon)
		draw_circle(dot_position, 4.2, Color(arrow_color, 0.98))
		distance_along += DOT_SPACING


func _point_along_path(
	path: PackedVector2Array,
	cumulative_lengths: PackedFloat32Array,
	distance_along: float
) -> Vector2:
	for point_index in range(1, cumulative_lengths.size()):
		if distance_along > cumulative_lengths[point_index]:
			continue
		var segment_start := cumulative_lengths[point_index - 1]
		var segment_length := maxf(0.001, cumulative_lengths[point_index] - segment_start)
		var segment_t := (distance_along - segment_start) / segment_length
		return path[point_index - 1].lerp(path[point_index], segment_t)
	return path[-1]
