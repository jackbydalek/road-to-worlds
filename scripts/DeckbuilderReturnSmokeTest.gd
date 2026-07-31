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

	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.get("starterDeck", []))
	main.run = main.run_state_service.create_run("spicy", starter, main._predator_archetype("spicy"), "season", "white")
	main._show_shop()
	await process_frame
	await process_frame

	var shop_world = main.find_child("CardShopOverworld", true, false)
	_expect(shop_world != null, "The return test could not open the card store.")
	var store_views := {
		"shopkeeper": "MenuPanel",
		"singles": "InSceneSinglesCase",
		"trade": "InSceneTradeBinder",
		"meta": "InSceneMetaAnalysis",
	}
	for view_value in store_views:
		var view := String(view_value)
		shop_world = main.find_child("CardShopOverworld", true, false)
		if shop_world == null:
			continue
		shop_world.restore_menu_view(view)
		var deck_button := main.find_child("ShopHudDeckButton", true, false) as Button
		_expect(deck_button != null, "The card-store HUD did not expose Deck Edit.")
		if deck_button != null:
			deck_button.emit_signal("pressed")
		await process_frame
		await process_frame
		main._show_deckbuilder()
		await process_frame
		await process_frame

		var back_button := _find_back_button(main)
		_expect(main.current_screen == "deck" and back_button != null, "Deck Edit did not open with a Back action.")
		if back_button != null:
			back_button.emit_signal("pressed")
		await process_frame
		await process_frame

		shop_world = main.find_child("CardShopOverworld", true, false)
		var restored_view := main.find_child(String(store_views[view]), true, false) as Control
		_expect(
			main.current_screen == "shop"
			and shop_world != null
			and restored_view != null
			and restored_view.visible,
			"Back from Deck Edit did not restore the originating %s menu." % view
		)

	main._show_season_run()
	await process_frame
	main._show_deckbuilder()
	await process_frame
	var back_button := _find_back_button(main)
	if back_button != null:
		back_button.emit_signal("pressed")
	await process_frame
	_expect(
		main.current_screen == "season" and main.find_child("SeasonCalendarMap", true, false) != null,
		"Back from Deck Edit did not restore the originating season menu."
	)

	if failed:
		quit(1)
		return
	print("Deckbuilder return smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _find_back_button(main) -> Button:
	for candidate in main.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.text == "Back":
			return button
	return null
