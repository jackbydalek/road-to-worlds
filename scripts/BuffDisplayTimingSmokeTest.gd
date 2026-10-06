extends SceneTree

## Real combat events must show their buff cue before their live stat increase.
## Add -- --capture with the native renderer to save the Polar Bear sequence.
class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var buff_starts: Array[Dictionary] = []
	var activation_starts := 0
	var attack_starts: Array[Dictionary] = []

	func _begin_match_pacing() -> void:
		pass

	func _start_buff_event_animation(event: Dictionary) -> float:
		var target := _card_node_for_instance(int(event.get("target_instance_id", -1)))
		var stats := target.get_node_or_null("Stats") as Label3D if target != null else null
		var duration := super._start_buff_event_animation(event)
		buff_starts.append({
			"stats": stats.text if stats != null else "missing",
			"at": Time.get_ticks_msec(),
			"duration": duration,
			"instance_id": int(event.get("target_instance_id", -1)),
		})
		return duration

	func _show_field_activation_indicator(event: Dictionary) -> void:
		activation_starts += 1
		await super._show_field_activation_indicator(event)

	func _animate_attack_motion(attacker_instance_id: int, target_instance_id: int, target_kind: String = "unit") -> void:
		var source := _card_node_for_instance(attacker_instance_id)
		var stats := source.get_node_or_null("Stats") as Label3D if source != null else null
		attack_starts.append({"instance_id": attacker_instance_id, "stats": stats.text if stats != null else "missing"})
		await super._animate_attack_motion(attacker_instance_id, target_instance_id, target_kind)


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_DIR := "res://outputs/buff_display_timing_2026-09-11"
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
	root.add_child(table)
	await _settle()
	await _test_polar_move(false)
	await _test_stacked_buffs()
	await _test_attack_buff_then_retaliation()
	await _test_activated_buff()
	await _test_on_play_buff()
	await _test_polar_move(true)
	table.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("Buff display timing smoke test passed: real Polar move, stacked buffs, Bison buff then retaliation, activated/on-play buffs, left inspection, and Reduced Motion.")
	quit(0 if failures.is_empty() else 1)


func _reset(reduced: bool = false) -> void:
	table.state = table.service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 628, "player", true, "easy")
	table.state.turn = 3
	table.state.phase = "player_main"
	table.state.game_over = false
	for side in ["player", "opponent"]:
		table.state[side].turns_started = 2
		table.state[side].prep = []
		table.state[side].plated = []
		table.state[side].hand = []
		table.state[side].environment = ""
	table.selected_ref = {}
	table.reduced_motion = reduced
	table.animation_busy = false
	table.production_match = true
	table.buff_starts.clear()
	table.activation_starts = 0
	table.attack_starts.clear()
	table.service.clear_animation_events(table.state)


func _unit(card_id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card(card_id), zone, "player")
	unit.table_slot = slot
	unit.ready = true
	table.state.player[zone].append(unit)
	return unit


func _test_polar_move(reduced: bool) -> void:
	_reset(reduced)
	var bear := _unit("hearty_polar_pot_pie_bear", "prep", 0)
	var id := int(bear.instance_id)
	table._render_match()
	table._inspect_card(table._card_node_for_instance(id))
	await _settle()
	_expect_stats(id, 3, 6, "Polar before moving")
	if not reduced:
		await _capture("polar_before")
	table.service.move_unit(table.state, id, "plated", 0)
	_expect(int(bear.attack) == 5 and int(bear.health) == 8, "Polar's authoritative combat result must resolve immediately.")
	_start_drain()
	_expect_stats(id, 3, 6, "Polar destination render before buff")
	await _wait_for_buff(1)
	_expect(table.buff_starts.size() == 1, "Polar's real move did not reach its buff animation.")
	if not table.buff_starts.is_empty():
		_expect(table.buff_starts[0].stats == "3 / 6", "Polar displayed its buff at cue start.")
		await _sample_active_buff(0, id, 3, 6, "Polar during its buff")
		if not reduced:
			await _capture("polar_buff_before_stats")
	await _wait_for_drain()
	_expect_stats(id, 5, 8, "Polar after buff finishes")
	_expect(table.inspector_card_face.get_global_rect().end.x < table.size.x * 0.5, "The updated buff preview left the left side of battle.")
	if not reduced:
		await _capture("polar_after")
	else:
		_expect(table.buff_starts.is_empty() or float(table.buff_starts[0].duration) < 0.84, "Reduced Motion kept the full normal-motion buff delay.")


