extends SceneTree

## Guard attack rendering by resource identity and retained draw commands,
## rather than machine-dependent frame-time thresholds. Run with a native
## renderer as well as --headless to exercise the paint draw assertions.
class TestTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	func _begin_match_pacing() -> void:
		pass

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const PAINT_LAYERS := ["RoomPaint", "TablePaint"]
var failures: Array[String] = []
var paint_draws := {}
var table
var face_mesh: Mesh
var back_mesh: Mesh


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	table = TABLE_SCENE.instantiate()
	table.set_script(TestTable)
	root.add_child(table)
	await _settle()
	table.state = table.service.start_game("hearty_test_kitchen", "spicy_test_kitchen", 628, "player", true, "easy")
	table.state.turn = 3
	table.state.phase = "player_main"
	table.animation_busy = false
	table.reduced_motion = false
	for side in ["player", "opponent"]:
		table.state[side].turns_started = 2
		table.state[side].prep = []
		table.state[side].plated = []
		table.state[side].hand = ["chef_mary"]
		table.state[side].environment = ""
	var attacker: Dictionary = table.service._make_unit(table.state, table.state.player, table.service.card("spicy_wasabi_wasp"), "plated", "player")
	var defender: Dictionary = table.service._make_unit(table.state, table.state.opponent, table.service.card("sweet_soft_serve_crab"), "plated", "opponent")
	attacker.merge({"table_slot": 2, "attack": 2, "health": 20, "max_health": 20, "ready": true}, true)
	defender.merge({"table_slot": 2, "attack": 1, "health": 20, "max_health": 20}, true)
	table.state.player.plated = [attacker]
	table.state.opponent.plated = [defender]
	table.selected_ref = {}
	table._render_match()
	await _settle()
	face_mesh = table._card_node_for_instance(attacker.instance_id).get_node("CardBody").mesh
	back_mesh = table.card_layer.get_node("PlayerDeckCard_0/CardBody").mesh
	_expect(face_mesh != back_mesh, "Face-up and sleeved stock lost their distinct geometry")
	table._inspect_card(table._card_node_for_instance(attacker.instance_id))
	await _settle()
	_expect_reused_resources("initial board")
	await _expect_retired_nodes_cleanup()

	var backdrop := table.get_node("BattleBackdrop") as Control
	for layer_name in PAINT_LAYERS:
		var canvas := backdrop.get_node_or_null(NodePath("%s/PaintCanvas" % layer_name)) as Control
		_expect(canvas != null, "Missing retained paint canvas %s" % layer_name)
		if canvas != null:
			paint_draws[layer_name] = 0
			canvas.draw.connect(_count_paint_draw.bind(layer_name))
			canvas.queue_redraw()
	await _settle()
	var initial_paint_draws := paint_draws.duplicate()
	if DisplayServer.get_name() != "headless":
		for layer_name in PAINT_LAYERS:
			_expect(int(initial_paint_draws.get(layer_name, 0)) > 0, "%s was never drawn by the native renderer" % layer_name)

	# The renderer may redraw once when its global viewport resizes. Within
	# each size, changing the horizon must reuse those retained paint commands,
	# with the tabletop still spanning the horizon through the screen bottom.
	for window_size in [Vector2i(1800, 1000), Vector2i(1280, 800), Vector2i(1440, 900)]:
		root.size = window_size
		await _settle()
		var resized_paint_draws := paint_draws.duplicate()
		for horizon_fraction in [0.18, 0.33, 0.46]:
			backdrop.set_table_horizon_from_local_y(backdrop.size.y * horizon_fraction)
			_expect_table_mapping(backdrop, horizon_fraction)
			await _settle()
		if DisplayServer.get_name() != "headless":
			_expect(paint_draws == resized_paint_draws, "Horizon movement regenerated retained paint at %s: %s -> %s" % [window_size, resized_paint_draws, paint_draws])
	var attack_paint_draws := paint_draws.duplicate()

	# Use the live action button, combat queue, and inspector rebuild paths.
	# Restore readiness between exchanges to keep this fixture a single board.
	for attack_index in range(2):
		attacker.ready = true
		table._inspect_card(table._card_node_for_instance(attacker.instance_id))
		await _settle()
		_expect_reused_resources("inspection before attack %d" % attack_index)
		var action := table.find_child("CardViewerAction_choose_attacker", true, false) as Button
		_expect(action != null and not action.disabled and action.text.is_empty() and action.icon == table.ACTION_ICON_ATTACK, "Attack action stopped being an available icon-only control")
		if action == null:
			continue
		action.pressed.emit()
		await _settle()
		_expect(int(table.state.selected_attacker) == int(attacker.instance_id), "Attack icon did not select the attacker")
		await table._perform_attack(defender.instance_id)
		await _settle()
		_expect(int(attacker.health) == 19 - attack_index and int(defender.health) == 18 - attack_index * 2, "Repeated combat produced incorrect health")
		table._inspect_card(table._card_node_for_instance(attacker.instance_id))
		await _settle()
		_expect_reused_resources("attack %d completion" % attack_index)
		var board_stats := table._card_node_for_instance(attacker.instance_id).get_node("Stats") as Label3D
		var preview_hp := table.inspector_card_face.find_child("HealthValue", true, false) as Label
		_expect(board_stats.text == "2 / %d" % (19 - attack_index), "Board stats did not publish combat health")
		_expect(preview_hp != null and preview_hp.text == str(19 - attack_index), "Inspector health differs from the board")
		for unused in range(2):
			table._refresh_action_panel()
			await _settle()
			_expect_reused_resources("repeated inspector refresh")

	if DisplayServer.get_name() != "headless":
		_expect(paint_draws == attack_paint_draws, "Attack camera impact regenerated retained room paint: %s -> %s" % [attack_paint_draws, paint_draws])
	var last_nodes: Array = table.card_layer.get_children()
	table._render_match()
	table.queue_free()
	await _settle()
	for old_node in last_nodes:
		_expect(not is_instance_valid(old_node), "Closing battle before retirement completed leaked an old render node")
	for failure in failures:
		push_error(failure)
	print("Battle rendering reuse smoke test: %d failures; native paint checks %s" % [failures.size(), "skipped (headless)" if DisplayServer.get_name() == "headless" else "enabled"])
	quit(0 if failures.is_empty() else 1)


