extends Node3D

signal starter_shop_requested

const ROAD_STRAIGHT := preload("res://assets/overworld/kenney_prototype/roads/road-straight.glb")
const ROAD_BEND := preload("res://assets/overworld/kenney_prototype/roads/road-bend.glb")
const ROAD_T_JUNCTION := preload("res://assets/overworld/kenney_prototype/roads/road-intersection.glb")
const ROAD_CROSSROAD := preload("res://assets/overworld/kenney_prototype/roads/road-crossroad.glb")
const ROAD_END := preload("res://assets/overworld/kenney_prototype/roads/road-end-round.glb")
const ROAD_DRIVEWAY_SINGLE := preload("res://assets/overworld/kenney_prototype/roads/road-driveway-single.glb")
const ROAD_DRIVEWAY_DOUBLE := preload("res://assets/overworld/kenney_prototype/roads/road-driveway-double.glb")
const STREET_LIGHT := preload("res://assets/overworld/kenney_prototype/roads/light-square.glb")
const SUBURBAN_BUILDINGS := [
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-a.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-c.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-h.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-k.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-m.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-q.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/building-type-t.glb"),
]
const LANDMARK_SHOP := preload("res://assets/overworld/kenney_prototype/suburban/building-type-t.glb")
const LANDMARK_CHAMPIONSHIP := preload("res://assets/overworld/kenney_prototype/suburban/building-type-q.glb")
const TREES := [
	preload("res://assets/overworld/kenney_prototype/suburban/tree-small.glb"),
	preload("res://assets/overworld/kenney_prototype/suburban/tree-large.glb"),
]
const PLANTER := preload("res://assets/overworld/kenney_prototype/suburban/planter.glb")
const DRIVEWAY_SURFACE := preload("res://assets/overworld/kenney_prototype/suburban/driveway-long.glb")
const ROAD_COLORMAP := preload("res://assets/overworld/kenney_prototype/roads/Textures/colormap.png")
const SUBURBAN_COLORMAP := preload("res://assets/overworld/kenney_prototype/suburban/Textures/colormap.png")
const STARTER_CITY_PALETTE_SHADER := preload("res://assets/shaders/starter_city_palette.gdshader")
const USER_GRASS_TEXTURE := preload("res://assets/overworld/starter_city_user/grass.png")
const USER_VEGETATION_TEXTURE := preload("res://assets/overworld/starter_city_user/vegetation_sheet.png")
const USER_GRASS_SHADER := preload("res://assets/shaders/starter_city_user_grass.gdshader")
const USER_PATH_SHADER := preload("res://assets/shaders/starter_city_illustrated_path.gdshader")
const USER_PAVED_GROUND_SHADER := preload("res://assets/shaders/starter_city_paved_ground.gdshader")
const USER_POND_WATER_SHADER := preload("res://assets/shaders/starter_city_pond_water.gdshader")
const USER_PAVING_TEXTURE := preload("res://assets/overworld/starter_city_user/street_brick.png")
const TOWN_NPC_SCRIPT := preload("res://scripts/overworld/TownEncounterNpc.gd")
const TOWN_NPC_TEXTURES := {
	"npc1": preload("res://assets/characters/rivals/route_rival_npc_01.png"),
	"npc2": preload("res://assets/characters/rivals/route_rival_npc_02.png"),
}

const ROAD_HEIGHT := 0.03
const GRID_COLUMN_STEP := 4
const GRID_LANES := [-3, 1, 5, 9]
const NORTH_BUILDING_Z := -5.0
const SOUTH_BUILDING_Z := 11.0
const MIN_ROUTE_CAMERA_SIZE := 12.0
const ROUTE_VERTICAL_PADDING := 4.2
const OVERVIEW_CAMERA_SIZE := 24.0
const CAMERA_ZOOM_SPEED := 34.0
const PLAYER_ROAD_CENTER_OFFSET_Z := 0.0
const USER_PLAYER_SCALE := 0.4
const USER_PLAYER_VISUAL_SCALE := 1.5
const PRODUCTION_ROUTE_ICON_WORLD_EXTENT := 0.833
const MAX_ROUTE_ICON_ZOOM_SCALE := 1.55
const USER_CAMERA_TILT_DEGREES := -64.0
const USER_CAMERA_HEIGHT := 24.0
const USER_CAMERA_GROUND_OFFSET_Z := 11.7
const USER_START_CAMERA_OFFSET_X := 5.0
const USER_STREET_TILE_SIZE := 1.035
const USER_BIG_TREE_REGION := Rect2(71.0, 299.0, 603.0, 905.0)
const USER_SMALL_TREE_REGION := Rect2(765.0, 592.0, 432.0, 578.0)
const USER_BUSH_CLUSTER_REGION := Rect2(1351.0, 756.0, 729.0, 476.0)
const USER_BIG_TREE_PIXEL_SIZE := 0.00345
const USER_SMALL_TREE_PIXEL_SIZE := 0.00325
const USER_BUSH_PIXEL_SIZE := 0.0031
const USER_GRASS_TILE_COUNT := Vector2(96.0, 48.0)
const USER_POND_COUNT := 2
const TOWN_CAMERA_SIZE := 10.5
const DEFAULT_TOWN_LAYOUT := {
	"id": "starter_town_main_route",
	"name": "Starter Town Main Route",
	"building_names": ["FLOWER SHOP", "TOWNHOUSES", "CORNER CAFE", "CITY HALL", "BOOK SHOP"],
}
# Kept as deferred authored variants. The production scene deliberately uses
# DEFAULT_TOWN_LAYOUT until the fixed town has been tuned and playtested.
const TOWN_LAYOUTS := [
	{
		"id": "garden_cross",
		"name": "Garden Cross",
		"parcel_bands": [2, 0, 2, 1],
		"outer_sides": [-1, 1, -1, 1],
		"building_names": ["FLOWER SHOP", "TOWNHOUSES", "CORNER CAFE", "GAME CLUB", "BAKERY", "LIBRARY", "APARTMENTS", "MARKET"],
	},
	{
		"id": "canal_walk",
		"name": "Canal Walk",
		"parcel_bands": [0, 2, 1, 2],
		"outer_sides": [1, 1, -1, -1],
		"building_names": ["BOAT HOUSE", "CARD CAFE", "BOOK SHOP", "TOWNHOUSES", "MARKET", "APARTMENTS", "FLOWER SHOP", "CLUBHOUSE"],
	},
	{
		"id": "market_square",
		"name": "Market Square",
		"parcel_bands": [1, 2, 0, 1],
		"outer_sides": [-1, -1, 1, 1],
		"building_names": ["FRESH MARKET", "BAKERY", "CARD CLUB", "CAFE", "TOWNHOUSES", "LIBRARY", "FLOWER SHOP", "WORKSHOP"],
	},
	{
		"id": "station_row",
		"name": "Station Row",
		"parcel_bands": [2, 1, 0, 2],
		"outer_sides": [-1, 1, 1, -1],
		"building_names": ["TRAIN DEPOT", "NEWSSTAND", "CAFE", "APARTMENTS", "CARD CLUB", "MARKET", "BAKERY", "TOWNHOUSES"],
	},
	{
		"id": "lantern_lane",
		"name": "Lantern Lane",
		"parcel_bands": [0, 1, 2, 0],
		"outer_sides": [1, -1, 1, -1],
		"building_names": ["LANTERN CAFE", "GAME CLUB", "FLOWER SHOP", "TOWNHOUSES", "LIBRARY", "MARKET", "BAKERY", "APARTMENTS"],
	},
	{
		"id": "terrace_square",
		"name": "Terrace Square",
		"parcel_bands": [1, 0, 1, 2],
		"outer_sides": [1, -1, -1, 1],
		"building_names": ["COMMUNITY HALL", "CARD CAFE", "TOWNHOUSES", "BOOK SHOP", "MARKET", "FLOWER SHOP", "APARTMENTS", "BAKERY"],
	},
	{
		"id": "civic_green",
		"name": "Civic Green",
		"parcel_bands": [2, 1, 2, 0],
		"outer_sides": [-1, -1, 1, -1],
		"building_names": ["CITY HALL", "LIBRARY", "CARD CLUB", "CAFE", "TOWNHOUSES", "FLOWER SHOP", "MARKET", "WORKSHOP"],
	},
]
const USER_POND_SHAPE := [
	Vector2(-0.96, -0.24),
	Vector2(-0.73, -0.76),
	Vector2(-0.18, -0.96),
	Vector2(0.38, -0.84),
	Vector2(0.88, -0.48),
	Vector2(0.82, 0.02),
	Vector2(1.0, 0.46),
	Vector2(0.52, 0.87),
	Vector2(-0.05, 0.82),
	Vector2(-0.54, 0.98),
	Vector2(-0.93, 0.55),
]

