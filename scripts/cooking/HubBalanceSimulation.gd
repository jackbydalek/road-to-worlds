extends "res://scripts/cooking/RouteCampaignSimulation.gd"

# Headless audit of the CURRENT four-round hub. No saves, UI, or production
# content are changed. Inherited helpers only supply production AI turn handling.
# See docs/balance-audit-2026-09-04.md for assumptions and reproduction commands.
const TOURNAMENT_SCRIPT := preload("res://scripts/TournamentService.gd")
const RUN_SCRIPT := preload("res://scripts/RunStateService.gd")
const KEYWORD_PROPOSAL := preload("res://scripts/cooking/KeywordStarterProposal.gd")
const AFFINITIES := ["spicy", "hearty", "sweet", "fresh"]
const SIMPLE_LISTS := {
	"spicy": {"spicy_jalapeno_jackal": 5, "spicy_wasabi_wasp": 4, "spicy_sriracharrow": 3, "item_wooden_spoon": 3},
	"hearty": {"hearty_french_bread_dog": 5, "hearty_macaroni_manatee": 4, "hearty_gravy_gazelle": 3, "item_wooden_spoon": 3},
	"sweet": {"sweet_soft_serve_crab": 5, "sweet_caramel_camel": 4, "sweet_mothchi": 3, "item_wooden_spoon": 3},
}

class MeasuredCombat extends "res://scripts/cooking/CookingCombatService.gd":
	func _deal_chef_damage(state: Dictionary, target_side: String, amount: int, source_side: String = "", combat_damage: bool = false, animation_group_id: int = -1, source_card_type: String = "") -> void:
		if amount > 0:
			state[target_side].audit_damage = int(state[target_side].get("audit_damage", 0)) + amount
		super._deal_chef_damage(state, target_side, amount, source_side, combat_damage, animation_group_id, source_card_type)

	func _queue_heal_event(state: Dictionary, side: String, target_kind: String, instance_id: int, amount: int, group_id: int = -1) -> void:
		if target_kind == "chef":
			state[side].audit_healing = int(state[side].get("audit_healing", 0)) + amount
		super._queue_heal_event(state, side, target_kind, instance_id, amount, group_id)

var tournament: RefCounted
var run_service: RefCounted
# Adapter fields/methods consumed by the actual TournamentService.
var cards: Array
var cards_by_id: Dictionary
var archetypes_by_id: Dictionary
var options := {"mode": "campaign", "runs": "100", "seed": "940001", "variant": "current", "rewards": "all", "bye": "heal", "shop": "none", "life": "40", "player-ai": "hard", "player-style": "live", "tier": "base", "starter": "all", "profile": "live", "pressure": "yes", "output": "", "rival-scale": "1.0"}
var records: Array = []
var output_file: FileAccess
var rival_cache := {}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := String(arg).trim_prefix("--").split("=", true, 1)
			if not options.has(parts[0]):
				push_error("Unknown option: " + parts[0])
				quit(1)
				return
			options[parts[0]] = parts[1]
	catalog = CONTENT_SCRIPT.new()
	assert(catalog.load_all())
	cards = catalog.cards
	cards_by_id = catalog.cards_by_id
	archetypes_by_id = catalog.archetypes_by_id
	route_service = ROUTE_SCRIPT.new()
	route_service.setup(cards, cards_by_id)
	combat_service = MeasuredCombat.new()
	assert(combat_service.load_content())
	tournament = TOURNAMENT_SCRIPT.new()
	run_service = RUN_SCRIPT.new()
	run_service.setup(cards_by_id, archetypes_by_id, AFFINITIES, 1, 6, 8, "", 0)
	shop_service = SHOP_SCRIPT.new()
	shop_service.setup(cards, cards_by_id, catalog.boosters_by_id, shop_rng)
	player_ai = options["player-ai"]
	assert(player_ai in ["easy", "medium", "hard", "expert"])
	if options.output != "":
		output_file = FileAccess.open(options.output, FileAccess.WRITE)
		assert(output_file != null)
	print("HUB_AUDIT_OPTIONS=" + JSON.stringify(options))
	if options.mode == "offers":
		_audit_offers()
	elif options.mode == "inventory":
		for affinity in AFFINITIES:
			_record({"affinity": affinity, "tier": "starter15", "deck": _starter_deck(affinity)})
			for tier in ["easy", "medium", "hard", "expert"]:
				_record({"affinity": affinity, "tier": tier, "deck": _rival_deck(affinity, tier)})
		_record({"catalog": cards})
	elif options.mode == "duel":
		_duels()
	elif options.mode == "curve":
		_difficulty_curve()
	else:
		for starter in STARTERS:
			if options.starter != "all" and options.starter != starter:
				continue
			for index in range(int(options.runs)):
				# Same seeds across starters AND variants for paired comparisons.
				var result := _hub_run(starter, int(options.seed) + index)
				_record(result)
			print("Completed %s: %d runs" % [starter, int(options.runs)])
	if output_file != null:
		output_file.close()
	print("HUB_AUDIT_COMPLETE records=%d" % records.size())
	quit(0)

