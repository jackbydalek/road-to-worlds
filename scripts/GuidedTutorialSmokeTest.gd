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
	tutorial._render_match()
	var bee_card := _card_node(tutorial, "hand", "player", "spicy_hot_honey_bee")
	var spoon_card := _card_node(tutorial, "hand", "player", "item_wooden_spoon")
	_expect(bee_card != null and tutorial._can_drag_card(bee_card), "The tutorial Ingredient could not begin a drag.")
	_expect(spoon_card != null and not tutorial._can_drag_card(spoon_card), "A non-tutorial hand card could begin a drag.")
	await _drag_card(tutorial, bee_card, Vector3(5.2, tutorial.TABLE_Y, -4.7))
	_expect(tutorial.tutorial_step_index == 1 and tutorial.state.player.prep.is_empty(), "An invalid Ingredient drop advanced the tutorial.")
	bee_card = _card_node(tutorial, "hand", "player", "spicy_hot_honey_bee")
	await _drag_card(tutorial, bee_card, _slot_point(tutorial, "player_prep", 1))
	_expect(tutorial.state.player.prep.size() == 1, "The forced Ingredient was not played to Prep.")

	tutorial._on_end_turn_pressed()
	_expect(String(tutorial._tutorial_step().action) == "play_hand" and String(tutorial.state.player.prep[0].card_id) == "spicy_hot_honey_bee", "End Turn did not fast-forward to the fixed recipe hand.")

	var environment_card := _card_node(tutorial, "hand", "player", "environment_spicy_taqueria")
	_expect(environment_card != null and tutorial._can_drag_card(environment_card), "The Environment could not begin a drag.")
	await _drag_card(tutorial, environment_card, tutorial.AUX_ZONE_POSITIONS.player_environment)
	_expect(String(tutorial.state.player.environment) == "environment_spicy_taqueria", "The Environment lesson did not resolve.")

	var meal_hand_card := _card_node(tutorial, "hand", "player", "spicy_sriracharrow")
	_expect(meal_hand_card != null and tutorial._can_drag_card(meal_hand_card), "The Meal could not begin a drag.")
	await _drag_card(tutorial, meal_hand_card, _slot_point(tutorial, "player_prep", 1))
	var ingredient_id := int(tutorial.state.player.prep[0].instance_id)
	var ingredient_card := _card_node(tutorial, "field", "player", "spicy_hot_honey_bee")
	_expect(ingredient_card != null, "The recipe Ingredient was not rendered for selection.")
	tutorial._handle_card_click(ingredient_card)
	await tutorial._confirm_meal_play()
	_expect(tutorial.state.player.prep.size() == 1 and String(tutorial.state.player.prep[0].card_id) == "spicy_sriracharrow", "The recipe did not sacrifice the fixed Ingredient and serve the Meal.")

	var meal_card := _card_node(tutorial, "field", "player", "spicy_sriracharrow")
	_expect(meal_card != null and tutorial._can_drag_card(meal_card), "The served Meal could not begin a lane drag.")
	await _drag_card(tutorial, meal_card, _slot_point(tutorial, "player_plated", 0))
	_expect(tutorial.state.player.plated.size() == 1 and String(tutorial._tutorial_step().card_id) == "spice_cayenne_crunch", "The zone drag did not advance to the support-card checkpoint.")

	meal_card = _card_node(tutorial, "field", "player", "spicy_sriracharrow")
	var spice_card := _card_node(tutorial, "hand", "player", "spice_cayenne_crunch")
	_expect(spice_card != null and tutorial._can_drag_card(spice_card), "The Spice could not begin a drag.")
	await _drag_card(tutorial, spice_card, meal_card.position)
	_expect(tutorial.state.player.plated[0].spices == ["spice_cayenne_crunch"], "The forced Spice did not attach.")

	spoon_card = _card_node(tutorial, "hand", "player", "item_wooden_spoon")
	await _drag_card(tutorial, spoon_card, Vector3(0.0, tutorial.TABLE_Y, -1.0))
	var chef_card := _card_node(tutorial, "hand", "player", "chef_mary")
	await _drag_card(tutorial, chef_card, Vector3(0.0, tutorial.TABLE_Y, -1.0))
	_expect(tutorial.state.opponent.plated.size() == 1 and String(tutorial._tutorial_step().action) == "attack_unit", "Support cards did not advance to the fixed combat checkpoint.")

	var first_attacker := _field_card_by_instance(tutorial, 1)
	var defender := _field_card_by_instance(tutorial, 3)
	_expect(first_attacker != null and tutorial._can_drag_card(first_attacker), "The first attacker could not begin a drag.")
	await _drag_card(tutorial, first_attacker, defender.position)
	_expect(tutorial.state.opponent.plated.is_empty(), "The scripted defender was not cleared.")
	var second_attacker := _field_card_by_instance(tutorial, 2)
	_expect(second_attacker != null and tutorial._can_drag_card(second_attacker), "The second attacker could not begin a drag.")
	await _drag_card(tutorial, second_attacker, tutorial.opponent_chef.position)
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


func _drag_card(tutorial, card_node: Node3D, destination: Vector3) -> void:
	if card_node == null:
		return
	tutorial.pressed_card = card_node
	tutorial.dragging = true
	tutorial.drag_offset = Vector3.ZERO
	tutorial.drag_original_position = card_node.position
	tutorial.drag_original_rotation = card_node.rotation
	await tutorial._finish_drag(destination)
	await process_frame


func _card_node(tutorial, kind: String, side: String, card_id: String) -> Node3D:
	for candidate in tutorial.interactive_cards:
		if (
			is_instance_valid(candidate)
			and String(candidate.get_meta("kind", "")) == kind
			and String(candidate.get_meta("side", "")) == side
			and String(candidate.get_meta("card_id", "")) == card_id
		):
			return candidate
	return null


func _field_card_by_instance(tutorial, instance_id: int) -> Node3D:
	for candidate in tutorial.interactive_cards:
		if (
			is_instance_valid(candidate)
			and String(candidate.get_meta("kind", "")) == "field"
			and int(candidate.get_meta("instance_id", -1)) == instance_id
		):
			return candidate
	return null


func _slot_point(tutorial, zone_id: String, slot_index: int) -> Vector3:
	var center: Vector3 = tutorial.ZONE_CENTERS[zone_id]
	var zone_name := zone_id.trim_prefix("player_").trim_prefix("opponent_")
	var capacity: int = tutorial.service.PREP_SLOTS if zone_name == "prep" else tutorial.service.PLATED_SLOTS
	var spacing := 1.72 if capacity == 3 else 1.8
	var offset := (float(slot_index) - float(capacity - 1) * 0.5) * spacing
	return center + Vector3(offset, 0.0, 0.0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
