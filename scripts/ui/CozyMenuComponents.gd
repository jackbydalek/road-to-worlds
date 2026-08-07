extends RefCounted
class_name CozyMenuComponents

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const INK := PALETTE.INK
const CREAM := PALETTE.GHOST
const MUTED_INK := PALETTE.SLATE


static func make_button(
	label: String,
	texture: Texture2D,
	minimum_size: Vector2,
	primary: bool = false,
	font_size: int = 30
) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = minimum_size
	button.add_theme_stylebox_override("normal", texture_style(texture, Color.WHITE, Vector4(34, 20, 34, 25), Vector4(42, 34, 42, 42)))
	button.add_theme_stylebox_override("hover", texture_style(texture, Color(1.08, 1.08, 1.08, 1.0), Vector4(34, 20, 34, 25), Vector4(42, 34, 42, 42)))
	button.add_theme_stylebox_override("pressed", texture_style(texture, Color(0.88, 0.88, 0.88, 1.0), Vector4(34, 20, 34, 25), Vector4(42, 38, 42, 38)))
	button.add_theme_stylebox_override("disabled", texture_style(texture, Color(0.72, 0.72, 0.72, 0.78), Vector4(34, 20, 34, 25), Vector4(42, 34, 42, 42)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var text_color := CREAM if primary else INK
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", PALETTE.DISABLED_INK)
	button.add_theme_font_override("font", bold_font())
	button.add_theme_font_size_override("font_size", font_size)
	return button


static func make_icon_button(
	texture: Texture2D,
	icon: Texture2D,
	minimum_size: Vector2 = Vector2(86, 88),
	icon_width: int = 48,
	_tooltip: String = ""
) -> Button:
	var button := make_button("", texture, minimum_size, false, 18)
	button.add_theme_stylebox_override("normal", texture_style(texture, Color.WHITE, Vector4(30, 30, 30, 34), Vector4(12, 12, 12, 15)))
	button.add_theme_stylebox_override("hover", texture_style(texture, Color(1.08, 1.08, 1.08, 1.0), Vector4(30, 30, 30, 34), Vector4(12, 12, 12, 15)))
	button.add_theme_stylebox_override("pressed", texture_style(texture, Color(0.88, 0.88, 0.88, 1.0), Vector4(30, 30, 30, 34), Vector4(12, 15, 12, 12)))
	button.add_theme_stylebox_override("disabled", texture_style(texture, Color(0.72, 0.72, 0.72, 0.78), Vector4(30, 30, 30, 34), Vector4(12, 12, 12, 15)))
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", icon_width)
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	button.add_theme_color_override("icon_hover_color", Color.WHITE)
	button.add_theme_color_override("icon_pressed_color", Color(0.84, 0.84, 0.84, 1.0))
	button.add_theme_color_override("icon_disabled_color", Color(0.62, 0.62, 0.62, 0.78))
	return button


static func make_panel(
	texture: Texture2D,
	minimum_size: Vector2,
	content_margins: Vector4 = Vector4(28, 28, 28, 30),
	texture_margins: Vector4 = Vector4(42, 42, 42, 46)
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", texture_style(texture, Color.WHITE, texture_margins, content_margins))
	return panel


static func make_banner(
	texture: Texture2D,
	text: String,
	minimum_size: Vector2,
	font_size: int,
	font_color: Color = INK
) -> TextureRect:
	var banner := TextureRect.new()
	banner.texture = texture
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	banner.custom_minimum_size = minimum_size
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", bold_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	banner.add_child(label)
	return banner


static func bold_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 0.65
	return font


static func texture_style(
	texture: Texture2D,
	tint: Color = Color.WHITE,
	texture_margins: Vector4 = Vector4.ZERO,
	content_margins: Vector4 = Vector4.ZERO
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


static func flat_panel_style(background: Color, border: Color, border_width: int = 3, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
