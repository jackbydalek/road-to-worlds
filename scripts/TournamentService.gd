extends RefCounted
class_name TournamentService


func create_active_tournament(host, event: Dictionary, deck_metrics: Dictionary) -> Dictionary:
	var event_id := String(event.get("id", "weekly_locals"))
	return {
		"active": true,
		"event_id": event_id,
		"event_name": String(event.get("name", event_id)),
		"round": 1,
		"rounds": int(event.get("rounds", 3)),
		"required_wins": int(event.get("requiredWins", 2)),
		"entry_fee": int(event.get("entryFee", 0)),
		"wins": 0,
		"losses": 0,
		"deck_primary": String(deck_metrics.primary),
		"logs": [
			"Entered %s with %s. Entry paid: $%d." % [
				String(event.get("name", event_id)),
				host.archetypes_by_id[String(deck_metrics.primary)].name,
				int(event.get("entryFee", 0))
			]
		],
		"current_opponent": {},
		"current_seed": 0,
		"round_result_recorded": false
	}


func should_finish(active: Dictionary) -> bool:
	var wins := int(active.get("wins", 0))
	var losses := int(active.get("losses", 0))
	var rounds := int(active.get("rounds", 1))
	var required := int(active.get("required_wins", 1))
	if losses > 0:
		return true
	if wins + losses >= rounds:
		return true
	return losses > rounds - required


func build_event_result_summary(
	host,
	event: Dictionary,
	wins: int,
	losses: int,
	required: int,
	made_record: bool,
	reward_money: int,
	reward_packs: int,
	lives_lost: int,
	run_continues: bool
) -> Dictionary:
	var event_id := String(event.get("id", "weekly_locals"))
	var next_event_id := String(host.run.get("selected_event_id", event_id))
	var next_event: Dictionary = host._season_event_by_id(next_event_id)
	return {
		"event_id": event_id,
		"event_name": String(event.get("name", event_id)),
		"stage": String(event.get("stage", "Tournament")),
		"wins": wins,
		"losses": losses,
		"rounds": int(event.get("rounds", max(1, wins + losses))),
		"required_wins": required,
		"made_record": made_record,
		"reward_money": reward_money,
		"reward_packs": reward_packs,
		"lives_lost": lives_lost,
		"lives_remaining": int(host.run.get("season_lives", 0)),
		"max_lives": int(host.run.get("max_season_lives", 0)),
		"next_event_id": next_event_id,
		"next_event_name": String(next_event.get("name", next_event_id)),
		"run_continues": run_continues,
		"season_champion": bool(host.run.get("season_champion", false)),
		"run_over": bool(host.run.get("run_over", false))
	}


func generate_opponent(host, round_number: int, deck_metrics: Dictionary, event: Dictionary = {}) -> Dictionary:
	var names := ["Mina", "Owen", "Priya", "Cal", "Nico", "Sam", "Jules", "Iris"]
	var event_id := String(event.get("id", "weekly_locals"))
	var event_index: int = max(0, host._season_event_index(event_id))
	var event_rounds := int(event.get("rounds", 3))
	var quality_bonus := difficulty_opponent_quality_bonus(host) + float(event_index) * 5.0
	if round_number >= event_rounds:
		var boss_archetype: String = String(event.get("bossArchetype", host._predator_archetype(String(deck_metrics.primary))))
		return {
			"name": String(event.get("bossName", "Local Rival Tess")),
			"archetype": boss_archetype,
			"quality": 52.0 + float(host.run.week) * 1.8 + float(round_number) * 1.5 + quality_bonus,
			"round": round_number,
			"tags": host.archetypes_by_id[boss_archetype].tags
		}

	var archetype_id: String = host._weighted_meta_pick()
	return {
		"name": names[host.rng.randi_range(0, names.size() - 1)],
		"archetype": archetype_id,
		"quality": 43.0 + float(round_number) * 3.0 + float(host.run.week) * 1.2 + quality_bonus + host.rng.randf_range(-3.0, 3.0),
		"round": round_number,
		"tags": host.archetypes_by_id[archetype_id].tags
	}


func difficulty_opponent_quality_bonus(host) -> float:
	match host._run_difficulty_id():
		"blue":
			return 7.0
		"silver":
			return 4.0
		_:
			return 0.0


func season_round_first_side(host) -> String:
	if host._run_difficulty_id() != "gold":
		return "player"
	return "opponent" if host.rng.randf() < 0.5 else "player"


func ai_difficulty_for_round(host, event: Dictionary, round_number: int) -> String:
	var event_index: int = max(0, host._season_event_index(String(event.get("id", "weekly_locals"))))
	var tier := "expert"
	if event_index == 0:
		tier = "easy" if round_number <= 1 else "medium"
	elif event_index == 1:
		tier = "hard" if round_number <= 2 else "expert"
	if host._run_difficulty_id() == "blue":
		if tier == "easy":
			tier = "medium"
		elif tier == "medium":
			tier = "hard"
		elif tier == "hard":
			tier = "expert"
	return tier


