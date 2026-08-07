extends Control
class_name CardFace

signal visual_changed

const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const GAME_PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ART_PENDING := preload("res://assets/cards/art_pending.png")
const CARD_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const CARD_TITLE_FONT := preload("res://assets/fonts/ArchivoNarrow-Regular.ttf")

const DEFAULT_SIZE := Vector2(250, 355)
const DEFAULT_FRAME_DURATION := 0.1
const SUPPORTED_ARCHETYPES := ["spicy", "sweet", "hearty", "fresh", "funky"]
const AFFINITY_CARD_TYPES := ["ingredient", "meal"]
const NEUTRAL_CARD_TYPES := ["chef", "tool", "spice", "environment"]
const DUAL_FRAME_KEYS := {
	"funky|spicy": "spicy_funky",
	"fresh|spicy": "spicy_fresh",
	"hearty|sweet": "hearty_sweet",
	"fresh|hearty": "hearty_fresh",
	"funky|sweet": "sweet_funky",
}
const DUAL_FRAME_AFFINITY_ORDER := {
	"spicy_funky": ["spicy", "funky"],
	"spicy_fresh": ["spicy", "fresh"],
	"hearty_sweet": ["hearty", "sweet"],
	"hearty_fresh": ["hearty", "fresh"],
	"sweet_funky": ["sweet", "funky"],
}

var _card: Dictionary = {}
var _animation_frames: Array[Texture2D] = []
var _frame_duration := DEFAULT_FRAME_DURATION
var _frame_elapsed := 0.0
var _frame_index := 0
var _animate_art := true
var _compact_visual := false
var _show_art := true

var _frame_panel: Panel
var _art_backdrop: Panel
var _dual_art_tint: Panel
var _dual_type_tint: Panel
var _art_texture: TextureRect
var _title_label: Label
var _icon_label: Label
var _title_left_ratio := 0.235
var _type_label: Label
var _requirements_label: Label
var _type_ribbon: Panel
var _requirements_divider: Panel
var _rules_backdrop: Panel
var _rules_label: Label
var _stats_badge: Panel
var _stats_label: Label


static func supports_card(card: Dictionary) -> bool:
	var card_type := String(card.get("card_type", ""))
	if card_type in NEUTRAL_CARD_TYPES:
		return true
	return String(card.get("archetype", "")) in SUPPORTED_ARCHETYPES and card_type in AFFINITY_CARD_TYPES


func configure(card: Dictionary, difficulty_id: String = "white", animate_art: bool = true, compact_visual: bool = false, show_art: bool = true) -> void:
	_card = card.duplicate(true)
	_animate_art = animate_art
	_compact_visual = compact_visual
	_show_art = show_art
	custom_minimum_size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_face(difficulty_id)


