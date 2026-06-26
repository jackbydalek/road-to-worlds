extends RefCounted
class_name ManualCombatUI

const PRINTED_CARD_ASPECT := 942.0 / 1355.0


func ui_combat_layout_profile(host) -> Dictionary:
	var viewport: Vector2 = host.get_viewport_rect().size
	if viewport.x <= 1.0 or viewport.y <= 1.0:
		viewport = Vector2(1440, 900)
	var compressed: bool = viewport.x < 1180.0 or viewport.y < 760.0
	var roomy: bool = viewport.x >= 1600.0 and viewport.y >= 940.0
	var shell_chrome: float = 96.0 if compressed else 112.0
	if bool(host.run.get("manual_battle_log_open", false)):
		shell_chrome += 96.0 if compressed else 116.0
	var battlefield_height: float = clamp(viewport.y - shell_chrome, 500.0, 980.0 if roomy else 860.0)
	var playmat_margin: float = 4.0 if compressed else 6.0
	var zone_gap: float = 2.0 if compressed else 4.0
	var zone_budget: float = max(420.0, battlefield_height - playmat_margin * 2.0 - zone_gap * 5.0)

	var opponent_hand_height: float = clamp(zone_budget * 0.060, 34.0, 58.0)
	var engine_height: float = clamp(zone_budget * 0.052, 30.0, 48.0)
	var board_height: float = clamp(zone_budget * (0.245 if roomy else 0.235), 132.0, 224.0)
	var player_hand_height: float = zone_budget - opponent_hand_height - engine_height * 2.0 - board_height * 2.0
	player_hand_height = clamp(player_hand_height, 126.0, 260.0 if roomy else 230.0)
	var used_height: float = opponent_hand_height + engine_height * 2.0 + board_height * 2.0 + player_hand_height
	if used_height > zone_budget:
		var scale: float = zone_budget / used_height
		opponent_hand_height *= scale
		engine_height *= scale
		board_height *= scale
		player_hand_height *= scale

	var side_gutter: float = clamp(viewport.x * 0.145, 196.0, 278.0 if roomy else 246.0)
	var left_gutter: float = side_gutter + (8.0 if compressed else 14.0)
	var right_gutter: float = side_gutter + (6.0 if compressed else 12.0)
	var arena_width: float = max(620.0, viewport.x - left_gutter - right_gutter - (16.0 if compressed else 28.0))
	var board_gap: float = 4.0 if compressed else 6.0
	var board_width_cap: float = (arena_width - board_gap * float(max(0, host.COMBAT_BOARD_SLOTS - 1)) - 44.0) / float(host.COMBAT_BOARD_SLOTS)
	var board_inner_height: float = max(96.0, board_height - (34.0 if compressed else 40.0))
	var card_height: float = clamp(board_inner_height, 104.0, 170.0 if roomy else 154.0)
	var card_width: float = clamp(min(board_width_cap, card_height * PRINTED_CARD_ASPECT), 64.0, 112.0 if roomy else 100.0)
	card_height = clamp(card_width / PRINTED_CARD_ASPECT, 112.0, board_inner_height)

	var hand_card_height: float = clamp(player_hand_height - (10.0 if compressed else 4.0), 146.0, 226.0 if roomy else 208.0)
	var hand_card_width: float = clamp(hand_card_height * PRINTED_CARD_ASPECT, 96.0, 154.0 if roomy else 142.0)

	return {
		"viewport": viewport,
		"compressed": compressed,
		"roomy": roomy,
		"battlefield_height": battlefield_height,
		"playmat_margin": playmat_margin,
		"zone_gap": zone_gap,
		"zone_label_font": 8 if compressed else 10,
		"opponent_hand_height": opponent_hand_height,
		"engine_height": engine_height,
		"board_height": board_height,
		"player_hand_height": player_hand_height,
		"board_gap": board_gap,
		"side_gutter_left": left_gutter,
		"side_gutter_right": right_gutter,
		"engine_gap": 3.0 if compressed else 5.0,
		"card_size": Vector2(card_width, card_height),
		"hand_card_size": Vector2(hand_card_width, hand_card_height),
		"board_slot_size": Vector2(card_width + 8.0, min(board_height - 10.0, card_height + 20.0)),
		"engine_slot_size": Vector2(max(88.0, card_width), max(24.0, engine_height - 12.0)),
		"empty_slot_size": Vector2(max(88.0, card_width), 22.0 if compressed else 26.0),
		"opponent_card_back_size": Vector2(26.0 if compressed else 32.0, max(32.0, opponent_hand_height - 10.0)),
		"hidden_card_back_size": Vector2(58.0 if compressed else 70.0, 26.0 if compressed else 30.0),
		"player_hand_fan_height": max(140.0, player_hand_height - 8.0),
		"opponent_hand_fan_height": max(30.0, opponent_hand_height - 8.0),
		"fan_spread_min": 68.0 if compressed else 78.0,
		"fan_spread_max": 104.0 if compressed else (132.0 if roomy else 118.0),
		"fan_base_y": -2.0 if compressed else -8.0,
		"opponent_fan_spread_min": 24.0 if compressed else 30.0,
		"opponent_fan_spread_max": 38.0 if compressed else 48.0,
		"action_bubble_size": Vector2(46.0 if compressed else 54.0, 46.0 if compressed else 54.0),
		"action_bubble_font": 12 if compressed else 14,
		"resource_width": 154.0 if compressed else 176.0,
		"resource_height": 78.0 if compressed else 98.0,
		"resource_font": 17 if compressed else 22,
		"context_width": 142.0 if compressed else 166.0,
		"context_height": 40.0 if compressed else 46.0,
		"context_button_font": 15 if compressed else 18,
		"inspect_width": 210.0 if compressed else 236.0,
		"inspect_height": 286.0 if compressed else 322.0,
		"inspect_margin": 8.0 if compressed else 14.0,
		"inspect_art_height": 76.0 if compressed else 100.0,
		"modal_width": 370.0 if compressed else 420.0,
		"modal_height": 180.0 if compressed else 210.0
	}


