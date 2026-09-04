extends CharacterBody3D

## HD-2D prototype controller: physical movement happens in the 3D town while
## the supplied illustration remains a camera-facing sprite.
const CHARACTER_POSES := {
	"spicy": {
		"idle": preload("res://assets/overworld/player_idle.png"),
		"walk": preload("res://assets/overworld/player_walk.png"),
		"victory": preload("res://assets/overworld/player_victory.png"),
	},
	"hearty": {
		"idle": preload("res://assets/overworld/hearty_player_idle.png"),
		"walk": preload("res://assets/overworld/hearty_player_walk.png"),
		"victory": preload("res://assets/overworld/hearty_player_victory.png"),
	},
	"sweet": {
		"idle": preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
		"walk": preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
		"victory": preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
	},
}

@export var move_speed := 7.6
@export var route_move_speed := 3.8
@export var world_min := Vector2(-16.0, -11.0)
@export var world_max := Vector2(32.0, 11.0)
@export var route_only_mode := true
@export var victory_duration := 0.62
@export var victory_bounce_height := 0.7
@export var walk_cycle_speed := 7.2
@export var walk_bounce_height := 0.11
@export var walk_sway_radians := 0.022
@export var free_roam_path_half_width := 0.39

@onready var artwork: Node3D = $Visual/Artwork
@onready var sprite: Sprite3D = $Visual/Artwork/PlayerSprite

var idle_texture: Texture2D
var walk_texture: Texture2D
var victory_texture: Texture2D
var character_id := "spicy"

var facing_right := true
var walk_time := 0.0
var victory_time := 0.0
var active_victory_duration := 0.62
var current_pose := ""
var space_was_down := false
var route_active := false
var route_points: Array[Vector3] = []
var route_point_index := 0
var route_arrival: Callable
var world_input_locked := false
var free_roam_enabled := false
var free_roam_cells: Dictionary = {}


func _ready() -> void:
	active_victory_duration = victory_duration
	_configure_world_occlusion()
	_load_character_textures()


func _configure_world_occlusion() -> void:
	# The player is part of the illustrated 3D town, so foreground cutouts must
	# be allowed to write over it. Keeping depth testing enabled also means trees
	# behind the player's ground position remain behind the character.
	sprite.no_depth_test = false
	sprite.render_priority = 0
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD


func configure_character(requested_character_id: String) -> void:
	character_id = requested_character_id if CHARACTER_POSES.has(requested_character_id) else "spicy"
	if is_node_ready():
		_load_character_textures()


func _load_character_textures() -> void:
	var poses: Dictionary = CHARACTER_POSES.get(character_id, CHARACTER_POSES["spicy"])
	idle_texture = poses["idle"] as Texture2D
	walk_texture = poses["walk"] as Texture2D
	victory_texture = poses["victory"] as Texture2D
	current_pose = ""
	_set_pose("idle")


func _physics_process(delta: float) -> void:
	var space_down := Input.is_key_pressed(KEY_SPACE)
	if space_down and not space_was_down and victory_time <= 0.0 and not route_active and not world_input_locked:
		active_victory_duration = victory_duration
		victory_time = victory_duration
	space_was_down = space_down

	var input_axis := Vector2.ZERO
	if route_active:
		input_axis = _route_input_axis()
	elif not route_only_mode and not world_input_locked:
		input_axis = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		input_axis += Vector2(
			float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		)
		input_axis = input_axis.limit_length()

	var celebrating := victory_time > 0.0
	if celebrating:
		victory_time = maxf(victory_time - delta, 0.0)
		input_axis = Vector2.ZERO

	var active_move_speed := route_move_speed if route_active else move_speed
	velocity.x = input_axis.x * active_move_speed
	velocity.y = 0.0
	velocity.z = input_axis.y * active_move_speed
	var previous_position := global_position
	move_and_slide()
	if free_roam_enabled and not route_active and not _free_roam_position_is_valid(global_position):
		# Preserve responsive movement along the road edge: if a diagonal step
		# leaves the path, retain whichever single axis still lies on it.
		var moved_position := global_position
		var x_only := previous_position
		x_only.x = moved_position.x
		var z_only := previous_position
		z_only.z = moved_position.z
		var prefer_x := absf(moved_position.x - previous_position.x) >= absf(
			moved_position.z - previous_position.z
		)
		if prefer_x and _free_roam_position_is_valid(x_only):
			global_position = x_only
			velocity.z = 0.0
		elif _free_roam_position_is_valid(z_only):
			global_position = z_only
			velocity.x = 0.0
		elif _free_roam_position_is_valid(x_only):
			global_position = x_only
			velocity.z = 0.0
		else:
			global_position.x = previous_position.x
			global_position.z = previous_position.z
			velocity.x = 0.0
			velocity.z = 0.0
	global_position.x = clampf(global_position.x, world_min.x, world_max.x)
	global_position.z = clampf(global_position.z, world_min.y, world_max.y)

	var walking := input_axis.length_squared() > 0.001
	if celebrating:
		_set_pose("victory")
		var progress := 1.0 - victory_time / maxf(active_victory_duration, 0.001)
		var bounce := sin(progress * PI)
		artwork.position.y = bounce * victory_bounce_height
		artwork.rotation.z = lerp_angle(artwork.rotation.z, 0.0, minf(delta * 12.0, 1.0))
		var anticipation := sin(progress * PI * 2.0)
		artwork.scale = Vector3(1.0 - anticipation * 0.035, 1.0 + anticipation * 0.055, 1.0)
	elif walking:
		_set_pose("walk")
		walk_time += delta * walk_cycle_speed
		if absf(input_axis.x) > 0.05:
			facing_right = input_axis.x > 0.0
		# Absolute sine gives one smooth lift for each footfall: two grounded steps
		# per complete gait instead of the old one-sided, twitchy pulse.
		var step_wave := sin(walk_time)
		var lift_amount := absf(step_wave)
		var target_scale := Vector3(1.0 + lift_amount * 0.012, 1.0 - lift_amount * 0.018, 1.0)
		artwork.scale = artwork.scale.lerp(target_scale, minf(delta * 10.0, 1.0))
		artwork.position.y = lerpf(artwork.position.y, lift_amount * walk_bounce_height, minf(delta * 11.0, 1.0))
		artwork.rotation.z = lerp_angle(artwork.rotation.z, step_wave * walk_sway_radians, minf(delta * 9.0, 1.0))
	else:
		_set_pose("idle")
		walk_time = 0.0
		artwork.scale = artwork.scale.lerp(Vector3.ONE, minf(delta * 13.0, 1.0))
		artwork.position.y = lerpf(artwork.position.y, 0.0, minf(delta * 16.0, 1.0))
		artwork.rotation.z = lerp_angle(artwork.rotation.z, 0.0, minf(delta * 12.0, 1.0))
	sprite.flip_h = not facing_right


