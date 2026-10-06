extends Control
class_name PeachSodaShopIllustration

## Supplied painted room layers. Source regions share the same 1:3 registration
## as the full shop illustration; live people, cards and hit areas stay separate.
const P := preload("res://scripts/ui/GamePalette.gd")
const INK := preload("res://scripts/ui/WarmSketch.gd")
const PAINT := preload("res://scripts/ui/PaintedRoomShapes.gd")
const MERCH := preload("res://scripts/ui/CardShopMerchandise.gd")
const ROOM_TEXTURE := preload("res://assets/illustrations/supplied_locals_2026_09_14/shop_background.png")
const COUNTER_TEXTURE := preload("res://assets/illustrations/supplied_locals_2026_09_14/shop_counter.png")
const VENDING_TEXTURE := preload("res://assets/illustrations/supplied_locals_2026_09_14/shop_vending.png")
const COUNTER_SOURCE := Rect2(0, 720, 2490, 1480)
const VENDING_SOURCE := Rect2(2490, 870, 900, 1300)
@export_enum("room", "counter", "vending", "plant", "table") var illustration := "room"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_meta("asset_origin", "owner_supplied_screen_layers")
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	match illustration:
		"room":
			# The authored 5:3 room fills the width. Its floor continues below the
			# source on taller windows; no stretching of furniture or plants.
			draw_rect(Rect2(Vector2.ZERO, size), P.PEACH_PAPER)
			draw_rect(Rect2(0, 474, size.x, maxf(0, size.y - 474)), P.PEACH_SHOP_FLOOR)
			draw_texture_rect(ROOM_TEXTURE, Rect2(0, -90, 1280, 768), false)
			if size.y > 678:
				# Continue the final painted floor row into the extra height. This
				# keeps the source's color planes joined instead of adding a seam.
				draw_texture_rect_region(ROOM_TEXTURE, Rect2(0, 678, 1280, size.y - 678), Rect2(0, 2303, 3840, 1))
			return
		"counter":
			draw_texture_rect_region(COUNTER_TEXTURE, Rect2(Vector2.ZERO, size), COUNTER_SOURCE)
			return
		"vending":
			draw_texture_rect_region(VENDING_TEXTURE, Rect2(Vector2.ZERO, size), VENDING_SOURCE)
			return
	var native := {"room": Vector2(1280, 900), "counter": Vector2(720, 280), "vending": Vector2(300, 500), "plant": Vector2(140, 200), "table": Vector2(360, 220)}
	draw_set_transform(Vector2.ZERO, 0.0, size / native[illustration])
	match illustration:
		"room": _room()
		"counter": _counter()
		"vending": _vending()
		"plant": _plant()
		"table": _table()
	draw_set_transform(Vector2.ZERO)


func _patch(rect: Rect2, fill: Color, seed := 0) -> void:
	PAINT.patch(self, rect, fill, seed)


func _poly(points: Array[Vector2], fill: Color, seed := 0) -> void:
	PAINT.polygon(self, points, fill, seed)


