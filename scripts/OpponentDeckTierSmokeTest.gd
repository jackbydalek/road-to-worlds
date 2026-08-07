extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const AI_LEVELS := ["easy", "medium", "hard", "expert"]

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.ARCHETYPE_ORDER.has("fresh"), "Fresh was not added to the season opponent pool.")
	_expect(main.archetypes_by_id.has("fresh"), "Fresh does not have an authored opponent deck.")
	var spicy_starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run("spicy", spicy_starter, "hearty", "season", "white")
	_expect(float(main.run.get("meta", {}).get("fresh", 0.0)) > 0.0, "Fresh received no metagame share and could not be selected as a tournament opponent.")
	for level in AI_LEVELS:
		var fresh_deck: Dictionary = main._opponent_deck_for_round("fresh", 1, {}, level)
		_expect(_deck_total(fresh_deck) == 20, "The %s Fresh AI deck did not contain 20 cards." % level.capitalize())
		_expect(_all_cards_exist(main, fresh_deck), "The %s Fresh AI deck referenced a missing card." % level.capitalize())

	var sweet_expert: Dictionary = main._opponent_deck_for_round("sweet", 1, {}, "expert")
	_expect(
		int(sweet_expert.get("sweet_cinnamon_snail", 0)) == 3,
		"Expert Sweet did not finish with 3 Cinnamon Snails."
	)
	_expect(_deck_total(sweet_expert) == 20, "The Expert Sweet AI deck did not contain 20 cards.")

	main._release_audio_streams()
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Opponent deck tier smoke test passed: Fresh at all four levels and 3 Cinnamon Snails in Expert Sweet.")
	quit(0)


func _deck_total(deck: Dictionary) -> int:
	var total := 0
	for count in deck.values():
		total += int(count)
	return total


func _all_cards_exist(main, deck: Dictionary) -> bool:
	for card_id in deck:
		if not main.cards_by_id.has(String(card_id)):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
