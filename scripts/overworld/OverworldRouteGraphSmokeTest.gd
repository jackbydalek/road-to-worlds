extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/StarterCityOverworld.tscn") as PackedScene
	var stage := packed.instantiate()
	root.call_deferred("add_child", stage)
	for _frame in range(8):
		await process_frame
	var graph = stage.get_node("RouteGraph")
	var player = stage.get_node("Player")
	var generated_city := stage.get_node_or_null("GeneratedStarterCity") as Node3D
	var city_district := (
		generated_city.get_node_or_null("UserIllustratedMap/DistrictZones/SmallCityDistrict") as MeshInstance3D
		if generated_city != null
		else null
	)
	if generated_city == null or city_district == null:
		push_error("Production Starter City did not build the fixed town/city district plan")
		quit(1)
		return
	var source_packs := generated_city.get_meta("source_packs", []) as Array
	if "City Kit - Roads" not in source_packs or "City Kit - Suburban" not in source_packs:
		push_error("Production Starter City lost its declared modular environment sources")
		quit(1)
		return
	for icon_type in ["enemy", "mini_boss", "final_boss", "shop", "event"]:
		var icon_texture := graph.icon_textures.get(icon_type) as Texture2D
		if icon_texture == null or not icon_texture.resource_path.ends_with("route_icons/%s.png" % icon_type):
			push_error("Route icon did not use the supplied %s sprite" % icon_type)
			quit(1)
			return
	var basic_enemy_texture := graph.icon_textures.get("enemy") as Texture2D
	if basic_enemy_texture.get_width() != 491 or basic_enemy_texture.get_height() != 603:
		push_error("Basic enemy route icon is still using the stale dark 447x563 import")
		quit(1)
		return
	var enemy_world_extent := -1.0
	var final_boss_world_extent := -1.0
	var enemy_button_extent := -1.0
	var final_boss_button_extent := -1.0
	for node_id: String in graph.node_sprites:
		var route_sprite := graph.node_sprites[node_id] as Sprite3D
		var texture_extent := maxi(route_sprite.texture.get_width(), route_sprite.texture.get_height())
		var expected_world_extent := float(route_sprite.get_meta("route_icon_world_extent", graph.ROUTE_ICON_WORLD_EXTENT))
		var node_type := String(graph.nodes[node_id].get("type", "enemy"))
		var route_button := graph.node_buttons[node_id] as TextureButton
		if node_type == "enemy" and enemy_world_extent < 0.0:
			enemy_world_extent = expected_world_extent
			enemy_button_extent = route_button.size.x
		elif node_type == "final_boss":
			final_boss_world_extent = expected_world_extent
			final_boss_button_extent = route_button.size.x
		if not is_equal_approx(route_sprite.pixel_size * float(texture_extent), expected_world_extent):
			push_error(
				"Route icon %s has world extent %.6f instead of %.6f (pixel size %.6f, texture %dx%d)" % [
					node_id,
					route_sprite.pixel_size * float(texture_extent),
					expected_world_extent,
					route_sprite.pixel_size,
					route_sprite.texture.get_width(),
					route_sprite.texture.get_height(),
				]
			)
			quit(1)
			return
	if final_boss_world_extent < enemy_world_extent * 1.25:
		push_error("Final boss route icon must be visibly larger than regular encounter icons")
		quit(1)
		return
	if final_boss_button_extent < enemy_button_extent * 1.25:
		push_error("Final boss route icon click target must scale with its larger visual")
		quit(1)
		return
	if graph.layers.size() != graph.route_columns + 2 or graph._available_destinations() != ["rival_town_west"]:
		push_error("Authored route must open on the west rival before presenting its two-way split")
		quit(1)
		return
	var start_position: Vector3 = graph.nodes.start.position
	var boss_position: Vector3 = graph.nodes.final_boss.position
	var route_camera := stage.get_node("Camera3D") as Camera3D
	if (
		start_position.x >= boss_position.x
		or start_position.z <= boss_position.z
		or route_camera.unproject_position(start_position).y
		<= route_camera.unproject_position(boss_position).y
	):
		push_error("Starter City route did not progress from the lower-left start to the upper-right championship")
		quit(1)
		return
	var miniboss_count := 0
	for route_node_value in graph.nodes.values():
		if String(route_node_value.get("type", "")) == "mini_boss":
			miniboss_count += 1
	if miniboss_count != graph.MINIBOSS_ROWS.size():
		push_error("Generated route must sprinkle two minibosses across the shorter map")
		quit(1)
		return
	if (
		not graph.routes.has("rival_town_west>event_west")
		or not graph.routes.has("rival_town_west>rival_town_center")
		or (graph.nodes.event_south.position as Vector3).z != 8.0
		or (graph.nodes.event_east.position as Vector3).z != 2.0
		or (graph.nodes.ace_top.position as Vector3).z != -6.0
	):
		push_error("Authored route lost its bottom, middle, or upper street structure")
		quit(1)
		return
	if not graph.world_exploration_mode or not player.free_roam_enabled:
		push_error("Production Starter City did not enable physical town exploration")
		quit(1)
		return
	var initial_player_x: float = player.global_position.x
	Input.action_press("ui_right")
	for _frame in range(12):
		await physics_frame
	Input.action_release("ui_right")
	await process_frame
	if player.global_position.x <= initial_player_x or graph.camera_target_x < player.global_position.x - 0.1:
		push_error("Free town movement or the player-follow camera did not move east")
		quit(1)
		return

	var steps := 0
	while graph.current_node_id != "final_boss" and steps < graph.route_columns + 3:
		var available: Array[String] = graph._available_destinations()
		if available.is_empty():
			push_error("Generated route reached a dead end before the boss")
			quit(1)
			return
		var target_id := available[0]
		graph.select_destination(target_id)
		if not await _wait_for_node(graph, target_id):
			push_error("Player did not reach generated node: " + target_id)
			quit(1)
			return
		steps += 1

	if graph.current_node_id != "final_boss" or not graph._available_destinations().is_empty():
		push_error("Generated route did not terminate at the final boss")
		quit(1)
		return
	if player.current_pose != "idle":
		push_error("Player should return to idle after route travel")
		quit(1)
		return

	# Campaign screens rebuild the overworld when the player returns. A restored
	# graph must put the avatar and camera at the saved node, not at the start.
	var saved_snapshot: Dictionary = graph.snapshot()
	if not (saved_snapshot.get("routes", {}) as Dictionary).has("ace_east>final_boss"):
		push_error("Authored route waypoints were not serialized with the run snapshot")
		quit(1)
		return
	stage.queue_free()
	await process_frame
	var restored_stage := packed.instantiate()
	var restored_graph = restored_stage.get_node("RouteGraph")
	restored_graph.configure(saved_snapshot)
	root.call_deferred("add_child", restored_stage)
	await process_frame
	await process_frame
	await process_frame
	var restored_player = restored_stage.get_node("Player")
	var expected_position: Vector3 = restored_graph.nodes[restored_graph.current_node_id].position
	if restored_graph.current_node_id != "final_boss" or restored_player.global_position.distance_to(expected_position) > 0.01:
		push_error("Restored map returned the player to the start instead of the saved node (current=%s, player=%s, expected=%s)" % [restored_graph.current_node_id, restored_player.global_position, expected_position])
		quit(1)
		return
	var expected_camera_x := clampf(
		expected_position.x + restored_graph.camera_focus_lead_x,
		restored_graph.camera_x_min,
		restored_graph.camera_x_max
	)
	if not is_equal_approx(restored_stage.get_node("Camera3D").position.x, expected_camera_x):
		push_error("Restored map camera did not follow the saved node")
		quit(1)
		return
	var expected_camera_z := (
		float(restored_stage.route_camera_center_z)
		+ float(restored_graph.camera_ground_offset_z)
		if restored_graph.vertical_camera_locked
		else clampf(
			expected_position.z + restored_graph.camera_ground_offset_z,
			restored_graph.camera_z_min,
			restored_graph.camera_z_max
		)
	)
	if not is_equal_approx(restored_stage.get_node("Camera3D").position.z, expected_camera_z):
		push_error("Restored production map camera did not vertically frame the saved node")
		quit(1)
		return
	print("OVERWORLD_ROUTE_GRAPH_SMOKE_TEST_OK")
	quit()


func _wait_for_node(graph: Node, target_id: String) -> bool:
	for _frame in range(720):
		await physics_frame
		if graph.current_node_id == target_id:
			await process_frame
			return true
	return false