func _record(result: Dictionary) -> void:
	result.options = options.duplicate()
	records.append(result)
	if output_file != null:
		output_file.store_line(JSON.stringify(result))
		output_file.flush()
	else:
		print(JSON.stringify(result))

func _deck_entries_to_dict(entries: Array) -> Dictionary:
	return catalog.deck_entries_to_dict(entries)

func _card_archetype(card_data: Dictionary) -> String:
	return String(card_data.get("animalType", card_data.get("archetype", "neutral")))

func _rival_deck(affinity: String, tier: String) -> Dictionary:
	var key := affinity + tier
	if not rival_cache.has(key):
		rival_cache[key] = tournament.opponent_deck_for_round(self, affinity, 1, {}, tier)
	return rival_cache[key].duplicate(true)

func _starter_deck(starter: String) -> Dictionary:
	var source: Dictionary = catalog.deck_entries_to_dict(archetypes_by_id[starter].starterDeck)
	if options.variant in ["keyword15", "keyword12"]:
		var proposal: Dictionary = KEYWORD_PROPOSAL.build(starter, combat_service.cards_by_id, 12 if options.variant == "keyword12" else 15)
		for id in proposal.cards:
			combat_service.cards_by_id[id] = proposal.cards[id]
		return proposal.deck
	if options.variant == "full20":
		return source
	if options.variant == "simple":
		return SIMPLE_LISTS[starter].duplicate(true)
	if options.variant == "fundamentals":
		var result := {"item_wooden_spoon": 2}
		for spec in [["attacker", "ingredient", 2, 2, 6], ["defender", "ingredient", 1, 3, 4], ["meal", "meal", 4, 4, 2]]:
			var id := "audit_%s_%s" % [starter, spec[0]]
			var definition := {"id": id, "name": "Basic " + String(spec[0]), "card_type": spec[1], "archetype": starter, "attack": spec[2], "health": spec[3], "text": "", "ingredient_types": [starter]}
			if spec[1] == "meal":
				definition.recipe = [starter]
			# Deliberately isolated from reward/shop catalog: hypothetical starters only.
			combat_service.cards_by_id[id] = definition
			result[id] = spec[4]
		var signature: String = {"spicy": "spicy_sriracharrow", "hearty": "hearty_gravy_gazelle", "sweet": "sweet_strawberry_sharkcake"}[starter]
		result[signature] = 1
		return result
	return route_service.compact_starter_deck(source, 15)

