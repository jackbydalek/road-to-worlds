extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/sketch_front_door"


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

	main.season_setup_archetype_index = 1
	main.season_setup_difficulty_index = 0
	main._show_season_run_setup()
	await _settle()
	await _capture("03_season_setup_hearty.png")

	main.season_setup_archetype_index = main.DEMO_STARTER_ORDER.find(main.DRAFT_NIGHT_ID)
	main.season_setup_difficulty_index = 3
	main._show_season_run_setup()
	await _settle()
	await _capture("04_season_setup_draft.png")
	main._show_starter_deck_preview(main.DRAFT_NIGHT_ID)
	await _settle()
	await _capture("05_draft_night_popup.png")
	main._close_starter_deck_preview()
	await _settle()

	main.rng.seed = 20260725
	main._begin_draft("silver")
	await _settle()
	await _capture("06_draft_workspace.png")
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Sketch front-door capture requires a graphical compatibility renderer.")
		quit(1)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var result := image.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Could not save sketch front-door preview: " + path)
