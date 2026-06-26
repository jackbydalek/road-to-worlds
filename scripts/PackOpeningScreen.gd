extends RefCounted
class_name PackOpeningScreen

const PACK_OPENING_SCENE := preload("res://scenes/PackOpeningScene.tscn")
const BOOSTER_ID := "base_standard_pack"
const PRIZE_BOOSTER_ID := "season_prize_pack"
const SCENE_SIZE := Vector2(1440, 900)
const CARD_SLOT_SIZE := Vector2(168, 236)
const FAN_CENTER_X := 666.0
const FAN_BASE_Y := 66.0
const FAN_SPACING := 164.0
const FAN_ROTATION_STEP := 0.04

var scene_root: Node
var status_label: Label
var pack_button: TextureButton
var reveal_all_button: Button
var done_button: Button
var card_fan: Control
var card_slots: Array[TextureButton] = []


func show(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "packs"
	host._render_nav()
	host._clear(host.content)
	host._update_status()

	scene_root = _add_scene(host)
	_cache_nodes()
	_fit_pack_button_hitbox_to_art()
	_layout_slots()
	_connect_controls(host)
	_render(host)


func _add_scene(host) -> Node:
	var frame := PanelContainer.new()
	frame.name = "PackOpeningSceneFrame"
	frame.custom_minimum_size = SCENE_SIZE
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", _style("#11141a", "#3a4352", 1, 6))
	host.content.add_child(frame)

	var canvas := Control.new()
	canvas.name = "PackOpeningSceneHost"
	canvas.custom_minimum_size = SCENE_SIZE
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.clip_contents = true
	frame.add_child(canvas)

	var root := PACK_OPENING_SCENE.instantiate()
	root.name = "PackOpeningScene"
	canvas.add_child(root)
	return root


func _cache_nodes() -> void:
	pack_button = _find_node_by_name(scene_root, "PackButton") as TextureButton
	reveal_all_button = _find_node_by_name(scene_root, "RevealAllButton") as Button
	done_button = _find_node_by_name(scene_root, "DoneButton") as Button
	card_fan = _find_node_by_name(scene_root, "CardFan") as Control
	status_label = _find_node_by_name(scene_root, "PackStatusLabel") as Label
	if status_label == null:
		status_label = Label.new()
		status_label.name = "PackStatusLabel"
		status_label.position = Vector2(84, 72)
		status_label.size = Vector2(760, 42)
		scene_root.add_child(status_label)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color("#f3efe4"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	card_slots = []
	for index in range(8):
		var slot := _find_node_by_name(scene_root, "PackCardSlot%d" % index) as TextureButton
		if slot != null:
			card_slots.append(slot)


func _layout_slots() -> void:
	for index in range(card_slots.size()):
		var slot := card_slots[index]
		var layout: Dictionary = _slot_layout(index, card_slots.size())
		slot.position = layout.position
		slot.size = CARD_SLOT_SIZE
		slot.custom_minimum_size = CARD_SLOT_SIZE
		slot.pivot_offset = CARD_SLOT_SIZE * 0.5
		slot.rotation = float(layout.rotation)
		slot.ignore_texture_size = true


func _fit_pack_button_hitbox_to_art() -> void:
	if pack_button == null:
		return

	for child in pack_button.get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue

		var texture_size := sprite.texture.get_size() * sprite.scale.abs()
		if texture_size.x <= 0.0 or texture_size.y <= 0.0:
			return

		var sprite_top_left := sprite.position - texture_size * 0.5
		pack_button.position += sprite_top_left
		pack_button.size = texture_size
		pack_button.custom_minimum_size = texture_size
		pack_button.pivot_offset = texture_size * 0.5
		sprite.position = texture_size * 0.5
		return


func _connect_controls(host) -> void:
	if pack_button != null:
		pack_button.pressed.connect(func() -> void: _on_pack_pressed(host), CONNECT_DEFERRED)
	if reveal_all_button != null:
		host._connect_pressed(reveal_all_button, func() -> void: _on_reveal_all_pressed(host))
	if done_button != null:
		host._connect_pressed(done_button, host._finish_pack_opening)

	for index in range(card_slots.size()):
		var slot_index := index
		card_slots[index].pressed.connect(func() -> void: _on_card_slot_pressed(host, slot_index), CONNECT_DEFERRED)


func _render(host) -> void:
	var pack: Array = host.run.get("current_pack", [])
	var opened := bool(host.run.get("pack_opened", false))
	var complete := _revealed_count(pack) >= pack.size() and not pack.is_empty()
	var pack_action := _pack_action(host)

	if pack_button != null:
		pack_button.visible = pack.is_empty() or not opened
		pack_button.disabled = pack.is_empty() and pack_action == "blocked"
		if pack_button.visible:
			pack_button.modulate.a = 1.0
			pack_button.scale = Vector2.ONE
			pack_button.mouse_filter = Control.MOUSE_FILTER_STOP

	if reveal_all_button != null:
		reveal_all_button.visible = opened and not complete
		reveal_all_button.disabled = pack.is_empty()
		reveal_all_button.text = "Reveal All"

	if done_button != null:
		done_button.visible = complete
		done_button.text = "Done"

	if pack.is_empty():
		match pack_action:
			"prize":
				_set_status("Click the pack to open a 3-card prize pack. Prize packs waiting: %d." % int(host.run.get("prize_packs", 0)))
			"buy":
				_set_status("Click the pack to buy and open a 6-card booster for $%d." % _booster_price(host))
			_:
				_set_status("No prize packs waiting. You need $%d to buy a 6-card booster." % _booster_price(host))
	elif not opened:
		_set_status("Sealed pack on the table. Click it to crack it open.")
	else:
		_set_status("%d/%d cards revealed. Click face-down cards to flip them." % [_revealed_count(pack), pack.size()])

	for index in range(card_slots.size()):
		var slot := card_slots[index]
		slot.visible = opened and index < pack.size()
		slot.disabled = not opened or index >= pack.size()
		if index < pack.size():
			var layout: Dictionary = _slot_layout(index, pack.size())
			slot.position = layout.position
			slot.rotation = float(layout.rotation)
			_render_card_slot(host, slot, index, pack[index])


func _on_pack_pressed(host) -> void:
	var pack: Array = host.run.get("current_pack", [])
	if pack.is_empty():
		var action := _pack_action(host)
		var result: Dictionary = {}
		match action:
			"prize":
				result = host.shop_economy_service.open_prize_pack(host.run, PRIZE_BOOSTER_ID, host._current_primary_archetype())
			"buy":
				result = host.shop_economy_service.buy_and_open_pack(host.run, BOOSTER_ID, host._current_primary_archetype())
			_:
				host._set_footer("No prize packs waiting, and you cannot afford a booster.")
				_render(host)
				return
		if not bool(result.get("ok", false)):
			host._set_footer(String(result.get("message", "Could not buy pack.")))
			_render(host)
			return
		host._set_footer(String(result.get("message", "")))
		_open_pack_to_table(host)
		return

	_open_pack_to_table(host)


func _open_pack_to_table(host) -> void:
	host.run.pack_opened = true
	_render(host)
	_animate_pack_open()
	_animate_spread()


func _on_card_slot_pressed(host, index: int) -> void:
	var pack: Array = host.run.get("current_pack", [])
	if index < 0 or index >= pack.size():
		return
	var entry: Dictionary = pack[index]
	if bool(entry.get("revealed", false)):
		return

	var slot := card_slots[index]
	slot.pivot_offset = CARD_SLOT_SIZE * 0.5
	var tween := slot.create_tween()
	tween.tween_property(slot, "scale", Vector2(0.04, 1.0), 0.09).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _finish_reveal_slot(host, index, slot))
	tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)


