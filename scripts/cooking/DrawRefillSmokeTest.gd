extends SceneTree
const SERVICE := preload("res://scripts/cooking/CookingCombatService.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service = SERVICE.new()
	assert(service.load_content())
	for pressure in [false, true]:
		for lethal in [false, true]:
			var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 491)
			state.player.hand = []
			state.player.deck = []
			state.player.discard = ["chef_mary"]
			state.player.life = 2 if lethal else 40
			state.player.turns_started = 3
			state.run_rules = {"reshuffle_pressure": pressure, "turn_hand_floor": 3, "reshuffle_damage": [3, 5, 7]}
			service._start_turn(state, "player")
			assert(state.player.hand.size() == (1 if pressure and not lethal else 0), "Empty-deck refill changed cards or did not stop")
			assert(bool(state.game_over) == (pressure and lethal), "Lethal reshuffle did not end refill")
			if not state.game_over:
				service._resolve_effects(state, "player", [{"type": "draw_to_hand_size", "amount": 5}], {})
				assert(state.player.hand.size() <= 1, "Draw-to-hand-size created unavailable cards")
	print("Draw refill smoke test passed: empty piles, non-reshuffling discard, exhaustion, and lethal pressure.")
	quit(0)
