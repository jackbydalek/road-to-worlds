extends Control
class_name CardMedallion

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var primary_color: Color = PALETTE.PEACH_TABLE
var secondary_color: Color = Color.TRANSPARENT
var symbol_text := ""
var symbol_font: Font = ThemeDB.fallback_font


func configure(
	accent: Color,
	secondary_accent: Color,
	symbol: String,
	font: Font
) -> void:
	primary_color = accent
	secondary_color = secondary_accent
	symbol_text = symbol
	symbol_font = font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var diameter := minf(size.x, size.y)
	if diameter < 12.0:
		return
	var center := size * 0.5
	var radius := diameter * 0.48
	var shadow_offset := Vector2(0.0, maxf(1.0, diameter * 0.045))

	draw_circle(center + shadow_offset, radius, Color(PALETTE.PEACH_INK, 0.16), true, -1.0, true)
	draw_circle(center, radius, PALETTE.PEACH_INK, true, -1.0, true)
	draw_circle(center, radius * 0.91, primary_color, true, -1.0, true)
	draw_circle(center, radius * 0.79, PALETTE.PEACH_PAPER, true, -1.0, true)
	draw_arc(center, radius * 0.79, 0.0, TAU, 64, Color(PALETTE.PEACH_INK, 0.40), maxf(1.0, diameter * 0.015), true)

	if secondary_color.a > 0.0:
		draw_arc(center, radius * 0.86, -PI * 0.5, PI * 0.5, 32, secondary_color, maxf(2.0, diameter * 0.055), true)

	if symbol_text.is_empty():
		return

	var font_size := clampi(int(round(diameter * (0.25 if secondary_color.a > 0.0 else 0.31))), 10, 24)
	var text_size := symbol_font.get_string_size(symbol_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_position := Vector2(center.x - text_size.x * 0.5, center.y + text_size.y * 0.34)
	draw_string(
		symbol_font,
		text_position,
		symbol_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		PALETTE.PEACH_INK
	)
