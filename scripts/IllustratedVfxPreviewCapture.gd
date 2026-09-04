extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const LAYOUT_PATH := "res://outputs/illustrated_vfx/combat_layout_spacing.png"
const SHOWCASE_PATH := "res://outputs/illustrated_vfx/illustrated_combat_effects.png"
const ACTIVATION_PATH := "res://outputs/illustrated_vfx/celestial_activation.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.production_match = true
	table.state.player.prep = [_unit(table, "player", "spicy_jalapeno_panther", "prep", 0, false)]
	table.state.player.plated = [
		_unit(table, "player", "spicy_sriracharrow", "plated", 0, true),
		_unit(table, "player", "spicy_firecracker_shrimp", "plated", 1, true),
	]
	table.state.opponent.prep = [_unit(table, "opponent", "hearty_french_bread_dog", "prep", 1, false)]
	table.state.opponent.plated = [_unit(table, "opponent", "hearty_bagver", "plated", 0, true)]
	table.state.message = "Illustrated effects showcase"
	table._render_match()
	await process_frame
	await process_frame
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	await process_frame
	await process_frame
	_save_preview(LAYOUT_PATH)

	var player_left := table.find_child("PlayerPlatedCard_*", true, false) as Node3D
	var player_prep := table.find_child("PlayerPrepCard_*", true, false) as Node3D
	var rival_card := table.find_child("OpponentPlatedCard_*", true, false) as Node3D
	var player_center: Vector2 = table._world_to_container(player_left.global_position + Vector3(0.0, 0.45, 0.0))
	var prep_center: Vector2 = table._world_to_container(player_prep.global_position + Vector3(0.0, 0.4, 0.0))
	var rival_center: Vector2 = table._world_to_container(rival_card.global_position + Vector3(0.0, 0.45, 0.0))

	table._play_graphic_vfx_screen("card_land", player_center, table.PALETTE.AFFINITY_SPICY)
	table._play_graphic_vfx_screen("heal", prep_center)
	table._play_graphic_vfx_screen("damage", rival_center)
	await create_timer(0.08).timeout
	_save_preview(SHOWCASE_PATH)

	await create_timer(1.15).timeout
	var activation_timer := create_timer(0.2)
	activation_timer.timeout.connect(func() -> void: _save_preview(ACTIVATION_PATH))
	await table._show_field_activation_indicator({
		"type": "ability_activation",
		"side": "player",
		"source_instance_id": int(table.state.player.plated[0].instance_id),
		"card_id": "spicy_sriracharrow",
		"activation_label": "ON-PLAY EFFECT"
	})
	if is_instance_valid(table.ability_activation_sound_player):
		table.ability_activation_sound_player.stop()
	table.queue_free()
	await process_frame
	quit()


func _save_preview(path: String) -> void:
	var preview := root.get_texture().get_image()
	if preview == null or preview.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("Could not save illustrated VFX preview: %s" % path)
	else:
		print("Saved illustrated VFX preview: %s" % path)


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
