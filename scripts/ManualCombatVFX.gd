extends RefCounted
class_name ManualCombatVFX


func add_recent_events(host, parent: Node, state: Dictionary) -> void:
	var log_lines: Array = state.get("log", [])
	if log_lines.is_empty():
		return

	var panel: VBoxContainer = host._add_panel(parent, "Combat Feedback", "#1c2430")
	panel.name = "ManualFeedbackPanel"
	var chips := HBoxContainer.new()
	chips.name = "ManualFeedbackChips"
	chips.add_theme_constant_override("separation", 8)
	panel.add_child(chips)

	var start_index: int = max(0, log_lines.size() - 4)
	for i in range(start_index, log_lines.size()):
		add_feedback_chip(host, chips, String(log_lines[i]))


func add_action_animation(host, parent: Node) -> void:
	var animation: Dictionary = host.run.get("manual_animation", {})
	if animation.is_empty():
		return

	var panel: VBoxContainer = host._add_panel(parent, "Action Animation", "#151d28")
	panel.name = "ManualAnimationPanel"

	var summary := Label.new()
	summary.name = "ManualAnimationSummary"
	summary.text = "%s: %s" % [
		String(animation.get("verb", "Action")),
		String(animation.get("card_name", "Card"))
	]
	summary.add_theme_color_override("font_color", Color("#f3efe4"))
	panel.add_child(summary)

	var route := Label.new()
	route.name = "ManualAnimationRoute"
	route.text = "%s -> %s -> %s" % [
		String(animation.get("source_zone", "Source")),
		String(animation.get("target_zone", "Target")),
		String(animation.get("destination_zone", "Destination"))
	]
	route.add_theme_color_override("font_color", Color("#a9c7ff"))
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(route)

	var track := Control.new()
	track.name = "ManualAnimationTrack"
	track.custom_minimum_size = Vector2(0, 88)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(track)

	var rail := ColorRect.new()
	rail.name = "ManualAnimationRail"
	rail.color = Color("#273241")
	rail.position = Vector2(10, 42)
	rail.size = Vector2(500, 3)
	track.add_child(rail)

	add_target_arc(host, track, animation)

	var ghost := create_animation_ghost(host, animation)
	track.add_child(ghost)
	animate_ghost(host, ghost)

	var badges := HBoxContainer.new()
	badges.name = "ManualImpactBadges"
	badges.add_theme_constant_override("separation", 8)
	panel.add_child(badges)
	for badge in animation.get("badges", []):
		add_impact_badge(host, badges, badge)


func add_action_summary(host, parent: Node) -> void:
	var animation: Dictionary = host.run.get("manual_animation", {})
	if animation.is_empty():
		return

	var panel: VBoxContainer = host._add_panel(parent, "Last Action", "#151d28")
	panel.name = "ManualActionSummaryPanel"

	var summary := Label.new()
	summary.name = "ManualActionSummary"
	summary.text = "%s: %s" % [
		String(animation.get("verb", "Action")),
		String(animation.get("card_name", "Card"))
	]
	summary.add_theme_color_override("font_color", Color("#f3efe4"))
	panel.add_child(summary)

	var route := Label.new()
	route.name = "ManualActionRoute"
	route.text = "%s -> %s -> %s" % [
		String(animation.get("source_zone", "Source")),
		String(animation.get("target_zone", "Target")),
		String(animation.get("destination_zone", "Destination"))
	]
	route.add_theme_color_override("font_color", Color("#a9c7ff"))
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(route)

	var badges := HBoxContainer.new()
	badges.name = "ManualImpactBadges"
	badges.add_theme_constant_override("separation", 8)
	panel.add_child(badges)
	for badge in animation.get("badges", []):
		add_impact_badge(host, badges, badge)


func refresh_board_arc_layer(host, layer: Node2D) -> void:
	if not is_instance_valid(layer):
		return
	for child in layer.get_children():
		child.queue_free()

	var state: Dictionary = host.run.get("manual_combat", {})
	if state.is_empty():
		return
	var root := layer.get_parent()
	if root == null:
		return
	if host.current_screen == "ui_combat" and root.get_parent() != null:
		root = root.get_parent()

	add_selection_preview_arcs(host, layer, root, state)
	add_drag_preview_arc(host, layer, root, state)
	add_committed_board_arc(host, layer, root)


