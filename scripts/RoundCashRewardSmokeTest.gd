extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var event: Dictionary = main._season_event_by_id("weekly_locals")
	_expect(
		main.tournament_service.round_cash_reward(event, 1) == 2
		and main.tournament_service.round_cash_reward(event, 2) == 3
		and main.tournament_service.round_cash_reward(event, 3) == 4,
		"The Weekly Locals round payouts did not increase from $2 to $4."
	)

	_start_locals(main)
	main.current_screen = "kitchen_match"
	main.run.kitchen_match_result = _win_result()
	main._show_season_round_result_popup(true)
	await process_frame
	var earnings_label := main.find_child("SeasonRoundCashReward", true, false) as Label
	_expect(
		earnings_label != null and earnings_label.text == "ROUND EARNINGS  +$2",
		"The round result did not preview its cash payout."
	)
	main._dismiss_round_result_popup()

	for round_number in [1, 2, 3]:
		main.run.kitchen_match_result = _win_result()
		main._season_record_current_round_result()
		await process_frame
		var expected_round_cash := 2 + 3 + 4 if round_number == 3 else 2 if round_number == 1 else 5
		var expected_balance := expected_round_cash + (14 if round_number == 3 else 0)
		_expect(
			int(main.run.get("money", 0)) == expected_balance,
			"Round %d did not add its cash payout exactly once." % round_number
		)
		if round_number < 3:
			_expect(
				int(main.run.active_tournament.get("round", 0)) == round_number + 1
				and int(main.run.active_tournament.get("last_round_cash", 0)) == round_number + 1
				and int(main.run.active_tournament.get("round_cash_earned", 0)) == expected_round_cash,
				"The active tournament did not retain its cumulative round earnings."
			)
			_expect(
				"Round %d earnings: +$%d." % [round_number, round_number + 1]
				in "\n".join(main.run.active_tournament.get("logs", [])),
				"The tournament log did not record the round payout."
			)

	_expect(
		int(main.run.last_event_result.get("round_cash_earned", 0)) == 9
		and int(main.run.last_event_result.get("reward_money", 0)) == 14,
		"The event result did not separate $9 of round earnings from the $14 event prize."
	)
	_expect(
		main.run.last_event_result.get("round_results", []).size() == 3,
		"The event result did not retain its player-facing round recap."
	)

	_start_locals(main)
	main.run.kitchen_match_result = _loss_result()
	main._season_record_current_round_result()
	await process_frame
	_expect(
		int(main.run.get("money", 0)) == 2
		and int(main.run.last_event_result.get("round_cash_earned", 0)) == 2,
		"Completing a lost round did not award that round's cash."
	)

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	for unused_frame in range(4):
		await process_frame
	if failed:
		quit(1)
		return
	print("Round cash reward smoke test passed.")
	quit()


func _start_locals(main) -> void:
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main.run.money = 0
	main.run.selected_event_id = "weekly_locals"
	var event: Dictionary = main._season_event_by_id("weekly_locals")
	var metrics: Dictionary = main._calculate_deck_metrics(main.run.deck, main.run.sideboard)
	main.run.active_tournament = main.tournament_service.create_active_tournament(main, event, metrics)
	main.run.active_tournament.current_opponent = {
		"name": "Cash Test Rival",
		"archetype": "hearty"
	}
	main.run.active_tournament.current_seed = 90210


func _win_result() -> Dictionary:
	return {
		"game_over": true,
		"winner": "player",
		"turn": 5,
		"player": {"life": 10},
		"opponent": {"life": 0}
	}


func _loss_result() -> Dictionary:
	return {
		"game_over": true,
		"winner": "opponent",
		"turn": 5,
		"player": {"life": 0},
		"opponent": {"life": 10}
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
