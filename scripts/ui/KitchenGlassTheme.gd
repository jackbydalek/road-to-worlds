extends RefCounted

## Shared Painted Shapes theme. Historical glass helper names remain compatible
## with older callers; ordinary surfaces are matte and lineless.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")

const INK := PALETTE.PEACH_INK
const INK_MUTED := PALETTE.PEACH_INK_SOFT
const PAPER := PALETTE.PEACH_PAPER
const PARCHMENT := PALETTE.PEACH_PAPER_MUTED
const OAK := PALETTE.PEACH_EDGE
const TEAL := PALETTE.PEACH_TEAL
const TEAL_DEEP := PALETTE.PEACH_TEAL
const TEAL_LIGHT := PALETTE.PEACH_TEAL
const ORANGE := PALETTE.LOCALS_PLAYER_SLEEVE
const DANGER := PALETTE.LOCALS_PLAYER_SLEEVE
const DISABLED := PALETTE.PEACH_PAPER_MUTED
const DARK_GLASS := PALETTE.PEACH_INK
const DARK_GLASS_HOVER := PALETTE.PEACH_INK_SOFT

# Original project SVGs, with the same intrinsic sizes as Godot's controls.
# Disabled and RTL states are explicit so those states never revert to stock art.
const SKETCH_ICONS := {
	"check-on": preload("res://assets/ui/sketch_controls/check-on.svg"),
	"check-off": preload("res://assets/ui/sketch_controls/check-off.svg"),
	"check-on-disabled": preload("res://assets/ui/sketch_controls/check-on-disabled.svg"),
	"check-off-disabled": preload("res://assets/ui/sketch_controls/check-off-disabled.svg"),
	"radio-on": preload("res://assets/ui/sketch_controls/radio-on.svg"),
	"radio-off": preload("res://assets/ui/sketch_controls/radio-off.svg"),
	"radio-on-disabled": preload("res://assets/ui/sketch_controls/radio-on-disabled.svg"),
	"radio-off-disabled": preload("res://assets/ui/sketch_controls/radio-off-disabled.svg"),
	"toggle-on": preload("res://assets/ui/sketch_controls/toggle-on.svg"),
	"toggle-off": preload("res://assets/ui/sketch_controls/toggle-off.svg"),
	"toggle-on-disabled": preload("res://assets/ui/sketch_controls/toggle-on-disabled.svg"),
	"toggle-off-disabled": preload("res://assets/ui/sketch_controls/toggle-off-disabled.svg"),
	"toggle-on-mirrored": preload("res://assets/ui/sketch_controls/toggle-on-mirrored.svg"),
	"toggle-off-mirrored": preload("res://assets/ui/sketch_controls/toggle-off-mirrored.svg"),
	"toggle-on-mirrored-disabled": preload("res://assets/ui/sketch_controls/toggle-on-mirrored-disabled.svg"),
	"toggle-off-mirrored-disabled": preload("res://assets/ui/sketch_controls/toggle-off-mirrored-disabled.svg"),
	"dropdown-chevron": preload("res://assets/ui/sketch_controls/dropdown-chevron.svg"),
	"slider-knob": preload("res://assets/ui/sketch_controls/slider-knob.svg"),
	"slider-knob-highlight": preload("res://assets/ui/sketch_controls/slider-knob-highlight.svg"),
	"slider-knob-disabled": preload("res://assets/ui/sketch_controls/slider-knob-disabled.svg"),
}

const BUTTON_VARIATIONS := {
	"default": "KTSecondaryButton",
	"target": "KTTargetButton",
	"selected": "KTSelectedButton",
	"action": "KTPrimaryButton",
	"danger": "KTDangerButton",
}


