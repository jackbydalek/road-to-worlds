extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	if main.current_screen != "start":
		push_error("Tournament smoke test did not begin on the mode selection start screen.")
		quit(1)
		return
	main._show_season_run_setup()
	await process_frame
	if main.current_screen != "season_setup":
		push_error("Tournament smoke test did not open the Season deck and difficulty selector.")
		quit(1)
		return
	main._confirm_season_run_setup()
	await process_frame
	if main.current_screen != "season" or String(main.run.get("run_mode", "")) != "season":
		push_error("Tournament smoke test did not enter the Season Run path.")
		quit(1)
		return
	if String(main.run.get("difficulty", "")) != "white":
		push_error("Tournament smoke test did not default the Season selector to White Border.")
		quit(1)
		return
	main._start_season_tournament()
	await process_frame
	if main.current_screen != "ui_combat" or main.run.get("manual_combat", {}).is_empty():
		push_error("Tournament smoke test did not launch a live Season UI Combat round.")
		quit(1)
		return
	if main.run.get("active_tournament", {}).is_empty():
		push_error("Tournament smoke test did not create active Season tournament state.")
		quit(1)
		return

	_force_live_round_result(main, true)
	main._season_record_current_round_result()
	await process_frame
	if int(main.run.get("active_tournament", {}).get("wins", 0)) != 1:
		push_error("Tournament smoke test did not record the first live Season round win.")
		quit(1)
		return
	if main.current_screen != "tournament":
		push_error("Tournament smoke test did not return to the tournament progress screen after round one.")
		quit(1)
		return

	main._start_season_tournament_round()
	await process_frame
	if main.current_screen != "ui_combat":
		push_error("Tournament smoke test did not launch live Season round two.")
		quit(1)
		return
	_force_live_round_result(main, true)
	main._season_record_current_round_result()
	await process_frame

	if int(main.run.get("active_tournament", {}).get("wins", 0)) != 2:
		push_error("Tournament smoke test did not record the second live Season round win.")
		quit(1)
		return
	if main.current_screen != "tournament":
		push_error("Tournament smoke test did not return to tournament progress after round two.")
		quit(1)
		return

	main._start_season_tournament_round()
	await process_frame
	if main.current_screen != "ui_combat":
		push_error("Tournament smoke test did not launch live Season round three.")
		quit(1)
		return
	_force_live_round_result(main, true)
	main._season_record_current_round_result()
	await process_frame

	if main.run.get("last_result", []).is_empty():
		push_error("Tournament smoke test produced no live Season result log.")
		quit(1)
		return
	if main.current_screen != "result":
		push_error("Tournament smoke test did not show the event result screen after live Season completion.")
		quit(1)
		return
	var result_summary: Dictionary = main.run.get("last_event_result", {})
	if result_summary.is_empty():
		push_error("Tournament smoke test did not store structured event result data.")
		quit(1)
		return
	if int(result_summary.get("wins", 0)) != 3 or int(result_summary.get("required_wins", 0)) != 2:
		push_error("Tournament smoke test stored incorrect event record summary.")
		quit(1)
		return
	if int(result_summary.get("reward_money", 0)) <= 0 or int(result_summary.get("reward_packs", 0)) <= 0:
		push_error("Tournament smoke test did not store event rewards in the result summary.")
		quit(1)
		return
	if not _has_button_text(main, "Open Prize Packs"):
		push_error("Tournament smoke test did not show the prize pack reward button.")
		quit(1)
		return
	if not _has_button_text(main, "Visit Card Shop") or not _has_button_text(main, "View Calendar"):
		push_error("Tournament smoke test did not show the post-event reward flow buttons.")
		quit(1)
		return
	if int(main.run.get("week", 0)) != 2:
		push_error("Tournament smoke test did not advance the week after a live Season tournament.")
		quit(1)
		return
	if not main.run.get("active_tournament", {}).is_empty():
		push_error("Tournament smoke test did not clear active tournament state after live Season completion.")
		quit(1)
		return
	if not main.run.get("calendar_completed", []).has("weekly_locals"):
		push_error("Tournament smoke test did not mark Weekly Locals as cleared on the season calendar.")
		quit(1)
		return
	if String(main.run.get("selected_event_id", "")) != "monthly_regionals":
		push_error("Tournament smoke test did not select Monthly Regionals after clearing Weekly Locals.")
		quit(1)
		return
	if int(main.run.get("calendar_unlocked_index", 0)) < 1:
		push_error("Tournament smoke test did not unlock the next season calendar event.")
		quit(1)
		return
	var prize_packs_before := int(main.run.get("prize_packs", 0))
	main._open_reward_pack_flow()
	await process_frame
	if main.current_screen != "packs" or main.run.get("current_pack", []).is_empty():
		push_error("Tournament smoke test reward flow did not open a prize pack.")
		quit(1)
		return
	if int(main.run.get("prize_packs", 0)) != prize_packs_before - 1:
		push_error("Tournament smoke test reward flow did not spend exactly one prize pack.")
		quit(1)
		return
	main._show_season_run()
	await process_frame
	if not String(main.run.get("season_notice", "")).contains("Monthly Regionals unlocked"):
		push_error("Tournament smoke test did not store the next-event prep notice.")
		quit(1)
		return
	if not _has_label_containing(main, "Monthly Regionals unlocked"):
		push_error("Tournament smoke test did not render the next-event prep notice on the Season screen.")
		quit(1)
		return

	main._show_season_run_setup()
	await process_frame
	main._confirm_season_run_setup()
	await process_frame
	await _force_two_loss_event(main)
	if bool(main.run.get("run_over", false)):
		push_error("Tournament smoke test ended the season despite remaining lives.")
		quit(1)
		return
	if int(main.run.get("season_lives", 0)) != 2:
		push_error("Tournament smoke test did not remove exactly one season life after a failed event.")
		quit(1)
		return
	if main.run.get("calendar_completed", []).has("weekly_locals"):
		push_error("Tournament smoke test incorrectly cleared a failed calendar event.")
		quit(1)
		return
	var failed_summary: Dictionary = main.run.get("last_event_result", {})
	if bool(failed_summary.get("made_record", true)) or int(failed_summary.get("lives_lost", 0)) != 1:
		push_error("Tournament smoke test did not store the failed-event summary correctly.")
		quit(1)
		return
	if String(main.run.get("selected_event_id", "")) != "weekly_locals":
		push_error("Tournament smoke test did not keep the failed event selected for retry.")
		quit(1)
		return
	if not String(main.run.get("season_notice", "")).contains("missed"):
		push_error("Tournament smoke test did not store the failed-event prep notice.")
		quit(1)
		return
	if not _has_button_text(main, "Retry Weekly Locals"):
		push_error("Tournament smoke test did not show the retry button after a failed event.")
		quit(1)
		return

	main._show_season_run_setup()
	await process_frame
	main._confirm_season_run_setup()
	await process_frame
	main.run.season_lives = 1
	main.run.max_season_lives = 1
	await _force_two_loss_event(main)
	if not bool(main.run.get("run_over", false)):
		push_error("Tournament smoke test did not end the season when no lives remained.")
		quit(1)
		return
	if not _has_button_text(main, "Start New Run"):
		push_error("Tournament smoke test did not show the new-run button after season failure.")
		quit(1)
		return

	main._start_new_run("flightless_birds")
	await process_frame
	main._choose_run_path("debug")
	await process_frame
	main._run_tournament()
	await process_frame

	if main.run.get("last_result", []).is_empty():
		push_error("Tournament smoke test produced no debug auto result log.")
		quit(1)
		return

	var saw_game_summary := false
	for line in main.run.get("last_result", []):
		if String(line).contains("Game 1:"):
			saw_game_summary = true
			break

	if not saw_game_summary:
		push_error("Tournament smoke test debug path did not use combat game summaries.")
		quit(1)
		return

	print("Tournament smoke test ran live Season and debug auto Weekly Locals.")
	quit(0)


