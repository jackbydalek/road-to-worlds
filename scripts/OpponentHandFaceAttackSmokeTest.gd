extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CAST := preload("res://scripts/ui/PeachSodaCast.gd")
const BACKDROP_SCRIPT := preload("res://scripts/ui/PeachSodaBattleBackdrop.gd")
const ATTACK_HIGHLIGHT_PREVIEW_PATH := "res://outputs/illustrated_vfx/attack_target_highlights.png"

var failed := false
var seated_cast_cases_completed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	# Use a normal attacker here. Wastabi's Stalwart bypass is tested separately
	# below, where attacking the opposing Chef through Plated blockers is legal.
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1, true)
	var blocker := _unit(table, "opponent", "hearty_bagver", "plated", 1, true)
	table.state.player.plated = [attacker]
	table.state.player.prep = []
	table.state.opponent.plated = [blocker]
	table.state.opponent.prep = []
	table.state.phase = "player_main"
	table.state.turn = 3
	table.state.first_player = "player"
	table.state.player.turns_started = 2
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame

	var hand_card := table.find_child("OpponentHandCard_0", true, false) as Node3D
	_expect(hand_card != null, "The opponent-hand attack test could not find a visible hand card.")
	if hand_card == null:
		quit(1)
		return
	var hand_click: Vector2 = table._card_screen_rect(hand_card).get_center()
	_expect(table._screen_hits_opponent_hand(hand_click), "The pictured opponent hand was not included in the face target.")

	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	var selected_attacker_card := table._card_node_for_instance(int(attacker.instance_id)) as Node3D
	var legal_blocker_card := table._card_node_for_instance(int(blocker.instance_id)) as Node3D
	_expect(
		selected_attacker_card != null
		and table.highlighted_bodies.has(selected_attacker_card.get_node("CardBody")),
		"Choosing Attack did not keep the selected attacker highlighted."
	)
	_expect(
		legal_blocker_card != null
		and table.highlighted_bodies.has(legal_blocker_card.get_node("CardBody"))
		and float(legal_blocker_card.get_node("CardBody").get_meta("highlight_pulse_amplitude", 0.0)) >= 0.7,
		"Choosing Attack did not add the stronger pulse to the legal defender."
	)
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	_expect(
		not table.highlighted_bodies.has(hand_card.get_node("CardBody")),
		"The opponent hand was highlighted even though a normal attacker could not attack directly."
	)
	var blocked_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == blocked_life
		and "clear all opposing Plated cards" in String(table.state.message),
		"Clicking the opponent hand bypassed the existing Plated blocker rule."
	)
	var stalwart_attacker := _unit(table, "player", "spicy_wasabi_wasp", "plated", 0, true)
	table.state.player.plated = [stalwart_attacker]
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	var stalwart_card := table._card_node_for_instance(int(stalwart_attacker.instance_id)) as Node3D
	var stalwart_origin: Vector3 = stalwart_card.position if stalwart_card != null else Vector3.ZERO
	await table._animate_attack_motion(int(stalwart_attacker.instance_id), -1, "chef")
	_expect(
		table.last_attack_used_stalwart_bypass
		and table.stalwart_bypass_animation_count == 1
		and float(table.last_attack_peak_height) >= stalwart_origin.y + 1.0,
		"A Stalwart direct attack through a blocker did not rise above the board."
	)
	_expect(
		stalwart_card != null and stalwart_card.position.is_equal_approx(stalwart_origin),
		"The Stalwart bypass card did not land back in its original board slot."
	)

	table.state.opponent.plated = []
	table.state.player.plated = [attacker]
	attacker.ready = true
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	hand_card = table.find_child("OpponentHandCard_0", true, false) as Node3D
	hand_click = table._card_screen_rect(hand_card).get_center()
	selected_attacker_card = table._card_node_for_instance(int(attacker.instance_id)) as Node3D
	_expect(
		selected_attacker_card != null
		and table.highlighted_bodies.has(selected_attacker_card.get_node("CardBody")),
		"The attacker highlight disappeared when a direct attack became legal."
	)
	_expect(
		table.highlighted_bodies.has(hand_card.get_node("CardBody"))
		and float(hand_card.get_node("CardBody").get_meta("highlight_pulse_amplitude", 0.0)) >= 0.7,
		"The opponent hand did not pulse as the legal direct-attack target."
	)
	if DisplayServer.get_name() != "headless":
		for tween in get_processed_tweens():
			tween.kill()
		if is_instance_valid(table.turn_banner_panel):
			table.turn_banner_panel.visible = false
		await process_frame
		var preview := root.get_texture().get_image()
		_expect(
			preview != null and preview.save_png(ProjectSettings.globalize_path(ATTACK_HIGHLIGHT_PREVIEW_PATH)) == OK,
			"Could not save the attack-target highlight preview."
		)
	var face_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(hand_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == face_life - int(attacker.attack),
		"Clicking the opponent hand did not resolve as an attack on the opposing Chef."
	)

	for unused_wait in range(30):
		if not bool(table.animation_busy):
			break
		await create_timer(0.1).timeout

	# An empty rival hand must not remove the direct-attack target. The always-visible
	# profile becomes the Chef target and receives the same cyan legal-state signal.
	table.state.opponent.hand = []
	attacker.ready = true
	table.state.selected_attacker = -1
	table._render_match()
	await process_frame
	await process_frame
	var resting_profile_scale: float = table.opponent_profile_badge.scale.x
	table.service.select_attacker(table.state, int(attacker.instance_id))
	table._render_match()
	await process_frame
	await process_frame
	_expect(table.find_child("OpponentHandCard_0", true, false) == null, "The empty-hand setup still rendered a rival hand card.")
	var profile_center_global: Vector2 = table.opponent_profile_badge.get_global_rect().get_center()
	var profile_click: Vector2 = table.viewport_container.get_global_transform_with_canvas().affine_inverse() * profile_center_global
	_expect(table._screen_hits_opponent_chef(profile_click), "The rival profile was not available as the empty-hand Chef target.")
	_expect(table.opponent_profile_badge.scale.x > resting_profile_scale, "The rival profile did not highlight above its resting size when a direct attack was legal.")
	var empty_hand_life := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(profile_click))
	await process_frame
	_expect(
		int(table.state.opponent.life) == empty_hand_life - int(attacker.attack),
		"Clicking the rival profile did not attack the opposing Chef when their hand was empty."
	)
	await _wait_for_attack(table)
	await _test_seated_cast()
	_expect(seated_cast_cases_completed == 2, "The seated-cast attack fixture did not complete both aspect ratios.")

	if failed:
		for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
			var audio_player := audio_node as AudioStreamPlayer
			audio_player.stop()
			audio_player.stream = null
		await create_timer(0.12).timeout
		table.queue_free()
		await process_frame
		await process_frame
		quit(1)
		return
	print("Opponent hand face-attack smoke test passed.")
	for audio_node in table.find_children("*", "AudioStreamPlayer", true, false):
		var audio_player := audio_node as AudioStreamPlayer
		audio_player.stop()
		audio_player.stream = null
	await create_timer(0.12).timeout
	table.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _left_click(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	return event


func _test_seated_cast() -> void:
	# A replaceable character layer sits above the native room. Exercise the
	# same player gestures against its actual composition at both aspect ratios.
	var cast_id := "pip"
	var registered_id := "peach_soda_opponent_" + cast_id
	var registered_path := _registered_art_path(registered_id)
	_expect(registered_path == CAST.asset_path(cast_id), "The cast resolver and generated-art registry disagree about Pip's texture.")
	for viewport_size in [Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		var rival = TABLE_SCENE.instantiate()
		rival.configured_opponent_name = "Pip"
		rival.configured_match_context = {"rival_cast_id": cast_id, "rival_portrait_id": cast_id}
		root.add_child(rival)
		await process_frame
		await process_frame
		rival.configure_battle_preferences("fast", 1.0, true, false)
		var attacker := _unit(rival, "player", "spicy_hot_honey_bee", "plated", 1, true)
		var blocker := _unit(rival, "opponent", "hearty_bagver", "plated", 1, true)
		rival.state.player.plated = [attacker]
		rival.state.player.prep = []
		rival.state.player.hand = []
		rival.state.opponent.plated = [blocker]
		rival.state.opponent.prep = []
		rival.state.opponent.hand = ["hearty_bagver"]
		rival.state.opponent.life = 30
		rival.state.opponent.max_life = 30
		rival.state.phase = "player_main"
		rival.state.turn = 3
		rival.state.first_player = "player"
		rival.state.player.turns_started = 2
		rival.state.selected_attacker = -1
		rival._render_match()
		await process_frame
		await process_frame
		var backdrop := rival.get_node_or_null("BattleBackdrop") as Control
		_expect(backdrop != null and not backdrop is TextureRect and backdrop.get_script() == BACKDROP_SCRIPT, "The seated cast did not use the native room backdrop.")
		var seated_rival := rival.get_node_or_null("RivalAtLocalsTable") as TextureRect
		_expect(seated_rival != null and seated_rival == rival.rival_at_table and seated_rival.visible and seated_rival.texture != null, "Pip's separate seated character layer is missing.")
		if seated_rival == null or seated_rival.texture == null:
			rival.queue_free()
			await process_frame
			continue
		_expect(seated_rival.texture.resource_path == registered_path, "The seated character does not use its registered texture.")
		_expect(String(seated_rival.get_meta("asset_origin", "")) == "generated_working_art" and String(seated_rival.get_meta("generated_art_id", "")) == registered_id, "The seated character lost its replaceable AI-art identification.")
		_expect(String(seated_rival.get_meta("replacement_registry", "")) == "res://assets/generated/manifest.json", "The seated character no longer points to its replacement registry.")
		var visible_rival_count := 0
		for texture_node in rival.find_children("*", "TextureRect", true, false):
			var texture_rect := texture_node as TextureRect
			if not texture_rect.is_visible_in_tree() or texture_rect.texture == null:
				continue
			var texture_path := texture_rect.texture.resource_path
			visible_rival_count += 1 if texture_path == registered_path else 0
			_expect(not texture_path.contains("locals-mina-scene") and not texture_path.contains("locals-room-reference"), "A former baked room or Mina image is still visible under the cast.")
		_expect(visible_rival_count == 1, "The seated rival was duplicated in the scene.")
		var hand_counter := rival.find_child("RivalLiveHandCount", true, false) as Label
		_expect(hand_counter != null and not hand_counter.visible and hand_counter.text == "1 card in hand", "Pip's optional hand counter is visible by default or does not reflect the actual one-card hand.")
		var dynamic_back := rival.find_child("OpponentHandCard_0", true, false) as Node3D
		_expect(dynamic_back != null and not dynamic_back.is_visible_in_tree(), "Pip's dynamic card backs are still drawn over her illustrated hand.")
		# This recognizable head/torso point is fixed to the visible composition,
		# independent of the implementation's private rectangle calculation.
		var face_point := Vector2(rival.viewport_container.size.x * 0.5, rival.viewport_container.size.y * 0.12)
		_expect(rival._reference_mina_rect().has_point(face_point), "The responsive layout moved Pip's attack target away from her visible figure at %s." % viewport_size)
		_expect(rival._screen_hits_opponent_hand(face_point) and rival._screen_hits_opponent_chef(face_point), "Pip's visible figure is not a direct-attack target while she has cards.")
		_expect(rival._pick_card(face_point) == null, "The seated Pip illustration exposed a hidden card through the normal picker.")
		_expect(not rival._reference_mina_rect().has_point(Vector2(rival.viewport_container.size.x * 0.18, face_point.y)), "Pip's attack rectangle incorrectly covers the shop beside her.")

		rival.service.select_attacker(rival.state, int(attacker.instance_id))
		rival._render_match()
		await process_frame
		var blocked_life := int(rival.state.opponent.life)
		rival._on_table_gui_input(_left_click(face_point))
		await process_frame
		_expect(int(rival.state.opponent.life) == blocked_life and "clear all opposing Plated cards" in String(rival.state.message), "Clicking illustrated Pip bypassed a Plated blocker.")
		rival._dismiss_invalid_action()
		rival.state.opponent.plated = []
		attacker.ready = true
		rival.state.selected_attacker = -1
		rival._render_match()
		await process_frame
		rival.service.select_attacker(rival.state, int(attacker.instance_id))
		rival._render_match()
		await process_frame
		var click_life := int(rival.state.opponent.life)
		rival._on_table_gui_input(_left_click(face_point))
		await _wait_for_attack(rival)
		_expect(int(rival.state.opponent.life) == click_life - int(attacker.attack) and not bool(attacker.ready), "Selecting an attacker and clicking illustrated Pip did not deal exactly one attack at %s." % viewport_size)

		# Start a real field drag with press/motion/release, including the arrow's
		# target resolution; calling the combat service directly would miss this.
		attacker.ready = true
		rival.state.selected_attacker = -1
		rival._render_match()
		await process_frame
		await process_frame
		var source: Node3D = rival._card_node_for_instance(int(attacker.instance_id))
		var source_point: Vector2 = rival._card_screen_rect(source).get_center()
		rival._on_table_gui_input(_left_click(source_point))
		var motion := InputEventMouseMotion.new()
		motion.position = face_point
		motion.relative = face_point - source_point
		rival._on_table_gui_input(motion)
		_expect(rival.dragging and bool(rival.drag_target_action.get("valid", false)) and int(rival.drag_target_action.get("target_instance_id", -2)) == -1, "Dragging onto illustrated Pip did not identify the legal Chef target.")
		var drag_life := int(rival.state.opponent.life)
		var release := _left_click(face_point)
		release.pressed = false
		rival._on_table_gui_input(release)
		await _wait_for_attack(rival)
		_expect(int(rival.state.opponent.life) == drag_life - int(attacker.attack) and not bool(attacker.ready) and not rival.dragging, "Releasing a field attack onto illustrated Pip did not deal exactly one attack.")

		rival.state.opponent.hand = []
		for target_kind in ["illustration", "profile"]:
			attacker.ready = true
			rival.state.selected_attacker = -1
			rival._render_match()
			await process_frame
			await process_frame
			rival.service.select_attacker(rival.state, int(attacker.instance_id))
			rival._render_match()
			await process_frame
			_expect(hand_counter != null and not hand_counter.visible and hand_counter.text == "0 cards in hand", "The seated rival's optional hand counter became visible or did not update when the hand became empty.")
			var target_point := face_point
			if target_kind == "profile":
				target_point = rival.viewport_container.get_global_transform_with_canvas().affine_inverse() * rival.opponent_profile_badge.get_global_rect().get_center()
			_expect(not rival._screen_hits_opponent_hand(face_point) and rival._screen_hits_opponent_chef(target_point), "Pip lost the %s Chef target when her hand became empty." % target_kind)
			_expect(rival.find_child("OpponentHandCard_0", true, false) == null, "Empty-handed Pip retained a hidden dynamic back-card target.")
			var empty_life := int(rival.state.opponent.life)
			rival._on_table_gui_input(_left_click(target_point))
			await _wait_for_attack(rival)
			_expect(int(rival.state.opponent.life) == empty_life - int(attacker.attack) and not bool(attacker.ready), "Clicking Pip's %s did not resolve as a Chef attack with an empty hand." % target_kind)
		seated_cast_cases_completed += 1
		rival.queue_free()
		await process_frame
		await process_frame
	root.size = Vector2i(1440, 900)


func _registered_art_path(asset_id: String) -> String:
	var registry: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	if not registry is Dictionary:
		_expect(false, "The generated-art registry did not load.")
		return ""
	for entry in registry.get("assets", []):
		if entry is Dictionary and String(entry.get("id", "")) == asset_id:
			return "res://" + String(entry.get("path", "")).trim_prefix("res://")
	_expect(false, "Missing generated-art registration for %s." % asset_id)
	return ""


func _wait_for_attack(table) -> void:
	await process_frame
	for _frame in range(60):
		if not bool(table.animation_busy):
			return
		await create_timer(0.05).timeout
	_expect(false, "A face attack did not finish its animation within three seconds.")


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