static func build(_default_font: Font) -> Theme:
	var result := Theme.new()
	result.default_font = UI.BODY_FONT
	result.default_font_size = 16
	result.set_color("font_color", "Label", INK)
	result.set_color("default_color", "RichTextLabel", INK)
	result.set_constant("outline_size", "Label", 0)

	for button_type in ["Button", "OptionButton", "MenuButton", "CheckButton", "CheckBox"]:
		_apply_default_button_theme(result, button_type)
	_apply_sketch_controls(result)
	_register_button_type(result, "KTSecondaryButton", PAPER, PAPER.lightened(0.045), PAPER.darkened(0.10), OAK, INK, INK)
	_register_button_type(result, "KTPrimaryButton", TEAL.darkened(0.10), TEAL.darkened(0.10).lightened(0.045), TEAL.darkened(0.19), TEAL_DEEP, PALETTE.PEACH_PAPER, PALETTE.PEACH_PAPER)
	_register_button_type(result, "KTTargetButton", TEAL.darkened(0.22), TEAL.darkened(0.18), TEAL.darkened(0.30), TEAL_DEEP, PALETTE.PEACH_PAPER, PALETTE.PEACH_PAPER)
	_register_button_type(result, "KTSelectedButton", TEAL.darkened(0.22), TEAL.darkened(0.18), TEAL.darkened(0.30), TEAL_DEEP, PALETTE.PEACH_PAPER, PALETTE.PEACH_PAPER)
	_register_button_type(result, "KTDangerButton", DANGER, DANGER.lightened(0.045), DANGER.darkened(0.10), DANGER.darkened(0.20), PALETTE.PEACH_PAPER, PALETTE.PEACH_PAPER)

	result.set_stylebox("panel", "TabContainer", light_glass_style(OAK))
	result.set_stylebox("tab_selected", "TabBar", _tab_style(TEAL_DEEP, TEAL_DEEP, 1))
	result.set_stylebox("tab_unselected", "TabBar", _tab_style(PARCHMENT, OAK, 1))
	result.set_stylebox("tab_hovered", "TabBar", _tab_style(PAPER, TEAL_DEEP, 1))
	result.set_color("font_selected_color", "TabBar", PALETTE.PEACH_PAPER)
	result.set_color("font_unselected_color", "TabBar", INK_MUTED.darkened(0.10))
	result.set_color("font_hovered_color", "TabBar", INK)
	result.set_color("font_disabled_color", "TabBar", INK_MUTED.darkened(0.10))
	result.set_font_size("font_size", "TabBar", 17)

	for input_type in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", input_type, UI.paper_style(PARCHMENT))
		result.set_stylebox("read_only", input_type, UI.paper_style(PARCHMENT))
		result.set_stylebox("focus", input_type, _focus_style())
		result.set_color("font_color", input_type, INK)
		result.set_color("font_placeholder_color", input_type, INK_MUTED)
		result.set_color("font_uneditable_color", input_type, INK_MUTED.darkened(0.10))
		result.set_color("font_selected_color", input_type, PALETTE.PEACH_PAPER)
		result.set_color("selection_color", input_type, TEAL_DEEP)
		result.set_color("caret_color", input_type, INK)
		result.set_color("clear_button_color", input_type, INK_MUTED)
		result.set_color("clear_button_color_pressed", input_type, INK)

	result.set_stylebox("panel", "PopupMenu", UI.paper_style(PAPER, 8))
	result.set_stylebox("hover", "PopupMenu", _tab_style(TEAL_DEEP, TEAL_DEEP, 1))
	result.set_color("font_color", "PopupMenu", INK)
	result.set_color("font_hover_color", "PopupMenu", PALETTE.PEACH_PAPER)
	result.set_color("font_disabled_color", "PopupMenu", INK_MUTED.darkened(0.10))
	result.set_color("font_separator_color", "PopupMenu", INK_MUTED)
	result.set_color("font_accelerator_color", "PopupMenu", INK_MUTED)
	result.set_constant("v_separation", "PopupMenu", 12)

	result.set_stylebox("panel", "TooltipPanel", UI.paper_style(PAPER, 10))
	result.set_color("font_color", "TooltipLabel", INK)
	result.set_font_size("font_size", "TooltipLabel", 14)
	result.set_stylebox("background", "ProgressBar", _flat_style(PARCHMENT, OAK, 1, 5))
	result.set_stylebox("fill", "ProgressBar", _flat_style(PALETTE.HEALTH_FILL, PALETTE.HEALTH_FILL, 1, 5))
	result.set_color("font_color", "ProgressBar", PALETTE.PEACH_PAPER)
	result.set_color("font_outline_color", "ProgressBar", INK)
	result.set_constant("outline_size", "ProgressBar", 2)

	for scrollbar_type in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", scrollbar_type, _flat_style(PARCHMENT, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber", scrollbar_type, _flat_style(OAK, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber_highlight", scrollbar_type, _flat_style(TEAL, Color.TRANSPARENT, 0, 4))
		result.set_stylebox("grabber_pressed", scrollbar_type, _flat_style(TEAL_DEEP, Color.TRANSPARENT, 0, 4))
	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 8)
	return result


