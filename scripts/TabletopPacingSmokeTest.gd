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
	# A drop is resolved under the dragged card, not under the offset point where
	# the player happened to grab it. This keeps the highlighted slot authoritative.
	table.drag_offset = Vector3(-0.55, 0.0, 0.0)
	var offset_drop_point: Vector3 = table._dragged_card_point(Vector3(0.4, table.TABLE_Y, -0.65))
	var offset_drop_slot: Dictionary = table._slot_at_point(offset_drop_point)
	_expect(
		String(offset_drop_slot.get("zone", "")) == "player_plated" and int(offset_drop_slot.get("slot", -1)) == 0,
		"An offset card grab resolved the drop under the pointer instead of the highlighted Plated slot."
	)
	table.drag_offset = Vector3.ZERO
	await create_timer(1.0).timeout
	table._spawn_screen_particle_burst(Vector2(120.0, 120.0), Color.WHITE, 1, "✦")
	var procedural_particle: Node = table.effect_layer.get_child(-1)
	_expect(procedural_particle is Polygon2D, "Tabletop effects still use font glyphs that can render as missing-character boxes.")
	await create_timer(0.6).timeout
	var draw_card_id := String(table.state.player.hand[0])
	var effect_count_before_draw: int = table.effect_layer.get_child_count()
	var draw_animation_duration: float = table._start_card_transfer_event_animation({
		"type": "draw",
		"side": "player",
		"hand_index": 0,
		"card_id": draw_card_id,
		"from": "deck",
		"to": "hand"
	})
	_expect(draw_animation_duration > 0.0 and table.effect_layer.get_child_count() == effect_count_before_draw, "Drawing a card still spawned a particle burst.")
	await create_timer(draw_animation_duration).timeout
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
	var floating_art := prep_card.find_child("FloatingArt", true, false) as MeshInstance3D if prep_card != null else null
	var floating_start_position := floating_art.position if floating_art != null else Vector3.ZERO
	var floating_start_rotation := floating_art.rotation if floating_art != null else Vector3.ZERO
	var floating_start_texture := (floating_art.material_override as StandardMaterial3D).albedo_texture if floating_art != null else null
	var field_face_viewport := table.texture_viewports.find_child("PrototypeFullCardFaceViewport_spicy_hot_honey_bee_NoArt", false, false) as SubViewport
	var field_card_art := field_face_viewport.find_child("CardArtwork", true, false) as TextureRect if field_face_viewport != null else null
	_expect(floating_art != null and is_equal_approx(floating_art.position.y, table.FLOATING_ART_HEIGHT) and floating_art.position.y < 0.75, "Field artwork was not lowered closer to its physical card.")
	_expect(field_card_art != null and not field_card_art.visible, "A field card duplicated its artwork beneath the floating image.")
	await create_timer(0.08).timeout
	var floating_advanced_texture := (floating_art.material_override as StandardMaterial3D).albedo_texture if floating_art != null else null
	_expect(floating_art != null and floating_art.position.is_equal_approx(floating_start_position) and floating_art.rotation.is_equal_approx(floating_start_rotation), "Field artwork still bounced or swayed instead of staying fixed above the card.")
	_expect(floating_start_texture != null and floating_advanced_texture != floating_start_texture, "Field artwork did not continue looping its authored animation frames.")
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

	# Dragging an attacker onto the opposing chef must restore its board pose,
	# then animate straight forward instead of lunging from the drop corner.
	var direct_attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "plated", "player")
	direct_attacker.ready = true
	direct_attacker.table_slot = 0
	table.state.player.prep = []
	table.state.player.plated = [direct_attacker]
	table.state.opponent.prep = []
	table.state.opponent.plated = []
	table.state.opponent.life = 25
	table.state.player.turns_started = 2
	table.state.phase = "player_main"
	table.state.game_over = false
	table.state.selected_attacker = -1
	table.service.clear_animation_events(table.state)
	table._render_match()
	var direct_attacker_card: Node3D = table._card_node_for_instance(int(direct_attacker.instance_id))
	var attack_origin := direct_attacker_card.position if direct_attacker_card != null else Vector3.ZERO
	if direct_attacker_card != null:
		table.pressed_card = direct_attacker_card
		table.dragging = true
		table.drag_original_position = attack_origin
		table.drag_original_rotation = direct_attacker_card.rotation
		direct_attacker_card.position = Vector3(table.opponent_chef.position.x, table.DRAG_Y, table.opponent_chef.position.z)
		direct_attacker_card.rotation = Vector3.ZERO
		direct_attacker_card.scale = Vector3.ONE
		table._finish_drag(table.opponent_chef.position)
		_expect(direct_attacker_card.position.is_equal_approx(attack_origin), "A chef-targeted drag attack did not return to its board slot before animating.")
		await create_timer(0.12).timeout
		_expect(bool(table.animation_busy) and direct_attacker_card.position.z < attack_origin.z - 0.2 and absf(direct_attacker_card.position.x - attack_origin.x) < 0.05, "A chef-targeted attack did not animate straight forward from its board slot.")
		await create_timer(1.0).timeout
		_expect(not bool(table.animation_busy) and int(table.state.opponent.life) == 24, "The forward chef-attack animation did not resolve combat cleanly.")
	else:
		_expect(false, "The direct-attack regression card was not rendered on the Living Table.")

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
