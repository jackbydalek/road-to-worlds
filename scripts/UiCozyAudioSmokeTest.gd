extends SceneTree
## Exercise real control signals, accessibility input, mute and bounded audio playback.
const CONTROLLER := preload("res://scripts/ui/UiSoundController.gd")
var errors: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var added_bus := AudioServer.get_bus_index("SFX") < 0
	if added_bus:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	var controller := CONTROLLER.new()
	var panel := Control.new()
	root.add_child(panel)
	var button := Button.new()
	button.text = "Choose a starter"
	button.position = Vector2(80, 80)
	button.size = Vector2(180, 50)
	panel.add_child(button)
	var toggle := CheckButton.new()
	toggle.position = Vector2(80, 150)
	panel.add_child(toggle)
	root.add_child(controller)
	await process_frame
	await process_frame
	_expect(button.has_meta("ui_sound_bound"), "Existing buttons must be bound.")
	var late_button := Button.new()
	late_button.position = Vector2(80, 220)
	panel.add_child(late_button)
	await process_frame
	await process_frame
	_expect(late_button.has_meta("ui_sound_bound"), "Controls added later must also be bound.")
	controller.cue_history.clear()
	button.grab_focus()
	_expect(controller.cue_history.is_empty(), "Restoring focus must not add a hover sound.")
	button.mouse_entered.emit()
	_expect(controller.last_cue.get("cue") == "highlight" and controller.last_cue.get("volume_db", 0.0) <= -24.0, "Hover must use a quiet highlight cue.")
	var count := controller.cue_history.size()
	var navigation := InputEventAction.new()
	navigation.action = &"ui_focus_next"
	navigation.pressed = true
	controller._input(navigation)
	button.focus_entered.emit()
	button.mouse_entered.emit()
	late_button.mouse_entered.emit()
	_expect(controller.cue_history.size() == count, "Mouse/focus overlap and rapid traversal must not stack hover cues.")
	await create_timer(0.12).timeout
	late_button.grab_focus()
	_expect(controller.cue_history.size() == count + 1 and controller.last_cue.get("cue") == "highlight", "Keyboard navigation must receive the same quiet focus cue.")
	button.button_down.emit()
	_expect(controller.last_cue.get("cue") == "button" and str(controller.last_cue.get("path")).ends_with("cute_cozy_full/Actions/Clicked_In_01.wav"), "Button presses must use the exact selected click recording.")
	_expect(CONTROLLER.BUTTON_PRESS.size() == 1 and controller.last_cue.get("volume_db") == -15.0 and controller.last_cue.get("pitch") == 1.0, "Button presses must preserve the auditioned single-clip choice, gain and pitch.")
	count = controller.cue_history.size()
	button.button_down.emit()
	_expect(controller.cue_history.size() == count, "Repeated button signals must be throttled.")
	await create_timer(0.08).timeout
	button.disabled = true
	button.button_down.emit()
	button.mouse_entered.emit()
	_expect(controller.cue_history.size() == count, "Disabled buttons must be silent.")
	button.disabled = false
	panel.hide()
	button.button_down.emit()
	toggle.button_down.emit()
	_expect(controller.cue_history.size() == count, "Hidden controls must be silent, including hidden parents.")
	panel.show()
	toggle.set_pressed_no_signal(false)
	toggle.button_down.emit()
	_expect(str(controller.last_cue.get("path")).ends_with("Clicked_In_02.wav"), "Enabling a toggle must use the on cue.")
	await create_timer(0.08).timeout
	toggle.set_pressed_no_signal(true)
	toggle.button_down.emit()
	_expect(str(controller.last_cue.get("path")).ends_with("Clicked_Out_03.wav"), "Disabling a toggle must use the off cue.")
	# Cosmetic randomization cannot alter the seeded card/run random sequence.
	seed(394721)
	var expected_next := randi()
	seed(394721)
	controller.play_transition()
	controller.play_cancel()
	_expect(randi() == expected_next, "Audio variation must not consume global game randomness.")
	_expect(controller.last_cue.get("bus") == "SFX", "All interface audio must respect the SFX bus.")
	count = controller.cue_history.size()
	controller.play_transition()
	_expect(controller.cue_history.size() == count, "Repeated transitions must be throttled.")
	controller.enabled = false
	controller.play_error()
	button.button_down.emit()
	_expect(controller.cue_history.size() == count and controller._voices.is_empty(), "Disabling sound must stop existing voices and suppress new cues.")
	controller.enabled = true
	controller.play_shop_bell()
	_expect(controller.last_cue.get("path") == "res://assets/audio/shop_door_bell_squeak.wav" and controller.last_cue.get("volume_db") == -14.0 and controller.last_cue.get("pitch") == 1.0, "The original shop bell must keep its recording, tuning and requested gain.")
	_expect(is_equal_approx(CONTROLLER.SHOP_BELL.get_length(), 8.0), "The original shop bell must retain its full recording.")
	count = controller.cue_history.size()
	controller.play_shop_bell()
	_expect(controller.cue_history.size() == count, "Shop navigation must not restart or stack the original bell.")
	var cases := {
		"play_purchase": ["purchase", "Currency/Purchase_01.wav"],
		"play_remove": ["remove", "Currency/Sell_04.wav"],
		"play_upgrade": ["upgrade", "Positive/Level_Up_04.wav"],
		"play_heal": ["heal", "Dialogue/Dialogue_Expression_Positive_01.wav"],
		"play_popup": ["popup", "Menus/Menu_Open_02.wav"],
		"play_popup_close": ["popup_close", "Menus/Menu_Close_02.wav"],
		"play_confirm": ["confirm", "Actions/Confirm_01.wav"],
		"play_error": ["error", "Negative/Error_07.wav"],
	}
	for method in cases:
		controller.call(method)
		_expect(controller.last_cue.get("cue") == cases[method][0] and str(controller.last_cue.get("path")).ends_with(cases[method][1]), "Committed action %s must use its own supplied recording." % method)
		if method == "play_purchase":
			_expect(controller.last_cue.get("volume_db") == -16.0, "Purchases must preserve the selected audition gain.")
		elif method == "play_heal":
			_expect(controller.last_cue.get("volume_db") == -14.0, "Shop healing must preserve the selected audition gain.")
	controller.play_result(true)
	_expect(str(controller.last_cue.get("path")).ends_with("Positive/Success_04.wav"), "A win must use the short success phrase.")
	controller.play_result(false)
	_expect(str(controller.last_cue.get("path")).ends_with("Negative/Failure_08.wav"), "A loss must use the gentle failure phrase.")
	controller.play_shop_focus("clerk")
	_expect(str(controller.last_cue.get("path")).ends_with("Dialogue/Dialogue_Expression_Neutral_02.wav"), "Clerk focus should play one quiet greeting.")
	_expect(controller._voices.size() <= CONTROLLER.MAX_VOICES, "Audio polyphony must stay bounded during overlapping UI events.")
	var bell_count := 0
	for voice in controller._voices:
		_expect(voice.bus == &"SFX", "A playing voice bypassed the SFX bus.")
		if voice.get_meta("cue", "") == "shop_bell": bell_count += 1
	_expect(bell_count == 1, "Busy interface feedback must not cut off the original shop bell.")
	var sfx_index := AudioServer.get_bus_index("SFX")
	var was_muted := AudioServer.is_bus_mute(sfx_index)
	AudioServer.set_bus_mute(sfx_index, true)
	_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index(controller._voices[0].bus)), "Muting SFX must mute the bus used by live UI voices.")
	AudioServer.set_bus_mute(sfx_index, was_muted)
	controller.enabled = false
	controller.queue_free()
	panel.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if added_bus: AudioServer.remove_bus(AudioServer.get_bus_index("SFX"))
	for message in errors: push_error(message)
	if errors.is_empty(): print("PASS: cozy UI audio (%d checks)." % checks)
	quit(0 if errors.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition: errors.append(message)