func _room() -> void:
	_patch(Rect2(-200, -100, 1700, 1100), P.PEACH_PAPER, 1)
	# Quiet plaster shapes catch daylight; color boundaries replace wall ink.
	_poly([Vector2(-200, 76), Vector2(180, 81), Vector2(196, 98), Vector2(733, 101), Vector2(820, 122), Vector2(-200, 117)], P.PEACH_PAPER_MUTED, 2)
	_patch(Rect2(-200, 390, 1700, 710), P.PEACH_TABLE, 3)
	# The same perspective floor, described by broad tile values instead of a grid.
	var depth: Array[float] = [390, 467, 555, 660, 795, 1100]
	for row in range(depth.size() - 1):
		for column in range(6):
			var left := -200.0 + column * 300.0
			var right := left + 300.0
			var near_y := depth[row + 1]
			var far_y := depth[row]
			var far_scale := lerpf(0.42, 1.0, (far_y - 391.0) / 589.0)
			var near_scale := lerpf(0.42, 1.0, (near_y - 391.0) / 589.0)
			var tile_color := P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.09) if (row + column) % 2 == 0 else P.PEACH_TABLE.darkened(0.035)
			_poly([Vector2(640 + (left - 640) * far_scale, far_y), Vector2(640 + (right - 640) * far_scale, far_y), Vector2(640 + (right - 640) * near_scale, near_y), Vector2(640 + (left - 640) * near_scale, near_y)], tile_color, 20 + row * 6 + column)
	# Daylight window: broad peach framing and mint glazing, with no perimeter ink.
	_patch(Rect2(889, 86, 443, 293), P.PEACH_TABLE.darkened(0.06), 61)
	_patch(Rect2(897, 86, 435, 286), P.PEACH_TABLE, 62)
	_patch(Rect2(905, 99, 412, 261), P.PEACH_MINT, 63)
	_poly([Vector2(916, 295), Vector2(916, 218), Vector2(988, 165), Vector2(1056, 211), Vector2(1056, 295)], P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.15), 64)
	_patch(Rect2(941, 229, 27, 45), P.PEACH_PAPER, 65)
	_patch(Rect2(989, 224, 38, 60), P.PEACH_TEAL.lerp(P.PEACH_MINT, 0.25), 66)
	for index in range(4):
		var point: Vector2 = [Vector2(1110, 179), Vector2(1180, 131), Vector2(1246, 204), Vector2(1309, 118)][index]
		PAINT.ellipse(self, Rect2(point - Vector2(48, 48), Vector2(96, 96)), P.PEACH_PAPER, 70 + index)
		PAINT.ellipse(self, Rect2(point + Vector2(-40, 39), Vector2(64, 105)), P.PEACH_MINT.lerp(P.PEACH_HEALTH, 0.22), 74 + index)
	for x in [1037, 1187]:
		_patch(Rect2(x, 98, 8, 267), P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.14), x)
	_patch(Rect2(898, 246, 424, 9), P.PEACH_TABLE, 78)
	_patch(Rect2(884, 374, 448, 12), P.PEACH_TABLE.darkened(0.13), 79)
	_patch(Rect2(884, 365, 448, 12), P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.18), 80)
	# Recessed stock bays and solid shelf faces replace the old outlined cabinet.
	_patch(Rect2(21, 108, 551, 235), P.PEACH_TABLE, 81)
	for row in range(2):
		var y := 127.0 + row * 105.0
		_patch(Rect2(32, y, 528, 88), P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.26), 82 + row)
		_patch(Rect2(32, y, 528, 10), P.PEACH_TABLE.darkened(0.12), 84 + row)
		if row == 0:
			for index in range(4):
				var fill: Color = [P.PEACH_TEAL, P.PEACH_TABLE, P.PEACH_MINT, P.PEACH_CARD_FRAME][index]
				MERCH.deck_box(self, Rect2(44 + index * 71, y + 21, 65, 64), fill)
			for index in range(4):
				var fill: Color = [P.PEACH_MINT, P.PEACH_TEAL, P.PEACH_TABLE, P.PEACH_CARD_FRAME][index]
				MERCH.sleeve_pack(self, Rect2(350 + index * 48, y + 5, 40, 78), fill)
		else:
			MERCH.deck_box(self, Rect2(44, y + 9, 82, 76), P.PEACH_TEAL, true)
			MERCH.deck_box(self, Rect2(138, y + 19, 69, 65), P.PEACH_TABLE)
			MERCH.deck_box(self, Rect2(218, y + 23, 65, 61), P.PEACH_MINT)
			MERCH.rolled_mat(self, Rect2(315, y + 44, 112, 40), P.PEACH_TEAL)
			MERCH.rolled_mat(self, Rect2(322, y + 8, 104, 37), P.PEACH_TABLE)
			MERCH.rolled_mat(self, Rect2(435, y + 44, 111, 40), P.PEACH_MINT)
			MERCH.rolled_mat(self, Rect2(441, y + 8, 104, 37), P.PEACH_CARD_FRAME)
		_patch(Rect2(18, y + 90, 558, 8), P.PEACH_TABLE.darkened(0.12), 87 + row)
		_patch(Rect2(18, y + 85, 558, 8), P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.16), 89 + row)
	for x in [165, 481, 811]:
		_patch(Rect2(x - 1, 60, 3, 44), P.PEACH_TEAL.darkened(0.1), x + 1)
		_poly([Vector2(x - 32, 122), Vector2(x - 18, 99), Vector2(x + 18, 99), Vector2(x + 32, 122)], P.PEACH_TEAL, x + 2)
		_patch(Rect2(x - 27, 122, 54, 4), P.PEACH_MINT, x + 3)
	_poly([Vector2(1082, 394), Vector2(1261, 394), Vector2(790, 900), Vector2(341, 900)], Color(P.PEACH_PAPER, 0.28), 90)


