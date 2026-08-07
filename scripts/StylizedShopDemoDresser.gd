extends Node

const GAME_PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ILLUSTRATED_SHADER := preload("res://assets/shaders/illustrated_cafe_palette.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/lofi_outline.gdshader")
const DISCARD_SHADER := preload("res://assets/shaders/discard_surface.gdshader")
const NEO_PALETTE_SHADER := preload("res://assets/shaders/neo_shopkeeper_palette.gdshader")
const NEO_PALETTE_TEXTURE := preload("res://assets/third_party/stylized_shop/neo_shopkeeper/textures/color_tx.png")

const WORLD_PATH := NodePath("../ViewportContainer/SubViewport/World")
const CAFE_FOLIAGE_MESHES := [
	"Object_16", "Object_18", "Object_24", "Object_28",
	"Object_30", "Object_36", "Object_40",
]
const CAFE_TRUNK_MESHES := [
	"Object_20", "Object_22", "Object_26", "Object_32",
	"Object_34", "Object_38", "Object_42",
]
const HIDDEN_GREYBOX_NODES := [
	"Floor",
	"BackWall",
	"SideWall",
	"shelf",
	"Table",
	"PastelDressing",
	"FeaturedTableProps",
	"ShelfGlow",
	"TableGlow",
	"WindowFill",
]


func _ready() -> void:
	call_deferred("_dress_shop")


func _dress_shop() -> void:
	var world := get_node_or_null(WORLD_PATH) as Node3D
	if world == null:
		push_warning("StylizedShopDemoDresser could not find the greybox World node.")
		return

	for node_name in HIDDEN_GREYBOX_NODES:
		var old_node := world.get_node_or_null(NodePath(node_name)) as Node3D
		if old_node != null:
			old_node.visible = false

	var legacy_shop := get_parent().get_node_or_null("shop good color doornknob inside") as Node3D
	if legacy_shop != null:
		legacy_shop.visible = false

	_configure_existing_cast(world)
	_configure_daylight(world)
	_configure_imported_assets(world)


func _configure_existing_cast(world: Node3D) -> void:
	var left_case := world.get_node_or_null("counter") as Node3D
	var right_case := world.get_node_or_null("counter2") as Node3D
	if left_case != null:
		left_case.position = Vector3(-1.15, -0.93, 1.35)
	if right_case != null:
		right_case.position = Vector3(1.15, -0.93, 1.35)

	# The imported clerk scene has a forward offset inside its own root. This
	# position keeps her behind the two card cases from the overview camera.
	var npc := world.get_node_or_null("NPC") as Node3D
	if npc != null:
		npc.position = Vector3(0.0, 0.0, -0.25)


func _configure_daylight(world: Node3D) -> void:
	var world_environment := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		world_environment.environment = world_environment.environment.duplicate(true)
		world_environment.environment.background_color = GAME_PALETTE.LAVENDER_GLASS
		world_environment.environment.ambient_light_color = GAME_PALETTE.CREAM
		world_environment.environment.ambient_light_energy = 0.9
	var sun := world.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.light_color = GAME_PALETTE.CREAM
		sun.light_energy = 0.82


func _configure_imported_assets(world: Node3D) -> void:
	var assets := world.get_node_or_null("StylizedAssets") as Node3D
	if assets == null:
		return

	var cafe := assets.get_node_or_null("LowPolyCafe") as Node3D
	var table_set := assets.get_node_or_null("CoffeeTableSet") as Node3D
	var plants_left := assets.get_node_or_null("InteriorPlantsLeft") as Node3D
	var plants_right := assets.get_node_or_null("InteriorPlantsRight") as Node3D
	var neo_shopkeeper := assets.get_node_or_null("NeoShopkeeperPrototype") as Node3D

	if table_set != null:
		# The pack contains four widely spaced props. Keep its round table here;
		# the dedicated plant pack supplies the foliage in this composition.
		for unused_name in ["Cube.064", "Cylinder", "Plane.003"]:
			var unused := table_set.find_child(unused_name, true, false) as Node3D
			if unused != null:
				unused.visible = false

	# Background assets rely on clean color shapes. Only the foreground table
	# receives an inverted-hull silhouette; outlining every plant/building mesh
	# was what created the noisy wireframe effect in the first pass.
	_stylize_mesh_tree(cafe, 0.0)
	_stylize_mesh_tree(table_set, 0.12)
	_stylize_mesh_tree(plants_left, 0.0)
	_stylize_mesh_tree(plants_right, 0.0)
	_configure_neo_shopkeeper(world, neo_shopkeeper)


