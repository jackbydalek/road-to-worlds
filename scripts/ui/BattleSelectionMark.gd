extends Control

## Flat printed selection mark; the live card remains the inspection source.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center + Vector2(1, 2), size.x * 0.48, Color(PALETTE.PEACH_INK, 0.22))
	draw_circle(center, size.x * 0.46, PALETTE.PEACH_TEAL)
	draw_arc(center, size.x * 0.46, 0, TAU, 32, PALETTE.PEACH_INK, 1.4, true)
	draw_polyline(PackedVector2Array([size * Vector2(0.27, 0.51), size * Vector2(0.44, 0.68), size * Vector2(0.75, 0.33)]), PALETTE.PEACH_PAPER, 2.8, true)
