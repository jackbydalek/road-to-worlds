extends SceneTree

## Deterministic, cursor-free gameplay shots for trailer editing. Each invocation
## records one self-contained clip through Godot Movie Maker:
##
##   Godot --path . --script res://scripts/TrailerClipPreviewCapture.gd \
##     --write-movie /tmp/title.avi --fixed-fps 30 -- title

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const CAPTURE_SIZE := Vector2i(1920, 1080)
const CURTAIN_COLOR := Color("#12161C")
const VALID_CLIPS := [
	"01_combat_hook",
	"02_title",
	"03_choose_competitor",
	"04_route_decision",
	"05_rival_challenge",
	"06_control_the_table",
	"07_battle_combo",
	"08_reward_pack",
	"09_shop_deckbuild",
	"10_upgrade_foil",
	"11_city_champion",
	"12_logo_end_card",
	"13_card_trade",
	"14_hand_trap_response",
	"15_saladmander_summon",
	"16_sweet_jellyfish_bounce",
	"17_firecracker_bench_hit",
]

var main
var curtain: ColorRect


func _init() -> void:
	root.size = CAPTURE_SIZE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	root.set_meta("reduced_motion", false)
	_create_curtain()
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var clip_id := String(arguments[0]) if not arguments.is_empty() else ""
	if clip_id not in VALID_CLIPS:
		push_error("Choose one trailer clip: %s" % ", ".join(VALID_CLIPS))
		quit(2)
		return

	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle(14)
	main.autosave_enabled = false
	main.autosave_suspended = true
	main.run_state_service.save_path = "/private/tmp/top-cut-trailer-capture-save.json"
	main.player_settings.reduced_motion = false
	main.player_settings.play_speed = "normal"
	main.rng.seed = 20260827

	match clip_id:
		"01_combat_hook":
			await _capture_combat_hook()
		"02_title":
			await _capture_title()
		"03_choose_competitor":
			await _capture_starter_choice()
		"04_route_decision":
			await _capture_route_travel()
		"05_rival_challenge":
			await _capture_rival_challenge()
		"06_control_the_table":
			await _capture_control_the_table()
		"07_battle_combo":
			await _capture_battle_combo()
		"08_reward_pack":
			await _capture_reward_pack()
		"09_shop_deckbuild":
			await _capture_shop_purchase()
		"10_upgrade_foil":
			await _capture_upgrade_foil()
		"11_city_champion":
			await _capture_city_champion()
		"12_logo_end_card":
			await _capture_logo_end_card()
		"13_card_trade":
			await _capture_card_trade()
		"14_hand_trap_response":
			await _capture_hand_trap_response()
		"15_saladmander_summon":
			await _capture_saladmander_summon()
		"16_sweet_jellyfish_bounce":
			await _capture_sweet_jellyfish_bounce()
		"17_firecracker_bench_hit":
			await _capture_firecracker_bench_hit()

	await _fade_to_dark(0.34)
	await _hold(0.12)
	print("TRAILER_CLIP_CAPTURED ", clip_id)
	quit()


func _capture_combat_hook() -> void:
	var tabletop: Node = await _open_trailer_match(
		"spicy",
		"fresh",
		"Rival Jules",
		20260828,
		10
	)
	if tabletop == null:
		return
	_stage_attack_hook_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.24)
	await _hold(0.48)
	var attacker_id := int(tabletop.get_meta("trailer_attacker_id", -1))
	await _drag_attack_to_chef(tabletop, attacker_id, 0.62, 0.62)
	await _hold(1.05)


func _capture_title() -> void:
	await _fade_from_dark(0.5)
	await _hold(4.0)


