extends Node

signal node_reached(node_id: String)
signal route_ready(snapshot: Dictionary)

const NAVY := Color("#29365F")
const CREAM := Color("#FFF7F1")
const CORAL := Color("#EF7E76")
const SKY := Color("#68C5E8")
const LAVENDER := Color("#E8E3F5")
const INACTIVE_ICON_TINT := Color(0.92, 0.94, 0.98, 0.84)
const ROUTE_YELLOW := Color("#F4DE77")
const ROUTE_INK := Color("#53628A")
const ROUTE_LANE_COUNT := 4
const MINIBOSS_ROWS := [2, 4]
const WEAVE_TRANSITIONS := [1, 3]
const ROUTE_ICON_WORLD_EXTENT := 1.785
const FINAL_BOSS_ICON_SCALE := 1.28
const ROUTE_ICON_BUTTON_SIZE := 102.0
const NPC_ARCHETYPES := ["spicy", "hearty", "sweet", "fresh", "funky"]
const NPC_PERSONALITIES := ["bold", "patient", "clever", "curious", "competitive"]

@export var generation_seed := 0
@export_range(5, 8, 1) var route_columns := 6
@export var horizontal_gap := 4.5
@export var camera_pan_speed := 13.0
@export var camera_wheel_step := 2.2
@export var camera_x_min := -8.0
@export var camera_x_max := 28.0
@export var camera_z_min := 22.0
@export var camera_z_max := 36.0
@export var camera_ground_offset_z := 25.3
@export var camera_focus_lead_x := 0.0
@export var vertical_camera_locked := false

@onready var player = get_parent().get_node("Player")
@onready var camera: Camera3D = get_parent().get_node("Camera3D")
@onready var button_layer: Control = get_parent().get_node("Interface/RouteButtons")
@onready var status_label: Label = get_parent().get_node("Interface/RouteStatus")

var nodes: Dictionary = {}
var routes: Dictionary = {}
var layers: Array = []
var route_lines: Node3D
var route_stops: Node3D
var current_node_id := "start"
var visited: Array[String] = ["start"]
var node_buttons: Dictionary = {}
var node_sprites: Dictionary = {}
var node_markers: Dictionary = {}
var icon_textures: Dictionary = {}
var pan_direction := 0.0
var vertical_pan_direction := 0.0
var camera_target_x := -8.0
var camera_target_z := 28.0
var left_pan_button: Button
var right_pan_button: Button
var up_pan_button: Button
var down_pan_button: Button
var configured_state: Dictionary = {}
var choices_locked := false
var route_float_time := 0.0
var camera_input_locked := false
var world_exploration_mode := false


func configure(state: Dictionary) -> void:
	configured_state = state.duplicate(true)
	generation_seed = int(configured_state.get("seed", generation_seed))


func set_choices_locked(locked: bool) -> void:
	choices_locked = locked
	if is_node_ready():
		_refresh_choices()


func enable_world_exploration() -> void:
	world_exploration_mode = true
	button_layer.visible = false
	if route_lines != null:
		route_lines.visible = false
	if route_stops != null:
		route_stops.visible = false
	for pan_button in [left_pan_button, right_pan_button, up_pan_button, down_pan_button]:
		if pan_button != null:
			(pan_button as Control).visible = false
	_refresh_choices()


func trigger_world_destination(node_id: String) -> bool:
	if choices_locked or node_id not in _available_destinations():
		return false
	_set_buttons_enabled(false)
	_arrive_at(node_id)
	return true


func node_data(node_id: String) -> Dictionary:
	return (nodes.get(node_id, {}) as Dictionary).duplicate(true)


func snapshot() -> Dictionary:
	var serialized_nodes := {}
	for node_id: String in nodes:
		var data: Dictionary = nodes[node_id]
		var position: Vector3 = data.get("position", Vector3.ZERO)
		var serialized: Dictionary = data.duplicate(true)
		serialized.position = [position.x, position.y, position.z]
		serialized.next = (data.get("next", []) as Array).duplicate()
		serialized_nodes[node_id] = serialized
	var serialized_routes := {}
	for route_key: String in routes:
		var serialized_points: Array = []
		for point_value in routes[route_key]:
			var point := point_value as Vector3
			serialized_points.append([point.x, point.y, point.z])
		serialized_routes[route_key] = serialized_points
	return {
		"seed": generation_seed,
		"nodes": serialized_nodes,
		"routes": serialized_routes,
		"layers": layers.duplicate(true),
		"current": current_node_id,
		"visited": visited.duplicate(),
	}


