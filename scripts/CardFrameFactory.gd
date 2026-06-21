extends RefCounted
class_name CardFrameFactory

const PRINTED_FRAME_ASPECT := 1545.0 / 1999.0
const PRINTED_FRAME_TEXTURES := {
	"threat": "res://assets/card_frames/threat_generic_silver.png",
	"action_engine": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"action": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"engine": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"white": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"blue": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"yellow": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"silver": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"gold": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"black": "res://assets/card_frames/action_or_engine_generic_silver.png",
	"threat_aggro": "res://assets/card_frames/threat_aggro_silver.png",
	"action_engine_aggro": "res://assets/card_frames/action_or_engine_aggro_silver.png",
	"threat_control": "res://assets/card_frames/threat_control_silver.png",
	"action_engine_control": "res://assets/card_frames/action_or_engine_control_silver.png",
	"threat_ramp": "res://assets/card_frames/threat_ramp_silver.png",
	"action_engine_ramp": "res://assets/card_frames/action_or_engine_ramp_silver.png",
	"threat_prop": "res://assets/card_frames/threat_prop_silver.png",
	"action_engine_prop": "res://assets/card_frames/action_or_engine_prop_silver.png",
	"threat_revive": "res://assets/card_frames/threat_revive_silver.png",
	"action_engine_revive": "res://assets/card_frames/action_or_engine_revive_silver.png",
	"threat_generic": "res://assets/card_frames/threat_generic_silver.png",
	"action_engine_generic": "res://assets/card_frames/action_or_engine_generic_silver.png"
}

var printed_frame_texture_cache := {}


func add_frame(parent: Node, data: Dictionary, options: Dictionary = {}) -> VBoxContainer:
	var compact := bool(options.get("compact", false))
	var prefix := String(options.get("name_prefix", "CardFrame"))
	var requested_size: Vector2 = options.get("min_size", Vector2(104, 136) if compact else Vector2(244, 0))
	var use_printed_frame := bool(options.get("use_printed_frame", data.get("use_printed_frame", true)))
	if use_printed_frame:
		requested_size = _printed_frame_size(requested_size, compact)

	var panel := PanelContainer.new()
	panel.name = String(options.get("panel_name", "CardFramePanel"))
	panel.custom_minimum_size = requested_size
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
	margin.add_theme_constant_override("margin_left", 0 if use_printed_frame else (4 if compact else 8))
	margin.add_theme_constant_override("margin_right", 0 if use_printed_frame else (4 if compact else 8))
	margin.add_theme_constant_override("margin_top", 0 if use_printed_frame else (3 if compact else 8))
	margin.add_theme_constant_override("margin_bottom", 0 if use_printed_frame else (3 if compact else 8))
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = String(options.get("contents_name", "CardFrameContents"))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2 if compact else 6)
	margin.add_child(box)

	if use_printed_frame:
		_add_printed_card(box, data, options, prefix, compact, requested_size)
		return box

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


func _add_printed_card(parent: VBoxContainer, data: Dictionary, options: Dictionary, prefix: String, compact: bool, requested_size: Vector2) -> void:
	var printed := Control.new()
	printed.name = prefix + "PrintedCard"
	printed.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	printed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	printed.clip_contents = true
	var width := requested_size.x if requested_size.x > 1.0 else (104.0 if compact else 248.0)
	var height := requested_size.y if requested_size.y > 1.0 else width / PRINTED_FRAME_ASPECT
	printed.custom_minimum_size = Vector2(width, height)
	parent.add_child(printed)

	var frame := TextureRect.new()
	frame.name = prefix + "FrameTexture"
	frame.texture = _printed_frame_texture(String(data.get("frame_id", data.get("border_id", options.get("border_id", "action_engine")))))
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(frame, Rect2(0.0, 0.0, 1.0, 1.0))
	printed.add_child(frame)

	_add_printed_art_box(printed, data, prefix, compact)
	_add_printed_title(printed, data, prefix, compact)
	_add_printed_focus_orb(printed, data, prefix, compact)
	_add_printed_type_line(printed, data, prefix, compact)
	_add_printed_meta_labels(printed, data, options, prefix, compact)
	_add_printed_combat_stats(printed, data, options, prefix, compact)
	_add_printed_effect_text(printed, data, options, prefix, compact)
	_add_printed_stat_labels(printed, data, prefix, compact)
	_add_printed_rarity(printed, data, prefix, compact)


