extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/storefront_menu"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	await create_timer(0.2).timeout
	await _settle()
	await _capture("01_storefront.png")
	main.queue_free()
	await _settle()

	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	main._show_game_start()
	await _settle()
	await _capture("02_door_gateway.png")
	main.queue_free()
	await _settle()

	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	var start_button := main.find_child("GameStartButton", true, false) as Button
	if start_button == null:
		push_error("Storefront preview could not find GameStartButton.")
		quit(1)
		return
	start_button.emit_signal("pressed")
	await create_timer(0.39).timeout
	await _capture("03_zoom_midpoint.png")
	await create_timer(0.48).timeout
	await _settle()
	await _capture("04_zoom_destination.png")
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Storefront menu capture requires a graphical compatibility renderer.")
		quit(1)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var result := image.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Could not save storefront menu preview: " + path)
