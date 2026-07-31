extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")


func _init() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		push_error("Could not load production card content.")
		quit(1)
		return
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 72601)
	state.player.deck = []
	state.player.hand = []
	state.player.life = 17
	state.player.fatigue = 0
	service.take_animation_events(state)
	service._draw(state, "player")
	service._draw(state, "player")
	var events: Array[Dictionary] = service.take_animation_events(state)
	for event in events:
		if String(event.get("type", "")) == "damage":
			push_error("An empty-deck draw still queued Chef damage.")
			quit(1)
			return
	if int(state.player.life) != 17 or int(state.player.fatigue) != 0 or not state.player.hand.is_empty():
		push_error("An empty-deck draw changed life, fatigue, or hand state.")
		quit(1)
		return
	print("Empty-deck draw smoke test passed.")
	quit(0)
