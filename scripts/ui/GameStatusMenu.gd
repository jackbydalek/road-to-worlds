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
@onready var product_viewport: SubViewport = $DoorDisplay/DoorMargin/DoorContent/SummaryRow/SavedDeckFrame/SavedDeckMount/SavedProductViewportContainer/SavedProductViewport
@onready var product_pivot: Node3D = %SavedProductPivot
@onready var status_lines: Array[Label] = [%StatusLine1, %StatusLine2, %StatusLine3, %StatusLine4]
@onready var continue_button: Button = %ContinueRunButton
@onready var view_deck_button: Button = %SavedDeckCollectionButton
@onready var options_panel: PanelContainer = %GameStartOptionsPanel
@onready var debug_button: Button = %OpenDebugMenuButton
@onready var storefront: StorefrontBackdrop = $StorefrontBackdrop
@onready var door_display: PanelContainer = $DoorDisplay
@onready var action_column: VBoxContainer = $ActionColumn
@onready var saved_deck_frame: PanelContainer = $DoorDisplay/DoorMargin/DoorContent/SummaryRow/SavedDeckFrame
@onready var saved_status_frame: PanelContainer = $DoorDisplay/DoorMargin/DoorContent/SummaryRow/SavedGameStatusFrame
@onready var options_button: Button = %GameStartOptionsButton

var transition_in_progress := false

const PRODUCT_SCENES := {
	"draft_night": preload("res://assets/season_setup/booster_box.tscn"),
}
const STARTER_FRONT_TEXTURES := {
	"spicy": preload("res://assets/season_setup/starter_spicy.png"),
	"hearty": preload("res://assets/season_setup/starter_hearty.png"),
	"sweet": preload("res://assets/season_setup/starter_sweet_alpha.png"),
}
const STARTER_FRONT_REGION := Rect2(0, 0, 420, 720)


func _ready() -> void:
	%ContinueRunButton.pressed.connect(continue_requested.emit)
	%NewGameButton.pressed.connect(new_game_requested.emit)
	%SavedDeckCollectionButton.pressed.connect(view_deck_requested.emit)
	%GameStartBackButton.pressed.connect(_request_back_to_title)
	%GameStartTutorialButton.pressed.connect(tutorial_requested.emit)
	%GameStartSettingsButton.pressed.connect(settings_requested.emit)
	%OpenDebugMenuButton.pressed.connect(debug_requested.emit)
	%GameStartOptionsButton.pressed.connect(func() -> void: options_panel.visible = not options_panel.visible)
	resized.connect(_layout_gateway)
	call_deferred("_layout_gateway")


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
	var lines: Array = data.get("status_lines", [])
	for index in range(status_lines.size()):
		status_lines[index].text = String(lines[index]) if index < lines.size() else ""
		status_lines[index].visible = index < lines.size() and String(lines[index]) != ""
	var has_save := bool(data.get("has_save", false))
	var product_id := "draft_night" if bool(data.get("drafted", false)) else String(data.get("starter_id", ""))
	var has_starter_front := has_save and STARTER_FRONT_TEXTURES.has(product_id)
	var has_3d_product := has_save and not has_starter_front and PRODUCT_SCENES.has(product_id)
	product_viewport_container.visible = has_3d_product
	deck_placeholder_mount.visible = not has_3d_product
	if has_starter_front:
		deck_art.queue_free()
		deck_placeholder_mount.add_child(_make_starter_front(product_id))
	else:
		deck_placeholder_mount.add_child(deck_art)
	_configure_saved_product(product_id if has_3d_product else "")
	var finished := bool(data.get("finished", false))
	continue_button.disabled = not has_save or finished
	view_deck_button.disabled = not has_save
	debug_button.visible = development_tools_enabled
	options_panel.custom_minimum_size.y = 304.0 if development_tools_enabled else 236.0
	options_panel.offset_top = -332.0 if development_tools_enabled else -264.0
	_layout_gateway()


func _make_starter_front(product_id: String) -> TextureRect:
	var cropped := AtlasTexture.new()
	cropped.atlas = STARTER_FRONT_TEXTURES[product_id]
	cropped.region = STARTER_FRONT_REGION
	var front := TextureRect.new()
	front.name = "SavedStarterProductArt"
	front.texture = cropped
	front.custom_minimum_size = Vector2(142, 244)
	front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return front


func _layout_gateway(available_size: Vector2 = Vector2.ZERO) -> void:
	if not is_node_ready():
		return
	var viewport_size := available_size if available_size.x > 0.0 and available_size.y > 0.0 else size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var compact := viewport_size.y < 760.0
	var edge := 14.0 if compact else 24.0
	var action_height := 136.0 if compact else 146.0
	var gap := 10.0 if compact else 22.0
	var panel_width := minf(360.0, maxf(292.0, viewport_size.x - edge * 2.0))
	var action_width := minf(340.0, maxf(280.0, viewport_size.x - edge * 2.0))
	var maximum_door_height := viewport_size.y - edge * 2.0 - gap - action_height
	var door_height := minf(546.0, maxf(350.0, maximum_door_height))
	var total_height := door_height + gap + action_height
	var top := maxf(edge, (viewport_size.y - total_height) * 0.5)

	door_display.set_anchors_preset(Control.PRESET_TOP_LEFT)
	door_display.position = Vector2((viewport_size.x - panel_width) * 0.5, top)
	door_display.size = Vector2(panel_width, door_height)
	action_column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	action_column.position = Vector2((viewport_size.x - action_width) * 0.5, top + door_height + gap)
	action_column.size = Vector2(action_width, action_height)
	continue_button.custom_minimum_size.y = 54.0 if compact else 66.0
	%NewGameButton.custom_minimum_size.y = 50.0 if compact else 60.0
	saved_deck_frame.custom_minimum_size.y = 178.0 if compact else 274.0
	saved_status_frame.custom_minimum_size.y = 108.0 if compact else 146.0
	product_viewport_container.custom_minimum_size.y = 166.0 if compact else 244.0
	var starter_front := deck_placeholder_mount.get_node_or_null("SavedStarterProductArt") as TextureRect
	if starter_front != null:
		starter_front.custom_minimum_size = Vector2(100, 166) if compact else Vector2(142, 244)

	if compact:
		options_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		options_button.position = Vector2(viewport_size.x - 172.0, 14.0)
		options_button.size = Vector2(158.0, 58.0)
		options_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		options_panel.position = Vector2(viewport_size.x - 338.0, 80.0)
		options_panel.size = Vector2(324.0, options_panel.custom_minimum_size.y)
	else:
		options_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		options_button.position = Vector2(viewport_size.x - 184.0, viewport_size.y - 84.0)
		options_button.size = Vector2(158.0, 58.0)
		options_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var panel_top := viewport_size.y - (332.0 if debug_button.visible else 264.0)
		options_panel.position = Vector2(viewport_size.x - 390.0, panel_top)
		options_panel.size = Vector2(324.0, viewport_size.y - 18.0 - panel_top)


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
	product_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


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
