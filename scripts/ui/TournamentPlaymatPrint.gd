extends RefCounted

## Flat editable cloth, ink and sewn edging for each player's locals mat. The public
## corner_frame name is retained for callers; it now draws a complete soft ring.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PRINT_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const INK_HEIGHT := 0.205
const CLOTH_TOP := 0.1975
const CLOTH_THICKNESS := 0.025


static func add_cloth(table: Control, arena: Node3D, node_name: String, side: String, color: Color) -> MeshInstance3D:
	var outline := _cloth_outline(table, side)
	var triangles := Geometry2D.triangulate_polygon(outline)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for index in triangles:
		var point := outline[index]
		vertices.append(Vector3(point.x, CLOTH_TOP, point.y))
		normals.append(Vector3.UP)
	# Actual thin side walls make these two pieces of fabric, rather than two
	# painted rectangles or a single surface with an ornamental middle rule.
	for index in outline.size():
		var start := outline[index]
		var end := outline[(index + 1) % outline.size()]
		var normal := Vector3(end.y - start.y, 0, start.x - end.x).normalized()
		var corners := [
			Vector3(start.x, CLOTH_TOP, start.y),
			Vector3(end.x, CLOTH_TOP, end.y),
			Vector3(end.x, CLOTH_TOP - CLOTH_THICKNESS, end.y),
			Vector3(start.x, CLOTH_TOP - CLOTH_THICKNESS, start.y),
		]
		for vertex_index in [0, 1, 2, 0, 2, 3]:
			vertices.append(corners[vertex_index])
			normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = color
	fabric.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fabric.roughness = 0.98
	fabric.metallic_specular = 0.0
	fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cloth := MeshInstance3D.new()
	cloth.name = node_name
	cloth.mesh = mesh
	cloth.material_override = fabric
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cloth.set_meta("procedural_geometry", true)
	cloth.set_meta("asset_origin", "engine_geometry")
	cloth.set_meta("side", side)
	cloth.set_meta("playmat_side", side)
	# World XZ contour is also the geometric coverage contract for layout QA.
	cloth.set_meta("playmat_outline", outline)
	cloth.set_meta("cloth_color", color)
	arena.add_child(cloth)
	return cloth


static func _cloth_outline(table: Control, side: String) -> PackedVector2Array:
	var half_width: float = table.PRODUCTION_PLAYMAT_WIDTH * 0.5
	var corners: PackedVector2Array
	var far_z: float = table.PRODUCTION_OPPONENT_MAT_FAR_Z if side == "opponent" else table.PRODUCTION_PLAYER_MAT_FAR_Z
	var near_z: float = table.PRODUCTION_OPPONENT_MAT_NEAR_Z if side == "opponent" else table.PRODUCTION_PLAYER_MAT_NEAR_Z
	corners = PackedVector2Array([
		Vector2(-half_width, far_z), Vector2(half_width, far_z),
		Vector2(half_width, near_z), Vector2(-half_width, near_z),
	])
	var outline := PackedVector2Array()
	for index in corners.size():
		var corner := corners[index]
		var previous := corners[(index - 1 + corners.size()) % corners.size()]
		var next := corners[(index + 1) % corners.size()]
		var trim := minf(0.18, minf(corner.distance_to(previous), corner.distance_to(next)) * 0.24)
		var start := corner.move_toward(previous, trim)
		var end := corner.move_toward(next, trim)
		for step in 9:
			var t := float(step) / 8.0
			outline.append(start.lerp(corner, t).lerp(corner.lerp(end, t), t))
	return outline


static func build(table: Control, arena: Node3D) -> void:
	var print_root := Node3D.new()
	print_root.name = "PlaymatPrinting"
	arena.add_child(print_root)
	for node_name in ["InsetPlaymat", "PlayerPlaymat"]:
		var cloth := arena.get_node(node_name) as MeshInstance3D
		_build_cloth_binding(print_root, cloth)
	_build_zone_labels(table, print_root)
	_build_pile_emblems(table, print_root)