func add_selection_preview_arcs(host, layer: Node2D, root: Node, state: Dictionary) -> void:
	var selection: Dictionary = host._manual_selection()
	if selection.is_empty():
		return

	var source_anchor := ""
	var preview_color := Color("#ffe08a")
	match String(selection.get("kind", "")):
		"attacker":
			var attacker_id := int(selection.get("instance_id", -1))
			var attacker: Dictionary = host._manual_find_player_unit(state, attacker_id)
			if attacker.is_empty() or not bool(attacker.get("ready", false)):
				return
			source_anchor = host._manual_unit_anchor(state, "player", attacker_id)
			preview_color = arc_color("Attack")
		"card":
			var card_id := String(selection.get("card_id", ""))
			if not host.cards_by_id.has(card_id) or not host._manual_can_play_card(state, card_id):
				return
			return
		_:
			return

	if source_anchor == "":
		return

	if host._manual_selected_can_target_face(state):
		var face_anchor: String = host._manual_target_anchor(state, "face", -1, true)
		var fallback_face_anchor := "ManualOpponentFanHand" if host.current_screen == "ui_combat" else "ManualOpponentPanel"
		if not draw_board_arc(host, layer, root, source_anchor, face_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", preview_color, 3.0, true):
			draw_board_arc(host, layer, root, source_anchor, fallback_face_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", preview_color, 3.0, true)

	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		var target_unit: Dictionary = unit
		if host._manual_selected_can_target_unit(state, target_unit):
			var target_anchor: String = host._manual_unit_anchor(state, "opponent", int(target_unit.get("instance_id", -1)))
			draw_board_arc(host, layer, root, source_anchor, target_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", preview_color, 3.0, true)


func add_drag_preview_arc(host, layer: Node2D, root: Node, _state: Dictionary) -> void:
	if host.manual_drag_state.is_empty():
		return
	if String(host.manual_drag_state.get("kind", "hand_card")) == "attack":
		add_attack_drag_preview_arc(host, layer, root)
		return
	var card_id := String(host.manual_drag_state.get("card_id", ""))
	if not host.cards_by_id.has(card_id):
		return
	if host._combat_card_type(host.cards_by_id[card_id]) != "action":
		return
	var drop_target: Dictionary = host.manual_drag_state.get("drop_target", {})
	if String(drop_target.get("kind", "")) != "action_target":
		return
	var source_global_data: Variant = host.manual_drag_state.get("global_position", [])
	if typeof(source_global_data) != TYPE_ARRAY or source_global_data.size() < 2:
		return
	var target_anchor := ""
	match String(drop_target.get("target_type", "")):
		"face":
			target_anchor = "ManualOpponentFanHand"
		"unit":
			target_anchor = host._manual_unit_card_anchor(false, int(drop_target.get("target_instance_id", -1)))
		_:
			return
	if target_anchor == "":
		return
	var drew_arc := draw_board_arc(host, layer, root, "", target_anchor, "ManualDragTargetPreviewArc", "ManualDragTargetPreviewArrowHead", Color("#7fb8ff"), 4.0, true, 0.0, source_global_data)
	if drew_arc:
		return
	var fallback_source_data: Variant = host.manual_drag_state.get("source_global", [])
	if typeof(fallback_source_data) == TYPE_VECTOR2:
		var fallback_source: Vector2 = fallback_source_data
		fallback_source_data = [fallback_source.x, fallback_source.y]
	draw_board_arc(host, layer, root, "", target_anchor, "ManualDragTargetPreviewArc", "ManualDragTargetPreviewArrowHead", Color("#7fb8ff"), 4.0, true, 0.0, fallback_source_data)


func add_attack_drag_preview_arc(host, layer: Node2D, root: Node) -> void:
	var drop_target: Dictionary = host.manual_drag_state.get("drop_target", {})
	if String(drop_target.get("kind", "")) != "attack_target":
		return
	var source_global_data: Variant = host.manual_drag_state.get("global_position", [])
	if typeof(source_global_data) != TYPE_ARRAY or source_global_data.size() < 2:
		return
	var target_anchor: String = host._manual_attack_drag_target_anchor(drop_target)
	if target_anchor == "":
		return
	var drew_arc := draw_board_arc(host, layer, root, "", target_anchor, "ManualDragAttackPreviewArc", "ManualDragAttackPreviewArrowHead", arc_color("Attack"), 4.0, true, 0.0, source_global_data)
	if drew_arc:
		return
	var fallback_source_data: Variant = host.manual_drag_state.get("source_global", [])
	if typeof(fallback_source_data) == TYPE_VECTOR2:
		var fallback_source: Vector2 = fallback_source_data
		fallback_source_data = [fallback_source.x, fallback_source.y]
	draw_board_arc(host, layer, root, "", target_anchor, "ManualDragAttackPreviewArc", "ManualDragAttackPreviewArrowHead", arc_color("Attack"), 4.0, true, 0.0, fallback_source_data)


func add_committed_board_arc(host, layer: Node2D, root: Node) -> void:
	var animation: Dictionary = host.run.get("manual_animation", {})
	if animation.is_empty():
		return
	if bool(animation.get("board_vfx_started", false)):
		return
	var source_anchor := String(animation.get("source_anchor", ""))
	var target_anchor := String(animation.get("target_anchor", ""))
	var destination_anchor := String(animation.get("destination_anchor", ""))
	if target_anchor == "":
		target_anchor = destination_anchor
	if destination_anchor == "":
		destination_anchor = target_anchor
	var should_draw_arrow := animation_should_draw_target_arrow(animation, target_anchor, destination_anchor)
	if host.current_screen == "ui_combat":
		source_anchor = visible_anchor_or_fallback(root, source_anchor, ui_combat_vfx_source_fallback_anchor(animation))
		var fallback_anchor := ui_combat_vfx_fallback_anchor(animation)
		target_anchor = visible_anchor_or_fallback(root, target_anchor, fallback_anchor)
		destination_anchor = visible_anchor_or_fallback(root, destination_anchor, target_anchor)
	if source_anchor == "" or target_anchor == "":
		return
	var started_vfx := false
	if should_draw_arrow:
		started_vfx = draw_board_arc(
			host,
			layer,
			root,
			source_anchor,
			target_anchor,
			"ManualBoardTargetArc",
			"ManualBoardTargetArrowHead",
			arc_color(String(animation.get("verb", "Action"))),
			5.0,
			false,
			0.85,
			animation.get("source_global_point", []),
			animation.get("target_global_point", [])
		)
	if add_board_card_travel(host, layer, root, animation, source_anchor, target_anchor, destination_anchor):
		started_vfx = true
	if not started_vfx:
		return
	animation["board_vfx_started"] = true
	host.run.manual_animation = animation
	if host._manual_has_pending_action():
		host._manual_schedule_pending_action_commit()
	elif not host.run.get("manual_animation_queue", []).is_empty():
		host._manual_schedule_animation_queue_advance(animation)
	elif host._manual_has_pending_opponent_turn():
		host._manual_schedule_pending_opponent_turn_commit(animation)
	pulse_anchor(host, root, source_anchor, Color("#ffe08a"))
	if should_draw_arrow:
		pulse_anchor(host, root, target_anchor, arc_color(String(animation.get("verb", "Action"))))
	if destination_anchor != target_anchor:
		pulse_anchor(host, root, destination_anchor, Color("#9ee66e"))
	elif not should_draw_arrow:
		pulse_anchor(host, root, destination_anchor, Color("#9ee66e"))
	add_board_impact_badges(host, layer, root, animation, target_anchor if should_draw_arrow else destination_anchor)


func draw_board_arc(
	host,
	layer: Node2D,
	root: Node,
	source_anchor: String,
	target_anchor: String,
	line_name: String,
	arrow_name: String,
	color: Color,
	width: float,
	preview: bool,
	lifetime: float = 0.0,
	source_global_data: Variant = [],
	target_global_data: Variant = []
) -> bool:
	var source_data := anchor_or_stored_point_in_layer(layer, root, source_anchor, source_global_data)
	var target_data := anchor_or_stored_point_in_layer(layer, root, target_anchor, target_global_data)
	if not bool(source_data.get("ok", false)) or not bool(target_data.get("ok", false)):
		return false

	var source: Vector2 = source_data.get("point", Vector2.ZERO)
	var target: Vector2 = target_data.get("point", Vector2.ZERO)
	if source.distance_to(target) < 4.0:
		return false

	var curve_control := board_arc_control_point(source, target)
	var line_color := color
	if preview:
		line_color.a = 0.48

	var arc := Line2D.new()
	arc.name = line_name
	arc.width = width
	arc.default_color = line_color
	arc.antialiased = true
	for i in range(24):
		var t := float(i) / 23.0
		var a := source.lerp(curve_control, t)
		var b := curve_control.lerp(target, t)
		arc.add_point(a.lerp(b, t))
	layer.add_child(arc)

	var previous := arc.get_point_position(max(0, arc.get_point_count() - 2))
	var direction := (target - previous).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var normal := Vector2(-direction.y, direction.x)
	var arrow_size := 16.0 if preview else 20.0
	var arrow := Line2D.new()
	arrow.name = arrow_name
	arrow.width = width
	arrow.default_color = line_color
	arrow.antialiased = true
	arrow.add_point(target)
	arrow.add_point(target - direction * arrow_size + normal * (arrow_size * 0.55))
	arrow.add_point(target)
	arrow.add_point(target - direction * arrow_size - normal * (arrow_size * 0.55))
	layer.add_child(arrow)

	if not preview:
		arc.modulate = Color(1, 1, 1, 0.25)
		arrow.modulate = Color(1, 1, 1, 0.25)
		var tween: Tween = host.create_tween()
		tween.tween_property(arc, "modulate", Color.WHITE, 0.12)
		tween.parallel().tween_property(arrow, "modulate", Color.WHITE, 0.12)
		tween.tween_property(arc, "width", width + 2.0, 0.08)
		tween.parallel().tween_property(arrow, "width", width + 2.0, 0.08)
		tween.tween_property(arc, "width", width, 0.12)
		tween.parallel().tween_property(arrow, "width", width, 0.12)
		if lifetime > 0.0:
			tween.tween_interval(lifetime)
			tween.tween_property(arc, "modulate", Color(1, 1, 1, 0), 0.20)
			tween.parallel().tween_property(arrow, "modulate", Color(1, 1, 1, 0), 0.20)
			tween.tween_callback(Callable(arc, "queue_free"))
			tween.tween_callback(Callable(arrow, "queue_free"))

	return true


func animation_should_draw_target_arrow(animation: Dictionary, target_anchor: String, destination_anchor: String) -> bool:
	var verb := String(animation.get("verb", "Action"))
	if verb == "Attack":
		return true
	if verb != "Cast":
		return false
	if target_anchor == "" or target_anchor == destination_anchor:
		return false
	var target_zone := String(animation.get("target_zone", ""))
	return target_zone.contains("Opponent") or target_zone.contains("Your")


func visible_anchor_or_fallback(root: Node, anchor: String, fallback_anchor: String) -> String:
	if anchor != "" and find_descendant_by_prefix(root, anchor) != null:
		return anchor
	return fallback_anchor


func ui_combat_vfx_fallback_anchor(animation: Dictionary) -> String:
	var target_zone := String(animation.get("target_zone", "")).to_lower()
	var destination_zone := String(animation.get("destination_zone", "")).to_lower()
	var target_text := "%s %s" % [target_zone, destination_zone]
	if target_zone.contains("your face"):
		return "ManualFanHand"
	if target_zone.contains("your board"):
		return "ManualZone_PlayerBoard"
	if target_zone.contains("opponent face"):
		return "ManualOpponentFanHand"
	if target_zone.contains("opponent board"):
		return "ManualZone_OpponentBoard"
	return "ManualOpponentFanHand" if target_text.contains("opponent") else "ManualPlayerResourceReadout"


func ui_combat_vfx_source_fallback_anchor(animation: Dictionary) -> String:
	var source_zone := String(animation.get("source_zone", "")).to_lower()
	if source_zone.contains("opponent hand"):
		return "ManualOpponentFanHand"
	if source_zone.contains("your hand"):
		return "ManualFanHand"
	if source_zone.contains("opponent board"):
		return "ManualZone_OpponentBoard"
	if source_zone.contains("your board"):
		return "ManualZone_PlayerBoard"
	return "ManualFanHand"


func add_board_card_travel(host, layer: Node2D, root: Node, animation: Dictionary, source_anchor: String, target_anchor: String, destination_anchor: String) -> bool:
	var source_data := anchor_or_stored_point_in_layer(layer, root, source_anchor, animation.get("source_global_point", []))
	var target_data := anchor_or_stored_point_in_layer(layer, root, target_anchor, animation.get("target_global_point", []))
	var destination_data := anchor_or_stored_point_in_layer(layer, root, destination_anchor, animation.get("destination_global_point", []))
	if not bool(source_data.get("ok", false)) or not bool(target_data.get("ok", false)):
		return false
	if not bool(destination_data.get("ok", false)):
		destination_data = target_data

	var source: Vector2 = source_data.get("point", Vector2.ZERO)
	var target: Vector2 = target_data.get("point", Vector2.ZERO)
	var destination: Vector2 = destination_data.get("point", Vector2.ZERO)
	var ghost := create_board_action_ghost(host, animation)
	var ghost_size := ghost.custom_minimum_size
	ghost.position = source - ghost_size * 0.5
	ghost.pivot_offset = ghost_size * 0.5
	layer.add_child(ghost)

	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	ghost.modulate = Color(1, 1, 1, 0.0)
	ghost.scale = Vector2(0.92, 0.92)
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0.94), 0.08)
	tween.parallel().tween_property(ghost, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(ghost, "position", target - ghost_size * 0.5, 0.22)
	tween.parallel().tween_property(ghost, "rotation_degrees", 2.0, 0.22)
	tween.tween_property(ghost, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(ghost, "scale", Vector2.ONE, 0.10)
	if destination.distance_to(target) > 10.0:
		tween.tween_property(ghost, "position", destination - ghost_size * 0.5, 0.20)
		tween.parallel().tween_property(ghost, "rotation_degrees", -2.0, 0.20)
	tween.tween_interval(0.10)
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.22)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.94, 0.94), 0.22)
	tween.tween_callback(Callable(ghost, "queue_free"))
	return true


