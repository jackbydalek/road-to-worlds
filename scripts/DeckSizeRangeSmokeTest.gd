extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.MAIN_DECK_SIZE == 20, "The starter/minimum deck size was not kept at 20.")
	_expect(main.MAX_MAIN_DECK_SIZE == 30, "The constructed-deck maximum was not set to 30.")
	_expect(main.run_state_service.main_deck_size == 20, "Run-state legality did not receive the 20-card minimum.")
	_expect(main.run_state_service.max_main_deck_size == 30, "Run-state legality did not receive the 30-card maximum.")

	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	_expect(main._deck_total(main.run.deck) == 20, "The Spicy starter no longer begins at exactly 20 cards.")
	_expect(bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)), "The untouched 20-card starter was not legal.")

	main.run.collection["item_tool_drawer"] = 1
	var add_result: Dictionary = main.run_state_service.add_to_deck(main.run, "item_tool_drawer")
	_expect(bool(add_result.get("ok", false)), "A newly acquired card could not be added directly to the 20-card starter.")
	_expect(main._deck_total(main.run.deck) == 21, "Adding a card to the starter did not produce a 21-card deck.")
	_expect(bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)), "A 21-card deck was not tournament legal.")

	main._show_deckbuilder()
	await process_frame
	await process_frame
	_expect(_has_label_text(main, "MAIN DECK  21/30"), "The Deck Workshop did not display its 30-card capacity.")
	_expect(main.status_label.text.ends_with("Main 21/30"), "The top status bar did not display the 30-card capacity.")

	var deck_30: Dictionary = starter.duplicate(true)
	deck_30["item_tool_drawer"] = 3
	deck_30["item_wooden_spoon"] = 3
	deck_30["item_switchblade"] = 3
	deck_30["environment_spicy_taqueria"] = 1
	main.run.deck = deck_30
	main.run.collection = deck_30.duplicate(true)
	_expect(main._deck_total(main.run.deck) == 30, "The range test did not construct a 30-card deck.")
	_expect(bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)), "A 30-card deck was not tournament legal.")

	var deck_31: Dictionary = deck_30.duplicate(true)
	deck_31["environment_hearty_diner"] = 1
	main.run.deck = deck_31
	main.run.collection = deck_31.duplicate(true)
	var too_large: Dictionary = main.run_state_service.deck_is_legal(main.run)
	_expect(
		not bool(too_large.get("ok", true))
		and String(too_large.get("reason", "")).contains("more than 30"),
		"A 31-card deck was not rejected with the maximum-size explanation."
	)

	var deck_19: Dictionary = starter.duplicate(true)
	var reduced_card_id := String(deck_19.keys()[0])
	deck_19[reduced_card_id] = int(deck_19[reduced_card_id]) - 1
	if int(deck_19[reduced_card_id]) <= 0:
		deck_19.erase(reduced_card_id)
	main.run.deck = deck_19
	main.run.collection = starter.duplicate(true)
	var too_small: Dictionary = main.run_state_service.deck_is_legal(main.run)
	_expect(
		not bool(too_small.get("ok", true))
		and String(too_small.get("reason", "")).contains("at least 20"),
		"A 19-card deck was not rejected with the minimum-size explanation."
	)

	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Deck size range smoke test passed.")
	quit()


func _has_label_text(parent: Node, expected: String) -> bool:
	for candidate in parent.find_children("*", "Label", true, false):
		if String((candidate as Label).text) == expected:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