func add_action_bubble_layer(host, parent: Control) -> Control:
	var layer := Control.new()
	layer.name = "ManualActionBubbleLayer"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 560
	layer.clip_contents = false
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = 0
	layer.offset_top = 0
	layer.offset_right = 0
	layer.offset_bottom = 0
	parent.add_child(layer)
	host.manual_action_bubble_layer = layer
	return layer


func add_battlefield(host, parent: Node) -> Control:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var playmat := PanelContainer.new()
	playmat.name = "ManualBattlefield"
	playmat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact_duel:
		playmat.custom_minimum_size = Vector2(0, float(layout.get("battlefield_height", 720.0)))
		playmat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16201c")
	style.border_color = Color("#526149")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	playmat.add_theme_stylebox_override("panel", style)
	parent.add_child(playmat)

	var margin := MarginContainer.new()
	var playmat_margin := int(layout.get("playmat_margin", 6)) if compact_duel else 10
	margin.add_theme_constant_override("margin_left", playmat_margin)
	margin.add_theme_constant_override("margin_right", playmat_margin)
	margin.add_theme_constant_override("margin_top", playmat_margin)
	margin.add_theme_constant_override("margin_bottom", playmat_margin)
	playmat.add_child(margin)

	var battlefield: Control
	if compact_duel:
		var canvas := Control.new()
		canvas.clip_contents = true
		canvas.mouse_filter = Control.MOUSE_FILTER_STOP
		battlefield = canvas
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		battlefield = row
	battlefield.name = "ManualBattlefield"
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(battlefield)
	return battlefield


