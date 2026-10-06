extends SceneTree
var main
var small := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	small = "--small" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720) if small else Vector2i(1440, 900)
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	root.size = Vector2i(1280, 720) if small else Vector2i(1440, 900)
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main.player_settings.text_scale = 1.25 if small else 1.0
	root.set_meta("reduced_motion", true)
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 24680)
	main.run.hub_round = 4
	main.run.life = 0
	main.run.money = 14
	main.run.route_round_results = [
		{"round": 1, "opponent_name": "Cal", "won": true, "cash": 2, "player_life": 34},
		{"round": 2, "opponent_name": "Priya", "won": true, "cash": 2, "player_life": 27},
		{"round": 3, "opponent_name": "Mina", "won": true, "cash": 5, "player_life": 18},
		{"round": 4, "opponent_name": "Tess", "won": false, "player_life": 0},
	]
	main.run.run_over = true
	main._show_route_game_over()
	await capture("01_defeated")
	if "--results-only" not in OS.get_cmdline_user_args():
		main._show_final_deck_review()
		await capture("02_final_deck")
		main._close_final_deck_review()
		main.run.run_over = false
		main.run.demo_complete = true
		main.run.route_round_results[3] = {"round": 4, "opponent_name": "Tess", "won": true, "cash": 8, "player_life": 12}
		main._show_route_victory()
		await capture("03_victory")
		main.run.demo_complete = false
		main.run.life = 28
		main._show_tournament_hub()
		await capture("04_hub")
		main._open_hub_shop()
		await create_timer(0.1).timeout
		var hub = main.find_child("TournamentHub", true, false)
		hub._shop_view.select_card(String(main.run.hub_shop.inventory[0]))
		await capture("04b_shop")
		hub._shop_view.close_inspection()
		main._leave_hub_shop()
		main.run.reward_offer = main.run.deck.keys().slice(0, 8)
		main.run.reward_picks_remaining = 8
		main._show_route_card_reward()
		await capture("04c_rewards")
		if "--rewards-only" in OS.get_cmdline_user_args():
			quit(0)
			return
		main._clear_route_reward_overlay()
		main.run.reward_offer = []
		main.run.reward_picks_remaining = 0
		main.run.pending_route_node = {}
		main._show_tournament_hub()
		main._show_deckbuilder()
		await capture("05_deck")
		main._show_tournament_hub()
		main._show_hub_break_upgrade()
		main._select_route_shop_service_card("break_upgrade", "spicy_wasabi_wasp", 0)
		await capture("06_upgrade")
		main._clear_route_shop_service_overlay()
		main._show_settings()
		await capture("07_settings")
		main.find_child("SettingsCategoryBattle", true, false).pressed.emit()
		await capture("07b_battle_settings")
		main._show_season_run_setup()
		await capture("08a_starter")
		main.find_child("SeasonRegistration", true, false).select_starter(1, false)
		await capture("08b_starter_selected")
		main._show_starter_deck_preview("spicy")
		await capture("08_starter_deck")
		main._close_starter_deck_preview()
		main._begin_draft("white")
		await capture("09_draft")
		main.hide()
		var table = load("res://scenes/Tabletop3DPrototype.tscn").instantiate()
		root.add_child(table)
		await create_timer(0.8).timeout
		for side in ["player", "opponent"]:
			table.state[side].plated = []
			table.state[side].prep = []
			table.state[side].turns_started = 2
		var attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_sriracharrow"), "plated", "player")
		var defender: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("sweet_soft_serve_crab"), "plated", "opponent")
		table.state.player.plated = [attacker]
		table.state.opponent.plated = [defender]
		table.state.phase = "player_main"
		table.state.selected_attacker = attacker.instance_id
		table.selected_ref = {"kind": "field", "side": "player", "hand_index": -1, "instance_id": attacker.instance_id, "zone": "plated", "card_id": "spicy_sriracharrow"}
		table.text_scale_index = 1 if small else 0
		table._apply_text_scale()
		table._render_match()
		await create_timer(0.3).timeout
		table.set_process(false)
		table._show_attack_preview(defender.instance_id, Vector2(820, 390))
		await capture("10_battle")
		table.queue_free()
	main._release_audio_streams()
	for tween in get_processed_tweens():
		tween.kill()
	main.queue_free()
	await process_frame
	quit(0)

func capture(label: String) -> void:
	for unused in range(8):
		await process_frame
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	if label == "04c_rewards":
		for node_name in ["RouteRewardActions", "RouteRewardAddAllButton", "RouteRewardSkipButton", "RouteRewardCardScroll", "RouteRewardModalContent"]:
			var node := main.find_child(node_name, true, false) as Control
			print(node_name, " rect=", node.get_global_rect(), " visible=", node.is_visible_in_tree(), " alpha=", node.modulate.a)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/ui_refresh/%s.png" % (label + "_1280_125" if small else label)))