var generated_city: Node3D
var road_segments := 0
var road_junctions := 0
var building_count := 0
var nature_count := 0
var generation_signature := ""
var road_cells: Dictionary = {}
var driveway_sides: Dictionary = {}
var route_camera_size := MIN_ROUTE_CAMERA_SIZE
var route_camera_center_z := 4.2
var route_icon_zoom_scale := -1.0
var camera_target_size := MIN_ROUTE_CAMERA_SIZE
var close_camera_position := Vector2.ZERO
var overview_camera_position := Vector2.ZERO
var overview_active := false
var overview_button: Button
var active_town_layout: Dictionary = {}
var town_interaction_locked := false


func _ready() -> void:
	var authored_buildings := get_node_or_null("StarterCityBackdrop") as Node3D
	var authored_park := get_node_or_null("ParkBackdrop") as Node3D
	if authored_buildings != null:
		authored_buildings.visible = false
	if authored_park != null:
		authored_park.visible = false
	_configure_guide()
	_build_from_route_graph()
	_configure_camera()
	_build_overview_control()
	call_deferred("_finish_prototype_presentation")


func _process(delta: float) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.size = move_toward(camera.size, camera_target_size, CAMERA_ZOOM_SPEED * delta)
		if not overview_active:
			_follow_town_player()


func _configure_camera() -> void:
	var camera := get_node("Camera3D") as Camera3D
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 120.0
	# The supplied map references use a near-plan handheld-RPG view. Keep a
	# little pitch so illustrated billboard characters and trees retain their
	# silhouettes, while letting streets and district footprints dominate.
	camera.rotation = Vector3(deg_to_rad(USER_CAMERA_TILT_DEGREES), 0.0, 0.0)
	camera.position.y = USER_CAMERA_HEIGHT
	var graph := get_node("RouteGraph")
	graph.camera_ground_offset_z = USER_CAMERA_GROUND_OFFSET_Z
	graph.camera_focus_lead_x = 0.0
	graph.vertical_camera_locked = false
	var start_x := (graph.nodes.start.position as Vector3).x
	var boss_x := (graph.nodes.final_boss.position as Vector3).x
	graph.camera_x_min = start_x - 1.0
	graph.camera_x_max = boss_x + 1.0
	var focus_id := String(graph.current_node_id)
	var focus_position: Vector3 = graph.nodes.get(focus_id, graph.nodes.start).position
	var route_z_bounds := _route_z_bounds(graph)
	graph.camera_z_min = route_z_bounds.x + USER_CAMERA_GROUND_OFFSET_Z - 1.2
	graph.camera_z_max = route_z_bounds.y + USER_CAMERA_GROUND_OFFSET_Z + 1.2
	route_camera_center_z = (route_z_bounds.x + route_z_bounds.y) * 0.5
	graph.camera_target_x = focus_position.x
	graph.camera_target_z = focus_position.z + float(graph.camera_ground_offset_z)
	camera.position.x = graph.camera_target_x
	camera.position.z = graph.camera_target_z
	route_camera_size = TOWN_CAMERA_SIZE
	camera.size = route_camera_size
	camera_target_size = route_camera_size
	close_camera_position = Vector2(camera.position.x, camera.position.z)
	var ground := get_node_or_null("GroundBlock") as MeshInstance3D
	if ground != null:
		ground.scale.x = 1.35
		var ground_material := ShaderMaterial.new()
		ground_material.shader = USER_GRASS_SHADER
		ground_material.set_shader_parameter("grass_texture", USER_GRASS_TEXTURE)
		ground_material.set_shader_parameter("grass_tint", GamePalette.CITY_GRASS)
		ground_material.set_shader_parameter("texture_strength", 0.9)
		ground_material.set_shader_parameter("saturation", 0.86)
		ground_material.set_shader_parameter("tile_count", USER_GRASS_TILE_COUNT)
		ground.material_override = ground_material


func _follow_town_player() -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	var graph := get_node_or_null("RouteGraph")
	if player == null or graph == null:
		return
	graph.camera_target_x = clampf(player.global_position.x, graph.camera_x_min, graph.camera_x_max)
	graph.camera_target_z = clampf(
		player.global_position.z + float(graph.camera_ground_offset_z),
		graph.camera_z_min,
		graph.camera_z_max
	)


func _route_z_bounds(graph: Node) -> Vector2:
	var min_z := INF
	var max_z := -INF
	for node_value in graph.nodes.values():
		var node_position: Vector3 = (node_value as Dictionary).position
		min_z = minf(min_z, node_position.z)
		max_z = maxf(max_z, node_position.z)
	return Vector2(min_z, max_z)


func _route_vertical_fit_size(camera: Camera3D, graph: Node) -> float:
	var min_vertical := INF
	var max_vertical := -INF
	for node_value in graph.nodes.values():
		var node_position: Vector3 = (node_value as Dictionary).position
		var camera_local_position := camera.to_local(node_position)
		min_vertical = minf(min_vertical, camera_local_position.y)
		max_vertical = maxf(max_vertical, camera_local_position.y)
	return maxf(MIN_ROUTE_CAMERA_SIZE, max_vertical - min_vertical + ROUTE_VERTICAL_PADDING)


func _build_overview_control() -> void:
	if overview_button != null:
		return
	var interface := get_node("Interface") as CanvasLayer
	overview_button = Button.new()
	overview_button.name = "MapOverview"
	overview_button.text = "TOWN MAP"
	overview_button.focus_mode = Control.FOCUS_NONE
	overview_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	overview_button.anchor_left = 1.0
	overview_button.anchor_right = 1.0
	overview_button.offset_left = -238.0
	overview_button.offset_right = -24.0
	overview_button.offset_top = 22.0
	overview_button.offset_bottom = 76.0
	overview_button.add_theme_font_size_override("font_size", 20)
	overview_button.add_theme_color_override("font_color", GamePalette.COOL_WHITE)
	overview_button.add_theme_color_override("font_hover_color", GamePalette.COOL_WHITE)
	overview_button.add_theme_color_override("font_pressed_color", GamePalette.CARBON)
	overview_button.add_theme_stylebox_override(
		"normal", _overview_button_style(GamePalette.GRAPHITE, GamePalette.STEEL)
	)
	overview_button.add_theme_stylebox_override(
		"hover", _overview_button_style(GamePalette.SELECTION_BLUE, GamePalette.ELECTRIC_CYAN)
	)
	overview_button.add_theme_stylebox_override(
		"pressed", _overview_button_style(GamePalette.ELECTRIC_CYAN, GamePalette.COOL_WHITE)
	)
	overview_button.pressed.connect(_toggle_map_overview)
	interface.add_child(overview_button)
	_update_overview_position()


func _overview_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 9
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 4
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style


func _update_overview_position() -> void:
	var graph := get_node("RouteGraph")
	if graph.nodes.is_empty():
		return
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for node_value in graph.nodes.values():
		var node_position: Vector3 = (node_value as Dictionary).position
		min_x = minf(min_x, node_position.x)
		max_x = maxf(max_x, node_position.x)
		min_z = minf(min_z, node_position.z)
		max_z = maxf(max_z, node_position.z)
	overview_camera_position = Vector2(
		(min_x + max_x) * 0.5,
		(min_z + max_z) * 0.5 + float(graph.camera_ground_offset_z)
	)


func _toggle_map_overview() -> void:
	var graph := get_node("RouteGraph")
	var player := get_node_or_null("Player") as CharacterBody3D
	overview_active = not overview_active
	graph.camera_input_locked = overview_active
	if player != null and player.has_method("set_world_input_locked"):
		player.call("set_world_input_locked", overview_active or town_interaction_locked)
	if overview_active:
		close_camera_position = Vector2(graph.camera_target_x, graph.camera_target_z)
		graph.pan_direction = 0.0
		graph.vertical_pan_direction = 0.0
		graph.camera_target_x = overview_camera_position.x
		graph.camera_target_z = overview_camera_position.y
		camera_target_size = OVERVIEW_CAMERA_SIZE
		overview_button.text = "RETURN"
	else:
		_follow_town_player()
		camera_target_size = route_camera_size
		overview_button.text = "TOWN MAP"
	_set_pan_controls_visible(false)


func _set_pan_controls_visible(controls_visible: bool) -> void:
	for control_name in ["MapPanLeft", "MapPanRight", "MapPanUp", "MapPanDown"]:
		var control := get_node_or_null("Interface/" + control_name) as Control
		if control != null:
			control.visible = controls_visible


func _update_route_icon_zoom_compensation(camera: Camera3D, force: bool = false) -> void:
	var zoom_ratio := camera.size / maxf(route_camera_size, 0.001)
	var next_zoom_scale := clampf(zoom_ratio, 1.0, MAX_ROUTE_ICON_ZOOM_SCALE)
	if not force and is_equal_approx(next_zoom_scale, route_icon_zoom_scale):
		return
	route_icon_zoom_scale = next_zoom_scale
	var graph := get_node("RouteGraph")
	for bubble_value in graph.node_sprites.values():
		var bubble := bubble_value as Sprite3D
		if not bubble.has_meta("route_icon_base_pixel_size"):
			continue
		var base_pixel_size := float(bubble.get_meta("route_icon_base_pixel_size"))
		bubble.pixel_size = base_pixel_size * route_icon_zoom_scale
		bubble.set_meta("route_icon_zoom_scale", route_icon_zoom_scale)


