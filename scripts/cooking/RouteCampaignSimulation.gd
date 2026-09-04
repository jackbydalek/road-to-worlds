extends SceneTree

# Deterministic, headless Starter City balance harness. Both seats use the
# production combat AI; the simulated player uses a separate configurable AI
# level and a documented heuristic for route, reward, event, and shop choices.

const CONTENT_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const ROUTE_SCRIPT := preload("res://scripts/RouteRunService.gd")
const COMBAT_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const SHOP_SCRIPT := preload("res://scripts/ShopEconomyService.gd")
const GRAPH_SCRIPT := preload("res://scripts/overworld/OverworldRouteGraph.gd")

const STARTERS := ["spicy", "hearty", "sweet"]
const RIVAL_AFFINITIES := ["spicy", "hearty", "sweet", "fresh"]
const DEFAULT_RUNS_PER_STARTER := 25
const DEFAULT_TURN_CAP := 100
const DEFAULT_SEED := 730001

var catalog: RefCounted
var route_service: RefCounted
var combat_service: RefCounted
var shop_service: RefCounted
var shop_rng := RandomNumberGenerator.new()
var player_ai := "hard"
var route_policy := "survival"
var turn_cap := DEFAULT_TURN_CAP


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runs_per_starter := DEFAULT_RUNS_PER_STARTER
	var seed_base := DEFAULT_SEED
	var requested_starter := "all"
	var minimum_win_rate := -1.0
	var maximum_win_rate := -1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			runs_per_starter = maxi(1, int(argument.trim_prefix("--runs=")))
		elif argument.begins_with("--seed="):
			seed_base = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--turn-cap="):
			turn_cap = maxi(1, int(argument.trim_prefix("--turn-cap=")))
		elif argument.begins_with("--player-ai="):
			var requested_ai := String(argument.trim_prefix("--player-ai="))
			if requested_ai in ["easy", "medium", "hard", "expert"]:
				player_ai = requested_ai
		elif argument.begins_with("--policy="):
			var requested_policy := String(argument.trim_prefix("--policy="))
			if requested_policy in ["survival", "greedy", "random"]:
				route_policy = requested_policy
		elif argument.begins_with("--starter="):
			requested_starter = String(argument.trim_prefix("--starter="))
		elif argument.begins_with("--min-win-rate="):
			minimum_win_rate = clampf(float(argument.trim_prefix("--min-win-rate=")), 0.0, 100.0)
		elif argument.begins_with("--max-win-rate="):
			maximum_win_rate = clampf(float(argument.trim_prefix("--max-win-rate=")), 0.0, 100.0)

	catalog = CONTENT_SCRIPT.new()
	if not catalog.load_all():
		push_error("Could not load campaign content.")
		quit(1)
		return
	route_service = ROUTE_SCRIPT.new()
	route_service.setup(catalog.cards, catalog.cards_by_id)
	combat_service = COMBAT_SCRIPT.new()
	if not combat_service.load_content():
		push_error("Could not load combat content.")
		quit(1)
		return
	shop_service = SHOP_SCRIPT.new()
	shop_service.setup(catalog.cards, catalog.cards_by_id, catalog.boosters_by_id, shop_rng)

	var starters: Array[String] = []
	if requested_starter == "all":
		for starter in STARTERS:
			starters.append(starter)
	elif requested_starter in STARTERS:
		starters.append(requested_starter)
	else:
		push_error("--starter must be all, spicy, hearty, or sweet.")
		quit(1)
		return

	var totals := _empty_totals()
	var starter_results := {}
	for starter_index in range(starters.size()):
		var starter := starters[starter_index]
		var starter_totals := _empty_totals()
		for run_index in range(runs_per_starter):
			var run_seed := seed_base + STARTERS.find(starter) * 1000000 + run_index
			_add_result(starter_totals, _simulate_run(starter, run_seed))
		starter_results[starter] = starter_totals
		_merge_totals(totals, starter_totals)

	print("Starter City campaign simulation: %d runs per starter, %s player AI, %s route policy" % [
		runs_per_starter, player_ai.capitalize(), route_policy.capitalize()
	])
	for starter in starters:
		_print_summary(starter.capitalize(), starter_results[starter])
	_print_summary("Overall", totals)
	var balance_flags := _balance_flags(starters, starter_results, totals, minimum_win_rate, maximum_win_rate)
	if not balance_flags.is_empty():
		print("Balance flags:")
		for flag in balance_flags:
			print("- " + flag)
	print("ROUTE_CAMPAIGN_RESULT=" + JSON.stringify({
		"runs_per_starter": runs_per_starter,
		"seed": seed_base,
		"turn_cap": turn_cap,
		"player_ai": player_ai,
		"route_policy": route_policy,
		"starters": starter_results,
		"totals": totals,
		"balance_flags": balance_flags,
	}))
	var exit_code := 0
	if int(totals.capped_battles) > 0:
		exit_code = 2
	elif not balance_flags.is_empty():
		exit_code = 3
	quit(exit_code)


