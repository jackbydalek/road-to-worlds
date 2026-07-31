extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")


func _init() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load production card content.")
		return

	var empty_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 71001)
	empty_state.player.hand = ["chef_john"]
	empty_state.player.deck = ["item_wooden_spoon", "spicy_sriracharrow", "spicy_hot_honey_bee", "hearty_bagver", "sweet_pup_tart"]
	empty_state.opponent.hand = ["spicy_hot_honey_bee", "spicy_jalapeno_jackal", "spicy_wasabi_wasp"]
	service.play_card(empty_state, 0)
	if empty_state.player.hand.size() != 4 or empty_state.player.deck.size() != 1 or empty_state.player.discard != ["chef_john"]:
		_fail("Chef Carmy did not draw four cards after discarding the played Chef.")
		return
	var empty_events: Array[Dictionary] = service.take_animation_events(empty_state)
	if empty_events.size() != 6 or String(empty_events[0].get("type", "")) != "play" or String(empty_events[1].get("type", "")) != "card_text_activation":
		_fail("Chef Carmy's presentation did not queue its card effect before the draws.")
		return
	for event_index in range(2, empty_events.size()):
		if String(empty_events[event_index].get("type", "")) != "draw":
			_fail("Chef Carmy's drawn cards were not queued as draw animations after its effect cue.")
			return

	var discard_state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 71002)
	discard_state.player.hand = ["chef_john", "hearty_bagver", "sweet_pup_tart"]
	discard_state.player.deck = ["item_wooden_spoon", "spicy_sriracharrow", "spicy_hot_honey_bee", "sweet_sugar_glider", "sweet_caramel_camel", "spicy_jalapeno_panther"]
	discard_state.opponent.hand = ["spicy_hot_honey_bee", "spicy_jalapeno_jackal"]
	service.play_card(discard_state, 0)
	if discard_state.player.hand.size() != 4 or discard_state.player.deck.size() != 2:
		_fail("Chef Carmy did not draw exactly four cards.")
		return
	if discard_state.player.discard != ["chef_john", "hearty_bagver", "sweet_pup_tart"]:
		_fail("Chef Carmy did not discard the previous hand.")
		return

	print("CHEF CARMY SMOKE TEST PASSED")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
