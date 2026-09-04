extends RefCounted
class_name TopdeckUIComponents

## Production UI primitives for the run-facing game. These components implement
## ART_DIRECTION.md's cool neutral chassis, clipped geometry, and semantic state
## colors. Legacy screen helpers remain available only while screens migrate.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ANGULAR_SURFACE_SCRIPT := preload("res://scripts/ui/BattleAngularSurface.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

const SCREEN_MARGIN := 18
const PANEL_MARGIN := Vector4(22, 16, 22, 18)
const SECTION_MARGIN := Vector4(16, 12, 16, 14)
const CONTROL_HEIGHT := 46


static func make_hud_bar(
	eyebrow: String,
	title: String,
	accent: Color = PALETTE.FOCUS_EDGE,
	minimum_height: float = 78.0
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionHudBar",
		PALETTE.SURFACE_RAISED,
		accent,
		Vector2(0, minimum_height),
		Vector4(22, 10, 18, 10),
		true
	)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 0)

	var row := HBoxContainer.new()
	row.name = "ProductionHudRow"
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)

	var identity := VBoxContainer.new()
	identity.name = "ProductionHudIdentity"
	identity.custom_minimum_size = Vector2(210, 0)
	identity.add_theme_constant_override("separation", 0)
	row.add_child(identity)
	identity.add_child(make_label(eyebrow.to_upper(), "eyebrow", accent))
	identity.add_child(make_label(title.to_upper(), "hud_title", PALETTE.TEXT_PRIMARY))

	var stats := HBoxContainer.new()
	stats.name = "ProductionHudStats"
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 8)
	row.add_child(stats)

	parts["row"] = row
	parts["stats"] = stats
	parts["identity"] = identity
	return parts


static func make_stat_chip(text: String, accent: Color, node_name: String = "ProductionStatChip") -> Label:
	var chip := Label.new()
	chip.name = node_name
	chip.text = text.to_upper()
	chip.custom_minimum_size = Vector2(134, 40)
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_theme_font_override("font", BODY_FONT)
	chip.add_theme_font_size_override("font_size", 15)
	chip.add_theme_color_override("font_color", PALETTE.TEXT_PRIMARY)
	chip.add_theme_stylebox_override("normal", stat_chip_style(accent))
	return chip


static func stat_chip_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.SURFACE_ROOT.lightened(0.035)
	style.border_color = PALETTE.SURFACE_SECONDARY.darkened(0.12)
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.border_color = accent
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


static func make_encounter_shell(
	node_name: String,
	eyebrow: String,
	title: String,
	subtitle: String,
	accent: Color,
	stats_text: String = "",
	media_texture: Texture2D = null,
	media_name: String = "EncounterArtwork"
) -> Dictionary:
	var parts := make_surface_panel(
		node_name,
		PALETTE.SURFACE_RAISED,
		accent,
		Vector2(0, 680),
		Vector4(30, 24, 30, 28),
		true
	)
	(parts.panel as PanelContainer).size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 14)

	var header := VBoxContainer.new()
	header.name = "EncounterHeader"
	header.add_theme_constant_override("separation", 3)
	body.add_child(header)
	if not eyebrow.is_empty():
		header.add_child(make_label(eyebrow.to_upper(), "eyebrow", accent))
	if not title.is_empty():
		header.add_child(make_label(title.to_upper(), "screen_title", PALETTE.TEXT_PRIMARY))
	if not subtitle.is_empty():
		header.add_child(make_label(subtitle, "body", PALETTE.TEXT_SECONDARY))
	if not stats_text.is_empty():
		var stats := make_label(stats_text, "status", PALETTE.STATE_REWARD)
		stats.name = "EncounterStats"
		header.add_child(stats)

	var divider := ColorRect.new()
	divider.name = "EncounterAccentDivider"
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = accent
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(divider)

	var columns := HBoxContainer.new()
	columns.name = "EncounterColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	body.add_child(columns)

	var media: PanelContainer
	if media_texture != null:
		var media_parts := make_surface_panel(
			"EncounterMediaPanel",
			PALETTE.SURFACE_ROOT,
			accent.darkened(0.08),
			Vector2(270, 0),
			Vector4(18, 18, 18, 18),
			false
		)
		media = media_parts.panel as PanelContainer
		media.size_flags_vertical = Control.SIZE_EXPAND_FILL
		columns.add_child(media)
		var media_body := media_parts.body as VBoxContainer
		media_body.alignment = BoxContainer.ALIGNMENT_CENTER
		var artwork := TextureRect.new()
		artwork.name = media_name
		artwork.texture = media_texture
		artwork.custom_minimum_size = Vector2(220, 260)
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
		media_body.add_child(artwork)

	var copy := VBoxContainer.new()
	copy.name = "EncounterContent"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 12)
	columns.add_child(copy)

	var actions := HBoxContainer.new()
	actions.name = "EncounterActions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)

	parts["header"] = header
	parts["columns"] = columns
	parts["media"] = media
	parts["content"] = copy
	parts["actions"] = actions
	return parts