func _finish_prototype_presentation() -> void:
	var legacy_route_network := get_node_or_null("RouteNetwork") as Node3D
	if legacy_route_network != null:
		legacy_route_network.visible = false
	var graph := get_node("RouteGraph")
	var focus_position: Vector3 = graph.nodes.get(graph.current_node_id, graph.nodes.start).position
	var player := get_node_or_null("Player") as CharacterBody3D
	if player != null:
		player.scale = Vector3.ONE * USER_PLAYER_SCALE
		var player_visual := player.get_node_or_null("Visual") as Node3D
		if player_visual != null:
			player_visual.scale = Vector3.ONE * USER_PLAYER_VISUAL_SCALE
		player.global_position = focus_position + Vector3(0.0, 0.0, PLAYER_ROAD_CENTER_OFFSET_Z)
		if player.has_method("configure_free_roam"):
			player.call("configure_free_roam", _current_route_walkable_cells(graph))
	graph.call("enable_world_exploration")
	_set_pan_controls_visible(false)
	_follow_town_player()
	var camera := get_node("Camera3D") as Camera3D
	camera.position.x = graph.camera_target_x
	camera.position.z = graph.camera_target_z


func _configure_guide() -> void:
	var guide := get_node_or_null("Interface/Guide") as PanelContainer
	if guide != null:
		guide.offset_left = 24.0
		guide.offset_top = 22.0
		guide.offset_right = 518.0
		guide.offset_bottom = 78.0
		guide.add_theme_stylebox_override(
			"panel", _map_hud_style(GamePalette.GRAPHITE, GamePalette.STEEL, 3)
		)
	var guide_text := get_node_or_null("Interface/Guide/Margin/Text") as Label
	if guide_text != null:
		guide_text.text = "STARTER CITY   •   MOVE WITH WASD / ARROWS"
		guide_text.add_theme_color_override("font_color", GamePalette.COOL_WHITE)
		guide_text.add_theme_font_size_override("font_size", 17)
	var status := get_node_or_null("Interface/RouteStatus") as Label
	if status != null:
		status.offset_left = 24.0
		status.offset_top = 88.0
		status.offset_right = 444.0
		status.offset_bottom = 140.0
		status.add_theme_color_override("font_color", GamePalette.COOL_WHITE)
		status.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		status.add_theme_constant_override("outline_size", 0)
		status.add_theme_font_size_override("font_size", 19)
		status.add_theme_stylebox_override(
			"normal", _map_hud_style(GamePalette.CARBON, GamePalette.ELECTRIC_CYAN, 5)
		)
		status.text = "Explore the open streets"


func _map_hud_style(fill: Color, accent: Color, accent_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill, 0.95)
	style.border_color = accent
	style.border_width_left = accent_width
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 9
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	style.content_margin_left = 16.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _build_from_route_graph() -> void:
	var graph := get_node("RouteGraph")
	if graph.nodes.is_empty():
		graph.route_ready.connect(func(_snapshot: Dictionary) -> void: _build_from_route_graph(), CONNECT_ONE_SHOT)
		return
	if generated_city != null:
		generated_city.queue_free()
	generated_city = Node3D.new()
	generated_city.name = "GeneratedStarterCity"
	add_child(generated_city)

	var roads := Node3D.new()
	roads.name = "Roads"
	generated_city.add_child(roads)
	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	generated_city.add_child(landmarks)
	var neighborhoods := Node3D.new()
	neighborhoods.name = "Neighborhoods"
	generated_city.add_child(neighborhoods)
	var nature := Node3D.new()
	nature.name = "Nature"
	generated_city.add_child(nature)

	road_segments = 0
	road_junctions = 0
	building_count = 0
	nature_count = 0
	driveway_sides.clear()
	active_town_layout = DEFAULT_TOWN_LAYOUT.duplicate(true)
	_build_road_grid(graph)
	_build_landmarks(graph, landmarks)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(graph.generation_seed)
	_build_neighborhood_blocks(graph, neighborhoods, nature, rng)
	_build_outer_edges(graph, neighborhoods, nature, rng)
	_build_street_furniture(graph, nature, rng)
	_instantiate_roads(roads)
	_apply_starter_city_palette(roads, landmarks, neighborhoods)
	_build_user_illustrated_map(graph, generated_city, roads, landmarks, neighborhoods, nature, rng)
	generation_signature = "%d:%d:%d:%d:%d" % [
		int(graph.generation_seed), road_segments, road_junctions, building_count, nature_count
	]
	generated_city.set_meta("generation_signature", generation_signature)
	generated_city.set_meta("source_packs", ["City Kit - Roads", "City Kit - Suburban"])
	generated_city.set_meta("environment_palette", "starter_city_bw")
	generated_city.set_meta("town_layout_id", String(active_town_layout.get("id", "garden_cross")))
	generated_city.set_meta("town_layout_name", String(active_town_layout.get("name", "Garden Cross")))
	generated_city.set_meta("town_layout_mode", "authored_default")
	generated_city.set_meta(
		"user_illustrated_assets",
		[
			"grass.png",
			"starter_city_illustrated_path.gdshader",
			"starter_city_pond_water.gdshader",
			"vegetation_sheet.png",
		]
	)


func _build_user_illustrated_map(
	graph: Node,
	parent: Node3D,
	legacy_roads: Node3D,
	legacy_landmarks: Node3D,
	legacy_neighborhoods: Node3D,
	legacy_nature: Node3D,
	rng: RandomNumberGenerator
) -> void:
	# Retain legacy nodes for compatibility with the existing generation tests,
	# but make the player's view entirely from the supplied illustrated kit.
	legacy_roads.visible = false
	legacy_landmarks.visible = false
	legacy_neighborhoods.visible = false
	legacy_nature.visible = false

	var illustrated := Node3D.new()
	illustrated.name = "UserIllustratedMap"
	illustrated.set_meta("art_source", "user_supplied_starter_city_sprites")
	parent.add_child(illustrated)

	var district_zones := Node3D.new()
	district_zones.name = "DistrictZones"
	illustrated.add_child(district_zones)
	_build_authored_district_zones(district_zones)

	var street_tiles := Node3D.new()
	street_tiles.name = "StreetTiles"
	illustrated.add_child(street_tiles)
	_build_user_street_tiles(street_tiles)

	var pond_layout := _starter_city_pond_layout(graph)
	var ponds := Node3D.new()
	ponds.name = "Ponds"
	illustrated.add_child(ponds)
	_build_user_ponds(ponds, pond_layout)

	var placeholder_buildings := Node3D.new()
	placeholder_buildings.name = "PlaceholderBuildings"
	illustrated.add_child(placeholder_buildings)
	_build_town_placeholder_buildings(graph, placeholder_buildings, pond_layout)

	var vegetation := Node3D.new()
	vegetation.name = "Vegetation"
	illustrated.add_child(vegetation)
	_build_user_vegetation(graph, vegetation, rng, pond_layout)

	var town_actors := Node3D.new()
	town_actors.name = "TownActors"
	illustrated.add_child(town_actors)
	_build_town_route_actors(graph, town_actors, placeholder_buildings)


func _build_town_placeholder_buildings(
	graph: Node,
	parent: Node3D,
	pond_layout: Array[Dictionary]
) -> void:
	var start_position := graph.nodes.start.position as Vector3
	_add_placeholder_building(
		parent,
		"LOCAL CARD SHOP",
		Vector3(start_position.x, 0.0, start_position.z - 1.55),
		Vector3(2.2, 1.45, 1.35),
		GamePalette.CITY_CHAMPIONSHIP,
		"starter_shop",
		true,
		Vector3(start_position.x, 0.0, start_position.z - 0.78)
	)

	var authored_sites := [
		{"label": "FLOWER SHOP", "position": Vector3(-9.0, 0.0, 4.35), "size": Vector3(1.6, 1.24, 1.35), "accent": GamePalette.CITY_WARM_ACCENT},
		{"label": "TOWNHOUSES", "position": Vector3(-0.7, 0.0, 5.0), "size": Vector3(2.15, 1.4, 1.4), "accent": GamePalette.CITY_ROOF},
		{"label": "CORNER CAFE", "position": Vector3(7.0, 0.0, 5.0), "size": Vector3(1.8, 1.28, 1.35), "accent": GamePalette.CITY_SAGE},
		{"label": "CITY HALL", "position": Vector3(-1.2, 0.0, -2.5), "size": Vector3(2.1, 1.5, 1.5), "accent": GamePalette.CITY_ROOF},
		{"label": "HEAL & UPGRADE", "position": Vector3(7.0, 0.0, -2.6), "size": Vector3(2.15, 1.45, 1.45), "accent": GamePalette.CITY_HEAL_CENTER},
		{"label": "BOOK SHOP", "position": Vector3(-2.0, 0.0, -7.65), "size": Vector3(1.8, 1.28, 1.3), "accent": GamePalette.CITY_WARM_ACCENT},
	]
	for site_value in authored_sites:
		var site := site_value as Dictionary
		var site_position := site.position as Vector3
		var site_size := site.size as Vector3
		if _placeholder_site_clear(site_position, Vector2(site_size.x, site_size.z)):
			_add_placeholder_building(
				parent,
				String(site.label),
				site_position,
				site_size,
				site.accent as Color
			)