func route_icon_pixel_size(texture: Texture2D, world_extent: float = ROUTE_ICON_WORLD_EXTENT) -> float:
	if texture == null:
		return 0.003
	var texture_extent := maxi(texture.get_width(), texture.get_height())
	return world_extent / float(maxi(texture_extent, 1))


func route_icon_world_extent(node_type: String, base_extent: float = ROUTE_ICON_WORLD_EXTENT) -> float:
	return base_extent * FINAL_BOSS_ICON_SCALE if node_type == "final_boss" else base_extent


func _ready() -> void:
	icon_textures = {
		"shop": load("res://assets/overworld/route_icons/shop.png"),
		"enemy": load("res://assets/overworld/route_icons/enemy.png"),
		"event": load("res://assets/overworld/route_icons/event.png"),
		"mini_boss": load("res://assets/overworld/route_icons/mini_boss.png"),
		"final_boss": load("res://assets/overworld/route_icons/final_boss.png"),
	}
	if not configured_state.get("nodes", {}).is_empty():
		_restore_route_graph(configured_state)
	else:
		_generate_route_graph()
	current_node_id = String(configured_state.get("current", current_node_id))
	visited.clear()
	for visited_id in configured_state.get("visited", ["start"]):
		visited.append(String(visited_id))
	if visited.is_empty():
		visited.append("start")
	route_lines = Node3D.new()
	route_lines.name = "RouteNetwork"
	get_parent().add_child.call_deferred(route_lines)
	route_stops = Node3D.new()
	route_stops.name = "RouteStops"
	get_parent().add_child.call_deferred(route_stops)
	_build_buttons()
	_build_node_sprites()
	_build_pan_controls()
	_build_route_board()
	# Rebuilding the map after a battle, shop, event, deck view, or settings must
	# restore the avatar to the committed route node rather than visually sending
	# the player back to the starting shop.
	if not nodes.has(current_node_id):
		current_node_id = "start"
	_restore_map_pose()
	call_deferred("_restore_map_pose")
	_refresh_choices()
	route_ready.emit(snapshot())


func _restore_map_pose() -> void:
	if not nodes.has(current_node_id) or not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var restored_position: Vector3 = nodes[current_node_id]["position"]
	player.global_position = restored_position
	camera_target_x = clampf(
		restored_position.x + camera_focus_lead_x,
		camera_x_min,
		camera_x_max
	)
	camera.position.x = camera_target_x
	if not vertical_camera_locked:
		camera_target_z = clampf(restored_position.z + camera_ground_offset_z, camera_z_min, camera_z_max)
		camera.position.z = camera_target_z


func _process(delta: float) -> void:
	route_float_time += delta
	if world_exploration_mode:
		camera.position.x = move_toward(camera.position.x, camera_target_x, camera_pan_speed * delta)
		camera.position.z = move_toward(camera.position.z, camera_target_z, camera_pan_speed * delta)
		return
	if not camera_input_locked and not is_zero_approx(pan_direction):
		camera_target_x = clampf(camera_target_x + pan_direction * camera_pan_speed * delta, camera_x_min, camera_x_max)
	if not vertical_camera_locked and not camera_input_locked and not is_zero_approx(vertical_pan_direction):
		camera_target_z = clampf(camera_target_z + vertical_pan_direction * camera_pan_speed * delta, camera_z_min, camera_z_max)
	camera.position.x = move_toward(camera.position.x, camera_target_x, camera_pan_speed * delta)
	camera.position.z = move_toward(camera.position.z, camera_target_z, camera_pan_speed * delta)
	_animate_route_icons()
	_layout_buttons()
	_update_pan_controls()


func _input(event: InputEvent) -> void:
	if camera_input_locked:
		return
	if event is InputEventPanGesture:
		var pan_event := event as InputEventPanGesture
		_pan_camera_by(Vector2(pan_event.delta.x, pan_event.delta.y) * camera_wheel_step)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	var wheel_direction := 0.0
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			wheel_direction = -1.0
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			wheel_direction = 1.0
		_:
			return
	var horizontal_scroll := (
		mouse_event.shift_pressed
		or mouse_event.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
	)
	_pan_camera_from_wheel(wheel_direction * maxf(mouse_event.factor, 0.25), horizontal_scroll)
	get_viewport().set_input_as_handled()


