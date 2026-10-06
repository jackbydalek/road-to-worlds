extends TextureRect

## Plays losslessly decoded supplied art; static generated rivals use the same
## TextureRect contract. Animation is local to this view, never a shared texture.
const CAST := preload("res://scripts/ui/PeachSodaCast.gd")

var cast_id := ""
var frame_index := 0
var elapsed := 0.0
var reduced_motion := false
var frames: Array[Texture2D] = []
var durations: Array[float] = []


func configure(id: String, generated_enabled: bool = true, reduce_motion: bool = false) -> void:
	cast_id = id.to_lower()
	frames = CAST.frame_textures(cast_id, generated_enabled)
	durations = CAST.frame_durations(cast_id)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("seated_cast_id", cast_id)
	for key in ["supplied_character_id", "generated_art_id", "replacement_registry"]:
		if has_meta(key):
			remove_meta(key)
	var supplied := CAST.has_supplied_art(cast_id)
	set_meta("asset_origin", "user_supplied_animation" if supplied else "generated_working_art" if CAST.has_generated_art(cast_id, generated_enabled) else "native_fallback")
	if supplied:
		set_meta("supplied_character_id", cast_id)
		set_meta("replacement_registry", CAST.MINA_ROOT + "provenance.json")
	elif CAST.has_generated_art(cast_id, generated_enabled):
		set_meta("generated_art_id", "peach_soda_opponent_" + cast_id)
		set_meta("replacement_registry", "res://assets/generated/manifest.json")
	set_reduced_motion(reduce_motion)
	# The authored navy contour meets the painted room directly. Keep the source
	# alpha and animation intact, without adding the former white cutout rim.
	material = null


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	frame_index = 0
	elapsed = 0.0
	texture = frames[0] if not frames.is_empty() else CAST.FALLBACK
	set_process(not reduced_motion and frames.size() > 1)


func _process(delta: float) -> void:
	if reduced_motion or frames.size() < 2 or not is_visible_in_tree():
		return
	# Bound work after a suspended/background window without changing GIF timing.
	var loop_duration := 0.0
	for index in range(frames.size()):
		loop_duration += durations[index]
	elapsed += fmod(delta, loop_duration)
	while elapsed >= durations[frame_index]:
		elapsed -= durations[frame_index]
		frame_index = (frame_index + 1) % frames.size()
	texture = frames[frame_index]
