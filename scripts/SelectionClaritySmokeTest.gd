extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const ABILITY_READY_PREVIEW_PATH := "/tmp/topdeck_to_worlds_ability_ready_glow.png"
const PROFILE_EXPANDED_PREVIEW_PATH := "/tmp/topdeck_to_worlds_profile_expanded.png"

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
	var ability_aura := ability_card.find_child("AbilityReadyAura", true, false) as MeshInstance3D if ability_card != null else null
	_expect(ability_aura != null, "Usable ability has no celestial frame.")
	_expect(
		ability_aura != null
		and (ability_aura.mesh as QuadMesh).size.x >= 1.60
		and float(ability_aura.get_meta("pulse_energy_max", 0.0)) >= 1.25
		and (ability_aura.material_override as StandardMaterial3D).albedo_color.a >= 0.95,
		"Usable ability glow is too subtle to read clearly on the battlefield."
	)
	_expect(
		ability_card != null and ability_card.find_child("AbilityReadySparkles", true, false) == null,
		"Usable ability frame still has distracting sparkle specks around its edges."
	)
	_expect(ability_card != null and ability_card.find_child("AbilityReadyBadge", true, false) == null, "Usable ability should communicate through its frame without a text badge.")
	_expect(ability_card != null and ability_card.find_child("ReadyStatus", true, false) == null, "Generic READY badge competes with ABILITY state.")
	_expect(
		table.player_profile_badge.size.x <= 110.0
		and table.opponent_profile_badge.size.x <= 110.0
		and not table.player_profile_details.visible
		and not table.opponent_profile_details.visible
		and table.player_profile_life_bar.size.x >= 280.0
		and table.opponent_profile_life_bar.size.x >= 280.0
		and table.player_profile_life_label.text == "20/20",
		"Collapsed combat profiles are not limited to portrait and HP."
	)
	table._toggle_profile_expanded("opponent")
	await process_frame
	_expect(
		table.opponent_profile_details.visible
		and table.opponent_profile_badge.size.x >= 240.0
		and table.opponent_profile_badge.size.y <= 110.0
		and table.opponent_profile_stats.text.contains("HAND")
		and table.opponent_profile_stats.text.contains("DECK")
		and table.opponent_profile_stats.text.contains("DISCARD"),
		"Clicking a profile portrait did not expand its card-count details."
	)
	if DisplayServer.get_name() != "headless":
		await create_timer(0.75).timeout
		var expanded_profile_preview := root.get_texture().get_image()
		_expect(expanded_profile_preview.save_png(PROFILE_EXPANDED_PREVIEW_PATH) == OK, "Expanded profile preview could not be saved.")
	table._toggle_profile_expanded("opponent")
	await process_frame
	var ability_base_position: Vector3 = ability_card.get_meta("base_position", ability_card.position)
	var ability_base_scale: Vector3 = ability_card.get_meta("base_scale", ability_card.scale)
	table.hovered_card = ability_card
	table._animate_physical_cards(0.2, 0.0)
	_expect(
		ability_card.position.y >= ability_base_position.y + 0.18
		and ability_card.scale.x >= ability_base_scale.x * 1.07,
		"Card hover feedback is not pronounced enough to read at the table scale."
	)
	table.hovered_card = null
	table._animate_physical_cards(0.2, 0.0)
	if DisplayServer.get_name() != "headless":
		# Give freshly rebuilt 3D card faces and their animated art time to settle
		# before capturing; the old sparkle sampling loop provided this delay.
		await create_timer(0.75).timeout
		var ability_ready_preview := root.get_texture().get_image()
		_expect(ability_ready_preview.save_png(ABILITY_READY_PREVIEW_PATH) == OK, "Ability-ready glow preview could not be saved.")
	var active_state: Dictionary = table.state
	table.state = active_state.duplicate(true)
	table.state.player.hand = []
	table.state.player.prep = []
	table.state.player.plated = []
	table.state.player.environment = ""
	table._render_match()
	_expect(
		table.end_turn_no_actions_attention_active
		and table.end_turn_attention_until_msec > Time.get_ticks_msec(),
		"End Turn did not receive its brief attention pulse when no useful actions remained."
	)
	table.state = active_state

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
