extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	var public_run := "--public" in OS.get_cmdline_user_args()
	_start_season(main)

	main.run.prize_packs = 1
	main.run.last_event_result = _victory_summary()
	var technical_logs := [
		"Round 1 vs Mina on Sweet Starter: Won. Turn 5, life 6-0, seed 2373465488.",
		"Round 2 vs Cal on Sweet Starter: Won. Turn 6, life 11-3, seed 2546198465.",
		"Round 3 vs Local Rival Tess on Hearty Starter: Won. Turn 3, life 12-0, seed 2679931114.",
	]
	main._show_tournament_result(technical_logs, true)
	await process_frame
	await process_frame

	_expect(main.find_child("TournamentResultScreen", true, false) != null, "The result ceremony root is missing.")
	_expect(main.find_child("TournamentResultHero", true, false) != null, "The result ceremony hero is missing.")
	_expect(main.find_child("TournamentResultRecord", true, false) != null, "The final record is missing.")
	_expect(main.find_child("TournamentResultRewards", true, false) != null, "The reward summary is missing.")
	_expect(main.find_child("TournamentResultNextStep", true, false) != null, "The next-event teaser is missing.")
	_expect(main.find_child("TournamentResultRoundRecap", true, false) != null, "The round recap is missing.")
	for round_number in range(1, 4):
		_expect(
			main.find_child("TournamentResultRoundCard_%d" % round_number, true, false) != null,
			"Round %d is missing from the recap." % round_number
		)
	var outcome := main.find_child("TournamentResultProgress", true, false) as Label
	_expect(outcome != null and outcome.text == "Round won", "The victory outcome is not player-facing.")
	var primary := main.find_child("SeasonResultPrimaryAction", true, false) as Button
	_expect(primary != null and primary.text == "Open Prize Packs (1)", "The prize pack is not the clear primary action.")
	var technical_details := main.find_child("TournamentResultTechnicalDetails", true, false)
	if public_run:
		_expect(technical_details == null, "Public results exposed technical match logs.")
		_expect(not _tree_contains_text(main, "seed 2373465488"), "Public results exposed a match seed.")
	else:
		_expect(
			technical_details != null and not technical_details.visible,
			"Development results do not provide collapsed technical details."
		)

	main.run.prize_packs = 0
	main.run.run_over = true
	main.run.last_event_result = _defeat_summary()
	main._show_tournament_result(
		["Round 1 vs Mina on Sweet Starter: Lost. Turn 7, life 0-4, seed 2373465488."],
		false
	)
	await process_frame
	await process_frame
	outcome = main.find_child("TournamentResultProgress", true, false) as Label
	_expect(outcome != null and outcome.text == "Defeated", "The defeat ceremony does not explain the outcome.")
	var paper_background := main.find_child("PaperBackground", true, false) as ColorRect
	var pastel_background := main.find_child("PastelWorkspaceBackground", true, false) as ColorRect
	var background := main.find_child("RoutePresentationBackground", true, false) as ColorRect
	_expect(not paper_background.visible and not pastel_background.visible and background.visible and background.color.is_equal_approx(PALETTE.PEACH_PAPER), "The result does not use the shared Peach Soda background.")
	var room := background.get_node_or_null("LocalsMenuRoom")
	_expect(room != null and room.get_script().resource_path == "res://scripts/ui/PeachSodaBattleBackdrop.gd", "The result should use native room geometry rather than a retired generated backdrop.")
	var hero := main.find_child("TournamentResultHero", true, false) as PanelContainer
	var hero_style := main.find_child("TournamentResultHeroSurface", true, false)
	_expect(hero_style != null and hero_style.fill_color.is_equal_approx(PALETTE.PEACH_PAPER), "The defeat banner must use the shared paper surface.")
	_expect(hero.find_children("*", "Label", true, false).size() == 2, "The result must show both the outcome and run progress.")

	primary = main.find_child("SeasonResultPrimaryAction", true, false) as Button
	_expect(primary != null and primary.text == "Start New Run" and primary.get_meta("ui_button_variant", "") == "primary", "Defeat does not offer a clear restart action.")
	_expect(_tree_contains_text(main, "Review Deck"), "Defeat does not offer a run-review action.")
	_expect(not _tree_contains_text(main, "Visit Card Shop"), "Defeat still offers an invalid shop route.")

	# A long match history must never push the restart/review actions off screen.
	var long_summary := _defeat_summary()
	long_summary.wins = 11
	long_summary.losses = 1
	long_summary.round_results = []
	for index in range(12):
		long_summary.round_results.append({"round": index + 1, "opponent_name": "Local Rival %d" % (index + 1), "opponent_archetype": "Hearty Starter", "won": index < 11, "turn": 7, "player_life": 0, "cash": 2})
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(1728, 1117)]:
		root.size = viewport_size
		main.run.last_event_result = long_summary.duplicate(true)
		main._show_tournament_result([], false)
		await _settle()
		_check_actions(main)
		var result_scroll := main.find_child("TournamentResultScroll", true, false) as ScrollContainer
		var final_round := main.find_child("TournamentResultRoundCard_12", true, false) as Control
		result_scroll.ensure_control_visible(final_round)
		await _settle()
		_expect(result_scroll.get_global_rect().encloses(final_round.get_global_rect()), "The last result row cannot be brought into view.")
		_check_actions(main)

	# The screenshot came from an older result without last_event_result data.
	# Rendering a fallback must offer the same valid end-of-run actions.
	main.run.last_event_result = {}
	main._show_tournament_result(["The run is over."], false)
	await _settle()
	_check_actions(main)
	_expect((main.find_child("TournamentResultRecord", true, false) as Label).text == "—" and _tree_contains_text(main, "Earnings not saved"), "The fallback invented a record or earnings for missing history.")
	_expect(not _tree_contains_text(main, "Visit Card Shop") and not _tree_contains_text(main, "View Calendar"), "The fallback defeat offers legacy progression actions.")
	main._show_tournament_result(["Round 1: Lost", "Round 2: Won"], false)
	await _settle()
	_expect((main.find_child("TournamentResultRecord", true, false) as Label).text == "1–1" and main.find_child("TournamentResultRoundCard_1", true, false) == null, "Aggregate-only history invented a round order.")
	_click(main.find_child("SeasonResultPrimaryAction", true, false))
	await _settle()
	_expect(main.current_screen == "season_setup", "Start New Run did not open starter selection.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Tournament result UI smoke test passed.")
	quit()


func _settle() -> void:
	for unused in range(8):
		await process_frame


func _check_actions(main: Node) -> void:
	var actions := main.find_child("SeasonResultActions", true, false) as Control
	var result_scroll := main.find_child("TournamentResultScroll", true, false) as Control
	_expect(actions.get_global_rect().position.y >= result_scroll.get_global_rect().end.y, "Actions overlap the scrolling recap.")
	for button_node in actions.find_children("*", "Button", true, false):
		var button := button_node as Button
		_expect(button != null and not button.disabled and root.get_visible_rect().encloses(button.get_global_rect()), "A result action is clipped or disabled.")
		_expect(button.size.y * root.size.y / root.get_visible_rect().size.y >= 46.0, "A result action is too small at this resolution.")


func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func _start_season(main) -> void:
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


func _victory_summary() -> Dictionary:
	return {
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


func _defeat_summary() -> Dictionary:
	return {
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


func _tree_contains_text(root_node: Node, needle: String) -> bool:
	if root_node is Label and needle in String(root_node.text):
		return true
	if root_node is Button and needle in String(root_node.text):
		return true
	for child in root_node.get_children():
		if _tree_contains_text(child, needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
