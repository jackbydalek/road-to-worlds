extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PREVIEW_PATH := "res://outputs/clarity_states/taunt_priority.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(1.15).timeout
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	for effect in table.effect_layer.get_children():
		effect.queue_free()
	await process_frame

	table.state.phase = "player_main"
	table.state.turn = 2
	table.state.player.prep = []
	table.state.player.plated = [_unit(table, "player", "spicy_sriracharrow", "plated", 0, true)]
	table.state.opponent.prep = []
	table.state.opponent.plated = [
		_unit(table, "opponent", "hearty_french_bread_dog", "plated", 0, true),
		_unit(table, "opponent", "hearty_bagver", "plated", 1, true),
	]
	table.state.message = "Taunt must be attacked before other cards."
	table._render_match()
	await process_frame
	await create_timer(0.18).timeout

	var preview := root.get_texture().get_image()
	if preview == null or preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH)) != OK:
		push_error("Could not save Taunt clarity preview.")
	else:
		print("Saved Taunt clarity preview: %s" % PREVIEW_PATH)
	table.queue_free()
	await process_frame
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
