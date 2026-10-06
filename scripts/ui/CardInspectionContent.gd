extends RefCounted
## One face size and keyword guide for every place a player reads a card.
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const CARD_SIZE := Vector2(320, 454)
const GUIDE_WIDTH := 280.0
const KEYWORDS := {
	"special_serve": {"title": "Special Serve", "body": "An alternate way to summon this Meal by paying its printed Special Serve condition. It does not use your normal Meal allowance. You can Special Serve any number of times per turn. These Ingredients do not need to be recipe ready unless the card says so."},
	"bodyguard": {"title": "Bodyguard", "body": "Prevents all excess combat damage from this unit reaching your Chef, including damage from Piercing."},
	"stalwart": {"title": "Stalwart", "body": "This card can attack the opposing Chef even while they control Plated cards."},
	"piercing": {"title": "Piercing", "body": "Excess combat damage reaches the opposing Chef even through a Defending unit. Bodyguard still prevents it."},
	"taunt": {"title": "Taunt", "body": "While a Taunt unit is Plated, attackers must target a Taunt before other cards or the Chef. The attacker chooses if there are several."},
	"hand_trap": {"title": "Handtrap", "body": "Discard this card from your hand to perform its action in response to an opponent's action."},
}


static func make_face(card: Dictionary, card_size: Vector2 = CARD_SIZE, difficulty: String = "white") -> Control:
	var face := CARD_FACE.new()
	face.name = "InspectedCardFace"
	face.configure(card, difficulty, true, false)
	face.custom_minimum_size = card_size
	face.size = card_size
	face.set_meta("shared_card_inspection", true)
	return face


static func known_keywords(card: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for value in card.get("keywords", []):
		var key := String(value)
		if KEYWORDS.has(key) and not result.has(key):
			result.append(key)
	if card.has("special_serve") and not result.has("special_serve"):
		result.append("special_serve")
	return result


static func make_glossary(card: Dictionary, width: float = GUIDE_WIDTH, prefix: String = "CardKeyword") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "CardKeywordGuide"
	panel.custom_minimum_size.x = width
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_sketch_paper(panel, PALETTE.PEACH_PAPER_MUTED, Vector4(20, 18, 20, 18))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	body.add_child(UI.make_label("Keyword guide", "eyebrow", PALETTE.PEACH_INK_SOFT))
	for key in known_keywords(card):
		var entry := VBoxContainer.new()
		entry.name = "%s_%s" % [prefix, key]
		entry.add_theme_constant_override("separation", 5)
		body.add_child(entry)
		var title := UI.make_label(String(KEYWORDS[key].title), "section", PALETTE.PEACH_INK)
		title.name = "%sTitle_%s" % [prefix, key]
		entry.add_child(title)
		var description := UI.make_label(String(KEYWORDS[key].body), "small", PALETTE.PEACH_INK_SOFT.darkened(0.08))
		description.name = "%sBody_%s" % [prefix, key]
		entry.add_child(description)
	_ignore_mouse(panel)
	return panel


static func make_content(card: Dictionary, difficulty: String = "white", card_size: Vector2 = CARD_SIZE, prefix: String = "CardKeyword") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "SharedCardInspectionContent"
	row.add_theme_constant_override("separation", 16)
	row.add_child(make_face(card, card_size, difficulty))
	if not known_keywords(card).is_empty():
		row.add_child(make_glossary(card, GUIDE_WIDTH, prefix))
	_ignore_mouse(row)
	return row


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = PALETTE.PEACH_TEAL
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.expand_margin_left = 3
	style.expand_margin_right = 3
	style.expand_margin_top = 3
	style.expand_margin_bottom = 3
	return style


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


static func preview_style() -> StyleBoxFlat:
	return UI.paper_style(PALETTE.PEACH_PAPER, 12)


static func apply_sketch_paper(panel: Control, fill: Color, margins: Vector4 = Vector4(12, 12, 12, 12), ink: Color = PALETTE.PEACH_INK) -> void:
	# The StyleBox only reserves content padding. Ink is drawn behind the child
	# controls, so the loose edge never changes reading space or pointer targets.
	var spacing := StyleBoxFlat.new()
	spacing.bg_color = Color.TRANSPARENT
	spacing.border_color = Color.TRANSPARENT
	spacing.set_border_width_all(1)
	spacing.content_margin_left = margins.x
	spacing.content_margin_top = margins.y
	spacing.content_margin_right = margins.z
	spacing.content_margin_bottom = margins.w
	panel.add_theme_stylebox_override("panel", spacing)
	panel.set_meta("warm_sketch_paper_fill", fill)
	panel.set_meta("warm_sketch_paper_ink", ink)
	if not panel.has_meta("warm_sketch_paper_bound"):
		panel.set_meta("warm_sketch_paper_bound", true)
		panel.draw.connect(_draw_sketch_paper.bind(panel))
		panel.resized.connect(panel.queue_redraw)
	panel.queue_redraw()


static func _draw_sketch_paper(panel: Control) -> void:
	var fill: Color = panel.get_meta("warm_sketch_paper_fill", PALETTE.PEACH_PAPER)
	var ink: Color = panel.get_meta("warm_sketch_paper_ink", PALETTE.PEACH_INK)
	SKETCH.paper(panel, Rect2(Vector2(1, 1), panel.size - Vector2(3, 4)), fill, ink)
