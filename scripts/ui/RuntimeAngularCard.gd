extends Control
class_name RuntimeAngularCard

signal visual_changed

## A resolution-independent card face built from Godot controls and draw calls.
## The illustration is the only raster layer; the chassis, panels, keylines,
## wedges, typography and stat treatment are all rendered at runtime.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const ART_INK_SHADER := preload("res://assets/shaders/runtime_art_black_ink.gdshader")
const RECIPE_TILES := preload("res://scripts/ui/RecipeRequirementTiles.gd")
const UPGRADED_CARD_FOIL := preload("res://scripts/ui/UpgradedCardFoil.gd")

var card_name := "JALAPEÑO PANTHER"
var card_type := "INGREDIENT"
var source_card_type := "ingredient"
var affinities: Array[String] = ["spicy"]
var recipe_requirements: Array[String] = []
var required_meal_archetype := ""
var rules_text := "Sacrifice this: search your deck\nfor a Spicy card."
var attack := 1
var health := 2
var card_art: Texture2D
var show_stats := true
var footer_text := "RESOLVE EFFECT"
var art_zoom := 1.0
var art_offset := Vector2.ZERO
var compact_visual := false
var show_art := true
var upgraded := false
var accent_color := PALETTE.SIGNAL_RED
var secondary_accent_color := PALETTE.SIGNAL_RED

var _title_label: Label
var _type_label: Label
var _affinity_label: Label
var _header_symbol_primary: Label
var _header_symbol_secondary: Label
var _rail_symbol_primary: Label
var _rail_symbol_secondary: Label
var _recipe_title_label: Label
var _recipe_requirements_label: Label
var _recipe_requirement_tiles: Control
var _rules_label: Label
var _attack_value: Label
var _attack_label: Label
var _health_value: Label
var _health_label: Label
var _footer_label: Label
var _art_clip: Control
var _art: TextureRect
var _foil_overlay: Control
var _deferred_layout_pending := false


func configure(card_data: Dictionary, texture: Texture2D) -> void:
	card_name = String(card_data.get("name", card_name)).to_upper()
	source_card_type = String(card_data.get("card_type", source_card_type)).to_lower()
	card_type = String(card_data.get("display_card_type", card_data.get("card_type", card_type))).to_upper()
	affinities = _read_affinities(card_data)
	recipe_requirements.clear()
	for requirement_value in card_data.get("recipe", []):
		recipe_requirements.append(String(requirement_value))
	required_meal_archetype = String(card_data.get("required_meal_archetype", ""))
	rules_text = String(card_data.get("text", rules_text))
	attack = int(card_data.get("attack", attack))
	health = int(card_data.get("health", health))
	show_stats = bool(card_data.get("show_stats", card_type in ["INGREDIENT", "MEAL"]))
	footer_text = String(card_data.get("footer_text", footer_text)).to_upper()
	art_zoom = maxf(0.5, float(card_data.get("art_zoom", 1.0)))
	art_offset = Vector2(card_data.get("art_offset", Vector2.ZERO))
	compact_visual = bool(card_data.get("compact_visual", false))
	show_art = bool(card_data.get("show_art", true))
	upgraded = bool(card_data.get("upgraded", false))
	accent_color = _card_accent_color(affinities[0])
	secondary_accent_color = _card_accent_color(affinities[1] if affinities.size() > 1 else affinities[0])
	card_art = texture
	if not is_instance_valid(_title_label):
		_create_content()
	_sync_content()
	_layout_content()
	_queue_deferred_layout()
	queue_redraw()


func set_card_art(texture: Texture2D) -> void:
	card_art = texture
	if is_instance_valid(_art):
		_art.texture = texture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	if not is_instance_valid(_title_label):
		_create_content()
	resized.connect(_on_resized)
	_sync_content()
	_layout_content()
	_queue_deferred_layout()
	queue_redraw()


func _on_resized() -> void:
	_layout_content()
	_queue_deferred_layout()
	queue_redraw()


func _queue_deferred_layout() -> void:
	if _deferred_layout_pending or not is_inside_tree():
		return
	_deferred_layout_pending = true
	call_deferred("_apply_deferred_layout")


func _apply_deferred_layout() -> void:
	_deferred_layout_pending = false
	_layout_content()
	queue_redraw()


