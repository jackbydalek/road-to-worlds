extends SceneTree

## Exercise actual production card effects and independently account for every
## sleeve entering/leaving a hand. Final count reconciliation must not conceal a
## missing withdrawal, a token mistaken for a held card, or a wrong pile source.
const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")
const FILLER := "spicy_hot_honey_bee"
var service = SERVICE.new()
var failures: Array[String] = []
var cases := 0


func _init() -> void:
	_check(service.load_content(), "Card content failed to load.")
	_test_tokens_and_discard_costs()
	_test_non_hand_deployments()
	_test_shuffle_and_forced_play()
	_test_board_returns()
	if failures.is_empty():
		print("HAND_PRESENTATION_EVENTS_SMOKE_TEST_OK (%d production cases)" % cases)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _fresh(opponent_hand: Array) -> Dictionary:
	var state: Dictionary = service.start_game("", "", 991, "player", true)
	for side in ["player", "opponent"]:
		state[side].hand = [FILLER, FILLER, FILLER]
		state[side].deck = [FILLER, FILLER, FILLER, FILLER, FILLER, FILLER]
		state[side].discard = []
		state[side].prep = []
		state[side].plated = []
		state[side].chef_used = false
	state.opponent.hand = opponent_hand.duplicate()
	service.clear_animation_events(state)
	return state


func _counts(state: Dictionary) -> Dictionary:
	return {"player": state.player.hand.size(), "opponent": state.opponent.hand.size()}


func _account(label: String, before: Dictionary, state: Dictionary) -> Array[Dictionary]:
	var presented := before.duplicate()
	var events: Array[Dictionary] = service.take_animation_events(state)
	for event in events:
		var side := String(event.get("side", ""))
		if not presented.has(side):
			continue
		var event_type := String(event.get("type", ""))
		var source := String(event.get("from", ""))
		var destination := String(event.get("to", ""))
		if event_type == "play" and source == "hand":
			presented[side] -= 1
		elif event_type == "discard" and source == "hand":
			presented[side] -= 1
		elif event_type in ["draw", "search"]:
			if source == "hand":
				presented[side] -= 1
			if destination == "hand":
				presented[side] += 1
		_check(int(presented[side]) >= 0, label + ": events remove a sleeve that does not exist.")
	for side in ["player", "opponent"]:
		_check(int(presented[side]) == state[side].hand.size(), "%s: %s presentation ends at %d cards but actual hand has %d." % [label, side, presented[side], state[side].hand.size()])
	cases += 1
	return events


func _test_tokens_and_discard_costs() -> void:
	var state := _fresh(["fresh_sprout_squirrel", FILLER])
	var before := _counts(state)
	service._play_ingredient(state, "opponent", 0, "prep")
	var events := _account("Sprout Squirrel", before, state)
	_check(_events(events, "play", "token").size() == 1, "Squirrel's generated token must not withdraw a second held card.")
	_check(state.opponent.hand.size() == 1 and state.opponent.prep.size() == 2, "Squirrel's production effect changed.")

	state = _fresh(["fresh_comeback_corgi", FILLER])
	before = _counts(state)
	service._trigger_friendly_chef_damaged(state, "opponent")
	events = _account("Cucorgi damage response", before, state)
	_check(_events(events, "play", "hand").size() == 1 and _events(events, "play", "token").size() == 1, "Cucorgi must withdraw one actual card and create one token.")

	state = _fresh([FILLER])
	before = _counts(state)
	service._resolve_effects(state, "opponent", [{"type": "fill_prep_with_tokens"}], {})
	events = _account("Fill Prep with tokens", before, state)
	_check(_events(events, "play", "token").size() == 3, "Saladmander must create all three token presentations without consuming hand cards.")

	state = _fresh(["funky_beat_beetle", FILLER, FILLER])
	before = _counts(state)
	service._play_ingredient(state, "opponent", 0, "prep")
	events = _account("Beet Beetle cost and draw", before, state)
	var discards := _events(events, "discard", "hand")
	var plays := _events(events, "play", "hand")
	_check(discards.size() == 1 and plays.size() == 1 and int(discards[0].group_id) == int(plays[0].group_id), "Beet Beetle's actual discard cost must accompany its play group.")
	_check(state.opponent.hand.size() == 2 and state.opponent.discard.size() == 1, "Beet Beetle's discard/draw rules changed.")

	state = _fresh(["item_recipe_prep", FILLER, FILLER, FILLER])
	before = _counts(state)
	service._pay_negated_card_from_hand(state, "opponent", "item_recipe_prep", "tool")
	events = _account("Negated Recipe Prep cost", before, state)
	discards = _events(events, "discard", "hand")
	plays = _events(events, "play", "hand")
	_check(discards.size() == 2 and plays.size() == 1, "Negating Recipe Prep must still visibly pay its two-card discard cost.")
	for event in discards:
		_check(int(event.group_id) == int(plays[0].group_id), "Negated tool cost detached from the negated play group.")
	_check(state.opponent.hand.size() == 1 and state.opponent.discard.size() == 3, "Negated tool cost rules changed.")


