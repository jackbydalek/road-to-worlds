extends RefCounted
class_name WarmSketch

## Original procedural pen paths inspired by the owner's hand-drawn UI reference.
## No raster art or kit assets. Paths stay fixed across redraws and never use RNG.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CURVE_STEPS := 12
const CORNER_STEPS := 5
const MAX_CACHED_PATHS := 384
static var _path_cache: Dictionary = {}


static func paper(
	canvas: Control,
	rect: Rect2,
	fill: Color,
	ink: Color = PALETTE.PEACH_INK,
	shadow: bool = true,
	line_width: float = 1.6
) -> void:
	if rect.size.x < 10.0 or rect.size.y < 10.0:
		return
	var variation := posmod(String(canvas.name).hash(), 17)
	var points := _contour(rect, variation)
	if shadow:
		var cast := PackedVector2Array()
		for point in points:
			cast.append(point + Vector2(1.5, 2.0))
		canvas.draw_colored_polygon(cast, Color(PALETTE.PEACH_INK, 0.10))
	canvas.draw_colored_polygon(points, fill)
	# Smooth pen strokes avoid the former straight segments and clipped corners.
	# Three long passes vary pressure without putting dark dots at every vertex.
	var closed := points.duplicate()
	closed.append(points[0])
	var third := maxi(1, (closed.size() - 1) / 3)
	for part in range(3):
		var first := part * third
		var last := closed.size() if part == 2 else (part + 1) * third + 1
		canvas.draw_polyline(closed.slice(first, last), ink, line_width * (0.95 + part * 0.05), true)


static func line(canvas: Control, start: Vector2, finish: Vector2, color: Color, width: float = 1.2) -> void:
	var direction := finish - start
	if direction.length() < 12.0:
		canvas.draw_line(start, finish, color, width, true)
		return
	var normal := Vector2(-direction.y, direction.x).normalized()
	var bend := minf(0.9, direction.length() * 0.012)
	var points := PackedVector2Array([start])
	_cubic(points, start, start.lerp(finish, 0.28) + normal * bend,
		start.lerp(finish, 0.73) - normal * bend, finish, 12)
	canvas.draw_polyline(points, color, width, true)


static func hatch(canvas: Control, rect: Rect2, color: Color, spacing: float = 5.0, width: float = 0.85) -> void:
	# Clip short diagonal pencil strokes analytically; no texture or masking shader.
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	var strokes := PackedVector2Array()
	var run := rect.size.y * 0.78
	var x := -run
	while x < rect.size.x:
		var lower_x := maxf(0.0, x)
		var upper_x := minf(rect.size.x, x + run)
		if upper_x > lower_x:
			var lower_y := rect.size.y - (lower_x - x) / 0.78
			var upper_y := rect.size.y - (upper_x - x) / 0.78
			strokes.append(rect.position + Vector2(lower_x, lower_y))
			strokes.append(rect.position + Vector2(upper_x, upper_y))
		x += maxf(2.0, spacing)
	canvas.draw_multiline(strokes, color, width, true)


static func _contour(rect: Rect2, variation: int = 0) -> PackedVector2Array:
	var key := "%s:%s:%d" % [rect.position, rect.size, variation]
	if _path_cache.has(key):
		return _path_cache[key]
	var p := rect.position
	var s := rect.size
	var r := minf(7.0, minf(s.x, s.y) * 0.16)
	var bend := minf(1.6, minf(s.x, s.y) * 0.038)
	var phase := float(variation) * 0.71
	var a := sin(phase + 0.4) * bend
	var b := sin(phase + 2.2) * bend
	# Control points may bow gently; all actual paths remain inside the draw rect.
	var top_left := p + Vector2(r, 1.0)
	var top_right := p + Vector2(s.x - r, 0.85)
	var right_top := p + Vector2(s.x - 0.9, r)
	var right_bottom := p + Vector2(s.x - 1.0, s.y - r)
	var bottom_right := p + Vector2(s.x - r, s.y - 0.85)
	var bottom_left := p + Vector2(r, s.y - 1.0)
	var left_bottom := p + Vector2(0.9, s.y - r)
	var left_top := p + Vector2(1.0, r)
	var points := PackedVector2Array([top_left])
	_cubic(points, top_left, p + Vector2(s.x * 0.28, 1.6 + a), p + Vector2(s.x * 0.7, 1.6 - b), top_right, CURVE_STEPS)
	_cubic(points, top_right, p + Vector2(s.x - 1.5, 0.3), p + Vector2(s.x - 0.3, 1.5), right_top, CORNER_STEPS)
	_cubic(points, right_top, p + Vector2(s.x - 1.7 - b, s.y * 0.3), p + Vector2(s.x - 1.7 + a, s.y * 0.72), right_bottom, CURVE_STEPS)
	_cubic(points, right_bottom, p + Vector2(s.x - 0.4, s.y - 1.8), p + Vector2(s.x - 1.9, s.y - 0.4), bottom_right, CORNER_STEPS)
	_cubic(points, bottom_right, p + Vector2(s.x * 0.7, s.y - 1.7 + b), p + Vector2(s.x * 0.27, s.y - 1.7 - a), bottom_left, CURVE_STEPS)
	_cubic(points, bottom_left, p + Vector2(1.7, s.y - 0.4), p + Vector2(0.4, s.y - 1.8), left_bottom, CORNER_STEPS)
	_cubic(points, left_bottom, p + Vector2(1.7 + a, s.y * 0.7), p + Vector2(1.7 - b, s.y * 0.28), left_top, CURVE_STEPS)
	_cubic(points, left_top, p + Vector2(0.3, 1.6), p + Vector2(1.9, 0.4), top_left, CORNER_STEPS)
	points.resize(points.size() - 1)
	if _path_cache.size() >= MAX_CACHED_PATHS:
		_path_cache.clear()
	_path_cache[key] = points
	return points


static func _cubic(points: PackedVector2Array, start: Vector2, c1: Vector2, c2: Vector2, finish: Vector2, steps: int) -> void:
	for index in range(1, steps + 1):
		var t := float(index) / float(steps)
		var u := 1.0 - t
		points.append(u * u * u * start + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * finish)
