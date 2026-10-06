extends SceneTree

## Real Jellyfish plays must retain the returned physical card until its flight.
## Add -- --capture with the native renderer for the Prep/Plated travel captures.
class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var return_starts: Array[Dictionary] = []
	var activation_starts := 0

	func _begin_match_pacing() -> void:
		pass

	func _show_field_activation_indicator(event: Dictionary) -> void:
		activation_starts += 1
		await super._show_field_activation_indicator(event)

	func _start_card_transfer_event_animation(event: Dictionary) -> float:
		if String(event.get("from", "")) not in ["prep", "plated"] or String(event.get("to", "")) != "hand":
			return super._start_card_transfer_event_animation(event)
		var source := _card_node_for_instance(int(event.get("source_instance_id", -1)))
		var destination := _hand_card_node(String(event.side), int(event.hand_index), String(event.card_id))
		var sample := {
			"event": event, "at": Time.get_ticks_msec(),
			"source": source,
			"source_visible": is_instance_valid(source) and source.is_visible_in_tree(),
			"source_transform": source.global_transform if is_instance_valid(source) else Transform3D.IDENTITY,
			"destination": destination,
			"destination_position": destination.global_position if is_instance_valid(destination) else Vector3.ZERO,
			"held_before": rival_held_cards.held_count if _has_live_rival_hand() else -1,
		}
		var duration := super._start_card_transfer_event_animation(event)
		sample.duration = duration
		sample.launch_transform = source.global_transform if is_instance_valid(source) else Transform3D.IDENTITY
		return_starts.append(sample)
		return duration


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_DIR := "res://outputs/jellyfish_bounce_2026-09-11"
const RETURN_CARD := "spicy_hot_honey_bee"
var failures: Array[String] = []
var table
var drain_done := true
var save_captures := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	save_captures = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	if save_captures:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	table = TABLE_SCENE.instantiate()
	table.set_script(ObservedTable)
	table.use_generated_opponent_art = false
	table.configured_match_context = {"rival_cast_id": "mina", "rival_display_name": "Mina"}
	table.configure_battle_preferences("fast", 1.0, true, false)
	root.add_child(table)
	await _settle()
	await _test_returns("player", ["prep"], false)
	await _test_returns("player", ["plated"], false)
	await _test_returns("player", ["prep", "plated"], false)
	await _test_returns("opponent", ["prep"], false)
	await _test_returns("opponent", ["plated"], false)
	await _test_returns("player", ["plated"], true)
	await _test_returns("opponent", ["prep"], true)
	await _test_token_return()
	table.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("Jellyfish bounce smoke test passed: Prep/Plated source continuity, real play/activation batches, duplicate copies, live rival hand arrival, Reduced Motion, and token evaporation.")
	quit(0 if failures.is_empty() else 1)


func _reset(reduced: bool) -> void:
	table.state = table.service.start_game("sweet_test_kitchen", "spicy_test_kitchen", 922, "player", true, "easy")
	table.state.turn = 3
	table.state.phase = "player_main"
	table.state.game_over = false
	for side in ["player", "opponent"]:
		table.state[side].turns_started = 2
		table.state[side].prep = []
		table.state[side].plated = []
		table.state[side].hand = []
		table.state[side].discard = []
		table.state[side].environment = ""
	table.selected_ref = {}
	table.animation_busy = false
	table.production_match = true
	table.configure_battle_preferences("fast", 1.0, reduced, false)
	table.return_starts.clear()
	table.activation_starts = 0
	table.service.clear_animation_events(table.state)


func _unit(side: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(RETURN_CARD), zone, side)
	unit.table_slot = slot
	unit.ready = true
	table.state[side][zone].append(unit)
	return unit


