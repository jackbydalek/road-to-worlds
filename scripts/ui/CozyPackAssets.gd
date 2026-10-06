extends RefCounted
class_name CozyPackAssets

## Supplied dobo_ui demo artwork, conventionally palette-mapped at load time.
## Source alpha and hand-drawn contours are preserved. No generative processing.
const P := preload("res://scripts/ui/GamePalette.gd")
const SOURCE := "res://assets/ui/dobo_cozy/source/"
const BUTTON_COLORS := [Color("fffeeb"), Color("97513e"), Color("fbd9cd"), Color("f8b3b6")]
const PANEL_COLORS := [Color("dd9a79"), Color("97513e"), Color("cc7f64"), Color("b05c4c")]
const CHECK_COLORS := [Color("ab9f9f"), Color("97513e"), Color("8a7e7e"), Color("fdfae7")]
static var _textures: Dictionary = {}
static var _styles: Dictionary = {}
static var _color_weights: Dictionary = {}


static func button_style(fill: Color, ink: Color = P.PEACH_INK, rounded := false) -> StyleBoxTexture:
	var name := "button_round" if rounded else "button_square"
	var target := [fill, ink, fill.lerp(ink, 0.12), fill.lerp(ink, 0.24)]
	var texture := _mapped_texture(name, BUTTON_COLORS, target)
	# Original corner widths remain fixed; the center strip stretches independently.
	var margins := Vector4(112, 76, 100, 78) if rounded else Vector4(80, 28, 56, 42)
	return _style(name + fill.to_html() + ink.to_html(), texture, margins, 0.30)


static func panel_style(fill: Color, ink: Color = P.PEACH_INK) -> StyleBoxTexture:
	return _style("panel" + fill.to_html() + ink.to_html(),
		_mapped_texture("panel", PANEL_COLORS, [fill, ink, fill.lerp(ink, 0.07), fill.lerp(ink, 0.13)]),
		Vector4(116, 64, 96, 68), 0.33)


static func note_style(fill: Color = P.PEACH_PAPER) -> StyleBoxTexture:
	# Keep the supplied perforations in the top-left cap, never stretched holes.
	return _style("note" + fill.to_html(),
		_mapped_texture("note", [Color("fffbed"), Color("f2e7db")],
		[fill.lightened(0.025), fill.lerp(P.PEACH_TABLE, 0.10)]),
		Vector4(76, 306, 42, 20), 0.32)


static func heart_texture() -> Texture2D:
	# The tiny warm life symbol is the supplied illustration, kept in our inks.
	return _mapped_texture("heart", [Color("f66369"), Color("a8254e"), Color("ffbcb0")],
		[P.SIGNAL_RED.lerp(P.PEACH_TABLE, 0.32), P.PEACH_INK, P.PEACH_PAPER])


static func health_track_style() -> StyleBoxTexture:
	return _style("health_track", _mapped_texture("health_track",
		[Color("fffeeb"), Color("97513e"), Color("fbd9cd")],
		[P.PEACH_PAPER, P.PEACH_INK, P.PEACH_PAPER_MUTED]), Vector4(36, 12, 36, 12), 24.0 / 69.0)


static func health_fill_style(fill: Color = P.PEACH_HEALTH) -> StyleBoxTexture:
	return _style("health_fill" + fill.to_html(), _mapped_texture("health_fill",
		[Color("ffdf87"), Color("f8ae66")],
		[fill, fill.lerp(P.PEACH_INK, 0.16)]), Vector4(27, 8, 27, 8), 24.0 / 69.0)


static func checkbox_texture(checked: bool, disabled := false) -> Texture2D:
	var fill := P.PEACH_PAPER_MUTED if disabled else P.PEACH_TEAL if checked else P.PEACH_PAPER
	var ink := P.PEACH_EDGE if disabled else P.PEACH_INK
	var mark := P.PEACH_INK_SOFT if disabled else P.PEACH_PAPER
	return _mapped_texture("check_on" if checked else "check_off", CHECK_COLORS,
		[fill, ink, fill.lerp(ink, 0.15), mark], Vector2i(24, 26))