func _capture_logo_end_card() -> void:
	var title_menu := main.find_child("BootLanding", true, false) as Control
	if title_menu == null:
		push_error("Trailer end-card clip could not find TitleMenu.")
		return
	var poster_layer := title_menu.get_node_or_null("PosterLayer") as Control
	var options_panel := title_menu.get_node_or_null("TitleOptionsPanel") as Control
	var options_button := title_menu.get_node_or_null("TitleOptionsButton") as Control
	var shop_sign := title_menu.get_node_or_null("ShopSign") as Control
	for menu_control in [poster_layer, options_panel, options_button]:
		if menu_control != null:
			menu_control.visible = false
	if shop_sign != null:
		shop_sign.anchor_left = 0.5
		shop_sign.anchor_top = 0.5
		shop_sign.anchor_right = 0.5
		shop_sign.anchor_bottom = 0.5
		shop_sign.offset_left = -500.0
		shop_sign.offset_top = -170.0
		shop_sign.offset_right = 500.0
		shop_sign.offset_bottom = 170.0
	await _settle(3)
	await _fade_from_dark(0.5)
	await _hold(4.0)


func _capture_starter_choice() -> void:
	main._show_season_run_setup()
	await _settle(16)
	var setup := main.find_child("SeasonRegistration", true, false) as SeasonSetupMenu
	if setup == null:
		push_error("Trailer starter-choice clip could not find SeasonRegistration.")
		return
	await _fade_from_dark(0.42)
	await _hold(0.75)
	setup.select_starter(0, true)
	await _hold(1.15)
	setup.select_starter(1, true)
	await _hold(1.15)
	setup.select_starter(2, true)
	await _hold(1.45)


func _capture_route_travel() -> void:
	_start_capture_run("spicy")
	await _settle(36)
	var stage: Node = main.find_child("StarterCityOverworld", true, false)
	var graph: Node = main.find_child("RouteGraph", true, false)
	if stage == null or graph == null:
		push_error("Trailer route clip could not build Starter City.")
		return
	await _fade_from_dark(0.42)
	await _hold(1.1)
	stage.call("_toggle_map_overview")
	await _hold(1.65)
	stage.call("_toggle_map_overview")
	await _hold(0.8)
	var destinations: Array[String] = graph.call("_available_destinations")
	if destinations.is_empty():
		push_error("Trailer route clip has no available destination.")
		return
	var combat_destinations: Array[String] = []
	for candidate_id in destinations:
		var candidate_data: Dictionary = graph.nodes.get(candidate_id, {})
		if String(candidate_data.get("type", "")) in ["enemy", "mini_boss", "final_boss"]:
			combat_destinations.append(candidate_id)
	var destination_id := _center_route_destination(
		graph,
		combat_destinations if not combat_destinations.is_empty() else destinations
	)
	graph.call("select_destination", destination_id)
	await _hold(2.45)


func _capture_rival_challenge() -> void:
	_start_capture_run("spicy")
	await _settle(30)
	await _fade_from_dark(0.34)
	await _hold(0.55)
	main.run.pending_route_node = {
		"id": "trailer_rival",
		"type": "enemy",
		"label": "Starter City Challenger",
	}
	main._start_route_battle()
	var battle: Dictionary = main.run.get("route_battle", {})
	if not battle.is_empty():
		battle.rival_portrait_id = "npc2"
		main.run.route_battle = battle
		main._show_route_encounter_intro()
	await _hold(2.55)
	var continue_button := main.find_child("BeginRouteEncounterButton", true, false) as Button
	if continue_button != null and not continue_button.disabled:
		continue_button.emit_signal("pressed")
		await _hold(1.65)


func _capture_control_the_table() -> void:
	var tabletop: Node = await _open_trailer_match(
		"hearty",
		"fresh",
		"Rival Jules",
		20260829,
		12
	)
	if tabletop == null:
		return
	_stage_zone_control_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.34)
	await _hold(0.7)
	var mover_id := int(tabletop.get_meta("trailer_mover_id", -1))
	await _drag_switch_to_slot(tabletop, mover_id, "player_plated", 0, 0.58, 0.58)
	await _hold(1.25)


func _capture_card_trade() -> void:
	_start_capture_run("spicy")
	main.run.pending_route_node = {
		"id": "trailer_card_trade",
		"type": "event",
		"label": "Friendly Trader",
		"event_outcome": "trade_card",
		"trading_card_id": "spicy_wasabi_wasp",
		"getting_card_id": "funky_eggplant_ant",
	}
	main._show_route_event()
	await _settle(18)
	await _fade_from_dark(0.38)
	await _hold(1.25)
	await main._resolve_route_event(
		"trade_card",
		"spicy_wasabi_wasp",
		"funky_eggplant_ant"
	)


