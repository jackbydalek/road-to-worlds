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
	var outcome := main.find_child("TournamentResultOutcome", true, false) as Label
	_expect(outcome != null and outcome.text == "EVENT CLEARED", "The victory outcome is not player-facing.")
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
	outcome = main.find_child("TournamentResultOutcome", true, false) as Label
	_expect(outcome != null and outcome.text == "SEASON ENDED", "The defeat ceremony does not explain the outcome.")
	var paper_background := main.find_child("PaperBackground", true, false) as ColorRect
	var pastel_background := main.find_child("PastelWorkspaceBackground", true, false) as ColorRect
	_expect(
		paper_background != null and not paper_background.visible
		and pastel_background != null and pastel_background.visible,
		"The season-ended screen still uses the paper background."
	)
	var defeat_hero := main.find_child("TournamentResultHero", true, false) as PanelContainer
	var defeat_hero_style := defeat_hero.get_theme_stylebox("panel") as StyleBoxFlat if defeat_hero != null else null
	_expect(
		defeat_hero_style != null
		and defeat_hero_style.bg_color.get_luminance() > 0.75
		and defeat_hero_style.border_color.is_equal_approx(PALETTE.NAVY)
		and defeat_hero_style.corner_radius_top_left >= 16,
		"The season-ended hero does not use the smooth pastel card treatment."
	)
	primary = main.find_child("SeasonResultPrimaryAction", true, false) as Button
	_expect(primary != null and primary.text == "Start New Run", "Defeat does not offer a clear restart action.")
	var primary_style := primary.get_theme_stylebox("normal") as StyleBoxFlat if primary != null else null
	_expect(primary_style != null and primary_style.bg_color.is_equal_approx(PALETTE.CORAL), "The restart action is not using the coral primary-action treatment.")
	_expect(_tree_contains_text(main, "Review Deck"), "Defeat does not offer a run-review action.")
	_expect(not _tree_contains_text(main, "Visit Card Shop"), "Defeat still offers an invalid shop route.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Tournament result UI smoke test passed.")
	quit()


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
