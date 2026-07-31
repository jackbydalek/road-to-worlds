extends Control
class_name WiredTitleDoodles

const INK := Color("#241B17")
const TEAL := Color("#2D6F6A")
const ORANGE := Color("#E06B4F")
const MUSTARD := Color("#F0B34D")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# A loose card stack on the left.
	_rough_loop([
		_p(92, 392), _p(263, 372), _p(275, 566), _p(103, 584), _p(92, 392)
	], INK, 2.4)
	_rough_loop([
		_p(111, 411), _p(282, 393), _p(291, 548), _p(121, 568), _p(111, 411)
	], TEAL, 2.1)
	_stroke([_p(130, 447), _p(230, 438)], ORANGE, 3.0)
	_stroke([_p(131, 478), _p(248, 467)], INK, 2.0)
	_stroke([_p(134, 512), _p(218, 504)], INK, 2.0)

	# A hand-drawn tournament cup on the right.
	_rough_loop([
		_p(1177, 405), _p(1300, 405), _p(1284, 492), _p(1256, 528),
		_p(1222, 528), _p(1193, 492), _p(1177, 405)
	], INK, 2.4)
	_stroke([_p(1202, 531), _p(1276, 531)], TEAL, 2.4)
	_stroke([_p(1238, 528), _p(1238, 574), _p(1196, 579), _p(1280, 577)], INK, 2.4)
	_stroke([_p(1178, 427), _p(1146, 420), _p(1152, 472), _p(1193, 483)], ORANGE, 2.2)
	_stroke([_p(1298, 426), _p(1330, 420), _p(1323, 472), _p(1284, 483)], ORANGE, 2.2)

	# Small sketch marks keep the empty space intentionally imperfect.
	_spark(_p(340, 323), 15.0, MUSTARD)
	_spark(_p(1083, 332), 13.0, ORANGE)
	_stroke([_p(321, 672), _p(347, 680), _p(329, 694)], TEAL, 2.4)
	_stroke([_p(1092, 668), _p(1118, 660), _p(1110, 686)], MUSTARD, 2.4)
	_rough_loop([
		_p(116, 684), _p(154, 677), _p(164, 708), _p(125, 714), _p(116, 684)
	], ORANGE, 2.0)
	_rough_loop([
		_p(1280, 686), _p(1322, 691), _p(1315, 721), _p(1275, 714), _p(1280, 686)
	], TEAL, 2.0)


func _p(x: float, y: float) -> Vector2:
	return Vector2(x / 1440.0 * size.x, y / 840.0 * size.y)


func _rough_loop(points: Array[Vector2], color: Color, width: float) -> void:
	_stroke(points, color, width)
	var shifted: Array[Vector2] = []
	for index in range(points.size()):
		var direction := 1.0 if index % 2 == 0 else -1.0
		shifted.append(points[index] + Vector2(2.0 * direction, 1.5 * -direction))
	_stroke(shifted, Color(color.r, color.g, color.b, 0.58), maxf(1.0, width * 0.58))


func _stroke(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)


func _spark(center: Vector2, radius: float, color: Color) -> void:
	_stroke([
		center + Vector2(0, -radius),
		center + Vector2(3, -3),
		center + Vector2(radius, 0),
		center + Vector2(3, 3),
		center + Vector2(0, radius),
		center + Vector2(-3, 3),
		center + Vector2(-radius, 0),
		center + Vector2(-3, -3),
		center + Vector2(0, -radius),
	], color, 2.2)
