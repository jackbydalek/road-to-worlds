extends SceneTree

## Blocked Prep damage must identify the protector and finish before later attacks.
## Run with a native renderer and -- --capture for settled middle-of-cue images.
class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var protection_starts: Array[Dictionary] = []
	var attack_starts: Array[Dictionary] = []
	var camera_cues := 0
	var floating_numbers := 0

	func _begin_match_pacing() -> void:
		pass

	func _start_damage_prevented_event_animation(event: Dictionary) -> float:
		var camera_before := camera_cues
		var numbers_before := floating_numbers
		var duration := super._start_damage_prevented_event_animation(event)
		protection_starts.append({
			"event": event.duplicate(true), "at": Time.get_ticks_msec(),
			"duration": duration,
			"cue": effect_layer.get_node_or_null("PrepProtectionVfx"),
			"camera_before": camera_before, "numbers_before": numbers_before,
		})
		return duration

	func _animate_attack_motion(attacker_instance_id: int, target_instance_id: int, target_kind: String = "unit") -> void:
		attack_starts.append({
			"instance_id": attacker_instance_id, "at": Time.get_ticks_msec(),
			"protection_active": effect_layer.get_node_or_null("PrepProtectionVfx") != null,
		})
		await super._animate_attack_motion(attacker_instance_id, target_instance_id, target_kind)

	func _start_camera_pulse(side: String, fov_amount: float = 2.0) -> void:
		camera_cues += 1
		super._start_camera_pulse(side, fov_amount)

	func _start_camera_impact(side: String, strength: float) -> void:
		camera_cues += 1
		super._start_camera_impact(side, strength)

	func _spawn_floating_number(world_position: Vector3, text_value: String, color: Color, duration: float = 0.83, travel: bool = true) -> Tween:
		floating_numbers += 1
		return super._spawn_floating_number(world_position, text_value, color, duration, travel)


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PROTECTOR := "fresh_salad_shield_skunk"
const ATTACKER := "spicy_sriracharrow"
const TARGET := "spicy_hot_honey_bee"
const OUTPUT_DIR := "res://outputs/prep_protection_2026-09-11"
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
	table.configure_battle_preferences("fast", 1.0, false, false)
	root.add_child(table)
	await _settle()
	for reduced in [false, true]:
		for protected_side in ["player", "opponent"]:
			await _test_attack_protection(protected_side, reduced)
	await _test_missing_protector()
	table.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("Prep protection animation smoke test passed: %d cases; real Sriracharrow choices, both seats, cue attribution/order, unchanged HP, Reduced Motion, and missing-protector fallback." % cases)
	quit(0 if failures.is_empty() else 1)


func _reset(reduced: bool) -> void:
	table.state = table.service.start_game("spicy_test_kitchen", "fresh_test_kitchen", 1416, "player", true, "easy")
	table.state.turn = 3
	table.state.phase = "player_main"
	table.state.game_over = false
	for side in ["player", "opponent"]:
		table.state[side].turns_started = 2
		table.state[side].life = 40
		table.state[side].max_life = 40
		table.state[side].prep = []
		table.state[side].plated = []
		table.state[side].hand = []
		table.state[side].discard = []
		table.state[side].environment = ""
	table.selected_ref = {}
	table.animation_busy = false
	table.production_match = true
	table.configure_battle_preferences("fast", 1.0, reduced, false)
	table.protection_starts.clear()
	table.attack_starts.clear()
	table.camera_cues = 0
	table.floating_numbers = 0
	table.service.clear_animation_events(table.state)


