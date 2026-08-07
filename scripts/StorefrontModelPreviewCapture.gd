extends SceneTree

const SHOP_SCENE := preload("res://assets/title_storefront/shop.glb")
const SHOP_TEXTURE := preload("res://assets/title_storefront/PandaMat.png")
const OUTPUT_DIR := "res://outputs/storefront_model_preview"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var world := Node3D.new()
	root.add_child(world)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#D9EEF2")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#BFD8E5")
	environment.ambient_light_energy = 0.85
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("#FFE6BD")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	world.add_child(sun)

	var shop := SHOP_SCENE.instantiate()
	shop.position.y = 3.17
	world.add_child(shop)
	var material := StandardMaterial3D.new()
	material.albedo_texture = SHOP_TEXTURE
	material.roughness = 0.86
	_apply_material(shop, material)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 3.3, 15.5)
	camera.fov = 40.0
	world.add_child(camera)
	camera.look_at(Vector3(0, 3.1, -1.65), Vector3.UP)
	camera.current = true

	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/front.png"))
	if result != OK:
		push_error("Could not save storefront model preview.")
		quit(1)
		return
	quit()


func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material(child, material)
