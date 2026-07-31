extends RefCounted

## Project-owned adaptation of the Audacious Assets glassmorphism language.
## The source pack is preserved under third_party/audacious_glassmorphism.

const INK := Color("#241B17")
const INK_MUTED := Color("#5D5148")
const PAPER := Color("#FFF9ED")
const PARCHMENT := Color("#F7E9C8")
const OAK := Color("#C99B63")
const TEAL := Color("#2D6F6A")
const TEAL_DEEP := Color("#1D4E4B")
const TEAL_LIGHT := Color("#78AAA3")
const ORANGE := Color("#E96A35")
const DANGER := Color("#A94336")
const DISABLED := Color("#C8BDAE")
const DARK_GLASS := Color(0.075, 0.165, 0.16, 0.94)
const DARK_GLASS_HOVER := Color(0.10, 0.23, 0.22, 0.96)

const BUTTON_VARIATIONS := {
	"default": "KTSecondaryButton",
	"target": "KTTargetButton",
	"selected": "KTSelectedButton",
	"action": "KTPrimaryButton",
	"danger": "KTDangerButton",
}


static func build(default_font: Font) -> Theme:
	var result := Theme.new()
	result.default_font = default_font
	result.default_font_size = 16

	_register_button_type(
		result,
		"KTSecondaryButton",
		PAPER,
		PARCHMENT,
		Color("#E7D4AF"),
		TEAL,
		INK,
		TEAL_DEEP
	)
	_register_button_type(
		result,
		"KTPrimaryButton",
		TEAL,
		Color("#377F79"),
		TEAL_DEEP,
		ORANGE,
		PAPER,
		PAPER
	)
	_register_button_type(
		result,
		"KTTargetButton",
		Color("#DDEAD8"),
		Color("#E8F2E3"),
		Color("#CADCC3"),
		Color("#66915B"),
		Color("#24452B"),
		Color("#24452B")
	)
	_register_button_type(
		result,
		"KTSelectedButton",
		Color("#FFF0CE"),
		Color("#FFF6DF"),
		Color("#E9D3A4"),
		ORANGE,
		INK,
		INK
	)
	_register_button_type(
		result,
		"KTDangerButton",
		DANGER,
		Color("#BC5344"),
		Color("#83362E"),
		Color("#E79B85"),
		PAPER,
		PAPER
	)

	for button_type in ["Button", "OptionButton", "MenuButton"]:
		_apply_default_button_theme(result, button_type)

	result.set_stylebox("panel", "TabContainer", light_glass_style(TEAL, 1))
	result.set_stylebox("tab_selected", "TabBar", _tab_style(PAPER, TEAL, 2))
	result.set_stylebox("tab_unselected", "TabBar", _tab_style(Color("#E9DDC7"), OAK, 1))
	result.set_stylebox("tab_hovered", "TabBar", _tab_style(PARCHMENT, ORANGE, 1))
	result.set_color("font_selected_color", "TabBar", TEAL_DEEP)
	result.set_color("font_unselected_color", "TabBar", INK_MUTED)
	result.set_color("font_hovered_color", "TabBar", INK)
	result.set_font_size("font_size", "TabBar", 17)

	for input_type in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", input_type, light_glass_style(OAK, 1))
		result.set_stylebox("focus", input_type, light_glass_style(TEAL, 2))
		result.set_color("font_color", input_type, INK)
		result.set_color("font_placeholder_color", input_type, INK_MUTED)
		result.set_color("caret_color", input_type, ORANGE)

	result.set_stylebox("panel", "TooltipPanel", dark_glass_style(TEAL_LIGHT, 1))
	result.set_color("font_color", "TooltipLabel", PAPER)
	result.set_font_size("font_size", "TooltipLabel", 14)

	result.set_stylebox("background", "ProgressBar", _flat_style(Color("#D8CCB7"), Color("#B7A68B"), 1, 7))
	result.set_stylebox("fill", "ProgressBar", _flat_style(TEAL, TEAL_DEEP, 1, 7))
	result.set_color("font_color", "ProgressBar", PAPER)

	result.set_stylebox("scroll", "VScrollBar", _flat_style(Color("#D7CBB6"), Color.TRANSPARENT, 0, 5))
	result.set_stylebox("grabber", "VScrollBar", _flat_style(TEAL_LIGHT, Color.TRANSPARENT, 0, 5))
	result.set_stylebox("grabber_highlight", "VScrollBar", _flat_style(TEAL, Color.TRANSPARENT, 0, 5))
	result.set_stylebox("grabber_pressed", "VScrollBar", _flat_style(TEAL_DEEP, Color.TRANSPARENT, 0, 5))

	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 8)
	result.set_constant("outline_size", "Label", 0)
	return result


