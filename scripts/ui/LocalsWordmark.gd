extends Control
class_name LocalsWordmark

## Owner-supplied hanging sign. Fit the visible artwork without changing its
## original pixels, colors, transparency or proportions.
const LOGO_TEXTURE := preload("res://assets/logos/see_you_at_locals_supplied.png")
const LOGO_SOURCE_REGION := Rect2(23, 314, 2132, 1055)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_meta("owner_supplied", true)
	set_meta("source_manifest", "res://assets/logos/see_you_at_locals_supplied.provenance.json")
	resized.connect(queue_redraw)
	queue_redraw()


func get_logo_rect() -> Rect2:
	var fit := minf(size.x / LOGO_SOURCE_REGION.size.x, size.y / LOGO_SOURCE_REGION.size.y)
	var drawn_size := LOGO_SOURCE_REGION.size * fit
	return Rect2((size - drawn_size) * 0.5, drawn_size)


func _draw() -> void:
	draw_texture_rect_region(LOGO_TEXTURE, get_logo_rect(), LOGO_SOURCE_REGION)
