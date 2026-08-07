extends SceneTree

const TUTORIAL_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tutorial = TUTORIAL_SCENE.instantiate()
	tutorial.configure_tutorial()
	root.add_child(tutorial)
	await process_frame
	await process_frame

	_expect(tutorial.tutorial_mode and tutorial.tutorial_step_index == 0, "The guided tutorial did not initialize.")
	tutorial._tutorial_complete_action("continue")
	tutorial._tutorial_complete_action("select_hand", {"card_id": "spicy_hot_honey_bee", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "spicy_hot_honey_bee"), "prep", 1)
	_expect(tutorial.state.player.prep.size() == 1, "The forced Ingredient was not played to Prep.")

	tutorial._on_end_turn_pressed()
	_expect(tutorial.tutorial_step_index == 4 and String(tutorial.state.player.prep[0].card_id) == "spicy_hot_honey_bee", "End Turn did not fast-forward to the fixed recipe hand.")

	tutorial._tutorial_complete_action("select_hand", {"card_id": "environment_spicy_taqueria", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "environment_spicy_taqueria"), "prep")
	_expect(String(tutorial.state.player.environment) == "environment_spicy_taqueria", "The Environment lesson did not resolve.")

	tutorial._tutorial_complete_action("select_hand", {"card_id": "spicy_sriracharrow", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "spicy_sriracharrow"), "prep", 1)
	var ingredient_id := int(tutorial.state.player.prep[0].instance_id)
	tutorial.service.toggle_ingredient_selection(tutorial.state, ingredient_id)
	tutorial._tutorial_complete_action("select_recipe", {"card_id": "spicy_hot_honey_bee", "instance_id": ingredient_id})
	await tutorial._confirm_meal_play()
	_expect(tutorial.state.player.prep.size() == 1 and String(tutorial.state.player.prep[0].card_id) == "spicy_sriracharrow", "The recipe did not sacrifice the fixed Ingredient and serve the Meal.")

	var meal_id := int(tutorial.state.player.prep[0].instance_id)
	var meal_card := tutorial.find_child("PlayerPrepCard*", true, false) as Node3D
	if meal_card != null:
		tutorial._handle_card_click(meal_card)
	_expect(tutorial.pending_move_instance_id == meal_id, "Selecting the Meal did not immediately arm physical-slot movement.")
	tutorial._choose_pending_move_destination("plated", 0)
	while tutorial.animation_busy:
		await process_frame
	_expect(tutorial.tutorial_step_index == 12 and tutorial.state.player.plated.size() == 1, "The zone lesson did not advance to the support-card checkpoint.")

	meal_id = int(tutorial.state.player.plated[0].instance_id)
	tutorial._tutorial_complete_action("select_field", {"card_id": "spicy_sriracharrow", "instance_id": meal_id})
	tutorial._select_spice_target(meal_id)
	tutorial._tutorial_complete_action("select_hand", {"card_id": "spice_cayenne_crunch", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "spice_cayenne_crunch"), "prep")
	_expect(tutorial.state.player.plated[0].spices == ["spice_cayenne_crunch"], "The forced Spice did not attach.")

	tutorial._tutorial_complete_action("select_hand", {"card_id": "item_wooden_spoon", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "item_wooden_spoon"), "prep")
	tutorial._tutorial_complete_action("select_hand", {"card_id": "chef_mary", "instance_id": -1})
	await tutorial._play_hand_card(_hand_index(tutorial, "chef_mary"), "prep")
	_expect(tutorial.tutorial_step_index == 20 and tutorial.state.opponent.plated.size() == 1, "Support cards did not advance to the fixed combat checkpoint.")

	tutorial._tutorial_complete_action("select_field", {"card_id": "spicy_sriracharrow", "instance_id": 1})
	tutorial._select_attacker(1)
	await tutorial._perform_attack(3)
	_expect(tutorial.state.opponent.plated.is_empty(), "The scripted defender was not cleared.")
	tutorial._tutorial_complete_action("select_field", {"card_id": "spicy_sriracharrow", "instance_id": 2})
	tutorial._select_attacker(2)
	await tutorial._perform_attack(-1)
	_expect(bool(tutorial.state.game_over) and String(tutorial.state.winner) == "player", "The direct Chef attack did not win the tutorial.")
	_expect(String(tutorial._tutorial_step().action) == "finish", "The tutorial did not reach its completion screen.")

	for audio_node in tutorial.find_children("*", "AudioStreamPlayer", true, false):
		var audio_player := audio_node as AudioStreamPlayer
		audio_player.stop()
		audio_player.stream = null
	await create_timer(0.12).timeout
	tutorial.queue_free()
	await process_frame
	if failures.is_empty():
		print("Guided tutorial smoke test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _hand_index(tutorial, card_id: String) -> int:
	return tutorial.state.player.hand.find(card_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