func _capture_hand_trap_response() -> void:
	var tabletop: Node = await _open_trailer_match(
		"spicy",
		"hearty",
		"Rival Mina",
		20260902,
		14
	)
	if tabletop == null:
		return
	_stage_hand_trap_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.34)
	await _hold(0.72)
	tabletop.animation_busy = true
	tabletop.service._play_ingredient(tabletop.state, "opponent", 0, "prep")
	await tabletop._drain_animation_event_queue()
	tabletop.animation_busy = false
	tabletop._render_match()
	await _hold(1.2)
	await tabletop._resolve_reaction(0)
	await _hold(1.25)


func _capture_saladmander_summon() -> void:
	var tabletop: Node = await _open_trailer_match(
		"hearty",
		"spicy",
		"Rival Kai",
		20260903,
		14
	)
	if tabletop == null:
		return
	_stage_saladmander_summon_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.30)
	await _hold(0.72)
	await tabletop._play_hand_card(0, "plated", 1)
	await _hold(0.48)
	var ingredient_id := int(tabletop.get_meta("trailer_saladmander_ingredient_id", -1))
	tabletop.service.toggle_ingredient_selection(tabletop.state, ingredient_id)
	tabletop._render_match()
	await _hold(0.62)
	await tabletop._confirm_meal_play()
	await _hold(1.55)


func _capture_sweet_jellyfish_bounce() -> void:
	var tabletop: Node = await _open_trailer_match(
		"hearty",
		"spicy",
		"Rival Remy",
		20260904,
		14
	)
	if tabletop == null:
		return
	_stage_sweet_jellyfish_bounce_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.30)
	await _hold(0.72)
	await tabletop._play_hand_card(0, "prep", 1)
	await _hold(0.68)
	var bounce_target_id := int(tabletop.get_meta("trailer_bounce_target_id", -1))
	# Drive the same production motion directly here; calling the nested async
	# target handler makes Godot's macOS Movie Maker intermittently drop frames.
	await _animate_trailer_bounce(tabletop, bounce_target_id)
	tabletop.animation_busy = true
	tabletop.service.choose_effect_target(tabletop.state, bounce_target_id)
	await tabletop._drain_animation_event_queue()
	tabletop.animation_busy = false
	tabletop._render_match()
	await _hold(1.35)


func _capture_firecracker_bench_hit() -> void:
	var tabletop: Node = await _open_trailer_match(
		"spicy",
		"hearty",
		"Rival Mina",
		20260905,
		16
	)
	if tabletop == null:
		return
	_stage_firecracker_bench_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.30)
	await _hold(0.72)
	var shrimp_id := int(tabletop.get_meta("trailer_firecracker_id", -1))
	var defender_id := int(tabletop.get_meta("trailer_firecracker_defender_id", -1))
	var bench_target_id := int(tabletop.get_meta("trailer_firecracker_bench_id", -1))
	await _drag_attack_to_unit(tabletop, shrimp_id, defender_id, 0.56, 0.46)
	await _hold(0.70)
	await tabletop._choose_effect_target_animated(bench_target_id)
	await _hold(1.45)


func _capture_shop_purchase() -> void:
	_start_capture_run("spicy")
	main.run.money = 30
	main.run.pending_route_node = {
		"id": "trailer_shop",
		"type": "shop",
		"label": "Corner Card Counter",
		"inventory": [
			"spicy_jalapeno_panther",
			"item_switchblade",
			"spicy_hot_honey_bee",
			"spicy_sriracharrow",
		],
		"shopkeeper_card_id": "spicy_jalapeno_panther",
	}
	main._show_route_shop()
	await _settle(18)
	var inventory: Array = main.run.get("pending_route_node", {}).get("inventory", [])
	if inventory.is_empty():
		push_error("Trailer shop clip did not generate card inventory.")
		return
	var card_id := "spicy_sriracharrow" if inventory.has("spicy_sriracharrow") else String(inventory[0])
	await _fade_from_dark(0.42)
	await _hold(1.4)
	main._select_route_shop_card(card_id)
	await _hold(0.85)
	await main._route_shop_buy_card(card_id)
	await _hold(1.75)


