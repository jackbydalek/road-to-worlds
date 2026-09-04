extends SceneTree

const SCENE_PATH := "res://scenes/StarterCityProceduralPrototype.tscn"
const PREVIEW_PATH := "res://outputs/illustrated_vfx/starter_city_procedural_prototype.png"
const OVERVIEW_PREVIEW_PATH := "res://outputs/illustrated_vfx/starter_city_procedural_overview.png"


func _initialize() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load the procedural Starter City prototype scene.")
		quit(1)
		return
	var stage := packed.instantiate()
	root.call_deferred("add_child", stage)
	for _frame in range(8):
		await process_frame
	var generated := stage.get_node_or_null("GeneratedStarterCity") as Node3D
	if generated == null:
		push_error("Procedural Starter City did not build its generated city root.")
		quit(1)
		return
	var graph := stage.get_node("RouteGraph")
	var ground := stage.get_node_or_null("GroundBlock") as MeshInstance3D
	var ground_material := ground.material_override as ShaderMaterial if ground != null else null
	var ground_grass_texture: Texture2D = (
		ground_material.get_shader_parameter("grass_texture")
		if ground_material != null
		else null
	)
	if (
		ground_material == null
		or ground_material.shader == null
		or not ground_material.shader.resource_path.ends_with("starter_city_user_grass.gdshader")
		or ground_grass_texture == null
		or not ground_grass_texture.resource_path.ends_with("starter_city_user/grass.png")
		or not (ground_material.get_shader_parameter("tile_count") as Vector2).is_equal_approx(
			stage.USER_GRASS_TILE_COUNT
		)
		or not (ground_material.get_shader_parameter("grass_tint") as Color).is_equal_approx(
			GamePalette.CITY_GRASS
		)
	):
		push_error("Starter City ground is not using its small, consistently oriented town grass texture.")
		quit(1)
		return
	var illustrated := generated.get_node_or_null("UserIllustratedMap") as Node3D
	var district_zones := generated.get_node_or_null("UserIllustratedMap/DistrictZones") as Node3D
	var city_district := generated.get_node_or_null(
		"UserIllustratedMap/DistrictZones/SmallCityDistrict"
	) as MeshInstance3D
	var illustrated_streets := generated.get_node_or_null("UserIllustratedMap/StreetTiles") as Node3D
	var illustrated_ponds := generated.get_node_or_null("UserIllustratedMap/Ponds") as Node3D
	var illustrated_buildings := generated.get_node_or_null("UserIllustratedMap/PlaceholderBuildings") as Node3D
	var illustrated_vegetation := generated.get_node_or_null("UserIllustratedMap/Vegetation") as Node3D
	var town_actors := generated.get_node_or_null("UserIllustratedMap/TownActors") as Node3D
	if (
		illustrated == null
		or district_zones == null
		or city_district == null
		or illustrated_streets == null
		or illustrated_ponds == null
		or illustrated_buildings == null
		or illustrated_vegetation == null
		or town_actors == null
		or illustrated_streets.get_child_count() != stage.road_cells.size()
		or illustrated_ponds.get_child_count() != stage.USER_POND_COUNT
		or illustrated_buildings.get_child_count() < 6
		or illustrated_vegetation.get_child_count() < 80
		or town_actors.get_child_count() < 10
	):
		push_error("Starter City did not build its explorable town layers and route actors.")
		quit(1)
		return
	var city_district_material := city_district.material_override as ShaderMaterial
	if (
		String(city_district.get_meta("map_role", "")) != "small_city_environment"
		or city_district_material == null
		or city_district_material.shader == null
		or not city_district_material.shader.resource_path.ends_with("starter_city_paved_ground.gdshader")
		or not (city_district_material.get_shader_parameter("paving_surface_color") as Color).is_equal_approx(
			GamePalette.CITY_PAVER_SURFACE
		)
	):
		push_error("The authored town is missing its paved upper-right small-city district.")
		quit(1)
		return
	var sample_street := illustrated_streets.get_child(0) as MeshInstance3D
	var sample_street_material := sample_street.material_override as ShaderMaterial
	var sample_vegetation := illustrated_vegetation.get_child(0) as Sprite3D
	var sample_atlas := sample_vegetation.texture as AtlasTexture
	if (
		sample_street_material == null
		or sample_street_material.shader == null
		or not sample_street_material.shader.resource_path.ends_with("starter_city_illustrated_path.gdshader")
		or String(sample_street.get_meta("map_role", "")) != "illustrated_footpath"
		or int(sample_street.get_meta("connection_mask", 0)) == 0
		or not (sample_street_material.get_shader_parameter("surface_color") as Color).is_equal_approx(
			GamePalette.CITY_PATH_SURFACE
		)
		or not (sample_street_material.get_shader_parameter("motif_color") as Color).is_equal_approx(
			GamePalette.CITY_PATH_MOTIF
		)
		or sample_atlas == null
		or sample_atlas.atlas == null
		or not sample_atlas.atlas.resource_path.ends_with("starter_city_user/vegetation_sheet.png")
	):
		push_error("Starter City illustrated layer is not using its patterned city path and supplied vegetation art.")
		quit(1)
		return
	for pond_value in illustrated_ponds.get_children():
		var pond := pond_value as Node3D
		var pond_water := pond.get_node_or_null("PondWater") as MeshInstance3D
		var pond_water_material := pond_water.material_override as ShaderMaterial if pond_water != null else null
		if (
			String(pond.get_meta("map_role", "")) != "neighborhood_pond"
			or pond.get_child_count() != 3
			or pond_water_material == null
			or pond_water_material.shader == null
			or not pond_water_material.shader.resource_path.ends_with("starter_city_pond_water.gdshader")
			or not (pond_water_material.get_shader_parameter("surface_color") as Color).is_equal_approx(
				GamePalette.CITY_POND_SURFACE
			)
		):
			push_error("Starter City pond did not retain its bank, outline, and illustrated water treatment.")
			quit(1)
			return
	var labeled_buildings := 0
	var has_local_card_shop := false
	var active_shop_entrances := 0
	var shop_entrance_count := 0
	var starter_shop_active := false
	for building_value in illustrated_buildings.get_children():
		var building := building_value as Node3D
		if String(building.get_meta("map_role", "")) != "placeholder_building":
			continue
		var building_label := building.get_node_or_null("BuildingName") as Label3D
		var building_collision := building.get_node_or_null("BuildingCollision/CollisionShape3D") as CollisionShape3D
		if building_label == null or building_collision == null or building_label.text.is_empty():
			push_error("A town placeholder is missing its visible name or collision footprint.")
			quit(1)
			return
		labeled_buildings += 1
		has_local_card_shop = has_local_card_shop or building_label.text == "LOCAL CARD SHOP"
		var shop_entrance := building.get_node_or_null("ShopEntrance") as Area3D
		if shop_entrance != null:
			var entrance_node_id := String(shop_entrance.get_meta("route_node_id", ""))
			if entrance_node_id == "starter_shop":
				starter_shop_active = bool(shop_entrance.get_meta("entrance_active", false))
			elif String(graph.nodes.get(entrance_node_id, {}).get("type", "")) == "shop":
				shop_entrance_count += 1
			if (
				String(graph.nodes.get(entrance_node_id, {}).get("type", "")) == "shop"
				and bool(shop_entrance.get_meta("entrance_active", false))
			):
				active_shop_entrances += 1
	if labeled_buildings < 6 or not has_local_card_shop or not starter_shop_active:
		push_error("The selected town layout did not create enough named building placeholders.")
		quit(1)
		return
	var unresolved_shop_nodes := 0
	for node_id: String in graph.nodes:
		if node_id not in graph.visited and String(graph.nodes[node_id].get("type", "")) == "shop":
			unresolved_shop_nodes += 1
	if shop_entrance_count != unresolved_shop_nodes:
		push_error("Route shop nodes were not represented by walk-in CARD STORE placeholders.")
		quit(1)
		return
	var active_npcs := 0
	var active_event_entrances := 0
	var active_npc_probe: Node3D
	for actor_value in town_actors.get_children():
		var npc := actor_value as Node3D
		var actor_node_id := String(npc.get_meta("route_node_id", ""))
		if actor_node_id.is_empty():
			push_error("A town route actor is not linked to a route node.")
			quit(1)
			return
		if String(graph.nodes[actor_node_id].get("type", "")) == "event":
			var event_square := npc.get_node_or_null("EventSquare") as MeshInstance3D
			var event_entrance := npc.get_node_or_null("EventEntrance") as Area3D
			if event_square == null or event_entrance == null:
				push_error("An authored event gate is missing its square marker or entrance trigger.")
				quit(1)
				return
			if bool(event_entrance.get_meta("entrance_active", false)):
				active_event_entrances += 1
			continue
		if String(npc.get_meta("npc_archetype", "")) not in graph.NPC_ARCHETYPES:
			push_error("A town NPC did not receive a seeded card affinity.")
			quit(1)
			return
		if npc.get_node_or_null("NpcArtwork") == null or npc.get_node_or_null("NpcSightline") == null:
			push_error("A town NPC is missing its reused artwork or sightline trigger.")
			quit(1)
			return
		if bool(npc.get_meta("encounter_active", false)):
			active_npcs += 1
			if active_npc_probe == null:
				active_npc_probe = npc
	if active_npcs + active_event_entrances + active_shop_entrances != graph._available_destinations().size() or active_npc_probe == null:
		push_error("The current route choices were not represented by active rivals, event gates, or shop doors.")
		quit(1)
		return
	var roads := generated.get_node_or_null("Roads") as Node3D
	var neighborhoods := generated.get_node_or_null("Neighborhoods") as Node3D
	var nature := generated.get_node_or_null("Nature") as Node3D
	if roads == null or roads.get_child_count() < 45:
		push_error("Procedural Starter City did not fit roads to the generated route graph.")
		quit(1)
		return
	var occupied_road_cells := {}
	var driveway_road_tiles := 0
	var rounded_end_tiles := 0
	var bend_tiles := 0
	for road_value in roads.get_children():
		var road := road_value as Node3D
		if not road.scale.is_equal_approx(Vector3.ONE):
			push_error("Road kit geometry was stretched instead of placed as unit tiles.")
			quit(1)
			return
		if not road.has_meta("grid_cell"):
			push_error("Road tile is missing its integer grid coordinate.")
			quit(1)
			return
		var cell := road.get_meta("grid_cell") as Vector2i
		var cell_key := "%d,%d" % [cell.x, cell.y]
		if occupied_road_cells.has(cell_key):
			push_error("Multiple road assets occupy the same grid cell: %s" % cell_key)
			quit(1)
			return
		occupied_road_cells[cell_key] = true
		if int(road.get_meta("driveway_count", 0)) > 0:
			driveway_road_tiles += 1
		if String(road.get_meta("road_piece", "")) == "end_round":
			rounded_end_tiles += 1
		if String(road.get_meta("road_piece", "")) == "RoadBend":
			bend_tiles += 1
			var directions := road.get_meta("connection_directions", []) as Array
			var expected_rotation := PI * 0.5
			if directions.has(Vector2i(-1, 0)) and directions.has(Vector2i(0, 1)):
				expected_rotation = 0.0
			elif directions.has(Vector2i(-1, 0)) and directions.has(Vector2i(0, -1)):
				expected_rotation = -PI * 0.5
			elif directions.has(Vector2i(1, 0)) and directions.has(Vector2i(0, -1)):
				expected_rotation = PI
			if not is_equal_approx(wrapf(road.rotation.y - expected_rotation, -PI, PI), 0.0):
				push_error("Rounded corner tile opens away from its connected straight roads at %s." % cell_key)
				quit(1)
				return
	# The authored placeholders own their own doors; hidden legacy curb cuts are
	# retained only where the old kit happens to align with the fixed streets.
	if rounded_end_tiles < 2:
		push_error("Authored route must expose readable rounded street end caps; found %d." % rounded_end_tiles)
		quit(1)
		return
	if bend_tiles < 2:
		push_error("Route did not produce enough tested rounded 90-degree corners.")
		quit(1)
		return
	if neighborhoods == null:
		push_error("Starter City lost its retained legacy neighborhood compatibility layer.")
		quit(1)
		return
	if nature == null:
		push_error("Starter City lost its retained legacy nature compatibility layer.")
		quit(1)
		return
	if String(generated.get_meta("environment_palette", "")) != "starter_city_bw":
		push_error("Procedural Starter City did not apply its current illustrated environment palette.")
		quit(1)
		return
	var road_meshes := roads.find_children("*", "MeshInstance3D", true, false)
	var building_meshes := neighborhoods.find_children("*", "MeshInstance3D", true, false)
	var road_material := (road_meshes[0] as MeshInstance3D).material_override as ShaderMaterial if not road_meshes.is_empty() else null
	var building_material: ShaderMaterial
	for building_mesh_value in building_meshes:
		var building_mesh := building_mesh_value as MeshInstance3D
		if String(building_mesh.get_meta("starter_city_palette", "")) == "building":
			building_material = building_mesh.material_override as ShaderMaterial
			break
	if (
		road_material == null
		or road_material.shader == null
		or not road_material.shader.resource_path.ends_with("starter_city_palette.gdshader")
		or int(road_material.get_shader_parameter("palette_mode")) != 0
		or not (road_material.get_shader_parameter("road_asphalt") as Color).is_equal_approx(GamePalette.CITY_ROAD_ASPHALT)
	):
		push_error("Starter City roads did not use the shared dusty lavender-gray road palette.")
		quit(1)
		return
	if (
		building_material == null
		or building_material.shader == null
		or not building_material.shader.resource_path.ends_with("starter_city_palette.gdshader")
		or int(building_material.get_shader_parameter("palette_mode")) != 1
		or not (building_material.get_shader_parameter("wall") as Color).is_equal_approx(GamePalette.CITY_WALL)
		or not (building_material.get_shader_parameter("roof") as Color).is_equal_approx(GamePalette.CITY_ROOF)
	):
		push_error("Starter City houses did not use the shared cream-wall and lavender-roof palette.")
		quit(1)
		return
	if graph.layers.size() != graph.route_columns + 2 or graph._available_destinations().size() != 1:
		push_error("Authored city changed the fixed opening-route contract.")
		quit(1)
		return
	var neighborhood_buildings := 0
	var north_edge_buildings := 0
	var south_edge_buildings := 0
	for neighborhood_child_value in neighborhoods.get_children():
		var neighborhood_child := neighborhood_child_value as Node3D
		if String(neighborhood_child.get_meta("map_role", "")) != "neighborhood_building":
			continue
		neighborhood_buildings += 1
		if is_equal_approx(neighborhood_child.position.z, stage.NORTH_BUILDING_Z):
			north_edge_buildings += 1
		elif is_equal_approx(neighborhood_child.position.z, stage.SOUTH_BUILDING_Z):
			south_edge_buildings += 1
	if neighborhood_buildings >= graph.nodes.size() / 2:
		push_error("Starter City filled too many route parcels with houses instead of preserving map breathing room.")
		quit(1)
		return
	if (
		not bool(graph.world_exploration_mode)
		or graph.button_layer.visible
		or graph.route_stops.visible
		or graph.route_lines.visible
	):
		push_error("Starter City still exposes clickable board markers instead of physical town actors.")
		quit(1)
		return
	var overview_button := stage.get_node_or_null("Interface/MapOverview") as Button
	if overview_button == null or overview_button.text != "TOWN MAP":
		push_error("Starter City exploration camera is missing its town-map overview control.")
		quit(1)
		return
	var guide_text := stage.get_node_or_null("Interface/Guide/Margin/Text") as Label
	if guide_text == null or guide_text.text != "STARTER CITY   •   MOVE WITH WASD / ARROWS":
		push_error("Starter City map is missing its free-movement guide.")
		quit(1)
		return
	var route_status := stage.get_node_or_null("Interface/RouteStatus") as Label
	if route_status == null or route_status.get_theme_constant("outline_size") != 0:
		push_error("Starter City route status still uses the legacy outlined map label.")
		quit(1)
		return
	var camera := stage.get_node("Camera3D") as Camera3D
	if not is_equal_approx(camera.size, stage.TOWN_CAMERA_SIZE) or not is_equal_approx(camera.size, stage.route_camera_size):
		push_error("Starter City did not open at its closer walking-camera scale.")
		quit(1)
		return
	var player := stage.get_node("Player") as CharacterBody3D
	var player_visual := player.get_node_or_null("Visual") as Node3D
	var expected_start_position: Vector3 = graph.nodes.start.position
	expected_start_position.z += stage.PLAYER_ROAD_CENTER_OFFSET_Z
	var landmarks := generated.get_node("Landmarks") as Node3D
	if (
		landmarks.visible
		or not player.free_roam_enabled
		or player.free_roam_cells.is_empty()
		or not player.global_position.is_equal_approx(expected_start_position)
		or not player.scale.is_equal_approx(Vector3.ONE * stage.USER_PLAYER_SCALE)
		or player_visual == null
		or not player_visual.scale.is_equal_approx(Vector3.ONE * stage.USER_PLAYER_VISUAL_SCALE)
	):
		push_error("Starter City player was not configured for road-constrained free movement.")
		quit(1)
		return
	var path_center := expected_start_position
	var path_inside := path_center + Vector3(0.0, 0.0, player.free_roam_path_half_width * 0.85)
	var path_outside := path_center + Vector3(0.0, 0.0, player.free_roam_path_half_width + 0.16)
	var between_tiles := path_center + Vector3(0.5, 0.0, 0.0)
	if (
		not player._free_roam_position_is_valid(path_center)
		or not player._free_roam_position_is_valid(path_inside)
		or not player._free_roam_position_is_valid(between_tiles)
		or player._free_roam_position_is_valid(path_outside)
	):
		push_error("Player movement was not clipped to the visible path footprint.")
		quit(1)
		return
	Input.action_press("ui_down")
	for _frame in range(12):
		await physics_frame
	Input.action_release("ui_down")
	await process_frame
	if absf(player.global_position.z - path_center.z) > player.free_roam_path_half_width + 0.02:
		push_error("Physics movement allowed the player to leave the visible path for the grass.")
		quit(1)
		return
	player.global_position = path_center
	overview_button.pressed.emit()
	for _frame in range(3):
		await process_frame
	await create_timer(1.1).timeout
	if (
		not stage.overview_active
		or not is_equal_approx(stage.camera_target_size, stage.OVERVIEW_CAMERA_SIZE)
	):
		push_error("Full-map control did not activate the overview framing.")
		quit(1)
		return
	if not player.is_world_input_locked() or overview_button.text != "RETURN":
		push_error("Opening the town map did not pause world movement.")
		quit(1)
		return
	if DisplayServer.get_name() != "headless":
		var overview_image := root.get_viewport().get_texture().get_image()
		if (
			overview_image == null
			or overview_image.save_png(ProjectSettings.globalize_path(OVERVIEW_PREVIEW_PATH)) != OK
		):
			push_error("Could not save the full-map Starter City preview.")
			quit(1)
			return
	overview_button.pressed.emit()
	for _frame in range(3):
		await process_frame
	if (
		stage.overview_active
		or not is_equal_approx(stage.camera_target_size, stage.route_camera_size)
		or player.is_world_input_locked()
		or overview_button.text != "TOWN MAP"
		or not is_equal_approx(graph.camera_target_x, player.global_position.x)
	):
		push_error("Town-map control did not return to the player-follow exploration view.")
		quit(1)
		return
	for route_key_value in graph.routes.keys():
		var route_key := String(route_key_value)
		var ids := route_key.split(">")
		var previous: Vector3 = graph.nodes[String(ids[0])].position
		for point_value in graph.routes[route_key]:
			var point := point_value as Vector3
			if (
				not is_zero_approx(previous.x - point.x)
				and not is_zero_approx(previous.z - point.z)
				and absf(previous.z - point.z) >= 0.7
			):
				push_error("Generated walking route left the fitted orthogonal street network: %s" % route_key)
				quit(1)
				return
			previous = point
	var sample_destination_id := String(active_npc_probe.get_meta("route_node_id", ""))
	var sample_destination: Dictionary = graph.node_data(sample_destination_id)
	var graph_snapshot: Dictionary = graph.snapshot()
	if (
		String(sample_destination.get("npc_archetype", "")) not in graph.NPC_ARCHETYPES
		or String(sample_destination.get("npc_personality", "")) not in graph.NPC_PERSONALITIES
		or not (graph_snapshot.nodes[sample_destination_id] as Dictionary).has("npc_archetype")
	):
		push_error("Seeded NPC typing was not preserved in the route snapshot.")
		quit(1)
		return
	var npc_sight_direction := active_npc_probe.get("sight_direction") as Vector3
	var sightline := active_npc_probe.get_node("NpcSightline") as Area3D
	var sightline_collision := sightline.get_node("SightlineShape") as CollisionShape3D
	var sightline_shape := sightline_collision.shape as BoxShape3D
	if sightline_shape == null or sightline_shape.size.x > 0.4:
		push_error("NPC sightline is still wide enough to trigger noticeably off-center.")
		quit(1)
		return
	var lateral_axis := Vector3(-npc_sight_direction.z, 0.0, npc_sight_direction.x)
	player.global_position = (
		active_npc_probe.global_position
		+ npc_sight_direction * 1.15
		+ lateral_axis * 0.3
		+ Vector3.UP * 0.62
	)
	if bool(active_npc_probe.call("_player_is_directly_ahead")):
		push_error("NPC sightline accepted a player who was offset from its centerline.")
		quit(1)
		return
	player.global_position = active_npc_probe.global_position + npc_sight_direction * 1.15 + Vector3.UP * 0.62
	if not bool(active_npc_probe.call("_player_is_directly_ahead")):
		push_error("NPC sightline did not recognize a player centered directly ahead.")
		quit(1)
		return
	var npc_world_position := active_npc_probe.global_position
	active_npc_probe.call("trigger_encounter")
	await process_frame
	var reaction_mark := active_npc_probe.get_node("ReactionMark") as Label3D
	if not player.is_world_input_locked() or not reaction_mark.visible:
		push_error("Walking into an NPC sightline did not lock movement and show the reaction mark.")
		quit(1)
		return
	await create_timer(0.8).timeout
	if (
		graph.current_node_id != sample_destination_id
		or not active_npc_probe.global_position.is_equal_approx(npc_world_position)
	):
		push_error("The stationary NPC reaction did not commit its physical route destination.")
		quit(1)
		return
	if stage.generation_signature.is_empty():
		push_error("Procedural city did not expose a deterministic generation signature.")
		quit(1)
		return
	var first_signature: String = stage.generation_signature
	var first_layout_id := String(generated.get_meta("town_layout_id", ""))
	await create_timer(0.35).timeout
	if DisplayServer.get_name() != "headless":
		var image := root.get_viewport().get_texture().get_image()
		if image == null or image.save_png(ProjectSettings.globalize_path(PREVIEW_PATH)) != OK:
			push_error("Could not save the procedural Starter City preview.")
			quit(1)
			return
	stage.queue_free()
	await process_frame
	var alternate_stage := packed.instantiate()
	alternate_stage.get_node("RouteGraph").generation_seed = 240827
	root.call_deferred("add_child", alternate_stage)
	for _frame in range(8):
		await process_frame
	var alternate_generated := alternate_stage.get_node("GeneratedStarterCity") as Node3D
	if (
		alternate_stage.generation_signature == first_signature
		or String(alternate_generated.get_meta("town_layout_id", "")) != first_layout_id
		or String(alternate_generated.get_meta("town_layout_mode", "")) != "authored_default"
		or alternate_stage.TOWN_LAYOUTS.size() != 7
	):
		push_error("The seed changed the fixed town plan or stopped varying encounter content.")
		quit(1)
		return
	print("STARTER_CITY_PROCEDURAL_PROTOTYPE_OK %s -> %s" % [first_signature, alternate_stage.generation_signature])
	quit()
