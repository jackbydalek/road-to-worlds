extends RefCounted
class_name SketchUIComponents

const INK := Color("#241B17")
const MUTED_INK := Color("#65584E")
const PAPER := Color("#FFFAF0")
const TEAL := Color("#2D6F6A")
const ORANGE := Color("#E06B4F")
const MUSTARD := Color("#F0B34D")

const DISPLAY_FONT := preload("res://assets/fonts/ArchivoNarrow-Regular.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const BUTTON_PAPER_A := preload("res://assets/ui/wired_title/button_paper_a.svg")
const BUTTON_PAPER_B := preload("res://assets/ui/wired_title/button_paper_b.svg")
const BUTTON_PRIMARY := preload("res://assets/ui/wired_title/button_primary.svg")
const BUTTON_COMPACT_A := preload("res://assets/ui/wired_title/button_compact_a.svg")
const BUTTON_COMPACT_B := preload("res://assets/ui/wired_title/button_compact_b.svg")
const BUTTON_COMPACT_PRIMARY := preload("res://assets/ui/wired_title/button_compact_primary.svg")
const PANEL_PAPER := preload("res://assets/ui/wired_title/panel_paper.svg")
const TITLE_PAPER := preload("res://assets/ui/wired_title/title_paper.svg")
const DRAFT_STAR := preload("res://assets/ui/wired_title/draft_star.svg")
const ROUGH_PANEL_SCRIPT := preload("res://scripts/ui/SketchPanelContainer.gd")


static func make_button(
	label: String,
	minimum_size: Vector2,
	primary: bool = false,
	font_size: int = 34,
	alternate_outline: bool = false
) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = minimum_size
	var texture := BUTTON_PRIMARY if primary else (BUTTON_PAPER_B if alternate_outline else BUTTON_PAPER_A)
	button.add_theme_stylebox_override("normal", texture_style(texture, Color.WHITE, Vector4(24, 22, 24, 22), Vector4(28, 15, 28, 17)))
	button.add_theme_stylebox_override("hover", texture_style(texture, Color(1.08, 1.08, 1.08, 1.0), Vector4(24, 22, 24, 22), Vector4(28, 15, 28, 17)))
	button.add_theme_stylebox_override("pressed", texture_style(texture, Color(0.88, 0.88, 0.88, 1.0), Vector4(24, 22, 24, 22), Vector4(28, 18, 28, 14)))
	button.add_theme_stylebox_override("disabled", texture_style(texture, Color(0.69, 0.69, 0.69, 0.72), Vector4(24, 22, 24, 22), Vector4(28, 15, 28, 17)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#766F67"))
	button.add_theme_font_override("font", display_font(0.72))
	button.add_theme_font_size_override("font_size", font_size)
	return button


static func make_panel(
	minimum_size: Vector2,
	content_margins: Vector4 = Vector4(28, 26, 28, 28)
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override(
		"panel",
		texture_style(PANEL_PAPER, Color.WHITE, Vector4(24, 24, 24, 24), content_margins)
	)
	return panel


static func make_rough_panel(
	minimum_size: Vector2,
	fill: Color = PAPER,
	outline: Color = INK,
	accent: Color = Color.TRANSPARENT,
	content_margins: Vector4 = Vector4(28, 26, 28, 28),
	variant: int = 0
) -> PanelContainer:
	var panel = ROUGH_PANEL_SCRIPT.new()
	panel.custom_minimum_size = minimum_size
	panel.configure(fill, outline, accent, content_margins, variant)
	return panel


static func make_section_banner(
	title: String,
	subtitle: String,
	minimum_size: Vector2,
	accent: Color = TEAL
) -> PanelContainer:
	var panel := make_rough_panel(
		minimum_size,
		PAPER,
		INK,
		accent,
		Vector4(38, 20, 38, 24),
		1
	)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -2)
	panel.add_child(copy)

	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", display_font(0.88))
	heading.add_theme_font_size_override("font_size", 43)
	heading.add_theme_color_override("font_color", INK)
	copy.add_child(heading)

	if subtitle != "":
		var detail := Label.new()
		detail.text = subtitle
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_override("font", body_font(0.16))
		detail.add_theme_font_size_override("font_size", 17)
		detail.add_theme_color_override("font_color", MUTED_INK)
		copy.add_child(detail)
	return panel


static func make_arrow_button(direction: int, minimum_size: Vector2 = Vector2(72, 72)) -> Button:
	var button := make_button("←" if direction < 0 else "→", minimum_size, false, 38, direction > 0)
	button.tooltip_text = "Previous" if direction < 0 else "Next"
	return button


static func make_pip(selected: bool, accent: Color = TEAL) -> PanelContainer:
	var fill := accent if selected else PAPER
	var panel := make_rough_panel(
		Vector2(31, 29),
		fill,
		INK,
		Color.TRANSPARENT,
		Vector4(3, 3, 3, 3),
		1 if selected else 0
	)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


static func make_draft_star(minimum_size: Vector2 = Vector2(86, 82)) -> TextureRect:
	var star := TextureRect.new()
	star.texture = DRAFT_STAR
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.custom_minimum_size = minimum_size
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return star


static func make_badge(
	text: String,
	background: Color,
	foreground: Color = INK,
	minimum_size: Vector2 = Vector2.ZERO
) -> PanelContainer:
	var badge := make_rough_panel(
		minimum_size,
		background,
		foreground,
		Color.TRANSPARENT,
		Vector4(9, 5, 9, 6),
		1
	)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", body_font(0.42))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", foreground)
	badge.add_child(label)
	return badge


static func make_list_row(
	minimum_size: Vector2 = Vector2(0, 42),
	accent: Color = TEAL,
	variant: int = 0
) -> PanelContainer:
	return make_rough_panel(
		minimum_size,
		PAPER,
		INK,
		accent,
		Vector4(14, 8, 14, 9),
		variant
	)


static func make_progress_bar(minimum_size: Vector2 = Vector2(0, 24)) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.custom_minimum_size = minimum_size
	progress.add_theme_stylebox_override("background", flat_style(Color("#E1D7C2"), INK, 1))
	progress.add_theme_stylebox_override("fill", flat_style(TEAL, INK, 1))
	progress.add_theme_color_override("font_color", PAPER)
	progress.add_theme_font_override("font", body_font(0.42))
	return progress


static func flat_style(
	background: Color,
	border: Color,
	border_width: int = 1,
	content_margins: Vector4 = Vector4.ZERO
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	style.anti_aliasing = true
	return style


static func make_title_panel(title: String, subtitle: String, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override(
		"panel",
		texture_style(TITLE_PAPER, Color.WHITE, Vector4(30, 28, 30, 28), Vector4(54, 27, 54, 36))
	)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -3)
	panel.add_child(copy)

	var eyebrow := Label.new()
	eyebrow.text = "A KITCHEN TABLE CARD GAME"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", body_font(0.45))
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", TEAL)
	copy.add_child(eyebrow)

	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", display_font(0.95))
	heading.add_theme_font_size_override("font_size", 70)
	heading.add_theme_color_override("font_color", INK)
	copy.add_child(heading)

	var deck_line := Label.new()
	deck_line.text = subtitle
	deck_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_line.add_theme_font_override("font", body_font(0.18))
	deck_line.add_theme_font_size_override("font_size", 19)
	deck_line.add_theme_color_override("font_color", MUTED_INK)
	copy.add_child(deck_line)
	return panel


static func make_note_card(
	heading_text: String,
	lines: Array[String],
	minimum_size: Vector2,
	accent: Color
) -> PanelContainer:
	var panel := make_panel(minimum_size, Vector4(30, 28, 30, 30))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)

	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_override("font", display_font(0.78))
	heading.add_theme_font_size_override("font_size", 29)
	heading.add_theme_color_override("font_color", accent)
	body.add_child(heading)

	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", line_style(accent, 2))
	body.add_child(divider)

	for index in range(lines.size()):
		var line := Label.new()
		line.text = "%02d  %s" % [index + 1, lines[index]]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_override("font", body_font(0.22))
		line.add_theme_font_size_override("font_size", 18)
		line.add_theme_color_override("font_color", INK)
		body.add_child(line)
	return panel


static func texture_style(
	texture: Texture2D,
	tint: Color,
	texture_margins: Vector4,
	content_margins: Vector4
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


static func line_style(color: Color, thickness: int) -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = color
	style.thickness = thickness
	return style


static func display_font(embolden: float = 0.0) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = DISPLAY_FONT
	font.variation_embolden = embolden
	return font


static func body_font(embolden: float = 0.0) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = BODY_FONT
	font.variation_embolden = embolden
	return font
