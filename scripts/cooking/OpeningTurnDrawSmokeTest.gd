extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	service.setup_content(
		[
			{
				"id": "test_ingredient",
				"name": "Test Ingredient",
				"card_type": "ingredient",
				"archetype": "spicy",
				"ingredient_types": ["spicy"],
				"attack": 1,
				"health": 1,
				"text": ""
			}
		],
		{
			"test_player": {
				"name": "Test Player",
				"cards": {"test_ingredient": 20}
			},
			"test_opponent": {
				"name": "Test Opponent",
				"cards": {"test_ingredient": 20}
			}
		}
	)

	var player_first: Dictionary = service.start_game(
		"test_player",
		"test_opponent",
		30001,
		"player",
		true
	)
	_expect(
		player_first.player.hand.size() == 5
		and player_first.player.deck.size() == 15
		and int(player_first.player.turns_started) == 1,
		"The player drew a sixth card while going first."
	)
	service.end_player_turn(player_first, true)
	service.advance_opponent_turn(player_first)
	_expect(
		player_first.opponent.hand.size() == 6
		and player_first.opponent.deck.size() == 14
		and int(player_first.opponent.turns_started) == 1,
		"The second player did not draw on their first turn."
	)

	var opponent_first_deferred: Dictionary = service.start_game(
		"test_player",
		"test_opponent",
		30002,
		"opponent",
		true
	)
	_expect(
		opponent_first_deferred.opponent.hand.size() == 5
		and opponent_first_deferred.opponent.deck.size() == 15
		and int(opponent_first_deferred.opponent.turns_started) == 0,
		"Opponent-first setup changed the opening hand before its turn began."
	)
	service.advance_opponent_turn(opponent_first_deferred)
	_expect(
		opponent_first_deferred.opponent.hand.size() == 5
		and opponent_first_deferred.opponent.deck.size() == 15
		and int(opponent_first_deferred.opponent.turns_started) == 1,
		"The opponent drew a sixth card while going first."
	)
	_expect(
		"Opponent goes first and skips their opening draw."
		in "\n".join(opponent_first_deferred.log),
		"The battle log did not explain the opponent's skipped opening draw."
	)
	var safety := 30
	while String(opponent_first_deferred.phase) == "opponent_turn" and safety > 0:
		safety -= 1
		service.advance_opponent_turn(opponent_first_deferred)
	_expect(
		safety > 0
		and String(opponent_first_deferred.phase) == "player_main"
		and opponent_first_deferred.player.hand.size() == 6
		and opponent_first_deferred.player.deck.size() == 14
		and int(opponent_first_deferred.player.turns_started) == 1,
		"The player did not draw normally when going second."
	)

	var opponent_first_automatic: Dictionary = service.start_game(
		"test_player",
		"test_opponent",
		30003,
		"opponent",
		false
	)
	_expect(
		String(opponent_first_automatic.phase) == "player_main"
		and opponent_first_automatic.opponent.deck.size() == 15
		and opponent_first_automatic.player.deck.size() == 14
		and opponent_first_automatic.player.hand.size() == 6,
		"The automatic opponent-first flow did not skip only the first player's draw."
	)

	if failed:
		quit(1)
		return
	print("Opening turn draw smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
