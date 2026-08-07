extends RefCounted
class_name NexusMenuComponents

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

const INK := PALETTE.INK
const PAPER := PALETTE.GHOST
const PAPER_DIM := PALETTE.GHOST_PRESSED
const TEAL := PALETTE.TEAL
const TEAL_DARK := PALETTE.TEAL_DARK
const TEAL_DEEP := PALETTE.LAVENDER_GLASS
const MUSTARD := PALETTE.APRICOT
const ORANGE := PALETTE.BRICK
const MUTED := PALETTE.SLATE


static func panel_style(
	fill: Color = PAPER,
	border: Color = MUSTARD,
	border_width: int = 2,
	radius: int = 3,
	margins: Vector4 = Vector4(18, 14, 18, 14),
	shadow: bool = true
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	style.anti_aliasing = true
	if shadow:
		style.shadow_color = Color(PALETTE.NAVY, 0.20)
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 4)
	return style


static func make_panel(
	minimum_size: Vector2 = Vector2.ZERO,
	fill: Color = PAPER,
	border: Color = MUSTARD,
	margins: Vector4 = Vector4(18, 14, 18, 14)
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(fill, border, 2, 3, margins))
	return panel


static func make_header_panel(minimum_size: Vector2 = Vector2(0, 90)) -> PanelContainer:
	var panel := make_panel(minimum_size, PALETTE.APRICOT_SOFT, PALETTE.CORAL, Vector4(24, 12, 24, 12))
	panel.add_theme_stylebox_override(
		"panel",
		panel_style(PALETTE.APRICOT_SOFT, PALETTE.CORAL, 3, 12, Vector4(24, 12, 24, 12), true)
	)
	return panel


static func make_menu_button(
	label: String,
	icon: Texture2D,
	selected: bool = false,
	action: bool = false
) -> Button:
	var button := Button.new()
	button.text = label.to_upper()
	button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = false
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_override("font", SKETCH_UI.display_font(0.72))
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_constant_override("icon_max_width", 28)
	button.add_theme_constant_override("h_separation", 14)

	var normal_fill := TEAL if selected else (MUSTARD.darkened(0.03) if action else PAPER)
	var normal_text := PAPER if selected else INK
	var normal_border := MUSTARD if selected else (TEAL_DARK if action else TEAL)
	button.add_theme_stylebox_override("normal", _button_style(normal_fill, normal_border, false, false))
	button.add_theme_stylebox_override("hover", _button_style(normal_fill.lightened(0.08), ORANGE, false, true))
	button.add_theme_stylebox_override("pressed", _button_style(normal_fill.darkened(0.12), ORANGE, true, false))
	button.add_theme_stylebox_override("disabled", _button_style(PAPER_DIM, PALETTE.DISABLED_INK, false, false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(state, normal_text)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_color_override("icon_disabled_color", MUTED)
	return button


static func make_event_button(selected: bool, completed: bool, unlocked: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_override("font", SKETCH_UI.display_font(0.68))
	button.add_theme_font_size_override("font_size", 16)
	var fill := TEAL if selected else (PALETTE.TEAL_SOFT if completed else PAPER)
	var border := MUSTARD if selected else (TEAL if unlocked else PALETTE.DISABLED_INK)
	var foreground := PAPER if selected else INK
	button.add_theme_stylebox_override("normal", _button_style(fill, border, false, false, 1))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.08), ORANGE, false, true, 1))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.12), ORANGE, true, false, 1))
	button.add_theme_stylebox_override("disabled", _button_style(PAPER_DIM, PALETTE.DISABLED_INK, false, false, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, foreground)
	button.add_theme_color_override("font_disabled_color", MUTED)
	return button


static func make_section_label(text: String, color: Color = INK, size: int = 20) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_override("font", SKETCH_UI.display_font(0.78))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func make_body_label(text: String, color: Color = MUTED, size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", SKETCH_UI.body_font(0.12))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func make_status_badge(text: String, accent: Color = MUSTARD) -> PanelContainer:
	var badge := make_panel(Vector2.ZERO, PALETTE.APRICOT_SOFT, accent, Vector4(10, 5, 10, 5))
	badge.add_theme_stylebox_override("panel", panel_style(PALETTE.APRICOT_SOFT, accent, 1, 10, Vector4(10, 5, 10, 5), false))
	var label := make_section_label(text, INK, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge


static func _button_style(
	fill: Color,
	border: Color,
	pressed: bool,
	hovered: bool,
	radius: int = 2
) -> StyleBoxFlat:
	var top := 10 if not pressed else 13
	var bottom := 11 if not pressed else 8
	var style := panel_style(fill, border, 2, radius, Vector4(18, top, 18, bottom), not pressed)
	if hovered:
		style.shadow_color = Color(ORANGE, 0.34)
		style.shadow_size = 9
	return style
