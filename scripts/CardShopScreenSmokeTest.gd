extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_new_run_with_mode("oxen", "debug", "white")
	await process_frame
	await process_frame

	if main.current_screen != "shop":
		_fail("Card shop smoke did not enter the Shop screen.")
		return

	for hotspot in [
		"CardShopStatusStrip",
		"CardShopSceneFrame",
		"CardShopSceneHost",
		"CardShopScene",
		"EventCalendarButton",
		"WalletButton",
		"DeckBoxButton",
		"MenuButton",
		"BoosterDisplayButton",
		"BoosterDisplayButton2",
		"TradeBindersButton",
		"TournamentPersonHotspot",
		"CardShopSinglesCounter"
	]:
		if _count_named_nodes(main, hotspot) == 0:
			_fail("Card shop smoke did not render hotspot: " + hotspot)
			return

	if not _has_button_text(main, "Scene Shop"):
		_fail("Card shop smoke did not render the debug Scene Shop nav button.")
		return

	if _count_named_nodes(main, "CardShopSingleTile_") == 0:
		_fail("Card shop smoke did not render any singles tiles.")
		return

	var booster_button := _find_node_by_name(main, "BoosterDisplayButton2") as Button
	if booster_button == null:
		_fail("Card shop smoke did not render the booster buy button.")
		return

	var register_button := _find_node_by_name(main, "TournamentPersonHotspot") as Button
	if register_button == null:
		_fail("Card shop smoke did not render the tournament clerk hotspot.")
		return

	var tournament_person := _find_node_by_name(main, "TournamentPersonHotspot") as Button
	if tournament_person == null:
		_fail("Card shop smoke did not render the clickable tournament person.")
		return
	tournament_person.emit_signal("mouse_entered")

	main.run.money = 200
	main._show_shop()
	await process_frame
	await process_frame

	var buy_button := _find_first_named_node(main, "CardShopSingleBuyButton_") as Button
	if buy_button == null:
		_fail("Card shop smoke did not render a single buy button.")
		return
	if buy_button.disabled:
		_fail("Card shop smoke rendered a single buy button disabled despite enough money.")
		return

	var card_id := String(buy_button.get_meta("card_id", ""))
	if card_id == "":
		_fail("Card shop smoke single buy button is missing card metadata.")
		return

	var price: int = main._card_price(card_id)
	var owned_before := int(main.run.collection.get(card_id, 0))
	buy_button.emit_signal("pressed")
	await process_frame
	await process_frame

	if int(main.run.collection.get(card_id, 0)) != owned_before + 1:
		_fail("Card shop smoke did not add bought single to the collection.")
		return
	if int(main.run.money) != 200 - price:
		_fail("Card shop smoke did not subtract the single price.")
		return

	print("Card shop smoke rendered the authored shop scene, debug nav, tournament person, and bought a single.")
	quit(0)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if String(node.name).begins_with(target_name) else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _find_first_named_node(node: Node, target_prefix: String) -> Node:
	if String(node.name).begins_with(target_prefix):
		return node
	for child in node.get_children():
		var found := _find_first_named_node(child, target_prefix)
		if found != null:
			return found
	return null


func _has_button_text(node: Node, text: String) -> bool:
	if node is Button and String((node as Button).text) == text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text):
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
