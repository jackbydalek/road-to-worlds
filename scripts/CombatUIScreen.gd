extends RefCounted
class_name CombatUIScreen


func show(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "ui_combat"
	if host.manual_drag_candidate.is_empty() and host.manual_drag_state.is_empty():
		host._manual_free_orphan_hand_drag_ghosts()
	host._render_nav()
	host._clear(host.content)
	host._update_status()

	var metrics: Dictionary = host._calculate_deck_metrics(host.run.deck, host.run.sideboard)
	var player_archetype: String = String(metrics.primary)
	var opponent_archetype: String = host._combat_lab_opponent_for(player_archetype)
	var legal: Dictionary = host._deck_is_legal()

	if not host.run.get("manual_combat", {}).is_empty():
		var setup_bar := HBoxContainer.new()
		setup_bar.name = "UICombatSetupBar"
		setup_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		setup_bar.add_theme_constant_override("separation", 8)
		host.content.add_child(setup_bar)

		var setup_label := Label.new()
		setup_label.text = _match_label(host, player_archetype, opponent_archetype)
		setup_label.add_theme_color_override("font_color", Color("#9aa7b7"))
		setup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		setup_bar.add_child(setup_label)

		if host._season_tournament_active():
			var tournament_button: Button = host._make_button("Tournament")
			host._connect_pressed(tournament_button, host._show_tournament)
			setup_bar.add_child(tournament_button)
		else:
			var restart_button: Button = host._make_button("Restart UI Battle")
			restart_button.disabled = not legal.ok
			host._connect_pressed(restart_button, host._start_manual_combat_lab_battle)
			setup_bar.add_child(restart_button)

		add_manual_combat_lab(host, host.content, host.run.manual_combat)
		return

	var panel: VBoxContainer = host._add_panel(host.content, "UI Combat")
	host._add_body_text(panel, "Your deck: %s | Opponent: %s" % [host.archetypes_by_id[player_archetype].name, host.archetypes_by_id[opponent_archetype].name])
	host._add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var opponent_row := HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 6)
	panel.add_child(opponent_row)

	var opponent_label := Label.new()
	opponent_label.text = "Opponent:"
	opponent_label.add_theme_color_override("font_color", Color("#c7d0df"))
	opponent_row.add_child(opponent_label)

	for archetype_id in host.ARCHETYPE_ORDER:
		var archetype: Dictionary = host.archetypes_by_id[archetype_id]
		var opponent_button: Button = host._make_button(archetype.get("name", archetype_id))
		opponent_button.disabled = String(archetype_id) == opponent_archetype
		var selected_id: String = String(archetype_id)
		host._connect_pressed(opponent_button, func() -> void: host._set_combat_lab_opponent(selected_id))
		opponent_row.add_child(opponent_button)

	var start_button: Button = host._make_button("Start UI Battle" if host.run.get("manual_combat", {}).is_empty() else "Restart UI Battle")
	start_button.disabled = not legal.ok
	host._connect_pressed(start_button, host._start_manual_combat_lab_battle)
	panel.add_child(start_button)


