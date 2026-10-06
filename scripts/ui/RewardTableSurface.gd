extends Control

## The same flat cloth and quiet sewn edge as the battle mats, in screen space.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
var tabletop := false
var content_height := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 40 or size.y < 40:
		return
	if tabletop:
		SKETCH.paper(self, Rect2(Vector2(2, 2), size - Vector2(5, 7)), PALETTE.PEACH_TABLE, PALETTE.PEACH_INK, true, 1.5)
		var wood_ink := Color(PALETTE.PEACH_INK, 0.09)
		for y in range(68, int(size.y) - 20, 104):
			SKETCH.line(self, Vector2(8, y), Vector2(size.x - 10, y + 2), wood_ink, 1.0)
		return
	var cloth := Rect2(Vector2(2, 2), size - Vector2(5, 7))
	if content_height > 0.0 and content_height < cloth.size.y:
		cloth.position.y += (cloth.size.y - content_height) * 0.5
		cloth.size.y = content_height
	SKETCH.paper(self, cloth, PALETTE.PEACH_MAT, PALETTE.PEACH_INK, true, 2.0)
	var stitch := PALETTE.PEACH_MAT.lerp(PALETTE.PEACH_PRINT, 0.3)
	for x in range(20, int(size.x) - 20, 13):
		draw_line(Vector2(x, cloth.position.y + 12), Vector2(x + 5, cloth.position.y + 12), stitch, 0.9, true)
		draw_line(Vector2(x, cloth.end.y - 10), Vector2(x + 5, cloth.end.y - 10), stitch, 0.9, true)
	for y in range(int(cloth.position.y) + 21, int(cloth.end.y) - 19, 13):
		draw_line(Vector2(14, y), Vector2(14, y + 5), stitch, 0.9, true)
		draw_line(Vector2(size.x - 16, y), Vector2(size.x - 16, y + 5), stitch, 0.9, true)
