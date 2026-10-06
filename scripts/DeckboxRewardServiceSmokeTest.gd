extends SceneTree
## Deckbox claims survive saves, act on distinct card copies and cannot repeat.
const CATALOG := preload("res://scripts/ContentCatalog.gd")
const ROUTE := preload("res://scripts/RouteRunService.gd")
var checks := 0
var failures: Array[String] = []
var service = ROUTE.new()
var card_id := "spicy_hot_honey_bee"
var other_id := "spicy_sriracharrow"


func _initialize() -> void:
	var catalog = CATALOG.new()
	_expect(catalog.load_all(), "Content did not load.")
	service.setup(catalog.cards, catalog.cards_by_id)
	_test_offers()
	_test_health()
	_test_removal()
	_test_upgrades()
	_test_exhausted_choices()
	_test_legacy_snapshot()
	_test_week_health_recovery()
	if failures.is_empty():
		print("DeckboxRewardServiceSmokeTest passed (%d checks)." % checks)
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _sample(deck: Dictionary = {}) -> Dictionary:
	var run := {"starter": "spicy", "deck": {card_id: 3, other_id: 2}, "money": 7}
	service.initialize_run(run, 9031)
	if not deck.is_empty():
		run.deck = deck.duplicate(true)
		run.collection = deck.duplicate(true)
	run.life = 20
	return run


func _choose(run: Dictionary, id: String) -> void:
	run.deckbox_offer = [id]
	run.week_transition = "deckbox"
	_expect(service.weekly.choose_deckbox(run, id), "Could not choose %s." % id)


func _reload(run: Dictionary) -> Dictionary:
	var loaded: Dictionary = JSON.parse_string(JSON.stringify(run))
	service.normalize_run(loaded)
	return loaded


func _test_offers() -> void:
	var expected := {
		"tip_jar": {"match_money": 1}, "big_lunch": {"max_life": 5},
		"loyal_regular": {"remove_cards": 3}, "chefs_edge": {"upgrade_cards": 2},
		"padded_picnic": {"reshuffle_damage_reduction": 2},
	}
	_expect(service.weekly.config.deckboxes.size() == 5, "The pool must contain exactly five deckboxes.")
	for id in expected:
		var effects: Dictionary = service.weekly.deckbox(id).effects
		var key: String = expected[id].keys()[0]
		_expect(effects.size() == 1 and int(effects.get(key, 0)) == int(expected[id][key]), "Wrong deckbox effect: %s." % id)
	var seen := {}
	for seed_value in range(30):
		var run := _sample()
		run.route_seed = seed_value
		service.weekly.prepare_deckbox_choice(run)
		var repeat := _sample()
		repeat.route_seed = seed_value
		service.weekly.prepare_deckbox_choice(repeat)
		_expect(run.deckbox_offer == repeat.deckbox_offer, "Seeded deckbox offers changed.")
		_expect(run.deckbox_offer.size() == 3, "A prize did not have three choices.")
		var unique := {}
		for id in run.deckbox_offer:
			_expect(expected.has(id) and not unique.has(id), "A prize contained an obsolete or duplicate box.")
			unique[id] = true
			seen[id] = true
		_expect(_reload(run).deckbox_offer == run.deckbox_offer, "Reload changed a current offer.")
	_expect(seen.size() == 5, "The seeded offer pool omitted a deckbox.")
	var old := _sample()
	old.week_transition = "deckbox"
	old.deckbox_offer = ["pepper_punch", "big_lunch", "big_lunch"]
	var migrated := _reload(old)
	_expect(migrated.deckbox_offer.size() == 3 and migrated.deckbox_offer[0] == "big_lunch", "Old offers did not retain valid choices and fill to three.")
	_expect(migrated.deckbox_offer == _reload(old).deckbox_offer and migrated.deckbox_offer == _reload(migrated).deckbox_offer, "Offer migration rerolled on reload.")
	var before := migrated.duplicate(true)
	_expect(not service.weekly.choose_deckbox(migrated, "pepper_punch") and migrated == before, "An obsolete box could still be chosen.")


