extends Node3D

signal encounter_requested(node_id: String)

const GamePalette := preload("res://scripts/ui/GamePalette.gd")

const SIGHTLINE_LENGTH := 1.85
const SIGHTLINE_COLLISION_WIDTH := 0.36
const DIRECT_ALIGNMENT_HALF_WIDTH := 0.18
const SIGHTLINE_MIN_FORWARD_DISTANCE := 0.05

var node_id := ""
var node_type := "enemy"
var npc_archetype := "neutral"
var npc_personality := "curious"
var player: CharacterBody3D
var active := false
var triggered := false
var sight_direction := Vector3(0.0, 0.0, 1.0)
var artwork: Sprite3D
var reaction_mark: Label3D
var type_badge: Label3D
var sightline: Area3D


func configure(
	player_node: CharacterBody3D,
	data: Dictionary,
	portrait_texture: Texture2D,
	is_active: bool,
	approach_direction: Vector3
) -> void:
	player = player_node
	node_id = String(data.get("id", ""))
	node_type = String(data.get("type", "enemy"))
	npc_archetype = String(data.get("npc_archetype", "neutral"))
	npc_personality = String(data.get("npc_personality", "curious"))
	active = is_active
	sight_direction = Vector3(approach_direction.x, 0.0, approach_direction.z).normalized()
	if sight_direction.length_squared() <= 0.01:
		sight_direction = Vector3(0.0, 0.0, 1.0)
	_build_visual(portrait_texture)
	_build_sightline()
	set_physics_process(active)
	set_meta("route_node_id", node_id)
	set_meta("npc_archetype", npc_archetype)
	set_meta("npc_personality", npc_personality)
	set_meta("encounter_active", active)


func trigger_encounter() -> void:
	if triggered or not active or player == null:
		return
	triggered = true
	active = false
	set_physics_process(false)
	set_meta("encounter_active", false)
	if sightline != null:
		sightline.set_deferred("monitoring", false)
	if player.has_method("set_world_input_locked"):
		player.call("set_world_input_locked", true)
	await _play_reaction()
	encounter_requested.emit(node_id)


func _build_visual(portrait_texture: Texture2D) -> void:
	artwork = Sprite3D.new()
	artwork.name = "NpcArtwork"
	artwork.texture = portrait_texture
	var texture_height := float(maxi(portrait_texture.get_height(), 1)) if portrait_texture != null else 1.0
	artwork.pixel_size = 1.72 / texture_height
	artwork.position.y = 0.88
	artwork.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	artwork.shaded = false
	artwork.double_sided = true
	artwork.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	artwork.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	artwork.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	artwork.modulate.a = 1.0 if active else 0.72
	artwork.flip_h = sight_direction.x < -0.05
	add_child(artwork)

	var shadow := MeshInstance3D.new()
	shadow.name = "NpcShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.34
	shadow_mesh.bottom_radius = 0.34
	shadow_mesh.height = 0.015
	shadow_mesh.radial_segments = 20
	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.albedo_color = Color(0.07, 0.09, 0.12, 0.24)
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mesh.material = shadow_material
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.045
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

	type_badge = Label3D.new()
	type_badge.name = "NpcTypeBadge"
	type_badge.text = _badge_text()
	type_badge.font_size = 38
	type_badge.pixel_size = 0.0052
	type_badge.position.y = 1.88
	type_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	type_badge.modulate = _archetype_color()
	type_badge.outline_size = 7
	type_badge.outline_modulate = GamePalette.CARBON
	type_badge.no_depth_test = true
	add_child(type_badge)

	reaction_mark = Label3D.new()
	reaction_mark.name = "ReactionMark"
	reaction_mark.text = "!"
	reaction_mark.font_size = 108
	reaction_mark.pixel_size = 0.0062
	reaction_mark.position = Vector3(0.0, 2.28, 0.0)
	reaction_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	reaction_mark.modulate = GamePalette.SIGNAL_YELLOW
	reaction_mark.outline_size = 12
	reaction_mark.outline_modulate = GamePalette.CARBON
	reaction_mark.no_depth_test = true
	reaction_mark.visible = false
	add_child(reaction_mark)


func _build_sightline() -> void:
	sightline = Area3D.new()
	sightline.name = "NpcSightline"
	sightline.collision_layer = 0
	sightline.collision_mask = 1
	sightline.monitoring = active
	sightline.monitorable = false
	sightline.position = sight_direction * (SIGHTLINE_LENGTH * 0.5) + Vector3(0.0, 0.9, 0.0)
	sightline.rotation.y = atan2(sight_direction.x, sight_direction.z)
	var collision := CollisionShape3D.new()
	collision.name = "SightlineShape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIGHTLINE_COLLISION_WIDTH, 2.2, SIGHTLINE_LENGTH)
	collision.shape = shape
	sightline.add_child(collision)
	sightline.body_entered.connect(_on_sightline_body_entered)
	add_child(sightline)


func _on_sightline_body_entered(body: Node3D) -> void:
	if body == player:
		_try_trigger_from_sightline()


func _physics_process(_delta: float) -> void:
	# A body can enter the collision box at its outer edge before its visual
	# center reaches the NPC's facing line. Keep checking while it overlaps so
	# the reaction occurs at the centerline instead of at that early edge.
	_try_trigger_from_sightline()


func _try_trigger_from_sightline() -> void:
	if triggered or not active or player == null or sightline == null:
		return
	if not sightline.overlaps_body(player) or not _player_is_directly_ahead():
		return
	if player.has_method("is_following_route") and bool(player.call("is_following_route")):
		return
	trigger_encounter()


func _player_is_directly_ahead() -> bool:
	if player == null:
		return false
	var flat_offset := player.global_position - global_position
	flat_offset.y = 0.0
	var forward_distance := flat_offset.dot(sight_direction)
	if forward_distance < SIGHTLINE_MIN_FORWARD_DISTANCE or forward_distance > SIGHTLINE_LENGTH:
		return false
	var lateral_axis := Vector3(-sight_direction.z, 0.0, sight_direction.x)
	return absf(flat_offset.dot(lateral_axis)) <= DIRECT_ALIGNMENT_HALF_WIDTH


func _play_reaction() -> void:
	reaction_mark.visible = true
	reaction_mark.scale = Vector3.ONE * 0.35
	reaction_mark.position.y = 1.98
	var tween := create_tween().set_parallel(true)
	tween.tween_property(reaction_mark, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(reaction_mark, "position:y", 2.34, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	await get_tree().create_timer(0.34).timeout
	reaction_mark.visible = false


func _badge_text() -> String:
	if node_type == "event":
		return "EVENT"
	if node_type == "mini_boss":
		return "%s ACE" % npc_archetype.to_upper()
	if node_type == "final_boss":
		return "CITY CHAMPION"
	return "%s RIVAL" % npc_archetype.to_upper()


func _archetype_color() -> Color:
	match npc_archetype:
		"spicy":
			return GamePalette.AFFINITY_SPICY
		"hearty":
			return GamePalette.AFFINITY_HEARTY
		"sweet":
			return GamePalette.AFFINITY_SWEET
		"fresh":
			return GamePalette.AFFINITY_FRESH
		"funky":
			return GamePalette.AFFINITY_FUNKY
		_:
			return GamePalette.COOL_WHITE
