extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_PATH := "res://outputs/illustrated_vfx/card_inspector_complete_text.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 600)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.selected_ref = {
		"kind": "field",
		"side": "player",
		"hand_index": -1,
		"instance_id": -1,
		"zone": "plated",
		"card_id": "hearty_gravy_gazelle",
	}
	table._refresh_action_panel()
	if is_instance_valid(table.turn_banner_panel):
		table.turn_banner_panel.visible = false
	await process_frame
	await process_frame
	var preview := root.get_texture().get_image()
	if preview == null or preview.save_png(ProjectSettings.globalize_path(OUTPUT_PATH)) != OK:
		push_error("Could not save card inspector preview.")
	for tween in get_processed_tweens():
		tween.kill()
	table.queue_free()
	await process_frame
	await process_frame
	quit()
