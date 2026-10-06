extends "res://scripts/SuppliedMinaCapture.gd"

## Native battle capture: two physical mats, supplied Mina, and her actual
## concealed hand. State fixtures never write saves or change source artwork.
const SPLIT_OUTPUT_DIR := "res://outputs/split_mats_live_hand"


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPLIT_OUTPUT_DIR))
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		await _create_match()
		_stage_board(true)
		table.configure_battle_preferences("fast", 1.0, true, false)
		var shot_index := 1
		for count in [0, 1, 3, 5, 12]:
			table.state.opponent.hand = _hand_for_count(count)
			table.service.clear_animation_events(table.state)
			table._render_match()
			await _settle()
			_check_board_and_hud("hand-%d" % count)
			_expect(table.rival_held_cards.held_count == count, "Live card backs disagree with hand count %d" % count)
			if count > 0:
				_expect(table.get_viewport_rect().encloses(table.rival_held_cards.get_hand_global_rect()), "Held cards clip at count %d" % count)
			await _save_shot("%02d_hand_%02d" % [shot_index, count])
			shot_index += 1
		await _capture_service_changes()
		for node in table.find_children("*", "AudioStreamPlayer", true, false):
			node.stop()
			node.stream = null
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	_expect(records.size() == 14, "Some requested hand-state captures did not finish")
	var report := FileAccess.open(SPLIT_OUTPUT_DIR.path_join("capture-review.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify({"renderer": "native Godot battle", "new_ai_image_generation": false, "character_source": "user-provided IMG_0450.GIF; authorship and AI origin unknown", "generated_rival_art_enabled": false, "shots": records, "failures": errors}, "\t") + "\n")
	else:
		_expect(false, "Could not write the capture review")
	for error in errors:
		push_error(error)
	print("SPLIT_MATS_LIVE_HAND_CAPTURE_%s: %d views; %d failures" % ["OK" if errors.is_empty() else "FAILED", records.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)


func _hand_for_count(count: int) -> Array:
	var result: Array = []
	var choices := ["hearty_bagver", "sweet_caramel_camel", "item_wooden_spoon", "sweet_jellyfish", "sweet_soft_serve_crab"]
	for index in range(count):
		result.append(choices[index % choices.size()])
	return result


func _capture_service_changes() -> void:
	table.state.phase = "opponent_turn"
	table.state.opponent.prep = []
	table.state.opponent.hand = _hand_for_count(3)
	table.state.opponent.deck = ["sweet_sugar_glider", "sweet_sugar_glider", "sweet_sugar_glider"]
	table.service.clear_animation_events(table.state)
	table.configure_battle_preferences("normal", 1.0, false, false)
	table._render_match()
	await _settle()
	table.service._draw(table.state, "opponent")
	_expect(table.state.opponent.hand.size() == 4, "The actual service did not draw a card")
	var draw_status := {"done": false}
	call("_drain_and_mark", draw_status)
	await create_timer(0.075).timeout
	_expect(table.rival_held_cards.is_animating(), "The draw capture missed the actual held-card motion")
	await _save_shot("06_mid_draw")
	await _wait_for_drain(draw_status)
	_expect(table.rival_held_cards.held_count == 4, "Held cards did not reconcile after the draw")
	table.service.clear_animation_events(table.state)
	var played: bool = table.service._play_ingredient(table.state, "opponent", 0, "prep")
	_expect(played and table.state.opponent.hand.size() == 3, "The actual service did not play the held Ingredient")
	var play_status := {"done": false}
	call("_drain_and_mark", play_status)
	await create_timer(0.075).timeout
	_expect(table.rival_held_cards.is_animating(), "The play capture missed the actual held-card motion")
	await _save_shot("07_mid_play")
	await _wait_for_drain(play_status)
	_expect(table.rival_held_cards.held_count == 3, "Held cards did not reconcile after the play")


func _drain_and_mark(status: Dictionary) -> void:
	await table._drain_animation_event_queue()
	table._render_match()
	status.done = true


func _wait_for_drain(status: Dictionary) -> void:
	for step in range(150):
		if bool(status.done):
			await _settle(2)
			return
		await create_timer(0.02).timeout
	_expect(false, "The actual draw/play animation queue did not complete")


func _save_shot(state_name: String) -> void:
	var shot_name := "%dx%d_%s" % [capture_size.x, capture_size.y, state_name]
	var held = table.rival_held_cards
	var record := {"shot": shot_name, "output_size": [capture_size.x, capture_size.y], "logical_size": str(table.size), "state_hand_count": table.state.opponent.hand.size(), "held_count": held.held_count, "held_animating": held.is_animating(), "hand_bounds": str(held.get_hand_global_rect()), "reduced_motion": table.reduced_motion, "saved_png": false}
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture := capture_viewport.get_texture().get_image()
		_expect(capture != null and capture.get_size() == capture_size, "%s: screenshot has incorrect dimensions" % state_name)
		if capture != null:
			record.saved_png = capture.save_png(ProjectSettings.globalize_path(SPLIT_OUTPUT_DIR.path_join(shot_name + ".png"))) == OK
			_expect(record.saved_png, "%s: screenshot could not be saved" % state_name)
	records.append(record)
	print("SPLIT_MATS_LIVE_HAND_CAPTURE ", shot_name)
