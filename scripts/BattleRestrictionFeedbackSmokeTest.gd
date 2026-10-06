extends "res://outputs/lineless_implementation_2026-09-11/capture_battle.gd"

const FEEDBACK_OUTPUT := "res://outputs/battle_feedback_2026-09-11/restrictions"


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FEEDBACK_OUTPUT))
	for output_size in [Vector2i(1280, 720), Vector2i(1440, 900)]:
		capture_size = output_size
		await _create_match()
		table.configured_card_border_id = "blue"
		table.face_materials.clear()
		for text_scale in [1.0, 1.5]:
			table.configure_battle_preferences("fast", text_scale, true, false)
			_stage_board(false)
			table.state.player.prep.clear()
			table.state.player.plated.clear()
			table.state.opponent.plated.clear()
			table.state.player.hand = ["spicy_sriracharrow", "item_wooden_spoon"]
			_add_unit("player", "spicy_hot_honey_bee", "prep", 0)
			_add_unit("opponent", "sweet_cinnamon_snail", "plated", 0)
			_select_hand(0)
			await _settle()
			var serve := table.find_child("CardViewerAction_serve_normally", true, false) as Button
			_expect(serve != null and serve.disabled, "Unpayable taxed Meal is still advertised as playable")
			_expect(table.inspector_action_hint.text.contains("Cinnamon Snail") and table.inspector_action_hint.text.contains("+1 Ingredient"), "Meal inspector hides the effect source")
			_expect(table.restriction_panel.visible, "No persistent restriction panel")
			_check_feedback_layout()
			table._begin_hand_play_selection(0)
			_expect(table.pending_hand_play_index == -1 and table.action_highlight_slots.is_empty(), "Blocked Meal advertises destinations")
			_expect(table.status_label.text.contains("Cinnamon Snail"), "Failed play does not name the blocker")
			table._dismiss_invalid_action()
			await _save_shot("snail_%s" % str(text_scale))
			var source_button := table.restriction_panel.find_child("Restriction_sweet_cinnamon_snail", true, false) as Button
			source_button.pressed.emit()
			await _settle()
			_expect(String(table.selected_ref.get("card_id", "")) == "sweet_cinnamon_snail", "Restriction source cannot be inspected")
			_expect(table.inspector_card_face.get_global_rect().get_center().x < table.size.x * 0.5, "Effect inspection moved off the left")
			_add_unit("opponent", "sweet_toffee_collie", "prep", 1)
			_add_unit("opponent", "sweet_pudding_puma", "plated", 1)
			for unit in [table.state.opponent.prep.back(), table.state.opponent.plated.back()]:
				table.service._resolve_effects(table.state, "opponent", table.service.card(String(unit.card_id)).get("on_combat_damage_to_chef", []), unit)
			_select_hand(1)
			await _settle()
			var play := table.find_child("CardViewerAction_play_card", true, false) as Button
			_expect(play.disabled and play.tooltip_text.contains("Sweet Pugtato"), "Tool action lacks source attribution")
			_expect(table.inspector_action_hint.visible and table.inspector_action_hint.text.contains("until your turn ends"), "Tool lock is only explained on hover")
			_expect(table.restriction_panel.get_meta("restrictions", []).size() == 3, "Concurrent restrictions are omitted")
			_expect(table.restriction_panel.scroll.get_v_scroll_bar().is_visible_in_tree(), "Multiple effects have no scrolling affordance")
			var panel_font := (table.restriction_panel.content.get_child(0).get_child(0) as Label).get_theme_font_size("font_size")
			table.configure_battle_preferences("fast", text_scale, true, false)
			await _settle()
			_expect((table.restriction_panel.content.get_child(0).get_child(0) as Label).get_theme_font_size("font_size") == panel_font, "Preferences compound the effect font scale")
			var last_effect := table.restriction_panel.content.get_child(2) as Button
			last_effect.grab_focus()
			await _settle()
			_expect(table.restriction_panel.scroll.get_global_rect().intersects(last_effect.get_global_rect()), "Keyboard-focused effect stays outside scroll view")
			last_effect.release_focus()
			table.restriction_panel.scroll.scroll_vertical = 0
			await _settle()
			_check_feedback_layout()
			await _save_shot("tool_lock_%s" % str(text_scale))
			var before: Array = table.state.player.hand.duplicate()
			table._play_hand_card(1, "prep")
			_expect(table.state.player.hand == before and table.status_label.text.contains("Sweet Pugtato"), "Blocked Tool changed hand or lost feedback")
			table._dismiss_invalid_action()
			table.service._clear_play_restrictions(table.state.player)
			table.state.opponent.plated.clear()
			_select_hand(1)
			await _settle()
			play = table.find_child("CardViewerAction_play_card", true, false) as Button
			_expect(not table.restriction_panel.visible and not play.disabled, "Expired restrictions leave stale UI")
			table.selected_ref = {}
			table._render_match()
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	for error in errors:
		push_error(error)
	print("BATTLE_RESTRICTION_FEEDBACK: 4 size/text configurations, %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)


func _select_hand(index: int) -> void:
	table.selected_ref = {"kind": "hand", "side": "player", "hand_index": index, "instance_id": -1, "zone": "hand", "card_id": String(table.state.player.hand[index])}
	table._render_match()


func _check_feedback_layout() -> void:
	var rect: Rect2 = table.restriction_panel.get_global_rect()
	_expect(table.get_viewport_rect().encloses(rect), "Restrictions clip outside screen")
	for control in [table.opponent_profile_badge, table.end_turn_button, table.settings_button, table.battle_log_button]:
		_expect(not rect.intersects(control.get_global_rect()), "Restrictions overlap " + String(control.name))
	for button in table.inspector_action_buttons:
		_expect(table.get_viewport_rect().encloses(button.get_global_rect()), "Inspector action clips")
	_expect(table.get_viewport_rect().encloses(table.inspector_action_hint.get_global_rect()), "Block explanation clips")
	_expect(not table.inspector_action_hint.get_global_rect().intersects(table.player_profile_badge.get_global_rect()), "Player life covers the blocked-action explanation")
	_expect(table.action_scroll.get_global_rect().encloses(table.inspector_action_hint.get_global_rect()), "Blocked-action explanation is clipped by the inspector scroll boundary")


func _save_shot(state_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)
	var filename := "%dx%d_%s.png" % [capture_size.x, capture_size.y, state_name]
	_expect(capture_viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(FEEDBACK_OUTPUT.path_join(filename))) == OK, "Capture failed: " + filename)