func _simulate_run(starter: String, run_seed: int) -> Dictionary:
	var starter_entries: Array = catalog.archetypes_by_id[starter].starterDeck
	var starter_deck: Dictionary = catalog.deck_entries_to_dict(starter_entries)
	var run := {
		"starter": starter,
		"deck": starter_deck,
		"collection": starter_deck.duplicate(true),
		"money": 8,
		"meta": {"spicy": 0.25, "hearty": 0.25, "sweet": 0.25, "fresh": 0.25},
	}
	route_service.initialize_run(run, run_seed)

	var graph: Node = GRAPH_SCRIPT.new()
	graph.generation_seed = run_seed
	graph.call("_generate_route_graph")
	var nodes: Dictionary = graph.nodes.duplicate(true)
	graph.free()

	var result := {
		"runs": 1,
		"wins": 0,
		"battles": 0,
		"battle_wins": 0,
		"turns": 0,
		"damage_taken": 0,
		"reshuffles": 0,
		"rewards_picked": 0,
		"shops": 0,
		"events": 0,
		"capped_battles": 0,
		"final_life": 0,
		"final_deck_size": 0,
		"death_layers": {},
		"death_node_types": {},
	}
	var policy_rng := RandomNumberGenerator.new()
	policy_rng.seed = run_seed ^ 0x51A7E
	var current_node := "start"
	var layer_index := 0
	while current_node != "final_boss" or int(result.wins) == 0:
		var choices: Array = nodes[current_node].get("next", [])
		if choices.is_empty():
			break
		var next_node := _choose_route_node(choices, nodes, run, policy_rng)
		current_node = next_node
		layer_index += 1
		var node: Dictionary = nodes[current_node]
		var node_type := String(node.get("type", "enemy"))
		match node_type:
			"enemy", "mini_boss", "final_boss":
				var battle_result := _simulate_battle(run, current_node, node_type, run_seed)
				result.battles += 1
				result.turns += int(battle_result.turns)
				result.damage_taken += int(battle_result.damage_taken)
				result.reshuffles += int(battle_result.reshuffles)
				if bool(battle_result.capped):
					result.capped_battles += 1
				if not bool(battle_result.won):
					_increment(result.death_layers, str(layer_index))
					_increment(result.death_node_types, node_type)
					result.final_life = int(run.life)
					result.final_deck_size = route_service.deck_total(run.deck)
					return result
				result.battle_wins += 1
				var cash_reward := 8 if node_type == "final_boss" else 5 if node_type == "mini_boss" else 2
				run.money = int(run.money) + cash_reward
				result.rewards_picked += _take_rewards(run, node_type, int(battle_result.seed) + 97)
				if node_type == "final_boss":
					result.wins = 1
					break
			"shop":
				result.shops += 1
				_resolve_shop(run, run_seed ^ hash(current_node))
			"event":
				result.events += 1
				_resolve_event(run, run_seed, current_node)
				if int(run.life) <= 0:
					_increment(result.death_layers, str(layer_index))
					_increment(result.death_node_types, "event")
					result.final_life = int(run.life)
					result.final_deck_size = route_service.deck_total(run.deck)
					return result
	result.final_life = int(run.life)
	result.final_deck_size = route_service.deck_total(run.deck)
	return result


