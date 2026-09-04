extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/terrain_battle_backdrops"
const TERRAIN_PREVIEWS := [
	{"id": "park", "location": "Park Table"},
	{"id": "sidewalk", "location": "Sidewalk Table"},
	{"id": "waterfront", "location": "Waterfront Table"},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var output_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if output_error != OK:
		push_error("Could not create terrain preview directory.")
		quit(1)
		return

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._start_new_run_with_mode("sweet", "debug", "white")
	var player_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.sweet.starterDeck)
	var opponent_deck: Dictionary = main._opponent_deck_for_round("hearty", 1)
	main._begin_kitchen_match(player_deck, opponent_deck, "League Player", false, 20260825, "player", "easy")
	for _frame in range(12):
		await process_frame

	var table := main.find_child("Tabletop3DPrototype", true, false) as Control
	if table == null:
		push_error("Could not find battle table for terrain previews.")
		quit(1)
		return
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	# Let the front-door transition flourish finish so each comparison only shows
	# the terrain treatment, not a one-off menu animation.
	for _frame in range(36):
		await process_frame

	for preview in TERRAIN_PREVIEWS:
		table.configured_match_context = {
			"route_encounter": true,
			"location": String(preview.location),
		}
		table._apply_route_location_theme()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var output_path := "%s/%s.png" % [OUTPUT_DIR, String(preview.id)]
		if image == null or image.save_png(ProjectSettings.globalize_path(output_path)) != OK:
			push_error("Could not save terrain preview: %s" % output_path)
			quit(1)
			return

	print("Terrain battle previews saved to %s." % OUTPUT_DIR)
	quit()
