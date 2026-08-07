extends SceneTree

const DEMO_SCENE := preload("res://scenes/StylizedShopDemo.tscn")
const ILLUSTRATED_SHADER_PATH := "res://assets/shaders/illustrated_cafe_palette.gdshader"
const NEO_PALETTE_SHADER_PATH := "res://assets/shaders/neo_shopkeeper_palette.gdshader"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var demo := DEMO_SCENE.instantiate()
	root.add_child(demo)
	for _frame in 5:
		await process_frame

	var world := demo.get_node_or_null("ViewportContainer/SubViewport/World") as Node3D
	_expect(world != null, "The stylized demo did not inherit the greybox World hierarchy.")
	if world != null:
		_expect(not (world.get_node("Floor") as Node3D).visible, "The legacy greybox floor is still visible.")
		_expect(world.get_node_or_null("counter") != null, "The left card display case is missing.")
		_expect(world.get_node_or_null("counter2") != null, "The right card display case is missing.")
		_expect(world.get_node_or_null("NPC/ShopkeeperModel") != null, "The existing shopkeeper is missing.")
		var neo_stage := world.get_node_or_null("NPC/ShopkeeperModel/NeoShopkeeperStage") as Node3D
		var neo_shopkeeper := world.get_node_or_null("NPC/ShopkeeperModel/NeoShopkeeperStage/NeoShopkeeperPrototype") as Node3D
		_expect(neo_stage != null, "The replacement shopkeeper stage is missing.")
		_expect(neo_shopkeeper != null, "The replacement Neo shopkeeper is missing from the interaction anchor.")
		if neo_shopkeeper != null:
			var animation_player := neo_shopkeeper.find_child("AnimationPlayer", true, false) as AnimationPlayer
			_expect(animation_player != null, "The replacement shopkeeper rig lost its AnimationPlayer.")
			_expect(
				animation_player != null and animation_player.has_animation(&"idle pose"),
				"The replacement shopkeeper's idle animation was not imported."
			)
			var has_palette_material := false
			for child in neo_shopkeeper.find_children("*", "MeshInstance3D", true, false):
				var mesh_instance := child as MeshInstance3D
				for surface_index in mesh_instance.mesh.get_surface_count():
					var material := mesh_instance.get_active_material(surface_index) as ShaderMaterial
					if material != null and material.shader != null and material.shader.resource_path == NEO_PALETTE_SHADER_PATH:
						has_palette_material = true
						_expect(material.next_pass != null, "The replacement shopkeeper lost its navy silhouette pass.")
			_expect(has_palette_material, "The replacement shopkeeper lost its opaque illustrated palette shader.")

		var cafe := world.get_node_or_null("StylizedAssets/LowPolyCafe") as Node3D
		var table_set := world.get_node_or_null("StylizedAssets/CoffeeTableSet") as Node3D
		var plants := world.get_node_or_null("StylizedAssets/InteriorPlantsLeft") as Node3D
		_expect(cafe != null, "The supplied low-poly café is missing.")
		_expect(table_set != null, "The supplied coffee table is missing.")
		_expect(plants != null, "The supplied stylized plants are missing.")

		if cafe != null:
			var cafe_meshes := cafe.find_children("*", "MeshInstance3D", true, false)
			_expect(not cafe_meshes.is_empty(), "The café import did not expose any meshes.")
			if not cafe_meshes.is_empty():
				var mesh := cafe_meshes[0] as MeshInstance3D
				var material := mesh.get_active_material(0) as ShaderMaterial
				_expect(
					material != null and material.shader != null and material.shader.resource_path == ILLUSTRATED_SHADER_PATH,
					"The café did not receive the illustrated palette shader."
				)

		var environment_node := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
		_expect(
			environment_node != null
			and environment_node.environment.background_color.is_equal_approx(Color("#E8E3F5")),
			"The demo did not switch to the bright lavender-glass daylight background."
		)

	root.remove_child(demo)
	demo.queue_free()
	if failures.is_empty():
		print("StylizedShopDemoSmokeTest: PASS")
		quit()
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
