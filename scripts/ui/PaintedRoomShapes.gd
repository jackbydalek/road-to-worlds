extends RefCounted
class_name PaintedRoomShapes

## Quiet, editable paint shapes for the room, never for live cards or controls.
## Tiny edge variations and pigment marks are deterministic: resize/reduced
## motion does not cause the background to shimmer or boil with the people.


static func polygon(canvas: Control, points, color: Color, seed := 0, texture_strength := 1.0) -> void:
	var source := PackedVector2Array(points)
	if source.size() < 3:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 7391
	var painted := PackedVector2Array()
	var bounds := Rect2(source[0], Vector2.ZERO)
	for index in source.size():
		var a := source[index]
		var b := source[(index + 1) % source.size()]
		bounds = bounds.expand(a)
		var distance := a.distance_to(b)
		var steps := maxi(1, ceili(distance / 14.0))
		var normal := (b - a).orthogonal().normalized()
		for step in steps:
			var t := float(step) / float(steps)
			# Keep authored corners; only the middle of a painted edge has tooth.
			var shift := rng.randf_range(-0.68, 0.68) if step > 0 else 0.0
			painted.append(a.lerp(b, t) + normal * shift)
	canvas.draw_colored_polygon(painted, color)
	if texture_strength <= 0.0 or color.a < 0.5:
		return
	# Sparse pigment flecks stay inside the shape. These are low-contrast color
	# dabs, not a full-screen noise texture, outline or animated shader.
	var count := clampi(int(bounds.get_area() / 900.0), 0, 420)
	for index in count:
		var center := bounds.position + Vector2(rng.randf(), rng.randf()) * bounds.size
		var radius := Vector2(rng.randf_range(0.45, 1.6), rng.randf_range(0.3, 0.8))
		if not Geometry2D.is_point_in_polygon(center, painted):
			continue
		if not Geometry2D.is_point_in_polygon(center + radius, painted):
			continue
		if not Geometry2D.is_point_in_polygon(center - radius, painted):
			continue
		var pigment := color.lightened(0.09) if index % 3 else color.darkened(0.07)
		pigment.a = color.a * clampf(0.24 * texture_strength, 0.0, 0.40)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(-radius.x, -radius.y * 0.3),
			center + Vector2(radius.x * 0.4, -radius.y),
			center + radius,
			center + Vector2(-radius.x * 0.6, radius.y * 0.7),
		]), pigment)


static func patch(canvas: Control, rect: Rect2, color: Color, seed := 0, texture_strength := 1.0) -> void:
	polygon(canvas, [rect.position, rect.position + Vector2(rect.size.x, 0),
		rect.end, rect.position + Vector2(0, rect.size.y)], color, seed, texture_strength)


static func ellipse(canvas: Control, rect: Rect2, color: Color, seed := 0, texture_strength := 1.0) -> void:
	var points := PackedVector2Array()
	for index in 40:
		var angle := float(index) / 40.0 * TAU
		points.append(rect.get_center() + Vector2(cos(angle), sin(angle)) * rect.size * 0.5)
	polygon(canvas, points, color, seed, texture_strength)
