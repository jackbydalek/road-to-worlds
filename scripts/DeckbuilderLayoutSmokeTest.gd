extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const LAYOUT_PREVIEW_PATH := "/tmp/road-to-worlds-deckbuilder-layout.png"
const HOVER_PREVIEW_PATH := "/tmp/road-to-worlds-deckbuilder-hover.png"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run("spicy", starter, main._predator_archetype("spicy"), "season", "white")
	main._show_deckbuilder()
	await process_frame
	await process_frame

	var workspace := main.find_child("DeckbuilderWorkspace", true, false)
	var collection_grid := main.find_child("DeckbuilderCollectionGrid", true, false) as GridContainer
	var deck_grid := main.find_child("DeckbuilderMainDeckScrollGrid", true, false) as GridContainer
	var collection_card := main.find_child("DeckbuilderCollectionCardBody", true, false) as Control
	var deck_card := main.find_child("DeckbuilderDeckCardBody", true, false) as Control
	var collection_summary := main.find_child("DeckbuilderCollectionSummary", true, false) as Label
	var metrics_summary := main.find_child("DeckbuilderMetricsSummary", true, false) as Label
	var hover_preview := main.find_child("DeckbuilderHoverPreview", true, false) as PanelContainer
	_expect(workspace != null, "Deckbuilder did not render the split collection-and-deck workspace.")
	_expect(collection_grid != null and collection_grid.columns == 4 and collection_grid.get_child_count() > 0, "Collection did not render as a four-column visual card grid.")
	_expect(deck_grid != null and deck_grid.columns == 3 and deck_grid.get_child_count() > 0, "Main deck did not render as a compact three-column card rail.")
	_expect(main.find_child("DeckbuilderCardPreview", true, false) == null, "The old permanently reserved preview column is still present.")
	_expect(hover_preview != null and not hover_preview.visible, "Hover preview was not created in its hidden resting state.")
	_expect(collection_card != null and collection_card.tooltip_text == "", "Collection cards still exposed the redundant native tooltip.")
	_expect(deck_card != null and deck_card.tooltip_text == "", "Deck cards still exposed the redundant native tooltip.")
	_expect(collection_summary != null and collection_summary.get_theme_color("font_color") == Color("#174f59"), "Collection summary text did not use the readable dark color.")
	_expect(metrics_summary != null and metrics_summary.get_theme_color("font_color") == Color("#5d5148"), "Deck metrics text did not use the readable dark color.")
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) == null, "Season Deck Workshop exposed debug-only sideboard controls.")
	_save_preview(LAYOUT_PREVIEW_PATH)

	if collection_card != null:
		main.deckbuilder_screen._show_hover_preview(main, collection_card, String(collection_card.get_meta("card_id", "")))
		await process_frame
		var preview_content := main.find_child("DeckbuilderHoverPreviewContent", true, false)
		var rendered_face: Control = preview_content.get_child(0) as Control if preview_content != null and preview_content.get_child_count() > 0 else null
		_expect(hover_preview.visible, "Hovering a collection card did not reveal the enlarged preview.")
		_expect(rendered_face != null and rendered_face.custom_minimum_size == Vector2(300, 426), "Hover preview did not use the enlarged readable card size.")
		_save_preview(HOVER_PREVIEW_PATH)
		collection_card.emit_signal("mouse_exited")
		await process_frame
		_expect(not hover_preview.visible, "Hover preview did not close when the pointer left the card.")

	var keyword_card: Control = null
	for candidate in main.find_children("DeckbuilderCollectionCardBody", "", true, false):
		if String(candidate.get_meta("card_id", "")) == "spicy_wasabi_wasp":
			keyword_card = candidate as Control
			break
	_expect(keyword_card != null, "The layout test could not find its Stalwart card.")
	if keyword_card != null:
		main.deckbuilder_screen._show_hover_preview(main, keyword_card, "spicy_wasabi_wasp")
		await process_frame
		_expect(main.find_child("DeckbuilderKeywordGlossary", true, false) != null, "A keyword card did not show the Deck Workshop glossary.")
		_expect(main.find_child("DeckbuilderKeyword_stalwart", true, false) != null, "The Stalwart explanation did not appear beside its card.")
		_expect(hover_preview.custom_minimum_size.x == 594.0, "The keyword preview did not widen to place its explanation beside the card.")

	main.run.run_mode = "debug"
	main._show_deckbuilder()
	await process_frame
	await process_frame
	_expect(main.find_child("DeckbuilderSideboardPanel", true, false) != null, "Debug Deck Workshop did not retain its Sideboard tab.")
	_expect(main.find_child("DeckbuilderAddSideButton", true, false) != null, "Debug Deck Workshop did not retain its add-to-sideboard actions.")

	if failed:
		quit(1)
		return
	print("Deckbuilder layout smoke test passed.")
	quit()


func _save_preview(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var preview := root.get_texture().get_image()
	_expect(preview != null and preview.save_png(path) == OK, "Could not save deckbuilder visual preview.")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