func _create_content() -> void:
	_art_clip = Control.new()
	_art_clip.name = "ArtClip"
	_art_clip.clip_contents = true
	_art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_clip)

	_art = TextureRect.new()
	_art.name = "CardArtwork"
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink_material := ShaderMaterial.new()
	ink_material.shader = ART_INK_SHADER
	_art.material = ink_material
	_art_clip.add_child(_art)

	_foil_overlay = UPGRADED_CARD_FOIL.new()
	_foil_overlay.name = "UpgradedCardFoil"
	_foil_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foil_overlay.visual_changed.connect(func() -> void: visual_changed.emit())
	add_child(_foil_overlay)
	_foil_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_title_label = _make_label(DISPLAY_FONT, 32, PALETTE.COOL_WHITE, 1.05)
	_title_label.name = "CardTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_title_label)

	_header_symbol_primary = _make_symbol_label("CardAffinityIcon", 34)
	add_child(_header_symbol_primary)
	_header_symbol_secondary = _make_symbol_label("CardAffinityIconSecondary", 24)
	add_child(_header_symbol_secondary)

	_type_label = _make_label(DISPLAY_FONT, 23, PALETTE.COOL_WHITE, 0.85)
	_type_label.name = "CardType"
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_type_label)

	_affinity_label = _make_label(DISPLAY_FONT, 23, PALETTE.COOL_WHITE, 0.85)
	_affinity_label.name = "AffinityLabel"
	_affinity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_affinity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_affinity_label)

	_rail_symbol_primary = _make_symbol_label("RailSymbolPrimary", 23)
	add_child(_rail_symbol_primary)
	_rail_symbol_secondary = _make_symbol_label("RailSymbolSecondary", 18)
	add_child(_rail_symbol_secondary)

	_recipe_title_label = _make_label(DISPLAY_FONT, 13, PALETTE.COOL_WHITE, 0.75)
	_recipe_title_label.name = "RecipeTitleLabel"
	_recipe_title_label.text = "RECIPE"
	_recipe_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recipe_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_recipe_title_label)

	_recipe_requirements_label = _make_label(
		AFFINITY_VISUALS.font_with_symbols(DISPLAY_FONT),
		22,
		PALETTE.COOL_WHITE,
		0.62
	)
	_recipe_requirements_label.name = "CardRequirements"
	_recipe_requirements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recipe_requirements_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_recipe_requirements_label.clip_text = true
	# Retain the plain-text representation for inspection/accessibility and the
	# existing card API. The visible treatment is rendered by affinity tiles.
	_recipe_requirements_label.modulate = Color.TRANSPARENT
	add_child(_recipe_requirements_label)

	_recipe_requirement_tiles = RECIPE_TILES.new()
	_recipe_requirement_tiles.name = "RecipeRequirementTiles"
	add_child(_recipe_requirement_tiles)

	_rules_label = _make_label(BODY_FONT, 24, PALETTE.CARBON, 0.18)
	_rules_label.name = "CardRules"
	_rules_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rules_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_rules_label.add_theme_constant_override("shadow_offset_x", 0)
	_rules_label.add_theme_constant_override("shadow_offset_y", 0)
	_rules_label.add_theme_constant_override("line_spacing", -3)
	# Prevent the raw, not-yet-wrapped sentence from inflating Label's minimum
	# width before the measured fit pass assigns its final line breaks.
	_rules_label.clip_text = true
	# Wrapping is measured and inserted by this card instead of delegated to
	# Label. That keeps the rules panel's minimum size stable while rescaling.
	_rules_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_rules_label)

	# Combat values use the wider hyperlegible face instead of the condensed
	# display font so single digits remain distinct when cards are scaled down.
	_attack_value = _make_label(BODY_FONT, 50, PALETTE.COOL_WHITE, 0.95)
	_attack_value.name = "AttackValue"
	_attack_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_attack_value.clip_text = true
	add_child(_attack_value)

	_attack_label = _make_label(DISPLAY_FONT, 25, PALETTE.COOL_WHITE, 0.9)
	_attack_label.name = "AttackLabel"
	_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_attack_label.clip_text = true
	add_child(_attack_label)

	_health_value = _make_label(BODY_FONT, 50, PALETTE.COOL_WHITE, 0.95)
	_health_value.name = "HealthValue"
	_health_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_value.clip_text = true
	add_child(_health_value)

	_health_label = _make_label(DISPLAY_FONT, 25, PALETTE.COOL_WHITE, 0.9)
	_health_label.name = "HealthLabel"
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_label.clip_text = true
	add_child(_health_label)

	_footer_label = _make_label(DISPLAY_FONT, 24, PALETTE.COOL_WHITE, 0.9)
	_footer_label.name = "FooterLabel"
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_footer_label)


