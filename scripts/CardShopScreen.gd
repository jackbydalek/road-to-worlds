extends RefCounted
class_name CardShopScreen

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")

const CARD_SHOP_SCENE_PATH := "res://scenes/CardShopScene.tscn"
const BOOSTER_ID := "base_standard_pack"
const DEFAULT_HOVER_TEXT := ""
const SCENE_SIZE := Vector2(1440, 900)
const HOVER_TEXT_SIZE := Vector2(360, 58)
const HOVER_TEXT_OFFSET := Vector2(18, 18)

var selected_single_id := ""


func show(host, debug_scene_test: bool = false) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "shop"
	host._render_nav()
	host._clear(host.content)
	host._update_status()

	if not host.run.has("shop") or not (host.run.shop is Array):
		host._generate_shop_inventory()

	var event: Dictionary = host._selected_tournament_event()
	var metrics: Dictionary = host._calculate_deck_metrics(host.run.get("deck", {}), host.run.get("sideboard", {}))
	var legal: Dictionary = host._deck_is_legal()

	_add_status_strip(host, event, metrics, legal, debug_scene_test)
	var scene_root := _add_authored_scene(host, event, legal)
	var hover_label := _find_node_by_name(scene_root, "HoverText") as Label
	if hover_label != null:
		hover_label.text = DEFAULT_HOVER_TEXT
		hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_label.z_index = 100
		hover_label.custom_minimum_size = HOVER_TEXT_SIZE
		hover_label.size = HOVER_TEXT_SIZE
		hover_label.add_theme_font_size_override("font_size", 15)
		hover_label.add_theme_color_override("font_color", SKETCH_UI.INK)
	_connect_scene_hotspots(host, scene_root, hover_label, event, legal)
	_add_singles_counter(host, hover_label)


func show_scene_test(host) -> void:
	show(host, true)
	host._set_footer("Scene shop test loaded. Hover the authored shop nodes, click packs/singles, or click the tournament clerk.")