func _counter() -> void:
	# Opaque wood surrounds the glass recess. Original cards remain separate nodes.
	_poly([Vector2(28, 252), Vector2(704, 252), Vector2(688, 279), Vector2(43, 279)], Color(P.PEACH_TABLE.darkened(0.28), 0.45), 101)
	_poly([Vector2(10, 46), Vector2(710, 46), Vector2(701, 262), Vector2(18, 262)], P.PEACH_TABLE.darkened(0.04), 102)
	_poly([Vector2(691, 53), Vector2(710, 46), Vector2(701, 262), Vector2(683, 257)], P.PEACH_TABLE.darkened(0.14), 103)
	_patch(Rect2(24, 83, 666, 158), P.PEACH_MAT, 104)
	_patch(Rect2(34, 91, 644, 140), P.PEACH_MINT, 105)
	_poly([Vector2(34, 91), Vector2(678, 91), Vector2(660, 105), Vector2(46, 105)], P.PEACH_MINT.lerp(P.PEACH_TEAL, 0.2), 106)
	_poly([Vector2(34, 91), Vector2(46, 105), Vector2(46, 220), Vector2(34, 231)], P.PEACH_MINT.lerp(P.PEACH_TEAL, 0.3), 107)
	for x in [70, 294, 515]:
		_poly([Vector2(x, 105), Vector2(x + 60, 105), Vector2(x - 5, 220), Vector2(x - 27, 220)], Color(P.PEACH_PAPER, 0.21), x)
	_poly([Vector2(0, 22), Vector2(678, 16), Vector2(719, 47), Vector2(12, 55)], P.PEACH_TABLE.lerp(P.PEACH_PAPER, 0.15), 108)
	_poly([Vector2(12, 55), Vector2(719, 47), Vector2(710, 65), Vector2(13, 71)], P.PEACH_TABLE.darkened(0.035), 109)
	for x in [127, 273, 419, 565]:
		_poly([Vector2(x - 26, 223), Vector2(x + 49, 223), Vector2(x + 42, 207), Vector2(x - 21, 207)], P.PEACH_PAPER_MUTED, x + 1)
	_patch(Rect2(19, 238, 678, 18), P.PEACH_TABLE, 110)
	_patch(Rect2(19, 254, 678, 7), P.PEACH_TABLE.darkened(0.16), 111)
	for x in [36, 680]:
		_patch(Rect2(x, 261, 16, 19), P.PEACH_TEAL, x + 2)


func _vending() -> void:
	# Paint planes give the cabinet its depth; small products retain printed ink.
	_poly([Vector2(16, 17), Vector2(278, 17), Vector2(295, 0), Vector2(30, 0)], P.PEACH_MINT.lerp(P.PEACH_TEAL, 0.25), 121)
	_poly([Vector2(277, 16), Vector2(295, 0), Vector2(295, 475), Vector2(277, 491)], P.PEACH_TEAL.darkened(0.15), 122)
	_patch(Rect2(8, 17, 271, 474), P.PEACH_TEAL, 123)
	_patch(Rect2(25, 35, 230, 29), P.PEACH_PAPER, 124)
	for x in [107, 126, 145]:
		_patch(Rect2(x, 42, 13, 16), P.PEACH_MINT, x)
	_patch(Rect2(23, 80, 192, 272), P.PEACH_MAT.darkened(0.1), 125)
	_patch(Rect2(32, 89, 174, 252), P.PEACH_MINT, 126)
	_patch(Rect2(32, 89, 174, 14), P.PEACH_MINT.lerp(P.PEACH_TEAL, 0.25), 127)
	for row in range(3):
		for column in range(3):
			var x := 43.0 + column * 53.0
			var y := 108.0 + row * 76.0
			var color: Color = [P.PEACH_TABLE, P.PEACH_PAPER, P.PEACH_TEAL][(row + column) % 3]
			INK.paper(self, Rect2(x, y, 33, 47), color, P.PEACH_INK, false, 1.3)
			INK.paper(self, Rect2(x + 7, y + 11, 19, 22), P.PEACH_PAPER, P.PEACH_INK, false, 1.0)
			INK.line(self, Vector2(x + 3, y + 4), Vector2(x + 29, y + 4), P.PEACH_INK, 1.0)
			for coil in range(4):
				draw_arc(Vector2(x + 5 + coil * 8, y + 50), 5.2, -PI * 0.7, PI * 0.7, 12, P.PEACH_MAT, 1.2, true)
		_patch(Rect2(35, 164 + row * 76, 169, 5), P.PEACH_MAT, 130 + row)
	_patch(Rect2(228, 86, 34, 30), P.PEACH_PAPER, 133)
	_patch(Rect2(235, 99, 20, 3), P.PEACH_TEAL, 134)
	for row in range(4):
		for column in range(2):
			_patch(Rect2(228 + column * 17, 136 + row * 20, 14, 16), P.PEACH_TEAL.darkened(0.2), 140 + row * 2 + column)
			_patch(Rect2(229 + column * 17, 137 + row * 20, 12, 13), P.PEACH_PAPER, 150 + row * 2 + column)
	_patch(Rect2(231, 238, 26, 63), P.PEACH_INK, 160)
	_patch(Rect2(238, 247, 13, 3), P.PEACH_PAPER_MUTED, 161)
	PAINT.ellipse(self, Rect2(237, 274, 12, 12), P.PEACH_CARD_FRAME, 162)
	_patch(Rect2(46, 382, 171, 62), P.PEACH_INK, 163)
	_patch(Rect2(56, 391, 151, 41), P.PEACH_CARD_FRAME, 164)
	_patch(Rect2(56, 391, 151, 7), P.PEACH_CARD_FRAME.darkened(0.16), 165)
	for x in [28, 235]:
		_patch(Rect2(x, 490, 23, 9), P.PEACH_MAT, x + 3)
	_poly([Vector2(39, 95), Vector2(73, 95), Vector2(38, 235)], Color(P.PEACH_PAPER, 0.18), 166)


