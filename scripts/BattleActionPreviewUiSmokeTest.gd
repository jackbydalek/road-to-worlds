extends SceneTree
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = load("res://scenes/Tabletop3DPrototype.tscn").instantiate()
	root.add_child(table)
	await create_timer(1.0).timeout
	table.reduced_motion = true
	for side in ["player", "opponent"]:
		table.state[side].plated = []
		table.state[side].prep = []
		table.state[side].turns_started = 2
	# A plain attack isolates overflow; Sriracharrow resolves an attack effect first.
	var attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_wasabi_wasp"), "plated", "player")
	var defender: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("sweet_soft_serve_crab"), "plated", "opponent")
	attacker.table_slot = 2
	defender.table_slot = 2
	table.state.player.plated = [attacker]
	table.state.opponent.plated = [defender]
	table.state.phase = "player_main"
	table.state.selected_attacker = attacker.instance_id
	table.selected_ref = {"kind": "field", "side": "player", "hand_index": -1, "instance_id": attacker.instance_id, "zone": "plated", "card_id": "spicy_wasabi_wasp"}
	table._render_match()
	await settle()
	var attack := table.find_child("CardViewerAction_choose_attacker", true, false) as Button
	expect(attack != null and attack.text.is_empty() and attack.icon == table.ACTION_ICON_ATTACK and not attack.disabled, "Attack is not an available icon-only action")
	var resting_copy := String(table.inspector_action_hint.get_meta("resting_copy", ""))
	var resting_attack_rect := attack.get_global_rect()
	attack.mouse_entered.emit()
	await settle()
	expect(table.inspector_action_hint.visible and table.inspector_action_hint.text.contains(String(attack.get_meta("action_label", ""))), "Hover did not reveal the Attack action name")
	expect(attack.get_global_rect().is_equal_approx(resting_attack_rect), "Hover moved the Attack icon away from the pointer")
	attack.mouse_exited.emit()
	await settle()
	expect(table.inspector_action_hint.text == resting_copy, "Leaving Attack did not restore the resting hint")
	expect(attack.get_global_rect().is_equal_approx(resting_attack_rect), "Leaving hover moved the Attack icon")
	attack.grab_focus()
	await settle()
	expect(table.inspector_action_hint.visible and table.inspector_action_hint.text.contains(String(attack.get_meta("action_label", ""))), "Keyboard focus did not reveal the Attack action name")
	expect(attack.get_global_rect().is_equal_approx(resting_attack_rect), "Keyboard focus moved the Attack icon")
	attack.release_focus()
	await settle()
	expect(table.inspector_action_hint.text == resting_copy, "Leaving keyboard focus did not restore the resting hint")
	expect(attack.get_global_rect().is_equal_approx(resting_attack_rect), "Leaving keyboard focus moved the Attack icon")
	var target: Node3D = table._card_node_for_instance(defender.instance_id)
	var point: Vector2 = table._card_screen_rect(target).get_center()
	var mouse := InputEventMouseMotion.new()
	mouse.position = point
	mouse.global_position = point
	root.push_input(mouse, true)
	if DisplayServer.get_name() != "headless":
		Input.warp_mouse(point)
		await create_timer(0.2).timeout
		table._update_attack_preview_pointer()
	else:
		table._show_attack_preview(defender.instance_id, point)
	expect(is_instance_valid(table.attack_preview_panel) and table.attack_preview_panel.visible, "Hovering the actual defender did not open a combat preview")
	if is_instance_valid(table.attack_preview_panel):
		expect(String(table.attack_preview_panel.get_meta("copy", "")).contains("Bodyguard"), "Bodyguard overflow protection is missing from the hover preview")
		expect(root.get_visible_rect().encloses(table.attack_preview_panel.get_global_rect()), "Attack preview clips")
	attacker.ready = false
	table._refresh_action_panel()
	await settle()
	attack = table.find_child("CardViewerAction_choose_attacker", true, false) as Button
	expect(attack.disabled and attack.tooltip_text == "Already attacked", "Unavailable Attack has no accurate reason")
	attack.mouse_entered.emit()
	expect(table.inspector_action_hint.text.contains(String(attack.get_meta("action_label", ""))) and table.inspector_action_hint.text.contains("Already attacked"), "Disabled Attack hover omitted its action name or reason")
	attack.mouse_exited.emit()
	expect(not is_instance_valid(table.attack_preview_panel) or not table.attack_preview_panel.visible, "An exhausted attacker retained a preview")
	# Disabled hand actions keep the actual constraint visible while hover names the icon.
	table.state.player.chef_used = true
	table.state.player.hand = ["chef_mary"]
	table.selected_ref = {"kind": "hand", "side": "player", "hand_index": 0, "instance_id": -1, "zone": "hand", "card_id": "chef_mary"}
	table._refresh_action_panel()
	await settle()
	var play := table.find_child("CardViewerAction_play_card", true, false) as Button
	expect(play.disabled and play.tooltip_text == "Chef used this turn", "Play did not explain the spent Chef action")
	expect(play.text.is_empty() and play.icon == table.ACTION_ICON_PLAY, "Disabled Play did not retain its icon-only button")
	play.mouse_entered.emit()
	expect(table.inspector_action_hint.text.contains(String(play.get_meta("action_label", ""))) and table.inspector_action_hint.text.contains("Chef used this turn"), "Play hover omitted its action name or spent-Chef reason")
	play.mouse_exited.emit()
	expect(table.inspector_action_hint.visible and table.inspector_action_hint.text.contains("Chef used this turn"), "Leaving Play removed the persistent disabled reason")
	# Maximum text plus an actual long Meal restriction previously resized the
	# preview on hover, moving the button away and causing enter/exit flicker.
	table.configure_battle_preferences("fast", 1.5, true, false)
	table.state.player.hand = ["spicy_sriracharrow"]
	table.state.player.prep.clear()
	var snail: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("sweet_cinnamon_snail"), "plated", "opponent")
	snail.table_slot = 0
	table.state.opponent.plated = [snail]
	table.selected_ref = {"kind": "hand", "side": "player", "hand_index": 0, "instance_id": -1, "zone": "hand", "card_id": "spicy_sriracharrow"}
	table._refresh_action_panel()
	await settle()
	var serve := table.find_child("CardViewerAction_serve_normally", true, false) as Button
	expect(serve != null and serve.disabled, "Long Meal-restriction fixture did not disable Serve")
	var resting_serve_rect := serve.get_global_rect()
	for cycle in range(3):
		serve.mouse_entered.emit()
		await settle()
		expect(serve.get_global_rect().is_equal_approx(resting_serve_rect), "Maximum-text Meal hover moved the icon (cycle %d)" % cycle)
		serve.mouse_exited.emit()
		await settle()
		expect(serve.get_global_rect().is_equal_approx(resting_serve_rect), "Maximum-text Meal hover exit moved the icon (cycle %d)" % cycle)
	table.queue_free()
	await settle()
	for error in errors:
		push_error(error)
	print("Battle action UI smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func settle() -> void:
	for unused in range(8):
		await process_frame

func expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
