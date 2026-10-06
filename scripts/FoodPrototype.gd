extends RefCounted
## Isolated, data-driven ruleset. Apply only to a freshly loaded catalog.

const ID := "food_prototype"
const SAVE_PATH := "user://food_prototype_run.json"
const CONFIG_PATH := "res://data/content/food_prototype.json"
const WEEKLY := preload("res://scripts/WeeklyDemoService.gd")


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


static func active(run: Dictionary) -> bool:
	return String(run.get("ruleset", "")) == ID


static func apply_catalog(catalog: RefCounted) -> void:
	var settings := config()
	for card in catalog.cards:
		if String(card.get("card_type", "")) == "meal":
			var recipe: Array = card.get("recipe", [])
			for index in range(recipe.size()):
				recipe[index] = "any"
			card.recipe = recipe
		var overrides: Dictionary = settings.get("card_overrides", {}).get(String(card.id), {})
		card.merge(overrides, true)
		catalog._decorate_card(card, String(card.get("expansion_id", "core")))
	for source in settings.starter_cards:
		var card: Dictionary = source.duplicate(true)
		var art: Dictionary = catalog.cards_by_id.get(String(source.art_source), {})
		for key in art:
			if String(key).begins_with("art"):
				card[key] = art[key]
		card.erase("art_source")
		card.erase("copies")
		card.archetype = "neutral"
		card.text = ""
		card.rare = false
		card.starter_only = true
		if String(card.card_type) == "ingredient":
			card.ingredient_types = ["neutral"]
		catalog._decorate_card(card)
		catalog.cards.append(card)
		catalog.cards_by_id[String(card.id)] = card
	var starter: Dictionary = catalog.archetypes_by_id.hearty.duplicate(true)
	starter.id = ID
	starter.name = "Food Prototype"
	starter.summary = "A basic deck. Every food type. Any Ingredients."
	starter.animalType = "neutral"
	starter.strategy = "adaptive"
	starter.tags = []
	starter.matchups = {}
	starter.starterDeck = []
	var deck := starter_deck()
	for id in deck:
		starter.starterDeck.append({"cardId": id, "count": deck[id]})
	catalog.archetypes_by_id[ID] = starter


static func starter_deck() -> Dictionary:
	var settings := config()
	var deck: Dictionary = settings.starter_tools.duplicate(true)
	for card in settings.starter_cards:
		deck[String(card.id)] = int(card.copies)
	return deck


static func initialize(run: Dictionary, seed_value: int, catalog: RefCounted) -> void:
	run.ruleset = ID
	run.ruleset_version = int(config().version)
	run.food_balance = {"encounters": config().get("encounters", {}).duplicate(true), "synergy_rewards": true}
	run.demo_weeks = 1
	run.hub_rounds_per_floor = 4
	run.season_goal = "Win four rounds of Locals with your evolving Food Prototype deck."
	run.season_notice = "Meals use any Ingredients. All five food types are available."
	run.food_opening_pending = true
	run.food_opening_offer = opening_offer(seed_value, catalog.cards_by_id)
	run.food_opening_pick = ""
	run.food_playtest_log = []


static func opening_offer(seed_value: int, database: Dictionary) -> Array:
	var pool: Array = config().opening_pool.duplicate()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value ^ 0xF00D
	var offer: Array = []
	while offer.size() < 3 and not pool.is_empty():
		var id := String(pool.pop_at(random.randi_range(0, pool.size() - 1)))
		if database.has(id):
			offer.append(id)
	return offer


static func choose_opening(run: Dictionary, card_id: String) -> bool:
	if not active(run) or not bool(run.get("food_opening_pending", false)) or not run.get("food_opening_offer", []).has(card_id):
		return false
	run.deck[card_id] = int(run.deck.get(card_id, 0)) + 1
	run.collection[card_id] = int(run.collection.get(card_id, 0)) + 1
	run.food_opening_pick = card_id
	run.food_opening_pending = false
	return true


static func encounter_settings(run: Dictionary, node_type: String) -> Dictionary:
	if not active(run):
		return {}
	return run.get("food_balance", {}).get("encounters", config().get("encounters", {})).get(node_type, {}).duplicate(true)