func _build_face(difficulty_id: String) -> void:
	for child in get_children():
		child.queue_free()
	_dual_art_tint = null
	_dual_type_tint = null

	var accent_colors := _affinity_colors()
	var primary_accent: Color = accent_colors[0]
	var card_type := String(_card.get("card_type", "ingredient"))
	var is_meal := card_type == "meal"
	var uses_neutral_frame := card_type in NEUTRAL_CARD_TYPES
	var art_lighten_amount := 0.38 if is_meal else 0.69
	var symbol_lighten_amount := 0.52 if is_meal else 0.72
	var type_lighten_amount := 0.30 if is_meal else 0.48
	var rules_lighten_amount := 0.74 if is_meal else 0.82
	var selected_border := _difficulty_color(difficulty_id)

	var shadow := _add_panel(
		"CardShadow",
		Color("#29365F2E"),
		Color.TRANSPARENT,
		0,
		20
	)
	_set_relative_rect(shadow, 0.025, 0.025, 0.995, 0.995)

	_frame_panel = _add_panel("CardFrame", GAME_PALETTE.CREAM, selected_border, 5, 20)
	_frame_panel.set_meta("frame_style", "cozy_cafe")
	_frame_panel.set_meta("difficulty_id", difficulty_id)
	_frame_panel.set_meta("difficulty_color", selected_border)
	_set_relative_rect(_frame_panel, 0.01, 0.005, 0.985, 0.98)

	_add_affinity_stripe(accent_colors)
	var outer_border_overlay := _add_panel("OuterBorderOverlay", Color.TRANSPARENT, selected_border, 5, 20)
	_set_relative_rect(outer_border_overlay, 0.01, 0.005, 0.985, 0.98)

	_art_backdrop = _add_panel("CardArtBackdrop", primary_accent.lightened(art_lighten_amount), GAME_PALETTE.NAVY, 2, 14)
	_art_backdrop.set_meta("card_type_color_role", "meal" if is_meal else "ingredient")
	_set_relative_rect(_art_backdrop, 0.045, 0.095, 0.95, 0.505)
	if accent_colors.size() == 2:
		_add_dual_affinity_treatment(accent_colors, art_lighten_amount)

	_art_texture = TextureRect.new()
	_art_texture.name = "CardArtwork"
	_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_relative_rect(_art_texture, 0.065, 0.115, 0.93, 0.49)
	add_child(_art_texture)
	if _show_art:
		_load_art()
	else:
		_art_texture.visible = false
		_art_texture.set_meta("art_pending", false)
		set_process(false)

	var title_capsule := _add_panel("CardTitleCapsule", Color("#FFFDFACC"), GAME_PALETTE.NAVY, 2, 10)
	_set_relative_rect(title_capsule, 0.17, 0.025, 0.96, 0.122)
	var dual_affinity := accent_colors.size() == 2
	# A dual card needs room for two symbols at the same readable scale as a
	# single-affinity card. Give it a deliberately larger, split-color tab
	# instead of squeezing both marks into the usual single-color box.
	var symbol_box_left := 0.045 if dual_affinity else 0.055
	var symbol_box_right := 0.38 if dual_affinity else 0.215
	var symbol_box_bottom := 0.145 if dual_affinity else 0.132
	_title_left_ratio = 0.385 if dual_affinity else 0.215
	var symbol_box := _add_panel("CardSymbolBox", primary_accent.lightened(symbol_lighten_amount), GAME_PALETTE.NAVY, 2, 9)
	_set_relative_rect(symbol_box, symbol_box_left, 0.015, symbol_box_right, symbol_box_bottom)
	if dual_affinity:
		var dual_symbol_tint := _add_right_half_panel(
			"DualAffinitySymbolTint",
			accent_colors[1].lightened(symbol_lighten_amount),
			7
		)
		var symbol_midpoint := (symbol_box_left + symbol_box_right) * 0.5
		_set_relative_rect(dual_symbol_tint, symbol_midpoint, 0.023, symbol_box_right - 0.008, symbol_box_bottom - 0.008)
		var symbol_divider := _add_panel("DualAffinitySymbolDivider", GAME_PALETTE.NAVY, Color.TRANSPARENT, 0, 0)
		_set_relative_rect(symbol_divider, symbol_midpoint - 0.003, 0.026, symbol_midpoint + 0.003, symbol_box_bottom - 0.011)

	_icon_label = _add_label("CardAffinityIcon", _classification_icon_text(), GAME_PALETTE.NAVY)
	_icon_label.add_theme_font_override("font", AFFINITY_VISUALS.monochrome_symbol_font())
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_relative_rect(_icon_label, symbol_box_left + 0.01, 0.02, symbol_box_right - 0.008, symbol_box_bottom - 0.005)

	_title_label = _add_label("CardTitle", String(_card.get("name", "Card")), GAME_PALETTE.NAVY)
	var bold_title_font := FontVariation.new()
	bold_title_font.base_font = CARD_TITLE_FONT
	bold_title_font.variation_embolden = 0.7
	_title_label.add_theme_font_override("font", bold_title_font)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_relative_rect(_title_label, _title_left_ratio, 0.03, 0.95, 0.117)

	_type_ribbon = _add_panel("CardTypeRibbon", primary_accent.lightened(type_lighten_amount), primary_accent.darkened(0.16), 2, 10)
	_set_relative_rect(_type_ribbon, 0.09, 0.46 if is_meal else 0.475, 0.91, 0.60 if is_meal else 0.565)
	if accent_colors.size() == 2:
		_dual_type_tint = _add_right_half_panel("DualTypeTint", accent_colors[1].lightened(type_lighten_amount), 8)
		_set_relative_rect(_dual_type_tint, 0.50, 0.465 if is_meal else 0.48, 0.90, 0.595 if is_meal else 0.56)
	_requirements_divider = _add_panel(
		"CardRequirementsDivider",
		primary_accent.darkened(0.10),
		Color.TRANSPARENT,
		0,
		0
	)
	_requirements_divider.visible = is_meal
	_set_relative_rect(_requirements_divider, 0.11, 0.522, 0.89, 0.527)
	_type_label = _add_label("CardType", _card_type_text(), GAME_PALETTE.NAVY)
	_type_label.add_theme_font_override("font", AFFINITY_VISUALS.font_with_symbols(CARD_FONT))
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.visible = not _compact_visual
	_set_relative_rect(_type_label, 0.11, 0.465 if is_meal else 0.48, 0.89, 0.522 if is_meal else 0.56)

	_requirements_label = _add_label("CardRequirements", _meal_requirements_text(), GAME_PALETTE.NAVY_MUTED)
	_requirements_label.add_theme_font_override("font", AFFINITY_VISUALS.font_with_symbols(CARD_FONT))
	_requirements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_requirements_label.visible = is_meal and not _compact_visual
	_set_relative_rect(_requirements_label, 0.11, 0.528, 0.89, 0.595)

	var rules_text := _rules_text()
	var rules_top := 0.61 if is_meal else 0.575
	var rules_bottom := 0.955 if uses_neutral_frame else 0.88
	_rules_backdrop = _add_panel("CardRulesBackdrop", primary_accent.lightened(rules_lighten_amount), Color("#29365F52"), 1, 11)
	_set_relative_rect(_rules_backdrop, 0.09, rules_top, 0.91, rules_bottom)
	_rules_label = _add_label("CardRules", rules_text, GAME_PALETTE.NAVY)
	_rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Rules text must always be complete. The fitting pass below reduces its
	# size to the available panel height rather than truncating after a fixed
	# number of lines on smaller card previews.
	_rules_label.max_lines_visible = -1
	_rules_label.clip_text = true
	_rules_label.add_theme_constant_override("line_spacing", 2)
	_rules_label.visible = not _compact_visual
	_rules_backdrop.visible = not _compact_visual
	_set_relative_rect(_rules_label, 0.125, rules_top + 0.005, 0.875, rules_bottom - 0.005)

	_stats_badge = _add_panel("CardStatsBadge", primary_accent, GAME_PALETTE.NAVY, 2, 12)
	_stats_badge.visible = not uses_neutral_frame
	_set_relative_rect(_stats_badge, 0.055, 0.885, 0.39, 0.975)
	_stats_label = _add_label("CardStats", "%d / %d" % [int(_card.get("attack", 0)), int(_card.get("health", 0))], GAME_PALETTE.NAVY)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.visible = not uses_neutral_frame
	_set_relative_rect(_stats_label, 0.055, 0.885, 0.39, 0.975)
	_update_typography()


