extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._start_new_run("oxen")
	main._show_deckbuilder()
	await process_frame

	var preview_body := _find_named_node(main, "DeckbuilderCardPreviewBody")
	if preview_body == null:
		_fail("Deckbuilder hover smoke did not render preview body.")
		return

	var row := _find_card_row(main)
	if row == null:
		_fail("Deckbuilder hover smoke did not render a card row.")
		return

	var card_id := String(row.get_meta("card_id", ""))
	row.emit_signal("mouse_entered")
	await process_frame
	await process_frame

	var name_label := _find_named_node(preview_body, "DeckbuilderPreviewName")
	if name_label == null:
		_fail("Deckbuilder hover smoke did not render preview name.")
		return
	if String(name_label.text) != String(main.cards_by_id[card_id].name):
		_fail("Deckbuilder hover smoke preview name did not match hovered card.")
		return

	if _empty_named_label(preview_body, "DeckbuilderPreviewCombatStats"):
		_fail("Deckbuilder hover smoke did not render combat stats.")
		return
	if _empty_named_label(preview_body, "DeckbuilderPreviewDeckStats"):
		_fail("Deckbuilder hover smoke did not render deck stats.")
		return
	if _empty_named_label(preview_body, "DeckbuilderPreviewEffect"):
		_fail("Deckbuilder hover smoke did not render effect text.")
		return

	print("Deckbuilder hover smoke rendered card preview for " + String(main.cards_by_id[card_id].name) + ".")
	quit(0)


func _find_card_row(node: Node) -> Control:
	if node.name == "DeckbuilderCardRow" and node.has_meta("card_id"):
		return node as Control
	for child in node.get_children():
		var found := _find_card_row(child)
		if found != null:
			return found
	return null


func _find_named_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named_node(child, target_name)
		if found != null:
			return found
	return null


func _empty_named_label(node: Node, target_name: String) -> bool:
	var label := _find_named_node(node, target_name)
	return label == null or String(label.text) == ""


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
