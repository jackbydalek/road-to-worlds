extends SceneTree

const DEMO_SCENE := preload("res://scenes/StylizedShopDemo.tscn")
const OUTPUT_DIR := "res://outputs/stylized_shop_demo"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var demo := DEMO_SCENE.instantiate()
	root.add_child(demo)
	for _frame in 8:
		await process_frame
	if not await _capture("overview.png"):
		return
	demo._show_menu()
	await create_timer(1.0).timeout
	for _frame in 3:
		await process_frame
	if not await _capture("shopkeeper.png"):
		return
	quit()


func _capture(filename: String) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Stylized shop preview requires a graphical compatibility renderer.")
		quit(1)
		return false
	var output_path := OUTPUT_DIR + "/" + filename
	var result := image.save_png(ProjectSettings.globalize_path(output_path))
	if result != OK:
		push_error("Could not save stylized shop preview: " + output_path)
		quit(1)
		return false
	return true