func _test_stacked_buffs() -> void:
	_reset()
	var bear := _unit("hearty_polar_pot_pie_bear", "plated", 0)
	var id := int(bear.instance_id)
	table._render_match()
	table._inspect_card(table._card_node_for_instance(id))
	# Independent action groups on one target must expose each resolved increment,
	# even though the engine has already applied both before presentation starts.
	for amount in [1, 2]:
		var previous := int(table.service._with_animation_group(table.state, table.service._next_animation_group(table.state)))
		table.service._resolve_effects(table.state, "player", [{"type": "buff_self", "attack": amount, "health": amount}], bear)
		table.service._restore_animation_group(table.state, previous)
	_expect(int(bear.attack) == 6 and int(bear.health) == 9, "Stacked fixture did not resolve both gameplay buffs.")
	_start_drain()
	await _wait_for_buff(1)
	await _sample_active_buff(0, id, 3, 6, "First stacked buff")
	await _wait_for_buff(2)
	_expect(table.buff_starts.size() == 2, "Both stacked buff events must animate.")
	if table.buff_starts.size() == 2:
		_expect(table.buff_starts[1].stats == "4 / 7", "The second buff did not start from the first displayed increment.")
		await _sample_active_buff(1, id, 4, 7, "Second stacked buff")
	await _wait_for_drain()
	_expect_stats(id, 6, 9, "After both stacked buffs")


func _test_activated_buff() -> void:
	_reset()
	var bear := _unit("hearty_polar_pot_pie_bear", "plated", 0)
	var gazelle := _unit("hearty_gravy_gazelle", "plated", 1)
	var id := int(bear.instance_id)
	table._render_match()
	table._inspect_card(table._card_node_for_instance(id))
	table.service.activate_ability(table.state, int(gazelle.instance_id), "gravy_gazelle_buff")
	table.service.choose_ability_target(table.state, id)
	_expect(int(bear.attack) == 4 and int(bear.health) == 7, "Gravy Gazelle did not buff its selected ally.")
	_start_drain()
	_expect_stats(id, 3, 6, "Before Gravy Gazelle activation")
	await _wait_for_buff(1)
	_expect(table.activation_starts == 1, "The real activated ability skipped its source indicator.")
	await _sample_active_buff(0, id, 3, 6, "Gravy Gazelle recipient during buff")
	await _wait_for_drain()
	_expect_stats(id, 4, 7, "Gravy Gazelle recipient after buff")


func _test_attack_buff_then_retaliation() -> void:
	_reset()
	var bison := _unit("hearty_bison_burrito", "plated", 0)
	var id := int(bison.instance_id)
	for slot in 3:
		_unit("spicy_hot_honey_bee", "prep", slot)
	var defender: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("spicy_sriracharrow"), "plated", "opponent")
	defender.table_slot = 0
	table.state.opponent.plated = [defender]
	table._render_match()
	table._inspect_card(table._card_node_for_instance(id))
	_expect_stats(id, 4, 5, "Bison before attacking")
	table.service.select_attacker(table.state, id)
	table.service.attack(table.state, int(defender.instance_id))
	_expect(int(bison.attack) == 7 and int(bison.health) == 2 and int(bison.max_health) == 8, "Bison's real attack must resolve +3/+3 then six retaliation damage in the rules immediately.")
	var event_types: Array[String] = []
	for event in table.state.animation_events:
		event_types.append(String(event.type))
	_expect(event_types.slice(0, 5) == ["destroy", "destroy", "destroy", "buff", "attack"], "The real Bison fixture did not put its buff before attack and retaliation.")
	_start_drain()
	await _wait_for_buff(1)
	await _sample_active_buff(0, id, 4, 5, "Bison buff before future retaliation")
	var deadline := Time.get_ticks_msec() + 15000
	while table.attack_starts.is_empty() and not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(table.attack_starts.size() == 1 and table.attack_starts[0].stats == "7 / 8", "Bison must display its completed 7/8 buff before the attack presents future retaliation.")
	_expect_stats(id, 7, 8, "Bison after buff, before retaliation")
	await _wait_for_drain()
	_expect_stats(id, 7, 2, "Bison after retaliation finishes")
	_expect(table.state.player.prep.is_empty() and table.state.opponent.plated.is_empty(), "Bison's discard cost or defeated defender changed during presentation.")