func _sync_content() -> void:
	if not is_instance_valid(_title_label):
		return
	_title_label.text = card_name
	_title_label.add_theme_color_override(
		"font_color",
		PALETTE.STATE_REWARD if upgraded else PALETTE.COOL_WHITE
	)
	_type_label.text = card_type
	_affinity_label.text = _affinity_display_text()
	_sync_classification_symbols()
	var meal := _is_meal()
	var ingredient := _is_ingredient()
	var tool := _is_tool()
	var chef := _is_chef()
	var spice := _is_spice()
	var environment := _is_environment()
	var category_only := ingredient or tool or chef or spice or environment
	_affinity_label.visible = not meal and not category_only
	_rail_symbol_primary.visible = not meal and not category_only and not _rail_symbol_primary.text.is_empty()
	_rail_symbol_secondary.visible = not meal and not category_only and not _rail_symbol_secondary.text.is_empty()
	_recipe_title_label.visible = meal
	_recipe_title_label.visible = meal and not compact_visual
	_recipe_requirements_label.visible = meal and not compact_visual
	_recipe_requirements_label.text = _meal_requirements_text()
	_recipe_requirement_tiles.visible = meal and not compact_visual
	_recipe_requirement_tiles.configure(recipe_requirements, required_meal_archetype)
	_rules_label.text = rules_text
	_attack_value.text = str(attack)
	_attack_label.text = "ATK"
	_health_value.text = str(health)
	_health_label.text = "HP"
	_type_label.visible = not compact_visual
	_affinity_label.visible = _affinity_label.visible and not compact_visual
	_rail_symbol_primary.visible = _rail_symbol_primary.visible and not compact_visual
	_rail_symbol_secondary.visible = _rail_symbol_secondary.visible and not compact_visual
	_rules_label.visible = not compact_visual
	_attack_value.visible = show_stats
	_attack_label.visible = show_stats
	_health_value.visible = show_stats
	_health_label.visible = show_stats
	_footer_label.visible = not show_stats and not compact_visual and not _uses_expanded_rules_panel()
	_footer_label.text = footer_text
	_art.texture = card_art
	_art.visible = show_art
	_foil_overlay.configure(
		upgraded,
		accent_color,
		secondary_accent_color,
		float(abs(card_name.hash()) % 1000) / 1000.0
	)


