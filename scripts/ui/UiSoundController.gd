extends Node
class_name UiSoundController

const BUTTON_PRESS := preload("res://assets/audio/ui/cute_cozy/Button_Pressed.wav")
const TOGGLE_ON := preload("res://assets/audio/ui/cute_cozy/Clicked_In.wav")
const TOGGLE_OFF := preload("res://assets/audio/ui/cute_cozy/Clicked_Out.wav")
const SCREEN_TRANSITION := preload("res://assets/audio/ui/cute_cozy/Confirm.wav")
const POPUP := preload("res://assets/audio/ui/cute_cozy/Menu_Open.wav")
const SUCCESS := preload("res://assets/audio/ui/cute_cozy/Success.wav")
const ERROR := preload("res://assets/audio/ui/cute_cozy/Warning.wav")
const SLIDER_TICK := preload("res://assets/audio/ui/cute_cozy/Clicked_In.wav")

const SLIDER_COOLDOWN_MSEC := 35
const TRANSITION_COOLDOWN_MSEC := 140

var enabled := true
var _last_slider_msec := -SLIDER_COOLDOWN_MSEC
var _last_transition_msec := -TRANSITION_COOLDOWN_MSEC


func _ready() -> void:
	add_to_group("ui_sound_controller")
	if not enabled:
		return
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_bind_existing_controls")


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
		_bind_button(node as BaseButton)
	elif node is HSlider or node is VSlider:
		_bind_slider(node as Range)
	elif node is TabBar:
		(node as TabBar).tab_changed.connect(func(_tab: int) -> void: play_transition())
	else:
		return
	node.set_meta("ui_sound_bound", true)


func _bind_button(button: BaseButton) -> void:
	if button is CheckButton:
		button.toggled.connect(func(is_on: bool) -> void:
			_play(TOGGLE_ON if is_on else TOGGLE_OFF, -12.0)
		)
	else:
		button.button_down.connect(func() -> void: _play(BUTTON_PRESS, -11.0))


func _bind_slider(slider: Range) -> void:
	slider.value_changed.connect(func(_value: float) -> void:
		if slider.has_focus() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_play_slider_tick()
	)


func _play_slider_tick() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_slider_msec < SLIDER_COOLDOWN_MSEC:
		return
	_last_slider_msec = now
	_play(SLIDER_TICK, -17.0)


func play_transition() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_transition_msec < TRANSITION_COOLDOWN_MSEC:
		return
	_last_transition_msec = now
	_play(SCREEN_TRANSITION, -17.0)


func play_popup() -> void:
	_play(POPUP, -12.0)


func play_success() -> void:
	_play(SUCCESS, -11.0)


func play_error() -> void:
	_play(ERROR, -10.0)


func _play(stream: AudioStream, volume_db: float) -> void:
	if not enabled or stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
