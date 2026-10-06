extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const BACKDROP_SCRIPT := preload("res://scripts/ui/PeachSodaBattleBackdrop.gd")
const TURN_GRAPHIC_SCRIPT := preload("res://scripts/ui/TurnChangeGraphic.gd")
const HEALTH_BAR_SCRIPT := preload("res://scripts/ui/CozyHealthBar.gd")
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
		and _contrast_ratio(table.settings_button.get_theme_color("icon_normal_color"), PALETTE.PEACH_PAPER) >= 4.5
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
	_expect(not table.tournament_slip.is_visible_in_tree() and not table.locals_venue_label.is_visible_in_tree() and not table.rival_hand_label.is_visible_in_tree(), "Optional match information is visible before enabling Board Info.")
	table.configure_battle_preferences("normal", 1.0, false, true)
	for board_label in board_info_labels:
		_expect(board_label.visible, "The Options board-information preference did not reveal a table label or pile count.")
	_expect(table.tournament_slip.is_visible_in_tree(), "Board Info did not reveal the live tournament context.")
	table.configure_battle_preferences("normal", 1.0, false, false)
	for board_label in board_info_labels:
		_expect(not board_label.visible, "The Options board-information preference did not hide a table label or pile count.")
	_expect(not table.tournament_slip.is_visible_in_tree() and not table.locals_venue_label.is_visible_in_tree() and not table.rival_hand_label.is_visible_in_tree(), "Disabling Board Info left a match-information plaque visible.")
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
	for loose_affinity in ["spicy", "hearty", "sweet", "fresh", "funky"]:
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
	_expect(
		not table.turn_label.is_visible_in_tree()
		and not table.normal_meal_status.is_visible_in_tree()
		and not table.end_turn_dock.is_visible_in_tree()
		and table.end_turn_button.is_visible_in_tree()
		and table.end_turn_button.tooltip_text.to_upper().contains("TURN")
		and table.end_turn_button.tooltip_text.contains("Meal"),
		"The solo End Turn control lost its contextual tooltip or retained permanent status plaques."
	)
	var end_turn_rect: Rect2 = table.end_turn_button.get_global_rect()
	_expect(end_turn_rect.position.x >= table.size.x * 0.80 and end_turn_rect.position.y >= table.size.y * 0.42 and end_turn_rect.end.y <= table.size.y * 0.53, "End Turn is not beside the seam between the playmats.")
	_expect(not table.title_label.visible, "The redundant matchup title is still visible in the top HUD.")
	_expect(table.find_child("MatchHeader", true, false) == null, "The persistent top-center match panel still exists.")
	_expect(
		table.battle_log_button.global_position.x > table.get_viewport_rect().size.x * 0.5,
		"The utility controls are not grouped on the right side of the top HUD."
	)
	_expect(
		table.player_profile_life_bar != null
		and table.opponent_profile_life_bar != null
		and table.player_profile_name.is_visible_in_tree()
		and table.opponent_profile_name.is_visible_in_tree()
		and not table.player_profile_name.text.is_empty()
		and not table.opponent_profile_name.text.is_empty()
		and not table.player_profile_details.visible
		and not table.opponent_profile_details.visible
		and table.player_profile_badge.get_global_rect().encloses(table.player_profile_life_bar.get_global_rect())
		and table.opponent_profile_badge.get_global_rect().encloses(table.opponent_profile_life_bar.get_global_rect())
		and table.player_profile_badge.get_global_rect().encloses(table.player_profile_name.get_global_rect())
		and table.opponent_profile_badge.get_global_rect().encloses(table.opponent_profile_name.get_global_rect()),
		"The competitor profiles do not integrate a visible name and numeric life bar."
	)
	for side in ["player", "opponent"]:
		_check_profile_health_layout(table, side)
	var player_profile_rect: Rect2 = table.player_profile_badge.get_global_rect()
	var opponent_profile_rect: Rect2 = table.opponent_profile_badge.get_global_rect()
	_expect(player_profile_rect.position.x <= 32.0 and player_profile_rect.position.y >= table.size.y * 0.77 and player_profile_rect.position.y <= table.size.y * 0.83, "The player profile is not aligned to the lower-left edge.")
	_expect(player_profile_rect.size.x >= 300.0 and opponent_profile_rect.size.x >= 280.0, "The reference's enlarged competitor scorecards reverted to the smaller HUD.")
	_expect(
		opponent_profile_rect.position.x >= table.size.x * 0.65
		and opponent_profile_rect.position.y >= table.size.y * 0.12
		and opponent_profile_rect.position.y <= table.size.y * 0.18
		and opponent_profile_rect.end.x >= table.size.x * 0.87
		and opponent_profile_rect.end.x <= table.size.x * 0.93,
		"The opponent profile is not positioned at the upper right beside the seated rival."
	)
	_expect(
		table.player_profile_badge.find_child("PlayerProfileBadgeAngularSurface", true, false) != null
		and table.opponent_profile_badge.find_child("OpponentProfileBadgeAngularSurface", true, false) != null
		and table.player_profile_badge.find_child("PlayerProfileBadgeTechPattern", true, false) == null,
		"The player and rival profiles do not use the clean scorecard treatment."
	)
	_expect(
		table.turn_banner_panel.get_theme_stylebox("panel") is StyleBoxEmpty
		and table.turn_banner_surface.peach_soda_style
		and table.turn_banner_surface.fill_color.is_equal_approx(PALETTE.PEACH_PAPER)
		and table.turn_banner_graphic.get_script() == TURN_GRAPHIC_SCRIPT
		and table.turn_banner_graphic.accent_color.is_equal_approx(table.turn_banner_accent_rule.color),
		"The turn-change banner does not use the native Peach Soda paper treatment."
	)
	table._show_turn_banner("opponent_turn")
	await create_timer(0.32).timeout
	_expect(
		table.turn_banner_title.text == "OPPONENT TURN"
		and table.turn_banner_title.get_theme_color("font_color").is_equal_approx(PALETTE.PEACH_INK)
		and _contrast_ratio(table.turn_banner_title.get_theme_color("font_color"), PALETTE.PEACH_PAPER) >= 4.5
		and table.turn_banner_title.get_theme_constant("outline_size") == 0
		and table.turn_banner_title.get_theme_constant("shadow_offset_x") == 0
		and table.turn_banner_title.get_theme_constant("shadow_offset_y") == 0
		and table.turn_banner_graphic.accent_color.is_equal_approx(PALETTE.SIGNAL_RED)
		and table.turn_banner_accent_rule.color.is_equal_approx(PALETTE.SIGNAL_RED)
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
		table._card_viewer_action_icon("Play Card").resource_path == "res://assets/ui/peach_soda_actions/play.svg"
		and table._card_viewer_action_icon("Activate Ability").resource_path == "res://assets/ui/peach_soda_actions/ability.svg"
		and table.ACTION_ICON_SPECIAL_SERVE.resource_path == "res://assets/ui/battle_actions/special_serve.png"
		and table._card_viewer_action_icon("Attack").resource_path == "res://assets/ui/peach_soda_actions/attack.svg"
		and table._card_viewer_action_icon("Move").resource_path == "res://assets/ui/peach_soda_actions/move.svg"
		and table._card_viewer_action_icon("Begin Recipe").resource_path == "res://assets/ui/peach_soda_actions/spice.svg",
		"The card inspector is not using the native Peach Soda symbols for its corresponding actions."
	)
	_expect(
		table.settings_button.get_node_or_null("BattleAngularButtonFace") != null
		and table.end_turn_button.get_node_or_null("BattleAngularButtonFace") != null,
		"The battle controls do not use the shared readable button treatment."
	)
	for side in ["player", "opponent"]:
		await _check_profile_health_animation(table, side)
	table._spawn_damage_burst_screen(Vector2(720, 430), PALETTE.SIGNAL_RED)
	_expect(
		table.effect_layer.find_child("DamageGraphicVfx", true, false) != null,
		"The engine-drawn damage impact burst did not spawn."
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
	var tabletop_box := tabletop_mesh.mesh as BoxMesh
	var battle_backdrop := table.get_node_or_null("BattleBackdrop") as Control
	var production_arena := table.get_node("ViewportContainer/WorldViewport/World/ProductionArena") as Node3D
	var inset_playmat := production_arena.get_node("InsetPlaymat") as MeshInstance3D
	var inset_material := inset_playmat.get_active_material(0) as StandardMaterial3D
	var player_playmat := production_arena.get_node("PlayerPlaymat") as MeshInstance3D
	var player_mat_material := player_playmat.get_active_material(0) as StandardMaterial3D
	var opponent_mat_bounds: AABB = inset_playmat.transform * inset_playmat.mesh.get_aabb()
	var player_mat_bounds: AABB = player_playmat.transform * player_playmat.mesh.get_aabb()
	_expect(
		battle_backdrop != null
		and not battle_backdrop is TextureRect
		and battle_backdrop.get_script() == BACKDROP_SCRIPT
		and battle_backdrop.is_visible_in_tree()
		and String(table.get_meta("battle_visual_style", "")) == "peach_soda"
		and not tabletop_mesh.is_visible_in_tree(),
		"The Peach Soda table perimeter is not drawn by the native backdrop, or the old 3D wood is still visible."
	)
	if battle_backdrop == null:
		quit(1)
		return
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
	var first_slot_bounds := _printed_geometry_bounds(first_player_prep_slot)
	var last_slot_bounds := _printed_geometry_bounds(last_player_prep_slot)
	var first_slot_target: Vector3 = table._slot_world_position("player_prep", 0)
	var last_slot_target: Vector3 = table._slot_world_position("player_prep", 2)
	_expect(
		first_player_prep_slot != null
		and last_player_prep_slot != null
		and absf(first_slot_bounds.get_center().x - first_slot_target.x) <= 0.03
		and absf(last_slot_bounds.get_center().x - last_slot_target.x) <= 0.03
		and first_slot_bounds.size.x >= table.FIELD_CARD_SIZE.x
		and first_slot_bounds.size.z >= table.ZONE_EXTENTS.player_prep.y * 2.0,
		"The printed corner marks do not frame the playable Prep destinations."
	)
	_expect(
		production_arena != null
		and String(production_arena.get_meta("asset_origin", "")) == "engine_geometry"
		and not bool(production_arena.get_meta("ships_external_art", true))
		and production_arena.get_node_or_null("InsetPlaymat") != null
		and production_arena.get_node_or_null("PlayerPlaymat") != null
		and production_arena.get_node_or_null("PlaymatPrinting/PlayerBinding") != null
		and production_arena.get_node_or_null("PlaymatPrinting/OpponentBinding") != null
		and production_arena.get_node_or_null("PrintedCardSlots/PlayerPrepSlot1") != null
		and production_arena.get_node_or_null("PlayerDeckTray") != null
		and production_arena.get_node_or_null("PlayerEnvironmentTray") != null
		and production_arena.get_node_or_null("OpponentDiscardTray") != null,
		"The separate cloth mats, their bindings, or marked deck/discard trays are missing."
	)
	_expect(
		inset_material != null
		and inset_material.albedo_color.is_equal_approx(PALETTE.PEACH_MAT)
		and inset_material.albedo_texture == null
		and inset_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		and is_zero_approx(inset_material.metallic_specular)
		and player_mat_material != null
		and player_mat_material.albedo_color.is_equal_approx(PALETTE.PEACH_MAT.lerp(PALETTE.PEACH_TEAL, 0.22))
		and player_mat_material.albedo_texture == null
		and player_mat_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		and is_zero_approx(player_mat_material.metallic_specular)
		and opponent_mat_bounds.size.x < tabletop_box.size.x
		and opponent_mat_bounds.size.z < tabletop_box.size.z
		and player_mat_bounds.size.x < tabletop_box.size.x
		and player_mat_bounds.size.z < tabletop_box.size.z
		and player_mat_bounds.position.z - opponent_mat_bounds.end.z >= 0.20
		and String(inset_playmat.get_meta("playmat_side", "")) == "opponent"
		and String(player_playmat.get_meta("playmat_side", "")) == "player"
		and production_arena.get_node_or_null("PlaymatPrinting/CenterRule") == null
		and production_arena.get_node_or_null("PlaymatPrinting/PlayerPrepPrint1") is Label3D
		and production_arena.get_node_or_null("PlaymatPrinting/OpponentPrepPrint1") is Label3D,
		"The battle board lost its two flat Peach Soda cloths, exposed center gap, or native printed zone labels."
	)
	for side in ["Player", "Opponent"]:
		var binding := production_arena.get_node("PlaymatPrinting/%sBinding/SoftBoundEdge" % side) as MeshInstance3D
		var binding_material := binding.get_active_material(0) as StandardMaterial3D
		_expect(
			binding_material != null
			and binding_material.albedo_color.a > 0.0
			and binding_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
			and bool(binding.get_meta("flat_playmat_ink", false))
			and bool(binding.get_meta("procedural_geometry", false)),
			"The %s cloth is missing its native flat sewn boundary." % side.to_lower()
		)
	_expect(
		table._zone_color("player_plated").is_equal_approx(PALETTE.ZONE_PLAYER_PLATED)
		and table._zone_color("player_prep").is_equal_approx(PALETTE.ZONE_PLAYER_PREP)
		and table._zone_color("opponent_plated").is_equal_approx(PALETTE.ZONE_OPPONENT_PLATED)
		and table._zone_color("opponent_prep").is_equal_approx(PALETTE.ZONE_OPPONENT_PREP),
		"The table zones do not use the two-color player-blue and rival-red ownership system."
	)
	_expect(
		battle_backdrop.get_script() == BACKDROP_SCRIPT
		and table.find_child("RivalAtLocalsTable", true, false) is TextureRect,
		"The native locals room or separate configured rival was not loaded."
	)
	var locals_backdrop_script: Script = battle_backdrop.get_script()
	table.configured_match_context = {"route_encounter": true, "location": "Waterfront Table"}
	table._apply_route_location_theme()
	_expect(
		table.get_node_or_null("BattleBackdrop") == battle_backdrop
		and battle_backdrop.get_script() == locals_backdrop_script
		and battle_backdrop.is_visible_in_tree(),
		"Route metadata replaced the native locals room backdrop."
	)
	table.configured_match_context = original_match_context
	table._apply_route_location_theme()
	_expect(
		table.end_turn_button.text.to_upper() == "END TURN"
		and table.end_turn_button.get_theme_font("font").resource_path == "res://assets/fonts/AtkinsonHyperlegibleNext.ttf"
		and String(table.end_turn_button.get_meta("ui_button_variant", "")) == "primary"
		and table.end_turn_button.size.y >= 46.0,
		"The primary turn action is not clearly labeled and large enough to press."
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
	_expect(table.battle_log_text.get_theme_color("default_color").is_equal_approx(PALETTE.PEACH_INK), "Match log copy did not use the readable Peach Soda ink color.")
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
	_expect(table.invalid_action_visible and "Normal Meal already served this turn." in table.status_label.text, "An illegal second Meal did not show its rule explanation.")
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
	for zone_id in table.ZONE_CENTERS:
		var capacity: int = table.service.PREP_SLOTS if String(zone_id).ends_with("prep") else table.service.PLATED_SLOTS
		for slot_index in range(capacity):
			var target: Vector3 = table._slot_world_position(String(zone_id), slot_index)
			var projected: Vector2 = table._world_to_container(target)
			var picked: Dictionary = table._slot_at_point(target)
			_expect(
				Rect2(Vector2.ZERO, table.viewport_container.size).has_point(projected)
				and String(picked.get("zone", "")) == String(zone_id)
				and int(picked.get("slot", -1)) == slot_index,
				"The battle composition clips a destination or disagrees with its hit target."
			)
	_expect(table.card_layer.find_children("*PlatedCard_*", "Node3D", true, false).size() == 3, "Camera preview did not render all Plated cards.")
	var ability_card: Node3D = table.find_child("PlayerPrepCard_*", true, false)
	var ability_aura := ability_card.find_child("AbilityReadyAura", true, false) as MeshInstance3D if ability_card != null else null
	_expect(ability_aura != null and ability_aura.material_override is StandardMaterial3D, "A field card with a ready activated ability has no glowing aura.")
	_expect(table.card_layer.find_children("AbilityReadyAura", "MeshInstance3D", true, false).size() == 1, "The ability-ready aura appeared on a card that cannot currently activate an ability.")
	var hand_card: Node3D = table.find_child("PlayerHandCard_0", true, false)
	_expect(hand_card != null, "Camera preview did not render the player's hand.")
	if hand_card != null:
		var hand_rect: Rect2 = table._card_screen_rect(hand_card)
		var visible_hand_rect := hand_rect.intersection(Rect2(Vector2.ZERO, table.viewport_container.size))
		_expect(
			hand_rect.size.x >= table.viewport_container.size.x * 0.10
			and hand_rect.size.y >= table.viewport_container.size.y * 0.18,
			"The player's hand cards are too small on screen to read."
		)
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
		var opponent_hand_rect: Rect2 = table._card_screen_rect(opponent_hand_card)
		_expect(
			Rect2(Vector2.ZERO, table.viewport_container.size).encloses(opponent_hand_rect),
			"The rival's visible card backs are clipped by the battle camera."
		)
		for field_card in table.interactive_cards:
			if not is_instance_valid(field_card) or String(field_card.get_meta("kind", "")) != "field":
				continue
			_expect(
				not opponent_hand_rect.intersects(table._card_screen_rect(field_card)),
				"The rival's card backs overlap a playable field card."
			)
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


func _check_profile_health_layout(table, side: String) -> void:
	var is_player := side == "player"
	var panel: Control = table.player_profile_badge if is_player else table.opponent_profile_badge
	var name_label: Label = table.player_profile_name if is_player else table.opponent_profile_name
	var value_label: Label = table.player_profile_life_label if is_player else table.opponent_profile_life_label
	var bar: ProgressBar = table.player_profile_life_bar if is_player else table.opponent_profile_life_bar
	var trail: ProgressBar = table.player_profile_life_trail_bar if is_player else table.opponent_profile_life_trail_bar
	var number_font := value_label.get_theme_font("font")
	var number_size := value_label.get_theme_font_size("font_size")
	var number_rect := value_label.get_global_rect()
	var expected_direction := ProgressBar.FILL_BEGIN_TO_END if is_player else ProgressBar.FILL_END_TO_BEGIN
	_expect(
		value_label.is_visible_in_tree()
		and number_size >= 18
		and number_font.resource_path == "res://assets/fonts/AtkinsonHyperlegibleNext.ttf"
		and number_font.get_string_size(value_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x <= value_label.size.x
		and value_label.get_theme_color("font_color").is_equal_approx(PALETTE.PEACH_INK)
		and _contrast_ratio(value_label.get_theme_color("font_color"), PALETTE.PEACH_PAPER) >= 4.5
		and panel.get_global_rect().encloses(number_rect)
		and not number_rect.intersects(name_label.get_global_rect())
		and number_rect.end.y <= bar.get_global_rect().position.y,
		"The %s HP numbers do not fit clearly above the meter without overlapping the name." % side
	)
	_expect(
		bar.get_script() == HEALTH_BAR_SCRIPT
		and trail.get_script() == HEALTH_BAR_SCRIPT
		and not bool(bar.get("draw_track"))
		and bool(trail.get("draw_track"))
		and bar.get("fill_color").is_equal_approx(PALETTE.PEACH_HEALTH)
		and _contrast_ratio(bar.get("fill_color"), PALETTE.PEACH_PAPER) >= 3.0
		and trail.get("fill_color").is_equal_approx(PALETTE.PEACH_TABLE)
		and bar.fill_mode == expected_direction
		and trail.fill_mode == expected_direction
		and bar.size.y >= 24.0
		and panel.get_global_rect().encloses(bar.get_global_rect())
		and panel.get_global_rect().encloses(trail.get_global_rect())
		and bar.get_global_rect().is_equal_approx(trail.get_global_rect()),
		"The %s HP meter does not use the supplied-kit renderer with an aligned damage trail and correct fill direction." % side
	)
	if not bar.has_method("fill_rect") or not trail.has_method("fill_rect"):
		return
	for meter: ProgressBar in [bar, trail]:
		var previous_value := meter.value
		meter.value = meter.min_value
		var empty_rect: Rect2 = meter.call("fill_rect")
		meter.value = meter.max_value
		var full_rect: Rect2 = meter.call("fill_rect")
		meter.value = lerpf(meter.min_value, meter.max_value, 0.5)
		var partial_rect: Rect2 = meter.call("fill_rect")
		meter.value = previous_value
		_expect(
			not empty_rect.has_area()
			and full_rect.has_area()
			and Rect2(Vector2.ZERO, meter.size).encloses(full_rect)
			and full_rect.size.x >= meter.size.x * 0.8
			and partial_rect.has_area()
			and full_rect.encloses(partial_rect)
			and is_equal_approx(partial_rect.size.x, full_rect.size.x * 0.5)
			and is_equal_approx(partial_rect.size.y, full_rect.size.y),
			"The %s HP fill is not empty at zero, contained at maximum, and proportional at half health." % side
		)
		_expect(
			is_equal_approx(partial_rect.position.x, full_rect.position.x) if is_player
			else is_equal_approx(partial_rect.end.x, full_rect.end.x),
			"The %s HP fill is not anchored toward its corresponding portrait." % side
		)


func _check_profile_health_animation(table, side: String) -> void:
	var is_player := side == "player"
	var bar: ProgressBar = table.player_profile_life_bar if is_player else table.opponent_profile_life_bar
	var trail: ProgressBar = table.player_profile_life_trail_bar if is_player else table.opponent_profile_life_trail_bar
	var value_label: Label = table.player_profile_life_label if is_player else table.opponent_profile_life_label
	var life_before := bar.value
	var combat_life_before := int(table.state[side].life)
	var damage := mini(3, int(life_before))
	var damaged_life := life_before - float(damage)
	_expect(damage > 0, "The %s life-animation fixture must begin with positive health." % side)
	if damage <= 0:
		return
	table._animate_profile_life_change(side, damage)
	await create_timer(0.32).timeout
	_expect(
		is_equal_approx(bar.value, damaged_life)
		and trail.value > bar.value
		and value_label.text == "%d/%d" % [int(damaged_life), int(bar.max_value)],
		"The %s life bar did not show the exact damaged total with a trailing drain." % side
	)
	await create_timer(0.4).timeout
	_expect(
		is_equal_approx(trail.value, damaged_life),
		"The %s damage trail did not settle at the displayed health." % side
	)
	table._animate_profile_life_change(side, damage, true)
	await create_timer(0.34).timeout
	_expect(
		is_equal_approx(bar.value, life_before)
		and is_equal_approx(trail.value, life_before)
		and value_label.text == "%d/%d" % [int(life_before), int(bar.max_value)]
		and int(table.state[side].life) == combat_life_before,
		"The %s healing animation did not settle at the restored total without changing combat state." % side
	)
	table._sync_profile_life_bar(side)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _printed_geometry_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	if node == null:
		return bounds
	for mesh_node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		var world_bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = bounds.merge(world_bounds) if found else world_bounds
		found = true
	return bounds


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