func add_manual_combat_lab(host, parent: Node, state: Dictionary) -> void:
	var is_over := bool(state.get("game_over", false))
	var phase := String(state.get("phase", ""))
	var player: Dictionary = state.get("player", {})
	var opponent: Dictionary = state.get("opponent", {})
	var opponent_name: String = host._archetype_label(String(opponent.get("archetype", "")))

	if host.current_screen == "ui_combat":
		_add_ui_combat_header(host, parent, state, is_over, phase, opponent_name)
		_add_ui_combat_battle_log(host, parent, state)
		_add_ui_combat_duel(host, parent, state, is_over, phase)
		return

	var panel: VBoxContainer = host._add_panel(parent, "Manual Battle", "#253044" if not is_over else "#442525")
	if is_over:
		host._add_body_text(panel, "Winner: %s | Opponent: %s | Turn %d" % [
			String(state.get("winner", "")).capitalize(),
			opponent_name,
			int(state.get("turn", 0))
		])
	else:
		host._add_body_text(panel, "Phase: %s | Opponent: %s | Turn %d | Seed %d" % [
			phase.replace("_", " ").capitalize(),
			opponent_name,
			int(state.get("turn", 0)),
			int(state.get("seed", 0))
		])

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	panel.add_child(controls)

	var end_button: Button = host._make_button("End Turn")
	end_button.disabled = is_over or phase != "player_main" or host._manual_has_pending_action()
	host._connect_pressed(end_button, host._manual_end_turn)
	controls.add_child(end_button)

	var clear_button: Button = host._make_button("Clear Manual Battle")
	host._connect_pressed(clear_button, host._clear_manual_battle)
	controls.add_child(clear_button)

	var selection_row := HBoxContainer.new()
	selection_row.add_theme_constant_override("separation", 6)
	panel.add_child(selection_row)

	var selection_label := Label.new()
	selection_label.text = host._manual_selection_label(state)
	selection_label.add_theme_color_override("font_color", Color("#ffe08a") if not host._manual_selection().is_empty() else Color("#c7d0df"))
	selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_row.add_child(selection_label)

	var cancel_selection: Button = host._make_button("Cancel Selection")
	cancel_selection.disabled = host._manual_selection().is_empty()
	host._connect_pressed(cancel_selection, host._manual_clear_selection)
	selection_row.add_child(cancel_selection)

	host._add_manual_recent_events(parent, state)
	if host.current_screen == "ui_combat":
		host._add_manual_action_summary(parent)
	else:
		host._add_manual_action_animation(parent)

	var battlefield: Control = host._add_manual_battlefield(parent)
	host._add_manual_inspect_panel(battlefield, state)
	var arena := VBoxContainer.new()
	arena.name = "ManualArenaZones"
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 10)
	battlefield.add_child(arena)
	host._add_manual_combatant_panel(arena, "Opponent", opponent, false, state)
	host._add_manual_combatant_panel(arena, "You", player, true, state)
	if host.current_screen == "ui_combat":
		var board_arc_layer := Node2D.new()
		board_arc_layer.name = "ManualBoardArcLayer"
		board_arc_layer.z_index = 120
		arena.add_child(board_arc_layer)
		host.call_deferred("_refresh_manual_board_arc_layer", board_arc_layer)

	var log_panel: VBoxContainer = host._add_panel(parent, "Manual Battle Log")
	var log_lines: Array = state.get("log", [])
	var start_index: int = max(0, log_lines.size() - 18)
	for i in range(start_index, log_lines.size()):
		host._add_body_text(log_panel, "• " + String(log_lines[i]))


