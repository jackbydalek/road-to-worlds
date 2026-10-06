extends "res://scripts/PeachSodaBattleSmokeTest.gd"

## Live integration check for the user-supplied Mina GIF. Reuses the existing
## battle fixture and input helpers without changing production state or art.
var completed_cases: Array[String] = []


func _run() -> void:
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = output_size
		root.set_meta("reduced_motion", false)
		var table = await _make_table(false, "mina")
		if table == null:
			quit(1)
			return
		_check_mina_catalog_and_placement(table)
		_check_scene_and_slots(table)
		await _check_card_art_and_shared_frames(table)
		await _check_mina_animation(table)
		await _check_mina_targeting(table)
		await _dispose_table(table)
	_check(completed_cases.size() == 6, "Some supplied Mina checks did not finish: " + str(completed_cases))
	print("SUPPLIED_MINA_SMOKE_TEST_%s: %d completed cases; %d failures" % ["OK" if failures.is_empty() else "FAILED", completed_cases.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_mina_catalog_and_placement(table) -> void:
	_check(not table.use_generated_opponent_art, "The Mina fixture did not disable generated rival art.")
	_check(CAST.is_cast_id("mina") and CAST.name_for("mina") == "Mina", "The supplied person is not registered as Mina.")
	_check(CAST.has_seated_art("mina", false), "The generated-art switch also hides supplied Mina.")
	_check(not CAST.has_generated_art("mina", true), "The supplied GIF is incorrectly classified as generated art.")
	var frames: Array = CAST.frame_textures("mina")
	var durations: Array = CAST.frame_durations("mina")
	_check(frames.size() == 6 and durations.size() == 6, "Mina lost the supplied GIF's six animation frames.")
	for duration in durations:
		_check(is_equal_approx(float(duration), 0.07), "Mina changed a supplied 70ms frame duration.")
	var source: Texture2D = CAST.texture_for("mina", false)
	_check(source != null and source != CAST.FALLBACK, "Disabling generated art replaces supplied Mina with a fallback.")
	_check(source != null and not source.resource_path.contains("/generated/"), "Mina is still loaded from generated working art.")
	if source == null or frames.is_empty():
		return
	_check(source == frames[0], "Mina's static source does not match her first supplied animation frame.")
	var canvas: Vector2 = CAST.canvas_for("mina")
	_check(canvas == Vector2(source.get_size()), "Mina's placement canvas disagrees with the supplied artwork.")
	_check(canvas == Vector2(701, 628) and is_equal_approx(CAST.resting_arm_y_for("mina"), 610.0), "Mina lost the supplied frame dimensions or resting-arm anchor.")
	_check(CAST.resting_arm_y_for("mina") > 0 and CAST.resting_arm_y_for("mina") <= canvas.y, "Mina has no valid resting-arm placement anchor.")
	for frame in frames:
		var frame_image: Image = frame.get_image()
		_check(frame_image != null, "A supplied Mina frame could not be read.")
		if frame_image == null:
			continue
		_check(Vector2(frame_image.get_size()) == source.get_size(), "Mina changes canvas size during animation.")
		_check(frame_image.get_pixel(0, 0).a == 0 and frame_image.get_pixel(frame_image.get_width() - 1, 0).a == 0, "Mina's supplied transparency became a filled rectangle.")
		_check(frame_image.get_used_rect().has_area(), "Mina's animation includes an empty frame.")
	var portrait: Texture2D = CAST.profile_texture("mina", false)
	_check(portrait is AtlasTexture and portrait != CAST.FALLBACK, "Mina's profile is not cropped from supplied art.")
	if not portrait is AtlasTexture:
		return
	if portrait is AtlasTexture:
		_check(portrait.atlas == source, "Mina's profile uses a different person's art.")
		_check(portrait.region.has_area() and Rect2(Vector2.ZERO, canvas).encloses(portrait.region), "Mina's profile crop extends outside her supplied frame.")
		_check(portrait.region == Rect2(130, 90, 335, 335), "Mina's profile no longer uses her supplied face crop.")
	var live_profile: Texture2D = table._route_rival_profile_portrait("mina")
	_check(live_profile is AtlasTexture and live_profile.atlas == source and live_profile.region == portrait.region, "The actual battle profile does not use Mina's supplied crop.")
	_check(table.opponent_profile_name.text == "Mina", "The visible opponent profile has the wrong name.")
	var actor: TextureRect = table.rival_at_table
	_check(actor != null and actor.is_visible_in_tree(), "Supplied Mina does not appear at the table with generated art disabled.")
	if actor != null:
		_check(actor.get_script() != null and actor.get_script().resource_path == "res://scripts/ui/SeatedRivalPortrait.gd", "Mina bypasses the shared animated seated portrait.")
		_check(actor.get_meta("asset_origin", "") == "user_supplied_animation" and not actor.has_meta("generated_art_id"), "Mina's live artwork has incorrect provenance metadata.")
		_check(actor.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Mina's artwork consumes live battle pointer events.")
		_check(actor.modulate.is_equal_approx(Color.WHITE), "Mina's supplied local colors are tinted.")
		_check(actor.material == null, "Mina's authored navy contour was replaced by a silhouette effect.")
		var badge := table.find_child("OpponentProfileBadgePortrait", true, false) as TextureRect
		_check(badge != null and badge.material == null, "Portrait styling leaked into Mina's HUD avatar.")
		_check(table.get_viewport_rect().encloses(actor.get_global_rect()), "Mina's visible art is clipped at the capture size.")
		# The native actor rect can fit while the 3D mat still hides most of the
		# supplied resting hand. Compare that source point to the real mat edge.
		var mat := table.find_child("InsetPlaymat", true, false) as MeshInstance3D
		_check(mat != null and mat.mesh != null, "The battle playmat geometry is unavailable for Mina's occlusion check.")
		if mat != null and mat.mesh != null:
			var mat_bounds: AABB = mat.mesh.get_aabb()
			var edge_world: Vector3 = mat.global_transform * Vector3(mat_bounds.get_center().x, mat_bounds.end.y, mat_bounds.position.z)
			var edge_local: Vector2 = table._world_to_container(edge_world)
			var edge_global: Vector2 = table.viewport_container.get_global_transform_with_canvas() * edge_local
			var hand_bottom: Vector2 = actor.global_position + actor.size * Vector2(560.0 / canvas.x, 614.0 / canvas.y)
			_check(hand_bottom.y <= edge_global.y + 2.0, "The 3D mat hides Mina's supplied resting hand.")
	completed_cases.append("catalog-and-placement-" + str(root.size))


func _check_mina_animation(table) -> void:
	var actor = table.rival_at_table
	if actor == null or not actor.has_method("set_reduced_motion"):
		_check(false, "Mina has no reduced-motion animation control.")
		return
	table.configure_battle_preferences("fast", 1.0, false, false)
	var observed_frames: Dictionary = {}
	for sample in 14:
		observed_frames[int(actor.frame_index)] = true
		await create_timer(0.035).timeout
	_check(observed_frames.size() > 1, "Mina does not animate during the real battle.")
	_check(CAST.frame_textures("mina").has(actor.texture), "Mina's displayed animation frame is not from the supplied GIF.")
	table.configure_battle_preferences("fast", 1.0, true, false)
	await _settle()
	var frozen_frame: int = actor.frame_index
	var frozen_elapsed: float = actor.elapsed
	var frozen_texture: Texture2D = actor.texture
	await create_timer(0.25).timeout
	_check(actor.frame_index == frozen_frame and actor.texture == frozen_texture and is_equal_approx(actor.elapsed, frozen_elapsed), "Reduced motion does not stop Mina's animation.")
	_check(frozen_frame == 0 and not actor.is_processing(), "Reduced motion does not hold Mina's first supplied frame.")
	_check(actor.is_visible_in_tree() and actor.texture != CAST.FALLBACK, "Reduced motion removes Mina instead of holding a supplied frame.")
	completed_cases.append("animation-" + str(root.size))


func _check_mina_targeting(table) -> void:
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1)
	var blocker := _unit(table, "opponent", "hearty_bagver", "plated", 1)
	_stage_attack(table, attacker, [blocker], ["hearty_bagver", "item_wooden_spoon"])
	await _settle()
	var face_point: Vector2 = _actor_point(table)
	_check(table._screen_hits_opponent_chef(face_point) and table._screen_hits_opponent_hand(face_point), "Supplied Mina's seated face/hand target is missing.")
	_check(table._pick_card(face_point) == null, "Hidden hand card geometry intercepts Mina's visible face.")
	_check(not table.rival_hand_label.visible and table.rival_hand_label.text == "2 cards in hand", "Mina's optional hand count is stale or visible before enabling Board Info.")
	table.configure_battle_preferences("fast", 1.0, true, true)
	_check(table.rival_hand_label.is_visible_in_tree() and table.rival_hand_label.text == "2 cards in hand", "Board Info did not reveal Mina's live hand count with generated art disabled.")
	table.configure_battle_preferences("fast", 1.0, true, false)
	_check(not table.rival_hand_label.visible, "Disabling Board Info left Mina's hand-count plaque visible.")
	var duplicate_hand := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_check(duplicate_hand != null and not duplicate_hand.is_visible_in_tree(), "Duplicate card backs draw over supplied Mina.")
	await _select_attacker(table, attacker)
	var before := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _settle()
	_check(int(table.state.opponent.life) == before and "clear all opposing Plated cards" in String(table.state.message), "Mina's portrait target bypasses opposing Plated blockers.")
	table._dismiss_invalid_action()
	_stage_attack(table, attacker, [], ["hearty_bagver"])
	await _select_attacker(table, attacker)
	_check(table.rival_hand_label.text == "1 card in hand", "Mina's hand label does not update after a card leaves.")
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "Clicking Mina's live hand target no longer resolves a direct attack.")
	_stage_attack(table, attacker, [], [])
	await _select_attacker(table, attacker)
	_check(table.rival_hand_label.text == "0 cards in hand" and not table._screen_hits_opponent_hand(face_point), "Mina retains a phantom hand target after her hand empties.")
	_check(table._screen_hits_opponent_chef(face_point), "Mina loses her face target when her hand empties.")
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(face_point))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "Empty-handed Mina no longer receives a valid direct attack.")
	completed_cases.append("targeting-" + str(root.size))
