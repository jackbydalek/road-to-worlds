extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const ATTACK_HIGHLIGHT_PREVIEW_PATH := "res://outputs/illustrated_vfx/attack_target_highlights.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	# Use a normal attacker here. Sriracharrow is Stalwart and is intentionally
	# allowed to attack the opposing Chef through Plated blockers.
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1, true)
	var blocker := _unit(table, "opponent", "hearty_bagver", "plated", 1, true)
	table.state.player.plated = [attacker]
	table.state.player.prep = []
	table.state.opponent.plated = [blocker]
	table.state.opponent.prep = []
	table.state.phase = "player_main"
	table.state.turn = 3
	table.state.first_player = "player"
	table.state.player.turns_started = 2
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame

	var hand_card := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_expect(hand_card != null, "The opponent-hand attack test could not find a visible hand card.")
	if hand_card == null:
		quit(1)
		return
	var hand_click: Vector2 = table._card_screen_rect(hand_card).get_center()
	_expect(table._screen_hits_opponent_hand(hand_click), "The pictured opponent hand was not included in the face target.")

	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	var selected_attacker_card := table._card_node_for_instance(int(attacker.instance_id)) as Node3D
	var legal_blocker_card := table._card_node_for_instance(int(blocker.instance_id)) as Node3D
	_expect(
		selected_attacker_card != null
		and table.highlighted_bodies.has(selected_attacker_card.get_node("CardBody")),
		"Choosing Attack did not keep the selected attacker highlighted."
	)
	_expect(
		legal_blocker_card != null
		and table.highlighted_bodies.has(legal_blocker_card.get_node("CardBody"))
		and float(legal_blocker_card.get_node("CardBody").get_meta("highlight_pulse_amplitude", 0.0)) >= 0.7,
		"Choosing Attack did not add the stronger pulse to the legal defender."
	)
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	_expect(
		not table.highlighted_bodies.has(hand_card.get_node("CardBody")),
		"The opponent hand was highlighted even though a normal attacker could not attack directly."
	)
	var blocked_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == blocked_life
		and "clear all opposing Plated cards" in String(table.state.message),
		"Clicking the opponent hand bypassed the existing Plated blocker rule."
	)
	var stalwart_attacker := _unit(table, "player", "spicy_wasabi_wasp", "plated", 0, true)
	table.state.player.plated = [stalwart_attacker]
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	var stalwart_card := table._card_node_for_instance(int(stalwart_attacker.instance_id)) as Node3D
	var stalwart_origin: Vector3 = stalwart_card.position if stalwart_card != null else Vector3.ZERO
	await table._animate_attack_motion(int(stalwart_attacker.instance_id), -1, "chef")
	_expect(
		table.last_attack_used_stalwart_bypass
		and table.stalwart_bypass_animation_count == 1
		and float(table.last_attack_peak_height) >= stalwart_origin.y + 1.0,
		"A Stalwart direct attack through a blocker did not rise above the board."
	)
	_expect(
		stalwart_card != null and stalwart_card.position.is_equal_approx(stalwart_origin),
		"The Stalwart bypass card did not land back in its original board slot."
	)

	table.state.opponent.plated = []
	table.state.player.plated = [attacker]
	attacker.ready = true
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	selected_attacker_card = table._card_node_for_instance(int(attacker.instance_id)) as Node3D
	_expect(
		selected_attacker_card != null
		and table.highlighted_bodies.has(selected_attacker_card.get_node("CardBody")),
		"The attacker highlight disappeared when a direct attack became legal."
	)
	_expect(
		table.highlighted_bodies.has(hand_card.get_node("CardBody"))
		and float(hand_card.get_node("CardBody").get_meta("highlight_pulse_amplitude", 0.0)) >= 0.7,
		"The opponent hand did not pulse as the legal direct-attack target."
	)
	if DisplayServer.get_name() != "headless":
		for tween in get_processed_tweens():
			tween.kill()
		if is_instance_valid(table.turn_banner_panel):
			table.turn_banner_panel.visible = false
		await process_frame
		var preview := root.get_texture().get_image()
		_expect(
			preview != null and preview.save_png(ProjectSettings.globalize_path(ATTACK_HIGHLIGHT_PREVIEW_PATH)) == OK,
			"Could not save the attack-target highlight preview."
		)
	var face_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == face_life - int(attacker.attack),
		"Clicking the opponent hand did not resolve as an attack on the opposing Chef."
	)

	for unused_wait in range(30):
		if not bool(table.animation_busy):
			break
		await create_timer(0.1).timeout

	# An empty rival hand must not remove the direct-attack target. The always-visible
	# profile becomes the Chef target and receives the same cyan legal-state signal.
	table.state.opponent.hand = []
	attacker.ready = true
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	_expect(table.find_child("OpponentHandCard_0", true, false) == null, "The empty-hand setup still rendered a rival hand card.")
	var profile_center_global: Vector2 = table.opponent_profile_badge.get_global_rect().get_center()
	var profile_click: Vector2 = table.viewport_container.get_global_transform_with_canvas().affine_inverse() * profile_center_global
	_expect(table._screen_hits_opponent_chef(profile_click), "The rival profile was not available as the empty-hand Chef target.")
	_expect(table.opponent_profile_badge.scale.x > 1.0, "The rival profile did not highlight when a direct attack was legal.")
	var empty_hand_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(profile_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == empty_hand_life - int(attacker.attack),
		"Clicking the rival profile did not attack the opposing Chef when their hand was empty."
	)

	if failed:
		for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
			var audio_player := audio_node as AudioStreamPlayer
			audio_player.stop()
			audio_player.stream = null
		await create_timer(0.12).timeout
		table.queue_free()
		await process_frame
		await process_frame
		quit(1)
		return
	print("Opponent hand face-attack smoke test passed.")
	for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
		var audio_player := audio_node as AudioStreamPlayer
		audio_player.stop()
		audio_player.stream = null
	await create_timer(0.12).timeout
	table.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _left_click(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	return event


func _unit(table, side: String, card_id: String, zone: String, slot: int, ready: bool) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(
		table.state,
		table.state[side],
		table.service.card(card_id),
		zone,
		side
	)
	unit.table_slot = slot
	unit.ready = ready
	return unit


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