static func make_section(
	title: String,
	accent: Color = PALETTE.FOCUS_EDGE,
	minimum_size: Vector2 = Vector2.ZERO
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionSection",
		PALETTE.SURFACE_ROOT.lightened(0.025),
		Color(accent, 0.82),
		minimum_size,
		SECTION_MARGIN,
		false
	)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 9)
	if not title.is_empty():
		body.add_child(make_label(title.to_upper(), "section", PALETTE.TEXT_PRIMARY))
	return parts


static func make_reward_header(
	title: String,
	instruction: String,
	stats_text: String,
	accent: Color = PALETTE.FOCUS_EDGE
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionRewardHeader",
		PALETTE.SURFACE_RAISED,
		accent,
		Vector2(0, 112),
		Vector4(22, 12, 22, 12),
		true
	)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 4)
	var heading := make_label(title.to_upper(), "section", PALETTE.TEXT_PRIMARY)
	var detail := make_label(instruction, "small", PALETTE.TEXT_SECONDARY)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var stats := make_label(stats_text, "small", PALETTE.STATE_REWARD)
	body.add_child(heading)
	body.add_child(detail)
	body.add_child(stats)
	parts["title"] = heading
	parts["instruction"] = detail
	parts["stats"] = stats
	return parts


static func make_button(
	text: String,
	variant: String = "secondary",
	minimum_size: Vector2 = Vector2(0, CONTROL_HEIGHT),
	node_name: String = ""
) -> Button:
	var button := Button.new()
	if not node_name.is_empty():
		button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", false)
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_font_size_override("font_size", 16)
	return button


static func make_label(text: String, role: String = "body", color: Color = Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var font: Font = BODY_FONT
	var font_size := 16
	var fallback_color := PALETTE.TEXT_SECONDARY
	match role:
		"eyebrow":
			font = DISPLAY_FONT
			font_size = 13
			fallback_color = PALETTE.FOCUS_EDGE
		"hud_title":
			font = DISPLAY_FONT
			font_size = 24
			fallback_color = PALETTE.TEXT_PRIMARY
		"screen_title":
			font = DISPLAY_FONT
			font_size = 38
			fallback_color = PALETTE.TEXT_PRIMARY
		"section":
			font = DISPLAY_FONT
			font_size = 21
			fallback_color = PALETTE.TEXT_PRIMARY
		"status":
			font_size = 15
			fallback_color = PALETTE.STATE_REWARD
		"small":
			font_size = 14
		"muted":
			font_size = 15
		"body":
			font_size = 17
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", fallback_color if color == Color.TRANSPARENT else color)
	if role in ["body", "muted", "small"]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func make_surface_panel(
	node_name: String,
	fill: Color,
	accent: Color,
	minimum_size: Vector2 = Vector2.ZERO,
	margins: Vector4 = PANEL_MARGIN,
	show_inner_keyline: bool = true
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var surface = ANGULAR_SURFACE_SCRIPT.new()
	surface.name = "%sSurface" % node_name
	surface.show_behind_parent = true
	surface.configure(fill, accent, fill.get_luminance() < 0.56, show_inner_keyline)
	panel.add_child(surface)

	var margin := MarginContainer.new()
	margin.name = "%sMargin" % node_name
	margin.add_theme_constant_override("margin_left", int(margins.x))
	margin.add_theme_constant_override("margin_top", int(margins.y))
	margin.add_theme_constant_override("margin_right", int(margins.z))
	margin.add_theme_constant_override("margin_bottom", int(margins.w))
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.name = "%sBody" % node_name
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	return {"panel": panel, "surface": surface, "pattern": panel.get_node_or_null("%sPattern" % node_name), "body": body}