func _finish_reveal_slot(host, index: int, slot: TextureButton) -> void:
	var result: Dictionary = host.shop_economy_service.reveal_pack_card(host.run, index, host._current_primary_archetype())
	host._set_footer(String(result.get("message", "")))
	var pack: Array = host.run.get("current_pack", [])
	_render(host)
	if index >= 0 and index < pack.size():
		var rarity := String(pack[index].get("rarity", "common"))
		_animate_reveal(slot, rarity)


func _on_reveal_all_pressed(host) -> void:
	host.run.pack_opened = true
	host.shop_economy_service.reveal_all_cards(host.run, host._current_primary_archetype())
	_render(host)
	for index in range(card_slots.size()):
		if index < host.run.get("current_pack", []).size():
			var rarity := String(host.run.current_pack[index].get("rarity", "common"))
			if _rarity_rank(rarity) >= 2:
				_animate_reveal(card_slots[index], rarity)


func _render_card_slot(host, slot: TextureButton, index: int, entry: Dictionary) -> void:
	for child in slot.get_children():
		slot.remove_child(child)
		child.queue_free()

	var revealed := bool(entry.get("revealed", false))
	var rarity := String(entry.get("rarity", "common"))
	var card_id := String(entry.get("cardId", ""))
	var card: Dictionary = host.cards_by_id.get(card_id, {})

	var aura := PanelContainer.new()
	aura.name = "PackCardAura%d" % index
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.set_anchors_preset(Control.PRESET_FULL_RECT)
	aura.add_theme_stylebox_override("panel", _aura_style(rarity, revealed))
	aura.visible = revealed and _rarity_rank(rarity) >= 2
	slot.add_child(aura)

	var face := PanelContainer.new()
	face.name = "PackCardFace%d" % index
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.add_theme_stylebox_override("panel", _card_style(host, rarity, revealed))
	slot.add_child(face)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	face.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	if not revealed:
		_add_slot_label(box, "ROAD", 19, Color("#f3efe4"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_slot_spacer(box)
		_add_slot_label(box, "TO", 15, Color("#9fb0c4"), HORIZONTAL_ALIGNMENT_CENTER)
		_add_slot_label(box, "WORLDS", 19, Color("#f3efe4"), HORIZONTAL_ALIGNMENT_CENTER)
		return

	_add_slot_label(box, String(card.get("name", card_id)), 13, host._rarity_text_color(rarity), HORIZONTAL_ALIGNMENT_CENTER)
	_add_slot_label(box, rarity.capitalize(), 12, Color("#c7d0df"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_slot_spacer(box)
	_add_slot_label(box, "%s | cost %d" % [
		String(card.get("role", "card")).capitalize(),
		int(card.get("cost", 0))
	], 11, Color("#d8dfec"), HORIZONTAL_ALIGNMENT_CENTER)
	var note := _note_for_pack_index(host.run.get("revealed_pack", []), index)
	if note != "":
		_add_slot_label(box, note, 10, Color("#ffe08a"), HORIZONTAL_ALIGNMENT_CENTER)


func _animate_spread() -> void:
	var start_position := _pack_origin_in_fan()
	var visible_count := 0
	for slot in card_slots:
		if slot.visible:
			visible_count += 1
	for index in range(card_slots.size()):
		var slot := card_slots[index]
		if not slot.visible:
			continue
		var layout: Dictionary = _slot_layout(index, max(1, visible_count))
		var final_position: Vector2 = layout.position
		var final_rotation := float(layout.rotation)
		slot.position = start_position
		slot.rotation = -0.03 + float(index) * 0.008
		slot.modulate.a = 0.0
		slot.scale = Vector2(0.36, 0.36)
		var tween := slot.create_tween()
		var delay := float(index) * 0.045
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_property(slot, "modulate:a", 1.0, 0.08)
		tween.parallel().tween_property(slot, "position", final_position, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "rotation", final_rotation, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _slot_layout(index: int, total: int) -> Dictionary:
	var safe_total: int = max(1, total)
	var center_offset := float(index) - float(safe_total - 1) * 0.5
	var y := FAN_BASE_Y + pow(abs(center_offset), 1.45) * 16.0
	return {
		"position": Vector2(FAN_CENTER_X + center_offset * FAN_SPACING, y),
		"rotation": center_offset * FAN_ROTATION_STEP
	}


func _animate_pack_open() -> void:
	if pack_button == null:
		return
	pack_button.visible = true
	pack_button.disabled = true
	pack_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_button.modulate.a = 1.0
	pack_button.scale = Vector2.ONE
	var tween := pack_button.create_tween()
	tween.tween_property(pack_button, "scale", Vector2(1.08, 0.92), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(pack_button, "scale", Vector2(1.18, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(pack_button, "modulate:a", 0.0, 0.18).set_delay(0.06)
	tween.tween_callback(func() -> void:
		pack_button.visible = false
		pack_button.mouse_filter = Control.MOUSE_FILTER_STOP
		pack_button.scale = Vector2.ONE
		pack_button.modulate.a = 1.0
	)


func _pack_origin_in_fan() -> Vector2:
	if pack_button == null or card_fan == null:
		return Vector2(604, 148)
	var pack_center := pack_button.get_global_rect().get_center()
	var local_center := card_fan.get_global_transform_with_canvas().affine_inverse() * pack_center
	return local_center - CARD_SLOT_SIZE * 0.5


func _animate_reveal(slot: TextureButton, rarity: String) -> void:
	if _rarity_rank(rarity) < 2:
		return

	var base_position := slot.position
	var aura := slot.get_node_or_null("PackCardAura%d" % _slot_index(slot)) as CanvasItem
	if aura != null:
		aura.modulate.a = 0.35
		var aura_tween := aura.create_tween()
		aura_tween.tween_property(aura, "modulate:a", 0.85, 0.18)
		aura_tween.tween_property(aura, "modulate:a", 0.45, 0.28)

	var strength := 7.0 if rarity == "mythic" else 4.0
	var tween := slot.create_tween()
	tween.tween_property(slot, "scale", Vector2(1.08, 1.08), 0.07)
	tween.parallel().tween_property(slot, "position", base_position + Vector2(strength, 0), 0.035)
	tween.tween_property(slot, "position", base_position - Vector2(strength, 0), 0.05)
	tween.tween_property(slot, "position", base_position, 0.05)
	tween.parallel().tween_property(slot, "scale", Vector2.ONE, 0.12)


func _slot_index(slot: TextureButton) -> int:
	for index in range(card_slots.size()):
		if card_slots[index] == slot:
			return index
	return -1


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func _booster_price(host) -> int:
	if not host.boosters_by_id.has(BOOSTER_ID):
		return 0
	return int(host.boosters_by_id[BOOSTER_ID].get("price", 0))


func _pack_action(host) -> String:
	if not host.run.get("current_pack", []).is_empty():
		return "continue"
	if int(host.run.get("prize_packs", 0)) > 0:
		return "prize"
	if int(host.run.get("money", 0)) >= _booster_price(host):
		return "buy"
	return "blocked"


func _revealed_count(pack: Array) -> int:
	var count := 0
	for entry in pack:
		if bool((entry as Dictionary).get("revealed", false)):
			count += 1
	return count


func _note_for_pack_index(revealed_pack: Array, index: int) -> String:
	for entry in revealed_pack:
		var reveal: Dictionary = entry
		if int(reveal.get("packIndex", -1)) == index:
			return String(reveal.get("note", ""))
	return ""


func _add_slot_label(parent: Node, text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)


func _add_slot_spacer(parent: Node) -> void:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)


func _card_style(host, rarity: String, revealed: bool) -> StyleBoxFlat:
	if not revealed:
		return _style("#202734", "#cfd6df", 2, 8)
	var background: String = "#" + host._rarity_line_color(rarity).to_html(false)
	var border: String = "#" + host._rarity_text_color(rarity).to_html(false)
	return _style(background, border, 2, 8)


func _aura_style(rarity: String, revealed: bool) -> StyleBoxFlat:
	var color := Color("#00000000")
	if revealed:
		match rarity:
			"rare":
				color = Color("#ffd37a55")
			"mythic":
				color = Color("#ff7ab866")
			_:
				color = Color("#00000000")
	return _style(color.to_html(true), color.lightened(0.4).to_html(true), 3, 12)


func _rarity_rank(rarity: String) -> int:
	match rarity:
		"common":
			return 0
		"uncommon":
			return 1
		"rare":
			return 2
		"mythic":
			return 3
		_:
			return 0


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _style(background: String, border: String, border_width: int = 1, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
