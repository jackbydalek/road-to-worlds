extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CAPTURES := [
	{"life": 10, "path": "/tmp/topdeck_to_worlds_hp_50_percent.png"},
	{"life": 5, "path": "/tmp/topdeck_to_worlds_hp_25_percent.png"},
	{"life": 0, "path": "/tmp/topdeck_to_worlds_hp_0_percent.png"},
]

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	table.reduced_motion = true
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	if is_instance_valid(table.turn_banner_panel):
		table.turn_banner_panel.visible = false
	if is_instance_valid(table.rival_action_panel):
		table.rival_action_panel.visible = false

	for capture in CAPTURES:
		var life := int(capture.life)
		table.state.player.life = life
		table.state.opponent.life = life
		table._render_match()
		await create_timer(0.7).timeout
		var screenshot := root.get_texture().get_image()
		var save_error := screenshot.save_png(String(capture.path))
		if save_error != OK:
			failed = true
			push_error("Could not save HP-state preview: %s" % String(capture.path))

	table.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("HP bar state captures saved.")
	quit()
