extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PREVIEW_PATH := "res://outputs/illustrated_vfx/support_card_frame_parity.png"


func _initialize() -> void:
	root.size = Vector2i(1440, 720)
	var background := ColorRect.new()
	background.color = Color("#E9EEF4")
	background.size = Vector2(root.size)
	root.add_child(background)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_error("Could not load cards for the support-frame preview.")
		quit(1)
		return
	var card_ids := [
		"chef_mary",
		"item_wooden_spoon",
		"spice_fresh_balsamic",
		"environment_spicy_taqueria",
	]
	for index in card_ids.size():
		var card_id := String(card_ids[index])
		var card: Dictionary = catalog.cards_by_id.get(card_id, {})
		if card.is_empty():
			push_error("Missing support-frame preview card: %s" % card_id)
			quit(1)
			return
		var face = CARD_FACE_SCRIPT.new()
		face.configure(card, "black", false)
		face.position = Vector2(44.0 + float(index) * 350.0, 48.0)
		face.size = Vector2(300.0, 426.0)
		root.add_child(face)

	for _frame in range(5):
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(PREVIEW_PATH)) != OK:
		push_error("Could not save the support-frame parity preview.")
		quit(1)
		return
	print("SUPPORT_CARD_FRAME_PREVIEW_OK")
	quit()
