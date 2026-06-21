extends RefCounted
class_name ManualCombatInput


func handle_hand_card_drag_input(host, event: InputEvent) -> bool:
	if host.manual_drag_candidate.is_empty() and host.manual_drag_state.is_empty():
		return false
	if event is InputEventMouseMotion:
		update_hand_card_drag(host, host.get_global_mouse_position())
		host.get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		finish_hand_card_drag(host, host.get_global_mouse_position())
		host.get_viewport().set_input_as_handled()
		return true
	return false


func try_begin_hand_card_drag(host, card_id: String, source_panel: Control) -> bool:
	if host.current_screen != "ui_combat":
		return false
	if not can_drag_hand_card(host, card_id):
		return false
	if source_panel == null or not is_instance_valid(source_panel):
		return false
	free_orphan_hand_drag_ghosts(host)
	var source_rect := source_panel.get_global_rect()
	host.manual_drag_candidate = {
		"kind": "hand_card",
		"card_id": card_id,
		"start_global": host.get_global_mouse_position(),
		"source_global": source_rect.get_center()
	}
	return true


func try_begin_unit_attack_drag(host, source_panel: Control) -> bool:
	if host.current_screen != "ui_combat":
		return false
	if source_panel == null or not is_instance_valid(source_panel):
		return false
	var instance_id := player_unit_instance_id_from_panel(source_panel)
	if not can_drag_attack_unit(host, instance_id):
		return false
	var unit: Dictionary = host._manual_find_player_unit(host.run.manual_combat, instance_id)
	free_orphan_hand_drag_ghosts(host)
	var source_rect := source_panel.get_global_rect()
	host.manual_drag_candidate = {
		"kind": "attack",
		"instance_id": instance_id,
		"card_id": String(unit.get("card_id", "")),
		"start_global": host.get_global_mouse_position(),
		"source_global": source_rect.get_center()
	}
	return true


func player_unit_instance_id_from_panel(source_panel: Control) -> int:
	var node: Node = source_panel
	var prefix := "CombatCardPanel_PlayerUnit_"
	while node != null:
		var node_name := String(node.name)
		if node_name.begins_with(prefix):
			return int(node_name.substr(prefix.length()))
		node = node.get_parent()
	return -1


func opponent_unit_instance_id_from_panel(source_panel: Control) -> int:
	var node: Node = source_panel
	var prefix := "CombatCardPanel_OpponentUnit_"
	while node != null:
		var node_name := String(node.name)
		if node_name.begins_with(prefix):
			return int(node_name.substr(prefix.length()))
		node = node.get_parent()
	return -1


func can_drag_attack_unit(host, instance_id: int) -> bool:
	var state: Dictionary = host.run.get("manual_combat", {})
	if state.is_empty() or not host._manual_combat_accepts_input(state):
		return false
	var unit: Dictionary = host._manual_find_player_unit(state, instance_id)
	return not unit.is_empty() and bool(unit.get("ready", false))


func can_drag_hand_card(host, card_id: String) -> bool:
	if host.run.get("manual_combat", {}).is_empty() or host._manual_has_pending_action():
		return false
	if not host.cards_by_id.has(card_id):
		return false
	var card: Dictionary = host.cards_by_id[card_id]
	var combat_type := String(host._combat_card_type(card))
	if not host._manual_can_play_card(host.run.manual_combat, card_id):
		return false
	if combat_type == "threat" or combat_type == "engine":
		return true
	return combat_type == "action" and host._manual_card_needs_target(card)


func update_hand_card_drag(host, global_position: Vector2) -> void:
	if host.manual_drag_state.is_empty():
		if host.manual_drag_candidate.is_empty():
			return
		var start: Vector2 = host.manual_drag_candidate.get("start_global", global_position)
		if start.distance_to(global_position) < 8.0:
			return
		start_hand_card_drag(host)

	if host.manual_drag_state.is_empty():
		return

	position_hand_drag_ghost(host, global_position)
	var drag_kind := String(host.manual_drag_state.get("kind", "hand_card"))
	var drop_target: Dictionary = {}
	if drag_kind == "attack":
		drop_target = attack_drag_target(host, int(host.manual_drag_state.get("instance_id", -1)), global_position)
	else:
		var card_id := String(host.manual_drag_state.get("card_id", ""))
		drop_target = hand_card_drag_target(host, card_id, global_position)
	var valid_drop := not drop_target.is_empty()
	host.manual_drag_state["drop_target"] = drop_target
	host.manual_drag_state["global_position"] = [global_position.x, global_position.y]
	host.manual_drag_state["valid_drop"] = valid_drop
	set_hand_drag_visual_state(host, valid_drop)
	refresh_drag_preview_layer(host)


