extends RefCounted
class_name LofiOutline

const OUTLINE_SHADER := preload("res://assets/shaders/lofi_outline.gdshader")


static func apply_to_mesh_tree(
	root: Node,
	width: float = 0.045,
	color: Color = Color("#100C18"),
	radial_width: float = 0.0,
	radial_origin: Vector3 = Vector3.ZERO
) -> void:
	if root is MeshInstance3D:
		_apply_to_mesh(root as MeshInstance3D, width, color, radial_width, radial_origin)
	for child in root.get_children():
		apply_to_mesh_tree(child, width, color, radial_width, radial_origin)


static func _apply_to_mesh(
	mesh_instance: MeshInstance3D,
	width: float,
	color: Color,
	radial_width: float,
	radial_origin: Vector3
) -> void:
	if mesh_instance.mesh == null:
		return
	if radial_width > 0.0:
		_add_silhouette_clone(mesh_instance, width, color, radial_width, radial_origin)
		return
	if mesh_instance.material_override is BaseMaterial3D:
		var overridden := (mesh_instance.material_override as BaseMaterial3D).duplicate() as BaseMaterial3D
		overridden.next_pass = _outline_material(width, color, radial_width, radial_origin)
		mesh_instance.material_override = overridden
		return
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var source := mesh_instance.get_active_material(surface_index)
		if not source is BaseMaterial3D:
			continue
		var outlined := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
		outlined.next_pass = _outline_material(width, color, radial_width, radial_origin)
		mesh_instance.set_surface_override_material(surface_index, outlined)


static func _outline_material(width: float, color: Color, radial_width: float, radial_origin: Vector3) -> ShaderMaterial:
	var outline_pass := ShaderMaterial.new()
	outline_pass.shader = OUTLINE_SHADER
	outline_pass.set_shader_parameter("outline_color", color)
	outline_pass.set_shader_parameter("outline_width", width)
	outline_pass.set_shader_parameter("radial_width", radial_width)
	outline_pass.set_shader_parameter("radial_origin", radial_origin)
	return outline_pass


static func _add_silhouette_clone(
	mesh_instance: MeshInstance3D,
	width: float,
	color: Color,
	radial_width: float,
	radial_origin: Vector3
) -> void:
	var parent := mesh_instance.get_parent()
	if parent == null:
		return
	var outline := MeshInstance3D.new()
	outline.name = "%s_LofiOutline" % mesh_instance.name
	outline.mesh = mesh_instance.mesh
	outline.skin = mesh_instance.skin
	outline.skeleton = mesh_instance.skeleton
	outline.transform = mesh_instance.transform
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.extra_cull_margin = radial_width * 2.0
	outline.set_meta("lofi_outline_clone", true)
	var outline_material := ShaderMaterial.new()
	outline_material.shader = OUTLINE_SHADER
	outline_material.set_shader_parameter("outline_color", color)
	outline_material.set_shader_parameter("outline_width", width)
	outline_material.set_shader_parameter("radial_width", radial_width)
	outline_material.set_shader_parameter("radial_origin", radial_origin)
	outline.material_override = outline_material
	parent.add_child(outline)
	parent.move_child(outline, mesh_instance.get_index())
