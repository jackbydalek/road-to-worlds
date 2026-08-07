extends SceneTree

const READABILITY_PREVIEW_PATH := "/tmp/road_to_worlds_tabletop_readability_preview.png"
const GAMEPLAY_FLOW_PREVIEW_PATH := "/tmp/road_to_worlds_meal_power_entrance.png"
const ACTION_SPIN_PREVIEW_PATH := "/tmp/road_to_worlds_action_card_spin.png"
const ACTIVATION_PREVIEW_PATH := "/tmp/road_to_worlds_field_activation.png"
const INSPECTOR_PREVIEW_PATH := "/tmp/road_to_worlds_card_inspector.png"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/Tabletop3DPrototype.tscn") as PackedScene
	_expect(packed_scene != null, "The Living Table scene could not be loaded.")
	if packed_scene == null:
		_finish()
		return
	var table = packed_scene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	var arena_table := table.get_node("ViewportContainer/WorldViewport/World/Table") as MeshInstance3D
	var arena_slot := table.get_node("ViewportContainer/WorldViewport/World/Zones/PlayerPrep/Slot1") as MeshInstance3D
	var arena_chef := table.get_node("ViewportContainer/WorldViewport/World/PlayerChef/Mesh") as MeshInstance3D
	var player_chef_life := table.get_node("ViewportContainer/WorldViewport/World/PlayerChef/Label") as Label3D
	var opponent_chef_life := table.get_node("ViewportContainer/WorldViewport/World/OpponentChef/Label") as Label3D
	var auxiliary_zone := table.find_child("PlayerDeckZone", true, false) as Node3D
	var auxiliary_pad := auxiliary_zone.find_child("ZonePad", true, false) as MeshInstance3D if auxiliary_zone != null else null
	_expect(_has_lofi_outline(arena_table), "The combat table surface did not receive the shop-style navy outline.")
	_expect(_has_lofi_outline(arena_slot), "Combat slot pads did not receive the shop-style navy outline.")
	_expect(_has_lofi_outline(arena_chef), "Chef pucks did not receive the shop-style navy outline.")
	_expect(
		player_chef_life.modulate == Color.WHITE
		and opponent_chef_life.modulate == Color.WHITE
		and player_chef_life.outline_modulate.is_equal_approx(Color("#29365F"))
		and opponent_chef_life.outline_modulate.is_equal_approx(Color("#29365F"))
		and player_chef_life.outline_size >= 15
		and opponent_chef_life.outline_size >= 15,
		"Chef health numbers did not use high-contrast white text with the navy outline."
	)
	_expect(_has_lofi_outline(auxiliary_pad), "Deck, discard, and Environment pads did not receive the shop-style navy outline.")
	_expect(table.find_child("TurnBanner", true, false) != null, "The turn pacing banner was not created.")
	_expect(table.find_child("OutcomeOverlay", true, false) != null, "The match outcome overlay was not created.")
	var rival_action_panel := table.find_child("RivalActionPanel", true, false) as PanelContainer
	var game_breakdown_button := table.find_child("GameBreakdownButton", true, false) as Button
	var rival_pacing_button := table.find_child("RivalPacingButton", true, false) as Button
	var text_scale_button := table.find_child("TextScaleButton", true, false) as Button
	_expect(rival_action_panel != null and not rival_action_panel.visible, "The persistent rival-action inspector was not created in its idle state.")
	_expect(table.battle_log_panel != null and not table.battle_log_panel.visible, "The battle log did not start collapsed.")
	_expect(game_breakdown_button != null and game_breakdown_button.disabled, "The Game Breakdown control was not created in its idle state.")
	var match_options_button := table.find_child("MatchOptionsButton", true, false) as Button
	var readability_controls := table.find_child("ReadabilityControls", true, false) as PanelContainer
	_expect(match_options_button != null and match_options_button.text == "OPTIONS", "The compact match-options control was not created.")
	_expect(readability_controls != null and not readability_controls.visible, "Readability settings did not start collapsed.")
	_expect(rival_pacing_button != null and rival_pacing_button.text.begins_with("PLAY SPEED"), "The play-speed control was not created.")
	_expect(text_scale_button != null and text_scale_button.text.begins_with("TEXT SIZE"), "The readable text-scale control was not created.")
	_expect(table.theme.default_font.resource_path.ends_with("AtkinsonHyperlegibleNext.ttf"), "The Living Table UI did not use the bundled hyperlegible font.")
	var original_text_scale_index: int = table.text_scale_index
	table.text_scale_index = 0
	table._apply_text_scale()
	var base_status_font_size: int = table.status_label.get_theme_font_size("font_size")
	table.text_scale_index = 2
	table._apply_text_scale()
	_expect(table.status_label.get_theme_font_size("font_size") > base_status_font_size, "The 150% text setting did not enlarge match UI copy.")
	table.text_scale_index = original_text_scale_index
	table._apply_text_scale()
	table._refresh_readability_control_labels()
	_expect(table.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "The no-sound pacing pass added an AudioStreamPlayer.")
	var ingredient_hand_index := -1
	for hand_index in range(table.state.player.hand.size()):
		if String(table.service.card(String(table.state.player.hand[hand_index])).get("card_type", "")) == "ingredient":
			ingredient_hand_index = hand_index
			break
	_expect(ingredient_hand_index >= 0, "The play-destination smoke test could not find an Ingredient in the opening hand.")
	if ingredient_hand_index >= 0:
		table.selected_ref = {
			"kind": "hand",
			"side": "player",
			"hand_index": ingredient_hand_index,
			"instance_id": -1,
			"zone": "hand",
			"card_id": String(table.state.player.hand[ingredient_hand_index])
		}
		table._refresh_action_panel()
		table._begin_hand_play_selection(ingredient_hand_index)
		var inspector_buttons: Array[Node] = table.action_list.find_children("*", "Button", true, false)
		var has_cancel := false
		for inspector_button in inspector_buttons:
			if String((inspector_button as Button).text) == "Cancel":
				has_cancel = true
		_expect(table.pending_hand_play_index == ingredient_hand_index and not table.action_highlight_slots.is_empty() and has_cancel, "Play Card did not enter the board-destination selection mode with a cancel action.")
		table._cancel_pending_hand_play()
		table.selected_ref = {}
		table._refresh_action_panel()
	table.selected_ref = {"kind": "field", "side": "opponent", "hand_index": -1, "instance_id": -1, "zone": "plated", "card_id": "spicy_wasabi_wasp"}
	table._refresh_action_panel()
	_expect(
		table.keyword_popout != null
		and table.keyword_popout.visible
		and String(table.service.card("spicy_wasabi_wasp").get("text", "")) == "Stalwart"
		and String(table.service.card("sweet_soft_serve_crab").get("text", "")) == "Bodyguard"
		and String(table.service.card("hearty_french_bread_dog").get("text", "")) == "Taunt",
		"Keyword cards did not use concise printed text with an inspector popout."
	)
	if DisplayServer.get_name() != "headless":
		await create_timer(1.0).timeout
		var inspector_preview := root.get_texture().get_image()
		_expect(inspector_preview.save_png(INSPECTOR_PREVIEW_PATH) == OK, "The card inspector preview could not be saved.")
	table.selected_ref = {}
	table._refresh_action_panel()
	# A drop is resolved under the dragged card, not under the offset point where
	# the player happened to grab it. This keeps the highlighted slot authoritative.
	table.drag_offset = Vector3(-0.55, 0.0, 0.0)
	var offset_drop_point: Vector3 = table._dragged_card_point(Vector3(0.4, table.TABLE_Y, -0.65))
	var offset_drop_slot: Dictionary = table._slot_at_point(offset_drop_point)
	_expect(
		String(offset_drop_slot.get("zone", "")) == "player_plated" and int(offset_drop_slot.get("slot", -1)) == 0,
		"An offset card grab resolved the drop under the pointer instead of the highlighted Plated slot."
	)
	table.drag_offset = Vector3.ZERO
	await create_timer(1.0).timeout
	table._spawn_screen_particle_burst(Vector2(120.0, 120.0), Color.WHITE, 1, "✦")
	var procedural_particle: Node = table.effect_layer.get_child(-1)
	_expect(procedural_particle is Polygon2D, "Tabletop effects still use font glyphs that can render as missing-character boxes.")
	await create_timer(0.6).timeout
	var draw_card_id := String(table.state.player.hand[0])
	var draw_card_node: Node3D = table._hand_card_node("player", 0, draw_card_id)
	var staged_draw_events: Array[Dictionary] = [{
		"type": "draw",
		"side": "player",
		"hand_index": 0,
		"card_id": draw_card_id,
		"from": "deck",
		"to": "hand"
	}]
	var staged_draw_cards: Array[Node3D] = table._stage_activation_result_transfers(staged_draw_events)
	_expect(draw_card_node != null and not draw_card_node.visible and staged_draw_cards.size() == 1, "An effect draw destination was visible before its transfer animation began.")
	table._release_staged_transfer_card({
		"type": "draw",
		"side": "player",
		"hand_index": 0,
		"card_id": draw_card_id,
		"to": "hand"
	}, staged_draw_cards)
	_expect(draw_card_node != null and draw_card_node.visible and staged_draw_cards.is_empty(), "A staged effect draw did not reveal its card when the transfer animation began.")
	var effect_count_before_draw: int = table.effect_layer.get_child_count()
	var draw_animation_duration: float = table._start_card_transfer_event_animation({
		"type": "draw",
		"side": "player",
		"hand_index": 0,
		"card_id": draw_card_id,
		"from": "deck",
		"to": "hand"
	})
	_expect(draw_animation_duration > 0.0 and table.effect_layer.get_child_count() == effect_count_before_draw, "Drawing a card still spawned a particle burst.")
	await create_timer(draw_animation_duration).timeout
	table.animation_busy = true
	var meal_probe: Node3D = table._make_card("spicy_sriracharrow", true)
	meal_probe.position = Vector3(0.0, table.TABLE_Y, -0.65)
	meal_probe.set_meta("instance_id", 99001)
	table.card_layer.add_child(meal_probe)
	table.interactive_cards.append(meal_probe)
	var meal_target_scale := meal_probe.scale
	var camera_before_meal: Transform3D = table.camera.global_transform
	var camera_fov_before_meal: float = table.camera.fov
	var meal_animation_duration: float = table._start_play_event_animation({
		"type": "play",
		"side": "player",
		"card_id": "spicy_sriracharrow",
		"card_type": "meal",
		"instance_id": 99001,
		"to": "plated"
	}, {})
	_expect(String(meal_probe.get_meta("play_animation_style", "")) == "meal_power" and meal_animation_duration >= 0.7, "Meals did not use the dramatic power-card entrance.")
	await create_timer(0.24).timeout
	_expect(
		table.camera.global_transform.is_equal_approx(camera_before_meal)
		and is_equal_approx(table.camera.fov, camera_fov_before_meal),
		"Serving a Meal moved the combat camera and caused a screen jump."
	)
	if DisplayServer.get_name() != "headless":
		var flow_preview := root.get_texture().get_image()
		_expect(flow_preview.save_png(GAMEPLAY_FLOW_PREVIEW_PATH) == OK, "The Meal power-entrance preview could not be saved.")
	await create_timer(meal_animation_duration - 0.24).timeout
	_expect(meal_probe.scale.is_equal_approx(meal_target_scale), "The Meal power entrance did not settle at the card's field scale.")
	var activation_origin_position: Vector3 = meal_probe.position
	var activation_origin_scale: Vector3 = meal_probe.scale
	var activation_probe_timer := create_timer(0.24)
	activation_probe_timer.timeout.connect(func() -> void:
		_expect(table.find_child("FieldActivationIndicator", true, false) != null, "The field activation callout did not appear over the source card.")
		_expect(meal_probe.position.y > activation_origin_position.y and meal_probe.scale.length() > activation_origin_scale.length(), "The activating field card did not lift and pulse.")
		if DisplayServer.get_name() != "headless":
			var activation_preview := root.get_texture().get_image()
			_expect(activation_preview.save_png(ACTIVATION_PREVIEW_PATH) == OK, "The field activation preview could not be saved.")
	)
	await table._show_field_activation_indicator({
		"type": "card_text_activation",
		"side": "player",
		"source_instance_id": 99001,
		"card_id": "spicy_sriracharrow",
		"activation_label": "ON-PLAY EFFECT"
	})
	_expect(
		table.field_activation_indicator_count == 1
		and table.last_field_activation_card_id == "spicy_sriracharrow"
		and table.last_field_activation_kind == "card_text_activation"
		and meal_probe.position.is_equal_approx(activation_origin_position)
		and meal_probe.scale.is_equal_approx(activation_origin_scale),
		"The on-play activation indicator did not identify the source and restore its field pose."
	)
	table.interactive_cards.erase(meal_probe)
	meal_probe.queue_free()
	var play_event_state: Dictionary = table.state.duplicate(true)
	table.service.clear_animation_events(play_event_state)
	table.service._queue_play_event(play_event_state, "player", "spicy_hot_honey_bee", "ingredient")
	var on_play_events: Array[Dictionary] = table.service.take_animation_events(play_event_state)
	_expect(
		on_play_events.size() == 2
		and String(on_play_events[0].get("type", "")) == "play"
		and String(on_play_events[1].get("type", "")) == "card_text_activation",
		"A card with on-play text did not queue its activation cue immediately after entering play."
	)
	var ability_event_state: Dictionary = table.state.duplicate(true)
	ability_event_state.phase = "player_main"
	ability_event_state.game_over = false
	ability_event_state.pending_meal = {}
	ability_event_state.pending_discard = {}
	ability_event_state.pending_ability = {}
	ability_event_state.pending_search = {}
	ability_event_state.pending_choice = {}
	var ability_source: Dictionary = table.service._make_unit(
		ability_event_state,
		ability_event_state.player,
		table.service.card("funky_fondue_ferret"),
		"prep",
		"player"
	)
	ability_event_state.player.prep = [ability_source]
	ability_event_state.player.plated = []
	table.service.clear_animation_events(ability_event_state)
	table.service.activate_ability(ability_event_state, int(ability_source.instance_id), "feta_ferret_mill")
	var ability_events: Array[Dictionary] = table.service.take_animation_events(ability_event_state)
	_expect(
		not ability_events.is_empty()
		and String(ability_events[0].get("type", "")) == "ability_activation"
		and int(ability_events[0].get("source_instance_id", -1)) == int(ability_source.instance_id),
		"An activated field ability did not queue a source-card activation cue before its result."
	)
	_expect(
		table._uses_field_activation_indicator(on_play_events[1])
		and table._uses_field_activation_indicator(ability_events[0])
		and not table._uses_field_activation_indicator({
			"type": "card_text_activation",
			"card_type": "tool",
			"card_id": "item_wooden_spoon"
		})
		and not table._uses_field_activation_indicator({
			"type": "card_text_activation",
			"card_type": "chef",
			"card_id": "chef_mary"
		}),
		"Discard-bound Tool or Chef effects still requested the redundant field highlight pause."
	)
	var action_reveal_preview_timer := create_timer(0.55)
	action_reveal_preview_timer.timeout.connect(func() -> void:
		var fullscreen_reveal := table.find_child("ActionCardFullscreenReveal", true, false) as TextureRect
		var reveal_border := fullscreen_reveal.find_child("ActionCardRevealBorder", true, false) as Panel if fullscreen_reveal != null else null
		var reveal_border_style := reveal_border.get_theme_stylebox("panel") as StyleBoxFlat if reveal_border != null else null
		_expect(fullscreen_reveal != null, "The Tool did not appear in the full-screen action-card reveal.")
		_expect(
			reveal_border_style != null
			and reveal_border_style.border_width_left >= 8
			and reveal_border_style.border_color == table._action_reveal_border_color(),
			"The Tool/Chef spin reveal did not carry the selected rounded card border."
		)
		_expect(
			reveal_border_style != null
			and not reveal_border_style.draw_center
			and reveal_border_style.shadow_size == 0,
			"The Tool/Chef spin border added a fill, tint, or shadow over the card art."
		)
		if DisplayServer.get_name() != "headless":
			var spin_preview := root.get_texture().get_image()
			_expect(spin_preview.save_png(ACTION_SPIN_PREVIEW_PATH) == OK, "The full-screen action-card preview could not be saved.")
	)
	await table._show_action_card_fullscreen_reveal({
		"type": "play",
		"side": "player",
		"card_id": "item_wooden_spoon",
		"card_type": "tool"
	})
	_expect(
		table.fullscreen_action_reveal_count == 1
		and table.last_fullscreen_action_reveal_card_id == "item_wooden_spoon"
		and table.last_fullscreen_action_reveal_type == "tool",
		"Tools did not use the restored full-screen action-card reveal."
	)
	var tool_probe: Node3D = table._make_card("item_wooden_spoon", true)
	tool_probe.position = table.AUX_ZONE_POSITIONS.player_discard
	tool_probe.scale = Vector3.ONE * 0.54
	tool_probe.set_meta("instance_id", 99002)
	table.card_layer.add_child(tool_probe)
	table.interactive_cards.append(tool_probe)
	var tool_animation_duration: float = table._start_play_event_animation({
		"type": "play",
		"side": "player",
		"card_id": "item_wooden_spoon",
		"card_type": "tool",
		"instance_id": 99002,
		"to": "discard"
	}, {})
	_expect(String(tool_probe.get_meta("play_animation_style", "")) == "action_fullscreen" and tool_animation_duration < 0.35, "The Tool still used the old 3D discard-pile spin.")
	await create_timer(tool_animation_duration).timeout
	table.interactive_cards.erase(tool_probe)
	tool_probe.queue_free()
	await table._show_action_card_fullscreen_reveal({
		"type": "play",
		"side": "player",
		"card_id": "chef_mary",
		"card_type": "chef"
	})
	_expect(table.fullscreen_action_reveal_count == 2 and table.last_fullscreen_action_reveal_type == "chef", "Chefs did not use the restored full-screen action-card reveal.")
	var original_rival_pacing_index: int = table.rival_pacing_index
	table.rival_pacing_index = 1
	var opponent_reveal_started := Time.get_ticks_msec()
	await table._show_action_card_fullscreen_reveal({
		"type": "play",
		"side": "opponent",
		"card_id": "item_wooden_spoon",
		"card_type": "tool"
	})
	var opponent_reveal_elapsed := float(Time.get_ticks_msec() - opponent_reveal_started) * 0.001
	_expect(
		table.fullscreen_action_reveal_count == 3
		and is_equal_approx(table.last_fullscreen_action_reveal_hold_seconds, 0.8)
		and opponent_reveal_elapsed >= table.last_fullscreen_action_reveal_hold_seconds,
		"The opponent's presented action card did not use the brisk Pocket-style hold."
	)
	table.rival_pacing_index = original_rival_pacing_index
	table.animation_busy = false
	table._reset_camera_pacing()
	var table_environment := table.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_expect(table_environment != null and table_environment.environment.background_color.is_equal_approx(Color(0.976, 0.941, 0.922, 1.0)), "Living Table did not retain its warm cream background.")
	table._face_material("spicy_hot_honey_bee")
	var bee_face_viewport := table.texture_viewports.find_child("PrototypeFullCardFaceViewport_spicy_hot_honey_bee", false, false) as SubViewport
	_expect(bee_face_viewport != null and bee_face_viewport.size == table.CARD_FACE_TEXTURE_SIZE and bee_face_viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Living Table card faces still used an unbounded full-frame render target.")
	var redraws_before_animation: int = table.card_face_redraw_requests
	await create_timer(0.14).timeout
	_expect(table.card_face_redraw_requests > redraws_before_animation and bee_face_viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Animated card art did not request a bounded redraw at its authored frame rate.")

	var reveal_events: Array[Dictionary] = [
		{"card_id": "spicy_hot_honey_bee", "card_type": "ingredient", "instance_id": -1, "side": "opponent", "type": "play", "zone": "prep", "to": "prep"},
		{"side": "opponent", "type": "draw", "from": "deck", "to": "hand"}
	]
	await table._show_opponent_reveal(reveal_events[0], reveal_events)
	await process_frame
	_expect(table.find_child("OpponentRevealPanel", true, false) == null, "A normal rival play still opened the blocking center breakdown.")
	_expect(not rival_action_panel.visible and not table.battle_log_panel.visible, "A normal rival play expanded a log panel over the table.")
	_expect(not game_breakdown_button.disabled, "Game Breakdown did not become available after a rival play.")
	var rival_action_card := table.find_child("RivalActionCard", true, false) as TextureRect
	var rival_outcome := table.rival_action_outcome_label as Label
	_expect(rival_action_card != null and rival_action_card.texture != null, "The persistent inspector did not retain the opponent's full card.")
	_expect(rival_outcome != null and rival_outcome.text.contains("Drew 1 card"), "The rival-action inspector did not summarize the visible resolution.")
	if DisplayServer.get_name() != "headless":
		var readability_preview := root.get_texture().get_image()
		_expect(readability_preview.save_png(READABILITY_PREVIEW_PATH) == OK, "The tabletop readability preview could not be saved.")
	var breakdown_resume_timer := create_timer(0.75)
	breakdown_resume_timer.timeout.connect(func() -> void:
		_expect(table.find_child("OpponentRevealPanel", true, false) != null and table.game_breakdown_active, "Game Breakdown did not open the blocking full-card explanation.")
		table.reveal_skip_requested = true
	)
	await table._open_game_breakdown()
	await process_frame
	_expect(not table.game_breakdown_active and table.find_child("OpponentRevealPanel", true, false) == null, "Game Breakdown did not resume and clean up.")
	var taunt_unit: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("hearty_french_bread_dog"), "plated", "opponent")
	taunt_unit.table_slot = 0
	table.state.opponent.prep = []
	table.state.opponent.plated = [taunt_unit]
	table._render_match()
	var plated_taunt_card: Node3D = table._card_node_for_instance(int(taunt_unit.instance_id))
	var taunt_aura := plated_taunt_card.find_child("TauntAura", true, false) as MeshInstance3D if plated_taunt_card != null else null
	var taunt_aura_material := taunt_aura.material_override as StandardMaterial3D if taunt_aura != null else null
	_expect(
		taunt_aura != null
		and taunt_aura_material != null
		and taunt_aura_material.emission.r > taunt_aura_material.emission.g * 2.0
		and taunt_aura_material.albedo_texture.resource_path.ends_with("taunt_aura.svg"),
		"A Taunt unit in Plated did not render its dedicated brick-red frame."
	)
	_expect(plated_taunt_card.find_child("TauntBadge", true, false) == null, "Taunt should communicate through its frame without a text badge.")
	_expect(plated_taunt_card.find_child("ReadyStatus", true, false) == null, "Generic READY competes with the Taunt priority state.")
	table.state.opponent.plated = []
	table.state.opponent.prep = [taunt_unit]
	table._render_match()
	var prep_taunt_card: Node3D = table._card_node_for_instance(int(taunt_unit.instance_id))
	_expect(
		prep_taunt_card != null
		and prep_taunt_card.find_child("TauntAura", true, false) == null,
		"A Taunt unit kept its red aura outside the Plated zone."
	)
	var moved_unit: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("spicy_hot_honey_bee"), "prep", "opponent")
	moved_unit.table_slot = 0
	table.state.opponent.prep = [moved_unit]
	table.state.opponent.plated = []
	table._render_match()
	var prep_card: Node3D = table._card_node_for_instance(int(moved_unit.instance_id))
	var floating_art := prep_card.find_child("FloatingArt", true, false) as MeshInstance3D if prep_card != null else null
	var stat_backing := prep_card.find_child("StatsBacking", true, false) as Sprite3D if prep_card != null else null
	var ready_badge_root := Node3D.new()
	ready_badge_root.scale = Vector3.ONE * table.PLATED_CARD_SCALE
	table.card_layer.add_child(ready_badge_root)
	var ready_badge_unit: Dictionary = moved_unit.duplicate(true)
	ready_badge_unit.ready = true
	table._add_stat_badge(ready_badge_root, ready_badge_unit, "player")
	var ready_stats := ready_badge_root.find_child("Stats", true, false) as Label3D
	var ready_stats_backing := ready_badge_root.find_child("StatsBacking", true, false) as Sprite3D
	var ready_indicator := ready_badge_root.find_child("ReadyStatus", true, false) as Label3D
	var ready_indicator_backing := ready_badge_root.find_child("ReadyStatusBacking", true, false) as Sprite3D
	var ready_status := ready_badge_root.find_child("Status", true, false) as Label3D
	_expect(
		ready_stats != null
		and ready_stats.text == "%d/%d" % [int(ready_badge_unit.attack), int(ready_badge_unit.health)]
		and ready_stats.font_size >= 54
		and ready_stats.pixel_size >= 0.006
		and ready_indicator != null
		and ready_indicator.text == "READY"
		and ready_indicator.font_size >= 54
		and ready_indicator.pixel_size >= 0.004
		and ready_stats_backing != null
		and ready_indicator_backing != null
		and float(ready_indicator_backing.get_meta("fitted_width", INF)) <= table.FIELD_BADGE_MAX_WIDTH
		and ready_status == null,
		"A ready card did not split its large stats and bounded READY indicators cleanly."
	)
	var ready_badge_gap := absf(ready_stats.position.z - ready_indicator.position.z) if ready_stats != null and ready_indicator != null else 0.0
	var combined_badge_half_height := (
		float(ready_stats_backing.get_meta("fitted_height", INF))
		+ float(ready_indicator_backing.get_meta("fitted_height", INF))
	) * 0.5 if ready_stats_backing != null and ready_indicator_backing != null else INF
	_expect(
		ready_badge_gap > combined_badge_half_height + 0.02,
		"A card's READY pill overlaps its attack/health pill vertically (gap %.3f, required %.3f)." % [ready_badge_gap, combined_badge_half_height + 0.02]
	)
	var adjacent_ready_root := Node3D.new()
	adjacent_ready_root.position.x = 1.72
	adjacent_ready_root.scale = Vector3.ONE * table.PLATED_CARD_SCALE
	table.card_layer.add_child(adjacent_ready_root)
	table._add_stat_badge(adjacent_ready_root, ready_badge_unit, "player")
	var adjacent_backing := adjacent_ready_root.find_child("ReadyStatusBacking", true, false) as Sprite3D
	var first_ready_width: float = float(ready_indicator_backing.get_meta("fitted_width", INF)) * table.PLATED_CARD_SCALE if ready_indicator_backing != null else INF
	var adjacent_ready_width: float = float(adjacent_backing.get_meta("fitted_width", INF)) * table.PLATED_CARD_SCALE if adjacent_backing != null else INF
	_expect(
		(first_ready_width + adjacent_ready_width) * 0.5 < adjacent_ready_root.position.x - 0.08,
		"Two adjacent plated cards let their READY pills overlap."
	)
	adjacent_ready_root.queue_free()
	ready_badge_root.queue_free()
	table.state.phase = "opponent_turn"
	table.animation_busy = true
	table._handle_card_click(prep_card)
	_expect(
		String(table.selected_ref.get("card_id", "")) == String(moved_unit.card_id)
		and table.action_panel.visible,
		"A card could not be opened for inspection while the opponent turn animation was running."
	)
	var inspection_buttons: Array[Node] = table.action_list.find_children("*", "Button", true, false)
	_expect(inspection_buttons.size() == 1 and String(inspection_buttons[0].name) == "LivingTableInfoClose", "Opponent-turn inspection exposed an actionable card control.")
	table.selected_ref = {}
	table._refresh_action_panel()
	table.animation_busy = false
	table.state.phase = "player_main"
	var floating_start_position := floating_art.position if floating_art != null else Vector3.ZERO
	var floating_start_rotation := floating_art.rotation if floating_art != null else Vector3.ZERO
	var floating_start_texture := (floating_art.material_override as StandardMaterial3D).albedo_texture if floating_art != null else null
	var field_face_viewport := table.texture_viewports.find_child("PrototypeFullCardFaceViewport_spicy_hot_honey_bee_NoArt", false, false) as SubViewport
	var field_card_art := field_face_viewport.find_child("CardArtwork", true, false) as TextureRect if field_face_viewport != null else null
	_expect(floating_art != null and is_equal_approx(floating_art.position.y, table.FLOATING_ART_HEIGHT) and floating_art.position.y < 0.75, "Field artwork was not lowered closer to its physical card.")
	_expect(stat_backing != null and stat_backing.texture != null and stat_backing.pixel_size < 0.004, "Field-card attack and health values do not have their compact rounded backing.")
	_expect(field_card_art != null and not field_card_art.visible, "A field card duplicated its artwork beneath the floating image.")
	await create_timer(0.08).timeout
	var floating_advanced_texture := (floating_art.material_override as StandardMaterial3D).albedo_texture if floating_art != null else null
	_expect(floating_art != null and floating_art.position.is_equal_approx(floating_start_position) and floating_art.rotation.is_equal_approx(floating_start_rotation), "Field artwork still bounced or swayed instead of staying fixed above the card.")
	_expect(floating_start_texture != null and floating_advanced_texture != floating_start_texture, "Field artwork did not continue looping its authored animation frames.")
	var prep_position: Vector3 = prep_card.position
	table.state.opponent.prep.erase(moved_unit)
	table.state.opponent.plated.append(moved_unit)
	table.service._queue_animation_event(table.state, "move", {
		"side": "opponent",
		"instance_id": int(moved_unit.instance_id),
		"card_id": String(moved_unit.card_id),
		"from": "prep",
		"to": "plated"
	}, table.service._next_animation_group(table.state))
	await table._drain_animation_event_queue()
	var plated_card: Node3D = table._card_node_for_instance(int(moved_unit.instance_id))
	_expect(plated_card != null and plated_card.position.z > prep_position.z + 1.0, "The opponent card did not animate from Prep into its Plated position.")
	moved_unit.ready = true
	table.service._set_defense_positions(table.state, "opponent")
	var defense_position_events: Array[Dictionary] = table.service.take_animation_events(table.state)
	_expect(defense_position_events.size() == 1, "Entering Defense did not queue exactly one position-change animation.")
	var defense_landing_height := plated_card.position.y if plated_card != null else 0.0
	table.animation_busy = true
	var defense_animation_duration: float = table._start_defense_position_animation(defense_position_events[0]) if not defense_position_events.is_empty() else 0.0
	await create_timer(0.12).timeout
	_expect(plated_card != null and plated_card.position.y > defense_landing_height + 0.1, "A card entering Defense did not lift into the air before turning.")
	await create_timer(maxf(0.0, defense_animation_duration - 0.12)).timeout
	table.animation_busy = false
	_expect(plated_card != null and is_equal_approx(plated_card.rotation_degrees.y, 90.0), "A card entering Defense did not rotate 90 degrees to the left.")
	table._render_match()
	plated_card = table._card_node_for_instance(int(moved_unit.instance_id))
	var defense_status := plated_card.find_child("Status", true, false) as Label3D if plated_card != null else null
	var defense_status_backing := plated_card.find_child("StatusBacking", true, false) as Sprite3D if plated_card != null else null
	var defense_stat_backing := plated_card.find_child("StatsBacking", true, false) as Sprite3D if plated_card != null else null
	_expect(defense_status != null and defense_status.text == "DEFENDING", "A Defending card did not render its separate status badge.")
	_expect(
		defense_status_backing != null
		and is_equal_approx(defense_status_backing.global_position.x, plated_card.global_position.x)
		and defense_status_backing.global_position.z > plated_card.global_position.z,
		"The Defending status was not centered along the card edge closest to the player."
	)
	_expect(
		defense_status_backing != null
		and defense_stat_backing != null
		and defense_status_backing.scale.x > defense_stat_backing.scale.x,
		"Field status backings did not resize to fit their text."
	)
	table.service._start_turn(table.state, "opponent", false)
	table.animation_busy = true
	await table._drain_animation_event_queue()
	table.animation_busy = false
	_expect(plated_card != null and is_zero_approx(plated_card.rotation_degrees.y), "A Defending card did not rotate upright at the start of its turn.")
	var removal_art := plated_card.find_child("FloatingArt", true, false) as MeshInstance3D if plated_card != null else null
	var removal_art_material := removal_art.material_override as StandardMaterial3D if removal_art != null else null
	var removal_duration: float = table._start_removal_event_animation({
		"type": "destroy",
		"instance_id": int(moved_unit.instance_id)
	})
	await create_timer(removal_duration * 0.55).timeout
	_expect(
		removal_art != null
		and removal_art.scale.length() < Vector3.ONE.length() * 0.7
		and removal_art_material != null
		and removal_art_material.albedo_color.a < 0.7,
		"A destroyed card's floating artwork did not shrink and fade with the physical card."
	)
	await create_timer(removal_duration * 0.5).timeout

	# Dragging an attacker onto the opposing chef must restore its board pose,
	# then animate straight forward instead of lunging from the drop corner.
	var direct_attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "plated", "player")
	direct_attacker.ready = true
	direct_attacker.table_slot = 0
	table.state.player.prep = []
	table.state.player.plated = [direct_attacker]
	table.state.opponent.prep = []
	table.state.opponent.plated = []
	table.state.opponent.life = 20
	table.state.player.turns_started = 2
	table.state.phase = "player_main"
	table.state.game_over = false
	table.state.selected_attacker = -1
	table.service.clear_animation_events(table.state)
	table._render_match()
	var direct_attacker_card: Node3D = table._card_node_for_instance(int(direct_attacker.instance_id))
	var attack_origin := direct_attacker_card.position if direct_attacker_card != null else Vector3.ZERO
	if direct_attacker_card != null:
		table.pressed_card = direct_attacker_card
		table.dragging = true
		table.drag_original_position = attack_origin
		table.drag_original_rotation = direct_attacker_card.rotation
		direct_attacker_card.position = Vector3(table.opponent_chef.position.x, table.DRAG_Y, table.opponent_chef.position.z)
		direct_attacker_card.rotation = Vector3.ZERO
		direct_attacker_card.scale = Vector3.ONE
		table._finish_drag(table.opponent_chef.position)
		_expect(direct_attacker_card.position.is_equal_approx(attack_origin), "A chef-targeted drag attack did not return to its board slot before animating.")
		await create_timer(0.12).timeout
		_expect(bool(table.animation_busy) and direct_attacker_card.position.z < attack_origin.z - 0.2 and absf(direct_attacker_card.position.x - attack_origin.x) < 0.05, "A chef-targeted attack did not animate straight forward from its board slot.")
		await create_timer(1.0).timeout
		_expect(not bool(table.animation_busy) and int(table.state.opponent.life) == 19, "The forward chef-attack animation did not resolve combat cleanly.")
	else:
		_expect(false, "The direct-attack regression card was not rendered on the Living Table.")

	var swap_prep: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_hot_honey_bee"), "prep", "player")
	swap_prep.table_slot = 1
	var swap_plated: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("hearty_bagver"), "plated", "player")
	swap_plated.table_slot = 0
	table.state.player.prep = [swap_prep]
	table.state.player.plated = [swap_plated]
	table.state.player.zone_move_used = false
	table.state.phase = "player_main"
	table.state.game_over = false
	table.service.clear_animation_events(table.state)
	table._render_match()
	var swap_animations_before: int = table.swap_move_animation_count
	table.service.move_unit(table.state, int(swap_prep.instance_id), "plated", 0)
	await table._drain_animation_event_queue()
	_expect(
		table.swap_move_animation_count == swap_animations_before + 1
		and not table.service._find_unit_in_zone(table.state.player, "plated", int(swap_prep.instance_id)).is_empty()
		and not table.service._find_unit_in_zone(table.state.player, "prep", int(swap_plated.instance_id)).is_empty(),
		"An occupied-slot move did not use the dedicated crossing swap animation."
	)

	table.state.game_over = true
	table.state.winner = "player"
	table.state.phase = "game_over"
	table.state.opponent.life = 0
	table.animation_busy = false
	table._render_match()
	for unused_wait in range(25):
		if bool(table.outcome_sequence_played):
			break
		await create_timer(0.1).timeout
	_expect(bool(table.outcome_sequence_played), "The victory presentation did not complete.")
	await create_timer(0.35).timeout
	_expect(table.prompt_panel.visible, "The debug match did not restore its post-sequence match-over controls.")
	table.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("Living Table pacing smoke test passed (silent presentation).")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _has_lofi_outline(mesh: MeshInstance3D) -> bool:
	if mesh == null or mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
		return false
	var material := mesh.get_active_material(0) as BaseMaterial3D
	if material == null or not material.next_pass is ShaderMaterial:
		return false
	var shader_material := material.next_pass as ShaderMaterial
	return shader_material.shader != null and shader_material.shader.resource_path.ends_with("lofi_outline.gdshader")
