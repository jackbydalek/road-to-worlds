extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/starter_table_runtime"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("StarterSelectionPreviewCapture requires a graphical renderer.")
		quit(1)
		return
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	main.autosave_enabled = false
	root.add_child(main)
	await _settle()
	main._show_season_run_setup()
	await _settle()
	await _capture("01-table.png")
	var setup = main.find_child("SeasonRegistration", true, false)
	for index in range(3):
		setup.select_starter(index, false)
		setup.select_difficulty([0, 3, 1][index])
		await _settle()
		await _capture(["02-spicy-black.png", "03-hearty-silver.png", "04-sweet-blue.png"][index])
	root.size = Vector2i(1280, 720)
	setup._collapse_selection()
	await _settle()
	await _capture("05-table-1280x720.png")
	setup.select_starter(2, false)
	setup.select_difficulty(4)
	await _settle()
	await _capture("06-sweet-gold-1280x720.png")
	main.player_settings.text_scale = 1.25
	main._apply_player_settings(false)
	await _settle()
	await _capture("07-large-text-1280x720.png")
	main._release_audio_streams()
	main.queue_free()
	await _settle()
	print("STARTER_TABLE_CAPTURE_OK: ", ProjectSettings.globalize_path(OUTPUT_DIR))
	quit()

func _settle() -> void:
	for frame in range(8):
		await process_frame

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot == null or screenshot.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])) != OK:
		push_error("Could not save starter table capture: " + filename)
