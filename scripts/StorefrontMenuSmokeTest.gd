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

	var starter: Dictionary = main._deck_entries_to_dict(
		main.archetypes_by_id.spicy.get("starterDeck", [])
	)
	for event_id in main.tournaments_by_id:
		_expect(
			int(main.tournaments_by_id[event_id].get("entryFee", -1)) == 0,
			"%s still charged a tournament entry fee." % event_id
		)
	main.run = main.run_state_service.create_run(
		"spicy",
		starter,
		main._predator_archetype("spicy"),
		"season",
		"white"
	)
	main._generate_shop_inventory()
	main._show_shop_overworld()
	await process_frame
	await process_frame

	var shop_world = main.find_child("CardShopOverworld", true, false)
	_expect(shop_world != null, "The storefront menu test could not open the card store.")
	if shop_world == null:
		quit(1)
		return
	var top_bar := main.find_child("TopBar", true, false) as PanelContainer
	var cash_hud := main.find_child("ShopHudCashButton", true, false) as Button
	var autosave := main.find_child("AutosaveIndicator", true, false) as Label
	_expect(not main.header_bar.visible and not main.nav.visible, "The 3D store still reserved the persistent outer title or status row.")
	_expect(
		top_bar != null and top_bar.get_theme_stylebox("panel") is StyleBoxFlat,
		"The in-store top bar did not use the formal flat treatment."
	)
	_expect(
		cash_hud != null and cash_hud.get_theme_stylebox("normal") is StyleBoxFlat,
		"The store HUD controls still used the rough sketch treatment."
	)
	_expect(
		autosave != null and autosave.get_parent() == main and not autosave.visible,
		"The save indicator was not converted into an independent hidden glyph."
	)
	main._show_autosave_indicator()
	_expect(
		autosave != null
		and autosave.visible
		and autosave.text == "◆"
		and autosave.size.x <= 40.0,
		"Saving did not display the compact save glyph."
	)
	await create_timer(1.1).timeout
	_expect(autosave != null and not autosave.visible, "The save glyph did not clear after saving.")

	var round_button := main.find_child("StoreOverviewRoundButton", true, false) as Button
	_expect(
		round_button != null
		and round_button.visible
		and round_button.text == "Start Round 1"
		and "Register" in round_button.tooltip_text,
		"The store overview did not offer Start Round 1 before tournament registration."
	)
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame

	var menu_panel := shop_world.menu_panel as PanelContainer
	var menu_content := shop_world.menu_content as VBoxContainer
	var status := main.find_child("ShopkeeperStatus", true, false) as HBoxContainer
	var buy_section := _find_label(main, "BUY CARDS")
	var plan_section := _find_label(main, "PLAN YOUR WEEK")
	var separator := main.find_child("ShopkeeperExitSeparator", true, false) as HSeparator
	_expect(menu_panel != null and menu_panel.visible, "The cleaned storefront menu did not become visible.")
	_expect(menu_content != null and menu_content.get_theme_constant("separation") == 10, "The storefront menu did not use the intended compact vertical rhythm.")
	_expect(status != null and status.get_child_count() == 2, "The storefront menu did not separate cash and prize-pack status.")
	_expect(buy_section != null and plan_section != null and separator != null, "The storefront menu is missing its action grouping.")
	_expect(main.find_child("Tournament", true, false) == null, "The tournament action is still inside the shopkeeper menu.")
	_expect(round_button != null and not round_button.visible, "The Start Round CTA remained visible inside the shopkeeper menu.")

	var cash_status := shop_world.menu_cash_status_label as Label
	var prize_status := shop_world.menu_prize_status_label as Label
	_expect(cash_status != null and cash_status.text == "$%d cash" % int(main.run.money), "The storefront cash badge did not match the live balance.")
	_expect(prize_status != null and prize_status.text == "0 prize packs", "The storefront prize badge did not use clear pluralized copy.")

	var actions := [
		main.find_child("BuySingles", true, false) as Button,
		main.find_child("BuyPack", true, false) as Button,
		main.find_child("Meta", true, false) as Button,
		main.find_child("Calendar", true, false) as Button,
		main.find_child("Leave", true, false) as Button,
	]
	for button_value in actions:
		var button := button_value as Button
		_expect(
			button != null
			and button.custom_minimum_size.y >= 46.0
			and button.alignment == HORIZONTAL_ALIGNMENT_LEFT
			and button.get_theme_stylebox("normal") is StyleBoxFlat,
			"A storefront action did not use the cleaned, full-height menu treatment."
		)

	main.run.active_tournament = {
		"active": true,
		"event_id": "weekly_locals",
		"event_name": "Weekly Locals",
		"round": 2,
	}
	shop_world.overview_active = true
	shop_world.update_shop_context(main._shop_overworld_context())
	await process_frame
	_expect(
		round_button != null
		and round_button.visible
		and round_button.text == "Start Round 2"
		and round_button.custom_minimum_size.x >= 400.0
		and round_button.get_signal_connection_list("pressed").size() > 0,
		"The store overview did not expose a large, connected Start Round 2 action."
	)
	shop_world.call("_show_menu")
	_expect(round_button != null and not round_button.visible, "The Start Round CTA remained visible after zooming into the shopkeeper.")
	shop_world.call("_return_to_shopkeeper_menu")
	await process_frame

	var browse := actions[0] as Button
	if browse != null:
		browse.emit_signal("pressed")
	await process_frame
	var singles_case := main.find_child("InSceneSinglesCase", true, false) as PanelContainer
	_expect(singles_case != null and singles_case.visible, "The cleaned Browse Singles action no longer opened the in-store case.")

	main.run.active_tournament = {}
	main.run.money = 0
	var money_before_entry := int(main.run.money)
	main._on_shop_tournament_requested()
	await process_frame
	await process_frame
	_expect(
		main.current_screen == "kitchen_match"
		and main._season_tournament_active()
		and int(main.run.active_tournament.get("round", 0)) == 1,
		"Start Round 1 did not register and launch the selected tournament for free."
	)
	_expect(int(main.run.money) == money_before_entry, "Registering for the tournament changed the player's money.")
	_expect(
		int(main.run.active_tournament.get("entry_fee", -1)) == 0
		and "Entry was free." in String(main.run.active_tournament.get("logs", [""])[0]),
		"The active tournament did not record free registration."
	)

	if failed:
		quit(1)
		return
	print("Storefront menu smoke test passed.")
	quit()


func _find_label(root_node: Node, text: String) -> Label:
	for candidate in root_node.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label.text == text:
			return label
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
