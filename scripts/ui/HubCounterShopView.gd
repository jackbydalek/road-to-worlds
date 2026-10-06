extends Control
## Cards stay in the counter: hover enlarges, selection lifts and reveals Buy.
signal buy_requested(card_id: String)
signal close_requested
signal focus_order_changed

const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const INSPECTION := preload("res://scripts/ui/CardInspectionOverlay.gd")
const NATIVE_SIZE := Vector2(250, 355)

var _offers: Dictionary = {}
var _cards: Array = []
var _money := 0
var _difficulty := "white"
var _interactive := false
var _selected_id := ""
var _hovered_id := ""
var _busy := false
var _reduced_motion := false
var _empty_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_empty_label = UI.make_label("Sold out · Reroll above, or restock after battle", "body", PALETTE.PEACH_INK)
	_empty_label.name = "HubCounterEmptyLabel"
	_empty_label.add_theme_stylebox_override("normal", _paper_tag_style())
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.position = Vector2(300, 350)
	_empty_label.size = Vector2(680, 40)
	_empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_empty_label)
	_add_paper_tag(_empty_label)


func configure(snapshot: Dictionary) -> void:
	_cards = snapshot.get("shop_cards", [])
	_money = int(snapshot.get("money", 0))
	_difficulty = String(snapshot.get("difficulty", "white"))
	var current_ids: Array[String] = []
	for card in _cards:
		var card_id := String(card.get("id", ""))
		current_ids.append(card_id)
		if not _offers.has(card_id):
			_add_offer(card_id)
		var offer: Dictionary = _offers[card_id]
		offer.face.configure(card, _difficulty, false)
		var price := int(card.get("shop_price", 0))
		(offer.buy as Button).text = "BUY · $%d" % price if _money >= price else "NEED $%d MORE" % (price - _money)
		(offer.price as Label).text = "$%d" % price
		INSPECTION.bind(offer.hit, card, _difficulty)
		(offer.hit as Button).tooltip_text = ""
		(offer.buy as Button).tooltip_text = "Owned ×%d · Deck %d → %d" % [int(card.get("owned_count", 0)), int(card.get("deck_count", 0)), int(card.get("deck_count", 0)) + 1]
	for card_id in _offers.keys():
		if not current_ids.has(card_id):
			var group := _offers[card_id].group as Control
			remove_child(group)
			group.queue_free()
			_offers.erase(card_id)
	if not current_ids.has(_selected_id):
		_selected_id = ""
	if not current_ids.has(_hovered_id):
		_hovered_id = ""
	_empty_label.visible = _cards.is_empty()
	_refresh_actions()


