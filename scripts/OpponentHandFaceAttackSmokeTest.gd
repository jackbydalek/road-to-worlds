extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

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
	var blocked_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == blocked_life
		and "clear all opposing Plated cards" in String(table.state.message),
		"Clicking the opponent hand bypassed the existing Plated blocker rule."
	)

	table.state.opponent.plated = []
	attacker.ready = true
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	table.service.select_attacker(table.state, int(attacker.instance_id))
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