func _rules_text() -> String:
	return String(_card.get("text", "")).strip_edges()


func _difficulty_color(difficulty_id: String) -> Color:
	match difficulty_id:
		"blue":
			return GAME_PALETTE.PERIWINKLE
		"yellow", "gold":
			return GAME_PALETTE.HONEY
		"silver":
			return Color("#B8BBD0")
		_:
			return GAME_PALETTE.NAVY


func _affinity_color(affinity_id: String) -> Color:
	match affinity_id:
		"spicy":
			return Color("#E96F64")
		"hearty":
			return GAME_PALETTE.SAGE
		"sweet":
			return Color("#8299D0")
		"fresh":
			return GAME_PALETTE.FRESH_YELLOW
		"funky":
			return GAME_PALETTE.FUNKY_PLUM
		_:
			return _support_color(String(_card.get("card_type", "")))


func _support_color(card_type: String) -> Color:
	match card_type:
		"chef":
			return GAME_PALETTE.PERIWINKLE
		"spice":
			return GAME_PALETTE.CORAL
		"environment":
			return Color("#4F777C")
		_:
			return GAME_PALETTE.LAVENDER


func _affinity_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for affinity_id in _card_affinity_ids():
		colors.append(_affinity_color(affinity_id))
	if colors.is_empty():
		colors.append(_support_color(String(_card.get("card_type", ""))))
	return colors


func _add_affinity_stripe(colors: Array[Color]) -> void:
	var segment_width := 0.88 / float(colors.size())
	for index in colors.size():
		var segment := _add_panel("AffinityStripe%d" % index, colors[index], Color.TRANSPARENT, 0, 5)
		var left := 0.06 + segment_width * index
		_set_relative_rect(segment, left, 0.025, left + segment_width, 0.057 if colors.size() == 2 else 0.047)


