extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run("spicy", starter, main._predator_archetype("spicy"), "debug", "white")
	main._start_debug_kitchen_match()
	await process_frame
	await process_frame

	var tabletop := main.find_child("Tabletop3DPrototype", true, false) as Control
	var settings_button := main.find_child("SettingsButton", true, false) as Button
	_expect(tabletop != null and settings_button != null, "The battle did not expose its Settings control.")
	if tabletop == null or settings_button == null:
		quit(1)
		return
	var turn_before := int(tabletop.state.get("turn", -1))
	settings_button.emit_signal("pressed")
	await process_frame
	await process_frame

	_expect(main.current_screen == "settings", "The battle Settings control did not open the settings screen.")
	_expect(main.suspended_tabletop == tabletop, "Opening Settings did not preserve the live tabletop instance.")
	_expect(not tabletop.visible and tabletop.process_mode == Node.PROCESS_MODE_DISABLED, "The preserved battle did not pause behind Settings.")
	_expect(main.find_child("MusicVolumeSlider", true, false) is HSlider, "The battle did not open the full game settings screen.")
	var play_speed_select := main.find_child("PlaySpeedSelect", true, false) as OptionButton
	var battle_text_select := main.find_child("BattleTextScaleSelect", true, false) as OptionButton
	_expect(play_speed_select != null and battle_text_select != null, "The main settings screen did not expose battle-only preferences.")
	if play_speed_select != null:
		play_speed_select.emit_signal("item_selected", 0)
	if battle_text_select != null:
		battle_text_select.emit_signal("item_selected", 2)

	main._return_from_settings()
	await process_frame
	await process_frame
	_expect(main.current_screen == "kitchen_match", "Back from Settings did not return to the battle.")
	_expect(tabletop.get_parent() == main.content and tabletop.visible, "Back from Settings did not restore the same tabletop instance.")
	_expect(tabletop.process_mode == Node.PROCESS_MODE_INHERIT, "The battle remained paused after leaving Settings.")
	_expect(int(tabletop.state.get("turn", -1)) == turn_before, "Opening Settings changed or restarted the battle turn.")
	_expect(tabletop.rival_pacing_index == 0 and tabletop.text_scale_index == 2, "Settings changes did not apply to the restored battle.")
	var play_speed_button := tabletop.find_child("RivalPacingButton", true, false) as Button
	_expect(play_speed_button != null and play_speed_button.text.begins_with("PLAY SPEED"), "The in-battle control was not renamed to Play Speed.")

	await create_timer(1.15).timeout
	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Battle settings smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
