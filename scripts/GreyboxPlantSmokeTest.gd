extends SceneTree

const DEMO := preload("res://scenes/GreyboxCameraDemo.tscn")
const PLANT_SCRIPT_PATH := "res://scripts/StylizedPlantVariant.gd"
const ILLUSTRATED_SHADER_PATH := "res://assets/shaders/illustrated_palette.gdshader"
const OUTLINE_SHADER_PATH := "res://assets/shaders/lofi_outline.gdshader"
const STOREFRONT_SHADER_PATH := "res://assets/shaders/storefront_cool_palette.gdshader"
const PLANT_PATHS := [
	"ViewportContainer/SubViewport/World/PastelDressing/WindowMonstera",
	"ViewportContainer/SubViewport/World/PastelDressing/CounterSnakePlant",
	"ViewportContainer/SubViewport/World/PastelDressing/TableCornerPothos",
	"ViewportContainer/SubViewport/World/PastelDressing/CounterSucculent",
]
const POSTER_COLORS := {
	"InteriorWindowPosterStart": Color("#EF7E76"),
	"InteriorWindowPosterHowTo": Color("#68C5E8"),
	"InteriorWindowPosterCredits": Color("#A69AB7"),
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var demo := DEMO.instantiate()
	root.add_child(demo)
	for _frame in 6:
		await process_frame

	for plant_path in PLANT_PATHS:
		var plant := demo.get_node_or_null(plant_path) as Node3D
		_expect(plant != null, "Missing replacement plant at %s." % plant_path)
		if plant == null:
			continue
		_expect(
			plant.get_script() != null and plant.get_script().resource_path == PLANT_SCRIPT_PATH,
			"%s is not using the supplied stylized plant variant." % plant.name
		)
		var visible_mesh_count := 0
		var has_illustrated_material := false
		for child in plant.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			if not mesh_instance.is_visible_in_tree():
				continue
			visible_mesh_count += 1
			for surface_index in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface_index) as ShaderMaterial
				if material != null and material.shader != null and material.shader.resource_path == ILLUSTRATED_SHADER_PATH:
					has_illustrated_material = true
					_expect(_has_outline(material), "%s lost its navy plant outline." % plant.name)
		_expect(visible_mesh_count > 0, "%s did not expose a visible plant cluster." % plant.name)
		_expect(has_illustrated_material, "%s lost its illustrated environment material." % plant.name)

	var floor_mesh := demo.get_node_or_null("ViewportContainer/SubViewport/World/Floor") as MeshInstance3D
	var back_wall := demo.get_node_or_null("ViewportContainer/SubViewport/World/BackWall") as MeshInstance3D
	var door_wall := demo.get_node_or_null("ViewportContainer/SubViewport/World/SideWall") as MeshInstance3D
	_expect(floor_mesh != null, "The greybox floor is missing.")
	_expect(back_wall != null and door_wall != null, "The greybox walls are missing.")
	if floor_mesh != null:
		var floor_material := floor_mesh.get_active_material(0) as BaseMaterial3D
		_expect(floor_material != null, "The greybox floor has no material.")
		if floor_material != null:
			_expect(
				floor_material.albedo_color.is_equal_approx(Color(0.91, 0.82, 0.68, 1.0)),
				"The floor is no longer using the muted pale-wood color."
			)
			_expect(floor_material.albedo_texture == null, "The old yellow floor texture returned.")
	if back_wall != null and door_wall != null:
		var back_material := back_wall.get_active_material(0) as BaseMaterial3D
		var door_wall_material := door_wall.get_active_material(0) as BaseMaterial3D
		_expect(
			back_material != null
			and door_wall_material != null
			and back_material.albedo_color.is_equal_approx(door_wall_material.albedo_color),
			"The back wall no longer matches the lavender door wall."
		)

	var shelf := demo.get_node_or_null("ViewportContainer/SubViewport/World/shelf") as Node3D
	_expect(shelf != null, "The greybox shelves are missing.")
	if shelf != null:
		var shelf_has_outline := false
		for child in shelf.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			for surface_index in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface_index)
				if material != null and _has_outline(material):
					shelf_has_outline = true
		_expect(shelf_has_outline, "The greybox shelves lost their strengthened navy outline.")

	var case_card_count := 0
	var case_card_variants := {"Spicy": 0, "Sweet": 0, "Hearty": 0}
	var case_frame_renderers := demo.get_node_or_null("CaseCardFrameRenderers")
	if case_frame_renderers != null:
		for variant_name in case_card_variants:
			var renderer := case_frame_renderers.get_node_or_null("%sFrameViewport" % variant_name) as SubViewport
			_expect(renderer != null, "The %s case-card frame renderer is missing." % variant_name)
			if renderer != null:
				var rendered_face := renderer.get_node_or_null("%sCaseCardFrame" % variant_name)
				var rendered_frame := rendered_face.find_child("CardFrame", true, false) if rendered_face != null else null
				_expect(
					rendered_frame != null and String(rendered_frame.get_meta("frame_style", "")) == "illustrated_card",
					"The %s display texture is not built from the current illustrated CardFace." % variant_name
				)
	for counter_name in ["counter", "counter2"]:
		var counter := demo.get_node_or_null("ViewportContainer/SubViewport/World/%s" % counter_name)
		_expect(counter != null, "The %s display case is missing." % counter_name)
		if counter == null:
			continue
		for face_value in counter.find_children("CardFace", "MeshInstance3D", true, false):
			var face := face_value as MeshInstance3D
			case_card_count += 1
			var variant_name := String(face.get_meta("case_card_frame_variant", ""))
			_expect(case_card_variants.has(variant_name), "%s has an unknown card-frame variant." % face.get_parent().name)
			if case_card_variants.has(variant_name):
				case_card_variants[variant_name] = int(case_card_variants[variant_name]) + 1
			var render_pending := bool(face.get_meta("current_card_frame_pending", false))
			if render_pending:
				_expect(case_frame_renderers != null, "%s has no pending current-frame renderer." % face.get_parent().name)
			else:
				_expect(
					bool(face.get_meta("uses_current_card_frame", false)),
					"%s is still using a legacy case-card texture." % face.get_parent().name
				)
				var face_material := face.get_active_material(0) as BaseMaterial3D
				_expect(
					face_material != null and face_material.albedo_texture is ImageTexture,
					"%s did not receive a baked current-style card frame." % face.get_parent().name
				)
				if face_material != null:
					_expect(_has_outline(face_material), "%s lost its navy modeled outline." % face.get_parent().name)
	_expect(case_card_count == 48, "Expected 48 current-style cards across the display cases, found %d." % case_card_count)
	for variant_name in case_card_variants:
		_expect(
			int(case_card_variants[variant_name]) == 16,
			"Expected 16 %s case-card frames, found %d." % [variant_name, int(case_card_variants[variant_name])]
		)

	var storefront := demo.get_node_or_null("shop good color doornknob inside") as Node3D
	_expect(storefront != null, "The textured storefront model is missing.")
	_expect(
		demo.get_node_or_null("shop good color doornknob inside/DreamyWindowBackdrop") == null,
		"The removed illustrated window overlay returned."
	)
	if storefront != null:
		var storefront_mesh := storefront.find_child("Env_CommercialBuilding_01", true, false) as MeshInstance3D
		_expect(storefront_mesh != null, "The storefront's actual building mesh is missing.")
		if storefront_mesh != null:
			var storefront_material := storefront_mesh.get_active_material(0) as ShaderMaterial
			_expect(
				storefront_material != null
				and storefront_material.shader != null
				and storefront_material.shader.resource_path == STOREFRONT_SHADER_PATH,
				"The real window, door, and frame surfaces lost their cool palette shader."
			)
			if storefront_material != null:
				var door_color: Color = storefront_material.get_shader_parameter("door_color")
				var expected_door_color := Color("#A69AB7")
				_expect(
					absf(door_color.r - expected_door_color.r) < 0.002
					and absf(door_color.g - expected_door_color.g) < 0.002
					and absf(door_color.b - expected_door_color.b) < 0.002,
					"The door is no longer using its solid room-lavender color."
				)

		for poster_name in POSTER_COLORS:
			var poster := storefront.get_node_or_null(poster_name) as MeshInstance3D
			_expect(poster != null and poster.visible, "%s is not visible in the window." % poster_name)
			if poster == null:
				continue
			var poster_material := poster.get_active_material(0) as BaseMaterial3D
			_expect(poster_material != null, "%s has no poster material." % poster_name)
			if poster_material != null:
				var expected_color: Color = POSTER_COLORS[poster_name]
				var actual_color := poster_material.albedo_color
				_expect(
					absf(actual_color.r - expected_color.r) < 0.003
					and absf(actual_color.g - expected_color.g) < 0.003
					and absf(actual_color.b - expected_color.b) < 0.003,
					"%s is not using its intended role color." % poster_name
				)

	demo.queue_free()
	if failures.is_empty():
		print("GreyboxPlantSmokeTest: PASS")
		quit()
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _has_outline(material: Material) -> bool:
	if material.next_pass == null or not material.next_pass is ShaderMaterial:
		return false
	var outline := material.next_pass as ShaderMaterial
	return outline.shader != null and outline.shader.resource_path == OUTLINE_SHADER_PATH
