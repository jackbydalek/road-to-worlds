extends Control
class_name UpgradedCardFoil

## Restrained, code-drawn foil treatment for upgraded cards. The overlay sits
## above the illustration and printed chassis but below all card typography so
## the premium finish never compromises rules or stat readability.

signal visual_changed

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const FRAME_INTERVAL := 1.0 / 18.0
const SWEEP_SECONDS := 4.2
const REVEAL_SWEEP_SECONDS := 0.72

var active := false
var accent_color := PALETTE.ELECTRIC_CYAN
var secondary_accent_color := PALETTE.INTERFACE_VIOLET
var phase := 0.0
var reveal_active := false
var reveal_phase := 0.0
var _elapsed := 0.0
var _frame_elapsed := 0.0
var _reveal_elapsed := 0.0


func configure(enabled: bool, accent: Color, secondary_accent: Color, seed: float = 0.0) -> void:
	active = enabled
	accent_color = accent
	secondary_accent_color = secondary_accent
	phase = fposmod(seed, 1.0)
	_elapsed = phase * SWEEP_SECONDS
	_frame_elapsed = 0.0
	reveal_active = false
	reveal_phase = 0.0
	_reveal_elapsed = 0.0
	visible = active
	set_process(active)
	queue_redraw()


func start_reveal_sweep() -> void:
	if not active:
		return
	reveal_active = true
	reveal_phase = 0.0
	_reveal_elapsed = 0.0
	visible = true
	set_process(true)
	queue_redraw()
	visual_changed.emit()


func _ready() -> void:
	name = "UpgradedCardFoil"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(active)
	resized.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	if not active or not is_visible_in_tree():
		return
	_elapsed = fmod(_elapsed + delta, SWEEP_SECONDS)
	if reveal_active:
		_reveal_elapsed += delta
		reveal_phase = clampf(_reveal_elapsed / REVEAL_SWEEP_SECONDS, 0.0, 1.0)
		if reveal_phase >= 1.0:
			reveal_active = false
	_frame_elapsed += delta
	if _frame_elapsed < FRAME_INTERVAL:
		return
	_frame_elapsed = fmod(_frame_elapsed, FRAME_INTERVAL)
	phase = _elapsed / SWEEP_SECONDS
	queue_redraw()
	visual_changed.emit()


