extends Control
class_name RuntimeAngularCard

signal visual_changed

## A resolution-independent card face built from Godot controls and draw calls.
## The illustration is the only raster layer. Paper frames, affinity medallions,
## folded ribbons and readable stat tabs are drawn live.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const DISPLAY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const ART_INK_SHADER := preload("res://assets/shaders/runtime_art_black_ink.gdshader")
const RECIPE_TILES := preload("res://scripts/ui/RecipeRequirementTiles.gd")
const UPGRADED_CARD_FOIL := preload("res://scripts/ui/UpgradedCardFoil.gd")
const CARD_RIBBON := preload("res://scripts/ui/CardRibbon.gd")
const CARD_MEDALLION := preload("res://scripts/ui/CardMedallion.gd")
const PEACH_FRAME_BORDER_WIDTH := 10

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
## Shared presentation default, independent of the card's rules and identity.
## An explicit false retains the former renderer for comparison tools.
var peach_soda_frame := true
var card_border_color := PALETTE.CARD_BORDER_BLACK
var accent_color := PALETTE.SIGNAL_RED
var secondary_accent_color := PALETTE.SIGNAL_RED
var sleeve_color := PALETTE.SIGNAL_RED
var secondary_sleeve_color := PALETTE.SIGNAL_RED

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
var _art_ink_material: ShaderMaterial
var _foil_overlay: Control
var _ribbon: Control
var _medallion: Control
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
	peach_soda_frame = bool(card_data.get("peach_soda_frame", true))
	card_border_color = PALETTE.card_border_color(String(card_data.get("card_border_id", "white")))
	accent_color = _card_accent_color(affinities[0])
	secondary_accent_color = _card_accent_color(affinities[1] if affinities.size() > 1 else affinities[0])
	sleeve_color = _affinity_color(affinities[0]).lerp(PALETTE.LOCALS_INK, 0.16)
	secondary_sleeve_color = _affinity_color(affinities[1] if affinities.size() > 1 else affinities[0]).lerp(PALETTE.LOCALS_INK, 0.16)
	if affinities[0] == "neutral":
		sleeve_color = PALETTE.LOCALS_PAPER_MUTED.lerp(PALETTE.LOCALS_INK, 0.44)
		secondary_sleeve_color = sleeve_color
	if card_data.get("sleeve_color") is Color:
		sleeve_color = card_data.sleeve_color
		secondary_sleeve_color = sleeve_color
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
	_art_ink_material = ShaderMaterial.new()
	_art_ink_material.shader = ART_INK_SHADER
	_art.material = _art_ink_material
	_art_clip.add_child(_art)

	_ribbon = CARD_RIBBON.new()
	_ribbon.name = "CardTypeRibbon"
	_ribbon.draw_copy = false
	add_child(_ribbon)
	_medallion = CARD_MEDALLION.new()
	_medallion.name = "CardAffinityMedallion"
	add_child(_medallion)

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
	_rules_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
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
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if peach_soda_frame else HORIZONTAL_ALIGNMENT_CENTER
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
	_attack_label.text = "/" if compact_visual else "ATK"
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
	_health_label.visible = show_stats and not compact_visual
	_footer_label.visible = not show_stats and not compact_visual and not _uses_expanded_rules_panel()
	_footer_label.text = footer_text
	_art.texture = card_art
	_art.visible = show_art
	# The ribbon frame displays the authored source texture without tint or ink
	# remapping; changing frame mode must not change the card illustration.
	_art.material = null if peach_soda_frame else _art_ink_material
	_ribbon.visible = peach_soda_frame
	_medallion.visible = peach_soda_frame
	_ribbon.configure(
		_pastel_ribbon_color(accent_color),
		_pastel_ribbon_color(secondary_accent_color) if affinities.size() > 1 else Color.TRANSPARENT,
		"" if compact_visual else card_type,
		_meal_requirements_text() if not compact_visual else ""
	)
	# Keep the original identity colors on the seal rim and its existing glyphs.
	_medallion.configure(accent_color, secondary_accent_color if affinities.size() > 1 else Color.TRANSPARENT, "", DISPLAY_FONT)
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

	_set_rect(_title_label, Vector2(88, 25), Vector2(300, 62), sx, sy)
	if peach_soda_frame:
		_set_rect(_title_label, Vector2(104, 25), Vector2(284, 62), sx, sy)
	_set_rect(_medallion, Vector2(13, 16), Vector2(82, 82), sx, sy)
	if compact_visual:
		# A taller plaque accommodates camera-facing combat values projected
		# over the table, as well as ordinary compact CardFace labels.
		_set_rect(_ribbon, Vector2(8, 436), Vector2(404, 176), sx, sy)
	elif _is_meal():
		_set_rect(_ribbon, Vector2(8, 314), Vector2(404, 106), sx, sy)
	else:
		_set_rect(_ribbon, Vector2(8, 342), Vector2(404, 70), sx, sy)
	if _header_symbol_secondary.visible:
		_set_rect(_header_symbol_primary, Vector2(29, 33), Vector2(27, 54), sx, sy)
		_set_rect(_header_symbol_secondary, Vector2(55, 33), Vector2(27, 54), sx, sy)
	else:
		_set_rect(_header_symbol_primary, Vector2(30, 33), Vector2(50, 56), sx, sy)
		_set_rect(_header_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
	var uses_compact_category_rail := _uses_full_width_category_rail()
	var art_height := (326 if peach_soda_frame else 354) if compact_visual else (226 if uses_compact_category_rail else 202)
	_set_rect(_art_clip, Vector2(33, 111), Vector2(354, art_height), sx, sy)
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
		_set_rect(_type_label, Vector2(31, 326), Vector2(358, 36), sx, sy)
	if _is_meal():
		_set_rect(_affinity_label, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_primary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_rail_symbol_secondary, Vector2.ZERO, Vector2.ZERO, sx, sy)
		_set_rect(_recipe_title_label, Vector2(35, 366), Vector2(83, 28), sx, sy)
		_set_rect(_recipe_requirements_label, Vector2(134, 366), Vector2(244, 30), sx, sy)
		var recipe_tile_width := 244.0
		if peach_soda_frame:
			# A short recipe uses small printed tokens rather than stretching one
			# affinity into a second full-width bar. Every AND/OR token remains live.
			var token_count := 0 if required_meal_archetype.is_empty() else 1
			for requirement in recipe_requirements:
				token_count += requirement.split("|").size()
			recipe_tile_width = clampf(float(token_count * 50 - 20), 30.0, 244.0)
		_set_rect(_recipe_requirement_tiles, Vector2(134, 366), Vector2(recipe_tile_width, 30), sx, sy)
		if peach_soda_frame:
			# Center the complete label + AND/OR expression inside the ribbon's
			# plaque. The folded ends are decorative space, never recipe space.
			var recipe_left := (420.0 - recipe_tile_width - 83.0) * 0.5
			_set_rect(_recipe_title_label, Vector2(recipe_left, 365), Vector2(75, 28), sx, sy)
			_set_rect(_recipe_requirement_tiles, Vector2(recipe_left + 83, 365), Vector2(recipe_tile_width, 28), sx, sy)
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
	var rules_height := 176 if _uses_expanded_rules_panel() else 118
	_set_rect(_rules_label, Vector2(42, 419), Vector2(336, rules_height) if not compact_visual else Vector2.ZERO, sx, sy)
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
	if compact_visual:
		# The field card reads like the reference: a generous art well and one
		# cream number strip, with full rules preserved for normal inspection.
		_set_rect(_attack_value, Vector2(76, 498), Vector2(106, 88), sx, sy)
		_set_rect(_attack_label, Vector2(184, 498), Vector2(52, 88), sx, sy)
		_set_rect(_health_value, Vector2(238, 498), Vector2(106, 88), sx, sy)
		_attack_value.add_theme_font_size_override("font_size", maxi(1, roundi(44 * font_scale)))
		_attack_label.add_theme_font_size_override("font_size", maxi(1, roundi(38 * font_scale)))
		_health_value.add_theme_font_size_override("font_size", maxi(1, roundi(44 * font_scale)))
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
	if size.x < 12.0 or size.y < 18.0:
		return
	var sx := size.x / 420.0
	var sy := size.y / 620.0
	var stroke := maxf(0.65, minf(sx, sy))
	if peach_soda_frame:
		_draw_peach_soda_frame(sx, sy, stroke)
		return
	var ink := PALETTE.LOCALS_INK

	# The supplied locals reference uses visible colored sleeves around the
	# entire face. One black contact edge grounds that color on the table.
	_draw_printed_panel(Rect2(4, 4, 412, 612), ink, ink, 13, sx, sy, 1, true)
	_draw_printed_panel(Rect2(14, 14, 392, 592), sleeve_color, ink, 8, sx, sy, 2)
	if not sleeve_color.is_equal_approx(secondary_sleeve_color):
		_draw_printed_panel(Rect2(210, 16, 194, 588), secondary_sleeve_color, Color.TRANSPARENT, 7, sx, sy)
	_draw_printed_panel(Rect2(80, 24, 314, 65), ink, Color.TRANSPARENT, 3, sx, sy)
	_draw_printed_panel(Rect2(26, 24, 58, 71), PALETTE.LOCALS_PAPER, ink, 4, sx, sy, 1)

	var full_category := _uses_full_width_category_rail()
	var art_height := 365.0 if compact_visual else (237.0 if full_category else 213.0)
	_draw_art_well(Rect2(28, 106, 364, art_height), sx, sy)
	if compact_visual:
		# Field renderers may place live combat values over this bottom 20%.
		# Keep the strip even when the card's own base stats are suppressed.
		_draw_printed_panel(Rect2(28, 480, 364, 123), PALETTE.LOCALS_PAPER, ink, 3, sx, sy, 1)
		return

	var rail_top := 347.0 if full_category else 326.0
	var rail_height := 53.0 if full_category else 35.0
	_draw_printed_panel(Rect2(28, rail_top, 364, rail_height), _ribbon_color(sleeve_color), ink, 3, sx, sy, 1)
	if not sleeve_color.is_equal_approx(secondary_sleeve_color):
		_draw_printed_panel(Rect2(210, rail_top + 1, 181, rail_height - 2), _ribbon_color(secondary_sleeve_color), Color.TRANSPARENT, 2, sx, sy)
	if _is_meal():
		_draw_printed_panel(Rect2(28, 364, 364, 36), PALETTE.LOCALS_PAPER, ink, 2, sx, sy, 1)
	var rules_bottom := 603.0 if _uses_expanded_rules_panel() else 541.0
	_draw_printed_panel(Rect2(28, 405, 364, rules_bottom - 405), PALETTE.LOCALS_PAPER, ink, 4, sx, sy, 1)
	if show_stats:
		_draw_printed_panel(Rect2(28, 548, 364, 55), PALETTE.LOCALS_PAPER, ink, 3, sx, sy, 1)
		draw_line(Vector2(210 * sx, 555 * sy), Vector2(210 * sx, 596 * sy), Color(ink, 0.36), stroke, true)
	elif not _uses_expanded_rules_panel():
		_draw_effect_footer(sx, sy, stroke)


func _draw_peach_soda_frame(sx: float, sy: float, _stroke: float) -> void:
	# Restore the cozy ribbon silhouette using native, editable shapes. Keep a
	# midtone art well so floating illustrations retain their white cutout edge.
	var ink := PALETTE.PEACH_INK
	# The chosen border owns the silhouette. A second dark contour or offset
	# paper shadow would read as an unwanted black sleeve around colored rims.
	# Give the identity rim a substantial trading-card frame presence while
	# keeping the printed face and internal rails readable.
	_draw_printed_panel(Rect2(8, 8, 404, 604), PALETTE.PEACH_PAPER_MUTED, card_border_color, 20, sx, sy, PEACH_FRAME_BORDER_WIDTH)
	_draw_printed_panel(Rect2(26, 20, 368, 76), PALETTE.PEACH_PAPER, ink, 15, sx, sy, 2)
	var full_category := _uses_full_width_category_rail()
	var art_height := 338.0 if compact_visual else (246.0 if full_category else 220.0)
	_draw_ribbon_art_well(Rect2(26, 104, 368, art_height), sx, sy)
	if upgraded:
		# Foil animation remains active; this small printed reward underline also
		# identifies an upgrade without yellow lettering on light paper.
		draw_line(Vector2(104 * sx, 88 * sy), Vector2(380 * sx, 88 * sy), PALETTE.STATE_REWARD, maxf(1.0, 3.0 * minf(sx, sy)), true)
	if compact_visual:
		# The compact ribbon also backs the field's live combat numbers; their
		# position and hit areas remain the same as the full-paper stat strip.
		return

	var rules_bottom := 603.0 if _uses_expanded_rules_panel() else 541.0
	_draw_printed_panel(Rect2(28, 405, 364, rules_bottom - 405), PALETTE.PEACH_PAPER, Color(ink, 0.36), 13, sx, sy, 1)
	if show_stats:
		_draw_printed_panel(Rect2(28, 548, 170, 55), _pastel_ribbon_color(accent_color), ink, 14, sx, sy, 2)
		_draw_printed_panel(Rect2(222, 548, 170, 55), _pastel_ribbon_color(secondary_accent_color), ink, 14, sx, sy, 2)
	elif not _uses_expanded_rules_panel():
		_draw_printed_panel(Rect2(28, 548, 364, 55), PALETTE.PEACH_PAPER, ink, 13, sx, sy, 1)


func _pastel_ribbon_color(color: Color) -> Color:
	# Warm the stock without replacing semantic affiliation hues. Exact colors
	# remain in the medallion; recipe symbols print in black on the softer ribbon.
	return color.lerp(PALETTE.PEACH_PAPER, PALETTE.PEACH_CARD_RIBBON_PAPER_MIX)


func _draw_ribbon_art_well(rect: Rect2, sx: float, sy: float) -> void:
	var fill := PALETTE.PEACH_CARD_FRAME.lerp(_pastel_ribbon_color(accent_color), 0.18)
	_draw_printed_panel(rect, fill, Color.TRANSPARENT, 13, sx, sy)
	if affinities.size() > 1:
		var right := StyleBoxFlat.new()
		right.bg_color = PALETTE.PEACH_CARD_FRAME.lerp(_pastel_ribbon_color(secondary_accent_color), 0.18)
		right.corner_radius_top_right = maxi(1, roundi(13 * minf(sx, sy)))
		right.corner_radius_bottom_right = right.corner_radius_top_right
		right.corner_detail = 8
		draw_style_box(right, Rect2(Vector2(rect.get_center().x * sx, rect.position.y * sy), Vector2(rect.size.x * 0.5 * sx, rect.size.y * sy)))
	_draw_printed_panel(rect, Color.TRANSPARENT, Color(PALETTE.PEACH_INK, 0.64), 13, sx, sy, 1)


func _draw_art_well(rect: Rect2, sx: float, sy: float) -> void:
	var cream := PALETTE.LOCALS_PAPER
	_draw_printed_panel(rect, cream, PALETTE.LOCALS_INK, 2, sx, sy, 1)
	# One broad diagonal is ink printed behind the genuine card illustration.
	# Its color echoes the sleeve, as in the supplied red and blue card frames.
	var inset := rect.grow(-1.5)
	var print_color := sleeve_color.lerp(cream, 0.24)
	var triangle: Array[Vector2] = [
		inset.position,
		Vector2(inset.end.x, inset.position.y),
		Vector2(inset.position.x, inset.position.y + inset.size.y * 0.88),
	]
	_draw_poly(_points(triangle, sx, sy), print_color)
	if not sleeve_color.is_equal_approx(secondary_sleeve_color):
		_draw_poly(_points([
			inset.position + Vector2(inset.size.x * 0.60, 0),
			Vector2(inset.end.x, inset.position.y),
			Vector2(inset.position.x + inset.size.x * 0.60, inset.position.y + inset.size.y * 0.35),
		], sx, sy), secondary_sleeve_color.lerp(cream, 0.24))


func _ribbon_color(color: Color) -> Color:
	return color.lerp(PALETTE.LOCALS_PAPER, 0.22)


func _draw_effect_footer(sx: float, sy: float, _stroke: float) -> void:
	_draw_printed_panel(Rect2(28, 548, 364, 55), PALETTE.LOCALS_PAPER, PALETTE.LOCALS_INK, 3, sx, sy, 1)


func _draw_printed_panel(rect: Rect2, fill: Color, edge: Color, radius: int, sx: float, sy: float, border: int = 0, shadow: bool = false) -> void:
	var paper := StyleBoxFlat.new()
	paper.bg_color = fill
	paper.border_color = edge
	paper.set_border_width_all(maxi(1, roundi(float(border) * minf(sx, sy))) if border > 0 else 0)
	paper.set_corner_radius_all(maxi(1, roundi(float(radius) * minf(sx, sy))) if radius > 0 else 0)
	paper.corner_detail = 8
	paper.anti_aliasing = true
	if shadow:
		paper.shadow_color = Color(PALETTE.PEACH_INK if peach_soda_frame else PALETTE.LOCALS_INK, 0.24)
		paper.shadow_size = 0 if peach_soda_frame else maxi(1, roundi(2 * minf(sx, sy)))
		paper.shadow_offset = Vector2(2 * sx, (3 if peach_soda_frame else 4) * sy)
	draw_style_box(paper, Rect2(rect.position * Vector2(sx, sy), rect.size * Vector2(sx, sy)))


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


func _apply_chrome_text_styles(_scale_factor: float = 1.0) -> void:
	# Solid printed text remains legible at hand and inspection scale. A dark
	# title strip supports the established reward-yellow upgraded card state.
	var ink := PALETTE.PEACH_INK if peach_soda_frame else PALETTE.LOCALS_INK
	var supporting_ink := PALETTE.PEACH_INK_SOFT if peach_soda_frame else PALETTE.LOCALS_INK_SOFT
	_apply_printed_text(_title_label, ink if peach_soda_frame else PALETTE.STATE_REWARD if upgraded else PALETTE.COOL_WHITE)
	_apply_printed_text(_type_label, ink)
	_apply_printed_text(_affinity_label, ink)
	_apply_printed_text(_attack_value, ink)
	_apply_printed_text(_attack_label, supporting_ink)
	_apply_printed_text(_health_value, ink)
	_apply_printed_text(_health_label, supporting_ink)
	_apply_printed_text(_footer_label, ink)
	_apply_printed_text(_recipe_title_label, supporting_ink)
	_apply_printed_text(_recipe_requirements_label, ink)
	_apply_printed_text(_rules_label, ink)


func _apply_printed_text(label: Label, foreground: Color) -> void:
	label.add_theme_color_override("font_color", foreground)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


func _scaled_outline(base_size: int, scale_factor: float) -> int:
	return maxi(1, roundi(float(base_size) * scale_factor))


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
