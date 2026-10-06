extends Control
class_name StarterTableSurface

## Original native table drawing; no generated backdrop or package bitmap.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.PEACH_TABLE)
	for y in range(20, int(size.y), 119):
		SKETCH.line(self, Vector2(0, y), Vector2(size.x, y + 4), Color(PALETTE.PEACH_INK, 0.12), 1.0)
		SKETCH.line(self, Vector2(18, y + 8), Vector2(size.x * 0.31, y + 10), Color(PALETTE.PEACH_PAPER, 0.32), 1.0)
	var mat := Rect2(62, 154, size.x - 124, size.y - 222)
	SKETCH.paper(self, Rect2(mat.position + Vector2(3, 9), mat.size), Color(PALETTE.PEACH_INK, 0.21), Color.TRANSPARENT, false)
	SKETCH.paper(self, mat, PALETTE.PEACH_MAT, PALETTE.PEACH_INK, false, 2.4)
	var inner := mat.grow(-12)
	for x in range(int(inner.position.x), int(inner.end.x), 18):
		SKETCH.line(self, Vector2(x, inner.position.y), Vector2(x + 6, inner.position.y), Color(PALETTE.PEACH_PRINT, 0.5), 0.9)
		SKETCH.line(self, Vector2(x, inner.end.y), Vector2(x + 6, inner.end.y), Color(PALETTE.PEACH_PRINT, 0.5), 0.9)
	for y in range(int(inner.position.y), int(inner.end.y), 18):
		SKETCH.line(self, Vector2(inner.position.x, y), Vector2(inner.position.x, y + 6), Color(PALETTE.PEACH_PRINT, 0.5), 0.9)
		SKETCH.line(self, Vector2(inner.end.x, y), Vector2(inner.end.x, y + 6), Color(PALETTE.PEACH_PRINT, 0.5), 0.9)
	_draw_plant(Vector2(86, 105))
	_draw_drink(Vector2(size.x - 108, 89))
	_draw_scorepad(Vector2(63, size.y - 110))
	SKETCH.paper(self, Rect2(size.x - 176, size.y - 118, 153, 46), PALETTE.PEACH_MINT, PALETTE.PEACH_INK, true, 1.3)
	draw_string(FONT, Vector2(size.x - 167, size.y - 89), "GOOD GAMES", HORIZONTAL_ALIGNMENT_CENTER, 133, 17, PALETTE.PEACH_INK)

func _draw_plant(center: Vector2) -> void:
	for branch in [Vector2(-48, -35), Vector2(-18, -58), Vector2(23, -49), Vector2(52, -28), Vector2(28, -8)]:
		SKETCH.line(self, center, center + branch, PALETTE.PEACH_INK, 1.5)
		SKETCH.paper(self, Rect2(center + branch - Vector2(16, 9), Vector2(32, 18)), PALETTE.PEACH_MINT, PALETTE.PEACH_INK, false, 1.4)
	SKETCH.paper(self, Rect2(center - Vector2(29, 4), Vector2(58, 56)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 1.8)
	SKETCH.line(self, center + Vector2(-26, 9), center + Vector2(26, 10), PALETTE.PEACH_INK, 1.0)

func _draw_drink(center: Vector2) -> void:
	draw_circle(center + Vector2(3, 44), 36, Color(PALETTE.PEACH_INK, 0.13), true, -1, true)
	SKETCH.paper(self, Rect2(center - Vector2(27, 30), Vector2(54, 88)), PALETTE.PEACH_PAPER_MUTED, PALETTE.PEACH_INK, true, 1.6)
	SKETCH.paper(self, Rect2(center - Vector2(22, 7), Vector2(44, 53)), PALETTE.PEACH_TABLE, Color.TRANSPARENT, false)
	SKETCH.line(self, center + Vector2(9, 8), center + Vector2(20, -57), PALETTE.PEACH_INK, 2.2)
	SKETCH.line(self, center + Vector2(-19, -22), center + Vector2(19, -23), PALETTE.PEACH_INK, 1.2)

func _draw_scorepad(origin: Vector2) -> void:
	SKETCH.paper(self, Rect2(origin, Vector2(152, 88)), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 1.3)
	draw_string(FONT, origin + Vector2(13, 25), "OPEN PLAY", HORIZONTAL_ALIGNMENT_LEFT, 130, 14, PALETTE.PEACH_INK)
	for y in [37, 55, 73]:
		SKETCH.line(self, origin + Vector2(12, y), origin + Vector2(139, y), Color(PALETTE.PEACH_INK, 0.25), 0.8)
	SKETCH.line(self, origin + Vector2(110, 19), origin + Vector2(185, 85), PALETTE.PEACH_INK, 6.0)
	SKETCH.line(self, origin + Vector2(109, 18), origin + Vector2(180, 80), PALETTE.PEACH_PAPER_MUTED, 2.2)
