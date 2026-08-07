extends SceneTree

const SHOP_SCENE := preload("res://scenes/GreyboxCameraDemo.tscn")
const OVERVIEW_PATH := "res://outputs/cafe_ui_review/shop_effects_oomph.png"
const MENU_PATH := "res://outputs/cafe_ui_review/shopkeeper_menu_no_dust.png"
const HEART_PATH := "res://outputs/cafe_ui_review/shopkeeper_goodbye_heart.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var shop := SHOP_SCENE.instantiate()
	root.add_child(shop)
	await process_frame
	await process_frame
	await create_timer(1.05).timeout
	_save(OVERVIEW_PATH)
	shop._show_menu()
	await create_timer(0.9).timeout
	_save(MENU_PATH)
	shop._show_overview()
	await create_timer(0.31).timeout
	_save(HEART_PATH)
	shop.queue_free()
	await process_frame
	quit()


func _save(path: String) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("Could not save shop effects preview: %s" % path)
	else:
		print("Saved shop effects preview: %s" % path)
