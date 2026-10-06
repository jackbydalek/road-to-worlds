extends "res://scripts/SuppliedMinaCapture.gd"

## Native review images for the shared ribbon frame. Uses real catalog cards
## and the supplied Mina fixture; no image generation or source-art changes.
const RIBBON_OUTPUT_DIR := "res://outputs/ribbon_card_frames"
const RIBBON_CARD_FACE := preload("res://scripts/CardFace.gd")
const RIBBON_CATALOG := preload("res://scripts/ContentCatalog.gd")
const RIBBON_PALETTE := preload("res://scripts/ui/GamePalette.gd")
const RIBBON_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const FAMILY_SIZE := Vector2i(1560, 1510)
const FAMILY_CARDS := [
	{"id": "spicy_firecracker_shrimp", "caption": "SPICY MEAL · RECIPE"},
	{"id": "fresh_crisp_capybara", "caption": "FRESH INGREDIENT"},
	{"id": "fresh_spicy_mexican_sweet_corino", "caption": "DUAL INGREDIENT · LONG TITLE"},
	{"id": "hearty_dumpling_tortoise", "caption": "DUAL MEAL · OR RECIPE"},
	{"id": "chef_mary", "caption": "CHEF"},
	{"id": "item_wooden_spoon", "caption": "TOOL"},
]


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RIBBON_OUTPUT_DIR))
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		await _create_match()
		_stage_board(true)
		table.configure_battle_preferences("fast", 1.0, true, false)
		await _settle()
		_check_board_and_hud("ribbon-card-frames")
		_expect(not table.use_generated_opponent_art and table.rival_at_table.is_visible_in_tree(), "Ribbon review lost supplied Mina")
		await _save_ribbon_view(capture_viewport, "%dx%d_battle.png" % [output_size.x, output_size.y], {
			"kind": "native populated battle",
			"generated_rival_art_enabled": table.use_generated_opponent_art,
			"reduced_motion": table.reduced_motion,
		})
		for node in table.find_children("*", "AudioStreamPlayer", true, false):
			node.stop()
			node.stream = null
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	await _capture_ribbon_family()
	var report := FileAccess.open(RIBBON_OUTPUT_DIR.path_join("capture-review.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({
			"renderer": "native Godot CardFace and battle renderer",
			"new_ai_image_generation": false,
			"art_source": "existing catalog illustrations and user-supplied Mina animation",
			"shots": records,
			"failures": errors,
		}, "\t") + "\n")
	else:
		_expect(false, "Could not save ribbon capture review")
	for error in errors:
		push_error(error)
	print("RIBBON_CARD_FRAME_CAPTURE_%s: %d native views; %d failures" % ["OK" if errors.is_empty() else "FAILED", records.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)


func _capture_ribbon_family() -> void:
	var catalog := RIBBON_CATALOG.new()
	if not catalog.load_all():
		_expect(false, "Could not load the actual card catalog for ribbon preview")
		return
	var family_view := SubViewport.new()
	family_view.size = FAMILY_SIZE
	family_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(family_view)
	var canvas := Control.new()
	canvas.size = Vector2(FAMILY_SIZE)
	family_view.add_child(canvas)
	var background := ColorRect.new()
	background.color = RIBBON_PALETTE.PEACH_PAPER_MUTED
	background.size = Vector2(FAMILY_SIZE)
	canvas.add_child(background)
	_add_family_label(canvas, "RIBBON FRAMES", Vector2(80, 25), Vector2(900, 48), 34)
	_add_family_label(canvas, "Current game cards · original illustrations", Vector2(80, 72), Vector2(1200, 32), 20)
	var card_ids: Array[String] = []
	for index in FAMILY_CARDS.size():
		var spec: Dictionary = FAMILY_CARDS[index]
		var card_id := String(spec.id)
		var card: Dictionary = catalog.cards_by_id.get(card_id, {})
		_expect(not card.is_empty(), "Missing family preview card: " + card_id)
		if card.is_empty():
			continue
		card_ids.append(card_id)
		var column := index % 3
		var row := floori(float(index) / 3.0)
		var card_position := Vector2(80 + column * 490, 124 + row * 700)
		var face := RIBBON_CARD_FACE.new()
		face.configure(card, "white", false, false)
		face.custom_minimum_size = Vector2(420, 620)
		face.size = Vector2(420, 620)
		face.position = card_position
		canvas.add_child(face)
		_add_family_label(canvas, String(spec.caption), card_position + Vector2(0, 640), Vector2(440, 32), 19)
	await _settle()
	await _save_ribbon_view(family_view, "ribbon_frame_family.png", {
		"kind": "actual CardFace controls",
		"card_ids": card_ids,
		"card_size": [420, 620],
		"animated_art": false,
	})
	family_view.queue_free()
	await _settle(3)


func _add_family_label(parent: Control, text: String, at: Vector2, bounds: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = bounds
	label.add_theme_font_override("font", RIBBON_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", RIBBON_PALETTE.PEACH_INK)
	parent.add_child(label)


func _save_ribbon_view(viewport: SubViewport, filename: String, metadata: Dictionary) -> void:
	var record := metadata.duplicate(true)
	record["shot"] = filename
	record["output_size"] = [viewport.size.x, viewport.size.y]
	record["saved_png"] = false
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var shot := viewport.get_texture().get_image()
		_expect(shot != null and shot.get_size() == viewport.size, "Incorrect image dimensions: " + filename)
		if shot != null:
			record["saved_png"] = shot.save_png(ProjectSettings.globalize_path(RIBBON_OUTPUT_DIR.path_join(filename))) == OK
			_expect(bool(record.saved_png), "Could not save " + filename)
	records.append(record)
