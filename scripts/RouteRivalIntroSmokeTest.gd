extends SceneTree


func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	for _frame in range(4):
		await process_frame
	main.autosave_enabled = false
	main._start_new_run_with_mode("spicy", "season", "white")
	for _frame in range(6):
		await process_frame

	var graph := main.find_child("RouteGraph", true, false)
	var town_actors := main.find_child("TownActors", true, false) as Node3D
	var active_npc: Node3D
	if town_actors != null:
		for actor_value in town_actors.get_children():
			var actor := actor_value as Node3D
			if bool(actor.get_meta("encounter_active", false)):
				active_npc = actor
				break
	_expect(active_npc != null, "The authored town did not expose an active rival NPC.")
	var npc_route_id := String(active_npc.get_meta("route_node_id", ""))
	var npc_route_data: Dictionary = graph.call("node_data", npc_route_id)
	var npc_world_position := active_npc.global_position
	active_npc.call("trigger_encounter")
	await process_frame
	var reaction_mark := active_npc.get_node_or_null("ReactionMark") as Label3D
	_expect(
		reaction_mark != null
		and reaction_mark.visible
		and active_npc.global_position.is_equal_approx(npc_world_position),
		"The sightline encounter did not show ! above the stationary rival."
	)
	await create_timer(0.8).timeout
	for _frame in range(4):
		await process_frame

	var portrait := main.find_child("RouteRivalPortrait", true, false) as TextureRect
	var intro_portrait_path := portrait.texture.resource_path if portrait != null and portrait.texture != null else ""
	var dialogue := main.find_child("RouteRivalDialogueText", true, false) as Label
	var continue_button := main.find_child("BeginRouteEncounterButton", true, false) as Button
	_expect(main.current_screen == "route_encounter_intro", "Combat node did not open the route-rival intro.")
	_expect(
		active_npc.global_position.is_equal_approx(npc_world_position),
		"The rival moved toward the player before opening the portrait screen."
	)
	_expect(main.find_child("StarterCityMap", true, false) != null, "The rival intro replaced the map instead of overlaying it.")
	_expect(main.find_child("RouteEncounterDimmer", true, false) != null, "The route map was not dimmed behind the rival.")
	_expect(
		portrait != null
		and portrait.texture != null
		and portrait.texture.resource_path.contains("route_rival_npc_"),
		"The route intro did not use a supplied NPC portrait."
	)
	_expect(dialogue != null and not dialogue.text.is_empty(), "The route rival has no dialogue.")
	_expect(continue_button != null and not continue_button.disabled, "The route rival intro has no usable Continue action.")
	_expect(
		String(main.run.route_battle.get("rival_portrait_id", ""))
		== String(npc_route_data.get("npc_portrait_id", "")),
		"The opening portrait did not match the NPC triggered in the town."
	)
	_expect(main._route_rival_portrait_id("mini_boss", 1) == "npc2", "The local champion did not keep NPC 2.")
	_expect(main._route_rival_portrait_id("final_boss", 1) == "npc1", "The city champion did not keep NPC 1.")

	continue_button.emit_signal("pressed")
	for _frame in range(5):
		await process_frame
	_expect(
		main.current_screen == "kitchen_match"
		and main.find_child("Tabletop3DPrototype", true, false) != null,
		"Continue did not launch the route battle."
	)
	var tabletop = main.find_child("Tabletop3DPrototype", true, false)
	var opponent_profile := main.find_child("OpponentProfileBadgePortrait", true, false) as TextureRect
	var profile_atlas := opponent_profile.texture as AtlasTexture if opponent_profile != null else null
	_expect(
		tabletop != null
		and String(tabletop.configured_match_context.get("rival_portrait_id", ""))
			== String(main.run.route_battle.get("rival_portrait_id", "")),
		"The route rival portrait ID did not reach the Living Table."
	)
	_expect(
		profile_atlas != null
		and profile_atlas.atlas != null
		and profile_atlas.atlas.resource_path == intro_portrait_path,
		"The battle profile icon did not use the rival shown in the encounter intro."
	)

	print("ROUTE_RIVAL_INTRO_SMOKE_TEST_OK")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