func _add_ui_combat_header(host, parent: Node, state: Dictionary, is_over: bool, phase: String, opponent_name: String) -> void:
	var panel: VBoxContainer = host._add_panel(parent, "", "#1b2330" if not is_over else "#442525")
	panel.name = "UICombatHeader"

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var log_open := bool(host.run.get("manual_battle_log_open", false))
	var log_button: Button = host._make_button("Hide Log" if log_open else "Battle Log")
	log_button.name = "ManualBattleLogButton"
	host._style_button(log_button, "selected" if log_open else "action")
	host._connect_pressed(log_button, host._toggle_manual_battle_log)
	row.add_child(log_button)

	var status := Label.new()
	status.text = "Duel | Turn %d | %s | Opponent: %s" % [
		int(state.get("turn", 0)),
		phase.replace("_", " ").capitalize(),
		opponent_name
	]
	status.add_theme_color_override("font_color", Color("#d8dfec"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)

	var selection := Label.new()
	selection.text = host._manual_selection_label(state)
	selection.add_theme_color_override("font_color", Color("#ffe08a") if not host._manual_selection().is_empty() else Color("#9aa7b7"))
	selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(selection)

	var cancel_selection: Button = host._make_button("Cancel")
	cancel_selection.disabled = host._manual_selection().is_empty()
	host._connect_pressed(cancel_selection, host._manual_clear_selection)
	row.add_child(cancel_selection)

	var clear_button: Button = host._make_button("Forfeit" if host._season_tournament_active() else "Clear")
	host._connect_pressed(clear_button, host._clear_manual_battle)
	row.add_child(clear_button)


func _add_ui_combat_battle_log(host, parent: Node, state: Dictionary) -> void:
	if not bool(host.run.get("manual_battle_log_open", false)):
		return

	var panel: VBoxContainer = host._add_panel(parent, "Battle Log", "#151d28")
	panel.name = "ManualBattleLogPanel"

	var row := HBoxContainer.new()
	row.name = "ManualBattleLogRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	host._add_manual_action_summary(row)
	host._add_manual_recent_events(row, state)

	var log_lines: Array = state.get("log", [])
	var lines_box := VBoxContainer.new()
	lines_box.name = "ManualBattleLogLines"
	lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_box.add_theme_constant_override("separation", 2)
	row.add_child(lines_box)

	if log_lines.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No battle events yet."
		empty_label.add_theme_color_override("font_color", Color("#7e8794"))
		lines_box.add_child(empty_label)
		return

	var start_index: int = max(0, log_lines.size() - 5)
	for i in range(start_index, log_lines.size()):
		var line := Label.new()
		line.text = "• " + String(log_lines[i])
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 11)
		line.add_theme_color_override("font_color", host._manual_log_line_color(String(log_lines[i])))
		lines_box.add_child(line)


func _add_ui_combat_duel(host, parent: Node, state: Dictionary, is_over: bool, phase: String) -> void:
	var player: Dictionary = state.get("player", {})
	var opponent: Dictionary = state.get("opponent", {})

	var battlefield: Control = host._add_manual_battlefield(parent)
	battlefield.name = "UICombatBattlefield"
	battlefield.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not event.double_click:
				host._manual_clear_ui_combat_context()
	)

	var arena := VBoxContainer.new()
	arena.name = "ManualArenaZones"
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena.offset_left = 0
	arena.offset_top = 0
	arena.offset_right = 0
	arena.offset_bottom = 0
	arena.add_theme_constant_override("separation", 4)
	battlefield.add_child(arena)
	host._add_manual_action_bubble_layer(battlefield)

	_add_ui_combat_opponent_hand(host, arena, opponent, state)
	host._add_manual_engine_zone(arena, opponent.get("engines", []), false)
	host._add_manual_board(arena, opponent.get("board", []), false, state)
	host._add_manual_board(arena, player.get("board", []), true, state)
	host._add_manual_engine_zone(arena, player.get("engines", []), true)
	host._add_manual_hand(arena, player, state)

	var board_arc_layer := Node2D.new()
	board_arc_layer.name = "ManualBoardArcLayer"
	board_arc_layer.z_index = 120
	arena.add_child(board_arc_layer)
	host.call_deferred("_refresh_manual_board_arc_layer", board_arc_layer)

	_add_ui_combat_resource_readout(host, battlefield, player, true)
	_add_ui_combat_resource_readout(host, battlefield, opponent, false)
	_add_ui_combat_end_turn_overlay(host, battlefield, is_over, phase)
	host._add_manual_inspect_panel(battlefield, state)
	if is_over and host._season_tournament_active():
		_add_ui_combat_season_result_overlay(host, battlefield, state)


