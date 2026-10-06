extends SceneTree

## Real multi-group summons must wait for their own play and source activation.
## Run natively with -- --capture for the source-cue and settled-board images.
class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var observing := false
	var expected_plays: Dictionary = {}
	var started_plays: Dictionary = {}
	var play_starts: Array[Dictionary] = []
	var timeline: Array[Dictionary] = []
	var observation_failures: Array[String] = []
	var render_samples := 0
	var future_samples := 0
	var choice_hidden_samples := 0

	func _begin_match_pacing() -> void:
		pass

	func _render_match() -> void:
		super._render_match()
		if observing:
			render_samples += 1
			observe_presentation("immediate render")

	func _start_play_event_animation(event: Dictionary, play_origin_pose: Dictionary) -> float:
		var id := int(event.get("instance_id", -1))
		var destination := _card_node_for_instance(id)
		var sample := {
			"event": event.duplicate(true), "at": Time.get_ticks_msec(),
			"destination": destination.global_position if destination != null else Vector3.ZERO,
		}
		# The current card may be made visible synchronously by the super call.
		# Every later card remains subject to the waiting-instance checks.
		started_plays[id] = true
		timeline.append({"kind": "play", "instance_id": id})
		var duration := super._start_play_event_animation(event, play_origin_pose)
		sample.duration = duration
		sample.launch = destination.global_position if is_instance_valid(destination) else Vector3.ZERO
		sample.visible = is_instance_valid(destination) and destination.is_visible_in_tree()
		play_starts.append(sample)
		observe_presentation("play launch")
		return duration

	func _show_field_activation_indicator(event: Dictionary) -> void:
		var id := int(event.get("source_instance_id", -1))
		timeline.append({"kind": "activation_start", "instance_id": id})
		observe_presentation("activation start")
		await super._show_field_activation_indicator(event)
		timeline.append({"kind": "activation_end", "instance_id": id})
		observe_presentation("activation end")

	func observe_presentation(context: String) -> void:
		if not observing:
			return
		for id in expected_plays:
			if started_plays.has(id):
				continue
			future_samples += 1
			var node := _card_node_for_instance(int(id))
			if node != null and node.is_visible_in_tree():
				_note("%s: %s became visible before its own play started." % [context, expected_plays[id].card_id])
		if animation_busy and not state.get("pending_search", {}).is_empty():
			choice_hidden_samples += 1
			if is_instance_valid(card_tray_overlay) and card_tray_overlay.is_visible_in_tree():
				_note(context + ": deck choices appeared before the source animation queue finished.")

	func _note(message: String) -> void:
		if not observation_failures.has(message):
			observation_failures.append(message)


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_DIR := "res://outputs/summon_effect_timing_2026-09-11"
const CAPYBARA := "fresh_crisp_capybara"
const SALADMANDER := "fresh_saladmander"
const SEARCHED := "fresh_sprout_squirrel"
const TOKEN := "token_fresh_ingredient"
var failures: Array[String] = []
var table
var drain_done := true
var save_captures := false
var cases := 0


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
	for reduced in [false, true]:
		for side in ["player", "opponent"]:
			await _test_saladmander(side, reduced)
			await _test_capybara(side, reduced)
	await _test_search_edges()
	table.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Summon effect timing: %d real Saladmander/Capybara cases, player/rival cross-group visibility, source cues, deck/token origins, search gating/skip/capacity and Reduced Motion; %d failures." % [cases, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _reset(reduced: bool) -> void:
	table.observing = false
	table.state = table.service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 1271, "player", true, "easy")
	table.state.turn = 3
	table.state.phase = "player_main"
	table.state.game_over = false
	for side in ["player", "opponent"]:
		table.state[side].turns_started = 2
		table.state[side].prep = []
		table.state[side].plated = []
		table.state[side].hand = []
		table.state[side].deck = []
		table.state[side].discard = []
		table.state[side].environment = ""
	table.pending_hand_play_index = -1
	table.pending_move_instance_id = -1
	table.manual_discard_tray_side = ""
	table.selected_ref = {}
	table.animation_busy = false
	table.production_match = true
	table.configure_battle_preferences("fast", 1.0, reduced, false)
	table.service.clear_animation_events(table.state)