func create_board_action_ghost(host, animation: Dictionary) -> PanelContainer:
	var card_id := String(animation.get("card_id", ""))
	var ghost := PanelContainer.new()
	ghost.name = "ManualBoardMovingCardGhost"
	ghost.custom_minimum_size = Vector2(154, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = host._combat_placeholder_color(card_id) if host.cards_by_id.has(card_id) else Color("#2d3442")
	style.border_color = Color("#ffe08a")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	ghost.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	ghost.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var label := Label.new()
	label.text = String(animation.get("card_name", "Card"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(label)

	var route := Label.new()
	route.text = String(animation.get("verb", "Action"))
	route.add_theme_font_size_override("font_size", 12)
	route.add_theme_color_override("font_color", Color("#c7d0df"))
	box.add_child(route)
	return ghost


func pulse_anchor(host, root: Node, anchor: String, color: Color) -> void:
	var node := find_descendant_by_prefix(root, anchor)
	if node == null or not (node is Control):
		return
	var control := node as Control
	control.pivot_offset = control.size * 0.5
	var original_modulate := control.modulate
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.08)
	tween.parallel().tween_property(control, "modulate", Color(
		min(1.45, color.r + 0.35),
		min(1.45, color.g + 0.35),
		min(1.45, color.b + 0.35),
		1.0
	), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(control, "modulate", original_modulate, 0.18)


func add_board_impact_badges(host, layer: Node2D, root: Node, animation: Dictionary, target_anchor: String) -> void:
	var badges: Array = animation.get("badges", [])
	if badges.is_empty():
		return
	var target_node := find_descendant_by_prefix(root, target_anchor)
	if target_node == null:
		return
	var target := node_center_in_layer(layer, target_node)
	var offset_index := 0
	for badge in badges.slice(0, min(3, badges.size())):
		var board_badge := create_board_impact_badge(badge)
		board_badge.position = target + Vector2(18 * offset_index, -26 - 14 * offset_index)
		board_badge.pivot_offset = Vector2(35, 18)
		layer.add_child(board_badge)
		animate_board_impact_badge(host, board_badge)
		offset_index += 1


func create_board_impact_badge(badge: Dictionary) -> PanelContainer:
	var impact := PanelContainer.new()
	impact.name = "ManualBoardImpactBadge"
	impact.custom_minimum_size = Vector2(70, 36)
	var colors := impact_badge_colors(String(badge.get("kind", "log")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colors.get("background", "#26303d"))
	style.border_color = Color(colors.get("border", "#465060"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	impact.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = String(badge.get("text", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(colors.get("text", "#eef3ff")))
	impact.add_child(label)
	return impact


func animate_board_impact_badge(host, badge: Control) -> void:
	badge.scale = Vector2(0.78, 0.78)
	badge.modulate = Color(1, 1, 1, 0.0)
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate", Color.WHITE, 0.08)
	tween.parallel().tween_property(badge, "scale", Vector2(1.16, 1.16), 0.12)
	tween.tween_property(badge, "position", badge.position + Vector2(0, -24), 0.34)
	tween.parallel().tween_property(badge, "modulate", Color(1, 1, 1, 0), 0.34)
	tween.tween_callback(Callable(badge, "queue_free"))


func board_arc_control_point(source: Vector2, target: Vector2) -> Vector2:
	var midpoint := (source + target) * 0.5
	var lift: float = clamp(source.distance_to(target) * 0.22, 48.0, 140.0)
	return midpoint + Vector2(0, -lift)


func node_center_in_layer(layer: Node2D, node: Node) -> Vector2:
	if node is Control:
		var rect := (node as Control).get_global_rect()
		return layer.to_local(rect.get_center())
	if node is Node2D:
		return layer.to_local((node as Node2D).global_position)
	return Vector2.ZERO


func capture_anchor_global_point(root: Node, anchor: String) -> Array:
	if anchor == "":
		return []
	var node := find_descendant_by_prefix(root, anchor)
	if node == null:
		return []
	var center := node_global_center(node)
	return [center.x, center.y]


func anchor_or_stored_point_in_layer(layer: Node2D, root: Node, anchor: String, global_data: Variant) -> Dictionary:
	var node := find_descendant_by_prefix(root, anchor)
	if node != null:
		return {
			"ok": true,
			"point": node_center_in_layer(layer, node)
		}
	var stored := global_point_from_data(global_data)
	if bool(stored.get("ok", false)):
		return {
			"ok": true,
			"point": layer.to_local(stored.get("point", Vector2.ZERO))
		}
	return {
		"ok": false,
		"point": Vector2.ZERO
	}


func global_point_from_data(global_data: Variant) -> Dictionary:
	if typeof(global_data) == TYPE_ARRAY and global_data.size() >= 2:
		return {
			"ok": true,
			"point": Vector2(float(global_data[0]), float(global_data[1]))
		}
	return {
		"ok": false,
		"point": Vector2.ZERO
	}


func node_global_center(node: Node) -> Vector2:
	if node is Control:
		return (node as Control).get_global_rect().get_center()
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


func find_descendant_by_prefix(root: Node, target_prefix: String) -> Node:
	if root == null or target_prefix == "":
		return null
	if String(root.name).begins_with(target_prefix):
		return root
	for child in root.get_children():
		var found := find_descendant_by_prefix(child, target_prefix)
		if found != null:
			return found
	return null


func add_target_arc(host, parent: Node, animation: Dictionary) -> void:
	var source := Vector2(66, 66)
	var control := Vector2(245, 2)
	var target := Vector2(424, 66)
	var destination := Vector2(532, 66)

	var arc := Line2D.new()
	arc.name = "ManualTargetArc"
	arc.width = 4.0
	arc.default_color = arc_color(String(animation.get("verb", "Action")))
	arc.antialiased = true
	for i in range(18):
		var t := float(i) / 17.0
		var a := source.lerp(control, t)
		var b := control.lerp(target, t)
		arc.add_point(a.lerp(b, t))
	parent.add_child(arc)

	var arrow := Line2D.new()
	arrow.name = "ManualTargetArrowHead"
	arrow.width = 4.0
	arrow.default_color = arc.default_color
	arrow.antialiased = true
	arrow.add_point(target)
	arrow.add_point(target + Vector2(-16, -10))
	arrow.add_point(target)
	arrow.add_point(target + Vector2(-16, 10))
	parent.add_child(arrow)

	add_arc_marker(parent, "ManualArcSourceMarker", source, "SRC", String(animation.get("source_zone", "Source")), Color("#a9c7ff"))
	add_arc_marker(parent, "ManualArcTargetMarker", target, "TGT", String(animation.get("target_zone", "Target")), Color("#ffb3a6"))
	add_arc_marker(parent, "ManualArcDestinationMarker", destination, "DST", String(animation.get("destination_zone", "Destination")), Color("#9ee66e"))

	var tween: Tween = host.create_tween()
	arc.modulate = Color(1, 1, 1, 0.2)
	arrow.modulate = Color(1, 1, 1, 0.2)
	tween.tween_property(arc, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.parallel().tween_property(arrow, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.tween_property(arc, "width", 6.0, 0.10)
	tween.parallel().tween_property(arrow, "width", 6.0, 0.10)
	tween.tween_property(arc, "width", 4.0, 0.12)
	tween.parallel().tween_property(arrow, "width", 4.0, 0.12)


func arc_color(verb: String) -> Color:
	match verb:
		"Attack":
			return Color("#f06f5f")
		"Cast":
			return Color("#7fb8ff")
		"Activate":
			return Color("#ffe08a")
		_:
			return Color("#9ee66e")


func add_arc_marker(parent: Node, node_name: String, position: Vector2, short_text: String, tooltip: String, color: Color) -> void:
	var marker := PanelContainer.new()
	marker.name = node_name
	marker.position = position - Vector2(28, 16)
	marker.custom_minimum_size = Vector2(56, 30)
	marker.tooltip_text = tooltip
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.55)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	marker.add_theme_stylebox_override("panel", style)
	parent.add_child(marker)

	var label := Label.new()
	label.text = short_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#eef3ff"))
	marker.add_child(label)


func create_animation_ghost(host, animation: Dictionary) -> PanelContainer:
	var card_id := String(animation.get("card_id", ""))
	var ghost := PanelContainer.new()
	ghost.name = "ManualMovingCardGhost"
	ghost.custom_minimum_size = Vector2(154, 58)
	ghost.position = Vector2(10, 14)
	ghost.pivot_offset = Vector2(77, 29)
	var style := StyleBoxFlat.new()
	style.bg_color = host._combat_placeholder_color(card_id) if host.cards_by_id.has(card_id) else Color("#2d3442")
	style.border_color = Color("#ffe08a")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	ghost.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	ghost.add_child(margin)

	var label := Label.new()
	label.text = String(animation.get("card_name", "Card"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	margin.add_child(label)
	return ghost


func animate_ghost(host, ghost: Control) -> void:
	ghost.modulate = Color(1, 1, 1, 0.82)
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "position", Vector2(150, 4), 0.18)
	tween.tween_property(ghost, "position", Vector2(330, 14), 0.24)
	tween.parallel().tween_property(ghost, "modulate", Color(1.18, 1.18, 1.18, 1.0), 0.18)
	tween.tween_property(ghost, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(ghost, "scale", Vector2.ONE, 0.12)


func add_impact_badge(host, parent: Node, badge: Dictionary) -> void:
	var impact := PanelContainer.new()
	impact.name = "ManualImpactBadge"
	impact.custom_minimum_size = Vector2(82, 42)
	impact.pivot_offset = Vector2(41, 21)
	var colors := impact_badge_colors(String(badge.get("kind", "log")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colors.get("background", "#26303d"))
	style.border_color = Color(colors.get("border", "#465060"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	impact.add_theme_stylebox_override("panel", style)
	parent.add_child(impact)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	impact.add_child(margin)

	var label := Label.new()
	label.name = "ManualImpactBadgeText"
	label.text = String(badge.get("text", "FX"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(colors.get("text", "#eef3ff")))
	label.tooltip_text = String(badge.get("line", ""))
	margin.add_child(label)

	animate_impact_badge(host, impact)


func impact_badge_colors(kind: String) -> Dictionary:
	match kind:
		"damage":
			return { "background": "#3a211f", "border": "#f06f5f", "text": "#ffb3a6" }
		"heal":
			return { "background": "#1f3323", "border": "#7fc46b", "text": "#bfe8a5" }
		"draw":
			return { "background": "#1d2a43", "border": "#6f99e8", "text": "#a9c7ff" }
		"ko":
			return { "background": "#371f2c", "border": "#d46a95", "text": "#ff9fc2" }
		"focus":
			return { "background": "#25351c", "border": "#a7d469", "text": "#d7ff9d" }
		_:
			return { "background": "#352d1c", "border": "#d6a84e", "text": "#ffe08a" }


func animate_impact_badge(host, badge: Control) -> void:
	badge.scale = Vector2(0.88, 0.88)
	var tween: Tween = host.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "scale", Vector2(1.18, 1.18), 0.12)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.16)


func add_feedback_chip(host, parent: Node, line: String) -> void:
	var feedback := feedback_data(line)
	var chip := PanelContainer.new()
	chip.name = "ManualFeedbackChip"
	chip.custom_minimum_size = Vector2(132 if host.current_screen == "ui_combat" else 170, 0)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(feedback.get("background", "#26303d"))
	style.border_color = Color(feedback.get("border", "#465060"))
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var tag := Label.new()
	tag.name = "ManualFeedbackKind"
	tag.text = String(feedback.get("tag", "LOG"))
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(feedback.get("color", "#d8dfec")))
	box.add_child(tag)

	var body := Label.new()
	body.name = "ManualFeedbackText"
	body.text = line
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#eef3ff"))
	box.add_child(body)


func feedback_data(line: String) -> Dictionary:
	var lower := line.to_lower()
	if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("trades"):
		return { "tag": "DMG", "color": "#ffb3a6", "background": "#3a211f", "border": "#f06f5f" }
	if lower.contains("dies") or lower.contains("destroy"):
		return { "tag": "KO", "color": "#ff9fc2", "background": "#371f2c", "border": "#d46a95" }
	if lower.contains("restore") or lower.contains("heal"):
		return { "tag": "HEAL", "color": "#bfe8a5", "background": "#1f3323", "border": "#7fc46b" }
	if lower.contains("draw"):
		return { "tag": "DRAW", "color": "#a9c7ff", "background": "#1d2a43", "border": "#6f99e8" }
	if lower.contains("create") or lower.contains("token") or lower.contains("plays"):
		return { "tag": "PLAY", "color": "#ffe08a", "background": "#352d1c", "border": "#d6a84e" }
	if lower.contains("turn") or lower.contains("focus"):
		return { "tag": "TURN", "color": "#c7d0df", "background": "#242b36", "border": "#5d6a7a" }
	return { "tag": "LOG", "color": "#d8dfec", "background": "#26303d", "border": "#465060" }


func log_line_color(line: String) -> Color:
	var lower := line.to_lower()
	if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("trades") or lower.contains("dies"):
		return Color("#ffb3a6")
	if lower.contains("restore") or lower.contains("draw") or lower.contains("creates"):
		return Color("#bfe8a5")
	if lower.contains("turn"):
		return Color("#a9c7ff")
	return Color("#d8dfec")