func _stylize_mesh_tree(root: Node, outline_width: float) -> void:
	if root == null:
		return
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.get_active_material(surface_index)
			var source_texture: Texture2D
			var source_tint := Color.WHITE
			if source_material is BaseMaterial3D:
				var base_material := source_material as BaseMaterial3D
				source_texture = base_material.albedo_texture
				source_tint = base_material.albedo_color

			var illustrated := ShaderMaterial.new()
			illustrated.shader = ILLUSTRATED_SHADER
			if outline_width > 0.0:
				var outline := ShaderMaterial.new()
				outline.shader = OUTLINE_SHADER
				outline.set_shader_parameter("outline_color", GAME_PALETTE.NAVY)
				outline.set_shader_parameter("outline_width", outline_width)
				illustrated.next_pass = outline
			illustrated.set_shader_parameter("use_texture", source_texture != null)
			illustrated.set_shader_parameter("source_texture", source_texture)
			illustrated.set_shader_parameter("source_tint", source_tint)
			illustrated.set_shader_parameter("palette_role", _cafe_palette_role(mesh_instance.name))
			illustrated.set_shader_parameter("ink", GAME_PALETTE.NAVY)
			illustrated.set_shader_parameter("cream", GAME_PALETTE.CREAM)
			illustrated.set_shader_parameter("coral", GAME_PALETTE.CORAL)
			illustrated.set_shader_parameter("blush", GAME_PALETTE.BLUSH)
			illustrated.set_shader_parameter("periwinkle", GAME_PALETTE.PERIWINKLE)
			illustrated.set_shader_parameter("sky", GAME_PALETTE.SKY)
			illustrated.set_shader_parameter("honey", GAME_PALETTE.HONEY)
			illustrated.set_shader_parameter("sage", GAME_PALETTE.SAGE)
			illustrated.set_shader_parameter("lavender", GAME_PALETTE.LAVENDER)
			mesh_instance.set_surface_override_material(surface_index, illustrated)


func _cafe_palette_role(mesh_name: StringName) -> int:
	if mesh_name == &"Object_4":
		return 1
	if String(mesh_name) in CAFE_FOLIAGE_MESHES:
		return 2
	if String(mesh_name) in CAFE_TRUNK_MESHES:
		return 3
	return 0


func _configure_neo_shopkeeper(world: Node3D, neo_shopkeeper: Node3D) -> void:
	if neo_shopkeeper == null:
		return
	var shopkeeper_anchor := world.get_node_or_null("NPC/ShopkeeperModel") as Node3D
	if shopkeeper_anchor == null:
		return

	# Keep the established anchor because camera focus, hover highlighting, and
	# menu interactions all target it. Hide the old clerk's meshes, then mount
	# the new rig beneath the same anchor.
	for child in shopkeeper_anchor.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).visible = false
	var stage := Node3D.new()
	stage.name = "NeoShopkeeperStage"
	shopkeeper_anchor.add_child(stage)
	neo_shopkeeper.reparent(stage, false)
	neo_shopkeeper.transform = Transform3D.IDENTITY
	_prepare_neo_materials(neo_shopkeeper)

	var animation_player := neo_shopkeeper.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player != null:
		# These files contain two-frame pose clips rather than continuous idles.
		# The Kayoko-on-Kayoko clip matches this particular skeleton and avoids
		# the root displacement present in the generic "idle pose" clip.
		var idle_name: StringName = &"kayoko action-kayoko armature"
		if not animation_player.has_animation(idle_name):
			var animations := animation_player.get_animation_list()
			idle_name = animations[0] if not animations.is_empty() else &""
		if idle_name != &"":
			animation_player.play(idle_name)
			animation_player.seek(0.05, true)
			animation_player.pause()
	_normalize_shopkeeper_stage(stage, neo_shopkeeper, 2.4)


