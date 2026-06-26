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

	main._show_packs()
	await process_frame
	await process_frame

	if main.current_screen != "packs":
		_fail("Pack opening smoke did not enter the Packs screen.")
		return

	var pack_button := _find_node_by_name(main, "PackButton") as TextureButton
	if pack_button == null:
		_fail("Pack opening smoke did not render PackButton.")
		return
	var pack_art := _find_node_by_name(main, "Untitled") as Sprite2D
	if pack_art == null or pack_art.texture == null:
		_fail("Pack opening smoke did not find the pack art.")
		return
	var art_size := pack_art.texture.get_size() * pack_art.scale.abs()
	var art_rect := Rect2(pack_art.global_position - art_size * 0.5, art_size)
	if not pack_button.get_global_rect().grow(1.0).encloses(art_rect):
		_fail("Pack opening smoke left part of the visible pack outside the click hitbox.")
		return

	pack_button.emit_signal("pressed")
	await process_frame
	await process_frame

	if main.run.get("current_pack", []).is_empty():
		_fail("Pack opening smoke did not buy/start a pack from PackButton.")
		return
	if main.run.current_pack.size() != 6:
		_fail("Pack opening smoke did not open a 6-card paid booster.")
		return
	if not bool(main.run.get("pack_opened", false)):
		_fail("Pack opening smoke did not open the pack on the first click.")
		return
	await create_timer(0.45).timeout

	var first_slot := _find_node_by_name(main, "PackCardSlot0") as TextureButton
	if first_slot == null or not first_slot.visible:
		_fail("Pack opening smoke did not show face-down card slots.")
		return

	var high_index := _first_high_rarity_index(main.run.get("current_pack", []))
	if high_index < 0:
		_fail("Pack opening smoke could not find a rare or mythic in the pack.")
		return

	var card_id := String(main.run.current_pack[high_index].get("cardId", ""))
	var owned_before := int(main.run.collection.get(card_id, 0))
	var slot := _find_node_by_name(main, "PackCardSlot%d" % high_index) as TextureButton
	if slot == null:
		_fail("Pack opening smoke did not find the high-rarity slot.")
		return

	slot.emit_signal("pressed")
	await create_timer(0.5).timeout

	if not bool(main.run.current_pack[high_index].get("revealed", false)):
		_fail("Pack opening smoke did not mark the clicked card revealed.")
		return
	if int(main.run.collection.get(card_id, 0)) != owned_before + 1:
		_fail("Pack opening smoke did not add the clicked card to collection.")
		return

	var aura := _find_node_by_name(slot, "PackCardAura%d" % high_index) as PanelContainer
	if aura == null or not aura.visible:
		_fail("Pack opening smoke did not show aura for a high-rarity reveal.")
		return

	var reveal_all := _find_node_by_name(main, "RevealAllButton") as Button
	if reveal_all == null:
		_fail("Pack opening smoke did not render RevealAllButton.")
		return
	reveal_all.emit_signal("pressed")
	await process_frame
	await process_frame

	if int(main.run.get("pack_index", 0)) != main.run.current_pack.size():
		_fail("Pack opening smoke did not reveal the rest of the pack.")
		return

	var done := _find_node_by_name(main, "DoneButton") as Button
	if done == null or not done.visible:
		_fail("Pack opening smoke did not show DoneButton after pack completion.")
		return

	print("Pack opening smoke covered sealed pack, spread, click reveal, high-rarity aura, and reveal all.")
	quit(0)


func _first_high_rarity_index(pack: Array) -> int:
	for index in range(pack.size()):
		var entry: Dictionary = pack[index]
		if _rarity_rank(String(entry.get("rarity", "common"))) >= 2:
			return index
	return -1


func _rarity_rank(rarity: String) -> int:
	match rarity:
		"common":
			return 0
		"uncommon":
			return 1
		"rare":
			return 2
		"mythic":
			return 3
		_:
			return 0


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