func _pan_camera_by(offset: Vector2) -> void:
	if camera_input_locked:
		return
	var horizontal_offset := offset.x
	if vertical_camera_locked and absf(offset.y) > absf(offset.x):
		horizontal_offset = offset.y
	camera_target_x = clampf(camera_target_x + horizontal_offset, camera_x_min, camera_x_max)
	if not vertical_camera_locked:
		camera_target_z = clampf(camera_target_z + offset.y, camera_z_min, camera_z_max)


func _pan_camera_from_wheel(direction: float, horizontal: bool = false) -> void:
	if camera_input_locked:
		return
	if horizontal or vertical_camera_locked:
		camera_target_x = clampf(
			camera_target_x + direction * camera_wheel_step,
			camera_x_min,
			camera_x_max
		)
	else:
		camera_target_z = clampf(
			camera_target_z + direction * camera_wheel_step,
			camera_z_min,
			camera_z_max
		)


func select_destination(node_id: String) -> void:
	if choices_locked or player.is_following_route() or node_id not in _available_destinations():
		return
	var key := current_node_id + ">" + node_id
	var points: Array[Vector3] = []
	var fallback_position: Vector3 = nodes[node_id]["position"]
	for route_point in routes.get(key, [fallback_position]):
		points.append(route_point as Vector3)
	_set_buttons_enabled(false)
	status_label.text = "Traveling to %s…" % str(nodes[node_id]["label"])
	# Full-map overview locks camera input and owns a fixed framing of the complete
	# route. Keep that framing while the avatar travels instead of following the
	# destination and creating a zoom/pan impression.
	if not camera_input_locked:
		var destination: Vector3 = nodes[node_id]["position"]
		camera_target_x = clampf(
			destination.x + camera_focus_lead_x,
			camera_x_min,
			camera_x_max
		)
		if not vertical_camera_locked:
			camera_target_z = clampf(destination.z + camera_ground_offset_z, camera_z_min, camera_z_max)
	player.follow_route(points, _arrive_at.bind(node_id))


func _arrive_at(node_id: String) -> void:
	current_node_id = node_id
	if node_id not in visited:
		visited.append(node_id)
	status_label.text = "Arrived: %s" % str(nodes[node_id]["label"])
	_refresh_choices()
	node_reached.emit(node_id)


func _available_destinations() -> Array[String]:
	var result: Array[String] = []
	for node_id in nodes[current_node_id]["next"]:
		result.append(str(node_id))
	return result


func _generate_route_graph() -> void:
	_generate_authored_town_graph()


