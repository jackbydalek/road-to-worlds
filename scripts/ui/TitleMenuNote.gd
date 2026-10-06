extends Control

## One quiet painted shape groups the title actions without a notebook frame.
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const P := preload("res://scripts/ui/GamePalette.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	SHAPES.draw_surface(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), P.PEACH_PAPER, 23, 12.0)
