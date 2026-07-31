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
	_expect(shop_world != null, "The in-store singles interaction test could not open the card store.")
	if shop_world == null:
		quit(1)
		return
	shop_world.call("_show_singles_case")
	await process_frame

	var singles_grid := main.find_child("InSceneSinglesGrid", true, false) as GridContainer
	var select_buttons := main.find_children("InSceneSingleSelect_*", "Button", true, false)
	var buy_buttons := main.find_children("BuyInScene_*", "Button", true, false)
	_expect(singles_grid != null and singles_grid.get_child_count() == 8, "The singles case did not show all eight live cards.")
	_expect(select_buttons.size() == 8, "Every single did not receive a card-selection target.")
	_expect(buy_buttons.size() == 8 and buy_buttons.all(func(button) -> bool: return not (button as Button).visible), "Buy buttons were visible before a card was selected.")

	if select_buttons.is_empty():
		quit(1)
		return
	var select_button := select_buttons[0] as Button
	var card_id := String(select_button.name).trim_prefix("InSceneSingleSelect_")
	var price: int = main._card_price(card_id)
	var money_before := int(main.run.money)
	var owned_before: int = main._owned_count(card_id)
	var shop_size_before: int = main.run.shop.size()

	select_button.emit_signal("pressed")
	await process_frame
	var selected_buy := main.find_child("BuyInScene_%s" % card_id, true, false) as Button
	var visible_buy_count := 0
	for button_value in main.find_children("BuyInScene_*", "Button", true, false):
		if (button_value as Button).visible:
			visible_buy_count += 1
	_expect(selected_buy != null and selected_buy.visible, "Selecting a card did not reveal its Buy button.")
	_expect(visible_buy_count == 1, "Selecting one card revealed more than one Buy button.")

	if selected_buy != null:
		selected_buy.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(int(main.run.money) == money_before - price, "Buying the selected single did not charge its sticker price.")
	_expect(main._owned_count(card_id) == owned_before + 1, "Buying the selected single did not add one owned copy.")
	_expect(main.run.shop.size() == shop_size_before - 1 and not main.run.shop.has(card_id), "Buying the selected single did not remove it from the live case.")

	if failed:
		quit(1)
		return
	print("Singles selection smoke test passed.")
	quit()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
