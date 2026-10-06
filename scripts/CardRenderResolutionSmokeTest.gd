extends SceneTree

## Normal gameplay must render cards and the 3D board at the same quality as
## capture tools. Run headlessly; no player settings or save files are written.
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_SIZES := [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(2880, 1800), Vector2i(1280, 720)]

var failures: Array[String] = []
var checked_layouts := 0
var checked_slots := 0
var checked_hand_cards := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.set_meta("trailer_high_quality", false)
	root.content_scale_size = Vector2i(1440, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = OUTPUT_SIZES[0]
	var table = await _make_table(root)
	for output_size in OUTPUT_SIZES:
		root.size = output_size
		await _settle()
		_check_render_and_geometry(table, output_size, "window")
		await _check_pointer_delivery(table)
	_check_card_face_cache(table)
	await _dispose_table(table)

	# Capture fixtures use their own scaled SubViewport rather than a window.
	# Exercise that parent transform too, including a resize back down.
	var outer := SubViewport.new()
	outer.size_2d_override = Vector2i(1600, 900)
	outer.size_2d_override_stretch = true
	outer.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	outer.size = Vector2i(1920, 1080)
	root.add_child(outer)
	var nested_table = await _make_table(outer)
	for output_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		outer.size = output_size
		await _settle()
		_check_render_and_geometry(nested_table, output_size, "nested viewport")
	await _dispose_table(nested_table)
	outer.queue_free()
	await _settle(2)
	for failure in failures:
		push_error(failure)
	print("CardRenderResolutionSmokeTest %s: %d layouts, %d projected slots, %d hand-card picks; normal-mode face quality and cache checked." % ["PASS" if failures.is_empty() else "FAIL", checked_layouts, checked_slots, checked_hand_cards])
	quit(0 if failures.is_empty() else 1)


func _make_table(parent: Node):
	var table = TABLE_SCENE.instantiate()
	table.configured_seed = 20260908
	table.use_generated_opponent_art = false
	table.configured_match_context = {"rival_cast_id": "mina", "rival_display_name": "Mina"}
	table.configure_battle_preferences("fast", 1.0, true, false)
	parent.add_child(table)
	await _settle()
	table.state.phase = "player_main"
	table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon", "spicy_sriracharrow"]
	table.state.selected_attacker = -1
	table.animation_busy = false
	table._render_match()
	await _settle()
	table.turn_banner_panel.hide()
	table.rival_action_panel.hide()
	return table


func _check_render_and_geometry(table, output_size: Vector2i, parent_kind: String) -> void:
	var context := "%s at %s" % [parent_kind, output_size]
	checked_layouts += 1
	_expect(table.world_viewport.size == output_size, "%s rendered the 3D board at %s instead of native pixels." % [context, table.world_viewport.size])
	_expect(table.viewport_container.texture == table.world_viewport.get_texture(), context + " is not displaying the live battle texture.")
	for zone_id in table.ZONE_CENTERS:
		var zone: String = String(zone_id).trim_prefix("player_").trim_prefix("opponent_")
		var side := "opponent" if String(zone_id).begins_with("opponent_") else "player"
		var capacity := 3 if zone == "prep" else 2
		for slot in range(capacity):
			var position: Vector3 = table._slot_world_position(String(zone_id), slot)
			position.y = table.TABLE_Y
			var rendered_pixel: Vector2 = table.camera.unproject_position(position)
			var displayed_point: Vector2 = rendered_pixel * table.viewport_container.size / Vector2(output_size)
			var projected: Vector2 = table._world_to_container(position)
			_expect(projected.distance_to(displayed_point) < 0.02, "%s: %s slot %d projects away from its displayed pixels." % [context, zone_id, slot])
			var ray_hit: Variant = table._mouse_to_table(displayed_point)
			_expect(ray_hit is Vector3 and ray_hit.distance_to(position) < 0.005, "%s: %s slot %d no longer matches the pointer ray." % [context, zone_id, slot])
			if ray_hit is Vector3:
				var picked_slot: Dictionary = table._slot_at_point(ray_hit)
				_expect(String(picked_slot.get("zone", "")) == "%s_%s" % [side, zone] and int(picked_slot.get("slot", -1)) == slot, "%s: pointer selects the wrong %s slot %d." % [context, zone_id, slot])
			checked_slots += 1
	for card: Node3D in table.interactive_cards:
		if String(card.get_meta("kind", "")) != "hand" or String(card.get_meta("side", "")) != "player":
			continue
		var polygon: PackedVector2Array = table._card_screen_polygon(card)
		var center := Vector2.ZERO
		for point in polygon:
			center += point / float(polygon.size())
		_expect(table._pick_card(center) == card, "%s: hand card %s cannot be picked at its rendered center." % [context, card.name])
		checked_hand_cards += 1


func _check_pointer_delivery(table) -> void:
	# Deliver a real GUI press through the window, not directly to the table's
	# handler: replacing the viewport presenter must keep pointer events working.
	var hand_card: Node3D
	for card: Node3D in table.interactive_cards:
		if String(card.get_meta("kind", "")) == "hand" and String(card.get_meta("side", "")) == "player":
			hand_card = card
			break
	_expect(hand_card != null, "No real hand card is available for the GUI input check.")
	if hand_card == null:
		return
	var center: Vector2 = table._card_screen_rect(hand_card).get_center()
	var pixel_transform: Transform2D = root.get_final_transform() * table.viewport_container.get_global_transform_with_canvas()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = pixel_transform * center
	click.global_position = click.position
	# These are window pixels. Let Godot map them through canvas_items scaling,
	# just as an operating-system mouse event is mapped during normal play.
	root.push_input(click, false)
	_expect(table.pressed_card == hand_card, "A real pointer press did not reach the visible hand card at %s." % root.size)
	# Release without activating the card, so every size tests the same state.
	table.pressed_card = null
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, false)
	await _settle(1)


