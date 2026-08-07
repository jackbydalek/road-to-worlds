extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const OUTPUT_PATH := "res://outputs/clarity_states/board_info_labels.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table := TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	table._toggle_board_info()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH)) != OK:
		push_error("Could not save board-info preview.")
	else:
		print("Saved board-info preview: %s" % OUTPUT_PATH)
	table.queue_free()
	await process_frame
	quit()