func _build_town_route_actors(graph: Node, parent: Node3D, building_parent: Node3D) -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return
	var available: Array = graph.call("_available_destinations")
	for node_id: String in graph.nodes:
		if node_id == "start" or node_id in graph.visited:
			continue
		var data := (graph.nodes[node_id] as Dictionary).duplicate(true)
		data.id = node_id
		var node_type := String(data.get("type", "enemy"))
		var node_position := data.position as Vector3
		var is_active: bool = node_id in available and not bool(graph.choices_locked)
		if node_type in ["shop", "final_boss"]:
			var is_championship := node_type == "final_boss"
			var building_offset := Vector3(0.0, 0.0, -1.6 if is_championship else -1.4)
			_add_placeholder_building(
				building_parent,
				"LOCALS CHAMPIONSHIP" if is_championship else "CARD STORE",
				Vector3(node_position.x, 0.0, node_position.z) + building_offset,
				Vector3(2.45, 1.65, 1.4) if is_championship else Vector3(1.65, 1.38, 1.3),
				GamePalette.CITY_CHAMPIONSHIP if is_championship else GamePalette.CITY_SHOP,
				node_id,
				is_active,
				Vector3(node_position.x, 0.0, node_position.z)
			)
			continue
		if node_type == "event":
			_add_town_event_marker(parent, graph, data, is_active)
			continue

		var npc := Node3D.new()
		npc.name = node_id.to_pascal_case() + "TownNpc"
		npc.set_script(TOWN_NPC_SCRIPT)
		var actor_position := Vector3(node_position.x, 0.0, node_position.z)
		var approach_direction := _incoming_route_direction(graph, node_id)
		var raw_offset := data.get("npc_offset", []) as Array
		if raw_offset.size() >= 2:
			actor_position += Vector3(float(raw_offset[0]), 0.0, float(raw_offset[1]))
			approach_direction = (Vector3(node_position.x, 0.0, node_position.z) - actor_position).normalized()
		npc.position = actor_position
		parent.add_child(npc)
		var portrait_id := String(data.get("npc_portrait_id", "npc1"))
		var portrait := TOWN_NPC_TEXTURES.get(portrait_id, TOWN_NPC_TEXTURES.npc1) as Texture2D
		npc.call(
			"configure",
			player,
			data,
			portrait,
			is_active,
			approach_direction
		)
		npc.connect("encounter_requested", _on_town_npc_encounter_requested.bind(graph))


func _add_town_event_marker(parent: Node3D, graph: Node, data: Dictionary, is_active: bool) -> void:
	var node_id := String(data.id)
	var node_position := data.position as Vector3
	var marker := Node3D.new()
	marker.name = node_id.to_pascal_case() + "EventMarker"
	marker.position = Vector3(node_position.x, 0.0, node_position.z)
	marker.set_meta("route_node_id", node_id)
	marker.set_meta("event_active", is_active)
	parent.add_child(marker)

	var square := MeshInstance3D.new()
	square.name = "EventSquare"
	var square_mesh := BoxMesh.new()
	square_mesh.size = Vector3(1.12, 0.09, 1.12)
	square.mesh = square_mesh
	square.material_override = _unshaded_environment_material(
		GamePalette.CITY_EVENT if is_active else GamePalette.CITY_EVENT.darkened(0.10)
	)
	square.position.y = ROAD_HEIGHT + 0.08
	marker.add_child(square)

	var label := Label3D.new()
	label.name = "EventLabel"
	label.text = "EVENT"
	label.font_size = 34
	label.pixel_size = 0.0052
	label.position.y = 0.62
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = GamePalette.COOL_WHITE
	label.outline_size = 8
	label.outline_modulate = GamePalette.CARBON
	label.no_depth_test = true
	marker.add_child(label)

	var trigger := Area3D.new()
	trigger.name = "EventEntrance"
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	trigger.monitoring = is_active
	trigger.monitorable = false
	trigger.position.y = 0.75
	trigger.set_meta("route_node_id", node_id)
	trigger.set_meta("entrance_active", is_active)
	var trigger_collision := CollisionShape3D.new()
	var trigger_shape := BoxShape3D.new()
	trigger_shape.size = Vector3(1.12, 1.7, 1.12)
	trigger_collision.shape = trigger_shape
	trigger.add_child(trigger_collision)
	trigger.body_entered.connect(_on_town_event_entered.bind(node_id, graph))
	marker.add_child(trigger)


func _on_town_event_entered(body: Node3D, node_id: String, graph: Node) -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	if body == player:
		_commit_town_destination(graph, node_id)


func _incoming_route_direction(graph: Node, node_id: String) -> Vector3:
	var preferred_key := String(graph.current_node_id) + ">" + node_id
	var route_key := preferred_key
	if not graph.routes.has(route_key):
		for candidate_value in graph.routes.keys():
			var candidate := String(candidate_value)
			if candidate.ends_with(">" + node_id):
				route_key = candidate
				break
	if not graph.routes.has(route_key):
		return Vector3(0.0, 0.0, 1.0)
	var split := route_key.split(">")
	var points: Array[Vector3] = [graph.nodes[String(split[0])].position as Vector3]
	for point_value in graph.routes[route_key]:
		points.append(point_value as Vector3)
	if points.size() < 2:
		return Vector3(0.0, 0.0, 1.0)
	return (points[points.size() - 2] - points[points.size() - 1]).normalized()


func _add_placeholder_building(
	parent: Node3D,
	label_text: String,
	position_value: Vector3,
	size_value: Vector3,
	accent: Color,
	door_node_id: String = "",
	door_active: bool = false,
	door_world_position: Vector3 = Vector3.ZERO
) -> Node3D:
	var building := Node3D.new()
	building.name = label_text.to_pascal_case().replace(" ", "") + "Placeholder"
	building.position = position_value
	building.set_meta("map_role", "placeholder_building")
	building.set_meta("building_label", label_text)
	building.set_meta("town_layout_id", String(active_town_layout.get("id", "garden_cross")))
	parent.add_child(building)

	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	building.add_child(body)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	collision.position.y = size_value.y * 0.5
	body.add_child(collision)

	var block := MeshInstance3D.new()
	block.name = "BuildingBlock"
	var block_mesh := BoxMesh.new()
	block_mesh.size = size_value
	block.mesh = block_mesh
	block.material_override = _unshaded_environment_material(GamePalette.CITY_WALL)
	block.position.y = size_value.y * 0.5
	building.add_child(block)

	var roof := MeshInstance3D.new()
	roof.name = "PlaceholderRoof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(size_value.x + 0.12, 0.16, size_value.z + 0.12)
	roof.mesh = roof_mesh
	roof.material_override = _unshaded_environment_material(accent)
	roof.position.y = size_value.y + 0.08
	building.add_child(roof)

	var label := Label3D.new()
	label.name = "BuildingName"
	label.text = label_text
	label.font_size = 38
	label.pixel_size = 0.006
	label.position.y = size_value.y + 0.52
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = GamePalette.COOL_WHITE
	label.outline_size = 9
	label.outline_modulate = GamePalette.CARBON
	label.no_depth_test = true
	building.add_child(label)

	if not door_node_id.is_empty():
		_add_placeholder_door(building, door_node_id, door_active, door_world_position)
	return building


func _add_placeholder_door(
	building: Node3D,
	node_id: String,
	is_active: bool,
	door_world_position: Vector3
) -> void:
	var local_door_position := door_world_position - building.global_position
	var door_direction := Vector3(local_door_position.x, 0.0, local_door_position.z).normalized()
	var door := MeshInstance3D.new()
	door.name = "ShopDoor"
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.58, 0.78, 0.08)
	door.mesh = door_mesh
	door.material_override = _unshaded_environment_material(
		GamePalette.ELECTRIC_CYAN if is_active else GamePalette.STEEL
	)
	door.position = local_door_position + Vector3(0.0, 0.4, 0.0)
	if absf(door_direction.x) > absf(door_direction.z):
		door.rotation.y = PI * 0.5
	building.add_child(door)

	var entrance := Area3D.new()
	entrance.name = "ShopEntrance"
	entrance.collision_layer = 0
	entrance.collision_mask = 1
	entrance.monitoring = is_active
	entrance.monitorable = false
	entrance.position = local_door_position + Vector3(0.0, 0.72, 0.0)
	entrance.set_meta("route_node_id", node_id)
	entrance.set_meta("entrance_active", is_active)
	var entrance_collision := CollisionShape3D.new()
	entrance_collision.name = "EntranceShape"
	var entrance_shape := BoxShape3D.new()
	entrance_shape.size = Vector3(0.72, 1.6, 0.72)
	entrance_collision.shape = entrance_shape
	entrance.add_child(entrance_collision)
	entrance.body_entered.connect(_on_town_shop_door_entered.bind(node_id))
	building.add_child(entrance)


