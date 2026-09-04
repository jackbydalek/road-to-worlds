extends RefCounted
class_name WorkspaceUIComponents

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

const INK := SKETCH_UI.INK
const MUTED_INK := SKETCH_UI.MUTED_INK
const TEAL := SKETCH_UI.TEAL
const ORANGE := SKETCH_UI.ORANGE
const MUSTARD := SKETCH_UI.MUSTARD
const SURFACE := PALETTE.GHOST
const SURFACE_WARM := PALETTE.APRICOT
const BORDER_SOFT := PALETTE.BORDER_SOFT
const TEAL_SOFT := PALETTE.TEAL_SOFT
const ORANGE_SOFT := PALETTE.BRICK_SOFT
const MUSTARD_SOFT := PALETTE.APRICOT_SOFT
const PRICE_STICKER := Color("#D5C16D")
const PRICE_STICKER_BORDER := Color("#756334")
## A single, forgiving silhouette for every player-facing action. Status chips
## deliberately remain smaller and rounder through make_badge().
const BUTTON_RADIUS := 12


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
		style.shadow_color = Color(0.08, 0.05, 0.16, 0.24)
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
			PRICE_STICKER,
			PALETTE.BRICK_DARK if on_sale else PRICE_STICKER_BORDER,
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
			clean_style(PALETTE.BRICK, Color.TRANSPARENT, 0, 0, Vector4(2, 0, 2, 0))
		)
		copy.add_child(sale_strip)
		var sale := Label.new()
		sale.name = "SaleLabel"
		sale.text = "SALE"
		sale.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sale.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sale.add_theme_font_override("font", SKETCH_UI.body_font(0.72))
		sale.add_theme_font_size_override("font_size", 13)
		sale.add_theme_color_override("font_color", PALETTE.GHOST)
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
	amount.add_theme_color_override("font_color", PALETTE.INK)
	copy.add_child(amount)
	return sticker


static func style_button(button: Button, variant: String = "secondary") -> void:
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", false)
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
		text_color if variant == "selected" else Color("#85829A")
	)


static func button_style(variant: String, state: String) -> StyleBoxFlat:
	var fill := Color(PALETTE.LAVENDER_GLASS, 0.86)
	var border := PALETTE.PERIWINKLE
	if variant == "primary":
		fill = Color(PALETTE.CORAL, 0.92)
		border = PALETTE.NAVY
	elif variant == "target":
		fill = Color(PALETTE.PERIWINKLE, 0.90)
		border = PALETTE.NAVY
	elif variant == "selected":
		fill = Color(PALETTE.SKY, 0.88)
		border = PALETTE.NAVY
	elif variant == "danger":
		fill = Color(PALETTE.BRICK, 0.92)
		border = PALETTE.BRICK_DARK

	var pressed := state == "pressed"
	if state == "hover" or state == "focus":
		fill = fill.lerp(PALETTE.BLUSH, 0.34)
		border = PALETTE.SKY
	elif pressed:
		fill = fill.darkened(0.10)
		border = PALETTE.NAVY
	elif state == "disabled":
		fill = Color(PALETTE.LAVENDER_GLASS, 0.62)
		border = PALETTE.PERIWINKLE.lightened(0.16)

	var style := clean_style(fill, border, 2, BUTTON_RADIUS, Vector4(15, 7, 15, 7), 0, not pressed)
	if pressed:
		style.content_margin_top = 8
		style.content_margin_bottom = 6
	return style


static func button_text_color(variant: String) -> Color:
	if variant == "danger":
		return PALETTE.GHOST
	return PALETTE.NAVY
