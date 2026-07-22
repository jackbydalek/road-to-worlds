extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const DECK_IDS := [
	"spicy_test_kitchen",
	"hearty_test_kitchen",
	"sweet_test_kitchen",
	"fresh_test_kitchen",
	"funky_test_kitchen"
]
const DEFAULT_GAMES_PER_ORDER := 500
const DEFAULT_TURN_CAP := 100


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var games_per_order := DEFAULT_GAMES_PER_ORDER
	var turn_cap := DEFAULT_TURN_CAP
	var ai_difficulty := "easy"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			games_per_order = maxi(1, int(argument.trim_prefix("--games=")))
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

	var deck_totals := {}
	for deck_id in DECK_IDS:
		deck_totals[deck_id] = {
			"games": 0,
			"wins": 0,
			"first_games": 0,
			"first_wins": 0,
			"second_games": 0,
			"second_wins": 0,
			"turns": 0
		}

	var ordered_results: Array = []
	var seed_block := 0
	for left_index in range(DECK_IDS.size()):
		for right_index in range(left_index + 1, DECK_IDS.size()):
			var left_id: String = DECK_IDS[left_index]
			var right_id: String = DECK_IDS[right_index]
			ordered_results.append(_simulate_order(service, left_id, right_id, games_per_order, turn_cap, seed_block, deck_totals, ai_difficulty))
			seed_block += 1
			ordered_results.append(_simulate_order(service, right_id, left_id, games_per_order, turn_cap, seed_block, deck_totals, ai_difficulty))
			seed_block += 1

	var total_games := 0
	var first_wins := 0
	var second_wins := 0
	var capped_games := 0
	for result in ordered_results:
		total_games += int(result.games)
		first_wins += int(result.first_wins)
		second_wins += int(result.second_wins)
		capped_games += int(result.capped_games)
	var combined_matchups := _combined_matchup_results(ordered_results)

	print("Starter balance simulation: %d games per seating order, %d total games, %s AI" % [games_per_order, total_games, ai_difficulty.capitalize()])
	for result in ordered_results:
		print("%s first vs %s: %.1f%% / %.1f%%, capped %d, average turns %.2f, responses/game %.2f" % [
			_deck_label(String(result.first_deck)),
			_deck_label(String(result.second_deck)),
			_rate(int(result.first_wins), int(result.games)),
			_rate(int(result.second_wins), int(result.games)),
			int(result.capped_games),
			float(result.turns) / float(maxi(1, int(result.games))),
			float(result.reactions) / float(maxi(1, int(result.games)))
		])
	print("Seat-neutral matchup totals:")
	for matchup in combined_matchups:
		print("%s vs %s: %.1f%% / %.1f%% over %d games" % [
			_deck_label(String(matchup.left_deck)),
			_deck_label(String(matchup.right_deck)),
			_rate(int(matchup.left_wins), int(matchup.games)),
			_rate(int(matchup.right_wins), int(matchup.games)),
			int(matchup.games)
		])
	print("Overall first-seat win rate: %.1f%%; second-seat win rate: %.1f%%; capped: %d" % [
		_rate(first_wins, total_games),
		_rate(second_wins, total_games),
		capped_games
	])
	for deck_id in DECK_IDS:
		var totals: Dictionary = deck_totals[deck_id]
		print("%s overall: %.1f%% (%d/%d); first %.1f%%; second %.1f%%; average turns %.2f" % [
			_deck_label(deck_id),
			_rate(int(totals.wins), int(totals.games)),
			int(totals.wins),
			int(totals.games),
			_rate(int(totals.first_wins), int(totals.first_games)),
			_rate(int(totals.second_wins), int(totals.second_games)),
			float(totals.turns) / float(maxi(1, int(totals.games)))
		])
	var balance_flags := _balance_flags(first_wins, total_games, deck_totals, combined_matchups)
	if balance_flags.is_empty():
		print("Balance flags: none")
	else:
		print("Balance flags:")
		for flag in balance_flags:
			print("- " + flag)
	print("BALANCE_RESULT=" + JSON.stringify({
		"games_per_order": games_per_order,
		"ai_difficulty": ai_difficulty,
		"turn_cap": turn_cap,
		"ordered_matchups": ordered_results,
		"combined_matchups": combined_matchups,
		"deck_totals": deck_totals,
		"first_seat_wins": first_wins,
		"second_seat_wins": second_wins,
		"capped_games": capped_games,
		"balance_flags": balance_flags
	}))
	quit(0)


