extends Control

## Native deckbox artwork, shared by the prize table, compact hub and battle.
## The parent owns input, live descriptions and selection; this draws no rules.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const DESIGN_SIZE := Vector2(300, 260)

var deckbox: Dictionary = {}
var selected := false
var _motion: Tween
var _lift := 0.0:
	set(value):
		_lift = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(value: Dictionary) -> void:
	deckbox = value.duplicate(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("deckbox_id", String(deckbox.get("id", "")))
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	if is_instance_valid(_motion):
		_motion.kill()
	var target := 11.0 if value else 0.0
	if not is_inside_tree() or bool(get_tree().root.get_meta("reduced_motion", false)):
		_lift = target
	else:
		_motion = create_tween()
		_motion.tween_property(self, "_lift", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var origin := (size - DESIGN_SIZE * factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	var id := String(deckbox.get("id", ""))
	var shape := Rect2(46, 78, 216, 154)
	var fill := PALETTE.PEACH_MINT
	match id:
		"basic":
			shape = Rect2(72, 57, 161, 177)
			fill = PALETTE.PEACH_TEAL
		"loyal_regular":
			shape = Rect2(71, 49, 163, 184)
			fill = PALETTE.PEACH_TABLE
		"extra_pocket":
			shape = Rect2(38, 82, 226, 152)
			fill = PALETTE.PEACH_TEAL
		"pepper_punch":
			shape = Rect2(68, 58, 176, 175)
			fill = PALETTE.PEACH_TABLE
		"padded_picnic":
			shape = Rect2(44, 84, 214, 148)
		"chefs_edge":
			shape = Rect2(72, 44, 160, 189)
			fill = PALETTE.PEACH_TEAL
		"oven_mitt":
			shape = Rect2(40, 82, 222, 150)
			fill = PALETTE.PEACH_TABLE
		"leftovers":
			shape = Rect2(44, 99, 218, 133)
			fill = PALETTE.PEACH_PAPER_MUTED
		"tip_jar":
			shape = Rect2(72, 57, 161, 177)
			fill = PALETTE.PEACH_TABLE
		"thermos":
			shape = Rect2(90, 42, 126, 190)
			fill = PALETTE.PEACH_TEAL
	var shadow := Rect2(shape.position + Vector2(-8, shape.size.y - 8), Vector2(shape.size.x + 10, 18))
	SKETCH.paper(self, shadow, Color(PALETTE.PEACH_INK, 0.17), Color.TRANSPARENT, false)
	draw_set_transform(origin - Vector2(0, _lift * factor), 0.0, Vector2.ONE * factor)
	var depth := Vector2(-20, -17)
	_polygon(PackedVector2Array([shape.position + depth, shape.position, Vector2(shape.position.x, shape.end.y), Vector2(shape.position.x, shape.end.y) + depth]), fill.lerp(PALETTE.PEACH_INK, 0.22))
	_polygon(PackedVector2Array([shape.position + depth, Vector2(shape.end.x, shape.position.y) + depth, Vector2(shape.end.x, shape.position.y), shape.position]), fill.lerp(PALETTE.PEACH_PAPER, 0.22))
	SKETCH.paper(self, shape, fill, PALETTE.PEACH_INK, false, 2.1)
	if id == "big_lunch":
		_draw_lunch(shape, selected)
	else:
		var lid_fill := fill if id in ["basic", "extra_pocket", "thermos"] else PALETTE.PEACH_PAPER
		SKETCH.paper(self, Rect2(shape.position - Vector2(1, 6), Vector2(shape.size.x + 2, 53)), lid_fill, PALETTE.PEACH_INK, true, 2.0)
		SKETCH.line(self, shape.position + Vector2(12, 35), shape.position + Vector2(shape.size.x - 12, 35), Color(PALETTE.PEACH_INK, 0.20), 1.0)
	_draw_detail(id, shape, fill, factor)
	_stitches(shape, fill)
	draw_set_transform(Vector2.ZERO)

func _draw_lunch(rect: Rect2, open: bool) -> void:
	if open:
		_polygon(PackedVector2Array([rect.position + Vector2(-18, -51), rect.position + Vector2(rect.size.x - 21, -64), rect.position + Vector2(rect.size.x + 1, -22), rect.position + Vector2(3, -9)]), PALETTE.PEACH_PAPER)
		SKETCH.paper(self, Rect2(rect.position + Vector2(8, -8), Vector2(rect.size.x - 16, 24)), PALETTE.PEACH_MAT, PALETTE.PEACH_INK, false, 1.4)
		for index in range(4):
			SKETCH.paper(self, Rect2(rect.position + Vector2(18 + index * 3, -17 + index * 5), Vector2(rect.size.x - 39, 11)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.0)
	else:
		SKETCH.paper(self, Rect2(rect.position - Vector2(1, 9), Vector2(rect.size.x + 2, 49)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 2.0)
	_heart(rect.get_center() + Vector2(0, 15), 19, PALETTE.PEACH_TEAL)

func _draw_detail(id: String, rect: Rect2, fill: Color, factor: float) -> void:
	var middle := rect.get_center()
	match id:
		"basic":
			for index in range(3):
				var offset := Vector2(-25 + index * 9, -9 + index * 7)
				SKETCH.paper(self, Rect2(middle + offset, Vector2(42, 57)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.4)
			draw_circle(middle + Vector2(14, 32), 7, PALETTE.PEACH_TEAL)
		"loyal_regular":
			SKETCH.paper(self, Rect2(rect.position + Vector2(30, 77), Vector2(103, 78)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 1.5)
			if factor > 0.35:
				draw_string(FONT, rect.position + Vector2(40, 99), "LOCALS", HORIZONTAL_ALIGNMENT_CENTER, 82, 14, PALETTE.PEACH_INK)
			for index in range(3):
				draw_circle(rect.position + Vector2(53 + index * 26, 114), 5, PALETTE.PEACH_TEAL)
			_pocket(Rect2(rect.position + Vector2(22, 125), Vector2(119, 52)), fill)
		"extra_pocket":
			SKETCH.paper(self, Rect2(rect.position + Vector2(54, 66), Vector2(69, 64)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.5)
			SKETCH.paper(self, Rect2(rect.position + Vector2(109, 72), Vector2(57, 59)), PALETTE.PEACH_TABLE, PALETTE.PEACH_INK, false, 1.5)
			_pocket(Rect2(rect.position + Vector2(40, 89), Vector2(147, 54)), PALETTE.PEACH_MINT)
		"padded_picnic", "oven_mitt":
			for index in range(1, 5):
				var x := rect.position.x + 18 + index * 36
				SKETCH.line(self, Vector2(x, rect.position.y + 60), Vector2(x - 20, rect.end.y - 12), Color(PALETTE.PEACH_INK, 0.24), 1.1)
			for y in range(int(rect.position.y + 74), int(rect.end.y - 8), 26):
				SKETCH.line(self, Vector2(rect.position.x + 15, y), Vector2(rect.end.x - 15, y + 4), Color(PALETTE.PEACH_INK, 0.20), 1.1)
			SKETCH.paper(self, Rect2(middle + Vector2(-22, -1), Vector2(44, 30)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.4)
			_plus(middle + Vector2(0, 14), 9, PALETTE.PEACH_TEAL)
		"pepper_punch":
			SKETCH.paper(self, Rect2(middle + Vector2(-43, -7), Vector2(86, 61)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.5)
			_polygon(PackedVector2Array([middle + Vector2(5, -1), middle + Vector2(-19, 23), middle + Vector2(-2, 23), middle + Vector2(-9, 45), middle + Vector2(21, 14), middle + Vector2(4, 14)]), PALETTE.PEACH_TEAL)
		"chefs_edge":
			_polygon(PackedVector2Array([rect.position + Vector2(24, 56), rect.position + Vector2(56, 56), rect.position + Vector2(135, 177), rect.position + Vector2(102, 177)]), PALETTE.PEACH_MINT)
			SKETCH.paper(self, Rect2(middle + Vector2(-23, 2), Vector2(46, 41)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.3)
			_plus(middle + Vector2(0, 22), 11, PALETTE.PEACH_TEAL)
		"leftovers":
			SKETCH.line(self, Vector2(rect.position.x + 5, rect.position.y + 88), Vector2(rect.end.x - 5, rect.position.y + 88), PALETTE.PEACH_INK, 2.0)
			SKETCH.paper(self, Rect2(middle + Vector2(-17, -11), Vector2(34, 49)), PALETTE.PEACH_TEAL, PALETTE.PEACH_INK, false, 1.6)
			_heart(middle + Vector2(0, 14), 9, PALETTE.PEACH_PAPER)
		"tip_jar":
			SKETCH.paper(self, Rect2(rect.position + Vector2(32, 75), Vector2(98, 86)), PALETTE.PEACH_MINT, PALETTE.PEACH_INK, false, 1.6)
			for offset in [Vector2(-17, 37), Vector2(14, 31), Vector2(-1, 51)]:
				draw_circle(middle + offset, 15, PALETTE.PEACH_PAPER)
				draw_arc(middle + offset, 15, 0, TAU, 24, PALETTE.PEACH_INK, 1.5, true)
			SKETCH.paper(self, Rect2(rect.position + Vector2(50, 12), Vector2(61, 8)), PALETTE.PEACH_MAT, PALETTE.PEACH_INK, false, 1.1)
		"thermos":
			SKETCH.paper(self, Rect2(rect.position + Vector2(0, 65), Vector2(rect.size.x, 17)), PALETTE.PEACH_MINT, PALETTE.PEACH_INK, false, 1.2)
			SKETCH.paper(self, Rect2(rect.position + Vector2(0, 147), Vector2(rect.size.x, 17)), PALETTE.PEACH_MINT, PALETTE.PEACH_INK, false, 1.2)
			SKETCH.paper(self, Rect2(middle + Vector2(-17, -4), Vector2(34, 41)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, false, 1.3)
			_plus(middle + Vector2(0, 17), 9, PALETTE.PEACH_TEAL)
		"big_lunch":
			pass
		_:
			draw_circle(middle + Vector2(0, 20), 17, PALETTE.PEACH_TEAL)

func _pocket(rect: Rect2, fill: Color) -> void:
	SKETCH.paper(self, rect, fill, PALETTE.PEACH_INK, false, 1.7)
	_stitches(rect, fill)

func _stitches(rect: Rect2, fill: Color) -> void:
	var ink := fill.lerp(PALETTE.PEACH_INK, 0.43)
	for y in range(int(rect.position.y + 52), int(rect.end.y - 8), 13):
		draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.position.x + 8, y + 5), ink, 0.9, true)
		draw_line(Vector2(rect.end.x - 8, y), Vector2(rect.end.x - 8, y + 5), ink, 0.9, true)
	for x in range(int(rect.position.x + 14), int(rect.end.x - 9), 13):
		draw_line(Vector2(x, rect.end.y - 8), Vector2(x + 5, rect.end.y - 8), ink, 0.9, true)

func _heart(center: Vector2, radius: float, fill: Color) -> void:
	var points := PackedVector2Array()
	for index in range(49):
		var angle := float(index) / 48.0 * TAU
		var x := 16.0 * pow(sin(angle), 3)
		var y := -(13.0 * cos(angle) - 5.0 * cos(2 * angle) - 2.0 * cos(3 * angle) - cos(4 * angle))
		points.append(center + Vector2(x, y) * radius / 16.0)
	draw_colored_polygon(points, fill)

func _plus(center: Vector2, radius: float, fill: Color) -> void:
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), fill, 4, true)
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), fill, 4, true)

func _polygon(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, PALETTE.PEACH_INK, 2.0, true)
