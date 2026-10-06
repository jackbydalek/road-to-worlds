extends SceneTree

## Live choice states: run headless for regressions, or with --capture for PNGs.
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_DIR := "res://outputs/choice_visibility_2026-09-11"
var failures: Array[String] = []
var table
var capture_viewport: SubViewport
var capture_size := Vector2i(1280, 720)
var save_captures := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	save_captures = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	if save_captures:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var sizes := [Vector2i(1280, 720), Vector2i(1440, 900)] if save_captures else [Vector2i(1280, 720)]
	for output_size in sizes:
		capture_size = output_size
		await _create_match()
		await _test_board_choice()
		await _test_ability_choice()
		await _test_meal_choice()
		await _test_hand_discard_choice()
		await _test_card_tray_choice()
		table.queue_free()
		await process_frame
		capture_viewport.queue_free()
		await process_frame
	for failure in failures:
		push_error(failure)
	print("Choice target clarity: board effects, abilities, recipes, discard costs, trays, cleanup and Reduced Motion; %d failures." % failures.size())
	quit(0 if failures.is_empty() else 1)


func _create_match() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = capture_size
	var canvas_scale := minf(float(capture_size.x) / 1440.0, float(capture_size.y) / 900.0)
	capture_viewport.size_2d_override = Vector2i(Vector2(capture_size) / canvas_scale)
	capture_viewport.size_2d_override_stretch = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	table = TABLE_SCENE.instantiate()
	table.configure_match(
		{"chef_bill": 3, "spicy_hot_honey_bee": 3, "spicy_wasabi_wasp": 3, "spicy_jalapeno_panther": 3, "spicy_sriracharrow": 3, "spicy_firecracker_shrimp": 3, "item_wooden_spoon": 2},
		{"chef_mary": 3, "sweet_sugar_glider": 3, "sweet_caramel_camel": 3, "sweet_soft_serve_crab": 3, "sweet_strawberry_sharkcake": 3, "sweet_jellyfish": 3, "item_wooden_spoon": 2},
		"You", "Pip", 20260907, "player", "Return", "easy", "blue",
		{"event_name": "Weekly Locals", "round": 1, "rounds": 4, "week": 1, "tournament_round": true, "player_starter": "spicy", "opponent_affinity": "sweet", "rival_cast_id": "pip", "rival_display_name": "Pip"},
		{"player_life": 32, "player_max_life": 40, "opponent_life": 18, "opponent_max_life": 25}
	)
	table.configure_battle_preferences("fast", 1.0, true, false)
	capture_viewport.add_child(table)
	await _settle(14)
	await create_timer(1.3).timeout
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()


func _reset() -> void:
	table.state.phase = "player_main"
	table.state.turn = 4
	table.state.first_player = "opponent"
	table.state.game_over = false
	table.state.selected_attacker = -1
	table.state.selected_ingredients = []
	table.state.selected_spice_target = -1
	table.state.animation_events = []
	table.state.message = "Choose a card to play or attack with."
	for key in ["pending_meal", "pending_discard", "pending_ability", "pending_search", "pending_choice", "pending_resume", "pending_reaction"]:
		table.state[key] = {}
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated", "discard"]:
			table.state[side][zone] = []
		table.state[side].turns_started = 2
		table.state[side].environment = ""
		table.state[side].meal_served = false
		table.state[side].zone_move_used = false
		table.state[side].chef_used = false
	table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon", "spicy_sriracharrow"]
	table.state.opponent.hand = ["sweet_sugar_glider", "sweet_jellyfish", "item_wooden_spoon"]
	table.selected_ref = {}
	table.manual_discard_tray_side = ""
	table.reduced_motion = true


func _test_board_choice() -> void:
	_reset()
	var friendly := _unit("player", "spicy_hot_honey_bee", "prep", 0)
	var enemy_a := _unit("opponent", "sweet_jellyfish", "prep", 0)
	var enemy_b := _unit("opponent", "hearty_macaroni_manatee", "prep", 2)
	var attacker := _unit("player", "spicy_sriracharrow", "plated", 0)
	var defender := _unit("opponent", "sweet_strawberry_sharkcake", "plated", 0)
	defender.health = 20
	defender.max_health = 20
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table.service.attack(table.state, int(defender.instance_id))
	table._render_match()
	var expected := [int(friendly.instance_id), int(enemy_a.instance_id), int(enemy_b.instance_id)]
	_expect(table.service.choice_target_ids(table.state).size() == expected.size(), "Sriracharrow did not enter its real three-Prep-card choice.")
	_expect_exact_targets(expected)
	await _shot("01_board_choice")
	table.service.choose_effect_target(table.state, int(defender.instance_id))
	_expect(not table.state.pending_choice.is_empty(), "Invalid Plated target unexpectedly ended the choice.")
	table._cancel_bottom_choice()
	_expect(table.state.pending_choice.is_empty() and table.state.pending_resume.is_empty(), "Cancel did not clear the attack's board choice.")
	_expect_no_choice_markers("Cancelled board choice")
	table.service.attack(table.state, int(defender.instance_id))
	var health_before := int(enemy_b.health)
	table.service.choose_effect_target(table.state, int(enemy_b.instance_id))
	table._render_match()
	_expect(int(enemy_b.health) == health_before - 1 and table.state.pending_choice.is_empty(), "Selected legal Prep card did not resolve the attack ability.")
	_expect_no_choice_markers("Resolved board choice")


