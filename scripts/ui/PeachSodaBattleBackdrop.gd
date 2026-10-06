extends Control
class_name PeachSodaBattleBackdrop

## The owner's separate room and tabletop paintings sit below live rivals,
## cards and UI. Source textures stay unchanged and are imported only once.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ROOM_TEXTURE := preload("res://assets/illustrations/supplied_locals_2026_09_14/battle_background.png")
const TABLE_TEXTURE := preload("res://assets/illustrations/supplied_locals_2026_09_14/battle_table.png")
const DESIGN_SIZE := Vector2(1600.0, 1000.0)
const TABLE_HORIZON := 330.0
const SOURCE_SIZE := Vector2(3840.0, 2304.0)
# Preserve the painted edge, excluding isolated marks in the transparent area.
const TABLE_SOURCE_REGION := Rect2(0.0, 686.0, 3840.0, 1618.0)

var table_horizon := TABLE_HORIZON
var _room_layer: Node2D
var _table_layer: Node2D


func set_table_horizon_from_local_y(local_y: float) -> void:
	if size.y <= 0.0:
		return
	var design_y := clampf(local_y * DESIGN_SIZE.y / size.y, 0.0, DESIGN_SIZE.y)
	if is_equal_approx(table_horizon, design_y):
		return
	table_horizon = design_y
	_layout_paint_layers()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_meta("asset_origin", "owner_supplied_art")
	set_meta("replacement_registry", "res://assets/illustrations/supplied_locals_2026_09_14/manifest.json")
	# Camera impact only transforms two retained CanvasItems. It never rebuilds
	# image textures or drawing commands during the attack animation.
	_room_layer = _add_paint_layer("RoomPaint", _draw_room)
	_table_layer = _add_paint_layer("TablePaint", _draw_table)
	resized.connect(_layout_paint_layers)
	_layout_paint_layers()


func _add_paint_layer(layer_name: String, paint: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	var canvas := Control.new()
	canvas.name = "PaintCanvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.size = DESIGN_SIZE
	canvas.draw.connect(paint.bind(canvas))
	layer.add_child(canvas)
	add_child(layer)
	return layer


func _layout_paint_layers() -> void:
	if not is_instance_valid(_room_layer):
		return
	var canvas_scale := size / DESIGN_SIZE
	# Room objects retain their authored proportions at every aspect ratio.
	# Only the tabletop stretches to meet the live board's projected far edge.
	_room_layer.scale = Vector2.ONE * canvas_scale.x
	var table_stretch := maxf(0.0, (DESIGN_SIZE.y - table_horizon) / (DESIGN_SIZE.y - TABLE_HORIZON))
	_table_layer.visible = table_stretch > 0.0
	_table_layer.scale = Vector2(canvas_scale.x, canvas_scale.y * maxf(0.00001, table_stretch))
	_table_layer.position = Vector2(0.0, canvas_scale.y * (table_horizon - TABLE_HORIZON * table_stretch))


func _draw_room(canvas: Control) -> void:
	# Back the source's transparent lower edge with quiet paper so even extreme
	# debug camera positions cannot expose a black clear color beneath it.
	canvas.draw_rect(Rect2(0.0, 0.0, DESIGN_SIZE.x, DESIGN_SIZE.y * 4.0), PALETTE.PEACH_PAPER)
	var art_size := SOURCE_SIZE * (DESIGN_SIZE.x / SOURCE_SIZE.x)
	canvas.draw_texture_rect(ROOM_TEXTURE, Rect2(Vector2.ZERO, art_size), false)


func _draw_table(canvas: Control) -> void:
	var table_rect := Rect2(0.0, TABLE_HORIZON, DESIGN_SIZE.x, DESIGN_SIZE.y - TABLE_HORIZON)
	canvas.draw_texture_rect_region(TABLE_TEXTURE, table_rect, TABLE_SOURCE_REGION)
