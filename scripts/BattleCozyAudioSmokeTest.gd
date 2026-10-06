extends SceneTree

class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var played_streams: Array[AudioStream] = []

	func _begin_match_pacing() -> void:
		pass

	func _play_card_sound(stream: AudioStream, volume_db: float = -18.0, pitch_scale: float = 1.0, from_position: float = 0.0) -> void:
		played_streams.append(stream)
		super._play_card_sound(stream, volume_db, pitch_scale, from_position)


const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Main normally creates the SFX bus before it mounts the battle scene.
	var added_sfx_bus := AudioServer.get_bus_index("SFX") < 0
	if added_sfx_bus:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	var table = TABLE_SCENE.instantiate()
	table.set_script(ObservedTable)
	root.add_child(table)
	await process_frame
	await process_frame

	# Sound selection must not alter gameplay/global randomness.
	seed(1937)
	var expected_random := randi()
	seed(1937)
	var combat_rng_state: int = table.service.rng.state
	table._play_random_card_sound(table.SLIDE_CARD_SOUNDS)
	_expect(randi() == expected_random, "Cosmetic sound variation consumed global randomness.")
	_expect(table.service.rng.state == combat_rng_state, "Sound playback advanced the combat RNG.")
	var players := _players(table)
	var foley := players.back() as AudioStreamPlayer
	_expect(foley.bus == &"SFX" and is_equal_approx(foley.volume_db, -18.0), "Card Foley bypassed SFX volume or played at full source volume.")
	_expect(table.DROP_CARD_SOUNDS.size() == 4, "The selected four-recording card-place pool was changed.")
	for index in range(4):
		_expect(table.DROP_CARD_SOUNDS[index].resource_path.ends_with("card-place-%d.ogg" % (index + 1)), "Card play must retain every selected placement recording.")
	_expect(table.PICK_CARD_SOUNDS.size() == 1 and table.PICK_CARD_SOUNDS[0].resource_path.ends_with("card-slide-4.ogg"), "Changing draw audio must not replace card pickup audio.")

	# Actual draw animation starts a paper cue; clustered transfers do not stack it.
	table.battle_cue_last_played.clear()
	var draw_event := {"type": "draw", "side": "player", "from": "deck", "to": "hand", "hand_index": 0, "card_id": String(table.state.player.hand[0])}
	var before_draw := _players(table).size()
	_expect(float(table._start_card_transfer_event_animation(draw_event)) > 0.0, "The fixture did not animate a real card transfer.")
	_expect(_players(table).size() == before_draw + 1, "An actual draw did not start exactly one paper cue.")
	var draw_player := _players(table).back() as AudioStreamPlayer
	_expect(table.DRAW_CARD_SOUNDS.size() == 1 and table.DRAW_CARD_SOUNDS.has(draw_player.stream), "Draws must use the separately selected single-recording pool.")
	_expect(draw_player.stream.resource_path.ends_with("card-slide-1.ogg"), "The draw did not use the exact auditioned slide recording.")
	_expect(is_equal_approx(draw_player.volume_db, -20.0) and is_equal_approx(float(table.CARD_DRAW_VOLUME_DB), -20.0), "Routine card draws were not mixed below card play actions.")
	_expect(is_equal_approx(draw_player.pitch_scale, 1.0), "Draws must preserve the auditioned recording's pitch.")
	table._start_card_transfer_event_animation(draw_event)
	_expect(_players(table).size() == before_draw + 1, "Simultaneous draw events stacked identical paper sounds.")
	# A later serial flight should still get its own cue.
	table.battle_cue_last_played["draw"] = Time.get_ticks_msec() - 100
	table._start_card_transfer_event_animation(draw_event)
	_expect(_players(table).size() == before_draw + 2, "The draw throttle suppressed a later card flight.")
	await create_timer(0.55).timeout

	# A missing presentation target must not create an unexplained paper sound.
	table.battle_cue_last_played.clear()
	var invalid_draw := draw_event.duplicate()
	invalid_draw.hand_index = 9999
	table.played_streams.clear()
	_expect(is_zero_approx(float(table._start_card_transfer_event_animation(invalid_draw))), "The invalid draw fixture unexpectedly found a visible target.")
	_expect(table.played_streams.is_empty(), "A missing hand card still triggered draw audio.")

	# Rebuilding or checking a deck's count is not shuffling the deck.
	for repeat in range(3):
		table._render_match()
		await process_frame
	_expect(table.played_streams.is_empty(), "Idle board refreshes emitted unexplained card audio.")
	for side in ["player", "opponent"]:
		table._straighten_deck(side)
		table._straighten_deck(side)
	_expect(_shuffle_count(table) == 0, "Repeated deck-count checks played a shuffle sound.")
	await create_timer(0.3).timeout

	# 'search' is also the visual transfer event for discard recovery; neither
	# that generic event nor its board refresh proves a shuffle happened.
	table.played_streams.clear()
	for source in ["deck", "discard"]:
		var search_event := draw_event.duplicate()
		search_event.type = "search"
		search_event.from = source
		var batch: Array[Dictionary] = [search_event]
		await table._animate_event_batch(batch, {})
	_expect(_shuffle_count(table) == 0, "A generic search or discard recovery played a full shuffle recording.")

	# Only a real deck refill earns the long shuffle recording, once.
	table.state.run_rules = {"reshuffle_pressure": true, "reshuffle_damage": [3, 5, 7]}
	table.state.player.deck = []
	table.state.player.discard = ["spicy_hot_honey_bee"]
	table.state.player.hand = []
	table.state.player.life = 40
	table.service.clear_animation_events(table.state)
	table.service._draw(table.state, "player")
	table.played_streams.clear()
	table.battle_cue_last_played.clear()
	await table._drain_animation_event_queue()
	_expect(_shuffle_count(table) == 1, "An actual discard-to-deck reshuffle did not play exactly one shuffle cue.")
	await table._drain_animation_event_queue()
	_expect(_shuffle_count(table) == 1, "Draining an already-consumed event queue replayed the shuffle cue.")

	table.last_ability_activation_sound_msec = -1000
	var before_ability := _players(table).size()
	table._play_ability_activation_sound()
	_expect(_players(table).size() == before_ability + 1, "Ability activation did not create its single reusable voice.")
	var ability_time: int = table.last_ability_activation_sound_msec
	table._play_ability_activation_sound()
	_expect(_players(table).size() == before_ability + 1 and table.last_ability_activation_sound_msec == ability_time, "A clustered activation restarted or layered its cue.")
	_expect(table.ability_activation_sound_player.bus == &"SFX" and is_equal_approx(table.ability_activation_sound_player.volume_db, -18.0), "Ability activation bypassed the quiet SFX mix.")
	_expect(table.ability_activation_sound_player.stream.resource_path.ends_with("Actions/Confirm_05.wav"), "Ability activation did not use the selected recording.")
	# The selected phrase is longer than the throttle. Another activation during
	# its tail must leave the same voice running instead of restarting it.
	await create_timer(0.3).timeout
	var ability_voice: AudioStreamPlayer = table.ability_activation_sound_player
	var ability_position := ability_voice.get_playback_position()
	table._play_ability_activation_sound()
	_expect(table.ability_activation_sound_player == ability_voice and ability_voice.playing, "Ability activations must share one live voice.")
	_expect(ability_voice.get_playback_position() >= ability_position, "A later activation restarted the selected phrase before it finished.")

	table.last_turn_sound_key = ""
	var before_turn := _players(table).size()
	table._play_turn_change_sound("player_main")
	table._play_turn_change_sound("player_main")
	_expect(_players(table).size() == before_turn + 1, "Repeated turn announcement played duplicate cues.")
	table._play_turn_change_sound("opponent_turn")
	_expect(_players(table).size() == before_turn + 2, "The rival's actual turn change did not receive its cue.")

	await create_timer(1.2).timeout
	table.queue_free()
	await process_frame
	await process_frame
	if added_sfx_bus:
		AudioServer.remove_bus(AudioServer.get_bus_index("SFX"))
	if failed:
		quit(1)
		return
	print("Cozy battle audio smoke test passed: quiet single-card draws, silent invalid/idle transfers, shuffle only on real deck refills, cooldowns, turn changes, and isolated randomness.")
	quit()


func _players(table: Node) -> Array[Node]:
	return table.find_children("*", "AudioStreamPlayer", true, false)


func _shuffle_count(table: Node) -> int:
	var count := 0
	for stream in table.played_streams:
		if (stream as AudioStream).resource_path.ends_with("card-shuffle.ogg"):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
