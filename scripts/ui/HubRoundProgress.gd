extends Control
## Small matte progress marks shared by the match readouts.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var current_round := 1
var bye_used := false
var total_rounds := 4

func configure(round_number: int, used: bool = false, rounds: int = 4) -> void:
	total_rounds = maxi(1, rounds)
	current_round = clampi(round_number, 1, total_rounds)
	bye_used = used
	tooltip_text = "Round %d of %d. %d completed." % [current_round, total_rounds, current_round - 1]
	queue_redraw()

func _draw() -> void:
	var step := size.x / float(total_rounds)
	var radius := minf(13.0, minf(size.y * 0.5 - 2.0, step * 0.3))
	var font := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
	var font_size := 13 if radius >= 10 else 11
	for index in range(total_rounds):
		var completed := index + 1 < current_round
		var current := index + 1 == current_round
		var center := Vector2((index + 0.5) * step, size.y * 0.5)
		if index < total_rounds - 1:
			draw_line(center + Vector2(radius + 5, 0), center + Vector2(step - radius - 5, 0), PALETTE.PEACH_MINT, 2.0, true)
		var fill := PALETTE.PEACH_HEALTH if completed else PALETTE.PEACH_TEAL if current else PALETTE.PEACH_MINT
		draw_circle(center, radius, fill, true, -1.0, true)
		if completed:
			draw_polyline(PackedVector2Array([center + Vector2(-4, 0), center + Vector2(-1, 3), center + Vector2(5, -4)]), PALETTE.PEACH_PAPER, 1.8, true)
		else:
			var label := str(index + 1)
			var text_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, center + Vector2(-text_width * 0.5, font.get_ascent(font_size) * 0.34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PALETTE.PEACH_PAPER if current else PALETTE.PEACH_INK)