static func synergy_rewards_enabled(run: Dictionary) -> bool:
	return active(run) and bool(run.get("food_balance", {}).get("synergy_rewards", true))


static func reward_card_eligible(card: Dictionary, run: Dictionary, database: Dictionary) -> bool:
	if bool(card.get("starter_only", false)) or not WEEKLY.card_available(card, run):
		return false
	# Week one has no Spices, so attachment removal cannot be useful yet.
	if String(card.get("id", "")) == "item_grater":
		return false
	# Affinity tutors need an actual target; the rest of the pool remains open.
	if String(card.get("id", "")).ends_with("_shopping_list"):
		for id in run.get("deck", {}):
			var target: Dictionary = database.get(id, {})
			if int(run.deck[id]) > 0 and target.get("card_type", "") == "ingredient" and target.get("ingredient_types", []).has(card.get("archetype", "")):
				return true
		return false
	return true


static func package_strength(deck: Dictionary, package: Dictionary) -> int:
	var score := 0
	for role in ["enablers", "payoffs"]:
		for id in package.get(role, []):
			score += mini(2, maxi(0, int(deck.get(id, 0))))
	return score


static func synergy_reward_pair(run: Dictionary, database: Dictionary, random: RandomNumberGenerator, excluded: Array = []) -> Array[String]:
	var packages: Dictionary = config().get("reward_packages", {})
	var candidates: Array = []
	var best_strength := -1
	for key in packages:
		var package: Dictionary = packages[key]
		var eligible := {}
		for role in ["enablers", "payoffs"]:
			eligible[role] = []
			for id in package.get(role, []):
				if not excluded.has(id) and database.has(id) and reward_card_eligible(database[id], run, database):
					eligible[role].append(id)
		if eligible.enablers.is_empty() or eligible.payoffs.is_empty():
			continue
		var strength := package_strength(run.get("deck", {}), package)
		if strength > best_strength:
			candidates.clear()
			best_strength = strength
		if strength == best_strength:
			candidates.append(eligible)
	if candidates.is_empty():
		return []
	var chosen: Dictionary = candidates[random.randi_range(0, candidates.size() - 1)]
	var pair: Array[String] = []
	for role in ["enablers", "payoffs"]:
		var weighted: Array[String] = []
		for id in chosen[role]:
			# Favor new pieces without making extra copies impossible.
			var weight := 3 if int(run.get("deck", {}).get(id, 0)) == 0 else 1
			for unused in range(weight):
				weighted.append(id)
		pair.append(weighted[random.randi_range(0, weighted.size() - 1)])
	return pair


static func record_checkpoint(run: Dictionary) -> void:
	if not active(run):
		return
	var checkpoint := {
		"round": run.get("hub_round", 1), "life": run.get("life", 40),
		"money": run.get("money", 0), "deck": run.get("deck", {}).duplicate(true),
		"upgrades": run.get("card_upgrades", {}).duplicate(true),
		"opening_offer": run.get("food_opening_offer", []).duplicate(),
		"opening_pick": run.get("food_opening_pick", ""),
		"reward_offer": run.get("reward_offer", []).duplicate(),
		"reward_picks": run.get("reward_selected", []).duplicate(),
		"shop_offer": run.get("hub_shop", {}).get("inventory", []).duplicate(),
		"results": run.get("route_round_results", []).duplicate(true),
		"finished": run.get("run_over", false), "won": run.get("demo_complete", false),
	}
	var history: Array = run.get("food_playtest_log", [])
	if history.is_empty() or history.back() != checkpoint:
		history.append(checkpoint)
	run.food_playtest_log = history


static func write_playtest(run: Dictionary, save_path: String) -> void:
	if not active(run):
		return
	var path := save_path.get_basename() + "_playtest_%s.json" % str(run.get("route_seed", 0))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"ruleset": ID, "version": run.get("ruleset_version", 1), "balance": run.get("food_balance", {}), "seed": run.get("route_seed", 0), "checkpoints": run.get("food_playtest_log", []), "final_deck": run.get("deck", {})}, "\t"))
