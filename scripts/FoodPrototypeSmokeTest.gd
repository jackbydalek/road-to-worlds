extends SceneTree

const FOOD := preload("res://scripts/FoodPrototype.gd")
const STANDARD_SAVE := "/private/tmp/food_prototype_standard_test.json"
const PROTOTYPE_SAVE := "/private/tmp/food_prototype_isolated_test.json"
const OUTPUT := "res://outputs/food_prototype_2026-09-22/"
var failed := false
var main
var large_text := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	large_text = "--large-text" in OS.get_cmdline_user_args()
	root.size = Vector2i(1440, 900) if large_text else Vector2i(1280, 720)
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.run_state_service.save_path = STANDARD_SAVE
	main.food_prototype_save_path = PROTOTYPE_SAVE
	main.autosave_enabled = true
	main.player_settings.reduced_motion = true
	main.player_settings.play_speed = "fast"
	if large_text:
		main.player_settings.text_scale = 1.25
		main._apply_accessibility_to_tree()
	main._start_new_run_with_mode("spicy", "season", "white")
	await _settle()
	main._show_start()
	await _settle()
	var original := FileAccess.get_file_as_string(STANDARD_SAVE)
	var button := main.find_child("FoodPrototypeButton", true, false) as Button
	_expect(button != null and button.visible, "Title entry missing.")
	var title = main.find_child("BootLanding", true, false)
	_expect(title.get_menu_sheet_rect().encloses(button.get_rect()), "Prototype entry overflows title menu.")
	await _capture("01_title")
	button.pressed.emit()
	await _settle()
	_expect(main.current_screen == "food_prototype_menu", "Title entry did not open prototype menu.")
	await _capture("02_menu")
	main._start_food_prototype(920026)
	await _settle()
	_expect(main._deck_total(main.run.deck) == 15, "Starter must contain 15 cards before opening pick.")
	for id in main.run.deck:
		_expect(main.cards_by_id[id].archetype == "neutral", "Starter contains a typed card.")
		_expect(main.CARD_FACE_SCRIPT.supports_card(main.cards_by_id[id]), "Neutral starter uses fallback battle rendering.")
	_expect(main.run.food_opening_offer.size() == 3, "Opening offer must have three cards.")
	var opening: Array = main.run.food_opening_offer.duplicate()
	await _capture("03_opening")
	main._show_start()
	await _settle()
	_expect(main.run_state_service.save_path == STANDARD_SAVE, "Title did not restore standard save path.")
	_expect(not main.cards_by_id.has("prototype_basic_bite"), "Prototype cards leaked into normal catalog.")
	_expect(main.cards_by_id.spicy_sriracharrow.recipe == ["spicy"], "Normal recipes were changed.")
	main._show_food_prototype_menu()
	await _settle()
	main._continue_run_to_shop()
	await _settle()
	_expect(main.current_screen == "food_prototype_opening" and main.run.food_opening_offer == opening, "Opening choice did not resume unchanged.")
	main._choose_food_prototype_opening(String(opening[0]))
	await _settle()
	main._choose_food_prototype_opening(String(opening[0]))
	_expect(main._deck_total(main.run.deck) == 16, "Opening pick was duplicated or lost.")
	_expect(main.current_screen == "route_hub", "Opening did not enter the hub.")
	await _capture("04_hub")
	main._open_hub_shop()
	await _settle()
	await _capture("05_shop")
	main._leave_hub_shop()
	await _settle()
	var seen := {}
	for seed_value in range(150):
		for id in main.route_run_service.generate_reward_offer(FOOD.ID, "enemy", seed_value, [], main.run):
			var card: Dictionary = main.cards_by_id[id]
			seen[String(card.archetype)] = true
			_expect(not card.get("starter_only", false) and int(card.get("unlock_week", 1)) <= 1 and card.card_type != "spice", "Reward pool includes starter-only or week-two content.")
		main.rng.seed = seed_value
		main.shop_economy_service.generate_shop_inventory(main.run, FOOD.ID)
		for id in main.run.shop:
			_expect(main.shop_economy_service.card_is_starter_eligible(main.cards_by_id[id], FOOD.ID), "Invalid shop card.")
	for affinity in ["spicy", "hearty", "sweet", "fresh", "funky"]:
		_expect(seen.has(affinity), "Reward pool excluded " + affinity)
	for card in main.cards:
		if card.card_type == "meal":
			for requirement in card.recipe:
				_expect(requirement == "any", "Printed prototype recipe is typed.")
	main.route_run_service.upgrade_card(main.run, "prototype_simple_serve")
	main._start_next_hub_round()
	await _settle()
	main._begin_route_battle_from_intro()
	await _settle(8)
	var table = main.find_child("Tabletop3DPrototype", true, false)
	_expect(table != null, "Prototype battle failed to mount.")
	if table == null:
		quit(1)
		return
	_expect(table.service.card("spicy_sriracharrow").recipe == ["any"], "Rival recipe was not generic.")
	_expect(table.service.card("prototype_simple_serve__route_upgraded").recipe == ["any"], "Upgraded starter missing generic recipe.")
	_expect(table.service.card("prototype_basic_bite").attack == 2, "Neutral starter was not loaded into combat.")
	_expect(not table.state.run_rules.special_serve_enabled, "Week-two Special Serve enabled in prototype.")
	await _capture("06_battle")
	# Exercise production legality with a neutral Ingredient, including readiness.
	var service = table.service
	var state: Dictionary = table.state.duplicate(true)
	state.player.prep = []
	state.player.plated = []
	var unit: Dictionary = service._make_unit(state, state.player, service.card("prototype_basic_bite"), "prep", "player")
	state.player.prep.append(unit)
	_expect(service._find_recipe_ingredients(state.player, ["any"]).is_empty(), "Freshly played Ingredient became recipe-ready too early.")
	unit.recipe_ready_on_turn = 0
	_expect(service._find_recipe_ingredients(state.player, ["any"]).size() == 1, "Neutral Ingredient cannot pay generic recipe.")
	_expect(service._find_recipe_ingredients(state.player, ["any", "any"]).is_empty(), "One Ingredient paid two sacrifices.")
	state.player.hand = ["spicy_sriracharrow"]
	service.begin_meal_play(state, 0)
	service.toggle_ingredient_selection(state, int(unit.instance_id))
	_expect(service.meal_selection_is_ready(state), "Neutral Ingredient was not selectable for a Spicy Meal.")
	service.confirm_meal_play(state)
	_expect(state.player.prep.is_empty() and state.player.plated.size() == 1 and state.player.plated[0].card_id == "spicy_sriracharrow", "Generic recipe did not sacrifice and serve correctly.")
	_expect(not service._can_serve_meal(state.player), "Generic serving bypassed the normal Meal limit.")
	table.state.player.life = 31
	main._autosave_now("kitchen_match")
	main._show_start()
	await _settle()
	main._show_food_prototype_menu()
	await _settle()
	main._continue_run_to_shop()
	await _settle(8)
	table = main.find_child("Tabletop3DPrototype", true, false)
	_expect(table != null and int(table.state.player.life) == 31, "Battle checkpoint was not restored.")
	_expect(table.service.card("spicy_sriracharrow").recipe == ["any"], "Battle reload lost ruleset.")
	# Walk the saved reward transitions through all four rounds (outcomes injected).
	for round_number in range(1, 5):
		main.run.hub_round = round_number
		main.run.pending_route_node = main._hub_round_node(round_number)
		main.run.route_battle = {"active": true, "node_id": main.run.pending_route_node.id, "node_type": main.run.pending_route_node.type, "seed": 90 + round_number, "label": "Test Rival"}
		main._finish_route_battle(true, 30)
		await _settle(5)
		var reward: String = main.run.reward_offer[0]
		main._pick_route_reward(reward)
		await _settle(5)
		main._finish_route_reward()
		await _settle(5)
	_expect(main.run.run_over and main.run.demo_complete and main.run.week == 1, "Prototype did not finish after four rounds.")
	_expect(main.run.week_transition == "", "Prototype entered week two.")
	await _capture("07_results")
	var final_deck: Dictionary = main.run.deck.duplicate(true)
	main._show_start()
	await _settle()
	_expect(FileAccess.get_file_as_string(STANDARD_SAVE) == original, "Prototype modified the normal save.")
	_expect(main.cards_by_id.spicy_sriracharrow.recipe == ["spicy"], "Exiting prototype failed to restore normal costs.")
	main._show_food_prototype_menu()
	await _settle()
	var saved: Dictionary = main.run_state_service.load_run()
	_expect(saved.run.deck == final_deck and saved.run.run_over, "Completed prototype save lost deck or completion.")
	_expect(not saved.run.food_playtest_log.is_empty(), "Playtest choices were not logged.")
	_expect(main.find_child("ContinueFoodPrototypeButton", true, false) == null, "Finished prototype still offers Continue.")
	main.autosave_enabled = false
	main._release_audio_streams()
	main.queue_free()
	await _settle()
	print("Food prototype smoke test %s." % ("FAILED" if failed else "passed"))
	quit(1 if failed else 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _settle(frames: int = 4) -> void:
	for unused in range(frames):
		await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var directory := OUTPUT + ("large_text/" if large_text else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(directory + name + ".png"))
