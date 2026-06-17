extends RefCounted
class_name CardFrameFactory


func add_frame(parent: Node, data: Dictionary, options: Dictionary = {}) -> VBoxContainer:
	var compact := bool(options.get("compact", false))
	var prefix := String(options.get("name_prefix", "CardFrame"))

	var panel := PanelContainer.new()
	panel.name = String(options.get("panel_name", "CardFramePanel"))
	panel.custom_minimum_size = options.get("min_size", Vector2(104, 136) if compact else Vector2(244, 0))
	panel.size_flags_horizontal = int(options.get("size_flags_horizontal", Control.SIZE_EXPAND_FILL))
	panel.mouse_filter = int(options.get("mouse_filter", Control.MOUSE_FILTER_PASS))
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	panel.clip_contents = bool(options.get("clip_contents", false))

	var style := StyleBoxFlat.new()
	style.bg_color = _color(data.get("frame_color", Color("#202734")), Color("#202734"))
	style.border_color = _color(options.get("border_color", data.get("border_color", Color("#465060"))), Color("#465060"))
	var border_width := int(options.get("border_width", data.get("border_width", 1)))
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact else 8)
	margin.add_theme_constant_override("margin_right", 4 if compact else 8)
	margin.add_theme_constant_override("margin_top", 3 if compact else 8)
	margin.add_theme_constant_override("margin_bottom", 3 if compact else 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = String(options.get("contents_name", "CardFrameContents"))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2 if compact else 6)
	margin.add_child(box)

	_add_title_row(box, data, prefix, compact)
	_add_art_box(box, data, prefix, compact)
	_add_type_strip(box, data, prefix, compact)
	_add_meta_line(box, data, prefix, compact)
	_add_effect_text(box, data, prefix, compact)

	if bool(options.get("show_deck_stats", false)):
		_add_optional_line(box, prefix + "DeckStats", String(data.get("deck_stats", "")), Color("#a9c7ff"), 8 if compact else 12, compact)
	if bool(options.get("show_rules_text", false)):
		var rules_text := String(data.get("rules_text", ""))
		if rules_text != "" and rules_text != String(data.get("effect_text", "")):
			_add_optional_line(box, prefix + "Text", rules_text, Color("#c7d0df"), 8 if compact else 12, compact)

	_add_bottom_row(box, data, prefix, compact)
	return box