func _simulate_battle(run: Dictionary, node_id: String, node_type: String, run_seed: int) -> Dictionary:
	var encounter_seed := run_seed ^ hash(node_id)
	var affinity_index := posmod(encounter_seed, RIVAL_AFFINITIES.size())
	var rival_affinity := String(RIVAL_AFFINITIES[affinity_index])
	if rival_affinity == String(run.starter):
		rival_affinity = _predator_affinity(rival_affinity)
	var opponent_ai: String = route_service.encounter_ai(node_type)
	var opponent_entries: Array = catalog.archetypes_by_id[rival_affinity].starterDeck
	var opponent_deck: Dictionary = catalog.deck_entries_to_dict(opponent_entries)
	_upgrade_opponent_deck(opponent_deck, rival_affinity, opponent_ai)

	var prepared_deck: Dictionary = route_service.prepare_player_combat_deck(run, run.deck)
	for custom_card_id_value in prepared_deck.get("cards", {}).keys():
		var custom_card_id := String(custom_card_id_value)
		combat_service.cards_by_id[custom_card_id] = prepared_deck.cards[custom_card_id].duplicate(true)
	combat_service.decks["route_sim_player"] = {
		"name": "Simulated Player", "archetype": String(run.starter), "cards": prepared_deck.deck.duplicate(true)
	}
	combat_service.decks["route_sim_opponent"] = {
		"name": "Route Rival", "archetype": rival_affinity, "cards": opponent_deck
	}
	var starting_life := int(run.life)
	var state: Dictionary = combat_service.start_game(
		"route_sim_player", "route_sim_opponent", encounter_seed, "player", false, opponent_ai,
		{
			"player_life": starting_life,
			"player_max_life": int(run.max_life),
			"opponent_life": route_service.encounter_life(node_type),
			"opponent_max_life": route_service.encounter_life(node_type),
			"turn_hand_floor": 3,
			"reshuffle_pressure": true,
			"reshuffle_damage": [3, 5, 7],
		}
	)
	while not bool(state.game_over) and int(state.turn) <= turn_cap:
		state.ai_difficulty = player_ai
		_run_production_ai_turn(state, "player")
		if bool(state.game_over):
			break
		combat_service._start_turn(state, "opponent")
		if bool(state.game_over):
			break
		state.ai_difficulty = opponent_ai
		_run_production_ai_turn(state, "opponent")
		if bool(state.game_over):
			break
		state.turn = int(state.turn) + 1
		combat_service._start_turn(state, "player")
	var capped := not bool(state.game_over)
	var won := not capped and String(state.winner) == "player"
	run.life = maxi(0, int(state.player.life))
	return {
		"won": won,
		"capped": capped,
		"seed": encounter_seed,
		"turns": mini(int(state.turn), turn_cap),
		"damage_taken": maxi(0, starting_life - int(run.life)),
		"reshuffles": int(state.player.get("fatigue", 0)),
	}


func _run_production_ai_turn(state: Dictionary, acting_side: String) -> void:
	var swapped := acting_side == "player"
	if swapped:
		_swap_perspective(state)
	state.phase = "opponent_turn"
	var reaction_safety := 64
	combat_service._ai_turn(state, false)
	while not bool(state.game_over) and not state.get("pending_reaction", {}).is_empty() and reaction_safety > 0:
		reaction_safety -= 1
		var eligible: Array[int] = combat_service.reaction_hand_indices(state)
		combat_service.resolve_reaction(state, int(eligible[0]) if not eligible.is_empty() else -1, false)
		if not bool(state.game_over) and state.get("pending_reaction", {}).is_empty():
			combat_service._ai_turn(state, false)
	if reaction_safety <= 0 and not state.get("pending_reaction", {}).is_empty():
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