func _force_live_round_result(main, player_won: bool) -> void:
	main.run.manual_combat["game_over"] = true
	main.run.manual_combat["winner"] = "player" if player_won else "opponent"
	main.run.manual_combat["phase"] = "game_over"
	main.run.manual_combat["turn"] = max(1, int(main.run.manual_combat.get("turn", 1)))
	main.run.manual_combat["player"]["life"] = 12 if player_won else 0
	main.run.manual_combat["opponent"]["life"] = 0 if player_won else 12


func _force_two_loss_event(main) -> void:
	main._start_season_tournament()
	await process_frame
	_force_live_round_result(main, false)
	main._season_record_current_round_result()
	await process_frame
	main._start_season_tournament_round()
	await process_frame
	_force_live_round_result(main, false)
	main._season_record_current_round_result()
	await process_frame


func _has_button_text(node: Node, text_prefix: String) -> bool:
	if node is Button and String(node.text).begins_with(text_prefix):
		return true
	for child in node.get_children():
		if _has_button_text(child, text_prefix):
			return true
	return false


func _has_label_containing(node: Node, text_fragment: String) -> bool:
	if node is Label and String(node.text).contains(text_fragment):
		return true
	for child in node.get_children():
		if _has_label_containing(child, text_fragment):
			return true
	return false
