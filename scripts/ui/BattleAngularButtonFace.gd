extends Control
class_name BattleAngularButtonFace

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var host_button: Button
var variant := "secondary"
var primary := false
var _held := false
var _restyle_requested := false
var _last_disabled := false
var _last_pressed := false
var _last_hovered := false


func configure(button: Button, style_variant: Variant = "secondary") -> void:
	host_button = button
	variant = _normalize_variant(
		("primary" if bool(style_variant) else "secondary")
		if style_variant is bool
		else String(style_variant)
	)
	primary = variant == "primary"
	host_button.set_meta("ui_button_variant", variant)
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_host_colors()
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	if is_instance_valid(host_button):
		host_button.mouse_entered.connect(queue_redraw)
		host_button.mouse_exited.connect(queue_redraw)
		host_button.focus_entered.connect(queue_redraw)
		host_button.focus_exited.connect(queue_redraw)
		host_button.button_down.connect(_on_button_down)
		host_button.button_up.connect(_on_button_up)
		host_button.toggled.connect(func(_pressed: bool) -> void: queue_redraw())
	_last_disabled = host_button.disabled if is_instance_valid(host_button) else false
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(host_button):
		return
	var requested_variant := _normalize_variant(String(host_button.get_meta("ui_button_variant", variant)))
	if requested_variant != variant:
		variant = requested_variant
		primary = variant == "primary"
		_apply_host_colors()
		queue_redraw()
	var pressed := _held or host_button.button_pressed
	var hovered := host_button.is_hovered() or host_button.has_focus()
	if host_button.disabled != _last_disabled or pressed != _last_pressed or hovered != _last_hovered:
		_last_disabled = host_button.disabled
		_last_pressed = pressed
		_last_hovered = hovered
		queue_redraw()
	var normal_style := host_button.get_theme_stylebox("normal")
	if (
		not _restyle_requested
		and not bool(normal_style.get_meta("global_angular_button_spacing", false))
	):
		var controller := get_tree().get_first_node_in_group("ui_button_style_controller")
		if controller != null and controller.has_method("refresh_button_by_id"):
			_restyle_requested = true
			controller.call_deferred("refresh_button_by_id", host_button.get_instance_id())


func mark_restyled() -> void:
	_restyle_requested = false


func text_color() -> Color:
	if not is_instance_valid(host_button) or host_button.disabled:
		return Color(PALETTE.COOL_WHITE, 0.48)
	return text_color_for_state("normal")


func text_color_for_state(state: String) -> Color:
	if state == "disabled":
		return Color(PALETTE.COOL_WHITE, 0.48)
	return PALETTE.CARBON if variant in ["selected", "confirm", "warning", "light"] else PALETTE.COOL_WHITE


func fill_color_for_state(state: String) -> Color:
	var fill := _base_fill()
	if state in ["hover", "focus"]:
		return fill.lightened(0.09)
	if state == "pressed":
		return fill.darkened(0.13)
	if state == "disabled":
		return PALETTE.STEEL.darkened(0.16)
	return fill


func _on_button_down() -> void:
	_held = true
	queue_redraw()


func _on_button_up() -> void:
	_held = false
	queue_redraw()


func _apply_host_colors() -> void:
	if not is_instance_valid(host_button):
		return
	var foreground := text_color()
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		host_button.add_theme_color_override(color_name, foreground)
	host_button.add_theme_color_override("font_disabled_color", Color(PALETTE.COOL_WHITE, 0.48))
	# Light buttons use carbon text, so their icons need the same foreground.
	# White icons disappear against the pale button face.
	var icon_foreground := foreground
	for color_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		host_button.add_theme_color_override(color_name, icon_foreground)
	host_button.add_theme_color_override("icon_disabled_color", Color(PALETTE.COOL_WHITE, 0.48))