func _choose_route_node(choices: Array, nodes: Dictionary, run: Dictionary, policy_rng: RandomNumberGenerator) -> String:
	if route_policy == "random":
		return String(choices[policy_rng.randi_range(0, choices.size() - 1)])
	var best_id := String(choices[0])
	var best_score := -INF
	for choice_value in choices:
		var choice_id := String(choice_value)
		var node_type := String(nodes[choice_id].get("type", "enemy"))
		var score := 0.0
		if route_policy == "greedy":
			score = {"enemy": 8.0, "mini_boss": 9.0, "final_boss": 10.0, "shop": 3.0, "event": 2.0}.get(node_type, 0.0)
		else:
			var missing_life := int(run.max_life) - int(run.life)
			match node_type:
				"event": score = 12.0 if missing_life >= 8 else 4.0
				"shop": score = 10.0 if missing_life >= 6 and int(run.money) >= 4 else 3.0
				"enemy": score = 7.0 if int(run.life) >= 25 else 1.0
				"mini_boss", "final_boss": score = 20.0
		# Stable seed-based jitter prevents the first lane from winning every tie.
		score += policy_rng.randf_range(0.0, 0.01)
		if score > best_score:
			best_score = score
			best_id = choice_id
	return best_id


func _take_rewards(run: Dictionary, node_type: String, reward_seed: int) -> int:
	var offer: Array[String] = route_service.generate_reward_offer(String(run.starter), node_type, reward_seed)
	var picks_remaining: int = route_service.reward_pick_count(node_type)
	var picked := 0
	while picks_remaining > 0:
		var best_id := ""
		var best_score := -INF
		for card_id_value in offer:
			var card_id := String(card_id_value)
			var score := _card_score(card_id, String(run.starter))
			if score > best_score:
				best_score = score
				best_id = card_id
		if best_id == "":
			break
		run.deck[best_id] = int(run.deck.get(best_id, 0)) + 1
		run.collection[best_id] = int(run.collection.get(best_id, 0)) + 1
		offer.erase(best_id)
		picks_remaining -= 1
		picked += 1
	return picked


func _resolve_event(run: Dictionary, run_seed: int, node_id: String) -> void:
	var outcome: String = route_service.event_outcome_for_node(run_seed, node_id)
	if outcome == "remove_card":
		var weakest_id := ""
		var weakest_score := INF
		for card_id_value in run.deck.keys():
			var card_id := String(card_id_value)
			var score := _card_score(card_id, String(run.starter))
			if score < weakest_score:
				weakest_score = score
				weakest_id = card_id
		route_service.resolve_event(run, outcome, weakest_id, 1)
		return
	if outcome == "upgrade_card":
		var best_id := ""
		var best_score := -INF
		for card_id in route_service.upgradeable_card_ids(run):
			var score := _card_score(card_id, String(run.starter))
			if score > best_score:
				best_score = score
				best_id = card_id
		route_service.resolve_event(run, outcome, best_id, 1)
		return
	route_service.resolve_event(run, outcome, "", 1)


