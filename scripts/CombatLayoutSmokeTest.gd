extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PREVIEW_PATH := "res://outputs/sketch_campaign/10_battle_ui.png"
const RULE_ERROR_PREVIEW_PATH := "res://outputs/sketch_campaign/10b_battle_rule_error.png"
const MEAL_AURA_PREVIEW_PATH := "res://outputs/sketch_campaign/10c_meal_selection_aura.png"
const TURN_BANNER_PREVIEW_PATH := "/tmp/topdeck_to_worlds_turn_banner.png"

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
		"player_starter": "spicy",
		"opponent_affinity": "hearty",
	}
	table.reset_button.visible = false

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
	_expect(table.find_child("MatchOptionsButton", true, false) == null, "The obsolete match-options control is still present.")
	_expect(not table.exit_button.visible, "The redundant top-level exit control is still visible.")
	_expect(
		table.settings_button.text.is_empty()
		and String(table.settings_button.get_meta("material_symbol", "")) == "settings"
		and table.settings_button.get_theme_color("icon_normal_color").is_equal_approx(PALETTE.COOL_WHITE)
		and table.settings_button.custom_minimum_size.x <= 56.0,
		"The consolidated match settings control is not represented by a compact cog."
	)
	_expect(table.find_child("BoardInfoButton", true, false) == null, "Board information still has a separate in-battle control.")
	_expect(not table.player_life.visible and not table.opponent_life.visible, "Duplicate life totals still occupy the top HUD.")
	_expect((table.player_chef.get_node("Label") as Label3D).text == str(int(table.state.player.life)), "The player Chef puck still shows a name instead of only its life total.")
	_expect((table.opponent_chef.get_node("Label") as Label3D).text == str(int(table.state.opponent.life)), "The rival Chef puck still shows a name instead of only its life total.")
	var board_info_labels: Array[Label3D] = []
	for label_node in table.card_layer.find_children("*", "Label3D", true, false):
		if bool(label_node.get_meta("board_info_label", false)):
			board_info_labels.append(label_node as Label3D)
	_expect(not board_info_labels.is_empty(), "The table information labels were not tagged for the HUD toggle.")
	for board_label in board_info_labels:
		_expect(not board_label.visible, "A table label or pile count is visible before opening table information.")
	table.configure_battle_preferences("normal", 1.0, false, true)
	for board_label in board_info_labels:
		_expect(board_label.visible, "The Options board-information preference did not reveal a table label or pile count.")
	table.configure_battle_preferences("normal", 1.0, false, false)
	for board_label in board_info_labels:
		_expect(not board_label.visible, "The Options board-information preference did not hide a table label or pile count.")
	var first_draw_event: Array[Dictionary] = [{"type": "draw", "side": "player", "from": "deck", "to": "hand"}]
	table._register_deck_draw_events(first_draw_event)
	table._render_match()
	var lightly_messy_deck_card := table.find_child("PlayerDeckCard_3", true, false) as Node3D
	var deck_center: Vector3 = table.AUX_ZONE_POSITIONS.player_deck
	var light_offset := Vector2(
		lightly_messy_deck_card.position.x - deck_center.x,
		lightly_messy_deck_card.position.z - deck_center.z
	).length() if lightly_messy_deck_card != null else 0.0
	var more_draw_events: Array[Dictionary] = [
		{"type": "draw", "side": "player", "from": "deck", "to": "hand"},
		{"type": "draw", "side": "player", "from": "deck", "to": "hand"},
		{"type": "draw", "side": "player", "from": "deck", "to": "hand"},
	]
	table._register_deck_draw_events(more_draw_events)
	table._render_match()
	var messy_deck_card := table.find_child("PlayerDeckCard_3", true, false) as Node3D
	var messy_offset := Vector2(
		messy_deck_card.position.x - deck_center.x,
		messy_deck_card.position.z - deck_center.z
	).length() if messy_deck_card != null else 0.0
	_expect(
		messy_deck_card != null
		and messy_offset > light_offset
		and absf(messy_deck_card.rotation_degrees.y) > 1.0,
		"Successive draws did not progressively loosen the deck stack."
	)
	var opponent_draw_events: Array[Dictionary] = [
		{"type": "draw", "side": "opponent", "from": "deck", "to": "hand"},
		{"type": "draw", "side": "opponent", "from": "deck", "to": "hand"},
	]
	table._register_deck_draw_events(opponent_draw_events)
	table._render_match()
	var hearty_deck_card := table.find_child("OpponentDeckCard_3", true, false) as Node3D
	var hearty_deck_center: Vector3 = table.AUX_ZONE_POSITIONS.opponent_deck
	_expect(
		int(table.deck_visual_messiness.opponent) == 0
		and hearty_deck_card != null
		and String(hearty_deck_card.get_meta("deck_stack_style", "")) == "neat"
		and absf(hearty_deck_card.position.x - hearty_deck_center.x) <= 0.01
		and absf(hearty_deck_card.position.z - hearty_deck_center.z) <= 0.01
		and absf(hearty_deck_card.rotation_degrees.y) <= 0.1,
		"A Hearty rival allowed repeated draws to loosen their neat deck stack."
	)
	for neat_affinity in ["sweet", "hearty"]:
		table.configured_match_context.player_starter = neat_affinity
		table.deck_visual_messiness.player = 0
		table._register_deck_draw_events(first_draw_event)
		_expect(
			int(table.deck_visual_messiness.player) == 0,
			"%s players did not keep their deck neatly stacked." % neat_affinity.capitalize()
		)
	for loose_affinity in ["spicy", "fresh", "funky"]:
		table.configured_match_context.player_starter = loose_affinity
		table.deck_visual_messiness.player = 0
		table._register_deck_draw_events(first_draw_event)
		_expect(
			int(table.deck_visual_messiness.player) == 1,
			"%s players did not allow their deck to loosen after a draw." % loose_affinity.capitalize()
		)
	table.configured_match_context.player_starter = "spicy"
	var deck_click := InputEventMouseButton.new()
	deck_click.button_index = MOUSE_BUTTON_LEFT
	deck_click.pressed = true
	deck_click.position = table._world_to_container(deck_center + Vector3(0.0, 0.12, 0.0))
	table._on_table_gui_input(deck_click)
	await create_timer(0.3).timeout
	var straightened_deck_card := table.find_child("PlayerDeckCard_3", true, false) as Node3D
	var revealed_deck_count := table.find_child("PlayerDeckCount", true, false) as Label3D
	_expect(
		int(table.deck_visual_messiness.player) == 0
		and bool(table.deck_count_revealed.player)
		and straightened_deck_card != null
		and absf(straightened_deck_card.position.x - deck_center.x) <= 0.01
		and absf(straightened_deck_card.position.z - deck_center.z) <= 0.01
		and absf(straightened_deck_card.rotation_degrees.y) <= 0.1
		and revealed_deck_count != null
		and revealed_deck_count.visible
		and revealed_deck_count.text == str(table.state.player.deck.size()),
		"Clicking the player deck did not reveal its count and straighten the pile."
	)
	_expect(table.find_child("MatchSettingsMenu", true, false) == null, "The obsolete in-battle settings dropdown still exists.")
	_expect(
		table.battle_log_button.get_parent().name == "TopRow"
		and table.battle_log_button.icon != null
		and not table.battle_log_button.text.contains("LOG")
		and table.battle_log_button.text.is_valid_int()
		and table.battle_log_button.custom_minimum_size.x <= 72.0,
		"The match log is not represented by its compact history symbol and count."
	)
	_expect(not table.turn_label.visible, "The persistent turn counter is still visible in the top HUD.")
	_expect(not table.title_label.visible, "The redundant matchup title is still visible in the top HUD.")
	_expect(table.find_child("MatchHeader", true, false) == null, "The persistent top-center match panel still exists.")
	_expect(
		table.battle_log_button.global_position.x > table.get_viewport_rect().size.x * 0.5,
		"The utility controls are not grouped on the right side of the top HUD."
	)
	_expect(
		table.player_profile_life_bar != null
		and table.opponent_profile_life_bar != null
		and table.player_profile_badge.size.x <= 110.0
		and table.opponent_profile_badge.size.x <= 110.0
		and not table.player_profile_details.visible
		and not table.opponent_profile_details.visible
		and table.player_profile_life_bar.position.y >= table.player_profile_badge.position.y + table.player_profile_badge.size.y - 1.0
		and table.opponent_profile_life_bar.position.y >= table.opponent_profile_badge.position.y + table.opponent_profile_badge.size.y - 1.0,
		"The numeric life bars are not positioned beneath both profile boxes."
	)
	var player_life_fill := table.player_profile_life_bar.get_theme_stylebox("fill") as StyleBoxFlat
	var player_life_track := table.player_profile_life_trail_bar.get_theme_stylebox("background") as StyleBoxFlat
	var player_hp_marker := table.player_profile_life_bar.find_child("PlayerLifeBarMarker", true, false) as Label
	_expect(
		table.player_profile_life_bar.size.y >= 36.0
		and table.opponent_profile_life_bar.size.y >= 36.0
		and table.player_profile_life_label.get_theme_font_size("font_size") >= 17
		and table.opponent_profile_life_label.get_theme_font_size("font_size") >= 17
		and table.player_profile_life_label.get_theme_font("font").resource_path == "res://assets/fonts/Oxanium-SemiBold.ttf"
		and table.player_profile_life_label.get_theme_constant("outline_size") >= 3
		and table.player_profile_life_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END
		and table.player_profile_life_trail_bar.fill_mode == ProgressBar.FILL_BEGIN_TO_END
		and table.opponent_profile_life_bar.fill_mode == ProgressBar.FILL_END_TO_BEGIN
		and table.opponent_profile_life_trail_bar.fill_mode == ProgressBar.FILL_END_TO_BEGIN
		and player_life_fill != null
		and player_life_fill.bg_color.is_equal_approx(PALETTE.HEALTH_FILL)
		and player_life_track != null
		and player_life_track.bg_color.is_equal_approx(Color(PALETTE.GRAPHITE, 0.99))
		and player_life_track.border_width_left >= 3
		and player_hp_marker != null
		and player_hp_marker.text == "HP"
		and player_hp_marker.get_theme_color("font_color").is_equal_approx(PALETTE.SIGNAL_YELLOW)
		and _contrast_ratio(PALETTE.COOL_WHITE, PALETTE.HEALTH_FILL) >= 4.5,
		"The profile HP readout is not large or high-contrast enough for gameplay."
	)
	_expect(table.player_profile_badge.position.x <= 24.0, "The player profile is not aligned to the lower-left edge.")
	_expect(
		table.opponent_profile_badge.position.x >= table.get_viewport_rect().size.x * 0.65
		and table.opponent_profile_badge.position.y <= table.get_viewport_rect().size.y * 0.22,
		"The opponent profile is not positioned in the open upper-right area."
	)
	_expect(
		table.player_profile_badge.find_child("PlayerProfileBadgeAngularSurface", true, false) != null
		and table.opponent_profile_badge.find_child("OpponentProfileBadgeAngularSurface", true, false) != null
		and table.player_profile_badge.find_child("PlayerProfileBadgeTechPattern", true, false) == null,
		"The player and rival profiles do not use the clean angular status treatment."
	)
	_expect(
		table.turn_banner_panel.get_theme_stylebox("panel") is StyleBoxEmpty
		and table.turn_banner_surface.fill_color.is_equal_approx(PALETTE.SURFACE_PAPER)
		and table.turn_banner_accent_rule.color.is_equal_approx(PALETTE.SELECTION_BLUE),
		"The turn-change banner still uses the legacy rounded paper treatment."
	)
	table._show_turn_banner("opponent_turn")
	await create_timer(0.32).timeout
	_expect(
		table.turn_banner_title.text == "OPPONENT TURN"
		and table.turn_banner_title.get_theme_color("font_color").is_equal_approx(PALETTE.SIGNAL_RED)
		and table.turn_banner_title.get_theme_color("font_outline_color").is_equal_approx(PALETTE.CARBON)
		and table.turn_banner_title.get_theme_constant("outline_size") >= 6
		and table.turn_banner_title.get_theme_constant("shadow_offset_x") == 0
		and table.turn_banner_title.get_theme_constant("shadow_offset_y") == 0
		and table.turn_banner_subtitle.text == "TURN 1"
		and table.turn_banner_subtitle.name == "TurnBannerNumber"
		and table.turn_banner_subtitle.get_parent().name == "TurnBannerNumberOffset"
		and (table.turn_banner_subtitle.get_parent() as MarginContainer).get_theme_constant("margin_top") == 20,
		"The opponent turn-change box does not show its ownership and turn number."
	)
	if DisplayServer.get_name() != "headless":
		var turn_banner_preview := root.get_texture().get_image()
		_expect(turn_banner_preview.save_png(TURN_BANNER_PREVIEW_PATH) == OK, "Turn banner preview could not be saved.")
	await create_timer(0.72).timeout
	_expect(
		table._card_viewer_action_icon("Play Card").resource_path == "res://assets/ui/battle_actions/play_card.png"
		and table._card_viewer_action_icon("Activate Ability").resource_path == "res://assets/ui/battle_actions/activate_ability.png"
		and table.ACTION_ICON_SPECIAL_SERVE.resource_path == "res://assets/ui/battle_actions/special_serve.png"
		and table._card_viewer_action_icon("Attack").resource_path == "res://assets/ui/battle_actions/attack.png"
		and table._card_viewer_action_icon("Move").resource_path == "res://assets/ui/battle_actions/move.png"
		and table._card_viewer_action_icon("Begin Recipe").resource_path == "res://assets/ui/battle_actions/spice.png",
		"The card inspector is not using the supplied authored action symbols."
	)
	_expect(
		table.settings_button.get_node_or_null("BattleAngularButtonFace") != null
		and table.end_turn_button.get_node_or_null("BattleAngularButtonFace") != null,
		"The battle controls do not use the smooth chamfered treatment."
	)
	var opponent_life_before := float(table.opponent_profile_life_bar.value)
	table._animate_profile_life_change("opponent", 3)
	await create_timer(0.5).timeout
	_expect(
		is_equal_approx(table.opponent_profile_life_bar.value, opponent_life_before - 3.0)
		and table.opponent_profile_life_trail_bar.value >= table.opponent_profile_life_bar.value
		and table.opponent_profile_life_label.text == "%d/%d" % [int(opponent_life_before) - 3, int(table.opponent_profile_life_bar.max_value)],
		"The opponent life bar did not animate down with a readable trailing damage drain."
	)
	table._sync_profile_life_bar("opponent")
	table._spawn_movement_trail_screen(Vector2(180, 520), Vector2(420, 360), PALETTE.ELECTRIC_CYAN)
	table._spawn_damage_burst_screen(Vector2(720, 430), PALETTE.SIGNAL_RED)
	_expect(
		table.effect_layer.find_child("MovementGraphicVfx", true, false) != null
		and table.effect_layer.find_child("DamageGraphicVfx", true, false) != null,
		"The engine-drawn movement trail or damage impact burst did not spawn."
	)
	var stable_camera_transform: Transform3D = table.camera.global_transform
	var stable_camera_fov: float = table.camera.fov
	table.reduced_motion = true
	table._start_camera_pulse("player", 2.2)
	table._start_camera_impact("player", 0.18)
	_expect(
		table.camera.global_transform.is_equal_approx(stable_camera_transform)
		and is_equal_approx(table.camera.fov, stable_camera_fov),
		"Reduced motion did not suppress battle-camera movement."
	)
	table.reduced_motion = false
	var original_match_context: Dictionary = table.configured_match_context.duplicate(true)
	table.configured_match_context = {"route_encounter": true, "location": "Sidewalk Market"}
	table._apply_route_location_theme()
	var tabletop_mesh := table.get_node("ViewportContainer/WorldViewport/World/Table") as MeshInstance3D
	var table_material := tabletop_mesh.material_override as StandardMaterial3D
	var tabletop_box := tabletop_mesh.mesh as BoxMesh
	var battle_backdrop := table.get_node("BattleBackdrop") as TextureRect
	var production_arena := table.get_node("ViewportContainer/WorldViewport/World/ProductionArena") as Node3D
	var inset_playmat := production_arena.get_node("InsetPlaymat") as MeshInstance3D
	var inset_material := inset_playmat.get_active_material(0) as ShaderMaterial
	var center_line := production_arena.get_node("CenterLine") as MeshInstance3D
	var center_line_material := center_line.get_active_material(0) as StandardMaterial3D
	_expect(
		table_material != null and table_material.albedo_color.is_equal_approx(PALETTE.GRAPHITE),
		"A route-location override changed the tournament table away from graphite."
	)
	_expect(
		tabletop_box != null
		and tabletop_box.size.x >= table.PRODUCTION_TABLE_WIDTH
		and tabletop_box.size.z >= 13.0
		and tabletop_mesh.position.z < 0.0
		and tabletop_mesh.position.z - tabletop_box.size.z * 0.5 <= table.ZONE_CENTERS.opponent_prep.z - 1.7,
		"The table was not extended far enough behind the opponent Prep zone."
	)
	var first_player_prep_slot := production_arena.get_node("PrintedCardSlots/PlayerPrepSlot1") as Node3D
	var last_player_prep_slot := production_arena.get_node("PrintedCardSlots/PlayerPrepSlot3") as Node3D
	var first_player_prep_mark := first_player_prep_slot.get_node("Near") as Node3D if first_player_prep_slot != null else null
	var last_player_prep_mark := last_player_prep_slot.get_node("Near") as Node3D if last_player_prep_slot != null else null
	_expect(
		first_player_prep_mark != null
		and last_player_prep_mark != null
		and absf(last_player_prep_mark.position.x - first_player_prep_mark.position.x) >= table.PREP_SLOT_SPACING * 2.0 - 0.01,
		"The battle slots were not expanded horizontally with the wider tabletop."
	)
	_expect(
		production_arena != null
		and String(production_arena.get_meta("asset_origin", "")) == "engine_geometry"
		and not bool(production_arena.get_meta("ships_external_art", true))
		and production_arena.get_node_or_null("InsetPlaymat") != null
		and production_arena.get_node_or_null("InsetRim") != null
		and production_arena.get_node_or_null("PrintedCardSlots/PlayerPrepSlot1") != null
		and production_arena.get_node_or_null("PlayerDeckTray") != null
		and production_arena.get_node_or_null("PlayerEnvironmentTray") != null
		and production_arena.get_node_or_null("OpponentDiscardTray") != null,
		"The inset tournament mat or its marked deck/discard trays are missing."
	)
	_expect(
		inset_material != null
		and inset_material.shader.resource_path == "res://assets/shaders/tournament_wood.gdshader"
		and is_equal_approx(center_line.position.z, table.PRODUCTION_BOARD_DIVIDER_Z)
		and center_line_material != null
		and center_line_material.albedo_color.is_equal_approx(Color(PALETTE.COOL_WHITE, 0.88))
		and production_arena.get_node_or_null("CenterCirclePrint") == null
		and production_arena.get_node_or_null("PlayerDiscardTray/SideMark") == null
		and production_arena.get_node_or_null("PlayerEnvironmentTray/SideMark") == null
		and production_arena.get_node_or_null("OpponentDiscardTray/SideMark") == null
		and production_arena.get_node_or_null("OpponentEnvironmentTray/SideMark") == null
		and production_arena.get_node_or_null("TournamentDressing") == null,
		"The battle board did not use the procedural wood treatment or still contains decorative table clutter."
	)
	_expect(
		table._zone_color("player_plated").is_equal_approx(PALETTE.ZONE_PLAYER_PLATED)
		and table._zone_color("player_prep").is_equal_approx(PALETTE.ZONE_PLAYER_PREP)
		and table._zone_color("opponent_plated").is_equal_approx(PALETTE.ZONE_OPPONENT_PLATED)
		and table._zone_color("opponent_prep").is_equal_approx(PALETTE.ZONE_OPPONENT_PREP),
		"The table zones do not use the two-color player-blue and rival-red ownership system."
	)
	_expect(
		battle_backdrop.texture.resource_path == "res://assets/battle/field-battle-background.png",
		"The supplied field battle backdrop was not loaded."
	)
	table.configured_match_context = {"route_encounter": true, "location": "Waterfront Table"}
	table._apply_route_location_theme()
	_expect(battle_backdrop.texture.resource_path == "res://assets/battle/field-battle-background.png", "Route metadata replaced the supplied field backdrop.")
	table.configured_match_context = original_match_context
	table._apply_route_location_theme()
	_expect(
		table.end_turn_button.text == "END TURN"
		and table.end_turn_button.icon != null
		and table.end_turn_button.get_theme_font("font").resource_path == "res://assets/fonts/Oxanium-SemiBold.ttf"
		and table.end_turn_button.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT,
		"The primary turn action is not clearly labeled with its caret icon."
	)
	for choice_button in [table.confirm_choice_button, table.cancel_choice_button, table.battle_log_close_button, table.card_tray_confirm_button, table.card_tray_skip_button]:
		var angular_face = choice_button.get_node_or_null("BattleAngularButtonFace")
		for state_name in ["normal", "hover", "pressed", "disabled"]:
			_expect(
				angular_face != null
				and _contrast_ratio(
					angular_face.text_color_for_state(state_name),
					angular_face.fill_color_for_state(state_name)
				) >= 4.5,
				"A battle-menu button has low-contrast text in its %s state." % state_name
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
	_expect(meal_candidate_card.find_child("MealCandidateBadge", true, false) != null, "A recipe-ready Meal ingredient is missing its CHOOSE badge.")
	table.state.selected_ingredients = [meal_test_ingredient_id]
	table._render_match()
	var selected_meal_card := table.find_child("PlayerPrepCard_%d" % meal_test_ingredient_id, true, false) as Node3D
	var selected_meal_aura := selected_meal_card.find_child("MealIngredientSelectedAura", true, false) as MeshInstance3D if selected_meal_card != null else null
	_expect(selected_meal_aura != null, "A selected Meal ingredient did not receive the stronger ability-style aura.")
	if selected_meal_aura != null:
		var selected_aura_material := selected_meal_aura.material_override as StandardMaterial3D
		_expect(selected_aura_material != null and selected_aura_material.albedo_texture.resource_path.ends_with("meal_selected_aura.svg"), "The selected Meal ingredient does not use its clear selected-state frame.")
		_expect(table.pulsing_field_auras.has(selected_meal_aura), "The selected Meal ingredient aura is not registered for pulsing animation.")
		_expect(selected_meal_card.find_child("MealSelectionBadge", true, false) != null, "A selected Meal ingredient is missing its SELECTED badge.")
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
	_expect(table.battle_log_text.get_theme_color("default_color") == Color("#29365F"), "Match log copy did not use the readable navy ink color.")
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
	_expect(
		table.camera.position.y >= 10.0
		and table.camera.position.y <= 11.0
		and table.camera.position.z >= 10.0,
		"Combat camera is not using the park promenade perspective."
	)
	_expect(table.camera.fov >= 42.5 and table.camera.fov <= 44.0, "Combat camera is outside the trailer-readable framing range.")
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
		_expect(hand_card.scale.x >= 1.25, "The player's hand cards did not retain their larger readable scale.")
		_expect(visible_hand_rect.size.y >= hand_rect.size.y * 0.72, "Too much of the player's hand is clipped below the screen.")
		_expect(
			visible_hand_rect.end.y >= table.viewport_container.size.y - 40.0,
			"The downward camera framing left too much dead space below the player's hand."
		)
		var visible_click_point := Vector2(visible_hand_rect.get_center().x, visible_hand_rect.position.y + 12.0)
		_expect(table._pick_card(visible_click_point) == hand_card, "The visible portion of a hand card is not clickable.")
		_expect(table._can_drag_card(hand_card), "A player hand card cannot begin a drag during the player's main phase.")
		_expect(table._mouse_to_table(visible_click_point) != null, "A visible hand-card click cannot be projected onto the table for dragging.")

	var opponent_hand_card := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_expect(opponent_hand_card != null, "Camera preview did not render the opponent's hand.")
	if opponent_hand_card != null:
		var far_table_edge := tabletop_mesh.position.z - tabletop_box.size.z * 0.5
		_expect(
			opponent_hand_card.position.z <= far_table_edge - 0.25,
			"The opponent hand was not moved clear of the far table edge."
		)
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


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var foreground_luminance := _relative_luminance(foreground)
	var background_luminance := _relative_luminance(background)
	var lighter := maxf(foreground_luminance, background_luminance)
	var darker := minf(foreground_luminance, background_luminance)
	return (lighter + 0.05) / (darker + 0.05)


func _relative_luminance(color: Color) -> float:
	var red := color.r / 12.92 if color.r <= 0.04045 else pow((color.r + 0.055) / 1.055, 2.4)
	var green := color.g / 12.92 if color.g <= 0.04045 else pow((color.g + 0.055) / 1.055, 2.4)
	var blue := color.b / 12.92 if color.b <= 0.04045 else pow((color.b + 0.055) / 1.055, 2.4)
	return red * 0.2126 + green * 0.7152 + blue * 0.0722
