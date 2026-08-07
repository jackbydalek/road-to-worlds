extends Control
class_name SeasonSetupMenu

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

signal back_requested
signal starter_selected_requested(index: int)
signal deck_list_requested
signal previous_border_requested
signal next_border_requested
signal confirm_requested
signal difficulty_closed_requested

@onready var starter_art_mount: CenterContainer = %SelectedStarterArtMount
@onready var starter_symbol_mount: CenterContainer = %StarterInfoSymbolMount
@onready var difficulty_scrim: ColorRect = %DifficultyScrim
@onready var border_frame_preview: TextureRect = %BorderFramePreview
@onready var selected_product_pivot: Node3D = %SelectedProductPivot

const BORDER_FRAME_TEXTURES: Array[Texture2D] = [
	preload("res://assets/season_setup/frames/black.png"),
	preload("res://assets/season_setup/frames/blue.png"),
	preload("res://assets/season_setup/frames/yellow.png"),
	preload("res://assets/season_setup/frames/silver.png"),
	preload("res://assets/season_setup/frames/gold.png"),
]

const STARTER_BUTTON_NAMES := [
	"SpicyStarterButton",
	"HeartyStarterButton",
	"SweetStarterButton",
	"DraftNightButton",
]

const PRODUCT_SCENES: Array[PackedScene] = [
	preload("res://assets/season_setup/starter_spicy.tscn"),
	preload("res://assets/season_setup/starter_hearty.tscn"),
	preload("res://assets/season_setup/starter_sweet.tscn"),
	preload("res://assets/season_setup/booster_box.tscn"),
]

const PRODUCT_PREVIEW_ROTATION_SPEED := 0.55


func _ready() -> void:
	_flatten_display_lighting($ShelfViewportContainer/ShelfViewport/World)
	%SeasonSetupBackButton.pressed.connect(back_requested.emit)
	%SpicyStarterButton.pressed.connect(func() -> void: starter_selected_requested.emit(0))
	%HeartyStarterButton.pressed.connect(func() -> void: starter_selected_requested.emit(1))
	%SweetStarterButton.pressed.connect(func() -> void: starter_selected_requested.emit(2))
	%DraftNightButton.pressed.connect(func() -> void: starter_selected_requested.emit(3))
	%StarterDeckContentsButton.pressed.connect(deck_list_requested.emit)
	%PreviousBorderButton.pressed.connect(previous_border_requested.emit)
	%NextBorderButton.pressed.connect(next_border_requested.emit)
	%ConfirmSeasonStartButton.pressed.connect(confirm_requested.emit)
	%CloseDifficultyButton.pressed.connect(difficulty_closed_requested.emit)


func _process(_delta: float) -> void:
	if difficulty_scrim.visible:
		selected_product_pivot.rotation.y = _current_product_rotation()


func _flatten_display_lighting(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh_instance.material_override is BaseMaterial3D:
			var flat_override := mesh_instance.material_override.duplicate() as BaseMaterial3D
			flat_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh_instance.material_override = flat_override
		elif mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material := mesh_instance.get_active_material(surface_index)
				if source_material is BaseMaterial3D:
					var flat_surface := source_material.duplicate() as BaseMaterial3D
					flat_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mesh_instance.set_surface_override_material(surface_index, flat_surface)
	for child in node.get_children():
		_flatten_display_lighting(child)


func configure(data: Dictionary, starter_art: Control) -> void:
	for child in starter_art_mount.get_children():
		child.queue_free()
	starter_art_mount.add_child(starter_art)
	for child in starter_symbol_mount.get_children():
		child.queue_free()
	%SeasonStarterCard.set_meta("starter_id", String(data.get("starter_id", "")))
	%SeasonBorderCard.set_meta("difficulty_id", String(data.get("difficulty_id", "white")))
	%StarterNameLabel.text = String(data.get("starter_title", "")).to_upper()
	%StarterInfoTitle.text = String(data.get("info_title", ""))
	%StarterInfoDetail.text = String(data.get("info_detail", ""))
	%BorderTitle.text = "%s BORDER" % String(data.get("difficulty_name", "Black")).to_upper()
	%BorderRules.text = String(data.get("difficulty_rules", "Base season rules."))
	%BorderStats.text = String(data.get("border_stats", ""))
	%RouteHint.text = String(data.get("route_hint", "STARTS AT THE CARD SHOP"))
	difficulty_scrim.visible = bool(data.get("difficulty_open", false))
	var selected_starter := int(data.get("starter_index", 0))
	_apply_starter_selection(selected_starter if difficulty_scrim.visible else -1)
	_configure_product_preview(selected_starter if difficulty_scrim.visible else -1)
	var selected_difficulty := int(data.get("difficulty_index", 0))
	border_frame_preview.texture = BORDER_FRAME_TEXTURES[clampi(selected_difficulty, 0, BORDER_FRAME_TEXTURES.size() - 1)]
	for index in range(5):
		var pip := get_node("%%SeasonBorderPip%d" % index) as ColorRect
		pip.color = PALETTE.TEAL if index == selected_difficulty else Color(PALETTE.INK, 0.35)


func get_symbol_mount() -> CenterContainer:
	return starter_symbol_mount


func _configure_product_preview(selected_index: int) -> void:
	for child in selected_product_pivot.get_children():
		selected_product_pivot.remove_child(child)
		child.queue_free()
	selected_product_pivot.rotation = Vector3(0, _current_product_rotation(), 0)
	if selected_index < 0 or selected_index >= PRODUCT_SCENES.size():
		return
	var product := PRODUCT_SCENES[selected_index].instantiate() as Node3D
	selected_product_pivot.add_child(product)
	if selected_index == 3:
		product.rotation_degrees = Vector3(0, 180, 0)
	else:
		product.rotation_degrees = Vector3(0, -90, 0)
	_flatten_display_lighting(product)
	_fit_product_to_preview(product)


func _current_product_rotation() -> float:
	return fmod(Time.get_ticks_msec() * 0.001 * PRODUCT_PREVIEW_ROTATION_SPEED, TAU)


func _fit_product_to_preview(product: Node3D) -> void:
	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_preview_meshes(product, mesh_nodes)
	if mesh_nodes.is_empty():
		return
	var pivot_inverse := selected_product_pivot.global_transform.affine_inverse()
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
	var fit_scale := minf(2.55 / maxf(bounds.size.y, 0.001), 2.65 / maxf(widest_side, 0.001))
	product.scale = Vector3.ONE * fit_scale
	product.position = -bounds.get_center() * fit_scale


func _collect_preview_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_preview_meshes(child, meshes)


func _apply_starter_selection(selected_index: int) -> void:
	for index in range(STARTER_BUTTON_NAMES.size()):
		var button := get_node("%%%s" % STARTER_BUTTON_NAMES[index]) as Button
		var style := StyleBoxFlat.new()
		style.bg_color = Color(PALETTE.LAVENDER_GLASS, 0.34) if index == selected_index else Color(0, 0, 0, 0)
		style.border_color = PALETTE.SKY if index == selected_index else Color(0, 0, 0, 0)
		style.set_border_width_all(4 if index == selected_index else 0)
		style.set_corner_radius_all(16)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_color_override("font_color", PALETTE.NAVY)
