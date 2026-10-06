extends SceneTree
## Paid rerolls preserve run services, use eligible unique stock and charge once.
const CATALOG := preload("res://scripts/ContentCatalog.gd")
const ECONOMY := preload("res://scripts/ShopEconomyService.gd")
const WEEKLY := preload("res://scripts/WeeklyDemoService.gd")
var catalog = CATALOG.new()
var service = ECONOMY.new()
var random := RandomNumberGenerator.new()
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_expect(catalog.load_all(), "The card catalog did not load.")
	random.seed = 7311
	service.setup(catalog.cards, catalog.cards_by_id, catalog.boosters_by_id, random)
	_test_prices_and_saves()
	_test_rejected_requests()
	_test_stock_and_eligibility()
	_test_small_catalogs()
	if failures.is_empty():
		print("ShopRerollServiceSmokeTest passed (%d checks)." % checks)
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _run_sample(starter: String = "spicy", week: int = 1) -> Dictionary:
	var run := {
		"run_loop": "route", "campaign_presentation": "tournament_hub", "demo_weeks": 2,
		"starter": starter, "week": week, "money": 100, "life": 12, "max_life": 45,
		"deck": {"spicy_hot_honey_bee": 2}, "collection": {"spicy_hot_honey_bee": 2},
		"card_upgrades": {"spicy_hot_honey_bee": 1}, "hub_break_used": true,
		"deckbox": {"id": "big_lunch", "effects": {"max_life": 5}},
		"reward_offer": ["spicy_hot_honey_bee"], "reward_picks_remaining": 1,
		"current_pack": [{"cardId": "spicy_hot_honey_bee", "revealed": false}],
	}
	service.generate_shop_inventory(run, starter)
	return run


func _shop_sample(run: Dictionary) -> Dictionary:
	return {
		"id": "locals_shop", "hub_shop": true, "inventory": run.shop.slice(0, 4),
		"remove_purchased": true, "upgrade_purchased": true, "hub_view": "counter",
	}


func _test_prices_and_saves() -> void:
	var run := _run_sample()
	var shop := _shop_sample(run)
	_expect(run.shop.size() == 8, "Legacy shop generation no longer makes eight cards.")
	_expect(service.shop_reroll_cost(shop) == 5, "An old saved shop did not start at $5.")
	var untouched_run := run.duplicate(true)
	untouched_run.erase("money")
	untouched_run.erase("shop")
	var untouched_shop := shop.duplicate(true)
	untouched_shop.erase("inventory")
	for price in [5, 6, 7]:
		var money_before: int = run.money
		var previous_stock: Array = shop.inventory.duplicate()
		var result: Dictionary = service.reroll_hub_shop(run, shop, "spicy", price)
		_expect(result.ok and result.cost == price and run.money == money_before - price, "The $%d reroll charged incorrectly." % price)
		_expect(service.shop_reroll_cost(shop) == price + 1 and shop.rerolls_used == price - 4, "The reroll price did not rise by $1.")
		_expect(shop.inventory.size() == 4 and run.shop == shop.inventory, "The visible and purchasable rerolled inventory diverged.")
		for id in shop.inventory:
			_expect(not previous_stock.has(id), "A reroll repeated a visible card despite a large fresh pool.")
		var after_run := run.duplicate(true)
		after_run.erase("money")
		after_run.erase("shop")
		var after_shop := shop.duplicate(true)
		after_shop.erase("inventory")
		after_shop.erase("rerolls_used")
		_expect(after_run == untouched_run and after_shop == untouched_shop, "Rerolling changed cards, health, rewards or a shop service flag.")
		var restored: Dictionary = JSON.parse_string(JSON.stringify({"run": run, "shop": shop}))
		_expect(service.shop_reroll_cost(restored.shop) == price + 1 and restored.shop.inventory == shop.inventory, "Saving/reloading lost the reroll count or stock.")
	_expect(run.money == 82, "Three rerolls should cost $18 total.")
	# The surrounding match controller resets the durable round counter.
	shop.rerolls_used = 0
	_expect(service.shop_reroll_cost(shop) == 5, "A reset round counter did not restore the $5 price.")