func _add_printed_art_box(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	var art := PanelContainer.new()
	art.name = prefix + "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(art, Rect2(0.060, 0.125, 0.880, 0.375))
	var style := StyleBoxFlat.new()
	var art_color := _color(data.get("art_color", Color("#76958b")), Color("#76958b"))
	style.bg_color = art_color.darkened(0.08)
	style.border_color = art_color.lightened(0.18)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	art.add_theme_stylebox_override("panel", style)
	parent.add_child(art)

	var art_label := Label.new()
	art_label.name = prefix + "ArtLabel"
	art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_label.text = String(data.get("art_text", "Picture placeholder")) if not compact else ""
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_font_size_override("font_size", 8 if compact else 18)
	art_label.add_theme_color_override("font_color", Color("#f6efe0"))
	art.add_child(art_label)


func _add_printed_title(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	var title := Label.new()
	title.name = prefix + "Name"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = String(data.get("title", "Card"))
	title.clip_text = true
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 7 if compact else 24)
	title.add_theme_color_override("font_color", Color("#15120d"))
	_anchor_rect(title, Rect2(0.065, 0.030, 0.650, 0.075))
	parent.add_child(title)


func _add_printed_focus_orb(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	var cost := int(data.get("cost", -1))
	if cost < 0:
		return
	var orb_rect := Rect2(0.828, 0.030, 0.106, 0.082)
	_add_printed_focus_flair(parent, orb_rect, prefix, compact)

	var orb := PanelContainer.new()
	orb.name = prefix + "CostBadge"
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(orb, orb_rect)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.88, 0.48, 0.94)
	style.border_color = Color("#5b4a18")
	style.border_width_left = 2 if compact else 3
	style.border_width_right = 2 if compact else 3
	style.border_width_top = 2 if compact else 3
	style.border_width_bottom = 2 if compact else 3
	style.corner_radius_top_left = 96
	style.corner_radius_top_right = 96
	style.corner_radius_bottom_left = 96
	style.corner_radius_bottom_right = 96
	orb.add_theme_stylebox_override("panel", style)
	parent.add_child(orb)
	_add_control_pulse(orb, Vector2(1.08, 1.08), 0.9)

	var label := Label.new()
	label.name = prefix + "Cost"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = str(cost)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9 if compact else 22)
	label.add_theme_color_override("font_color", Color("#15120d"))
	orb.add_child(label)


func _add_printed_focus_flair(parent: Control, orb_rect: Rect2, prefix: String, compact: bool) -> void:
	var halo := PanelContainer.new()
	halo.name = prefix + "CostHalo"
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(halo, Rect2(orb_rect.position.x - 0.010, orb_rect.position.y - 0.008, orb_rect.size.x + 0.020, orb_rect.size.y + 0.016))
	var halo_style := StyleBoxFlat.new()
	halo_style.bg_color = Color(1.0, 0.92, 0.50, 0.10)
	halo_style.border_color = Color(1.0, 0.95, 0.58, 0.48)
	halo_style.border_width_left = 1 if compact else 2
	halo_style.border_width_right = 1 if compact else 2
	halo_style.border_width_top = 1 if compact else 2
	halo_style.border_width_bottom = 1 if compact else 2
	halo_style.corner_radius_top_left = 96
	halo_style.corner_radius_top_right = 96
	halo_style.corner_radius_bottom_left = 96
	halo_style.corner_radius_bottom_right = 96
	halo.add_theme_stylebox_override("panel", halo_style)
	parent.add_child(halo)
	_add_control_pulse(halo, Vector2(1.22, 1.22), 1.25, 0.28)

	var glint := PanelContainer.new()
	glint.name = prefix + "CostGlint"
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(glint, Rect2(orb_rect.position.x + orb_rect.size.x * 0.18, orb_rect.position.y + orb_rect.size.y * 0.16, orb_rect.size.x * 0.24, orb_rect.size.y * 0.20))
	var glint_style := StyleBoxFlat.new()
	glint_style.bg_color = Color(1.0, 1.0, 0.82, 0.55)
	glint_style.border_color = Color(1.0, 1.0, 0.82, 0.0)
	glint_style.corner_radius_top_left = 96
	glint_style.corner_radius_top_right = 96
	glint_style.corner_radius_bottom_left = 96
	glint_style.corner_radius_bottom_right = 96
	glint.add_theme_stylebox_override("panel", glint_style)
	parent.add_child(glint)


func _add_printed_type_line(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	var type_line := String(data.get("type_line", ""))
	if type_line == "":
		return
	var label := Label.new()
	label.name = prefix + "Type"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = type_line.to_upper() if compact else type_line
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 5 if compact else 18)
	label.add_theme_color_override("font_color", _color(data.get("animal_color", Color("#224e62")), Color("#224e62")).darkened(0.25))
	_anchor_rect(label, Rect2(0.065, 0.510, 0.870, 0.045))
	parent.add_child(label)


func _add_printed_meta_labels(parent: Control, data: Dictionary, options: Dictionary, prefix: String, compact: bool) -> void:
	if not bool(options.get("show_deck_stats", false)):
		return
	var deck_stats := String(data.get("deck_stats", ""))
	if deck_stats == "":
		return
	var deck_label := Label.new()
	deck_label.name = prefix + "DeckStats"
	deck_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_label.text = deck_stats
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_label.clip_text = true
	deck_label.add_theme_font_size_override("font_size", 5 if compact else 11)
	deck_label.add_theme_color_override("font_color", Color("#40382a"))
	_anchor_rect(deck_label, Rect2(0.300, 0.875, 0.400, 0.045))
	parent.add_child(deck_label)


