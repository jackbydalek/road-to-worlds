extends SceneTree

## Native, reproducible screenshots of the current UI. Never writes save data.
const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/warm_sketch_ui"
var main
var capture_size := Vector2i.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	root.set_meta("reduced_motion", true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		root.size = output_size
		main._show_start()
		await _capture("01_title")
		main._show_settings()
		await _capture("02_settings")
		main._show_season_run_setup()
		await _capture("03_starters")
		main._show_starter_deck_preview("spicy")
		await _capture("04_starter_cards")
		var preview: Node = main.find_child("StarterDeckPreview", true, false)
		if preview != null:
			preview.queue_free()
		await _settle()
		_prepare_run()
		main._show_tournament_hub()
		await _capture("05_hub")
		(main.find_child("HubShopButton", true, false) as Button).pressed.emit()
		await create_timer(0.7).timeout
		await _capture("06_shop_case")
		var hub = main.find_child("TournamentHub", true, false)
		hub._shop_view.select_card("spicy_sriracharrow")
		await _capture("07_shop_card")
		main._show_tournament_hub()
		main._show_hub_break_upgrade()
		await _capture("08_upgrade")
		main._show_tournament_hub()
		main._show_deckbuilder()
		await _capture("09_deck")
		main.run.pending_route_node = main._hub_round_node(1)
		main.run.reward_offer = ["spicy_hot_honey_bee", "spicy_sriracharrow", "spicy_firecracker_shrimp"]
		main.run.reward_picks_remaining = 3
		main.run.reward_selected = []
		main.selected_route_reward_card_id = ""
		main._show_route_card_reward()
		await _capture("10_rewards")
		main._clear_route_reward_overlay()
		main.run.demo_complete = true
		main._show_route_victory()
		await _capture("11_results")
	main._release_audio_streams()
	for tween in get_processed_tweens():
		tween.kill()
	main.queue_free()
	await _settle()
	print("WARM_SKETCH_UI_CAPTURE_OK: 11 screens at 2 resolutions")
	quit(0)


func _prepare_run() -> void:
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 24680)
	main.run.life = 28
	main.run.money = 12
	main.run.hub_shop = {
		"id": "locals_card_shop", "type": "shop", "hub_shop": true,
		"inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"]
	}


func _settle() -> void:
	for unused in range(8):
		await process_frame


func _capture(screen: String) -> void:
	await _settle()
	await create_timer(0.35).timeout
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var destination := OUTPUT_DIR.path_join("%dx%d_%s.png" % [capture_size.x, capture_size.y, screen])
	if root.get_texture().get_image().save_png(ProjectSettings.globalize_path(destination)) != OK:
		push_error("Unable to save " + destination)
		quit(1)
	print("UI_CAPTURE " + destination)
