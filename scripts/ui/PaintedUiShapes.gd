extends RefCounted
class_name PaintedUiShapes

## Stable matte paint for native UI. Geometry is cached by dimensions, never
## animated or randomized; text, hit areas and game randomness stay independent.
## Ordinary surfaces have no contour. Focus is a deliberate, temporary mark.

class SurfaceStyle extends StyleBoxFlat:
	var paint_seed := 0
	var paint_radius := 9.0
	static var _geometry_cache: Dictionary = {}

	func _draw(canvas_item: RID, rect: Rect2) -> void:
		var points := geometry(rect, paint_seed, paint_radius)
		if points.size() < 3:
			return
		if draw_center and bg_color.a > 0.0:
			RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([bg_color]))
			var closed := points.duplicate()
			closed.append(points[0])
			RenderingServer.canvas_item_add_polyline(canvas_item, closed, PackedColorArray([bg_color]), 0.65, true)
		var border_width := maxi(maxi(border_width_left, border_width_right), maxi(border_width_top, border_width_bottom))
		if border_width > 0 and border_color.a > 0.0:
			points.append(points[0])
			RenderingServer.canvas_item_add_polyline(canvas_item, points, PackedColorArray([border_color]), float(border_width), true)

	static func geometry(rect: Rect2, seed: int, radius: float) -> PackedVector2Array:
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return PackedVector2Array()
		var key := "%s:%s:%s" % [rect.size, seed, radius]
		if not _geometry_cache.has(key):
			# Bounded even if a resizable window is dragged continuously.
			if _geometry_cache.size() >= 256:
				_geometry_cache.clear()
			_geometry_cache[key] = _build_geometry(rect.size, seed, radius)
		var points: PackedVector2Array = _geometry_cache[key].duplicate()
		for index in points.size():
			points[index] += rect.position
		return points

	static func _build_geometry(dimensions: Vector2, seed: int, radius: float) -> PackedVector2Array:
		var shortest_edge := minf(dimensions.x, dimensions.y)
		var r := minf(maxf(radius, 0.05), shortest_edge * 0.40)
		# A draining life bar can be narrower than one pixel. Keep its paint
		# variation proportional so opposite edges never cross near zero life.
		var edge_scale := minf(1.0, shortest_edge / 6.0)
		var centers := [Vector2(dimensions.x - r, r), dimensions - Vector2(r, r), Vector2(r, dimensions.y - r), Vector2(r, r)]
		var points := PackedVector2Array()
		for corner in 4:
			var start_angle := -PI * 0.5 + float(corner) * PI * 0.5
			for step in 6:
				var angle := start_angle + float(step) / 5.0 * PI * 0.5
				points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * r)
			var start: Vector2 = points[-1]
			var next_angle := start_angle + PI * 0.5
			var finish: Vector2 = centers[(corner + 1) % 4] + Vector2(cos(next_angle), sin(next_angle)) * r
			var steps := maxi(1, ceili(start.distance_to(finish) / 24.0))
			var inward := (finish - start).orthogonal().normalized()
			for step in range(1, steps):
				var t := float(step) / float(steps)
				var tooth := (sin(float(step * 13 + seed * 7 + corner * 3)) * 0.38 + sin(t * PI) * 0.42) * edge_scale
				points.append(start.lerp(finish, t) + inward * tooth)
		return points


static func draw_surface(canvas: CanvasItem, rect: Rect2, fill: Color, seed: int = 0, radius: float = 9.0) -> void:
	var points := SurfaceStyle.geometry(rect, seed, radius)
	if points.size() < 3 or fill.a <= 0.0:
		return
	canvas.draw_colored_polygon(points, fill)
	points.append(points[0])
	canvas.draw_polyline(points, fill, 0.65, true)


static func draw_focus(canvas: CanvasItem, rect: Rect2, color: Color, seed: int = 0) -> void:
	var points := SurfaceStyle.geometry(rect, seed, 9.0)
	if points.size() < 3:
		return
	points.append(points[0])
	canvas.draw_polyline(points, color, 2.5, true)


static func style(fill: Color, margins: Vector4 = Vector4(14, 10, 14, 10), seed: int = 0, radius: float = 9.0) -> StyleBoxFlat:
	var result := SurfaceStyle.new()
	result.bg_color = fill
	result.border_color = Color.TRANSPARENT
	result.set_border_width_all(0)
	result.set_corner_radius_all(int(radius))
	result.paint_seed = seed
	result.paint_radius = radius
	result.content_margin_left = margins.x
	result.content_margin_top = margins.y
	result.content_margin_right = margins.z
	result.content_margin_bottom = margins.w
	result.set_meta("painted_shapes", true)
	return result