func _check_card_face_cache(table) -> void:
	var face: MeshInstance3D
	for card: Node3D in table.interactive_cards:
		if String(card.get_meta("kind", "")) == "hand" and String(card.get_meta("side", "")) == "player":
			face = card.get_node("CardFace") as MeshInstance3D
			break
	_expect(face != null, "No real hand-card face material was rendered.")
	if face == null:
		return
	var material := face.material_override as StandardMaterial3D
	_expect(material.albedo_texture.get_size() == Vector2(960, 1365), "Normal gameplay is still using a low-resolution hand-card face.")
	var face_viewport: SubViewport
	for child in table.texture_viewports.get_children():
		if child is SubViewport and child.get_texture() == material.albedo_texture:
			face_viewport = child
			break
	_expect(face_viewport != null, "The card face is not backed by its runtime viewport.")
	if face_viewport != null:
		_expect(face_viewport.size_2d_override == Vector2i(320, 455) and face_viewport.size_2d_override_stretch, "High-resolution rendering changed the card's logical layout.")
		_expect(face_viewport.render_target_update_mode in [SubViewport.UPDATE_ONCE, SubViewport.UPDATE_DISABLED], "Static card faces are rendering continuously.")
		table._request_card_face_redraw(face_viewport)
		_expect(face_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "An art-frame update no longer requests a bounded card redraw.")
	var child_count: int = table.texture_viewports.get_child_count()
	var existing_material = table._face_material("spicy_wasabi_wasp", true)
	for repeat in range(4):
		_expect(table._face_material("spicy_wasabi_wasp", true) == existing_material, "Repeated card draws recreated the cached face material.")
	_expect(table.texture_viewports.get_child_count() == child_count, "Reusing the same hand card allocated more face viewports.")


func _dispose_table(table) -> void:
	for player in table.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
		player.stream = null
	table.queue_free()
	await _settle(3)


func _settle(frames: int = 8) -> void:
	for frame in range(frames):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
