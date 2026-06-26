extends RefCounted
class_name ShopEconomyService

var cards: Array = []
var cards_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var rng: RandomNumberGenerator


func setup(card_list: Array, card_database: Dictionary, booster_database: Dictionary, rng_source: RandomNumberGenerator) -> void:
	cards = card_list
	cards_by_id = card_database
	boosters_by_id = booster_database
	rng = rng_source


func buy_and_open_pack(target_run: Dictionary, booster_id: String, current_primary: String) -> Dictionary:
	var booster: Dictionary = boosters_by_id[booster_id]
	if int(target_run.get("money", 0)) < int(booster.get("price", 0)):
		return { "ok": false, "message": "Not enough money for a booster." }
	target_run.money = int(target_run.money) - int(booster.price)
	start_pack(target_run, generate_pack(booster_id, current_primary))
	return { "ok": true, "message": "You bought a %s. Time to sweat the rare slot." % booster.get("name", "booster") }


func open_prize_pack(target_run: Dictionary, booster_id: String, current_primary: String) -> Dictionary:
	if int(target_run.get("prize_packs", 0)) <= 0:
		return { "ok": false, "message": "No prize packs waiting." }
	target_run.prize_packs = int(target_run.prize_packs) - 1
	start_pack(target_run, generate_pack(booster_id, current_primary))
	return { "ok": true, "message": "Prize pack opened. Free cardboard always feels a little better." }


func start_pack(target_run: Dictionary, pack: Array) -> void:
	for index in range(pack.size()):
		var entry: Dictionary = pack[index]
		entry.revealed = false
		pack[index] = entry
	target_run.current_pack = pack
	target_run.revealed_pack = []
	target_run.pack_index = 0
	target_run.pack_opened = false


func generate_pack(booster_id: String, current_primary: String) -> Array:
	var booster: Dictionary = boosters_by_id[booster_id]
	var pack: Array = []

	for slot in booster.get("slots", []):
		var count := int(slot.get("count", 1))
		for i in range(count):
			var rarity := ""
			if slot.has("slotType") and slot.slotType == "wildcard":
				var roll := rng.randf()
				if roll < float(slot.get("mythicChance", 0.0)):
					rarity = "mythic"
				elif roll < float(slot.get("mythicChance", 0.0)) + float(slot.get("rareChance", 0.0)):
					rarity = "rare"
				elif roll < float(slot.get("mythicChance", 0.0)) + float(slot.get("rareChance", 0.0)) + float(slot.get("uncommonChance", 0.0)):
					rarity = "uncommon"
				else:
					rarity = "common"
			else:
				rarity = slot.get("rarity", "common")
				if slot.has("upgradeChance") and rng.randf() < float(slot.upgradeChance):
					rarity = slot.get("upgradeRarity", rarity)

			pack.append({ "cardId": pick_card_by_rarity(rarity, current_primary), "rarity": rarity })

	pack.shuffle()
	pack.sort_custom(func(a, b) -> bool: return rarity_rank(a.rarity) < rarity_rank(b.rarity))
	return pack


func pick_card_by_rarity(rarity: String, current_primary: String) -> String:
	var pool := []
	for card in cards:
		if card.get("rarity", "") == rarity:
			pool.append(card.id)

	if pool.is_empty():
		return cards[0].id

	var weighted := []
	for card_id in pool:
		var card: Dictionary = cards_by_id[card_id]
		var weight := 2 if card.get("archetype", "") == current_primary or card.get("archetype", "") == "neutral" else 1
		for i in range(weight):
			weighted.append(card_id)

	return weighted[rng.randi_range(0, weighted.size() - 1)]


func rarity_rank(rarity: String) -> int:
	match rarity:
		"common":
			return 0
		"uncommon":
			return 1
		"rare":
			return 2
		"mythic":
			return 3
		_:
			return 0


func reveal_next_card(target_run: Dictionary, current_primary: String) -> Dictionary:
	for index in range(target_run.current_pack.size()):
		var entry: Dictionary = target_run.current_pack[index]
		if not bool(entry.get("revealed", false)):
			return reveal_pack_card(target_run, index, current_primary)
	return { "ok": false, "message": "Pack complete." }


func reveal_all_cards(target_run: Dictionary, current_primary: String) -> void:
	for index in range(target_run.current_pack.size()):
		var entry: Dictionary = target_run.current_pack[index]
		if not bool(entry.get("revealed", false)):
			reveal_pack_card(target_run, index, current_primary)