func _test_ability_choice() -> void:
	_reset()
	var target := _unit("player", "spicy_hot_honey_bee", "prep", 0)
	var second := _unit("player", "spicy_jalapeno_panther", "prep", 2)
	var source := _unit("player", "spicy_funky_relishoon", "plated", 0)
	_unit("opponent", "sweet_jellyfish", "prep", 0)
	table.service.activate_ability(table.state, int(source.instance_id), "relishoon_sacrifice")
	table._render_match()
	_expect(not table.state.pending_ability.is_empty(), "Relishoon did not enter its real sacrifice choice.")
	_expect_exact_targets([int(target.instance_id), int(second.instance_id)])
	await _shot("02_ability_choice")
	var card: Node3D = table._card_node_for_instance(int(target.instance_id))
	var aura := card.get_node_or_null("CardChoiceAura") as MeshInstance3D
	if aura != null:
		table._animate_physical_cards(0.1, 0.0)
		var stable_scale := aura.scale
		table._animate_physical_cards(0.1, 1.0)
		_expect(aura.scale.is_equal_approx(stable_scale), "Reduced Motion changed the target aura's scale.")
		table.reduced_motion = false
		table._animate_physical_cards(0.1, 2.0)
		_expect((aura.material_override as StandardMaterial3D).albedo_color.a >= 0.95, "Normal-motion target emphasis fades below a clearly visible state.")
	table.reduced_motion = true
	table._cancel_bottom_choice()
	_expect(table.state.pending_ability.is_empty(), "Cancel did not clear ability target selection.")
	_expect_no_choice_markers("Cancelled activated ability")


func _test_meal_choice() -> void:
	_reset()
	var first := _unit("player", "spicy_hot_honey_bee", "prep", 0)
	var second := _unit("player", "spicy_jalapeno_panther", "prep", 2)
	var ineligible := _unit("opponent", "sweet_jellyfish", "prep", 0)
	table.service.play_card(table.state, 2, "plated")
	table._render_match()
	_expect(not table.state.pending_meal.is_empty(), "Meal did not enter ingredient selection.")
	for unit in [first, second]:
		_expect_choice(table._card_node_for_instance(int(unit.instance_id)), "MealIngredientCandidateAura", "MealCandidateBadge", "CHOOSE")
	_expect(table._card_node_for_instance(int(ineligible.instance_id)).get_node_or_null("MealIngredientCandidateAura") == null, "Opponent ingredient advertised as a legal recipe payment.")
	table.service.toggle_ingredient_selection(table.state, int(first.instance_id))
	table._render_match()
	_expect_choice(table._card_node_for_instance(int(first.instance_id)), "MealIngredientSelectedAura", "MealSelectionBadge", "SELECTED")
	await _shot("03_meal_selected")
	table.service.toggle_ingredient_selection(table.state, int(first.instance_id))
	table._render_match()
	_expect_choice(table._card_node_for_instance(int(first.instance_id)), "MealIngredientCandidateAura", "MealCandidateBadge", "CHOOSE")
	table._cancel_bottom_choice()
	_expect_no_choice_markers("Cancelled Meal")


func _test_hand_discard_choice() -> void:
	_reset()
	table.state.player.hand = ["item_spicy_shopping_list", "spicy_hot_honey_bee", "spicy_wasabi_wasp"]
	table.service.play_card(table.state, 0, "prep")
	table._render_match()
	_expect(not table.state.pending_discard.is_empty(), "Shopping List did not request its discard payment.")
	for index in [1, 2]:
		_expect_choice(table.find_child("PlayerHandCard_%d" % index, true, false), "CardChoiceAura", "ChoiceBadge", "CHOOSE")
	var paying: Node3D = table.find_child("PlayerHandCard_0", true, false)
	_expect(paying.get_node_or_null("CardChoiceAura") == null, "Card being paid for incorrectly advertised as discard payment.")
	table.service.toggle_discard_card(table.state, 1)
	table._render_match()
	_expect_choice(table.find_child("PlayerHandCard_1", true, false), "CardChoiceSelectedAura", "ChoiceBadge", "SELECTED")
	await _shot("04_hand_discard")
	table.service.cancel_discard_cost(table.state)
	table._render_match()
	_expect_no_choice_markers("Cancelled discard payment")