func _simulate_order(
	service: RefCounted,
	first_deck: String,
	second_deck: String,
	games: int,
	turn_cap: int,
	seed_block: int,
	deck_totals: Dictionary,
	ai_difficulty: String
) -> Dictionary:
	var result := {
		"first_deck": first_deck,
		"second_deck": second_deck,
		"games": games,
		"first_wins": 0,
		"second_wins": 0,
		"capped_games": 0,
		"turns": 0,
		"reactions": 0
	}
	for game_index in range(games):
		var seed_value := 1000003 + seed_block * 100000 + game_index
		var state: Dictionary = service.start_game(first_deck, second_deck, seed_value, "player", false, ai_difficulty)
		while not bool(state.game_over) and int(state.turn) <= turn_cap:
			result.reactions += _run_production_ai_turn(service, state, "player")
			if bool(state.game_over):
				break
			service._start_turn(state, "opponent")
			if bool(state.game_over):
				break
			result.reactions += _run_production_ai_turn(service, state, "opponent")
			if bool(state.game_over):
				break
			state.turn = int(state.turn) + 1
			service._start_turn(state, "player")

		result.turns += mini(int(state.turn), turn_cap)
		deck_totals[first_deck].games += 1
		deck_totals[first_deck].first_games += 1
		deck_totals[first_deck].turns += mini(int(state.turn), turn_cap)
		deck_totals[second_deck].games += 1
		deck_totals[second_deck].second_games += 1
		deck_totals[second_deck].turns += mini(int(state.turn), turn_cap)
		match String(state.winner):
			"player":
				result.first_wins += 1
				deck_totals[first_deck].wins += 1
				deck_totals[first_deck].first_wins += 1
			"opponent":
				result.second_wins += 1
				deck_totals[second_deck].wins += 1
				deck_totals[second_deck].second_wins += 1
			_:
				result.capped_games += 1
	return result


func _run_production_ai_turn(service: RefCounted, state: Dictionary, acting_side: String) -> int:
	var swapped := acting_side == "player"
	if swapped:
		_swap_perspective(state)
	state.phase = "opponent_turn"
	var reactions := _run_oriented_opponent_turn(service, state)
	if swapped:
		_swap_perspective(state)
	return reactions


# CookingCombatService's production AI is written for the opponent. Perspective
# swapping lets both starters use that exact implementation. Response windows are
# resolved here without invoking the live UI's automatic turn handoff.
func _run_oriented_opponent_turn(service: RefCounted, state: Dictionary) -> int:
	var reaction_safety := 64
	var reactions := 0
	service._ai_turn(state, false)
	while not bool(state.game_over) and not state.get("pending_reaction", {}).is_empty() and reaction_safety > 0:
		reaction_safety -= 1
		var eligible: Array[int] = service.reaction_hand_indices(state)
		var reaction_index := int(eligible[0]) if not eligible.is_empty() else -1
		if reaction_index >= 0:
			reactions += 1
		service.resolve_reaction(state, reaction_index, false)
		if not bool(state.game_over) and state.get("pending_reaction", {}).is_empty():
			service._ai_turn(state, false)
	if reaction_safety <= 0 and not state.get("pending_reaction", {}).is_empty():
		push_error("Automated reaction safety limit reached.")
		state.pending_reaction = {}
	return reactions


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


func _combined_matchup_results(ordered_results: Array) -> Array:
	var combined: Array = []
	for index in range(0, ordered_results.size(), 2):
		if index + 1 >= ordered_results.size():
			break
		var forward: Dictionary = ordered_results[index]
		var reverse: Dictionary = ordered_results[index + 1]
		combined.append({
			"left_deck": String(forward.first_deck),
			"right_deck": String(forward.second_deck),
			"games": int(forward.games) + int(reverse.games),
			"left_wins": int(forward.first_wins) + int(reverse.second_wins),
			"right_wins": int(forward.second_wins) + int(reverse.first_wins)
		})
	return combined


func _balance_flags(first_wins: int, total_games: int, deck_totals: Dictionary, combined_matchups: Array) -> Array[String]:
	var flags: Array[String] = []
	var first_rate := _rate(first_wins, total_games)
	if first_rate < 47.0 or first_rate > 53.0:
		flags.append("First-seat win rate %.1f%% is outside the 47-53%% target." % first_rate)
	for deck_id in DECK_IDS:
		var totals: Dictionary = deck_totals[deck_id]
		var deck_rate := _rate(int(totals.wins), int(totals.games))
		if deck_rate < 45.0 or deck_rate > 55.0:
			flags.append("%s overall win rate %.1f%% is outside the 45-55%% target." % [_deck_label(deck_id), deck_rate])
	for matchup in combined_matchups:
		var left_rate := _rate(int(matchup.left_wins), int(matchup.games))
		if left_rate < 35.0 or left_rate > 65.0:
			flags.append("%s vs %s is an extreme %.1f%% / %.1f%% matchup." % [
				_deck_label(String(matchup.left_deck)),
				_deck_label(String(matchup.right_deck)),
				left_rate,
				100.0 - left_rate
			])
	return flags


func _deck_label(deck_id: String) -> String:
	return deck_id.trim_suffix("_test_kitchen").capitalize()


func _rate(wins: int, games: int) -> float:
	return 0.0 if games <= 0 else float(wins) * 100.0 / float(games)