func _add_dual_affinity_treatment(colors: Array[Color], art_lighten_amount: float) -> void:
	_dual_art_tint = _add_panel("DualArtTint", colors[1].lightened(art_lighten_amount), Color.TRANSPARENT, 0, 0)
	_set_relative_rect(_dual_art_tint, 0.50, 0.105, 0.94, 0.495)

	var left_rail := _add_panel("DualAffinityRailLeft", colors[0], Color.TRANSPARENT, 0, 4)
	_set_relative_rect(left_rail, 0.012, 0.13, 0.034, 0.90)
	var right_rail := _add_panel("DualAffinityRailRight", colors[1], Color.TRANSPARENT, 0, 4)
	_set_relative_rect(right_rail, 0.962, 0.13, 0.984, 0.90)

func _classification_icon_text() -> String:
	var card_type := String(_card.get("card_type", ""))
	if card_type in NEUTRAL_CARD_TYPES:
		return AFFINITY_VISUALS.card_type_symbol(card_type)
	return _affinity_icon_text()


func _card_type_text() -> String:
	var card_type := String(_card.get("card_type", "ingredient"))
	if card_type in NEUTRAL_CARD_TYPES:
		return AFFINITY_VISUALS.card_type_label(card_type)
	var affinities := _card_affinity_ids()
	if affinities.size() == 2:
		var symbols: Array[String] = []
		var display_affinities: Array = DUAL_FRAME_AFFINITY_ORDER.get(_dual_frame_key(), affinities)
		for affinity_id in display_affinities:
			symbols.append(AFFINITY_VISUALS.symbol(String(affinity_id)))
		return "%s %s" % [" + ".join(symbols), card_type.capitalize()]
	return card_type.capitalize()


func _card_affinity_ids() -> Array[String]:
	var result: Array[String] = []
	var authored_affinities: Array = _card.get("archetypes", [])
	if authored_affinities.is_empty() and String(_card.get("card_type", "")) == "ingredient":
		authored_affinities = _card.get("ingredient_types", [])
	for affinity_value in authored_affinities:
		var affinity_id := String(affinity_value)
		if affinity_id in SUPPORTED_ARCHETYPES and not result.has(affinity_id):
			result.append(affinity_id)
	if result.is_empty():
		var primary_affinity := String(_card.get("archetype", ""))
		if primary_affinity in SUPPORTED_ARCHETYPES:
			result.append(primary_affinity)
	return result


func _dual_frame_key() -> String:
	var affinities := _card_affinity_ids()
	if affinities.size() != 2:
		return ""
	affinities.sort()
	return String(DUAL_FRAME_KEYS.get("|".join(affinities), ""))


func _affinity_icon_text() -> String:
	var symbols: Array[String] = []
	var display_affinities: Array = DUAL_FRAME_AFFINITY_ORDER.get(_dual_frame_key(), _card_affinity_ids())
	for affinity_id in display_affinities:
		symbols.append(AFFINITY_VISUALS.symbol(String(affinity_id)))
	return "".join(symbols)


func _meal_requirements_text() -> String:
	if String(_card.get("card_type", "")) != "meal":
		return ""
	var requirement_order: Array[String] = []
	var requirement_counts: Dictionary = {}
	for requirement_value in _card.get("recipe", []):
		var requirement := String(requirement_value)
		if not requirement_counts.has(requirement):
			requirement_order.append(requirement)
			requirement_counts[requirement] = 0
		requirement_counts[requirement] = int(requirement_counts[requirement]) + 1

	var parts: Array[String] = []
	var required_meal_archetype := String(_card.get("required_meal_archetype", ""))
	if required_meal_archetype != "":
		parts.append("%s Meal" % AFFINITY_VISUALS.symbol(required_meal_archetype))
	for requirement in requirement_order:
		var display_symbol := "*"
		if requirement != "any":
			var option_symbols: Array[String] = []
			for option in requirement.split("|"):
				option_symbols.append(AFFINITY_VISUALS.symbol(String(option)))
			display_symbol = " or ".join(option_symbols)
		var count := int(requirement_counts[requirement])
		parts.append(display_symbol if count == 1 else "%d× %s" % [count, display_symbol])
	if parts.is_empty():
		return "No Ingredients Required"
	return " + ".join(parts)


