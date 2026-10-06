extends "res://scripts/PeachSodaBattleCapture.gd"
const REFERENCE_OUTPUT := "res://outputs/combat_reference_2026-09-15"

func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REFERENCE_OUTPUT))
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		await _create_match()
		_stage_board(true)
		table.state.player.plated.clear()
		_add_unit("player", "spicy_wasabi_wasp", "prep", 1)
		_add_unit("opponent", "sweet_caramel_camel", "prep", 1)
		table._render_match()
		await _settle()
		_check_board_and_hud("reference")
		await _save_shot("01_reference")
		var unit: Dictionary = table.state.player.prep[1]
		table._inspect_card(table._card_node_for_instance(int(unit.instance_id)))
		await _settle()
		for action in table.inspector_action_buttons:
			_expect(table.get_viewport_rect().encloses(action.get_global_rect()), "Inspector action clips")
			_expect(not action.get_global_rect().intersects(table.player_profile_badge.get_global_rect()), "Health covers inspector action")
		await _save_shot("02_inspector")
		table.configure_battle_preferences("fast", 1.5, true, false)
		await _settle()
		await _save_shot("03_large_text")
		table._dismiss_card_viewer()
		table.configure_battle_preferences("fast", 1.0, true, true)
		await _settle()
		await _save_shot("04_board_info")
		for node in table.find_children("*", "AudioStreamPlayer", true, false):
			node.stop()
			node.stream = null
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	for error in errors: push_error(error)
	print("Combat reference capture: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func _save_shot(state_name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	await process_frame
	var filename := "%dx%d_%s.png" % [capture_size.x, capture_size.y, state_name]
	_expect(capture_viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(REFERENCE_OUTPUT.path_join(filename))) == OK, "Capture failed: " + filename)
	print("COMBAT_REFERENCE_CAPTURE ", filename)

func _create_match() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = capture_size
	# Match project.godot's 1440x900 canvas_items/expand behavior without the
	# desktop window manager constraining a 1080p screenshot on smaller screens.
	var canvas_scale := minf(float(capture_size.x) / 1440.0, float(capture_size.y) / 900.0)
	capture_viewport.size_2d_override = Vector2i(Vector2(capture_size) / canvas_scale)
	capture_viewport.size_2d_override_stretch = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	table = TABLE_SCENE.instantiate()
	table.configure_match(
		{"chef_bill": 3, "spicy_hot_honey_bee": 3, "spicy_wasabi_wasp": 3, "spicy_jalapeno_panther": 3, "spicy_sriracharrow": 3, "spicy_firecracker_shrimp": 3, "item_wooden_spoon": 2},
		{"chef_mary": 3, "sweet_sugar_glider": 3, "sweet_caramel_camel": 3, "sweet_soft_serve_crab": 3, "sweet_strawberry_sharkcake": 3, "sweet_jellyfish": 3, "item_wooden_spoon": 2},
		"You", "Sana", 20260907, "player", "Return", "easy", "white",
		{"event_name": "Weekly Locals", "round": 1, "rounds": 3, "player_starter": "spicy", "opponent_affinity": "sweet", "rival_cast_id": "sana", "rival_display_name": "Sana", "tournament_round": true},
		{"player_life": 38, "player_max_life": 40, "opponent_life": 12, "opponent_max_life": 12}
	)
	table.configure_battle_preferences("fast", 1.0, true, false)
	capture_viewport.add_child(table)
	await _settle(14)
	await create_timer(1.3).timeout
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()


