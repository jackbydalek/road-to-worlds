extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_PATH := "res://outputs/nexus_2011/season_calendar.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://outputs/nexus_2011"))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle(4)

	var starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main._generate_shop_inventory()
	main._show_season_run()
	await _settle(6)

	var image := root.get_texture().get_image()
	if image == null:
		push_error("Nexus season preview requires the compatibility renderer.")
		quit(1)
		return
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if result != OK:
		push_error("Could not save Nexus season preview.")
		quit(1)
		return
	print("Saved Nexus season preview: " + OUTPUT_PATH)
	quit()


func _settle(frames: int) -> void:
	for unused_frame in range(frames):
		await process_frame
