extends SceneTree

## Run with Godot --headless --path . --script scripts/PeachSodaBattleSmokeTest.gd.
## Exercises live input and fallback behavior without editing any art files/save.
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CAST := preload("res://scripts/ui/PeachSodaCast.gd")
const BACKDROP := preload("res://scripts/ui/PeachSodaBattleBackdrop.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const BUTTON_FACE := preload("res://scripts/ui/BattleAngularButtonFace.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = await _make_table(true, "pip")
	if table == null:
		quit(1)
		return
	_check_cast_resolution(table)
	_check_scene_and_slots(table)
	await _check_card_art_and_shared_frames(table)
	_check_shared_buttons_and_contrast(table)
	await _check_seated_actor_inputs(table)
	await _check_table_coverage_after_resize(table)
	await _dispose_table(table)

	# Same playable interaction at a second aspect ratio after opting out of all
	# generated rival art. This catches a visual kill switch disabling targeting.
	root.size = Vector2i(1280, 720)
	var fallback_table = await _make_table(false, "ellis")
	if fallback_table == null:
		quit(1)
		return
	await _check_art_disabled_inputs(fallback_table)
	await _check_table_coverage_after_resize(fallback_table)
	await _dispose_table(fallback_table)

	# The tightly cropped supplied portrait rests higher than the generated cast.
	# Its low hand and the far mat must both sit over wood at either aspect ratio.
	var mina_table = await _make_table(false, "mina")
	if mina_table == null:
		quit(1)
		return
	await _check_table_coverage_after_resize(mina_table)
	await _dispose_table(mina_table)
	if failures.is_empty():
		print("PEACH_SODA_BATTLE_SMOKE_TEST_OK")
		quit(0)
	else:
		print("PEACH_SODA_BATTLE_SMOKE_TEST_FAILED: %d checks" % failures.size())
		quit(1)


func _make_table(generated: bool, id: String):
	var table = TABLE_SCENE.instantiate()
	if not table.has_method("configure_battle_preferences"):
		_check(false, "Battle scene script did not load; import the project before running this test.")
		table.free()
		return null
	table.use_generated_opponent_art = generated
	table.configured_opponent_name = "Saved Rival"
	table.configured_seed = 8128
	table.configured_match_context = {
		"rival_portrait_id": "npc2", "rival_cast_id": id,
		"rival_display_name": CAST.name_for(id), "opponent_affinity": "hearty",
	}
	table.configure_battle_preferences("fast", 1.0, true, false)
	root.add_child(table)
	await _settle()
	if is_instance_valid(table.turn_banner_panel):
		table.turn_banner_panel.hide()
	return table


func _check_cast_resolution(table) -> void:
	var original_context: Dictionary = table.configured_match_context.duplicate(true)
	var original_rng_state: int = table.service.rng.state
	var distinct: Dictionary = {}
	for id in CAST.ids():
		table.configured_match_context = {
			"rival_portrait_id": "npc1", "rival_cast_id": id,
			"rival_display_name": CAST.name_for(id),
		}
		_check(table._rival_cast_id() == id, "Saved legacy identity overrode explicit cast %s." % id)
		_check(table._rival_display_name() == CAST.name_for(id), "Display name disagreed with cast %s." % id)
		_check(CAST.texture_for(id) != null and CAST.profile_texture(id) != null, "Missing usable art/fallback for %s." % id)
		distinct[table._rival_cast_id()] = true
	_check(distinct.size() == 9 and distinct.has("mina"), "The live table lost supplied Mina or one of the eight working cast members.")
	var regular_ids: Dictionary = {}
	for seed_value in range(-6, 7):
		var first := CAST.resolve_id("npc2", "Saved Rival", seed_value)
		_check(first == CAST.resolve_id("npc2", "Saved Rival", seed_value), "Legacy cast mapping changed between calls.")
		regular_ids[first] = true
	_check(regular_ids.size() == 6, "Seeded legacy encounters lost regular cast variety.")
	_check(table.service.rng.state == original_rng_state, "Presentation selection consumed combat RNG.")
	table.configured_match_context = original_context
	_check(CAST.texture_for("removed_working_art") == CAST.FALLBACK, "An unavailable cast asset did not provide a safe fallback.")
	_check(CAST.texture_for("pip", false) == CAST.FALLBACK, "Disabled art did not use the native fallback.")


func _check_scene_and_slots(table) -> void:
	var backdrop := table.get_node("BattleBackdrop") as Control
	_check(backdrop != null and backdrop.get_script() == BACKDROP, "The layered supplied battle backdrop did not mount.")
	_check(backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The supplied room blocks live battle input.")
	_check(table.world_viewport.transparent_bg, "The 3D viewport hides the supplied room.")
	_check(table.service.PREP_SLOTS == 3 and table.service.PLATED_SLOTS == 2, "Battle capacity changed during the visual overhaul.")
	# Project each existing playable slot through the actual camera, then raycast
	# back through input mapping. Ten distinct slots must remain reachable.
	var hits: Dictionary = {}
	for side in ["player", "opponent"]:
		for zone in ["prep", "plated"]:
			var capacity := 3 if zone == "prep" else 2
			for index in range(capacity):
				var zone_id: String = "%s_%s" % [side, zone]
				var world_point: Vector3 = table._slot_world_position(zone_id, index)
				var screen_point: Vector2 = table._world_to_container(world_point)
				var ray_point: Variant = table._mouse_to_table(screen_point)
				_check(ray_point != null, "Camera ray missed %s slot %d." % [zone_id, index])
				if ray_point == null:
					continue
				var hit: Dictionary = table._slot_at_point(ray_point)
				_check(String(hit.get("zone", "")) == zone_id and int(hit.get("slot", -1)) == index, "Camera/input mapping lost %s slot %d." % [zone_id, index])
				hits["%s:%s" % [hit.get("zone", ""), hit.get("slot", -1)]] = true
	_check(hits.size() == 10, "Some of the ten battle slot targets overlap.")


func _check_table_coverage_after_resize(table) -> void:
	# Resize the same live scene, rather than rebuilding a correctly sized room.
	# This catches a backdrop that keeps its initial horizon after the board moves.
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = output_size
		await _settle()
		await _settle()
		_check_scene_and_slots(table)
		_check_table_coverage(table)


func _check_table_coverage(table) -> void:
	var backdrop := table.get_node("BattleBackdrop") as Control
	var horizon: Variant = backdrop.get("table_horizon")
	_check(horizon != null, "Battle backdrop does not expose its live table edge.")
	if horizon == null:
		return
	var backdrop_transform := backdrop.get_global_transform_with_canvas()
	var local_horizon := float(horizon) * backdrop.size.y / BACKDROP.DESIGN_SIZE.y
	var horizon_global := backdrop_transform * Vector2(0, local_horizon)
	var scaled_margin := 12.0 * backdrop.size.y / BACKDROP.DESIGN_SIZE.y * backdrop_transform.y.length()
	var mat := table.find_child("InsetPlaymat", true, false) as MeshInstance3D
	_check(mat != null, "Opponent mat is missing during table coverage checks.")
	if mat == null:
		return
	var outline: PackedVector2Array = mat.get_meta("playmat_outline", PackedVector2Array())
	_check(not outline.is_empty(), "Opponent mat has no outline to check against the visible table.")
	var top_y := mat.get_aabb().end.y
	var container_transform: Transform2D = table.viewport_container.get_global_transform_with_canvas()
	var context := "%s at %s" % [table._rival_cast_id(), root.size]
	for point in outline:
		var mat_screen: Vector2 = table._world_to_container(mat.to_global(Vector3(point.x, top_y, point.y)))
		var mat_global := container_transform * mat_screen
		_check(mat_global.y - horizon_global.y >= scaled_margin, "The table ends before the opponent mat or leaves no wood margin for " + context + ".")
	if is_instance_valid(table.rival_at_table) and table.rival_at_table.is_visible_in_tree():
		var actor: Control = table.rival_at_table
		var cast_id: String = table._rival_cast_id()
		var arm_local := Vector2(actor.size.x * 0.5, actor.size.y * CAST.resting_arm_y_for(cast_id) / CAST.canvas_for(cast_id).y)
		var arm_global := actor.get_global_transform_with_canvas() * arm_local
		_check(arm_global.y - horizon_global.y >= scaled_margin * 0.5, "The seated rival's resting hands extend beyond the table for " + context + ".")
		var shoulder_global := actor.get_global_transform_with_canvas() * Vector2(actor.size.x * 0.5, actor.size.y * 0.35)
		_check(horizon_global.y > shoulder_global.y, "The table edge rose into the rival's upper body for " + context + ".")


func _check_card_art_and_shared_frames(table) -> void:
	var card_id := "spicy_wasabi_wasp"
	var original: Dictionary = table.service.card(card_id).duplicate(true)
	table._face_material(card_id, true)
	await _settle()
	var face := table.texture_viewports.find_child("PrototypeFullCardFace_" + card_id, true, false) as CardFace
	_check(face != null, "Battle did not build the authored card face.")
	if face == null:
		return
	var runtime := face._runtime_face
	var art := runtime.find_child("CardArtwork", true, false) as TextureRect
	_check(runtime.peach_soda_frame, "Live battle card did not opt into Soft Print.")
	_check(art != null and art.texture != null and art.texture.resource_path.contains("/cards/art/" + card_id + "/"), "Soft Print replaced the original card illustration.")
	_check(art != null and art.material == null and art.modulate.is_equal_approx(Color.WHITE), "Soft Print recolors the source card illustration.")
	_check(runtime.accent_color.is_equal_approx(PALETTE.INGREDIENT_SPICY), "Peach Soda replaced the card affiliation band.")
	_check(table.service.card(card_id) == original, "Battle frame opt-in mutated the shared card catalog.")
	var other_screen_card := CARD_FACE.new()
	other_screen_card.configure(original, "white", false)
	root.add_child(other_screen_card)
	_check(other_screen_card._runtime_face.peach_soda_frame, "A non-battle card did not use the shared Soft Print frame.")
	_check(table.service.card(card_id) == original, "The shared frame default mutated the authoritative card catalog.")
	other_screen_card.queue_free()
	var legacy_data := original.duplicate(true)
	legacy_data["peach_soda_frame"] = false
	var legacy_comparison := CARD_FACE.new()
	legacy_comparison.configure(legacy_data, "white", false)
	root.add_child(legacy_comparison)
	_check(not legacy_comparison._runtime_face.peach_soda_frame, "An explicit legacy comparison frame can no longer be selected.")
	legacy_comparison.queue_free()
	await _settle()


func _check_shared_buttons_and_contrast(table) -> void:
	for button in [table.end_turn_button, table.settings_button, table.battle_log_button]:
		var face = button.get_node_or_null("BattleAngularButtonFace")
		_check(face != null and face.peach_soda_style, "Live battle button did not opt into Peach Soda.")
		if face == null:
			continue
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			var foreground: Color = face.text_color_for_state(state_name)
			var background: Color = face.fill_color_for_state(state_name)
			_check(_contrast(foreground, background) >= 4.5, "%s %s text contrast fell below 4.5:1." % [button.name, state_name])
	var other_screen_button := Button.new()
	var other_screen_face := BUTTON_FACE.new()
	other_screen_face.configure(other_screen_button, "primary")
	other_screen_button.add_child(other_screen_face)
	_check(other_screen_face.peach_soda_style, "A non-battle button did not use the shared Peach Soda palette.")
	_check(other_screen_face.fill_color_for_state("normal").is_equal_approx(PALETTE.PEACH_TEAL), "The shared primary action lost its teal fill.")
	other_screen_button.free()


func _check_seated_actor_inputs(table) -> void:
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1)
	var blocker := _unit(table, "opponent", "hearty_bagver", "plated", 1)
	_stage_attack(table, attacker, [blocker], ["hearty_bagver", "item_wooden_spoon", "spicy_wasabi_wasp"])
	await _settle()
	_check(table.rival_at_table.is_visible_in_tree(), "Generated rival did not appear with working art enabled.")
	_check(_visible_hand_count(table, "player") == table.state.player.hand.size(), "Rendered player hand count disagrees with live cards.")
	_check(table.rival_hand_label.text == "3 cards in hand", "Rival hand counter is baked into the illustration.")
	_check(table.opponent_profile_name.text == "Pip", "Profile name does not match the seated rival.")
	var face_point: Vector2 = _actor_point(table)
	_check(table._screen_hits_opponent_hand(face_point) and table._screen_hits_opponent_chef(face_point), "The visible seated rival cannot be targeted while holding cards.")
	_check(table._pick_card(face_point) == null, "Hidden card geometry intercepts a click on the seated rival.")
	var hidden_back := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_check(hidden_back != null and not hidden_back.is_visible_in_tree(), "Generated rival has duplicate live card backs drawn over their hand.")
	await _select_attacker(table, attacker)
	var before := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _settle()
	_check(int(table.state.opponent.life) == before and "clear all opposing Plated cards" in String(table.state.message), "Clicking the portrait bypassed Plated blockers.")
	table._dismiss_invalid_action()

	_stage_attack(table, attacker, [], ["hearty_bagver"])
	await _select_attacker(table, attacker)
	_check(table.rival_hand_label.text == "1 card in hand", "Live hand count did not update to one card.")
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "A valid actor click did not resolve a direct attack.")

	_stage_attack(table, attacker, [], [])
	await _select_attacker(table, attacker)
	_check(table.rival_hand_label.text == "0 cards in hand", "Empty-hand count did not update.")
	_check(not table._screen_hits_opponent_hand(face_point) and table._screen_hits_opponent_chef(face_point), "An empty rival hand removed the seated Chef target or kept a phantom hand.")
	_check(table.find_child("OpponentHandCard_0", true, false) == null, "Empty hand retained hidden target cards.")
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "The empty-handed rival is no longer clickable for direct attacks.")