func _prepare_neo_materials(neo_shopkeeper: Node3D) -> void:
	for child in neo_shopkeeper.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.get_active_material(surface_index)
			if not source is BaseMaterial3D:
				continue
			var material_name := source.resource_name.to_lower()
			if material_name.contains("lewd") or material_name.contains("outline"):
				var discarded := ShaderMaterial.new()
				discarded.shader = DISCARD_SHADER
				mesh_instance.set_surface_override_material(surface_index, discarded)
				continue
			var material := ShaderMaterial.new()
			material.shader = NEO_PALETTE_SHADER
			var outline := ShaderMaterial.new()
			outline.shader = OUTLINE_SHADER
			outline.set_shader_parameter("outline_color", GAME_PALETTE.NAVY)
			# The rig is normalized to roughly 6.5x its authored size. A restrained
			# source-space shell produces a 2-4 px gameplay silhouette after scale.
			outline.set_shader_parameter("outline_width", 0.004)
			material.next_pass = outline
			material.set_shader_parameter("source_texture", NEO_PALETTE_TEXTURE)
			material.set_shader_parameter("ink", GAME_PALETTE.NAVY)
			material.set_shader_parameter("cream", GAME_PALETTE.CREAM)
			material.set_shader_parameter("blush", GAME_PALETTE.BLUSH)
			material.set_shader_parameter("sage", GAME_PALETTE.SAGE)
			mesh_instance.set_surface_override_material(surface_index, material)


func _normalize_shopkeeper_stage(stage: Node3D, shopkeeper: Node3D, target_height: float) -> void:
	var skinned_bounds := _get_skinned_bounds(stage, shopkeeper)
	if skinned_bounds.size.y > 0.001:
		var skinned_scale := target_height / skinned_bounds.size.y
		var skinned_center := skinned_bounds.get_center()
		stage.scale = Vector3.ONE * skinned_scale
		stage.position = Vector3(
			-skinned_center.x * skinned_scale,
			-skinned_bounds.position.y * skinned_scale,
			-skinned_center.z * skinned_scale
		)
		return

	# Fall back to authored mesh bounds for an unskinned replacement model.
	var has_bounds := false
	var minimum := Vector3.ZERO
	var maximum := Vector3.ZERO
	var stage_inverse := stage.global_transform.affine_inverse()
	for child in shopkeeper.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var aabb := mesh_instance.get_aabb()
		var to_stage := stage_inverse * mesh_instance.global_transform
		for corner_index in 8:
			var corner := aabb.get_endpoint(corner_index)
			var point := to_stage * corner
			if not has_bounds:
				minimum = point
				maximum = point
				has_bounds = true
			else:
				minimum = minimum.min(point)
				maximum = maximum.max(point)
	if not has_bounds or maximum.y - minimum.y <= 0.001:
		return
	var uniform_scale := target_height / (maximum.y - minimum.y)
	var center := (minimum + maximum) * 0.5
	stage.scale = Vector3.ONE * uniform_scale
	stage.position = Vector3(-center.x * uniform_scale, -minimum.y * uniform_scale, -center.z * uniform_scale)


func _get_skinned_bounds(stage: Node3D, shopkeeper: Node3D) -> AABB:
	var has_point := false
	var bounds := AABB()
	var stage_inverse := stage.global_transform.affine_inverse()
	for child in shopkeeper.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or mesh_instance.skin == null:
			continue
		var skeleton := mesh_instance.get_node_or_null(mesh_instance.skeleton) as Skeleton3D
		if skeleton == null:
			continue
		var skin := mesh_instance.skin
		var bind_transforms: Array[Transform3D] = []
		for bind_index in skin.get_bind_count():
			var bone_index := skin.get_bind_bone(bind_index)
			if bone_index < 0:
				bone_index = skeleton.find_bone(skin.get_bind_name(bind_index))
			if bone_index >= 0:
				bind_transforms.append(
					skeleton.get_bone_global_pose(bone_index) * skin.get_bind_pose(bind_index)
				)
			else:
				bind_transforms.append(Transform3D.IDENTITY)
		var skeleton_to_stage := stage_inverse * skeleton.global_transform
		for surface_index in mesh_instance.mesh.get_surface_count():
			var override := mesh_instance.get_surface_override_material(surface_index) as ShaderMaterial
			if override != null and override.shader == DISCARD_SHADER:
				continue
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or bones.is_empty() or weights.is_empty():
				continue
			var influence_count := bones.size() / vertices.size()
			for vertex_index in vertices.size():
				var point := Vector3.ZERO
				var total_weight := 0.0
				for influence_index in influence_count:
					var array_index := vertex_index * influence_count + influence_index
					var weight := weights[array_index]
					var bind_index := bones[array_index]
					if weight <= 0.0 or bind_index < 0 or bind_index >= bind_transforms.size():
						continue
					point += (bind_transforms[bind_index] * vertices[vertex_index]) * weight
					total_weight += weight
				if total_weight <= 0.0:
					continue
				point = skeleton_to_stage * (point / total_weight)
				if not has_point:
					bounds = AABB(point, Vector3.ZERO)
					has_point = true
				else:
					bounds = bounds.expand(point)
	return bounds
