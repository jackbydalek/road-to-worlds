extends SceneTree

const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const GAME_PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PREVIEW_PATH := "/tmp/topdeck-to-worlds-card-frame-redesign.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1370, 760)
	var background := ColorRect.new()
	background.color = Color("#F4EEF8")
	background.position = Vector2.ZERO
	background.size = Vector2(root.size)
	root.add_child(background)

	var catalog = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Card catalog did not load.")
	if failed:
		quit(1)
		return

	var cards: Array[Dictionary] = []
	cards.append(_find_card(catalog.cards, "spicy_firecracker_shrimp", "ingredient", false))
	cards.append(_find_card(catalog.cards, "fresh_crisp_capybara", "ingredient", false))
	cards.append(_find_card(catalog.cards, "", "meal", true))
	cards.append(_find_card(catalog.cards, "item_wooden_spoon", "tool", false))
	for card in cards:
		_expect(not card.is_empty(), "Could not find every representative card for the redesign preview.")
	if failed:
		quit(1)
		return

	var difficulties := ["black", "yellow", "gold", "silver"]
	for index in cards.size():
		var face = CARD_FACE_SCRIPT.new()
		face.configure(cards[index], difficulties[index], false)
		face.position = Vector2(30.0 + index * 335.0, 28.0)
		face.size = Vector2(300.0, 426.0)
		root.add_child(face)

		var compact_face = CARD_FACE_SCRIPT.new()
		compact_face.configure(cards[index], difficulties[index], false, true)
		compact_face.position = Vector2(70.0 + index * 330.0, 515.0)
		compact_face.size = Vector2(125.0, 178.0)
		root.add_child(compact_face)

	await process_frame
	await process_frame

	for child in root.get_children():
		if not child is CardFace:
			continue
		var frame := child.find_child("CardFrame", true, false) as Panel
		var difficulty_trim := child.find_child("DifficultyTrim", true, false)
		var art_backdrop := child.find_child("CardArtBackdrop", true, false) as Panel
		var title_capsule := child.find_child("CardTitleCapsule", true, false) as Panel
		var symbol_box := child.find_child("CardSymbolBox", true, false) as Panel
		var title := child.find_child("CardTitle", true, false) as Label
		var rules := child.find_child("CardRules", true, false) as Label
		var stats := child.find_child("CardStatsBadge", true, false) as Panel
		var type_ribbon := child.find_child("CardTypeRibbon", true, false) as Panel
		var requirements := child.find_child("CardRequirements", true, false) as Label
		_expect(frame != null and frame.get_meta("frame_style", "") == "illustrated_card", "A representative card did not use the reusable frame.")
		if frame != null:
			var frame_style := frame.get_theme_stylebox("panel") as StyleBoxFlat
			_expect(frame_style != null and frame_style.border_color == frame.get_meta("difficulty_color"), "The selected border color did not replace the outer frame outline.")
		_expect(difficulty_trim == null, "The old inset difficulty trim is still pasted over the card frame.")
		_expect(art_backdrop != null and title_capsule != null, "A representative card lost its artwork well or title capsule.")
		_expect(symbol_box != null, "A representative card lost its dedicated affinity-symbol box.")
		if art_backdrop != null and title_capsule != null:
			_expect(
				title_capsule.position.y + title_capsule.size.y > art_backdrop.position.y,
				"The floating title tab no longer overlaps the artwork well."
			)
		if symbol_box != null:
			_expect(
				symbol_box.size.x >= symbol_box.size.y * 0.85,
				"The affinity-symbol tab regressed into a thin header strip."
			)
		_expect(type_ribbon != null and type_ribbon.position.y < art_backdrop.position.y + art_backdrop.size.y, "The type pill no longer overlaps the artwork boundary.")
		if requirements != null and requirements.visible:
			_expect(not requirements.text.contains("Anything"), "A wildcard recipe still used the word Anything.")
			if title != null and title.text == "Firecracker Shrimp":
				_expect(requirements.text.contains("*"), "The wildcard recipe did not use the compact wildcard notation.")
			_expect(
				requirements.position.y >= type_ribbon.position.y
				and requirements.position.y + requirements.size.y <= type_ribbon.position.y + type_ribbon.size.y + 1.0,
				"Meal requirements escaped the combined type pill."
			)
		if title != null:
			var title_width := title.get_theme_font("font").get_string_size(
				title.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				title.get_theme_font_size("font_size")
			).x
			_expect(title_width <= title.size.x + 1.0, "Card title '%s' overflowed its title area." % title.text)
		if rules != null and rules.visible and stats != null and stats.visible:
			_expect(rules.position.y + rules.size.y <= stats.position.y + 1.0, "The attack/health pill overlapped the rules text.")
			var stats_label := child.find_child("CardStats", true, false) as Label
			if stats_label != null:
				var stats_height := stats_label.get_theme_font("font").get_height(stats_label.get_theme_font_size("font_size"))
				_expect(stats_height <= stats_label.size.y + 1.0, "The attack/health numbers were vertically squashed.")
		if child.size.x < 130.0:
			var compact_rules := child.find_child("CardRules", true, false) as Label
			_expect(compact_rules != null and not compact_rules.visible, "Compact cards still displayed unreadable rules text.")

	var preview: Image = null
	if DisplayServer.get_name() != "headless":
		preview = root.get_texture().get_image()
	if preview != null:
		_expect(preview.save_png(PREVIEW_PATH) == OK, "Could not save the card redesign preview.")

	if failed:
		quit(1)
		return
	print("Card frame redesign smoke test passed." + (" Preview: " + PREVIEW_PATH if preview != null else ""))
	quit(0)


func _find_card(cards: Array, preferred_id: String, card_type: String, require_dual: bool) -> Dictionary:
	if preferred_id != "":
		for card in cards:
			if String(card.get("id", "")) == preferred_id:
				return card
	for card in cards:
		if String(card.get("card_type", "")) != card_type:
			continue
		var affinities: Array = card.get("archetypes", [])
		if require_dual != (affinities.size() == 2):
			continue
		return card
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