func _unit(side: String, card_id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	unit.recipe_ready_on_turn = 0
	table.state[side][zone].append(unit)
	return unit


func _test_saladmander(side: String, reduced: bool) -> void:
	_reset(reduced)
	var label := "%s Saladmander%s" % [side, " Reduced Motion" if reduced else ""]
	var ingredient := _unit(side, "fresh_salad_shield_skunk", "prep", 1)
	table.state[side].hand = [SALADMANDER]
	table._render_match()
	await _settle()
	var origin: Dictionary = table._hand_card_pose(0) if side == "player" else {}
	if side == "player":
		table.service.begin_meal_play(table.state, 0, "plated")
		table.service.toggle_ingredient_selection(table.state, int(ingredient.instance_id))
		_expect(table.service.meal_selection_is_ready(table.state), label + ": real recipe selection was not ready.")
		table.service.confirm_meal_play(table.state)
	else:
		_expect(table.service._serve_meal(table.state, side, 0, [int(ingredient.instance_id)], "plated"), label + ": rival's real Meal play failed.")
	_expect(table.state[side].plated.size() == 1 and table.state[side].plated[0].card_id == SALADMANDER, label + ": authoritative Meal did not resolve immediately.")
	_expect(table.state[side].prep.size() == 3 and table.state[side].prep.all(func(unit: Dictionary) -> bool: return unit.card_id == TOKEN), label + ": authoritative Prep did not immediately contain all three tokens.")
	var events: Array = table.state.animation_events.duplicate(true)
	_expect(_event_types(events) == ["sacrifice", "play", "card_text_activation", "play", "play", "play"], label + ": fixture did not produce the real sacrifice/source/activation/token sequence.")
	_expect(_count_plays(events, "token") == 3, label + ": result events lost their token origin.")
	await _observe_drain(events, origin, label, side + "_saladmander" if not reduced else "")
	_expect(table.state[side].prep.size() == 3 and table.state[side].plated.size() == 1, label + ": presentation changed resolved gameplay.")
	cases += 1


func _test_capybara(side: String, reduced: bool) -> void:
	_reset(reduced)
	var label := "%s Capybara%s" % [side, " Reduced Motion" if reduced else ""]
	table.state[side].hand = [CAPYBARA]
	# Fetching an on-play Ingredient exercises another source cue followed by a
	# further token group. It must not inherit Capybara's physical hand origin.
	table.state[side].deck = [SEARCHED]
	table._render_match()
	await _settle()
	var origin: Dictionary = table._hand_card_pose(0) if side == "player" else {}
	if side == "player":
		table.service.play_card(table.state, 0, "prep")
	else:
		_expect(table.service._play_ingredient(table.state, side, 0, "prep"), label + ": rival's real Ingredient play failed.")
	var events: Array = table.state.animation_events.duplicate(true)
	if side == "player":
		_expect(table.state[side].prep.size() == 1 and not table.state.pending_search.is_empty(), label + ": source play did not immediately resolve its deck choice.")
		_expect(_event_types(events) == ["play", "card_text_activation"], label + ": source emitted an unexpected premature result event.")
		await _observe_drain(events, origin, label + " source", side + "_capybara_source" if not reduced else "")
		_expect(table.choice_hidden_samples > 0, label + ": deck-tray gating was not sampled during source presentation.")
		_expect(table.card_tray_overlay.is_visible_in_tree(), label + ": completed source cue did not reveal its deck choice.")
		_expect(table.card_tray_selection_status.text.contains("play it to Prep"), label + ": deck-choice subtitle advertised the wrong destination.")
		table.observing = false
		table.service.select_search_card(table.state, SEARCHED)
		events = table.state.animation_events.duplicate(true)
		_expect(_event_types(events) == ["play", "card_text_activation", "play"], label + ": fetched on-play Ingredient did not queue its own activation and token.")
	else:
		_expect(table.state.pending_search.is_empty(), label + ": rival incorrectly created a player choice tray.")
		_expect(_event_types(events) == ["play", "card_text_activation", "play", "card_text_activation", "play"], label + ": rival source/deck-result/nested-token event order changed.")
	_expect(table.state[side].prep.size() == 3 and table.state[side].deck.is_empty() and table.state[side].hand.is_empty(), label + ": deck result and token must resolve immediately without taking an extra hand card.")
	_expect(_count_plays(events, "deck") == 1 and _count_plays(events, "token") == 1, label + ": result provenance must distinguish deck and token origins.")
	# Retaining the original supplied pose also catches accidental application of
	# one hand origin to every subsequent field result in the event queue.
	await _observe_drain(events, origin, label + " results", side + "_capybara_results" if not reduced else "")
	_expect(table.state.pending_search.is_empty() and not table.card_tray_overlay.is_visible_in_tree(), label + ": resolved deck choice remained open.")
	_expect(table.state[side].prep.size() == 3 and table.state[side].hand.is_empty(), label + ": presentation altered authoritative summons/hand count.")
	cases += 1


func _test_search_edges() -> void:
	for mode in ["no candidates", "full Prep", "skip"]:
		_reset(true)
		var label := "Capybara " + String(mode)
		table.state.player.hand = [CAPYBARA]
		table.state.player.deck = [CAPYBARA] if mode == "no candidates" else [SEARCHED]
		if mode == "full Prep":
			_unit("player", "fresh_salad_shield_skunk", "prep", 0)
			_unit("player", "fresh_salad_shield_skunk", "prep", 1)
		table._render_match()
		await _settle()
		var origin: Dictionary = table._hand_card_pose(0)
		table.service.play_card(table.state, 0, "prep")
		var events: Array = table.state.animation_events.duplicate(true)
		_expect(_event_types(events) == ["play", "card_text_activation"], label + ": search edge created an unsolicited result play.")
		_expect(table.state.pending_search.is_empty() == (mode != "skip"), label + ": search eligibility changed.")
		await _observe_drain(events, origin, label, "")
		if mode == "skip":
			_expect(table.card_tray_overlay.is_visible_in_tree(), label + ": available search was not shown after its source cue.")
			table.service.skip_search(table.state)
			table._render_match()
			_expect(table.state.animation_events.is_empty(), label + ": skipping invented a summon animation.")
		_expect(not table.card_tray_overlay.is_visible_in_tree() and table.state.pending_search.is_empty(), label + ": stale search controls remained visible.")
		_expect(table.state.player.prep.size() == (3 if mode == "full Prep" else 1) and table.state.player.deck.size() == 1, label + ": search edge altered the resolved board/deck.")
		cases += 1


func _observe_drain(events: Array, origin: Dictionary, label: String, capture_name: String) -> void:
	table.expected_plays.clear()
	table.started_plays.clear()
	table.play_starts.clear()
	table.timeline.clear()
	table.observation_failures.clear()
	table.render_samples = 0
	table.future_samples = 0
	table.choice_hidden_samples = 0
	for event in events:
		if String(event.type) == "play" and int(event.get("instance_id", -1)) >= 0:
			table.expected_plays[int(event.instance_id)] = event
	table.observing = true
	_start_drain(origin)
	var deadline := Time.get_ticks_msec() + 20000
	var captured := false
	while not drain_done and Time.get_ticks_msec() < deadline:
		table.observe_presentation("frame")
		if save_captures and capture_name != "" and not captured and _activation_is_running():
			captured = true
			await _capture(capture_name + "_source_cue")
		await process_frame
	_expect(drain_done, label + ": animation queue did not finish.")
	for failure in table.observation_failures:
		_expect(false, label + ": " + failure)
	_expect(table.render_samples > 0 and table.future_samples > 0, label + ": immediate-render/future-card observations were not exercised.")
	_expect(table.play_starts.size() == table.expected_plays.size(), label + ": a field play animation was skipped or duplicated.")
	_check_timeline(events, label)
	for sample in table.play_starts:
		var event: Dictionary = sample.event
		_expect(bool(sample.visible), label + ": play did not reveal its own card at launch.")
		var from := String(event.get("from", ""))
		if from == "deck":
			var deck: Vector3 = table.AUX_ZONE_POSITIONS[String(event.side) + "_deck"]
			_expect(_same_board_point(sample.launch, deck), label + ": searched Ingredient launched from somewhere other than its own deck.")
		elif from == "token":
			_expect(_same_board_point(sample.launch, sample.destination), label + ": generated token launched from a hand/deck instead of its destination slot.")
	for id in table.expected_plays:
		var node: Node3D = table._card_node_for_instance(int(id))
		_expect(node != null and node.is_visible_in_tree(), label + ": completed field play is missing from the board.")
	table.observing = false
	await _settle()
	if save_captures and capture_name != "":
		await _capture(capture_name + "_settled")


func _check_timeline(events: Array, label: String) -> void:
	var expected: Array[Dictionary] = []
	for event in events:
		if String(event.type) == "play":
			expected.append({"kind": "play", "instance_id": int(event.instance_id)})
		elif String(event.type) == "card_text_activation":
			expected.append({"kind": "activation_start", "instance_id": int(event.source_instance_id)})
			expected.append({"kind": "activation_end", "instance_id": int(event.source_instance_id)})
	_expect(table.timeline == expected, label + ": result play began before its prior source activation finished, or source cues were skipped/reordered.")


func _activation_is_running() -> bool:
	return not table.timeline.is_empty() and String(table.timeline.back().kind) == "activation_start"


func _same_board_point(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) < 0.04


func _event_types(events: Array) -> Array[String]:
	var types: Array[String] = []
	for event in events:
		types.append(String(event.type))
	return types


func _count_plays(events: Array, origin: String) -> int:
	var count := 0
	for event in events:
		if String(event.type) == "play" and String(event.get("from", "")) == origin:
			count += 1
	return count


func _start_drain(origin: Dictionary) -> void:
	drain_done = false
	table.animation_busy = true
	await table._drain_animation_event_queue(origin)
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