func _add_printed_combat_stats(parent: Control, data: Dictionary, options: Dictionary, prefix: String, compact: bool) -> void:
	if not bool(options.get("show_combat_stats", false)):
		return
	var combat_stats := String(data.get("combat_stats", ""))
	if combat_stats == "":
		return
	var label := Label.new()
	label.name = prefix + "CombatStats"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = combat_stats
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 5 if compact else 12)
	label.add_theme_color_override("font_color", Color("#5b3d1d"))
	_anchor_rect(label, Rect2(0.075, 0.545, 0.850, 0.035))
	parent.add_child(label)


func _add_printed_effect_text(parent: Control, data: Dictionary, options: Dictionary, prefix: String, compact: bool) -> void:
	var effect_text := String(data.get("effect_text", ""))
	var rules_text := String(data.get("rules_text", ""))
	var lines: Array[String] = []
	if effect_text != "":
		lines.append(effect_text)
	if bool(options.get("show_rules_text", false)) and rules_text != "" and rules_text != effect_text:
		lines.append(rules_text)
	var label := Label.new()
	label.name = prefix + "Effect"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "\n".join(PackedStringArray(lines))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 6 if compact else 16)
	label.add_theme_color_override("font_color", Color("#241d15"))
	_anchor_rect(label, Rect2(0.075, 0.575, 0.850, 0.285))
	parent.add_child(label)


func _add_printed_stat_labels(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	if not bool(data.get("show_attack_health", false)):
		return
	var attack := int(data.get("attack", 0))
	var health := int(data.get("health", 0))
	var max_health := int(data.get("max_health", health))
	var attack_label := Label.new()
	attack_label.name = prefix + "AttackStat"
	attack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_label.text = str(attack)
	attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attack_label.add_theme_font_size_override("font_size", 14 if compact else 30)
	attack_label.add_theme_color_override("font_color", Color("#1f160c"))
	_anchor_rect(attack_label, Rect2(0.045, 0.895, 0.220, 0.070))
	parent.add_child(attack_label)

	var health_label := Label.new()
	health_label.name = prefix + "HealthStat"
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_label.text = str(health)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 14 if compact else 30)
	health_label.add_theme_color_override("font_color", Color("#7e1515") if health < max_health else Color("#1f100e"))
	_anchor_rect(health_label, Rect2(0.735, 0.895, 0.220, 0.070))
	parent.add_child(health_label)


func _add_printed_rarity(parent: Control, data: Dictionary, prefix: String, compact: bool) -> void:
	var rarity := String(data.get("rarity", ""))
	if rarity == "":
		return
	var label := Label.new()
	label.name = prefix + "Rarity"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = _rarity_symbol(rarity)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 9 if compact else 22)
	label.add_theme_color_override("font_color", Color("#2a241c"))
	_anchor_rect(label, Rect2(0.385, 0.920, 0.230, 0.035))
	parent.add_child(label)


func _rarity_symbol(rarity: String) -> String:
	match rarity.to_lower():
		"common":
			return "•"
		"uncommon":
			return "◆"
		"rare":
			return "★"
		"mythic":
			return "♛"
		_:
			return "•"


func _add_control_pulse(control: Control, target_scale: Vector2, duration: float, min_alpha: float = 1.0) -> void:
	control.resized.connect(func() -> void:
		control.pivot_offset = control.size * 0.5
	)
	var tween := control.create_tween()
	tween.set_loops()
	tween.tween_property(control, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if min_alpha < 1.0:
		tween.parallel().tween_property(control, "modulate:a", min_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if min_alpha < 1.0:
		tween.parallel().tween_property(control, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _anchor_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _printed_frame_size(requested_size: Vector2, compact: bool) -> Vector2:
	var width := requested_size.x if requested_size.x > 1.0 else (104.0 if compact else 248.0)
	var height := width / PRINTED_FRAME_ASPECT
	if not compact:
		height = max(320.0, height)
	return Vector2(width, height)


func _printed_frame_texture_path(border_id: String) -> String:
	var normalized := border_id.to_lower()
	if PRINTED_FRAME_TEXTURES.has(normalized):
		return String(PRINTED_FRAME_TEXTURES[normalized])
	return String(PRINTED_FRAME_TEXTURES["action_engine"])


func _printed_frame_texture(border_id: String) -> Texture2D:
	var path := _printed_frame_texture_path(border_id)
	if printed_frame_texture_cache.has(path):
		return printed_frame_texture_cache[path]
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("Could not load card frame texture: " + path)
		return null
	var texture := ImageTexture.create_from_image(image)
	printed_frame_texture_cache[path] = texture
	return texture


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