func _on_town_npc_encounter_requested(node_id: String, graph: Node) -> void:
	_commit_town_destination(graph, node_id)


func _on_town_shop_door_entered(body: Node3D, node_id: String) -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	if body != player:
		return
	if node_id == "starter_shop":
		if town_interaction_locked:
			return
		town_interaction_locked = true
		if player.has_method("set_world_input_locked"):
			player.call("set_world_input_locked", true)
		starter_shop_requested.emit()
		return
	_commit_town_destination(get_node("RouteGraph"), node_id)


func _commit_town_destination(graph: Node, node_id: String) -> void:
	if town_interaction_locked:
		return
	town_interaction_locked = true
	var player := get_node_or_null("Player") as CharacterBody3D
	if player != null and player.has_method("set_world_input_locked"):
		player.call("set_world_input_locked", true)
	if not bool(graph.call("trigger_world_destination", node_id)):
		town_interaction_locked = false
		if player != null and player.has_method("set_world_input_locked"):
			player.call("set_world_input_locked", overview_active)


func _placeholder_site_clear(position_value: Vector3, footprint: Vector2) -> bool:
	for road_value in road_cells.values():
		var cell := (road_value as Dictionary).cell as Vector2i
		if (
			absf(position_value.x - float(cell.x)) < footprint.x * 0.5 + 0.48
			and absf(position_value.z - float(cell.y)) < footprint.y * 0.5 + 0.48
		):
			return false
	return true


func _placeholder_accent(index: int) -> Color:
	var accents := [
		GamePalette.CITY_ROOF,
		GamePalette.CITY_SAGE,
		GamePalette.CITY_WARM_ACCENT,
		GamePalette.SELECTION_BLUE,
	]
	return accents[index % accents.size()]


func _build_user_street_tiles(parent: Node3D) -> void:
	var tile_mesh := PlaneMesh.new()
	tile_mesh.size = Vector2(USER_STREET_TILE_SIZE, USER_STREET_TILE_SIZE)
	var path_materials := {}
	for connection_value in road_cells.values():
		var connection := connection_value as Dictionary
		var cell := connection.cell as Vector2i
		var directions := connection.directions as Dictionary
		var connection_mask := _path_connection_mask(directions)
		if not path_materials.has(connection_mask):
			path_materials[connection_mask] = _illustrated_path_material(connection_mask)
		var tile := MeshInstance3D.new()
		tile.name = "IllustratedPath_%d_%d" % [cell.x, cell.y]
		tile.mesh = tile_mesh
		tile.material_override = path_materials[connection_mask]
		tile.position = Vector3(float(cell.x), ROAD_HEIGHT + 0.018, float(cell.y))
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tile.set_meta("grid_cell", cell)
		tile.set_meta("connection_mask", connection_mask)
		tile.set_meta("map_role", "illustrated_footpath")
		parent.add_child(tile)


func _build_authored_district_zones(parent: Node3D) -> void:
	# The lower and left portions remain the grassy small-town district supplied
	# by GroundBlock. This inset marks the denser upper-right city district from
	# the user's route sketch, with streets drawn cleanly above it.
	var city_ground := MeshInstance3D.new()
	city_ground.name = "SmallCityDistrict"
	var city_mesh := PlaneMesh.new()
	city_mesh.size = Vector2(18.0, 10.5)
	city_ground.mesh = city_mesh
	var city_material := ShaderMaterial.new()
	city_material.shader = USER_PAVED_GROUND_SHADER
	city_material.set_shader_parameter("paving_texture", USER_PAVING_TEXTURE)
	city_material.set_shader_parameter("paving_surface_color", GamePalette.CITY_PAVER_SURFACE)
	city_material.set_shader_parameter("paving_joint_color", GamePalette.CITY_PAVER_JOINT)
	city_material.set_shader_parameter("texture_scale", 0.72)
	city_material.set_meta("starter_city_district", "small_city")
	city_ground.material_override = city_material
	city_ground.position = Vector3(5.0, ROAD_HEIGHT + 0.004, -3.25)
	city_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city_ground.set_meta("map_role", "small_city_environment")
	parent.add_child(city_ground)


func _path_connection_mask(directions: Dictionary) -> int:
	var connection_mask := 0
	if directions.has(Vector2i(-1, 0)):
		connection_mask |= 1
	if directions.has(Vector2i(1, 0)):
		connection_mask |= 2
	if directions.has(Vector2i(0, -1)):
		connection_mask |= 4
	if directions.has(Vector2i(0, 1)):
		connection_mask |= 8
	return connection_mask