func _draw() -> void:
	if not active or size.x < 32.0 or size.y < 48.0:
		return
	var sx := size.x / 420.0
	var sy := size.y / 620.0
	var stroke := maxf(1.0, minf(sx, sy))
	var left := 13.0 * sx
	var right := size.x - 13.0 * sx
	var top := 13.0 * sy
	var bottom := size.y - 13.0 * sy
	var span := right - left
	var skew := 94.0 * sx

	# Several broad, low-opacity color planes create the pearlescent shift. They
	# deliberately stay subtle; the moving white strip supplies the actual shine.
	var foil_colors := [
		PALETTE.ELECTRIC_CYAN,
		secondary_accent_color,
		PALETTE.STATE_REWARD,
		PALETTE.EMERALD,
		accent_color,
	]
	var band_width := maxf(34.0 * sx, span * 0.13)
	for band_index in range(foil_colors.size()):
		var offset := fposmod(
			phase * (span + band_width * 2.0) + float(band_index) * span * 0.28,
			span + band_width * 2.0
		) - band_width
		var band_left := left + offset
		var band := PackedVector2Array([
			Vector2(band_left, top),
			Vector2(band_left + band_width, top),
			Vector2(band_left + band_width - skew, bottom),
			Vector2(band_left - skew, bottom),
		])
		draw_colored_polygon(band, Color(foil_colors[band_index], 0.038))

	# The specular pass is a narrow white center with a soft cyan shoulder. Its
	# slow diagonal travel reads as laminated foil instead of a sci-fi scanline.
	var sweep_travel := span + skew + band_width * 2.0
	var sweep_x := left - band_width + phase * sweep_travel
	var glow_width := maxf(30.0 * sx, span * 0.085)
	var core_width := glow_width * 0.28
	_draw_sweep_band(sweep_x, glow_width, skew, top, bottom, Color(PALETTE.ELECTRIC_CYAN, 0.075))
	_draw_sweep_band(sweep_x + glow_width * 0.31, core_width, skew, top, bottom, Color(PALETTE.COOL_WHITE, 0.19))
	if reveal_active:
		var reveal_strength := sin(PI * reveal_phase)
		var reveal_width := maxf(52.0 * sx, span * 0.15)
		var reveal_x := left - reveal_width - skew + reveal_phase * (span + skew + reveal_width * 2.0)
		_draw_sweep_band(
			reveal_x,
			reveal_width,
			skew,
			top,
			bottom,
			Color(accent_color, 0.20 * reveal_strength)
		)
		_draw_sweep_band(
			reveal_x + reveal_width * 0.34,
			reveal_width * 0.24,
			skew,
			top,
			bottom,
			Color(PALETTE.COOL_WHITE, 0.62 * reveal_strength)
		)
		_draw_glint(
			Vector2(
				clampf(reveal_x - skew * 0.34, 34.0 * sx, size.x - 34.0 * sx),
				232.0 * sy
			),
			11.0 * stroke,
			Color(PALETTE.COOL_WHITE, 0.86 * reveal_strength)
		)

	# A thin segmented keyline is always present so the upgraded finish remains
	# identifiable when the moving reflection is between passes.
	var inner := PackedVector2Array([
		Vector2(28 * sx, 15 * sy), Vector2(381 * sx, 15 * sy),
		Vector2(405 * sx, 39 * sy), Vector2(405 * sx, 580 * sy),
		Vector2(380 * sx, 605 * sy), Vector2(28 * sx, 605 * sy),
		Vector2(15 * sx, 592 * sy), Vector2(15 * sx, 28 * sy),
		Vector2(28 * sx, 15 * sy),
	])
	draw_polyline(inner, Color(PALETTE.STATE_REWARD, 0.54), 1.7 * stroke, true)
	draw_line(Vector2(29 * sx, 15 * sy), Vector2(164 * sx, 15 * sy), Color(PALETTE.COOL_WHITE, 0.82), 2.2 * stroke, true)
	draw_line(Vector2(405 * sx, 176 * sy), Vector2(405 * sx, 338 * sy), Color(secondary_accent_color, 0.62), 2.0 * stroke, true)

	# One tiny four-point glint follows the sweep through the artwork area. It is
	# intentionally omitted at thumbnail scale where it would become visual grit.
	if minf(size.x, size.y) >= 190.0:
		var glint_position := Vector2(
			clampf(sweep_x - skew * 0.34, 38.0 * sx, size.x - 38.0 * sx),
			232.0 * sy
		)
		_draw_glint(glint_position, 7.5 * stroke, Color(PALETTE.COOL_WHITE, 0.62))


func _draw_sweep_band(
	x_position: float,
	width: float,
	skew: float,
	top: float,
	bottom: float,
	color: Color
) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(x_position, top),
		Vector2(x_position + width, top),
		Vector2(x_position + width - skew, bottom),
		Vector2(x_position - skew, bottom),
	]), color)


func _draw_glint(position_value: Vector2, radius: float, color: Color) -> void:
	var inner := radius * 0.20
	draw_colored_polygon(PackedVector2Array([
		position_value + Vector2(0.0, -radius),
		position_value + Vector2(inner, -inner),
		position_value + Vector2(radius, 0.0),
		position_value + Vector2(inner, inner),
		position_value + Vector2(0.0, radius),
		position_value + Vector2(-inner, inner),
		position_value + Vector2(-radius, 0.0),
		position_value + Vector2(-inner, -inner),
	]), color)