func _hub_run(starter: String, run_seed: int) -> Dictionary:
	var full: Dictionary = catalog.deck_entries_to_dict(archetypes_by_id[starter].starterDeck)
	var run: Dictionary = run_service.create_run(starter, full, run_service.predator_archetype(starter), "season", "white")
	route_service.initialize_run(run, run_seed)
	run.deck = _starter_deck(starter)
	run.collection = run.deck.duplicate(true)
	run.life = int(options.life)
	run.max_life = int(options.life)
	# Production hub keeps the FIRST FOUR generated singles for the whole floor.
	shop_rng.seed = run_seed
	shop_service.generate_shop_inventory(run, starter)
	run.shop = run.shop.slice(0, 4)
	var result := {"starter": starter, "seed": run_seed, "won": false, "battles": [], "offers": [], "picks": [], "purchases": [], "bye_healing": 0, "start_deck": run.deck.duplicate(true), "shop_stock": run.shop.duplicate(), "upgrade": ""}
	for round_number in range(1, 5):
		if options.bye == "heal" and not run.hub_break_used and (int(run.max_life) - int(run.life) >= ROUTE_SCRIPT.HUB_BREAK_HEAL_AMOUNT or round_number == 4):
			var heal: Dictionary = route_service.use_hub_break_heal(run)
			result.bye_healing += int(heal.get("healed", 0))
		elif options.bye == "upgrade" and not run.hub_break_used:
			var eligible: Array[String] = route_service.upgradeable_card_ids(run)
			eligible.sort_custom(func(a, b): return _card_score(a, starter) > _card_score(b, starter))
			if not eligible.is_empty():
				route_service.use_hub_break_upgrade(run, eligible[0])
				result.upgrade = eligible[0]
		if options.shop == "singles":
			_buy_singles(run, result)
		var node_type := "enemy" if round_number <= 2 else "mini_boss" if round_number == 3 else "final_boss"
		var encounter_seed := run_seed ^ hash("locals_round_%d" % round_number)
		var affinity := String(AFFINITIES[posmod(encounter_seed, AFFINITIES.size())])
		if affinity == starter:
			affinity = run_service.predator_archetype(affinity)
		var tier: String = route_service.encounter_ai(node_type)
		var prepared: Dictionary = route_service.prepare_player_combat_deck(run, run.deck)
		for card_id in prepared.cards:
			combat_service.cards_by_id[card_id] = prepared.cards[card_id].duplicate(true)
		var battle := _battle(prepared.deck, _rival_deck(affinity, tier), starter, affinity, int(run.life), int(run.max_life), roundi(float(route_service.encounter_life(node_type)) * float(options["rival-scale"])), tier, encounter_seed, true)
		battle.round = round_number
		battle.rival_affinity = affinity
		battle.deck_size = route_service.deck_total(run.deck)
		result.battles.append(battle)
		run.life = maxi(0, int(battle.player_life))
		if battle.winner != "player":
			break
		run.money += 8 if round_number == 4 else 5 if round_number == 3 else 2
		var offer: Array[String] = route_service.generate_reward_offer(starter, node_type, encounter_seed + 97)
		result.offers.append(offer.duplicate())
		var selected := _select_rewards(run, offer)
		result.picks.append(selected)
		for card_id in selected:
			run.deck[card_id] = int(run.deck.get(card_id, 0)) + 1
			run.collection[card_id] = int(run.collection.get(card_id, 0)) + 1
		if round_number == 4:
			result.won = true
	result.final_life = run.life
	result.final_deck_size = route_service.deck_total(run.deck)
	result.money = run.money
	return result

func _select_rewards(run: Dictionary, offer: Array[String]) -> Array[String]:
	if options.rewards == "none":
		return []
	if options.rewards == "all":
		return offer.duplicate()
	var ranked := offer.duplicate()
	ranked.sort_custom(func(a, b): return _card_score(a, run.starter) > _card_score(b, run.starter))
	if options.rewards == "one":
		var single: Array[String] = []
		if not ranked.is_empty():
			single.append(ranked[0])
		return single
	# Simple understandable policy: avoid Meals whose recipe has no matching
	# Ingredient in this deck; accept at most two choices. Not an optimal drafter.
	var selected: Array[String] = []
	for id in ranked:
		if _recipe_supported(cards_by_id[id], run.deck):
			selected.append(id)
			if selected.size() == 2:
				break
	return selected

func _recipe_supported(card_data: Dictionary, deck: Dictionary) -> bool:
	var pool: Array[String] = []
	for id in deck:
		var ingredient: Dictionary = combat_service.cards_by_id[id]
		if ingredient.get("card_type", "") != "ingredient":
			continue
		for unused in range(int(deck[id])):
			pool.append(id)
	# Backtracking handles OR requirements and distinct cards correctly.
	return _can_pay_recipe(card_data.get("recipe", []), pool, 0)

