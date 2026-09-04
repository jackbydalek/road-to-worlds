extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const LAYOUT_PREVIEW_PATH := "/tmp/top-cut-deck-workshop-simplified.png"
const HOVER_PREVIEW_PATH := "/tmp/topdeck-to-worlds-deckbuilder-hover.png"
const KEYWORD_PREVIEW_PATH := "/tmp/topdeck-to-worlds-deckbuilder-keyword.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var full_starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	var starter: Dictionary = main.route_run_service.compact_starter_deck(full_starter, 15)
	main.run = main.run_state_service.create_run("spicy", starter, main._predator_archetype("spicy"), "season", "white")
	main.run.run_loop = "route"
	main.run.max_life = 40
	main.run.life = 40
	var upgraded_probe_id := String(starter.keys()[0])
	main.run["card_upgrades"] = {upgraded_probe_id: 1}
	main._show_deckbuilder()
	await process_frame
	await process_frame
	# The compatibility renderer can present one black frame while card-face
	# subviewports finish their first draw. Give the visual capture a settled
	# frame without changing the structural assertions below.
	await create_timer(0.12).timeout
	await process_frame

	var workspace := main.find_child("DeckbuilderWorkspace", true, false) as VBoxContainer
	var deck_grid := main.find_child("DeckbuilderMainDeckScrollGrid", true, false) as GridContainer
	var deck_card := main.find_child("DeckbuilderDeckCardBody", true, false) as Control
	var hover_preview := main.find_child("DeckbuilderHoverPreview", true, false) as PanelContainer
	var workshop_shell := main.find_child("DeckbuilderWorkshopShell", true, false) as PanelContainer
	var top_bar := main.find_child("DeckbuilderTopBar", true, false) as PanelContainer
	var back_button := main.find_child("DeckbuilderBackButton", true, false) as Button
	var deck_rail := main.find_child("DeckbuilderDeckRail", true, false) as VBoxContainer
	var rendered_cards := main.find_children("DeckbuilderDeckCardBody", "", true, false)
	_expect(workspace != null, "Deckbuilder did not render its active-deck workspace.")
	_expect(workshop_shell != null and workshop_shell.find_child("DeckbuilderAngularSurface", false, false) != null, "Deck Workshop did not use the dark angular chassis.")
	_expect(main.find_child("DeckbuilderCollectionPanel", true, false) == null, "Deck review still rendered the removed collection pane.")
	_expect(main.find_child("DeckbuilderHeader", true, false) == null, "Deck review still rendered the removed workshop summary header.")
	_expect(main.find_child("DeckbuilderSortAffinity", true, false) == null, "Deck review still rendered the removed sort controls.")
	_expect(deck_rail != null and deck_rail.size.x > 1200.0, "Active Deck did not expand to use the full screen width.")
	_expect(deck_grid != null and deck_grid.columns == 8, "Active Deck did not render its wide eight-column card grid at 1440 px.")
	_expect(rendered_cards.size() == main._deck_total(main.run.deck), "Active Deck did not render one tile per physical card copy.")
	_expect(main.find_child("DeckbuilderCardPreview", true, false) == null, "The old permanently reserved preview column is still present.")
	_expect(hover_preview != null and not hover_preview.visible, "Hover preview was not created in its hidden resting state.")
	_expect(deck_card != null and deck_card.tooltip_text == "", "Deck cards still exposed the redundant native tooltip.")
	_expect(top_bar != null and back_button != null and top_bar.is_ancestor_of(back_button), "Back navigation was not moved into the upper-left bar.")
	_expect(back_button != null and deck_rail != null and back_button.global_position.y < deck_rail.global_position.y, "Back navigation still appeared beneath the deck.")
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) == null, "Deck review still exposed the removed sideboard pane.")

	var duplicate_probe_id := ""
	for card_id_value in main.run.deck:
		if int(main.run.deck[card_id_value]) > 1:
			duplicate_probe_id = String(card_id_value)
			break
	var rendered_duplicate_count := 0
	for deck_card_candidate in rendered_cards:
		if String(deck_card_candidate.get_meta("card_id", "")) == duplicate_probe_id:
			rendered_duplicate_count += 1
	_expect(
		duplicate_probe_id != "" and rendered_duplicate_count == int(main.run.deck[duplicate_probe_id]),
		"A repeated card was collapsed into a quantity label instead of separate copies."
	)
	var found_quantity_label := false
	if deck_rail != null:
		for label_candidate in deck_rail.find_children("*", "Label", true, false):
			if String((label_candidate as Label).text).begins_with("×"):
				found_quantity_label = true
				break
	_expect(not found_quantity_label, "Active Deck still displayed an ×N quantity label.")

	var upgraded_deck_foil: Control = null
	for deck_card_candidate in rendered_cards:
		if String(deck_card_candidate.get_meta("card_id", "")) == upgraded_probe_id and int(deck_card_candidate.get_meta("copy_index", -1)) == 0:
			upgraded_deck_foil = deck_card_candidate.find_child("UpgradedCardFoil", true, false) as Control
			break
	_expect(upgraded_deck_foil != null and upgraded_deck_foil.visible, "An upgraded route card did not keep its foil finish in the Deck Workshop.")
	_save_preview(LAYOUT_PREVIEW_PATH)

	if deck_card != null:
		main.deckbuilder_screen._show_hover_preview(
			main,
			deck_card,
			String(deck_card.get_meta("card_id", "")),
			int(deck_card.get_meta("copy_index", -1))
		)
		await process_frame
		var preview_content := main.find_child("DeckbuilderHoverPreviewContent", true, false)
		var rendered_face: Control = preview_content.get_child(0) as Control if preview_content != null and preview_content.get_child_count() > 0 else null
		_expect(hover_preview.visible, "Hovering a deck card did not reveal the enlarged preview.")
		_expect(rendered_face != null and rendered_face.custom_minimum_size == Vector2(300, 426), "Hover preview did not use the enlarged readable card size.")
		_save_preview(HOVER_PREVIEW_PATH)
		deck_card.emit_signal("mouse_exited")
		await process_frame
		_expect(not hover_preview.visible, "Hover preview did not close when the pointer left the card.")

	var keyword_card: Control = null
	for candidate in rendered_cards:
		if String(candidate.get_meta("card_id", "")) == "spicy_wasabi_wasp":
			keyword_card = candidate as Control
			break
	_expect(keyword_card != null, "The layout test could not find Wastabi's Stalwart card.")
	if keyword_card != null:
		main.deckbuilder_screen._show_hover_preview(main, keyword_card, "spicy_wasabi_wasp", int(keyword_card.get_meta("copy_index", -1)))
		await process_frame
		_expect(main.find_child("DeckbuilderKeywordGlossary", true, false) != null, "A keyword card did not show the Deck Workshop glossary.")
		_expect(main.find_child("DeckbuilderKeyword_stalwart", true, false) != null, "The Stalwart explanation did not appear beside Wastabi.")
		_expect(hover_preview.custom_minimum_size.x == 594.0, "The keyword preview did not widen to place its explanation beside the card.")
		_expect(main.find_child("KeywordAccentBar", true, false) != null, "The keyword explanation did not include its semantic accent bar.")
		_save_preview(KEYWORD_PREVIEW_PATH)

	main.run.run_mode = "debug"
	main.run.run_loop = ""
	main._show_deckbuilder()
	await process_frame
	await process_frame
	_expect(main.find_child("DeckbuilderCollectionPanel", true, false) == null, "Debug Deck Workshop restored the removed collection pane.")
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) == null, "Debug Deck Workshop restored the removed sideboard pane.")
	_expect(main.find_child("DeckbuilderRemoveMainButton", true, false) != null, "Editable deck review lost its per-copy remove action.")

	main._release_audio_streams()
	await create_timer(0.12).timeout
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Deckbuilder layout smoke test passed.")
	quit()


func _save_preview(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var preview := root.get_texture().get_image()
	_expect(preview != null and preview.save_png(ProjectSettings.globalize_path(path)) == OK, "Could not save deckbuilder visual preview.")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