static func arrow_texture(direction: String, fill: Color = P.PEACH_TEAL) -> Texture2D:
	assert(direction in ["left", "right", "up", "down"])
	return _mapped_texture("arrow_" + direction, [Color("fffeeb"), Color("97513e"), Color("fbd9cd")],
		[fill, P.PEACH_INK, fill.lerp(P.PEACH_INK, 0.15)])


static func _style(key: String, texture: Texture2D, margins: Vector4, scale: float) -> StyleBoxTexture:
	if _styles.has(key):
		return _styles[key]
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margins[side])
		style.set_content_margin(side, 0.0)
	style.set_meta("cozy_draw_scale", scale)
	_styles[key] = style
	return style


static func draw_style(canvas: CanvasItem, style: StyleBoxTexture, rect: Rect2) -> void:
	# Keep the full-resolution texture in GPU memory. Scaling the drawing rather
	# than shrinking its pixels keeps blue contours sharp on high-DPI displays.
	var scale := float(style.get_meta("cozy_draw_scale", 1.0))
	var border_size := Vector2(style.get_texture_margin(SIDE_LEFT) + style.get_texture_margin(SIDE_RIGHT),
		style.get_texture_margin(SIDE_TOP) + style.get_texture_margin(SIDE_BOTTOM))
	scale = minf(scale, minf(rect.size.x / maxf(1.0, border_size.x), rect.size.y / maxf(1.0, border_size.y)))
	if scale <= 0.0:
		return
	canvas.draw_set_transform(rect.position, 0, Vector2.ONE * scale)
	canvas.draw_style_box(style, Rect2(Vector2.ZERO, rect.size / scale))
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _mapped_texture(name: String, source_colors: Array, target_colors: Array, target_size := Vector2i.ZERO) -> Texture2D:
	var key := name + str(target_size)
	for color: Color in target_colors:
		key += color.to_html()
	if _textures.has(key):
		return _textures[key]
	# Source files stay untouched; the cached ImageTexture is an ordinary UI skin.
	var source: Texture2D = load(SOURCE + name + ".png")
	var original := source.get_image()
	if original.is_compressed():
		original.decompress()
	original.convert(Image.FORMAT_RGBA8)
	var bytes := original.get_data()
	var palette_key := str(source_colors)
	var weights: Dictionary = _color_weights.get(palette_key, {})
	for offset in range(0, bytes.size(), 4):
		if bytes[offset + 3] == 0:
			continue
		var rgb := (int(bytes[offset]) << 16) | (int(bytes[offset + 1]) << 8) | int(bytes[offset + 2])
		if not weights.has(rgb):
			weights[rgb] = _nearest_pair(Vector3(bytes[offset], bytes[offset + 1], bytes[offset + 2]) / 255.0, source_colors)
		var pair: Vector3 = weights[rgb]
		var mapped: Color = target_colors[int(pair.x)].lerp(target_colors[int(pair.y)], pair.z)
		bytes[offset] = roundi(clampf(mapped.r, 0, 1) * 255)
		bytes[offset + 1] = roundi(clampf(mapped.g, 0, 1) * 255)
		bytes[offset + 2] = roundi(clampf(mapped.b, 0, 1) * 255)
	_color_weights[palette_key] = weights
	var result := Image.create_from_data(original.get_width(), original.get_height(), false, Image.FORMAT_RGBA8, bytes)
	if target_size != Vector2i.ZERO:
		result.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var texture := ImageTexture.create_from_image(result)
	_textures[key] = texture
	return texture


static func _nearest_pair(pixel: Vector3, palette: Array) -> Vector3:
	# Antialiased source RGB lies between paint colors. Mapping the nearest pair
	# preserves that blend rather than leaving a brown fringe at transparent edges.
	var best := INF
	var answer := Vector3.ZERO
	for a in palette.size():
		var start := Vector3(palette[a].r, palette[a].g, palette[a].b)
		for b in range(a, palette.size()):
			var finish := Vector3(palette[b].r, palette[b].g, palette[b].b)
			var delta := finish - start
			var weight := clampf((pixel - start).dot(delta) / delta.length_squared(), 0.0, 1.0) if delta.length_squared() > 0.00001 else 0.0
			var error := pixel.distance_squared_to(start.lerp(finish, weight))
			if error < best:
				best = error
				answer = Vector3(a, b, weight)
	return answer
