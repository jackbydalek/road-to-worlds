extends SceneTree

const MENU_SPARKLE_CONTROLLER := preload("res://scripts/ui/MenuSparkleController.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.set_meta("reduced_motion", false)

	var controller := MENU_SPARKLE_CONTROLLER.new()
	controller.enabled = true
	root.add_child(controller)

	var menu := Control.new()
	menu.name = "TestMenu"
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)

	var button := Button.new()
	button.name = "TestMenuButton"
	button.position = Vector2(300, 240)
	button.size = Vector2(220, 64)
	menu.add_child(button)

	await process_frame
	await process_frame
	button.mouse_entered.emit()
	button.focus_entered.emit()
	await process_frame
	_expect(button.find_children("MenuClickSparkleBurst", "Node2D", true, false).is_empty(), "Hover or focus created menu sparkles without a click.")

	root.set_meta("reduced_motion", true)
	button.button_down.emit()
	await process_frame
	var reduced_burst := button.find_child("MenuClickSparkleBurst", true, false) as Node2D
	_expect(reduced_burst != null and reduced_burst.get_child_count() == 2, "Reduced motion did not limit the menu sparkle burst.")
	_expect(reduced_burst != null and reduced_burst.show_behind_parent, "Menu sparkles are not rendered behind their button.")

	if reduced_burst != null:
		reduced_burst.queue_free()
	await process_frame
	root.set_meta("reduced_motion", false)
	var popup := Control.new()
	popup.name = "TestOptionsOverlay"
	popup.position = Vector2(380, 160)
	popup.size = Vector2(520, 360)
	popup.visible = false
	menu.add_child(popup)
	await process_frame
	await process_frame
	popup.visible = true
	await process_frame
	await process_frame
	_expect(button.find_children("MenuClickSparkleBurst", "Node2D", true, false).is_empty(), "A revealed menu overlay created sparkles without a click.")
	button.button_down.emit()
	await process_frame
	var normal_burst := button.find_child("MenuClickSparkleBurst", true, false) as Node2D
	_expect(normal_burst != null and normal_burst.get_child_count() == 5, "A normal menu click did not create the expected sparkle burst.")

	var tabletop := Control.new()
	tabletop.name = "Tabletop3DPrototype"
	root.add_child(tabletop)
	var battle_button := Button.new()
	battle_button.name = "BattleButton"
	battle_button.size = Vector2(180, 52)
	tabletop.add_child(battle_button)
	await process_frame
	await process_frame
	_expect(not battle_button.has_meta("menu_sparkle_bound"), "The menu sparkle controller bound to a battle control.")

	if failed:
		quit(1)
		return
	print("Menu sparkle smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
