extends SceneTree

const SCENE_PATH := "res://scenes/StarterCityOverworld.tscn"


func _initialize() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load Starter City for town-layout testing.")
		quit(1)
		return
	var layout_ids := {}
	var npc_archetypes := {}
	var shop_door_checked := false
	for seed_offset in range(7):
		var stage := packed.instantiate()
		stage.get_node("RouteGraph").generation_seed = 240821 + seed_offset
		root.call_deferred("add_child", stage)
		for _frame in range(8):
			await process_frame
		var generated := stage.get_node_or_null("GeneratedStarterCity") as Node3D
		var buildings := stage.get_node_or_null(
			"GeneratedStarterCity/UserIllustratedMap/PlaceholderBuildings"
		) as Node3D
		var actors := stage.get_node_or_null("GeneratedStarterCity/UserIllustratedMap/TownActors") as Node3D
		var graph := stage.get_node("RouteGraph")
		if generated == null or buildings == null or actors == null:
			push_error("A seeded town layout did not build its physical world layers.")
			quit(1)
			return
		var layout_id := String(generated.get_meta("town_layout_id", ""))
		layout_ids[layout_id] = true
		if (
			layout_id != "starter_town_main_route"
			or String(generated.get_meta("town_layout_mode", "")) != "authored_default"
			or buildings.get_child_count() < 6
		):
			push_error("Town seed %d did not retain the populated authored default." % (240821 + seed_offset))
			quit(1)
			return
		for node_value in graph.nodes.values():
			var data := node_value as Dictionary
			var archetype := String(data.get("npc_archetype", ""))
			if not archetype.is_empty():
				npc_archetypes[archetype] = true
		if not graph.world_exploration_mode or graph._available_destinations().is_empty():
			push_error("Town seed %d lost its explorable route choices." % (240821 + seed_offset))
			quit(1)
			return
		if not shop_door_checked:
			for building_value in buildings.get_children():
				var building := building_value as Node3D
				var entrance := building.get_node_or_null("ShopEntrance") as Area3D
				if entrance == null:
					continue
				var shop_node_id := String(entrance.get_meta("route_node_id", ""))
				if String(graph.nodes.get(shop_node_id, {}).get("type", "")) != "shop":
					continue
				shop_door_checked = true
				break
		stage.queue_free()
		await process_frame
	if layout_ids.size() != 1 or not layout_ids.has("starter_town_main_route"):
		push_error("Seeds changed the production town plan before procedural layouts were enabled.")
		quit(1)
		return
	if npc_archetypes.size() != 5:
		push_error("Seeded NPCs did not cover all five card affinities.")
		quit(1)
		return
	if not shop_door_checked:
		push_error("The authored town did not expose its walk-in CARD STORE placeholder.")
		quit(1)
		return
	print("STARTER_CITY_TOWN_LAYOUT_SMOKE_TEST_OK %s" % ", ".join(layout_ids.keys()))
	quit()