func _can_pay_recipe(recipe: Array, pool: Array[String], index: int) -> bool:
	if index >= recipe.size():
		return true
	var alternatives := String(recipe[index]).split("|")
	for i in range(pool.size()):
		var ingredient: Dictionary = combat_service.cards_by_id[pool[i]]
		var matched := alternatives.has("any")
		for affinity in ingredient.get("ingredient_types", [ingredient.get("archetype", "")]):
			matched = matched or alternatives.has(String(affinity))
		if matched:
			var remaining := pool.duplicate()
			remaining.remove_at(i)
			if _can_pay_recipe(recipe, remaining, index + 1):
				return true
	return false

func _buy_singles(run: Dictionary, result: Dictionary) -> void:
	var stock: Array = run.shop.duplicate()
	stock.sort_custom(func(a, b): return _card_score(a, run.starter) / float(shop_service.card_price(run, a)) > _card_score(b, run.starter) / float(shop_service.card_price(run, b)))
	for id in stock:
		var price: int = shop_service.card_price(run, id)
		if price <= int(run.money) and _recipe_supported(cards_by_id[id], run.deck):
			run.money -= price
			run.deck[id] = int(run.deck.get(id, 0)) + 1
			run.collection[id] = int(run.collection.get(id, 0)) + 1
			run.shop.erase(id)
			result.purchases.append(id)

func _battle(left: Dictionary, right: Dictionary, left_affinity: String, right_affinity: String, life: int, max_life: int, rival_life: int, tier: String, battle_seed: int, campaign: bool) -> Dictionary:
	# IDs and blank archetypes match Tabletop3DPrototype's live initialization.
	combat_service.decks["configured_player"] = {"name": "Audit Player", "archetype": left_affinity if options.profile == "affinity" else "", "cards": left}
	combat_service.decks["configured_opponent"] = {"name": "Audit Rival", "archetype": right_affinity if options.profile == "affinity" else "", "cards": right}
	var rules := {"player_life": life, "player_max_life": max_life, "opponent_life": rival_life, "opponent_max_life": rival_life, "turn_hand_floor": 3, "reshuffle_pressure": options.pressure == "yes", "reshuffle_damage": [3, 5, 7]}
	var state: Dictionary = combat_service.start_game("configured_player", "configured_opponent", battle_seed, "player", false, tier, rules)
	# Equal-seat duels use the same style to isolate decks. Campaign uses exact
	# live fallback styles (the human player's decisions are an AI proxy).
	if not campaign and options.profile == "live":
		state.player.ai_profile = state.opponent.ai_profile
	if options["player-style"] in ["pressure", "defensive", "value"]:
		state.player.ai_profile = options["player-style"]
	while not bool(state.game_over) and int(state.turn) <= turn_cap:
		state.ai_difficulty = player_ai
		_run_production_ai_turn(state, "player")
		if bool(state.game_over):
			break
		combat_service._start_turn(state, "opponent")
		if bool(state.game_over):
			break
		state.ai_difficulty = tier
		_run_production_ai_turn(state, "opponent")
		if bool(state.game_over):
			break
		state.turn += 1
		combat_service._start_turn(state, "player")
		state.animation_events.clear()
	var reshuffles := int(state.player.fatigue)
	return {"winner": String(state.winner), "capped": not bool(state.game_over), "seed": battle_seed, "turns": mini(int(state.turn), turn_cap), "start_life": life, "rival_start_life": rival_life, "player_life": int(state.player.life), "opponent_life": int(state.opponent.life), "damage": int(state.player.get("audit_damage", 0)), "healing": int(state.player.get("audit_healing", 0)), "reshuffles": reshuffles, "pressure_damage": (3 if reshuffles >= 1 else 0) + (5 if reshuffles >= 2 else 0) + maxi(0, reshuffles - 2) * 7, "opponent_reshuffles": int(state.opponent.fatigue), "player_profile": state.player.ai_profile, "rival_profile": state.opponent.ai_profile}