func _add_title_row(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	var row := HBoxContainer.new()
	row.name = prefix + "TitleRow"
	row.add_theme_constant_override("separation", 3 if compact else 6)
	parent.add_child(row)

	var title := Label.new()
	title.name = prefix + "Name"
	title.text = String(data.get("title", "Card"))
	title.add_theme_font_size_override("font_size", 9 if compact else 18)
	title.add_theme_color_override("font_color", Color("#f3efe4"))
	title.autowrap_mode = TextServer.AUTOWRAP_OFF if compact else TextServer.AUTOWRAP_WORD_SMART
	title.clip_text = compact
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var cost := int(data.get("cost", -1))
	if cost < 0:
		return

	var badge := PanelContainer.new()
	badge.name = prefix + "CostBadge"
	badge.custom_minimum_size = Vector2(24, 18) if compact else Vector2(34, 28)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d7f2ff")
	style.border_color = Color("#6cb4e8")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	badge.add_theme_stylebox_override("panel", style)
	row.add_child(badge)

	var cost_label := Label.new()
	cost_label.name = prefix + "Cost"
	cost_label.text = str(cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 9 if compact else 14)
	cost_label.add_theme_color_override("font_color", Color("#07131d"))
	badge.add_child(cost_label)


func _add_art_box(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	var art := PanelContainer.new()
	art.name = prefix + "Art"
	art.custom_minimum_size = Vector2(0, 32) if compact else Vector2(0, 118)
	var style := StyleBoxFlat.new()
	var art_color := _color(data.get("art_color", Color("#283545")), Color("#283545"))
	style.bg_color = art_color.darkened(0.22)
	style.border_color = art_color.lightened(0.18)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	art.add_theme_stylebox_override("panel", style)
	parent.add_child(art)

	var label := Label.new()
	label.name = prefix + "ArtLabel"
	label.text = String(data.get("art_text", "")) if not compact else ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9 if compact else 12)
	label.add_theme_color_override("font_color", Color("#d8dfec"))
	art.add_child(label)


func _add_type_strip(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	var type_line := String(data.get("type_line", ""))
	if type_line == "":
		return

	var strip := PanelContainer.new()
	strip.name = prefix + "TypeStrip"
	strip.custom_minimum_size = Vector2(0, 12) if compact else Vector2(0, 24)
	var style := StyleBoxFlat.new()
	var animal_color := _color(data.get("animal_color", Color("#c7d0df")), Color("#c7d0df"))
	style.bg_color = Color("#121a24")
	style.bg_color.a = 0.86
	style.border_color = animal_color.lightened(0.35)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	strip.add_theme_stylebox_override("panel", style)
	parent.add_child(strip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3 if compact else 6)
	margin.add_theme_constant_override("margin_right", 3 if compact else 6)
	strip.add_child(margin)

	var label := Label.new()
	label.name = prefix + "Type"
	label.text = type_line.to_upper() if compact else type_line
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 7 if compact else 12)
	label.add_theme_color_override("font_color", animal_color.lightened(0.68))
	margin.add_child(label)


func _add_meta_line(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	_add_optional_line(parent, prefix + "Meta", String(data.get("meta_line", "")), Color("#c7d0df"), 7 if compact else 12, compact)
	_add_optional_line(parent, prefix + "CombatStats", String(data.get("combat_stats", "")), Color("#ffe08a"), 8 if compact else 13, compact)


func _add_effect_text(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	_add_optional_line(parent, prefix + "Effect", String(data.get("effect_text", "")), Color("#d8dfec"), 7 if compact else 12, compact)


func _add_bottom_row(parent: VBoxContainer, data: Dictionary, prefix: String, compact: bool) -> void:
	var show_stats := bool(data.get("show_attack_health", false))
	var attack := int(data.get("attack", -1))
	var health := int(data.get("health", -1))
	var area_text := String(data.get("area_text", ""))
	if not show_stats and area_text == "":
		return

	var row := HBoxContainer.new()
	row.name = prefix + "BottomRow"
	row.add_theme_constant_override("separation", 4 if compact else 8)
	parent.add_child(row)

	if show_stats:
		_add_stat_chip(row, prefix + "AttackStat", "ATK", attack, Color("#f2a329"), compact)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	if area_text != "":
		var area := Label.new()
		area.name = prefix + "Area"
		area.text = area_text
		area.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		area.add_theme_font_size_override("font_size", 7 if compact else 11)
		area.add_theme_color_override("font_color", Color("#c7d0df"))
		row.add_child(area)

	if show_stats:
		_add_stat_chip(row, prefix + "HealthStat", "HP", health, Color("#e85d88"), compact)


func _add_stat_chip(parent: HBoxContainer, node_name: String, label_text: String, value: int, color: Color, compact: bool) -> void:
	var chip := PanelContainer.new()
	chip.name = node_name
	chip.custom_minimum_size = Vector2(30, 18) if compact else Vector2(48, 26)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)

	var label := Label.new()
	label.text = "%s %d" % [label_text, value]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 7 if compact else 11)
	label.add_theme_color_override("font_color", Color("#11141a"))
	chip.add_child(label)


func _add_optional_line(parent: VBoxContainer, node_name: String, text: String, color: Color, font_size: int, compact: bool) -> void:
	if text == "":
		return
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = compact
	if compact:
		label.custom_minimum_size = Vector2(0, 12)
	parent.add_child(label)


func _color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if typeof(value) == TYPE_STRING:
		return Color(String(value))
	return fallback