func _test_returns(side: String, zones: Array, reduced: bool) -> void:
	_reset(reduced)
	var label := "%s %s%s" % [side, "+".join(zones), " Reduced Motion" if reduced else ""]
	var acting_side := "opponent" if side == "player" else "player"
	var targets: Array[Dictionary] = []
	for index in zones.size():
		targets.append(_unit(side, String(zones[index]), 2 if zones[index] == "prep" else 1))
	# Identical copies already in hand must remain present while the specific
	# returned instance waits on the board. Card-id lookup alone is insufficient.
	table.state[side].hand = [RETURN_CARD, RETURN_CARD]
	for unused in zones.size():
		table.state[acting_side].hand.append("sweet_jellyfish")
	table._render_match()
	await _settle()
	var origins: Dictionary = {}
	for target in targets:
		var id := int(target.instance_id)
		var source: Node3D = table._card_node_for_instance(id)
		origins[id] = {"node": source, "transform": source.global_transform}
	if side == "opponent":
		_expect(table._has_live_rival_hand() and table.rival_held_cards.held_count == 2, label + ": fixture has no two-card live rival hand.")
	if save_captures and zones.size() == 1 and not reduced:
		await _capture(side + "_" + zones[0] + "_before")
	for target in targets:
		var played: bool = table.service._play_ingredient(table.state, acting_side, 0, "prep")
		_expect(played, label + ": real Jellyfish play failed.")
		if acting_side == "player":
			_expect(not table.state.get("pending_choice", {}).is_empty(), label + ": Jellyfish did not request its real target choice.")
			table.service.choose_effect_target(table.state, int(target.instance_id))
	var events: Array = table.state.animation_events
	var returns: Array[Dictionary] = []
	for event in events:
		if String(event.get("from", "")) in ["prep", "plated"] and String(event.get("to", "")) == "hand":
			returns.append(event)
	_expect(returns.size() == zones.size(), label + ": real Jellyfish did not queue each board return.")
	_expect(table.state[side].hand.size() == 2 + zones.size(), label + ": authoritative hand did not resolve immediately.")
	_expect(table.state[side].prep.is_empty() and table.state[side].plated.is_empty(), label + ": authoritative board retained returned cards.")
	_start_drain()
	var deadline := Time.get_ticks_msec() + 20000
	var previous_start_count := 0
	var flight_samples: Dictionary = {}
	var before_samples := 0
	var capture_taken := false
	var landing_capture_taken := false
	while not drain_done and Time.get_ticks_msec() < deadline:
		for event in returns:
			var id := int(event.source_instance_id)
			var sample := _return_sample(id)
			if sample.is_empty():
				var source: Node3D = origins[id].node if is_instance_valid(origins[id].node) else null
				_expect(source != null and source.is_visible_in_tree(), label + ": card disappeared before its return started.")
				if source != null:
					_expect(source.global_transform.is_equal_approx(origins[id].transform), label + ": waiting card jumped from its original board pose.")
				var pending: Node3D = table._hand_card_node(side, int(event.hand_index), RETURN_CARD)
				_expect(pending == null or not pending.is_visible_in_tree(), label + ": destination appeared before the board card left.")
				before_samples += 1
				continue
			var elapsed := float(Time.get_ticks_msec() - int(sample.at)) / 1000.0
			if bool(sample.event.get("board_return_presented", false)) or elapsed >= float(sample.duration) or reduced:
				continue
			var moving := _visible_return_node(sample)
			_expect(moving != null, label + ": card vanished during board-to-hand travel.")
			if moving != null:
				var distance_from_source: float = moving.global_position.distance_to(origins[id].transform.origin)
				if distance_from_source > 0.04:
					flight_samples[id] = int(flight_samples.get(id, 0)) + 1
			if side == "opponent" and elapsed < float(sample.duration) * 0.80:
				_expect(table.rival_held_cards.held_count == int(sample.held_before), label + ": live hand count increased before the returning card arrived.")
			if save_captures and not capture_taken and zones.size() == 1 and elapsed > float(sample.duration) * 0.35:
				capture_taken = true
				await _capture(side + "_" + zones[0] + "_travelling")
			if save_captures and not landing_capture_taken and zones.size() == 1 and elapsed > float(sample.duration) * 0.88:
				landing_capture_taken = true
				await _capture(side + "_" + zones[0] + "_landing")
		if table.return_starts.size() > previous_start_count:
			for index in range(previous_start_count, table.return_starts.size()):
				var sample: Dictionary = table.return_starts[index]
				var id := int(sample.event.source_instance_id)
				_expect(bool(sample.source_visible), label + ": transfer began without its visible board card.")
				_expect(sample.source_transform.is_equal_approx(origins[id].transform), label + ": transfer reconstructed a different source pose.")
				if reduced:
					_expect(float(sample.duration) <= 0.12, label + ": Reduced Motion retained a full travel animation.")
				else:
					_expect(sample.launch_transform.is_equal_approx(origins[id].transform), label + ": card jumped when board-to-hand motion started.")
			previous_start_count = table.return_starts.size()
		await process_frame
	_expect(drain_done, label + ": queue did not finish.")
	_expect(table.return_starts.size() == zones.size(), label + ": missing or repeated return flight.")
	_expect(before_samples > 0 and table.activation_starts == zones.size(), label + ": fixture did not cover source visibility during Jellyfish's play and activation.")
	if not reduced:
		for target in targets:
			_expect(int(flight_samples.get(int(target.instance_id), 0)) > 0, label + ": returned card never visibly travelled away from its board slot.")
	await _settle()
	_expect(table.state[side].hand.count(RETURN_CARD) == 2 + zones.size(), label + ": duplicate card copies were lost or created.")
	_expect(table.state[side].discard.is_empty(), label + ": bounced cards incorrectly entered discard.")
	_expect(table.animation_ghost_nodes.is_empty(), label + ": return left a stale board ghost.")
	if side == "opponent":
		_expect(table.rival_held_cards.held_count == 2 + zones.size(), label + ": settled live rival hand count is wrong.")
		_expect(table.rival_hand_label.text == "%d cards in hand" % (2 + zones.size()), label + ": rival hand label did not update on arrival.")
	else:
		for index in range(2 + zones.size()):
			var card: Node3D = table._hand_card_node(side, index, RETURN_CARD)
			_expect(card != null and card.is_visible_in_tree(), label + ": one real returned/duplicate hand card is missing.")
	if save_captures and zones.size() == 1 and not reduced:
		await _capture(side + "_" + zones[0] + "_arrived")