func _draw() -> void:
	if not is_instance_valid(host_button) or size.x < 18.0 or size.y < 18.0:
		return
	var pressed := _held or host_button.button_pressed
	var active := host_button.is_hovered() or host_button.has_focus()
	var quiet_keyline := bool(host_button.get_meta("ui_button_quiet_keyline", false))
	var pressed_offset := Vector2(0, 2) if pressed else Vector2.ZERO
	var cut := clampf(size.y * 0.18, 6.0, 11.0)
	var card_action_shape := String(host_button.get_meta("ui_button_shape", "")) == "card_action"
	var points := _card_action_points(pressed_offset) if card_action_shape else PackedVector2Array([
		Vector2(cut, 2) + pressed_offset,
		Vector2(size.x - 2, 2) + pressed_offset,
		Vector2(size.x - 2, size.y - cut) + pressed_offset,
		Vector2(size.x - cut, size.y - 2) + pressed_offset,
		Vector2(2, size.y - 2) + pressed_offset,
		Vector2(2, cut) + pressed_offset,
	])
	var fill := _base_fill()
	var outline := _quiet_outline() if quiet_keyline else _base_outline()
	if host_button.disabled:
		fill = PALETTE.STEEL.darkened(0.16)
		outline = Color(PALETTE.STEEL, 0.72)
	elif active:
		fill = fill.lightened(0.09)
		outline = PALETTE.CARBON if variant in ["selected", "warning", "light"] else PALETTE.COOL_WHITE
	elif pressed:
		fill = fill.darkened(0.13)
		outline = PALETTE.CARBON if variant in ["selected", "warning", "light"] else PALETTE.COOL_WHITE

	if not pressed:
		draw_colored_polygon(_offset_points(points, Vector2(3, 4)), Color(PALETTE.CARBON, 0.48))
	draw_colored_polygon(points, fill)
	var diagonal := _card_action_diagonal(pressed_offset) if card_action_shape else PackedVector2Array([
		Vector2(size.x * 0.55, 3) + pressed_offset,
		Vector2(size.x - 3, 3) + pressed_offset,
		Vector2(size.x - 3, size.y - cut) + pressed_offset,
		Vector2(size.x - cut, size.y - 3) + pressed_offset,
		Vector2(size.x * 0.74, size.y - 3) + pressed_offset,
	])
	draw_colored_polygon(
		diagonal,
		Color(PALETTE.CARBON, 0.15)
		if variant in ["selected", "confirm", "warning", "light"]
		else Color(PALETTE.COOL_WHITE, 0.045)
	)
	_draw_closed_line(points, outline, 2.5)
	var local_accent := _variant_accent()
	draw_line(
		Vector2(cut, 2.0) + pressed_offset,
		Vector2(minf(size.x * 0.34, size.x - 14.0), 2.0) + pressed_offset,
		local_accent,
		3.5,
		true
	)
	if not quiet_keyline and variant in ["primary", "selected"]:
		_draw_closed_line(
			_scaled_points(points, Vector2(0.93, 0.80)) if card_action_shape else _scaled_points(points, Vector2(0.974, 0.82)),
			Color(PALETTE.COOL_WHITE, 0.38) if variant == "primary" else Color(PALETTE.CARBON, 0.30),
			1.0
		)


func _card_action_points(pressed_offset: Vector2) -> PackedVector2Array:
	var shoulder := clampf(size.x * 0.16, 10.0, 15.0)
	var end_inset := clampf(size.y * 0.31, 14.0, 19.0)
	return PackedVector2Array([
		Vector2(shoulder, 2) + pressed_offset,
		Vector2(size.x - shoulder, 2) + pressed_offset,
		Vector2(size.x - 2, end_inset) + pressed_offset,
		Vector2(size.x - 2, size.y - end_inset) + pressed_offset,
		Vector2(size.x - shoulder, size.y - 2) + pressed_offset,
		Vector2(shoulder, size.y - 2) + pressed_offset,
		Vector2(2, size.y - end_inset) + pressed_offset,
		Vector2(2, end_inset) + pressed_offset,
	])


func _card_action_diagonal(pressed_offset: Vector2) -> PackedVector2Array:
	var shoulder := clampf(size.x * 0.16, 10.0, 15.0)
	var end_inset := clampf(size.y * 0.31, 14.0, 19.0)
	return PackedVector2Array([
		Vector2(size.x * 0.58, 3) + pressed_offset,
		Vector2(size.x - shoulder, 3) + pressed_offset,
		Vector2(size.x - 3, end_inset) + pressed_offset,
		Vector2(size.x - 3, size.y - end_inset) + pressed_offset,
		Vector2(size.x - shoulder, size.y - 3) + pressed_offset,
		Vector2(size.x * 0.72, size.y - 3) + pressed_offset,
	])


func _base_fill() -> Color:
	match variant:
		"primary":
			return PALETTE.SELECTION_BLUE
		"danger":
			return PALETTE.SIGNAL_RED
		"target":
			return PALETTE.INTERFACE_VIOLET
		"selected":
			return PALETTE.ELECTRIC_CYAN
		"confirm":
			return PALETTE.EMERALD
		"warning":
			return PALETTE.SIGNAL_YELLOW
		"light":
			return PALETTE.COOL_WHITE.darkened(0.04)
		_:
			return PALETTE.GRAPHITE


func _base_outline() -> Color:
	match variant:
		"selected", "confirm", "warning", "light":
			return PALETTE.CARBON
		"primary", "danger", "target":
			return PALETTE.COOL_WHITE
		_:
			return PALETTE.STRUCTURAL_EDGE


func _quiet_outline() -> Color:
	match variant:
		"selected", "confirm", "warning", "light":
			return PALETTE.CARBON
		_:
			return PALETTE.STRUCTURAL_EDGE.darkened(0.18)


func _variant_accent() -> Color:
	match variant:
		"primary", "selected":
			return PALETTE.ELECTRIC_CYAN if variant == "primary" else PALETTE.CARBON
		"danger":
			return PALETTE.SIGNAL_RED
		"target":
			return PALETTE.INTERFACE_VIOLET
		"confirm":
			return PALETTE.EMERALD.darkened(0.24)
		"warning":
			return PALETTE.CARBON
		"light":
			return PALETTE.STEEL
		_:
			return PALETTE.STRUCTURAL_EDGE


func _normalize_variant(value: String) -> String:
	match value.to_lower():
		"action", "primary":
			return "primary"
		"danger", "destructive":
			return "danger"
		"target", "special":
			return "target"
		"selected", "active":
			return "selected"
		"confirm", "success":
			return "confirm"
		"warning", "reward":
			return "warning"
		"light":
			return "light"
		_:
			return "secondary"


func _draw_closed_line(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _scaled_points(points: PackedVector2Array, scale: Vector2) -> PackedVector2Array:
	var center := size * 0.5
	var result := PackedVector2Array()
	for point in points:
		result.append((point - center) * scale + center)
	return result