func _load_art() -> void:
	_animation_frames.clear()
	_frame_index = 0
	_frame_elapsed = 0.0
	_frame_duration = maxf(0.02, float(_card.get("art_frame_duration", DEFAULT_FRAME_DURATION)))

	for frame_path_value in _card.get("art_frames", []):
		var frame_path := String(frame_path_value)
		if not ResourceLoader.exists(frame_path):
			continue
		var frame_texture := load(frame_path) as Texture2D
		if frame_texture != null:
			_animation_frames.append(frame_texture)

	if not _animation_frames.is_empty():
		_art_texture.texture = _animation_frames[0]
		_art_texture.set_meta("art_pending", false)
		set_process(_animate_art and _animation_frames.size() > 1)
		return

	var static_art_path := String(_card.get("art_path", ""))
	if static_art_path != "" and ResourceLoader.exists(static_art_path):
		_art_texture.texture = load(static_art_path) as Texture2D
		_art_texture.set_meta("art_pending", false)
	else:
		_art_texture.texture = ART_PENDING
		_art_texture.set_meta("art_pending", true)
	set_process(false)


func _process(delta: float) -> void:
	if not _animate_art or _animation_frames.size() < 2 or not is_visible_in_tree():
		return
	_frame_elapsed += delta
	var frame_changed := false
	while _frame_elapsed >= _frame_duration:
		_frame_elapsed -= _frame_duration
		_frame_index = (_frame_index + 1) % _animation_frames.size()
		_art_texture.texture = _animation_frames[_frame_index]
		frame_changed = true
	if frame_changed:
		visual_changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_title_label):
		_update_typography()
		# Container layout updates child rects after the parent's resize
		# notification. Fit once more on the following frame so cards embedded in
		# draft/shop tiles use the final rules-box dimensions.
		call_deferred("_update_typography")
		visual_changed.emit()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_instance_valid(_title_label) and visible:
		# Hover cards are laid out while hidden, then revealed by their shop
		# overlay. Refit after that reveal so their actual panel rect is used.
		call_deferred("_update_typography")


func _update_typography() -> void:
	var display_width := size.x if size.x > 0.0 else custom_minimum_size.x
	var dual_affinity := _card_affinity_ids().size() == 2
	var card_type := String(_card.get("card_type", "ingredient"))
	var uses_neutral_frame := card_type in NEUTRAL_CARD_TYPES
	var simplified_visual := _compact_visual or display_width < 120.0
	_type_ribbon.visible = not simplified_visual
	if is_instance_valid(_dual_type_tint):
		_dual_type_tint.visible = not simplified_visual
	_type_label.visible = not simplified_visual
	_requirements_label.visible = card_type == "meal" and not simplified_visual
	_requirements_divider.visible = card_type == "meal" and not simplified_visual
	_rules_label.visible = not simplified_visual
	_rules_backdrop.visible = not simplified_visual
	_stats_badge.visible = not uses_neutral_frame
	_stats_label.visible = not uses_neutral_frame
	if simplified_visual:
		_set_relative_rect(_art_backdrop, 0.045, 0.095, 0.95, 0.93)
		_set_relative_rect(_art_texture, 0.065, 0.12, 0.93, 0.90)
		if is_instance_valid(_dual_art_tint):
			_set_relative_rect(_dual_art_tint, 0.50, 0.105, 0.94, 0.92)
		_set_relative_rect(_stats_badge, 0.055, 0.85, 0.40, 0.965)
		_set_relative_rect(_stats_label, 0.055, 0.85, 0.40, 0.965)
	else:
		_set_relative_rect(_art_backdrop, 0.045, 0.095, 0.95, 0.505)
		_set_relative_rect(_art_texture, 0.065, 0.115, 0.93, 0.49)
		if is_instance_valid(_dual_art_tint):
			_set_relative_rect(_dual_art_tint, 0.50, 0.105, 0.94, 0.495)
		_set_relative_rect(_stats_badge, 0.055, 0.885, 0.39, 0.975)
		_set_relative_rect(_stats_label, 0.055, 0.885, 0.39, 0.975)
	var preferred_rules_size := 9
	if _compact_visual:
		_icon_label.add_theme_font_size_override("font_size", maxi(9, int(round(display_width / 12.0))))
		_fit_title_text(maxi(8, int(round(display_width / 10.5))))
		_type_label.add_theme_font_size_override("font_size", 8)
		_requirements_label.add_theme_font_size_override("font_size", 8)
		_fit_stats_text(maxi(8, int(round(display_width / 8.0))), true)
		_fit_rules_text(preferred_rules_size)
		return
	if display_width < 160.0:
		_icon_label.add_theme_font_size_override("font_size", maxi(9, int(round(display_width / (13.0 if dual_affinity else 11.5)))))
		_fit_title_text(maxi(9, int(round(display_width / 11.0))))
		_type_label.add_theme_font_size_override("font_size", maxi(7, int(round(display_width / 17.0))))
		_requirements_label.add_theme_font_size_override("font_size", maxi(5, int(round(display_width / 24.0))))
		preferred_rules_size = maxi(10, int(round(display_width / 16.0)))
		_fit_stats_text(maxi(12, int(round(display_width / 9.5))), false)
		_fit_rules_text(preferred_rules_size)
		return
	var title_size := maxi(13, int(round(display_width / 11.0)))
	_icon_label.add_theme_font_size_override("font_size", maxi(14, int(round(display_width / (12.5 if dual_affinity else 11.5)))))
	_fit_title_text(title_size)
	_type_label.add_theme_font_size_override("font_size", maxi(11, int(round(display_width / 17.0))))
	_requirements_label.add_theme_font_size_override("font_size", maxi(9, int(round(display_width / 24.0))))
	preferred_rules_size = maxi(13, int(round(display_width / 16.0)))
	_fit_stats_text(maxi(16, int(round(display_width / 9.5))), false)
	_fit_rules_text(preferred_rules_size)


