extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	var before_count := table.find_children("*", "AudioStreamPlayer", true, false).size()
	table._start_heal_event_animation({
		"type": "heal",
		"amount": 2,
		"target_kind": "chef",
		"target_side": "player",
	})
	var players := table.find_children("*", "AudioStreamPlayer", true, false)
	_expect(players.size() == before_count + 1, "A successful heal did not start the positive-effect sound.")
	if players.size() > before_count:
		var player := players[players.size() - 1] as AudioStreamPlayer
		_expect(player.stream == table.POSITIVE_EFFECT_SOUND, "The heal used the wrong positive-effect sound.")
		_expect(is_equal_approx(player.volume_db, table.POSITIVE_EFFECT_VOLUME_DB), "The positive-effect sound used the wrong volume.")

	table._play_positive_effect_sound()
	_expect(
		table.find_children("*", "AudioStreamPlayer", true, false).size() == players.size(),
		"The positive-effect cooldown did not suppress a clustered duplicate chime."
	)

	for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
		var audio_player := audio_node as AudioStreamPlayer
		audio_player.stop()
		audio_player.queue_free()
	players.clear()
	await create_timer(0.8).timeout
	table.queue_free()
	await process_frame
	await process_frame
	if get_meta("failed", false):
		quit(1)
		return
	print("Positive-effect sound smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	set_meta("failed", true)
	push_error(message)