func _add_ui_combat_season_result_overlay(host, parent: Node, state: Dictionary) -> void:
	var active: Dictionary = host.run.get("active_tournament", {})
	var panel := PanelContainer.new()
	panel.name = "SeasonRoundResultOverlay"
	panel.z_index = 140
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210.0
	panel.offset_top = -96.0
	panel.offset_right = 210.0
	panel.offset_bottom = 96.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.9)
	style.border_color = Color("#88bfff") if String(state.get("winner", "")) == "player" else Color("#ff8f7f")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Round %d Complete" % int(active.get("round", 1))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f3efe4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var winner_text := "Win" if String(state.get("winner", "")) == "player" else "Loss"
	var summary := Label.new()
	summary.text = "%s | Current event record %d-%d" % [
		winner_text,
		int(active.get("wins", 0)),
		int(active.get("losses", 0))
	]
	summary.add_theme_color_override("font_color", Color("#c7d0df"))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(summary)

	var record_button: Button = host._make_button("Record Round Result")
	record_button.name = "SeasonRecordRoundButton"
	host._style_button(record_button, "action")
	host._connect_pressed(record_button, host._season_record_current_round_result)
	box.add_child(record_button)


func _add_ui_combat_opponent_hand(host, parent: Node, opponent: Dictionary, state: Dictionary) -> void:
	var zone: VBoxContainer = host._add_manual_zone(parent, "Hand Zone", "OpponentHand", "#182537")
	zone.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var fan := Control.new()
	fan.name = "ManualOpponentFanHand"
	fan.custom_minimum_size = Vector2(0, 34)
	fan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fan.mouse_filter = Control.MOUSE_FILTER_STOP
	fan.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if host._manual_selection_can_try_face(host.run.get("manual_combat", {})):
				fan.accept_event()
			if event.double_click and host._manual_selected_can_target_face(host.run.get("manual_combat", {})):
				host._manual_target_face()
	)
	zone.add_child(fan)

	var hand_count := int(opponent.get("hand", []).size())
	if hand_count <= 0:
		host._add_manual_empty_zone_slot(fan, "Empty Hand")
	else:
		for i in range(hand_count):
			_add_ui_combat_blank_hand_card(fan, i)
		call_deferred("_layout_ui_combat_opponent_hand", fan)
	if host._manual_selection_can_try_face(state):
		_add_ui_combat_face_target_anchor(fan, host._manual_selected_can_target_face(state))


func _add_ui_combat_face_target_anchor(parent: Control, selected_can_face: bool) -> void:
	var anchor := PanelContainer.new()
	anchor.name = "ManualFaceTargetAffordance"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.offset_left = 0.0
	anchor.offset_top = 0.0
	anchor.offset_right = 0.0
	anchor.offset_bottom = 0.0
	anchor.z_index = 25
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.22, 0.14, 0.12) if selected_can_face else Color(0.26, 0.14, 0.14, 0.10)
	style.border_color = Color(0.62, 0.9, 0.43, 0.68) if selected_can_face else Color(0.85, 0.63, 0.63, 0.35)
	style.border_width_left = 2 if selected_can_face else 1
	style.border_width_right = 2 if selected_can_face else 1
	style.border_width_top = 2 if selected_can_face else 1
	style.border_width_bottom = 2 if selected_can_face else 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	anchor.add_theme_stylebox_override("panel", style)
	parent.add_child(anchor)


func _add_ui_combat_blank_hand_card(parent: Node, index: int) -> void:
	var back := PanelContainer.new()
	back.name = "ManualCardBackSlot_%d" % (index + 1)
	back.custom_minimum_size = Vector2(32, 40)
	back.size = back.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172a36")
	style.border_color = Color("#05070a")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	back.add_theme_stylebox_override("panel", style)
	parent.add_child(back)


func _layout_ui_combat_opponent_hand(fan: Control) -> void:
	if not is_instance_valid(fan):
		return
	var backs: Array = []
	for child in fan.get_children():
		if child is Control and String(child.name).begins_with("ManualCardBackSlot"):
			backs.append(child)
	var count := backs.size()
	if count <= 0:
		return
	var card_size: Vector2 = backs[0].custom_minimum_size
	var available_width := fan.size.x
	if available_width <= 1.0:
		available_width = max(card_size.x, card_size.x + 34.0 * float(max(0, count - 1)))
	var spread: float = 0.0 if count == 1 else clamp((available_width - card_size.x) / float(count - 1), 30.0, 46.0)
	var total_width: float = card_size.x + spread * float(max(0, count - 1))
	var start_x: float = max(0.0, (available_width - total_width) * 0.5)
	var center_index: float = float(count - 1) * 0.5
	for index in range(count):
		var card_panel: Control = backs[index]
		var offset: float = float(index) - center_index
		card_panel.size = card_panel.custom_minimum_size
		card_panel.pivot_offset = card_panel.custom_minimum_size * 0.5
		card_panel.position = Vector2(start_x + spread * float(index), -6.0 + abs(offset) * 1.5)
		card_panel.rotation_degrees = offset * 8.0
		card_panel.z_index = index


