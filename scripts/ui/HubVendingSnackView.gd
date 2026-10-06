extends Control
## Physical snack packets: inspect first, then confirm the selected service.
signal focus_order_changed

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const AREA_HIGHLIGHT := preload("res://assets/shaders/shop_area_highlight.gdshader")
const PACKET_IDS := ["heal", "upgrade"]
const ACTION_SIZE := Vector2(270, 50)

class PacketHitButton extends Button:
	var excluded_rects: Array[Rect2] = []

	func _has_point(point: Vector2) -> bool:
		if not Rect2(Vector2.ZERO, size).has_point(point):
			return false
		# An enlarged packet must not swallow the other packet's original target.
		for excluded in excluded_rects:
			if excluded.has_point(point):
				return false
		return true

var _offers: Dictionary = {}
var _reduced_motion := false
var _keyboard_highlight := false
var _selected_id := ""
var _interactive := false
var _break_used := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_refresh_highlights)


func setup(heal_button: Button, upgrade_button: Button, heal_texture: Texture2D, upgrade_texture: Texture2D) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_offer("heal", heal_button, heal_texture)
	_add_offer("upgrade", upgrade_button, upgrade_texture)
	_refresh_actions()


func _add_offer(snack_id: String, action: Button, texture: Texture2D) -> void:
	var group := Control.new()
	group.name = "HubVendingPacket_%s" % snack_id
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(group)
	var visual := TextureRect.new()
	visual.name = "HubVendingPacketArtwork_%s" % snack_id
	visual.texture = texture
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var highlight := ShaderMaterial.new()
	highlight.shader = AREA_HIGHLIGHT
	highlight.set_shader_parameter("highlight_color", PALETTE.PEACH_PAPER.lerp(PALETTE.PEACH_MINT, 0.25))
	visual.material = highlight
	group.add_child(visual)

	var hit := PacketHitButton.new()
	hit.name = "HubVendingSnackButton_%s" % snack_id
	hit.flat = true
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.set_meta("ui_button_style_exempt", true)
	hit.accessibility_name = "Heart Bites" if snack_id == "heal" else "Foil Crunch"
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hit.pressed.connect(select_snack.bind(snack_id))
	for event in [hit.mouse_entered, hit.mouse_exited, hit.focus_entered, hit.focus_exited]:
		event.connect(_refresh_highlights)
	group.add_child(hit)

	if action.get_parent() != null:
		action.reparent(group)
	else:
		group.add_child(action)
	action.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	action.set_meta("ui_button_style_exempt", true)
	action.set_meta("ui_button_variant", "primary")
	action.set_meta("ui_button_variant_inferred", false)
	action.set_meta("ui_button_shape", "round")
	action.text = "Heal 5 HP" if snack_id == "heal" else "Upgrade a card"
	action.icon = null
	action.add_theme_font_override("font", UI.BODY_FONT)
	action.add_theme_font_size_override("font_size", 19)
	action.set_meta("accessibility_base_font_size", 19)
	action.custom_minimum_size = ACTION_SIZE
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := PALETTE.PEACH_TEAL
		if state == "hover":
			fill = fill.lightened(0.10)
		elif state == "pressed":
			fill = fill.darkened(0.10)
		elif state == "disabled":
			fill = PALETTE.PEACH_MINT
		var style := SHAPES.style(fill, Vector4(16, 9, 16, 9), 51, 9)
		if state == "focus":
			style.draw_center = false
			style.border_color = PALETTE.SELECTION_BLUE
			style.set_border_width_all(3)
		action.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		action.add_theme_color_override(state, PALETTE.PEACH_PAPER)
	action.add_theme_color_override("font_disabled_color", PALETTE.PEACH_INK_SOFT)
	for event in [action.mouse_entered, action.mouse_exited, action.focus_entered, action.focus_exited]:
		event.connect(_refresh_highlights)
	_offers[snack_id] = {"group": group, "visual": visual, "hit": hit, "action": action,
		"rect": Rect2(), "zoom": 1.0, "lift": 0.0, "tween": null, "can_use": true}


func configure(snapshot: Dictionary) -> void:
	_break_used = bool(snapshot.get("break_used", false))
	var life := int(snapshot.get("life", 0))
	var maximum := maxi(1, int(snapshot.get("max_life", 40)))
	var heal_amount := maxi(0, int(snapshot.get("bye_heal", 5)))
	for snack_id in PACKET_IDS:
		if not _offers.has(snack_id):
			continue
		var offer: Dictionary = _offers[snack_id]
		var action := offer.action as Button
		var hit := offer.hit as Button
		if snack_id == "heal":
			offer.can_use = bool(snapshot.get("can_heal", life < maximum)) and life < maximum
			action.text = "Heal %d HP" % heal_amount
			action.tooltip_text = "Your health is already full." if life >= maximum else "Heart Bites: restore up to %d HP. Uses your one free weekly bye." % heal_amount
		else:
			offer.can_use = bool(snapshot.get("can_upgrade", true))
			action.text = "Upgrade a card"
			action.tooltip_text = "Choose one card to upgrade for free. Cancelling keeps your weekly bye available." if offer.can_use else "No eligible cards to upgrade."
		if _break_used:
			action.tooltip_text = "Your free bye is already used this week."
		hit.tooltip_text = action.tooltip_text
	if _break_used:
		clear_selection()
	else:
		_refresh_actions()
		for snack_id in _offers:
			_apply_pose(snack_id)