func _generate_authored_town_graph() -> void:
	nodes.clear()
	routes.clear()
	layers.clear()
	var start_position := Vector3(-12.0, 0.62, 8.0)
	nodes["start"] = {
		"type": "start", "label": "Neighborhood Locals", "position": start_position, "next": []
	}
	_add_authored_node("rival_town_west", "enemy", "Neighborhood Challenger", Vector3(-8.0, 0.62, 8.0), Vector2(0.0, -1.5))
	_add_authored_node("rival_town_center", "enemy", "Park Table Rival", Vector3(-3.0, 0.62, 8.0), Vector2(0.0, -1.5))
	_add_authored_node("event_west", "event", "Town Crossroads", Vector3(-6.0, 0.62, 2.0))
	_add_authored_node("event_south", "event", "Garden Gate", Vector3(4.0, 0.62, 8.0))
	_add_authored_node("shop_city", "shop", "Card Store", Vector3(-2.0, 0.62, 2.0))
	_add_authored_node("rival_mid_east", "enemy", "City League Player", Vector3(4.0, 0.62, 2.0), Vector2(0.0, -1.5))
	_add_authored_node("event_northwest", "event", "City Corner", Vector3(2.0, 0.62, -6.0))
	_add_authored_node("event_east", "event", "Championship Turn", Vector3(10.0, 0.62, 2.0))
	_add_authored_node("rival_top", "enemy", "Uptown Challenger", Vector3(6.0, 0.62, -6.0), Vector2(0.0, -1.5))
	_add_authored_node("ace_east", "mini_boss", "Neighborhood Ace", Vector3(10.0, 0.62, -3.0), Vector2(1.5, 0.0))
	_add_authored_node("ace_top", "mini_boss", "League Favorite", Vector3(10.0, 0.62, -6.0), Vector2(0.0, -1.5))
	var boss_position := Vector3(12.0, 0.62, -6.0)
	nodes["final_boss"] = {
		"type": "final_boss", "label": "Starter City Championship", "position": boss_position, "next": []
	}
	layers = [
		["start"],
		["rival_town_west"],
		["rival_town_center", "event_west"],
		["event_south", "shop_city"],
		["rival_mid_east", "event_northwest"],
		["event_east", "rival_top"],
		["ace_east", "ace_top"],
		["final_boss"],
	]

	_connect_authored_nodes("start", "rival_town_west", [Vector3(-8.0, 0.62, 8.0)])
	_connect_authored_nodes("rival_town_west", "rival_town_center", [Vector3(-3.0, 0.62, 8.0)])
	_connect_authored_nodes(
		"rival_town_west",
		"event_west",
		[Vector3(-6.0, 0.62, 8.0), Vector3(-6.0, 0.62, 2.0)]
	)
	_connect_authored_nodes("rival_town_center", "event_south", [Vector3(4.0, 0.62, 8.0)])
	_connect_authored_nodes("event_west", "shop_city", [Vector3(-2.0, 0.62, 2.0)])
	_connect_authored_nodes(
		"event_south",
		"rival_mid_east",
		[Vector3(4.0, 0.62, 2.0)]
	)
	_connect_authored_nodes(
		"shop_city",
		"event_northwest",
		[
			Vector3(4.0, 0.62, 2.0),
			Vector3(4.0, 0.62, -6.0),
			Vector3(2.0, 0.62, -6.0),
		]
	)
	_connect_authored_nodes("rival_mid_east", "event_east", [Vector3(10.0, 0.62, 2.0)])
	_connect_authored_nodes("event_northwest", "rival_top", [Vector3(6.0, 0.62, -6.0)])
	_connect_authored_nodes("event_east", "ace_east", [Vector3(10.0, 0.62, -3.0)])
	_connect_authored_nodes("rival_top", "ace_top", [Vector3(10.0, 0.62, -6.0)])
	_connect_authored_nodes(
		"ace_east",
		"final_boss",
		[Vector3(10.0, 0.62, -6.0), boss_position]
	)
	_connect_authored_nodes("ace_top", "final_boss", [boss_position])
	_assign_npc_profiles()


func _add_authored_node(
	node_id: String,
	node_type: String,
	label: String,
	position: Vector3,
	npc_offset: Vector2 = Vector2.ZERO
) -> void:
	var data := {
		"type": node_type,
		"label": label,
		"position": position,
		"next": [],
	}
	if npc_offset != Vector2.ZERO:
		data.npc_offset = [npc_offset.x, npc_offset.y]
	nodes[node_id] = data


func _connect_authored_nodes(from_id: String, to_id: String, points: Array[Vector3]) -> void:
	var next_nodes: Array = nodes[from_id]["next"]
	if to_id not in next_nodes:
		next_nodes.append(to_id)
		nodes[from_id]["next"] = next_nodes
	routes[from_id + ">" + to_id] = points.duplicate()


