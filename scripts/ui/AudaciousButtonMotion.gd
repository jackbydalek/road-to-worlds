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
	# A button press can replace its entire screen before button_up arrives. In
	# that case this helper has already left the SceneTree and must not create a
	# tween or query the root viewport.
	if not is_inside_tree() or not is_instance_valid(button):
		return
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	if bool(tree.root.get_meta("reduced_motion", false)):
		button.scale = rest_scale
		return
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(button, "scale", target, duration)
