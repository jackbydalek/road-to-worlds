extends Button
class_name AssetButtonTint

@export_node_path("CanvasItem") var tint_target_path: NodePath = ^"Artwork"
@export var normal_tint := Color.WHITE
@export var hover_tint := Color(1.04, 1.04, 1.04, 1.0)
@export var pressed_tint := Color(0.82, 0.82, 0.82, 1.0)
@export var transition_seconds := 0.08

var _held := false
var _tint_target: CanvasItem
var _tint_tween: Tween


func _ready() -> void:
	_tint_target = get_node_or_null(tint_target_path) as CanvasItem
	mouse_entered.connect(_refresh_tint)
	mouse_exited.connect(_refresh_tint)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_apply_tint(normal_tint, true)


func _on_button_down() -> void:
	_held = true
	_refresh_tint()


func _on_button_up() -> void:
	_held = false
	_refresh_tint()


func _refresh_tint() -> void:
	if _held:
		_apply_tint(pressed_tint)
	elif is_hovered():
		_apply_tint(hover_tint)
	else:
		_apply_tint(normal_tint)


func _apply_tint(color: Color, immediately: bool = false) -> void:
	if _tint_target == null:
		return
	if _tint_tween != null and _tint_tween.is_valid():
		_tint_tween.kill()
	if immediately or transition_seconds <= 0.0:
		_tint_target.modulate = color
		return
	_tint_tween = create_tween()
	_tint_tween.tween_property(_tint_target, "modulate", color, transition_seconds).set_trans(Tween.TRANS_SINE)
