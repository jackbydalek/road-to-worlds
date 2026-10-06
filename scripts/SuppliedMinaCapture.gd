extends "res://scripts/PeachSodaBattleCapture.gd"

## Captures the real populated battle with user-supplied Mina and generated
## rival art disabled. No image generation, source recoloring, or save writes.
const MINA_OUTPUT_DIR := "res://outputs/supplied_mina"


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MINA_OUTPUT_DIR))
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		await _create_match()
		_stage_board(true)
		await _settle()
		_check_board_and_hud("supplied_mina")
		_expect(not table.use_generated_opponent_art and table.rival_at_table.is_visible_in_tree(), "Disabling generated art also removed supplied Mina")
		_expect(table.opponent_profile_name.text == "Mina", "The actual battle profile is not Mina")
		_expect(table.get_viewport_rect().encloses(table.rival_at_table.get_global_rect()), "Mina's supplied sprite is clipped")
		await _save_shot("01_populated")
		table.configure_battle_preferences("fast", 1.0, true, false)
		await _settle()
		var frozen_frame: int = table.rival_at_table.frame_index
		await create_timer(0.25).timeout
		_expect(table.rival_at_table.frame_index == frozen_frame, "Reduced-motion Mina keeps animating")
		await _save_shot("02_reduced_motion")
		for node in table.find_children("*", "AudioStreamPlayer", true, false):
			node.stop()
			node.stream = null
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	var report := FileAccess.open(MINA_OUTPUT_DIR.path_join("capture-review.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"renderer": "native Godot battle", "new_ai_image_generation": false, "character_source": "user-provided IMG_0450.GIF; authorship and AI origin unknown", "generated_rival_art_enabled": false, "shots": records, "failures": errors}, "\t") + "\n")
	else:
		_expect(false, "Could not write the capture review")
	for error in errors:
		push_error(error)
	print("SUPPLIED_MINA_CAPTURE_%s: %d views; %d failures" % ["OK" if errors.is_empty() else "FAILED", records.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)


func _create_match() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = capture_size
	var canvas_scale := minf(float(capture_size.x) / 1440.0, float(capture_size.y) / 900.0)
	capture_viewport.size_2d_override = Vector2i(Vector2(capture_size) / canvas_scale)
	capture_viewport.size_2d_override_stretch = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	table = TABLE_SCENE.instantiate()
	table.use_generated_opponent_art = false
	table.configure_match(
		{"chef_bill": 3, "spicy_hot_honey_bee": 3, "spicy_wasabi_wasp": 3, "spicy_jalapeno_panther": 3, "spicy_sriracharrow": 3, "spicy_firecracker_shrimp": 3, "item_wooden_spoon": 2},
		{"chef_mary": 3, "sweet_sugar_glider": 3, "sweet_caramel_camel": 3, "sweet_soft_serve_crab": 3, "sweet_strawberry_sharkcake": 3, "sweet_jellyfish": 3, "item_wooden_spoon": 2},
		"You", "Mina", 20260907, "player", "Return", "easy", "white",
		{"event_name": "Weekly Locals", "round": 1, "rounds": 3, "player_starter": "spicy", "opponent_affinity": "sweet", "rival_cast_id": "mina", "rival_display_name": "Mina"},
		{"player_life": 32, "player_max_life": 40, "opponent_life": 18, "opponent_max_life": 25}
	)
	table.configure_battle_preferences("fast", 1.0, false, false)
	capture_viewport.add_child(table)
	await _settle(14)
	await create_timer(1.3).timeout
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()


func _save_shot(state_name: String) -> void:
	var shot_name := "%dx%d_%s" % [capture_size.x, capture_size.y, state_name]
	var actor = table.rival_at_table
	var record := {"shot": shot_name, "output_size": [capture_size.x, capture_size.y], "logical_size": str(table.size), "actor_rect": str(actor.get_global_rect()), "frame_index": int(actor.frame_index), "generated_rival_art_enabled": table.use_generated_opponent_art, "reduced_motion": table.reduced_motion, "saved_png": false}
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture := capture_viewport.get_texture().get_image()
		_expect(capture != null and capture.get_size() == capture_size, "%s: screenshot has incorrect dimensions" % state_name)
		if capture != null:
			record.saved_png = capture.save_png(ProjectSettings.globalize_path(MINA_OUTPUT_DIR.path_join(shot_name + ".png"))) == OK
			_expect(record.saved_png, "%s: screenshot could not be saved" % state_name)
	records.append(record)
	print("SUPPLIED_MINA_CAPTURE ", shot_name)