func _capture_reward_pack() -> void:
	_start_capture_run("spicy")
	main.run.pending_route_node = {
		"id": "trailer_reward",
		"type": "enemy",
		"label": "Park Regular Jules",
	}
	main.run.reward_offer = [
		"spicy_hot_honey_bee",
		"spicy_jalapeno_panther",
		"spicy_sriracharrow",
	]
	main.run.reward_picks_remaining = main.run.reward_offer.size()
	main.run.reward_selected = []
	main.run.route_pack_presented = true
	main.run.route_pack_opened = false
	main.run.route_reward_intro_seen = true
	main._show_route_sealed_pack()
	await _settle(16)
	await _fade_from_dark(0.42)
	await _hold(1.35)
	main._crack_route_victory_pack()
	await _hold(1.65)
	var offer: Array = main.run.get("reward_offer", [])
	if offer.is_empty():
		push_error("Trailer reward clip did not generate a card offer.")
		return
	var card_id := "spicy_sriracharrow" if offer.has("spicy_sriracharrow") else String(offer[0])
	main._select_route_reward_card(card_id)
	await _hold(0.75)
	main._pick_route_reward(card_id)
	await _hold(1.75)


func _capture_upgrade_foil() -> void:
	_start_capture_run("spicy")
	main.run.money = 30
	main.run.pending_route_node = {
		"id": "trailer_upgrade_shop",
		"type": "shop",
		"label": "Corner Card Counter",
	}
	main._show_route_shop()
	await _settle(16)
	await _fade_from_dark(0.42)
	await _hold(1.0)
	main._show_route_upgrade_card()
	await _hold(1.05)
	var candidates: Array[String] = main.route_run_service.upgradeable_card_ids(main.run)
	if candidates.is_empty():
		push_error("Trailer upgrade clip has no eligible card.")
		return
	candidates.sort()
	var card_id := "spicy_hot_honey_bee" if candidates.has("spicy_hot_honey_bee") else String(candidates[0])
	main._select_route_shop_service_card("upgrade", card_id)
	await _hold(0.65)
	await main._route_upgrade_card(card_id)
	await _hold(1.65)


func _capture_battle_combo() -> void:
	var tabletop: Node = await _open_trailer_match(
		"hearty",
		"fresh",
		"Rival Jules",
		20260807,
		12
	)
	if tabletop == null:
		return
	_stage_hearty_board(tabletop)
	await _settle(8)
	await _fade_from_dark(0.42)
	await _hold(1.25)
	var gazelle_id := int(tabletop.get_meta("trailer_gazelle_id", -1))
	var lasagnama_id := int(tabletop.get_meta("trailer_lasagnama_id", -1))
	var defender_id := int(tabletop.get_meta("trailer_defender_id", -1))
	await tabletop._activate_ability(gazelle_id, "gravy_gazelle_buff")
	await _hold(0.55)
	await tabletop._choose_ability_target_animated(lasagnama_id)
	await _hold(0.78)
	await _drag_attack_to_unit(tabletop, lasagnama_id, defender_id, 0.55, 0.46)
	await _hold(0.55)
	await _drag_attack_to_chef(tabletop, gazelle_id, 0.58, 0.5)
	await _hold(1.05)


func _capture_city_champion() -> void:
	_start_capture_run("sweet")
	await _settle(30)
	await _fade_from_dark(0.34)
	await _hold(0.5)
	main.run.pending_route_node = {
		"id": "trailer_city_champion",
		"type": "final_boss",
		"label": "Starter City Champion",
	}
	main._start_route_battle()
	await _hold(3.8)


func _start_capture_run(starter_id: String) -> void:
	main.rng.seed = 20260827
	main._start_new_run_with_mode(starter_id, "season", "white")
	main.autosave_enabled = false
	main.autosave_suspended = true
	main.player_settings.reduced_motion = false


