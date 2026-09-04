extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const OUTPUT_PATH := "res://outputs/concept_art/live-runtime-card-integration-v1.png"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(2000, 1120)
	root.content_scale_size = Vector2i(2000, 1120)
	var canvas := _Background.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)

	var eyebrow := _label("LIVE COMPONENT / CARDFACE.GD", 24, PALETTE.ELECTRIC_CYAN, DISPLAY_FONT)
	eyebrow.position = Vector2(88, 52)
	eyebrow.size = Vector2(800, 36)
	canvas.add_child(eyebrow)
	var heading := _label("THE APPROVED CARD SYSTEM IS NOW IN GAME.", 52, PALETTE.COOL_WHITE, DISPLAY_FONT)
	heading.position = Vector2(86, 90)
	heading.size = Vector2(1700, 68)
	canvas.add_child(heading)
	var description := _label("These are live CardFace instances—the same component used by battle, inspection, shops, rewards, packs, and 3D card textures.", 20, Color(PALETTE.COOL_WHITE, 0.68), BODY_FONT)
	description.position = Vector2(90, 158)
	description.size = Vector2(1700, 34)
	canvas.add_child(description)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_error("Could not load cards for live runtime capture.")
		quit(1)
		return

	_add_sample(canvas, catalog.cards_by_id.fresh_comeback_corgi, Vector2(88, 262), Vector2(420, 620), false, "FULL / INGREDIENT")
	_add_sample(canvas, catalog.cards_by_id.sweet_pup_tart, Vector2(558, 262), Vector2(420, 620), false, "FULL / DUAL MEAL")
	_add_sample(canvas, catalog.cards_by_id.chef_mary, Vector2(1072, 302), Vector2(274, 390), false, "CHEF / 274 × 390")
	_add_sample(canvas, catalog.cards_by_id.item_wooden_spoon, Vector2(1405, 302), Vector2(274, 390), false, "TOOL / 274 × 390")
	_add_sample(canvas, catalog.cards_by_id.spicy_funky_jambaye_aye, Vector2(1740, 370), Vector2(176, 250), false, "SHOP / 176 × 250")

	var compact_note := _label("Compact board cards retain identity, artwork, and split stats; inspection reveals the full rules face.", 18, Color(PALETTE.COOL_WHITE, 0.58), BODY_FONT)
	compact_note.position = Vector2(1072, 756)
	compact_note.size = Vector2(790, 58)
	compact_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(compact_note)

	for _frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Live runtime card capture returned an empty image.")
		quit(1)
		return
	var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Could not save live runtime card capture: %s" % error_string(save_error))
		quit(1)
		return
	print("LIVE_RUNTIME_CARD_CAPTURE=%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit(0)


func _add_sample(parent: Control, card: Dictionary, position_value: Vector2, dimensions: Vector2, compact: bool, caption_text: String) -> void:
	var caption := _label(caption_text, 20, Color(PALETTE.COOL_WHITE, 0.78), DISPLAY_FONT)
	caption.position = Vector2(position_value.x, position_value.y - 38)
	caption.size = Vector2(maxf(dimensions.x, 220.0), 30)
	parent.add_child(caption)
	var face := CARD_FACE_SCRIPT.new()
	face.configure(card, "black", false, compact)
	face.position = position_value
	face.custom_minimum_size = dimensions
	parent.add_child(face)
	face.set_deferred("size", dimensions)


func _label(value: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	var variation := FontVariation.new()
	variation.base_font = font
	variation.variation_embolden = 0.45
	label.text = value
	label.add_theme_font_override("font", variation)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


class _Background extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PALETTE.CARBON.darkened(0.14))
		for x in range(-500, 2400, 116):
			draw_line(Vector2(x, 0), Vector2(x + 610, 1120), Color(PALETTE.STEEL, 0.045), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(2000, 0), Vector2(1730, 1120), Vector2(0, 1120),
		]), Color(PALETTE.GRAPHITE, 0.22))
		draw_line(Vector2(0, 208), Vector2(2000, 208), Color(PALETTE.ELECTRIC_CYAN, 0.17), 2.0, true)
