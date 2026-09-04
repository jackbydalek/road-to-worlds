extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const OUTPUT_PATH := "res://outputs/illustrated_vfx/card_viewer_action_icons.png"
const FIELD_OUTPUT_PATH := "res://outputs/illustrated_vfx/card_viewer_field_actions.png"
const ZONE_OUTPUT_PATH := "res://outputs/illustrated_vfx/card_play_zone_hover.png"
const TURN_OUTPUT_PATH := "res://outputs/illustrated_vfx/battle_round_turn_ui.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(0.9).timeout
	table.production_match = true
	table.configured_match_context = {
		"tournament_round": true,
		"event_name": "Weekly Locals",
		"round": 1,
		"rounds": 3,
	}
	table._render_match()
	table.turn_banner_title.text = "YOUR TURN"
	table.turn_banner_subtitle.text = "TURN 1  •  READY YOUR KITCHEN"
	table.turn_banner_surface.configure(PALETTE.SURFACE_PAPER, PALETTE.SELECTION_BLUE, false, false)
	table.turn_banner_accent_rule.color = PALETTE.SELECTION_BLUE
	table.turn_banner_panel.visible = true
	table.turn_banner_panel.modulate = Color.WHITE
	table.turn_banner_panel.scale = Vector2.ONE
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var turn_preview := root.get_texture().get_image()
		if turn_preview == null or turn_preview.save_png(ProjectSettings.globalize_path(TURN_OUTPUT_PATH)) != OK:
			push_error("Could not save round-and-turn UI preview.")
			failed = true
	table.turn_banner_panel.visible = false
	var inspected_hand_index := 0
	for hand_index in range(table.state.player.hand.size()):
		var candidate_id := String(table.state.player.hand[hand_index])
		if String(table.service.card(candidate_id).get("card_type", "")) in ["ingredient", "meal"]:
			inspected_hand_index = hand_index
			break
	var inspected_card_id := String(table.state.player.hand[inspected_hand_index])
	table.selected_ref = {
		"kind": "hand",
		"side": "player",
		"hand_index": inspected_hand_index,
		"instance_id": -1,
		"zone": "",
		"card_id": inspected_card_id,
	}
	table._refresh_action_panel()
	table._show_card_viewer_action_hint("Play Card")
	for action_button in table.inspector_action_buttons:
		_expect(
			String(action_button.get_meta("ui_button_shape", "")) == "card_action"
			and action_button.custom_minimum_size == Vector2(80, 58),
			"A card-viewer action did not use the wide clipped action-button geometry."
		)
	if is_instance_valid(table.turn_banner_panel):
		table.turn_banner_panel.visible = false
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var preview := root.get_texture().get_image()
		if preview == null or preview.save_png(ProjectSettings.globalize_path(OUTPUT_PATH)) != OK:
			push_error("Could not save card inspector preview.")
			failed = true
	table._begin_hand_play_selection(inspected_hand_index)
	if not table.action_highlight_slots.is_empty():
		var hover_choice: Dictionary = table.action_highlight_slots[0]
		table._update_action_destination_hover(table._world_to_container(
			table._slot_world_position(String(hover_choice.zone), int(hover_choice.slot))
		))
		table._update_zone_flair(0.0)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var zone_preview := root.get_texture().get_image()
		if zone_preview == null or zone_preview.save_png(ProjectSettings.globalize_path(ZONE_OUTPUT_PATH)) != OK:
			push_error("Could not save legal-zone hover preview.")
			failed = true
	table._cancel_pending_hand_play()
	for hand_index in range(table.state.player.hand.size() - 1, -1, -1):
		var hand_card_id := String(table.state.player.hand[hand_index])
		if String(table.service.card(hand_card_id).get("card_type", "")) == "spice":
			table.state.player.hand.remove_at(hand_index)
	var field_card_id := "hearty_gravy_gazelle"
	var field_unit: Dictionary = table.service._make_unit(
		table.state,
		table.state.player,
		table.service.card(field_card_id),
		"plated",
		"player"
	)
	field_unit.table_slot = 0
	field_unit.ready = true
	table.state.player.plated = [field_unit]
	table.selected_ref = {
		"kind": "field",
		"side": "player",
		"hand_index": -1,
		"instance_id": int(field_unit.instance_id),
		"zone": "plated",
		"card_id": field_card_id,
	}
	table._refresh_action_panel()
	table._show_card_viewer_action_hint("Activate Ability")
	_expect(not _has_action(table, "Season This Card"), "The field viewer showed Season This Card without a Spice in hand.")
	_expect(not _has_action(table, "Select for Recipe"), "The field viewer showed the redundant recipe-selection action.")
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var field_preview := root.get_texture().get_image()
		if field_preview == null or field_preview.save_png(ProjectSettings.globalize_path(FIELD_OUTPUT_PATH)) != OK:
			push_error("Could not save field-action card viewer preview.")
			failed = true
	table.state.player.hand.append("spice_savory_gravy")
	table._refresh_action_panel()
	_expect(_has_action(table, "Season This Card"), "The field viewer did not restore Season This Card when a Spice entered the hand.")
	var face_click := _left_click(table.inspector_card_face.get_global_rect().get_center())
	table._input(face_click)
	_expect(not table.selected_ref.is_empty(), "Clicking the viewed card dismissed the card viewer.")
	var action_button := table.inspector_action_buttons[0] as Button
	table._input(_left_click(action_button.get_global_rect().get_center()))
	_expect(not table.selected_ref.is_empty(), "Clicking a card action dismissed the card viewer before the button could run.")
	table._input(_left_click(Vector2(720.0, 120.0)))
	_expect(table.selected_ref.is_empty() and not table.action_panel.visible, "Clicking away from the card and its actions did not dismiss the viewer.")
	for tween in get_processed_tweens():
		tween.kill()
	table.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)


func _left_click(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	return event


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _has_action(table, action_label: String) -> bool:
	for button in table.inspector_action_buttons:
		if is_instance_valid(button) and String(button.get_meta("action_label", "")) == action_label:
			return true
	return false
