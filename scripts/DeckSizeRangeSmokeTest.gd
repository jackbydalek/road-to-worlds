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

	_expect(main.MAIN_DECK_SIZE == 20, "The legacy constructed starter size was not kept at 20.")
	_expect(main.MIN_MAIN_DECK_SIZE == 1, "The minimum main-deck size was not set to one.")
	_expect(main.MAX_MAIN_DECK_SIZE == 0, "The constructed deck did not use the unlimited-size sentinel.")
	_expect(main.run_state_service.main_deck_size == 1, "Run-state legality did not receive the one-card minimum.")
	_expect(main.run_state_service.max_main_deck_size == 0, "Run-state legality did not enable unlimited deck size.")

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
	_expect(_has_label_text(main, "MAIN DECK  21 CARDS • NO MAXIMUM"), "The Deck Workshop did not advertise unlimited deck size.")
	_expect(main.status_label.text.ends_with("Main 21"), "The top status bar still displayed a deck-size ceiling.")

	var deck_30: Dictionary = starter.duplicate(true)
	deck_30["item_tool_drawer"] = 3
	deck_30["item_wooden_spoon"] = 3
	deck_30["item_switchblade"] = 3
	deck_30["environment_spicy_taqueria"] = 1
	main.run.deck = deck_30
	main.run.collection = deck_30.duplicate(true)
	_expect(main._deck_total(main.run.deck) == 30, "The range test did not construct a 30-card deck.")
	_expect(bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)), "A 30-card deck was not tournament legal.")

	main.run.collection["environment_hearty_diner"] = 1
	var add_above_former_maximum: Dictionary = main.run_state_service.add_to_deck(main.run, "environment_hearty_diner")
	_expect(bool(add_above_former_maximum.get("ok", false)), "The deck service refused to add a card above the former 30-card maximum.")
	_expect(main._deck_total(main.run.deck) == 31, "The unlimited-size test did not construct a 31-card deck.")
	_expect(
		bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)),
		"A deck above the former 30-card maximum was not legal."
	)

	main.run.collection["item_tool_drawer"] = 4
	var add_fourth_copy: Dictionary = main.run_state_service.add_to_deck(main.run, "item_tool_drawer")
	_expect(bool(add_fourth_copy.get("ok", false)), "The deck service refused to add a fourth copy of one card.")
	_expect(int(main.run.deck["item_tool_drawer"]) == 4, "The copy-limit test did not construct four copies of one card.")
	_expect(
		bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)),
		"A deck containing more than three copies of one card was not legal."
	)

	var one_card_id := String(starter.keys()[0])
	main.run.deck = {one_card_id: 1}
	main.run.collection = {one_card_id: 1}
	_expect(
		bool(main.run_state_service.deck_is_legal(main.run).get("ok", false)),
		"A one-card deck was not legal."
	)

	main.run.deck = {}
	main.run.collection = {}
	var too_small: Dictionary = main.run_state_service.deck_is_legal(main.run)
	_expect(
		not bool(too_small.get("ok", true))
		and String(too_small.get("reason", "")).contains("at least 1"),
		"An empty deck was not rejected with the one-card minimum explanation."
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
