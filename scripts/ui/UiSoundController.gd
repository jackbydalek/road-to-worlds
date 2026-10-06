extends Node
class_name UiSoundController
## Owner-supplied Cute & Cozy recordings; cosmetic variation never advances game RNG.

const BUTTON_PRESS := [
	preload("res://assets/audio/ui/cute_cozy_full/Actions/Clicked_In_01.wav"),
]
const TOGGLE_ON := preload("res://assets/audio/ui/cute_cozy_full/Actions/Clicked_In_02.wav")
const TOGGLE_OFF := preload("res://assets/audio/ui/cute_cozy_full/Actions/Clicked_Out_03.wav")
const HIGHLIGHT := preload("res://assets/audio/ui/cute_cozy_full/Actions/Highlight_02.wav")
const SCREEN_TRANSITION := [
	preload("res://assets/audio/ui/cute_cozy_full/Menus/Transition_03.wav"),
	preload("res://assets/audio/ui/cute_cozy_full/Menus/Transition_04.wav"),
]
const POPUP := preload("res://assets/audio/ui/cute_cozy_full/Menus/Menu_Open_02.wav")
const POPUP_CLOSE := preload("res://assets/audio/ui/cute_cozy_full/Menus/Menu_Close_02.wav")
const CONFIRM := preload("res://assets/audio/ui/cute_cozy_full/Actions/Confirm_01.wav")
const CANCEL := [
	preload("res://assets/audio/ui/cute_cozy_full/Actions/Cancel_02.wav"),
	preload("res://assets/audio/ui/cute_cozy_full/Actions/Cancel_03.wav"),
]
const SUCCESS := [
	preload("res://assets/audio/ui/cute_cozy_full/Positive/Success_04.wav"),
	preload("res://assets/audio/ui/cute_cozy_full/Positive/Success_06.wav"),
]
const ERROR := preload("res://assets/audio/ui/cute_cozy_full/Negative/Error_07.wav")
const PURCHASE := preload("res://assets/audio/ui/cute_cozy_full/Currency/Purchase_01.wav")
const REMOVE := preload("res://assets/audio/ui/cute_cozy_full/Currency/Sell_04.wav")
const UPGRADE := preload("res://assets/audio/ui/cute_cozy_full/Positive/Level_Up_04.wav")
const HEAL := preload("res://assets/audio/ui/cute_cozy_full/Dialogue/Dialogue_Expression_Positive_01.wav")
const LOSS := preload("res://assets/audio/ui/cute_cozy_full/Negative/Failure_08.wav")
const CLERK := preload("res://assets/audio/ui/cute_cozy_full/Dialogue/Dialogue_Expression_Neutral_02.wav")
# Keep the original shop-door recording intact, including its familiar squeak/tail.
const SHOP_BELL := preload("res://assets/audio/shop_door_bell_squeak.wav")
const MAX_VOICES := 6
const HISTORY_LIMIT := 32
const HIGHLIGHT_COOLDOWN_MSEC := 90
const SLIDER_COOLDOWN_MSEC := 65
const TRANSITION_COOLDOWN_MSEC := 180

var enabled := true:
	set(value):
		enabled = value
		if not enabled:
			for voice in _voices:
				if is_instance_valid(voice):
					voice.stop()
					voice.stream = null
					voice.queue_free()
			_voices.clear()
var last_cue: Dictionary = {}
var cue_history: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _voices: Array[AudioStreamPlayer] = []
var _last_cue_msec: Dictionary = {}
var _last_highlight_control_id := 0
var _last_highlight_msec := -1000
var _last_keyboard_navigation_msec := -1000


func _ready() -> void:
	_rng.randomize()
	add_to_group("ui_sound_controller")
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_controls")


