extends RefCounted
class_name TopdeckUIComponents

## Production UI primitives for the run-facing game. These components implement
## ART_DIRECTION.md's printed scorecards, friendly type, and clear action
## colors. Legacy screen helpers remain available only while screens migrate.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const ANGULAR_SURFACE_SCRIPT := preload("res://scripts/ui/BattleAngularSurface.gd")
const DISPLAY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

const SCREEN_MARGIN := 18
const PANEL_MARGIN := Vector4(22, 16, 22, 18)
const SECTION_MARGIN := Vector4(16, 12, 16, 14)
const CONTROL_HEIGHT := 46


static func make_hud_bar(
	eyebrow: String,
	title: String,
	accent: Color = PALETTE.PEACH_TEAL,
	minimum_height: float = 78.0
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionHudBar",
		PALETTE.PEACH_PAPER,
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
	identity.add_child(make_label(eyebrow, "eyebrow", _paper_accent(accent)))
	identity.add_child(make_label(title, "hud_title", PALETTE.PEACH_INK))

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
	chip.text = text
	chip.custom_minimum_size = Vector2(134, 40)
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_theme_font_override("font", BODY_FONT)
	chip.add_theme_font_size_override("font_size", 15)
	chip.add_theme_color_override("font_color", PALETTE.PEACH_INK)
	chip.add_theme_stylebox_override("normal", stat_chip_style(accent))
	return chip


static func stat_chip_style(accent: Color) -> StyleBoxFlat:
	var style := paper_style(PALETTE.PEACH_PAPER.lightened(0.015).lerp(accent, 0.025), 0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
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
		PALETTE.PEACH_PAPER,
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
		header.add_child(make_label(eyebrow, "eyebrow", _paper_accent(accent)))
	if not title.is_empty():
		header.add_child(make_label(title, "screen_title", PALETTE.PEACH_INK))
	if not subtitle.is_empty():
		header.add_child(make_label(subtitle, "body", PALETTE.PEACH_INK_SOFT))
	if not stats_text.is_empty():
		var stats := make_label(stats_text, "status", PALETTE.SIGNAL_YELLOW.darkened(0.54))
		stats.name = "EncounterStats"
		header.add_child(stats)

	var divider := ColorRect.new()
	divider.name = "EncounterAccentDivider"
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = PALETTE.PEACH_EDGE
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
			PALETTE.PEACH_PAPER_MUTED,
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
	accent: Color = PALETTE.PEACH_TEAL,
	minimum_size: Vector2 = Vector2.ZERO
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionSection",
		PALETTE.PEACH_PAPER_MUTED.lightened(0.025),
		Color(accent, 0.82),
		minimum_size,
		SECTION_MARGIN,
		false
	)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 9)
	if not title.is_empty():
		body.add_child(make_label(title, "section", PALETTE.PEACH_INK))
	return parts


static func make_reward_header(
	title: String,
	instruction: String,
	stats_text: String,
	accent: Color = PALETTE.PEACH_TEAL
) -> Dictionary:
	var parts := make_surface_panel(
		"ProductionRewardHeader",
		PALETTE.PEACH_PAPER,
		accent,
		Vector2(0, 72 if instruction.is_empty() else 112),
		Vector4(22, 12, 22, 12),
		false
	)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 4)
	var heading := make_label(title, "section", PALETTE.PEACH_INK)
	var detail := make_label(instruction, "small", PALETTE.PEACH_INK_SOFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var stats := make_label(stats_text, "small", PALETTE.SIGNAL_YELLOW.darkened(0.54))
	body.add_child(heading)
	detail.visible = not instruction.is_empty()
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
	button.custom_minimum_size = Vector2(minimum_size.x, maxf(CONTROL_HEIGHT, minimum_size.y))
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", false)
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_font_size_override("font_size", 16)
	return button


static func _paper_accent(accent: Color) -> Color:
	# Eyebrows can arrive in any affinity color, including bright yellow. Keep
	# their identity while giving small printed text a readable ink value.
	var ink := Color(accent, 1.0)
	var paper_luminance := PALETTE.PEACH_PAPER.srgb_to_linear().get_luminance()
	for _step in range(12):
		var contrast := (paper_luminance + 0.05) / (ink.srgb_to_linear().get_luminance() + 0.05)
		if contrast >= 4.5:
			break
		ink = ink.lerp(PALETTE.PEACH_INK, 0.16)
	return ink


static func make_label(text: String, role: String = "body", color: Color = Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var font: Font = BODY_FONT
	var font_size := 16
	var fallback_color := PALETTE.PEACH_INK_SOFT
	match role:
		"eyebrow":
			font = DISPLAY_FONT
			font_size = 13
			fallback_color = _paper_accent(PALETTE.PEACH_TEAL)
		"hud_title":
			font = DISPLAY_FONT
			font_size = 24
			fallback_color = PALETTE.PEACH_INK
		"screen_title":
			font = DISPLAY_FONT
			font_size = 38
			fallback_color = PALETTE.PEACH_INK
		"section":
			font = DISPLAY_FONT
			font_size = 21
			fallback_color = PALETTE.PEACH_INK
		"status":
			font_size = 15
			fallback_color = PALETTE.SIGNAL_YELLOW.darkened(0.54)
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
	show_inner_keyline: bool = false
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


static func flat_style(fill: Color, padding: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func paper_style(fill: Color = PALETTE.PEACH_PAPER, padding: int = 16) -> StyleBoxFlat:
	return SHAPES.style(fill, Vector4(padding, padding, padding, padding))


static func style_scroll(scroll: ScrollContainer) -> void:
	for bar in [scroll.get_v_scroll_bar(), scroll.get_h_scroll_bar()]:
		for state in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			var fill := PALETTE.PEACH_PAPER_MUTED if state == "scroll" else PALETTE.PEACH_TEAL if state in ["grabber_highlight", "grabber_pressed"] else PALETTE.PEACH_EDGE
			var style := flat_style(fill, 5)
			style.set_corner_radius_all(4)
			bar.add_theme_stylebox_override(state, style)


static func enter(control: Control) -> void:
	if not control.is_inside_tree() or bool(control.get_tree().root.get_meta("reduced_motion", false)):
		return
	control.modulate.a = 0.0
	control.create_tween().tween_property(control, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func toast(source: Control, message: String, variant: String = "confirm") -> void:
	var root := source.get_tree().root
	for previous in source.get_tree().get_nodes_in_group("ui_feedback"):
		previous.queue_free()
	var feedback := PanelContainer.new()
	feedback.name = "ActionFeedback"
	feedback.add_to_group("ui_feedback")
	feedback.z_index = 4000
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.add_theme_stylebox_override("panel", paper_style())
	var color := PALETTE.ACTION_DANGER.darkened(0.24) if variant == "danger" else PALETTE.SIGNAL_YELLOW.darkened(0.54) if variant == "reward" else PALETTE.HEALTH_FILL
	feedback.add_child(make_label(message, "section", color))
	root.add_child(feedback)
	feedback.size = feedback.get_combined_minimum_size()
	feedback.position = Vector2((source.get_viewport_rect().size.x - feedback.size.x) * 0.5, source.get_viewport_rect().size.y - 140)
	enter(feedback)
	root.get_tree().create_timer(1.5).timeout.connect(feedback.queue_free)