func _restore_route_graph(state: Dictionary) -> void:
	nodes.clear()
	routes.clear()
	layers = (state.get("layers", []) as Array).duplicate(true)
	for node_id_value in (state.get("nodes", {}) as Dictionary).keys():
		var node_id := String(node_id_value)
		var saved: Dictionary = state.nodes[node_id]
		var raw_position: Array = saved.get("position", [0.0, 0.62, 0.0])
		var position := Vector3(
			float(raw_position[0]) if raw_position.size() > 0 else 0.0,
			float(raw_position[1]) if raw_position.size() > 1 else 0.62,
			float(raw_position[2]) if raw_position.size() > 2 else 0.0
		)
		var restored: Dictionary = saved.duplicate(true)
		restored.type = String(saved.get("type", "enemy"))
		restored.label = String(saved.get("label", node_id))
		restored.position = position
		restored.next = (saved.get("next", []) as Array).duplicate()
		nodes[node_id] = restored
	var saved_routes := state.get("routes", {}) as Dictionary
	if saved_routes.is_empty():
		for from_id: String in nodes:
			for to_id_value in nodes[from_id].get("next", []):
				var to_id := String(to_id_value)
				if nodes.has(to_id):
					routes[from_id + ">" + to_id] = [nodes[to_id]["position"]]
	else:
		for route_key_value in saved_routes.keys():
			var route_key := String(route_key_value)
			var restored_points: Array[Vector3] = []
			for raw_point_value in saved_routes[route_key_value]:
				var raw_point := raw_point_value as Array
				restored_points.append(
					Vector3(
						float(raw_point[0]) if raw_point.size() > 0 else 0.0,
						float(raw_point[1]) if raw_point.size() > 1 else 0.62,
						float(raw_point[2]) if raw_point.size() > 2 else 0.0
					)
				)
			routes[route_key] = restored_points
	_assign_npc_profiles()


func _assign_npc_profiles() -> void:
	for node_id: String in nodes:
		var data := nodes[node_id] as Dictionary
		var node_type := String(data.get("type", "enemy"))
		if node_type not in ["enemy", "mini_boss", "final_boss", "event"]:
			continue
		var profile_seed := generation_seed ^ node_id.hash()
		if not data.has("npc_archetype"):
			data.npc_archetype = NPC_ARCHETYPES[posmod(profile_seed, NPC_ARCHETYPES.size())]
		if not data.has("npc_personality"):
			var personality_index := posmod(
				floori(float(profile_seed) / float(maxi(1, NPC_ARCHETYPES.size()))),
				NPC_PERSONALITIES.size()
			)
			data.npc_personality = NPC_PERSONALITIES[
				personality_index
			]
		if not data.has("npc_portrait_id"):
			data.npc_portrait_id = "npc1" if posmod(profile_seed, 2) == 0 else "npc2"
		if node_type == "mini_boss":
			data.npc_portrait_id = "npc2"
		elif node_type == "final_boss":
			data.npc_portrait_id = "npc1"
		nodes[node_id] = data


func _connect_route_rows(from_row: Array, to_row: Array, transition_index: int, rng: RandomNumberGenerator) -> void:
	for lane_index in range(ROUTE_LANE_COUNT):
		_connect_nodes(String(from_row[lane_index]), String(to_row[lane_index]))
	if transition_index not in WEAVE_TRANSITIONS:
		return

	var weave_pairs: Array = []
	match transition_index:
		1:
			weave_pairs = [[0, 1], [2, 3]]
		3:
			weave_pairs = [[1, 2]]
			weave_pairs.append([0, 1] if rng.randf() < 0.5 else [2, 3])
	for pair_value in weave_pairs:
		var pair: Array = pair_value
		var first_lane := int(pair[0])
		var second_lane := int(pair[1])
		_connect_nodes(String(from_row[first_lane]), String(to_row[second_lane]))
		_connect_nodes(String(from_row[second_lane]), String(to_row[first_lane]))


func _connect_nodes(from_id: String, to_id: String) -> void:
	var next_nodes: Array = nodes[from_id]["next"]
	if to_id in next_nodes:
		return
	next_nodes.append(to_id)
	nodes[from_id]["next"] = next_nodes
	var target_position: Vector3 = nodes[to_id]["position"]
	routes[from_id + ">" + to_id] = [target_position]


func _label_for_type(node_type: String, rng: RandomNumberGenerator) -> String:
	var choices := {
		"enemy": ["League Player", "Featured Match", "Challenger", "Top Table"],
		"event": ["Surprise Event", "Friendly Face", "Card Shop Story"],
		"shop": ["Card Shop", "Corner Game Shop", "Deck Counter"],
		"mini_boss": ["Local Champion", "Neighborhood Ace", "League Favorite", "Park Table Pro"],
	}
	var labels: Array = choices[node_type]
	return str(labels[rng.randi_range(0, labels.size() - 1)])


