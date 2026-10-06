extends RefCounted
class_name RouteRunService

const WEEKLY := preload("res://scripts/WeeklyDemoService.gd")
const FOOD := preload("res://scripts/FoodPrototype.gd")
var weekly := WEEKLY.new()

const STARTING_LIFE := 40
const STARTING_DECK_SIZE := 15
const REGULAR_REWARD_SIZE := 3
const MINIBOSS_REWARD_SIZE := 5
const BOSS_REWARD_SIZE := 8
const SHOP_HEAL_COST := 4
const SHOP_HEAL_AMOUNT := 9
const SHOP_REMOVE_COST := 3
const SHOP_UPGRADE_COST := 5
const HUB_BREAK_HEAL_AMOUNT := 5
const EVENT_HEAL_AMOUNT := 8
const EVENT_MAX_LIFE_AMOUNT := 5
const EVENT_MONEY_AMOUNT := 5
const EVENT_STEAL_AMOUNT := 3
const EVENT_UPGRADE_DAMAGE := 5
const EVENT_OUTCOMES := [
	"heal",
	"max_life",
	"money",
	"steal_money",
	"remove_card",
	"upgrade_card",
	"trade_card",
]
const UPGRADED_CARD_SUFFIX := "__route_upgraded"

# Starter runs are deliberately closed ecosystems.  A card with more than one
# printed affinity must fit entirely within the starter's permitted pairings.
const STARTER_ALLOWED_AFFINITIES := {
	"spicy": ["spicy", "fresh", "funky"],
	"sweet": ["sweet", "hearty", "funky"],
	"hearty": ["hearty", "sweet", "fresh"],
}

var cards: Array = []
var cards_by_id: Dictionary = {}
var rng := RandomNumberGenerator.new()


func setup(card_list: Array, card_database: Dictionary) -> void:
	cards = card_list
	cards_by_id = card_database


func initialize_run(target_run: Dictionary, seed_value: int) -> void:
	target_run.run_loop = "route"
	target_run.act_id = "starter_city"
	target_run.act_number = 1
	target_run.route_seed = seed_value
	target_run.route_graph = {}
	target_run.route_current = "start"
	target_run.route_visited = ["start"]
	target_run.route_resolved = ["start"]
	target_run.pending_route_node = {}
	target_run.last_route_shopkeeper_card_id = ""
	target_run.route_battle = {}
	target_run.route_round_results = []
	target_run.reward_offer = []
	target_run.reward_picks_remaining = 0
	target_run.route_pack_presented = false
	target_run.route_pack_opened = false
	target_run.card_upgrades = {}
	target_run.campaign_presentation = "tournament_hub"
	target_run.hub_floor = "locals"
	target_run.hub_round = 1
	target_run.hub_rounds_per_floor = int(weekly.config.get("rounds_per_week", 4))
	target_run.week = 1
	target_run.demo_weeks = int(weekly.config.get("weeks", 2))
	target_run.week_transition = ""
	target_run.deckbox = {}
	target_run.deckbox_offer = []
	target_run.deckbox_reward = {}
	target_run.hub_break_used = false
	target_run.hub_break_choice = ""
	target_run.hub_shop = {}
	target_run.hub_notice = ""
	target_run.max_life = STARTING_LIFE
	target_run.life = STARTING_LIFE
	target_run.run_over = false
	target_run.demo_complete = false
	target_run.season_goal = "Win two weekly Locals tournaments. Choose a deckbox and discover Second Helpings between weeks."
	target_run.season_notice = "Your deck and life carry between rounds and weeks. The bye machine works once each week."
	target_run.sideboard = {}
	target_run.deck = compact_starter_deck(target_run.get("deck", {}), STARTING_DECK_SIZE)
	target_run.collection = target_run.deck.duplicate(true)


