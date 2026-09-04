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
	var singles_case := main.find_child("InSceneSinglesCase", true, false) as PanelContainer
	var singles_actions := main.find_child("InSceneSinglesActions", true, false) as Control
	var select_buttons := main.find_children("InSceneSingleSelect_*", "Button", true, false)
	var buy_buttons := main.find_children("BuyInScene_*", "Button", true, false)
	_expect(singles_grid != null and singles_grid.get_child_count() == 8, "The singles case did not show all eight live cards.")
	_expect(select_buttons.size() == 8, "Every single did not receive a card-selection target.")
	_expect(buy_buttons.size() == 8 and buy_buttons.all(func(button) -> bool: return not (button as Button).visible), "Buy buttons were visible before a card was selected.")
	var price_stickers := main.find_children("SinglesPriceBadge", "PanelContainer", true, false)
	_expect(price_stickers.size() == 8, "The illustrated singles case did not give every card a price sticker.")
	for price_sticker_value in price_stickers:
		var price_sticker := price_sticker_value as PanelContainer
		var sticker_style := price_sticker.get_theme_stylebox("panel") as StyleBoxFlat
		_expect(
			sticker_style != null
			and is_equal_approx(sticker_style.bg_color.a, 1.0)
			and sticker_style.corner_radius_top_left <= 2,
			"A singles price marker reverted to a translucent pill instead of an opaque square sticker."
		)
	var case_style := singles_case.get_theme_stylebox("panel") as StyleBoxFlat if singles_case != null else null
	_expect(
		case_style != null
		and case_style.border_color.is_equal_approx(Color("#29365F"))
		and case_style.border_width_left >= 2
		and case_style.corner_radius_top_left >= 14,
		"The singles case lost its cream-and-navy illustrated frame."
	)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900)]:
		root.size = viewport_size
		await process_frame
		shop_world.call("_layout_singles_panel")
		await process_frame
		_expect(
			singles_case != null
			and singles_actions != null
			and singles_case.get_global_rect().encloses(singles_actions.get_global_rect()),
			"The singles-case navigation extends outside %dx%d." % [viewport_size.x, viewport_size.y]
		)

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
