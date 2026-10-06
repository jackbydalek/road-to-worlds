extends Control
class_name StarterSelectionSurface

## Matte painted labels for starter tags and the welcome surface.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
var accent := PALETTE.PEACH_MINT
var show_tape := true
var use_cozy_panel := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 20 or size.y < 20:
		return
	var paper_rect := Rect2(2, 3, size.x - 6, size.y - 8)
	SHAPES.draw_surface(self, paper_rect, PALETTE.PEACH_PAPER, 21)
	if show_tape:
		SHAPES.draw_surface(self, Rect2(23, 0, 48, 12), accent, 23, 3)