func _layout_content() -> void:
	if not is_instance_valid(_title_label) or size.x <= 1.0 or size.y <= 1.0:
		return
	var sx := size.x / 420.0
	var sy := size.y / 620.0
	var font_scale := minf(sx, sy)

	_set_rect(_title_label, Vector2(84, 24), Vector2(308, 74), sx, sy)
	if _header_symbol_secondary.visible:
		_set_rect(_header_symbol_primary, Vector2(31, 43), Vector2(29, 50), sx, sy)
		_set_rect(_header_symbol_secondary, Vector2(55, 43), Vector2(29, 50), sx, sy)
	else:
		_set_rect(_header_symbol_primary, Vector2(31, 40), Vector2(49, 56), sx, sy)
		_set_rect(_header_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
	var uses_compact_category_rail := _uses_full_width_category_rail()
	var art_height := 407 if compact_visual else (217 if uses_compact_category_rail else 193)
	_set_rect(_art_clip, Vector2(31, 121), Vector2(358, art_height), sx, sy)
	_art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Keep a restrained bleed beyond the clipped illustration well. The former
	# overscan cropped ears, tails, and tall silhouettes too aggressively.
	var base_art_size := _art_clip.size + Vector2(16.0 * sx, 12.0 * sy)
	_art.size = base_art_size * art_zoom
	_art.position = (_art_clip.size - _art.size) * 0.5 + Vector2(art_offset.x * sx, art_offset.y * sy)
	if compact_visual:
		_set_rect(_type_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_affinity_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_primary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_title_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirements_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirement_tiles, Vector2.ZERO, Vector2.ZERO, sx, sy)
	elif uses_compact_category_rail:
		_set_rect(_type_label, Vector2(31, 351), Vector2(358, 40), sx, sy)
		_set_rect(_affinity_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_primary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_title_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirements_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirement_tiles, Vector2.ZERO, Vector2.ZERO, sx, sy)
	else:
		_set_rect(_type_label, Vector2(31, 337), Vector2(190, 50), sx, sy)
	if _is_meal():
		_set_rect(_affinity_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_primary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_title_label, Vector2(244, 328), Vector2(139, 23), sx, sy)
		_set_rect(_recipe_requirements_label, Vector2(238, 347), Vector2(145, 45), sx, sy)
		_set_rect(_recipe_requirement_tiles, Vector2(246, 350), Vector2(134, 37), sx, sy)
	elif not _is_ingredient():
		if affinities.size() > 1:
			_set_rect(_affinity_label, Vector2(278, 337), Vector2(106, 50), sx, sy)
			_set_rect(_rail_symbol_primary, Vector2(240, 343), Vector2(20, 38), sx, sy)
			_set_rect(_rail_symbol_secondary, Vector2(257, 343), Vector2(20, 38), sx, sy)
		else:
			_set_rect(_affinity_label, Vector2(277, 337), Vector2(107, 50), sx, sy)
			_set_rect(_rail_symbol_primary, Vector2(242, 341), Vector2(29, 42), sx, sy)
			_set_rect(_rail_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_title_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirements_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_requirement_tiles, Vector2.ZERO, Vector2.ZERO, sx, sy)
	var rules_height := 192 if _uses_expanded_rules_panel() else 134
	_set_rect(_rules_label, Vector2(42, 409), Vector2(336, rules_height) if not compact_visual else Vector2.ZERO, sx, sy)
	_set_rect(_attack_value, Vector2(36, 544), Vector2(68, 60), sx, sy)
	_set_rect(_attack_label, Vector2(106, 552), Vector2(85, 51), sx, sy)
	_set_rect(_health_value, Vector2(236, 544), Vector2(68, 60), sx, sy)
	_set_rect(_health_label, Vector2(305, 552), Vector2(77, 51), sx, sy)
	_set_rect(_footer_label, Vector2(51, 552), Vector2(318, 51), sx, sy)

	_fit_title_text(font_scale)
	_header_symbol_primary.add_theme_font_size_override("font_size", roundi((24.0 if _header_symbol_secondary.visible else 34.0) * font_scale))
	_header_symbol_secondary.add_theme_font_size_override("font_size", roundi(24.0 * font_scale))
	_type_label.add_theme_font_size_override("font_size", roundi(23.0 * font_scale))
	_affinity_label.add_theme_font_size_override("font_size", roundi((17.0 if affinities.size() > 1 else 23.0) * font_scale))
	_rail_symbol_primary.add_theme_font_size_override("font_size", roundi((18.0 if _rail_symbol_secondary.visible else 23.0) * font_scale))
	_rail_symbol_secondary.add_theme_font_size_override("font_size", roundi(18.0 * font_scale))
	_recipe_title_label.add_theme_font_size_override("font_size", roundi(15.0 * font_scale))
	_recipe_requirements_label.add_theme_font_size_override("font_size", roundi(_recipe_font_size() * font_scale))
	_fit_rules_text(font_scale)
	_attack_value.add_theme_font_size_override("font_size", roundi(38.0 * font_scale))
	_attack_label.add_theme_font_size_override("font_size", roundi(25.0 * font_scale))
	_health_value.add_theme_font_size_override("font_size", roundi(38.0 * font_scale))
	_health_label.add_theme_font_size_override("font_size", roundi(25.0 * font_scale))
	_footer_label.add_theme_font_size_override("font_size", roundi(24.0 * font_scale))
	# Labels compute their minimum height from the previous font size. Reapply
	# the stat rectangles after scaling typography so small cards do not retain
	# a full-size label box that centers their numbers below the pod.
	_set_rect(_attack_value, Vector2(36, 544), Vector2(68, 60), sx, sy)
	_set_rect(_attack_label, Vector2(106, 552), Vector2(85, 51), sx, sy)
	_set_rect(_health_value, Vector2(236, 544), Vector2(68, 60), sx, sy)
	_set_rect(_health_label, Vector2(305, 552), Vector2(77, 51), sx, sy)
	_apply_chrome_text_styles(font_scale)


func _fit_title_text(font_scale: float) -> void:
	if not is_instance_valid(_title_label):
		return
	var title_font := _title_label.get_theme_font("font")
	var preferred_size := maxi(1, roundi(32.0 * font_scale))
	var minimum_size := maxi(1, roundi(18.0 * font_scale))
	var outline_allowance := float(_scaled_outline(3, font_scale) * 2)
	var available_width := maxf(1.0, _title_label.size.x - outline_allowance - 4.0 * font_scale)
	var fitted_size := minimum_size
	for font_size in range(preferred_size, minimum_size - 1, -1):
		var measured_width := title_font.get_string_size(
			card_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x
		if measured_width <= available_width + 0.5:
			fitted_size = font_size
			break
	_title_label.add_theme_font_size_override("font_size", fitted_size)


func _fit_rules_text(font_scale: float) -> void:
	if not is_instance_valid(_rules_label):
		return
	var rules_font := _rules_label.get_theme_font("font")
	var available_width := maxf(1.0, _rules_label.size.x - 2.0 * font_scale)
	var available_height := maxf(1.0, _rules_label.size.y - 2.0 * font_scale)
	var preferred_size := maxi(1, roundi(24.0 * font_scale))
	var minimum_size := maxi(1, roundi(16.0 * font_scale))
	var line_spacing := roundi(-3.0 * font_scale)
	var fitted_text := rules_text
	var fitted_size := minimum_size

	for font_size in range(preferred_size, minimum_size - 1, -1):
		var wrapped_text := _wrap_rules_to_width(rules_text, rules_font, font_size, available_width)
		var measured_size := rules_font.get_multiline_string_size(
			wrapped_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		)
		var line_count := maxi(1, wrapped_text.count("\n") + 1)
		var measured_height := measured_size.y + float(line_spacing * maxi(0, line_count - 1))
		if measured_size.x <= available_width + 0.5 and measured_height <= available_height + 0.5:
			fitted_text = wrapped_text
			fitted_size = font_size
			break
		fitted_text = wrapped_text

	_rules_label.add_theme_constant_override("line_spacing", line_spacing)
	_rules_label.add_theme_font_size_override("font_size", fitted_size)
	_rules_label.text = fitted_text


func _wrap_rules_to_width(value: String, font: Font, font_size: int, available_width: float) -> String:
	var wrapped_lines: PackedStringArray = []
	for paragraph_value in value.split("\n", true):
		var paragraph := String(paragraph_value).strip_edges()
		if paragraph.is_empty():
			wrapped_lines.append("")
			continue
		var current_line := ""
		for word_value in paragraph.split(" ", false):
			var word := String(word_value)
			var candidate := word if current_line.is_empty() else "%s %s" % [current_line, word]
			var candidate_width := font.get_string_size(
				candidate,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size
			).x
			if candidate_width > available_width and not current_line.is_empty():
				wrapped_lines.append(current_line)
				current_line = word
			else:
				current_line = candidate
		if not current_line.is_empty():
			wrapped_lines.append(current_line)
	return "\n".join(wrapped_lines)


func _draw() -> void:
	if size.x < 80.0 or size.y < 120.0:
		return
	var sx := size.x / 420.0
	var sy := size.y / 620.0
	var stroke := maxf(1.0, minf(sx, sy))

	var outer := _points([
		Vector2(24, 4), Vector2(386, 4), Vector2(416, 34),
		Vector2(416, 586), Vector2(386, 616), Vector2(24, 616),
		Vector2(4, 596), Vector2(4, 24),
	], sx, sy)
	_draw_poly(_offset_points(outer, Vector2(8 * sx, 10 * sy)), Color(PALETTE.CARBON, 0.62))
	_draw_poly(outer, PALETTE.GRAPHITE)
	_draw_closed_line(outer, PALETTE.STEEL.lightened(0.16), 3.0 * stroke)

	var inner := _points([
		Vector2(27, 13), Vector2(381, 13), Vector2(407, 39),
		Vector2(407, 581), Vector2(381, 607), Vector2(27, 607),
		Vector2(13, 593), Vector2(13, 27),
	], sx, sy)
	_draw_closed_line(inner, Color(PALETTE.COOL_WHITE, 0.16), 1.1 * stroke)

	# Header: white affinity tile, carbon name bar, affinity underline and cyan rail.
	var header := _points([
		Vector2(22, 22), Vector2(389, 22), Vector2(400, 33),
		Vector2(400, 101), Vector2(386, 115), Vector2(22, 115),
	], sx, sy)
	_draw_poly(_offset_points(header, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.65))
	_draw_poly(header, PALETTE.CARBON.lightened(0.018))
	_draw_closed_line(header, PALETTE.STEEL.lightened(0.12), 2.0 * stroke)

	var title_wedge := _points([
		Vector2(84, 96), Vector2(319, 96), Vector2(330, 87),
		Vector2(400, 87), Vector2(400, 103), Vector2(386, 115),
		Vector2(98, 115),
	], sx, sy)
	_draw_poly(title_wedge, accent_color)
	if affinities.size() > 1:
		_draw_poly(_points([
			Vector2(246, 96), Vector2(319, 96), Vector2(330, 87),
			Vector2(400, 87), Vector2(400, 103), Vector2(386, 115),
			Vector2(276, 115),
		], sx, sy), secondary_accent_color)

	var icon_tile := _points([
		Vector2(22, 22), Vector2(75, 22), Vector2(87, 34),
		Vector2(87, 103), Vector2(75, 115), Vector2(22, 115),
	], sx, sy)
	_draw_poly(icon_tile, PALETTE.COOL_WHITE)
	_draw_poly(_points([
		Vector2(22, 22), Vector2(31, 22), Vector2(31, 115), Vector2(22, 115),
	], sx, sy), accent_color)
	if affinities.size() > 1:
		_draw_poly(_points([
			Vector2(22, 68), Vector2(31, 68), Vector2(31, 115), Vector2(22, 115),
		], sx, sy), secondary_accent_color)

	_draw_poly(_points([
		Vector2(388, 23), Vector2(397, 32), Vector2(397, 80),
		Vector2(394, 80), Vector2(385, 71), Vector2(385, 30),
	], sx, sy), PALETTE.ELECTRIC_CYAN)

	# Illustration well and its deterministic diagonal field.
	var compact_category_layout := _uses_full_width_category_rail()
	var art_vertical_end := 512.0 if compact_visual else (323.0 if compact_category_layout else 299.0)
	var art_bottom := 532.0 if compact_visual else (343.0 if compact_category_layout else 319.0)
	var art_well := _points([
		Vector2(22, 120), Vector2(398, 120), Vector2(398, art_vertical_end),
		Vector2(378, art_bottom), Vector2(42, art_bottom), Vector2(22, art_vertical_end),
	], sx, sy)
	_draw_poly(_offset_points(art_well, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.64))
	_draw_poly(art_well, PALETTE.COOL_WHITE.darkened(0.018))
	_draw_poly(_points([
		Vector2(24, 122), Vector2(288, 122), Vector2(24, 392 if compact_visual else (276 if compact_category_layout else 260)),
	], sx, sy), accent_color)
	_draw_poly(_points([
		Vector2(24, 122), Vector2(166, 122), Vector2(24, 252 if compact_visual else (202 if compact_category_layout else 190)),
	], sx, sy), secondary_accent_color.darkened(0.10))
	for index in range(3):
		var y := (491.0 if compact_visual else (302.0 if compact_category_layout else 278.0)) + float(index) * 12.0
		draw_line(Vector2(270 * sx, y * sy), Vector2(397 * sx, (y - 63.0) * sy), Color(PALETTE.STEEL, 0.11), 7.0 * stroke, true)
	_draw_closed_line(art_well, PALETTE.STEEL.lightened(0.06), 2.2 * stroke)
	if compact_visual:
		if show_stats:
			_draw_stat_pod(Vector2(22, 548), Vector2(184, 60), false, sx, sy, stroke, accent_color)
			_draw_stat_pod(Vector2(214, 548), Vector2(184, 60), true, sx, sy, stroke, secondary_accent_color)
		else:
			_draw_effect_footer(sx, sy, stroke)
		return

	# Card type/affinity rail.
	var rail_top := 346.0 if compact_category_layout else 326.0
	var type_rail := _points([
		Vector2(22, rail_top), Vector2(398, rail_top), Vector2(398, 390),
		Vector2(388, 400), Vector2(32, 400), Vector2(22, 390),
	], sx, sy)
	_draw_poly(_offset_points(type_rail, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.70))
	_draw_poly(type_rail, PALETTE.CARBON.lightened(0.018))
	if compact_category_layout:
		_draw_poly(type_rail, accent_color)
		if affinities.size() > 1:
			_draw_poly(_points([
				Vector2(210, 346), Vector2(398, 346), Vector2(398, 390),
				Vector2(388, 400), Vector2(210, 400),
			], sx, sy), secondary_accent_color)
	else:
		var type_tab := _points([
			Vector2(22, 326), Vector2(213, 326), Vector2(250, 400),
			Vector2(32, 400), Vector2(22, 390),
		], sx, sy)
		_draw_poly(type_tab, accent_color)
		if affinities.size() > 1:
			_draw_poly(_points([
				Vector2(136, 326), Vector2(213, 326), Vector2(250, 400),
				Vector2(136, 400),
			], sx, sy), secondary_accent_color)
	_draw_closed_line(type_rail, PALETTE.STEEL.lightened(0.10), 2.0 * stroke)

	# Rules panel.
	var rules_bottom := 608.0 if _uses_expanded_rules_panel() else 545.0
	var rules_vertical_end := rules_bottom - 12.0
	var rules := _points([
		Vector2(31, 405), Vector2(389, 405), Vector2(398, 414),
		Vector2(398, rules_vertical_end), Vector2(386, rules_bottom), Vector2(34, rules_bottom),
		Vector2(22, rules_vertical_end), Vector2(22, 421), Vector2(31, 412),
	], sx, sy)
	_draw_poly(_offset_points(rules, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.65))
	_draw_poly(rules, PALETTE.COOL_WHITE)
	_draw_closed_line(rules, PALETTE.STEEL.lightened(0.16), 2.0 * stroke)
	_draw_poly(_points([
		Vector2(31, 405), Vector2(61, 405), Vector2(53, 413),
		Vector2(31, 413), Vector2(31, 429), Vector2(22, 429),
		Vector2(22, 414),
	], sx, sy), accent_color)
	_draw_poly(_points([
		Vector2(370, rules_bottom - 8.0), Vector2(390, rules_bottom - 8.0), Vector2(398, rules_bottom - 16.0),
		Vector2(398, rules_bottom), Vector2(360, rules_bottom),
	], sx, sy), secondary_accent_color)

	if show_stats:
		# Mirrored stat pods anchor combat cards to the bottom edge.
		_draw_stat_pod(Vector2(22, 548), Vector2(184, 60), false, sx, sy, stroke, accent_color)
		_draw_stat_pod(Vector2(214, 548), Vector2(184, 60), true, sx, sy, stroke, secondary_accent_color)
		for index in range(4):
			var x := 182.0 + float(index) * 14.0
			draw_line(Vector2(x * sx, 599 * sy), Vector2((x + 24.0) * sx, 560 * sy), Color(PALETTE.COOL_WHITE, 0.075), 5.0 * stroke, true)
	elif not _uses_expanded_rules_panel():
		_draw_effect_footer(sx, sy, stroke)


func _draw_stat_pod(origin: Vector2, dimensions: Vector2, mirrored: bool, sx: float, sy: float, stroke: float, stat_accent: Color) -> void:
	var x := origin.x
	var y := origin.y
	var w := dimensions.x
	var h := dimensions.y
	var pod_points: Array[Vector2]
	var number_points: Array[Vector2]
	if mirrored:
		pod_points = [
			Vector2(x + 16, y), Vector2(x + w - 10, y), Vector2(x + w, y + 10),
			Vector2(x + w, y + h - 10), Vector2(x + w - 10, y + h),
			Vector2(x + 16, y + h), Vector2(x, y + h - 16), Vector2(x, y + 16),
		]
		number_points = [
			Vector2(x + 16, y + 4), Vector2(x + 75, y + 4), Vector2(x + 102, y + h - 4),
			Vector2(x + 16, y + h - 4), Vector2(x + 4, y + h - 16), Vector2(x + 4, y + 16),
		]
	else:
		pod_points = [
			Vector2(x + 10, y), Vector2(x + w - 16, y), Vector2(x + w, y + 16),
			Vector2(x + w, y + h - 16), Vector2(x + w - 16, y + h),
			Vector2(x + 10, y + h), Vector2(x, y + h - 10), Vector2(x, y + 10),
		]
		number_points = [
			Vector2(x + 4, y + 4), Vector2(x + 75, y + 4), Vector2(x + 100, y + h - 4),
			Vector2(x + 10, y + h - 4), Vector2(x + 4, y + h - 10),
		]
	var pod := _points(pod_points, sx, sy)
	_draw_poly(_offset_points(pod, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.72))
	_draw_poly(pod, PALETTE.CARBON.lightened(0.028))
	_draw_poly(_points(number_points, sx, sy), stat_accent)
	_draw_closed_line(pod, PALETTE.STEEL.lightened(0.18), 2.0 * stroke)


func _draw_effect_footer(sx: float, sy: float, stroke: float) -> void:
	var footer := _points([
		Vector2(32, 548), Vector2(388, 548), Vector2(398, 558),
		Vector2(398, 598), Vector2(388, 608), Vector2(32, 608),
		Vector2(22, 598), Vector2(22, 558),
	], sx, sy)
	_draw_poly(_offset_points(footer, Vector2(3 * sx, 4 * sy)), Color(PALETTE.CARBON, 0.72))
	_draw_poly(footer, PALETTE.CARBON.lightened(0.028))
	_draw_poly(_points([
		Vector2(22, 558), Vector2(32, 548), Vector2(66, 548),
		Vector2(49, 608), Vector2(32, 608), Vector2(22, 598),
	], sx, sy), accent_color)
	_draw_poly(_points([
		Vector2(354, 548), Vector2(388, 548), Vector2(398, 558),
		Vector2(398, 598), Vector2(388, 608), Vector2(371, 608),
	], sx, sy), secondary_accent_color)
	_draw_closed_line(footer, PALETTE.STEEL.lightened(0.18), 2.0 * stroke)


func _sync_classification_symbols() -> void:
	var symbols := _classification_symbols()
	_header_symbol_primary.text = symbols[0] if not symbols.is_empty() else ""
	_header_symbol_secondary.text = symbols[1] if symbols.size() > 1 else ""
	_rail_symbol_primary.text = _header_symbol_primary.text
	_rail_symbol_secondary.text = _header_symbol_secondary.text
	_header_symbol_primary.visible = not _header_symbol_primary.text.is_empty()
	_header_symbol_secondary.visible = not _header_symbol_secondary.text.is_empty()
	_header_symbol_primary.add_theme_color_override("font_color", accent_color)
	_header_symbol_secondary.add_theme_color_override("font_color", secondary_accent_color)
	_rail_symbol_primary.add_theme_color_override("font_color", accent_color)
	_rail_symbol_secondary.add_theme_color_override("font_color", secondary_accent_color)


func _classification_symbols() -> Array[String]:
	var type_symbol := AFFINITY_VISUALS.card_type_symbol(source_card_type)
	if not type_symbol.is_empty():
		return [type_symbol]
	var result: Array[String] = []
	for affinity in affinities:
		var affinity_symbol := AFFINITY_VISUALS.symbol(affinity)
		if not affinity_symbol.is_empty():
			result.append(affinity_symbol)
	return result.slice(0, 2)


func _is_meal() -> bool:
	return source_card_type == "meal" or card_type == "MEAL"


func _is_ingredient() -> bool:
	return source_card_type == "ingredient" or card_type == "INGREDIENT"


func _is_tool() -> bool:
	return source_card_type == "tool" or card_type in ["TOOL", "ITEM"]


func _is_chef() -> bool:
	return source_card_type == "chef" or card_type == "CHEF"


func _is_spice() -> bool:
	return source_card_type == "spice" or card_type == "SPICE"


func _is_environment() -> bool:
	return source_card_type == "environment" or card_type == "ENVIRONMENT"


func _uses_full_width_category_rail() -> bool:
	return _is_ingredient() or _is_tool() or _is_chef() or _is_spice() or _is_environment()


func _uses_expanded_rules_panel() -> bool:
	return _is_tool() or _is_chef() or _is_spice() or _is_environment()


func _meal_requirements_text() -> String:
	if not _is_meal():
		return ""
	var requirement_order: Array[String] = []
	var requirement_counts := {}
	for requirement in recipe_requirements:
		if not requirement_counts.has(requirement):
			requirement_order.append(requirement)
			requirement_counts[requirement] = 0
		requirement_counts[requirement] = int(requirement_counts[requirement]) + 1

	var parts: Array[String] = []
	if not required_meal_archetype.is_empty():
		parts.append("%s MEAL" % AFFINITY_VISUALS.symbol(required_meal_archetype))
	for requirement in requirement_order:
		var display_symbol := "*"
		if requirement != "any":
			var option_symbols: Array[String] = []
			for option in requirement.split("|"):
				option_symbols.append(AFFINITY_VISUALS.symbol(String(option)))
			display_symbol = "/".join(option_symbols)
		var count := int(requirement_counts[requirement])
		parts.append(display_symbol if count == 1 else "%d× %s" % [count, display_symbol])
	return "NONE" if parts.is_empty() else " + ".join(parts)


func _recipe_font_size() -> float:
	var display_text := _meal_requirements_text()
	if display_text.contains(" + ") or display_text.contains(" MEAL"):
		return 22.0
	if display_text.contains("/") or display_text.contains("×"):
		return 25.0
	return 30.0


func _read_affinities(card_data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw_value: Variant = card_data.get("affinities", card_data.get("archetypes", []))
	if raw_value is Array:
		for value in raw_value:
			var normalized := String(value).strip_edges().to_lower()
			if not normalized.is_empty() and normalized not in result:
				result.append(normalized)
	if result.is_empty():
		var fallback := String(card_data.get("affinity", card_data.get("archetype", "neutral"))).strip_edges().to_lower()
		result.append(fallback if not fallback.is_empty() else "neutral")
	return result.slice(0, 2)


func _affinity_display_text() -> String:
	var names: PackedStringArray = []
	for value in affinities:
		names.append(value.to_upper())
	return " + ".join(names)


func _affinity_color(value: String) -> Color:
	match value.to_lower():
		"spicy":
			return PALETTE.AFFINITY_SPICY
		"funky":
			return PALETTE.AFFINITY_FUNKY
		"sweet":
			return PALETTE.AFFINITY_SWEET
		"fresh":
			return PALETTE.AFFINITY_FRESH
		"hearty":
			return PALETTE.AFFINITY_HEARTY
		_:
			return PALETTE.AFFINITY_NEUTRAL


func _card_accent_color(value: String) -> Color:
	if not _is_ingredient():
		return _affinity_color(value)
	match value.to_lower():
		"spicy": return PALETTE.INGREDIENT_SPICY
		"hearty": return PALETTE.INGREDIENT_HEARTY
		"sweet": return PALETTE.INGREDIENT_SWEET
		"fresh": return PALETTE.INGREDIENT_FRESH
		"funky": return PALETTE.INGREDIENT_FUNKY
		_: return PALETTE.INGREDIENT_NEUTRAL


func _apply_chrome_text_styles(scale_factor: float = 1.0) -> void:
	# Colored tabs and numbers share one high-contrast treatment on every card.
	# Dark neutral rails keep solid light text so the outlined style never turns
	# hollow against a carbon background.
	_apply_outlined_light_text(
		_title_label,
		_scaled_outline(3, scale_factor),
		PALETTE.STATE_REWARD if upgraded else PALETTE.COOL_WHITE
	)
	_apply_outlined_dark_text(_type_label, _scaled_outline(4, scale_factor))
	_apply_outlined_light_text(_affinity_label, _scaled_outline(3, scale_factor))
	_apply_outlined_dark_text(_attack_value, _scaled_outline(5, scale_factor))
	_apply_outlined_light_text(_attack_label, _scaled_outline(3, scale_factor))
	_apply_outlined_dark_text(_health_value, _scaled_outline(5, scale_factor))
	_apply_outlined_light_text(_health_label, _scaled_outline(3, scale_factor))
	_apply_outlined_light_text(_footer_label, _scaled_outline(3, scale_factor))
	_apply_outlined_light_text(_recipe_title_label, _scaled_outline(2, scale_factor))
	_recipe_requirements_label.add_theme_color_override("font_color", accent_color)
	_recipe_requirements_label.add_theme_color_override("font_outline_color", PALETTE.TRUE_BLACK)
	_recipe_requirements_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_recipe_requirements_label.add_theme_constant_override("outline_size", _scaled_outline(2, scale_factor))
	_recipe_requirements_label.add_theme_constant_override("shadow_offset_x", 0)
	_recipe_requirements_label.add_theme_constant_override("shadow_offset_y", 0)


func _scaled_outline(base_size: int, scale_factor: float) -> int:
	return maxi(1, roundi(float(base_size) * scale_factor))


func _apply_outlined_dark_text(label: Label, outline_size: int) -> void:
	label.add_theme_color_override("font_color", PALETTE.TRUE_BLACK)
	label.add_theme_color_override("font_outline_color", PALETTE.COOL_WHITE)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


func _apply_outlined_light_text(label: Label, outline_size: int, font_color := PALETTE.COOL_WHITE) -> void:
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", PALETTE.TRUE_BLACK)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


func _make_label(font: Font, font_size: int, color: Color, embolden: float) -> Label:
	var label := Label.new()
	var font_variation := FontVariation.new()
	font_variation.base_font = font
	font_variation.variation_embolden = embolden
	label.add_theme_font_override("font", font_variation)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(PALETTE.CARBON, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_symbol_label(label_name: String, font_size: int) -> Label:
	var label := _make_label(AFFINITY_VISUALS.monochrome_symbol_font(), font_size, PALETTE.COOL_WHITE, 0.0)
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _set_rect(control: Control, position_value: Vector2, size_value: Vector2, sx: float, sy: float) -> void:
	control.size = Vector2(size_value.x * sx, size_value.y * sy)
	control.position = Vector2(position_value.x * sx, position_value.y * sy)


func _points(source: Array[Vector2], sx: float, sy: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in source:
		result.append(Vector2(point.x * sx, point.y * sy))
	return result


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _draw_poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


func _draw_closed_line(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)
