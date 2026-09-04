extends Control
class_name CardFace

## Public adapter used by every gameplay surface that displays a card. The
## visual chassis lives in RuntimeAngularCard; this class preserves the
## established configure/animation API used by battle, shops, rewards, pack
## opening, inspection views, and SubViewport-backed 3D card textures.

signal visual_changed

const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const RUNTIME_CARD_SCRIPT := preload("res://scripts/ui/RuntimeAngularCard.gd")
const ART_PENDING := preload("res://assets/cards/art_pending.png")

const DEFAULT_SIZE := Vector2(250, 355)
const DEFAULT_FRAME_DURATION := 0.1
const SUPPORTED_ARCHETYPES := ["spicy", "sweet", "hearty", "fresh", "funky"]
const AFFINITY_CARD_TYPES := ["ingredient", "meal"]
const NEUTRAL_CARD_TYPES := ["chef", "tool", "spice", "environment"]

var _card: Dictionary = {}
var _animation_frames: Array[Texture2D] = []
var _frame_duration := DEFAULT_FRAME_DURATION
var _frame_elapsed := 0.0
var _frame_index := 0
var _animate_art := true
var _compact_visual := false
var _show_art := true
var _runtime_face: RuntimeAngularCard


static func supports_card(card: Dictionary) -> bool:
	var card_type := String(card.get("card_type", ""))
	if card_type in NEUTRAL_CARD_TYPES:
		return true
	return String(card.get("archetype", "")) in SUPPORTED_ARCHETYPES and card_type in AFFINITY_CARD_TYPES


func configure(card: Dictionary, difficulty_id: String = "white", animate_art: bool = true, compact_visual: bool = false, show_art: bool = true) -> void:
	_card = card.duplicate(true)
	_animate_art = animate_art
	_compact_visual = compact_visual
	_show_art = show_art
	custom_minimum_size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_build_runtime_face(difficulty_id)


func _build_runtime_face(difficulty_id: String) -> void:
	for child in get_children():
		child.queue_free()

	_runtime_face = RUNTIME_CARD_SCRIPT.new()
	_runtime_face.name = "RuntimeCardFace"
	_runtime_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime_face.set_meta("frame_style", "runtime_angular_card")
	_runtime_face.set_meta("difficulty_id", difficulty_id)
	add_child(_runtime_face)
	_runtime_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_runtime_face.visual_changed.connect(func() -> void: visual_changed.emit())

	var runtime_data := _card.duplicate(true)
	var card_type := String(_card.get("card_type", "ingredient"))
	runtime_data["affinities"] = _card_affinity_ids()
	runtime_data["display_card_type"] = "TOOL" if card_type == "tool" else AFFINITY_VISUALS.card_type_name(card_type)
	runtime_data["compact_visual"] = _compact_visual
	runtime_data["show_art"] = _show_art
	runtime_data["show_stats"] = card_type not in NEUTRAL_CARD_TYPES
	if card_type in NEUTRAL_CARD_TYPES:
		runtime_data["footer_text"] = "SIGNATURE EFFECT" if card_type == "chef" else "UTILITY / RESOLVE"
	if not runtime_data.has("art_zoom"):
		if card_type == "chef":
			runtime_data["art_zoom"] = 0.92
		elif card_type == "tool":
			runtime_data["art_zoom"] = 1.08
		elif card_type in ["spice", "environment"]:
			runtime_data["art_zoom"] = 0.84

	var initial_art := _prepare_runtime_art()
	_runtime_face.configure(runtime_data, initial_art)
	var runtime_art := _runtime_face.find_child("CardArtwork", true, false) as TextureRect
	if runtime_art != null:
		runtime_art.set_meta("art_pending", initial_art == ART_PENDING)
	visual_changed.emit()


func _prepare_runtime_art() -> Texture2D:
	_animation_frames.clear()
	_frame_index = 0
	_frame_elapsed = 0.0
	_frame_duration = maxf(0.02, float(_card.get("art_frame_duration", DEFAULT_FRAME_DURATION)))
	if not _show_art:
		set_process(false)
		return null

	for frame_path_value in _card.get("art_frames", []):
		var frame_path := String(frame_path_value)
		if not ResourceLoader.exists(frame_path):
			continue
		var frame_texture := load(frame_path) as Texture2D
		if frame_texture != null:
			_animation_frames.append(frame_texture)
	if not _animation_frames.is_empty():
		set_process(_animate_art and _animation_frames.size() > 1)
		return _animation_frames[0]

	var static_art_path := String(_card.get("art_path", ""))
	set_process(false)
	if not static_art_path.is_empty() and ResourceLoader.exists(static_art_path):
		return load(static_art_path) as Texture2D
	return ART_PENDING


func _card_affinity_ids() -> Array[String]:
	var result: Array[String] = []
	var authored_affinities: Array = _card.get("archetypes", [])
	if authored_affinities.is_empty() and String(_card.get("card_type", "")) == "ingredient":
		authored_affinities = _card.get("ingredient_types", [])
	for affinity_value in authored_affinities:
		var affinity_id := String(affinity_value).to_lower()
		if affinity_id in SUPPORTED_ARCHETYPES and affinity_id not in result:
			result.append(affinity_id)
	if result.is_empty():
		var primary_affinity := String(_card.get("archetype", "")).to_lower()
		if primary_affinity in SUPPORTED_ARCHETYPES:
			result.append(primary_affinity)
	return result.slice(0, 2)


func _process(delta: float) -> void:
	if not _animate_art or _animation_frames.size() < 2 or not is_visible_in_tree():
		return
	_frame_elapsed += delta
	var frame_changed := false
	while _frame_elapsed >= _frame_duration:
		_frame_elapsed -= _frame_duration
		_frame_index = (_frame_index + 1) % _animation_frames.size()
		if is_instance_valid(_runtime_face):
			_runtime_face.set_card_art(_animation_frames[_frame_index])
		frame_changed = true
	if frame_changed:
		visual_changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_runtime_face):
		visual_changed.emit()
