extends RefCounted
class_name CozyCafeThemeAssets

## Runtime bridge for the licensed Cozy Cafe UI Kit v3.0.9 assets imported under
## third_party/cozy_cafe_ui. The source artwork is textless so Godot continues
## to own labels, localization, focus, and accessibility.

const BUTTONS := {
	"primary": {
		"normal": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_primary_medium_default_textless.png"),
		"hover": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_primary_medium_hover_textless.png"),
		"pressed": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_primary_medium_pressed_textless.png"),
		"disabled": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_primary_medium_disabled_textless.png"),
	},
	"secondary": {
		"normal": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_secondary_medium_default_textless.png"),
		"hover": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_secondary_medium_hover_textless.png"),
		"pressed": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_secondary_medium_pressed_textless.png"),
		"disabled": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_secondary_medium_disabled_textless.png"),
	},
	"success": {
		"normal": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_success_medium_default_textless.png"),
		"hover": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_success_medium_hover_textless.png"),
		"pressed": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_success_medium_pressed_textless.png"),
		"disabled": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_success_medium_disabled_textless.png"),
	},
	"danger": {
		"normal": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_danger_medium_default_textless.png"),
		"hover": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_danger_medium_hover_textless.png"),
		"pressed": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_danger_medium_pressed_textless.png"),
		"disabled": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_danger_medium_disabled_textless.png"),
	},
	"dark": {
		"normal": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_dark_medium_default_textless.png"),
		"hover": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_dark_medium_hover_textless.png"),
		"pressed": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_dark_medium_pressed_textless.png"),
		"disabled": preload("res://third_party/cozy_cafe_ui/runtime/buttons/button_dark_medium_disabled_textless.png"),
	},
}

const PANELS := {
	"small": preload("res://third_party/cozy_cafe_ui/runtime/components/panel_small_textless.png"),
	"medium": preload("res://third_party/cozy_cafe_ui/runtime/components/panel_medium_textless.png"),
	"large": preload("res://third_party/cozy_cafe_ui/runtime/components/panel_large_textless.png"),
	"modal": preload("res://third_party/cozy_cafe_ui/runtime/components/modal_panel_textless.png"),
}

const BUTTON_VARIANTS := {
	"primary": "primary",
	"action": "primary",
	"secondary": "secondary",
	"default": "secondary",
	"target": "success",
	"selected": "dark",
	"danger": "danger",
	"icon": "secondary",
}


static func button_style(variant: String, state: String) -> StyleBoxTexture:
	var family: String = BUTTON_VARIANTS.get(variant, "secondary")
	var resolved_state := "hover" if state == "focus" else state
	if not BUTTONS[family].has(resolved_state):
		resolved_state = "normal"
	var style := StyleBoxTexture.new()
	style.texture = BUTTONS[family][resolved_state]
	style.texture_margin_left = 48.0
	style.texture_margin_top = 20.0
	style.texture_margin_right = 48.0
	style.texture_margin_bottom = 20.0
	style.content_margin_left = 17.0
	style.content_margin_top = 7.0 if resolved_state != "pressed" else 9.0
	style.content_margin_right = 17.0
	style.content_margin_bottom = 8.0 if resolved_state != "pressed" else 6.0
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


static func panel_style(size: String = "medium", content := Vector4(24, 22, 24, 24)) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PANELS.get(size, PANELS.medium)
	var patch := 48.0
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	style.content_margin_left = content.x
	style.content_margin_top = content.y
	style.content_margin_right = content.z
	style.content_margin_bottom = content.w
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style