func set_interactive(enabled: bool) -> void:
	if _interactive == enabled:
		return
	_interactive = enabled
	_refresh_actions()


func project_snack(snack_id: String, rect: Rect2) -> void:
	if not _offers.has(snack_id):
		return
	_offers[snack_id].rect = Rect2(rect.position - position, rect.size)
	for current_id in _offers:
		_apply_pose(current_id)


func select_snack(snack_id: String) -> void:
	if not _interactive or _break_used or not _offers.has(snack_id):
		return
	_selected_id = "" if snack_id == _selected_id else snack_id
	_refresh_actions()
	_animate_poses()


func clear_selection() -> void:
	_selected_id = ""
	for snack_id in _offers:
		var offer: Dictionary = _offers[snack_id]
		if offer.tween != null and (offer.tween as Tween).is_valid():
			(offer.tween as Tween).kill()
		_set_pose(Vector2(1, 0), snack_id)
	_refresh_actions()


func set_keyboard_highlight(enabled: bool) -> void:
	_keyboard_highlight = enabled
	_refresh_highlights()


func _refresh_actions() -> void:
	for snack_id in _offers:
		var offer: Dictionary = _offers[snack_id]
		var hit := offer.hit as Button
		var action := offer.action as Button
		hit.disabled = not _interactive or _break_used
		hit.focus_mode = Control.FOCUS_ALL if not hit.disabled else Control.FOCUS_NONE
		hit.mouse_filter = Control.MOUSE_FILTER_STOP if not hit.disabled else Control.MOUSE_FILTER_IGNORE
		action.visible = _interactive and not _break_used and snack_id == _selected_id
		action.disabled = not action.visible or not bool(offer.can_use)
		action.focus_mode = Control.FOCUS_ALL if not action.disabled else Control.FOCUS_NONE
		action.mouse_filter = Control.MOUSE_FILTER_STOP if action.visible else Control.MOUSE_FILTER_IGNORE
		(offer.visual as CanvasItem).modulate.a = 0.35 if _break_used else 1.0
	_refresh_highlights()
	focus_order_changed.emit()


func _refresh_highlights() -> void:
	for offer in _offers.values():
		var hit := offer.hit as Button
		var action := offer.action as Button
		var indicated := hit.has_focus() or action.has_focus() if _keyboard_highlight else hit.is_hovered() or (action.is_visible_in_tree() and action.is_hovered())
		var active := is_visible_in_tree() and _interactive and not _break_used and indicated
		hit.set_meta("highlight_active", active)
		((offer.visual as TextureRect).material as ShaderMaterial).set_shader_parameter("highlight_strength", 1.0 if active else 0.0)


func _animate_poses() -> void:
	for snack_id in _offers:
		var offer: Dictionary = _offers[snack_id]
		if offer.tween != null and (offer.tween as Tween).is_valid():
			(offer.tween as Tween).kill()
		var target := Vector2(1.4, 30) if snack_id == _selected_id else Vector2(1, 0)
		if _reduced_motion or not is_inside_tree():
			_set_pose(target, snack_id)
		else:
			var tween := create_tween()
			offer.tween = tween
			tween.tween_method(_set_pose.bind(snack_id), Vector2(float(offer.zoom), float(offer.lift)), target, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_pose(pose: Vector2, snack_id: String) -> void:
	if not _offers.has(snack_id):
		return
	_offers[snack_id].zoom = pose.x
	_offers[snack_id].lift = pose.y
	_apply_pose(snack_id)


func _apply_pose(snack_id: String) -> void:
	var offer: Dictionary = _offers[snack_id]
	var rect: Rect2 = offer.rect
	var group := offer.group as Control
	var visual := offer.visual as TextureRect
	var hit := offer.hit as PacketHitButton
	var action := offer.action as Button
	group.position = rect.position
	group.size = rect.size
	group.z_index = 2 if snack_id == _selected_id else 0
	visual.size = rect.size
	visual.scale = Vector2.ONE * float(offer.zoom)
	visual.position = rect.size * (1.0 - float(offer.zoom)) * 0.5 - Vector2(0, float(offer.lift))
	var visible_rect := Rect2(visual.position, rect.size * visual.scale)
	var footprint := Rect2(Vector2.ZERO, rect.size).merge(visible_rect)
	hit.position = footprint.position
	hit.size = footprint.size
	hit.excluded_rects.clear()
	if snack_id == _selected_id:
		for other_id in _offers:
			if other_id != snack_id:
				var other_rect: Rect2 = _offers[other_id].rect
				hit.excluded_rects.append(Rect2(other_rect.position - rect.position - footprint.position, other_rect.size))
	# Respect enlarged text by growing the confirmation instead of shrinking it.
	action.size = ACTION_SIZE.max(action.get_combined_minimum_size())
	var button_center := rect.position.x + rect.size.x * 0.5
	var canvas_width := (get_parent() as Control).size.x if get_parent() is Control else 1280.0
	var left := clampf(button_center - action.size.x * 0.5, 16.0 - position.x, maxf(16.0 - position.x, canvas_width - position.x - action.size.x - 16.0))
	action.position = Vector2(left - rect.position.x, visible_rect.end.y + 12)


func focus_controls() -> Array[Control]:
	var result: Array[Control] = []
	for snack_id in PACKET_IDS:
		if not _offers.has(snack_id):
			continue
		for control in [_offers[snack_id].hit, _offers[snack_id].action]:
			if control.is_visible_in_tree() and not control.disabled:
				result.append(control)
	return result