func normalize_run(target_run: Dictionary) -> void:
	if String(target_run.get("run_loop", "")) != "route":
		return
	if not target_run.has("act_id"):
		target_run.act_id = "starter_city"
	if not target_run.has("act_number"):
		target_run.act_number = 1
	if not target_run.has("route_seed"):
		target_run.route_seed = 1
	if not target_run.has("route_graph"):
		target_run.route_graph = {}
	if not target_run.has("route_current"):
		target_run.route_current = "start"
	if not target_run.has("route_visited"):
		target_run.route_visited = ["start"]
	if not target_run.has("route_resolved"):
		target_run.route_resolved = ["start"]
	if not target_run.has("pending_route_node"):
		target_run.pending_route_node = {}
	if not target_run.has("last_route_shopkeeper_card_id"):
		target_run.last_route_shopkeeper_card_id = ""
	if not target_run.has("route_battle"):
		target_run.route_battle = {}
	if not target_run.has("reward_offer"):
		target_run.reward_offer = []
	if not target_run.has("reward_picks_remaining"):
		target_run.reward_picks_remaining = 0
	if not target_run.has("route_pack_presented"):
		target_run.route_pack_presented = false
	if not target_run.has("route_pack_opened"):
		# Older saves used route_reward_intro_seen to mean the cards were already open.
		target_run.route_pack_opened = bool(target_run.get("route_reward_intro_seen", false))
	if not target_run.has("card_upgrades") or not (target_run.card_upgrades is Dictionary):
		target_run.card_upgrades = {}
	if not target_run.has("campaign_presentation"):
		target_run.campaign_presentation = "tournament_hub"
	if not target_run.has("hub_floor"):
		target_run.hub_floor = "locals"
	if not target_run.has("hub_round"):
		target_run.hub_round = 1
	if not target_run.has("hub_rounds_per_floor"):
		target_run.hub_rounds_per_floor = 4
	if not target_run.has("hub_break_used"):
		target_run.hub_break_used = false
	if not target_run.has("hub_break_choice"):
		target_run.hub_break_choice = ""
	if not target_run.has("hub_shop") or not (target_run.hub_shop is Dictionary):
		target_run.hub_shop = {}
	if not target_run.has("hub_notice"):
		target_run.hub_notice = ""
	target_run.hub_round = clampi(int(target_run.hub_round), 1, maxi(1, int(target_run.hub_rounds_per_floor)))
	if String(target_run.campaign_presentation) == "tournament_hub":
		if not target_run.has("demo_weeks"):
			# Completed legacy demos remain completed; active hub saves gain week two.
			target_run.demo_weeks = 1 if bool(target_run.get("demo_complete", false)) else int(weekly.config.get("weeks", 2))
			target_run.week = 1
		for entry in [["week_transition", ""], ["deckbox", {}], ["deckbox_offer", []], ["deckbox_reward", {}]]:
			if not target_run.has(entry[0]):
				target_run[entry[0]] = entry[1]
		if String(target_run.week_transition) == "deckbox":
			weekly.normalize_deckbox_offers(target_run)
	_normalize_card_upgrades(target_run)
	settle_deckbox_reward(target_run)
	if not target_run.has("max_life"):
		target_run.max_life = STARTING_LIFE
	if not target_run.has("life"):
		target_run.life = int(target_run.max_life)
	target_run.life = clampi(int(target_run.life), 0, int(target_run.max_life))


func _normalize_card_upgrades(target_run: Dictionary) -> void:
	var normalized := {}
	for card_id_value in target_run.get("card_upgrades", {}).keys():
		var card_id := String(card_id_value)
		var deck_count := int(target_run.get("deck", {}).get(card_id, 0))
		if deck_count <= 0 or not cards_by_id.has(card_id) or not card_is_upgradeable(card_id):
			continue
		var upgrade_count := clampi(int(target_run.card_upgrades.get(card_id, 0)), 0, deck_count)
		if upgrade_count > 0:
			normalized[card_id] = upgrade_count
	target_run.card_upgrades = normalized


func compact_starter_deck(source: Dictionary, target_size: int) -> Dictionary:
	var result := source.duplicate(true)
	while deck_total(result) > target_size:
		var candidate := ""
		var candidate_count := 0
		for card_id_value in result.keys():
			var card_id := String(card_id_value)
			var count := int(result[card_id])
			if count > candidate_count:
				candidate = card_id
				candidate_count = count
		if candidate == "":
			break
		result[candidate] = candidate_count - 1
		if int(result[candidate]) <= 0:
			result.erase(candidate)
	return result


