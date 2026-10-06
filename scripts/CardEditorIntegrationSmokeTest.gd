extends SceneTree

## Reads an isolated card file produced by the webapp's apply path. Never changes
## the project's cards or player saves. Run via tools/card-editor's test suite.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the isolated edited card fixture as a user argument.")
		quit(1)
		return
	var service := preload("res://scripts/cooking/CookingCombatService.gd").new()
	if not service.load_content(args[0]):
		push_error("Could not load the edited card file.")
		quit(1)
		return
	var card: Dictionary = service.card("spicy_hot_honey_bee")
	if int(card.attack) != 7 or int(card.health) != 8 or int(card.on_play[0].amount) != 3 or not String(card.text).contains("3 damage"):
		push_error("Edited card fields did not reach the game.")
		quit(1)
		return
	var state := service.start_game("", "", 19)
	state.player.hand = ["spicy_hot_honey_bee"]
	state.player.prep.clear()
	state.opponent.hand.clear()
	var life_before := int(state.opponent.life)
	service.play_card(state, 0, "prep")
	if int(state.opponent.life) != life_before - 3 or state.player.prep.is_empty() or int(state.player.prep[0].attack) != 7:
		push_error("Edited damage or stats did not resolve in combat.")
		quit(1)
		return
	if service.card("token_fresh_ingredient").is_empty():
		push_error("Editable token definition is missing.")
		quit(1)
		return
	print("Card editor integration passed: edited JSON loaded and resolved in combat.")
	quit(0)
