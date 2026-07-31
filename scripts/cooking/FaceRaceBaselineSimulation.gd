extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const SPICY_DECK := "spicy_test_kitchen"
const OPPONENT_DECKS := [
	"spicy_test_kitchen",
	"hearty_test_kitchen",
	"sweet_test_kitchen"
]
const DEFAULT_GAMES_PER_SEAT := 250
const DEFAULT_TURN_CAP := 100


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var games_per_seat := DEFAULT_GAMES_PER_SEAT
	var turn_cap := DEFAULT_TURN_CAP
	var ai_difficulty := "hard"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			games_per_seat = maxi(1, int(argument.trim_prefix("--games=")))
		elif argument.begins_with("--turn-cap="):
			turn_cap = maxi(1, int(argument.trim_prefix("--turn-cap=")))
		elif argument.begins_with("--ai="):
			var requested_ai := String(argument.trim_prefix("--ai="))
			if requested_ai in ["easy", "medium", "hard", "expert"]:
				ai_difficulty = requested_ai

	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		push_error("Could not load starter deck content.")
		quit(1)
		return

	var matchups: Array[Dictionary] = []
	var total_baseline_wins := 0
	var total_production_wins := 0
	var total_capped := 0
	for opponent_index in range(OPPONENT_DECKS.size()):
		var opponent_deck: String = OPPONENT_DECKS[opponent_index]
		var baseline_first := _simulate_seating(
			service, SPICY_DECK, opponent_deck, true, games_per_seat,
			turn_cap, 700 + opponent_index * 2, ai_difficulty
		)
		var baseline_second := _simulate_seating(
			service, opponent_deck, SPICY_DECK, false, games_per_seat,
			turn_cap, 701 + opponent_index * 2, ai_difficulty
		)
		var matchup := {
			"opponent_deck": opponent_deck,
			"games": games_per_seat * 2,
			"baseline_wins": int(baseline_first.baseline_wins) + int(baseline_second.baseline_wins),
			"production_wins": int(baseline_first.production_wins) + int(baseline_second.production_wins),
			"capped_games": int(baseline_first.capped_games) + int(baseline_second.capped_games),
			"baseline_first": baseline_first,
			"baseline_second": baseline_second
		}
		matchups.append(matchup)
		total_baseline_wins += int(matchup.baseline_wins)
		total_production_wins += int(matchup.production_wins)
		total_capped += int(matchup.capped_games)

	var total_games := games_per_seat * 2 * OPPONENT_DECKS.size()
	print("Face-race baseline: %d games per seat, %d total games, %s production AI" % [games_per_seat, total_games, ai_difficulty.capitalize()])
	for matchup in matchups:
		print("Spicy face-race vs %s production: %.1f%% / %.1f%%, capped %d" % [
			_deck_label(String(matchup.opponent_deck)),
			_rate(int(matchup.baseline_wins), int(matchup.games)),
			_rate(int(matchup.production_wins), int(matchup.games)),
			int(matchup.capped_games)
		])
	print("Overall face-race win rate: %.1f%%; production: %.1f%%; capped: %d" % [
		_rate(total_baseline_wins, total_games),
		_rate(total_production_wins, total_games),
		total_capped
	])
	print("FACE_RACE_RESULT=" + JSON.stringify({
		"games_per_seat": games_per_seat,
		"ai_difficulty": ai_difficulty,
		"turn_cap": turn_cap,
		"matchups": matchups,
		"baseline_wins": total_baseline_wins,
		"production_wins": total_production_wins,
		"capped_games": total_capped
	}))
	quit(0)


func _simulate_seating(
	service: RefCounted,
	first_deck: String,
	second_deck: String,
	baseline_is_first: bool,
	games: int,
	turn_cap: int,
	seed_block: int,
	ai_difficulty: String
) -> Dictionary:
	var result := {
		"games": games,
		"baseline_wins": 0,
		"production_wins": 0,
		"capped_games": 0,
		"turns": 0
	}
	for game_index in range(games):
		var seed_value := 2000003 + seed_block * 100000 + game_index
		var state: Dictionary = service.start_game(first_deck, second_deck, seed_value, "player", false, ai_difficulty)
		var baseline: Dictionary = state.player if baseline_is_first else state.opponent
		var production: Dictionary = state.opponent if baseline_is_first else state.player
		baseline.ai_policy = service.AI_POLICY_FACE_RACE
		baseline.ai_profile = "pressure"
		production.ai_policy = service.AI_POLICY_PRODUCTION

		while not bool(state.game_over) and int(state.turn) <= turn_cap:
			_run_ai_turn(service, state, "player")
			if bool(state.game_over):
				break
			service._start_turn(state, "opponent")
			if bool(state.game_over):
				break
			_run_ai_turn(service, state, "opponent")
			if bool(state.game_over):
				break
			state.turn = int(state.turn) + 1
			service._start_turn(state, "player")

		result.turns += mini(int(state.turn), turn_cap)
		if String(state.winner) == "":
			result.capped_games += 1
		elif (String(state.winner) == "player") == baseline_is_first:
			result.baseline_wins += 1
		else:
			result.production_wins += 1
	return result


func _run_ai_turn(service: RefCounted, state: Dictionary, acting_side: String) -> void:
	var swapped := acting_side == "player"
	if swapped:
		_swap_perspective(state)
	state.phase = "opponent_turn"
	var reaction_safety := 64
	service._ai_turn(state, false)
	while not bool(state.game_over) and not state.get("pending_reaction", {}).is_empty() and reaction_safety > 0:
		reaction_safety -= 1
		var eligible: Array[int] = service.reaction_hand_indices(state)
		service.resolve_reaction(state, int(eligible[0]) if not eligible.is_empty() else -1, false)
		if not bool(state.game_over) and state.get("pending_reaction", {}).is_empty():
			service._ai_turn(state, false)
	if reaction_safety <= 0 and not state.get("pending_reaction", {}).is_empty():
		push_error("Automated reaction safety limit reached.")
		state.pending_reaction = {}
	if swapped:
		_swap_perspective(state)


func _swap_perspective(state: Dictionary) -> void:
	var original_player: Dictionary = state.player
	state.player = state.opponent
	state.opponent = original_player
	state.first_player = "opponent" if String(state.first_player) == "player" else "player"
	if bool(state.game_over):
		if String(state.winner) == "player":
			state.winner = "opponent"
		elif String(state.winner) == "opponent":
			state.winner = "player"


func _deck_label(deck_id: String) -> String:
	return deck_id.trim_suffix("_test_kitchen").capitalize()


func _rate(wins: int, games: int) -> float:
	return float(wins) * 100.0 / float(maxi(1, games))