func deck_total(deck: Dictionary) -> int:
	var total := 0
	for count in deck.values():
		total += int(count)
	return total


func event_outcome_for_node(route_seed: int, node_id: String) -> String:
	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = route_seed ^ hash("route_event:%s" % node_id)
	return String(EVENT_OUTCOMES[event_rng.randi_range(0, EVENT_OUTCOMES.size() - 1)])


func trade_offer_for_node(
	target_run: Dictionary,
	starter_affinity: String,
	route_seed: int,
	node_id: String
) -> Dictionary:
	var source_ids: Array[String] = []
	for card_id_value in target_run.get("deck", {}).keys():
		var card_id := String(card_id_value)
		if int(target_run.deck.get(card_id, 0)) <= 0 or not cards_by_id.has(card_id):
			continue
		if bool((cards_by_id[card_id] as Dictionary).get("is_token", false)):
			continue
		source_ids.append(card_id)
	if source_ids.is_empty():
		return {}
	source_ids.sort()

	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = route_seed ^ hash("route_trade:%s" % node_id)
	var offered_id := source_ids[event_rng.randi_range(0, source_ids.size() - 1)]
	var offered_card := cards_by_id[offered_id] as Dictionary
	var offered_type := String(offered_card.get("card_type", ""))
	var offered_rarity := String(offered_card.get("rarity", "common"))
	var best_score := -1
	var replacement_ids: Array[String] = []
	for card_value in cards:
		var candidate := card_value as Dictionary
		var candidate_id := String(candidate.get("id", ""))
		if (
			candidate_id.is_empty()
			or candidate_id == offered_id
			or bool(candidate.get("is_token", false))
			or not card_is_starter_eligible(candidate, starter_affinity)
		):
			continue
		# Prefer an unseen, like-for-like card while retaining a fallback if a
		# small test catalog cannot provide an exact type and rarity match.
		var candidate_score := 0
		if int(target_run.get("deck", {}).get(candidate_id, 0)) <= 0:
			candidate_score += 4
		if String(candidate.get("card_type", "")) == offered_type:
			candidate_score += 3
		if String(candidate.get("rarity", "common")) == offered_rarity:
			candidate_score += 1
		if candidate_score > best_score:
			best_score = candidate_score
			replacement_ids = [candidate_id]
		elif candidate_score == best_score:
			replacement_ids.append(candidate_id)
	if replacement_ids.is_empty():
		return {}
	replacement_ids.sort()
	var replacement_id := replacement_ids[event_rng.randi_range(0, replacement_ids.size() - 1)]
	return {
		"trading_card_id": offered_id,
		"getting_card_id": replacement_id,
	}


func card_is_upgradeable(card_id: String) -> bool:
	if not cards_by_id.has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	return (
		card.has("attack")
		or card.has("health")
		or int(card.get("discard_cost", 0)) > 0
	)


