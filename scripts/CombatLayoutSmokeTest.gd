extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PREVIEW_PATH := "res://outputs/sketch_campaign/10_battle_ui.png"
const RULE_ERROR_PREVIEW_PATH := "res://outputs/sketch_campaign/10b_battle_rule_error.png"
const MEAL_AURA_PREVIEW_PATH := "res://outputs/sketch_campaign/10c_meal_selection_aura.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.production_match = true
	table.configured_match_context = {
		"tournament_round": true,
		"event_name": "Weekly Locals",
		"round": 1,
		"rounds": 3,
	}
	table.reset_button.visible = false
	table.exit_button.text = "LEAVE MATCH"
	table.exit_button.custom_minimum_size.x = 126

	table.state.player.prep = [_unit(table, "player", "spicy_jalapeno_panther", "prep", 0, false)]
	table.state.player.plated = [
		_unit(table, "player", "spicy_sriracharrow", "plated", 0, true),
		_unit(table, "player", "spicy_firecracker_shrimp", "plated", 1, true),
	]
	table.state.opponent.prep = [_unit(table, "opponent", "hearty_french_bread_dog", "prep", 1, false)]
	table.state.opponent.plated = [_unit(table, "opponent", "hearty_bagver", "plated", 0, true)]
	table.state.message = "Choose a card to play or attack with."
	table._render_match()
	await create_timer(1.9).timeout
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	table._render_match()
	await process_frame
	await process_frame
	await create_timer(0.18).timeout

	_expect(table.find_child("MatchOverviewRail", true, false) == null, "The removed match-overview rail is still present.")
	_expect(table.find_child("CommandRail", true, false) == null, "The removed command rail is still present.")
	_expect(table.find_child("CombatLine", true, false) == null, "The removed combat-flow line is still present.")
	_expect(table.find_child("MatchOptionsButton", true, false) != null, "The match HUD is missing its compact options control.")
	var board_info_button := table.find_child("BoardInfoButton", true, false) as Button
	_expect(board_info_button != null and board_info_button.text == "i", "The match HUD is missing its table-information control.")
	_expect(not table.player_life.visible and not table.opponent_life.visible, "Duplicate life totals still occupy the top HUD.")
	_expect((table.player_chef.get_node("Label") as Label3D).text == "15", "The player Chef puck still shows a name instead of only its life total.")
	_expect((table.opponent_chef.get_node("Label") as Label3D).text == "15", "The rival Chef puck still shows a name instead of only its life total.")
	var board_info_labels: Array[Label3D] = []
	for label_node in table.card_layer.find_children("*", "Label3D", true, false):
		if bool(label_node.get_meta("board_info_label", false)):
			board_info_labels.append(label_node as Label3D)
	_expect(not board_info_labels.is_empty(), "The table information labels were not tagged for the HUD toggle.")
	for board_label in board_info_labels:
		_expect(not board_label.visible, "A table label or pile count is visible before opening table information.")
	if board_info_button != null:
		board_info_button.emit_signal("pressed")
		for board_label in board_info_labels:
			_expect(board_label.visible, "The information control did not reveal a table label or pile count.")
		board_info_button.emit_signal("pressed")
		for board_label in board_info_labels:
			_expect(not board_label.visible, "The information control did not hide a table label or pile count.")
	var match_options_button := table.find_child("MatchOptionsButton", true, false) as Button
	var readability_controls := table.find_child("ReadabilityControls", true, false) as PanelContainer
	if match_options_button != null:
		match_options_button.emit_signal("pressed")
		_expect(readability_controls != null and readability_controls.visible, "Match Options did not reveal the readability controls.")
		match_options_button.emit_signal("pressed")
		_expect(readability_controls != null and not readability_controls.visible, "Match Options did not collapse the readability controls.")
	_expect(table.battle_log_button.get_parent().name == "TopRow", "The match log still floats over the battlefield.")
	_expect(table.turn_label.text == "YOUR TURN  •  TURN 1", "The match HUD does not clearly identify turn ownership.")
	_expect(table.title_label.text == "Weekly Locals  •  ROUND 1 OF 3", "The match HUD still exposes prototype or AI-facing copy.")
	_expect(table.end_turn_button.text == "END TURN  →", "The primary turn action is not clearly labeled.")
	for choice_button in [table.confirm_choice_button, table.cancel_choice_button, table.battle_log_close_button, table.card_tray_confirm_button, table.card_tray_skip_button]:
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			_expect(
				choice_button.get_theme_color(color_name).get_luminance() >= 0.70,
				"A dark battle-menu button has low-contrast text in its %s state." % color_name
			)
	_expect(table.status_context_label.text == "YOUR MOVE", "The instruction strip is missing its action context.")
	_expect(not table.status_panel.visible, "The bottom instruction strip remains visible during ordinary play.")
	var ordinary_message := String(table.state.message)
	var meal_test_ingredient: Dictionary = table.state.player.prep[0]
	var meal_test_ingredient_id := int(meal_test_ingredient.instance_id)
	var original_recipe_ready_turn := int(meal_test_ingredient.get("recipe_ready_on_turn", 0))
	meal_test_ingredient.recipe_ready_on_turn = 0
	table.state.player.hand.append("spicy_sriracharrow")
	var meal_test_hand_index: int = table.state.player.hand.size() - 1
	table.state.pending_meal = {
		"hand_index": meal_test_hand_index,
		"card_id": "spicy_sriracharrow",
		"destination": "prep",
		"destination_slot": 1,
		"required": 1,
	}
	table.state.selected_ingredients = []
	table.state.message = "Choose Ingredients for Sriracharrow."
	table._render_match()
	_expect(table.status_panel.visible, "A required Meal decision did not reveal the contextual action bar.")
	_expect(table.confirm_choice_button.visible and table.cancel_choice_button.visible, "The Meal action bar is missing Confirm or Cancel.")
	_expect(table.confirm_choice_button.get_parent().name == "StatusRow", "Confirm and Cancel were moved outside the contextual action bar.")
	var meal_candidate_card := table.find_child("PlayerPrepCard_%d" % meal_test_ingredient_id, true, false) as Node3D
	var candidate_aura := meal_candidate_card.find_child("MealIngredientCandidateAura", true, false) as MeshInstance3D if meal_candidate_card != null else null
	_expect(candidate_aura != null, "A recipe-ready Meal ingredient did not receive the ability-style candidate aura.")
	table.state.selected_ingredients = [meal_test_ingredient_id]
	table._render_match()
	var selected_meal_card := table.find_child("PlayerPrepCard_%d" % meal_test_ingredient_id, true, false) as Node3D
	var selected_meal_aura := selected_meal_card.find_child("MealIngredientSelectedAura", true, false) as MeshInstance3D if selected_meal_card != null else null
	_expect(selected_meal_aura != null, "A selected Meal ingredient did not receive the stronger ability-style aura.")
	if selected_meal_aura != null:
		var selected_aura_material := selected_meal_aura.material_override as StandardMaterial3D
		_expect(selected_aura_material != null and selected_aura_material.albedo_texture.resource_path.ends_with("ability_ready_aura.svg"), "The Meal selection aura does not reuse the ability-aura texture.")
		_expect(table.pulsing_field_auras.has(selected_meal_aura), "The selected Meal ingredient aura is not registered for pulsing animation.")
	if DisplayServer.get_name() != "headless":
		await process_frame
		var meal_aura_preview := root.get_texture().get_image()
		_expect(
			meal_aura_preview != null and meal_aura_preview.save_png(ProjectSettings.globalize_path(MEAL_AURA_PREVIEW_PATH)) == OK,
			"Could not save the Meal ingredient aura preview."
		)
	table.state.pending_meal = {}
	table.state.selected_ingredients = []
	table.state.player.hand.remove_at(meal_test_hand_index)
	meal_test_ingredient.recipe_ready_on_turn = original_recipe_ready_turn
	table.state.message = ordinary_message
	table._render_match()
	_expect(not table.status_panel.visible, "The contextual action bar remained visible after its decision ended.")
	_expect("CURRENT" in table.battle_log_text.text and String(table.state.message) in table.battle_log_text.text, "Current match guidance was not moved into the match log.")
	table.dragging = true
	table._refresh_status_panel_visibility()
	_expect(not table.status_panel.visible, "The rule-error toast appeared during a valid card drag.")
	table.dragging = false
	table._refresh_status_panel_visibility()
	var chef_hand_index := -1
	for hand_index in range(table.state.player.hand.size()):
		if String(table.service.card(String(table.state.player.hand[hand_index])).get("card_type", "")) == "chef":
			chef_hand_index = hand_index
			break
	_expect(chef_hand_index >= 0, "The invalid-action smoke test could not find a Chef in hand.")
	if chef_hand_index >= 0:
		table.state.player.chef_used = true
		await table._play_hand_card(chef_hand_index, "prep")
		_expect(table.invalid_action_visible and table.status_panel.visible, "An illegal second Chef did not show the rule-error toast.")
		_expect("already used a Chef" in table.status_label.text, "The rule-error toast did not explain the second-Chef restriction.")
		table._dismiss_invalid_action()
		table.state.player.chef_used = false

	table.state.player.hand.append("spicy_sriracharrow")
	table.state.player.meal_served = true
	table.state.player.meals_served = 1
	await table._play_hand_card(table.state.player.hand.size() - 1, "prep", 1)
	_expect(table.invalid_action_visible and "already served a Meal" in table.status_label.text, "An illegal second Meal did not show its rule explanation.")
	table._dismiss_invalid_action()
	table.state.player.meal_served = false
	table.state.player.meals_served = 0
	table.state.player.hand.erase("spicy_sriracharrow")

	var original_opponent_plated: Array = table.state.opponent.plated.duplicate(true)
	var original_turn := int(table.state.turn)
	var original_player_turns_started := int(table.state.player.turns_started)
	var original_attacker := int(table.state.get("selected_attacker", -1))
	var attacker: Dictionary = table.state.player.plated[0]
	var attacker_ready := bool(attacker.get("ready", false))
	var taunt_unit := _unit(table, "opponent", "hearty_french_bread_dog", "plated", 0, true)
	var non_taunt_unit := _unit(table, "opponent", "hearty_bagver", "plated", 1, true)
	table.state.opponent.plated = [taunt_unit, non_taunt_unit]
	table.state.turn = 2
	table.state.player.turns_started = 2
	attacker.ready = true
	table.state.selected_attacker = int(attacker.instance_id)
	await table._perform_attack(int(non_taunt_unit.instance_id))
	_expect(table.invalid_action_visible and "Taunt must be attacked first" in table.status_label.text, "Ignoring Taunt did not show its rule explanation.")
	if DisplayServer.get_name() != "headless":
		await process_frame
		var rule_error_preview := root.get_texture().get_image()
		_expect(
			rule_error_preview != null and rule_error_preview.save_png(ProjectSettings.globalize_path(RULE_ERROR_PREVIEW_PATH)) == OK,
			"Could not save the rule-error toast preview."
		)
	table._dismiss_invalid_action()
	table.state.opponent.plated = original_opponent_plated
	table.state.turn = original_turn
	table.state.player.turns_started = original_player_turns_started
	table.state.selected_attacker = original_attacker
	attacker.ready = attacker_ready
	table._render_match()
	_expect(not table.status_panel.visible, "The rule-error toast did not dismiss cleanly.")
	_expect(table.camera.position.y >= 12.0 and table.camera.position.z <= 8.6, "Combat camera is not using the overhead board angle.")
	_expect(table.camera.fov >= 41.0, "Combat camera is too tightly cropped to show the full table.")
	_expect(table.find_children("*PlatedCard_*", "Node3D", true, false).size() == 3, "Camera preview did not render all Plated cards.")
	var ability_card: Node3D = table.find_child("PlayerPrepCard_*", true, false)
	var ability_aura := ability_card.find_child("AbilityReadyAura", true, false) as MeshInstance3D if ability_card != null else null
	_expect(ability_aura != null and ability_aura.material_override is StandardMaterial3D, "A field card with a ready activated ability has no glowing aura.")
	_expect(table.find_children("AbilityReadyAura", "MeshInstance3D", true, false).size() == 1, "The ability-ready aura appeared on a card that cannot currently activate an ability.")
	var hand_card: Node3D = table.find_child("PlayerHandCard_0", true, false)
	_expect(hand_card != null, "Camera preview did not render the player's hand.")
	if hand_card != null:
		var hand_rect: Rect2 = table._card_screen_rect(hand_card)
		var visible_hand_rect := hand_rect.intersection(Rect2(Vector2.ZERO, table.viewport_container.size))
		_expect(visible_hand_rect.size.y >= hand_rect.size.y * 0.72, "Too much of the player's hand is clipped below the screen.")
		var status_panel: Control = table.get_node("Interface/StatusPanel")
		_expect(hand_rect.end.y <= status_panel.global_position.y - 4.0, "The message strip blocks the player's hand cards.")
		var visible_click_point := Vector2(visible_hand_rect.get_center().x, visible_hand_rect.position.y + 12.0)
		_expect(table._pick_card(visible_click_point) == hand_card, "The visible portion of a hand card is not clickable.")
		_expect(table._can_drag_card(hand_card), "A player hand card cannot begin a drag during the player's main phase.")
		_expect(table._mouse_to_table(visible_click_point) != null, "A visible hand-card click cannot be projected onto the table for dragging.")

	var opponent_hand_card := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_expect(opponent_hand_card != null, "Camera preview did not render the opponent's hand.")
	if opponent_hand_card != null:
		var opponent_hand_rect: Rect2 = table._card_screen_rect(opponent_hand_card)
		var opponent_hand_click := opponent_hand_rect.get_center()
		_expect(
			table._screen_hits_opponent_hand(opponent_hand_click),
			"The visible opponent hand did not register as a rival-face attack target."
		)
		_expect(
			table._pick_card(opponent_hand_click) == null,
			"The opponent hand entered the normal card picker and could expose hidden card information."
		)

	if DisplayServer.get_name() != "headless":
		var preview := root.get_texture().get_image()
		_expect(
			preview != null and preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH)) == OK,
			"Could not save the overhead combat preview."
		)

	if failed:
		quit(1)
		return
	print("Combat camera smoke test passed." + (" Preview: " + PREVIEW_PATH if DisplayServer.get_name() != "headless" else ""))
	quit()


func _unit(table, side: String, card_id: String, zone: String, slot: int, ready: bool) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(
		table.state,
		table.state[side],
		table.service.card(card_id),
		zone,
		side
	)
	unit.table_slot = slot
	unit.ready = ready
	return unit


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
