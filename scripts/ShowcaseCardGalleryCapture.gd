extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

const CANVAS_SIZE := Vector2i(1920, 1080)
const CARD_SIZE := Vector2(340, 483)
const CARD_Y := 306.0
const OUTPUT_DIRECTORY := "/Users/jack.bydalek/Desktop/TOP CUT Locals to Worlds Card Showcase"
const OUTPUT_PATH := OUTPUT_DIRECTORY + "/topdeck-card-showcase.png"
const SHOWCASE_CARDS := [
	{
		"id": "sweet_pup_tart",
		"label": "DUAL AFFILIATION",
		"caption": "SWEET + HEARTY",
		"fill": Color("#E8E3F5"),
		"rotation": -2.0,
		"file": "dual-type-pup-tart.png",
	},
	{
		"id": "spicy_hot_honey_bee",
		"label": "INGREDIENT",
		"caption": "BUILD YOUR RECIPES",
		"fill": Color("#F2A4B8"),
		"rotation": 1.25,
		"file": "ingredient-hot-honey-bee.png",
	},
	{
		"id": "sweet_cinnamon_snail",
		"label": "MEAL",
		"caption": "SERVE YOUR FINISHER",
		"fill": Color("#8EA9E6"),
		"rotation": -1.25,
		"file": "meal-cinnamon-snail.png",
	},
	{
		"id": "item_wooden_spoon",
		"label": "TOOL",
		"caption": "CHANGE THE PLAY",
		"fill": Color("#D8B35F"),
		"rotation": 2.0,
		"file": "tool-wooden-spoon.png",
	},
]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.content_scale_size = CANVAS_SIZE
	root.size = CANVAS_SIZE
	var canvas := Control.new()
	canvas.name = "CardShowcaseCanvas"
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)

	var background := ColorRect.new()
	background.color = PALETTE.CREAM
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	_add_background_shapes(canvas)

	var title := _label("A TASTE OF THE SET", 64, PALETTE.NAVY, DISPLAY_FONT)
	title.position = Vector2(160, 65)
	title.size = Vector2(1600, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(title)

	var subtitle := _label(
		"BUILD A KITCHEN • SERVE A MEAL • TOPDECK THE WIN",
		24,
		PALETTE.NAVY_MUTED,
		BODY_FONT
	)
	subtitle.position = Vector2(160, 145)
	subtitle.size = Vector2(1600, 42)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(subtitle)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_error("Could not load the card catalog for the showcase capture.")
		quit(1)
		return

	var total_width := CARD_SIZE.x * SHOWCASE_CARDS.size() + 58.0 * (SHOWCASE_CARDS.size() - 1)
	var start_x := (CANVAS_SIZE.x - total_width) * 0.5
	var card_rects: Array[Rect2i] = []
	for index in SHOWCASE_CARDS.size():
		var entry: Dictionary = SHOWCASE_CARDS[index]
		var card_x := start_x + index * (CARD_SIZE.x + 58.0)
		_add_category_sticker(canvas, entry, Vector2(card_x + 22.0, 219.0))

		var face := CARD_FACE_SCRIPT.new()
		face.name = "ShowcaseCard_%s" % String(entry.id)
		face.configure(catalog.cards_by_id[String(entry.id)], "black", false)
		face.position = Vector2(card_x, CARD_Y)
		face.size = CARD_SIZE
		canvas.add_child(face)
		card_rects.append(Rect2i(int(card_x), int(CARD_Y), int(CARD_SIZE.x), int(CARD_SIZE.y)))

		var caption := _label(String(entry.caption), 18, PALETTE.NAVY_MUTED, BODY_FONT)
		caption.position = Vector2(card_x - 8.0, CARD_Y + CARD_SIZE.y + 28.0)
		caption.size = Vector2(CARD_SIZE.x + 16.0, 34.0)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		canvas.add_child(caption)

	var footer := _label("TOP CUT: Locals to Worlds", 26, PALETTE.NAVY, DISPLAY_FONT)
	footer.position = Vector2(160, 954)
	footer.size = Vector2(1600, 42)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(footer)

	for _frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Godot did not return a rendered showcase image.")
		quit(1)
		return
	var save_error := image.save_png(OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save showcase image: %s" % error_string(save_error))
		quit(1)
		return

	for index in SHOWCASE_CARDS.size():
		var crop_rect: Rect2i = card_rects[index]
		var card_image := image.get_region(crop_rect)
		var card_path := OUTPUT_DIRECTORY + "/" + String(SHOWCASE_CARDS[index].file)
		var card_error := card_image.save_png(card_path)
		if card_error != OK:
			push_error("Could not save card crop: %s" % card_path)
			quit(1)
			return

	print("Card showcase saved: %s" % OUTPUT_PATH)
	quit()


func _add_background_shapes(parent: Control) -> void:
	var lavender := Polygon2D.new()
	lavender.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(660, 0), Vector2(390, 1080), Vector2(0, 1080),
	])
	lavender.color = Color(PALETTE.LAVENDER_GLASS, 0.72)
	parent.add_child(lavender)

	var blush := Polygon2D.new()
	blush.polygon = PackedVector2Array([
		Vector2(1460, 0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(1670, 1080),
	])
	blush.color = Color(PALETTE.BLUSH, 0.30)
	parent.add_child(blush)

	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(0, 900), Vector2(530, 770), Vector2(760, 1080), Vector2(0, 1080),
	])
	sky.color = Color(PALETTE.SKY, 0.28)
	parent.add_child(sky)


func _add_category_sticker(parent: Control, entry: Dictionary, position: Vector2) -> void:
	var sticker := PanelContainer.new()
	sticker.position = position
	sticker.size = Vector2(296, 60)
	sticker.rotation = deg_to_rad(float(entry.rotation))
	var style := StyleBoxFlat.new()
	style.bg_color = entry.fill
	style.border_color = PALETTE.NAVY
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(PALETTE.NAVY, 0.20)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	sticker.add_theme_stylebox_override("panel", style)
	parent.add_child(sticker)

	var text := _label(String(entry.label), 25, PALETTE.NAVY, DISPLAY_FONT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sticker.add_child(text)


func _label(text: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
