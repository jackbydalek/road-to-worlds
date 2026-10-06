extends Button

## Editable printed-paper packaging. No generated bitmap or gameplay state.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
var pack_kind := "enemy"
var card_count := 3
var opened_remnant := false

func _ready() -> void:
	custom_minimum_size = Vector2(300, 112) if opened_remnant else Vector2(285, 390)
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_meta("asset_origin", "native_ui")
	set_meta("ui_button_style_exempt", true)
	if opened_remnant:
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited, resized]:
		event.connect(queue_redraw)
	queue_redraw()

func configure(kind: String, count: int) -> void:
	pack_kind = kind
	card_count = count
	tooltip_text = "Open your %d-card reward pack" % card_count
	queue_redraw()

func _draw() -> void:
	if opened_remnant:
		_draw_opened_wrapper()
		return
	var tint := PALETTE.PEACH_MINT if pack_kind == "mini_boss" else PALETTE.PEACH_TABLE if pack_kind == "final_boss" else PALETTE.AFFINITY_SWEET.lerp(PALETTE.PEACH_PAPER, 0.6)
	var edge := PALETTE.PEACH_TEAL if has_focus() or is_hovered() else PALETTE.PEACH_INK
	var scale_to_fit := size / Vector2(285, 390)
	draw_set_transform(Vector2.ZERO, 0, scale_to_fit)
	SKETCH.paper(self, Rect2(20, 6, 245, 378), PALETTE.PEACH_PAPER, edge, true, 2.2)
	SKETCH.paper(self, Rect2(24, 32, 237, 326), tint, edge, false, 1.7)
	for x in range(28, 259, 9):
		SKETCH.line(self, Vector2(x, 13), Vector2(x, 26), PALETTE.PEACH_EDGE, 0.9)
		SKETCH.line(self, Vector2(x, 365), Vector2(x, 378), PALETTE.PEACH_EDGE, 0.9)
	_center_text("SEE YOU AT", 70, 16)
	_center_text("LOCALS", 111, 39)
	SKETCH.line(self, Vector2(54, 126), Vector2(231, 126), edge, 1.5)
	# A small printed fan echoes the real card rewards inside.
	for i in range(3):
		draw_set_transform(Vector2(99 + i * 43, 174 + (0 if i == 1 else 12)) * scale_to_fit, (i - 1) * 0.15, scale_to_fit)
		SKETCH.paper(self, Rect2(-37, -14, 74, 104), PALETTE.PEACH_PAPER, edge, false, 1.8)
		draw_circle(Vector2(0, 35), 16, PALETTE.PEACH_TEAL, true, -1, true)
		draw_string(FONT, Vector2(-8, 43), "✦", HORIZONTAL_ALIGNMENT_LEFT, 24, 22, PALETTE.PEACH_PAPER)
	draw_set_transform(Vector2.ZERO, 0, scale_to_fit)
	_center_text("SECOND HELPINGS" if pack_kind == "week_pack" else "CHAMPION PACK" if pack_kind == "final_boss" else "TOP CUT PACK" if pack_kind == "mini_boss" else "ROUND PACK", 298, 21)
	_center_text("%d CARDS INSIDE" % card_count, 331, 15)
	if has_focus():
		SKETCH.line(self, Vector2(78, 345), Vector2(207, 345), edge, 2.5)

func _center_text(value: String, baseline: float, font_size: int) -> void:
	draw_string(FONT, Vector2(24, baseline), value, HORIZONTAL_ALIGNMENT_CENTER, 237, font_size, PALETTE.PEACH_INK)


func _draw_opened_wrapper() -> void:
	# The opened paper stays beside the choices; labels/counts are live drawing.
	var torn_edge := PackedVector2Array([
		Vector2(9, 9), Vector2(31, 16), Vector2(size.x - 42, 16),
		Vector2(size.x - 21, 5), Vector2(size.x - 27, 20), Vector2(size.x - 8, 16),
		Vector2(size.x - 19, 32), Vector2(size.x - 9, 43), Vector2(size.x - 19, 56),
		Vector2(size.x - 8, 69), Vector2(size.x - 21, 80), Vector2(size.x - 9, size.y - 7),
		Vector2(size.x - 38, size.y - 17), Vector2(29, size.y - 17), Vector2(8, size.y - 6),
		Vector2(14, size.y - 26), Vector2(7, size.y - 36), Vector2(15, size.y - 49),
		Vector2(7, 49), Vector2(14, 35), Vector2(7, 24), Vector2(9, 9)
	])
	draw_set_transform(Vector2(0, 4))
	draw_colored_polygon(torn_edge, Color(PALETTE.PEACH_INK, 0.16))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(torn_edge, PALETTE.PEACH_PAPER)
	draw_polyline(torn_edge, PALETTE.PEACH_INK, 1.4, true)
	# An empty opening and folded-back lip distinguish it from the sealed pack.
	draw_colored_polygon(PackedVector2Array([Vector2(size.x - 42, 17), Vector2(size.x - 27, 27), Vector2(size.x - 33, size.y - 20), Vector2(size.x - 46, size.y - 17)]), PALETTE.PEACH_PAPER_MUTED.darkened(0.13))
	for y in range(18, int(size.y) - 15, 9):
		SKETCH.line(self, Vector2(18, y), Vector2(28, y + 3), PALETTE.PEACH_EDGE, 0.8)
		SKETCH.line(self, Vector2(size.x - 27, y + 2), Vector2(size.x - 16, y), PALETTE.PEACH_EDGE, 0.8)
	SKETCH.line(self, Vector2(35, 17), Vector2(30, size.y - 17), PALETTE.PEACH_EDGE, 1.1)
	SKETCH.line(self, Vector2(size.x - 35, 18), Vector2(size.x - 30, size.y - 17), PALETTE.PEACH_EDGE, 1.1)
	draw_string(FONT, Vector2(32, 34), "SEE YOU AT", HORIZONTAL_ALIGNMENT_CENTER, size.x - 64, 12, PALETTE.PEACH_INK)
	draw_string(FONT, Vector2(32, 63), "LOCALS", HORIZONTAL_ALIGNMENT_CENTER, size.x - 64, 29, PALETTE.PEACH_INK)
	var pack_label := "SECOND HELPINGS" if pack_kind == "week_pack" else "CHAMPION" if pack_kind == "final_boss" else "TOP CUT" if pack_kind == "mini_boss" else "ROUND REWARD"
	draw_string(FONT, Vector2(32, 88), "%s · %d CARDS" % [pack_label, card_count], HORIZONTAL_ALIGNMENT_CENTER, size.x - 64, 13, PALETTE.PEACH_INK_SOFT)