func follow_route(points: Array[Vector3], on_arrival: Callable = Callable()) -> void:
	if points.is_empty():
		if on_arrival.is_valid():
			on_arrival.call()
		return
	route_points = points.duplicate()
	route_point_index = 0
	route_arrival = on_arrival
	route_active = true
	victory_time = 0.0


func is_following_route() -> bool:
	return route_active


func configure_free_roam(cell_values: Array[Vector2i]) -> void:
	free_roam_cells.clear()
	for cell in cell_values:
		free_roam_cells[_grid_key(cell)] = cell
	free_roam_enabled = not free_roam_cells.is_empty()
	route_only_mode = false


func set_world_input_locked(locked: bool) -> void:
	world_input_locked = locked
	if locked:
		velocity = Vector3.ZERO


func is_world_input_locked() -> bool:
	return world_input_locked


func _free_roam_position_is_valid(candidate: Vector3) -> bool:
	if free_roam_cells.is_empty():
		return true
	var point := Vector2(candidate.x, candidate.z)
	for cell_value in free_roam_cells.values():
		var cell := cell_value as Vector2i
		var center := Vector2(float(cell.x), float(cell.y))
		# Each visible tile has a round center, with narrow arms joining it only
		# to neighboring walkable tiles. Testing those capsules mirrors the path
		# shader instead of treating the whole tile as a walkable square.
		if point.distance_to(center) <= free_roam_path_half_width:
			return true
		for direction_value in [Vector2i(1, 0), Vector2i(0, 1)]:
			var direction := direction_value as Vector2i
			var neighbor: Vector2i = cell + direction
			if not free_roam_cells.has(_grid_key(neighbor)):
				continue
			var neighbor_center := Vector2(float(neighbor.x), float(neighbor.y))
			if _distance_to_segment(point, center, neighbor_center) <= free_roam_path_half_width:
				return true
	return false


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var progress := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * progress)


func _grid_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func celebrate(duration: float = -1.0) -> void:
	if route_active:
		return
	active_victory_duration = victory_duration if duration <= 0.0 else duration
	victory_time = active_victory_duration


func _route_input_axis() -> Vector2:
	while route_point_index < route_points.size():
		var offset := route_points[route_point_index] - global_position
		var flat_offset := Vector2(offset.x, offset.z)
		if flat_offset.length() <= 0.14:
			global_position.x = route_points[route_point_index].x
			global_position.z = route_points[route_point_index].z
			route_point_index += 1
			continue
		return flat_offset.normalized()
	route_active = false
	velocity = Vector3.ZERO
	var completed_callback := route_arrival
	route_arrival = Callable()
	if completed_callback.is_valid():
		completed_callback.call_deferred()
	return Vector2.ZERO


func _set_pose(pose: String) -> void:
	if current_pose == pose:
		return
	current_pose = pose
	match pose:
		"walk":
			sprite.texture = walk_texture
		"victory":
			sprite.texture = victory_texture
		_:
			sprite.texture = idle_texture