func _test_on_play_buff() -> void:
	_reset()
	# Bibimbear is newly rendered by its play event. It has no older field node
	# from which to copy the unbuffed value, so event staging must work there too.
	table.state.player.discard = ["spicy_sriracharrow"]
	table._render_match()
	var bear := _unit("funky_bibimbear", "plated", 0)
	var id := int(bear.instance_id)
	var group := int(table.service._queue_play_event(table.state, "player", "funky_bibimbear", "meal", id))
	var previous := int(table.service._with_animation_group(table.state, group))
	table.service._resolve_effects(table.state, "player", table.service.card("funky_bibimbear").on_play, bear)
	table.service._restore_animation_group(table.state, previous)
	var final_attack := int(bear.attack)
	_expect(final_attack > 0, "Bibimbear's real on-play effect did not increase attack.")
	_start_drain()
	table._inspect_card(table._card_node_for_instance(id))
	_expect_stats(id, 0, 4, "Newly played Bibimbear before buff")
	await _wait_for_buff(1)
	await _sample_active_buff(0, id, 0, 4, "Newly played Bibimbear during buff")
	await _wait_for_drain()
	_expect_stats(id, final_attack, 4, "Bibimbear after on-play buff")


func _start_drain() -> void:
	drain_done = false
	table.animation_busy = true
	await table._drain_animation_event_queue()
	table.animation_busy = false
	table._render_match()
	drain_done = true


func _wait_for_buff(count: int) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while table.buff_starts.size() < count and not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(table.buff_starts.size() >= count, "Timed out waiting for buff cue %d." % count)


func _sample_active_buff(index: int, id: int, attack: int, health: int, context: String) -> void:
	if table.buff_starts.size() <= index:
		return
	var sample: Dictionary = table.buff_starts[index]
	var sample_at := int(sample.at) + int(float(sample.duration) * 650.0)
	while Time.get_ticks_msec() < sample_at:
		await process_frame
	_expect_stats(id, attack, health, context)
	# Reopening inspection during a running animation must not bypass staging.
	table._inspect_card(table._card_node_for_instance(id))
	_expect_stats(id, attack, health, context + " after reopening inspection")


func _wait_for_drain() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(drain_done, "Buff animation queue did not finish.")
	await _settle()


func _expect_stats(id: int, attack: int, health: int, context: String) -> void:
	var card: Node3D = table._card_node_for_instance(id)
	var stats := card.get_node_or_null("Stats") as Label3D if card != null else null
	_expect(stats != null and stats.text == "%d / %d" % [attack, health], context + ": field stats changed at the wrong time.")
	var face := table.inspector_card_face as CardFace
	_expect(is_instance_valid(face) and int(face._card.get("attack", -1)) == attack and int(face._card.get("health", -1)) == health, context + ": left preview stats changed at the wrong time.")
	if is_instance_valid(face):
		var runtime := face.find_child("RuntimeCardFace", true, false) as RuntimeAngularCard
		_expect(runtime != null and runtime.attack == attack and runtime.health == health, context + ": native preview digits disagree with the staged stats.")


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
	var capture := root.get_texture().get_image()
	_expect(capture != null and capture.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(name + ".png"))) == OK, "Could not save " + name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
