extends Node

## Shared tactile press motion for the project's textured UI buttons.
## Kept subtle so the glass button shadows do not collide inside containers.

const PRESSED_SCALE := Vector2(0.975, 0.975)
const PRESS_SECONDS := 0.07
const RETURN_SECONDS := 0.12

var button: BaseButton
var rest_scale := Vector2.ONE
var active_tween: Tween


func _ready() -> void:
	button = get_parent() as BaseButton
	if button == null:
		queue_free()
		return
	rest_scale = button.scale
	button.resized.connect(_update_pivot)
	button.button_down.connect(_press)
	button.button_up.connect(_release)
	button.mouse_exited.connect(_release)
	_update_pivot()


func _update_pivot() -> void:
	if button != null:
		button.pivot_offset = button.size * 0.5


func _press() -> void:
	_tween_scale(PRESSED_SCALE, PRESS_SECONDS)


func _release() -> void:
	_tween_scale(rest_scale, RETURN_SECONDS)


func _tween_scale(target: Vector2, duration: float) -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if bool(get_tree().root.get_meta("reduced_motion", false)):
		button.scale = rest_scale
		return
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(button, "scale", target, duration)