func opponent_deck_for_round(
	host,
	opponent_archetype: String,
	round_number: int,
	event: Dictionary = {},
	ai_difficulty: String = "easy"
) -> Dictionary:
	var opponent_deck: Dictionary = host._deck_entries_to_dict(host.archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var upgrade_count := _deck_upgrade_count_for_ai(ai_difficulty)
	if upgrade_count > 0:
		_upgrade_opponent_deck_for_difficulty(host, opponent_deck, opponent_archetype, upgrade_count)
	return opponent_deck


func _deck_upgrade_count_for_ai(ai_difficulty: String) -> int:
	match ai_difficulty:
		"expert":
			return 8
		"hard":
			return 6
		"medium":
			return 3
	return 0


func _upgrade_opponent_deck_for_difficulty(host, opponent_deck: Dictionary, opponent_archetype: String, upgrade_count: int) -> void:
	var candidates: Array = _opponent_upgrade_candidates(host, opponent_archetype)
	for unused_upgrade in range(upgrade_count):
		var best_swap := _best_opponent_deck_upgrade(host, opponent_deck, candidates)
		if best_swap.is_empty():
			return
		var remove_id := String(best_swap.remove_id)
		var add_id := String(best_swap.add_id)
		opponent_deck[remove_id] = int(opponent_deck[remove_id]) - 1
		if int(opponent_deck[remove_id]) <= 0:
			opponent_deck.erase(remove_id)
		opponent_deck[add_id] = int(opponent_deck.get(add_id, 0)) + 1


func _best_opponent_deck_upgrade(host, opponent_deck: Dictionary, candidates: Array) -> Dictionary:
	var best_swap: Dictionary = {}
	var best_improvement := 0.0
	for remove_id_value in opponent_deck.keys():
		var remove_id := String(remove_id_value)
		if int(opponent_deck.get(remove_id, 0)) <= 0 or not host.cards_by_id.has(remove_id):
			continue
		var remove_card: Dictionary = host.cards_by_id[remove_id]
		var remove_type := String(remove_card.get("card_type", ""))
		var remove_score := _opponent_card_upgrade_score(host, remove_id)
		for candidate_id_value in candidates:
			var candidate_id := String(candidate_id_value)
			if candidate_id == remove_id or not host.cards_by_id.has(candidate_id):
				continue
			if String(host.cards_by_id[candidate_id].get("card_type", "")) != remove_type:
				continue
			if int(opponent_deck.get(candidate_id, 0)) >= host._deck_limit(candidate_id):
				continue
			var improvement := _opponent_card_upgrade_score(host, candidate_id) - remove_score
			if improvement > best_improvement:
				best_improvement = improvement
				best_swap = {"remove_id": remove_id, "add_id": candidate_id}
	return best_swap


func _opponent_upgrade_candidates(host, opponent_archetype: String) -> Array:
	var candidates: Array = []
	for card in host.cards:
		var card_id := String(card.get("id", ""))
		if card_id == "":
			continue
		var card_archetype: String = host._card_archetype(card)
		if card_archetype != opponent_archetype and card_archetype != "neutral":
			continue
		candidates.append(card_id)
	candidates.sort_custom(func(a, b) -> bool: return _opponent_card_upgrade_score(host, String(a)) > _opponent_card_upgrade_score(host, String(b)))
	return candidates


func _opponent_card_upgrade_score(host, card_id: String) -> float:
	if not host.cards_by_id.has(card_id):
		return 0.0
	var card: Dictionary = host.cards_by_id[card_id]
	var stats: Dictionary = card.get("stats", {})
	return (
		float(int(card.get("value", 0)))
		+ float(host._rarity_rank(String(card.get("rarity", "common")))) * 6.0
		+ float(int(card.get("attack", 0))) * 0.8
		+ float(int(card.get("health", 0))) * 0.55
		+ float(int(stats.get("interaction", 0)) + int(stats.get("advantage", 0))) * 0.4
		- float(int(card.get("cost", 0))) * 0.2
	)


func simulate_combat_match(host, opponent: Dictionary, deck_metrics: Dictionary) -> Dictionary:
	var player_game_wins := 0
	var opponent_game_wins := 0
	var game_number := 1
	var game_summaries: Array = []
	var probability := estimate_match_probability(host, opponent, deck_metrics)

	while player_game_wins < 2 and opponent_game_wins < 2:
		var seed_value: int = host.rng.randi()
		var player_won: bool = host.rng.randf() <= probability
		if player_won:
			player_game_wins += 1
		else:
			opponent_game_wins += 1

		game_summaries.append("Kitchen game %d: %s. Seed %d." % [
			game_number,
			"Won" if player_won else "Lost",
			seed_value
		])
		game_number += 1

	return {
		"won": player_game_wins > opponent_game_wins,
		"player_game_wins": player_game_wins,
		"opponent_game_wins": opponent_game_wins,
		"display_probability": probability,
		"game_summaries": game_summaries
	}


func estimate_match_probability(host, opponent: Dictionary, deck_metrics: Dictionary) -> float:
	var player_score := float(deck_metrics.score)
	player_score += host._matchup_tech_bonus(opponent.tags)
	player_score += host.rng.randf_range(-2.0, 2.0)

	var opponent_score := float(opponent.quality)
	var matchup_mod := 0.0
	var player_archetype: Dictionary = host.archetypes_by_id[deck_metrics.primary]
	if player_archetype.get("matchups", {}).has(opponent.archetype):
		matchup_mod = float(player_archetype.matchups[opponent.archetype])

	var base_probability: float = clamp(0.5 + ((player_score - opponent_score) * 0.018) + matchup_mod, 0.08, 0.92)
	return base_probability