func _resolve_shop(run: Dictionary, shop_seed: int) -> void:
	shop_rng.seed = shop_seed
	shop_service.generate_shop_inventory(run, String(run.starter))
	var inventory: Array = run.shop.slice(0, 3)
	if int(run.life) <= int(run.max_life) - 6 and int(run.money) >= route_service.SHOP_HEAL_COST:
		run.money = int(run.money) - route_service.SHOP_HEAL_COST
		run.life = mini(int(run.max_life), int(run.life) + route_service.SHOP_HEAL_AMOUNT)
	var best_id := ""
	var best_score := -INF
	for card_id_value in inventory:
		var card_id := String(card_id_value)
		var price: int = shop_service.card_price(run, card_id)
		if price > int(run.money):
			continue
		var score := _card_score(card_id, String(run.starter)) - float(price) * 0.4
		if score > best_score:
			best_score = score
			best_id = card_id
	if best_id != "":
		var price: int = shop_service.card_price(run, best_id)
		run.money = int(run.money) - price
		run.deck[best_id] = int(run.deck.get(best_id, 0)) + 1
		run.collection[best_id] = int(run.collection.get(best_id, 0)) + 1
	# Each shop can refine one weak card and upgrade one strong card, matching the
	# production shop's per-visit service limits.
	if int(run.money) >= route_service.SHOP_REMOVE_COST and route_service.deck_total(run.deck) > 1:
		var weakest_id := ""
		var weakest_score := INF
		for card_id_value in run.deck.keys():
			var card_id := String(card_id_value)
			var score := _card_score(card_id, String(run.starter))
			if score < weakest_score:
				weakest_score = score
				weakest_id = card_id
		if weakest_id != "":
			run.money = int(run.money) - route_service.SHOP_REMOVE_COST
			route_service.remove_card(run, weakest_id, 1)
	if int(run.money) >= route_service.SHOP_UPGRADE_COST:
		var best_upgrade_id := ""
		var best_upgrade_score := -INF
		for card_id in route_service.upgradeable_card_ids(run):
			var score := _card_score(card_id, String(run.starter))
			if score > best_upgrade_score:
				best_upgrade_score = score
				best_upgrade_id = card_id
		if best_upgrade_id != "":
			run.money = int(run.money) - route_service.SHOP_UPGRADE_COST
			route_service.upgrade_card(run, best_upgrade_id)


func _upgrade_opponent_deck(deck: Dictionary, affinity: String, ai: String) -> void:
	var upgrade_count: int = int({"easy": 1, "medium": 4, "hard": 7, "expert": 9}.get(ai, 1))
	var candidates: Array[String] = []
	for card_value in catalog.cards:
		var card: Dictionary = card_value
		var card_id := String(card.get("id", ""))
		if card_id != "" and String(card.get("archetype", "neutral")) in [affinity, "neutral"]:
			candidates.append(card_id)
	for unused in range(upgrade_count):
		var best_remove := ""
		var best_add := ""
		var best_gain := 0.0
		for remove_id_value in deck.keys():
			var remove_id := String(remove_id_value)
			var remove_type := String(catalog.cards_by_id[remove_id].get("card_type", ""))
			for add_id in candidates:
				if add_id == remove_id:
					continue
				if String(catalog.cards_by_id[add_id].get("card_type", "")) != remove_type:
					continue
				var gain := _opponent_card_score(add_id) - _opponent_card_score(remove_id)
				if gain > best_gain:
					best_gain = gain
					best_remove = remove_id
					best_add = add_id
		if best_add == "":
			break
		deck[best_remove] = int(deck[best_remove]) - 1
		if int(deck[best_remove]) <= 0:
			deck.erase(best_remove)
		deck[best_add] = int(deck.get(best_add, 0)) + 1


func _opponent_card_score(card_id: String) -> float:
	var card: Dictionary = catalog.cards_by_id[card_id]
	var stats: Dictionary = card.get("stats", {})
	var strategic_bonus := 3.0 if card_id == "sweet_cinnamon_snail" else 0.0
	return (
		float(int(card.get("value", 0)))
		+ float(_rarity_rank(String(card.get("rarity", "common")))) * 6.0
		+ float(int(card.get("attack", 0))) * 0.8
		+ float(int(card.get("health", 0))) * 0.55
		+ float(int(stats.get("interaction", 0)) + int(stats.get("advantage", 0))) * 0.4
		- float(int(card.get("cost", 0))) * 0.2
		+ strategic_bonus
	)