func add_zone(host, parent: Node, title: String, zone_name: String, accent: String) -> VBoxContainer:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var panel := PanelContainer.new()
	panel.name = "ManualZone_" + zone_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact_duel:
		var fixed_height := ui_combat_zone_height(host, zone_name)
		if fixed_height > 0.0:
			panel.custom_minimum_size = Vector2(0, fixed_height)
			panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		panel.clip_contents = zone_name != "PlayerHand"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent)
	style.border_color = Color("#586575")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 8)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 8)
	margin.add_theme_constant_override("margin_top", 1 if compact_duel else 6)
	margin.add_theme_constant_override("margin_bottom", 2 if compact_duel else 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", int(layout.get("zone_gap", 2)) if compact_duel else 6)
	margin.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", int(layout.get("zone_label_font", 9)) if compact_duel else 13)
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(label)
	return box


func ui_combat_zone_height(host, zone_name: String) -> float:
	var layout := ui_combat_layout_profile(host)
	match zone_name:
		"OpponentHand":
			return float(layout.get("opponent_hand_height", 46.0))
		"OpponentEngine", "PlayerEngine":
			return float(layout.get("engine_height", 38.0))
		"OpponentBoard", "PlayerBoard":
			return float(layout.get("board_height", 190.0))
		"PlayerHand":
			return float(layout.get("player_hand_height", 240.0))
		_:
			return 0.0


func add_engine_slot(host, parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var slot := PanelContainer.new()
	slot.name = host._manual_engine_slot_anchor(is_player, slot_index)
	slot.custom_minimum_size = layout.get("engine_slot_size", Vector2(96, 24)) if compact_duel else Vector2(132, 44)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111922")
	style.border_color = Color("#3f4a59")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	slot.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "ManualEngineSlotContents"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	return box


func add_empty_zone_slot(host, parent: Node, text: String) -> void:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var slot := PanelContainer.new()
	slot.name = "ManualEmptyZoneSlot"
	slot.custom_minimum_size = layout.get("empty_slot_size", Vector2(96, 24)) if compact_duel else Vector2(132, 44)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#141a22")
	style.border_color = Color("#3f4a59")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	slot.add_child(margin)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if compact_duel:
		label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("#7e8794"))
	margin.add_child(label)


func add_card_back_slot(host, parent: Node, text: String) -> void:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var back := PanelContainer.new()
	back.name = "ManualCardBackSlot"
	back.custom_minimum_size = layout.get("hidden_card_back_size", Vector2(70, 30)) if compact_duel else Vector2(96, 44)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171c2b")
	style.border_color = Color("#6f99e8")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	back.add_theme_stylebox_override("panel", style)
	parent.add_child(back)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	back.add_child(margin)

	var label := Label.new()
	label.text = "Card" if compact_duel else text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if compact_duel:
		label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#a9c7ff"))
	margin.add_child(label)


func add_board_slot(host, parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var layout: Dictionary = ui_combat_layout_profile(host) if compact_duel else {}
	var slot := PanelContainer.new()
	slot.name = host._manual_board_slot_anchor(is_player, slot_index)
	slot.custom_minimum_size = layout.get("board_slot_size", Vector2(108, 166)) if compact_duel else Vector2(188, 250)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#14221a") if is_player else Color("#24171d")
	style.border_color = Color("#445443") if is_player else Color("#5a404a")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3 if compact_duel else 4)
	margin.add_theme_constant_override("margin_right", 3 if compact_duel else 4)
	margin.add_theme_constant_override("margin_top", 2 if compact_duel else 4)
	margin.add_theme_constant_override("margin_bottom", 2 if compact_duel else 4)
	slot.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "ManualBoardSlotContents"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2 if compact_duel else 4)
	margin.add_child(box)

	var label := Label.new()
	label.text = "Slot %d" % (slot_index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8 if compact_duel else 10)
	label.add_theme_color_override("font_color", Color("#7e8794"))
	box.add_child(label)
	return box


