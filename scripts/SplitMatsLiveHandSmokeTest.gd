extends "res://scripts/SuppliedMinaSmokeTest.gd"

## Exercises split physical cloth and Mina's live concealed cards using the
## production battle/service. No save writes or source-image changes.
var split_cases: Array[String] = []


func _run() -> void:
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = output_size
		var table = await _make_table(false, "mina")
		if table == null:
			quit(1)
			return
		_check_split_mats(table)
		_check_scene_and_slots(table)
		_check_mina_catalog_and_placement(table)
		await _check_live_hand_counts(table)
		await _check_service_hand_changes(table)
		await _check_grouped_cost_and_draw(table)
		await _check_live_hand_targets(table)
		await _dispose_table(table)
	_check(split_cases.size() == 10, "Some split-mat/live-hand cases did not finish: " + str(split_cases))
	print("SPLIT_MATS_LIVE_HAND_SMOKE_TEST_%s: %d completed cases; %d failures" % ["OK" if failures.is_empty() else "FAILED", split_cases.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_split_mats(table) -> void:
	var far_mat := table.find_child("InsetPlaymat", true, false) as MeshInstance3D
	var near_mat := table.find_child("PlayerPlaymat", true, false) as MeshInstance3D
	_check(far_mat != null and near_mat != null and far_mat != near_mat, "Battle does not contain two separate physical playmats.")
	if far_mat == null or near_mat == null:
		return
	var far_outline: PackedVector2Array = far_mat.get_meta("playmat_outline", PackedVector2Array())
	var near_outline: PackedVector2Array = near_mat.get_meta("playmat_outline", PackedVector2Array())
	_check(far_outline.size() >= 4 and near_outline.size() >= 4, "Physical playmat outlines are unavailable.")
	if far_outline.size() < 4 or near_outline.size() < 4:
		return
	_check(far_mat.get_meta("playmat_side", "") == "opponent" and near_mat.get_meta("playmat_side", "") == "player", "The mats do not belong to their respective sides.")
	_check(Geometry2D.intersect_polygons(far_outline, near_outline).is_empty(), "The physical mats overlap instead of exposing table between them.")
	var far_center_edge := _edge_at_center(far_outline, true)
	var near_center_edge := _edge_at_center(near_outline, false)
	_check(near_center_edge - far_center_edge >= 0.20, "The center table gap is too narrow to read as two mats.")
	var gap_center := Vector2(0, (far_center_edge + near_center_edge) * 0.5)
	_check(not Geometry2D.is_point_in_polygon(gap_center, far_outline) and not Geometry2D.is_point_in_polygon(gap_center, near_outline), "The center table strip is still covered by cloth.")
	var far_screen: Vector2 = table._world_to_container(Vector3(0, 0.20, far_center_edge))
	var near_screen: Vector2 = table._world_to_container(Vector3(0, 0.20, near_center_edge))
	_check(near_screen.y - far_screen.y >= 4.0, "The actual camera hides the gap between the two mats.")
	for side in ["player", "opponent"]:
		var outline: PackedVector2Array = near_outline if side == "player" else far_outline
		for zone in ["prep", "plated"]:
			var capacity := 3 if zone == "prep" else 2
			var card_scale: float = table.PLATED_CARD_SCALE if zone == "plated" else 1.0
			var half_size: Vector2 = table.FIELD_CARD_SIZE * Vector2(1, 0.78) * card_scale * 0.5
			for slot in range(capacity):
				var point: Vector3 = table._slot_world_position(side + "_" + zone, slot)
				_check_footprint(outline, Vector2(point.x, point.z), half_size, "%s %s slot %d" % [side, zone, slot])
		for pile in ["deck", "discard", "environment"]:
			var point: Vector3 = table.AUX_ZONE_POSITIONS[side + "_" + pile]
			var half_size: Vector2 = table.FIELD_CARD_SIZE * table._auxiliary_card_scale() * 0.5
			_check_footprint(outline, Vector2(point.x, point.z), half_size, side + " " + pile)
			var printed_half_size: Vector2 = (table.FIELD_CARD_SIZE + Vector2(0.20, 0.12)) * 0.5
			_check_footprint(outline, Vector2(point.x, point.z), printed_half_size, side + " " + pile + " printed tray")
	split_cases.append("split-mats-" + str(root.size))


func _edge_at_center(outline: PackedVector2Array, near_edge: bool) -> float:
	var intersections: Array[float] = []
	for index in range(outline.size()):
		var first := outline[index]
		var second := outline[(index + 1) % outline.size()]
		if minf(first.x, second.x) <= 0 and maxf(first.x, second.x) >= 0 and not is_equal_approx(first.x, second.x):
			intersections.append(lerpf(first.y, second.y, -first.x / (second.x - first.x)))
	_check(intersections.size() >= 2, "A playmat has no physical edge across table center.")
	if intersections.is_empty():
		return 0
	return intersections.max() if near_edge else intersections.min()


func _check_footprint(outline: PackedVector2Array, center: Vector2, half_size: Vector2, description: String) -> void:
	for x in [-1.0, 0.0, 1.0]:
		for y in [-1.0, 0.0, 1.0]:
			_check(Geometry2D.is_point_in_polygon(center + half_size * Vector2(x, y), outline), description + " extends outside its owner's physical mat.")


func _hand_for_count(count: int) -> Array:
	var hand: Array = []
	var choices := ["hearty_bagver", "sweet_caramel_camel", "item_wooden_spoon", "sweet_jellyfish", "sweet_soft_serve_crab"]
	for index in range(count):
		hand.append(choices[index % choices.size()])
	return hand


func _held(table):
	var hand = table.get("rival_held_cards")
	_check(is_instance_valid(hand), "Mina has no live held-card presentation.")
	return hand


func _concealed_cards(hand) -> Array[TextureRect]:
	var cards: Array[TextureRect] = []
	for node in hand.find_children("*", "TextureRect", true, false):
		if bool(node.get_meta("concealed", false)) and not node.is_queued_for_deletion() and node.is_visible_in_tree():
			cards.append(node as TextureRect)
	return cards


func _check_concealed_cards(table, count: int) -> void:
	var hand = _held(table)
	if not is_instance_valid(hand):
		return
	var cards := _concealed_cards(hand)
	_check(hand.held_count == count and cards.size() == count, "Mina's visible card backs disagree with the actual hand of %d cards." % count)
	for card_back in cards:
		_check(card_back.texture != null and card_back.texture.resource_path == table.CARD_BACK.resource_path, "Mina's concealed hand shows a card face or unrelated texture.")
		_check(not card_back.has_meta("card_id"), "Mina's held backs carry private card identities into their visual nodes.")
		_check(card_back.mouse_filter == Control.MOUSE_FILTER_IGNORE, "A held-card drawing consumes battle pointer events.")
	if count > 0:
		var rect: Rect2 = hand.get_hand_global_rect()
		_check(rect.has_area() and table.get_viewport_rect().encloses(rect), "Mina's live hand is clipped or has no visible bounds.")
		var actor: TextureRect = table.rival_at_table
		var source_scale: Vector2 = actor.size / CAST.canvas_for("mina")
		var resting_hand := Rect2(actor.global_position + Vector2(430, 520) * source_scale, Vector2(190, 104) * source_scale)
		_check(resting_hand.grow(2.0).has_point(hand.get_grip_global()) and resting_hand.intersects(rect), "The live cards are not held in Mina's supplied free/resting hand.")
	else:
		_check(cards.is_empty(), "Empty hand leaves phantom card backs.")
	_check(_visible_hand_count(table, "opponent") == 0, "Duplicate 3D hand backs are visible behind Mina's held cards.")
	_check(table.rival_hand_label.text == "%d card%s in hand" % [count, "" if count == 1 else "s"], "Mina's settled count label disagrees with the live cards.")


func _check_live_hand_counts(table) -> void:
	table.configure_battle_preferences("fast", 1.0, true, false)
	for count in [0, 1, 3, 5, 12, 0]:
		table.service.clear_animation_events(table.state)
		table.state.opponent.hand = _hand_for_count(count)
		table._render_match()
		await _settle()
		_check_concealed_cards(table, count)
		var hand = _held(table)
		if not is_instance_valid(hand):
			return
		_check(not hand.is_animating(), "Reduced-motion hand-size change did not snap immediately.")
		table._render_match()
		await _settle()
		_check_concealed_cards(table, count)
	split_cases.append("hand-counts-" + str(root.size))


func _check_service_hand_changes(table) -> void:
	table.state.phase = "opponent_turn"
	table.state.opponent.prep = []
	table.state.opponent.hand = _hand_for_count(3)
	table.state.opponent.deck = ["sweet_sugar_glider"]
	table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon"]
	table.service.clear_animation_events(table.state)
	table.configure_battle_preferences("normal", 1.0, false, false)
	table._render_match()
	await _settle()
	var hand = _held(table)
	if not is_instance_valid(hand):
		return
	_check_concealed_cards(table, 3)
	table.service._draw(table.state, "opponent")
	_check(table.state.opponent.hand.size() == 4, "The real service did not draw the fixture card.")
	var draw_status := {"done": false}
	call("_drain_and_mark", table, draw_status)
	await create_timer(0.075).timeout
	_check(hand.is_animating(), "A real opponent draw does not animate into Mina's hand.")
	await _wait_for_drain(draw_status)
	_check_concealed_cards(table, 4)
	table.service.clear_animation_events(table.state)
	var played: bool = table.service._play_ingredient(table.state, "opponent", 0, "prep")
	_check(played and table.state.opponent.hand.size() == 3, "The real service did not play one held Ingredient.")
	var play_status := {"done": false}
	call("_drain_and_mark", table, play_status)
	await create_timer(0.075).timeout
	_check(hand.is_animating(), "A real opponent play does not leave Mina's held hand.")
	await _wait_for_drain(play_status)
	_check_concealed_cards(table, 3)
	_check(not table.state.opponent.prep.is_empty(), "The played card never reached the opposing Prep zone.")
	# With reduced motion, the same service-driven draw updates the held backs
	# immediately while the gameplay animation queue completes normally.
	table.configure_battle_preferences("fast", 1.0, true, false)
	table.state.opponent.deck = ["sweet_sugar_glider"]
	table.service._draw(table.state, "opponent")
	var reduced_status := {"done": false}
	call("_drain_and_mark", table, reduced_status)
	await _settle()
	_check(not hand.is_animating(), "A reduced-motion draw still animates the held cards.")
	await _wait_for_drain(reduced_status)
	_check_concealed_cards(table, 4)
	split_cases.append("service-hand-changes-" + str(root.size))


func _check_grouped_cost_and_draw(table) -> void:
	# The real Beet Beetle play consumes itself and one discard-cost card,
	# then draws a replacement. Final reconciliation alone cannot prove that
	# the outgoing cost card finished before the incoming card started.
	table.state.phase = "opponent_turn"
	table.state.opponent.prep = []
	table.state.opponent.discard = []
	table.state.opponent.hand = ["funky_beat_beetle", "spicy_hot_honey_bee", "spicy_hot_honey_bee"]
	table.state.opponent.deck = ["spicy_hot_honey_bee", "spicy_hot_honey_bee"]
	table.state.player.hand = ["spicy_wasabi_wasp", "item_wooden_spoon"]
	table.service.clear_animation_events(table.state)
	table.configure_battle_preferences("normal", 1.0, false, false)
	table._render_match()
	await _settle()
	var hand = _held(table)
	if not is_instance_valid(hand):
		return
	_check_concealed_cards(table, 3)
	var played: bool = table.service._play_ingredient(table.state, "opponent", 0, "prep")
	_check(played and table.state.opponent.hand.size() == 2 and table.state.opponent.discard.size() == 1, "Beet Beetle did not pay one discard cost and draw its replacement.")
	var status := {"done": false}
	var observed_play_cards: Dictionary = {}
	var observed_draw_cards: Dictionary = {}
	var overlapping_flights := false
	var minimum_held := 3
	call("_drain_and_mark", table, status)
	for step in range(1000):
		var has_play := false
		var has_draw := false
		for flight in hand.get("_flights"):
			var flight_card: TextureRect = flight.get("card")
			if String(flight.get("kind", "")) == "play":
				has_play = true
				observed_play_cards[flight_card.get_instance_id()] = true
			elif String(flight.get("kind", "")) == "draw":
				has_draw = true
				observed_draw_cards[flight_card.get_instance_id()] = true
		minimum_held = mini(minimum_held, int(hand.held_count))
		overlapping_flights = overlapping_flights or (has_play and has_draw)
		if bool(status.done):
			break
		await create_timer(0.01).timeout
	_check(bool(status.done), "The grouped Beet Beetle event drain did not finish.")
	_check(not overlapping_flights, "Beet Beetle's replacement draw starts while its discard-cost back is still leaving Mina's hand.")
	_check(observed_play_cards.size() == 2 and observed_draw_cards.size() == 1, "Beet Beetle did not visibly remove both paid cards and draw exactly one new back.")
	_check(minimum_held == 1, "Beet Beetle's held count never reflects both outgoing cards before its draw.")
	await _settle()
	_check_concealed_cards(table, 2)
	_check(not hand.is_animating(), "Beet Beetle leaves a held-card flight active after the event drain.")
	split_cases.append("grouped-cost-and-draw-" + str(root.size))


func _drain_and_mark(table, status: Dictionary) -> void:
	await table._drain_animation_event_queue()
	table._render_match()
	status.done = true


func _wait_for_drain(status: Dictionary) -> void:
	for step in range(150):
		if bool(status.done):
			await _settle()
			return
		await create_timer(0.02).timeout
	_check(false, "The actual battle draw/play event queue did not finish.")


func _fan_point(table) -> Vector2:
	var rect: Rect2 = table.rival_held_cards.get_hand_global_rect()
	return table.viewport_container.get_global_transform_with_canvas().affine_inverse() * rect.get_center()


func _check_live_hand_targets(table) -> void:
	await _check_mina_targeting(table)
	var attacker := _unit(table, "player", "spicy_hot_honey_bee", "plated", 1)
	var blocker := _unit(table, "opponent", "hearty_bagver", "plated", 1)
	_stage_attack(table, attacker, [blocker], _hand_for_count(3))
	await _select_attacker(table, attacker)
	var target := _fan_point(table)
	_check(table._screen_hits_opponent_hand(target), "The visible held-card fan is not a live hand target.")
	_check(table._pick_card(target) == null, "Hidden 3D cards intercept the visible fan target.")
	var before := int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(target))
	await _settle()
	_check(int(table.state.opponent.life) == before and "clear all opposing Plated cards" in String(table.state.message), "Clicking the live fan bypasses normal Plated blockers.")
	table._dismiss_invalid_action()
	_stage_attack(table, attacker, [], _hand_for_count(1))
	await _select_attacker(table, attacker)
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(_fan_point(table)))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(attacker.attack), "A valid live-fan click does not resolve a direct attack.")
	var stalwart := _unit(table, "player", "spicy_wasabi_wasp", "plated", 1)
	_stage_attack(table, stalwart, [blocker], _hand_for_count(3))
	await _select_attacker(table, stalwart)
	before = int(table.state.opponent.life)
	table._on_table_gui_input(_left_click(_fan_point(table)))
	await _wait_for_attack(table)
	_check(int(table.state.opponent.life) == before - int(stalwart.attack), "The live fan breaks Stalwart's legal direct attack through blockers.")
	_stage_attack(table, attacker, [], [])
	await _settle()
	_check_concealed_cards(table, 0)
	_check(table._screen_hits_opponent_chef(_actor_point(table)), "Clearing the fan removes Mina's empty-handed face target.")
	split_cases.append("live-hand-targets-" + str(root.size))
