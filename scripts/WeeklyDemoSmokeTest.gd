extends SceneTree
const WEEKLY := preload("res://scripts/WeeklyDemoService.gd")
const COMBAT := preload("res://scripts/cooking/CookingCombatService.gd")
var checks := 0
var main

func _initialize() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child.call_deferred(main)
	await frames(3)
	main.run_state_service.save_path = "/private/tmp/locals-weekly-demo-smoke.json"
	main.autosave_enabled = true
	main.player_settings.reduced_motion = true
	main._start_new_run_with_mode("spicy", "season", "white")
	await frames(3)
	_expect(int(main.run.demo_weeks) == 2 and int(main.run.week) == 1, "New run is not two weeks")
	var weekly = main.route_run_service.weekly
	_expect(weekly.config.deckboxes.size() == 5, "Expected five deckbox prizes")
	for starter in ["spicy", "hearty", "sweet"]:
		var sample: Dictionary = main.run.duplicate(true)
		sample.starter = starter
		for seed in range(12):
			var reward: Array = main.route_run_service.generate_reward_offer(starter, "final_boss", seed, [], sample)
			for id in reward:
				_expect(WEEKLY.card_available(main.cards_by_id[id], sample), "Week-one reward leaked new mechanics")
			main.shop_economy_service.generate_shop_inventory(sample, starter)
			for id in sample.shop:
				_expect(WEEKLY.card_available(main.cards_by_id[id], sample), "Week-one shop leaked new mechanics")
		sample.week = 2
		var pack: Array = weekly.make_intro_pack(sample, main.cards, main.route_run_service.card_is_starter_eligible)
		var special_count := 0
		var spice_count := 0
		for id in pack:
			var card: Dictionary = main.cards_by_id[id]
			special_count += 1 if card.has("special_serve") else 0
			spice_count += 1 if String(card.card_type) == "spice" else 0
			_expect(main.route_run_service.card_is_starter_eligible(card, starter), "Intro pack broke starter ecosystem")
		_expect(pack.size() == 5 and special_count >= 2 and spice_count >= 1, "Intro pack does not demonstrate both mechanics")
	# Prize effects preserve the normal card-upgrade and rival-card contracts.
	for box in weekly.config.deckboxes:
		var sample: Dictionary = main.run.duplicate(true)
		sample.deckbox = box.duplicate(true)
		sample.deck = {"spicy_hot_honey_bee": 2, "spicy_sriracharrow": 1}
		sample.card_upgrades = {"spicy_hot_honey_bee": 1}
		var prepared: Dictionary = main.route_run_service.prepare_player_combat_deck(sample, sample.deck)
		var combat = COMBAT.new()
		combat.load_content()
		for id in prepared.cards:
			combat.cards_by_id[id] = prepared.cards[id]
		combat.decks.test_player = {"cards": {"spicy_hot_honey_bee": 20}}
		combat.decks.test_rival = {"cards": {"spicy_hot_honey_bee": 20}}
		var state: Dictionary = combat.start_game("test_player", "test_rival", 7, "player", true, "easy", {"deckbox_effects": box.effects})
		_expect(state.player.hand.size() == 5 + int(box.effects.get("opening_hand", 0)) and state.opponent.hand.size() == 5, "Opening-hand bonus affected wrong seat")
		for id in prepared.deck:
			var card: Dictionary = combat.card(id)
			var unit: Dictionary = combat._make_unit(state, state.player, card, "prep", "player")
			var base_id := String(card.get("base_card_id", id))
			var base: Dictionary = main.cards_by_id.get(base_id, main.cards_by_id.spicy_hot_honey_bee)
			var upgrade := 1 if bool(card.get("upgraded", false)) else 0
			_expect(int(unit.attack) == int(base.attack) + upgrade + int(box.effects.get(String(card.card_type) + "_attack", 0)), "Attack bonus missing or applied twice")
			_expect(int(unit.max_health) == int(base.health) + upgrade + int(box.effects.get(String(card.card_type) + "_health", 0)), "Health bonus missing or applied twice")
		var token: Dictionary = combat._make_unit(state, state.player, combat.card("token_fresh_ingredient"), "prep", "player")
		_expect(int(token.attack) == 1 + int(box.effects.get("ingredient_attack", 0)), "Ingredient box omitted tokens")
		sample.life = 1
		sample.hub_break_used = false
		main.route_run_service.use_hub_break_heal(sample)
		_expect(sample.life == 6 + int(box.effects.get("bye_heal", 0)), "Bye bonus is wrong")
		var without: Dictionary = sample.duplicate(true)
		without.deckbox = {}
		var normal_price: int = main.shop_economy_service.card_price(without, "spicy_sriracharrow")
		_expect(main.shop_economy_service.card_price(sample, "spicy_sriracharrow") == maxi(1, normal_price - int(box.effects.get("shop_discount", 0))), "Shop discount is wrong")
	var initial_run: Dictionary = main.run.duplicate(true)
	for box_id in ["padded_picnic", "tip_jar"]:
		for won in [true, false]:
			main.run = initial_run.duplicate(true)
			main.run.deckbox = weekly.deckbox(box_id)
			main.run.pending_route_node = main._hub_round_node(1)
			main.run.route_battle = {"active": true, "node_id": "passive_test", "node_type": "enemy", "seed": 61, "label": "Passive test"}
			var money_before: int = main.run.money
			var remaining_life := 20 if won else 0
			var expected_cash := (2 if won else 0) + (1 if box_id == "tip_jar" else 0)
			main._finish_route_battle(won, remaining_life)
			await frames(5)
			_expect(main.run.life == remaining_life, "Match cash prize changed remaining life")
			_expect(main.run.money == money_before + expected_cash, "Match cash did not apply for %s (%s)" % [box_id, "win" if won else "loss"])
			main._finish_route_battle(won, remaining_life)
			_expect(main.run.money == money_before + expected_cash, "Repeated match result paid the box again")
	main.run = initial_run
	main._show_tournament_hub()
	await frames(3)
	var health_sample: Dictionary = initial_run.duplicate(true)
	health_sample.life = 20
	health_sample.week_transition = "deckbox"
	health_sample.deckbox_offer = ["big_lunch", "tip_jar", "padded_picnic"]
	_expect(weekly.choose_deckbox(health_sample, "big_lunch") and health_sample.life == 25 and health_sample.max_life == 45, "Health deckbox did not raise and heal life once")
	_expect(not weekly.choose_deckbox(health_sample, "big_lunch") and health_sample.max_life == 45, "Health deckbox equipped twice")
	await _check_partial_weekly_recovery(initial_run)
	# Play through both weekly tournament transitions using production reward callbacks.
	for week in range(1, 3):
		for round_number in range(1, 5):
			_expect(main.run.week == week and main.run.hub_round == round_number, "Wrong weekly round")
			var node: Dictionary = main._hub_round_node(round_number)
			main.run.pending_route_node = node
			main.run.route_battle = {"active": true, "node_id": node.id, "node_type": node.type, "seed": 100 + week * 4 + round_number, "label": "Test Rival"}
			main._finish_route_battle(true, 30)
			await frames(5)
			var money: int = main.run.money
			main._finish_route_battle(true, 1)
			_expect(main.run.money == money and main.run.life == 30, "Duplicate win changed state")
			main._finish_route_reward()
			await frames(3)
		if week == 1:
			_expect(not main.run.run_over and main.current_screen == "week_transition", "First championship ended the demo")
			var offered: Array = main.run.deckbox_offer.duplicate()
			_expect(offered.size() == 3, "Deckbox choice missing")
			for id in offered:
				_expect(not weekly.deckbox(String(id)).is_empty(), "Generated deckbox offer contains a retired prize")
			# Copy-choice prizes have focused coverage; keep this complete weekly
			# flow deterministic by equipping Big Lunch through its real buttons.
			offered = ["big_lunch", "tip_jar", "padded_picnic"]
			main.run.deckbox_offer = offered.duplicate()
			main._show_week_transition()
			await frames(3)
			await capture("deckbox_choices")
			main._save_run()
			main._load_run_from_disk()
			await frames(3)
			_expect(main.run.deckbox_offer == offered and main.current_screen == "week_transition", "Reload rerolled or skipped deckboxes")
			# Exercise real Select and Keep buttons.
			(main.find_child("DeckboxChoice_" + String(offered[0]), true, false) as Button).pressed.emit()
			(main.find_child("WeeklyDemoContinue", true, false) as Button).pressed.emit()
			await frames(3)
			_expect(main.run.week_transition == "week_intro", "Deckbox UI failed to equip")
			var selected: Dictionary = main.run.deckbox.duplicate(true)
			var max_life: int = main.run.max_life
			main._choose_demo_deckbox(String(offered[0]))
			_expect(main.run.max_life == max_life, "Duplicate equip stacked health")
			await capture("week_two_intro")
			main._save_run()
			main._load_run_from_disk()
			await frames(3)
			_expect(main.run.deckbox == selected and main.run.week_transition == "week_intro", "Selected box did not survive reload")
			_expect(main.run.life == 35 and main.run.max_life == 45, "Week introduction healed before the player started the week")
			var recovery_rules := main.find_child("WeeklyRecoveryRules", true, false) as Label
			_expect(recovery_rules != null and recovery_rules.text.contains("Start the week at full life"), "Black border intro did not explain full weekly recovery")
			main.run.hub_break_used = true
			main.run.hub_shop.upgrade_purchased = true
			(main.find_child("WeeklyDemoContinue", true, false) as Button).pressed.emit()
			await frames(3)
			_expect(main.run.week == 2 and main.run.hub_round == 1 and not main.run.hub_break_used, "Week two failed to reset round/bye")
			_expect(main.run.life == 45 and main.run.max_life == 45, "Black border did not fully heal to Big Lunch's maximum on week advancement")
			_expect(not main.run.hub_shop.get("upgrade_purchased", false), "Week two kept used services")
			_expect(main.run.reward_offer.size() == 5 and main.run.pending_route_node.type == "week_pack", "Intro pack not opened")
			await capture("second_helpings_pack")
			var offer: Array = main.run.reward_offer.duplicate()
			main._crack_route_victory_pack()
			await frames(3)
			await capture("second_helpings_cards")
			var card_id := String(offer[0])
			# Persist a partially collected pack without triggering a collect animation.
			main.run.deck[card_id] = int(main.run.deck.get(card_id, 0)) + 1
			main.run.collection[card_id] = int(main.run.collection.get(card_id, 0)) + 1
			main.run.reward_offer.erase(card_id)
			main.run.reward_picks_remaining -= 1
			main._save_run()
			main._load_run_from_disk()
			await frames(3)
			_expect(main.run.reward_offer.size() == 4 and not main.run.reward_offer.has(card_id), "Reload duplicated an intro-pack card")
			_expect(main.run.life == 45, "Partial-pack reload changed weekly healing")
			main._add_all_route_rewards()
			await frames(3)
			_expect(main.current_screen == "route_hub" and main.run.week_transition == "", "Pack completion did not return to week-two hub")
			await capture("week_two_hub")
			# Verify a continuing combat effect separately from the pickup prize.
			main.run.deckbox = weekly.deckbox("padded_picnic")
			var equipped_box: Dictionary = main.run.deckbox.duplicate(true)
			main._start_next_hub_round()
			await frames(3)
			main._begin_route_battle_from_intro()
			await frames(3)
			var table = main.find_child("Tabletop3DPrototype", true, false)
			_expect(table != null and table.state.run_rules.special_serve_enabled, "Week-two battle did not enable Special Serve")
			_expect(table.state.player.deckbox_effects.get("reshuffle_damage_reduction", 0) == 2, "Deckbox was not passed to the production battle")
			_expect(table.configured_match_context.get("deckbox", {}) == equipped_box, "Battle presentation lost the equipped deckbox's saved identity")
			_expect(main.run.kitchen_match.match_context.get("deckbox", {}) == equipped_box, "Battle checkpoint omitted the equipped deckbox presentation")
			for id in table.state.player.hand:
				_expect(not table.service.card(id).is_empty(), "Production hand contains an unknown deckbox variant")
			var original_hand: Array = table.state.player.hand.duplicate()
			main._save_run()
			main._load_run_from_disk()
			await frames(4)
			table = main.find_child("Tabletop3DPrototype", true, false)
			_expect(table != null and table.state.player.hand == original_hand, "Battle resume redrew or lost the deckbox hand")
			_expect(table.state.player.deckbox_effects.get("reshuffle_damage_reduction", 0) == 2, "Battle resume lost deckbox effects")
			_expect(table.configured_match_context.get("deckbox", {}) == equipped_box and main.run.deckbox == equipped_box, "Battle resume rewrote or lost the equipped deckbox snapshot")
			main.run.route_battle = {}
			main.run.pending_route_node = {}
			main._clear_kitchen_match_state()
			main._show_tournament_hub()
			await frames(3)
	_expect(main.run.demo_complete and main.run.run_over and main.current_screen == "route_victory", "Second championship did not finish the demo")
	_expect(main.run.route_round_results.size() == 8, "Final recap lost a week's matches")
	await capture("demo_complete")
	main._save_run()
	main._load_run_from_disk()
	await frames(3)
	_expect(main.current_screen == "route_victory", "Completed demo failed to resume")
	print("Weekly demo smoke test passed: %d checks." % checks)
	main.queue_free()
	await frames(2)
	quit(0)