func start_hand_card_drag(host) -> void:
	if host.manual_drag_candidate.is_empty():
		return
	var drag_kind := String(host.manual_drag_candidate.get("kind", "hand_card"))
	var source_global: Vector2 = host.manual_drag_candidate.get("source_global", host.get_global_mouse_position())
	if drag_kind == "attack":
		var instance_id := int(host.manual_drag_candidate.get("instance_id", -1))
		if not can_drag_attack_unit(host, instance_id):
			clear_hand_card_drag(host)
			return
		var unit: Dictionary = host._manual_find_player_unit(host.run.manual_combat, instance_id)
		host.manual_drag_state = {
			"kind": "attack",
			"instance_id": instance_id,
			"card_id": String(unit.get("card_id", "")),
			"source_global": source_global,
			"valid_drop": false
		}
		host.manual_drag_ghost = create_attack_drag_ghost(host, unit)
		host._set_footer(attack_drag_footer_text(host, unit))
	else:
		var card_id := String(host.manual_drag_candidate.get("card_id", ""))
		if not can_drag_hand_card(host, card_id):
			clear_hand_card_drag(host)
			return
		host.manual_drag_state = {
			"kind": "hand_card",
			"card_id": card_id,
			"source_global": source_global,
			"valid_drop": false
		}
		host.manual_drag_ghost = create_hand_drag_ghost(host, card_id)
		host._set_footer(drag_footer_text(host, card_id))
	position_hand_drag_ghost(host, host.get_global_mouse_position())
	set_drag_board_highlight(host, true)


func finish_hand_card_drag(host, global_position: Vector2) -> void:
	if host.manual_drag_state.is_empty():
		if not host.manual_drag_candidate.is_empty():
			var clicked_kind := String(host.manual_drag_candidate.get("kind", "hand_card"))
			var clicked_card_id := String(host.manual_drag_candidate.get("card_id", ""))
			var clicked_instance_id := int(host.manual_drag_candidate.get("instance_id", -1))
			clear_hand_card_drag(host)
			if clicked_kind == "attack":
				var clicked_unit: Dictionary = host._manual_find_player_unit(host.run.manual_combat, clicked_instance_id)
				if not clicked_unit.is_empty():
					host._manual_select_attacker(clicked_instance_id)
			elif host.cards_by_id.has(clicked_card_id):
				if host._manual_can_play_card(host.run.manual_combat, clicked_card_id):
					host._manual_select_card(clicked_card_id)
				else:
					host._manual_set_inspect_card(clicked_card_id, "Hand", "", true)
					host.call_deferred("_show_active_combat_screen")
		return

	var drag_kind := String(host.manual_drag_state.get("kind", "hand_card"))
	var card_id := String(host.manual_drag_state.get("card_id", ""))
	var instance_id := int(host.manual_drag_state.get("instance_id", -1))
	var drop_target: Dictionary = attack_drag_target(host, instance_id, global_position) if drag_kind == "attack" else hand_card_drag_target(host, card_id, global_position)
	var valid_drop := not drop_target.is_empty()
	var source_global: Vector2 = host.manual_drag_state.get("source_global", global_position)
	if valid_drop:
		clear_hand_card_drag(host)
		if drag_kind == "attack":
			host._manual_attack_target(instance_id, String(drop_target.get("target_type", "face")), int(drop_target.get("target_instance_id", -1)))
		else:
			match String(drop_target.get("kind", "")):
				"board_slot", "engine_slot":
					host._manual_play_card_to_slot(card_id, int(drop_target.get("slot_index", -1)))
				"action_target":
					host._manual_play_card_target(card_id, String(drop_target.get("target_type", "face")), int(drop_target.get("target_instance_id", -1)))
	else:
		snap_back_hand_drag_ghost(host, source_global)
		host.manual_drag_candidate = {}
		host.manual_drag_state = {}
		set_drag_board_highlight(host, false)
		if drag_kind == "attack":
			host._set_footer("Drop the attacker on an enemy threat or the opponent hand.")
		else:
			host._set_footer(drag_footer_text(host, card_id))


