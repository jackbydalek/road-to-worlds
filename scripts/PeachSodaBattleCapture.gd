extends SceneTree

## Real battle renderer at the game's supported screen sizes. Deterministic
## fixture states exercise a sparse opening, a populated board, legal placement,
## and inspection. Run normally to save PNGs, or --headless for layout checks.
## Godot --path . --script res://scripts/PeachSodaBattleCapture.gd

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_DIR := "res://outputs/peach_soda_battle"
const CAPTURE_SIZES := [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(1920, 1080)]

var table
var capture_viewport: SubViewport
var errors: Array[String] = []
var records: Array[Dictionary] = []
var capture_size := Vector2i.ZERO


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for output_size in CAPTURE_SIZES:
		capture_size = output_size
		await _create_match()
		_stage_board(false)
		await _settle()
		_check_board_and_hud("sparse")
		await _save_shot("01_sparse")
		_stage_board(true)
		await _settle()
		_check_board_and_hud("populated")
		await _save_shot("02_populated")
		await _capture_legal_destination()
		await _capture_inspector()
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	if DisplayServer.get_name() != "headless":
		var report := FileAccess.open(OUTPUT_DIR.path_join("layout_report.json"), FileAccess.WRITE)
		if report != null:
			report.store_string(JSON.stringify({"shots": records, "failures": errors}, "\t"))
	for error in errors:
		push_error(error)
	print("Peach Soda battle: %d resolutions, 12 states, %d failures" % [CAPTURE_SIZES.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)


func _create_match() -> void:
	capture_viewport = SubViewport.new()
	capture_viewport.size = capture_size
	# Match project.godot's 1440x900 canvas_items/expand behavior without the
	# desktop window manager constraining a 1080p screenshot on smaller screens.
	var canvas_scale := minf(float(capture_size.x) / 1440.0, float(capture_size.y) / 900.0)
	capture_viewport.size_2d_override = Vector2i(Vector2(capture_size) / canvas_scale)
	capture_viewport.size_2d_override_stretch = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	table = TABLE_SCENE.instantiate()
	table.configure_match(
		{"chef_bill": 3, "spicy_hot_honey_bee": 3, "spicy_wasabi_wasp": 3, "spicy_jalapeno_panther": 3, "spicy_sriracharrow": 3, "spicy_firecracker_shrimp": 3, "item_wooden_spoon": 2},
		{"chef_mary": 3, "sweet_sugar_glider": 3, "sweet_caramel_camel": 3, "sweet_soft_serve_crab": 3, "sweet_strawberry_sharkcake": 3, "sweet_jellyfish": 3, "item_wooden_spoon": 2},
		"You", "Pip", 20260907, "player", "Return", "easy", "white",
		{"event_name": "Weekly Locals", "round": 1, "rounds": 3, "player_starter": "spicy", "opponent_affinity": "sweet", "rival_cast_id": "pip", "rival_display_name": "Pip"},
		{"player_life": 32, "player_max_life": 40, "opponent_life": 18, "opponent_max_life": 25}
	)
	table.configure_battle_preferences("fast", 1.0, true, false)
	capture_viewport.add_child(table)
	await _settle(14)
	await create_timer(1.3).timeout
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()


func _stage_board(populated: bool) -> void:
	var state: Dictionary = table.state
	state.turn = 4 if populated else 2
	state.phase = "player_main"
	state.first_player = "opponent"
	state.selected_attacker = -1
	state.selected_ingredients = []
	state.animation_events = []
	state.message = "Choose a card to play or attack with."
	for key in ["pending_meal", "pending_discard", "pending_ability", "pending_search", "pending_choice", "pending_resume", "pending_reaction"]:
		state[key] = {}
	for side in ["player", "opponent"]:
		state[side].turns_started = 2
		state[side].prep = []
		state[side].plated = []
		state[side].discard = []
		state[side].environment = ""
		state[side].meal_served = false
		state[side].zone_move_used = false
		state[side].chef_used = false
	state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon", "spicy_sriracharrow"]
	state.opponent.hand = ["sweet_sugar_glider", "sweet_jellyfish", "item_wooden_spoon"]
	table.selected_ref = {}
	_add_unit("player", "spicy_hot_honey_bee", "prep", 0)
	_add_unit("opponent", "sweet_sugar_glider", "prep", 0)
	if populated:
		_add_unit("player", "spicy_jalapeno_panther", "prep", 2)
		_add_unit("player", "spicy_firecracker_shrimp", "plated", 0)
		_add_unit("player", "spicy_sriracharrow", "plated", 1)
		_add_unit("opponent", "sweet_caramel_camel", "prep", 2)
		_add_unit("opponent", "sweet_strawberry_sharkcake", "plated", 0)
		_add_unit("opponent", "sweet_soft_serve_crab", "plated", 1)
	table._render_match()
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()


func _add_unit(side: String, card_id: String, zone: String, slot: int) -> void:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(card_id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	unit.recipe_ready_on_turn = 0
	table.state[side][zone].append(unit)


func _capture_legal_destination() -> void:
	# Follow the real inspect → Play flow so its Cancel action and Escape route
	# remain available while the board is choosing a destination.
	var hand_card := table.find_child("PlayerHandCard_0", true, false) as Node3D
	_expect(is_instance_valid(hand_card), "legal: hand card did not render")
	table._inspect_card(hand_card)
	table._begin_hand_play_selection(0)
	_expect(not table.action_highlight_slots.is_empty(), "legal: Ingredient offered no destination")
	for choice in table.action_highlight_slots:
		var zone := String(choice.zone).trim_prefix("player_")
		_expect(table._slot_can_receive_hand_card(table.service.card("spicy_wasabi_wasp"), "player", zone, int(choice.slot)), "legal: highlight advertised an invalid slot")
	if not table.action_highlight_slots.is_empty():
		var choice: Dictionary = table.action_highlight_slots[0]
		var target_point: Vector2 = table._world_to_container(table._slot_world_position(String(choice.zone), int(choice.slot)))
		table._update_action_destination_hover(target_point)
		table._update_zone_flair(0.0)
		_expect(table.get_viewport_rect().has_point(target_point), "legal: destination is outside the viewport")
		_expect(table.hovered_action_zone == String(choice.zone) and table.hovered_action_slot == int(choice.slot), "legal: screen projection does not select the highlighted slot")
	await _settle()
	await _save_shot("03_legal_destination")
	var cancel_event := InputEventKey.new()
	cancel_event.pressed = true
	cancel_event.keycode = KEY_ESCAPE
	table._input(cancel_event)
	_expect(table.pending_hand_play_index == -1 and table.action_highlight_slots.is_empty() and not table.action_panel.visible, "legal: Escape did not cancel placement and clear destination highlights")


func _capture_inspector() -> void:
	var inspected_unit: Dictionary = table.state.player.plated[0]
	var card_node: Node3D = table._card_node_for_instance(int(inspected_unit.instance_id))
	table._inspect_card(card_node)
	await _settle()
	_expect(table.action_panel.is_visible_in_tree(), "inspector: selecting a field card did not open inspection")
	_expect(is_instance_valid(table.inspector_card_face), "inspector: card artwork/rules are missing")
	if is_instance_valid(table.inspector_card_face):
		_expect(table.get_viewport_rect().encloses(table.inspector_card_face.get_global_rect()), "inspector: card is clipped")
	_expect(not table.inspector_action_buttons.is_empty(), "inspector: field card has no actions")
	for button in table.inspector_action_buttons:
		_expect(button.is_visible_in_tree() and table.get_viewport_rect().encloses(button.get_global_rect()), "inspector: an action is clipped or hidden")
		_expect(not button.get_global_rect().intersects(table.player_profile_badge.get_global_rect()), "inspector: player profile covers a card action")
	await _save_shot("04_inspector")


func _check_board_and_hud(state_name: String) -> void:
	var bounds: Rect2 = table.get_viewport_rect()
	var hud: Array[Control] = [table.player_profile_badge, table.opponent_profile_badge, table.end_turn_button, table.settings_button, table.battle_log_button]
	for control in hud:
		_expect(control.is_visible_in_tree() and bounds.encloses(control.get_global_rect()), "%s: %s is clipped or hidden" % [state_name, control.name])
	for first in range(hud.size()):
		for second in range(first + 1, hud.size()):
			_expect(not hud[first].get_global_rect().intersects(hud[second].get_global_rect()), "%s: %s overlaps %s" % [state_name, hud[first].name, hud[second].name])
	for label in [table.player_profile_name, table.opponent_profile_name, table.player_profile_life_label, table.opponent_profile_life_label]:
		_expect(label.is_visible_in_tree() and not label.text.is_empty(), "%s: competitor name or life total is missing" % state_name)
	for card in table.interactive_cards:
		if String(card.get_meta("kind", "")) == "hand":
			var hand_rect: Rect2 = table._card_screen_rect(card)
			_expect(bounds.encloses(hand_rect), "%s: player hand card is clipped" % state_name)
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated"]:
			for unit in table.state[side][zone]:
				var card_node: Node3D = table._card_node_for_instance(int(unit.instance_id))
				_expect(is_instance_valid(card_node), "%s: field card did not render" % state_name)
				if not is_instance_valid(card_node):
					continue
				var rect: Rect2 = table._card_screen_rect(card_node)
				rect.position += table.viewport_container.global_position
				_expect(bounds.encloses(rect), "%s: %s %s card is clipped" % [state_name, side, zone])
				for control in hud:
					_expect(not rect.intersects(control.get_global_rect()), "%s: %s covers a %s %s card" % [state_name, control.name, side, zone])


func _save_shot(state_name: String) -> void:
	var shot_name := "%dx%d_%s" % [capture_size.x, capture_size.y, state_name]
	var record := {"shot": shot_name, "output_size": str(capture_size), "logical_size": str(table.size)}
	for control in [table.player_profile_badge, table.opponent_profile_badge, table.end_turn_button]:
		record[String(control.name)] = str(control.get_global_rect())
	records.append(record)
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var capture := capture_viewport.get_texture().get_image()
	_expect(capture != null and capture.get_size() == capture_size, "%s: screenshot has incorrect dimensions" % state_name)
	if capture != null:
		_expect(capture.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(shot_name + ".png"))) == OK, "%s: screenshot could not be saved" % state_name)
	print("BATTLE_BOARD_CAPTURE ", shot_name)


func _settle(frames: int = 16) -> void:
	for unused in range(frames):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append("%dx%d %s" % [capture_size.x, capture_size.y, message])
