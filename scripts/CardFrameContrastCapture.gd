extends "res://scripts/SuppliedMinaCapture.gd"

## Native screenshots of the darker shared frames, using the existing battle
## fixture. No generated images or changes to the card illustration textures.
const CONTRAST_OUTPUT_DIR := "res://outputs/card_frame_contrast"


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONTRAST_OUTPUT_DIR))
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		await _create_match()
		_stage_board(true)
		table.configure_battle_preferences("fast", 1.0, true, false)
		await _settle()
		_check_board_and_hud("darker-card-frames")
		await RenderingServer.frame_post_draw
		var shot := capture_viewport.get_texture().get_image()
		var filename := "%dx%d_battle.png" % [output_size.x, output_size.y]
		_expect(shot != null and shot.save_png(ProjectSettings.globalize_path(CONTRAST_OUTPUT_DIR.path_join(filename))) == OK, "Could not save " + filename)
		for node in table.find_children("*", "AudioStreamPlayer", true, false):
			node.stop()
			node.stream = null
		table.queue_free()
		await _settle(3)
		capture_viewport.queue_free()
		await _settle(3)
	for error in errors:
		push_error(error)
	print("CARD_FRAME_CONTRAST_CAPTURE_%s: 2 native views" % ["OK" if errors.is_empty() else "FAILED"])
	quit(0 if errors.is_empty() else 1)