func clear_hand_card_drag(host) -> void:
	host.manual_drag_candidate = {}
	host.manual_drag_state = {}
	set_drag_board_highlight(host, false)
	if host.manual_drag_ghost != null and is_instance_valid(host.manual_drag_ghost):
		host.manual_drag_ghost.queue_free()
	host.manual_drag_ghost = null
	free_orphan_hand_drag_ghosts(host)
	refresh_drag_preview_layer(host)


func free_orphan_hand_drag_ghosts(host) -> void:
	free_descendants_by_prefix(host, host, "ManualDragCardGhost")


func free_descendants_by_prefix(_host, root: Node, target_prefix: String) -> void:
	for child in root.get_children():
		if String(child.name).begins_with(target_prefix):
			child.queue_free()
		else:
			free_descendants_by_prefix(_host, child, target_prefix)


func snap_back_hand_drag_ghost(host, source_global: Vector2) -> void:
	if host.manual_drag_ghost == null or not is_instance_valid(host.manual_drag_ghost):
		host.manual_drag_ghost = null
		return
	var ghost: Control = host.manual_drag_ghost
	host.manual_drag_ghost = null
	var ghost_size := ghost.custom_minimum_size
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "global_position", source_global - ghost_size * 0.5, 0.14)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.0), 0.14)
	tween.tween_callback(Callable(ghost, "queue_free"))


func position_hand_drag_ghost(host, global_position: Vector2) -> void:
	if host.manual_drag_ghost == null or not is_instance_valid(host.manual_drag_ghost):
		return
	var ghost_size: Vector2 = host.manual_drag_ghost.custom_minimum_size
	host.manual_drag_ghost.global_position = global_position - ghost_size * 0.5
	host.manual_drag_ghost.visible = true


func set_hand_drag_visual_state(host, valid_drop: bool) -> void:
	if host.manual_drag_ghost != null and is_instance_valid(host.manual_drag_ghost):
		host.manual_drag_ghost.modulate = Color(0.92, 1.08, 0.95, 0.94) if valid_drop else Color(1.08, 0.92, 0.92, 0.88)
	if String(host.manual_drag_state.get("kind", "hand_card")) == "attack":
		apply_attack_drag_highlight(host, int(host.manual_drag_state.get("instance_id", -1)), valid_drop, true)
	else:
		var card_id := String(host.manual_drag_state.get("card_id", host.manual_drag_candidate.get("card_id", "")))
		apply_drag_zone_highlight(host, card_id, valid_drop, true)


func set_drag_board_highlight(host, active: bool) -> void:
	var drag_kind := String(host.manual_drag_state.get("kind", host.manual_drag_candidate.get("kind", "hand_card")))
	if drag_kind == "attack":
		var instance_id := int(host.manual_drag_state.get("instance_id", host.manual_drag_candidate.get("instance_id", -1)))
		apply_attack_drag_highlight(host, instance_id, false, active)
	else:
		var card_id := String(host.manual_drag_state.get("card_id", host.manual_drag_candidate.get("card_id", "")))
		apply_drag_zone_highlight(host, card_id, false, active)


func refresh_drag_preview_layer(host) -> void:
	var layer: Node = host._find_descendant_by_prefix(host, "ManualBoardArcLayer")
	if layer != null and layer is Node2D:
		host._refresh_manual_board_arc_layer(layer)


func hand_card_drag_drop_is_valid(host, card_id: String, global_position: Vector2) -> bool:
	return not hand_card_drag_target(host, card_id, global_position).is_empty()