func _expect_table_mapping(backdrop: Control, horizon_fraction: float) -> void:
	var layer := backdrop.get_node_or_null("TablePaint") as Node2D
	if layer == null:
		return
	var top := layer.position.y + 330.0 * layer.scale.y
	var bottom := layer.position.y + 1000.0 * layer.scale.y
	_expect(absf(top - backdrop.size.y * horizon_fraction) < 0.01, "Table paint top missed its projected horizon")
	_expect(absf(bottom - backdrop.size.y) < 0.01, "Table paint no longer reaches the screen bottom")
	_expect(absf(layer.scale.x * 1600.0 - backdrop.size.x) < 0.01, "Table paint no longer spans the screen width")


func _expect_reused_resources(context: String) -> void:
	for body in table.card_layer.find_children("CardBody", "MeshInstance3D", true, false):
		_expect(body.mesh == face_mesh or body.mesh == back_mesh, "%s recreated a card body Mesh" % context)


func _expect_retired_nodes_cleanup() -> void:
	var old_nodes: Array = []
	# Two updates can happen before the renderer presents a frame. Neither old
	# board may remain visible, and both generations must release after drawing.
	for unused in range(2):
		old_nodes.append_array(table.card_layer.get_children())
		table._render_match()
	for old_node in old_nodes:
		_expect(is_instance_valid(old_node), "A board refresh released old shader resources before replacement rendering")
		if is_instance_valid(old_node) and old_node is Node3D:
			_expect(not old_node.is_visible_in_tree(), "A retired render node remained visible beside its replacement")
	await _settle()
	for old_node in old_nodes:
		_expect(not is_instance_valid(old_node), "A retired render node survived after replacement rendering")
	_expect_reused_resources("two same-frame board refreshes")


func _count_paint_draw(layer_name: String) -> void:
	paint_draws[layer_name] = int(paint_draws[layer_name]) + 1


func _settle() -> void:
	for unused in range(4):
		await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
