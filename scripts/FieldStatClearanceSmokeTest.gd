extends SceneTree

## Run headlessly. Optional -- --simulate-original-stats reproduces the old
## centered ribbon anchor without production edits; that negative control fails.
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CLEARANCE_EPSILON := 0.001

var failures: Array[String] = []
var checked_poses := 0
var minimum_clearance := INF


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.set_process(false)
	table.animation_busy = false
	table.production_match = true
	for side in ["player", "opponent"]:
		table.state[side].prep = [_unit(table, side, "prep", 0, false, 1, 1)]
		table.state[side].plated = [
			_unit(table, side, "plated", 0, false, 11, 20),
			_unit(table, side, "plated", 1, true, 0, 9),
		]
	table._render_match()
	await process_frame
	await process_frame
	var field_cards: Array[Node3D] = []
	for card: Node3D in table.interactive_cards:
		if String(card.get_meta("kind", "")) == "field":
			field_cards.append(card)
	_expect(field_cards.size() == 6, "Expected six field cards covering both sides, both zones, and Defense.")
	if OS.get_cmdline_user_args().has("--simulate-original-stats"):
		for card in field_cards:
			var stats := card.get_node("Stats") as Label3D
			stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			stats.position = Vector3(0.0, 0.065, 0.61)
		await process_frame
	for card in field_cards:
		_check_clearance(card, table.camera, "rest")
		# A large delta reaches the actual hover target (lift, tilt and scale).
		table.hovered_card = card
		table._animate_physical_cards(1.0, 0.0)
		_check_clearance(card, table.camera, "hover")
		table.hovered_card = null
		table._animate_physical_cards(1.0, 0.0)
	table.queue_free()
	await process_frame
	if failures.is_empty():
		print("FieldStatClearanceSmokeTest PASS: %d real billboard poses; minimum card-face clearance %.5f." % [checked_poses, minimum_clearance])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _unit(table, side: String, zone: String, slot: int, defending: bool, attack: int, health: int) -> Dictionary:
	var card_id := "spicy_hot_honey_bee" if zone == "prep" else "spicy_sriracharrow"
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	unit.defending = defending
	unit.attack = attack
	unit.health = health
	return unit


func _check_clearance(card: Node3D, camera: Camera3D, pose: String) -> void:
	var label := card.get_node_or_null("Stats") as Label3D
	var face := card.get_node_or_null("CardFace") as MeshInstance3D
	var context := "%s (%s)" % [card.name, pose]
	_expect(label != null and face != null, context + " lacks its live stats or physical face.")
	if label == null or face == null:
		return
	var triangles := label.generate_triangle_mesh()
	_expect(triangles != null, context + " produced no text geometry.")
	if triangles == null:
		return
	var vertices := triangles.get_faces()
	_expect(not vertices.is_empty(), context + " produced empty text geometry.")
	if vertices.is_empty():
		return
	# Label3D's shader billboards its mesh; global_transform alone would leave
	# a defending card's text sideways and give the wrong clearance. Preserve
	# inherited axis lengths while orienting the generated text to the camera.
	var text_basis := label.global_basis
	if label.billboard == BaseMaterial3D.BILLBOARD_ENABLED:
		var camera_basis := camera.global_basis.orthonormalized()
		text_basis = Basis(
			camera_basis.x * text_basis.x.length(),
			camera_basis.y * text_basis.y.length(),
			camera_basis.z * text_basis.z.length()
		)
	var face_normal := face.global_basis.z.normalized()
	var clearance := INF
	for vertex in vertices:
		var world_vertex := label.global_position + text_basis * vertex
		clearance = minf(clearance, face_normal.dot(world_vertex - face.global_position))
	minimum_clearance = minf(minimum_clearance, clearance)
	checked_poses += 1
	_expect(clearance > CLEARANCE_EPSILON, "%s text intersects its card face: mesh clearance %.5f (required > %.5f)." % [context, clearance, CLEARANCE_EPSILON])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