func _add_ui_combat_resource_readout(host, parent: Node, combatant: Dictionary, is_player: bool) -> void:
	var panel := PanelContainer.new()
	panel.name = "ManualPlayerResourceReadout" if is_player else "ManualOpponentResourceReadout"
	panel.z_index = 110
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	if is_player:
		panel.anchor_left = 0.0
		panel.anchor_top = 1.0
		panel.anchor_right = 0.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 20.0
		panel.offset_top = -116.0
		panel.offset_right = 196.0
		panel.offset_bottom = -18.0
	else:
		panel.anchor_left = 1.0
		panel.anchor_top = 0.0
		panel.anchor_right = 1.0
		panel.anchor_bottom = 0.0
		panel.offset_left = -222.0
		panel.offset_top = 18.0
		panel.offset_right = -24.0
		panel.offset_bottom = 124.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.17, 0.72)
	style.border_color = Color(0.18, 0.27, 0.36, 0.62)
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
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var readout := Label.new()
	readout.name = "ManualResourceReadoutText"
	readout.text = "Life: %d\nFocus: %d/%d%s" % [
		int(combatant.get("life", 0)),
		int(combatant.get("focus", 0)),
		int(combatant.get("max_focus", 0)),
		host._manual_restricted_focus_text(combatant)
	]
	readout.add_theme_font_size_override("font_size", 22)
	readout.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(readout)


func _add_ui_combat_end_turn_overlay(host, parent: Node, is_over: bool, phase: String) -> void:
	var panel := PanelContainer.new()
	panel.name = "ManualContextPanel"
	panel.z_index = 115
	panel.anchor_left = 1.0
	panel.anchor_top = 0.5
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.5
	panel.offset_left = -194.0
	panel.offset_top = -24.0
	panel.offset_right = -28.0
	panel.offset_bottom = 22.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.13, 0.2, 0.78)
	style.border_color = Color("#05070a")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var end_button: Button = host._make_button("End Turn")
	end_button.name = "ManualEndTurnButton"
	host._style_button(end_button, "action")
	end_button.add_theme_font_size_override("font_size", 18)
	end_button.custom_minimum_size = Vector2(150, 32)
	end_button.disabled = is_over or phase != "player_main" or host._manual_has_pending_action()
	host._connect_pressed(end_button, host._manual_end_turn)
	margin.add_child(end_button)


func _match_label(host, player_archetype: String, fallback_opponent_archetype: String) -> String:
	if host._season_tournament_active():
		var active: Dictionary = host.run.get("active_tournament", {})
		var opponent: Dictionary = active.get("current_opponent", {})
		var event_name := String(active.get("event_name", "Tournament"))
		var round_number := int(active.get("round", 1))
		var rounds := int(active.get("rounds", 1))
		var record := "%d-%d" % [int(active.get("wins", 0)), int(active.get("losses", 0))]
		return "%s Round %d/%d | Record %s | %s vs %s on %s" % [
			event_name,
			round_number,
			rounds,
			record,
			host.archetypes_by_id[player_archetype].name,
			String(opponent.get("name", "Opponent")),
			host._archetype_label(String(opponent.get("archetype", fallback_opponent_archetype)))
		]
	return "%s vs %s" % [host.archetypes_by_id[player_archetype].name, host.archetypes_by_id[fallback_opponent_archetype].name]
