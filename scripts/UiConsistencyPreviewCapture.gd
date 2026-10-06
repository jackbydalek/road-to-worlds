extends SceneTree
## Reproducible public-screen reference set for the UI consistency audit.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _settle()
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main._show_start()
	await _capture("title")
	main._show_settings()
	await _capture("settings")
	main._show_season_run_setup()
	await _capture("starter")
	main._show_starter_deck_preview("spicy")
	await _capture("starter_deck")
	var starter_preview := main.find_child("StarterDeckPreview", true, false)
	if starter_preview != null:
		starter_preview.queue_free()
	await _settle()
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 24680)
	main.run.life = 28
	main.run.money = 12
	main._show_tournament_hub()
	await _capture("hub")
	main._show_hub_break_upgrade()
	await _capture("upgrade")
	main._show_tournament_hub()
	main._show_deckbuilder()
	await _capture("deck")
	main.run.demo_complete = true
	main._show_route_victory()
	await _capture("victory")
	main._show_thanks_for_playing()
	await _capture("legacy_finale")
	main._begin_draft("white")
	await _capture("draft")
	main._release_audio_streams()
	for tween in get_processed_tweens():
		tween.kill()
	main.queue_free()
	await _settle()
	print("Saved UI consistency audit previews.")
	quit(0)


func _settle() -> void:
	for unused in range(8):
		await process_frame


func _capture(screen: String) -> void:
	await _settle()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame.save_png(ProjectSettings.globalize_path("res://outputs/ui_audit_%s.png" % screen)) != OK:
		push_error("Could not save UI audit screen: %s" % screen)
		quit(1)
