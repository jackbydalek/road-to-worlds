extends Control
class_name TerrainBattleBackdrop

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var terrain_id := "park"


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func set_terrain(value: String) -> void:
	terrain_id = value if value in ["park", "sidewalk", "waterfront"] else "park"
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	match terrain_id:
		"sidewalk":
			_draw_sidewalk()
		"waterfront":
			_draw_waterfront()
		_:
			_draw_park()


func _draw_park() -> void:
	_draw_sky(Color("#86D3ED"), Color("#DDF5F4"))
	_band(0.43, 0.12, Color("#A6D99B"))
	_band(0.55, 0.16, Color("#78B56A"))
	_band(0.71, 0.29, Color("#4F8C56"))
	for tree in [
		[0.03, 0.48, 0.11], [0.14, 0.45, 0.085], [0.25, 0.49, 0.07],
		[0.74, 0.48, 0.075], [0.86, 0.44, 0.095], [0.97, 0.48, 0.11],
	]:
		_draw_tree(float(tree[0]), float(tree[1]), float(tree[2]), Color("#2F684B"), Color("#67A956"))
	_draw_path([_p(0.0, 1.0), _p(0.0, 0.82), _p(0.43, 0.57), _p(0.49, 0.57), _p(0.24, 1.0)], Color("#DCC894"))
	_draw_path([_p(1.0, 1.0), _p(1.0, 0.82), _p(0.57, 0.57), _p(0.51, 0.57), _p(0.76, 1.0)], Color("#DCC894"))
	_draw_stage_pads(Color("#3C7052"), Color("#73A96E"))


func _draw_sidewalk() -> void:
	_draw_sky(Color("#8BCFE8"), Color("#E5F4F1"))
	_band(0.43, 0.14, Color("#B8C5B5"))
	_draw_city_block(0.0, 0.20, 0.18, 0.38, Color("#DED4C1"), Color("#8A6C67"))
	_draw_city_block(0.14, 0.28, 0.17, 0.29, Color("#C8D1C7"), Color("#6B727E"))
	_draw_city_block(0.71, 0.26, 0.16, 0.31, Color("#DCCCB9"), Color("#997068"))
	_draw_city_block(0.84, 0.19, 0.16, 0.38, Color("#C9D3CD"), Color("#65717C"))
	_band(0.57, 0.43, Color("#D8D5CE"))
	for row in range(5):
		var y := 0.60 + float(row) * 0.085
		draw_line(_p(0.0, y), _p(1.0, y), Color("#AAA9AA"), maxf(1.0, size.y * 0.002), true)
	for column in range(9):
		var bottom_x := float(column) / 8.0
		var top_x := 0.5 + (bottom_x - 0.5) * 0.28
		draw_line(_p(bottom_x, 1.0), _p(top_x, 0.57), Color("#BBB9B5"), maxf(1.0, size.x * 0.0012), true)
	_draw_stage_pads(Color("#6A6C78"), Color("#9A9BA2"))


func _draw_waterfront() -> void:
	_draw_sky(Color("#79CCEC"), Color("#DDF5F6"))
	_band(0.36, 0.09, Color("#42B8D0"))
	_band(0.45, 0.08, Color("#279DBD"))
	_band(0.53, 0.09, Color("#1684AA"))
	_band(0.62, 0.08, Color("#126D91"))
	for y in [0.405, 0.49, 0.575, 0.655]:
		draw_line(_p(0.0, y), _p(1.0, y), Color(1.0, 1.0, 1.0, 0.22), maxf(1.0, size.y * 0.002), true)
	_band(0.70, 0.30, Color("#D9D2C4"))
	draw_line(_p(0.0, 0.73), _p(1.0, 0.73), PALETTE.STEEL, maxf(3.0, size.y * 0.007), true)
	for post in range(11):
		var x := float(post) / 10.0
		draw_line(_p(x, 0.68), _p(x, 0.77), PALETTE.STEEL, maxf(2.0, size.x * 0.003), true)
	for row in range(4):
		var y := 0.76 + float(row) * 0.075
		draw_line(_p(0.0, y), _p(1.0, y), Color("#B3AEA7"), maxf(1.0, size.y * 0.002), true)
	_draw_stage_pads(Color("#266B78"), Color("#62A5A6"))


func _draw_sky(top_color: Color, horizon_color: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), top_color)
	for index in range(6):
		var t := float(index) / 5.0
		var color := top_color.lerp(horizon_color, t)
		_band(t * 0.43, 0.09, color)
	_draw_cloud(0.18, 0.16, 0.075)
	_draw_cloud(0.76, 0.12, 0.095)


func _draw_cloud(x: float, y: float, radius: float) -> void:
	var color := Color(PALETTE.COOL_WHITE, 0.82)
	for cloud_part in [[-0.8, 0.2, 0.55], [-0.3, -0.1, 0.75], [0.25, -0.2, 0.9], [0.8, 0.15, 0.6]]:
		var center := _p(x + float(cloud_part[0]) * radius, y + float(cloud_part[1]) * radius)
		draw_circle(center, size.y * radius * float(cloud_part[2]), color, true, -1.0, true)


func _draw_tree(x: float, ground_y: float, crown_radius: float, trunk_color: Color, leaf_color: Color) -> void:
	var trunk_width := crown_radius * 0.20
	draw_rect(Rect2(_p(x - trunk_width * 0.5, ground_y - crown_radius * 0.7), Vector2(size.x * trunk_width, size.y * crown_radius * 0.8)), trunk_color)
	for crown in [[-0.55, -0.45, 0.62], [0.0, -0.72, 0.8], [0.58, -0.42, 0.63], [0.0, -0.25, 0.9]]:
		draw_circle(
			_p(x + float(crown[0]) * crown_radius, ground_y + float(crown[1]) * crown_radius),
			size.y * crown_radius * float(crown[2]),
			leaf_color,
			true,
			-1.0,
			true
		)


func _draw_city_block(x: float, y: float, width: float, height: float, wall: Color, roof: Color) -> void:
	var building_rect := Rect2(_p(x, y), Vector2(size.x * width, size.y * height))
	draw_rect(building_rect, wall)
	draw_colored_polygon(PackedVector2Array([_p(x - 0.01, y), _p(x + width * 0.5, y - 0.07), _p(x + width + 0.01, y)]), roof)
	for floor_index in range(2):
		for window_index in range(3):
			var window_x := x + width * (0.16 + float(window_index) * 0.31)
			var window_y := y + height * (0.23 + float(floor_index) * 0.42)
			draw_rect(Rect2(_p(window_x, window_y), Vector2(size.x * width * 0.12, size.y * height * 0.14)), Color("#78ABC0"))


func _draw_stage_pads(edge: Color, fill: Color) -> void:
	_draw_oval(_p(0.08, 0.90), Vector2(size.x * 0.19, size.y * 0.12), edge)
	_draw_oval(_p(0.08, 0.90), Vector2(size.x * 0.165, size.y * 0.095), fill)
	_draw_oval(_p(0.92, 0.90), Vector2(size.x * 0.19, size.y * 0.12), edge)
	_draw_oval(_p(0.92, 0.90), Vector2(size.x * 0.165, size.y * 0.095), fill)


func _draw_path(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(48):
		var angle := TAU * float(index) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _band(y: float, height: float, color: Color) -> void:
	draw_rect(Rect2(_p(0.0, y), Vector2(size.x, size.y * height)), color)


func _p(x: float, y: float) -> Vector2:
	return Vector2(size.x * x, size.y * y)