func layout_fanned_hand(host, fan: Control) -> void:
	if not is_instance_valid(fan):
		return
	var card_panels: Array = []
	for child in fan.get_children():
		if child is Control and String(child.name).begins_with("CombatCardPanel_Hand"):
			card_panels.append(child)
	var count := card_panels.size()
	if count <= 0:
		return
	var layout: Dictionary = ui_combat_layout_profile(host) if host.current_screen == "ui_combat" else {}
	var card_size: Vector2 = card_panels[0].custom_minimum_size
	var available_width := fan.size.x
	if available_width <= 1.0:
		available_width = max(card_size.x, card_size.x + 58.0 * float(max(0, count - 1)))
	var spread_min := float(layout.get("fan_spread_min", 58.0)) if host.current_screen == "ui_combat" else 58.0
	var spread_max := float(layout.get("fan_spread_max", 88.0)) if host.current_screen == "ui_combat" else 88.0
	var spread: float = 0.0 if count == 1 else clamp((available_width - card_size.x) / float(count - 1), spread_min, spread_max)
	var total_width: float = card_size.x + spread * float(max(0, count - 1))
	var start_x: float = max(0.0, (available_width - total_width) * 0.5)
	var center_index: float = float(count - 1) * 0.5
	var base_y := float(layout.get("fan_base_y", -12.0)) if host.current_screen == "ui_combat" else 0.0
	for index in range(count):
		var card_panel: Control = card_panels[index]
		var offset: float = float(index) - center_index
		card_panel.size = card_panel.custom_minimum_size
		card_panel.pivot_offset = card_panel.custom_minimum_size * 0.5
		card_panel.position = Vector2(start_x + spread * float(index), base_y + abs(offset) * 2.8)
		card_panel.rotation_degrees = offset * 7.0
		card_panel.z_index = index
		var card_id := hand_card_id_from_panel(card_panel)
		if card_id != "" and host._manual_selection_is_card(card_id):
			card_panel.z_index += 100
		position_action_bubbles_for_card(host, card_panel)


func hand_card_id_from_panel(card_panel: Control) -> String:
	var prefix := "CombatCardPanel_Hand_"
	var node_name := String(card_panel.name)
	if node_name.begins_with(prefix):
		return node_name.substr(prefix.length())
	return ""


func add_action_bubble(host, card_box: Node, label: String, callback: Callable, stack_index: int = 0) -> void:
	if host.current_screen != "ui_combat":
		return
	var card_panel := card_panel_from_contents(card_box)
	if card_panel == null:
		return
	var bubble := Button.new()
	bubble.name = "ManualCardActionBubble"
	bubble.text = label
	bubble.focus_mode = Control.FOCUS_NONE
	var layout: Dictionary = ui_combat_layout_profile(host)
	bubble.custom_minimum_size = layout.get("action_bubble_size", Vector2(54, 54))
	bubble.size = bubble.custom_minimum_size
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.z_index = 560
	bubble.set_meta("stack_index", stack_index)
	bubble.set_meta("source_card_instance", card_panel.get_instance_id())
	style_action_bubble(bubble)
	bubble.add_theme_font_size_override("font_size", int(layout.get("action_bubble_font", 14)))
	host._connect_pressed(bubble, callback)
	var bubble_parent: Control = host._manual_action_bubble_layer()
	if bubble_parent == null:
		bubble_parent = card_panel
	bubble_parent.add_child(bubble)
	host.call_deferred("_position_manual_action_bubble", bubble, card_panel)


func position_action_bubbles_for_card(host, card_panel: Control) -> void:
	if card_panel == null or not is_instance_valid(card_panel):
		return
	for child in card_panel.get_children():
		if child is Button and String(child.name).begins_with("ManualCardActionBubble"):
			position_action_bubble(child as Button, card_panel)
	var bubble_layer: Control = host._manual_action_bubble_layer()
	if bubble_layer == null:
		return
	for child in bubble_layer.get_children():
		if child is Button and String(child.name).begins_with("ManualCardActionBubble") and int(child.get_meta("source_card_instance", -1)) == card_panel.get_instance_id():
			position_action_bubble(child as Button, card_panel)


