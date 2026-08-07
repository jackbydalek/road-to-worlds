extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	table.reduced_motion = false
	table.state.phase = "player_main"
	table.state.turn = 2

	var selected_unit := _unit(table, "spicy_hot_honey_bee", 0)
	var candidate_unit := _unit(table, "spicy_jalapeno_panther", 1)
	selected_unit.recipe_ready_on_turn = 0
	candidate_unit.recipe_ready_on_turn = 0
	table.state.player.prep = [selected_unit, candidate_unit]
	table.state.player.plated = []
	table.state.player.hand.append("spicy_sriracharrow")
	table.state.pending_meal = {
		"hand_index": table.state.player.hand.size() - 1,
		"card_id": "spicy_sriracharrow",
		"destination": "plated",
		"destination_slot": 0,
		"required": 1,
	}
	table.state.selected_ingredients = [int(selected_unit.instance_id)]
	table._render_match()

	var selected_card: Node3D = table._card_node_for_instance(int(selected_unit.instance_id))
	var candidate_card: Node3D = table._card_node_for_instance(int(candidate_unit.instance_id))
	_expect(selected_card != null and selected_card.find_child("MealSelectionBadge", true, false) != null, "Selected Meal ingredient has no SELECTED badge.")
	_expect(candidate_card != null and candidate_card.find_child("MealCandidateBadge", true, false) != null, "Meal candidate has no CHOOSE badge.")
	var selected_aura := selected_card.find_child("MealIngredientSelectedAura", true, false) as MeshInstance3D
	var candidate_aura := candidate_card.find_child("MealIngredientCandidateAura", true, false) as MeshInstance3D
	_expect(_texture_ends_with(selected_aura, "meal_selected_aura.svg"), "Selected Meal ingredient has the wrong frame.")
	_expect(_texture_ends_with(candidate_aura, "meal_candidate_aura.svg"), "Meal candidate has the wrong frame.")

	table.state.pending_meal = {}
	table.state.selected_ingredients = []
	var ability_unit := _unit(table, "spicy_jalapeno_panther", 1)
	ability_unit.ready = true
	table.state.player.prep = [ability_unit]
	table._render_match()
	var ability_card: Node3D = table._card_node_for_instance(int(ability_unit.instance_id))
	_expect(ability_card != null and ability_card.find_child("AbilityReadyAura", true, false) != null, "Usable ability has no celestial frame.")
	var ability_sparkles := ability_card.find_child("AbilityReadySparkles", true, false) as MeshInstance3D if ability_card != null else null
	_expect(ability_sparkles != null, "Usable ability has no independently animated sparkle layer.")
	_expect(_texture_ends_with(ability_sparkles, "ability_ready_sparkles.svg"), "Ability sparkle layer uses the wrong texture.")
	if ability_sparkles != null and ability_sparkles.material_override is StandardMaterial3D:
		var sparkle_material := ability_sparkles.material_override as StandardMaterial3D
		var sparkle_alpha_min := sparkle_material.albedo_color.a
		var sparkle_alpha_max := sparkle_alpha_min
		for unused_sample in range(8):
			await create_timer(0.08).timeout
			sparkle_alpha_min = minf(sparkle_alpha_min, sparkle_material.albedo_color.a)
			sparkle_alpha_max = maxf(sparkle_alpha_max, sparkle_material.albedo_color.a)
		_expect(sparkle_alpha_max - sparkle_alpha_min > 0.05, "Ability sparkles do not visibly animate in and out.")
	_expect(ability_card != null and ability_card.find_child("AbilityReadyBadge", true, false) == null, "Usable ability should communicate through its frame without a text badge.")
	_expect(ability_card != null and ability_card.find_child("ReadyStatus", true, false) == null, "Generic READY badge competes with ABILITY state.")

	table.queue_free()
	await process_frame
	if failures.is_empty():
		print("Selection clarity smoke test passed.")
		quit()
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _unit(table, card_id: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(
		table.state,
		table.state.player,
		table.service.card(card_id),
		"prep",
		"player"
	)
	unit.table_slot = slot
	return unit


func _texture_ends_with(aura: MeshInstance3D, suffix: String) -> bool:
	if aura == null or not (aura.material_override is StandardMaterial3D):
		return false
	var material := aura.material_override as StandardMaterial3D
	return material.albedo_texture != null and material.albedo_texture.resource_path.ends_with(suffix)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