func _check_art_disabled_inputs(table) -> void:
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1)
	_stage_attack(table, attacker, [], ["hearty_bagver", "item_wooden_spoon"])
	await _settle()
	_check(not table.rival_at_table.visible, "Art kill switch left a generated figure visible.")
	_check(table._route_rival_profile_portrait("ellis") == CAST.FALLBACK, "Disabled generated profile does not use the native fallback.")
	_check(not table.rival_hand_label.visible, "Hidden figure left its floating hand label behind.")
	_check(_visible_hand_count(table, "opponent") == table.state.opponent.hand.size(), "Art-free rival hand count does not match its live card backs.")
	var back := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_check(back != null and back.is_visible_in_tree(), "Removing generated art also removed the actual rival hand backs.")
	if back == null:
		return
	var hand_point: Vector2 = table._card_screen_rect(back).get_center()
	_check(table._screen_hits_opponent_hand(hand_point), "Fallback hand is visible but cannot be clicked.")
	await _select_attacker(table, attacker)
	var before := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "Disabling generated art broke direct attacks through the live hand.")
	_stage_attack(table, attacker, [], [])
	await _select_attacker(table, attacker)
	var profile_point: Vector2 = table.viewport_container.get_global_transform_with_canvas().affine_inverse() * table.opponent_profile_badge.get_global_rect().get_center()
	_check(table._screen_hits_opponent_chef(profile_point), "Fallback profile is not an empty-hand Chef target.")
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(profile_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "Art-free empty-hand profile click failed to resolve combat.")


