extends "res://scripts/SplitMatsLiveHandSmokeTest.gd"

## Uses the real battle service, event queue and concealed scene nodes for the
## formerly painted hands. Mina's supplied-frame checks remain in its own suite.
func _run() -> void:
	for cast_id in ["pip", "milo", "bea"]:
		root.size = Vector2i(1280, 720)
		var table = await _make_table(true, cast_id)
		if table == null:
			quit(1)
			return
		await _check_live_hand_counts(table)
		await _check_service_hand_changes(table)
		if cast_id == "pip":
			await _check_grouped_cost_and_draw(table)
		await _dispose_table(table)
	print("CAST_LIVE_HAND_BATTLE_SMOKE_TEST_%s: three cast poses, authoritative state counts, real draw/play and grouped discard/draw; %d failures" % ["OK" if failures.is_empty() else "FAILED", failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_concealed_cards(table, count: int) -> void:
	var hand = _held(table)
	if not is_instance_valid(hand):
		return
	var cards := _concealed_cards(hand)
	_check(hand.held_count == count and cards.size() == count, "The visible held backs disagree with the actual hand of %d cards." % count)
	for card_back in cards:
		_check(card_back.texture == table.CARD_BACK, "The held fan shows a card face or unrelated sleeve.")
		_check(not card_back.has_meta("card_id"), "The held backs carry private identities.")
		_check(card_back.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Held-card drawing consumes pointer events.")
	if count > 0:
		_check(table.get_viewport_rect().encloses(hand.get_hand_global_rect()), "The live held fan is clipped at 1280x720.")
	_check(_visible_hand_count(table, "opponent") == 0, "Duplicate 3D backs remain visible behind the held cards.")
	_check(table.rival_hand_label.text == "%d card%s in hand" % [count, "" if count == 1 else "s"], "The exact count label disagrees with the visible sleeves.")