static func button_variation(variant: String) -> StringName:
	return StringName(BUTTON_VARIATIONS.get(variant, BUTTON_VARIATIONS.default))


static func light_glass_style(accent: Color = TEAL, border_width: int = 1) -> StyleBoxFlat:
	var style := _flat_style(Color(1.0, 0.976, 0.91, 0.94), accent, border_width, 14)
	style.shadow_color = Color(0.18, 0.13, 0.08, 0.14)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style


static func tinted_paper_style(accent: Color, border_width: int = 1) -> StyleBoxFlat:
	var surface := PAPER.lerp(accent, 0.08)
	var edge := TEAL if accent.get_luminance() < 0.22 else accent.darkened(0.30)
	var style := light_glass_style(edge, border_width)
	style.bg_color = Color(surface.r, surface.g, surface.b, 0.95)
	return style


static func dark_glass_style(accent: Color = TEAL_LIGHT, border_width: int = 1) -> StyleBoxFlat:
	var style := _flat_style(DARK_GLASS, accent, border_width, 14)
	style.shadow_color = Color(0.04, 0.07, 0.06, 0.30)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style


static func _apply_default_button_theme(theme: Theme, type_name: String) -> void:
	theme.set_stylebox("normal", type_name, _button_style(PAPER, TEAL))
	theme.set_stylebox("hover", type_name, _button_style(PARCHMENT, TEAL_DEEP))
	theme.set_stylebox("pressed", type_name, _button_style(Color("#E7D4AF"), TEAL_DEEP, true))
	theme.set_stylebox("disabled", type_name, _button_style(Color("#DED5C8"), DISABLED))
	theme.set_stylebox("focus", type_name, _button_style(Color.TRANSPARENT, ORANGE))
	theme.set_color("font_color", type_name, INK)
	theme.set_color("font_hover_color", type_name, TEAL_DEEP)
	theme.set_color("font_pressed_color", type_name, INK)
	theme.set_color("font_disabled_color", type_name, Color("#8D8378"))
	theme.set_color("icon_normal_color", type_name, TEAL_DEEP)
	theme.set_color("icon_hover_color", type_name, TEAL)
	theme.set_color("icon_pressed_color", type_name, INK)
	theme.set_color("icon_disabled_color", type_name, Color("#8D8378"))
	theme.set_font_size("font_size", type_name, 16)
	theme.set_constant("icon_max_width", type_name, 19)
	theme.set_constant("h_separation", type_name, 8)


static func _register_button_type(
	theme: Theme,
	type_name: String,
	normal: Color,
	hover: Color,
	pressed: Color,
	border: Color,
	text: Color,
	hover_text: Color
) -> void:
	theme.set_type_variation(type_name, "Button")
	theme.set_stylebox("normal", type_name, _button_style(normal, border))
	theme.set_stylebox("hover", type_name, _button_style(hover, border.lightened(0.08)))
	theme.set_stylebox("pressed", type_name, _button_style(pressed, border.darkened(0.10), true))
	theme.set_stylebox("disabled", type_name, _button_style(Color("#DED5C8"), DISABLED))
	theme.set_stylebox("focus", type_name, _button_style(Color.TRANSPARENT, ORANGE))
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, hover_text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, Color("#8D8378"))
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, hover_text)
	theme.set_color("icon_pressed_color", type_name, text)
	theme.set_color("icon_disabled_color", type_name, Color("#8D8378"))
	theme.set_font_size("font_size", type_name, 16)
	theme.set_constant("icon_max_width", type_name, 19)
	theme.set_constant("h_separation", type_name, 8)


static func _button_style(background: Color, border: Color, pressed: bool = false) -> StyleBoxFlat:
	var style := _flat_style(background, border, 1, 9)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 5 if not pressed else 6
	style.content_margin_bottom = 5 if not pressed else 4
	style.shadow_color = Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.30 if not pressed else 0.10)
	style.shadow_size = 2 if not pressed else 0
	style.shadow_offset = Vector2(0, 3 if not pressed else 1)
	return style


static func _tab_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _flat_style(background, border, border_width, 9)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


static func _flat_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