func _test_health() -> void:
	for life in [20, 40]:
		var run := _sample()
		run.life = life
		_choose(run, "big_lunch")
		_expect(run.life == life + 5 and run.max_life == 45, "Big Lunch did not add and heal five life.")
		var reloaded := _reload(run)
		_expect(not service.weekly.choose_deckbox(reloaded, "big_lunch"), "Big Lunch was claimed twice.")
		_expect(reloaded.life == life + 5 and reloaded.max_life == 45, "Reload repeated Big Lunch's healing.")


func _test_removal() -> void:
	var run := _sample()
	run.card_upgrades = {card_id: 1}
	_choose(run, "loyal_regular")
	_expect(run.week_transition == "deckbox_reward" and run.deckbox_reward.remaining == 3, "Removal choice did not pause the week transition.")
	_expect(not service.weekly.start_next_week(run), "An unclaimed removal reward could skip to week two.")
	var original := run.duplicate(true)
	_expect(not service.claim_deckbox_card_reward(run, card_id, 99).ok and run == original, "An invalid copy changed the reward.")
	_expect(service.claim_deckbox_card_reward(run, card_id, 1).ok, "A normal copy could not be removed.")
	_expect(service.upgrade_count(run, card_id) == 1 and run.deck[card_id] == 2, "Removing a normal copy erased an upgraded copy.")
	run = _reload(run)
	_expect(run.deckbox_reward.remaining == 2 and run.deckbox_reward.applied == 1 and run.week_transition == "deckbox_reward", "Partial removal progress did not survive reload.")
	_expect(service.claim_deckbox_card_reward(run, card_id, 0).ok, "An upgraded copy could not be removed.")
	_expect(service.upgrade_count(run, card_id) == 0, "Removing an upgraded copy retained its upgrade.")
	_expect(service.claim_deckbox_card_reward(run, other_id, 0).ok, "The third removal failed.")
	_expect(service.deck_total(run.deck) == 2 and run.deck == run.collection, "Three removals did not update deck and collection together.")
	_expect(run.week_transition == "week_intro" and run.deckbox_reward.remaining == 0 and run.deckbox_reward.applied == 3, "Removal completion was not durable.")
	var complete := run.duplicate(true)
	_expect(not service.claim_deckbox_card_reward(run, card_id, 0).ok and run == complete, "A completed reward removed a fourth card.")
	_expect(run.money == 7 and not run.hub_break_used, "Free removals charged money or used the bye.")
	_expect(service.weekly.start_next_week(run), "Completed removal did not unlock week two.")
	_expect(_reload(run).deckbox_reward.applied == 3, "Week two forgot the actual removal count.")


func _test_upgrades() -> void:
	var run := _sample()
	run.card_upgrades = {card_id: 1}
	_choose(run, "chefs_edge")
	var original := run.duplicate(true)
	_expect(not service.claim_deckbox_card_reward(run, card_id, 0).ok and run == original, "An upgraded copy was upgraded again.")
	_expect(service.claim_deckbox_card_reward(run, card_id, 1).ok, "The first upgrade failed.")
	var once := run.duplicate(true)
	_expect(not service.claim_deckbox_card_reward(run, card_id, 1).ok and run == once, "A repeated stale upgrade click granted another upgrade.")
	run = _reload(run)
	_expect(run.deckbox_reward.remaining == 1 and run.deckbox_reward.applied == 1 and service.upgrade_count(run, card_id) == 2, "Partial upgrade progress did not survive reload.")
	_expect(service.claim_deckbox_card_reward(run, card_id, 2).ok, "A second distinct copy of the same card could not be upgraded.")
	_expect(service.upgrade_count(run, card_id) == 3 and run.deckbox_reward.applied == 2 and run.week_transition == "week_intro", "Upgrade completion recorded the wrong copies or count.")
	var complete := run.duplicate(true)
	_expect(not service.claim_deckbox_card_reward(run, other_id, 0).ok and run == complete, "A completed reward granted a third upgrade.")
	_expect(run.money == 7 and not run.hub_break_used and service.deck_total(run.deck) == 5, "Free upgrades changed money, the bye or deck size.")


