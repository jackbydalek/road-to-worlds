extends Control
class_name GameStatusMenu

signal continue_requested
signal new_game_requested
signal view_deck_requested
signal back_requested
signal tutorial_requested
signal settings_requested
signal debug_requested

@onready var deck_placeholder_mount: CenterContainer = %SavedDeckPlaceholderMount
@onready var product_viewport_container: SubViewportContainer = %SavedProductViewportContainer
@onready var product_pivot: Node3D = %SavedProductPivot
@onready var status_lines: Array[Label] = [%StatusLine1, %StatusLine2, %StatusLine3, %StatusLine4]
@onready var continue_button: Button = %ContinueRunButton
@onready var view_deck_button: Button = %SavedDeckCollectionButton
@onready var options_panel: PanelContainer = %GameStartOptionsPanel
@onready var debug_button: Button = %OpenDebugMenuButton
@onready var storefront: StorefrontBackdrop = $StorefrontBackdrop

var transition_in_progress := false

const PRODUCT_SCENES := {
	"spicy": preload("res://assets/season_setup/starter_spicy.tscn"),
	"hearty": preload("res://assets/season_setup/starter_hearty.tscn"),
	"sweet": preload("res://assets/season_setup/starter_sweet.tscn"),
	"draft_night": preload("res://assets/season_setup/booster_box.tscn"),
}


func _ready() -> void:
	%ContinueRunButton.pressed.connect(continue_requested.emit)
	%NewGameButton.pressed.connect(new_game_requested.emit)
	%SavedDeckCollectionButton.pressed.connect(view_deck_requested.emit)
	%GameStartBackButton.pressed.connect(_request_back_to_title)
	%GameStartTutorialButton.pressed.connect(tutorial_requested.emit)
	%GameStartSettingsButton.pressed.connect(settings_requested.emit)
	%OpenDebugMenuButton.pressed.connect(debug_requested.emit)
	%GameStartOptionsButton.pressed.connect(func() -> void: options_panel.visible = not options_panel.visible)


func _request_back_to_title() -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := create_tween().set_parallel(true)
	for item: CanvasItem in [
		$DoorDisplay,
		$ActionColumn,
		%GameStartOptionsButton,
		options_panel,
	]:
		fade.tween_property(item, "modulate:a", 0.0, 0.26)
	await storefront.transition_to("overview")
	back_requested.emit()


func configure(data: Dictionary, deck_art: Control, development_tools_enabled: bool) -> void:
	for child in deck_placeholder_mount.get_children():
		child.queue_free()
	deck_placeholder_mount.add_child(deck_art)
	var lines: Array = data.get("status_lines", [])
	for index in range(status_lines.size()):
		status_lines[index].text = String(lines[index]) if index < lines.size() else ""
		status_lines[index].visible = index < lines.size() and String(lines[index]) != ""
	var has_save := bool(data.get("has_save", false))
	var product_id := "draft_night" if bool(data.get("drafted", false)) else String(data.get("starter_id", ""))
	var has_product := has_save and PRODUCT_SCENES.has(product_id)
	product_viewport_container.visible = has_product
	deck_placeholder_mount.visible = not has_product
	_configure_saved_product(product_id if has_product else "")
	var finished := bool(data.get("finished", false))
	continue_button.disabled = not has_save or finished
	view_deck_button.disabled = not has_save
	debug_button.visible = development_tools_enabled
	options_panel.custom_minimum_size.y = 304.0 if development_tools_enabled else 236.0
	options_panel.offset_top = -332.0 if development_tools_enabled else -264.0


func _configure_saved_product(product_id: String) -> void:
	for child in product_pivot.get_children():
		product_pivot.remove_child(child)
		child.queue_free()
	if not PRODUCT_SCENES.has(product_id):
		return
	var product := (PRODUCT_SCENES[product_id] as PackedScene).instantiate() as Node3D
	product_pivot.add_child(product)
	product.rotation_degrees = Vector3(0, 180, 0) if product_id == "draft_night" else Vector3(0, -90, 0)
	_flatten_product_lighting(product)
	_fit_product(product)


func _flatten_product_lighting(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh_instance.material_override is BaseMaterial3D:
			var material := mesh_instance.material_override.duplicate() as BaseMaterial3D
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh_instance.material_override = material
		elif mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material := mesh_instance.get_active_material(surface_index)
				if source_material is BaseMaterial3D:
					var material := source_material.duplicate() as BaseMaterial3D
					material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mesh_instance.set_surface_override_material(surface_index, material)
	for child in node.get_children():
		_flatten_product_lighting(child)


func _fit_product(product: Node3D) -> void:
	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_product_meshes(product, mesh_nodes)
	if mesh_nodes.is_empty():
		return
	var pivot_inverse := product_pivot.global_transform.affine_inverse()
	var bounds := AABB()
	var has_point := false
	for mesh_node in mesh_nodes:
		var mesh_to_pivot := pivot_inverse * mesh_node.global_transform
		var mesh_bounds := mesh_node.get_aabb()
		for endpoint_index in range(8):
			var point := mesh_to_pivot * mesh_bounds.get_endpoint(endpoint_index)
			if has_point:
				bounds = bounds.expand(point)
			else:
				bounds = AABB(point, Vector3.ZERO)
				has_point = true
	var widest_side := maxf(bounds.size.x, bounds.size.z)
	var fit_scale := minf(2.35 / maxf(bounds.size.y, 0.001), 2.35 / maxf(widest_side, 0.001))
	product.scale = Vector3.ONE * fit_scale
	product.position = -bounds.get_center() * fit_scale


func _collect_product_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_product_meshes(child, meshes)