func _build_buttons() -> void:
	for node_id: String in nodes:
		if node_id == "start":
			continue
		var button := TextureButton.new()
		button.name = node_id.to_pascal_case() + "RouteButton"
		button.texture_normal = icon_textures[nodes[node_id]["type"]]
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		var node_type := String(nodes[node_id]["type"])
		var button_extent := ROUTE_ICON_BUTTON_SIZE * (FINAL_BOSS_ICON_SCALE if node_type == "final_boss" else 1.0)
		button.custom_minimum_size = Vector2.ONE * button_extent
		button.size = Vector2.ONE * button_extent
		button.tooltip_text = str(nodes[node_id]["label"])
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(select_destination.bind(node_id))
		button.mouse_entered.connect(_set_node_hovered.bind(node_id, true))
		button.mouse_exited.connect(_set_node_hovered.bind(node_id, false))
		button_layer.add_child(button)
		node_buttons[node_id] = button


func _build_node_sprites() -> void:
	for node_id: String in nodes:
		if node_id == "start":
			continue
		var bubble := Sprite3D.new()
		bubble.name = node_id.to_pascal_case() + "RouteBubble"
		bubble.texture = icon_textures[nodes[node_id]["type"]]
		bubble.position = nodes[node_id]["position"] + Vector3(0.0, 0.34, 0.0)
		var world_extent := route_icon_world_extent(String(nodes[node_id]["type"]))
		bubble.pixel_size = route_icon_pixel_size(bubble.texture, world_extent)
		bubble.set_meta("route_icon_world_extent", world_extent)
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.shaded = false
		bubble.double_sided = true
		bubble.no_depth_test = true
		bubble.render_priority = 0
		route_stops.add_child(bubble)
		node_sprites[node_id] = bubble


func _build_pan_controls() -> void:
	left_pan_button = _make_pan_button("MapPanLeft", "‹", true)
	right_pan_button = _make_pan_button("MapPanRight", "›", false)
	left_pan_button.mouse_entered.connect(_set_pan_direction.bind(-1.0))
	left_pan_button.mouse_exited.connect(_clear_pan_direction.bind(-1.0))
	right_pan_button.mouse_entered.connect(_set_pan_direction.bind(1.0))
	right_pan_button.mouse_exited.connect(_clear_pan_direction.bind(1.0))
	if vertical_camera_locked:
		return
	up_pan_button = _make_vertical_pan_button("MapPanUp", "↑", true)
	down_pan_button = _make_vertical_pan_button("MapPanDown", "↓", false)
	up_pan_button.mouse_entered.connect(_set_vertical_pan_direction.bind(-1.0))
	up_pan_button.mouse_exited.connect(_clear_vertical_pan_direction.bind(-1.0))
	down_pan_button.mouse_entered.connect(_set_vertical_pan_direction.bind(1.0))
	down_pan_button.mouse_exited.connect(_clear_vertical_pan_direction.bind(1.0))


