extends SceneTree
## Deterministic hub-only presentation captures. Never writes the player's save.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.autosave_suspended = true
	main.player_settings.reduced_motion = true
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 424242)
	main.run.life = 25
	main.run.money = 12
	main.run.hub_shop = {
		"id": "locals_card_shop", "type": "shop", "hub_shop": true,
		"inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"],
	}
	main.run.hub_notice = "Your life and deck carry into every round. Take a bye when you need it."
	main._show_tournament_hub()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await _settle()
		_capture("room_polish_%dx%d" % [viewport_size.x, viewport_size.y])
	root.size = Vector2i(1280, 720)
	await _settle()
	var display := main.find_child("HubShopDisplayWindow", true, false) as Control
	var motion := InputEventMouseMotion.new()
	motion.position = display.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion, true)
	await _settle()
	assert((main.find_child("HubShopGlassHighlight", true, false) as Polygon2D).color.a > 0.2, "Display hover did not highlight the glass")
	_capture("room_polish_display_hover")
	motion = motion.duplicate()
	motion.position = Vector2(4, 4)
	motion.global_position = motion.position
	root.push_input(motion, true)
	(main.find_child("HubNextRoundButton", true, false) as Button).grab_focus()
	await _settle()
	_capture("room_polish_keyboard_focus")
	main.run.life = 40
	main._show_tournament_hub()
	await _settle()
	_capture("room_polish_full_health")
	main.run.hub_round = 3
	main.run.hub_break_used = true
	main.run.hub_break_choice = "heal"
	main.run.life = 33
	main.run.hub_shop.inventory = []
	main._show_tournament_hub()
	await _settle()
	_capture("room_polish_used_bye")
	main.queue_free()
	await process_frame
	quit()

func _settle() -> void:
	for unused in range(16):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(filename: String) -> void:
	var path := "res://outputs/%s.png" % filename
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	assert(error == OK, "Could not save hub capture")
	print("HUB_CAPTURE ", path)
