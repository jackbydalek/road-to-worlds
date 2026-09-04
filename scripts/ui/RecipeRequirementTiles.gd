extends Control
class_name RecipeRequirementTiles

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const SYMBOL_FONT := preload("res://assets/fonts/KitchenAffinitySymbols.ttf")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BLACK_SYMBOL_SHADER := preload("res://assets/shaders/ui_symbol_black_mask.gdshader")

var requirements: Array[String] = []
var required_meal_archetype := ""
var _labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_tiles)
	_rebuild()


func configure(values: Array[String], meal_archetype: String = "") -> void:
	requirements = values.duplicate()
	required_meal_archetype = meal_archetype
	if is_inside_tree():
		_rebuild()


func _rebuild() -> void:
	for label in _labels:
		label.queue_free()
	_labels.clear()
	var segments := _segments()
	for segment in segments:
		var label := Label.new()
		var is_operator := String(segment.kind) == "operator"
		label.text = String(segment.text)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", DISPLAY_FONT if is_operator else SYMBOL_FONT)
		label.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.88) if is_operator else PALETTE.TRUE_BLACK)
		label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		label.add_theme_constant_override("outline_size", 0)
		if not is_operator:
			var black_symbol_material := ShaderMaterial.new()
			black_symbol_material.shader = BLACK_SYMBOL_SHADER
			label.material = black_symbol_material
		add_child(label)
		label.set_meta("segment_kind", String(segment.kind))
		_labels.append(label)
	_layout_tiles()
	queue_redraw()


func _layout_tiles() -> void:
	if _labels.is_empty() or size.x <= 0.0:
		return
	var gap := maxf(3.0, size.x * 0.032)
	var operator_count := 0
	for label in _labels:
		operator_count += 1 if String(label.get_meta("segment_kind")) == "operator" else 0
	var tile_count := _labels.size() - operator_count
	var unit_width := (size.x - gap * float(_labels.size() - 1)) / (float(tile_count) + float(operator_count) * 0.46)
	var cursor := 0.0
	for index in _labels.size():
		var label := _labels[index]
		var is_operator := String(label.get_meta("segment_kind")) == "operator"
		var segment_width := unit_width * (0.46 if is_operator else 1.0)
		label.position = Vector2(cursor, 0.0)
		label.size = Vector2(segment_width, size.y)
		label.add_theme_font_size_override("font_size", maxi(7, roundi(minf(size.y * (0.43 if is_operator else 0.7), segment_width * (0.72 if is_operator else 0.62)))))
		cursor += segment_width + gap
	queue_redraw()


func _draw() -> void:
	var segments := _segments()
	if segments.is_empty():
		return
	var gap := maxf(3.0, size.x * 0.032)
	var operator_count := 0
	for segment in segments:
		operator_count += 1 if String(segment.kind) == "operator" else 0
	var tile_count := segments.size() - operator_count
	var unit_width := (size.x - gap * float(segments.size() - 1)) / (float(tile_count) + float(operator_count) * 0.46)
	var cursor := 0.0
	for segment in segments:
		var is_operator := String(segment.kind) == "operator"
		var segment_width := unit_width * (0.46 if is_operator else 1.0)
		if is_operator:
			cursor += segment_width + gap
			continue
		var x := cursor
		draw_rect(Rect2(Vector2(x, 0), Vector2(segment_width, size.y)), _color_for(String(segment.affinity)))
		cursor += segment_width + gap


func _segments() -> Array[Dictionary]:
	var groups: Array[Array] = []
	if not required_meal_archetype.is_empty():
		groups.append([required_meal_archetype])
	for requirement in requirements:
		var options: Array[String] = []
		for option in requirement.split("|"):
			options.append(String(option))
		groups.append(options)
	var result: Array[Dictionary] = []
	for group_index in groups.size():
		if group_index > 0:
			result.append({"kind": "operator", "text": "+", "affinity": ""})
		var group := groups[group_index]
		for option_index in group.size():
			if option_index > 0:
				result.append({"kind": "operator", "text": "OR", "affinity": ""})
			var affinity := String(group[option_index])
			result.append({"kind": "tile", "text": _token_text(affinity), "affinity": affinity})
	return result


func _token_text(token: String) -> String:
	if token == "any":
		return "*"
	var symbols: Array[String] = []
	for option in token.split("|"):
		symbols.append(AFFINITY_VISUALS.symbol(String(option)))
	return "/".join(symbols)


func _primary_color(token: String) -> Color:
	return _color_for(String(token.split("|")[0]))


func _color_for(value: String) -> Color:
	match value.to_lower():
		"spicy": return PALETTE.AFFINITY_SPICY
		"hearty": return PALETTE.AFFINITY_HEARTY
		"sweet": return PALETTE.AFFINITY_SWEET
		"fresh": return PALETTE.AFFINITY_FRESH
		"funky": return PALETTE.AFFINITY_FUNKY
		_: return PALETTE.AFFINITY_NEUTRAL