func upgradeable_card_ids(target_run: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for card_id_value in target_run.get("deck", {}).keys():
		var card_id := String(card_id_value)
		var deck_count := int(target_run.deck.get(card_id, 0))
		var upgrade_count := int(target_run.get("card_upgrades", {}).get(card_id, 0))
		if card_is_upgradeable(card_id) and upgrade_count < deck_count:
			result.append(card_id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return String(cards_by_id[a].get("name", a)) < String(cards_by_id[b].get("name", b))
	)
	return result


func upgrade_count(target_run: Dictionary, card_id: String) -> int:
	return clampi(
		int(target_run.get("card_upgrades", {}).get(card_id, 0)),
		0,
		int(target_run.get("deck", {}).get(card_id, 0))
	)


func upgrade_summary(card_id: String) -> String:
	if not card_is_upgradeable(card_id):
		return "No upgrade available"
	var card: Dictionary = cards_by_id[card_id]
	var bonuses: Array[String] = []
	if card.has("attack"):
		bonuses.append("+1 Attack")
	if card.has("health"):
		bonuses.append("+1 Health")
	if int(card.get("discard_cost", 0)) > 0:
		bonuses.append("-1 discard cost")
	return " • ".join(bonuses)


func upgraded_card_id(card_id: String) -> String:
	return "%s%s" % [card_id, UPGRADED_CARD_SUFFIX]


func upgraded_card_data(card_id: String) -> Dictionary:
	if not card_is_upgradeable(card_id):
		return {}
	var upgraded: Dictionary = cards_by_id[card_id].duplicate(true)
	upgraded.id = upgraded_card_id(card_id)
	upgraded.upgraded = true
	upgraded.base_card_id = card_id
	if upgraded.has("attack"):
		upgraded.attack = int(upgraded.get("attack", 0)) + 1
	if upgraded.has("health"):
		upgraded.health = int(upgraded.get("health", 0)) + 1
	if int(upgraded.get("discard_cost", 0)) > 0:
		upgraded.discard_cost = maxi(0, int(upgraded.discard_cost) - 1)
		upgraded.cost = maxi(0, int(upgraded.get("cost", upgraded.discard_cost + 1)) - 1)
		upgraded.text = _upgraded_discard_text(card_id, int(upgraded.discard_cost))
	return upgraded


func _upgraded_discard_text(card_id: String, new_cost: int) -> String:
	var original: Dictionary = cards_by_id[card_id]
	var rules := String(original.get("text", ""))
	var old_cost := int(original.get("discard_cost", 0))
	var old_cards := "%d card%s" % [old_cost, "" if old_cost == 1 else "s"]
	var new_cards := "%d card%s" % [new_cost, "" if new_cost == 1 else "s"]
	var tool_prefix := "Discard %s; " % old_cards
	var unit_prefix := "When played, discard %s, then " % old_cards
	if rules.begins_with(tool_prefix):
		var effect := rules.trim_prefix(tool_prefix)
		return "Discard %s; %s" % [new_cards, effect] if new_cost > 0 else effect.left(1).to_upper() + effect.substr(1)
	if rules.begins_with(unit_prefix):
		var effect := rules.trim_prefix(unit_prefix)
		return "When played, discard %s, then %s" % [new_cards, effect] if new_cost > 0 else "When played, %s" % effect
	return rules


func prepare_player_combat_deck(target_run: Dictionary, source_deck: Dictionary) -> Dictionary:
	var runtime_deck := {}
	var custom_cards := {}
	for card_id_value in source_deck.keys():
		var card_id := String(card_id_value)
		var card_count := maxi(0, int(source_deck.get(card_id, 0)))
		var upgraded_count := mini(card_count, upgrade_count(target_run, card_id))
		var normal_count := card_count - upgraded_count
		if normal_count > 0:
			runtime_deck[card_id] = normal_count
		if upgraded_count > 0:
			var runtime_id := upgraded_card_id(card_id)
			runtime_deck[runtime_id] = upgraded_count
			custom_cards[runtime_id] = upgraded_card_data(card_id)
	if not target_run.get("deckbox", {}).is_empty():
		for id_value in runtime_deck.keys():
			var id := String(id_value)
			var data: Dictionary = custom_cards.get(id, cards_by_id.get(id, {})).duplicate(true)
			var boosted := deckbox_card_data(target_run, data)
			if boosted == data:
				continue
			var runtime_id := id + "__deckbox"
			boosted.id = runtime_id
			boosted.base_card_id = String(data.get("base_card_id", id))
			boosted.deckbox_applied = true
			custom_cards[runtime_id] = boosted
			runtime_deck[runtime_id] = runtime_deck[id]
			runtime_deck.erase(id)
	return {"deck": runtime_deck, "cards": custom_cards}


func deckbox_card_data(target_run: Dictionary, source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var kind := String(result.get("card_type", ""))
	if kind in ["ingredient", "meal"]:
		result.attack = int(result.get("attack", 0)) + WEEKLY.bonus(target_run, kind + "_attack")
		result.health = int(result.get("health", 1)) + WEEKLY.bonus(target_run, kind + "_health")
	return result


func remove_card(target_run: Dictionary, card_id: String, minimum_deck_size: int = 1, copy_index: int = -1) -> Dictionary:
	if deck_total(target_run.get("deck", {})) <= minimum_deck_size:
		return {"ok": false, "message": "Your deck is already at its minimum size."}
	if int(target_run.get("deck", {}).get(card_id, 0)) <= 0:
		return {"ok": false, "message": "That card is not in your deck."}
	if copy_index >= int(target_run.deck[card_id]):
		return {"ok": false, "message": "That copy is no longer in your deck."}
	target_run.deck[card_id] = int(target_run.deck[card_id]) - 1
	target_run.collection[card_id] = maxi(0, int(target_run.get("collection", {}).get(card_id, 0)) - 1)
	if int(target_run.deck[card_id]) <= 0:
		target_run.deck.erase(card_id)
	var upgraded_count := int(target_run.get("card_upgrades", {}).get(card_id, 0))
	if copy_index >= 0 and copy_index < upgraded_count:
		upgraded_count -= 1
	var remaining_count := int(target_run.get("deck", {}).get(card_id, 0))
	upgraded_count = mini(upgraded_count, remaining_count)
	if target_run.has("card_upgrades"):
		if upgraded_count > 0:
			target_run.card_upgrades[card_id] = upgraded_count
		else:
			target_run.card_upgrades.erase(card_id)
	return {"ok": true, "message": "Removed %s from your deck." % String(cards_by_id.get(card_id, {}).get("name", card_id))}


func upgrade_card(target_run: Dictionary, card_id: String) -> Dictionary:
	if not card_is_upgradeable(card_id) or int(target_run.get("deck", {}).get(card_id, 0)) <= 0:
		return {"ok": false, "message": "That card cannot be upgraded."}
	if not target_run.has("card_upgrades") or not (target_run.card_upgrades is Dictionary):
		target_run.card_upgrades = {}
	var current_upgrades := upgrade_count(target_run, card_id)
	if current_upgrades >= int(target_run.deck.get(card_id, 0)):
		return {"ok": false, "message": "Every copy of that card is already upgraded."}
	target_run.card_upgrades[card_id] = current_upgrades + 1
	return {
		"ok": true,
		"message": "Upgraded %s: %s." % [String(cards_by_id[card_id].get("name", card_id)), upgrade_summary(card_id)]
	}


func settle_deckbox_reward(target_run: Dictionary) -> Dictionary:
	var reward: Dictionary = target_run.get("deckbox_reward", {})
	var kind := String(reward.get("kind", ""))
	var applied := maxi(0, int(reward.get("applied", 0)))
	var active := String(target_run.get("week_transition", "")) == "deckbox_reward"
	if not active:
		return {"kind": kind, "remaining": 0, "applied": applied, "eligible": 0, "complete": true, "message": ""}
	var maximum := WEEKLY.bonus(target_run, "remove_cards" if kind == "remove" else "upgrade_cards") if kind in ["remove", "upgrade"] else 0
	applied = mini(applied, maximum)
	var remaining := clampi(int(reward.get("remaining", 0)), 0, maximum - applied)
	var eligible := 0
	if kind == "remove":
		eligible = maxi(0, deck_total(target_run.get("deck", {})) - 1)
	elif kind == "upgrade":
		for id_value in target_run.get("deck", {}):
			var id := String(id_value)
			if card_is_upgradeable(id):
				eligible += maxi(0, int(target_run.deck[id]) - upgrade_count(target_run, id))
	remaining = mini(remaining, eligible)
	reward.remaining = remaining
	reward.applied = applied
	target_run.deckbox_reward = reward
	var message := ""
	if remaining == 0:
		target_run.week_transition = "week_intro"
		if eligible == 0:
			message = "Your deck must keep at least 1 card." if kind == "remove" else "There are no more cards to upgrade."
	return {"kind": kind, "remaining": remaining, "applied": applied, "eligible": eligible, "complete": remaining == 0, "message": message}


func claim_deckbox_card_reward(target_run: Dictionary, card_id: String, copy_index: int) -> Dictionary:
	var status := settle_deckbox_reward(target_run)
	if bool(status.complete):
		return {"ok": false, "message": "This deckbox's card reward is already complete."}
	var card_count := int(target_run.get("deck", {}).get(card_id, 0))
	if copy_index < 0 or copy_index >= card_count:
		return {"ok": false, "message": "That copy is no longer in your deck."}
	var result: Dictionary
	if String(status.kind) == "remove":
		result = remove_card(target_run, card_id, 1, copy_index)
	else:
		# Identical normal copies share one choice. Its index is the first copy
		# after the upgraded prefix; refreshing after each choice advances it.
		if copy_index != upgrade_count(target_run, card_id):
			return {"ok": false, "message": "That copy is already upgraded or the card choice has changed."}
		result = upgrade_card(target_run, card_id)
	if not bool(result.get("ok", false)):
		return result
	target_run.deckbox_reward.remaining = int(target_run.deckbox_reward.remaining) - 1
	target_run.deckbox_reward.applied = int(target_run.deckbox_reward.applied) + 1
	var after := settle_deckbox_reward(target_run)
	result.remaining = int(after.remaining)
	result.applied = int(after.applied)
	result.complete = bool(after.complete)
	return result


func use_hub_break_heal(target_run: Dictionary) -> Dictionary:
	if bool(target_run.get("hub_break_used", false)):
		return {"ok": false, "message": "The break machine is already out of order."}
	var missing_life := maxi(0, int(target_run.get("max_life", STARTING_LIFE)) - int(target_run.get("life", 0)))
	if missing_life <= 0:
		return {"ok": false, "message": "Your life is already full. The machine was not used."}
	var healed := mini(HUB_BREAK_HEAL_AMOUNT + WEEKLY.bonus(target_run, "bye_heal"), missing_life)
	target_run.life = int(target_run.get("life", 0)) + healed
	target_run.hub_break_used = true
	target_run.hub_break_choice = "heal"
	target_run.hub_notice = "Recovered %d life. The break machine is now out of order." % healed
	return {"ok": true, "healed": healed, "message": String(target_run.hub_notice)}


func use_hub_break_upgrade(target_run: Dictionary, card_id: String) -> Dictionary:
	if bool(target_run.get("hub_break_used", false)):
		return {"ok": false, "message": "The break machine is already out of order."}
	var result := upgrade_card(target_run, card_id)
	if not bool(result.get("ok", false)):
		return result
	target_run.hub_break_used = true
	target_run.hub_break_choice = "upgrade"
	target_run.hub_notice = "%s The break machine is now out of order." % String(result.get("message", "Card upgraded."))
	result.message = String(target_run.hub_notice)
	return result


func buy_card_removal(target_run: Dictionary, shop_node: Dictionary, card_id: String, minimum_deck_size: int = 1, copy_index: int = -1) -> Dictionary:
	if bool(shop_node.get("remove_purchased", false)):
		return {"ok": false, "message": "This shop's card removal has already been used."}
	if int(target_run.get("money", 0)) < SHOP_REMOVE_COST:
		return {"ok": false, "message": "Not enough money for card removal."}
	var result := remove_card(target_run, card_id, minimum_deck_size, copy_index)
	if not bool(result.get("ok", false)):
		return result
	target_run.money = int(target_run.money) - SHOP_REMOVE_COST
	shop_node.remove_purchased = true
	result.message = "%s Paid $%d." % [String(result.message), SHOP_REMOVE_COST]
	return result


func buy_card_upgrade(target_run: Dictionary, shop_node: Dictionary, card_id: String) -> Dictionary:
	if bool(shop_node.get("upgrade_purchased", false)):
		return {"ok": false, "message": "This shop's card upgrade has already been used."}
	if int(target_run.get("money", 0)) < SHOP_UPGRADE_COST:
		return {"ok": false, "message": "Not enough money for a card upgrade."}
	var result := upgrade_card(target_run, card_id)
	if not bool(result.get("ok", false)):
		return result
	target_run.money = int(target_run.money) - SHOP_UPGRADE_COST
	shop_node.upgrade_purchased = true
	result.message = "%s Paid $%d." % [String(result.message), SHOP_UPGRADE_COST]
	return result


func resolve_event(
	target_run: Dictionary,
	outcome: String,
	card_id: String = "",
	minimum_deck_size: int = 1,
	replacement_card_id: String = ""
) -> Dictionary:
	match outcome:
		"heal":
			var healed := mini(EVENT_HEAL_AMOUNT, maxi(0, int(target_run.max_life) - int(target_run.life)))
			target_run.life = mini(int(target_run.max_life), int(target_run.life) + EVENT_HEAL_AMOUNT)
			return {"ok": true, "message": "Recovered %d life." % healed}
		"max_life", "max_health":
			target_run.max_life = int(target_run.max_life) + EVENT_MAX_LIFE_AMOUNT
			return {"ok": true, "message": "Maximum life increased by %d." % EVENT_MAX_LIFE_AMOUNT}
		"money":
			target_run.money = int(target_run.money) + EVENT_MONEY_AMOUNT
			return {"ok": true, "message": "Found $%d." % EVENT_MONEY_AMOUNT}
		"steal_money", "lose_money":
			var stolen := mini(EVENT_STEAL_AMOUNT, int(target_run.get("money", 0)))
			target_run.money = maxi(0, int(target_run.get("money", 0)) - EVENT_STEAL_AMOUNT)
			return {"ok": true, "message": "$%d was stolen." % stolen}
		"remove_card", "remove":
			if deck_total(target_run.get("deck", {})) <= minimum_deck_size:
				return {"ok": true, "message": "Your deck is already at its minimum size, so nothing was removed."}
			return remove_card(target_run, card_id, minimum_deck_size)
		"upgrade_card", "upgrade":
			if upgradeable_card_ids(target_run).is_empty() and card_id.is_empty():
				return {"ok": true, "message": "No cards could be upgraded, so you left unharmed."}
			var upgrade_result := upgrade_card(target_run, card_id)
			if not bool(upgrade_result.get("ok", false)):
				return upgrade_result
			target_run.life = maxi(0, int(target_run.life) - EVENT_UPGRADE_DAMAGE)
			upgrade_result.message = "%s You took %d damage." % [String(upgrade_result.message), EVENT_UPGRADE_DAMAGE]
			upgrade_result.run_over = int(target_run.life) <= 0
			return upgrade_result
		"trade_card", "trade":
			return trade_card(target_run, card_id, replacement_card_id)
		"decline":
			return {"ok": true, "message": "You declined the risky upgrade."}
		"decline_trade":
			return {"ok": true, "message": "You kept your card and thanked them for the offer."}
		_:
			return {"ok": false, "message": "Unknown route event."}


func trade_card(target_run: Dictionary, offered_card_id: String, replacement_card_id: String) -> Dictionary:
	if offered_card_id.is_empty() or replacement_card_id.is_empty() or offered_card_id == replacement_card_id:
		return {"ok": false, "message": "That trade is not valid."}
	if int(target_run.get("deck", {}).get(offered_card_id, 0)) <= 0:
		return {"ok": false, "message": "The card being traded is no longer in your deck."}
	if not cards_by_id.has(offered_card_id) or not cards_by_id.has(replacement_card_id):
		return {"ok": false, "message": "That trade contains an unknown card."}
	var replacement_card := cards_by_id[replacement_card_id] as Dictionary
	if (
		bool(replacement_card.get("is_token", false))
		or not card_is_starter_eligible(replacement_card, String(target_run.get("starter", "")))
	):
		return {"ok": false, "message": "That card is outside this run's card ecosystem."}

	# A trade preserves deck size, so it is legal even for a one-card test deck.
	# remove_card also keeps collection counts and upgraded-copy bookkeeping valid.
	var removal := remove_card(target_run, offered_card_id, 0)
	if not bool(removal.get("ok", false)):
		return removal
	target_run.deck[replacement_card_id] = int(target_run.deck.get(replacement_card_id, 0)) + 1
	target_run.collection[replacement_card_id] = int(target_run.get("collection", {}).get(replacement_card_id, 0)) + 1
	var offered_name := String((cards_by_id[offered_card_id] as Dictionary).get("name", offered_card_id))
	var replacement_name := String(replacement_card.get("name", replacement_card_id))
	return {
		"ok": true,
		"traded_card_id": offered_card_id,
		"received_card_id": replacement_card_id,
		"message": "Traded %s for %s." % [offered_name, replacement_name],
	}


func encounter_life(node_type: String) -> int:
	match node_type:
		"mini_boss":
			return 18
		"final_boss":
			return 28
		_:
			return 12


func encounter_ai(node_type: String) -> String:
	match node_type:
		"mini_boss":
			return "hard"
		"final_boss":
			return "expert"
		_:
			return "medium"


func reward_pick_count(node_type: String) -> int:
	match node_type:
		"mini_boss":
			return MINIBOSS_REWARD_SIZE
		"final_boss":
			return BOSS_REWARD_SIZE
		_:
			return REGULAR_REWARD_SIZE


func generate_reward_offer(starter_affinity: String, node_type: String, seed_value: int, excluded: Array = [], target_run: Dictionary = {}) -> Array[String]:
	rng.seed = seed_value
	var offer_size := REGULAR_REWARD_SIZE
	if node_type == "mini_boss":
		offer_size = MINIBOSS_REWARD_SIZE
	elif node_type == "final_boss":
		offer_size = BOSS_REWARD_SIZE
	var result: Array[String] = []
	var synergy := FOOD.synergy_rewards_enabled(target_run)
	if synergy:
		result = FOOD.synergy_reward_pair(target_run, cards_by_id, rng, excluded)
	var pool: Array[String] = []
	for card_value in cards:
		var card: Dictionary = card_value
		var card_id := String(card.get("id", ""))
		if card_id == "" or excluded.has(card_id) or not WEEKLY.card_available(card, target_run) or not card_is_starter_eligible(card, starter_affinity):
			continue
		if result.has(card_id) or (synergy and not FOOD.reward_card_eligible(card, target_run, cards_by_id)):
			continue
		var rarity := String(card.get("rarity", "common"))
		var rarity_weight := _rarity_weight(rarity, node_type)
		var affinity_weight := 1
		if _card_has_affinity(card, starter_affinity):
			affinity_weight = 5
		elif String(card.get("archetype", "")) == "neutral":
			affinity_weight = 2
		for unused in range(rarity_weight * affinity_weight):
			pool.append(card_id)
	while result.size() < offer_size and not pool.is_empty():
		var chosen := pool[rng.randi_range(0, pool.size() - 1)]
		if not result.has(chosen):
			result.append(chosen)
		else:
			pool.erase(chosen)
	return result


func _rarity_weight(rarity: String, node_type: String) -> int:
	match node_type:
		"final_boss":
			return {"common": 1, "uncommon": 4, "rare": 7, "mythic": 5}.get(rarity, 1)
		"mini_boss":
			return {"common": 2, "uncommon": 5, "rare": 4, "mythic": 1}.get(rarity, 1)
		_:
			return {"common": 6, "uncommon": 3, "rare": 1, "mythic": 1}.get(rarity, 1)


func _card_has_affinity(card: Dictionary, affinity: String) -> bool:
	if String(card.get("archetype", "")) == affinity:
		return true
	for printed_affinity in card.get("archetypes", []):
		if String(printed_affinity) == affinity:
			return true
	for ingredient_type in card.get("ingredient_types", []):
		if String(ingredient_type) == affinity:
			return true
	return false


func card_is_starter_eligible(card: Dictionary, starter_affinity: String) -> bool:
	if bool(card.get("starter_only", false)) or bool(card.get("is_token", false)):
		return false
	if starter_affinity == "food_prototype":
		return true
	var allowed: Array = STARTER_ALLOWED_AFFINITIES.get(starter_affinity, [starter_affinity])
	var printed_affinities: Array[String] = []
	for affinity_value in card.get("archetypes", []):
		var affinity := String(affinity_value)
		if affinity != "neutral" and not printed_affinities.has(affinity):
			printed_affinities.append(affinity)
	for affinity_value in card.get("ingredient_types", []):
		var affinity := String(affinity_value)
		if affinity != "neutral" and affinity != "any" and not printed_affinities.has(affinity):
			printed_affinities.append(affinity)
	var primary := String(card.get("archetype", "neutral"))
	if primary != "neutral" and not printed_affinities.has(primary):
		printed_affinities.append(primary)
	for affinity in printed_affinities:
		if not allowed.has(affinity):
			return false
	return true