func hand_card_drag_target(host, card_id: String, global_position: Vector2) -> Dictionary:
	if not can_drag_hand_card(host, card_id):
		return {}
	var card: Dictionary = host.cards_by_id[card_id]
	match host._combat_card_type(card):
		"threat":
			var board_slot := hand_card_drag_target_slot(host, global_position)
			if board_slot >= 0 and host._manual_board_slot_is_open(host.run.manual_combat.get("player", {}), board_slot):
				return { "kind": "board_slot", "slot_index": board_slot }
		"engine":
			var engine_slot := hand_card_drag_engine_target_slot(host, global_position)
			if engine_slot >= 0 and host._manual_engine_slot_is_open(host.run.manual_combat.get("player", {}), engine_slot):
				return { "kind": "engine_slot", "slot_index": engine_slot }
		"action":
			return hand_card_drag_action_target(host, card_id, global_position)
	return {}


func hand_card_drag_target_slot(host, global_position: Vector2) -> int:
	for slot_index in range(host.COMBAT_BOARD_SLOTS):
		var slot: Node = host._find_descendant_by_prefix(host, host._manual_board_slot_anchor(true, slot_index))
		if slot != null and slot is Control and (slot as Control).get_global_rect().has_point(global_position):
			return slot_index
	return -1


func hand_card_drag_engine_target_slot(host, global_position: Vector2) -> int:
	for slot_index in range(host.COMBAT_ENGINE_SLOTS):
		var slot: Node = host._find_descendant_by_prefix(host, host._manual_engine_slot_anchor(true, slot_index))
		if slot != null and slot is Control and (slot as Control).get_global_rect().has_point(global_position):
			return slot_index
	return -1


func hand_card_drag_action_target(host, card_id: String, global_position: Vector2) -> Dictionary:
	if not host.cards_by_id.has(card_id):
		return {}
	var card: Dictionary = host.cards_by_id[card_id]
	var state: Dictionary = host.run.get("manual_combat", {})
	if state.is_empty():
		return {}
	if host._manual_card_can_target_units(card):
		var opponent: Dictionary = state.get("opponent", {})
		for unit in opponent.get("board", []):
			var instance_id := int(unit.get("instance_id", -1))
			var anchor := String(host._manual_unit_card_anchor(false, instance_id))
			if global_point_hits_anchor(host, anchor, global_position):
				return {
					"kind": "action_target",
					"target_type": "unit",
					"target_instance_id": instance_id
				}
	if host._manual_card_can_target_face(card) and global_point_hits_anchor(host, "ManualOpponentFanHand", global_position):
		return {
			"kind": "action_target",
			"target_type": "face",
			"target_instance_id": -1
		}
	return {}


func attack_drag_target(host, instance_id: int, global_position: Vector2) -> Dictionary:
	var state: Dictionary = host.run.get("manual_combat", {})
	if not can_drag_attack_unit(host, instance_id):
		return {}
	var opponent: Dictionary = state.get("opponent", {})
	for unit_value in opponent.get("board", []):
		var unit: Dictionary = unit_value
		var target_instance_id := int(unit.get("instance_id", -1))
		var anchor := String(host._manual_unit_card_anchor(false, target_instance_id))
		if global_point_hits_anchor(host, anchor, global_position):
			return {
				"kind": "attack_target",
				"target_type": "unit",
				"target_instance_id": target_instance_id
			}
	if attack_drag_can_target_face(host, state, instance_id) and global_point_hits_anchor(host, "ManualOpponentFanHand", global_position):
		return {
			"kind": "attack_target",
			"target_type": "face",
			"target_instance_id": -1
		}
	return {}


func attack_drag_can_target_face(host, state: Dictionary, instance_id: int) -> bool:
	var attacker: Dictionary = host._manual_find_player_unit(state, instance_id)
	return not attacker.is_empty() and bool(attacker.get("ready", false)) and host._manual_guard_unit(state).is_empty()


func attack_drag_target_anchor(host, drop_target: Dictionary) -> String:
	match String(drop_target.get("target_type", "")):
		"face":
			return "ManualOpponentFanHand"
		"unit":
			return host._manual_unit_card_anchor(false, int(drop_target.get("target_instance_id", -1)))
	return ""


