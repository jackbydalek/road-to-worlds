extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const DECK_IDS := ["spicy_test_kitchen", "hearty_test_kitchen", "sweet_test_kitchen"]
const DEFAULT_GAMES_PER_ORDER := 500
const DEFAULT_TURN_CAP := 100


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var games_per_order := DEFAULT_GAMES_PER_ORDER
	var turn_cap := DEFAULT_TURN_CAP
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			games_per_order = maxi(1, int(argument.trim_prefix("--games=")))
		elif argument.begins_with("--turn-cap="):
			turn_cap = maxi(1, int(argument.trim_prefix("--turn-cap=")))

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
			ordered_results.append(_simulate_order(service, left_id, right_id, games_per_order, turn_cap, seed_block, deck_totals))
			seed_block += 1
			ordered_results.append(_simulate_order(service, right_id, left_id, games_per_order, turn_cap, seed_block, deck_totals))
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

	print("Starter balance simulation: %d games per seating order, %d total games" % [games_per_order, total_games])
	for result in ordered_results:
		print("%s first vs %s: %.1f%% / %.1f%%, capped %d, average turns %.2f" % [
			_deck_label(String(result.first_deck)),
			_deck_label(String(result.second_deck)),
			_rate(int(result.first_wins), int(result.games)),
			_rate(int(result.second_wins), int(result.games)),
			int(result.capped_games),
			float(result.turns) / float(maxi(1, int(result.games)))
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
	print("BALANCE_RESULT=" + JSON.stringify({
		"games_per_order": games_per_order,
		"turn_cap": turn_cap,
		"ordered_matchups": ordered_results,
		"deck_totals": deck_totals,
		"first_seat_wins": first_wins,
		"second_seat_wins": second_wins,
		"capped_games": capped_games
	}))
	quit(0)


func _simulate_order(
	service: RefCounted,
	first_deck: String,
	second_deck: String,
	games: int,
	turn_cap: int,
	seed_block: int,
	deck_totals: Dictionary
) -> Dictionary:
	var result := {
		"first_deck": first_deck,
		"second_deck": second_deck,
		"games": games,
		"first_wins": 0,
		"second_wins": 0,
		"capped_games": 0,
		"turns": 0
	}
	for game_index in range(games):
		var seed_value := 1000003 + seed_block * 100000 + game_index
		var state: Dictionary = service.start_game(first_deck, second_deck, seed_value, "player")
		while not bool(state.game_over) and int(state.turn) <= turn_cap:
			_take_current_player_ai_turn(service, state)
			if bool(state.game_over):
				break
			state.phase = "opponent_turn"
			service._ai_turn(state)
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


func _take_current_player_ai_turn(service: RefCounted, state: Dictionary) -> void:
	_swap_perspective(state)
	_take_opponent_actions(service, state)
	_swap_perspective(state)


# Mirrors CookingCombatService._ai_turn after its start-of-turn step. Swapping the
# two combatants lets both decks use the same decisions and automatic targeting.
func _take_opponent_actions(service: RefCounted, state: Dictionary) -> void:
	var safety := 30
	var progress := true
	while progress and safety > 0:
		safety -= 1
		progress = false
		for hand_index in range(state.opponent.hand.size() - 1, -1, -1):
			var data: Dictionary = service.card(String(state.opponent.hand[hand_index]))
			var card_type := String(data.get("card_type", ""))
			if card_type == "environment":
				progress = service._play_environment(state, "opponent", hand_index)
				break
			if card_type == "meal" and not bool(state.opponent.meal_served):
				var recipe_units: Array = service._find_recipe_ingredients(state.opponent, service._effective_recipe(state, "opponent", data))
				if not recipe_units.is_empty():
					var meal_destination := "plated" if state.opponent.plated.size() < 2 else "prep"
					progress = service._serve_meal(state, "opponent", hand_index, recipe_units, meal_destination)
					break
			if card_type == "ingredient":
				var destination := "prep" if state.opponent.prep.size() < 3 else "plated"
				var capacity := 3 if destination == "prep" else 2
				if state.opponent[destination].size() < capacity:
					progress = service._play_ingredient(state, "opponent", hand_index, destination)
					break
			if card_type == "spice":
				var spice_target: Dictionary = service._first_unspiced_unit(state.opponent)
				if not spice_target.is_empty():
					progress = service._play_spice(state, "opponent", hand_index, int(spice_target.instance_id))
					break
			if card_type == "tool":
				progress = service._play_tool(state, "opponent", hand_index)
				break
			if card_type == "chef":
				progress = service._play_chef(state, "opponent", hand_index)
				break
	if not bool(state.opponent.zone_move_used) and state.opponent.plated.size() < 2 and not state.opponent.prep.is_empty():
		var moved: Dictionary = state.opponent.prep.pop_front()
		moved.ready = true
		state.opponent.plated.append(moved)
		state.opponent.zone_move_used = true
		service._resolve_effects(state, "opponent", service.card(String(moved.card_id)).get("on_move_to_plated", []), moved)
		service._refresh_stat_auras(state)
	for unit in state.opponent.plated.duplicate():
		if not bool(unit.ready) or bool(state.game_over):
			continue
		unit.ready = false
		var target: Dictionary = {} if service._unit_has_keyword(unit, "stalwart") else service._weakest_plated_unit(state.player)
		if target.is_empty():
			service._resolve_effects(state, "opponent", service.card(String(unit.card_id)).get("on_attack", []), unit)
			state.player.life -= int(unit.attack)
			if int(unit.attack) > 0:
				service._resolve_effects(state, "opponent", service.card(String(unit.card_id)).get("on_combat_damage_to_chef", []), unit)
		else:
			service._resolve_effects(state, "opponent", service.card(String(unit.card_id)).get("on_attack", []), unit)
			service._resolve_unit_battle(state, "opponent", unit, target)
		service._check_game_over(state)
	state.opponent.chefs_disabled = false
	state.opponent.items_disabled = false
	service._clear_temporary_buffs(state.opponent)


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
	return 0.0 if games <= 0 else float(wins) * 100.0 / float(games)
