extends Control
class_name StarterSelectionSurface

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var accent: Color = PALETTE.AFFINITY_NEUTRAL:
	set(value):
		accent = value
		queue_redraw()
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var hovered := false:
	set(value):
		hovered = value
		queue_redraw()
var side := 0:
	set(value):
		side = value
		queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 2.0 or height <= 2.0:
		return
	var cut := minf(54.0, width * 0.13)
	var outer := _panel_polygon(width, height, cut, 0.0)
	draw_colored_polygon(outer, PALETTE.CARBON)
	var inner := _panel_polygon(width - 8.0, height - 8.0, maxf(8.0, cut - 4.0), 4.0)
	var inactive_fill := accent.lerp(PALETTE.STEEL, 0.68).darkened(0.18)
	var fill := accent.darkened(0.16) if selected else inactive_fill
	draw_colored_polygon(inner, fill)

	var stripe_fill := Color(PALETTE.COOL_WHITE, 0.16 if selected else 0.08)
	var stripe := PackedVector2Array([
		Vector2(cut + 18.0, 0.0),
		Vector2(minf(width, cut + 128.0), 0.0),
		Vector2(maxf(0.0, cut + 64.0), height),
		Vector2(maxf(0.0, cut - 30.0), height),
	])
	draw_colored_polygon(stripe, stripe_fill)

	if hovered and not selected:
		draw_colored_polygon(inner, Color(PALETTE.ELECTRIC_CYAN, 0.12))
	if selected:
		draw_polyline(PackedVector2Array(Array(outer) + [outer[0]]), PALETTE.ELECTRIC_CYAN, 3.0, true)
		draw_line(Vector2(cut + 12.0, height - 10.0), Vector2(width - cut - 12.0, height - 10.0), PALETTE.COOL_WHITE, 3.0, true)


func _panel_polygon(width: float, height: float, cut: float, inset: float) -> PackedVector2Array:
	if side < 0:
		return PackedVector2Array([
			Vector2(inset, inset),
			Vector2(width - cut, inset),
			Vector2(width, height - inset),
			Vector2(cut, height - inset),
		])
	if side > 0:
		return PackedVector2Array([
			Vector2(cut, inset),
			Vector2(width, inset),
			Vector2(width - cut, height - inset),
			Vector2(inset, height - inset),
		])
	return PackedVector2Array([
		Vector2(cut, inset),
		Vector2(width, inset),
		Vector2(width - cut, height - inset),
		Vector2(inset, height - inset),
	])
