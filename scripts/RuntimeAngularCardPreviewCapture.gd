extends SceneTree

const CARD_SCENE := preload("res://scripts/ui/RuntimeAngularCard.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ART := preload("res://assets/cards/art/spicy_jalapeno_panther/frame_00.png")
const OUTPUT_PATH := "res://outputs/concept_art/card-jalapeno-panther-runtime-v1.png"


func _init() -> void:
	call_deferred("_build_and_capture")


func _build_and_capture() -> void:
	root.title = "TOP CUT: Locals to Worlds — Runtime Card Prototype"
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	var background := _PreviewBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var eyebrow := _label(DISPLAY_FONT, 22, Color(PALETTE.COOL_WHITE, 0.66), 0.6)
	eyebrow.text = "RUNTIME CARD FRAME / 01"
	eyebrow.position = Vector2(74, 62)
	eyebrow.size = Vector2(460, 34)
	background.add_child(eyebrow)

	var heading := _label(DISPLAY_FONT, 45, PALETTE.COOL_WHITE, 0.95)
	heading.text = "BUILT IN GODOT"
	heading.position = Vector2(72, 91)
	heading.size = Vector2(480, 62)
	background.add_child(heading)

	var description := _label(BODY_FONT, 19, Color(PALETTE.COOL_WHITE, 0.72), 0.06)
	description.text = "No card-frame bitmap. The chassis, clipped panels,\nkeylines, type rail, rules box and stat pods are runtime UI."
	description.position = Vector2(76, 153)
	description.size = Vector2(480, 66)
	background.add_child(description)

	var card := CARD_SCENE.new()
	card.name = "JalapenoPantherRuntimeCard"
	card.position = Vector2(750, 104)
	card.size = Vector2(500, 738)
	background.add_child(card)
	card.configure({
		"name": "Jalapeño Panther",
		"card_type": "Ingredient",
		"affinity": "Spicy",
		"text": "Sacrifice this: search your\ndeck for a Spicy card.",
		"attack": 1,
		"health": 2,
	}, ART)

	_add_feature(background, Vector2(76, 298), PALETTE.SIGNAL_RED, "SHAPE LANGUAGE", "Clipped corners and diagonal wedges")
	_add_feature(background, Vector2(76, 387), PALETTE.ELECTRIC_CYAN, "COLOR LOGIC", "Dark neutral chassis + one affinity accent")
	_add_feature(background, Vector2(76, 476), PALETTE.COOL_WHITE, "CARD CONTENT", "Data-driven type, rules and combat stats")
	_add_feature(background, Vector2(76, 565), PALETTE.STEEL, "ART LAYER", "Existing creature illustration, linearly filtered")

	var footer := _label(DISPLAY_FONT, 18, Color(PALETTE.COOL_WHITE, 0.46), 0.35)
	footer.text = "PROTOTYPE SCALE  •  500 × 738  •  RESOLUTION INDEPENDENT FRAME"
	footer.position = Vector2(76, 812)
	footer.size = Vector2(630, 30)
	background.add_child(footer)

	for _frame in range(5):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Runtime card capture failed: viewport image is empty")
		quit(1)
		return
	var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Runtime card capture failed with error %s" % save_error)
		quit(1)
		return
	print("RUNTIME_CARD_CAPTURE=%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()


func _add_feature(parent: Control, position_value: Vector2, color: Color, title: String, detail: String) -> void:
	var marker := ColorRect.new()
	marker.color = color
	marker.position = position_value
	marker.size = Vector2(9, 58)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(marker)

	var title_label := _label(DISPLAY_FONT, 23, PALETTE.COOL_WHITE, 0.72)
	title_label.text = title
	title_label.position = position_value + Vector2(24, -2)
	title_label.size = Vector2(510, 30)
	parent.add_child(title_label)

	var detail_label := _label(BODY_FONT, 17, Color(PALETTE.COOL_WHITE, 0.64), 0.03)
	detail_label.text = detail
	detail_label.position = position_value + Vector2(24, 29)
	detail_label.size = Vector2(520, 27)
	parent.add_child(detail_label)


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
		draw_rect(Rect2(Vector2.ZERO, size), PALETTE.CARBON.darkened(0.12))
		for x in range(-300, 1600, 96):
			draw_line(Vector2(x, 0), Vector2(x + 520, 900), Color(PALETTE.STEEL, 0.055), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(650, 0), Vector2(430, 900), Vector2(0, 900),
		]), Color(PALETTE.GRAPHITE, 0.44))
		draw_line(Vector2(650, 0), Vector2(430, 900), Color(PALETTE.ELECTRIC_CYAN, 0.20), 2.0, true)