func position_action_bubble(bubble: Button, card_panel: Control) -> void:
	if bubble == null or card_panel == null:
		return
	if not is_instance_valid(bubble) or not is_instance_valid(card_panel):
		return
	var bubble_size := bubble.custom_minimum_size
	if bubble_size == Vector2.ZERO:
		bubble_size = Vector2(54, 54)
	bubble.size = bubble_size
	var stack_index := int(bubble.get_meta("stack_index", 0))
	var card_size := card_panel.size
	if card_size == Vector2.ZERO:
		card_size = card_panel.custom_minimum_size
	var card_rect := card_panel.get_global_rect()
	if card_rect.size == Vector2.ZERO:
		card_rect.size = card_size
		card_rect.position = card_panel.global_position
	var card_name := String(card_panel.name)
	var desired_position := Vector2.ZERO
	if card_name.begins_with("CombatCardPanel_PlayerUnit") or card_name.begins_with("CombatCardPanel_OpponentUnit"):
		desired_position = Vector2(
			card_rect.position.x + card_rect.size.x + 8.0,
			card_rect.position.y + card_rect.size.y * 0.10 + float(stack_index) * (bubble_size.y + 8.0)
		)
		place_action_bubble(bubble, desired_position)
		return
	desired_position = Vector2(
		card_rect.position.x + card_rect.size.x * 0.5 - bubble_size.x * 0.5,
		card_rect.position.y - bubble_size.y - 6.0 - float(stack_index) * (bubble_size.y + 6.0)
	)
	place_action_bubble(bubble, desired_position)


func place_action_bubble(bubble: Button, global_position: Vector2) -> void:
	var parent := bubble.get_parent()
	if parent is Control and String(parent.name).begins_with("ManualActionBubbleLayer"):
		bubble.position = global_position - (parent as Control).get_global_rect().position
	else:
		bubble.global_position = global_position


func style_action_bubble(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#ff71ff"))
	button.add_theme_color_override("font_hover_color", Color("#ffa5ff"))
	button.add_theme_color_override("font_pressed_color", Color("#ffe3ff"))
	button.add_theme_stylebox_override("normal", action_bubble_stylebox(Color(0.05, 0.06, 0.08, 0.78), Color("#fff48f"), 5))
	button.add_theme_stylebox_override("hover", action_bubble_stylebox(Color(0.07, 0.08, 0.10, 0.86), Color("#fff8b5"), 5))
	button.add_theme_stylebox_override("pressed", action_bubble_stylebox(Color(0.03, 0.035, 0.05, 0.92), Color("#ffe16f"), 5))
	button.add_theme_stylebox_override("disabled", action_bubble_stylebox(Color(0.05, 0.06, 0.08, 0.35), Color("#7d7550"), 4))


func action_bubble_stylebox(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func card_panel_from_contents(contents: Node) -> Control:
	var node := contents
	while node != null:
		if node is PanelContainer and (String(node.name).begins_with("CombatCardPanel") or String(node.name).begins_with("ManualDragCardGhost")):
			return node as Control
		node = node.get_parent()
	return null


func add_card_badge(host, parent: Node, text: String, color: Color) -> void:
	var compact_duel: bool = host.current_screen == "ui_combat"
	var badge := Label.new()
	badge.name = "ManualTargetBadge" if text == "LEGAL TARGET" else "ManualCardBadge"
	var display_text := text
	if compact_duel:
		match text:
			"ATTACKER SELECTED":
				display_text = "ATTACKER"
			"LEGAL TARGET":
				display_text = "TARGET"
			"SELECTED":
				display_text = "SEL"
	badge.text = display_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 9 if compact_duel else 11)
	badge.add_theme_color_override("font_color", color)
	parent.add_child(badge)
