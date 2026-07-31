extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const OUTPUT_DIR := "res://outputs/sketch_campaign"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	main._show_settings()
	await _settle()
	await _capture("00_settings.png")
	main._show_start()
	await _settle()

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
	await _settle()
	await _capture("01_season_calendar.png")

	main._show_shop_overworld()
	await create_timer(1.15).timeout
	await _settle()
	await _capture("02_card_store.png")
	root.size = Vector2i(704, 486)
	await _settle()
	await _capture("02d_compact_store.png")
	root.size = Vector2i(1440, 900)
	await _settle()
	main._show_autosave_indicator()
	await create_timer(0.2).timeout
	await _capture("02c_saving_toast.png")
	await create_timer(0.85).timeout
	var shop_world := main.find_child("CardShopOverworld", true, false)
	if shop_world != null:
		main.run.active_tournament = {
			"active": true,
			"event_id": "weekly_locals",
			"event_name": "Weekly Locals",
			"round": 2,
		}
		shop_world.call("update_shop_context", main._shop_overworld_context())
		await _settle()
		await _capture("02a_start_round.png")
		main.run.active_tournament = {}
		shop_world.call("update_shop_context", main._shop_overworld_context())
		shop_world.call("_show_menu")
		await create_timer(0.9).timeout
		await _settle()
		await _capture("02b_shopkeeper_menu.png")
		shop_world.call("_show_singles_case")
		await _settle()
		var in_scene_select := main.find_child("InSceneSingleSelect_*", true, false) as Button
		if in_scene_select != null:
			in_scene_select.emit_signal("pressed")
			await _settle()
		await _capture("03_singles_case.png")

	main._show_deckbuilder()
	await _settle()
	await _capture("04_deck_workshop.png")

	main._show_singles_shop()
	await _settle()
	var singles_select := main.find_child("CardShopSingleSelectButton_*", true, false) as Button
	if singles_select != null:
		singles_select.emit_signal("pressed")
		await _settle()
	await _capture("09_singles_browser.png")

	main.run.prize_packs = 1
	main._open_reward_pack_flow()
	await _settle()
	await _capture("05_pack_opening.png")

	main._finish_pack_state()
	main._show_tournament()
	await _settle()
	await _capture("06_tournament_registration.png")

	main.run.last_event_result = {
		"event_id": "weekly_locals",
		"event_name": "Weekly Locals",
		"stage": "Week 2",
		"wins": 3,
		"losses": 0,
		"rounds": 3,
		"required_wins": 3,
		"made_record": true,
		"reward_money": 14,
		"reward_packs": 1,
		"round_cash_earned": 9,
		"next_event_name": "League Cup",
		"run_over": false,
		"round_results": [
			{"round": 1, "opponent_name": "Mina", "opponent_archetype": "Sweet Starter", "won": true, "turn": 5, "player_life": 6, "cash": 2},
			{"round": 2, "opponent_name": "Cal", "opponent_archetype": "Sweet Starter", "won": true, "turn": 6, "player_life": 11, "cash": 3},
			{"round": 3, "opponent_name": "Local Rival Tess", "opponent_archetype": "Hearty Starter", "won": true, "turn": 3, "player_life": 12, "cash": 4},
		],
	}
	main.run.prize_packs = 1
	main._show_tournament_result(
		[
			"Round 1 vs Mina on Sweet Starter: Won. Turn 5, life 6-0, seed 2373465488.",
			"Round 2 vs Cal on Sweet Starter: Won. Turn 6, life 11-3, seed 2546198465.",
			"Round 3 vs Local Rival Tess on Hearty Starter: Won. Turn 3, life 12-0, seed 2679931114.",
		],
		true
	)
	await create_timer(0.3).timeout
	await _settle()
	await _capture("07_tournament_result.png")

	main.run.prize_packs = 0
	main.run.run_over = true
	main.run.last_event_result = {
		"event_id": "weekly_locals",
		"event_name": "Weekly Locals",
		"stage": "Week 2",
		"wins": 0,
		"losses": 1,
		"rounds": 3,
		"required_wins": 3,
		"made_record": false,
		"reward_money": 0,
		"reward_packs": 0,
		"round_cash_earned": 2,
		"run_over": true,
		"round_results": [
			{"round": 1, "opponent_name": "Mina", "opponent_archetype": "Sweet Starter", "won": false, "turn": 7, "player_life": 0, "cash": 2},
		],
	}
	main._show_tournament_result(
		["Round 1 vs Mina on Sweet Starter: Lost. Turn 7, life 0-4, seed 2373465488."],
		false
	)
	await create_timer(0.3).timeout
	await _settle()
	await _capture("07b_tournament_defeat.png")

	main._show_thanks_for_playing()
	await create_timer(0.75).timeout
	await _settle()
	await _capture("08_thanks.png")
	quit()


func _settle(frames: int = 3) -> void:
	for index in range(frames):
		await process_frame


func _capture(filename: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Sketch campaign capture requires a graphical compatibility renderer.")
		quit(1)
		return
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var result := image.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Could not save sketch campaign preview: " + path)