func _fit_title_text(preferred_font_size: int) -> void:
	if not is_instance_valid(_title_label):
		return
	var display_width := size.x if size.x > 0.0 else custom_minimum_size.x
	var available_width := maxf(1.0, display_width * (0.95 - _title_left_ratio) - 12.0)
	var title_font := _title_label.get_theme_font("font")
	var fitted_size := maxi(7, preferred_font_size)
	if _title_label.text.length() > 11:
		fitted_size = mini(fitted_size, maxi(9, int(round(display_width / 15.5))))
	while fitted_size > 7:
		var measured_width := title_font.get_string_size(
			_title_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fitted_size
		).x
		if measured_width <= available_width:
			break
		fitted_size -= 1
	_title_label.add_theme_font_size_override("font_size", fitted_size)


func _fit_stats_text(preferred_font_size: int, simplified_visual: bool) -> void:
	if not is_instance_valid(_stats_label):
		return
	var display_height := size.y if size.y > 0.0 else custom_minimum_size.y
	var top_ratio := 0.85 if simplified_visual else 0.885
	var bottom_ratio := 0.965 if simplified_visual else 0.975
	var available_height := maxf(1.0, display_height * (bottom_ratio - top_ratio) - 4.0)
	var stats_font := _stats_label.get_theme_font("font")
	var fitted_size := maxi(8, preferred_font_size)
	while fitted_size > 8 and stats_font.get_height(fitted_size) > available_height:
		fitted_size -= 1
	_stats_label.add_theme_font_size_override("font_size", fitted_size)


func _fit_rules_text(preferred_font_size: int) -> void:
	if not is_instance_valid(_rules_label):
		return
	var display_width := size.x if size.x > 0.0 else custom_minimum_size.x
	var display_height := size.y if size.y > 0.0 else custom_minimum_size.y
	var available_width := _rules_label.size.x if _rules_label.size.x > 0.0 else display_width * 0.75
	var card_type := String(_card.get("card_type", "ingredient"))
	var rules_top := 0.61 if card_type == "meal" else 0.575
	var rules_bottom := 0.955 if card_type in NEUTRAL_CARD_TYPES else 0.88
	var available_height := _rules_label.size.y if _rules_label.size.y > 0.0 else display_height * (rules_bottom - rules_top)
	var rules_font := _rules_label.get_theme_font("font")
	# Match Label's smart word-wrap rules exactly; adaptive breaks can measure
	# fewer lines than the label renders and leave the final line clipped.
	var break_flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	var fitted_size := maxi(1, preferred_font_size)
	while fitted_size > 1:
		var measured_size := rules_font.get_multiline_string_size(
			_rules_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			available_width,
			fitted_size,
			-1,
			break_flags
		)
		var font_height := maxf(1.0, rules_font.get_height(fitted_size))
		var line_count := maxi(1, int(ceil(measured_size.y / font_height)))
		var spacing_height := _rules_label.get_theme_constant("line_spacing") * (line_count - 1)
		if measured_size.y + spacing_height <= available_height:
			break
		fitted_size -= 1
	_rules_label.add_theme_font_size_override("font_size", fitted_size)


func _add_panel(node_name: String, fill: Color, border: Color, border_width: int, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel


func _add_right_half_panel(node_name: String, fill: Color, radius: int) -> Panel:
	var panel := _add_panel(node_name, fill, Color.TRANSPARENT, 0, 0)
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	return panel


func _add_label(node_name: String, value: String, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CARD_FONT)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _set_relative_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
