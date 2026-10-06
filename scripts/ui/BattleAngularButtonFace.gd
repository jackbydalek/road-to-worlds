extends Control
class_name BattleAngularButtonFace

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")

var host_button: Button
var variant := "secondary"
var primary := false
## Every public action uses the same matte Painted Shapes treatment.
var peach_soda_style := true:
	set(value):
		if peach_soda_style == value:
			return
		peach_soda_style = value
		_apply_host_colors()
		queue_redraw()
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
	set_meta("painted_shapes", true)
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
	if host_button.disabled != _last_disabled:
		# Re-enabled actions must regain their normal text and icon contrast.
		_apply_host_colors()
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
	return text_color_for_state("disabled" if not is_instance_valid(host_button) or host_button.disabled else "normal")


func text_color_for_state(state: String) -> Color:
	if state == "disabled":
		return PALETTE.PEACH_INK.lerp(PALETTE.PEACH_PAPER_MUTED, 0.28) if peach_soda_style else PALETTE.LOCALS_INK_SOFT.darkened(0.10)
	var paper := PALETTE.PEACH_PAPER if peach_soda_style else PALETTE.COOL_WHITE
	var ink := PALETTE.PEACH_INK if peach_soda_style else PALETTE.LOCALS_INK
	return paper if variant in ["primary", "selected", "confirm", "danger", "target"] else ink


func fill_color_for_state(state: String) -> Color:
	var fill := _base_fill()
	if state in ["hover", "focus"]:
		if peach_soda_style:
			return PALETTE.PEACH_MINT if variant in ["secondary", "light"] else fill.darkened(0.06)
		return fill.lightened(0.045)
	if state == "pressed":
		if peach_soda_style:
			return PALETTE.PEACH_MINT.darkened(0.05) if variant in ["secondary", "light"] else fill.darkened(0.14)
		return fill.darkened(0.10)
	if state == "disabled":
		return PALETTE.PEACH_PAPER_MUTED if peach_soda_style else PALETTE.LOCALS_PAPER_MUTED
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
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var foreground := text_color_for_state(state)
		var font_key := "font_color" if state == "normal" else "font_%s_color" % state
		host_button.add_theme_color_override(font_key, foreground)
		host_button.add_theme_color_override("icon_%s_color" % state, foreground)
	# Printed labels have no embossed outline or drop shadow.
	host_button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	host_button.add_theme_constant_override("outline_size", 0)


func _draw() -> void:
	if not is_instance_valid(host_button) or size.x < 18.0 or size.y < 18.0:
		return
	var pressed := (_held or host_button.button_pressed) and not host_button.disabled
	var active := (host_button.is_hovered() or host_button.has_focus()) and not host_button.disabled
	var state := "disabled" if host_button.disabled else "pressed" if pressed else "hover" if active else "normal"
	var face_rect := Rect2(Vector2(3, 3 + (1 if pressed else 0)), size - Vector2(6, 7))
	# A single matte shape replaces outlined kit buttons. Its edge is stable;
	# only color and a one-pixel press change when interacting.
	SHAPES.draw_surface(self, face_rect, fill_color_for_state(state), 3)
	if host_button.has_focus() and not host_button.disabled:
		# Focus is explicit, rather than depending on a subtle fill change alone.
		SHAPES.draw_focus(self, face_rect.grow(-3.0), text_color_for_state("focus"), 3)


func _base_fill() -> Color:
	match variant:
		"primary":
			return PALETTE.PEACH_TEAL if peach_soda_style else PALETTE.LOCALS_BLUE.darkened(0.10)
		"selected":
			return PALETTE.PEACH_TEAL.darkened(0.16) if peach_soda_style else PALETTE.LOCALS_BLUE.darkened(0.22)
		"danger":
			return PALETTE.SIGNAL_RED.darkened(0.22)
		"target":
			return PALETTE.PEACH_TEAL.darkened(0.08) if peach_soda_style else PALETTE.LOCALS_BLUE.darkened(0.22)
		"confirm":
			return PALETTE.HEALTH_FILL
		"warning":
			return PALETTE.SIGNAL_YELLOW
		_:
			return PALETTE.PEACH_PAPER if peach_soda_style else PALETTE.LOCALS_PAPER


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
