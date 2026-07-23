extends Control
class_name CardFace

signal visual_changed

const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const ART_PENDING := preload("res://assets/cards/art_pending.png")

const DEFAULT_SIZE := Vector2(250, 355)
const DEFAULT_FRAME_DURATION := 0.1
const SUPPORTED_ARCHETYPES := ["spicy", "sweet", "hearty", "fresh", "funky"]
const AFFINITY_CARD_TYPES := ["ingredient", "meal"]
const NEUTRAL_CARD_TYPES := ["chef", "tool"]

var _card: Dictionary = {}
var _animation_frames: Array[Texture2D] = []
var _frame_duration := DEFAULT_FRAME_DURATION
var _frame_elapsed := 0.0
var _frame_index := 0
var _animate_art := true
var _compact_visual := false
var _show_art := true

var _frame_texture: TextureRect
var _art_texture: TextureRect
var _title_label: Label
var _icon_label: Label
var _type_label: Label
var _requirements_label: Label
var _rules_label: Label
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

	_frame_texture = TextureRect.new()
	_frame_texture.name = "CardFrame"
	_frame_texture.texture = load(_frame_path(difficulty_id)) as Texture2D
	_frame_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_frame_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_relative_rect(_frame_texture, 0.0, 0.0, 1.0, 1.0)
	add_child(_frame_texture)

	_art_texture = TextureRect.new()
	_art_texture.name = "CardArtwork"
	_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_relative_rect(_art_texture, 0.055, 0.145, 0.945, 0.585)
	add_child(_art_texture)
	if _show_art:
		_load_art()
	else:
		_art_texture.visible = false
		_art_texture.set_meta("art_pending", false)
		set_process(false)

	var card_type := String(_card.get("card_type", "ingredient"))
	var uses_neutral_frame := card_type in NEUTRAL_CARD_TYPES
	var archetype_id := String(_card.get("archetype", "spicy"))
	_icon_label = _add_label("CardAffinityIcon", AFFINITY_VISUALS.symbol(archetype_id), Color("#111111"))
	_icon_label.add_theme_font_override("font", AFFINITY_VISUALS.monochrome_symbol_font())
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.visible = not uses_neutral_frame
	_set_relative_rect(_icon_label, 0.055, 0.03, 0.22, 0.145)

	_title_label = _add_label("CardTitle", String(_card.get("name", "Card")), Color.WHITE)
	var bold_title_font := FontVariation.new()
	bold_title_font.base_font = ThemeDB.fallback_font
	bold_title_font.variation_embolden = 0.7
	_title_label.add_theme_font_override("font", bold_title_font)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_relative_rect(_title_label, 0.09 if uses_neutral_frame else 0.225, 0.035, 0.92, 0.135)

	var is_meal := card_type == "meal"
	_type_label = _add_label("CardType", card_type.capitalize(), Color("#111111"))
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.visible = not _compact_visual and not uses_neutral_frame
	_set_relative_rect(_type_label, 0.09, 0.585, 0.92, 0.645 if is_meal else 0.66)

	_requirements_label = _add_label("CardRequirements", _meal_requirements_text(), Color("#111111"))
	_requirements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_requirements_label.visible = is_meal and not _compact_visual
	_set_relative_rect(_requirements_label, 0.09, 0.635, 0.92, 0.705)

	var rules_text := String(_card.get("text", "")).strip_edges()
	if rules_text == "":
		rules_text = "No printed ability."
	_rules_label = _add_label("CardRules", rules_text, Color("#111111"))
	_rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules_label.visible = not _compact_visual
	_set_relative_rect(_rules_label, 0.105, 0.60 if uses_neutral_frame else (0.72 if is_meal else 0.68), 0.90, 0.94 if uses_neutral_frame else 0.91)

	_stats_label = _add_label("CardStats", "%d / %d" % [int(_card.get("attack", 0)), int(_card.get("health", 0))], Color("#111111"))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.visible = not uses_neutral_frame
	_set_relative_rect(_stats_label, 0.065, 0.89, 0.33, 0.98)

	_update_typography()


func _frame_path(difficulty_id: String) -> String:
	var card_type := String(_card.get("card_type", "ingredient"))
	if card_type in NEUTRAL_CARD_TYPES:
		return "res://assets/cards/frames/%s/black.png" % card_type
	var border_color := difficulty_id if difficulty_id in ["black", "blue", "yellow", "silver", "gold"] else "black"
	var archetype_id := String(_card.get("archetype", "spicy"))
	return "res://assets/cards/frames/%s_%s/%s.png" % [archetype_id, card_type, border_color]


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
		parts.append("%s Meal" % required_meal_archetype.capitalize())
	for requirement in requirement_order:
		var display_name := "Any" if requirement == "any" else requirement.capitalize()
		var count := int(requirement_counts[requirement])
		parts.append("%s Ingredient%s" % [display_name if count == 1 else "%d× %s" % [count, display_name], "" if count == 1 else "s"])
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
		visual_changed.emit()


func _update_typography() -> void:
	var display_width := size.x if size.x > 0.0 else custom_minimum_size.x
	if _compact_visual:
		_icon_label.add_theme_font_size_override("font_size", maxi(12, int(round(display_width / 5.0))))
		_title_label.add_theme_font_size_override("font_size", maxi(8, int(round(display_width / 9.0))))
		_type_label.add_theme_font_size_override("font_size", 8)
		_requirements_label.add_theme_font_size_override("font_size", 8)
		_rules_label.add_theme_font_size_override("font_size", 8)
		_stats_label.add_theme_font_size_override("font_size", maxi(8, int(round(display_width / 8.0))))
		return
	if display_width < 160.0:
		_icon_label.add_theme_font_size_override("font_size", maxi(11, int(round(display_width / 8.5))))
		_title_label.add_theme_font_size_override("font_size", maxi(9, int(round(display_width / 11.0))))
		_type_label.add_theme_font_size_override("font_size", maxi(7, int(round(display_width / 17.0))))
		_requirements_label.add_theme_font_size_override("font_size", maxi(5, int(round(display_width / 24.0))))
		_rules_label.add_theme_font_size_override("font_size", maxi(6, int(round(display_width / 19.0))))
		_stats_label.add_theme_font_size_override("font_size", maxi(10, int(round(display_width / 11.0))))
		return
	var title_size := maxi(13, int(round(display_width / 11.0)))
	_icon_label.add_theme_font_size_override("font_size", maxi(16, int(round(display_width / 8.5))))
	_title_label.add_theme_font_size_override("font_size", title_size)
	_type_label.add_theme_font_size_override("font_size", maxi(11, int(round(display_width / 17.0))))
	_requirements_label.add_theme_font_size_override("font_size", maxi(9, int(round(display_width / 24.0))))
	_rules_label.add_theme_font_size_override("font_size", maxi(10, int(round(display_width / 19.0))))
	_stats_label.add_theme_font_size_override("font_size", maxi(14, int(round(display_width / 11.0))))


func _add_label(node_name: String, value: String, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
