extends RefCounted
class_name WorkspaceTheme

const UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
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

	_register_button(result, "KTSecondaryButton", "secondary")
	_register_button(result, "KTPrimaryButton", "primary")
	_register_button(result, "KTTargetButton", "target")
	_register_button(result, "KTSelectedButton", "selected")
	_register_button(result, "KTDangerButton", "danger")
	for button_type in ["Button", "OptionButton", "MenuButton"]:
		_apply_button(result, button_type, "secondary")

	result.set_stylebox("panel", "PanelContainer", UI.clean_style(UI.SURFACE, UI.BORDER_SOFT, 1, 8, Vector4(12, 10, 12, 10)))
	result.set_stylebox("panel", "TabContainer", UI.clean_style(UI.SURFACE, UI.BORDER_SOFT, 1, 7, Vector4(8, 8, 8, 8)))
	result.set_stylebox("tab_selected", "TabBar", UI.clean_style(UI.TEAL_SOFT, UI.TEAL, 1, 5, Vector4(11, 6, 11, 6)))
	result.set_stylebox("tab_unselected", "TabBar", UI.clean_style(UI.SURFACE_WARM, UI.BORDER_SOFT, 1, 5, Vector4(11, 6, 11, 6)))
	result.set_stylebox("tab_hovered", "TabBar", UI.clean_style(UI.MUSTARD_SOFT, UI.BORDER_SOFT, 1, 5, Vector4(11, 6, 11, 6)))
	result.set_color("font_selected_color", "TabBar", UI.TEAL.darkened(0.2))
	result.set_color("font_unselected_color", "TabBar", UI.MUTED_INK)
	result.set_color("font_hovered_color", "TabBar", UI.INK)

	for input_type in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", input_type, UI.clean_style(UI.SURFACE, UI.BORDER_SOFT, 1, 6, Vector4(10, 7, 10, 7)))
		result.set_stylebox("focus", input_type, UI.clean_style(PALETTE.GHOST, UI.TEAL, 2, 6, Vector4(10, 7, 10, 7)))
		result.set_color("font_color", input_type, UI.INK)
		result.set_color("font_placeholder_color", input_type, UI.MUTED_INK)
		result.set_color("caret_color", input_type, UI.ORANGE)

	result.set_stylebox("panel", "TooltipPanel", UI.clean_style(UI.SURFACE, UI.TEAL, 1, 7, Vector4(10, 8, 10, 8), 0, true))
	result.set_color("font_color", "TooltipLabel", UI.INK)
	result.set_stylebox("background", "ProgressBar", UI.clean_style(PALETTE.GHOST_PRESSED, UI.BORDER_SOFT, 1, 4))
	result.set_stylebox("fill", "ProgressBar", UI.clean_style(UI.TEAL, UI.TEAL, 0, 4))
	result.set_color("font_color", "ProgressBar", PALETTE.GHOST)

	for scroll_type in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", scroll_type, UI.clean_style(PALETTE.GHOST_PRESSED, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber", scroll_type, UI.clean_style(UI.TEAL, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber_highlight", scroll_type, UI.clean_style(UI.MUSTARD, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber_pressed", scroll_type, UI.clean_style(UI.ORANGE, Color.TRANSPARENT, 0, 4))

	result.set_color("font_color", "Label", UI.INK)
	result.set_color("font_color", "RichTextLabel", UI.INK)
	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 8)
	return result


static func button_variation(variant: String) -> StringName:
	return StringName(BUTTON_VARIATIONS.get(variant, BUTTON_VARIATIONS.default))


static func _register_button(theme: Theme, type_name: String, variant: String) -> void:
	theme.set_type_variation(type_name, "Button")
	_apply_button(theme, type_name, variant)


static func _apply_button(theme: Theme, type_name: String, variant: String) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, type_name, UI.button_style(variant, state))
	var text_color := UI.button_text_color(variant)
	theme.set_color("font_color", type_name, text_color)
	theme.set_color("font_hover_color", type_name, text_color)
	theme.set_color("font_pressed_color", type_name, text_color)
	theme.set_color("font_disabled_color", type_name, text_color if variant == "selected" else PALETTE.DISABLED_INK)
	theme.set_color("icon_normal_color", type_name, text_color)
	theme.set_color("icon_hover_color", type_name, text_color)
	theme.set_color("icon_pressed_color", type_name, text_color)
	theme.set_color("icon_disabled_color", type_name, PALETTE.DISABLED_INK)
	theme.set_font("font", type_name, SKETCH_UI.body_font(0.5))
	theme.set_font_size("font_size", type_name, 13)
	theme.set_constant("icon_max_width", type_name, 18)
	theme.set_constant("h_separation", type_name, 7)
