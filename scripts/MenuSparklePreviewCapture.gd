extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/menu_sparkles"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var start_button := main.find_child("GameStartButton", true, false) as BaseButton
	if start_button == null:
		start_button = main.find_child("*Start*Button*", true, false) as BaseButton
	if start_button != null:
		start_button.button_down.emit()
	await create_timer(0.16).timeout
	_save_capture("title_menu.png")

	main._show_settings()
	await process_frame
	await process_frame
	var settings_button := main.find_child("SettingsBackButton", true, false) as BaseButton
	if settings_button == null:
		settings_button = main.find_child("*Toggle", true, false) as BaseButton
	if settings_button != null:
		settings_button.button_down.emit()
	await create_timer(0.16).timeout
	_save_capture("settings_menu.png")
	await create_timer(0.35).timeout
	quit(0)


func _save_capture(filename: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	if image.save_png(path) != OK:
		push_error("Could not save menu sparkle preview: " + path)
