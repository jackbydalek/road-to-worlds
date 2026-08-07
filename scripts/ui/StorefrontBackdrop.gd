extends Control
class_name StorefrontBackdrop

const SHOP_TEXTURE := preload("res://assets/title_storefront/PandaMat.png")
const TRANSITION_SECONDS := 0.78
const VIEW_DATA := {
	"overview": {
		"position": Vector3(-0.5, 5.7, 9.5),
		"target": Vector3(-0.5, 5.7, 0.0),
		"fov": 40.0,
	},
	"door": {
		"position": Vector3(2.75, 4.8, 8.5),
		"target": Vector3(2.75, 4.8, 0.0),
		"fov": 12.0,
	},
}

@export_enum("overview", "door") var initial_view := "overview"
@export var straighten_door := false
@export_range(1.5, 8.0, 0.1) var straight_door_size := 1.8

@onready var camera_rig: Node3D = $ViewportContainer/SubViewport/World/CameraRig
@onready var camera: Camera3D = $ViewportContainer/SubViewport/World/CameraRig/Camera3D
@onready var shop_model: Node3D = $ViewportContainer/SubViewport/World/StorefrontShop
@onready var storefront_viewport: SubViewport = $ViewportContainer/SubViewport

var camera_tween: Tween
var current_view := "overview"


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = SHOP_TEXTURE
	material.roughness = 0.86
	material.metallic = 0.0
	_apply_material(shop_model, material)
	set_view_immediate(initial_view)


func set_view_immediate(view_name: String) -> void:
	var resolved := view_name if VIEW_DATA.has(view_name) else "overview"
	current_view = resolved
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	var data: Dictionary = VIEW_DATA[resolved]
	camera_rig.transform = _view_transform(data)
	if resolved == "door" and straighten_door:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = straight_door_size
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = float(data.fov)
	storefront_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func transition_to(view_name: String) -> void:
	var resolved := view_name if VIEW_DATA.has(view_name) else "overview"
	if resolved == current_view:
		return
	current_view = resolved
	var data: Dictionary = VIEW_DATA[resolved]
	if bool(get_tree().root.get_meta("reduced_motion", false)):
		set_view_immediate(resolved)
		return
	storefront_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera_rig, "transform", _view_transform(data), TRANSITION_SECONDS)
	camera_tween.tween_property(camera, "fov", float(data.fov), TRANSITION_SECONDS)
	await camera_tween.finished
	storefront_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _view_transform(data: Dictionary) -> Transform3D:
	var position: Vector3 = data.position
	var target: Vector3 = data.target
	return Transform3D(Basis.IDENTITY, position).looking_at(target, Vector3.UP)


func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material(child, material)
