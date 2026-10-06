extends Control

## A physical destination for collected pack cards. The owner supplies the
## committed deck count; arrival motion never changes saved or displayed totals.
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CARD_BACK := preload("res://assets/cards/card_backs/living_table.png")
const DESIGN_SIZE := Vector2(92, 104)
const TOP_CARD_RECT := Rect2(12, 1, 66, 88)

var card_count := 0
var _arrival := 0.0:
	set(value):
		_arrival = value
		queue_redraw()
var _arrival_tween: Tween


func _init() -> void:
	custom_minimum_size = DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _ready() -> void:
	resized.connect(queue_redraw)
	set_meta("asset_origin", "native_ui_with_supplied_card_back")
	set_card_count(card_count)


func set_card_count(count: int) -> void:
	card_count = maxi(count, 0)
	accessibility_name = "Your deck: %d cards" % card_count
	queue_redraw()


func get_landing_rect_global() -> Rect2:
	# Return the same complete texture rectangle used by _draw, including any
	# ancestor canvas transform. The travelling card can arrive without a snap.
	var design_transform := _design_transform()
	var top_rect := TOP_CARD_RECT
	top_rect.position.y += _arrival * 1.8
	return get_global_transform() * (design_transform * top_rect)


func play_arrival(reduced_motion: bool) -> void:
	if is_instance_valid(_arrival_tween):
		_arrival_tween.kill()
	_arrival = 0.0
	if reduced_motion or not is_inside_tree():
		return
	_arrival_tween = create_tween()
	_arrival_tween.tween_property(self, "_arrival", 1.0, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_arrival_tween.tween_property(self, "_arrival", 0.0, 0.17).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _design_transform() -> Transform2D:
	var fit := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	fit = maxf(fit, 0.0)
	return Transform2D(0.0, Vector2.ONE * fit, 0.0, (size - DESIGN_SIZE * fit) * 0.5)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_set_transform_matrix(_design_transform())
	var depth := clampf(float(card_count) * 0.32, 2.0, 10.0)
	var shadow := Rect2(18, 85 + depth, 60, 8)
	draw_style_box(_rounded_fill(Color(PALETTE.PEACH_INK, 0.13), 4), shadow)
	if card_count == 0:
		# Empty decks retain only a quiet footprint, never a phantom top card.
		draw_style_box(_rounded_fill(Color(PALETTE.PEACH_INK, 0.06), 4), Rect2(18, 10, 58, 80))
		return
	var layers := mini(card_count, 6)
	for layer in range(layers, 0, -1):
		var fraction := float(layer) / float(layers)
		var offset := Vector2(fraction * 2.5, depth * fraction + _arrival * 1.8 * (1.0 - fraction))
		var page := _sleeve_shape(TOP_CARD_RECT.position + offset)
		var paper := PALETTE.PEACH_PAPER_MUTED if layer % 2 == 0 else PALETTE.PEACH_PAPER
		draw_colored_polygon(page, paper)
		var edge := page.duplicate()
		edge.append(page[0])
		draw_polyline(edge, Color(PALETTE.PEACH_INK, 0.56), 0.8, true)
	var top_rect := TOP_CARD_RECT
	top_rect.position.y += _arrival * 1.8
	draw_texture_rect(CARD_BACK, top_rect, false)


func _sleeve_shape(origin: Vector2) -> PackedVector2Array:
	# Match the supplied sleeve's transparent margins and clipped corners so
	# the cream page edges emerge from beneath the actual back silhouette.
	return PackedVector2Array([
		origin + Vector2(10, 0.5), origin + Vector2(63, 0.5),
		origin + Vector2(63, 84), origin + Vector2(59, 87.5),
		origin + Vector2(5, 87.5), origin + Vector2(5, 5),
	])


func _rounded_fill(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