func _make_pan_button(button_name: String, arrow_text: String, on_left: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = arrow_text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	button.offset_top = -58.0
	button.offset_bottom = 58.0
	if on_left:
		button.anchor_left = 0.0
		button.anchor_right = 0.0
		button.offset_left = 18.0
		button.offset_right = 82.0
	else:
		button.anchor_left = 1.0
		button.anchor_right = 1.0
		button.offset_left = -82.0
		button.offset_right = -18.0
	button.add_theme_font_size_override("font_size", 52)
	button.add_theme_color_override("font_color", GamePalette.COOL_WHITE)
	button.add_theme_color_override("font_hover_color", GamePalette.COOL_WHITE)
	button.add_theme_color_override("font_pressed_color", GamePalette.CARBON)
	button.add_theme_stylebox_override("normal", _pan_style(GamePalette.GRAPHITE, GamePalette.STEEL))
	button.add_theme_stylebox_override("hover", _pan_style(GamePalette.SELECTION_BLUE, GamePalette.ELECTRIC_CYAN))
	button.add_theme_stylebox_override("pressed", _pan_style(GamePalette.ELECTRIC_CYAN, GamePalette.COOL_WHITE))
	get_parent().get_node("Interface").add_child(button)
	return button


func _make_vertical_pan_button(button_name: String, arrow_text: String, on_top: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = arrow_text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.anchor_left = 0.58 if on_top else 0.5
	button.anchor_right = 0.58 if on_top else 0.5
	button.offset_left = -48.0
	button.offset_right = 48.0
	if on_top:
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_top = 18.0
		button.offset_bottom = 78.0
	else:
		button.anchor_top = 1.0
		button.anchor_bottom = 1.0
		button.offset_top = -78.0
		button.offset_bottom = -18.0
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", GamePalette.COOL_WHITE)
	button.add_theme_color_override("font_hover_color", GamePalette.COOL_WHITE)
	button.add_theme_color_override("font_pressed_color", GamePalette.CARBON)
	button.add_theme_stylebox_override("normal", _pan_style(GamePalette.GRAPHITE, GamePalette.STEEL))
	button.add_theme_stylebox_override("hover", _pan_style(GamePalette.SELECTION_BLUE, GamePalette.ELECTRIC_CYAN))
	button.add_theme_stylebox_override("pressed", _pan_style(GamePalette.ELECTRIC_CYAN, GamePalette.COOL_WHITE))
	get_parent().get_node("Interface").add_child(button)
	return button


func _pan_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = 4
	return style


func _set_pan_direction(direction: float) -> void:
	pan_direction = direction


func _clear_pan_direction(direction: float) -> void:
	if is_equal_approx(pan_direction, direction):
		pan_direction = 0.0


func _set_vertical_pan_direction(direction: float) -> void:
	vertical_pan_direction = direction


func _clear_vertical_pan_direction(direction: float) -> void:
	if is_equal_approx(vertical_pan_direction, direction):
		vertical_pan_direction = 0.0


func _update_pan_controls() -> void:
	left_pan_button.modulate.a = 1.0 if camera.position.x > camera_x_min + 0.1 else 0.35
	right_pan_button.modulate.a = 1.0 if camera.position.x < camera_x_max - 0.1 else 0.35
	if up_pan_button != null:
		up_pan_button.modulate.a = 1.0 if camera.position.z > camera_z_min + 0.1 else 0.35
	if down_pan_button != null:
		down_pan_button.modulate.a = 1.0 if camera.position.z < camera_z_max - 0.1 else 0.35


func _refresh_choices() -> void:
	var available := _available_destinations()
	for node_id: String in node_buttons:
		var button := node_buttons[node_id] as TextureButton
		var bubble := node_sprites[node_id] as Sprite3D
		var can_choose := not choices_locked and node_id in available
		button.disabled = not can_choose
		button.modulate = Color(1.0, 1.0, 1.0, 0.0)
		bubble.modulate = Color.WHITE if can_choose else INACTIVE_ICON_TINT
		_set_marker_state(node_id, can_choose, false)
	if world_exploration_mode:
		status_label.text = "Explore the open streets"
		return
	if choices_locked:
		status_label.text = "Resolve this stop before continuing"
		return
	if available.is_empty():
		status_label.text = "Route complete — press Space to celebrate!"
	else:
		status_label.text = "Choose your next destination"


func _build_route_board() -> void:
	for route_key: String in routes:
		var split := route_key.split(">")
		var from: Vector3 = nodes[split[0]]["position"]
		var points: Array[Vector3] = [from]
		for route_point in routes[route_key]:
			points.append(route_point as Vector3)
		for index in range(points.size() - 1):
			_add_dotted_route(points[index], points[index + 1])
	for node_id: String in nodes:
		if node_id != "start":
			_add_stop_platform(nodes[node_id]["position"], node_id)


func _add_dotted_route(from: Vector3, to: Vector3) -> void:
	var flat_from := Vector3(from.x, 0.14, from.z)
	var flat_to := Vector3(to.x, 0.14, to.z)
	var offset := flat_to - flat_from
	var length := offset.length()
	if length <= 0.01:
		return
	var endpoint_margin := minf(0.72, length * 0.2)
	var usable_length := maxf(0.1, length - endpoint_margin * 2.0)
	var dot_count := maxi(2, int(floor(usable_length / 0.46)) + 1)
	var direction := offset / length

	var dot_mesh := CylinderMesh.new()
	dot_mesh.top_radius = 0.1
	dot_mesh.bottom_radius = 0.1
	dot_mesh.height = 0.035
	dot_mesh.radial_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = ROUTE_INK
	material.roughness = 0.95
	dot_mesh.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = dot_mesh
	multimesh.instance_count = dot_count
	for dot_index in range(dot_count):
		var progress := float(dot_index) / float(dot_count - 1)
		var distance := endpoint_margin + usable_length * progress
		multimesh.set_instance_transform(dot_index, Transform3D(Basis.IDENTITY, flat_from + direction * distance))
	var dots := MultiMeshInstance3D.new()
	dots.name = "RouteDots"
	dots.multimesh = multimesh
	route_lines.add_child(dots)


func _add_stop_platform(position: Vector3, node_id: String) -> void:
	var marker := Node3D.new()
	marker.name = node_id.to_pascal_case() + "StreetMarker"
	marker.position = Vector3(position.x, 0.0, position.z)
	marker.set_meta("node_id", node_id)
	route_stops.add_child(marker)
	_add_stop_disc(marker, "OuterRing", Vector3(0.0, 0.115, 0.0), 0.19, GamePalette.STEEL, 0.009)
	_add_stop_disc(marker, "InnerPlate", Vector3(0.0, 0.122, 0.0), 0.125, GamePalette.GRAPHITE, 0.01)
	node_markers[node_id] = marker


func _add_stop_disc(
	parent: Node3D,
	disc_name: String,
	position: Vector3,
	radius: float,
	color: Color,
	height: float
) -> void:
	var stop := MeshInstance3D.new()
	stop.name = disc_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 0.9
	mesh.material = material
	stop.mesh = mesh
	stop.position = position
	stop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(stop)


func _set_buttons_enabled(enabled: bool) -> void:
	var available := _available_destinations()
	for node_id: String in node_buttons:
		var button := node_buttons[node_id] as TextureButton
		var bubble := node_sprites[node_id] as Sprite3D
		var can_choose := node_id in available
		button.disabled = not enabled or not can_choose
		button.modulate = Color(1.0, 1.0, 1.0, 0.0)
		bubble.modulate = Color.WHITE if enabled and can_choose else INACTIVE_ICON_TINT
		_set_marker_state(node_id, enabled and can_choose, false)


func _set_node_hovered(node_id: String, hovered: bool) -> void:
	if node_id not in node_sprites:
		return
	var bubble := node_sprites[node_id] as Sprite3D
	var can_choose := not (node_buttons[node_id] as TextureButton).disabled
	bubble.scale = Vector3.ONE * (1.1 if hovered and can_choose else 1.0)
	_set_marker_state(node_id, can_choose, hovered and can_choose)


func _set_marker_state(node_id: String, selectable: bool, hovered: bool) -> void:
	if node_id not in node_markers:
		return
	var marker := node_markers[node_id] as Node3D
	var outer := marker.get_node("OuterRing") as MeshInstance3D
	var inner := marker.get_node("InnerPlate") as MeshInstance3D
	var outer_material := outer.mesh.material as StandardMaterial3D
	var inner_material := inner.mesh.material as StandardMaterial3D
	marker.scale = Vector3.ONE * (1.12 if hovered else 1.0)
	outer_material.albedo_color = GamePalette.ELECTRIC_CYAN if hovered else (
		GamePalette.SELECTION_BLUE if selectable else GamePalette.STEEL
	)
	inner_material.albedo_color = GamePalette.SELECTION_BLUE if hovered else GamePalette.GRAPHITE
	outer.transparency = 0.2 if hovered else (0.62 if selectable else 0.91)
	inner.transparency = 0.24 if hovered else (0.5 if selectable else 0.93)


func _animate_route_icons() -> void:
	for node_id: String in node_sprites:
		var bubble := node_sprites[node_id] as Sprite3D
		var node_position: Vector3 = nodes[node_id]["position"]
		var phase := float(abs(node_id.hash()) % 628) * 0.01
		bubble.position = node_position + Vector3(
			0.0,
			0.34 + sin(route_float_time * 2.1 + phase) * 0.04,
			0.0
		)


func _layout_buttons() -> void:
	var viewport_size := button_layer.get_viewport_rect().size
	var screen_bounds := Rect2(Vector2(-70.0, -70.0), viewport_size + Vector2(140.0, 140.0))
	for node_id: String in node_buttons:
		var button := node_buttons[node_id] as TextureButton
		var world_position: Vector3 = nodes[node_id]["position"] + Vector3(0.0, 0.34, 0.0)
		if camera.is_position_behind(world_position):
			button.visible = false
			continue
		var screen_position := camera.unproject_position(world_position)
		button.visible = screen_bounds.has_point(screen_position)
		button.position = screen_position - button.size * 0.5