func _stage_attack(table, attacker: Dictionary, blockers: Array, hand: Array) -> void:
	attacker.ready = true
	table.state.player.plated = [attacker]
	table.state.player.prep = []
	table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon"]
	table.state.opponent.plated = blockers
	table.state.opponent.prep = []
	table.state.opponent.hand = hand
	table.state.opponent.life = 40
	table.state.opponent.max_life = 40
	table.state.phase = "player_main"
	table.state.turn = 3
	table.state.first_player = "player"
	table.state.player.turns_started = 2
	table.state.selected_attacker = -1
	table._render_match()


func _select_attacker(table, attacker: Dictionary) -> void:
	await _settle()
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await _settle()


func _actor_point(table) -> Vector2:
	# Center of the visible figure's head/upper torso, not its private hitbox.
	var screen_point: Vector2 = table.rival_at_table.global_position + table.rival_at_table.size * Vector2(0.5, 0.31)
	return table.viewport_container.get_global_transform_with_canvas().affine_inverse() * screen_point


func _visible_hand_count(table, side: String) -> int:
	var count := 0
	for card in table.card_layer.get_children():
		if not card.is_queued_for_deletion() and String(card.get_meta("kind", "")) == "hand" and String(card.get_meta("side", "")) == side and card.is_visible_in_tree():
			count += 1
	return count


func _unit(table, side: String, id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	return unit


func _left_click(point: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	return event


func _settle() -> void:
	await process_frame
	await process_frame


func _wait_for_attack(table) -> void:
	await _settle()
	for _step in range(60):
		if not table.animation_busy:
			return
		await create_timer(0.05).timeout
	_check(false, "Direct attack did not finish within three seconds.")


func _dispose_table(table) -> void:
	for node in table.find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	# Allow the audio server to release the attack MP3 playback before freeing
	# the scene; otherwise headless runs report a playback resource at shutdown.
	await create_timer(0.15).timeout
	table.queue_free()
	await _settle()


func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)


func _luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error(message)
