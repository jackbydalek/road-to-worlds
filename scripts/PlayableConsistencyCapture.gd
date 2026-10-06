extends SceneTree

## Offline review captures of actual playable screens. Never writes player saves.
const MAIN_SCENE := preload("res://scenes/Main.tscn")
var main: Node
var capture_size := Vector2i(1440, 900)
var destination := "res://outputs/playable_consistency_2026-09-08/before"
var only_view := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			destination = "res://outputs/playable_consistency_2026-09-08/" + argument.trim_prefix("--label=").validate_filename()
		elif argument.begins_with("--view="):
			only_view = argument.trim_prefix("--view=")
		elif argument == "--large":
			capture_size = Vector2i(1920, 1080)
		elif argument == "--small":
			capture_size = Vector2i(1280, 720)
	root.size = capture_size
	root.set_meta("reduced_motion", true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	for view in ["title", "settings", "starter", "starter_border", "hub", "card_case", "clerk", "machine", "machine_used", "deck", "pack", "reward", "upgrade", "victory", "defeat", "rival", "battle", "discard", "tutorial"]:
		if not only_view.is_empty() and view not in only_view.split(","):
			continue
		main = MAIN_SCENE.instantiate()
		main.autosave_enabled = false
		main.autosave_suspended = true
		root.add_child(main)
		await _settle()
		main.run_state_service.save_path = "/private/tmp/locals-consistency-capture-save.json"
		main.player_settings.reduced_motion = true
		root.set_meta("reduced_motion", true)
		root.size = capture_size
		await _settle()
		match view:
			"title": main._show_start()
			"settings": main._show_settings()
			"starter": main._show_season_run_setup()
			"starter_border":
				main._show_season_run_setup()
				await _settle()
				var setup = main.find_child("SeasonRegistration", true, false)
				setup.select_starter(1, false)
				setup.select_difficulty(3)
			"hub":
				_prepare_run()
				main._show_tournament_hub()
			"card_case", "clerk", "machine", "machine_used":
				_prepare_run()
				if view == "machine_used":
					main.run.hub_break_used = true
					main.run.hub_break_choice = "heal"
				main._show_tournament_hub()
				main._open_hub_view("counter" if view == "card_case" else "seller" if view == "clerk" else "machine")
			"deck":
				_prepare_run()
				main._show_tournament_hub()
				main._show_deckbuilder()
			"reward", "pack":
				_prepare_run()
				main.run.pending_route_node = {"id": "review_reward", "type": "enemy", "label": "Local Rival"}
				main.run.reward_offer = ["spicy_hot_honey_bee", "spicy_jalapeno_panther", "spicy_sriracharrow"]
				main.run.reward_picks_remaining = 3
				main.run.reward_selected = []
				main.run.route_pack_presented = true
				main.run.route_pack_opened = true
				main.run.route_reward_intro_seen = true
				if view == "pack": main._show_route_sealed_pack()
				else: main._show_route_card_reward()
			"upgrade":
				_prepare_run()
				main._show_tournament_hub()
				main._show_hub_break_upgrade()
				main._select_route_shop_service_card("break_upgrade", "spicy_hot_honey_bee")
			"victory":
				_prepare_run()
				main.run.demo_complete = true
				_prepare_results(true)
				main._show_route_victory()
			"defeat":
				_prepare_run()
				main.run.life = 0
				main.run.run_over = true
				_prepare_results(false)
				main._show_route_game_over()
			"rival", "battle", "discard":
				_prepare_run()
				main.run.pending_route_node = main._hub_round_node(3)
				main.run.pending_route_node.npc_portrait_id = "mina"
				main._start_route_battle()
				if view != "rival":
					main._begin_route_battle_from_intro()
					await _settle()
					var table = main.find_child("Tabletop3DPrototype", true, false)
					for side in ["player", "opponent"]:
						table.state[side].prep = []
						table.state[side].plated = []
					_add_unit(table, "player", "spicy_hot_honey_bee", "prep", 0)
					_add_unit(table, "player", "spicy_sriracharrow", "plated", 0)
					_add_unit(table, "opponent", "sweet_sugar_glider", "prep", 0)
					_add_unit(table, "opponent", "sweet_strawberry_sharkcake", "plated", 0)
					table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon", "spicy_jalapeno_panther"]
					table.state.player.discard = ["spicy_hot_honey_bee", "item_wooden_spoon", "spicy_jalapeno_panther"]
					table.service.clear_animation_events(table.state)
					table._render_match()
					if view == "discard": table._open_discard_tray("player")
			"tutorial": main._show_tutorial()
		await _settle()
		# Draw even when the desktop places the review window behind another app.
		RenderingServer.force_draw(false)
		var frame := root.get_texture().get_image()
		assert(frame.get_size() == capture_size)
		assert(frame.save_png(ProjectSettings.globalize_path(destination.path_join("%s_%dx%d.png" % [view, capture_size.x, capture_size.y]))) == OK)
		print("PLAYABLE_CAPTURE ", view)
		main._release_audio_streams()
		for tween in get_processed_tweens():
			tween.kill()
		main.queue_free()
		await _settle()
	print("PLAYABLE_CONSISTENCY_CAPTURE_COMPLETE")
	quit(0)


func _prepare_run() -> void:
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 24680)
	main.run.life = 28
	main.run.money = 12


func _prepare_results(won: bool) -> void:
	main.run.hub_round = 4
	main.run.route_round_results = []
	for index in range(4):
		main.run.route_round_results.append({
			"round": index + 1, "opponent_name": ["Kit", "Pip", "Mina", "Bea"][index],
			"opponent_archetype": ["Hearty", "Sweet", "Sweet", "Spicy"][index],
			"won": won or index < 3, "cash": 2 if index < 2 else 5 if index == 2 else 8 if won else 0,
			"turn": 5 + index, "player_life": 32 - index * 6 if won or index < 3 else 0,
		})


func _add_unit(table: Node, side: String, id: String, zone: String, slot: int) -> void:
	var unit: Dictionary = table.service._make_unit(table.state, table.state[side], table.service.card(id), zone, side)
	unit.table_slot = slot
	unit.ready = true
	table.state[side][zone].append(unit)


func _settle() -> void:
	for unused in range(16):
		await process_frame
		# Nested card-face viewports also need completed draws while occluded.
		RenderingServer.force_draw(false)
	await create_timer(0.2).timeout