static func _apply_sketch_controls(theme: Theme) -> void:
	for checked in [false, true]:
		var state := "checked" if checked else "unchecked"
		var suffix := "on" if checked else "off"
		for disabled in [false, true]:
			var disabled_theme := "_disabled" if disabled else ""
			var disabled_asset := "-disabled" if disabled else ""
			theme.set_icon(state + disabled_theme, "CheckBox", SKETCH_ICONS["check-" + suffix + disabled_asset])
			theme.set_icon("radio_" + state + disabled_theme, "CheckBox", SKETCH_ICONS["radio-" + suffix + disabled_asset])
			theme.set_icon(state + disabled_theme, "CheckButton", SKETCH_ICONS["toggle-" + suffix + disabled_asset])
			theme.set_icon(state + disabled_theme + "_mirrored", "CheckButton", SKETCH_ICONS["toggle-" + suffix + "-mirrored" + disabled_asset])
		# Popup choices use the same marks as standalone check/radio controls.
		theme.set_icon(state, "PopupMenu", SKETCH_ICONS["check-" + suffix])
		theme.set_icon("radio_" + state, "PopupMenu", SKETCH_ICONS["radio-" + suffix])
	for color_name in ["checkbox_checked_color", "checkbox_unchecked_color"]:
		theme.set_color(color_name, "CheckBox", Color.WHITE)
	for color_name in ["button_checked_color", "button_unchecked_color"]:
		theme.set_color(color_name, "CheckButton", Color.WHITE)
	theme.set_icon("arrow", "OptionButton", SKETCH_ICONS["dropdown-chevron"])
	theme.set_constant("modulate_arrow", "OptionButton", 0)
	for type_name in ["HSlider", "VSlider"]:
		var vertical: bool = type_name == "VSlider"
		theme.set_icon("grabber", type_name, SKETCH_ICONS["slider-knob"])
		theme.set_icon("grabber_highlight", type_name, SKETCH_ICONS["slider-knob-highlight"])
		theme.set_icon("grabber_disabled", type_name, SKETCH_ICONS["slider-knob-disabled"])
		theme.set_stylebox("slider", type_name, _slider_line(PALETTE.PEACH_EDGE, 2, vertical))
		theme.set_stylebox("grabber_area", type_name, _slider_line(TEAL, 2, vertical))
		theme.set_stylebox("grabber_area_highlight", type_name, _slider_line(TEAL, 3, vertical))


static func style_settings_slider(slider: HSlider) -> void:
	# Keep the existing Range behavior, keyboard focus and pointer target. Only
	# its six-pixel stock track and stock thumb are replaced with slim ink marks.
	slider.add_theme_stylebox_override("slider", _slider_line(PALETTE.PEACH_EDGE, 2))
	slider.add_theme_stylebox_override("grabber_area", _slider_line(TEAL, 2))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_line(TEAL, 3))
	slider.add_theme_icon_override("grabber", SKETCH_ICONS["slider-knob"])
	slider.add_theme_icon_override("grabber_highlight", SKETCH_ICONS["slider-knob-highlight"])
	slider.add_theme_icon_override("grabber_disabled", SKETCH_ICONS["slider-knob-disabled"])


