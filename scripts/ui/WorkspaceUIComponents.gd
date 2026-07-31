extends RefCounted
class_name WorkspaceUIComponents

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")

const INK := SKETCH_UI.INK
const MUTED_INK := SKETCH_UI.MUTED_INK
const TEAL := SKETCH_UI.TEAL
const ORANGE := SKETCH_UI.ORANGE
const MUSTARD := SKETCH_UI.MUSTARD
const SURFACE := Color("#FFFCF6")
const SURFACE_WARM := Color("#F8F1E4")
const BORDER_SOFT := Color("#C8BDAE")
const TEAL_SOFT := Color("#DDECE8")
const ORANGE_SOFT := Color("#F6DED5")
const MUSTARD_SOFT := Color("#F8E8BC")


static func clean_style(
	background: Color,
	border: Color = BORDER_SOFT,
	border_width: int = 1,
	radius: int = 7,
	content_margins: Vector4 = Vector4.ZERO,
	accent_width: int = 0,
	with_shadow: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	if accent_width > 0:
		style.border_width_left = accent_width
	style.set_corner_radius_all(radius)
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	style.anti_aliasing = true
	if with_shadow:
		style.shadow_color = Color(0.15, 0.11, 0.08, 0.18)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 3)
	return style


static func make_section(
	title: String,
	accent: Color = TEAL,
	minimum_size: Vector2 = Vector2.ZERO,
	warm: bool = false,
	margins: Vector4 = Vector4(12, 9, 12, 9)
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		clean_style(SURFACE_WARM if warm else SURFACE, accent, 1, 8, Vector4.ZERO, 4)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(margins.x))
	margin.add_theme_constant_override("margin_top", int(margins.y))
	margin.add_theme_constant_override("margin_right", int(margins.z))
	margin.add_theme_constant_override("margin_bottom", int(margins.w))
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	margin.add_child(body)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_override("font", SKETCH_UI.body_font(0.58))
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", INK)
	body.add_child(heading)
	return {"panel": panel, "body": body, "heading": heading}


static func make_badge(text: String, background: Color, foreground: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		clean_style(background, foreground.lightened(0.14), 1, 5, Vector4(8, 4, 8, 4))
	)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", SKETCH_UI.body_font(0.48))
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", foreground)
	badge.add_child(label)
	return badge


static func make_price_sticker(price: int, minimum_size: Vector2 = Vector2(72, 48)) -> PanelContainer:
	var on_sale := price > 5
	var sticker := PanelContainer.new()
	sticker.name = "PriceSticker"
	sticker.set_meta("shows_sale", on_sale)
	sticker.set_meta("price", price)
	sticker.custom_minimum_size = minimum_size
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker.z_index = 20
	sticker.rotation = deg_to_rad(5.0)
	sticker.add_theme_stylebox_override(
		"panel",
		clean_style(
			Color("#F2F018"),
			Color("#D94524") if on_sale else Color("#A18F16"),
			2 if on_sale else 1,
			1,
			Vector4(3, 3, 3, 3)
		)
	)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 0)
	sticker.add_child(copy)

	if on_sale:
		var sale_strip := PanelContainer.new()
		sale_strip.name = "SaleStrip"
		sale_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sale_strip.add_theme_stylebox_override(
			"panel",
			clean_style(Color("#E54824"), Color.TRANSPARENT, 0, 0, Vector4(2, 0, 2, 0))
		)
		copy.add_child(sale_strip)
		var sale := Label.new()
		sale.name = "SaleLabel"
		sale.text = "SALE"
		sale.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sale.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sale.add_theme_font_override("font", SKETCH_UI.body_font(0.72))
		sale.add_theme_font_size_override("font_size", 13)
		sale.add_theme_color_override("font_color", Color("#FFF327"))
		sale_strip.add_child(sale)

	var amount := Label.new()
	amount.name = "PriceAmount"
	amount.text = "$%d" % price
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.size_flags_vertical = Control.SIZE_EXPAND_FILL
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_font_override("font", SKETCH_UI.body_font(0.55))
	amount.add_theme_font_size_override("font_size", 16 if on_sale else 18)
	amount.add_theme_color_override("font_color", Color("#111111"))
	copy.add_child(amount)
	return sticker


static func style_button(button: Button, variant: String = "secondary") -> void:
	button.theme_type_variation = &""
	button.custom_minimum_size.y = 34
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.remove_theme_stylebox_override(style_name)
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_disabled_color",
	]:
		button.remove_theme_color_override(color_name)

	var text_color := button_text_color(variant)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, button_style(variant, state))
	button.add_theme_font_override("font", SKETCH_UI.body_font(0.5))
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override(
		"font_disabled_color",
		text_color if variant == "selected" else Color("#8D847A")
	)


static func button_style(variant: String, state: String) -> StyleBoxFlat:
	var normal_fill := SURFACE
	var hover_fill := TEAL_SOFT
	var pressed_fill := MUSTARD_SOFT
	var disabled_fill := Color("#E9E3D9")
	var border := BORDER_SOFT
	if variant == "primary":
		normal_fill = TEAL
		hover_fill = TEAL.lightened(0.08)
		pressed_fill = TEAL.darkened(0.08)
		border = TEAL.darkened(0.18)
	elif variant == "selected":
		normal_fill = TEAL_SOFT
		hover_fill = TEAL_SOFT
		pressed_fill = TEAL_SOFT
		disabled_fill = TEAL_SOFT
		border = TEAL
	elif variant == "danger" or variant == "icon":
		normal_fill = ORANGE_SOFT
		hover_fill = Color("#F2CABB")
		pressed_fill = Color("#EDB7A4")
		border = ORANGE
	elif variant == "target":
		normal_fill = MUSTARD_SOFT
		hover_fill = Color("#F5D98F")
		pressed_fill = Color("#EDC866")
		border = MUSTARD.darkened(0.22)

	match state:
		"hover":
			return clean_style(hover_fill, border, 1, 6, Vector4(9, 4, 9, 5))
		"pressed":
			return clean_style(pressed_fill, border, 1, 6, Vector4(9, 5, 9, 4))
		"disabled":
			return clean_style(disabled_fill, border if variant == "selected" else Color("#CFC5B7"), 1, 6, Vector4(9, 4, 9, 5))
		"focus":
			return clean_style(Color.TRANSPARENT, TEAL, 2, 6)
		_:
			return clean_style(normal_fill, border, 1, 6, Vector4(9, 4, 9, 5))


static func button_text_color(variant: String) -> Color:
	if variant == "primary":
		return Color.WHITE
	if variant == "selected":
		return TEAL.darkened(0.2)
	return INK
