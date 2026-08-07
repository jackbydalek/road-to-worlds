extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const PREVIEW_PATH := "/tmp/topdeck-to-worlds-card-content-fit.png"
const TEST_CARD_IDS := [
	"funky_fondue_ferret",
	"spicy_funky_relishoon",
	"fresh_harvest_hydra",
	"item_switchblade",
]

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1660, 720)
	var background := ColorRect.new()
	background.color = Color("#F4EEF8")
	background.size = Vector2(root.size)
	root.add_child(background)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	if failed:
		quit(1)
		return

	for index in TEST_CARD_IDS.size():
		var card_id: String = TEST_CARD_IDS[index]
		var card: Dictionary = catalog.cards_by_id.get(card_id, {})
		_expect(not card.is_empty(), "Missing content-fit card %s." % card_id)
		if card.is_empty():
			continue

		var large_face = CARD_FACE_SCRIPT.new()
		large_face.configure(card, "gold", false)
		large_face.position = Vector2(35.0 + index * 400.0, 25.0)
		large_face.size = Vector2(250.0, 355.0)
		large_face.set_meta("expected_scale", "large")
		root.add_child(large_face)

		var inspection_face = CARD_FACE_SCRIPT.new()
		inspection_face.configure(card, "gold", false)
		inspection_face.position = Vector2(90.0 + index * 400.0, 430.0)
		inspection_face.size = Vector2(150.0, 213.0)
		inspection_face.set_meta("expected_scale", "inspection")
		root.add_child(inspection_face)

	await process_frame
	await process_frame

	for child in root.get_children():
		if not child is CardFace:
			continue
		var title := child.find_child("CardTitle", true, false) as Label
		var rules := child.find_child("CardRules", true, false) as Label
		var dual_badge := child.find_child("DualAffinityBadgeLabel", true, false)
		_expect(title != null and rules != null, "A content-fit card lost its title or rules label.")
		_expect(dual_badge == null, "A content-fit card restored the redundant DUAL badge.")
		if title != null:
			var title_width := title.get_theme_font("font").get_string_size(
				title.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				title.get_theme_font_size("font_size")
			).x
			_expect(title_width <= title.size.x + 1.0, "%s still clips its title at %s scale." % [title.text, child.get_meta("expected_scale")])
			var minimum_title_size := 12 if child.get_meta("expected_scale") == "large" else 10
			_expect(title.get_theme_font_size("font_size") >= minimum_title_size, "%s only fits by making its title illegibly small." % title.text)
		if rules != null:
			var rules_font := rules.get_theme_font("font")
			var rules_size := rules.get_theme_font_size("font_size")
			var measured := rules_font.get_multiline_string_size(
				rules.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				rules.size.x,
				rules_size
			)
			var line_spacing := rules.get_theme_constant("line_spacing") * maxi(0, rules.get_line_count() - 1)
			_expect(measured.y + line_spacing <= rules.size.y + 1.0, "%s clips its rules at %s scale." % [title.text, child.get_meta("expected_scale")])
			_expect(rules.max_lines_visible == -1, "%s still truncates rules at a fixed visible-line limit." % title.text)
			var minimum_rules_size := 11 if child.get_meta("expected_scale") == "large" else 5
			_expect(rules_size >= minimum_rules_size, "%s only fits by making its rules illegibly small." % title.text)

	var preview: Image = null
	if DisplayServer.get_name() != "headless":
		preview = root.get_texture().get_image()
	if preview != null:
		_expect(preview.save_png(PREVIEW_PATH) == OK, "Could not save the content-fit preview.")

	if failed:
		quit(1)
		return
	print("Card content fit smoke test passed." + (" Preview: " + PREVIEW_PATH if preview != null else ""))
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
