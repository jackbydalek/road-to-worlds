extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const MEAL_PATH := "res://outputs/clarity_states/meal_selection.png"
const ABILITY_PATH := "res://outputs/clarity_states/ability_ready.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	await create_timer(1.15).timeout
	table.turn_banner_panel.visible = false
	table.rival_action_panel.visible = false
	for effect in table.effect_layer.get_children():
		effect.queue_free()
	await process_frame
	table.state.phase = "player_main"
	table.state.turn = 2

	var first_ingredient := _unit(table, "player", "spicy_hot_honey_bee", "prep", 0, false)
	var second_ingredient := _unit(table, "player", "spicy_jalapeno_panther", "prep", 1, false)
	first_ingredient.recipe_ready_on_turn = 0
	second_ingredient.recipe_ready_on_turn = 0
	table.state.player.prep = [first_ingredient, second_ingredient]
	table.state.player.plated = []
	table.state.player.hand.append("spicy_sriracharrow")
	var meal_hand_index: int = table.state.player.hand.size() - 1
	table.state.pending_meal = {
		"hand_index": meal_hand_index,
		"card_id": "spicy_sriracharrow",
		"destination": "plated",
		"destination_slot": 0,
		"required": 1,
	}
	table.state.selected_ingredients = [int(first_ingredient.instance_id)]
	table.state.message = "Choose one Ingredient for Sriracharrow."
	table._render_match()
	await process_frame
	await create_timer(0.18).timeout
	_save_preview(MEAL_PATH)

	table.state.pending_meal = {}
	table.state.selected_ingredients = []
	table.state.player.hand.remove_at(meal_hand_index)
	var ability_unit := _unit(table, "player", "spicy_jalapeno_panther", "prep", 1, true)
	table.state.player.prep = [ability_unit]
	table.state.player.plated = []
	table.state.message = "Choose a card to play or use an available ability."
	table._render_match()
	await process_frame
	var ability_card: Node3D = table._card_node_for_instance(int(ability_unit.instance_id))
	var ability_sparkles := ability_card.find_child("AbilityReadySparkles", true, false) as MeshInstance3D if ability_card != null else null
	var sparkle_material := ability_sparkles.material_override as StandardMaterial3D if ability_sparkles != null else null
	var wait_started := Time.get_ticks_msec()
	while sparkle_material != null and sparkle_material.albedo_color.a < 0.88 and Time.get_ticks_msec() - wait_started < 1500:
		await process_frame
	_save_preview(ABILITY_PATH)

	table.queue_free()
	await process_frame
	quit()


func _save_preview(path: String) -> void:
	var preview := root.get_texture().get_image()
	if preview == null or preview.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("Could not save clarity preview: %s" % path)
	else:
		print("Saved clarity preview: %s" % path)


func _unit(table, side: String, card_id: String, zone: String, slot: int, ready: bool) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(
		table.state,
		table.state[side],
		table.service.card(card_id),
		zone,
		side
	)
	unit.table_slot = slot
	unit.ready = ready
	return unit
