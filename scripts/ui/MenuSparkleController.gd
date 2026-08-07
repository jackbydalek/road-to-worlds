extends Node
class_name MenuSparkleController

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var enabled := true


func _ready() -> void:
	if not enabled:
		return
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_controls")


func _bind_existing_controls() -> void:
	var tree_root := get_tree().root
	for node in tree_root.find_children("*", "Control", true, false):
		_bind_control(node as Control)


func _on_node_added(node: Node) -> void:
	if enabled and node is Control:
		call_deferred("_bind_control_by_id", node.get_instance_id())


func _bind_control_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Control:
		_bind_control(node as Control)


func _bind_control(control: Control) -> void:
	if not is_instance_valid(control) or _belongs_to_tabletop(control):
		return
	if control is BaseButton:
		_bind_button(control as BaseButton)


func _bind_button(button: BaseButton) -> void:
	if bool(button.get_meta("menu_sparkle_bound", false)):
		return
	button.set_meta("menu_sparkle_bound", true)
	button.button_down.connect(func() -> void: _play_button_press(button))


func _play_button_press(button: BaseButton) -> void:
	if not _can_play_for(button) or button.disabled:
		return
	_spawn_burst(button, PALETTE.CORAL, 5, 28.0)


func _spawn_burst(button: BaseButton, accent: Color, count: int, distance: float) -> void:
	if not enabled or not is_instance_valid(button):
		return
	var reduced_motion := bool(get_tree().root.get_meta("reduced_motion", false))
	var actual_count := mini(2, count) if reduced_motion else count
	var burst := Node2D.new()
	burst.name = "MenuClickSparkleBurst"
	burst.position = button.size * 0.5
	burst.show_behind_parent = true
	button.add_child(burst)
	var half_size := button.size * 0.5
	var longest_duration := 0.0
	for particle_index in range(actual_count):
		var radius := 4.5 + float(particle_index % 3) * 1.6
		var fill := accent if particle_index % 2 == 0 else PALETTE.FRESH_YELLOW
		var particle := _outlined_particle(radius, fill)
		particle.scale = Vector2.ONE * 0.25
		burst.add_child(particle)
		var angle := TAU * float(particle_index) / float(maxi(1, actual_count)) - PI * 0.5
		var direction := Vector2(cos(angle), sin(angle))
		var edge_distance := minf(
			half_size.x / maxf(absf(direction.x), 0.001),
			half_size.y / maxf(absf(direction.y), 0.001)
		)
		particle.position = direction * maxf(0.0, edge_distance - 8.0)
		var travel := distance * (0.62 + float((particle_index * 7) % 5) * 0.09)
		var destination := direction * (edge_distance + travel)
		var duration := 0.28 if reduced_motion else 0.48 + float(particle_index % 3) * 0.04
		longest_duration = maxf(longest_duration, duration)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "position", destination, duration)
		tween.tween_property(particle, "scale", Vector2.ONE * (0.82 + float(particle_index % 2) * 0.18), duration * 0.42)
		if not reduced_motion:
			tween.tween_property(particle, "rotation", angle * 0.22, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration * 0.48).set_delay(duration * 0.52)
		tween.finished.connect(particle.queue_free)
	var cleanup := create_tween()
	cleanup.tween_interval(longest_duration + 0.06)
	cleanup.tween_callback(Callable(self, "_cleanup_burst").bind(burst.get_instance_id()))


func _cleanup_burst(instance_id: int) -> void:
	var burst := instance_from_id(instance_id)
	if is_instance_valid(burst):
		burst.queue_free()


func _outlined_particle(radius: float, fill: Color) -> Polygon2D:
	var particle := Polygon2D.new()
	particle.polygon = _sparkle_polygon(radius + 2.2)
	particle.color = Color(PALETTE.NAVY, 0.88)
	var center := Polygon2D.new()
	center.polygon = _sparkle_polygon(radius)
	center.color = fill
	particle.add_child(center)
	return particle


func _sparkle_polygon(radius: float) -> PackedVector2Array:
	var inner := radius * 0.22
	return PackedVector2Array([
		Vector2(0.0, -radius), Vector2(inner, -inner),
		Vector2(radius, 0.0), Vector2(inner, inner),
		Vector2(0.0, radius), Vector2(-inner, inner),
		Vector2(-radius, 0.0), Vector2(-inner, -inner),
	])


func _can_play_for(control: Control) -> bool:
	return enabled and is_instance_valid(control) and control.is_visible_in_tree() and not _belongs_to_tabletop(control)


func _belongs_to_tabletop(node: Node) -> bool:
	var cursor := node
	while cursor != null:
		if cursor.name == "Tabletop3DPrototype":
			return true
		cursor = cursor.get_parent()
	return false