func _test_rejected_requests() -> void:
	for case in ["poor", "stale", "stale_higher"]:
		var run := _run_sample()
		var shop := _shop_sample(run)
		var expected_price := 5
		if case == "poor":
			run.money = 4
		elif case == "stale":
			shop.rerolls_used = 1
		else:
			expected_price = 6
		var run_before := run.duplicate(true)
		var shop_before := shop.duplicate(true)
		var rng_before := random.state
		var result: Dictionary = service.reroll_hub_shop(run, shop, "spicy", expected_price)
		_expect(not result.ok and run == run_before and shop == shop_before and random.state == rng_before, "A rejected %s request changed state or consumed RNG." % case)
	var run := _run_sample()
	var shop := _shop_sample(run)
	run.money = 5
	_expect(service.reroll_hub_shop(run, shop, "spicy", 5).ok and run.money == 0, "Exactly $5 could not buy the first reroll.")
	var after := run.duplicate(true)
	var after_shop := shop.duplicate(true)
	var rng_after := random.state
	_expect(not service.reroll_hub_shop(run, shop, "spicy", 5).ok and run == after and shop == after_shop and random.state == rng_after, "A duplicate stale request bought another reroll.")
	_expect(service.shop_reroll_cost({"rerolls_used": -2}) == 5, "A malformed negative counter discounted the reroll.")


func _test_stock_and_eligibility() -> void:
	for starter in ["spicy", "sweet", "hearty"]:
		for week in [1, 2]:
			for seed_value in range(12):
				random.seed = seed_value
				var run := _run_sample(starter, week)
				var shop := _shop_sample(run)
				# Full, partly sold and sold-out cases all receive four fresh cards.
				shop.inventory = shop.inventory.slice(0, seed_value % 3 * 2)
				var old: Array = shop.inventory.duplicate()
				_expect(service.reroll_hub_shop(run, shop, starter).ok, "An eligible %s week-%d case could not reroll." % [starter, week])
				var unique := {}
				for id in shop.inventory:
					_expect(catalog.cards_by_id.has(id) and not unique.has(id), "Rerolled stock contained an invalid or duplicate card.")
					unique[id] = true
					var card: Dictionary = catalog.cards_by_id[id]
					_expect(service.card_is_starter_eligible(card, starter) and WEEKLY.card_available(card, run), "A reroll leaked a card outside the starter/week ecosystem.")
					_expect(not old.has(id), "A partial case's previous card was unnecessarily repeated.")
				_expect(shop.inventory.size() == 4 and run.shop == shop.inventory, "A partial/sold-out case was not completely restocked.")


func _test_small_catalogs() -> void:
	var legal_cards: Array = []
	var eligibility_run := _run_sample()
	for card in catalog.cards:
		if service.card_is_starter_eligible(card, "spicy") and WEEKLY.card_available(card, eligibility_run):
			legal_cards.append(card)
		if legal_cards.size() == 5:
			break
	for pool_size in [3, 4, 5]:
		var limited = ECONOMY.new()
		var limited_rng := RandomNumberGenerator.new()
		limited_rng.seed = 483
		var limited_cards: Array = legal_cards.slice(0, pool_size)
		var database := {}
		var old: Array = []
		for card in limited_cards:
			database[String(card.id)] = card
			if old.size() < 4:
				old.append(String(card.id))
		limited.setup(limited_cards, database, {}, limited_rng)
		var run := _run_sample()
		var shop := _shop_sample(run)
		shop.inventory = old
		var before := run.duplicate(true)
		var shop_before := shop.duplicate(true)
		var rng_before := limited_rng.state
		var result: Dictionary = limited.reroll_hub_shop(run, shop, "spicy", 5)
		if pool_size < 4:
			_expect(not result.ok and run == before and shop == shop_before and limited_rng.state == rng_before, "An undersized catalog charged money or changed state/RNG.")
		else:
			var unique := {}
			for id in shop.inventory:
				unique[id] = true
			_expect(result.ok and unique.size() == 4 and not unique.has(""), "A small eligible pool could not supply four distinct cards.")
			if pool_size == 5:
				_expect(shop.inventory.has(String(limited_cards[4].id)), "A small pool failed to prefer its one fresh alternative.")


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
