extends PanelContainer

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PAINT := preload("res://scripts/ui/PaintedUiShapes.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

var content: VBoxContainer
var scroll: ScrollContainer
var text_scale := 1.0


func configure(restrictions: Array[Dictionary], inspect_source: Callable, scale_value: float = 1.0) -> void:
	text_scale = scale_value
	for child in get_children():
		remove_child(child)
		child.queue_free()
	visible = not restrictions.is_empty()
	set_meta("restrictions", restrictions.duplicate(true))
	if not visible:
		return
	add_theme_stylebox_override("panel", PAINT.style(PALETTE.PEACH_PAPER, Vector4(10, 8, 10, 8), 81))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	add_child(column)
	var title := _label("Rival effects · %d" % restrictions.size(), 13)
	title.add_theme_color_override("font_color", PALETTE.PEACH_TEAL)
	column.add_child(title)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var scrollbar := scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 8
	for state_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
		var track := StyleBoxFlat.new()
		track.bg_color = PALETTE.PEACH_MINT if state_name == "scroll" else PALETTE.PEACH_TEAL
		track.set_corner_radius_all(3)
		track.content_margin_left = 3
		track.content_margin_right = 3
		scrollbar.add_theme_stylebox_override(state_name, track)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)
	for restriction in restrictions:
		var button := Button.new()
		button.name = "Restriction_" + String(restriction.get("card_id", restriction.kind))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "Inspect the source card"
		button.add_theme_stylebox_override("normal", PAINT.style(PALETTE.PEACH_PAPER_MUTED, Vector4(5, 5, 5, 5), 82, 6))
		button.add_theme_stylebox_override("hover", PAINT.style(PALETTE.PEACH_MINT, Vector4(5, 5, 5, 5), 82, 6))
		button.add_theme_stylebox_override("pressed", PAINT.style(PALETTE.PEACH_MINT, Vector4(5, 5, 5, 5), 82, 6))
		var focus := PAINT.style(Color.TRANSPARENT, Vector4(5, 5, 5, 5), 82, 6)
		focus.border_color = PALETTE.PEACH_TEAL
		focus.set_border_width_all(2)
		button.add_theme_stylebox_override("focus", focus)
		var copy := _label(String(restriction.message), 14)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		copy.offset_left = 8
		copy.offset_right = -8
		copy.offset_top = 5
		copy.offset_bottom = -5
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(copy)
		content.add_child(button)
		copy.minimum_size_changed.connect(func() -> void: button.custom_minimum_size.y = copy.get_minimum_size().y + 10)
		button.custom_minimum_size.y = 60 * text_scale
		if String(restriction.get("card_id", "")).is_empty():
			button.disabled = true
			button.tooltip_text = String(restriction.message)
		else:
			button.pressed.connect(inspect_source.bind(restriction))
func preferred_height() -> float:
	if not is_instance_valid(content):
		return 0.0
	# Fit a single effect snugly; several effects scroll inside the space between
	# the rival's scorecard and End Turn rather than growing into live battle controls.
	return content.get_combined_minimum_size().y + 13.0 * text_scale + 30.0


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", roundi(font_size * text_scale))
	label.set_meta("readability_base_font_font_size", font_size)
	label.add_theme_color_override("font_color", PALETTE.PEACH_INK)
	return label
