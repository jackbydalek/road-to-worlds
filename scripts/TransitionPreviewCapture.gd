extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const MENU_PREVIEW_PATH := "res://outputs/illustrated_vfx/paper_iris_transition.png"
const ROUND_PREVIEW_PATH := "res://outputs/illustrated_vfx/round_paper_iris_transition.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main._play_menu_circle_wipe(Callable(self, "_keep_current_screen"))
	await create_timer(0.28).timeout
	_save_preview(MENU_PREVIEW_PATH)
	await create_timer(0.55).timeout

	main._play_round_circle_wipe("Local Qualifier", 2)
	await create_timer(0.32).timeout
	_save_preview(ROUND_PREVIEW_PATH)
	await create_timer(1.25).timeout
	main.queue_free()
	await process_frame
	await process_frame
	quit()


func _keep_current_screen() -> void:
	pass


func _save_preview(path: String) -> void:
	var preview := root.get_texture().get_image()
	if preview == null or preview.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("Could not save transition preview: %s" % path)
	else:
		print("Saved transition preview: %s" % path)