func _test_non_hand_deployments() -> void:
	var state := _fresh([FILLER])
	state.opponent.discard = ["funky_eggplant_ant"]
	var before := _counts(state)
	service._ai_play_discard_ingredient(state)
	var events := _account("Eggplant Ant from discard", before, state)
	_check(_events(events, "play", "discard").size() == 1, "Eggplant Ant must travel from discard, not the held fan.")

	state = _fresh([FILLER])
	state.opponent.discard = [FILLER]
	before = _counts(state)
	service._revive_from_discard(state, "opponent", {"amount": 1})
	events = _account("Revive from discard", before, state)
	_check(_events(events, "play", "discard").size() == 1 and state.opponent.discard.is_empty(), "Revived cards have the wrong source or remain in discard.")

	state = _fresh(["fresh_crisp_capybara", FILLER])
	before = _counts(state)
	service._play_ingredient(state, "opponent", 0, "prep")
	events = _account("Crisp Capybara deck deployment", before, state)
	_check(_events(events, "play", "deck").size() == 1 and _events(events, "play", "hand").size() == 1, "Capybara must consume only its own held card and deploy its target from deck.")

	state = _fresh([FILLER])
	for index in SERVICE.PREP_SLOTS:
		state.opponent.prep.append(service._make_unit(state, state.opponent, service.card(FILLER), "prep", "opponent"))
	before = _counts(state)
	service._deploy_searched_ingredient(state, "opponent", FILLER)
	events = _account("Full Prep search fallback", before, state)
	_check(_events(events, "search", "deck").size() == 1 and state.opponent.hand.size() == 2, "The full-Prep fallback must visibly add its searched card to hand.")


func _test_shuffle_and_forced_play() -> void:
	var state := _fresh(["chef_duff", FILLER, FILLER])
	var before := _counts(state)
	service._play_chef(state, "opponent", 0, true)
	var events := _account("Chef Duff replaces both hands", before, state)
	_check(_events(events, "search", "hand").size() == 5, "Duff must put both actual old hands into their decks before drawing.")
	_check(state.opponent.hand.size() == 4 and state.player.hand.size() == 4, "Chef Duff no longer draws four cards for each player.")

	state = _fresh(["fresh_sprout_squirrel", FILLER])
	before = _counts(state)
	service._deploy_enemy_hand_unit(state, "player", 0)
	events = _account("Tongs pulls a rival card", before, state)
	_check(_events(events, "play", "hand").size() == 1, "Tongs must visibly withdraw the real rival card.")
	_check(state.opponent.prep.size() == 1 and _events(events, "card_text_activation", "").is_empty(), "Tongs incorrectly resolves or advertises the forced card's on-play effect.")


func _test_board_returns() -> void:
	for zone in ["prep", "plated"]:
		var state := _fresh([FILLER])
		var unit: Dictionary = service._make_unit(state, state.opponent, service.card(FILLER), zone, "opponent")
		unit.table_slot = 1
		state.opponent[zone].append(unit)
		var before := _counts(state)
		if zone == "prep":
			service._return_enemy_ingredient(state, "opponent", int(unit.instance_id))
		else:
			service._return_enemy_plated_unit(state, "opponent", int(unit.instance_id))
		var events := _account("Return " + zone + " card to hand", before, state)
		var returns := _events(events, "search", zone)
		_check(returns.size() == 1 and int(returns[0].source_table_slot) == 1 and int(returns[0].source_instance_id) == int(unit.instance_id), "Board return lost the actual card's slot/source identity.")
		_check(state.opponent[zone].is_empty(), "Returned card remained on the board.")

	var state := _fresh([FILLER])
	var token: Dictionary = service._make_unit(state, state.opponent, service.card("token_fresh_ingredient"), "prep", "opponent")
	token.is_token = true
	state.opponent.prep.append(token)
	var before := _counts(state)
	service._return_enemy_ingredient(state, "opponent", int(token.instance_id))
	var events := _account("Returned token evaporates", before, state)
	_check(_events(events, "search", "prep").is_empty() and _events(events, "evaporate", "").size() == 1, "A returned token must evaporate without adding a sleeve to hand.")


func _events(events: Array[Dictionary], event_type: String, source: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if String(event.get("type", "")) == event_type and String(event.get("from", "")) == source:
			found.append(event)
	return found


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
