extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main.run.week = 1
	main.run.money = 29
	main.run.run_over = true
	main.run.last_event_result = {
		"event_id": "weekly_locals",
		"event_name": "Weekly Locals",
		"stage": "Locals",
		"wins": 2,
		"losses": 1,
		"rounds": 3,
		"required_wins": 3,
		"made_record": false,
		"reward_money": 0,
		"reward_packs": 0,
		"round_cash_earned": 9,
		"run_over": true,
		"round_results": [
			{"round": 1, "opponent_name": "Priya", "opponent_archetype": "Hearty Starter", "won": true, "turn": 4, "player_life": 17, "cash": 2},
			{"round": 2, "opponent_name": "Priya", "opponent_archetype": "Sweet Starter", "won": true, "turn": 7, "player_life": 18, "cash": 3},
			{"round": 3, "opponent_name": "Local Rival Tess", "opponent_archetype": "Hearty Starter", "won": false, "turn": 0, "player_life": 0, "cash": 4},
		],
	}
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(1728, 1117)]:
		root.size = viewport_size
		main._show_tournament_result([], false)
		await _capture("season_ended_%dx%d" % [viewport_size.x, viewport_size.y])
	main.run.last_event_result = {}
	main._show_tournament_result(["The run is over."], false)
	await _capture("season_ended_fallback")
	main.queue_free()
	await process_frame
	print("Saved season-ended previews.")
	quit(0)


func _capture(filename: String) -> void:
	for unused in range(8):
		await process_frame
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.save_png(ProjectSettings.globalize_path("res://outputs/%s.png" % filename)) != OK:
		push_error("Could not save season-ended preview.")
		quit(1)