func _test_card_tray_choice() -> void:
	_reset()
	table.state.player.hand = ["item_tool_drawer"]
	table.state.player.deck = ["spicy_hot_honey_bee", "item_wooden_spoon", "spicy_sriracharrow", "item_tongs"]
	table.service.play_card(table.state, 0, "prep")
	table._render_match()
	_expect(not table.state.pending_search.is_empty() and table.card_tray_overlay.visible, "Tool Drawer did not open its revealed-card choice.")
	var eligible := 0
	var ineligible := 0
	for button in table.card_tray_cards.get_children():
		if not button is Button:
			continue
		if button.disabled:
			ineligible += 1
		else:
			eligible += 1
			var style := button.get_theme_stylebox("normal") as StyleBoxFlat
			_expect(style != null and style.border_width_left >= 5, "Eligible revealed card lacks a broad candidate frame.")
			_expect_tray_badge(button, "CHOOSE")
		if button.disabled:
			_expect(button.get_node_or_null("ChoiceBadge") == null, "Ineligible revealed card advertises CHOOSE.")
	_expect(eligible == 2 and ineligible == 2, "Search tray changed which revealed cards can be taken.")
	await _shot("05_search_choice")
	table.service.skip_search(table.state)
	table._render_match()
	_expect(not table.card_tray_overlay.visible, "Search tray remained after its prompt ended.")
	_reset()
	table.state.player.hand = ["chef_gusteau"]
	table.state.player.discard = ["spicy_hot_honey_bee", "spicy_sriracharrow", "item_wooden_spoon"]
	table.service.play_card(table.state, 0, "prep")
	table._render_match()
	_expect(String(table.state.pending_choice.get("choice_kind", "")) == "discard", "Chef Gusteau did not enter discard recovery.")
	_expect(table.card_tray_cards.get_child_count() == 2, "Discard recovery displayed an invalid Tool target.")
	for button in table.card_tray_cards.get_children():
		_expect_tray_badge(button, "CHOOSE")
	table.service.toggle_discard_choice(table.state, 0)
	table._render_match()
	_expect_tray_badge(table.card_tray_cards.get_child(0), "SELECTED")
	_expect_tray_badge(table.card_tray_cards.get_child(1), "CHOOSE")
	await _shot("06_discard_recovery")
	table.service.skip_effect_choice(table.state)
	table._render_match()
	table._open_discard_tray("player")
	for button in table.card_tray_cards.get_children():
		_expect(button.get_node_or_null("ChoiceBadge") == null, "Ordinary discard browsing acquired a CHOOSE/SELECTED label.")
	table._close_card_tray()


func _expect_tray_badge(button: Node, expected: String) -> void:
	var badge := button.get_node_or_null("ChoiceBadge") as Label
	_expect(badge != null and badge.text.contains(expected), "Tray card lacks an explicit %s label." % expected)


func _expect_exact_targets(ids: Array) -> void:
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated"]:
			for unit in table.state[side][zone]:
				var node: Node3D = table._card_node_for_instance(int(unit.instance_id))
				if ids.has(int(unit.instance_id)):
					_expect_choice(node, "CardChoiceAura", "ChoiceBadge", "CHOOSE")
				else:
					_expect(node.get_node_or_null("CardChoiceAura") == null, "Illegal target %s acquired a choose-card frame." % unit.name)


func _expect_choice(node: Node3D, aura_name: String, badge_name: String, text: String) -> void:
	_expect(node != null, "Choice card disappeared.")
	if node == null:
		return
	var aura := node.get_node_or_null(aura_name) as MeshInstance3D
	var badge := node.get_node_or_null(badge_name) as Label3D
	_expect(aura != null, "%s lacks its %s perimeter." % [node.name, aura_name])
	_expect(badge != null and badge.text.contains(text), "%s lacks its explicit %s label." % [node.name, text])
	if aura != null:
		var material := aura.material_override as StandardMaterial3D
		_expect(material != null and material.albedo_color.a >= 0.95 and not material.emission_enabled, "%s must have a fully visible matte target perimeter." % node.name)
		var mesh := aura.mesh as QuadMesh
		_expect(mesh != null and mesh.size.x >= 1.6 and mesh.size.y >= 2.15, "%s's target perimeter is too small to clear the card face." % node.name)


func _expect_no_choice_markers(context: String) -> void:
	# Retired render nodes remain hidden until their materials can be released
	# after a frame. Only the live card layer represents current choice state.
	for marker in ["CardChoiceAura", "CardChoiceSelectedAura", "MealIngredientCandidateAura", "MealIngredientSelectedAura"]:
		_expect(table.card_layer.find_children(marker, "MeshInstance3D", true, false).is_empty(), "%s left a stale %s." % [context, marker])


func _unit(side: String, card_id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	unit.recipe_ready_on_turn = 0
	table.state[side][zone].append(unit)
	return unit


func _settle(frames: int = 8) -> void:
	for frame in frames:
		await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)


func _shot(suffix: String) -> void:
	await _settle()
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()
	if not save_captures:
		return
	# Fixture states replace several faces at once. Refresh their one-shot
	# viewports after layout settles so capture does not retain a blank first draw.
	for viewport in table.texture_viewports.get_children():
		if viewport is SubViewport:
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await _settle(4)
	RenderingServer.force_draw(false)
	var file_path := OUTPUT_DIR.path_join("%dx%d_%s.png" % [capture_size.x, capture_size.y, suffix])
	_expect(capture_viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(file_path)) == OK, "Could not save " + file_path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