func _open_trailer_match(
	starter_id: String,
	opponent_affinity: String,
	opponent_label: String,
	battle_seed: int,
	opponent_life: int
) -> Node:
	_start_capture_run(starter_id)
	main.run.route_battle = {
		"active": true,
		"node_id": "trailer_battle_%d" % battle_seed,
		"node_type": "enemy",
		"label": opponent_label,
		"seed": battle_seed,
		"opponent_affinity": opponent_affinity,
		"opponent_life": opponent_life,
		"ai": "easy",
		"intro_seen": true,
		"location": "Starter City Table",
	}
	var opponent_deck: Dictionary = main._opponent_deck_for_round(opponent_affinity, 1)
	main._begin_kitchen_match(
		main.run.get("deck", {}),
		opponent_deck,
		opponent_label,
		false,
		battle_seed,
		"player",
		"easy",
		{},
		{
			"player_life": 32,
			"player_max_life": 40,
			"opponent_life": opponent_life,
			"opponent_max_life": opponent_life,
			"turn_hand_floor": 3,
			"reshuffle_pressure": true,
			"reshuffle_damage": [3, 5, 7],
		}
	)
	await _settle(24)
	var tabletop: Node = main.find_child("Tabletop3DPrototype", true, false)
	if tabletop == null:
		push_error("Trailer battle clip could not create the Living Table.")
	return tabletop


func _drag_attack_to_unit(
	tabletop: Node,
	attacker_id: int,
	defender_id: int,
	travel_duration: float,
	valid_hold: float
) -> void:
	var attacker_card: Node3D = tabletop._card_node_for_instance(attacker_id)
	var defender_card: Node3D = tabletop._card_node_for_instance(defender_id)
	if attacker_card == null or defender_card == null:
		push_error("Trailer attack drag could not find its field cards.")
		return
	var source_world := attacker_card.position
	var target_world := defender_card.position
	var source_screen: Vector2 = tabletop._world_to_container(attacker_card.global_position)
	var target_screen: Vector2 = tabletop._world_to_container(defender_card.global_position)
	tabletop.pressed_card = attacker_card
	tabletop._begin_drag(source_world, source_screen)
	await _animate_field_drag(tabletop, source_world, target_world, source_screen, target_screen, travel_duration)
	await _hold(valid_hold)
	await tabletop._finish_drag(target_world, target_screen)


func _drag_attack_to_chef(
	tabletop: Node,
	attacker_id: int,
	travel_duration: float,
	valid_hold: float
) -> void:
	var attacker_card: Node3D = tabletop._card_node_for_instance(attacker_id)
	if attacker_card == null:
		push_error("Trailer direct-attack drag could not find its attacker.")
		return
	var source_world := attacker_card.position
	var target_world: Vector3 = tabletop.opponent_chef.position
	var source_screen: Vector2 = tabletop._world_to_container(attacker_card.global_position)
	var target_screen: Vector2 = tabletop._world_to_container(tabletop.opponent_chef.global_position)
	tabletop.pressed_card = attacker_card
	tabletop._begin_drag(source_world, source_screen)
	await _animate_field_drag(tabletop, source_world, target_world, source_screen, target_screen, travel_duration)
	await _hold(valid_hold)
	await tabletop._finish_drag(target_world, target_screen)


func _drag_switch_to_slot(
	tabletop: Node,
	mover_id: int,
	zone_id: String,
	slot_index: int,
	travel_duration: float,
	valid_hold: float
) -> void:
	var mover_card: Node3D = tabletop._card_node_for_instance(mover_id)
	if mover_card == null:
		push_error("Trailer zone-switch drag could not find its source card.")
		return
	var source_world := mover_card.position
	var target_world: Vector3 = tabletop._slot_world_position(zone_id, slot_index)
	var source_screen: Vector2 = tabletop._world_to_container(mover_card.global_position)
	var target_screen: Vector2 = tabletop._world_to_container(target_world)
	tabletop.pressed_card = mover_card
	tabletop._begin_drag(source_world, source_screen)
	await _animate_field_drag(tabletop, source_world, target_world, source_screen, target_screen, travel_duration)
	await _hold(valid_hold)
	await tabletop._finish_drag(target_world, target_screen)


func _animate_field_drag(
	tabletop: Node,
	source_world: Vector3,
	target_world: Vector3,
	source_screen: Vector2,
	target_screen: Vector2,
	duration: float
) -> void:
	var frame_count := maxi(2, int(ceil(duration * 30.0)))
	for frame_index in range(frame_count):
		var weight := float(frame_index + 1) / float(frame_count)
		var eased_weight := ease(weight, 0.65)
		tabletop._update_drag(
			source_world.lerp(target_world, eased_weight),
			source_screen.lerp(target_screen, eased_weight)
		)
		await process_frame


