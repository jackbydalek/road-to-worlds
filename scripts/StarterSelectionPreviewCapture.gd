extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/character_selection"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	main._show_season_run_setup()
	await _settle()
	await _capture("01_lineup.png")
	var setup := main.find_child("SeasonRegistration", true, false) as SeasonSetupMenu
	setup.select_starter(0, false)
	await _settle()
	await _capture("02_spicy_selected.png")
	setup.select_starter(1, false)
	await _settle()
	await _capture("03_hearty_selected.png")
	setup.select_starter(2, false)
	await _settle()
	await _capture("04_sweet_selected.png")
	setup._begin_selected_run(2)
	await process_frame
	await process_frame
	await _capture("05_sweet_victory.png")
	quit()


func _settle() -> void:
	for _frame in range(8):
		await process_frame


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Character-selection preview requires a graphical renderer.")
		return
	var output_path := "%s/%s" % [OUTPUT_DIR, filename]
	if image.save_png(ProjectSettings.globalize_path(output_path)) != OK:
		push_error("Could not save character-selection preview: %s" % output_path)
