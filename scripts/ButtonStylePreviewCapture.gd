extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/button_style_preview"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	await _capture("01_title.png")

	main._show_game_start()
	await _settle()
	await _capture("02_game_status.png")

	main.season_setup_archetype_index = main.DEMO_STARTER_ORDER.find(main.DRAFT_NIGHT_ID)
	main.season_setup_difficulty_index = 3
	main._show_season_run_setup()
	await _settle()
	await _capture("03_season_setup.png")
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Button style preview requires a graphical compatibility renderer.")
		quit(1)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var result := image.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Could not save button style preview: " + path)