func _leaf(origin: Vector2, target: Vector2, width: float, fill: Color, seed: int) -> void:
	# Broad asymmetric leaf masses, with the stem expressed in the same local green.
	var middle := origin.lerp(target, 0.54)
	var normal := (target - origin).orthogonal().normalized() * width
	_poly([origin, origin.lerp(target, 0.22) + normal * 0.55, middle + normal, origin.lerp(target, 0.82) + normal * 0.55, target, origin.lerp(target, 0.79) - normal * 0.45, middle - normal * 0.76, origin.lerp(target, 0.23) - normal * 0.37], fill, seed)


func _plant() -> void:
	var targets: Array[Vector2] = [Vector2(18, 75), Vector2(29, 40), Vector2(63, 10), Vector2(102, 29), Vector2(131, 67), Vector2(114, 103)]
	for index in range(targets.size()):
		var target := targets[index]
		var origin := Vector2(70, 147)
		var fill := P.PEACH_TEAL if index % 3 == 0 else P.PEACH_HEALTH
		if index % 3 == 2:
			fill = P.PEACH_HEALTH.lerp(P.PEACH_MINT, 0.32)
		_poly([origin + Vector2(-1.2, 0), target + Vector2(-0.9, 0), target + Vector2(1.2, 0), origin + Vector2(1.2, 0)], fill, 170 + index)
		_leaf(origin.lerp(target, 0.27), target, 19, fill, 180 + index)
	# A few overlapping lower leaves keep the pot rooted in a full organic silhouette.
	_leaf(Vector2(69, 139), Vector2(24, 112), 14, P.PEACH_HEALTH, 188)
	_leaf(Vector2(71, 137), Vector2(122, 121), 13, P.PEACH_TEAL, 189)
	_poly([Vector2(35, 140), Vector2(105, 140), Vector2(96, 192), Vector2(43, 192)], P.PEACH_PAPER, 190)
	_poly([Vector2(83, 144), Vector2(105, 140), Vector2(96, 192), Vector2(81, 192)], P.PEACH_PAPER_MUTED, 191)
	_patch(Rect2(31, 132, 78, 14), P.PEACH_PAPER_MUTED, 192)
	_patch(Rect2(34, 132, 72, 5), P.PEACH_TABLE, 193)


func _table() -> void:
	for x in [28, 297]:
		_patch(Rect2(x, 82, 16, 136), P.PEACH_TABLE.darkened(0.1), x)
	_poly([Vector2(27, 9), Vector2(343, 9), Vector2(359, 99), Vector2(0, 99)], P.PEACH_TABLE, 201)
	_poly([Vector2(0, 99), Vector2(359, 99), Vector2(355, 109), Vector2(4, 109)], P.PEACH_TABLE.darkened(0.13), 202)
	_poly([Vector2(49, 23), Vector2(317, 23), Vector2(331, 78), Vector2(28, 78)], P.PEACH_TEAL, 203)
	# Foreground playing cards remain little inked pieces on the lineless furniture.
	for index in range(3):
		INK.paper(self, Rect2(90 + index * 39, 45, 25, 36), P.PEACH_PAPER, P.PEACH_INK, false, 1.1)
