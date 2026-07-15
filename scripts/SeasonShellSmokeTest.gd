extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.cards_by_id.size() == 61, "Season shell did not load all 61 kitchen cards.")
	_expect(main.archetypes_by_id.size() == 3, "Season shell did not build the three kitchen archetypes.")
	_expect(main.boosters_by_id.size() == 2, "Season shell did not load booster definitions.")
	_expect(main.tournaments_by_id.size() == 5, "Season shell did not load the tournament calendar.")
	_expect(main.current_screen == "start", "Season shell did not open on the season/debug menu.")

	main._start_new_run_with_mode("spicy", "debug", "white")
	await process_frame
	_expect(main.current_screen == "shop", "Debug run did not open the shop.")
	_expect(main._deck_total(main.run.deck) == 30, "Kitchen starter deck is not 30 cards.")
	_expect(main.run.shop.size() == 8, "Shop did not generate eight singles.")

	var collection_before: int = main._deck_total(main.run.collection)
	var pack: Array = main._generate_pack("base_standard_pack")
	_expect(pack.size() == 6, "Base booster did not generate six cards.")
	main._start_pack(pack)
	main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
	_expect(main._deck_total(main.run.collection) == collection_before + 6, "Revealed booster cards did not enter the collection.")

	main._show_deckbuilder()
	await process_frame
	_expect(main.current_screen == "deck", "Deckbuilder did not open.")
	main._show_meta()
	await process_frame
	_expect(main.current_screen == "meta", "Metagame screen did not open.")

	main._start_debug_kitchen_match()
	await process_frame
	await process_frame
	_expect(main.current_screen == "kitchen_match", "Debug menu did not launch Kitchen Table TCG.")
	_expect(main.find_child("KitchenGameRoot", true, false) != null, "Kitchen match board did not render inside the season shell.")
	main._on_kitchen_match_finished({
		"winner": "player",
		"turn": 4,
		"player_life": 12,
		"opponent_life": 0
	})
	main._on_kitchen_exit_requested()
	await process_frame
	_expect(main.current_screen == "shop", "Debug Kitchen Match did not return to the shell.")

	main._start_new_run_with_mode("hearty", "season", "white")
	await process_frame
	_expect(main.current_screen == "season", "Season run did not open the calendar.")
	_expect(main._season_calendar_ids().size() == 5, "Season calendar does not contain five events.")
	_expect(main._selected_season_event_id() == "weekly_locals", "Weekly Locals was not the opening event.")

	main._start_season_tournament()
	await process_frame
	await process_frame
	_expect(main.current_screen == "kitchen_match", "Tournament round did not launch a Kitchen Match.")
	_expect(main._season_tournament_active(), "Tournament state was not created.")

	var winners := ["player", "player", "opponent"]
	for index in range(winners.size()):
		if index > 0:
			main._start_season_tournament_round()
			await process_frame
			await process_frame
			_expect(main.current_screen == "kitchen_match", "Later tournament round did not launch Kitchen Match.")
		main._on_kitchen_match_finished({
			"winner": winners[index],
			"turn": 5 + index,
			"player_life": 10 if winners[index] == "player" else 0,
			"opponent_life": 0 if winners[index] == "player" else 8
		})
		main._on_kitchen_exit_requested()
		await process_frame
		await process_frame

	_expect(main._season_event_completed("weekly_locals"), "A 2-1 Locals result did not advance the calendar.")
	_expect(main._season_event_unlocked("monthly_regionals"), "Monthly Regionals did not unlock.")
	_expect(not main._season_tournament_active(), "Completed tournament remained active.")
	_expect(main.current_screen == "result", "Completed tournament did not show its result screen.")

	main.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("Kitchen season shell smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
