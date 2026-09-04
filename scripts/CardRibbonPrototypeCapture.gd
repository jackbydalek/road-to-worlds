extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CARD_RIBBON_SCRIPT := preload("res://scripts/ui/CardRibbon.gd")
const CARD_MEDALLION_SCRIPT := preload("res://scripts/ui/CardMedallion.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

const CANVAS_SIZE := Vector2i(1600, 960)
const OUTPUT_PATH := "res://outputs/card_ribbon_prototype.png"
const CARD_SIZE := Vector2(290, 412)
const CARD_Y := 178.0
const CARD_ENTRIES := [
	{
		"id": "spicy_firecracker_shrimp",
		"caption": "MEAL + RECIPE",
		"title": "MEAL",
		"detail": "SPICY + ANY",
		"left": Color("#C96C60"),
	},
	{
		"id": "fresh_crisp_capybara",
		"caption": "SINGLE AFFINITY",
		"title": "INGREDIENT",
		"detail": "",
		"left": PALETTE.FRESH_YELLOW,
	},
	{
		"id": "spicy_habanero_hare",
		"caption": "DUAL AFFINITY",
		"title": "INGREDIENT",
		"detail": "",
		"left": PALETTE.FRESH_YELLOW,
		"right": Color("#C96C60"),
	},
	{
		"id": "chef_mary",
		"caption": "SUPPORT CARD",
		"title": "CHEF",
		"detail": "",
		"left": PALETTE.PERIWINKLE,
	},
]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.content_scale_size = CANVAS_SIZE
	root.size = CANVAS_SIZE
	var canvas := Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	_add_background(canvas)

	var title := _label("PROGRAMMATIC RIBBON PROTOTYPE", 48, PALETTE.NAVY, DISPLAY_FONT)
	title.position = Vector2(120, 48)
	title.size = Vector2(1360, 62)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(title)

	var subtitle := _label(
		"SCALABLE GODOT SHAPES • AFFINITY COLOR • NAVY LINEWORK • NO IMAGE ASSET",
		18,
		PALETTE.NAVY_MUTED,
		BODY_FONT
	)
	subtitle.position = Vector2(120, 108)
	subtitle.size = Vector2(1360, 34)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(subtitle)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_error("Could not load card catalog for ribbon prototype.")
		quit(1)
		return

	var gap := 58.0
	var total_width := CARD_SIZE.x * CARD_ENTRIES.size() + gap * (CARD_ENTRIES.size() - 1)
	var start_x := (CANVAS_SIZE.x - total_width) * 0.5
	for index in CARD_ENTRIES.size():
		var entry: Dictionary = CARD_ENTRIES[index]
		var face := CARD_FACE_SCRIPT.new()
		face.configure(catalog.cards_by_id[String(entry.id)], "black", false)
		face.clip_contents = false
		face.position = Vector2(start_x + index * (CARD_SIZE.x + gap), CARD_Y)
		face.size = CARD_SIZE
		canvas.add_child(face)
		_replace_existing_symbol(face, entry)
		_replace_existing_ribbon(face, entry)
		_move_stats_badge(face)
		call_deferred("_move_stats_badge", face)

		var caption := _label(String(entry.caption), 17, PALETTE.NAVY, BODY_FONT)
		caption.position = Vector2(face.position.x, CARD_Y + CARD_SIZE.y + 18.0)
		caption.size = Vector2(CARD_SIZE.x, 30)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		canvas.add_child(caption)

	_add_scale_samples(canvas)
	for _frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://outputs"))
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Godot did not return a rendered ribbon prototype image.")
		quit(1)
		return
	var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if save_error != OK:
		push_error("Could not save ribbon prototype: %s" % error_string(save_error))
		quit(1)
		return
	print("Ribbon prototype saved: %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	quit()


func _replace_existing_ribbon(face: Control, entry: Dictionary) -> void:
	for node_name in ["CardTypeRibbon", "DualTypeTint", "CardRequirementsDivider", "CardType", "CardRequirements"]:
		var existing := face.find_child(node_name, true, false)
		if existing != null:
			existing.visible = false
	var ribbon = CARD_RIBBON_SCRIPT.new()
	ribbon.name = "PrototypeRibbon"
	var secondary: Color = entry.get("right", Color.TRANSPARENT)
	ribbon.configure(entry.left, secondary, String(entry.title), String(entry.detail))
	var is_meal := String(entry.title) == "MEAL"
	ribbon.position = Vector2(CARD_SIZE.x * 0.025, CARD_SIZE.y * (0.44 if is_meal else 0.475))
	var ribbon_height_ratio := 0.19 if is_meal else (0.155 if entry.detail != "" else 0.125)
	ribbon.size = Vector2(CARD_SIZE.x * 0.95, CARD_SIZE.y * ribbon_height_ratio)
	face.add_child(ribbon)


func _replace_existing_symbol(face: Control, entry: Dictionary) -> void:
	var title_capsule := face.find_child("CardTitleCapsule", true, false) as Panel
	if title_capsule != null:
		var current_style := title_capsule.get_theme_stylebox("panel") as StyleBoxFlat
		if current_style != null:
			var opaque_style := current_style.duplicate() as StyleBoxFlat
			opaque_style.bg_color = PALETTE.CREAM
			title_capsule.add_theme_stylebox_override("panel", opaque_style)

	var icon := face.find_child("CardAffinityIcon", true, false) as Label
	if icon == null:
		return
	var symbol_text := icon.text
	var symbol_font := icon.get_theme_font("font")
	for node_name in ["CardSymbolBox", "DualAffinitySymbolTint", "DualAffinitySymbolDivider", "CardAffinityIcon"]:
		var existing := face.find_child(node_name, true, false)
		if existing != null:
			existing.visible = false

	var title := face.find_child("CardTitle", true, false) as Label
	if title != null:
		title.anchor_left = 0.215
		title.offset_left = 0.0

	var medallion = CARD_MEDALLION_SCRIPT.new()
	medallion.name = "PrototypeMedallion"
	var secondary: Color = entry.get("right", Color.TRANSPARENT)
	medallion.configure(entry.left, secondary, symbol_text, symbol_font)
	medallion.position = Vector2(-CARD_SIZE.x * 0.05, -CARD_SIZE.y * 0.015)
	medallion.size = Vector2(CARD_SIZE.x * 0.235, CARD_SIZE.x * 0.235)
	face.add_child(medallion)


func _move_stats_badge(face: Control) -> void:
	for node_name in ["CardStatsBadge", "CardStats"]:
		var stats_control := face.find_child(node_name, true, false) as Control
		if stats_control == null:
			continue
		stats_control.anchor_left = 0.005
		stats_control.anchor_top = 0.905
		stats_control.anchor_right = 0.34
		stats_control.anchor_bottom = 0.995
		stats_control.offset_left = 0.0
		stats_control.offset_top = 0.0
		stats_control.offset_right = 0.0
		stats_control.offset_bottom = 0.0


func _add_scale_samples(parent: Control) -> void:
	var panel := Panel.new()
	panel.position = Vector2(160, 690)
	panel.size = Vector2(1280, 205)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(PALETTE.LAVENDER_GLASS, 0.68)
	panel_style.border_color = Color(PALETTE.PERIWINKLE, 0.72)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(panel)

	var label := _label("SAME DRAWING CODE AT DIFFERENT SIZES", 18, PALETTE.NAVY_MUTED, BODY_FONT)
	label.position = Vector2(34, 18)
	label.size = Vector2(1212, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	var large = CARD_RIBBON_SCRIPT.new()
	large.configure(Color("#C96C60"), PALETTE.FRESH_YELLOW, "MEAL", "SPICY + FRESH")
	large.position = Vector2(72, 70)
	large.size = Vector2(460, 102)
	panel.add_child(large)

	var medium = CARD_RIBBON_SCRIPT.new()
	medium.configure(PALETTE.FUNKY_PLUM, Color.TRANSPARENT, "INGREDIENT")
	medium.position = Vector2(625, 84)
	medium.size = Vector2(350, 78)
	panel.add_child(medium)

	var small = CARD_RIBBON_SCRIPT.new()
	small.configure(PALETTE.PERIWINKLE, Color.TRANSPARENT, "CHEF")
	small.position = Vector2(1040, 104)
	small.size = Vector2(170, 46)
	panel.add_child(small)


func _add_background(parent: Control) -> void:
	var background := ColorRect.new()
	background.color = PALETTE.CREAM
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)

	var blush := Polygon2D.new()
	blush.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(520, 0), Vector2(290, 960), Vector2(0, 960),
	])
	blush.color = Color(PALETTE.BLUSH, 0.18)
	parent.add_child(blush)

	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(1240, 0), Vector2(1600, 0), Vector2(1600, 960), Vector2(1370, 960),
	])
	sky.color = Color(PALETTE.SKY, 0.16)
	parent.add_child(sky)


func _label(text: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