func global_point_hits_anchor(host, anchor: String, global_position: Vector2) -> bool:
	var node: Node = host._find_descendant_by_prefix(host, anchor)
	return node != null and node is Control and (node as Control).get_global_rect().has_point(global_position)


func reset_drag_highlights(host) -> void:
	var anchors := [
		"ManualZone_PlayerBoard",
		"ManualZone_PlayerEngine",
		"ManualOpponentFanHand",
		"ManualZone_OpponentBoard"
	]
	for anchor in anchors:
		var node: Node = host._find_descendant_by_prefix(host, anchor)
		if node != null and node is Control:
			(node as Control).modulate = Color.WHITE
	var state: Dictionary = host.run.get("manual_combat", {})
	var player: Dictionary = state.get("player", {})
	for unit_value in player.get("board", []):
		var unit: Dictionary = unit_value
		var unit_anchor := String(host._manual_unit_card_anchor(true, int(unit.get("instance_id", -1))))
		var unit_node: Node = host._find_descendant_by_prefix(host, unit_anchor)
		if unit_node != null and unit_node is Control:
			(unit_node as Control).modulate = Color.WHITE
	var opponent: Dictionary = state.get("opponent", {})
	for unit_value in opponent.get("board", []):
		var unit: Dictionary = unit_value
		var unit_anchor := String(host._manual_unit_card_anchor(false, int(unit.get("instance_id", -1))))
		var unit_node: Node = host._find_descendant_by_prefix(host, unit_anchor)
		if unit_node != null and unit_node is Control:
			(unit_node as Control).modulate = Color.WHITE


func apply_drag_zone_highlight(host, card_id: String, valid_drop: bool, active: bool) -> void:
	reset_drag_highlights(host)
	if not active or not host.cards_by_id.has(card_id):
		return

	var color := Color(1.08, 1.16, 1.08, 1.0) if valid_drop else Color(1.12, 1.02, 1.02, 1.0)
	var card: Dictionary = host.cards_by_id[card_id]
	var target_anchors: Array = []
	match host._combat_card_type(card):
		"threat":
			target_anchors.append("ManualZone_PlayerBoard")
		"engine":
			target_anchors.append("ManualZone_PlayerEngine")
		"action":
			if host._manual_card_can_target_face(card):
				target_anchors.append("ManualOpponentFanHand")
			if host._manual_card_can_target_units(card):
				target_anchors.append("ManualZone_OpponentBoard")
	for anchor in target_anchors:
		var node: Node = host._find_descendant_by_prefix(host, anchor)
		if node != null and node is Control:
			(node as Control).modulate = color
	if valid_drop:
		var drop_target: Dictionary = host.manual_drag_state.get("drop_target", {})
		if String(drop_target.get("kind", "")) == "action_target":
			var exact_anchor := ""
			match String(drop_target.get("target_type", "")):
				"face":
					exact_anchor = "ManualOpponentFanHand"
				"unit":
					exact_anchor = host._manual_unit_card_anchor(false, int(drop_target.get("target_instance_id", -1)))
			if exact_anchor != "":
				var exact_node: Node = host._find_descendant_by_prefix(host, exact_anchor)
				if exact_node != null and exact_node is Control:
					(exact_node as Control).modulate = Color(1.18, 1.24, 1.08, 1.0)


func apply_attack_drag_highlight(host, instance_id: int, valid_drop: bool, active: bool) -> void:
	reset_drag_highlights(host)
	if not active:
		return
	var state: Dictionary = host.run.get("manual_combat", {})
	if not can_drag_attack_unit(host, instance_id):
		return
	var color := Color(1.10, 1.16, 1.24, 1.0) if valid_drop else Color(1.12, 1.02, 1.02, 1.0)
	var opponent_board: Node = host._find_descendant_by_prefix(host, "ManualZone_OpponentBoard")
	if opponent_board != null and opponent_board is Control:
		(opponent_board as Control).modulate = color
	if attack_drag_can_target_face(host, state, instance_id):
		var face_node: Node = host._find_descendant_by_prefix(host, "ManualOpponentFanHand")
		if face_node != null and face_node is Control:
			(face_node as Control).modulate = color
	var source_node: Node = host._find_descendant_by_prefix(host, host._manual_unit_card_anchor(true, instance_id))
	if source_node != null and source_node is Control:
		(source_node as Control).modulate = Color(1.10, 1.10, 1.04, 1.0)
	if valid_drop:
		var drop_target: Dictionary = host.manual_drag_state.get("drop_target", {})
		if String(drop_target.get("kind", "")) == "attack_target":
			var exact_anchor := attack_drag_target_anchor(host, drop_target)
			if exact_anchor != "":
				var exact_node: Node = host._find_descendant_by_prefix(host, exact_anchor)
				if exact_node != null and exact_node is Control:
					(exact_node as Control).modulate = Color(1.22, 1.24, 1.08, 1.0)


