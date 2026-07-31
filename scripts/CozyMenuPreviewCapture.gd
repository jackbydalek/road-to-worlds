extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/cozy_menu_first_pass"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	await _capture("01_title.png")
	main._show_game_start()
	await process_frame
	await process_frame
	await _capture("02_game_status.png")

	main.season_setup_archetype_index = 1
	main.season_setup_difficulty_index = 0
	main._show_season_run_setup()
	await process_frame
	await process_frame
	await _capture("03_season_setup_hearty.png")
	main._show_starter_deck_preview("hearty")
	await process_frame
	await process_frame
	await _capture("05_starter_deck_popup.png")
	var preview_rows := main.find_children("StarterDeckPreviewEntry_*", "", true, false)
	if not preview_rows.is_empty():
		var preview_row := preview_rows[0] as Control
		var preview_card_id := String(preview_row.name).trim_prefix("StarterDeckPreviewEntry_")
		main._show_starter_deck_hover_preview(preview_row, preview_card_id)
		await process_frame
		await process_frame
		await _capture("07_starter_deck_card_hover.png")
	main._close_starter_deck_preview()
	await process_frame

	main.season_setup_archetype_index = main.DEMO_STARTER_ORDER.find(main.DRAFT_NIGHT_ID)
	main.season_setup_difficulty_index = 3
	main._show_season_run_setup()
	await process_frame
	await process_frame
	await _capture("04_season_setup_draft.png")
	main._show_starter_deck_preview(main.DRAFT_NIGHT_ID)
	await process_frame
	await process_frame
	await _capture("06_draft_night_popup.png")
	quit()


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var result := image.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Could not save Cozy menu preview: " + path)