func _input(event: InputEvent) -> void:
	for action in [&"ui_focus_next", &"ui_focus_prev", &"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		if event.is_action_pressed(action):
			_last_keyboard_navigation_msec = Time.get_ticks_msec()
			return


func _bind_existing_controls() -> void:
	var root := get_tree().root
	_bind_control(root)
	for node in root.find_children("*", "", true, false):
		_bind_control(node)


func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_bind_control_by_id", node.get_instance_id())


func _bind_control_by_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Control:
		_bind_control(node)


func _bind_control(node: Node) -> void:
	if not is_instance_valid(node) or bool(node.get_meta("ui_sound_bound", false)):
		return
	if node is BaseButton:
		var button := node as BaseButton
		button.button_down.connect(func() -> void:
			if not _control_can_sound(button): return
			if button is CheckButton or button is CheckBox:
				_cue("toggle", [TOGGLE_OFF if button.button_pressed else TOGGLE_ON], -15.0)
			else:
				_cue("button", BUTTON_PRESS, -15.0, 65, 0.0)
		)
	elif node is HSlider or node is VSlider:
		var slider := node as Range
		slider.value_changed.connect(func(_value: float) -> void:
			if _control_can_sound(slider) and (slider.has_focus() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
				_cue("slider", [TOGGLE_ON], -23.0, SLIDER_COOLDOWN_MSEC)
		)
	elif node is TabBar:
		(node as TabBar).tab_changed.connect(func(_tab: int) -> void:
			if _control_can_sound(node as Control): play_transition()
		)
	else:
		return
	var control := node as Control
	control.mouse_entered.connect(func() -> void: _play_control_highlight(control, false))
	control.focus_entered.connect(func() -> void: _play_control_highlight(control, true))
	node.set_meta("ui_sound_bound", true)


func _control_can_sound(control: Control) -> bool:
	if not enabled or not is_instance_valid(control) or not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	if control is BaseButton and (control as BaseButton).disabled:
		return false
	if control is Slider and not (control as Slider).editable:
		return false
	return not bool(control.get_meta("ui_sound_silent", false))


func _play_control_highlight(control: Control, keyboard_focus: bool) -> void:
	if not _control_can_sound(control): return
	var now := Time.get_ticks_msec()
	# Initial/restored focus is silent. Only actual navigation earns a focus tick.
	if keyboard_focus and (now - _last_keyboard_navigation_msec > 500 or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		return
	var control_id := control.get_instance_id()
	if control_id == _last_highlight_control_id and now - _last_highlight_msec < 200:
		return
	if now - _last_highlight_msec < HIGHLIGHT_COOLDOWN_MSEC:
		return
	_last_highlight_control_id = control_id
	_last_highlight_msec = now
	_cue("highlight", [HIGHLIGHT], -27.0, HIGHLIGHT_COOLDOWN_MSEC)


func play_transition() -> void:
	_cue("transition", SCREEN_TRANSITION, -20.0, TRANSITION_COOLDOWN_MSEC)


func play_popup() -> void:
	_cue("popup", [POPUP], -18.0, 160)


func play_popup_close() -> void:
	_cue("popup_close", [POPUP_CLOSE], -19.0, 160)


func play_confirm() -> void:
	_cue("confirm", [CONFIRM], -17.0, 160, 0.0)


func play_cancel() -> void:
	_cue("cancel", CANCEL, -19.0, 160)


func play_success() -> void:
	_cue("success", SUCCESS, -17.0, 220, 0.0)


func play_error() -> void:
	_cue("error", [ERROR], -19.0, 220, 0.0)


func play_purchase() -> void:
	_cue("purchase", [PURCHASE], -16.0, 160, 0.0)


func play_remove() -> void:
	_cue("remove", [REMOVE], -17.0, 160, 0.0)


func play_upgrade() -> void:
	_cue("upgrade", [UPGRADE], -17.0, 220, 0.0)


func play_heal() -> void:
	_cue("heal", [HEAL], -14.0, 220, 0.0)


func play_result(won: bool) -> void:
	_cue("result_win" if won else "result_loss", [SUCCESS[0] if won else LOSS], -15.0, 500, 0.0)


func play_shop_focus(view: String) -> void:
	_cue("shop_focus", [CLERK if view == "clerk" or view == "seller" else POPUP], -21.0, 220, 0.0)


func play_shop_bell() -> void:
	_cue("shop_bell", [SHOP_BELL], -14.0, 8000, 0.0)


func _cue(cue: String, streams: Array, volume_db: float, cooldown_msec: int = 65, pitch_variation: float = 0.025) -> void:
	if not enabled or streams.is_empty() or not is_inside_tree(): return
	var now := Time.get_ticks_msec()
	if now - int(_last_cue_msec.get(cue, -10000)) < cooldown_msec: return
	for index in range(_voices.size() - 1, -1, -1):
		if not is_instance_valid(_voices[index]) or _voices[index].is_queued_for_deletion():
			_voices.remove_at(index)
	if _voices.size() >= MAX_VOICES:
		if cue == "highlight" or cue == "slider": return
		# Quiet navigation cannot cut off the original long shop bell.
		for index in range(_voices.size()):
			if _voices[index].get_meta("cue", "") != "shop_bell":
				var oldest := _voices[index]
				_voices.remove_at(index)
				oldest.stop()
				oldest.stream = null
				oldest.queue_free()
				break
		if _voices.size() >= MAX_VOICES: return
	var stream: AudioStream = streams[_rng.randi_range(0, streams.size() - 1)]
	if stream == null: return
	_last_cue_msec[cue] = now
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.pitch_scale = _rng.randf_range(1.0 - pitch_variation, 1.0 + pitch_variation) if pitch_variation > 0.0 else 1.0
	player.set_meta("cue", cue)
	player.finished.connect(func() -> void:
		_voices.erase(player)
		player.queue_free()
	)
	add_child(player)
	_voices.append(player)
	last_cue = {"cue": cue, "path": stream.resource_path, "volume_db": volume_db, "pitch": player.pitch_scale, "bus": "SFX"}
	cue_history.append(last_cue.duplicate())
	if cue_history.size() > HISTORY_LIMIT: cue_history.pop_front()
	player.play()