func _run_production_ai_turn(state: Dictionary, acting_side: String) -> void:
	var swapped := acting_side == "player"
	if swapped:
		_swap_perspective(state)
	state.phase = "opponent_turn"
	var safety := 64
	combat_service._ai_turn(state, false)
	while not bool(state.game_over) and not state.get("pending_reaction", {}).is_empty() and safety > 0:
		safety -= 1
		var eligible: Array[int] = combat_service.reaction_hand_indices(state)
		combat_service.resolve_reaction(state, int(eligible[0]) if not eligible.is_empty() else -1, false)
		if not bool(state.game_over) and state.get("pending_reaction", {}).is_empty():
			combat_service._ai_turn(state, false)
	assert(safety > 0, "Reaction safety limit reached; reject this experiment")
	if swapped:
		_swap_perspective(state)

func _duels() -> void:
	var affinities: Array = AFFINITIES if options.variant in ["current", "full20"] else STARTERS
	for left_index in range(affinities.size()):
		for right_index in range(left_index + 1, affinities.size()):
			for reverse in [false, true]:
				var left := String(affinities[right_index if reverse else left_index])
				var right := String(affinities[left_index if reverse else right_index])
				var left_deck := _starter_deck(left) if options.tier == "base" else _rival_deck(left, options.tier)
				var right_deck := _starter_deck(right) if options.tier == "base" else _rival_deck(right, options.tier)
				for index in range(int(options.runs)):
					var result := _battle(left_deck, right_deck, left, right, 20, 20, 20, player_ai, int(options.seed) + index, false)
					result.left = left
					result.right = right
					_record(result)
			print("Completed matchup %s / %s" % [affinities[left_index], affinities[right_index]])

func _difficulty_curve() -> void:
	# Fresh 40-life, unevolved starters against each real rival tier: separates
	# encounter strength from accumulated damage and reward/shop choices.
	for starter in STARTERS:
		var starter_deck := _starter_deck(starter)
		for tier in ["easy", "medium", "hard", "expert"]:
			var rival_life := 12 if tier in ["easy", "medium"] else 18 if tier == "hard" else 28
			for roll_index in range(AFFINITIES.size()):
				var affinity := String(AFFINITIES[roll_index])
				if affinity == starter:
					affinity = run_service.predator_archetype(starter)
				for index in range(int(options.runs)):
					var result := _battle(starter_deck, _rival_deck(affinity, tier), starter, affinity, int(options.life), int(options.life), rival_life, tier, int(options.seed) + roll_index * 100000 + index, true)
					result.starter = starter
					result.rival_affinity = affinity
					result.tier = tier
					result.deck_size = route_service.deck_total(starter_deck)
					_record(result)
			print("Completed curve %s / %s" % [starter, tier])

func _audit_offers() -> void:
	for starter in STARTERS:
		var deck := _starter_deck(starter)
		for kind in ["enemy", "mini_boss", "final_boss"]:
			var tally := {"starter": starter, "kind": kind, "cards": {}, "rarities": {}, "types": {}, "affinities": {}, "unsupported_meals": 0, "offered": 0, "offers_without_supported_meal": 0, "offers_without_rare_plus": 0, "illegal": 0}
			for index in range(int(options.runs)):
				var offers: Array[String] = route_service.generate_reward_offer(starter, kind, int(options.seed) + index)
				assert(offers.size() == route_service.reward_pick_count(kind))
				var supported_meal := false
				var rare_plus := false
				for id in offers:
					var c: Dictionary = cards_by_id[id]
					_increment(tally.cards, id)
					_increment(tally.rarities, c.rarity)
					_increment(tally.types, c.card_type)
					_increment(tally.affinities, c.archetype)
					tally.offered += 1
					if not route_service.card_is_starter_eligible(c, starter):
						tally.illegal += 1
					if c.card_type == "meal":
						if _recipe_supported(c, deck):
							supported_meal = true
						else:
							tally.unsupported_meals += 1
					rare_plus = rare_plus or c.rarity in ["rare", "mythic"]
				if not supported_meal:
					tally.offers_without_supported_meal += 1
				if not rare_plus:
					tally.offers_without_rare_plus += 1
			_record(tally)