func _unit(side: String, card_id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	table.state[side][zone].append(unit)
	return unit


func _test_attack_protection(protected_side: String, reduced: bool) -> void:
	_reset(reduced)
	var label := protected_side + (" Reduced Motion" if reduced else " normal")
	var acting_side := "opponent" if protected_side == "player" else "player"
	var protector := _unit(protected_side, PROTECTOR, "prep", 0)
	var target := _unit(protected_side, TARGET, "prep", 1)
	var attacker := _unit(acting_side, ATTACKER, "plated", 0)
	var later_attacker := _unit(acting_side, TARGET, "plated", 1)
	var original_health := int(target.health)
	table._render_match()
	await _settle()
	if acting_side == "player":
		table.service.select_attacker(table.state, int(attacker.instance_id))
		table.service.attack(table.state, -1)
		_expect(not table.state.pending_choice.is_empty() and String(table.state.pending_choice.effect.type) == "damage_prep_unit", label + ": Sriracharrow did not open its real Prep choice.")
		_expect(_events_of_type("damage_prevented").is_empty(), label + ": block appeared before choosing its target.")
		table._render_match()
		_expect(table.service.choice_target_ids(table.state).has(int(target.instance_id)), label + ": protected card is missing from the legal choice.")
		table.service.choose_effect_target(table.state, int(target.instance_id))
		table.service.select_attacker(table.state, int(later_attacker.instance_id))
		table.service.attack(table.state, -1)
	else:
		# Sriracharrow's real AI target rule chooses the lower-HP Bee beside the
		# three-HP protector, then queues its authored post-combat effect.
		table.state.phase = "opponent_turn"
		table.service._ai_attack_with_unit(table.state, attacker)
		table.service._ai_attack_with_unit(table.state, later_attacker)
	var blocks := _events_of_type("damage_prevented")
	_expect(blocks.size() == 1, label + ": expected exactly one blocked Prep hit.")
	_expect(int(target.health) == original_health, label + ": blocked effect changed authoritative target HP.")
	if blocks.size() != 1:
		return
	var blocked: Dictionary = blocks[0]
	_check_event(blocked, protector, target, attacker, protected_side, acting_side, label)
	var first_attack := _attack_event_index(int(attacker.instance_id))
	var later_attack := _attack_event_index(int(later_attacker.instance_id))
	var blocked_index: int = table.state.animation_events.find(blocked)
	_expect(first_attack >= 0 and first_attack < blocked_index and blocked_index < later_attack, label + ": block disrupted Sriracharrow's combat-first event order.")
	_start_drain()
	await _wait_for_protection(label)
	await _inspect_middle_of_cue(target, original_health, label, protected_side + ("_reduced" if reduced else "_normal"))
	await _wait_for_drain(label)
	_expect(table.protection_starts.size() == 1, label + ": block cue was skipped or duplicated.")
	_expect(table.attack_starts.size() == 2, label + ": originating or later attack did not animate.")
	if table.attack_starts.size() == 2 and table.protection_starts.size() == 1:
		var cue: Dictionary = table.protection_starts[0]
		_expect(int(table.attack_starts[0].at) < int(cue.at), label + ": the block preceded its originating combat.")
		_expect(int(table.attack_starts[1].at) >= int(cue.at) + int(float(cue.duration) * 1000.0) - 25, label + ": next attack began before the block cue finished.")
		_expect(not bool(table.attack_starts[1].protection_active), label + ": next attack overlapped an uncleared block cue.")
	_expect(int(target.health) == original_health, label + ": presentation changed protected target HP.")
	_expect(table.effect_layer.get_node_or_null("PrepProtectionVfx") == null, label + ": protection graphic did not clean up.")
	cases += 1


func _test_missing_protector() -> void:
	_reset(false)
	var protector := _unit("player", PROTECTOR, "prep", 0)
	var target := _unit("player", TARGET, "prep", 1)
	var attacker := _unit("opponent", ATTACKER, "plated", 0)
	var original_health := int(target.health)
	table.service._resolve_effects(table.state, "opponent", [{"type": "damage_prep_unit", "amount": 1}], attacker, int(target.instance_id))
	var blocks := _events_of_type("damage_prevented")
	_expect(blocks.size() == 1, "Fallback: real opposing effect did not create a block.")
	if blocks.size() != 1:
		return
	# A later resolved change can remove the source from the current board;
	# the original event must still identify its protector and recorded slot.
	table.state.player.prep.erase(protector)
	table._render_match()
	_expect(table._card_node_for_instance(int(protector.instance_id)) == null, "Fallback fixture retained the protector's live node.")
	_start_drain()
	await _wait_for_protection("Missing protector")
	await _inspect_middle_of_cue(target, original_health, "Missing protector", "missing_protector")
	await _wait_for_drain("Missing protector")
	_expect(table.effect_layer.get_node_or_null("PrepProtectionVfx") == null, "Fallback block graphic did not clean up.")
	cases += 1


func _check_event(event: Dictionary, protector: Dictionary, target: Dictionary, attacker: Dictionary, protected_side: String, acting_side: String, label: String) -> void:
	_expect(String(event.get("protector_side", "")) == protected_side and int(event.get("protector_instance_id", -1)) == int(protector.instance_id), label + ": wrong protecting seat or instance.")
	_expect(String(event.get("protector_card_id", "")) == PROTECTOR and String(event.get("protector_zone", "")) == "prep" and int(event.get("protector_table_slot", -1)) == 0, label + ": missing protector identity/position snapshot.")
	_expect(String(event.get("target_side", "")) == protected_side and int(event.get("target_instance_id", -1)) == int(target.instance_id), label + ": wrong protected target.")
	_expect(String(event.get("target_card_id", "")) == TARGET and String(event.get("target_zone", "")) == "prep" and int(event.get("target_table_slot", -1)) == 1, label + ": missing target identity/position snapshot.")
	_expect(String(event.get("source_side", "")) == acting_side and int(event.get("source_instance_id", -1)) == int(attacker.instance_id), label + ": incoming effect lost its original source.")
	_expect(int(event.get("amount", 0)) == 1, label + ": prevented amount is incorrect.")
	for damage in _events_of_type("damage"):
		_expect(int(damage.get("target_instance_id", -1)) != int(target.instance_id), label + ": prevented hit also queued target damage.")


func _inspect_middle_of_cue(target: Dictionary, original_health: int, label: String, capture_name: String) -> void:
	if table.protection_starts.is_empty():
		return
	var sample: Dictionary = table.protection_starts[0]
	var sample_at := int(sample.at) + 250
	while Time.get_ticks_msec() < sample_at and not drain_done:
		await process_frame
	var cue := sample.cue as Node2D
	_expect(is_instance_valid(cue) and cue.is_visible_in_tree(), label + ": block graphic is not visible in the middle of its cue.")
	if not is_instance_valid(cue):
		return
	_expect(cue.modulate.a > 0.75, label + ": block graphic is still too faint in its readable middle phase.")
	var source_ring := cue.find_child("PrepProtectionSourceRing", true, false) as CanvasItem
	var link := cue.find_child("PrepProtectionLink", true, false) as Line2D
	var shield := cue.find_child("PrepProtectionShield", true, false) as CanvasItem
	var copy := cue.find_child("PrepProtectionLabel", true, false) as Label
	_expect(source_ring != null and source_ring.is_visible_in_tree(), label + ": protector ring is missing.")
	_expect(link != null and link.is_visible_in_tree() and link.points.size() >= 2, label + ": source-to-target link is missing.")
	_expect(shield != null and shield.is_visible_in_tree(), label + ": target shield is missing.")
	_expect(copy != null and copy.is_visible_in_tree() and copy.text.to_upper().contains("BLOCKED") and copy.text.to_lower().contains("iceberg skunkuce"), label + ": readable block/protector attribution is missing.")
	_expect(int(target.health) == original_health, label + ": HP changed while protected.")
	var target_node := table._card_node_for_instance(int(target.instance_id)) as Node3D
	var stats := target_node.get_node_or_null("Stats") as Label3D if target_node != null else null
	_expect(stats != null and stats.text == "%d / %d" % [int(target.attack), original_health], label + ": printed HP suggests damage was taken.")
	_expect(table.camera_cues == int(sample.camera_before), label + ": protection caused a damage camera cue.")
	_expect(table.floating_numbers == int(sample.numbers_before), label + ": protection spawned a damage number.")
	if String(sample.event.get("source_side", "")) == "player":
		for card_node in table.interactive_cards:
			for marker_name in ["ChoiceBadge", "CardChoiceAura", "CardChoiceSelectedAura"]:
				var marker := card_node.get_node_or_null(NodePath(marker_name)) as Node3D
				_expect(marker == null or not marker.is_visible_in_tree(), label + ": resolved target choice retained " + marker_name + " during its block cue.")
		_expect(not table.cancel_choice_button.is_visible_in_tree() and not table.confirm_choice_button.is_visible_in_tree(), label + ": resolved target choice retained bottom choice controls.")
	_expect(float(sample.duration) >= (0.45 if table.reduced_motion else 0.8), label + ": block cue is too brief to read.")
	if table.reduced_motion:
		_expect(float(sample.duration) < 0.8, label + ": Reduced Motion kept the longer normal cue.")
	await _capture(capture_name)


func _events_of_type(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in table.state.animation_events:
		if String(event.get("type", "")) == kind:
			result.append(event)
	return result


func _attack_event_index(instance_id: int) -> int:
	for index in table.state.animation_events.size():
		var event: Dictionary = table.state.animation_events[index]
		if String(event.type) == "attack" and int(event.get("source_instance_id", -1)) == instance_id:
			return index
	return -1


func _start_drain() -> void:
	drain_done = false
	table.animation_busy = true
	await table._drain_animation_event_queue()
	table.animation_busy = false
	table._render_match()
	drain_done = true


func _wait_for_protection(label: String) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while table.protection_starts.is_empty() and not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not table.protection_starts.is_empty(), label + ": timed out waiting for the protection cue.")


func _wait_for_drain(label: String) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(drain_done, label + ": blocked-hit event queue did not finish.")
	# The final attack's unrelated floating chef damage can outlive its event
	# timer. Let it retire before resetting into the next isolated scenario.
	await create_timer(0.45).timeout
	await _settle()


func _settle() -> void:
	for frame in 3:
		await process_frame
		if save_captures:
			RenderingServer.force_draw(false)


func _capture(name: String) -> void:
	if not save_captures:
		return
	await _settle()
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	_expect(image != null and image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(name + ".png"))) == OK, "Could not save " + name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