func _add_offer(card_id: String) -> void:
	var group := Control.new()
	group.name = "RouteShopCardChoice_%s" % card_id
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(group)
	var visual := Control.new()
	visual.name = "HubCounterLiftedCard_%s" % card_id
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(visual)
	var face := CARD_FACE.new()
	face.size = NATIVE_SIZE
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(face)
	var hit := Button.new()
	hit.name = "RouteShopCardButton_%s" % card_id
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.set_meta("ui_button_style_exempt", true)
	for state in ["normal", "hover", "pressed", "disabled"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hit.pressed.connect(select_card.bind(card_id))
	hit.mouse_entered.connect(set_hovered_card.bind(card_id))
	hit.mouse_exited.connect(_check_hover_exit.bind(card_id))
	group.add_child(hit)
	var price := UI.make_label("", "small", PALETTE.PEACH_INK)
	price.add_theme_stylebox_override("normal", _paper_tag_style())
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(price)
	_add_paper_tag(price)
	var buy := UI.make_button("BUY", "confirm", Vector2(174, 44), "RouteShopBuy_%s" % card_id)
	buy.add_theme_font_size_override("font_size", 16)
	buy.visible = false
	buy.mouse_entered.connect(set_hovered_card.bind(card_id))
	buy.mouse_exited.connect(_check_hover_exit.bind(card_id))
	buy.pressed.connect(_buy_selected.bind(card_id))
	group.add_child(buy)
	_offers[card_id] = {"group": group, "visual": visual, "face": face, "hit": hit, "buy": buy, "price": price, "rect": Rect2(), "zoom": 1.0, "lift": 0.0, "tween": null}


func project_card(card_id: String, rect: Rect2) -> void:
	if _offers.has(card_id):
		_offers[card_id].rect = Rect2(rect.position - position, rect.size)
		_apply_pose(card_id)


func replaces_card(card_id: String) -> bool:
	return _offers.has(card_id) and (_offers[card_id].visual as Control).visible


func _apply_pose(card_id: String) -> void:
	var offer: Dictionary = _offers[card_id]
	var rect: Rect2 = offer.rect
	var group := offer.group as Control
	var visual := offer.visual as Control
	group.position = rect.position
	group.size = rect.size
	group.z_index = 3 if card_id == _hovered_id else 2 if card_id == _selected_id else 0
	visual.size = rect.size
	visual.scale = Vector2.ONE * float(offer.zoom)
	visual.position = rect.size * (1.0 - float(offer.zoom)) * 0.5 - Vector2(0, float(offer.lift))
	visual.visible = (_interactive or _busy) and (float(offer.zoom) > 1.001 or float(offer.lift) > 0.001 or card_id == _selected_id)
	(offer.face as Control).scale = rect.size / NATIVE_SIZE
	# Keep the original footprint clickable as the visible card lifts away.
	var hit_rect := Rect2(Vector2.ZERO, rect.size).merge(Rect2(visual.position, rect.size * visual.scale))
	(offer.hit as Control).position = hit_rect.position
	(offer.hit as Control).size = hit_rect.size
	var buy := offer.buy as Button
	buy.size = Vector2(174, 44)
	buy.position = Vector2((rect.size.x - buy.size.x) * 0.5, rect.size.y + 10)
	var price := offer.price as Label
	price.position = Vector2(0, rect.size.y + 12)
	price.size = Vector2(rect.size.x, 28)
	price.visible = _interactive and card_id != _selected_id


func select_card(card_id: String) -> void:
	if not _interactive or _busy or not _offers.has(card_id):
		return
	_selected_id = "" if _selected_id == card_id else card_id
	_refresh_actions()
	_animate_poses()


func set_hovered_card(card_id: String) -> void:
	if not _interactive or _busy or _hovered_id == card_id:
		return
	_hovered_id = card_id
	_animate_poses()


func _check_hover_exit(card_id: String) -> void:
	_finish_hover_exit.call_deferred(card_id)


func _finish_hover_exit(card_id: String) -> void:
	if not _offers.has(card_id) or _hovered_id != card_id:
		return
	var offer: Dictionary = _offers[card_id]
	var pointer := get_global_mouse_position()
	if (offer.hit as Control).get_global_rect().has_point(pointer) or ((offer.buy as Control).is_visible_in_tree() and (offer.buy as Control).get_global_rect().has_point(pointer)):
		return
	set_hovered_card("")


func _animate_poses() -> void:
	for card_id in _offers:
		var offer: Dictionary = _offers[card_id]
		if offer.tween != null and (offer.tween as Tween).is_valid():
			(offer.tween as Tween).kill()
		var zoom := 1.18 if card_id == _hovered_id else 1.035 if card_id == _selected_id else 1.0
		var lift := 24.0 if card_id == _selected_id else 6.0 if card_id == _hovered_id else 0.0
		if _reduced_motion:
			_set_pose(Vector2(zoom, lift), card_id)
		else:
			var tween := create_tween()
			offer.tween = tween
			tween.tween_method(_set_pose.bind(card_id), Vector2(float(offer.zoom), float(offer.lift)), Vector2(zoom, lift), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_pose(pose: Vector2, card_id: String) -> void:
	if _offers.has(card_id):
		_offers[card_id].zoom = pose.x
		_offers[card_id].lift = pose.y
		_apply_pose(card_id)


func _buy_selected(card_id: String) -> void:
	if _interactive and not _busy and card_id == _selected_id and not (_offers[card_id].buy as Button).disabled:
		buy_requested.emit(card_id)


func purchase_control(card_id: String) -> Control:
	if not _offers.has(card_id):
		return null
	_selected_id = card_id
	_busy = true
	for offer in _offers.values():
		if offer.tween != null and (offer.tween as Tween).is_valid():
			(offer.tween as Tween).kill()
	_apply_pose(card_id)
	_refresh_actions()
	return _offers[card_id].visual as Control


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	if enabled:
		_busy = false
	_refresh_actions()
	for card_id in _offers:
		_apply_pose(card_id)


func _refresh_actions() -> void:
	for card in _cards:
		var card_id := String(card.id)
		var offer: Dictionary = _offers[card_id]
		(offer.hit as Button).disabled = not _interactive or _busy
		(offer.hit as Button).set_meta("inspection_available", _interactive and not _busy)
		(offer.buy as Button).visible = card_id == _selected_id and _interactive and not _busy
		(offer.buy as Button).disabled = not _interactive or _busy or _money < int(card.get("shop_price", 0))
	focus_order_changed.emit()


func close_inspection() -> void:
	for overlay in get_tree().get_nodes_in_group("shared_card_inspection"):
		overlay.dismiss(false)
	_selected_id = ""
	_hovered_id = ""
	_refresh_actions()
	_animate_poses()


func clear_reroll_selection() -> void:
	# A new stock may contain the same card ID. Cancel its old visual pose too,
	# so an old selected/hovered copy cannot remain lifted after replacement.
	for overlay in get_tree().get_nodes_in_group("shared_card_inspection"):
		overlay.dismiss(false)
	_selected_id = ""
	_hovered_id = ""
	for card_id in _offers:
		var offer: Dictionary = _offers[card_id]
		if offer.tween != null and (offer.tween as Tween).is_valid():
			(offer.tween as Tween).kill()
		_set_pose(Vector2(1, 0), card_id)
	_refresh_actions()


func focus_controls() -> Array[Control]:
	var result: Array[Control] = []
	for card in _cards:
		var offer: Dictionary = _offers[String(card.id)]
		for control in [offer.hit, offer.buy]:
			if control.is_visible_in_tree() and not control.disabled:
				result.append(control)
	return result


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _busy:
		return
	if not _selected_id.is_empty():
		close_inspection()
	else:
		close_requested.emit()


func _paper_tag_style() -> StyleBoxEmpty:
	var paper := StyleBoxEmpty.new()
	paper.content_margin_left = 6
	paper.content_margin_right = 6
	return paper


func _add_paper_tag(label: Label) -> void:
	var backing := Control.new()
	backing.name = "WarmSketchPaper"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.show_behind_parent = true
	label.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.draw.connect(_draw_paper_tag.bind(backing))
	backing.resized.connect(backing.queue_redraw)


func _draw_paper_tag(backing: Control) -> void:
	SHAPES.draw_surface(backing, Rect2(Vector2(1, 1), backing.size - Vector2(2, 2)), PALETTE.PEACH_PAPER, 41, 5)
