extends SceneTree

class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"

	func _begin_match_pacing() -> void:
		pass


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var added_sfx_bus := AudioServer.get_bus_index("SFX") < 0
	if added_sfx_bus:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	var table = TABLE_SCENE.instantiate()
	table.set_script(ObservedTable)
	root.add_child(table)
	await process_frame
	await process_frame

	_expect("cute_cozy_full/Actions/Unlock_02.wav" in String(table.POSITIVE_EFFECT_SOUND.resource_path), "Changing healing audio must not change the buff cue.")
	_expect("cute_cozy_full/Dialogue/Dialogue_Expression_Positive_01.wav" in String(table.HEAL_EFFECT_SOUND.resource_path), "Healing must use the exact selected recording.")
	_expect(is_equal_approx(float(table.POSITIVE_EFFECT_VOLUME_DB), -14.0), "Buffs must retain their existing gain.")
	_expect(is_equal_approx(float(table.HEAL_EFFECT_VOLUME_DB), -14.0), "Healing must retain the auditioned gain.")
	var buff_target: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "plated", "player")
	buff_target.table_slot = 0
	table.state.player.plated = [buff_target]
	table._render_match()
	await process_frame
	var before_count := table.find_children("*", "AudioStreamPlayer", true, false).size()
	table._start_heal_event_animation({"type": "heal", "amount": 0, "target_kind": "chef", "target_side": "player"})
	_expect(table.find_children("*", "AudioStreamPlayer", true, false).size() == before_count, "A zero-health change must not play a healing sound.")
	table._start_heal_event_animation({
		"type": "heal",
		"amount": 2,
		"target_kind": "chef",
		"target_side": "player",
	})
	var players := table.find_children("*", "AudioStreamPlayer", true, false)
	_expect(players.size() == before_count + 1, "A successful heal did not start exactly one healing sound.")
	if players.size() > before_count:
		var player := players[players.size() - 1] as AudioStreamPlayer
		_expect(player.stream == table.HEAL_EFFECT_SOUND, "The actual heal event did not route to the selected healing recording.")
		_expect(is_equal_approx(player.volume_db, table.HEAL_EFFECT_VOLUME_DB) and player.bus == &"SFX", "The healing sound lost its auditioned gain or SFX bus.")

	table._play_heal_effect_sound()
	_expect(
		table.find_children("*", "AudioStreamPlayer", true, false).size() == players.size(),
		"The healing cooldown did not suppress a clustered duplicate."
	)
	var buff_duration := float(table._start_buff_event_animation({"type": "buff", "target_instance_id": int(buff_target.instance_id), "attack_delta": 1, "health_delta": 0}))
	var after_buff := table.find_children("*", "AudioStreamPlayer", true, false)
	_expect(buff_duration > 0.0 and after_buff.size() == players.size() + 1, "Healing must not suppress a separate successful buff cue.")
	if after_buff.size() > players.size():
		var buff_player := after_buff.back() as AudioStreamPlayer
		_expect(buff_player.stream == table.POSITIVE_EFFECT_SOUND and is_equal_approx(buff_player.volume_db, -14.0), "An actual buff must retain its own recording and gain.")
	table._play_positive_effect_sound()
	_expect(table.find_children("*", "AudioStreamPlayer", true, false).size() == after_buff.size(), "Buffs must still suppress their own clustered duplicates.")

	for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
		var audio_player := audio_node as AudioStreamPlayer
		audio_player.stop()
		audio_player.queue_free()
	players.clear()
	await create_timer(0.8).timeout
	table.queue_free()
	await process_frame
	await process_frame
	if added_sfx_bus:
		AudioServer.remove_bus(AudioServer.get_bus_index("SFX"))
	if get_meta("failed", false):
		quit(1)
		return
	print("Positive-effect sound smoke test passed: selected healing, unchanged buffs, isolated cooldowns, and SFX routing.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	set_meta("failed", true)
	push_error(message)