func _test_exhausted_choices() -> void:
	for count in [1, 2]:
		var run := _sample({card_id: count})
		_choose(run, "loyal_regular")
		service.settle_deckbox_reward(run)
		if count > 1:
			_expect(service.claim_deckbox_card_reward(run, card_id, 0).ok, "A small deck could not take its available removal.")
		_expect(run.deck[card_id] == 1 and run.week_transition == "week_intro" and run.deckbox_reward.applied == count - 1, "A small deck was emptied or stuck in removals.")
	for already_upgraded in [0, 1]:
		var run := _sample({card_id: 1})
		run.card_upgrades = {card_id: already_upgraded}
		_choose(run, "chefs_edge")
		run = _reload(run)
		if already_upgraded == 0:
			_expect(service.claim_deckbox_card_reward(run, card_id, 0).ok, "A single eligible copy could not be upgraded.")
		_expect(run.week_transition == "week_intro" and run.deckbox_reward.applied == 1 - already_upgraded, "An exhausted upgrade reward became stuck or overstated its effect.")


func _test_legacy_snapshot() -> void:
	var run := _sample()
	run.deckbox = {"id": "loyal_regular", "name": "Loyal Regular Box", "description": "Old saved effect.", "effects": {"shop_discount": 1}}
	run.week_transition = "week_intro"
	run.deckbox_offer = ["pepper_punch", "loyal_regular", "thermos"]
	var saved_snapshot: Dictionary = JSON.parse_string(JSON.stringify(run.deckbox))
	var loaded := _reload(run)
	_expect(loaded.deckbox == saved_snapshot and loaded.deckbox_reward.is_empty(), "Reload rewrote an equipped prototype or granted a new reward.")
	_expect(service.weekly.bonus(loaded, "shop_discount") == 1 and service.weekly.bonus(loaded, "remove_cards") == 0, "A saved deckbox inherited its replacement effect.")


func _test_week_health_recovery() -> void:
	for difficulty in ["white", "blue", "yellow", "silver", "gold"]:
		var full_heal: bool = difficulty in ["white", "blue"]
		for maximum in [40, 45]:
			for life in [1, 19, maximum - 3, maximum]:
				var run := _sample()
				run.difficulty = difficulty
				_choose(run, "big_lunch" if maximum == 45 else "tip_jar")
				_expect(run.max_life == maximum, "Weekly recovery fixture did not keep Big Lunch's increased maximum.")
				run.life = life
				var before := run.duplicate(true)
				var rule: Dictionary = service.weekly.week_health_recovery(run)
				_expect(rule.full_heal == full_heal and rule.amount == 20 and run == before, "The weekly recovery description is wrong or heals while inspected.")
				run = _reload(run)
				_expect(run.life == life and run.week == 1, "Loading the week introduction healed before continuing.")
				var expected_life: int = maximum if full_heal else mini(maximum, life + 20)
				_expect(service.weekly.start_next_week(run), "A valid week transition could not apply its recovery.")
				_expect(run.life == expected_life and run.max_life == maximum and run.week == 2 and run.week_transition == "new_pack", "Wrong recovery for %s at %d/%d life." % [difficulty, life, maximum])
				var completed := run.duplicate(true)
				_expect(not service.weekly.start_next_week(run) and run == completed, "A duplicate transition repeated weekly recovery.")
				run = _reload(run)
				_expect(run.life == expected_life and run.week == 2, "Loading the new-pack state repeated or lost weekly recovery.")
				# A later ordinary-round save keeps subsequent damage. Neither a
				# normalization nor a stray transition call may restore it again.
				run.life = expected_life - 5
				run.week_transition = ""
				run.hub_round = 2
				run = _reload(run)
				_expect(not service.weekly.start_next_week(run) and run.life == expected_life - 5 and run.hub_round == 2, "An ordinary round or reload triggered another weekly heal.")
		# Prize selection and partially claimed card rewards still precede the
		# heal, including across save/resume before the last confirmation.
		for box_id in ["loyal_regular", "chefs_edge"]:
			var run := _sample()
			run.difficulty = difficulty
			run.life = 1
			service.weekly.prepare_deckbox_choice(run)
			_expect(not service.weekly.start_next_week(run) and run.life == 1, "The deckbox selection screen healed early.")
			_choose(run, box_id)
			_expect(service.claim_deckbox_card_reward(run, card_id, 0).ok, "Could not prepare a partial card reward for weekly recovery.")
			run = _reload(run)
			_expect(not service.weekly.start_next_week(run) and run.life == 1 and run.week == 1, "A partial deckbox reward or its reload healed early.")
	_expect(service.weekly.week_health_recovery({}).full_heal, "An old save without difficulty did not use the Black-border default.")


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
