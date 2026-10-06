extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var failures: Array[String] = []
var table


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.reduced_motion = true
	table.state.phase = "player_main"
	table.state.game_over = false
	table.state.turn = 3
	table.state.player.prep = []
	table.state.player.plated = []
	table.state.player.environment = ""
	table.state.opponent.prep = []
	table.state.opponent.plated = []
	for key in ["pending_meal", "pending_discard", "pending_ability", "pending_search", "pending_choice", "pending_reaction"]:
		table.state[key] = {}
	var ferret := _unit("funky_fondue_ferret", "prep", 0)
	table.state.player.prep = [ferret]
	# Activated abilities do not require the separate attack-ready state.
	ferret.ready = false
	table._render_match()
	_expect_marker(ferret, true, "Unused Prep ability")
	var card: Node3D = table._card_node_for_instance(int(ferret.instance_id))
	var badge := card.get_node_or_null("AbilityReadyBadge") as Label3D
	var backing := card.get_node_or_null("AbilityReadyBadgeBacking") as MeshInstance3D
	_expect(badge != null and badge.text == "USE ABILITY" and badge.modulate == PALETTE.PEACH_PAPER and badge.outline_size == 0, "Ability state needs clear paper text without a glow or dark text outline.")
	_expect(backing != null and backing.material_override is StandardMaterial3D and backing.material_override.albedo_color == PALETTE.PEACH_TEAL and not backing.material_override.emission_enabled, "Ability tab must use a matte teal backing.")
	table.service.activate_ability(table.state, int(ferret.instance_id), "feta_ferret_mill")
	table._render_match()
	_expect_marker(ferret, false, "Used once-per-turn ability")
	table.service._start_turn(table.state, "player", false)
	table._render_match()
	_expect_marker(ferret, true, "Next turn refreshed ability")
	table.state.player.prep = []
	table.state.player.plated = [ferret]
	table._render_match()
	_expect_marker(ferret, false, "Prep-only ability moved to Plated")
	table.state.player.plated = []
	table.state.player.prep = [ferret]
	table.state.pending_search = {"effect": {}, "remaining": 1}
	table._render_match()
	_expect_marker(ferret, false, "Another choice is active")
	table.state.pending_search = {}
	table.state.phase = "opponent_main"
	table._render_match()
	_expect_marker(ferret, false, "Rival turn")
	table.state.phase = "player_main"
	table.reduced_motion = false
	table._render_match()
	_expect_marker(ferret, true, "Normal-motion readiness")
	table.reduced_motion = true
	table._render_match()
	_expect_marker(ferret, true, "Reduced-motion readiness")
	var relishoon := _unit("spicy_funky_relishoon", "plated", 0)
	table.state.player.prep = []
	table.state.player.plated = [relishoon]
	table._render_match()
	_expect_marker(relishoon, false, "No legal sacrifice target")
	table.state.player.prep = [ferret]
	table._render_match()
	_expect_marker(relishoon, true, "Legal sacrifice target present")
	table.service.activate_ability(table.state, int(relishoon.instance_id), "relishoon_sacrifice")
	table._render_match()
	_expect_marker(relishoon, false, "Ability is choosing its target")
	table.service.cancel_ability_target(table.state)
	table.state.player.environment = "environment_funky_pickle_stand"
	table.state.player.environment_used_abilities = []
	table.state.player.discard = ["funky_fondue_ferret"]
	table._render_match()
	var environment: Node3D = table.find_child("PlayerEnvironmentCard", true, false)
	_expect(environment != null and environment.has_node("AbilityReadyBadge"), "Environment ability lacks the same readable readiness tab.")
	table.service.activate_environment_ability(table.state, "funky_pickle_recover")
	table._render_match()
	environment = table.find_child("PlayerEnvironmentCard", true, false)
	_expect(environment != null and not environment.has_node("AbilityReadyBadge"), "Used environment still advertises USE ABILITY.")
	table.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("Ability readiness smoke test passed: visible action tabs, live usage and next-turn reset, zones, target legality, prompts, environment and Reduced Motion.")
	quit(0 if failures.is_empty() else 1)


func _unit(card_id: String, zone: String, slot: int) -> Dictionary:
	var unit: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card(card_id), zone, "player")
	unit.table_slot = slot
	return unit


func _expect_marker(unit: Dictionary, expected: bool, context: String) -> void:
	var card: Node3D = table._card_node_for_instance(int(unit.instance_id))
	_expect(card != null, context + ": card disappeared.")
	if card == null:
		return
	_expect(card.has_node("AbilityReadyBadge") == expected and card.has_node("AbilityReadyAura") == expected, context + ": readiness label/frame disagree with availability.")
	if expected:
		_expect(not card.has_node("MealCandidateBadge") and not card.has_node("MealSelectionBadge") and not card.has_node("ReadyStatus"), context + ": action badge competes with another readiness state.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
