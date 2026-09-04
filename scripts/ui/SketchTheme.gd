extends RefCounted
class_name SketchTheme

const UI := preload("res://scripts/ui/SketchUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

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

	_register_button(result, "KTSecondaryButton", PALETTE.GHOST, UI.INK, UI.INK)
	_register_button(result, "KTPrimaryButton", PALETTE.TEAL, PALETTE.TEAL_DARK, UI.INK)
	_register_button(result, "KTTargetButton", PALETTE.APRICOT, PALETTE.BRICK_DARK, PALETTE.GHOST)
	_register_button(result, "KTSelectedButton", PALETTE.TEAL_SOFT, PALETTE.TEAL, PALETTE.GHOST)
	_register_button(result, "KTDangerButton", PALETTE.BRICK, PALETTE.BRICK_DARK, PALETTE.GHOST)

	for button_type in ["Button", "OptionButton", "MenuButton"]:
		_apply_button(result, button_type, PALETTE.GHOST, UI.INK, UI.INK)

	result.set_stylebox(
		"panel",
		"PanelContainer",
		UI.texture_style(UI.PANEL_PAPER, Color.WHITE, Vector4(24, 24, 24, 24), Vector4(18, 16, 18, 18))
	)
	result.set_stylebox(
		"panel",
		"TabContainer",
		UI.texture_style(UI.PANEL_PAPER, Color.WHITE, Vector4(24, 24, 24, 24), Vector4(18, 16, 18, 18))
	)
	result.set_stylebox("tab_selected", "TabBar", _flat(PALETTE.APRICOT, UI.INK, 2, 0))
	result.set_stylebox("tab_unselected", "TabBar", _flat(UI.PAPER, UI.INK, 1, 0))
	result.set_stylebox("tab_hovered", "TabBar", _flat(PALETTE.APRICOT_SOFT, UI.INK, 2, 0))
	result.set_color("font_selected_color", "TabBar", UI.INK)
	result.set_color("font_unselected_color", "TabBar", UI.MUTED_INK)
	result.set_color("font_hovered_color", "TabBar", UI.INK)
	result.set_font("font", "TabBar", UI.display_font(0.62))
	result.set_font_size("font_size", "TabBar", 17)

	for input_type in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", input_type, _flat(UI.PAPER, UI.INK, 2, 0, Vector4(12, 8, 12, 8)))
		result.set_stylebox("focus", input_type, _flat(PALETTE.GHOST, UI.TEAL, 3, 0, Vector4(12, 8, 12, 8)))
		result.set_stylebox("read_only", input_type, _flat(PALETTE.GHOST_PRESSED, PALETTE.SLATE, 1, 0, Vector4(12, 8, 12, 8)))
		result.set_color("font_color", input_type, UI.INK)
		result.set_color("font_placeholder_color", input_type, UI.MUTED_INK)
		result.set_color("caret_color", input_type, UI.ORANGE)

	result.set_stylebox(
		"panel",
		"TooltipPanel",
		UI.texture_style(UI.PANEL_PAPER, Color.WHITE, Vector4(24, 24, 24, 24), Vector4(14, 11, 14, 12))
	)
	result.set_color("font_color", "TooltipLabel", UI.INK)
	result.set_font_size("font_size", "TooltipLabel", 14)

	result.set_stylebox("background", "ProgressBar", _flat(PALETTE.GHOST_PRESSED, UI.INK, 1, 0))
	result.set_stylebox("fill", "ProgressBar", _flat(UI.TEAL, UI.INK, 1, 0))
	result.set_color("font_color", "ProgressBar", UI.PAPER)

	result.set_stylebox("scroll", "VScrollBar", _flat(PALETTE.GHOST_PRESSED, Color.TRANSPARENT, 0, 0))
	result.set_stylebox("grabber", "VScrollBar", _flat(UI.TEAL, UI.INK, 1, 0))
	result.set_stylebox("grabber_highlight", "VScrollBar", _flat(UI.MUSTARD, UI.INK, 1, 0))
	result.set_stylebox("grabber_pressed", "VScrollBar", _flat(UI.ORANGE, UI.INK, 1, 0))
	result.set_stylebox("scroll", "HScrollBar", _flat(PALETTE.GHOST_PRESSED, Color.TRANSPARENT, 0, 0))
	result.set_stylebox("grabber", "HScrollBar", _flat(UI.TEAL, UI.INK, 1, 0))
	result.set_stylebox("grabber_highlight", "HScrollBar", _flat(UI.MUSTARD, UI.INK, 1, 0))
	result.set_stylebox("grabber_pressed", "HScrollBar", _flat(UI.ORANGE, UI.INK, 1, 0))

	result.set_color("font_color", "Label", UI.INK)
	result.set_color("font_color", "RichTextLabel", UI.INK)
	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 8)
	return result


static func button_variation(variant: String) -> StringName:
	return StringName(BUTTON_VARIATIONS.get(variant, BUTTON_VARIATIONS.default))


static func _register_button(theme: Theme, type_name: String, fill: Color, border: Color, text: Color) -> void:
	theme.set_type_variation(type_name, "Button")
	_apply_button(theme, type_name, fill, border, text)


static func _apply_button(theme: Theme, type_name: String, fill: Color, border: Color, text: Color) -> void:
	theme.set_stylebox("normal", type_name, _button_style(Color(fill, 0.88), border, false))
	theme.set_stylebox("hover", type_name, _button_style(Color(fill.lightened(0.10), 0.94), PALETTE.SKY, false, true))
	theme.set_stylebox("pressed", type_name, _button_style(Color(fill.darkened(0.08), 0.96), PALETTE.NAVY, true))
	theme.set_stylebox("disabled", type_name, _button_style(Color(PALETTE.DISABLED, 0.58), PALETTE.BORDER_SOFT, false))
	theme.set_stylebox("focus", type_name, _button_style(Color(fill, 0.92), PALETTE.SKY, false, true))
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, text)
	theme.set_color("icon_pressed_color", type_name, text)
	theme.set_color("icon_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_font("font", type_name, UI.display_font(0.68))
	theme.set_font_size("font_size", type_name, 17)
	theme.set_constant("icon_max_width", type_name, 20)
	theme.set_constant("h_separation", type_name, 8)


static func _button_style(fill: Color, border: Color, pressed: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := _flat(fill, border, 2, 12)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 6 if not pressed else 8
	style.content_margin_bottom = 7 if not pressed else 5
	if not pressed:
		style.shadow_color = Color(0.13, 0.09, 0.06, 0.18 if not hovered else 0.26)
		style.shadow_size = 4 if not hovered else 6
		style.shadow_offset = Vector2(0, 2)
	return style


static func _flat(
	background: Color,
	border: Color,
	border_width: int,
	radius: int,
	margins: Vector4 = Vector4.ZERO
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	style.anti_aliasing = true
	return style
