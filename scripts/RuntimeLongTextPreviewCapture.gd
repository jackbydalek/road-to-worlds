extends SceneTree

const CARD_SCRIPT := preload("res://scripts/ui/RuntimeAngularCard.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CARD_DATA_PATH := "res://data/cards.json"
const OUTPUT_PATH := "res://outputs/concept_art/runtime-long-text-cards-v1.png"

const CARD_SPECS := [
	{
		"id": "fresh_comeback_corgi",
		"caption": "LONGEST INGREDIENT",
		"note": "146 CHARACTERS",
		"art_zoom": 1.0,
	},
	{
		"id": "fresh_harvest_hydra",
		"caption": "LONGEST MEAL",
		"note": "135 CHARACTERS + RECIPE",
		"art_zoom": 1.0,
	},
	{
		"id": "sweet_pup_tart",
		"caption": "DUAL MEAL",
		"note": "101 CHARACTERS + RECIPE",
		"art_zoom": 1.0,
	},
	{
		"id": "spicy_ghost_pepper_python",
		"caption": "DUAL INGREDIENT",
		"note": "90 CHARACTERS / 2 SENTENCES",
		"art_zoom": 1.0,
	},
]


func _init() -> void:
	call_deferred("_build_and_capture")


func _build_and_capture() -> void:
	root.title = "TOP CUT: Locals to Worlds — Long Card Text"
	root.size = Vector2i(2000, 1120)
	root.content_scale_size = Vector2i(2000, 1120)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	var background := _PreviewBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var eyebrow := _label(DISPLAY_FONT, 24, Color(PALETTE.ELECTRIC_CYAN, 0.88), 0.62)
	eyebrow.text = "RUNTIME SYSTEM / LONG-FORM RULES"
	eyebrow.position = Vector2(86, 54)
	eyebrow.size = Vector2(900, 36)
	background.add_child(eyebrow)

	var heading := _label(DISPLAY_FONT, 54, PALETTE.COOL_WHITE, 1.0)
	heading.text = "REAL CARD COPY. MEASURED TO FIT."
	heading.position = Vector2(84, 88)
	heading.size = Vector2(1500, 70)
	background.add_child(heading)

	var description := _label(BODY_FONT, 20, Color(PALETTE.COOL_WHITE, 0.68), 0.04)
	description.text = "The rules panel wraps by rendered width and steps down from 24 px only when the complete effect needs more room. No copy is truncated."
	description.position = Vector2(88, 158)
	description.size = Vector2(1700, 38)
	background.add_child(description)

	var database := _load_card_database()
	var card_size := Vector2(420, 620)
	var start_x := 88.0
	var gap := 60.0
	for index in CARD_SPECS.size():
		var spec: Dictionary = CARD_SPECS[index]
		var card_id := String(spec["id"])
		if not database.has(card_id):
			push_error("Long-text preview is missing data for %s" % card_id)
			continue
		var x := start_x + float(index) * (card_size.x + gap)
		var card_data: Dictionary = database[card_id].duplicate(true)
		card_data["display_card_type"] = String(card_data.get("card_type", "card")).to_upper()
		card_data["affinities"] = _affinities_for(card_data)
		card_data["art_zoom"] = float(spec.get("art_zoom", 1.0))

		var caption_color := _color_for_affinity(String(card_data["affinities"][0]))
		var caption_bar := ColorRect.new()
		caption_bar.color = caption_color
		caption_bar.position = Vector2(x, 220)
		caption_bar.size = Vector2(62, 7)
		caption_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(caption_bar)

		var caption := _label(DISPLAY_FONT, 24, PALETTE.COOL_WHITE, 0.72)
		caption.text = String(spec["caption"])
		caption.position = Vector2(x + 76, 202)
		caption.size = Vector2(344, 32)
		background.add_child(caption)

		var art := load(_art_path_for(card_data)) as Texture2D
		var card := CARD_SCRIPT.new()
		card.name = "%sLongTextCard" % card_id.to_pascal_case()
		card.position = Vector2(x, 250)
		card.size = card_size
		background.add_child(card)
		card.configure(card_data, art)

		var note := _label(BODY_FONT, 17, Color(PALETTE.COOL_WHITE, 0.56), 0.08)
		note.text = String(spec["note"])
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.position = Vector2(x, 892)
		note.size = Vector2(card_size.x, 28)
		background.add_child(note)

	var footer := _label(DISPLAY_FONT, 19, Color(PALETTE.COOL_WHITE, 0.46), 0.35)
	footer.text = "LIVE CARDS.JSON COPY  /  EXISTING CARD ART  /  COMPLETE EFFECTS  /  RUNTIME WRAP + FONT FIT"
	footer.position = Vector2(88, 1012)
	footer.size = Vector2(1500, 32)
	background.add_child(footer)

	for _frame in range(5):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Long-text card capture failed: viewport image is empty")
		quit(1)
		return
	var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Long-text card capture failed with error %s" % save_error)
		quit(1)
		return
	print("RUNTIME_LONG_TEXT_CAPTURE=%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()


func _load_card_database() -> Dictionary:
	var file := FileAccess.open(CARD_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open %s" % CARD_DATA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Card data did not parse into a dictionary")
		return {}
	var result := {}
	for card_value in parsed.get("cards", []):
		if card_value is Dictionary:
			result[String(card_value.get("id", ""))] = card_value
	return result


func _art_path_for(card_data: Dictionary) -> String:
	if card_data.has("art_path"):
		return String(card_data["art_path"])
	var frames: Array = card_data.get("art_frames", [])
	return String(frames[0]) if not frames.is_empty() else "res://assets/cards/art_pending.png"


func _affinities_for(card_data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw: Variant = card_data.get("archetypes", [])
	if raw is Array:
		for affinity_value in raw:
			result.append(String(affinity_value))
	if result.is_empty():
		result.append(String(card_data.get("archetype", "neutral")))
	return result.slice(0, 2)


func _color_for_affinity(value: String) -> Color:
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


func _label(font: Font, font_size: int, color: Color, embolden: float) -> Label:
	var label := Label.new()
	var font_variation := FontVariation.new()
	font_variation.base_font = font
	font_variation.variation_embolden = embolden
	label.add_theme_font_override("font", font_variation)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


class _PreviewBackground extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PALETTE.CARBON.darkened(0.13))
		for x in range(-500, 2300, 112):
			draw_line(Vector2(x, 0), Vector2(x + 600, 1120), Color(PALETTE.STEEL, 0.05), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(2000, 0), Vector2(1740, 1120), Vector2(0, 1120),
		]), Color(PALETTE.GRAPHITE, 0.23))
		draw_line(Vector2(0, 206), Vector2(2000, 206), Color(PALETTE.ELECTRIC_CYAN, 0.18), 2.0, true)
