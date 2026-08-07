extends SceneTree

const DEMO := preload("res://scenes/GreyboxCameraDemo.tscn")
const OUTPUT_PATH := "res://outputs/greybox_plants/overview.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var demo := DEMO.instantiate()
	root.add_child(demo)
	for _frame in 10:
		await process_frame
	var image := root.get_texture().get_image()
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if result != OK:
		push_error("Could not capture the greybox plant preview.")
		quit(1)
		return
	quit()