func _check_partial_weekly_recovery(initial_run: Dictionary) -> void:
	# A low-life Gold save distinguishes +20 from an accidental full refill.
	main.run = initial_run.duplicate(true)
	main.run.difficulty = "gold"
	main.run.deckbox = main.route_run_service.weekly.deckbox("big_lunch")
	main.run.life = 7
	main.run.max_life = 45
	main.run.week_transition = "week_intro"
	main._show_week_transition()
	await frames(3)
	var recovery_rules := main.find_child("WeeklyRecoveryRules", true, false) as Label
	_expect(recovery_rules != null and recovery_rules.text.contains("Heal 20 life") and recovery_rules.text.contains("up to your maximum"), "Gold border intro did not explain capped weekly recovery")
	main._save_run()
	main._load_run_from_disk()
	await frames(3)
	_expect(main.run.life == 7 and main.run.week == 1, "Loading the introduction healed before week advancement")
	(main.find_child("WeeklyDemoContinue", true, false) as Button).pressed.emit()
	await frames(3)
	_expect(main.run.life == 27 and main.run.max_life == 45 and main.run.week == 2, "Gold Continue did not heal exactly 20 life")
	var offer: Array = main.run.reward_offer.duplicate()
	main._start_demo_week_two()
	_expect(main.run.life == 27 and main.run.reward_offer == offer, "Repeated Continue reapplied healing or rerolled the pack")
	main._save_run()
	main._load_run_from_disk()
	await frames(3)
	_expect(main.run.life == 27 and main.run.week == 2 and main.run.reward_offer == offer, "Pack reload healed again or lost the weekly recovery")
	main.run = initial_run.duplicate(true)
	main._show_tournament_hub()
	await frames(3)

func frames(count: int) -> void:
	for unused in range(count):
		await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(2.6).timeout
	await frames(8)
	var directory := "res://outputs/weekly_demo_2026-09-10"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.get_texture().get_image().save_png(directory + "/" + label + ".png")

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