func drag_footer_text(host, card_id: String) -> String:
	if not host.cards_by_id.has(card_id):
		return "Drop the card on a legal target."
	var card: Dictionary = host.cards_by_id[card_id]
	var card_name := String(card.get("name", card_id))
	match host._combat_card_type(card):
		"threat":
			return "Drag onto an open board slot to play " + card_name + "."
		"engine":
			return "Drag onto an open engine slot to play " + card_name + "."
		"action":
			return "Drag onto the opponent hand or a legal unit target to cast " + card_name + "."
	return "Drop " + card_name + " on a legal target."


func attack_drag_footer_text(host, unit: Dictionary) -> String:
	var unit_name := String(unit.get("name", "attacker"))
	if host._manual_guard_unit(host.run.get("manual_combat", {})).is_empty():
		return "Drag %s onto an enemy threat or the opponent hand to attack face." % unit_name
	return "Drag %s onto an enemy threat. Guard is blocking face attacks." % unit_name


func create_hand_drag_ghost(host, card_id: String) -> Control:
	var box: VBoxContainer = host.card_frame_factory.add_frame(
		host,
		host._card_frame_data(card_id),
		{
			"panel_name": "ManualDragCardGhost",
			"contents_name": "ManualDragCardGhostContents",
			"name_prefix": "ManualDragCard",
			"compact": true,
			"min_size": Vector2(104, 154),
			"mouse_filter": Control.MOUSE_FILTER_IGNORE,
			"show_deck_stats": false,
			"show_rules_text": false,
			"border_color": Color("#ffe08a"),
			"border_width": 2
		}
	)
	var ghost: Control = host._manual_card_panel_from_contents(box)
	if ghost == null:
		return box
	ghost.set_as_top_level(true)
	ghost.z_index = 420
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = ghost.custom_minimum_size
	ghost.scale = Vector2(1.08, 1.08)
	ghost.modulate = Color(1, 1, 1, 0.92)
	ghost.visible = false
	return ghost


func create_attack_drag_ghost(host, unit: Dictionary) -> Control:
	var card_id := String(unit.get("card_id", ""))
	var frame_data: Dictionary = host._card_frame_data(card_id, {
		"title": String(unit.get("name", "Threat")),
		"type_line": host._unit_card_type_line(unit),
		"combat_stats": host._manual_current_unit_summary(unit),
		"effect_text": host._manual_unit_keyword_text(unit),
		"rules_text": host._manual_unit_keyword_text(unit),
		"attack": int(unit.get("attack", 0)),
		"health": int(unit.get("health", 0)),
		"max_health": int(unit.get("max_health", unit.get("health", 0))),
		"show_attack_health": true,
		"animal_color": host._affinity_color(host._unit_animal_type(unit)),
		"frame_color": host._combat_placeholder_color(card_id),
		"border_color": Color("#ffe08a"),
		"border_width": 2
	})
	var box: VBoxContainer = host.card_frame_factory.add_frame(
		host,
		frame_data,
		{
			"panel_name": "ManualDragCardGhost",
			"contents_name": "ManualDragCardGhostContents",
			"name_prefix": "ManualDragCard",
			"compact": true,
			"min_size": Vector2(104, 154),
			"mouse_filter": Control.MOUSE_FILTER_IGNORE,
			"show_deck_stats": false,
			"show_rules_text": false,
			"border_color": Color("#ffe08a"),
			"border_width": 2
		}
	)
	var ghost: Control = host._manual_card_panel_from_contents(box)
	if ghost == null:
		return box
	ghost.set_as_top_level(true)
	ghost.z_index = 420
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = ghost.custom_minimum_size
	ghost.scale = Vector2(1.08, 1.08)
	ghost.modulate = Color(1, 1, 1, 0.92)
	ghost.visible = false
	return ghost