func _return_sample(id: int) -> Dictionary:
	for sample in table.return_starts:
		if int(sample.event.source_instance_id) == id:
			return sample
	return {}


func _visible_return_node(sample: Dictionary) -> Node3D:
	for key in ["source", "destination"]:
		var card = sample.get(key)
		if is_instance_valid(card) and card.is_visible_in_tree() and not card.is_queued_for_deletion():
			return card as Node3D
	return null


func _test_token_return() -> void:
	_reset(false)
	var token := _unit("player", "prep", 0)
	token.is_token = true
	table.state.opponent.hand = ["sweet_jellyfish"]
	table._render_match()
	var evaporation_before := int(table.token_evaporation_animation_count)
	table.service._play_ingredient(table.state, "opponent", 0, "prep")
	_expect(table.state.player.hand.is_empty(), "Returned token entered a hand instead of evaporating.")
	_expect(table.state.animation_events.any(func(event: Dictionary) -> bool: return String(event.type) == "evaporate"), "Jellyfish stopped generating token evaporation.")
	_start_drain()
	var deadline := Time.get_ticks_msec() + 10000
	while not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(drain_done and table.token_evaporation_animation_count == evaporation_before + 1, "Returned token did not complete its existing evaporation cue.")
	_expect(table.return_starts.is_empty() and table.state.player.hand.is_empty(), "Token evaporation created a board-to-hand flight or card.")


func _start_drain() -> void:
	drain_done = false
	table.animation_busy = true
	await table._drain_animation_event_queue()
	table.animation_busy = false
	table._render_match()
	drain_done = true


func _settle() -> void:
	for frame in 3:
		await process_frame
		if save_captures:
			RenderingServer.force_draw(false)


func _capture(name: String) -> void:
	if not save_captures:
		return
	RenderingServer.force_draw(false)
	var capture := root.get_texture().get_image()
	_expect(capture != null and capture.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(name + ".png"))) == OK, "Could not save " + name)


func _expect(condition: bool, message: String) -> void:
	if not condition and not failures.has(message):
		failures.append(message)