func _animate_trailer_bounce(tabletop: Node, target_instance_id: int) -> void:
	var target_card: Node3D = tabletop._card_node_for_instance(target_instance_id)
	if target_card == null:
		push_error("Trailer bounce could not find its opposing card.")
		return
	var hand_anchor: Node3D = tabletop._hand_card_node("opponent", 0)
	var destination := target_card.position + Vector3(0.0, 1.0, -3.8)
	if hand_anchor != null:
		destination = hand_anchor.position + Vector3(0.72, 0.16, 0.0)
	var origin := target_card.position
	var origin_rotation := target_card.rotation_degrees
	var origin_scale := target_card.scale
	var midpoint := origin.lerp(destination, 0.5) + Vector3(0.0, 1.45, 0.0)
	var accent := Color("#26C7ED")
	tabletop._play_random_card_sound(tabletop.SLIDE_CARD_SOUNDS, -1.0, 0.04)
	tabletop._spawn_movement_trail_screen(
		tabletop._world_to_container(origin + Vector3(0.0, 0.24, 0.0)),
		tabletop._world_to_container(destination + Vector3(0.0, 0.24, 0.0)),
		accent
	)
	tabletop._play_graphic_vfx_world("card_land", origin, accent)
	tabletop._spawn_particle_burst(origin + Vector3(0.0, 0.24, 0.0), accent, 11, "◆")
	var movement := target_card.create_tween()
	movement.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	movement.tween_property(target_card, "position", midpoint, 0.24)
	movement.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	movement.tween_property(target_card, "position", destination, 0.34)
	var pose := target_card.create_tween().set_parallel(true)
	pose.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	pose.tween_property(target_card, "rotation_degrees", origin_rotation + Vector3(-34.0, 360.0, 14.0), 0.58)
	pose.tween_property(target_card, "scale", origin_scale * 0.54, 0.58)
	await movement.finished
	tabletop._spawn_particle_burst(destination + Vector3(0.0, 0.2, 0.0), accent, 13, "✦")
	tabletop._play_graphic_vfx_world("card_land", destination, accent)
	tabletop._start_camera_impact("player", 0.10)


func _center_route_destination(graph: Node, destinations: Array[String]) -> String:
	var selected_id := destinations[0]
	var best_distance := INF
	for destination_id in destinations:
		var node_data: Dictionary = graph.nodes.get(destination_id, {})
		var position: Vector3 = node_data.get("position", Vector3.ZERO)
		var distance := absf(position.z - 4.2)
		if distance < best_distance:
			best_distance = distance
			selected_id = destination_id
	return selected_id


