extends Button
class_name StarterDeckBox

## Native retail paperboard around an unchanged CardFace. Difficulty affects
## only the card rim; package colors and affiliation are independent.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const AFFINITY := preload("res://scripts/AffinityVisuals.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const DESIGN_SIZE := Vector2(300, 600)
const WINDOW_RECT := Rect2(18, 173, 264, 378)
const CARD_RECT := Rect2(27, 182, 246, 359)

var starter_id := "spicy"
var affiliation_color := PALETTE.AFFINITY_SPICY
var package_color := PALETTE.PEACH_TABLE
var border_color := Color("#090909")
var difficulty_id := "white"
var card_data: Dictionary = {}
var face: CardFace
var window: Control
var border_overlay: Control
var selected := false:
	set(value):
		selected = value
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		event.connect(queue_redraw)
	window = Control.new()
	window.name = "CardWindow"
	window.position = WINDOW_RECT.position
	window.size = WINDOW_RECT.size
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(window)
	face = CARD_FACE.new()
	face.name = "StarterCardFace"
	window.add_child(face)
	border_overlay = Control.new()
	border_overlay.name = "DifficultyCardBorder"
	border_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(border_overlay)
	border_overlay.draw.connect(_draw_card_border)
	_refresh_face()

func configure(id: String, data: Dictionary, accent: Color, paper_tint: Color) -> void:
	starter_id = id
	card_data = data.duplicate(true)
	affiliation_color = accent
	package_color = paper_tint
	text = "%s starter deck" % id.capitalize()
	accessibility_name = text
	tooltip_text = "Choose the %s starter deck" % id.capitalize()
	set_meta("starter_id", id)
	set_meta("cover_card_id", String(card_data.get("id", "")))
	_refresh_face()
	queue_redraw()

func set_difficulty(id: String, color: Color) -> void:
	difficulty_id = id
	border_color = color
	if is_instance_valid(face):
		face.set_meta("difficulty_id", id)
		border_overlay.set_meta("border_color", color)
		border_overlay.queue_redraw()

func _refresh_face() -> void:
	if not is_instance_valid(face) or card_data.is_empty():
		return
	face.configure(card_data, difficulty_id, false)
	face.custom_minimum_size = Vector2.ZERO
	face.position = CARD_RECT.position - WINDOW_RECT.position
	face.size = CARD_RECT.size
	border_overlay.position = face.position
	border_overlay.size = face.size
	_ignore_mouse(face)
	set_difficulty(difficulty_id, border_color)

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _draw_card_border() -> void:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = border_color
	style.set_border_width_all(5)
	style.set_corner_radius_all(10)
	style.anti_aliasing = true
	border_overlay.draw_style_box(style, Rect2(Vector2.ZERO, border_overlay.size))

func _draw() -> void:
	var side := package_color.lerp(PALETTE.PEACH_INK, 0.18)
	SKETCH.paper(self, Rect2(7, 50, 303, 548), Color(PALETTE.PEACH_INK, 0.22), Color.TRANSPARENT, false)
	_polygon(PackedVector2Array([Vector2(294, 44), Vector2(311, 55), Vector2(311, 597), Vector2(294, 587)]), side)
	_polygon(PackedVector2Array([Vector2(5, 584), Vector2(295, 584), Vector2(311, 597), Vector2(17, 597)]), side)
	SKETCH.paper(self, Rect2(34, 2, 232, 67), package_color, PALETTE.PEACH_INK, false, 1.9)
	SKETCH.paper(self, Rect2(119, 17, 62, 12), PALETTE.PEACH_MAT, PALETTE.PEACH_INK, false, 1.4)
	SKETCH.paper(self, Rect2(0, 43, 300, 547), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 2.0)
	draw_rect(Rect2(6, 51, 7, 529), package_color)
	draw_rect(Rect2(287, 51, 7, 529), package_color)
	_center_text("SEE YOU AT", 80, 13, PALETTE.PEACH_TEAL)
	_center_text("LOCALS", 119, 36, PALETTE.PEACH_TEAL)
	draw_circle(Vector2(265, 87), 18, affiliation_color, true, -1, true)
	draw_arc(Vector2(265, 87), 18, 0, TAU, 40, PALETTE.PEACH_INK, 1.7, true)
	draw_string(AFFINITY.SYMBOL_FONT, Vector2(250, 98), AFFINITY.symbol(starter_id), HORIZONTAL_ALIGNMENT_CENTER, 30, 27, PALETTE.PEACH_INK)
	_polygon(PackedVector2Array([Vector2(7, 139), Vector2(45, 139), Vector2(45, 172), Vector2(7, 172), Vector2(15, 155)]), side)
	_polygon(PackedVector2Array([Vector2(293, 139), Vector2(255, 139), Vector2(255, 172), Vector2(293, 172), Vector2(285, 155)]), side)
	SKETCH.paper(self, Rect2(23, 131, 254, 33), package_color, PALETTE.PEACH_INK, false, 1.6)
	_center_text("%s STARTER" % starter_id.to_upper(), 154, 16, PALETTE.PEACH_INK)
	SKETCH.paper(self, WINDOW_RECT, PALETTE.PEACH_MAT, PALETTE.PEACH_INK, false, 2.0)
	draw_string(FONT, Vector2(25, 577), "15 CARDS", HORIZONTAL_ALIGNMENT_LEFT, 100, 17, PALETTE.PEACH_INK)
	draw_string(FONT, Vector2(156, 577), "READY TO PLAY", HORIZONTAL_ALIGNMENT_RIGHT, 117, 12, PALETTE.PEACH_INK_SOFT)
	for y in range(185, 540, 19):
		SKETCH.line(self, Vector2(9, y), Vector2(9, y + 6), Color(PALETTE.PEACH_INK, 0.24), 0.8)
	if selected or has_focus() or is_hovered():
		var focus_style := StyleBoxFlat.new()
		focus_style.draw_center = false
		focus_style.border_color = PALETTE.PEACH_PAPER if has_focus() else PALETTE.PEACH_MINT
		focus_style.set_border_width_all(3)
		focus_style.set_corner_radius_all(9)
		draw_style_box(focus_style, Rect2(-7, 35, 323, 567))

func _center_text(copy: String, baseline: float, font_size: int, color: Color) -> void:
	draw_string(FONT, Vector2(24, baseline), copy, HORIZONTAL_ALIGNMENT_CENTER, 252, font_size, color)

func _polygon(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, PALETTE.PEACH_INK, 1.8, true)