func show_singles(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "singles"
	host._render_nav()
	host._clear(host.content)
	host._update_status()
	selected_single_id = ""
	if not host.run.has("shop") or not (host.run.shop is Array):
		host._generate_shop_inventory()

	var intro_section: Dictionary = WORKSPACE_UI.make_section(
		"SINGLES CASE",
		SKETCH_UI.TEAL,
		Vector2(0, 86)
	)
	host.content.add_child(intro_section.panel)
	var intro: VBoxContainer = intro_section.body
	host._add_body_text(intro, "Buy exact cards from the current case. Sold cards stay gone until the case restocks after a tournament round.")
	var hover_label := Label.new()
	hover_label.name = "SinglesHoverText"
	hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_label.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	intro.add_child(hover_label)
	_add_singles_counter(host, hover_label)
	var exit_button: Button = host._add_exit_to_store_button(host.content)
	WORKSPACE_UI.style_button(exit_button)


func _add_status_strip(host, event: Dictionary, metrics: Dictionary, legal: Dictionary, debug_scene_test: bool) -> void:
	var title := "Card Shop Scene Test" if debug_scene_test else "Card Shop"
	var panel: VBoxContainer = host._add_bordered_panel(host.content, title, "#29233C", "#8299D0", 2)
	panel.name = "CardShopStatusStrip"
	panel.custom_minimum_size = Vector2(0, 86)
	host._add_body_text(panel, "$%d | Prize packs %d | Next event: %s | Free entry | Deck %s" % [
		int(host.run.get("money", 0)),
		int(host.run.get("prize_packs", 0)),
		String(event.get("name", "Weekly Locals")),
		"ready" if bool(legal.get("ok", false)) else String(legal.get("reason", "needs work"))
	])
	host._add_body_text(panel, host._format_metrics_short(metrics))


func _add_authored_scene(host, event: Dictionary, legal: Dictionary) -> Node:
	var frame := PanelContainer.new()
	frame.name = "CardShopSceneFrame"
	frame.custom_minimum_size = SCENE_SIZE
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override(
		"panel",
		SKETCH_UI.texture_style(
			SKETCH_UI.PANEL_PAPER,
			Color("#E9DFEE"),
			Vector4(24, 24, 24, 24),
			Vector4(8, 8, 8, 8)
		)
	)
	host.content.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	frame.add_child(margin)

	var canvas := Control.new()
	canvas.name = "CardShopSceneHost"
	canvas.custom_minimum_size = SCENE_SIZE
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	canvas.clip_contents = true
	margin.add_child(canvas)

	var packed_scene := load(CARD_SHOP_SCENE_PATH) as PackedScene
	assert(packed_scene != null, "Unable to load card shop scene: %s" % CARD_SHOP_SCENE_PATH)
	var scene_root := packed_scene.instantiate()
	scene_root.name = "CardShopScene"
	canvas.add_child(scene_root)
	_update_authored_button_labels(host, scene_root, event, legal)
	return scene_root


func _update_authored_button_labels(host, scene_root: Node, event: Dictionary, legal: Dictionary) -> void:
	var wallet := _find_node_by_name(scene_root, "WalletButton") as Button
	if wallet != null:
		wallet.text = "$%d" % int(host.run.get("money", 0))

	var event_button := _find_node_by_name(scene_root, "EventCalendarButton") as Button
	if event_button != null:
		event_button.text = "Event Calendar"

	var deck_box := _find_node_by_name(scene_root, "DeckBoxButton") as Button
	if deck_box != null:
		deck_box.text = "Deck Box"

	var menu := _find_node_by_name(scene_root, "MenuButton") as Button
	if menu != null:
		menu.text = "Settings"

	var singles := _find_node_by_name(scene_root, "BoosterDisplayButton") as Button
	if singles != null:
		singles.text = "Buy Singles"

	var packs := _find_node_by_name(scene_root, "BoosterDisplayButton2") as Button
	if packs != null:
		var price := 0
		if host.boosters_by_id.has(BOOSTER_ID):
			price = int(host.boosters_by_id[BOOSTER_ID].get("price", 0))
		var prize_packs := int(host.run.get("prize_packs", 0))
		if host._current_pack_needs_attention():
			packs.text = "Continue Pack"
			packs.disabled = false
		elif prize_packs > 0:
			packs.text = "Open Prize Pack"
			packs.disabled = false
		else:
			packs.text = "Open Pack - $%d" % price
			packs.disabled = int(host.run.get("money", 0)) < price

	var trade := _find_node_by_name(scene_root, "TradeBindersButton") as Button
	if trade != null:
		trade.text = "Trade Binder"

	var can_register := _can_register(host, event, legal)
	var marker := _find_node_by_name(scene_root, "TournamentPersonButton")
	if marker is Button:
		(marker as Button).disabled = not can_register


func _connect_scene_hotspots(host, scene_root: Node, hover_label: Label, event: Dictionary, legal: Dictionary) -> void:
	_connect_button(
		host,
		scene_root,
		"EventCalendarButton",
		host._show_season_run if host._run_mode() == "season" else host._show_tournament,
		hover_label,
		"Event calendar: review the season path and selected tournament."
	)
	_connect_button(
		host,
		scene_root,
		"WalletButton",
		host._sell_extra_copies,
		hover_label,
		"Wallet: check cash and sell safe extra copies."
	)
	_connect_button(
		host,
		scene_root,
		"DeckBoxButton",
		host._show_deckbuilder,
		hover_label,
		"Deck box: tune your main deck and sideboard."
	)
	_connect_button(
		host,
		scene_root,
		"MenuButton",
		host._show_settings,
		hover_label,
		"Settings: adjust display, audio, and accessibility."
	)
	_connect_button(
		host,
		scene_root,
		"BoosterDisplayButton",
		func() -> void: host._set_footer("Singles are listed below the shop scene."),
		hover_label,
		"Singles case: buy exact cards from the live list below."
	)
	_connect_button(
		host,
		scene_root,
		"BoosterDisplayButton2",
		host._open_reward_pack_flow,
		hover_label,
		"Booster display: open prize packs first, or buy a base booster."
	)
	_connect_button(
		host,
		scene_root,
		"TradeBindersButton",
		host._sell_extra_copies,
		hover_label,
		"Trade binders: sell safe extra copies for tournament money."
	)
	_add_tournament_person_hotspot(host, scene_root, hover_label, event, legal)


func _connect_button(host, scene_root: Node, node_name: String, callback: Callable, hover_label: Label, hover_text: String) -> void:
	var button := _find_node_by_name(scene_root, node_name) as Button
	if button == null:
		return
	button.theme = host.theme
	host._style_button(button, "action" if node_name in ["BoosterDisplayButton2", "TournamentPersonButton"] else "default")
	_wire_hover(button, hover_label, hover_text)
	host._connect_pressed(button, callback)


func _add_tournament_person_hotspot(host, scene_root: Node, hover_label: Label, event: Dictionary, legal: Dictionary) -> void:
	var existing := _find_node_by_name(scene_root, "TournamentPersonButton")
	if existing is Button:
		var button := existing as Button
		button.disabled = not _can_register(host, event, legal)
		_wire_hover(button, hover_label, "Tournament clerk: click to open registration for the selected event.")
		host._connect_pressed(button, host._show_tournament)
		return

	var sprite := _find_node_by_name(scene_root, "TournamentClerk2") as Sprite2D
	if sprite == null:
		sprite = _find_node_by_name(scene_root, "TournamentPersonButton") as Sprite2D
	if sprite == null:
		return

	var size := _sprite_display_size(sprite)
	if size.x <= 0.0 or size.y <= 0.0:
		size = Vector2(340, 430)

	var button := Button.new()
	button.name = "TournamentPersonHotspot"
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not _can_register(host, event, legal)
	button.position = sprite.position - size * 0.5
	button.custom_minimum_size = size
	button.size = size
	button.add_theme_stylebox_override("normal", _transparent_button_style())
	button.add_theme_stylebox_override("hover", _transparent_button_style(Color(SKETCH_UI.TEAL, 0.20), SKETCH_UI.TEAL, 2))
	button.add_theme_stylebox_override("pressed", _transparent_button_style(Color(SKETCH_UI.ORANGE, 0.20), SKETCH_UI.ORANGE, 2))
	button.add_theme_stylebox_override("disabled", _transparent_button_style())
	_wire_hover(button, hover_label, "Tournament clerk: click to open registration for the selected event.")
	host._connect_pressed(button, host._show_tournament)
	scene_root.add_child(button)


func _add_singles_counter(host, hover_label: Label) -> void:
	var counter_section: Dictionary = WORKSPACE_UI.make_section(
		"LIVE SINGLES CASE",
		SKETCH_UI.ORANGE,
		Vector2.ZERO,
		true
	)
	host.content.add_child(counter_section.panel)
	var counter: VBoxContainer = counter_section.body
	counter.name = "CardShopSinglesCounter"
	_wire_hover(counter, hover_label, "Singles case: buy exact cards instead of gambling on boosters.")
	host._add_body_text(counter, "Click the singles area in the shop art, then buy exact cards here.")

	var grid := GridContainer.new()
	grid.name = "CardShopSinglesGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	counter.add_child(grid)

	var inventory: Array = host.run.get("shop", [])
	if inventory.is_empty():
		host._add_body_text(counter, "The singles case is sold out. New cards arrive after the next tournament round.")
		return

	for card_id_value in inventory:
		_add_single_tile(host, grid, String(card_id_value), hover_label)
	_update_single_selection(host)


func _add_single_tile(host, parent: Node, card_id: String, hover_label: Label) -> void:
	if not host.cards_by_id.has(card_id):
		return

	var card: Dictionary = host.cards_by_id[card_id]
	var rarity := String(card.get("rarity", "common"))
	var price: int = host._card_price(card_id)
	var authored_face: bool = host._card_uses_authored_face(card)
	var tile := PanelContainer.new()
	tile.name = "CardShopSingleTile_%s" % card_id
	tile.set_meta("card_id", card_id)
	tile.custom_minimum_size = Vector2(210, 276 if authored_face else 156)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tile_fill: Color = WORKSPACE_UI.SURFACE.lerp(host._rarity_line_color(rarity), 0.07)
	var tile_accent: Color = host._rarity_text_color(rarity).darkened(0.28)
	tile.set_meta("tile_fill", tile_fill)
	tile.set_meta("tile_accent", tile_accent)
	_wire_hover(tile, hover_label, "%s: buy this single for $%d." % [String(card.get("name", card_id)), price])
	parent.add_child(tile)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	tile.add_child(box)

	if authored_face:
		var face_center := CenterContainer.new()
		face_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(face_center)
		var card_stack := Control.new()
		card_stack.custom_minimum_size = Vector2(150, 213)
		face_center.add_child(card_stack)

		var face: Control = host._make_card_face(card, Vector2(150, 213), false)
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_stack.add_child(face)

		var sticker: PanelContainer = WORKSPACE_UI.make_price_sticker(price)
		sticker.position = Vector2(77, 48)
		card_stack.add_child(sticker)

		var select_button := Button.new()
		select_button.name = "CardShopSingleSelectButton_%s" % card_id
		select_button.text = ""
		select_button.focus_mode = Control.FOCUS_ALL
		select_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			select_button.add_theme_stylebox_override(
				state,
				WORKSPACE_UI.clean_style(
					Color("#FFFFFF08") if state == "hover" else Color.TRANSPARENT,
					Color("#FFFFFF00"),
					0,
					5
				)
			)
		var selected_id := card_id
		host._connect_pressed(select_button, func() -> void: _select_single(host, selected_id))
		card_stack.add_child(select_button)
	else:
		var name_label := Label.new()
		name_label.text = host._card_display_name(card)
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", SKETCH_UI.INK)
		box.add_child(name_label)
		host._add_body_text(box, "%s | %s | cost %d" % [
			rarity.capitalize(),
			host._card_descriptor(card),
			int(card.get("cost", 0))
		])
	host._add_body_text(box, "Owned %d | Deck %d/%d" % [
		host._owned_count(card_id),
		host._deck_count(card_id),
		host._deck_limit(card_id)
	])

	var buy_button: Button = host._make_button("Buy")
	buy_button.name = "CardShopSingleBuyButton_%s" % card_id
	buy_button.set_meta("card_id", card_id)
	buy_button.disabled = int(host.run.get("money", 0)) < price
	buy_button.visible = false
	WORKSPACE_UI.style_button(buy_button, "primary")
	_wire_hover(buy_button, hover_label, "Buy %s for $%d and add it to your collection." % [String(card.get("name", card_id)), price])
	var selected_id := card_id
	host._connect_pressed(buy_button, func() -> void: host._buy_single(selected_id))
	box.add_child(buy_button)


func _select_single(host, card_id: String) -> void:
	selected_single_id = card_id
	_update_single_selection(host)
	var card: Dictionary = host.cards_by_id.get(card_id, {})
	var price: int = host._card_price(card_id)
	var message := "%s selected — $%d. Click Buy to add it to your collection." % [
		String(card.get("name", card_id)),
		price,
	]
	var hover_label := host.find_child("SinglesHoverText", true, false) as Label
	if hover_label != null:
		hover_label.text = message
	host._set_footer(message)


func _update_single_selection(host) -> void:
	for candidate in host.find_children("CardShopSingleTile_*", "PanelContainer", true, false):
		var tile := candidate as PanelContainer
		if tile == null:
			continue
		var card_id := String(tile.get_meta("card_id", ""))
		var selected := card_id == selected_single_id
		var fill: Color = tile.get_meta("tile_fill", WORKSPACE_UI.SURFACE)
		var accent: Color = tile.get_meta("tile_accent", WORKSPACE_UI.BORDER_SOFT)
		tile.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI.clean_style(
				fill,
				WORKSPACE_UI.MUSTARD if selected else accent,
				3 if selected else 1,
				8 if selected else 7,
				Vector4(9, 8, 9, 9),
				4 if selected else 3,
				selected
			)
		)
		var buy_button := tile.find_child("CardShopSingleBuyButton_*", true, false) as Button
		if buy_button != null:
			buy_button.visible = selected


