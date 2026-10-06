extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PREVIEW_PATH := "/tmp/topdeck-to-worlds-draft-menu.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.current_screen == "start", "The game did not open on the start screen.")
	_expect(main.find_child("GameStartButton", true, false) is Button, "The boot landing did not offer New Game.")
	_expect(main.find_child("ContinueRunButton", true, false) is Button, "The boot landing did not own the Continue action.")
	# Draft is a retained mode; the active campaign selection offers three starters.
	main.autosave_enabled = false
	main.rng.seed = 20260725
	main._begin_draft("silver")
	await process_frame
	await process_frame

	_expect(main.current_screen == "draft", "Starting a draft did not open the draft screen.")
	var draft_scene := main.find_child("DraftWorkspaceScreen", true, false) as Control
	_expect(draft_scene != null, "The shared draft workspace is missing.")
	var back := main.find_child("DraftBackButton", true, false) as Control
	_expect(back != null and root.get_visible_rect().encloses(back.get_global_rect()), "Draft Back is clipped.")
	_expect(not main.footer_label.visible and not main.scroll.get_h_scroll_bar().visible, "Draft adds redundant chrome or horizontal scrolling.")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var preview := root.get_texture().get_image()
		_expect(preview != null and preview.save_png(PREVIEW_PATH) == OK, "The draft workspace preview could not be captured.")
	_expect(main.draft_offer.size() == main.DRAFT_OFFER_SIZE, "The opening draft offer did not contain three cards.")
	_expect(main.find_child("DraftOfferRow", true, false) != null, "The opening draft offer was not rendered.")
	var offered_panel := _find_live(main, "DraftOffer_%s" % String(main.draft_offer[0])) as Control
	_expect(offered_panel != null, "The first draft offer card was not rendered.")
	if offered_panel != null:
		var face := offered_panel.get_child(0) as Control
		_expect(face.has_meta("shared_inspection_bound"), "Draft choices do not use common inspection.")
		_expect(root.get_visible_rect().encloses(offered_panel.get_global_rect()), "A draft choice is clipped.")

	var opening_pairs := {}
	for card_id_value in main.draft_offer:
		var card_id := String(card_id_value)
		var card: Dictionary = main.cards_by_id.get(card_id, {})
		var card_archetypes: Array = card.get("archetypes", [])
		_expect(String(card.get("card_type", "")) == "meal", "An opening signpost was not a Meal: %s." % card_id)
		_expect(card_archetypes.size() == 2, "An opening signpost was not dual type: %s." % card_id)
		if card_archetypes.size() == 2:
			var pair: Array[String] = [String(card_archetypes[0]), String(card_archetypes[1])]
			pair.sort()
			opening_pairs["|".join(pair)] = true
	_expect(opening_pairs.size() == main.DRAFT_OFFER_SIZE, "The three opening signposts did not represent different dual-type pairs.")

	var opening_pick := String(main.draft_offer[0])
	main._draft_pick(opening_pick)
	await process_frame
	await process_frame
	var review := _find_live(main, "ViewDraftedCardsButton") as Button
	_expect(review != null and review.text.contains("1/20"), "Draft count did not update after the pick.")
	main._show_drafted_cards_menu()
	await process_frame
	await process_frame
	var draft_grid := main.find_child("DraftedCardsGrid", true, false) as GridContainer
	_expect(draft_grid != null and draft_grid.get_child_count() == 1, "Draft review did not include the selected card.")
	main._close_drafted_cards_menu()
	await process_frame
	var active_draft_deck: Dictionary = main.draft_deck.duplicate(true)
	main.draft_deck = {
		"chef_mary": 1,
		"fresh_sprout_squirrel": 1,
		"hearty_macaroni_manatee": 1,
		"spicy_hot_honey_bee": 1,
	}
	var type_sorted: Array[Dictionary] = main._draft_summary_entries(main.DRAFT_SORT_TYPE)
	var affinity_sorted: Array[Dictionary] = main._draft_summary_entries(main.DRAFT_SORT_AFFINITY)
	_expect(
		type_sorted.map(func(entry): return String(entry.id)) == ["chef_mary", "fresh_sprout_squirrel", "hearty_macaroni_manatee", "spicy_hot_honey_bee"],
		"Card Type sorting did not group the drafted cards by type."
	)
	_expect(
		affinity_sorted.map(func(entry): return String(entry.id)) == ["fresh_sprout_squirrel", "hearty_macaroni_manatee", "chef_mary", "spicy_hot_honey_bee"],
		"Affinity sorting did not group the drafted cards by color affiliation."
	)
	main.draft_deck = active_draft_deck

	while main.current_screen == "draft":
		_expect(main.draft_offer.size() == main.DRAFT_OFFER_SIZE, "A draft pick did not offer three cards.")
		var unique_offer := {}
		for offered_id in main.draft_offer:
			unique_offer[String(offered_id)] = true
		_expect(unique_offer.size() == main.DRAFT_OFFER_SIZE, "A draft offer contained duplicate choices.")
		main._draft_pick(String(main.draft_offer[0]))
		await process_frame
		await process_frame

	_expect(bool(main.run.get("drafted", false)), "Completing the draft did not mark the run as drafted.")
	_expect(String(main.run.get("run_mode", "")) == "season", "The drafted deck did not start a Season Run.")
	_expect(String(main.run.get("difficulty", "")) == "silver", "The drafted run did not preserve the selected season border.")
	_expect(main._deck_total(main.run.get("deck", {})) == main.DRAFT_DECK_SIZE, "The drafted starting deck did not contain exactly 20 cards.")
	_expect(main.run.get("deck", {}) == main.run.get("collection", {}), "The drafted collection did not exactly match the drafted deck.")
	_expect(main.run.get("draft_picks", []).size() == main.DRAFT_DECK_SIZE, "The run did not preserve all 20 draft picks.")
	_expect(main.current_screen == "shop", "Completing the draft did not continue to the card shop.")
	_expect(main._deck_limit("spicy_hot_honey_bee") == 0, "The draft catalog did not use the unlimited-copy sentinel.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	for unused_frame in range(4):
		await process_frame
	if failed:
		quit(1)
	else:
		print("Draft mode smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _find_live(parent: Node, node_name: String) -> Node:
	for candidate in parent.find_children(node_name, "", true, false):
		if not candidate.is_queued_for_deletion():
			return candidate
	return null


func _find_live_button_by_text(parent: Node, button_text: String) -> Button:
	for candidate in parent.find_children("*", "Button", true, false):
		if not candidate.is_queued_for_deletion() and String(candidate.text) == button_text:
			return candidate as Button
	return null
