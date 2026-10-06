extends "res://scripts/TrailerClipPreviewCapture.gd"

## Offline, native 4K screenshots. Uses production UI and combat rendering;
## stages deterministic board states without changing normal game behavior.
var destination := "res://outputs/steam_gallery_refresh/4k"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	main = MAIN_SCENE.instantiate()
	master_viewport = SubViewport.new()
	master_viewport.size = CAPTURE_SIZE * 2
	master_viewport.size_2d_override = Vector2i(1600, 900)
	master_viewport.size_2d_override_stretch = true
	master_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(master_viewport)
	var presentation := TextureRect.new()
	presentation.texture = master_viewport.get_texture()
	presentation.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	presentation.size = Vector2(root.size)
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(presentation)
	curtain.reparent(master_viewport)
	master_viewport.add_child(main)
	await _settle(20)
	main.autosave_enabled = false
	main.autosave_suspended = true
	main.run_state_service.save_path = "/private/tmp/top-cut-steam-gallery-save.json"
	main.player_settings.reduced_motion = false
	main.player_settings.play_speed = "normal"
	curtain.hide()
	await _combat(false)
	# A fresh scene avoids carrying the first match's modal/transition state
	# into the second staged match.
	main.queue_free()
	await _settle(4)
	main = MAIN_SCENE.instantiate()
	master_viewport.add_child(main)
	await _settle(20)
	main.autosave_enabled = false
	main.autosave_suspended = true
	main.run_state_service.save_path = "/private/tmp/top-cut-steam-gallery-save.json"
	await _combat(true)
	_start_capture_run("spicy")
	main.run.money = 12
	main.run.hub_round = 2
	main.run.life = 25
	main.run.hub_break_used = false
	main.run.hub_shop = {
		"id": "locals_card_shop", "type": "shop", "hub_shop": true,
		"inventory": ["spicy_jalapeno_panther", "item_switchblade", "spicy_hot_honey_bee", "spicy_sriracharrow"],
	}
	main.run.pending_route_node = {}
	main.run.route_battle = {}
	main._show_tournament_hub()
	await _save_shot("05_tournament_hub")
	main.run.pending_route_node = {"id": "gallery_reward", "type": "enemy", "label": "Local Rival"}
	main.run.reward_offer = ["spicy_hot_honey_bee", "spicy_jalapeno_panther", "spicy_sriracharrow"]
	main.run.reward_picks_remaining = 3
	main.run.reward_selected = []
	main.run.route_pack_presented = true
	main.run.route_pack_opened = false
	main.run.route_reward_intro_seen = true
	main._show_route_sealed_pack()
	await _settle(12)
	main._crack_route_victory_pack()
	await _hold(1.0)
	await _save_shot("04_reward_choices")
	main.run.pending_route_node = {"id": "gallery_upgrade", "type": "shop", "hub_shop": true, "hub_view": "counter", "inventory": main.run.hub_shop.inventory}
	main._show_route_shop()
	await _settle(12)
	main._show_route_upgrade_card()
	await _settle(12)
	main._select_route_shop_service_card("upgrade", "spicy_hot_honey_bee")
	await _save_shot("02_foil_upgrade_preview")
	main.queue_free()
	await _settle(4)
	main = MAIN_SCENE.instantiate()
	master_viewport.add_child(main)
	await _settle(20)
	main.autosave_enabled = false
	main.autosave_suspended = true
	main._show_season_run_setup()
	await _settle(16)
	var setup = main.find_child("SeasonRegistration", true, false)
	setup.select_starter(0, true)
	await _save_shot("06_choose_your_starter")
	print("STEAM_GALLERY_COMPLETE")
	quit()

func _combat(hearty: bool) -> void:
	var table: Node = await _open_trailer_match("hearty" if hearty else "spicy", "sweet", "Rival Mina", 20260906, 18)
	assert(table != null)
	var state: Dictionary = table.state
	_reset_trailer_board_state(state)
	state.opponent.life = 18
	state.opponent.max_life = 18
	state.player.deck = ["item_wooden_spoon", "spicy_hot_honey_bee"]
	state.opponent.deck = ["sweet_sugar_glider", "sweet_jellyfish"]
	var attacker: Dictionary
	if hearty:
		attacker = _add_unit(table, "player", "hearty_polar_pot_pie_bear", "plated", 0, true)
		_add_unit(table, "player", "hearty_macaroni_manatee", "plated", 1, true)
		_add_unit(table, "player", "hearty_ramen_ram", "prep", 0, true)
		_add_unit(table, "player", "hearty_bagver", "prep", 1, true)
		state.player.hand = ["hearty_ramen_ram", "item_wooden_spoon", "hearty_macaroni_manatee"]
	else:
		attacker = _add_unit(table, "player", "spicy_firecracker_shrimp", "plated", 0, true)
		_add_unit(table, "player", "spicy_sriracharrow", "plated", 1, true)
		_add_unit(table, "player", "spicy_hot_honey_bee", "prep", 0, true)
		_add_unit(table, "player", "spicy_jalapeno_panther", "prep", 1, true)
		state.player.hand = ["spicy_wasabi_wasp", "item_switchblade", "spicy_hot_honey_bee"]
	_add_unit(table, "opponent", "sweet_strawberry_sharkcake", "plated", 0, true)
	# Respect the Crab's Bodyguard: target it rather than the protected Shark.
	var defender := _add_unit(table, "opponent", "sweet_soft_serve_crab", "plated", 1, true)
	_add_unit(table, "opponent", "sweet_caramel_camel", "prep", 0, true)
	_add_unit(table, "opponent", "sweet_sugar_glider", "prep", 1, true)
	table.service.clear_animation_events(state)
	table._render_match()
	await _settle(12)
	if not hearty:
		table._inspect_card(table._card_node_for_instance(int(attacker.instance_id)))
		await _save_shot("01_combat_card_strategy")
	else:
		var source: Node3D = table._card_node_for_instance(int(attacker.instance_id))
		var target: Node3D = table._card_node_for_instance(int(defender.instance_id))
		var from_screen: Vector2 = table._world_to_container(source.global_position)
		var to_screen: Vector2 = table._world_to_container(target.global_position)
		table.pressed_card = source
		table._begin_drag(source.position, from_screen)
		await _animate_field_drag(table, source.position, target.position, from_screen, to_screen, 0.3)
		await _save_shot("03_choose_your_attack")

func _save_shot(shot_name: String) -> void:
	await _settle(24)
	await process_frame
	var capture := master_viewport.get_texture().get_image()
	assert(capture.get_size() == Vector2i(3840, 2160))
	var error := capture.save_png(destination.path_join(shot_name + ".png"))
	assert(error == OK)
	print("STEAM_SCREENSHOT ", shot_name)
