extends Control
class_name TitleBackgroundPattern

## Editable tabletop drawing shared by the title and starter-selection screens.
## All props, lettering and contours are native; no generated raster is used.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

var menu_sheet_rect := Rect2():
	set(value):
		menu_sheet_rect = value
		queue_redraw()
var show_title_details := true:
	set(value):
		show_title_details = value
		queue_redraw()
var menu_only := false:
	set(value):
		menu_only = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 2 or size.y < 2:
		return
	if menu_only:
		if menu_sheet_rect.has_area():
			SKETCH.paper(self, menu_sheet_rect, PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 1.7)
		return
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.PEACH_TABLE)
	for mark in [0.12, 0.41, 0.73, 0.92]:
		SKETCH.line(self, Vector2(size.x * mark, 14), Vector2(size.x * mark + 86, 13), Color(PALETTE.PEACH_INK, 0.15))
		SKETCH.line(self, Vector2(size.x * mark - 30, size.y - 13), Vector2(size.x * mark + 60, size.y - 15), Color(PALETTE.PEACH_INK, 0.15))
	var mat := Rect2(Vector2(25, 25), size - Vector2(50, 50))
	SKETCH.paper(self, mat, PALETTE.PEACH_TEAL, PALETTE.PEACH_INK, true, 2.1)
	# A few broken perimeter stitches suggest cloth without a full-screen weave.
	for point in [Vector2(43, 56), Vector2(44, size.y - 64), Vector2(size.x - 52, 70), Vector2(size.x - 54, size.y - 74)]:
		SKETCH.line(self, point, point + Vector2(0, 12), Color(PALETTE.PEACH_MINT, 0.55), 1.0)
	if not show_title_details:
		return
	if size.x >= 1000.0:
		_draw_table_details()
	if menu_sheet_rect.has_area():
		SKETCH.paper(self, menu_sheet_rect, PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 1.7)
	var footer := "Good company. Great games. One more round."
	var font_size := 16 if size.x < 1000.0 else 18
	var text_width := FONT.get_string_size(footer, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left := size.x * 0.085 if size.x >= 1000.0 else (size.x - text_width) * 0.5
	draw_string(FONT, Vector2(left, size.y - 67), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PALETTE.PEACH_PAPER)
	if size.x >= 1000.0:
		SKETCH.line(self, Vector2(left + text_width - 112, size.y - 60), Vector2(left + text_width - 10, size.y - 62), PALETTE.PEACH_MINT, 1.7)


func _draw_table_details() -> void:
	var scale_factor := minf(size.y / 900.0, 1.1)
	# A little open-play slip at the edge, clear of the title and menu targets.
	draw_set_transform(Vector2(size.x * 0.105, 26), -0.09, Vector2.ONE * scale_factor)
	SKETCH.paper(self, Rect2(-52, -48, 170, 114), PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true)
	draw_string(FONT, Vector2(-33, -2), "SATURDAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PALETTE.PEACH_INK)
	draw_string(FONT, Vector2(-33, 23), "OPEN PLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PALETTE.PEACH_INK)
	SKETCH.line(self, Vector2(-33, 35), Vector2(94, 34), PALETTE.PEACH_TEAL, 1.6)
	draw_set_transform(Vector2.ZERO)
	# Top-down cup, drawn as a few flat shapes with one contact shadow.
	var cup := Vector2(size.x * 0.85, size.y * 0.21)
	var radius := 67.0 * scale_factor
	draw_circle(cup + Vector2(4, 8), radius, Color(PALETTE.PEACH_INK, 0.22), true, -1, true)
	draw_circle(cup, radius, PALETTE.PEACH_MINT, true, -1, true)
	draw_circle(cup, radius, PALETTE.PEACH_INK, false, 1.8, true)
	var handle := cup + Vector2(radius * 0.72, -radius * 0.18)
	draw_circle(handle, radius * 0.31, PALETTE.PEACH_PAPER, true, -1, true)
	draw_circle(handle, radius * 0.31, PALETTE.PEACH_INK, false, 1.8, true)
	draw_circle(handle, radius * 0.16, PALETTE.PEACH_TEAL, true, -1, true)
	draw_circle(cup + Vector2(-6, -9), radius * 0.76, PALETTE.PEACH_PAPER, true, -1, true)
	draw_circle(cup + Vector2(-6, -9), radius * 0.76, PALETTE.PEACH_INK, false, 2.0, true)
	draw_circle(cup + Vector2(-6, -11), radius * 0.55, PALETTE.PEACH_INK, true, -1, true)
	draw_arc(cup + Vector2(-6, -11), radius * 0.59, PI * 1.1, PI * 1.6, 16, PALETTE.PEACH_TABLE, 2.2, true)
