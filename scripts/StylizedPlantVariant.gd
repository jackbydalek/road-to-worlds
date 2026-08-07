extends Node3D

const GAME_PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ILLUSTRATED_SHADER := preload("res://assets/shaders/illustrated_cafe_palette.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/lofi_outline.gdshader")
const PLANT_OUTLINE_WORLD_WIDTH := 0.022

enum PlantVariant {
	TALL_LEAFY,
	ROSETTE,
	CACTUS,
}

const VARIANT_NODES := {
	PlantVariant.TALL_LEAFY: [
		"Cube", "Cube_001", "Cube_002", "Cube_003", "Cube_004", "Cube_005",
		"Cube_006", "Cube_007", "Cube_008", "Cube_009", "Cube_010", "Cube_011",
		"Cube_012", "Cube_013", "Cube_014", "Cube_015", "Cube_016", "Cube_017",
		"Cube_018", "Cube_019", "Cube_020", "Cube_021",
	],
	PlantVariant.ROSETTE: [
		"Cube_022", "Cube_023", "Cube_024", "Cube_025", "Cube_026", "Cube_027",
		"Cube_028", "Cube_029", "Cube_030", "Cube_031", "Cube_032", "Cube_034",
		"Cube_035", "Cube_036", "Cube_037", "Cube_038", "Cube_039",
	],
	PlantVariant.CACTUS: [
		"Cube_040", "Cube_041", "Cube_042", "Cube_043", "Cube_044",
		"Sphere_000", "Sphere_001", "Sphere_009",
	],
}

const FOLIAGE_MATERIALS := [
	"material.001",
	"material.006",
	"material.007",
	"material.008",
]

@export_enum("Tall Leafy", "Rosette", "Cactus") var variant: int = PlantVariant.TALL_LEAFY
@export_range(0.1, 3.0, 0.05) var target_height := 1.25


func _ready() -> void:
	call_deferred("_configure_variant")


func _configure_variant() -> void:
	var plant_pack := get_node_or_null("PlantPack") as Node3D
	if plant_pack == null:
		push_warning("StylizedPlantVariant is missing its PlantPack scene.")
		return
	var source_root := plant_pack.find_child("Root", true, false) as Node3D
	if source_root == null:
		push_warning("StylizedPlantVariant could not find the imported Root node.")
		return

	var kept_names: Array = VARIANT_NODES.get(variant, VARIANT_NODES[PlantVariant.TALL_LEAFY])
	for child in source_root.get_children():
		if child is Node3D:
			(child as Node3D).visible = String(child.name) in kept_names

	_normalize_visible_variant(plant_pack)
	_stylize_visible_meshes(plant_pack)


func _stylize_visible_meshes(plant_pack: Node3D) -> void:
	for child in plant_pack.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.get_active_material(surface_index)
			var source_texture: Texture2D
			var source_tint := Color.WHITE
			var palette_role := 0
			if source_material is BaseMaterial3D:
				var base_material := source_material as BaseMaterial3D
				source_texture = base_material.albedo_texture
				source_tint = base_material.albedo_color
				var material_name := source_material.resource_name.to_lower()
				if material_name in FOLIAGE_MATERIALS:
					palette_role = 2
				elif material_name == "material.002":
					palette_role = 3

			var illustrated := ShaderMaterial.new()
			illustrated.shader = ILLUSTRATED_SHADER
			var outline := ShaderMaterial.new()
			outline.shader = OUTLINE_SHADER
			outline.set_shader_parameter("outline_color", GAME_PALETTE.NAVY)
			# Source leaves and pots use very different internal scales. Compensate
			# per mesh so their silhouette reads at a consistent gameplay width.
			var mesh_scale := mesh_instance.global_transform.basis.get_scale()
			var largest_axis := maxf(mesh_scale.x, maxf(mesh_scale.y, mesh_scale.z))
			outline.set_shader_parameter(
				"outline_width",
				clampf(PLANT_OUTLINE_WORLD_WIDTH / maxf(largest_axis, 0.001), 0.006, 0.18)
			)
			illustrated.next_pass = outline
			illustrated.set_shader_parameter("use_texture", source_texture != null)
			illustrated.set_shader_parameter("source_texture", source_texture)
			illustrated.set_shader_parameter("source_tint", source_tint)
			illustrated.set_shader_parameter("palette_role", palette_role)
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


func _normalize_visible_variant(plant_pack: Node3D) -> void:
	var has_bounds := false
	var minimum := Vector3.ZERO
	var maximum := Vector3.ZERO
	var pack_inverse := plant_pack.global_transform.affine_inverse()
	for child in plant_pack.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var aabb := mesh_instance.get_aabb()
		var to_pack := pack_inverse * mesh_instance.global_transform
		for corner_index in 8:
			var point := to_pack * aabb.get_endpoint(corner_index)
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
	plant_pack.scale = Vector3.ONE * uniform_scale
	plant_pack.position = Vector3(
		-center.x * uniform_scale,
		-minimum.y * uniform_scale,
		-center.z * uniform_scale
	)