static func _build_cloth_binding(parent: Node3D, cloth: MeshInstance3D) -> void:
	var side := String(cloth.get_meta("playmat_side"))
	var outline: PackedVector2Array = cloth.get_meta("playmat_outline")
	var cloth_color: Color = cloth.get_meta("cloth_color")
	var binding := Node3D.new()
	binding.name = "%sBinding" % side.capitalize()
	binding.set_meta("playmat_side", side)
	parent.add_child(binding)
	var ink_origin := Vector3(0, INK_HEIGHT, 0)
	_add_ink_paths(binding, "SoftBoundEdge", [_closed_inset(outline, 0.034)], ink_origin, 0.045, PALETTE.PEACH_INK.darkened(0.23))
	_add_ink_paths(binding, "BoundEdgeInset", [_closed_inset(outline, 0.094)], ink_origin, 0.010, cloth_color.lerp(PALETTE.PEACH_PRINT, 0.18))
	var seam := _closed_inset(outline, 0.145)
	var lengths := PackedFloat32Array([0.0])
	for index in range(seam.size() - 1):
		lengths.append(lengths[index] + seam[index].distance_to(seam[index + 1]))
	var perimeter := float(lengths[lengths.size() - 1])
	var stitches: Array[PackedVector2Array] = []
	var distance := 0.03
	while distance + 0.075 < perimeter:
		stitches.append(PackedVector2Array([
			_path_point(seam, lengths, distance),
			_path_point(seam, lengths, distance + 0.0375),
			_path_point(seam, lengths, distance + 0.075),
		]))
		distance += 0.25
	_add_ink_paths(binding, "QuietStitching", stitches, ink_origin + Vector3(0, 0.001, 0), 0.009, cloth_color.lerp(PALETTE.PEACH_PRINT, 0.30))


static func _closed_inset(outline: PackedVector2Array, inset: float) -> PackedVector2Array:
	var inset_polygons := Geometry2D.offset_polygon(outline, -inset, Geometry2D.JOIN_ROUND)
	var result: PackedVector2Array = inset_polygons[0] if not inset_polygons.is_empty() else outline
	result.append(result[0])
	return result


static func _path_point(path: PackedVector2Array, lengths: PackedFloat32Array, distance: float) -> Vector2:
	for index in range(lengths.size() - 1):
		if distance <= lengths[index + 1]:
			return path[index].lerp(path[index + 1], inverse_lerp(lengths[index], lengths[index + 1], distance))
	return path[path.size() - 1]


static func _build_zone_labels(table: Control, parent: Node3D) -> void:
	var label_color := PALETTE.PEACH_MAT.lerp(PALETTE.PEACH_PRINT, 0.78)
	for zone_id_value in table.ZONE_CENTERS:
		var zone_id := String(zone_id_value)
		var center: Vector3 = table.ZONE_CENTERS[zone_id]
		var extents: Vector2 = table.ZONE_EXTENTS[zone_id]
		if zone_id.ends_with("prep"):
			# Prep names sit on the outside of each owner's row, leaving the
			# space between the two combat rows clear over the exposed table.
			var label_z: float = center.z + (extents.y + 0.18) * (1.0 if zone_id.begins_with("player") else -1.0)
			for index in range(3):
				var label_x: float = center.x + (float(index) - 1.0) * table.PREP_SLOT_SPACING
				var label: Label3D = table._add_surface_label(parent, "%sPrint%d" % [zone_id.to_pascal_case(), index + 1], "PREP", Vector3(label_x, INK_HEIGHT, label_z), label_color)
				_style_label(label, 44)
		else:
			# Like a real printed playmat, small flanking names identify the
			# row without giant central branding or bright ownership stripes.
			for side in [-1.0, 1.0]:
				var label_x: float = center.x + side * (extents.x + 0.60)
				var label: Label3D = table._add_surface_label(parent, "%sPrint" % zone_id.to_pascal_case(), "PLATED", Vector3(label_x, INK_HEIGHT, center.z + 0.52), label_color)
				_style_label(label, 42)


static func _style_label(label: Label3D, font_size: int) -> void:
	label.font = PRINT_FONT
	label.font_size = font_size
	label.pixel_size = 0.006
	label.outline_size = 0