func _stage_attack_hook_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.hand = [
		"spicy_sriracharrow",
		"item_switchblade",
		"spice_cayenne_crunch",
	]
	state.player.deck = ["spicy_jalapeno_panther", "spicy_wasabi_wasp"]
	state.player.environment = "environment_spicy_taqueria"
	state.opponent.life = 10
	state.opponent.max_life = 10
	state.opponent.deck = ["fresh_sprout_squirrel", "fresh_crisp_capybara"]
	var attacker := _add_unit(tabletop, "player", "spicy_hot_honey_bee", "plated", 1, true)
	_add_unit(tabletop, "player", "spicy_jalapeno_panther", "prep", 0, false)
	_add_unit(tabletop, "opponent", "fresh_sprout_squirrel", "prep", 0, false)
	_add_unit(tabletop, "opponent", "fresh_crisp_capybara", "prep", 2, false)
	tabletop.set_meta("trailer_attacker_id", int(attacker.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _stage_zone_control_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.hand = [
		"hearty_ramen_ram",
		"spice_savory_gravy",
		"item_wooden_spoon",
	]
	state.player.deck = ["hearty_kale_whale", "hearty_french_bread_dog"]
	state.player.environment = "environment_hearty_diner"
	state.opponent.deck = ["fresh_sprout_squirrel", "fresh_crisp_capybara"]
	var mover := _add_unit(tabletop, "player", "hearty_gravy_gazelle", "prep", 1, false)
	_add_unit(tabletop, "player", "hearty_bagver", "plated", 0, true)
	_add_unit(tabletop, "opponent", "fresh_saladmander", "plated", 1, true)
	_add_unit(tabletop, "opponent", "fresh_sprout_squirrel", "prep", 2, false)
	tabletop.set_meta("trailer_mover_id", int(mover.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _reset_trailer_board_state(state: Dictionary) -> void:
	state.turn = 4
	state.phase = "player_main"
	state.first_player = "opponent"
	state.game_over = false
	state.winner = ""
	state.selected_attacker = -1
	state.selected_ingredients = []
	state.pending_meal = {}
	state.pending_discard = {}
	state.pending_ability = {}
	state.pending_search = {}
	state.pending_choice = {}
	state.pending_resume = {}
	state.pending_reaction = {}
	state.animation_events = []
	state.player.life = 32
	state.player.turns_started = 2
	state.player.hand = []
	state.player.deck = []
	state.player.prep = []
	state.player.plated = []
	state.player.discard = []
	state.player.environment = ""
	state.player.meal_served = false
	state.player.zone_move_used = false
	state.player.chef_used = false
	state.opponent.life = 12
	state.opponent.turns_started = 2
	state.opponent.hand = []
	state.opponent.deck = []
	state.opponent.prep = []
	state.opponent.plated = []
	state.opponent.discard = []
	state.opponent.environment = ""


func _stage_hearty_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.life = 32
	state.opponent.life = 12
	state.player.hand = [
		"hearty_ramen_ram",
		"spice_savory_gravy",
		"item_wooden_spoon",
		"hearty_polar_pot_pie_bear",
	]
	state.player.deck = ["hearty_bagver", "hearty_french_bread_dog", "hearty_kale_whale"]
	state.player.discard = ["hearty_macaroni_manatee"]
	state.player.environment = "environment_hearty_diner"
	state.player.meal_served = false
	state.player.zone_move_used = false
	state.player.chef_used = false
	state.opponent.deck = ["fresh_sprout_squirrel", "fresh_crisp_capybara"]

	var gazelle := _add_unit(tabletop, "player", "hearty_gravy_gazelle", "plated", 0, true)
	var lasagnama := _add_unit(tabletop, "player", "hearty_lasagnama", "plated", 1, true)
	_add_unit(tabletop, "player", "hearty_bagver", "prep", 1, false)
	var defender := _add_unit(tabletop, "opponent", "fresh_saladmander", "plated", 0, true)
	tabletop.set_meta("trailer_gazelle_id", int(gazelle.instance_id))
	tabletop.set_meta("trailer_lasagnama_id", int(lasagnama.instance_id))
	tabletop.set_meta("trailer_defender_id", int(defender.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _stage_hand_trap_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.turn = 5
	state.phase = "opponent_turn"
	state.player.hand = [
		"funky_chef_check_chinchilla",
		"spicy_sriracharrow",
		"item_switchblade",
	]
	state.player.deck = ["spicy_jalapeno_panther", "funky_beat_beetle"]
	state.player.environment = "environment_spicy_taqueria"
	state.player.hand_trap_used = false
	state.opponent.hand = ["hearty_macaroni_manatee"]
	state.opponent.deck = ["hearty_bagver", "hearty_kale_whale"]
	state.opponent.hand_trap_used = false
	_add_unit(tabletop, "player", "spicy_hot_honey_bee", "plated", 0, true)
	_add_unit(tabletop, "player", "funky_fondue_ferret", "prep", 1, false)
	_add_unit(tabletop, "opponent", "hearty_bagver", "plated", 0, true)
	_add_unit(tabletop, "opponent", "hearty_lasagnama", "prep", 2, false)
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _stage_saladmander_summon_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.hand = [
		"fresh_saladmander",
		"hearty_ramen_ram",
		"item_wooden_spoon",
	]
	state.player.deck = ["fresh_crisp_capybara", "fresh_salad_shield_skunk"]
	state.player.environment = "environment_fresh_greensweet"
	state.opponent.deck = ["spicy_jalapeno_panther", "spicy_wasabi_wasp"]
	var ingredient := _add_unit(tabletop, "player", "fresh_sprout_squirrel", "prep", 1, true)
	ingredient.recipe_ready_on_turn = int(state.player.turns_started)
	_add_unit(tabletop, "player", "hearty_bagver", "plated", 0, true)
	_add_unit(tabletop, "opponent", "spicy_jalapeno_panther", "plated", 0, true)
	_add_unit(tabletop, "opponent", "spicy_wasabi_wasp", "prep", 2, false)
	tabletop.set_meta("trailer_saladmander_ingredient_id", int(ingredient.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _stage_sweet_jellyfish_bounce_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.hand = [
		"sweet_jellyfish",
		"sweet_strawberry_sharkcake",
		"sweet_sugar_glider",
	]
	state.player.deck = ["sweet_caramel_camel", "sweet_soft_serve_crab"]
	state.player.environment = "environment_sweet_bakery"
	state.opponent.hand = ["item_switchblade"]
	state.opponent.deck = ["spicy_hot_honey_bee", "spicy_wasabi_wasp"]
	_add_unit(tabletop, "player", "sweet_soft_serve_crab", "plated", 0, true)
	var bounce_target := _add_unit(tabletop, "opponent", "spicy_jalapeno_panther", "plated", 1, true)
	_add_unit(tabletop, "opponent", "spicy_firecracker_shrimp", "plated", 2, true)
	_add_unit(tabletop, "opponent", "spicy_hot_honey_bee", "prep", 0, false)
	tabletop.set_meta("trailer_bounce_target_id", int(bounce_target.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _stage_firecracker_bench_board(tabletop: Node) -> void:
	var state: Dictionary = tabletop.state
	_reset_trailer_board_state(state)
	state.player.hand = [
		"spicy_sriracharrow",
		"spice_cayenne_crunch",
		"item_switchblade",
	]
	state.player.deck = ["spicy_hot_honey_bee", "spicy_jalapeno_panther"]
	state.player.environment = "environment_spicy_taqueria"
	state.opponent.deck = ["hearty_bagver", "hearty_kale_whale"]
	var shrimp := _add_unit(tabletop, "player", "spicy_firecracker_shrimp", "plated", 1, true)
	_add_unit(tabletop, "player", "spicy_hot_honey_bee", "prep", 0, false)
	var defender := _add_unit(tabletop, "opponent", "hearty_lasagnama", "plated", 1, true)
	_add_unit(tabletop, "opponent", "hearty_bagver", "prep", 0, false)
	var bench_target := _add_unit(tabletop, "opponent", "hearty_macaroni_manatee", "prep", 2, false)
	tabletop.set_meta("trailer_firecracker_id", int(shrimp.instance_id))
	tabletop.set_meta("trailer_firecracker_defender_id", int(defender.instance_id))
	tabletop.set_meta("trailer_firecracker_bench_id", int(bench_target.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _add_unit(
	tabletop: Node,
	side: String,
	card_id: String,
	zone: String,
	slot: int,
	ready: bool
) -> Dictionary:
	var combatant: Dictionary = tabletop.state[side]
	var unit: Dictionary = tabletop.service._make_unit(
		tabletop.state,
		combatant,
		tabletop.service.card(card_id),
		zone,
		side
	)
	unit.table_slot = slot
	unit.ready = ready
	combatant[zone].append(unit)
	return unit


func _create_curtain() -> void:
	curtain = ColorRect.new()
	curtain.name = "TrailerCurtain"
	curtain.position = Vector2.ZERO
	curtain.size = Vector2(CAPTURE_SIZE)
	curtain.color = CURTAIN_COLOR
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.z_index = 4095
	root.add_child(curtain)


func _fade_from_dark(duration: float) -> void:
	curtain.visible = true
	var tween := curtain.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(curtain, "color:a", 0.0, duration)
	await tween.finished
	curtain.visible = false


func _fade_to_dark(duration: float) -> void:
	curtain.visible = true
	var tween := curtain.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(curtain, "color:a", 1.0, duration)
	await tween.finished


func _hold(seconds: float) -> void:
	await create_timer(seconds).timeout


func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame
