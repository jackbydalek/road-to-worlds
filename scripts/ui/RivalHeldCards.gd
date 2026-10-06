extends Control

## Live concealed cards, composited between the portrait and its original hand.
## Source art is never changed: the small finger overlay samples those same
## pixels through a cached native mask. There are no card identities here.
const SLEEVE := preload("res://assets/cards/card_backs/living_table.png")
const HAND_POSE := preload("res://scripts/ui/RivalHandPose.gd")
const MINA_CANVAS := Vector2(701, 628)
const MINA_HAND_ROI := Rect2i(430, 520, 190, 104)
const DRAW_SECONDS := 0.28
const PLAY_SECONDS := 0.30

var held_count := 0
var reduced_motion := false
var _portrait: TextureRect
var _cast_id := ""
var _cards: Array[TextureRect] = []
var _flights: Array[Dictionary] = []
var _hand_overlay: TextureRect
var _hand_cache: Dictionary = {}
var _last_texture: Texture2D
var _art_rect := Rect2()
var _source_size := MINA_CANVAS
var _source_scale := 1.0
var _serial := 0
var _pose: Dictionary = {}
var _cover_colors := PackedColorArray()


static func supports_cast(cast_id: String) -> bool:
	return HAND_POSE.supports_cast(cast_id)


func configure(portrait: TextureRect, cast_id: String, reduce_motion: bool) -> void:
	_portrait = portrait
	_cast_id = cast_id.to_lower()
	_pose = HAND_POSE.for_cast(_cast_id)
	reduced_motion = reduce_motion
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	z_index = 2
	z_as_relative = true
	set_meta("concealed", true)
	set_meta("is_face_down", true)
	if _hand_overlay == null:
		_hand_overlay = TextureRect.new()
		_hand_overlay.name = "OriginalFingerOverlay"
		_hand_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hand_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_hand_overlay.stretch_mode = TextureRect.STRETCH_SCALE
		_hand_overlay.z_index = 1
		add_child(_hand_overlay)
	_hand_overlay.set_meta("art_origin", "original_supplied_pixels" if _cast_id == "mina" else "original_generated_pixels")
	_update_geometry()
	_update_hand_overlay()
	_prepare_garment_cover()
	set_process(true)


func _draw() -> void:
	if _pose.is_empty() or _cover_colors.is_empty():
		return
	var points := PackedVector2Array()
	for point in _pose["cover"]:
		points.append(_source_to_local(point))
	draw_polygon(points, _cover_colors)
	if _cast_id == "milo":
		# Continue the hoodie cord that was originally hidden by Milo's cards.
		# It is part of the native clothing layer, beneath the live fan/hands.
		var cord_ink := Color("38454a")
		draw_line(_source_to_local(Vector2(650, 678)), _source_to_local(Vector2(650, 748)), cord_ink, 2.2 * _source_scale, true)
		draw_line(_source_to_local(Vector2(658, 678)), _source_to_local(Vector2(658, 748)), cord_ink, 2.2 * _source_scale, true)


func _prepare_garment_cover() -> void:
	_cover_colors.clear()
	if _pose.is_empty() or not is_instance_valid(_portrait) or _portrait.texture == null:
		return
	var source := _portrait.texture.get_image()
	if source.is_compressed():
		source.decompress()
	var left_sample: Vector2 = _pose["sample_left"]
	var right_sample: Vector2 = _pose["sample_right"]
	var left := source.get_pixelv(Vector2i(left_sample))
	var right := source.get_pixelv(Vector2i(right_sample))
	for point in _pose["cover"]:
		var fraction := clampf((point.x - left_sample.x) / (right_sample.x - left_sample.x), 0.0, 1.0)
		_cover_colors.append(left.lerp(right, fraction))
	queue_redraw()


func sync_count(count: int) -> void:
	# A state resync is authoritative, including a zero-card hand. Cancel any
	# pending visual flight without leaving an extra sleeve behind.
	held_count = maxi(0, count)
	for child in get_children():
		if bool(child.get_meta("rival_held_card", false)):
			remove_child(child)
			child.queue_free()
	_cards.clear()
	_flights.clear()
	for index in range(held_count):
		_cards.append(_new_card())
	_update_geometry()
	_layout_cards()


func animate_draw(from_global: Vector2) -> float:
	if reduced_motion or not is_instance_valid(_portrait):
		sync_count(held_count + 1)
		return 0.0
	held_count += 1
	var card := _new_card()
	_cards.append(card)
	_update_geometry()
	_layout_cards()
	_flights.append({
		"card": card, "kind": "draw", "elapsed": 0.0,
		"duration": DRAW_SECONDS, "from_global": from_global,
		"from_rotation": -0.16,
	})
	_apply_flight(_flights.back())
	return DRAW_SECONDS


func animate_play(to_global: Vector2) -> float:
	if held_count <= 0 or _cards.is_empty():
		return 0.0
	if reduced_motion or not is_instance_valid(_portrait):
		sync_count(held_count - 1)
		return 0.0
	var card: TextureRect = _cards.pop_back()
	# A play can follow a draw before its visual flight has finished.
	for index in range(_flights.size() - 1, -1, -1):
		if _flights[index]["card"] == card:
			_flights.remove_at(index)
	var from_global := card.get_global_transform() * (card.size * 0.5)
	held_count -= 1
	_flights.append({
		"card": card, "kind": "play", "elapsed": 0.0,
		"duration": PLAY_SECONDS, "from_global": from_global,
		"to_global": to_global, "from_rotation": card.rotation,
	})
	_layout_cards()
	_apply_flight(_flights.back())
	return PLAY_SECONDS


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value and not _flights.is_empty():
		sync_count(held_count)


func is_animating() -> bool:
	return not _flights.is_empty()


func get_grip_global() -> Vector2:
	_update_geometry()
	return get_global_transform() * _source_to_local(_grip_source())


func get_play_departure_global() -> Vector2:
	_update_geometry()
	# Clear the fingers upward by the same proportion for every portrait. Keep
	# this independent of hand count so the following board flight joins here.
	var center := _source_to_local(_grip_source()) + Vector2.UP * _card_size_source().y * _source_scale * 1.4
	return get_global_transform() * center


func get_return_landing_pose() -> Dictionary:
	# Predict the incoming top sleeve without adding it ahead of its arrival.
	_update_geometry()
	var pose := _target_pose(held_count, held_count + 1)
	var card_size := _card_size_source() * _source_scale
	var angle: float = pose["angle"]
	var center: Vector2 = pose["anchor"] + Vector2(0, -card_size.y * 0.5).rotated(angle)
	var canvas_transform := get_global_transform_with_canvas()
	var horizontal := canvas_transform.basis_xform(Vector2.RIGHT.rotated(angle))
	var vertical := canvas_transform.basis_xform(Vector2.DOWN.rotated(angle))
	return {
		"center": canvas_transform * center,
		"size": card_size * Vector2(horizontal.length(), vertical.length()),
		"rotation": horizontal.angle(),
	}


func get_hand_global_rect() -> Rect2:
	# Bounds of the target fan, excluding a sleeve travelling to/from the deck.
	_update_geometry()
	var bounds := Rect2(get_grip_global(), Vector2.ZERO)
	var card_size := _card_size_source() * _source_scale
	for index in range(held_count):
		var pose := _target_pose(index)
		var anchor: Vector2 = pose["anchor"]
		var angle: float = pose["angle"]
		for corner in [Vector2(-card_size.x * 0.5, -card_size.y), Vector2(card_size.x * 0.5, -card_size.y), Vector2(card_size.x * 0.5, 0), Vector2(-card_size.x * 0.5, 0)]:
			bounds = bounds.expand(get_global_transform() * (anchor + corner.rotated(angle)))
	return bounds


func _process(delta: float) -> void:
	if not is_instance_valid(_portrait):
		return
	_update_geometry()
	_update_hand_overlay()
	_layout_cards()
	for index in range(_flights.size() - 1, -1, -1):
		var flight := _flights[index]
		flight["elapsed"] = float(flight["elapsed"]) + delta
		_apply_flight(flight)
		if float(flight["elapsed"]) < float(flight["duration"]):
			continue
		var card: TextureRect = flight["card"]
		_flights.remove_at(index)
		if flight["kind"] == "play":
			remove_child(card)
			card.queue_free()
		else:
			_place_card(card, _cards.find(card))


func _new_card() -> TextureRect:
	var card := TextureRect.new()
	_serial += 1
	card.name = "ConcealedHeldCard%02d" % _serial
	card.texture = SLEEVE
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_SCALE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("rival_held_card", true)
	card.set_meta("concealed", true)
	card.set_meta("is_face_down", true)
	add_child(card)
	return card


func _update_geometry() -> void:
	if not is_instance_valid(_portrait):
		return
	var previous_rect := _art_rect
	position = Vector2.ZERO
	size = _portrait.size
	_source_size = _portrait.texture.get_size() if _portrait.texture != null else MINA_CANVAS
	_source_scale = minf(size.x / maxf(1.0, _source_size.x), size.y / maxf(1.0, _source_size.y))
	_art_rect = Rect2((size - _source_size * _source_scale) * 0.5, _source_size * _source_scale)
	if _hand_overlay != null:
		var hand_roi := _hand_roi()
		_hand_overlay.position = _source_to_local(Vector2(hand_roi.position))
		_hand_overlay.size = Vector2(hand_roi.size) * _source_scale
	if _art_rect != previous_rect:
		queue_redraw()


func _hand_roi() -> Rect2i:
	return _pose.get("hand_roi", MINA_HAND_ROI)


func _source_to_local(point: Vector2) -> Vector2:
	return _art_rect.position + point * _source_scale


func _frame_delta() -> Vector2:
	if _cast_id == "mina" and is_instance_valid(_portrait):
		var current_frame: Variant = _portrait.get("frame_index")
		if current_frame != null and int(current_frame) >= 3:
			return Vector2(1, 0)
	return Vector2.ZERO


func _grip_source() -> Vector2:
	return Vector2(498, 565) + _frame_delta() if _cast_id == "mina" else _pose.get("grip", _source_size * Vector2(0.66, 0.80))


func _card_size_source() -> Vector2:
	return Vector2(88, 138) if _cast_id == "mina" else _pose.get("card_size", _source_size * Vector2(0.1255, 0.2197))


func _target_pose(index: int, count_override: int = -1) -> Dictionary:
	var count := held_count if count_override < 0 else count_override
	var fraction := float(index) / float(count - 1) - 0.5 if count > 1 else 0.0
	# The spread stops growing at five cards; higher counts compress within the
	# same fan while keeping exactly one visible sleeve node per real card.
	var spread := minf(36.0, maxf(0.0, float(count - 1) * 9.0))
	var pivot := Vector2(506, 585) + _frame_delta() if _cast_id == "mina" else _grip_source()
	pivot += Vector2(fraction * _card_size_source().x * 0.2273, absf(fraction) * 3.0)
	return {"anchor": _source_to_local(pivot), "angle": deg_to_rad(fraction * spread)}


func _layout_cards() -> void:
	for index in range(_cards.size()):
		var card := _cards[index]
		var in_flight := false
		for flight in _flights:
			if flight["card"] == card:
				in_flight = true
				break
		if not in_flight:
			_place_card(card, index)


func _place_card(card: TextureRect, index: int) -> void:
	if index < 0:
		return
	var pose := _target_pose(index)
	card.size = _card_size_source() * _source_scale
	card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
	card.position = Vector2(pose["anchor"]) - card.pivot_offset
	card.rotation = float(pose["angle"])
	card.modulate = Color.WHITE


func _apply_flight(flight: Dictionary) -> void:
	var card: TextureRect = flight["card"]
	var progress := clampf(float(flight["elapsed"]) / float(flight["duration"]), 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	card.size = _card_size_source() * _source_scale
	card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
	var inverse := get_global_transform().affine_inverse()
	var from: Vector2 = inverse * Vector2(flight["from_global"])
	var destination: Vector2
	var end_rotation := 0.0
	if flight["kind"] == "draw":
		var pose := _target_pose(_cards.find(card))
		end_rotation = float(pose["angle"])
		destination = Vector2(pose["anchor"]) + Vector2(0, -card.size.y * 0.5).rotated(end_rotation)
	else:
		destination = inverse * Vector2(flight["to_global"])
	card.rotation = lerpf(float(flight["from_rotation"]), end_rotation, eased)
	var arc_height := minf(28.0, _source_scale * 65.0)
	if flight["kind"] == "play" and destination.y < from.y:
		# An upward withdrawal eases straight out of the fingers; a sine arc
		# would overshoot and dip back down just before the card leaves.
		arc_height = 0.0
	var center := from.lerp(destination, eased) + Vector2(0, -sin(progress * PI) * arc_height)
	card.position = center - card.pivot_offset - (card.size * 0.5 - card.pivot_offset).rotated(card.rotation)
	card.modulate.a = 1.0 if flight["kind"] == "draw" else 1.0 - smoothstep(0.83, 1.0, progress)


func _update_hand_overlay() -> void:
	if _hand_overlay == null or not is_instance_valid(_portrait):
		return
	_hand_overlay.visible = supports_cast(_cast_id) and _portrait.texture != null
	if not _hand_overlay.visible or _portrait.texture == _last_texture:
		return
	_last_texture = _portrait.texture
	var key := _last_texture.get_instance_id()
	if not _hand_cache.has(key):
		_hand_cache[key] = _make_original_hand_overlay(_last_texture)
	_hand_overlay.texture = _hand_cache[key]


func _make_original_hand_overlay(source: Texture2D) -> Texture2D:
	var image := source.get_image()
	if image == null or image.is_empty():
		return null
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var original := image.get_region(_hand_roi())
	var width := original.get_width()
	var height := original.get_height()
	var pixels := original.get_data()
	var skin := PackedByteArray()
	skin.resize(width * height)
	for index in range(skin.size()):
		var offset := index * 4
		var is_skin := pixels[offset] > 180 and pixels[offset + 1] > 100 and pixels[offset + 1] < 205 and pixels[offset + 2] < 160
		if _cast_id != "mina":
			is_skin = pixels[offset] > 135 and pixels[offset] > pixels[offset + 1] * 1.2 and pixels[offset + 1] > pixels[offset + 2] * 1.2
		if pixels[offset + 3] > 0 and is_skin:
			skin[index] = 1
	# Two separable passes keep the source's dark finger contour. The generated
	# portraits have a wider source canvas and correspondingly wider ink.
	var contour_radius := 2 if _cast_id == "mina" else 4
	var horizontal := PackedByteArray()
	horizontal.resize(skin.size())
	for y in range(height):
		for x in range(width):
			for nx in range(maxi(0, x - contour_radius), mini(width, x + contour_radius + 1)):
				if skin[y * width + nx] != 0:
					horizontal[y * width + x] = 1
					break
	for y in range(height):
		for x in range(width):
			var retained := false
			for ny in range(maxi(0, y - contour_radius), mini(height, y + contour_radius + 1)):
				if horizontal[ny * width + x] != 0:
					retained = true
					break
			var offset := (y * width + x) * 4
			# Original ink is retained around fingers, but neighboring cream card
			# rims must not survive as fixed slivers in an empty live hand.
			if _cast_id != "mina" and skin[y * width + x] == 0:
				retained = retained and pixels[offset] < 85 and pixels[offset + 1] < 105
			if not retained:
				pixels[offset + 3] = 0
	# Retained RGB and alpha bytes are exactly those of the supplied frame.
	return ImageTexture.create_from_image(Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels))