static func _slider_line(color: Color, width: int, vertical: bool = false) -> StyleBoxLine:
	var line := StyleBoxLine.new()
	line.color = color
	line.thickness = width
	line.vertical = vertical
	line.grow_begin = 2
	line.grow_end = 2
	return line


static func button_variation(variant: String) -> StringName:
	return StringName(BUTTON_VARIATIONS.get(variant, BUTTON_VARIATIONS.default))


static func light_glass_style(accent: Color = OAK, border_width: int = 1) -> StyleBoxFlat:
	var style := UI.paper_style(PAPER, 16)
	style.border_color = accent
	style.set_border_width_all(border_width if border_width > 1 else 0)
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style


static func tinted_paper_style(accent: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := light_glass_style(OAK, border_width)
	style.bg_color = PAPER.lerp(accent, 0.025)
	return style


static func dark_glass_style(accent: Color = OAK, border_width: int = 1) -> StyleBoxFlat:
	# Deliberately dark consumers keep their light text; this helper no longer
	# introduces purple glass, transparency or a luminous perimeter.
	var style := UI.paper_style(DARK_GLASS, 14)
	style.border_color = OAK.lerp(accent, 0.10)
	style.set_border_width_all(border_width if border_width > 1 else 0)
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style


static func _apply_default_button_theme(theme: Theme, type_name: String) -> void:
	theme.set_stylebox("normal", type_name, _button_style(PAPER, OAK))
	theme.set_stylebox("hover", type_name, _button_style(PAPER.lightened(0.045), INK))
	theme.set_stylebox("pressed", type_name, _button_style(PAPER.darkened(0.10), INK, true))
	theme.set_stylebox("disabled", type_name, _disabled_style())
	theme.set_stylebox("focus", type_name, _focus_style())
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var color := INK_MUTED.darkened(0.10) if state == "disabled" else INK
		theme.set_color("font_color" if state == "normal" else "font_%s_color" % state, type_name, color)
		theme.set_color("icon_%s_color" % state, type_name, color)
	theme.set_font_size("font_size", type_name, 16)
	# Toggle tracks are 32x16; the ordinary button cap would squash them.
	theme.set_constant("icon_max_width", type_name, 32 if type_name == "CheckButton" else 19)
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
	theme.set_stylebox("hover", type_name, _button_style(hover, border))
	theme.set_stylebox("pressed", type_name, _button_style(pressed, border, true))
	theme.set_stylebox("disabled", type_name, _disabled_style())
	theme.set_stylebox("focus", type_name, _focus_style())
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, hover_text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_focus_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, INK_MUTED.darkened(0.10))
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, hover_text)
	theme.set_color("icon_pressed_color", type_name, text)
	theme.set_color("icon_focus_color", type_name, text)
	theme.set_color("icon_disabled_color", type_name, INK_MUTED.darkened(0.10))
	theme.set_font_size("font_size", type_name, 16)
	theme.set_constant("icon_max_width", type_name, 19)
	theme.set_constant("h_separation", type_name, 8)


static func _button_style(background: Color, border: Color, pressed: bool = false) -> StyleBoxFlat:
	var style := _flat_style(background, border, 1, 5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6 if not pressed else 7
	style.content_margin_bottom = 6 if not pressed else 5
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


static func _disabled_style() -> StyleBoxFlat:
	var style := _button_style(DISABLED, OAK)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


static func _focus_style() -> StyleBoxFlat:
	var style := _flat_style(Color.TRANSPARENT, TEAL_DEEP, 2, 5)
	return style


static func _tab_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _flat_style(background, border, border_width, 5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


static func _flat_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := SHAPES.style(background, Vector4.ZERO, 0, float(radius))
	style.border_color = border
	style.set_border_width_all(border_width if border_width > 1 else 0)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
