extends RefCounted
class_name CardShopMerchandise

## Native, unbranded card-shop props. Shared by the room and battle shelves.
## Product references supply physical construction only; no imported artwork.
const P := preload("res://scripts/ui/GamePalette.gd")
const PAINT := preload("res://scripts/ui/PaintedRoomShapes.gd")


static func deck_box(canvas: Control, rect: Rect2, color: Color, opened := false) -> void:
	# Squat case: the lid, side and magnetic flap read through color planes.
	# Background stock has no ink perimeter; only its printed paper marks remain.
	var front := Rect2(rect.position + rect.size * Vector2(0, 0.16), rect.size * Vector2(0.78, 0.84))
	_contact_shadow(canvas, rect)
	_poly(canvas, rect, [Vector2(0, 0.16), Vector2(0.22, 0), Vector2(1, 0), Vector2(0.78, 0.16)], color.lightened(0.13))
	_poly(canvas, rect, [Vector2(0.78, 0.16), Vector2(1, 0), Vector2(1, 0.84), Vector2(0.78, 1)], color.darkened(0.16))
	PAINT.patch(canvas, front, color, int(rect.position.x))
	_poly(canvas, rect, [Vector2(0.03, 0.20), Vector2(0.17, 0.19), Vector2(0.14, 0.98), Vector2(0.02, 0.98)], color.lightened(0.035))
	if opened:
		# Lifted lid behind a stepped stack: clearly a storage box, not a book.
		_poly(canvas, rect, [Vector2(0.04, 0.40), Vector2(0.03, 0.02), Vector2(0.72, 0.02), Vector2(0.75, 0.40)], color.lightened(0.12))
		for index in range(4):
			var card := Rect2(rect.position + rect.size * Vector2(0.17 + index * 0.025, 0.24 - index * 0.025), rect.size * Vector2(0.47, 0.43))
			PAINT.patch(canvas, card, P.PEACH_PAPER_MUTED if index % 2 else P.PEACH_PAPER, index)
		var face := Rect2(rect.position + rect.size * Vector2(0.17, 0.25), rect.size * Vector2(0.46, 0.41))
		PAINT.patch(canvas, face, P.PEACH_TEAL, 12)
		_poly(canvas, rect, [Vector2(0.02, 0.53), Vector2(0.23, 0.53), Vector2(0.29, 0.61), Vector2(0.48, 0.61), Vector2(0.55, 0.53), Vector2(0.77, 0.53), Vector2(0.77, 0.98), Vector2(0.02, 0.98)], color)
	else:
		_poly(canvas, rect, [Vector2(0.03, 0.22), Vector2(0.75, 0.22), Vector2(0.74, 0.65), Vector2(0.66, 0.76), Vector2(0.12, 0.76), Vector2(0.03, 0.66)], color.darkened(0.10))
		_poly(canvas, rect, [Vector2(0.03, 0.18), Vector2(0.75, 0.18), Vector2(0.74, 0.62), Vector2(0.66, 0.72), Vector2(0.12, 0.72), Vector2(0.03, 0.63)], color.lightened(0.08))
		# A tiny three-card stamp provides a repeatable original merchandise mark.
		for index in range(3):
			var point := rect.position + rect.size * Vector2(0.28 + index * 0.08, 0.42 - (0.02 if index == 1 else 0.0))
			canvas.draw_rect(Rect2(point, rect.size * Vector2(0.08, 0.13)), P.PEACH_PAPER, false, 0.9)
	_poly(canvas, rect, [Vector2(0.83, 0.24), Vector2(0.89, 0.20), Vector2(0.89, 0.82), Vector2(0.84, 0.86)], color.darkened(0.10))


