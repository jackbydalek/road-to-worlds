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
const SPOTLIGHT_SWEEP_SECONDS := 1.02

var active := false
var accent_color := PALETTE.ELECTRIC_CYAN
var secondary_accent_color := PALETTE.INTERFACE_VIOLET
var phase := 0.0
var reveal_active := false
var reveal_phase := 0.0
var _elapsed := 0.0
var _frame_elapsed := 0.0
var _reveal_elapsed := 0.0
var _spotlight_reveal := false
var _clip_size := Vector2.ZERO
var _clip_polygon := PackedVector2Array()


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
	_spotlight_reveal = false
	visible = active
	set_process(active)
	queue_redraw()


func start_reveal_sweep(spotlight: bool = false) -> void:
	if not active:
		return
	reveal_active = true
	reveal_phase = 0.0
	_reveal_elapsed = 0.0
	_spotlight_reveal = spotlight
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
		var reveal_seconds := SPOTLIGHT_SWEEP_SECONDS if _spotlight_reveal else REVEAL_SWEEP_SECONDS
		reveal_phase = clampf(_reveal_elapsed / reveal_seconds, 0.0, 1.0)
		if reveal_phase >= 1.0:
			reveal_active = false
	_frame_elapsed += delta
	# The one-shot spotlight deserves smooth specular motion. Resting card
	# thumbnails retain their low-cost, restrained 18 fps finish.
	var frame_interval := (1.0 / 60.0) if reveal_active and _spotlight_reveal else FRAME_INTERVAL
	if _frame_elapsed < frame_interval:
		return
	_frame_elapsed = fmod(_frame_elapsed, frame_interval)
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
		_draw_foil_polygon(band, Color(foil_colors[band_index], 0.038))

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
		var reveal_width := maxf(52.0 * sx, span * (0.25 if _spotlight_reveal else 0.15))
		var reveal_x := left - reveal_width - skew + reveal_phase * (span + skew + reveal_width * 2.0)
		if _spotlight_reveal:
			# A wider pearl shoulder and warm/cool offsets make the new finish
			# read as foil. The printed type remains above this material layer.
			_draw_sweep_band(reveal_x - reveal_width * 0.55, reveal_width * 1.7, skew, top, bottom,
				Color(PALETTE.PEACH_MINT, 0.24 * reveal_strength))
			_draw_sweep_band(reveal_x - reveal_width * 0.18, reveal_width * 0.44, skew, top, bottom,
				Color(PALETTE.CARD_BORDER_GOLD, 0.29 * reveal_strength))
			_draw_sweep_band(reveal_x + reveal_width * 0.58, reveal_width * 0.37, skew, top, bottom,
				Color(secondary_accent_color, 0.24 * reveal_strength))
		_draw_sweep_band(
			reveal_x,
			reveal_width,
			skew,
			top,
			bottom,
			Color(accent_color, (0.30 if _spotlight_reveal else 0.20) * reveal_strength)
		)
		_draw_sweep_band(
			reveal_x + reveal_width * 0.34,
			reveal_width * 0.24,
			skew,
			top,
			bottom,
			Color(PALETTE.PEACH_PAPER if _spotlight_reveal else PALETTE.COOL_WHITE, (0.83 if _spotlight_reveal else 0.62) * reveal_strength)
		)
		_draw_glint(
			Vector2(
				clampf(reveal_x - skew * 0.34, 34.0 * sx, size.x - 34.0 * sx),
				232.0 * sy
			),
			11.0 * stroke,
			Color(PALETTE.COOL_WHITE, 0.86 * reveal_strength)
		)

	# A gold printed rule identifies the upgrade while the physical foil moves.
	# It follows the simple new sleeve instead of outlining an armored frame.
	draw_line(Vector2(30 * sx, 20 * sy), Vector2(152 * sx, 20 * sy), Color(PALETTE.STATE_REWARD, 0.82), 2.0 * stroke, true)

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
	_draw_foil_polygon(PackedVector2Array([
		Vector2(x_position, top),
		Vector2(x_position + width, top),
		Vector2(x_position + width - skew, bottom),
		Vector2(x_position - skew, bottom),
	]), color)


func _draw_glint(position_value: Vector2, radius: float, color: Color) -> void:
	var inner := radius * 0.20
	_draw_foil_polygon(PackedVector2Array([
		position_value + Vector2(0.0, -radius),
		position_value + Vector2(inner, -inner),
		position_value + Vector2(radius, 0.0),
		position_value + Vector2(inner, inner),
		position_value + Vector2(0.0, radius),
		position_value + Vector2(-inner, inner),
		position_value + Vector2(-radius, 0.0),
		position_value + Vector2(-inner, -inner),
	]), color)


func _draw_foil_polygon(points: PackedVector2Array, color: Color) -> void:
	if color.a <= 0.001:
		return
	# clip_contents only clips child CanvasItems, not this Control's own draw
	# commands. Clip every idle/reveal band and glint to the paper inside the
	# selected rim; otherwise diagonal sweep shoulders escape the silhouette.
	if _clip_size != size:
		_clip_size = size
		var design_clip := PackedVector2Array([
			Vector2(30, 18), Vector2(390, 18), Vector2(402, 30),
			Vector2(402, 590), Vector2(390, 602), Vector2(30, 602),
			Vector2(18, 590), Vector2(18, 30),
		])
		_clip_polygon = PackedVector2Array()
		for point in design_clip:
			_clip_polygon.append(point * size / Vector2(420, 620))
	for clipped in Geometry2D.intersect_polygons(points, _clip_polygon):
		if clipped.size() < 3:
			continue
		# Sweeps enter and leave through a corner. Ignore their vanishingly
		# small last sliver so coincident vertices never reach triangulation.
		var area := 0.0
		for index in range(clipped.size()):
			area += clipped[index].cross(clipped[(index + 1) % clipped.size()])
		if absf(area) > 0.5:
			draw_colored_polygon(clipped, color)