func _card_score(card_id: String, starter: String) -> float:
	var card: Dictionary = catalog.cards_by_id[card_id]
	var stats: Dictionary = card.get("stats", {})
	var score := float(int(card.get("value", 0))) * 1.5 + float(_rarity_rank(String(card.get("rarity", "common")))) * 2.0
	score += float(int(card.get("attack", 0))) * 0.7 + float(int(card.get("health", 0))) * 0.45
	score += float(int(stats.get("interaction", 0)) + int(stats.get("advantage", 0)) + int(stats.get("consistency", 0))) * 0.35
	if String(card.get("archetype", "neutral")) == starter:
		score += 2.0
	return score


func _deck_limit(card_id: String) -> int:
	return 0


func _rarity_rank(rarity: String) -> int:
	return {"common": 0, "uncommon": 1, "rare": 2, "mythic": 3}.get(rarity, 0)


func _predator_affinity(affinity: String) -> String:
	return {"spicy": "hearty", "hearty": "sweet", "sweet": "spicy", "fresh": "spicy"}.get(affinity, "spicy")


func _empty_totals() -> Dictionary:
	return {
		"runs": 0, "wins": 0, "battles": 0, "battle_wins": 0,
		"turns": 0, "damage_taken": 0, "reshuffles": 0,
		"rewards_picked": 0, "shops": 0, "events": 0,
		"capped_battles": 0, "final_life": 0, "final_deck_size": 0,
		"death_layers": {}, "death_node_types": {},
	}


func _add_result(totals: Dictionary, result: Dictionary) -> void:
	for key in ["runs", "wins", "battles", "battle_wins", "turns", "damage_taken", "reshuffles", "rewards_picked", "shops", "events", "capped_battles", "final_life", "final_deck_size"]:
		totals[key] = int(totals[key]) + int(result[key])
	for key in ["death_layers", "death_node_types"]:
		for bucket in result[key]:
			totals[key][bucket] = int(totals[key].get(bucket, 0)) + int(result[key][bucket])


func _merge_totals(target: Dictionary, source: Dictionary) -> void:
	_add_result(target, source)


func _increment(buckets: Dictionary, key: String) -> void:
	buckets[key] = int(buckets.get(key, 0)) + 1


func _print_summary(label: String, totals: Dictionary) -> void:
	var runs := maxi(1, int(totals.runs))
	var battles := maxi(1, int(totals.battles))
	print("%s: %.1f%% run wins (%d/%d), %.1f%% battle wins, life %.1f, deck %.1f, turns/battle %.2f" % [
		label,
		_rate(int(totals.wins), int(totals.runs)), int(totals.wins), int(totals.runs),
		_rate(int(totals.battle_wins), int(totals.battles)),
		float(totals.final_life) / float(runs),
		float(totals.final_deck_size) / float(runs),
		float(totals.turns) / float(battles),
	])
	print("  deaths by layer %s; by node %s; capped battles %d" % [
		JSON.stringify(totals.death_layers), JSON.stringify(totals.death_node_types), int(totals.capped_battles)
	])


func _balance_flags(
	starters: Array[String],
	starter_results: Dictionary,
	totals: Dictionary,
	minimum_win_rate: float,
	maximum_win_rate: float
) -> Array[String]:
	var flags: Array[String] = []
	if minimum_win_rate < 0.0 and maximum_win_rate < 0.0:
		return flags
	var groups := {"Overall": totals}
	for starter in starters:
		groups[starter.capitalize()] = starter_results[starter]
	for label in groups:
		var group: Dictionary = groups[label]
		var win_rate := _rate(int(group.wins), int(group.runs))
		if minimum_win_rate >= 0.0 and win_rate < minimum_win_rate:
			flags.append("%s run win rate %.1f%% is below %.1f%%." % [label, win_rate, minimum_win_rate])
		if maximum_win_rate >= 0.0 and win_rate > maximum_win_rate:
			flags.append("%s run win rate %.1f%% is above %.1f%%." % [label, win_rate, maximum_win_rate])
	return flags


func _rate(numerator: int, denominator: int) -> float:
	return 0.0 if denominator <= 0 else float(numerator) * 100.0 / float(denominator)