func _can_register(host, event: Dictionary, legal: Dictionary) -> bool:
	var can_register := bool(legal.get("ok", false))
	if host._run_mode() == "season":
		can_register = can_register and host._season_event_selectable(String(event.get("id", "")))
	return can_register


func _wire_hover(control: Control, hover_label: Label, text: String) -> void:
	if hover_label == null:
		return
	control.mouse_entered.connect(func() -> void:
		hover_label.text = text
		_move_hover_label(control, hover_label)
	)
	control.mouse_exited.connect(func() -> void:
		if hover_label.text == text:
			hover_label.text = DEFAULT_HOVER_TEXT
	)
	control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			_move_hover_label(control, hover_label)
	)


func _move_hover_label(control: Control, hover_label: Label) -> void:
	var parent_item := hover_label.get_parent() as CanvasItem
	if parent_item == null:
		return
	var local_mouse := parent_item.get_global_transform_with_canvas().affine_inverse() * control.get_global_mouse_position()
	var target := local_mouse + HOVER_TEXT_OFFSET
	target.x = clamp(target.x, 8.0, SCENE_SIZE.x - HOVER_TEXT_SIZE.x - 8.0)
	target.y = clamp(target.y, 8.0, SCENE_SIZE.y - HOVER_TEXT_SIZE.y - 8.0)
	hover_label.position = target


func _sprite_display_size(sprite: Sprite2D) -> Vector2:
	if sprite.texture == null:
		return Vector2.ZERO
	return sprite.texture.get_size() * sprite.scale.abs()


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _style(background: String, border: String, border_width: int = 1, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _transparent_button_style(background: Color = Color("#00000000"), border: Color = Color("#00000000"), border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	return style