func _illustrated_path_material(connection_mask: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = USER_PATH_SHADER
	material.set_shader_parameter("connect_west", 1.0 if (connection_mask & 1) != 0 else 0.0)
	material.set_shader_parameter("connect_east", 1.0 if (connection_mask & 2) != 0 else 0.0)
	material.set_shader_parameter("connect_north", 1.0 if (connection_mask & 4) != 0 else 0.0)
	material.set_shader_parameter("connect_south", 1.0 if (connection_mask & 8) != 0 else 0.0)
	material.set_shader_parameter("path_half_width", 0.36)
	material.set_shader_parameter("edge_width", 0.055)
	material.set_shader_parameter("surface_color", GamePalette.CITY_PATH_SURFACE)
	material.set_shader_parameter("highlight_color", GamePalette.CITY_PATH_HIGHLIGHT)
	material.set_shader_parameter("edge_color", GamePalette.CITY_PATH_EDGE)
	material.set_shader_parameter("fleck_color", GamePalette.CITY_PATH_FLECK)
	material.set_shader_parameter("motif_color", GamePalette.CITY_PATH_MOTIF)
	material.set_meta("starter_city_path_mask", connection_mask)
	return material


func _starter_city_pond_layout(graph: Node) -> Array[Dictionary]:
	return [
		{
			"layer_index": 1,
			"band_index": 0,
			"center": Vector3(-10.4, 0.0, 3.9),
			"scale": Vector2(0.72, 0.82),
			"rotation": -0.12,
		},
		{
			"layer_index": 3,
			"band_index": 1,
			"center": Vector3(2.0, 0.0, 5.0),
			"scale": Vector2(0.82, 0.68),
			"rotation": 0.16,
		},
	]


func _build_user_ponds(parent: Node3D, pond_layout: Array[Dictionary]) -> void:
	var water_material := ShaderMaterial.new()
	water_material.shader = USER_POND_WATER_SHADER
	water_material.set_shader_parameter("deep_color", GamePalette.CITY_POND_DEEP)
	water_material.set_shader_parameter("surface_color", GamePalette.CITY_POND_SURFACE)
	water_material.set_shader_parameter("glint_color", GamePalette.CITY_POND_GLINT)
	water_material.set_meta("starter_city_water", true)
	var outline_material := _unshaded_environment_material(GamePalette.CITY_POND_OUTLINE)
	var bank_material := _unshaded_environment_material(GamePalette.CITY_POND_BANK)

	for pond_index in range(pond_layout.size()):
		var pond_data := pond_layout[pond_index]
		var pond := Node3D.new()
		pond.name = "NeighborhoodPond_%d" % (pond_index + 1)
		pond.position = pond_data.center as Vector3
		pond.rotation.y = float(pond_data.rotation)
		pond.set_meta("map_role", "neighborhood_pond")
		pond.set_meta("layer_index", int(pond_data.layer_index))
		pond.set_meta("band_index", int(pond_data.band_index))
		parent.add_child(pond)

		var pond_scale := pond_data.scale as Vector2
		_add_pond_surface(
			pond,
			"PondOutline",
			pond_scale,
			ROAD_HEIGHT + 0.010,
			outline_material,
			"pond_outline"
		)
		_add_pond_surface(
			pond,
			"PondBank",
			pond_scale * 0.89,
			ROAD_HEIGHT + 0.013,
			bank_material,
			"pond_bank"
		)
		_add_pond_surface(
			pond,
			"PondWater",
			pond_scale * 0.74,
			ROAD_HEIGHT + 0.016,
			water_material,
			"pond_water"
		)


func _add_pond_surface(
	parent: Node3D,
	node_name: String,
	surface_scale: Vector2,
	height: float,
	material: Material,
	map_role: String
) -> void:
	var surface := MeshInstance3D.new()
	surface.name = node_name
	surface.mesh = _irregular_pond_mesh(surface_scale)
	surface.material_override = material
	surface.position.y = height
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.set_meta("map_role", map_role)
	parent.add_child(surface)


func _irregular_pond_mesh(surface_scale: Vector2) -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point_index in range(USER_POND_SHAPE.size()):
		var point := USER_POND_SHAPE[point_index] as Vector2
		var next_point := USER_POND_SHAPE[(point_index + 1) % USER_POND_SHAPE.size()] as Vector2
		surface_tool.set_normal(Vector3.UP)
		surface_tool.add_vertex(Vector3.ZERO)
		surface_tool.set_normal(Vector3.UP)
		surface_tool.add_vertex(Vector3(point.x * surface_scale.x, 0.0, point.y * surface_scale.y))
		surface_tool.set_normal(Vector3.UP)
		surface_tool.add_vertex(
			Vector3(next_point.x * surface_scale.x, 0.0, next_point.y * surface_scale.y)
		)
	return surface_tool.commit()


func _unshaded_environment_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	return material


func _build_user_vegetation(
	graph: Node,
	parent: Node3D,
	rng: RandomNumberGenerator,
	pond_layout: Array[Dictionary]
) -> void:
	var start_x := float((graph.nodes.start.position as Vector3).x)
	var boss_x := float((graph.nodes.final_boss.position as Vector3).x)
	var min_x := start_x - 2.5
	var max_x := boss_x + 2.5
	var route_z_bounds := _route_z_bounds(graph)
	var min_z := route_z_bounds.x - 2.55
	var max_z := route_z_bounds.y + 2.55

	# Dense overlapping perimeter rows create the clear forest boundary language
	# of the supplied references without making any reachable street impassable.
	var edge_step := 1.55
	var edge_index := 0
	var x := min_x
	while x <= max_x + 0.01:
		var tree_kind := "big" if edge_index % 3 != 1 else "small"
		_add_user_vegetation_sprite(parent, tree_kind, Vector3(x, 0.0, min_z), rng.randf_range(0.94, 1.06))
		_add_user_vegetation_sprite(parent, tree_kind, Vector3(x + 0.26, 0.0, max_z), rng.randf_range(0.94, 1.06))
		_add_user_vegetation_sprite(parent, "small", Vector3(x + 0.7, 0.0, min_z - 1.18), rng.randf_range(0.9, 1.02))
		_add_user_vegetation_sprite(parent, "small", Vector3(x - 0.44, 0.0, max_z + 1.14), rng.randf_range(0.9, 1.02))
		x += edge_step
		edge_index += 1

	var z := min_z + 1.4
	while z < max_z - 0.9:
		_add_user_vegetation_sprite(parent, "small", Vector3(min_x, 0.0, z), rng.randf_range(0.94, 1.08))
		_add_user_vegetation_sprite(parent, "small", Vector3(max_x, 0.0, z + 0.18), rng.randf_range(0.94, 1.08))
		_add_user_vegetation_sprite(parent, "small", Vector3(min_x - 1.12, 0.0, z + 0.7), rng.randf_range(0.88, 1.0))
		_add_user_vegetation_sprite(parent, "small", Vector3(max_x + 1.12, 0.0, z - 0.54), rng.randf_range(0.88, 1.0))
		z += 1.55

	# A few fixed garden pockets make the default composition feel authored. The
	# broader procedural parcel dressing remains deferred with TOWN_LAYOUTS.
	for pocket_position in [Vector3(-4.2, 0.0, 5.0), Vector3(5.3, 0.0, 5.05), Vector3(-4.5, 0.0, -2.8)]:
		_add_user_vegetation_sprite(parent, "small", pocket_position, rng.randf_range(0.82, 0.96))
		_add_user_vegetation_sprite(
			parent,
			"bush",
			pocket_position + Vector3(0.72, 0.0, 0.35),
			rng.randf_range(0.62, 0.72)
		)


func _parcel_has_pond(pond_layout: Array[Dictionary], layer_index: int, band_index: int) -> bool:
	for pond_data in pond_layout:
		if int(pond_data.layer_index) == layer_index and int(pond_data.band_index) == band_index:
			return true
	return false


func _add_user_vegetation_sprite(
	parent: Node3D,
	kind: String,
	ground_position: Vector3,
	scale_value: float
) -> void:
	var region := USER_SMALL_TREE_REGION
	var pixel_size := USER_SMALL_TREE_PIXEL_SIZE
	match kind:
		"big":
			region = USER_BIG_TREE_REGION
			pixel_size = USER_BIG_TREE_PIXEL_SIZE
		"bush":
			region = USER_BUSH_CLUSTER_REGION
			pixel_size = USER_BUSH_PIXEL_SIZE

	var atlas := AtlasTexture.new()
	atlas.atlas = USER_VEGETATION_TEXTURE
	atlas.region = region
	atlas.filter_clip = true

	var sprite := Sprite3D.new()
	sprite.name = kind.to_pascal_case() + "Vegetation"
	sprite.texture = atlas
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# Atlas mipmaps sample neighboring drawings and create detached black marks at
	# this scale. Linear filtering keeps the authored linework clean.
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.scale = Vector3.ONE * scale_value
	var world_height := region.size.y * pixel_size * scale_value
	sprite.position = ground_position + Vector3(0.0, world_height * 0.5 + 0.035, 0.0)
	sprite.set_meta("vegetation_kind", kind)
	sprite.set_meta("source_region", region)
	parent.add_child(sprite)


func _apply_starter_city_palette(roads: Node3D, landmarks: Node3D, neighborhoods: Node3D) -> void:
	var road_material := _starter_city_palette_material(ROAD_COLORMAP, 0, "road")
	var driveway_material := _starter_city_palette_material(SUBURBAN_COLORMAP, 0, "road")
	var building_material := _starter_city_palette_material(SUBURBAN_COLORMAP, 1, "building")
	_apply_palette_material(roads, road_material, driveway_material)
	_apply_palette_material(landmarks, building_material, driveway_material)
	_apply_palette_material(neighborhoods, building_material, driveway_material)

	# Landmarks use decisive local color identities so they remain readable among
	# the vivid supplied trees. Secondary neighborhood geometry keeps the quieter
	# city palette and never competes with route destinations.
	var card_shop := landmarks.get_node_or_null("NeighborhoodCardShop") as Node3D
	if card_shop != null:
		var card_shop_material := _colorful_building_material(
			"building_card_shop",
			GamePalette.AFFINITY_SWEET.lightened(0.34),
			GamePalette.SELECTION_BLUE,
			GamePalette.SIGNAL_YELLOW
		)
		_apply_palette_material(card_shop, card_shop_material, driveway_material)
	var championship := landmarks.get_node_or_null("StarterCityChampionship") as Node3D
	if championship != null:
		var championship_material := _colorful_building_material(
			"building_championship",
			GamePalette.AFFINITY_SPICY.lightened(0.38),
			GamePalette.INTERFACE_VIOLET,
			GamePalette.SIGNAL_YELLOW
		)
		_apply_palette_material(championship, championship_material, driveway_material)


func _colorful_building_material(
	palette_name: String,
	wall_color: Color,
	roof_color: Color,
	accent_color: Color
) -> ShaderMaterial:
	var material := _starter_city_palette_material(SUBURBAN_COLORMAP, 1, palette_name)
	material.set_shader_parameter("wall", wall_color)
	material.set_shader_parameter("roof", roof_color)
	material.set_shader_parameter("trim", GamePalette.GRAPHITE)
	material.set_shader_parameter("glass_color", GamePalette.ELECTRIC_CYAN)
	material.set_shader_parameter("sage", GamePalette.EMERALD)
	material.set_shader_parameter("warm_accent", accent_color)
	return material


func _starter_city_palette_material(source_texture: Texture2D, palette_mode: int, palette_name: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = STARTER_CITY_PALETTE_SHADER
	material.set_shader_parameter("source_texture", source_texture)
	material.set_shader_parameter("palette_mode", palette_mode)
	material.set_shader_parameter("road_asphalt", GamePalette.CITY_ROAD_ASPHALT)
	material.set_shader_parameter("road_shadow", GamePalette.CITY_ROAD_SHADOW)
	material.set_shader_parameter("paving", GamePalette.CITY_PAVING)
	material.set_shader_parameter("wall", GamePalette.CITY_WALL)
	material.set_shader_parameter("roof", GamePalette.CITY_ROOF)
	material.set_shader_parameter("trim", GamePalette.CITY_TRIM)
	material.set_shader_parameter("glass_color", GamePalette.CITY_GLASS)
	material.set_shader_parameter("sage", GamePalette.CITY_SAGE)
	material.set_shader_parameter("warm_accent", GamePalette.CITY_WARM_ACCENT)
	material.set_meta("starter_city_palette", palette_name)
	return material


func _apply_palette_material(node: Node, material: ShaderMaterial, driveway_material: ShaderMaterial) -> void:
	var branch_material := driveway_material if node.name == "DrivewaySurface" else material
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = branch_material
		mesh_instance.set_meta("starter_city_palette", String(branch_material.get_meta("starter_city_palette", "")))
	for child in node.get_children():
		_apply_palette_material(child, branch_material, driveway_material)


func _build_road_grid(graph: Node) -> void:
	road_cells.clear()
	for route_key: String in graph.routes:
		var ids := route_key.split(">")
		if ids.size() != 2:
			continue
		var from: Vector3 = graph.nodes[String(ids[0])].position
		var previous := from
		for route_point_value in graph.routes[route_key]:
			var route_point := route_point_value as Vector3
			_mark_grid_segment(previous, route_point)
			previous = route_point
	var start_position: Vector3 = graph.nodes.start.position
	var boss_position: Vector3 = graph.nodes.final_boss.position
	_mark_grid_segment(start_position, start_position + Vector3.LEFT)
	_mark_grid_segment(boss_position, boss_position + Vector3.RIGHT)
	road_segments = road_cells.size()


func _instantiate_roads(parent: Node3D) -> void:
	for connection_value in road_cells.values():
		_add_road_tile(parent, connection_value as Dictionary)


func _normalize_city_grid(graph: Node) -> void:
	var start_x: int = roundi((graph.nodes.start.position as Vector3).x)
	for layer_index in range(graph.layers.size()):
		var layer_value = graph.layers[layer_index]
		var layer := layer_value as Array
		var layer_x := start_x + layer_index * GRID_COLUMN_STEP
		if layer.size() == 1:
			# Deferred procedural layouts still normalize their endpoints from the
			# lower-left locals to the upper-right championship.
			var endpoint_z := float(GRID_LANES[GRID_LANES.size() - 1])
			if layer_index == graph.layers.size() - 1:
				endpoint_z = float(GRID_LANES[0])
			_set_graph_node_grid_position(graph, String(layer[0]), Vector3(layer_x, 0.62, endpoint_z))
			continue
		var sorted_ids := layer.duplicate()
		sorted_ids.sort_custom(func(a: String, b: String) -> bool:
			return (graph.nodes[a].position as Vector3).z < (graph.nodes[b].position as Vector3).z
		)
		for lane_index in range(sorted_ids.size()):
			var node_id := String(sorted_ids[lane_index])
			_set_graph_node_grid_position(graph, node_id, Vector3(layer_x, 0.62, GRID_LANES[lane_index]))
	var player := get_node_or_null("Player") as CharacterBody3D
	if player != null:
		var current_id := String(graph.current_node_id)
		player.global_position = graph.nodes.get(current_id, graph.nodes.start).position


func _set_graph_node_grid_position(graph: Node, node_id: String, position: Vector3) -> void:
	graph.nodes[node_id].position = position
	if graph.node_sprites.has(node_id):
		var bubble := graph.node_sprites[node_id] as Sprite3D
		bubble.position = position + Vector3(0.0, 0.34, 0.0)
	if graph.node_markers.has(node_id):
		var marker := graph.node_markers[node_id] as Node3D
		marker.position = Vector3(position.x, 0.0, position.z)


func _orthogonalize_route_paths(graph: Node) -> void:
	# Cross-lane route choices share a perpendicular connector street instead of
	# producing overlapping diagonal highways. These points also become the
	# player's actual walking path, keeping navigation and scenery in agreement.
	for route_key_value in graph.routes.keys():
		var route_key := String(route_key_value)
		var ids := route_key.split(">")
		if ids.size() != 2:
			continue
		var from: Vector3 = graph.nodes[String(ids[0])].position
		var to: Vector3 = graph.nodes[String(ids[1])].position
		if absf(from.z - to.z) < 0.7:
			graph.routes[route_key] = [to]
			continue
		var connector_x := roundf((from.x + to.x) * 0.5)
		graph.routes[route_key] = [
			Vector3(connector_x, to.y, from.z),
			Vector3(connector_x, to.y, to.z),
			to,
		]


func _mark_grid_segment(from: Vector3, to: Vector3) -> void:
	var from_cell := Vector2i(roundi(from.x), roundi(from.z))
	var to_cell := Vector2i(roundi(to.x), roundi(to.z))
	if from_cell == to_cell:
		return
	var direction := Vector2i(signi(to_cell.x - from_cell.x), signi(to_cell.y - from_cell.y))
	assert(direction.x == 0 or direction.y == 0, "Road segments must be orthogonal before tiling.")
	var current := from_cell
	while current != to_cell:
		var next := current + direction
		_connect_road_cells(current, next, direction)
		current = next


func _connect_road_cells(from: Vector2i, to: Vector2i, direction: Vector2i) -> void:
	var from_key := _grid_key(from)
	var to_key := _grid_key(to)
	if not road_cells.has(from_key):
		road_cells[from_key] = {"cell": from, "position": Vector3(from.x, ROAD_HEIGHT, from.y), "directions": {}}
	if not road_cells.has(to_key):
		road_cells[to_key] = {"cell": to, "position": Vector3(to.x, ROAD_HEIGHT, to.y), "directions": {}}
	(road_cells[from_key].directions as Dictionary)[direction] = true
	(road_cells[to_key].directions as Dictionary)[-direction] = true


func _grid_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _current_route_walkable_cells(graph: Node) -> Array[Vector2i]:
	var cells := {}
	var current_id := String(graph.current_node_id)
	if not graph.nodes.has(current_id):
		return []
	var current_position := graph.nodes[current_id].position as Vector3
	cells[_grid_key(Vector2i(roundi(current_position.x), roundi(current_position.z)))] = Vector2i(
		roundi(current_position.x), roundi(current_position.z)
	)
	for destination_id in graph.call("_available_destinations"):
		var route_key := current_id + ">" + String(destination_id)
		var previous := current_position
		var fallback_position := graph.nodes[String(destination_id)].position as Vector3
		for point_value in graph.routes.get(route_key, [fallback_position]):
			var point := point_value as Vector3
			_add_walkable_segment(cells, previous, point)
			previous = point
	var result: Array[Vector2i] = []
	for cell_value in cells.values():
		result.append(cell_value as Vector2i)
	return result


func _add_walkable_segment(cells: Dictionary, from: Vector3, to: Vector3) -> void:
	var current := Vector2i(roundi(from.x), roundi(from.z))
	var destination := Vector2i(roundi(to.x), roundi(to.z))
	cells[_grid_key(current)] = current
	while current != destination:
		var difference := destination - current
		var direction := Vector2i(signi(difference.x), 0) if difference.x != 0 else Vector2i(0, signi(difference.y))
		current += direction
		cells[_grid_key(current)] = current


func _add_road_tile(parent: Node3D, connection: Dictionary) -> void:
	var directions := connection.directions as Dictionary
	var tile_scene: PackedScene
	var rotation_y := 0.0
	var tile_name := "RoadTile"
	var cell := connection.cell as Vector2i
	var driveway_key := _grid_key(cell)
	var sides := driveway_sides.get(driveway_key, {}) as Dictionary
	var horizontal_straight := (
		directions.size() == 2
		and directions.has(Vector2i(-1, 0))
		and directions.has(Vector2i(1, 0))
	)
	if horizontal_straight and not sides.is_empty():
		if sides.size() >= 2:
			tile_scene = ROAD_DRIVEWAY_DOUBLE
			tile_name = "RoadDrivewayDouble"
		else:
			tile_scene = ROAD_DRIVEWAY_SINGLE
			tile_name = "RoadDrivewaySingle"
			rotation_y = 0.0 if sides.has(Vector2i(0, -1)) else PI
	else:
		match directions.size():
			1:
				tile_scene = ROAD_END
				rotation_y = _rotation_from_east(directions.keys()[0] as Vector2i)
				tile_name = "RoadEnd"
			2:
				var first := directions.keys()[0] as Vector2i
				var second := directions.keys()[1] as Vector2i
				if first == -second:
					tile_scene = ROAD_STRAIGHT
					rotation_y = 0.0 if first.x != 0 else -PI * 0.5
					tile_name = "RoadStraightTile"
				else:
					tile_scene = ROAD_BEND
					rotation_y = _corner_rotation(directions)
					tile_name = "RoadBend"
			3:
				tile_scene = ROAD_T_JUNCTION
				rotation_y = _t_junction_rotation(directions)
				tile_name = "RoadIntersection"
			_:
				tile_scene = ROAD_CROSSROAD
				tile_name = "RoadCrossroad"
	var tile := _spawn_scene(tile_scene, parent, tile_name)
	var position_value := connection.position as Vector3
	tile.position = Vector3(position_value.x, ROAD_HEIGHT, position_value.z)
	tile.rotation.y = rotation_y
	tile.scale = Vector3.ONE
	tile.set_meta("grid_cell", cell)
	tile.set_meta("connection_count", directions.size())
	tile.set_meta("connection_directions", directions.keys())
	tile.set_meta("driveway_count", sides.size())
	tile.set_meta("road_piece", "end_round" if directions.size() == 1 else tile_name)
	if directions.size() != 2 or (directions.keys()[0] as Vector2i) != -(directions.keys()[1] as Vector2i):
		road_junctions += 1


func _rotation_from_east(direction: Vector2i) -> float:
	if direction == Vector2i(0, 1):
		return -PI * 0.5
	if direction == Vector2i(-1, 0):
		return PI
	if direction == Vector2i(0, -1):
		return PI * 0.5
	return 0.0


func _corner_rotation(directions: Dictionary) -> float:
	# Kenney's road-bend.glb opens west + south at its authored rotation.
	if directions.has(Vector2i(-1, 0)) and directions.has(Vector2i(0, 1)):
		return 0.0
	if directions.has(Vector2i(-1, 0)) and directions.has(Vector2i(0, -1)):
		return -PI * 0.5
	if directions.has(Vector2i(1, 0)) and directions.has(Vector2i(0, -1)):
		return PI
	return PI * 0.5


func _t_junction_rotation(directions: Dictionary) -> float:
	if not directions.has(Vector2i(0, -1)):
		return 0.0
	if not directions.has(Vector2i(1, 0)):
		return -PI * 0.5
	if not directions.has(Vector2i(0, 1)):
		return PI
	return PI * 0.5


func _build_landmarks(graph: Node, parent: Node3D) -> void:
	var start_position: Vector3 = graph.nodes.start.position
	var boss_position: Vector3 = graph.nodes.final_boss.position
	var shop := _spawn_scene(LANDMARK_SHOP, parent, "NeighborhoodCardShop")
	# Keep the doorway, driveway, route stop, and avatar on one centerline so the
	# close camera opens with the player clearly standing in front of home.
	shop.position = Vector3(start_position.x, 0.03, start_position.z - 2.0)
	shop.rotation.y = 0.0
	shop.scale = Vector3.ONE * 1.34
	shop.set_meta("landmark", "start_card_shop")
	_register_driveway(parent, shop.position, shop.rotation.y)
	building_count += 1
	var championship := _spawn_scene(LANDMARK_CHAMPIONSHIP, parent, "StarterCityChampionship")
	championship.position = Vector3(boss_position.x - 1.0, 0.03, boss_position.z + 2.0)
	championship.rotation.y = PI
	championship.scale = Vector3.ONE * 1.46
	championship.set_meta("landmark", "floor_boss_venue")
	_register_driveway(parent, championship.position, championship.rotation.y)
	building_count += 1


func _build_neighborhood_blocks(graph: Node, buildings: Node3D, dressing: Node3D, rng: RandomNumberGenerator) -> void:
	# Give each route interval one visual anchor instead of filling every parcel.
	# The remaining parcels alternate between a small green pocket and open space,
	# keeping encounter markers readable while the city still feels inhabited.
	for layer_index in range(1, graph.layers.size() - 2):
		var from_layer: Array = graph.layers[layer_index]
		var to_layer: Array = graph.layers[layer_index + 1]
		if from_layer.size() < 4 or to_layer.size() < 4:
			continue
		var from_x: int = roundi((graph.nodes[String(from_layer[0])].position as Vector3).x)
		var pattern_seed := layer_index * 5 + int(graph.generation_seed)
		var house_band := posmod(pattern_seed, 3)
		var green_band := posmod(house_band + 1 + posmod(pattern_seed, 2), 3)
		for band_index in range(3):
			var upper: Vector3 = graph.nodes[String(from_layer[band_index])].position
			var lower: Vector3 = graph.nodes[String(from_layer[band_index + 1])].position
			var cell_z := roundi((upper.z + lower.z) * 0.5)
			var cell_x := from_x + 1
			if band_index == house_band:
				var facing := PI if band_index % 2 == 0 else 0.0
				_add_house(buildings, cell_x, cell_z, facing, rng, 1.18)
				_add_block_tree(dressing, Vector3(cell_x + 0.9, 0.08, cell_z), rng, 0.88)
			elif band_index == green_band:
				if posmod(pattern_seed, 2) == 0:
					_add_park_lot(dressing, Vector3(cell_x, 0.02, cell_z), rng)
				else:
					_add_block_tree(dressing, Vector3(cell_x, 0.08, cell_z), rng, 0.92)


func _build_outer_edges(graph: Node, buildings: Node3D, dressing: Node3D, rng: RandomNumberGenerator) -> void:
	for layer_index in range(1, graph.layers.size() - 1, 2):
		var layer: Array = graph.layers[layer_index]
		if layer.is_empty():
			continue
		var x: float = graph.nodes[String(layer[0])].position.x
		var use_north_edge := posmod(floori(layer_index * 0.5) + int(graph.generation_seed), 2) == 0
		var building_z := NORTH_BUILDING_Z if use_north_edge else SOUTH_BUILDING_Z
		var facing := 0.0 if use_north_edge else PI
		var tree_offset := 1.0 if use_north_edge else -1.0
		_add_house(buildings, x, building_z, facing, rng, 1.24)
		_add_block_tree(dressing, Vector3(x + tree_offset, 0.02, building_z), rng, 1.0)


func _add_house(parent: Node3D, x: float, z: float, facing: float, rng: RandomNumberGenerator, base_scale := 0.68) -> void:
	_register_driveway(parent, Vector3(x, 0.03, z), facing)
	var building_scene: PackedScene = SUBURBAN_BUILDINGS[rng.randi_range(0, SUBURBAN_BUILDINGS.size() - 1)]
	var building := _spawn_scene(building_scene, parent, "NeighborhoodBuilding")
	building.position = Vector3(x, 0.03, z)
	building.rotation.y = facing
	var scale_variation := base_scale * rng.randf_range(0.94, 1.06)
	building.scale = Vector3.ONE * scale_variation
	building.set_meta("map_role", "neighborhood_building")
	building_count += 1


func _register_driveway(parent: Node3D, building_position: Vector3, facing: float) -> void:
	var front_direction := Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, facing)
	var road_position := building_position + front_direction * 2.0
	var road_cell := Vector2i(roundi(road_position.x), roundi(road_position.z))
	var road_key := _grid_key(road_cell)
	if not road_cells.has(road_key):
		return
	var surface := _spawn_scene(DRIVEWAY_SURFACE, parent, "DrivewaySurface")
	surface.position = Vector3(building_position.x, 0.025, building_position.z) + front_direction * 1.15
	surface.rotation.y = facing
	surface.scale = Vector3(1.0, 1.0, 3.5)
	if not driveway_sides.has(road_key):
		driveway_sides[road_key] = {}
	var building_side := Vector2i(roundi(-front_direction.x), roundi(-front_direction.z))
	(driveway_sides[road_key] as Dictionary)[building_side] = true


func _add_park_lot(parent: Node3D, center: Vector3, rng: RandomNumberGenerator) -> void:
	_add_block_tree(parent, center + Vector3(-0.75, 0.08, 0.15), rng, 1.22)
	_add_block_tree(parent, center + Vector3(0.7, 0.08, -0.2), rng, 1.02)
	for offset in [Vector3(-0.55, 0.0, -0.9), Vector3(0.55, 0.0, 0.85)]:
		var planter := _spawn_scene(PLANTER, parent, "ParkPlanter")
		planter.position = center + offset + Vector3(0.0, 0.08, 0.0)
		planter.rotation.y = 0.0 if absf(offset.x) > absf(offset.z) else PI * 0.5
		planter.scale = Vector3.ONE * 0.94
		nature_count += 1


func _add_block_tree(parent: Node3D, position_value: Vector3, rng: RandomNumberGenerator, scale_value: float) -> void:
	var tree_scene: PackedScene = TREES[rng.randi_range(0, TREES.size() - 1)]
	var tree := _spawn_scene(tree_scene, parent, "NeighborhoodTree")
	tree.position = position_value
	tree.rotation.y = rng.randf_range(-PI, PI)
	tree.scale = Vector3.ONE * scale_value
	nature_count += 1


func _build_street_furniture(graph: Node, parent: Node3D, rng: RandomNumberGenerator) -> void:
	for layer_index in range(1, graph.layers.size() - 1, 2):
		var layer: Array = graph.layers[layer_index]
		if layer.size() < 4:
			continue
		for lane_index in [0, 3]:
			var node_position: Vector3 = graph.nodes[String(layer[lane_index])].position
			var light := _spawn_scene(STREET_LIGHT, parent, "StreetLight")
			light.position = Vector3(node_position.x + 1.15, 0.04, node_position.z + (-0.72 if lane_index == 0 else 0.72))
			light.rotation.y = PI * 0.5
			light.scale = Vector3.ONE * rng.randf_range(0.82, 0.92)
			nature_count += 1


func _spawn_scene(scene: PackedScene, parent: Node3D, node_name: String) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.name = node_name
	parent.add_child(instance)
	return instance