static func sleeve_pack(canvas: Control, rect: Rect2, color: Color) -> void:
	# Retail pouch: hanger tab and slot, sealed edges, clear sleeve sample window.
	_contact_shadow(canvas, rect)
	_poly(canvas, rect, [Vector2(0.04, 0.17), Vector2(0.26, 0.17), Vector2(0.26, 0.01), Vector2(0.74, 0.01), Vector2(0.74, 0.17), Vector2(0.96, 0.17), Vector2(0.98, 1), Vector2(0.02, 1)], color)
	_line(canvas, rect, Vector2(0.40, 0.08), Vector2(0.61, 0.08), P.PEACH_PAPER, 2.2)
	_poly(canvas, rect, [Vector2(0.05, 0.20), Vector2(0.95, 0.20), Vector2(0.95, 0.28), Vector2(0.05, 0.28)], color.lightened(0.12))
	_poly(canvas, rect, [Vector2(0.04, 0.91), Vector2(0.97, 0.91), Vector2(0.98, 1), Vector2(0.02, 1)], color.darkened(0.12))
	_poly(canvas, rect, [Vector2(0.83, 0.30), Vector2(0.96, 0.29), Vector2(0.97, 0.88), Vector2(0.85, 0.88)], color.darkened(0.08))
	var window := Rect2(rect.position + rect.size * Vector2(0.16, 0.38), rect.size * Vector2(0.66, 0.42))
	PAINT.patch(canvas, window, P.PEACH_PAPER, int(rect.position.x))
	_poly(canvas, rect, [Vector2(0.23, 0.43), Vector2(0.57, 0.40), Vector2(0.64, 0.74), Vector2(0.30, 0.77)], color.darkened(0.12))
	_poly(canvas, rect, [Vector2(0.42, 0.43), Vector2(0.75, 0.47), Vector2(0.68, 0.78), Vector2(0.35, 0.74)], color.lightened(0.20))
	_line(canvas, rect, Vector2(0.44, 0.49), Vector2(0.68, 0.52), P.PEACH_PAPER, 1.0)


static func rolled_mat(canvas: Control, rect: Rect2, color: Color) -> void:
	# Horizontal cloth cylinder with a visible spiral end and a paper belly band.
	_contact_shadow(canvas, rect)
	var body: Array[Vector2] = [Vector2(0.10, 0.16), Vector2(0.89, 0.05)]
	# The far rim is a rounded cylinder end, never a pointed package/pencil tip.
	for index in range(1, 17):
		var angle := -PI * 0.5 + float(index) / 16.0 * PI
		body.append(Vector2(0.89 + cos(angle) * 0.11, 0.435 + sin(angle) * 0.385))
	body.append_array([Vector2(0.12, 0.96), Vector2(0.02, 0.70)])
	_poly(canvas, rect, body, color)
	_poly(canvas, rect, [Vector2(0.12, 0.71), Vector2(0.93, 0.60), Vector2(0.91, 0.83), Vector2(0.12, 0.96)], color.darkened(0.10))
	_poly(canvas, rect, [Vector2(0.14, 0.18), Vector2(0.86, 0.08), Vector2(0.91, 0.19), Vector2(0.15, 0.30)], color.lightened(0.06))
	_poly(canvas, rect, [Vector2(0.52, 0.11), Vector2(0.68, 0.08), Vector2(0.74, 0.85), Vector2(0.57, 0.89)], P.PEACH_PAPER)
	# Ellipse drawn directly so nested prop calls do not alter the room transform.
	var center := rect.position + rect.size * Vector2(0.11, 0.55)
	var points := PackedVector2Array()
	for index in range(33):
		var angle := float(index) / 32.0 * TAU
		points.append(center + Vector2(cos(angle) * rect.size.x * 0.10, sin(angle) * rect.size.y * 0.41))
	PAINT.polygon(canvas, points, color.lightened(0.20), int(rect.position.y))
	points.clear()
	for index in range(33):
		var progress := float(index) / 32.0
		var angle := progress * TAU * 1.65
		var radius := 0.82 * (1.0 - progress) + 0.05
		points.append(center + Vector2(cos(angle) * rect.size.x * 0.10, sin(angle) * rect.size.y * 0.41) * radius)
	# A material-colored spiral is a cloth fold, not an ink contour.
	canvas.draw_polyline(points, color.darkened(0.05), 1.2, true)


static func _poly(canvas: Control, rect: Rect2, unit_points: Array[Vector2], color: Color) -> void:
	var points := PackedVector2Array()
	for point in unit_points:
		points.append(rect.position + point * rect.size)
	PAINT.polygon(canvas, points, color, int(rect.position.x + rect.position.y))


static func _line(canvas: Control, rect: Rect2, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	canvas.draw_line(rect.position + a * rect.size, rect.position + b * rect.size, color, width, true)


static func _contact_shadow(canvas: Control, rect: Rect2) -> void:
	PAINT.ellipse(canvas, Rect2(rect.position + rect.size * Vector2(0.01, 0.91), rect.size * Vector2(1.0, 0.13)), Color(P.PEACH_TEAL, 0.09), 25, 0.0)
