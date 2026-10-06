extends SceneTree
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var table = load("res://scenes/Tabletop3DPrototype.tscn").instantiate()
	root.add_child(table)
	await create_timer(0.3).timeout
	table.reduced_motion = true
	table.state.game_over = false
	table.state.phase = "player_main"
	table.state.player.prep = []
	table.state.player.plated = []
	table.state.opponent.prep = []
	table.state.opponent.plated = []
	table.state.player.turns_started = 2
	table.state.player.meals_served = 1
	table.state.player.meal_served = true
	table.state.player.hand = ["spicy_quesadillama", "spicy_quesadillama"]
	var payment: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "prep", "player")
	payment.attack = 3
	payment.table_slot = 0
	table.state.player.prep.append(payment)
	table.selected_ref = {"kind": "hand", "side": "player", "hand_index": 0, "instance_id": -1, "zone": "hand", "card_id": "spicy_quesadillama"}
	table._render_match()
	await settle()
	var normal := table.find_child("CardViewerAction_serve_normally", true, false) as Button
	var special := table.find_child("CardViewerAction_special_serve", true, false) as Button
	expect(normal != null and normal.disabled, "Used normal summon remained available")
	expect(special != null and not special.disabled and special.icon == table.ACTION_ICON_SPECIAL_SERVE, "Special Serve action missing or disabled")
	expect(normal != null and normal.text.is_empty() and normal.icon == table.ACTION_ICON_PLAY, "Normal action must show only its icon")
	expect(special != null and special.text.is_empty(), "Special action must show only its icon")
	expect(table.inspector_card_face.get_global_rect().end.x < table.size.x * 0.5, "Battle preview left the left side")
	expect(table.inspector_action_hint.text.contains("Keeps your normal Meal allowance"), "Special allowance explanation missing")
	await capture("special_serve_actions")
	for scale_value in [1.25, 1.5]:
		table.configure_battle_preferences("fast", scale_value, true, false)
		table._refresh_action_panel()
		await settle()
		for action_button in table.inspector_action_buttons:
			expect(table.action_panel.get_global_rect().encloses(action_button.get_global_rect()), "Large-text action escaped the left preview")
		expect(table.action_panel.get_global_rect().encloses(table.inspector_action_hint.get_global_rect()), "Large-text Special Serve condition clipped")
		expect(table.inspector_action_hint.get_global_rect().end.y < table.player_profile_badge.get_global_rect().position.y - 6, "Special Serve explanation overlaps player life")
		special = table.find_child("CardViewerAction_special_serve", true, false) as Button
		special.mouse_entered.emit()
		await settle()
		expect(table.inspector_action_hint.text.contains("Special Serve") and table.inspector_action_hint.text.contains("Keeps your normal Meal allowance"), "Special Serve hover lost its label or allowance explanation")
		expect(table.inspector_action_hint.get_global_rect().end.y < table.player_profile_badge.get_global_rect().position.y - 6, "Special Serve hover label overlaps player life")
		special.mouse_exited.emit()
	table.state.phase = "opponent_turn"
	table._refresh_action_panel()
	expect(table.inspector_action_buttons.is_empty() and table.action_panel.visible, "Rival turn must allow inspection without player actions")
	expect(table.inspector_action_hint.text == "Wait for your turn", "Rival-turn inspection has no waiting explanation")
	table.state.phase = "player_main"
	table._refresh_action_panel()
	special = table.find_child("CardViewerAction_special_serve", true, false) as Button
	if special != null:
		special.pressed.emit()
	await settle()
	expect(table.pending_hand_special and table.pending_hand_play_index == 0, "Special button lost summon mode")
	# Use the occupied payment slot: the summon must replace the selected Ingredient.
	table._choose_pending_hand_destination("prep", 0)
	await settle()
	expect(bool(table.state.get("pending_meal", {}).get("special", false)), "Destination selection reverted to normal summon")
	var card_node: Node3D = table._card_node_for_instance(int(payment.instance_id))
	if card_node != null:
		table._handle_card_click(card_node)
	await settle()
	expect(table.service.meal_selection_is_ready(table.state), "UI could not select a freshly played special payment")
	expect(table.confirm_choice_button.text == "Special Serve" and not table.confirm_choice_button.disabled, "Confirm did not show Special Serve")
	await capture("special_serve_payment")
	await table._confirm_meal_play()
	await settle()
	expect(table.state.player.prep.size() == 1 and table.state.player.prep[0].card_id == "spicy_quesadillama", "UI summon did not replace its payment")
	expect(int(table.state.player.prep[0].table_slot) == 0 and int(table.state.player.meals_served) == 1, "UI summon lost slot or changed normal allowance")
	expect(table.state.player.hand.size() == 1 and table.state.player.discard.has("spicy_hot_honey_bee"), "UI summon did not pay exactly once")
	table.queue_free()
	await settle()
	for error in errors:
		push_error(error)
	print("Weekly Special Serve UI smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func settle() -> void:
	for unused in range(8):
		await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle()
	var directory := "res://outputs/weekly_demo_2026-09-10"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.get_texture().get_image().save_png(directory + "/" + label + ".png")

func expect(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
