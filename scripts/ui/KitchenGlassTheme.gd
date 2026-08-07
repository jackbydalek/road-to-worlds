extends RefCounted

## Project-owned adaptation of the Audacious Assets glassmorphism language.
## The source pack is preserved under third_party/audacious_glassmorphism.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

const INK := PALETTE.INK
const INK_MUTED := PALETTE.SLATE
const PAPER := PALETTE.GHOST
const PARCHMENT := PALETTE.APRICOT
const OAK := PALETTE.BORDER_SOFT
const TEAL := PALETTE.TEAL
const TEAL_DEEP := PALETTE.TEAL_DARK
const TEAL_LIGHT := PALETTE.TEAL_HOVER
const ORANGE := PALETTE.BRICK
const DANGER := PALETTE.BRICK
const DISABLED := PALETTE.BORDER_SOFT
const DARK_GLASS := Color("#24213F", 0.94)
const DARK_GLASS_HOVER := Color("#353462", 0.96)

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
		PALETTE.LAVENDER_GLASS,
		PALETTE.BLUSH,
		PALETTE.PERIWINKLE,
		PALETTE.PERIWINKLE,
		PALETTE.NAVY,
		PALETTE.NAVY
	)
	_register_button_type(
		result,
		"KTPrimaryButton",
		PALETTE.CORAL,
		PALETTE.BLUSH,
		PALETTE.CORAL.darkened(0.10),
		PALETTE.NAVY,
		PALETTE.NAVY,
		PALETTE.NAVY
	)
	_register_button_type(
		result,
		"KTTargetButton",
		PALETTE.PERIWINKLE,
		PALETTE.SKY,
		PALETTE.PERIWINKLE.darkened(0.10),
		PALETTE.NAVY,
		PALETTE.NAVY,
		PALETTE.NAVY
	)
	_register_button_type(
		result,
		"KTSelectedButton",
		PALETTE.SKY,
		PALETTE.SKY.lightened(0.08),
		PALETTE.SKY.darkened(0.08),
		PALETTE.NAVY,
		PALETTE.NAVY,
		PALETTE.NAVY
	)
	_register_button_type(
		result,
		"KTDangerButton",
		DANGER,
		PALETTE.BRICK_HOVER,
		PALETTE.BRICK_DARK,
		PALETTE.BRICK_DARK,
		PAPER,
		PAPER
	)

	for button_type in ["Button", "OptionButton", "MenuButton"]:
		_apply_default_button_theme(result, button_type)

	result.set_stylebox("panel", "TabContainer", light_glass_style(TEAL, 1))
	result.set_stylebox("tab_selected", "TabBar", _tab_style(PAPER, TEAL, 2))
	result.set_stylebox("tab_unselected", "TabBar", _tab_style(PALETTE.GHOST_PRESSED, OAK, 1))
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

	result.set_stylebox("background", "ProgressBar", _flat_style(PALETTE.GHOST_PRESSED, PALETTE.BORDER_SOFT, 1, 7))
	result.set_stylebox("fill", "ProgressBar", _flat_style(TEAL, TEAL_DEEP, 1, 7))
	result.set_color("font_color", "ProgressBar", PAPER)

	result.set_stylebox("scroll", "VScrollBar", _flat_style(PALETTE.GHOST_PRESSED, Color.TRANSPARENT, 0, 5))
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
	var style := _flat_style(Color(PAPER.r, PAPER.g, PAPER.b, 0.94), accent, border_width, 14)
	style.shadow_color = Color(0.08, 0.05, 0.16, 0.25)
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
	style.shadow_color = Color(0.04, 0.02, 0.10, 0.38)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style


static func _apply_default_button_theme(theme: Theme, type_name: String) -> void:
	theme.set_stylebox("normal", type_name, _button_style(Color(PALETTE.LAVENDER_GLASS, 0.86), PALETTE.PERIWINKLE))
	theme.set_stylebox("hover", type_name, _button_style(Color(PALETTE.BLUSH, 0.82), PALETTE.SKY))
	theme.set_stylebox("pressed", type_name, _button_style(Color(PALETTE.PERIWINKLE, 0.90), PALETTE.NAVY, true))
	theme.set_stylebox("disabled", type_name, _button_style(Color(PALETTE.DISABLED, 0.58), PALETTE.BORDER_SOFT))
	theme.set_stylebox("focus", type_name, _button_style(Color(PALETTE.LAVENDER_GLASS, 0.90), PALETTE.SKY))
	theme.set_color("font_color", type_name, INK)
	theme.set_color("font_hover_color", type_name, TEAL_DEEP)
	theme.set_color("font_pressed_color", type_name, INK)
	theme.set_color("font_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_color("icon_normal_color", type_name, TEAL_DEEP)
	theme.set_color("icon_hover_color", type_name, TEAL)
	theme.set_color("icon_pressed_color", type_name, INK)
	theme.set_color("icon_disabled_color", type_name, PALETTE.DISABLED_INK)
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
	theme.set_stylebox("normal", type_name, _button_style(Color(normal, 0.88), border))
	theme.set_stylebox("hover", type_name, _button_style(Color(hover, 0.94), PALETTE.SKY))
	theme.set_stylebox("pressed", type_name, _button_style(Color(pressed, 0.96), PALETTE.NAVY, true))
	theme.set_stylebox("disabled", type_name, _button_style(Color(PALETTE.DISABLED, 0.58), PALETTE.BORDER_SOFT))
	theme.set_stylebox("focus", type_name, _button_style(Color(normal, 0.92), PALETTE.SKY))
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, hover_text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, hover_text)
	theme.set_color("icon_pressed_color", type_name, text)
	theme.set_color("icon_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_font_size("font_size", type_name, 16)
	theme.set_constant("icon_max_width", type_name, 19)
	theme.set_constant("h_separation", type_name, 8)


static func _button_style(background: Color, border: Color, pressed: bool = false) -> StyleBoxFlat:
	# Buttons use the same soft-ticket silhouette as the campaign screens. Pills
	# are reserved for compact status information, not actions.
	var style := _flat_style(background, border, 2, 12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6 if not pressed else 7
	style.content_margin_bottom = 6 if not pressed else 5
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
