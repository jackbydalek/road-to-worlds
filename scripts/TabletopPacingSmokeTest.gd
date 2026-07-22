extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/Tabletop3DPrototype.tscn") as PackedScene
	_expect(packed_scene != null, "The Living Table scene could not be loaded.")
	if packed_scene == null:
		_finish()
		return
	var table = packed_scene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	_expect(table.find_child("TurnBanner", true, false) != null, "The turn pacing banner was not created.")
	_expect(table.find_child("OutcomeOverlay", true, false) != null, "The match outcome overlay was not created.")
	_expect(table.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "The no-sound pacing pass added an AudioStreamPlayer.")
	var table_environment := table.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_expect(table_environment != null and table_environment.environment.background_color.is_equal_approx(Color("#b0cece")), "Living Table did not match the shop scene's #b0cece background.")
	table._face_material("spicy_hot_honey_bee")
	var bee_face_viewport := table.texture_viewports.find_child("PrototypeFullCardFaceViewport_spicy_hot_honey_bee", false, false) as SubViewport
	_expect(bee_face_viewport != null and bee_face_viewport.size == table.CARD_FACE_TEXTURE_SIZE and bee_face_viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Living Table card faces still used an unbounded full-frame render target.")
	var redraws_before_animation: int = table.card_face_redraw_requests
	await create_timer(0.14).timeout
	_expect(table.card_face_redraw_requests > redraws_before_animation and bee_face_viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Animated card art did not request a bounded redraw at its authored frame rate.")

	await table._show_opponent_reveal({"card_id": "spicy_hot_honey_bee", "side": "opponent", "type": "play"})
	await process_frame
	_expect(table.find_child("OpponentRevealCard", true, false) == null, "The opponent reveal card did not clean itself up.")
	var moved_unit: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("spicy_hot_honey_bee"), "prep", "opponent")
	moved_unit.table_slot = 0
	table.state.opponent.prep = [moved_unit]
	table.state.opponent.plated = []
	table._render_match()
	var prep_card: Node3D = table._card_node_for_instance(int(moved_unit.instance_id))
	var prep_position: Vector3 = prep_card.position
	table.state.opponent.prep.erase(moved_unit)
	table.state.opponent.plated.append(moved_unit)
	table.service._queue_animation_event(table.state, "move", {
		"side": "opponent",
		"instance_id": int(moved_unit.instance_id),
		"card_id": String(moved_unit.card_id),
		"from": "prep",
		"to": "plated"
	}, table.service._next_animation_group(table.state))
	await table._drain_animation_event_queue()
	var plated_card: Node3D = table._card_node_for_instance(int(moved_unit.instance_id))
	_expect(plated_card != null and plated_card.position.z > prep_position.z + 1.0, "The opponent card did not animate from Prep into its Plated position.")

	table.state.game_over = true
	table.state.winner = "player"
	table.state.phase = "game_over"
	table.state.opponent.life = 0
	table.animation_busy = false
	table._render_match()
	for unused_wait in range(25):
		if bool(table.outcome_sequence_played):
			break
		await create_timer(0.1).timeout
	_expect(bool(table.outcome_sequence_played), "The victory presentation did not complete.")
	await create_timer(0.35).timeout
	_expect(table.prompt_panel.visible, "The debug match did not restore its post-sequence match-over controls.")
	table.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("Living Table pacing smoke test passed (silent presentation).")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
