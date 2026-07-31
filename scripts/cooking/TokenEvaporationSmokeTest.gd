extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const TOKEN_ID := "token_fresh_ingredient"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	_reset_battlefield(table)
	var returned_token := _add_token(table, "opponent", "prep")
	returned_token.spices = ["spice_sugar_glaze"]
	table._render_match()
	table.service.clear_animation_events(table.state)
	table.service._resolve_effects(
		table.state,
		"player",
		[{"type": "return_enemy_ingredient"}],
		{},
		int(returned_token.instance_id)
	)
	var return_events: Array = table.state.get("animation_events", [])
	_expect(table.state.opponent.prep.is_empty(), "A bounced token remained on the battlefield.")
	_expect(not table.state.opponent.hand.has(TOKEN_ID), "A bounced token became a real card in its owner's hand.")
	_expect(not table.state.opponent.discard.has(TOKEN_ID), "A bounced token entered its owner's discard pile.")
	_expect(table.state.opponent.discard.has("spice_sugar_glaze"), "A real Spice attached to a bounced token did not enter discard.")
	_expect(
		_has_evaporation_event(return_events, int(returned_token.instance_id), "hand"),
		"Returning a token to hand did not queue its evaporation event."
	)
	var evaporation_count_before := int(table.token_evaporation_animation_count)
	await table._drain_animation_event_queue()
	_expect(
		int(table.token_evaporation_animation_count) == evaporation_count_before + 1,
		"The Living Table did not play the token evaporation animation."
	)
	await process_frame
	_expect(
		table._card_node_for_instance(int(returned_token.instance_id)) == null,
		"The evaporated token still had a physical card on the Living Table."
	)

	_reset_battlefield(table)
	var plated_token := _add_token(table, "opponent", "plated")
	table._render_match()
	table.service.clear_animation_events(table.state)
	table.service._resolve_effects(
		table.state,
		"player",
		[{"type": "return_enemy_plated_unit"}],
		{},
		int(plated_token.instance_id)
	)
	_expect(
		table.state.opponent.plated.is_empty()
		and not table.state.opponent.hand.has(TOKEN_ID)
		and _has_evaporation_event(table.state.animation_events, int(plated_token.instance_id), "hand"),
		"Rolling Pin-style return effects did not evaporate a Plated token."
	)
	await table._drain_animation_event_queue()

	_reset_battlefield(table)
	var defeated_token := _add_token(table, "player", "plated")
	table._render_match()
	table.service.clear_animation_events(table.state)
	defeated_token.health = 0
	table.service._remove_defeated(table.state, "player")
	_expect(table.state.player.plated.is_empty(), "A defeated token remained on the battlefield.")
	_expect(not table.state.player.discard.has(TOKEN_ID), "A defeated token became a real card in the discard pile.")
	_expect(
		_has_evaporation_event(table.state.animation_events, int(defeated_token.instance_id), "discard"),
		"A token headed to discard did not queue its evaporation event."
	)
	await table._drain_animation_event_queue()

	_reset_battlefield(table)
	var sacrificed_token := _add_token(table, "player", "prep")
	var sacrifice_source: Dictionary = table.service._make_unit(
		table.state,
		table.state.player,
		table.service.card("fresh_sprout_squirrel"),
		"plated",
		"player"
	)
	table.state.player.plated.append(sacrifice_source)
	table.service.clear_animation_events(table.state)
	table.service._resolve_effects(
		table.state,
		"player",
		[{"type": "sacrifice_friendly_then_damage_all_enemy_units_by_attack"}],
		sacrifice_source,
		int(sacrificed_token.instance_id)
	)
	_expect(
		not table.state.player.discard.has(TOKEN_ID)
		and _has_replaced_evaporation_event(
			table.state.animation_events,
			int(sacrificed_token.instance_id),
			"sacrifice"
		),
		"A sacrificed token did not evaporate before reaching the discard pile."
	)

	_reset_battlefield(table)
	var normal_unit: Dictionary = table.service._make_unit(
		table.state,
		table.state.opponent,
		table.service.card("spicy_hot_honey_bee"),
		"plated",
		"opponent"
	)
	table.state.opponent.plated.append(normal_unit)
	table.service._resolve_effects(
		table.state,
		"player",
		[{"type": "return_enemy_plated_unit"}],
		{},
		int(normal_unit.instance_id)
	)
	_expect(
		table.state.opponent.hand.has("spicy_hot_honey_bee"),
		"A normal card stopped returning to its owner's hand."
	)
	_expect(
		not _has_event_type(table.state.animation_events, "evaporate"),
		"A normal card incorrectly used the token evaporation rule."
	)

	table.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Token evaporation smoke test passed.")
	quit()


func _reset_battlefield(table) -> void:
	for side in ["player", "opponent"]:
		table.state[side].hand = []
		table.state[side].deck = []
		table.state[side].discard = []
		table.state[side].prep = []
		table.state[side].plated = []
	table.state.phase = "player_main"
	table.state.game_over = false
	table.state.pending_choice = {}
	table.state.pending_reaction = {}
	table.service.clear_animation_events(table.state)


func _add_token(table, side: String, zone: String) -> Dictionary:
	var token: Dictionary = table.service._make_unit(
		table.state,
		table.state[side],
		table.service.card(TOKEN_ID),
		zone,
		side
	)
	token.table_slot = 0
	table.state[side][zone].append(token)
	return token


func _has_evaporation_event(events: Array, instance_id: int, destination: String) -> bool:
	for event_value in events:
		var event: Dictionary = event_value
		if (
			String(event.get("type", "")) == "evaporate"
			and int(event.get("instance_id", -1)) == instance_id
			and String(event.get("attempted_destination", "")) == destination
			and bool(event.get("is_token", false))
		):
			return true
	return false


func _has_event_type(events: Array, event_type: String) -> bool:
	for event_value in events:
		if String((event_value as Dictionary).get("type", "")) == event_type:
			return true
	return false


func _has_replaced_evaporation_event(events: Array, instance_id: int, replaced_type: String) -> bool:
	for event_value in events:
		var event: Dictionary = event_value
		if (
			String(event.get("type", "")) == "evaporate"
			and int(event.get("instance_id", -1)) == instance_id
			and String(event.get("replaced_event_type", "")) == replaced_type
		):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