static func _build_pile_emblems(table: Control, parent: Node3D) -> void:
	var ink := PALETTE.PEACH_MAT.lerp(PALETTE.PEACH_PRINT, 0.43)
	for key_value in table.AUX_ZONE_POSITIONS:
		var key := String(key_value)
		var position: Vector3 = table.AUX_ZONE_POSITIONS[key]
		position.y = INK_HEIGHT + 0.001
		if key.ends_with("environment"):
			# An original leaf outline and simple stem, kept lighter than cards.
			var leaf := PackedVector2Array([
				Vector2(-0.15, 0.20), Vector2(-0.25, 0.04), Vector2(-0.21, -0.12),
				Vector2(-0.04, -0.23), Vector2(0.25, -0.29), Vector2(0.24, -0.04),
				Vector2(0.12, 0.17), Vector2(-0.02, 0.23), Vector2(-0.15, 0.20),
			])
			var stem := PackedVector2Array([Vector2(-0.17, 0.34), Vector2(-0.07, 0.09), Vector2(0.16, -0.17)])
			_add_ink_paths(parent, "%sLeafPrint" % key.to_pascal_case(), [leaf, stem], position, 0.031, ink)
		elif key.ends_with("discard"):
			# Two curved return arrows give discard an editable, unbranded mark.
			var paths: Array[PackedVector2Array] = []
			for turn in [0.0, PI]:
				var arc := PackedVector2Array()
				for index in range(17):
					var angle: float = float(turn) + 0.12 + float(index) / 16.0 * PI * 0.75
					arc.append(Vector2(cos(angle), sin(angle)) * 0.28)
				paths.append(arc)
				var end := arc[arc.size() - 1]
				var direction := (end - arc[arc.size() - 2]).normalized()
				var side := Vector2(-direction.y, direction.x)
				paths.append(PackedVector2Array([end - direction * 0.11 + side * 0.10, end, end - direction * 0.11 - side * 0.10]))
			_add_ink_paths(parent, "%sReturnPrint" % key.to_pascal_case(), paths, position, 0.032, ink)


static func corner_frame(_table: Control, parent: Node3D, frame_name: String, center: Vector3, extent: Vector2, _color: Color) -> Node3D:
	var frame := Node3D.new()
	frame.name = frame_name
	parent.add_child(frame)
	# The old caller colors were pale steel/white. Printed slot boundaries now
	# take their warmth and contrast from the reference's worn cloth ink.
	var ink := PALETTE.PEACH_MAT.lerp(PALETTE.PEACH_PRINT, 0.68)
	_add_ink_paths(frame, "RoundedPrintedOutline", [_rounded_rect(extent, 0.095)], center, 0.024, ink)
	return frame


static func _rounded_rect(extent: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := extent * 0.5
	var centers := [
		Vector2(half.x - radius, half.y - radius),
		Vector2(-half.x + radius, half.y - radius),
		Vector2(-half.x + radius, -half.y + radius),
		Vector2(half.x - radius, -half.y + radius),
	]
	for corner in range(4):
		for step in range(9):
			var angle := float(corner) * PI * 0.5 + float(step) / 8.0 * PI * 0.5
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	return points


static func _add_ink_paths(parent: Node3D, node_name: String, paths: Array, origin: Vector3, width: float, color: Color) -> MeshInstance3D:
	# One flat triangle ribbon per path: no raised metal-looking bars, frame
	# shadows, raster texture, or external art asset is needed for the printing.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for path_value in paths:
		var path: PackedVector2Array = path_value
		for index in range(path.size() - 1):
			var start := path[index]
			var end := path[index + 1]
			var direction := (end - start).normalized()
			var offset := Vector2(-direction.y, direction.x) * width * 0.5
			# A slight end overlap closes the tiny seams along the round corners.
			var overlap := direction * minf(width * 0.16, 0.003)
			var quad := [start - overlap + offset, end + overlap + offset, end + overlap - offset, start - overlap - offset]
			for vertex_index in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[vertex_index]
				vertices.append(Vector3(point.x, 0, point.y))
				normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	material.metallic_specular = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = origin
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("procedural_geometry", true)
	instance.set_meta("flat_playmat_ink", true)
	parent.add_child(instance)
	return instance
