extends SceneTree

class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var played_streams: Array[AudioStream] = []
	var played_volumes: Array[float] = []
	var played_pitches: Array[float] = []
	var hit_flash_times: Array[int] = []
	var played_times: Array[int] = []

	func _begin_match_pacing() -> void:
		pass

	func _play_card_sound(stream: AudioStream, volume_db: float = -18.0, pitch_scale: float = 1.0, _from_position: float = 0.0) -> void:
		played_streams.append(stream)
		played_volumes.append(volume_db)
		played_pitches.append(pitch_scale)
		played_times.append(Time.get_ticks_msec())

	func _spawn_impact_flash(world_position: Vector3, accent: Color = PALETTE.SIGNAL_RED) -> void:
		hit_flash_times.append(Time.get_ticks_msec())
		super._spawn_impact_flash(world_position, accent)


const TABLETOP_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
var failed := false
var attack_done := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var added_sfx_bus := AudioServer.get_bus_index("SFX") < 0
	if added_sfx_bus:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	var table = TABLETOP_SCENE.instantiate()
	table.set_script(ObservedTable)
	root.add_child(table)
	await process_frame
	await process_frame
	table.reduced_motion = true
	_expect("cute_cozy_full/Actions/Confirm_02.wav" in String(table.MEAL_SUMMON_SOUND.resource_path), "Meal summons lost the short cozy confirmation.")
	_expect(is_equal_approx(float(table.MEAL_SUMMON_VOLUME_DB), -14.0), "The Meal summon cue was not softly mixed.")
	_expect(is_equal_approx(float(table.MEAL_SUMMON_SOUND_DELAY_SECONDS), 0.44), "The Meal summon cue was no longer aligned with its landing flash.")
	_expect("cute_cozy_full/Actions/Confirm_05.wav" in String(table.ABILITY_ACTIVATION_SOUND.resource_path), "Activated abilities did not use the exact selected recording.")
	_expect(float(table.MEAL_SUMMON_SOUND.get_length()) < 0.8, "Meal summon retained a long tail.")
	_expect(is_equal_approx(float(table.ABILITY_ACTIVATION_VOLUME_DB), -18.0), "Ability activation was not softly mixed.")
	_expect(is_equal_approx(float(table.CARD_IMPACT_VOLUME_DB), -5.0) and is_equal_approx(float(table.INGREDIENT_CHEF_IMPACT_VOLUME_DB), -5.0), "Ordinary hits retained the previous quiet mix.")
	_expect(is_equal_approx(float(table.MEAL_CHEF_IMPACT_VOLUME_DB), -3.0), "Meal hits retained the previous quiet mix.")
	_expect(is_equal_approx(float(table.EFFECT_DAMAGE_VOLUME_DB), -6.0), "Effect and reaction hits retained the previous quiet mix.")
	_expect(table.CARD_IMPACT_SOUNDS.size() == 1 and table.CARD_IMPACT_SOUNDS[0].resource_path.ends_with("impactPunch_medium_000.ogg"), "Normal hits must use only the selected punch recording.")
	_expect(table.MEAL_CHEF_IMPACT_SOUNDS.size() == 1 and table.MEAL_CHEF_IMPACT_SOUNDS[0].resource_path.ends_with("impactPunch_heavy_000.ogg"), "Meal-to-Chef hits must use only the selected heavy punch recording.")

	# Exercise real animation paths, so a second hit call cannot evade a profile test.
	var attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "plated", "player")
	var defender: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("hearty_bagver"), "plated", "opponent")
	attacker.table_slot = 0
	defender.table_slot = 0
	table.state.player.plated = [attacker]
	table.state.opponent.plated = [defender]
	table._render_match()
	table.played_streams.clear()
	_start_observed_attack(table, int(attacker.instance_id), int(defender.instance_id), "unit")
	_expect(table.played_streams.is_empty(), "The attack played its hit before the card reached contact.")
	while not attack_done:
		await process_frame
	_expect(table.played_streams.size() == 1, "A card attack did not play exactly one hit sound.")
	_start_observed_attack(table, int(attacker.instance_id), -1, "chef")
	_expect(table.played_streams.size() == 1, "The direct attack played its hit at launch.")
	while not attack_done:
		await process_frame
	_expect(table.played_streams.size() == 2, "A direct attack did not play exactly one hit sound.")
	for index in range(mini(2, table.played_streams.size())):
		_expect(table.played_streams[index].resource_path.ends_with("impactPunch_medium_000.ogg") and is_equal_approx(table.played_volumes[index], -5.0), "Ordinary unit and Ingredient-to-Chef contacts must use the selected normal hit and gain.")
	var meal: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_sriracharrow"), "plated", "player")
	meal.table_slot = 0
	table.state.player.plated = [meal]
	table._render_match()
	_start_observed_attack(table, int(meal.instance_id), -1, "chef")
	_expect(table.played_streams.size() == 2, "The Meal-to-Chef hit played before contact.")
	while not attack_done:
		await process_frame
	_expect(table.played_streams.size() == 3, "A Meal-to-Chef attack did not play exactly one hit sound.")
	if table.played_streams.size() == 3:
		_expect(table.played_streams[2].resource_path.ends_with("impactPunch_heavy_000.ogg") and is_equal_approx(table.played_volumes[2], -3.0), "An actual Meal-to-Chef contact did not use the selected heavy hit and gain.")
	_expect(table.hit_flash_times.size() == 3, "The attack fixture did not reach all three visible contacts.")
	for index in range(mini(table.played_times.size(), table.hit_flash_times.size())):
		_expect(absi(int(table.played_times[index]) - int(table.hit_flash_times[index])) <= 60, "A hit cue played at attack launch rather than visible contact.")
		_expect(is_equal_approx(table.played_pitches[index], 1.0), "Selected attack contacts must retain the auditioned punch pitch.")
	for target_kind in ["unit", "chef"]:
		var duration := float(table._start_damage_event_animation({"amount": 1, "combat": true, "target_kind": target_kind, "target_side": "opponent", "target_instance_id": int(defender.instance_id)}))
		_expect(duration > 0.0, "The combat damage fixture did not reach its real animation path.")
	_expect(table.played_streams.size() == 3, "Combat damage layered a second hit over the attack contact sound.")
	for target_kind in ["unit", "chef"]:
		await create_timer(0.1).timeout
		var before_effect: int = table.played_streams.size()
		var duration := float(table._start_damage_event_animation({"amount": 1, "combat": false, "target_kind": target_kind, "target_side": "opponent", "target_instance_id": int(defender.instance_id)}))
		_expect(duration > 0.0, "The effect damage fixture did not reach its real animation path.")
		_expect(table.played_streams.size() == before_effect + 1, "Effect damage did not play one hit cue.")
	await create_timer(0.5).timeout

	var reveal_count: int = table.hand_trap_reveal_count
	var before_reaction: int = table.played_streams.size()
	await table._show_hand_trap_fullscreen_reveal({"card_id": "funky_chef_check_chinchilla", "reacted_card_id": "spicy_hot_honey_bee", "side": "player"})
	_expect(int(table.hand_trap_reveal_count) == reveal_count + 1, "The reaction fixture did not run the full hand-trap reveal.")
	_expect(table.played_streams.size() == before_reaction + 1, "The reaction reveal did not play its impact cue.")
	for index in range(table.played_streams.size()):
		_expect("assets/audio/kenney_impacts/" in String(table.played_streams[index].resource_path), "A hit was routed to a musical or card-handling cue.")
		_expect(float(table.played_volumes[index]) > -11.0, "A hit retained the inaudible soft-pass attenuation.")
	for index in range(3, table.played_streams.size()):
		_expect("impactWood_medium" in String(table.played_streams[index].resource_path), "Effect or reaction hits retained the overly light source family.")

	await create_timer(0.5).timeout
	table.queue_free()
	await process_frame
	await process_frame
	if added_sfx_bus:
		AudioServer.remove_bus(AudioServer.get_bus_index("SFX"))
	if failed:
		quit(1)
		return
	print("Combat audio smoke test passed: selected normal and heavy punches at contact, unchanged effect/reaction hits, no duplicate combat hit, and selected ability cue.")
	quit()


func _start_observed_attack(table: Node, attacker_id: int, target_id: int, target_kind: String) -> void:
	attack_done = false
	await table._animate_attack_motion(attacker_id, target_id, target_kind)
	attack_done = true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