func apply_combat_card_motion(host, card_panel: Control, inspect_card_id: String = "", inspect_zone: String = "", inspect_current: String = "") -> void:
	card_panel.mouse_entered.connect(func() -> void:
		if inspect_card_id != "" and host.current_screen != "ui_combat":
			host._manual_set_inspect_card(inspect_card_id, inspect_zone, inspect_current, false)
		tween_control_feedback(host, card_panel, Vector2(1.035, 1.035), Color(1.12, 1.12, 1.12, 1.0), 0.08)
	)
	card_panel.mouse_exited.connect(func() -> void:
		if inspect_card_id != "" and host.current_screen != "ui_combat":
			host._manual_clear_hover_inspect(inspect_card_id, inspect_zone, inspect_current)
		tween_control_feedback(host, card_panel, Vector2.ONE, Color.WHITE, 0.10)
	)
	card_panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				card_panel.accept_event()
				if host.current_screen == "ui_combat" and event.double_click and handle_card_double_click(host, card_panel, inspect_zone):
					return
				if try_begin_hand_card_drag(host, inspect_card_id, card_panel):
					tween_control_feedback(host, card_panel, Vector2(1.035, 1.035), Color(1.10, 1.10, 1.10, 1.0), 0.06)
					return
				if try_begin_unit_attack_drag(host, card_panel):
					tween_control_feedback(host, card_panel, Vector2(1.035, 1.035), Color(1.10, 1.10, 1.10, 1.0), 0.06)
					return
				if host.current_screen == "ui_combat" and inspect_zone == "Your Board":
					var player_instance_id := player_unit_instance_id_from_panel(card_panel)
					var player_unit: Dictionary = host._manual_find_player_unit(host.run.get("manual_combat", {}), player_instance_id)
					if host._manual_unit_has_action_bubbles(host.run.get("manual_combat", {}), player_unit):
						host._manual_select_attacker(player_instance_id)
						return
				if inspect_card_id != "":
					if host.current_screen == "ui_combat" and inspect_zone == "Hand" and host._manual_can_play_card(host.run.manual_combat, inspect_card_id):
						host._manual_select_card(inspect_card_id)
						return
					host._manual_set_inspect_card(inspect_card_id, inspect_zone, inspect_current, true)
					if host.current_screen == "ui_combat":
						host.call_deferred("_show_active_combat_screen")
				tween_control_feedback(host, card_panel, Vector2(0.985, 0.985), Color(0.95, 0.95, 0.95, 1.0), 0.05)
			else:
				card_panel.accept_event()
				if host.current_screen == "ui_combat" and (not host.manual_drag_candidate.is_empty() or not host.manual_drag_state.is_empty()):
					finish_hand_card_drag(host, host.get_global_mouse_position())
					return
				tween_control_feedback(host, card_panel, Vector2(1.035, 1.035), Color(1.12, 1.12, 1.12, 1.0), 0.07)
	)


func handle_card_double_click(host, card_panel: Control, inspect_zone: String) -> bool:
	if inspect_zone != "Opponent Board":
		return false
	var instance_id := opponent_unit_instance_id_from_panel(card_panel)
	if instance_id < 0:
		return false
	var state: Dictionary = host.run.get("manual_combat", {})
	var unit: Dictionary = host._manual_find_opponent_unit(state, instance_id)
	if unit.is_empty() or not host._manual_selected_can_target_unit(state, unit):
		return false
	host._manual_target_unit(instance_id)
	return true


func tween_control_feedback(host, control: Control, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if not is_instance_valid(control):
		return
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target_scale, duration)
	tween.parallel().tween_property(control, "modulate", target_modulate, duration)