func reveal_pack_card(target_run: Dictionary, pack_index: int, current_primary: String) -> Dictionary:
	if pack_index < 0 or pack_index >= target_run.get("current_pack", []).size():
		return { "ok": false, "message": "That pack slot is empty." }

	var entry: Dictionary = target_run.current_pack[pack_index]
	if bool(entry.get("revealed", false)):
		return { "ok": false, "message": "That card is already revealed." }

	target_run.pack_opened = true
	var card_id: String = String(entry.get("cardId", ""))
	var owned_before := _owned_count(target_run, card_id)
	_add_to_collection(target_run, card_id, 1)

	var note := _pack_reveal_note(target_run, card_id, owned_before, current_primary)
	entry.revealed = true
	target_run.current_pack[pack_index] = entry
	target_run.revealed_pack.append({
		"cardId": card_id,
		"note": note,
		"packIndex": pack_index,
		"rarity": String(entry.get("rarity", "common"))
	})
	target_run.pack_index = target_run.revealed_pack.size()
	return { "ok": true, "message": "Revealed %s." % _card_name(card_id) }


func card_matches_current_deck(card_id: String, current_primary: String) -> bool:
	var card: Dictionary = cards_by_id[card_id]
	return card.get("archetype", "") == current_primary or card.get("archetype", "") == "neutral"


func buy_single(target_run: Dictionary, card_id: String) -> Dictionary:
	var price := card_price(target_run, card_id)
	if int(target_run.get("money", 0)) < price:
		return { "ok": false, "message": "Not enough money for " + _card_name(card_id) + "." }
	target_run.money = int(target_run.money) - price
	_add_to_collection(target_run, card_id, 1)
	return { "ok": true, "message": "Bought %s for $%d." % [_card_name(card_id), price] }


func generate_shop_inventory(target_run: Dictionary, current_primary: String) -> void:
	if target_run.is_empty():
		return

	var shop := []
	var rarity_budget := ["common", "common", "uncommon", "uncommon", "rare"]

	for rarity in rarity_budget:
		shop.append(pick_shop_card(rarity, current_primary, shop))

	while shop.size() < 8:
		var rarity := "common"
		var roll := rng.randf()
		if roll > 0.9:
			rarity = "rare"
		elif roll > 0.55:
			rarity = "uncommon"
		shop.append(pick_shop_card(rarity, current_primary, shop))

	target_run.shop = shop


func pick_shop_card(rarity: String, current_primary: String, excluded: Array) -> String:
	var pool := []
	for card in cards:
		if card.rarity != rarity:
			continue
		if excluded.has(card.id):
			continue
		var weight := 1
		if card.archetype == current_primary:
			weight += 2
		if card.archetype == "neutral":
			weight += 1
		for i in range(weight):
			pool.append(card.id)

	if pool.is_empty():
		for card in cards:
			if not excluded.has(card.id):
				pool.append(card.id)

	return pool[rng.randi_range(0, pool.size() - 1)]


func card_price(target_run: Dictionary, card_id: String) -> int:
	var card: Dictionary = cards_by_id[card_id]
	var base := int(card.get("value", 1))
	var demand := 1.0
	if card.get("archetype", "") != "neutral" and target_run.has("meta"):
		demand += float(target_run.meta.get(card.archetype, 0.0)) * 0.35
	if card.get("rarity", "") == "mythic":
		demand += 0.2
	return max(1, int(ceil(float(base) * demand)))


func _pack_reveal_note(target_run: Dictionary, card_id: String, owned_before: int, current_primary: String) -> String:
	var note := ""
	if owned_before == 0:
		note = "NEW"
	elif owned_before < deck_limit(card_id):
		note = "Useful copy"
	else:
		note = "Duplicate"

	if card_matches_current_deck(card_id, current_primary):
		note += " | Fits deck"

	return note


func deck_limit(card_id: String) -> int:
	return int(cards_by_id[card_id].get("deckLimit", 3))


func _owned_count(target_run: Dictionary, card_id: String) -> int:
	return int(target_run.get("collection", {}).get(card_id, 0))


func _add_to_collection(target_run: Dictionary, card_id: String, count: int) -> void:
	target_run.collection[card_id] = _owned_count(target_run, card_id) + count


func _card_name(card_id: String) -> String:
	if not cards_by_id.has(card_id):
		return card_id
	return String(cards_by_id[card_id].get("name", card_id))
