extends Control
class_name BattleMatchHudSurface

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PAINT := preload("res://scripts/ui/PaintedUiShapes.gd")

var fill_color := PALETTE.PEACH_PAPER
var accent_color := PALETTE.PEACH_TEAL
var compact_profile := false
var portrait_on_right := false
var attack_target := false
var header_height := 64.0


func configure(fill: Color, accent: Color, _dark := true, _inner_keyline := false) -> void:
	fill_color = fill
	accent_color = accent
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 24.0 or size.y < 20.0:
		return
	if compact_profile:
		# Name, exact total and meter sit on one calm painted shape. The
		# portrait remains an inspectable target without another enclosing rim.
		PAINT.draw_surface(self, Rect2(Vector2.ZERO, Vector2(size.x, 64)), fill_color, 41, 9)
		if size.y > 80.0:
			PAINT.draw_surface(self, Rect2(0, 68, size.x, size.y - 68), fill_color, 42, 7)
		if attack_target:
			PAINT.draw_focus(self, Rect2(Vector2(-3, -3), size + Vector2(6, 6)), PALETTE.PEACH_TEAL, 41)
		return
	if name == "EndTurnDock":
		# One backing for turn ownership + Meal availability, followed by the
		# primary action. No stacked pill, paper label and outlined button.
		PAINT.draw_surface(self, Rect2(0, 0, size.x, header_height), fill_color, 57, 9)
		return
	PAINT.draw_surface(self, Rect2(Vector2.ZERO, size), fill_color, 13, 9)
