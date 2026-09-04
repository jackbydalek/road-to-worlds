extends SceneTree

const CARD_SCRIPT := preload("res://scripts/ui/RuntimeAngularCard.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CARD_DATA_PATH := "res://data/cards.json"
const OUTPUT_PATH := "res://outputs/concept_art/runtime-affinity-family-v1.png"

const CARD_SPECS := [
	{"id": "spicy_hot_honey_bee", "caption": "SPICY", "art_zoom": 1.10},
	{"id": "sweet_caramel_camel", "caption": "SWEET", "art_zoom": 1.00},
	{"id": "hearty_ramen_ram", "caption": "HEARTY", "art_zoom": 1.00},
	{"id": "funky_toolbox_toad", "caption": "FUNKY", "art_zoom": 1.20},
	{"id": "fresh_sprout_squirrel", "caption": "FRESH", "art_zoom": 1.15},
]


func _init() -> void:
	call_deferred("_build_and_capture")


func _build_and_capture() -> void:
	root.title = "TOP CUT: Locals to Worlds — Runtime Affinity Family"
	root.size = Vector2i(2400, 1120)
	root.content_scale_size = Vector2i(2400, 1120)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	var background := _PreviewBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var eyebrow := _label(DISPLAY_FONT, 24, Color(PALETTE.ELECTRIC_CYAN, 0.88), 0.62)
	eyebrow.text = "RUNTIME SYSTEM / AFFINITY FAMILY"
	eyebrow.position = Vector2(66, 54)
	eyebrow.size = Vector2(800, 36)
	background.add_child(eyebrow)

	var heading := _label(DISPLAY_FONT, 54, PALETTE.COOL_WHITE, 1.0)
	heading.text = "FIVE AFFINITIES. ONE CARD SYSTEM."
	heading.position = Vector2(64, 88)
	heading.size = Vector2(1500, 70)
	background.add_child(heading)

	var description := _label(BODY_FONT, 20, Color(PALETTE.COOL_WHITE, 0.68), 0.04)
	description.text = "Identical runtime layout and typography; only the affinity accent, symbol pairing, card data and illustration change."
	description.position = Vector2(68, 158)
	description.size = Vector2(1750, 38)
	background.add_child(description)

	var database := _load_card_database()
	var card_size := Vector2(420, 620)
	var start_x := 60.0
	var gap := 45.0
	for index in CARD_SPECS.size():
		var spec: Dictionary = CARD_SPECS[index]
		var card_id := String(spec["id"])
		if not database.has(card_id):
			push_error("Runtime affinity preview is missing data for %s" % card_id)
			continue
		var x := start_x + float(index) * (card_size.x + gap)
		var card_data: Dictionary = database[card_id].duplicate(true)
		card_data["display_card_type"] = "INGREDIENT"
		card_data["affinities"] = [String(card_data.get("archetype", "neutral"))]
		card_data["art_zoom"] = float(spec["art_zoom"])
		card_data["text"] = _line_break_rules(String(card_data.get("text", "")), 28)

		var affinity := String(card_data["affinities"][0])
		var caption_color := _color_for_affinity(affinity)
		var caption_bar := ColorRect.new()
		caption_bar.color = caption_color
		caption_bar.position = Vector2(x, 220)
		caption_bar.size = Vector2(62, 7)
		caption_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(caption_bar)

		var caption := _label(DISPLAY_FONT, 24, PALETTE.COOL_WHITE, 0.72)
		caption.text = String(spec["caption"])
		caption.position = Vector2(x + 76, 204)
		caption.size = Vector2(300, 36)
		background.add_child(caption)

		var art := load(_art_path_for(card_data)) as Texture2D
		var card := CARD_SCRIPT.new()
		card.name = "%sRuntimeCard" % card_id.to_pascal_case()
		card.position = Vector2(x, 250)
		card.size = card_size
		background.add_child(card)
		card.configure(card_data, art)

	var footer := _label(DISPLAY_FONT, 19, Color(PALETTE.COOL_WHITE, 0.46), 0.35)
	footer.text = "REAL GAME DATA  /  EXISTING CARD ART  /  PROCEDURAL FRAME GEOMETRY  /  NO FRAME BITMAPS"
	footer.position = Vector2(68, 1012)
	footer.size = Vector2(1600, 32)
	background.add_child(footer)

	for _frame in range(5):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Runtime affinity family capture failed: viewport image is empty")
		quit(1)
		return
	var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Runtime affinity family capture failed with error %s" % save_error)
		quit(1)
		return
	print("RUNTIME_AFFINITY_FAMILY_CAPTURE=%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
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
	var frames: Array = card_data.get("art_frames", [])
	return String(frames[0]) if not frames.is_empty() else "res://assets/cards/art_pending.png"


func _line_break_rules(value: String, max_characters: int) -> String:
	var words := value.split(" ", false)
	var lines: PackedStringArray = []
	var current := ""
	for word in words:
		var candidate := String(word) if current.is_empty() else "%s %s" % [current, word]
		if candidate.length() > max_characters and not current.is_empty():
			lines.append(current)
			current = String(word)
		else:
			current = candidate
	if not current.is_empty():
		lines.append(current)
	return "\n".join(lines)


func _color_for_affinity(value: String) -> Color:
	match value.to_lower():
		"spicy":
			return PALETTE.AFFINITY_SPICY
		"sweet":
			return PALETTE.AFFINITY_SWEET
		"hearty":
			return PALETTE.AFFINITY_HEARTY
		"funky":
			return PALETTE.AFFINITY_FUNKY
		"fresh":
			return PALETTE.AFFINITY_FRESH
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
		for x in range(-500, 2700, 112):
			draw_line(Vector2(x, 0), Vector2(x + 600, 1120), Color(PALETTE.STEEL, 0.05), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(2400, 0), Vector2(2140, 1120), Vector2(0, 1120),
		]), Color(PALETTE.GRAPHITE, 0.18))
		draw_line(Vector2(0, 198), Vector2(2400, 198), Color(PALETTE.STEEL, 0.22), 2.0, true)
		draw_line(Vector2(0, 199), Vector2(760, 199), Color(PALETTE.ELECTRIC_CYAN, 0.58), 3.0, true)
