extends Control

const MAIN_DECK_SIZE := 30
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SAVE_PATH := "user://road_to_worlds_run.json"
const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"
const ARCHETYPE_ORDER := ["flightless_birds", "snake", "oxen", "glires", "insect"]
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const COMBAT_SERVICE_SCRIPT := preload("res://scripts/CombatService.gd")
const DECK_METRICS_SERVICE_SCRIPT := preload("res://scripts/DeckMetricsService.gd")
const RUN_STATE_SERVICE_SCRIPT := preload("res://scripts/RunStateService.gd")
const SHOP_ECONOMY_SERVICE_SCRIPT := preload("res://scripts/ShopEconomyService.gd")
const CARD_FRAME_FACTORY_SCRIPT := preload("res://scripts/CardFrameFactory.gd")
const COMBAT_BOARD_SLOTS := 5
const COMBAT_ENGINE_SLOTS := 3
const MANUAL_PENDING_ACTION_COMMIT_DELAY := 1.0

var rng := RandomNumberGenerator.new()
var content_catalog: RefCounted
var combat_service: RefCounted
var deck_metrics_service: RefCounted
var run_state_service: RefCounted
var shop_economy_service: RefCounted
var card_frame_factory: RefCounted

var cards: Array = []
var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var tournaments_by_id: Dictionary = {}

var run: Dictionary = {}
var current_screen := "start"
var deckbuilder_sort_mode := SORT_AFFINITY

var root_margin: MarginContainer
var shell: VBoxContainer
var title_label: Label
var status_label: Label
var nav: HBoxContainer
var scroll: ScrollContainer
var content: VBoxContainer
var footer_label: RichTextLabel
var manual_inspect_art_panel: PanelContainer
var manual_inspect_name_label: Label
var manual_inspect_type_panel: PanelContainer
var manual_inspect_type_label: Label
var manual_inspect_meta_label: Label
var manual_inspect_stats_label: Label
var manual_inspect_zone_label: Label
var manual_inspect_effect_label: Label
var manual_inspect_text_label: Label
var manual_drag_candidate: Dictionary = {}
var manual_drag_state: Dictionary = {}
var manual_drag_ghost: Control


func _ready() -> void:
	rng.randomize()
	_load_content()
	combat_service = COMBAT_SERVICE_SCRIPT.new()
	combat_service.setup(cards_by_id, archetypes_by_id)
	deck_metrics_service = DECK_METRICS_SERVICE_SCRIPT.new()
	deck_metrics_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE)
	run_state_service = RUN_STATE_SERVICE_SCRIPT.new()
	run_state_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE, SIDEBOARD_SIZE, STARTING_MONEY, SAVE_PATH)
	shop_economy_service = SHOP_ECONOMY_SERVICE_SCRIPT.new()
	shop_economy_service.setup(cards, cards_by_id, boosters_by_id, rng)
	card_frame_factory = CARD_FRAME_FACTORY_SCRIPT.new()
	_build_shell()
	_show_start()


func _input(event: InputEvent) -> void:
	if current_screen != "ui_combat":
		return
	if _manual_handle_hand_card_drag_input(event):
		return
	if run.get("manual_inspect", {}).is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hovered := get_viewport().gui_get_hovered_control()
		if not _ui_combat_click_keeps_inspect(hovered):
			call_deferred("_manual_clear_inspect_overlay")


func _ui_combat_click_keeps_inspect(control: Control) -> bool:
	var node: Node = control
	while node != null:
		var node_name := String(node.name)
		if node_name.begins_with("CombatCardPanel"):
			return true
		if node_name.begins_with("ManualInspectPanelOverlay"):
			return true
		if node_name.begins_with("ManualCardPlayButton") or node_name.begins_with("ManualCardSelectButton"):
			return true
		if node_name.begins_with("ManualAttackSelectButton") or node_name.begins_with("ManualUnitTargetButton"):
			return true
		if node_name.begins_with("ManualFaceTargetButton") or node_name.begins_with("ManualEndTurnButton"):
			return true
		node = node.get_parent()
	return false


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#11141a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(root_margin)

	shell = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	root_margin.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	shell.add_child(header)

	title_label = Label.new()
	title_label.text = "Road to Worlds"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("#f3efe4"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", Color("#c7d0df"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_label)

	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	shell.add_child(nav)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	footer_label = RichTextLabel.new()
	footer_label.custom_minimum_size = Vector2(0, 78)
	footer_label.bbcode_enabled = true
	footer_label.fit_content = false
	footer_label.scroll_active = true
	footer_label.add_theme_color_override("default_color", Color("#c7d0df"))
	shell.add_child(footer_label)


func _load_content() -> void:
	content_catalog = CONTENT_CATALOG_SCRIPT.new()
	content_catalog.load_all()

	cards = content_catalog.cards
	cards_by_id = content_catalog.cards_by_id
	archetypes_by_id = content_catalog.archetypes_by_id
	boosters_by_id = content_catalog.boosters_by_id
	tournaments_by_id = content_catalog.tournaments_by_id


func _clear(node: Node) -> void:
	for child in node.get_children():
		# Screen rebuilds are often triggered by button signals; queue deletion so the
		# emitting button is not freed while Godot is still dispatching its signal.
		child.queue_free()


func _connect_pressed(button: Button, callback: Callable) -> void:
	button.pressed.connect(callback, CONNECT_DEFERRED)


func _show_start() -> void:
	current_screen = "start"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose a starter deck. The first prototype is about opening packs, tuning a list, and trying to survive Weekly Locals.")

	var intro := _add_panel(content, "Choose Your Starter")
	_add_body_text(
		intro,
		"You are starting a new competitive season with a small budget and a borrowed deck shell. Each starter is legal for Weekly Locals, but neither is optimized."
	)

	var starter_grid := HBoxContainer.new()
	starter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starter_grid.add_theme_constant_override("separation", 10)
	intro.add_child(starter_grid)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var box := _add_panel(starter_grid, archetype.get("name", archetype_id), archetype.get("color", "#2d3442"))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_body_text(box, archetype.get("summary", ""))
		var metrics := _calculate_deck_metrics(_deck_entries_to_dict(archetype.get("starterDeck", [])), {})
		_add_body_text(box, _format_metrics_short(metrics))
		var button := _make_button("Start With " + archetype.get("name", archetype_id))
		var selected_id: String = archetype_id
		_connect_pressed(button, func() -> void: _start_new_run(selected_id))
		box.add_child(button)


func _start_new_run(archetype_id: String) -> void:
	_manual_clear_hand_card_drag()
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id))

	_generate_shop_inventory()
	_set_footer("New season started. You have $%d, a legal starter deck, and one shot at this week's locals." % run.money)
	_show_shop()


func _deck_entries_to_dict(entries: Array) -> Dictionary:
	return content_catalog.deck_entries_to_dict(entries)


func _render_nav() -> void:
	_clear(nav)
	_apply_screen_chrome()
	if run.is_empty():
		return

	_add_nav_button("Shop", _show_shop)
	_add_nav_button("Packs", _show_packs)
	_add_nav_button("Deckbuilder", _show_deckbuilder)
	_add_nav_button("Combat Lab", _show_combat_lab)
	_add_nav_button("UI Combat", _show_ui_combat)
	_add_nav_button("Tournament", _show_tournament)
	_add_nav_button("Metagame", _show_meta)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)

	_add_nav_button("Save", _save_run)
	_add_nav_button("Load", _load_run_from_disk)
	_add_nav_button("New Run", _show_start)


func _apply_screen_chrome() -> void:
	if footer_label == null:
		return
	var compact_duel := current_screen == "ui_combat"
	footer_label.visible = not compact_duel
	footer_label.custom_minimum_size = Vector2(0, 0 if compact_duel else 78)
	root_margin.add_theme_constant_override("margin_left", 10 if compact_duel else 18)
	root_margin.add_theme_constant_override("margin_right", 10 if compact_duel else 18)
	root_margin.add_theme_constant_override("margin_top", 8 if compact_duel else 14)
	root_margin.add_theme_constant_override("margin_bottom", 8 if compact_duel else 14)
	shell.add_theme_constant_override("separation", 6 if compact_duel else 10)


func _add_nav_button(label: String, callback: Callable) -> void:
	var button := _make_button(label)
	_connect_pressed(button, callback)
	nav.add_child(button)


func _show_shop() -> void:
	if _guard_run_over():
		return
	current_screen = "shop"
	_render_nav()
	_clear(content)
	_update_status()

	var event: Dictionary = tournaments_by_id["weekly_locals"]
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 10)
	content.add_child(top)

	var event_panel := _add_panel(top, "Card Shop", "#1e2630")
	event_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(
		event_panel,
		"Next event: %s, %d rounds, need %d wins. Entry fee: $%d."
		% [event.name, event.rounds, event.requiredWins, event.entryFee]
	)
	_add_body_text(event_panel, "Money: $%d | Prize packs waiting: %d" % [run.money, run.prize_packs])

	var pack_button := _make_button("Buy & Open Base Booster ($5)")
	pack_button.disabled = run.money < boosters_by_id["base_standard_pack"].price
	_connect_pressed(pack_button, _buy_and_open_pack)
	event_panel.add_child(pack_button)

	var prize_button := _make_button("Open Prize Pack")
	prize_button.disabled = run.prize_packs <= 0
	_connect_pressed(prize_button, _open_prize_pack)
	event_panel.add_child(prize_button)

	var sell_button := _make_button("Sell Extra Copies")
	_connect_pressed(sell_button, _sell_extra_copies)
	event_panel.add_child(sell_button)

	var deck_panel := _add_panel(top, "Current Deck", "#222936")
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(deck_panel, _format_metrics(metrics))
	var deck_button := _make_button("Tune Deck")
	_connect_pressed(deck_button, _show_deckbuilder)
	deck_panel.add_child(deck_button)

	var singles := _add_panel(content, "Singles Case")
	_add_body_text(singles, "Singles are reliable. Packs are tempting. Your wallet is not large enough for both every week.")

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	singles.add_child(grid)

	for card_id in run.shop:
		var card: Dictionary = cards_by_id[card_id]
		var price := _card_price(card_id)
		var row := _add_card_panel(grid, card_id, "Buy for $%d" % price)
		var button := _make_button("Buy")
		button.disabled = run.money < price
		var selected_id: String = String(card_id)
		_connect_pressed(button, func() -> void: _buy_single(selected_id))
		row.add_child(button)
		_add_body_text(row, card.text)

	var report := _add_panel(content, "Shop Talk")
	for line in run.reports:
		_add_body_text(report, "• " + line)


func _show_packs() -> void:
	if _guard_run_over():
		return
	current_screen = "packs"
	_render_nav()
	_clear(content)
	_update_status()

	var panel := _add_panel(content, "Pack Opening")
	if run.current_pack.is_empty():
		_add_body_text(panel, "No pack is currently open. Buy a booster from the shop or earn prize packs at locals.")
		var buy_button := _make_button("Buy & Open Base Booster ($5)")
		buy_button.disabled = run.money < boosters_by_id["base_standard_pack"].price
		_connect_pressed(buy_button, _buy_and_open_pack)
		panel.add_child(buy_button)
		return

	_add_body_text(panel, "Reveal the pack one card at a time. New cards and deck-relevant cards are highlighted.")

	var reveal_grid := GridContainer.new()
	reveal_grid.columns = 4
	reveal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reveal_grid.add_theme_constant_override("h_separation", 8)
	reveal_grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(reveal_grid)

	for entry in run.revealed_pack:
		_add_card_panel(reveal_grid, entry.cardId, entry.note)

	var remaining: int = run.current_pack.size() - int(run.pack_index)
	if remaining > 0:
		var next_button := _make_button("Reveal Next Card (%d left)" % remaining)
		_connect_pressed(next_button, _reveal_next_card)
		panel.add_child(next_button)

		var all_button := _make_button("Reveal All")
		_connect_pressed(all_button, _reveal_all_cards)
		panel.add_child(all_button)
	else:
		_add_body_text(panel, "Pack complete. Check the deckbuilder to see what changed.")
		var deck_button := _make_button("Open Deckbuilder")
		_connect_pressed(deck_button, _show_deckbuilder)
		panel.add_child(deck_button)


func _buy_and_open_pack() -> void:
	var result: Dictionary = shop_economy_service.buy_and_open_pack(run, "base_standard_pack", _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _open_prize_pack() -> void:
	var result: Dictionary = shop_economy_service.open_prize_pack(run, "base_standard_pack", _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _start_pack(pack: Array) -> void:
	shop_economy_service.start_pack(run, pack)


func _generate_pack(booster_id: String) -> Array:
	return shop_economy_service.generate_pack(booster_id, _current_primary_archetype())


func _pick_card_by_rarity(rarity: String) -> String:
	return shop_economy_service.pick_card_by_rarity(rarity, _current_primary_archetype())


func _rarity_rank(rarity: String) -> int:
	return shop_economy_service.rarity_rank(rarity)


func _reveal_next_card() -> void:
	shop_economy_service.reveal_next_card(run, _current_primary_archetype())
	_show_packs()


func _reveal_all_cards() -> void:
	shop_economy_service.reveal_all_cards(run, _current_primary_archetype())
	_show_packs()


func _card_matches_current_deck(card_id: String) -> bool:
	return shop_economy_service.card_matches_current_deck(card_id, _current_primary_archetype())


func _buy_single(card_id: String) -> void:
	var result: Dictionary = shop_economy_service.buy_single(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_generate_shop_inventory()
	_show_shop()


func _sell_extra_copies() -> void:
	var total: int = run_state_service.sell_extra_copies(run)
	if total > 0:
		_set_footer("Sold extra copies for $%d." % total)
	else:
		_set_footer("No safe extra copies to sell.")
	_show_shop()


func _generate_shop_inventory() -> void:
	shop_economy_service.generate_shop_inventory(run, _current_primary_archetype())


func _pick_shop_card(rarity: String, primary: String, excluded: Array) -> String:
	return shop_economy_service.pick_shop_card(rarity, primary, excluded)


func _card_price(card_id: String) -> int:
	return shop_economy_service.card_price(run, card_id)


func _current_primary_archetype() -> String:
	if run.is_empty():
		return String(ARCHETYPE_ORDER[0])
	return String(_calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {})).primary)


func _show_deckbuilder() -> void:
	if _guard_run_over():
		return
	current_screen = "deck"
	_render_nav()
	_clear(content)
	_update_status()

	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var legal := _deck_is_legal()
	var collection_ids: Array = _sorted_card_ids(run.collection.keys(), metrics.primary)
	var preview_card_id := ""
	if not collection_ids.is_empty():
		preview_card_id = String(collection_ids[0])

	var summary := _add_panel(content, "Deckbuilder")
	_add_body_text(summary, _format_metrics(metrics))
	_add_body_text(summary, "Legality: " + ("Legal for Weekly Locals" if legal.ok else legal.reason))
	_add_sort_controls(summary)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	content.add_child(columns)

	var collection_panel := _add_panel(columns, "Collection")
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for card_id in collection_ids:
		var owned := _owned_count(card_id)
		var available := _available_count(card_id)
		var card: Dictionary = cards_by_id[card_id]
		var row_panel := PanelContainer.new()
		row_panel.name = "DeckbuilderCardRow"
		row_panel.set_meta("card_id", String(card_id))
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = _rarity_line_color(card.get("rarity", "common"))
		row_style.border_color = Color("#3a4352")
		row_style.border_width_left = 1
		row_style.border_width_right = 1
		row_style.border_width_top = 1
		row_style.border_width_bottom = 1
		row_style.corner_radius_top_left = 4
		row_style.corner_radius_top_right = 4
		row_style.corner_radius_bottom_left = 4
		row_style.corner_radius_bottom_right = 4
		row_panel.add_theme_stylebox_override("panel", row_style)
		collection_panel.add_child(row_panel)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 6)
		row_margin.add_theme_constant_override("margin_right", 6)
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(row_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row_margin.add_child(row)

		var dot := Label.new()
		dot.text = "●"
		dot.tooltip_text = _affinity_label(_card_animal_type(card))
		dot.add_theme_color_override("font_color", _affinity_color(_card_animal_type(card)))
		row.add_child(dot)

		var label := Label.new()
		label.text = "%s x%d | %s %s | cost %d | %s" % [
			card.name,
			owned,
			String(card.rarity).capitalize(),
			String(card.role).capitalize(),
			int(card.cost),
			_affinity_label(_card_animal_type(card))
		]
		label.tooltip_text = card.text
		label.add_theme_color_override("font_color", _rarity_text_color(card.get("rarity", "common")))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var add_main := _make_button("+ Main")
		add_main.disabled = available <= 0 or _deck_total(run.deck) >= MAIN_DECK_SIZE or _deck_count(card_id) >= _deck_limit(card_id)
		var main_id := String(card_id)
		_connect_pressed(add_main, func() -> void: _add_to_deck(main_id))
		row.add_child(add_main)

		var add_side := _make_button("+ Side")
		add_side.disabled = available <= 0 or _deck_total(run.sideboard) >= SIDEBOARD_SIZE or _sideboard_count(card_id) >= _deck_limit(card_id)
		var side_id := String(card_id)
		_connect_pressed(add_side, func() -> void: _add_to_sideboard(side_id))
		row.add_child(add_side)

	var preview_panel := _add_panel(columns, "Card Preview")
	preview_panel.name = "DeckbuilderCardPreview"
	preview_panel.custom_minimum_size = Vector2(260, 0)
	var preview_body := VBoxContainer.new()
	preview_body.name = "DeckbuilderCardPreviewBody"
	preview_body.add_theme_constant_override("separation", 6)
	preview_panel.add_child(preview_body)
	_show_deckbuilder_card_preview(preview_body, preview_card_id)

	for row_panel in collection_panel.get_children():
		if row_panel is Control and row_panel.has_meta("card_id"):
			_bind_deckbuilder_card_hover(row_panel, String(row_panel.get_meta("card_id")), preview_body)

	var deck_panel := _add_panel(columns, "Main Deck %d/%d" % [_deck_total(run.deck), MAIN_DECK_SIZE])
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_deck_list(deck_panel, run.deck, true, preview_body)

	var side_panel := _add_panel(columns, "Sideboard %d/%d" % [_deck_total(run.sideboard), SIDEBOARD_SIZE])
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_deck_list(side_panel, run.sideboard, false, preview_body)


func _add_deck_list(parent: VBoxContainer, deck: Dictionary, is_main: bool, preview_body: VBoxContainer = null) -> void:
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var ids: Array = _sorted_card_ids(deck.keys(), metrics.primary)
	if ids.is_empty():
		_add_body_text(parent, "No cards yet.")
		return

	for card_id in ids:
		var card: Dictionary = cards_by_id[card_id]
		var row_panel := PanelContainer.new()
		row_panel.name = "DeckbuilderCardRow"
		row_panel.set_meta("card_id", String(card_id))
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = _rarity_line_color(card.get("rarity", "common"))
		row_style.border_color = Color("#3a4352")
		row_style.border_width_left = 1
		row_style.border_width_right = 1
		row_style.border_width_top = 1
		row_style.border_width_bottom = 1
		row_style.corner_radius_top_left = 4
		row_style.corner_radius_top_right = 4
		row_style.corner_radius_bottom_left = 4
		row_style.corner_radius_bottom_right = 4
		row_panel.add_theme_stylebox_override("panel", row_style)
		parent.add_child(row_panel)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 6)
		row_margin.add_theme_constant_override("margin_right", 6)
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(row_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row_margin.add_child(row)

		var dot := Label.new()
		dot.text = "●"
		dot.tooltip_text = _affinity_label(_card_animal_type(card))
		dot.add_theme_color_override("font_color", _affinity_color(_card_animal_type(card)))
		row.add_child(dot)

		var label := Label.new()
		label.text = "%s x%d | %s | cost %d" % [
			card.name,
			int(deck[card_id]),
			String(card.rarity).capitalize(),
			int(card.cost)
		]
		label.tooltip_text = card.text
		label.add_theme_color_override("font_color", _rarity_text_color(card.get("rarity", "common")))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var button := _make_button("−")
		button.tooltip_text = "Remove " + String(card.name)
		var selected_id := String(card_id)
		if is_main:
			_connect_pressed(button, func() -> void: _remove_from_deck(selected_id))
		else:
			_connect_pressed(button, func() -> void: _remove_from_sideboard(selected_id))
		row.add_child(button)
		_bind_deckbuilder_card_hover(row_panel, String(card_id), preview_body)


func _bind_deckbuilder_card_hover(control: Control, card_id: String, preview_body: VBoxContainer) -> void:
	if control == null or preview_body == null:
		return
	control.mouse_entered.connect(func() -> void: _show_deckbuilder_card_preview(preview_body, card_id))


func _show_deckbuilder_card_preview(preview_body: VBoxContainer, card_id: String) -> void:
	if preview_body == null or not is_instance_valid(preview_body):
		return
	for child in preview_body.get_children():
		child.free()
	if not cards_by_id.has(card_id):
		return

	card_frame_factory.add_frame(
		preview_body,
		_card_frame_data(card_id),
		{
			"panel_name": "DeckbuilderPreviewFrame",
			"contents_name": "DeckbuilderPreviewContents",
			"name_prefix": "DeckbuilderPreview",
			"compact": false,
			"min_size": Vector2(248, 0),
			"show_deck_stats": true,
			"show_rules_text": true,
			"border_width": 2
		}
	)


func _card_frame_data(card_id: String, overrides: Dictionary = {}) -> Dictionary:
	var card: Dictionary = cards_by_id.get(card_id, {})
	var combat: Dictionary = card.get("combat", {})
	var animal_type := _card_animal_type(card) if not card.is_empty() else "neutral"
	var kind := String(combat.get("kind", _combat_card_type(card) if not card.is_empty() else "card")).capitalize()
	var attack := -1
	var health := -1
	if String(combat.get("kind", "")) == "unit":
		attack = int(combat.get("attack", -1))
		health = int(combat.get("health", -1))

	var data := {
		"card_id": card_id,
		"title": String(card.get("name", card_id)),
		"cost": int(card.get("cost", -1)),
		"rarity": String(card.get("rarity", "")),
		"type_line": _combat_card_type_line(card) if not card.is_empty() else "",
		"meta_line": "%s | %s | Limit %d" % [
			String(card.get("rarity", "common")).capitalize(),
			kind,
			_deck_limit(card_id) if cards_by_id.has(card_id) else 0
		],
		"combat_stats": _manual_inspect_stats(card, "") if not card.is_empty() else "",
		"deck_stats": _deckbuilder_stats_line(card) if not card.is_empty() else "",
		"effect_text": _combat_effect_summary(card) if not card.is_empty() else "",
		"rules_text": String(card.get("text", "")),
		"attack": attack,
		"health": health,
		"show_attack_health": attack >= 0 and health >= 0,
		"area_text": String(card.get("role", "card")).capitalize(),
		"art_text": "Picture\nplaceholder",
		"animal_color": _affinity_color(animal_type),
		"frame_color": _rarity_line_color(String(card.get("rarity", "common"))),
		"art_color": _combat_placeholder_color(card_id),
		"border_color": _affinity_color(animal_type).lightened(0.12),
		"border_width": 1
	}

	for key in overrides.keys():
		data[key] = overrides[key]
	return data


func _deckbuilder_stats_line(card: Dictionary) -> String:
	var stats: Dictionary = card.get("stats", {})
	if stats.is_empty():
		return ""
	return "Speed %d | Power %d | Interaction %d\nResilience %d | Advantage %d | Consistency %d" % [
		int(stats.get("speed", 0)),
		int(stats.get("power", 0)),
		int(stats.get("interaction", 0)),
		int(stats.get("resilience", 0)),
		int(stats.get("advantage", 0)),
		int(stats.get("consistency", 0))
	]


func _add_sort_controls(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Sort cards:"
	label.add_theme_color_override("font_color", Color("#c7d0df"))
	row.add_child(label)

	_add_sort_button(row, "Deck Affinity", SORT_AFFINITY)
	_add_sort_button(row, "Rarity", SORT_RARITY)
	_add_sort_button(row, "Name", SORT_NAME)


func _add_sort_button(parent: HBoxContainer, label: String, mode: String) -> void:
	var button := _make_button(label)
	button.disabled = deckbuilder_sort_mode == mode
	_connect_pressed(button, func() -> void: _set_deckbuilder_sort(mode))
	parent.add_child(button)


func _set_deckbuilder_sort(mode: String) -> void:
	deckbuilder_sort_mode = mode
	_set_footer("Deckbuilder sorted by " + mode + ".")
	_show_deckbuilder()


func _sorted_card_ids(ids: Array, primary_archetype: String) -> Array:
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort_custom(func(a, b) -> bool: return _card_id_comes_before(String(a), String(b), primary_archetype))
	return sorted_ids


func _card_id_comes_before(a: String, b: String, primary_archetype: String) -> bool:
	var card_a: Dictionary = cards_by_id[a]
	var card_b: Dictionary = cards_by_id[b]

	match deckbuilder_sort_mode:
		SORT_RARITY:
			var rarity_a := _rarity_rank(card_a.get("rarity", "common"))
			var rarity_b := _rarity_rank(card_b.get("rarity", "common"))
			if rarity_a != rarity_b:
				return rarity_a > rarity_b
		SORT_AFFINITY:
			var affinity_a := _affinity_rank(card_a.get("archetype", "neutral"), primary_archetype)
			var affinity_b := _affinity_rank(card_b.get("archetype", "neutral"), primary_archetype)
			if affinity_a != affinity_b:
				return affinity_a < affinity_b
			var rarity_a := _rarity_rank(card_a.get("rarity", "common"))
			var rarity_b := _rarity_rank(card_b.get("rarity", "common"))
			if rarity_a != rarity_b:
				return rarity_a > rarity_b

	var name_a := String(card_a.get("name", a)).to_lower()
	var name_b := String(card_b.get("name", b)).to_lower()
	if name_a == name_b:
		return a < b
	return name_a < name_b


func _affinity_rank(archetype_id: String, primary_archetype: String) -> int:
	if archetype_id == primary_archetype:
		return 0
	if archetype_id == "neutral":
		return 1
	return 2


func _add_to_deck(card_id: String) -> void:
	var result: Dictionary = run_state_service.add_to_deck(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_show_deckbuilder()


func _remove_from_deck(card_id: String) -> void:
	if run_state_service.remove_from_deck(run, card_id):
		_show_deckbuilder()


func _add_to_sideboard(card_id: String) -> void:
	var result: Dictionary = run_state_service.add_to_sideboard(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_show_deckbuilder()


func _remove_from_sideboard(card_id: String) -> void:
	if run_state_service.remove_from_sideboard(run, card_id):
		_show_deckbuilder()


func _show_combat_lab() -> void:
	if _guard_run_over():
		return
	current_screen = "combat_lab"
	_render_nav()
	_clear(content)
	_update_status()

	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype: String = String(metrics.primary)
	var opponent_archetype: String = _combat_lab_opponent_for(player_archetype)
	var legal := _deck_is_legal()

	var panel := _add_panel(content, "Combat Lab")
	_add_body_text(panel, "This is the workbench for the simplified TCG duel system. It auto-plays a seeded duel using your current deck, then shows the final game state and combat log.")
	_add_body_text(panel, "Your deck: %s | Test opponent: %s" % [archetypes_by_id[player_archetype].name, archetypes_by_id[opponent_archetype].name])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var opponent_row := HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 6)
	panel.add_child(opponent_row)

	var opponent_label := Label.new()
	opponent_label.text = "Opponent:"
	opponent_label.add_theme_color_override("font_color", Color("#c7d0df"))
	opponent_row.add_child(opponent_label)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var opponent_button := _make_button(archetype.get("name", archetype_id))
		opponent_button.disabled = String(archetype_id) == opponent_archetype
		var selected_id: String = String(archetype_id)
		_connect_pressed(opponent_button, func() -> void: _set_combat_lab_opponent(selected_id))
		opponent_row.add_child(opponent_button)

	var run_button := _make_button("Run Auto Duel")
	run_button.disabled = not legal.ok
	_connect_pressed(run_button, _run_combat_lab_duel)
	panel.add_child(run_button)

	var manual_button := _make_button("Start Manual Battle")
	manual_button.disabled = not legal.ok
	_connect_pressed(manual_button, _start_manual_combat_lab_battle)
	panel.add_child(manual_button)

	if not run.get("manual_combat", {}).is_empty():
		_add_manual_combat_lab(content, run.manual_combat)

	if run.get("last_combat", {}).is_empty():
		return

	var result: Dictionary = run.last_combat
	var summary := _add_panel(content, "Last Combat Test", "#253044" if result.get("winner", "") == "player" else "#442525")
	_add_body_text(summary, "Winner: %s | Seed: %d | Opponent: %s" % [
		String(result.get("winner", "")).capitalize(),
		int(result.get("seed", 0)),
		archetypes_by_id[String(result.get("opponent_archetype", opponent_archetype))].name
	])
	_add_body_text(summary, "Final life: You %d, Opponent %d | Turns: %d" % [
		int(result.get("player_life", 0)),
		int(result.get("opponent_life", 0)),
		int(result.get("turns", 0))
	])

	var snapshots := HBoxContainer.new()
	snapshots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	snapshots.add_theme_constant_override("separation", 10)
	content.add_child(snapshots)
	_add_combatant_snapshot(snapshots, "You", result.get("player_state", {}))
	_add_combatant_snapshot(snapshots, "Opponent", result.get("opponent_state", {}))

	var log_panel := _add_panel(content, "Combat Log")
	for line in result.get("log", []):
		_add_body_text(log_panel, "• " + String(line))


func _show_ui_combat() -> void:
	if _guard_run_over():
		return
	current_screen = "ui_combat"
	if manual_drag_candidate.is_empty() and manual_drag_state.is_empty():
		_manual_free_orphan_hand_drag_ghosts()
	_render_nav()
	_clear(content)
	_update_status()

	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype: String = String(metrics.primary)
	var opponent_archetype: String = _combat_lab_opponent_for(player_archetype)
	var legal := _deck_is_legal()

	if not run.get("manual_combat", {}).is_empty():
		var setup_bar := HBoxContainer.new()
		setup_bar.name = "UICombatSetupBar"
		setup_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		setup_bar.add_theme_constant_override("separation", 8)
		content.add_child(setup_bar)

		var setup_label := Label.new()
		setup_label.text = "%s vs %s" % [archetypes_by_id[player_archetype].name, archetypes_by_id[opponent_archetype].name]
		setup_label.add_theme_color_override("font_color", Color("#9aa7b7"))
		setup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		setup_bar.add_child(setup_label)

		var restart_button := _make_button("Restart UI Battle")
		restart_button.disabled = not legal.ok
		_connect_pressed(restart_button, _start_manual_combat_lab_battle)
		setup_bar.add_child(restart_button)

		_add_manual_combat_lab(content, run.manual_combat)
		return

	var panel := _add_panel(content, "UI Combat")
	_add_body_text(panel, "Your deck: %s | Opponent: %s" % [archetypes_by_id[player_archetype].name, archetypes_by_id[opponent_archetype].name])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var opponent_row := HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 6)
	panel.add_child(opponent_row)

	var opponent_label := Label.new()
	opponent_label.text = "Opponent:"
	opponent_label.add_theme_color_override("font_color", Color("#c7d0df"))
	opponent_row.add_child(opponent_label)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var opponent_button := _make_button(archetype.get("name", archetype_id))
		opponent_button.disabled = String(archetype_id) == opponent_archetype
		var selected_id: String = String(archetype_id)
		_connect_pressed(opponent_button, func() -> void: _set_combat_lab_opponent(selected_id))
		opponent_row.add_child(opponent_button)

	var start_button := _make_button("Start UI Battle" if run.get("manual_combat", {}).is_empty() else "Restart UI Battle")
	start_button.disabled = not legal.ok
	_connect_pressed(start_button, _start_manual_combat_lab_battle)
	panel.add_child(start_button)

	if run.get("manual_combat", {}).is_empty():
		return


func _show_active_combat_screen() -> void:
	if current_screen == "ui_combat":
		_show_ui_combat()
	else:
		_show_combat_lab()


func _combat_lab_opponent_for(player_archetype: String) -> String:
	if not run.has("combat_lab_opponent") or not archetypes_by_id.has(String(run.get("combat_lab_opponent", ""))):
		run.combat_lab_opponent = _predator_archetype(player_archetype)
	return String(run.combat_lab_opponent)


func _set_combat_lab_opponent(archetype_id: String) -> void:
	_manual_clear_hand_card_drag()
	run.combat_lab_opponent = archetype_id
	run.last_combat = {}
	run.manual_combat = {}
	run.manual_selection = {}
	run.manual_inspect = {}
	run.manual_battle_log_open = false
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_pending_action = {}
	_set_footer("Combat Lab opponent set to " + archetypes_by_id[archetype_id].name + ".")
	_show_active_combat_screen()


func _run_combat_lab_duel() -> void:
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype := String(metrics.primary)
	var opponent_archetype := _combat_lab_opponent_for(player_archetype)
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var seed_value := rng.randi()
	var state: Dictionary = combat_service.auto_play_game(run.deck, player_archetype, opponent_deck, opponent_archetype, seed_value)

	run.last_combat = {
		"seed": seed_value,
		"winner": state.get("winner", ""),
		"player_archetype": player_archetype,
		"opponent_archetype": opponent_archetype,
		"turns": int(state.get("turn", 0)),
		"player_life": int(state.get("player", {}).get("life", 0)),
		"opponent_life": int(state.get("opponent", {}).get("life", 0)),
		"player_board": state.get("player", {}).get("board", []).size(),
		"opponent_board": state.get("opponent", {}).get("board", []).size(),
		"player_state": _summarize_combatant(state.get("player", {})),
		"opponent_state": _summarize_combatant(state.get("opponent", {})),
		"log": state.get("log", [])
	}
	_set_footer("Combat Lab auto-duel complete.")
	_show_combat_lab()


func _start_manual_combat_lab_battle() -> void:
	_manual_clear_hand_card_drag()
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype := String(metrics.primary)
	var opponent_archetype := _combat_lab_opponent_for(player_archetype)
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var seed_value := rng.randi()
	run.manual_combat = combat_service.start_manual_game(run.deck, player_archetype, opponent_deck, opponent_archetype, seed_value)
	run.manual_selection = {}
	run.manual_inspect = {}
	run.manual_battle_log_open = false
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_pending_action = {}
	run.last_combat = {}
	_set_footer("Manual battle started.")
	_show_active_combat_screen()


func _manual_play_card(card_id: String) -> void:
	_manual_play_card_to_slot(card_id, -1)


func _manual_play_card_to_slot(card_id: String, desired_slot_index: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var after_state: Dictionary = combat_service.manual_play_card(before_state.duplicate(true), card_id)
	var destination_anchor := _manual_play_destination_anchor(before_state, after_state, card_id, "auto", current_screen == "ui_combat")
	if cards_by_id.has(card_id):
		match _combat_card_type(cards_by_id[card_id]):
			"threat":
				var placed_slot_index := _manual_assign_new_unit_board_slot(before_state, after_state, "player", card_id, desired_slot_index)
				destination_anchor = _manual_play_destination_anchor(before_state, after_state, card_id, "auto", current_screen == "ui_combat", placed_slot_index)
			"engine":
				var placed_engine_slot := _manual_assign_new_engine_slot(before_state, after_state, "player", card_id, desired_slot_index)
				if current_screen == "ui_combat" and placed_engine_slot >= 0:
					destination_anchor = _manual_engine_slot_anchor(true, placed_engine_slot)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": card_id,
		"source_zone": "Your Hand",
		"target_zone": _manual_play_destination_zone(card_id, "auto"),
		"destination_zone": _manual_play_destination_zone(card_id, "auto"),
		"source_anchor": _manual_hand_card_anchor(card_id),
		"target_anchor": destination_anchor,
		"destination_anchor": destination_anchor,
		"verb": "Play"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_play_card_target(card_id: String, target_type: String, target_instance_id: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var after_state: Dictionary = combat_service.manual_play_card_with_target(before_state.duplicate(true), card_id, target_type, target_instance_id)
	var target_anchor := _manual_target_anchor(before_state, target_type, target_instance_id, false)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": card_id,
		"source_zone": "Your Hand",
		"target_zone": _manual_target_zone_label(before_state, target_type, target_instance_id),
		"destination_zone": _manual_play_destination_zone(card_id, target_type),
		"source_anchor": _manual_hand_card_anchor(card_id),
		"target_anchor": target_anchor,
		"destination_anchor": _manual_play_destination_anchor(before_state, after_state, card_id, target_type, current_screen == "ui_combat"),
		"verb": "Cast"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_attack(instance_id: int, target_mode: String) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var attacker := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var target_anchor := _manual_target_anchor(before_state, target_mode, -1, false)
	var after_state: Dictionary = combat_service.manual_attack(before_state.duplicate(true), instance_id, target_mode)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(attacker.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": "Best Legal Target",
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": target_anchor if target_anchor != "" else "ManualOpponentPanel",
		"destination_anchor": source_anchor,
		"verb": "Attack"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_attack_target(instance_id: int, target_type: String, target_instance_id: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var attacker := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var after_state: Dictionary = combat_service.manual_attack_target(before_state.duplicate(true), instance_id, target_type, target_instance_id)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(attacker.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": _manual_target_zone_label(before_state, target_type, target_instance_id),
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": _manual_target_anchor(before_state, target_type, target_instance_id, false),
		"destination_anchor": source_anchor,
		"verb": "Attack"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_activate_unit_ability(instance_id: int, ability_index: int) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var unit := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var after_state: Dictionary = combat_service.manual_activate_unit_ability(before_state.duplicate(true), instance_id, ability_index)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(unit.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": "Ability",
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": source_anchor,
		"destination_anchor": source_anchor,
		"verb": "Activate"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_end_turn() -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	run.manual_combat = combat_service.manual_end_player_turn(run.manual_combat)
	_manual_set_animation_queue(_manual_build_opponent_turn_animation_queue(before_state, run.manual_combat, log_start))
	run.manual_selection = {}
	_show_active_combat_screen()


func _clear_manual_battle() -> void:
	_manual_clear_hand_card_drag()
	run.manual_combat = {}
	run.manual_selection = {}
	run.manual_inspect = {}
	run.manual_battle_log_open = false
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_pending_action = {}
	_set_footer("Manual battle cleared.")
	_show_active_combat_screen()


func _toggle_manual_battle_log() -> void:
	if run.is_empty():
		return
	run.manual_battle_log_open = not bool(run.get("manual_battle_log_open", false))
	_show_active_combat_screen()


func _manual_clear_inspect_overlay() -> void:
	if run.is_empty():
		return
	if run.get("manual_inspect", {}).is_empty():
		return
	run.manual_inspect = {}
	if current_screen == "ui_combat":
		_show_active_combat_screen()
	else:
		_refresh_manual_inspect_panel()


func _manual_select_card(card_id: String) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	run.manual_selection = { "kind": "card", "card_id": card_id }
	_manual_set_inspect_card(card_id, "Hand", "", true)
	_set_footer("Selected " + cards_by_id[card_id].get("name", card_id) + ". Choose a highlighted target.")
	_show_active_combat_screen()


func _manual_select_attacker(instance_id: int) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	run.manual_selection = { "kind": "attacker", "instance_id": instance_id }
	var attacker := _manual_find_player_unit(run.manual_combat, instance_id)
	if not attacker.is_empty():
		_manual_set_inspect_card(String(attacker.get("card_id", "")), "Your Board", _manual_current_unit_summary(attacker), true)
	_set_footer("Selected attacker. Choose a highlighted target.")
	_show_active_combat_screen()


func _manual_clear_selection() -> void:
	run.manual_selection = {}
	_set_footer("Selection cleared.")
	_show_active_combat_screen()


func _manual_target_face() -> void:
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			_manual_play_card_target(String(selection.get("card_id", "")), "face", -1)
		"attacker":
			_manual_attack_target(int(selection.get("instance_id", -1)), "face", -1)


func _manual_target_unit(instance_id: int) -> void:
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			_manual_play_card_target(String(selection.get("card_id", "")), "unit", instance_id)
		"attacker":
			_manual_attack_target(int(selection.get("instance_id", -1)), "unit", instance_id)


func _manual_commit_action_animation(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int) -> void:
	var animation := _manual_build_action_animation(before_state, after_state, descriptor, log_start)
	if animation.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
		return
	run.manual_animation = animation
	run.manual_animation_queue = []


func _manual_stage_or_commit_player_action(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int) -> void:
	var animation := _manual_build_action_animation(before_state, after_state, descriptor, log_start)
	if current_screen == "ui_combat" and _manual_card_action_commits_immediately(descriptor):
		run.manual_combat = after_state
		run.manual_pending_action = {}
		if animation.is_empty():
			run.manual_animation = {}
			run.manual_animation_queue = []
		else:
			animation["board_vfx_started"] = true
			run.manual_animation = animation
			run.manual_animation_queue = []
		return
	if current_screen == "ui_combat" and not animation.is_empty():
		_manual_stage_pending_action(after_state, animation)
		return

	run.manual_combat = after_state
	if animation.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
	else:
		run.manual_animation = animation
		run.manual_animation_queue = []


func _manual_card_action_commits_immediately(descriptor: Dictionary) -> bool:
	if String(descriptor.get("source_zone", "")) != "Your Hand":
		return false
	var card_id := String(descriptor.get("card_id", ""))
	if card_id == "" or not cards_by_id.has(card_id):
		return false
	return _combat_card_type(cards_by_id[card_id]) == "threat"


func _manual_stage_pending_action(after_state: Dictionary, animation: Dictionary) -> void:
	animation["pending_commit"] = true
	run.manual_animation = animation
	run.manual_animation_queue = []
	run.manual_pending_action = {
		"after_state": after_state,
		"commit_scheduled": false
	}
	call_deferred("_manual_schedule_pending_action_commit")


func _manual_has_pending_action() -> bool:
	return not run.get("manual_pending_action", {}).is_empty()


func _manual_schedule_pending_action_commit() -> void:
	if run.is_empty():
		return
	var pending: Dictionary = run.get("manual_pending_action", {})
	if pending.is_empty():
		return
	if bool(pending.get("commit_scheduled", false)):
		return
	pending["commit_scheduled"] = true
	run.manual_pending_action = pending
	var timer := get_tree().create_timer(MANUAL_PENDING_ACTION_COMMIT_DELAY)
	timer.timeout.connect(Callable(self, "_manual_commit_pending_action"))


func _manual_commit_pending_action() -> void:
	if run.is_empty():
		return
	var pending: Dictionary = run.get("manual_pending_action", {})
	if pending.is_empty():
		return
	var after_state: Dictionary = pending.get("after_state", {})
	if not after_state.is_empty():
		run.manual_combat = after_state
	var animation: Dictionary = run.get("manual_animation", {})
	if not animation.is_empty():
		animation["board_vfx_started"] = true
		animation.erase("pending_commit")
		run.manual_animation = animation
	run.manual_pending_action = {}
	run.manual_selection = {}
	if current_screen == "ui_combat":
		_show_active_combat_screen()


func _manual_build_action_animation(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int, log_end: int = -1) -> Dictionary:
	var log_lines: Array = after_state.get("log", [])
	var new_lines: Array = []
	var end_index: int = log_lines.size() if log_end < 0 else int(min(log_end, log_lines.size()))
	for i in range(log_start, end_index):
		new_lines.append(String(log_lines[i]))

	if new_lines.is_empty() or not _manual_log_has_animation_event(new_lines):
		return {}

	var card_id := String(descriptor.get("card_id", ""))
	var card_name := String(descriptor.get("card_name", ""))
	if card_name == "" and cards_by_id.has(card_id):
		card_name = String(cards_by_id[card_id].get("name", card_id))
	if card_name == "":
		card_name = String(descriptor.get("verb", "Action"))

	return {
		"card_id": card_id,
		"card_name": card_name,
		"source_zone": String(descriptor.get("source_zone", "Source")),
		"target_zone": String(descriptor.get("target_zone", "Target")),
		"destination_zone": String(descriptor.get("destination_zone", "Destination")),
		"source_anchor": String(descriptor.get("source_anchor", "")),
		"target_anchor": String(descriptor.get("target_anchor", "")),
		"destination_anchor": String(descriptor.get("destination_anchor", "")),
		"source_global_point": _manual_capture_anchor_global_point(String(descriptor.get("source_anchor", ""))),
		"target_global_point": _manual_capture_anchor_global_point(String(descriptor.get("target_anchor", ""))),
		"destination_global_point": _manual_capture_anchor_global_point(String(descriptor.get("destination_anchor", ""))),
		"verb": String(descriptor.get("verb", "Action")),
		"summary": new_lines.slice(max(0, new_lines.size() - 4), new_lines.size()),
		"badges": _manual_impact_badges_from_log(new_lines)
	}


func _manual_set_animation_queue(animations: Array) -> void:
	if animations.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
		return
	run.manual_animation = animations[0]
	run.manual_animation_queue = animations.slice(1, animations.size()) if animations.size() > 1 else []


func _manual_build_opponent_turn_animation_queue(before_state: Dictionary, after_state: Dictionary, log_start: int) -> Array:
	var animations: Array = []
	var log_lines: Array = after_state.get("log", [])
	var used_new_units := {}
	var used_action_counts := {}
	var in_opponent_turn := false
	for i in range(log_start, log_lines.size()):
		var line := String(log_lines[i])
		if line.begins_with("Opponent turn"):
			in_opponent_turn = true
			continue
		if in_opponent_turn and line.begins_with("You turn"):
			break
		if not in_opponent_turn:
			continue

		var descriptor := _manual_opponent_animation_descriptor_for_line(line, before_state, after_state, used_new_units, used_action_counts)
		if descriptor.is_empty():
			continue
		var animation := _manual_build_action_animation(before_state, after_state, descriptor, i, i + 1)
		if not animation.is_empty():
			animations.append(animation)
	return animations


func _manual_opponent_animation_descriptor_for_line(line: String, before_state: Dictionary, after_state: Dictionary, used_new_units: Dictionary, used_action_counts: Dictionary) -> Dictionary:
	if line.begins_with("Opponent plays engine "):
		var engine_name := _manual_trim_sentence_end(_manual_text_after(line, "Opponent plays engine "))
		var engine_id := _manual_card_id_for_name(engine_name, before_state, after_state)
		return {
			"card_id": engine_id,
			"card_name": engine_name,
			"source_zone": "Opponent Hand",
			"target_zone": "Opponent Engine Zone",
			"destination_zone": "Opponent Engine Zone",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": "ManualZone_OpponentEngine",
			"destination_anchor": "ManualZone_OpponentEngine",
			"verb": "Play"
		}

	if line.begins_with("Opponent plays "):
		var unit_name := _manual_text_between(line, "Opponent plays ", " as a ")
		if unit_name == "":
			return {}
		var unit_card_id := _manual_card_id_for_name(unit_name, before_state, after_state)
		var unit_anchor := _manual_new_unit_anchor_for_event(before_state, after_state, "opponent", unit_card_id, used_new_units)
		if unit_anchor == "":
			unit_anchor = "ManualZone_OpponentBoard"
		return {
			"card_id": unit_card_id,
			"card_name": unit_name,
			"source_zone": "Opponent Hand",
			"target_zone": "Opponent Board",
			"destination_zone": "Opponent Board",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": unit_anchor,
			"destination_anchor": unit_anchor,
			"verb": "Play"
		}

	if line.begins_with("Opponent casts "):
		var cast_name := _manual_cast_card_name_from_line(line)
		if cast_name == "":
			return {}
		var cast_has_target := line.contains(" to ")
		var cast_target_name: String = _manual_trim_sentence_end(_manual_text_after(line, " to ")) if cast_has_target else ""
		var cast_target_anchor: String = _manual_target_anchor_for_opponent_log_name(before_state, after_state, cast_target_name) if cast_has_target else "ManualZone_OpponentBoard"
		return {
			"card_id": _manual_card_id_for_name(cast_name, before_state, after_state),
			"card_name": cast_name,
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(cast_target_name) if cast_has_target else "Action",
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": cast_target_anchor,
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	if line.begins_with("Opponent fires finisher "):
		var finisher_name := _manual_text_between(line, "Opponent fires finisher ", " at ")
		if finisher_name == "":
			return {}
		var finisher_target_name := _manual_trim_sentence_end(_manual_text_after(line, " at "))
		return {
			"card_id": _manual_card_id_for_name(finisher_name, before_state, after_state),
			"card_name": finisher_name,
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(finisher_target_name),
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": _manual_target_anchor_for_opponent_log_name(before_state, after_state, finisher_target_name),
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	var effect_action_id := _manual_opponent_action_card_id_from_effect_line(line, before_state, after_state, used_action_counts)
	if effect_action_id != "":
		used_action_counts[effect_action_id] = int(used_action_counts.get(effect_action_id, 0)) + 1
		var effect_target_name := _manual_effect_target_name_from_line(line)
		var has_effect_target := effect_target_name != ""
		return {
			"card_id": effect_action_id,
			"card_name": String(cards_by_id[effect_action_id].get("name", effect_action_id)),
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(effect_target_name) if has_effect_target else "Action",
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": _manual_target_anchor_for_opponent_log_name(before_state, after_state, effect_target_name) if has_effect_target else "ManualZone_OpponentBoard",
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	if line.contains(" attacks You for "):
		var attacker_name := _manual_text_between(line, "", " attacks You for ")
		var source_anchor := _manual_unit_anchor_by_name(before_state, after_state, "opponent", attacker_name)
		return {
			"card_id": _manual_unit_card_id_by_name(before_state, after_state, "opponent", attacker_name),
			"card_name": attacker_name,
			"source_zone": "Opponent Board",
			"target_zone": "Your Face",
			"destination_zone": "Opponent Board",
			"source_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"target_anchor": _manual_face_anchor_for_side("player"),
			"destination_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"verb": "Attack"
		}

	if line.contains(" trades with "):
		var attacker_name := _manual_text_between(line, "", " trades with ")
		var target_name := _manual_trim_sentence_end(_manual_text_after(line, " trades with "))
		var source_anchor := _manual_unit_anchor_by_name(before_state, after_state, "opponent", attacker_name)
		var target_anchor := _manual_unit_anchor_by_name(before_state, after_state, "player", target_name)
		return {
			"card_id": _manual_unit_card_id_by_name(before_state, after_state, "opponent", attacker_name),
			"card_name": attacker_name,
			"source_zone": "Opponent Board",
			"target_zone": "Your Board",
			"destination_zone": "Opponent Board",
			"source_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"target_anchor": target_anchor if target_anchor != "" else "ManualZone_PlayerBoard",
			"destination_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"verb": "Attack"
		}

	return {}


func _manual_cast_card_name_from_line(line: String) -> String:
	var card_name := _manual_text_between(line, "Opponent casts ", " for ")
	if card_name != "":
		return card_name
	card_name = _manual_text_between(line, "Opponent casts ", " and draws")
	if card_name != "":
		return card_name
	return _manual_text_between(line, "Opponent casts ", " for tempo")


func _manual_opponent_action_card_id_from_effect_line(line: String, before_state: Dictionary, after_state: Dictionary, used_action_counts: Dictionary) -> String:
	var available_counts := _manual_new_opponent_discarded_action_counts(before_state, after_state)
	for card_id_value in available_counts.keys():
		var card_id := String(card_id_value)
		if int(used_action_counts.get(card_id, 0)) >= int(available_counts.get(card_id, 0)):
			continue
		if not cards_by_id.has(card_id):
			continue
		var card_name := String(cards_by_id[card_id].get("name", card_id))
		if line.begins_with(card_name + " ") or line.begins_with(card_name + "'s "):
			return card_id
	return ""


func _manual_new_opponent_discarded_action_counts(before_state: Dictionary, after_state: Dictionary) -> Dictionary:
	var before_counts := _manual_card_count_map(before_state.get("opponent", {}).get("discard", []))
	var after_counts := _manual_card_count_map(after_state.get("opponent", {}).get("discard", []))
	var counts := {}
	for card_id_value in after_counts.keys():
		var card_id := String(card_id_value)
		var delta := int(after_counts.get(card_id, 0)) - int(before_counts.get(card_id, 0))
		if delta <= 0 or not cards_by_id.has(card_id):
			continue
		if _combat_card_type(cards_by_id[card_id]) == "action":
			counts[card_id] = delta
	return counts


func _manual_card_count_map(card_ids: Array) -> Dictionary:
	var counts := {}
	for card_id_value in card_ids:
		var card_id := String(card_id_value)
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	return counts


func _manual_effect_target_name_from_line(line: String) -> String:
	return _manual_trim_sentence_end(_manual_text_after(line, " to "))


func _manual_target_anchor_for_opponent_log_name(before_state: Dictionary, after_state: Dictionary, target_name: String) -> String:
	if target_name == "" or target_name == "You":
		return _manual_face_anchor_for_side("player")
	if target_name == "Opponent":
		return _manual_face_anchor_for_side("opponent")
	var player_unit_anchor := _manual_unit_anchor_by_name(before_state, after_state, "player", target_name)
	if player_unit_anchor != "":
		return player_unit_anchor
	return "ManualZone_PlayerBoard"


func _manual_target_zone_for_opponent_log_name(target_name: String) -> String:
	if target_name == "" or target_name == "You":
		return "Your Face"
	if target_name == "Opponent":
		return "Opponent Face"
	return "Your Board"


func _manual_face_anchor_for_side(side: String) -> String:
	if current_screen == "ui_combat":
		return "ManualFanHand" if side == "player" else "ManualOpponentFanHand"
	return "ManualPlayerPanel" if side == "player" else "ManualOpponentPanel"


func _manual_new_unit_anchor_for_event(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, used_new_units: Dictionary) -> String:
	var before_ids := {}
	var before_combatant: Dictionary = before_state.get(side, {})
	for unit in before_combatant.get("board", []):
		before_ids[int(unit.get("instance_id", -1))] = true
	var after_combatant: Dictionary = after_state.get(side, {})
	for unit in after_combatant.get("board", []):
		var instance_id := int(unit.get("instance_id", -1))
		if before_ids.has(instance_id) or used_new_units.has(instance_id):
			continue
		if card_id != "" and String(unit.get("card_id", "")) != card_id:
			continue
		used_new_units[instance_id] = true
		return _manual_unit_card_anchor(side == "player", instance_id)
	return ""


func _manual_unit_anchor_by_name(before_state: Dictionary, after_state: Dictionary, side: String, unit_name: String) -> String:
	var before_anchor := _manual_unit_anchor_by_name_in_state(before_state, side, unit_name)
	if before_anchor != "":
		return before_anchor
	return _manual_unit_anchor_by_name_in_state(after_state, side, unit_name)


func _manual_unit_anchor_by_name_in_state(state: Dictionary, side: String, unit_name: String) -> String:
	var combatant: Dictionary = state.get(side, {})
	for unit in combatant.get("board", []):
		if String(unit.get("name", "")) == unit_name:
			return _manual_unit_card_anchor(side == "player", int(unit.get("instance_id", -1)))
	return ""


func _manual_unit_card_id_by_name(before_state: Dictionary, after_state: Dictionary, side: String, unit_name: String) -> String:
	var before_id := _manual_unit_card_id_by_name_in_state(before_state, side, unit_name)
	if before_id != "":
		return before_id
	return _manual_unit_card_id_by_name_in_state(after_state, side, unit_name)


func _manual_unit_card_id_by_name_in_state(state: Dictionary, side: String, unit_name: String) -> String:
	var combatant: Dictionary = state.get(side, {})
	for unit in combatant.get("board", []):
		if String(unit.get("name", "")) == unit_name:
			return String(unit.get("card_id", ""))
	return ""


func _manual_card_id_for_name(card_name: String, before_state: Dictionary, after_state: Dictionary) -> String:
	var candidates: Array = []
	_manual_append_opponent_card_candidates(candidates, before_state)
	_manual_append_opponent_card_candidates(candidates, after_state)
	for card_id_value in candidates:
		var card_id := String(card_id_value)
		if cards_by_id.has(card_id) and String(cards_by_id[card_id].get("name", card_id)) == card_name:
			return card_id
	for card_id_value in cards_by_id.keys():
		var card_id := String(card_id_value)
		if String(cards_by_id[card_id].get("name", card_id)) == card_name:
			return card_id
	return ""


func _manual_append_opponent_card_candidates(candidates: Array, state: Dictionary) -> void:
	var opponent: Dictionary = state.get("opponent", {})
	for card_id in opponent.get("hand", []):
		candidates.append(String(card_id))
	for card_id in opponent.get("discard", []):
		candidates.append(String(card_id))
	for unit in opponent.get("board", []):
		candidates.append(String(unit.get("card_id", "")))
	for engine in opponent.get("engines", []):
		candidates.append(String(engine.get("card_id", "")))


func _manual_text_between(text: String, prefix: String, suffix: String) -> String:
	var start := 0
	if prefix != "":
		start = text.find(prefix)
		if start < 0:
			return ""
		start += prefix.length()
	var end := text.find(suffix, start)
	if end < 0:
		return ""
	return text.substr(start, end - start).strip_edges()


func _manual_text_after(text: String, prefix: String) -> String:
	var start := text.find(prefix)
	if start < 0:
		return ""
	start += prefix.length()
	return text.substr(start).strip_edges()


func _manual_trim_sentence_end(text: String) -> String:
	var trimmed := text.strip_edges()
	while trimmed.ends_with("."):
		trimmed = trimmed.substr(0, trimmed.length() - 1).strip_edges()
	return trimmed


func _manual_log_has_animation_event(lines: Array) -> bool:
	for line_value in lines:
		var lower := String(line_value).to_lower()
		if lower.contains("plays") or lower.contains("casts") or lower.contains("attacks") or lower.contains("deals"):
			return true
		if lower.contains("damage") or lower.contains("trades") or lower.contains("dies") or lower.contains("destroy"):
			return true
		if lower.contains("restore") or lower.contains("heal") or lower.contains("draw") or lower.contains("creates"):
			return true
		if lower.contains("activates") or lower.contains("exhausts") or lower.contains("gains"):
			return true
	return false


func _manual_impact_badges_from_log(lines: Array) -> Array:
	var badges: Array = []
	for line_value in lines:
		var line := String(line_value)
		var lower := line.to_lower()
		var amount := _manual_first_int_in_text(line)
		if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("takes"):
			badges.append({
				"kind": "damage",
				"text": "-%d" % max(1, amount),
				"line": line
			})
		elif lower.contains("restore") or lower.contains("heal"):
			badges.append({
				"kind": "heal",
				"text": "+%d" % max(0, amount),
				"line": line
			})
		elif lower.contains("draw"):
			badges.append({
				"kind": "draw",
				"text": "DRAW %d" % max(1, amount),
				"line": line
			})
		elif lower.contains("creates") or lower.contains("plays") or lower.contains("casts"):
			badges.append({
				"kind": "play",
				"text": "PLAY",
				"line": line
			})
		elif lower.contains("dies") or lower.contains("destroy"):
			badges.append({
				"kind": "ko",
				"text": "KO",
				"line": line
			})
		elif lower.contains("gains") and lower.contains("focus"):
			badges.append({
				"kind": "focus",
				"text": "+%d FOCUS" % max(1, amount),
				"line": line
			})
	if badges.size() > 5:
		return badges.slice(0, 5)
	return badges


func _manual_first_int_in_text(text: String) -> int:
	var digits := ""
	for i in range(text.length()):
		var character := text.substr(i, 1)
		if character >= "0" and character <= "9":
			digits += character
		elif digits != "":
			break
	if digits == "":
		return 0
	return int(digits)


func _manual_play_destination_zone(card_id: String, target_type: String) -> String:
	if not cards_by_id.has(card_id):
		return "Destination"
	var card: Dictionary = cards_by_id[card_id]
	match _combat_card_type(card):
		"threat":
			return "Your Board"
		"engine":
			return "Your Engine Zone"
		"action":
			if target_type == "face":
				return "Opponent Face, then Discard"
			if target_type == "unit":
				return "Opponent Board, then Discard"
			return "Discard Zone"
	return "Destination"


func _manual_target_zone_label(state: Dictionary, target_type: String, target_instance_id: int) -> String:
	match target_type:
		"face":
			return "Opponent Face"
		"unit":
			var opponent: Dictionary = state.get("opponent", {})
			for unit in opponent.get("board", []):
				if int(unit.get("instance_id", -1)) == target_instance_id:
					return "Opponent Board: " + String(unit.get("name", "Unit"))
			return "Opponent Board"
		"auto":
			return "Auto Target"
		_:
			return "Target"


func _manual_play_destination_anchor(before_state: Dictionary, after_state: Dictionary, card_id: String, target_type: String, prefer_slot_anchor: bool = false, preferred_slot_index: int = -1) -> String:
	if not cards_by_id.has(card_id):
		return "ManualZone_PlayerDiscard"
	var card: Dictionary = cards_by_id[card_id]
	match _combat_card_type(card):
		"threat":
			if prefer_slot_anchor:
				if preferred_slot_index >= 0:
					return _manual_board_slot_anchor(true, preferred_slot_index)
				var slot_anchor := _manual_new_unit_slot_anchor(before_state, after_state, "player", card_id)
				if slot_anchor != "":
					return slot_anchor
			var new_unit_anchor := _manual_new_unit_anchor(before_state, after_state, "player", card_id)
			return new_unit_anchor if new_unit_anchor != "" else "ManualZone_PlayerBoard"
		"engine":
			return "ManualZone_PlayerEngine"
		"action":
			if target_type == "face" or target_type == "unit":
				return "ManualZone_PlayerDiscard"
			return "ManualZone_PlayerDiscard"
	return "ManualZone_PlayerDiscard"


func _manual_new_unit_slot_anchor(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String) -> String:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))
	var after_board: Array = after_combatant.get("board", [])
	var slotted_units := _manual_units_by_board_slot(after_board)
	for slot_index in range(slotted_units.size()):
		var unit: Dictionary = slotted_units[slot_index]
		if unit.is_empty():
			continue
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			return _manual_board_slot_anchor(side == "player", slot_index)
	return ""


func _manual_target_anchor(state: Dictionary, target_type: String, target_instance_id: int, prefer_face_affordance: bool) -> String:
	match target_type:
		"face":
			if current_screen == "ui_combat":
				return "ManualFaceTargetAffordance" if prefer_face_affordance else "ManualOpponentFanHand"
			return "ManualFaceTargetAffordance" if prefer_face_affordance else "ManualOpponentPanel"
		"unit":
			return _manual_unit_anchor(state, "opponent", target_instance_id)
		"player":
			return "ManualPlayerPanel"
		"auto":
			return "ManualOpponentPanel"
		_:
			return ""


func _manual_unit_anchor(state: Dictionary, side: String, instance_id: int) -> String:
	var combatant: Dictionary = state.get("player" if side == "player" else "opponent", {})
	var slot_index := _manual_unit_slot_index(combatant, instance_id)
	if slot_index >= 0:
		return _manual_unit_card_anchor(side == "player", instance_id)
	return "ManualZone_PlayerBoard" if side == "player" else "ManualZone_OpponentBoard"


func _manual_new_unit_anchor(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String) -> String:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))
	for unit_index in range(after_combatant.get("board", []).size()):
		var unit: Dictionary = after_combatant.get("board", [])[unit_index]
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			return _manual_unit_card_anchor(side == "player", int(unit.get("instance_id", -1)))
	return ""


func _manual_unit_slot_index(combatant: Dictionary, instance_id: int) -> int:
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	for unit_index in range(slotted_units.size()):
		var unit: Dictionary = slotted_units[unit_index]
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit_index
	return -1


func _manual_assign_new_unit_board_slot(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, desired_slot_index: int) -> int:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))

	var slot_index := desired_slot_index
	if not _manual_board_slot_is_open(before_combatant, slot_index):
		slot_index = _manual_first_open_board_slot(before_combatant)
	if slot_index < 0:
		return -1

	var after_board: Array = after_combatant.get("board", [])
	for unit in after_board:
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			unit["board_slot"] = slot_index
			return slot_index
	return -1


func _manual_board_slot_is_open(combatant: Dictionary, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= COMBAT_BOARD_SLOTS:
		return false
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	return slot_index < slotted_units.size() and slotted_units[slot_index].is_empty()


func _manual_first_open_board_slot(combatant: Dictionary) -> int:
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	for slot_index in range(slotted_units.size()):
		if slotted_units[slot_index].is_empty():
			return slot_index
	return -1


func _manual_units_by_board_slot(units: Array) -> Array:
	var slotted_units: Array = []
	for i in range(COMBAT_BOARD_SLOTS):
		slotted_units.append({})

	var deferred_units: Array = []
	for unit_value in units:
		var unit: Dictionary = unit_value
		var desired_slot := int(unit.get("board_slot", -1))
		if desired_slot >= 0 and desired_slot < COMBAT_BOARD_SLOTS and slotted_units[desired_slot].is_empty():
			slotted_units[desired_slot] = unit
		else:
			deferred_units.append(unit)

	for unit in deferred_units:
		for slot_index in range(COMBAT_BOARD_SLOTS):
			if slotted_units[slot_index].is_empty():
				slotted_units[slot_index] = unit
				break
	return slotted_units


func _manual_assign_new_engine_slot(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, desired_slot_index: int) -> int:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var slot_index := desired_slot_index
	if not _manual_engine_slot_is_open(before_combatant, slot_index):
		slot_index = _manual_first_open_engine_slot(before_combatant)
	if slot_index < 0:
		return -1

	var remaining_existing := 0
	for engine in before_combatant.get("engines", []):
		if String(engine.get("card_id", "")) == card_id:
			remaining_existing += 1

	for engine in after_combatant.get("engines", []):
		if String(engine.get("card_id", "")) != card_id:
			continue
		if remaining_existing > 0:
			remaining_existing -= 1
			continue
		engine["engine_slot"] = slot_index
		return slot_index
	return -1


func _manual_engine_slot_is_open(combatant: Dictionary, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= COMBAT_ENGINE_SLOTS:
		return false
	var slotted_engines := _manual_engines_by_slot(combatant.get("engines", []))
	return slot_index < slotted_engines.size() and slotted_engines[slot_index].is_empty()


func _manual_first_open_engine_slot(combatant: Dictionary) -> int:
	var slotted_engines := _manual_engines_by_slot(combatant.get("engines", []))
	for slot_index in range(slotted_engines.size()):
		if slotted_engines[slot_index].is_empty():
			return slot_index
	return -1


func _manual_engines_by_slot(engines: Array) -> Array:
	var slotted_engines: Array = []
	for i in range(COMBAT_ENGINE_SLOTS):
		slotted_engines.append({})

	var deferred_engines: Array = []
	for engine_value in engines:
		var engine: Dictionary = engine_value
		var desired_slot := int(engine.get("engine_slot", -1))
		if desired_slot >= 0 and desired_slot < COMBAT_ENGINE_SLOTS and slotted_engines[desired_slot].is_empty():
			slotted_engines[desired_slot] = engine
		else:
			deferred_engines.append(engine)

	for engine in deferred_engines:
		for slot_index in range(COMBAT_ENGINE_SLOTS):
			if slotted_engines[slot_index].is_empty():
				slotted_engines[slot_index] = engine
				break
	return slotted_engines


func _manual_engine_slot_anchor(is_player: bool, slot_index: int) -> String:
	return "ManualEngineSlot_%s_%d" % ["Player" if is_player else "Opponent", slot_index + 1]


func _manual_board_slot_anchor(is_player: bool, slot_index: int) -> String:
	return "ManualBoardSlot_%s_%d" % ["Player" if is_player else "Opponent", slot_index + 1]


func _manual_hand_card_anchor(card_id: String, hand_index: int = -1) -> String:
	var base := "CombatCardPanel_Hand_%s" % _manual_anchor_token(card_id)
	return base if hand_index < 0 else "%s_%d" % [base, hand_index]


func _manual_unit_card_anchor(is_player: bool, instance_id: int) -> String:
	return "CombatCardPanel_%sUnit_%d" % ["Player" if is_player else "Opponent", instance_id]


func _manual_anchor_token(value: String) -> String:
	var token := ""
	for i in range(value.length()):
		var character := value.substr(i, 1)
		if (character >= "a" and character <= "z") or (character >= "A" and character <= "Z") or (character >= "0" and character <= "9") or character == "_":
			token += character
		else:
			token += "_"
	return token


func _add_manual_combat_lab(parent: Node, state: Dictionary) -> void:
	var is_over := bool(state.get("game_over", false))
	var phase := String(state.get("phase", ""))
	var player: Dictionary = state.get("player", {})
	var opponent: Dictionary = state.get("opponent", {})
	var opponent_name := _archetype_label(String(opponent.get("archetype", "")))

	if current_screen == "ui_combat":
		_add_ui_combat_header(parent, state, is_over, phase, opponent_name)
		_add_ui_combat_battle_log(parent, state)
		_add_ui_combat_duel(parent, state, is_over, phase)
		return

	var panel := _add_panel(parent, "Manual Battle", "#253044" if not is_over else "#442525")
	if is_over:
		_add_body_text(panel, "Winner: %s | Opponent: %s | Turn %d" % [
			String(state.get("winner", "")).capitalize(),
			opponent_name,
			int(state.get("turn", 0))
		])
	else:
		_add_body_text(panel, "Phase: %s | Opponent: %s | Turn %d | Seed %d" % [
			phase.replace("_", " ").capitalize(),
			opponent_name,
			int(state.get("turn", 0)),
			int(state.get("seed", 0))
		])

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	panel.add_child(controls)

	var end_button := _make_button("End Turn")
	end_button.disabled = is_over or phase != "player_main" or _manual_has_pending_action()
	_connect_pressed(end_button, _manual_end_turn)
	controls.add_child(end_button)

	var clear_button := _make_button("Clear Manual Battle")
	_connect_pressed(clear_button, _clear_manual_battle)
	controls.add_child(clear_button)

	var selection_row := HBoxContainer.new()
	selection_row.add_theme_constant_override("separation", 6)
	panel.add_child(selection_row)

	var selection_label := Label.new()
	selection_label.text = _manual_selection_label(state)
	selection_label.add_theme_color_override("font_color", Color("#ffe08a") if not _manual_selection().is_empty() else Color("#c7d0df"))
	selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_row.add_child(selection_label)

	var cancel_selection := _make_button("Cancel Selection")
	cancel_selection.disabled = _manual_selection().is_empty()
	_connect_pressed(cancel_selection, _manual_clear_selection)
	selection_row.add_child(cancel_selection)

	_add_manual_recent_events(parent, state)
	if current_screen == "ui_combat":
		_add_manual_action_summary(parent)
	else:
		_add_manual_action_animation(parent)

	var battlefield := _add_manual_battlefield(parent)
	_add_manual_inspect_panel(battlefield, state)
	var arena := VBoxContainer.new()
	arena.name = "ManualArenaZones"
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 10)
	battlefield.add_child(arena)
	_add_manual_combatant_panel(arena, "Opponent", opponent, false, state)
	_add_manual_combatant_panel(arena, "You", player, true, state)
	if current_screen == "ui_combat":
		var board_arc_layer := Node2D.new()
		board_arc_layer.name = "ManualBoardArcLayer"
		board_arc_layer.z_index = 120
		arena.add_child(board_arc_layer)
		call_deferred("_refresh_manual_board_arc_layer", board_arc_layer)

	var log_panel := _add_panel(parent, "Manual Battle Log")
	var log_lines: Array = state.get("log", [])
	var start_index: int = max(0, log_lines.size() - 18)
	for i in range(start_index, log_lines.size()):
		_add_body_text(log_panel, "• " + String(log_lines[i]))


func _add_ui_combat_header(parent: Node, state: Dictionary, is_over: bool, phase: String, opponent_name: String) -> void:
	var panel := _add_panel(parent, "", "#1b2330" if not is_over else "#442525")
	panel.name = "UICombatHeader"

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var log_open := bool(run.get("manual_battle_log_open", false))
	var log_button := _make_button("Hide Log" if log_open else "Battle Log")
	log_button.name = "ManualBattleLogButton"
	_style_button(log_button, "selected" if log_open else "action")
	_connect_pressed(log_button, _toggle_manual_battle_log)
	row.add_child(log_button)

	var status := Label.new()
	status.text = "Duel | Turn %d | %s | Opponent: %s" % [
		int(state.get("turn", 0)),
		phase.replace("_", " ").capitalize(),
		opponent_name
	]
	status.add_theme_color_override("font_color", Color("#d8dfec"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)

	var selection := Label.new()
	selection.text = _manual_selection_label(state)
	selection.add_theme_color_override("font_color", Color("#ffe08a") if not _manual_selection().is_empty() else Color("#9aa7b7"))
	selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(selection)

	var cancel_selection := _make_button("Cancel")
	cancel_selection.disabled = _manual_selection().is_empty()
	_connect_pressed(cancel_selection, _manual_clear_selection)
	row.add_child(cancel_selection)

	var clear_button := _make_button("Clear")
	_connect_pressed(clear_button, _clear_manual_battle)
	row.add_child(clear_button)


func _add_ui_combat_battle_log(parent: Node, state: Dictionary) -> void:
	if not bool(run.get("manual_battle_log_open", false)):
		return

	var panel := _add_panel(parent, "Battle Log", "#151d28")
	panel.name = "ManualBattleLogPanel"

	var row := HBoxContainer.new()
	row.name = "ManualBattleLogRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	_add_manual_action_summary(row)
	_add_manual_recent_events(row, state)

	var log_lines: Array = state.get("log", [])
	var lines_box := VBoxContainer.new()
	lines_box.name = "ManualBattleLogLines"
	lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_box.add_theme_constant_override("separation", 2)
	row.add_child(lines_box)

	if log_lines.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No battle events yet."
		empty_label.add_theme_color_override("font_color", Color("#7e8794"))
		lines_box.add_child(empty_label)
		return

	var start_index: int = max(0, log_lines.size() - 5)
	for i in range(start_index, log_lines.size()):
		var line := Label.new()
		line.text = "• " + String(log_lines[i])
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 11)
		line.add_theme_color_override("font_color", _manual_log_line_color(String(log_lines[i])))
		lines_box.add_child(line)


func _add_ui_combat_duel(parent: Node, state: Dictionary, is_over: bool, phase: String) -> void:
	var player: Dictionary = state.get("player", {})
	var opponent: Dictionary = state.get("opponent", {})

	var battlefield := _add_manual_battlefield(parent)
	battlefield.name = "UICombatBattlefield"
	battlefield.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_manual_clear_inspect_overlay()
	)

	var arena := VBoxContainer.new()
	arena.name = "ManualArenaZones"
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena.offset_left = 0
	arena.offset_top = 0
	arena.offset_right = 0
	arena.offset_bottom = 0
	arena.add_theme_constant_override("separation", 4)
	battlefield.add_child(arena)

	_add_ui_combat_opponent_hand(arena, opponent, state)
	_add_manual_engine_zone(arena, opponent.get("engines", []), false)
	_add_manual_board(arena, opponent.get("board", []), false, state)
	_add_manual_board(arena, player.get("board", []), true, state)
	_add_manual_engine_zone(arena, player.get("engines", []), true)
	_add_manual_hand(arena, player, state)

	var board_arc_layer := Node2D.new()
	board_arc_layer.name = "ManualBoardArcLayer"
	board_arc_layer.z_index = 120
	arena.add_child(board_arc_layer)
	call_deferred("_refresh_manual_board_arc_layer", board_arc_layer)

	_add_ui_combat_resource_readout(battlefield, player, true, state)
	_add_ui_combat_resource_readout(battlefield, opponent, false, state)
	_add_ui_combat_end_turn_overlay(battlefield, is_over, phase)
	_add_manual_inspect_panel(battlefield, state)


func _add_ui_combat_opponent_hand(parent: Node, opponent: Dictionary, state: Dictionary) -> void:
	var zone := _add_manual_zone(parent, "Hand Zone", "OpponentHand", "#182537")
	zone.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var fan := Control.new()
	fan.name = "ManualOpponentFanHand"
	fan.custom_minimum_size = Vector2(0, 34)
	fan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.add_child(fan)

	var hand_count := int(opponent.get("hand", []).size())
	if hand_count <= 0:
		_add_manual_empty_zone_slot(fan, "Empty Hand")
	else:
		for i in range(hand_count):
			_add_ui_combat_blank_hand_card(fan, i)
		call_deferred("_layout_ui_combat_opponent_hand", fan)
	if _manual_selection_can_try_face(state):
		_add_ui_combat_face_target_anchor(fan, _manual_selected_can_target_face(state))


func _add_ui_combat_face_target_anchor(parent: Control, selected_can_face: bool) -> void:
	var anchor := PanelContainer.new()
	anchor.name = "ManualFaceTargetAffordance"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.offset_left = 0.0
	anchor.offset_top = 0.0
	anchor.offset_right = 0.0
	anchor.offset_bottom = 0.0
	anchor.z_index = 25
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.22, 0.14, 0.12) if selected_can_face else Color(0.26, 0.14, 0.14, 0.10)
	style.border_color = Color(0.62, 0.9, 0.43, 0.68) if selected_can_face else Color(0.85, 0.63, 0.63, 0.35)
	style.border_width_left = 2 if selected_can_face else 1
	style.border_width_right = 2 if selected_can_face else 1
	style.border_width_top = 2 if selected_can_face else 1
	style.border_width_bottom = 2 if selected_can_face else 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	anchor.add_theme_stylebox_override("panel", style)
	parent.add_child(anchor)


func _add_ui_combat_blank_hand_card(parent: Node, index: int) -> void:
	var back := PanelContainer.new()
	back.name = "ManualCardBackSlot_%d" % (index + 1)
	back.custom_minimum_size = Vector2(32, 40)
	back.size = back.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172a36")
	style.border_color = Color("#05070a")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	back.add_theme_stylebox_override("panel", style)
	parent.add_child(back)


func _layout_ui_combat_opponent_hand(fan: Control) -> void:
	if not is_instance_valid(fan):
		return
	var backs: Array = []
	for child in fan.get_children():
		if child is Control and String(child.name).begins_with("ManualCardBackSlot"):
			backs.append(child)
	var count := backs.size()
	if count <= 0:
		return
	var card_size: Vector2 = backs[0].custom_minimum_size
	var available_width := fan.size.x
	if available_width <= 1.0:
		available_width = max(card_size.x, card_size.x + 34.0 * float(max(0, count - 1)))
	var spread: float = 0.0 if count == 1 else clamp((available_width - card_size.x) / float(count - 1), 30.0, 46.0)
	var total_width: float = card_size.x + spread * float(max(0, count - 1))
	var start_x: float = max(0.0, (available_width - total_width) * 0.5)
	var center_index: float = float(count - 1) * 0.5
	for index in range(count):
		var card_panel: Control = backs[index]
		var offset: float = float(index) - center_index
		card_panel.size = card_panel.custom_minimum_size
		card_panel.pivot_offset = card_panel.custom_minimum_size * 0.5
		card_panel.position = Vector2(start_x + spread * float(index), -6.0 + abs(offset) * 1.5)
		card_panel.rotation_degrees = offset * 8.0
		card_panel.z_index = index


func _add_ui_combat_resource_readout(parent: Node, combatant: Dictionary, is_player: bool, state: Dictionary) -> void:
	var can_try_face := not is_player and _manual_selection_can_try_face(state)
	var selected_can_face := can_try_face and _manual_selected_can_target_face(state)
	var panel := PanelContainer.new()
	panel.name = "ManualPlayerResourceReadout" if is_player else "ManualOpponentResourceReadout"
	panel.z_index = 110
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	if is_player:
		panel.anchor_left = 0.0
		panel.anchor_top = 1.0
		panel.anchor_right = 0.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 20.0
		panel.offset_top = -116.0
		panel.offset_right = 196.0
		panel.offset_bottom = -18.0
	else:
		panel.anchor_left = 1.0
		panel.anchor_top = 0.0
		panel.anchor_right = 1.0
		panel.anchor_bottom = 0.0
		panel.offset_left = -222.0
		panel.offset_top = 18.0
		panel.offset_right = -24.0
		panel.offset_bottom = 124.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.17, 0.72)
	style.border_color = Color(0.18, 0.27, 0.36, 0.62)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var readout := Label.new()
	readout.name = "ManualResourceReadoutText"
	readout.text = "Life: %d\nFocus: %d/%d%s" % [
		int(combatant.get("life", 0)),
		int(combatant.get("focus", 0)),
		int(combatant.get("max_focus", 0)),
		_manual_restricted_focus_text(combatant)
	]
	readout.add_theme_font_size_override("font_size", 22)
	readout.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(readout)

	if can_try_face:
		var face_button := _make_button(_manual_target_action_label() + " Face")
		face_button.name = "ManualFaceTargetButton"
		_style_button(face_button, "target" if selected_can_face else "danger")
		face_button.custom_minimum_size = Vector2(0, 24)
		face_button.disabled = not selected_can_face
		if not selected_can_face:
			face_button.tooltip_text = _manual_face_block_reason(state)
		_connect_pressed(face_button, _manual_target_face)
		box.add_child(face_button)


func _add_ui_combat_end_turn_overlay(parent: Node, is_over: bool, phase: String) -> void:
	var panel := PanelContainer.new()
	panel.name = "ManualContextPanel"
	panel.z_index = 115
	panel.anchor_left = 1.0
	panel.anchor_top = 0.5
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.5
	panel.offset_left = -194.0
	panel.offset_top = -24.0
	panel.offset_right = -28.0
	panel.offset_bottom = 22.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.13, 0.2, 0.78)
	style.border_color = Color("#05070a")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var end_button := _make_button("End Turn")
	end_button.name = "ManualEndTurnButton"
	_style_button(end_button, "action")
	end_button.add_theme_font_size_override("font_size", 18)
	end_button.custom_minimum_size = Vector2(150, 32)
	end_button.disabled = is_over or phase != "player_main" or _manual_has_pending_action()
	_connect_pressed(end_button, _manual_end_turn)
	margin.add_child(end_button)


func _add_ui_combat_board_controls(parent: Node, state: Dictionary, is_over: bool, phase: String) -> void:
	var row := HBoxContainer.new()
	row.name = "ManualBoardControls"
	row.custom_minimum_size = Vector2(0, 46)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var panel := _add_panel(row, "", "#172333")
	panel.name = "ManualContextPanel"
	panel.custom_minimum_size = Vector2(150, 0)

	var player: Dictionary = state.get("player", {})
	var focus := Label.new()
	focus.name = "ManualFocusReadout"
	focus.text = "Focus %d/%d%s" % [
		int(player.get("focus", 0)),
		int(player.get("max_focus", 0)),
		_manual_restricted_focus_text(player)
	]
	focus.add_theme_color_override("font_color", Color("#a9c7ff"))
	focus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(focus)

	_add_ui_context_selection_actions(panel, state)

	var end_button := _make_button("End Turn")
	end_button.name = "ManualEndTurnButton"
	_style_button(end_button, "action")
	end_button.disabled = is_over or phase != "player_main"
	_connect_pressed(end_button, _manual_end_turn)
	panel.add_child(end_button)


func _add_ui_context_selection_actions(parent: Node, state: Dictionary) -> void:
	var selection := _manual_selection()
	if selection.is_empty():
		var hint := Label.new()
		hint.name = "ManualContextHint"
		hint.text = "Select a card or ready unit."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", Color("#9aa7b7"))
		parent.add_child(hint)
		return

	match String(selection.get("kind", "")):
		"card":
			if _manual_selected_can_target_face(state):
				var face_button := _make_button("Cast Face")
				face_button.name = "ManualContextFaceButton"
				_style_button(face_button, "target")
				_connect_pressed(face_button, _manual_target_face)
				parent.add_child(face_button)
			var hint := Label.new()
			hint.name = "ManualContextHint"
			hint.text = "Choose a highlighted target."
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_color_override("font_color", Color("#ffe08a"))
			parent.add_child(hint)
		"attacker":
			if _manual_selected_can_target_face(state):
				var attack_face := _make_button("Attack Face")
				attack_face.name = "ManualContextFaceButton"
				_style_button(attack_face, "target")
				_connect_pressed(attack_face, _manual_target_face)
				parent.add_child(attack_face)
			var hint := Label.new()
			hint.name = "ManualContextHint"
			hint.text = "Attack a highlighted unit or face."
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_color_override("font_color", Color("#ffe08a"))
			parent.add_child(hint)


func _add_manual_recent_events(parent: Node, state: Dictionary) -> void:
	var log_lines: Array = state.get("log", [])
	if log_lines.is_empty():
		return

	var panel := _add_panel(parent, "Combat Feedback", "#1c2430")
	panel.name = "ManualFeedbackPanel"
	var chips := HBoxContainer.new()
	chips.name = "ManualFeedbackChips"
	chips.add_theme_constant_override("separation", 8)
	panel.add_child(chips)

	var start_index: int = max(0, log_lines.size() - 4)
	for i in range(start_index, log_lines.size()):
		_add_manual_feedback_chip(chips, String(log_lines[i]))


func _add_manual_action_animation(parent: Node) -> void:
	var animation: Dictionary = run.get("manual_animation", {})
	if animation.is_empty():
		return

	var panel := _add_panel(parent, "Action Animation", "#151d28")
	panel.name = "ManualAnimationPanel"

	var summary := Label.new()
	summary.name = "ManualAnimationSummary"
	summary.text = "%s: %s" % [
		String(animation.get("verb", "Action")),
		String(animation.get("card_name", "Card"))
	]
	summary.add_theme_color_override("font_color", Color("#f3efe4"))
	panel.add_child(summary)

	var route := Label.new()
	route.name = "ManualAnimationRoute"
	route.text = "%s -> %s -> %s" % [
		String(animation.get("source_zone", "Source")),
		String(animation.get("target_zone", "Target")),
		String(animation.get("destination_zone", "Destination"))
	]
	route.add_theme_color_override("font_color", Color("#a9c7ff"))
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(route)

	var track := Control.new()
	track.name = "ManualAnimationTrack"
	track.custom_minimum_size = Vector2(0, 88)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(track)

	var rail := ColorRect.new()
	rail.name = "ManualAnimationRail"
	rail.color = Color("#273241")
	rail.position = Vector2(10, 42)
	rail.size = Vector2(500, 3)
	track.add_child(rail)

	_add_manual_target_arc(track, animation)

	var ghost := _create_manual_animation_ghost(animation)
	track.add_child(ghost)
	_animate_manual_ghost(ghost)

	var badges := HBoxContainer.new()
	badges.name = "ManualImpactBadges"
	badges.add_theme_constant_override("separation", 8)
	panel.add_child(badges)
	for badge in animation.get("badges", []):
		_add_manual_impact_badge(badges, badge)


func _add_manual_action_summary(parent: Node) -> void:
	var animation: Dictionary = run.get("manual_animation", {})
	if animation.is_empty():
		return

	var panel := _add_panel(parent, "Last Action", "#151d28")
	panel.name = "ManualActionSummaryPanel"

	var summary := Label.new()
	summary.name = "ManualActionSummary"
	summary.text = "%s: %s" % [
		String(animation.get("verb", "Action")),
		String(animation.get("card_name", "Card"))
	]
	summary.add_theme_color_override("font_color", Color("#f3efe4"))
	panel.add_child(summary)

	var route := Label.new()
	route.name = "ManualActionRoute"
	route.text = "%s -> %s -> %s" % [
		String(animation.get("source_zone", "Source")),
		String(animation.get("target_zone", "Target")),
		String(animation.get("destination_zone", "Destination"))
	]
	route.add_theme_color_override("font_color", Color("#a9c7ff"))
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(route)

	var badges := HBoxContainer.new()
	badges.name = "ManualImpactBadges"
	badges.add_theme_constant_override("separation", 8)
	panel.add_child(badges)
	for badge in animation.get("badges", []):
		_add_manual_impact_badge(badges, badge)


func _refresh_manual_board_arc_layer(layer: Node2D) -> void:
	if not is_instance_valid(layer):
		return
	for child in layer.get_children():
		child.queue_free()

	var state: Dictionary = run.get("manual_combat", {})
	if state.is_empty():
		return
	var root := layer.get_parent()
	if root == null:
		return
	if current_screen == "ui_combat" and root.get_parent() != null:
		root = root.get_parent()

	_add_manual_selection_preview_arcs(layer, root, state)
	_add_manual_drag_preview_arc(layer, root, state)
	_add_manual_committed_board_arc(layer, root)


func _add_manual_selection_preview_arcs(layer: Node2D, root: Node, state: Dictionary) -> void:
	var selection := _manual_selection()
	if selection.is_empty():
		return

	var source_anchor := ""
	var arc_color := Color("#ffe08a")
	match String(selection.get("kind", "")):
		"attacker":
			var attacker_id := int(selection.get("instance_id", -1))
			var attacker := _manual_find_player_unit(state, attacker_id)
			if attacker.is_empty() or not bool(attacker.get("ready", false)):
				return
			source_anchor = _manual_unit_anchor(state, "player", attacker_id)
			arc_color = _manual_arc_color("Attack")
		"card":
			var card_id := String(selection.get("card_id", ""))
			if not cards_by_id.has(card_id) or not _manual_can_play_card(state, card_id):
				return
			return
		_:
			return

	if source_anchor == "":
		return

	if _manual_selected_can_target_face(state):
		var face_anchor := _manual_target_anchor(state, "face", -1, true)
		var fallback_face_anchor := "ManualOpponentFanHand" if current_screen == "ui_combat" else "ManualOpponentPanel"
		if not _manual_draw_board_arc(layer, root, source_anchor, face_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", arc_color, 3.0, true):
			_manual_draw_board_arc(layer, root, source_anchor, fallback_face_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", arc_color, 3.0, true)

	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		var target_unit: Dictionary = unit
		if _manual_selected_can_target_unit(state, target_unit):
			var target_anchor := _manual_unit_anchor(state, "opponent", int(target_unit.get("instance_id", -1)))
			_manual_draw_board_arc(layer, root, source_anchor, target_anchor, "ManualBoardPreviewArc", "ManualBoardPreviewArrowHead", arc_color, 3.0, true)


func _add_manual_drag_preview_arc(layer: Node2D, root: Node, state: Dictionary) -> void:
	if manual_drag_state.is_empty():
		return
	var card_id := String(manual_drag_state.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return
	if _combat_card_type(cards_by_id[card_id]) != "action":
		return
	var drop_target: Dictionary = manual_drag_state.get("drop_target", {})
	if String(drop_target.get("kind", "")) != "action_target":
		return
	var source_global_data: Variant = manual_drag_state.get("global_position", [])
	if typeof(source_global_data) != TYPE_ARRAY or source_global_data.size() < 2:
		return
	var target_anchor := ""
	match String(drop_target.get("target_type", "")):
		"face":
			target_anchor = "ManualOpponentFanHand"
		"unit":
			target_anchor = _manual_unit_card_anchor(false, int(drop_target.get("target_instance_id", -1)))
		_:
			return
	if target_anchor == "":
		return
	var drew_arc := _manual_draw_board_arc(
		layer,
		root,
		"",
		target_anchor,
		"ManualDragTargetPreviewArc",
		"ManualDragTargetPreviewArrowHead",
		Color("#7fb8ff"),
		4.0,
		true,
		0.0,
		source_global_data
	)
	if drew_arc:
		return
	var fallback_source_data: Variant = manual_drag_state.get("source_global", [])
	if typeof(fallback_source_data) == TYPE_VECTOR2:
		var fallback_source: Vector2 = fallback_source_data
		fallback_source_data = [fallback_source.x, fallback_source.y]
	_manual_draw_board_arc(
		layer,
		root,
		"",
		target_anchor,
		"ManualDragTargetPreviewArc",
		"ManualDragTargetPreviewArrowHead",
		Color("#7fb8ff"),
		4.0,
		true,
		0.0,
		fallback_source_data
	)


func _add_manual_committed_board_arc(layer: Node2D, root: Node) -> void:
	var animation: Dictionary = run.get("manual_animation", {})
	if animation.is_empty():
		return
	if bool(animation.get("board_vfx_started", false)):
		return
	var source_anchor := String(animation.get("source_anchor", ""))
	var target_anchor := String(animation.get("target_anchor", ""))
	var destination_anchor := String(animation.get("destination_anchor", ""))
	if target_anchor == "":
		target_anchor = destination_anchor
	if destination_anchor == "":
		destination_anchor = target_anchor
	var should_draw_arrow := _manual_animation_should_draw_target_arrow(animation, target_anchor, destination_anchor)
	if current_screen == "ui_combat":
		source_anchor = _manual_visible_anchor_or_fallback(root, source_anchor, _manual_ui_combat_vfx_source_fallback_anchor(animation))
		var fallback_anchor := _manual_ui_combat_vfx_fallback_anchor(animation)
		target_anchor = _manual_visible_anchor_or_fallback(root, target_anchor, fallback_anchor)
		destination_anchor = _manual_visible_anchor_or_fallback(root, destination_anchor, target_anchor)
	if source_anchor == "" or target_anchor == "":
		return
	var started_vfx := false
	if should_draw_arrow:
		started_vfx = _manual_draw_board_arc(
			layer,
			root,
			source_anchor,
			target_anchor,
			"ManualBoardTargetArc",
			"ManualBoardTargetArrowHead",
			_manual_arc_color(String(animation.get("verb", "Action"))),
			5.0,
			false,
			0.85,
			animation.get("source_global_point", []),
			animation.get("target_global_point", [])
		)
	if _add_manual_board_card_travel(layer, root, animation, source_anchor, target_anchor, destination_anchor):
		started_vfx = true
	if not started_vfx:
		return
	animation["board_vfx_started"] = true
	run.manual_animation = animation
	if _manual_has_pending_action():
		_manual_schedule_pending_action_commit()
	elif not run.get("manual_animation_queue", []).is_empty():
		_manual_schedule_animation_queue_advance(animation)
	_pulse_manual_anchor(root, source_anchor, Color("#ffe08a"))
	if should_draw_arrow:
		_pulse_manual_anchor(root, target_anchor, _manual_arc_color(String(animation.get("verb", "Action"))))
	if destination_anchor != target_anchor:
		_pulse_manual_anchor(root, destination_anchor, Color("#9ee66e"))
	elif not should_draw_arrow:
		_pulse_manual_anchor(root, destination_anchor, Color("#9ee66e"))
	_add_manual_board_impact_badges(layer, root, animation, target_anchor if should_draw_arrow else destination_anchor)


func _manual_draw_board_arc(layer: Node2D, root: Node, source_anchor: String, target_anchor: String, line_name: String, arrow_name: String, color: Color, width: float, preview: bool, lifetime: float = 0.0, source_global_data: Variant = [], target_global_data: Variant = []) -> bool:
	var source_data := _manual_anchor_or_stored_point_in_layer(layer, root, source_anchor, source_global_data)
	var target_data := _manual_anchor_or_stored_point_in_layer(layer, root, target_anchor, target_global_data)
	if not bool(source_data.get("ok", false)) or not bool(target_data.get("ok", false)):
		return false

	var source: Vector2 = source_data.get("point", Vector2.ZERO)
	var target: Vector2 = target_data.get("point", Vector2.ZERO)
	if source.distance_to(target) < 4.0:
		return false

	var curve_control := _manual_board_arc_control_point(source, target)
	var line_color := color
	if preview:
		line_color.a = 0.48

	var arc := Line2D.new()
	arc.name = line_name
	arc.width = width
	arc.default_color = line_color
	arc.antialiased = true
	for i in range(24):
		var t := float(i) / 23.0
		var a := source.lerp(curve_control, t)
		var b := curve_control.lerp(target, t)
		arc.add_point(a.lerp(b, t))
	layer.add_child(arc)

	var previous := arc.get_point_position(max(0, arc.get_point_count() - 2))
	var direction := (target - previous).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var normal := Vector2(-direction.y, direction.x)
	var arrow_size := 16.0 if preview else 20.0
	var arrow := Line2D.new()
	arrow.name = arrow_name
	arrow.width = width
	arrow.default_color = line_color
	arrow.antialiased = true
	arrow.add_point(target)
	arrow.add_point(target - direction * arrow_size + normal * (arrow_size * 0.55))
	arrow.add_point(target)
	arrow.add_point(target - direction * arrow_size - normal * (arrow_size * 0.55))
	layer.add_child(arrow)

	if not preview:
		arc.modulate = Color(1, 1, 1, 0.25)
		arrow.modulate = Color(1, 1, 1, 0.25)
		var tween := create_tween()
		tween.tween_property(arc, "modulate", Color.WHITE, 0.12)
		tween.parallel().tween_property(arrow, "modulate", Color.WHITE, 0.12)
		tween.tween_property(arc, "width", width + 2.0, 0.08)
		tween.parallel().tween_property(arrow, "width", width + 2.0, 0.08)
		tween.tween_property(arc, "width", width, 0.12)
		tween.parallel().tween_property(arrow, "width", width, 0.12)
		if lifetime > 0.0:
			tween.tween_interval(lifetime)
			tween.tween_property(arc, "modulate", Color(1, 1, 1, 0), 0.20)
			tween.parallel().tween_property(arrow, "modulate", Color(1, 1, 1, 0), 0.20)
			tween.tween_callback(Callable(arc, "queue_free"))
			tween.tween_callback(Callable(arrow, "queue_free"))

	return true


func _manual_animation_should_draw_target_arrow(animation: Dictionary, target_anchor: String, destination_anchor: String) -> bool:
	var verb := String(animation.get("verb", "Action"))
	if verb == "Attack":
		return true
	if verb != "Cast":
		return false
	if target_anchor == "" or target_anchor == destination_anchor:
		return false
	var target_zone := String(animation.get("target_zone", ""))
	return target_zone.contains("Opponent") or target_zone.contains("Your")


func _manual_visible_anchor_or_fallback(root: Node, anchor: String, fallback_anchor: String) -> String:
	if anchor != "" and _find_descendant_by_prefix(root, anchor) != null:
		return anchor
	return fallback_anchor


func _manual_ui_combat_vfx_fallback_anchor(animation: Dictionary) -> String:
	var target_zone := String(animation.get("target_zone", "")).to_lower()
	var destination_zone := String(animation.get("destination_zone", "")).to_lower()
	var target_text := "%s %s" % [target_zone, destination_zone]
	if target_zone.contains("your face"):
		return "ManualFanHand"
	if target_zone.contains("your board"):
		return "ManualZone_PlayerBoard"
	if target_zone.contains("opponent face"):
		return "ManualOpponentFanHand"
	if target_zone.contains("opponent board"):
		return "ManualZone_OpponentBoard"
	return "ManualOpponentFanHand" if target_text.contains("opponent") else "ManualPlayerResourceReadout"


func _manual_ui_combat_vfx_source_fallback_anchor(animation: Dictionary) -> String:
	var source_zone := String(animation.get("source_zone", "")).to_lower()
	if source_zone.contains("opponent hand"):
		return "ManualOpponentFanHand"
	if source_zone.contains("your hand"):
		return "ManualFanHand"
	if source_zone.contains("opponent board"):
		return "ManualZone_OpponentBoard"
	if source_zone.contains("your board"):
		return "ManualZone_PlayerBoard"
	return "ManualFanHand"


func _manual_schedule_animation_queue_advance(animation: Dictionary) -> void:
	if bool(animation.get("advance_scheduled", false)):
		return
	animation["advance_scheduled"] = true
	run.manual_animation = animation
	var timer := get_tree().create_timer(1.12)
	timer.timeout.connect(Callable(self, "_manual_advance_manual_animation_queue"))


func _manual_advance_manual_animation_queue() -> void:
	if run.is_empty():
		return
	var queue: Array = run.get("manual_animation_queue", [])
	if queue.is_empty():
		return
	run.manual_animation = queue[0]
	run.manual_animation_queue = queue.slice(1, queue.size()) if queue.size() > 1 else []
	if current_screen == "ui_combat":
		_show_active_combat_screen()


func _add_manual_board_card_travel(layer: Node2D, root: Node, animation: Dictionary, source_anchor: String, target_anchor: String, destination_anchor: String) -> bool:
	var source_data := _manual_anchor_or_stored_point_in_layer(layer, root, source_anchor, animation.get("source_global_point", []))
	var target_data := _manual_anchor_or_stored_point_in_layer(layer, root, target_anchor, animation.get("target_global_point", []))
	var destination_data := _manual_anchor_or_stored_point_in_layer(layer, root, destination_anchor, animation.get("destination_global_point", []))
	if not bool(source_data.get("ok", false)) or not bool(target_data.get("ok", false)):
		return false
	if not bool(destination_data.get("ok", false)):
		destination_data = target_data

	var source: Vector2 = source_data.get("point", Vector2.ZERO)
	var target: Vector2 = target_data.get("point", Vector2.ZERO)
	var destination: Vector2 = destination_data.get("point", Vector2.ZERO)
	var ghost := _create_manual_board_action_ghost(animation)
	var ghost_size := ghost.custom_minimum_size
	ghost.position = source - ghost_size * 0.5
	ghost.pivot_offset = ghost_size * 0.5
	layer.add_child(ghost)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	ghost.modulate = Color(1, 1, 1, 0.0)
	ghost.scale = Vector2(0.92, 0.92)
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0.94), 0.08)
	tween.parallel().tween_property(ghost, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(ghost, "position", target - ghost_size * 0.5, 0.22)
	tween.parallel().tween_property(ghost, "rotation_degrees", 2.0, 0.22)
	tween.tween_property(ghost, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(ghost, "scale", Vector2.ONE, 0.10)
	if destination.distance_to(target) > 10.0:
		tween.tween_property(ghost, "position", destination - ghost_size * 0.5, 0.20)
		tween.parallel().tween_property(ghost, "rotation_degrees", -2.0, 0.20)
	tween.tween_interval(0.10)
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.22)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.94, 0.94), 0.22)
	tween.tween_callback(Callable(ghost, "queue_free"))
	return true


func _create_manual_board_action_ghost(animation: Dictionary) -> PanelContainer:
	var card_id := String(animation.get("card_id", ""))
	var ghost := PanelContainer.new()
	ghost.name = "ManualBoardMovingCardGhost"
	ghost.custom_minimum_size = Vector2(154, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = _combat_placeholder_color(card_id) if cards_by_id.has(card_id) else Color("#2d3442")
	style.border_color = Color("#ffe08a")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	ghost.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	ghost.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var label := Label.new()
	label.text = String(animation.get("card_name", "Card"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(label)

	var route := Label.new()
	route.text = String(animation.get("verb", "Action"))
	route.add_theme_font_size_override("font_size", 12)
	route.add_theme_color_override("font_color", Color("#c7d0df"))
	box.add_child(route)
	return ghost


func _pulse_manual_anchor(root: Node, anchor: String, color: Color) -> void:
	var node := _find_descendant_by_prefix(root, anchor)
	if node == null or not (node is Control):
		return
	var control := node as Control
	control.pivot_offset = control.size * 0.5
	var original_modulate := control.modulate
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.08)
	tween.parallel().tween_property(control, "modulate", Color(
		min(1.45, color.r + 0.35),
		min(1.45, color.g + 0.35),
		min(1.45, color.b + 0.35),
		1.0
	), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(control, "modulate", original_modulate, 0.18)


func _add_manual_board_impact_badges(layer: Node2D, root: Node, animation: Dictionary, target_anchor: String) -> void:
	var badges: Array = animation.get("badges", [])
	if badges.is_empty():
		return
	var target_node := _find_descendant_by_prefix(root, target_anchor)
	if target_node == null:
		return
	var target := _manual_node_center_in_layer(layer, target_node)
	var offset_index := 0
	for badge in badges.slice(0, min(3, badges.size())):
		var board_badge := _create_manual_board_impact_badge(badge)
		board_badge.position = target + Vector2(18 * offset_index, -26 - 14 * offset_index)
		board_badge.pivot_offset = Vector2(35, 18)
		layer.add_child(board_badge)
		_animate_manual_board_impact_badge(board_badge)
		offset_index += 1


func _create_manual_board_impact_badge(badge: Dictionary) -> PanelContainer:
	var impact := PanelContainer.new()
	impact.name = "ManualBoardImpactBadge"
	impact.custom_minimum_size = Vector2(70, 36)
	var colors := _manual_impact_badge_colors(String(badge.get("kind", "log")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colors.get("background", "#26303d"))
	style.border_color = Color(colors.get("border", "#465060"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	impact.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = String(badge.get("text", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(colors.get("text", "#eef3ff")))
	impact.add_child(label)
	return impact


func _animate_manual_board_impact_badge(badge: Control) -> void:
	badge.scale = Vector2(0.78, 0.78)
	badge.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate", Color.WHITE, 0.08)
	tween.parallel().tween_property(badge, "scale", Vector2(1.16, 1.16), 0.12)
	tween.tween_property(badge, "position", badge.position + Vector2(0, -24), 0.34)
	tween.parallel().tween_property(badge, "modulate", Color(1, 1, 1, 0), 0.34)
	tween.tween_callback(Callable(badge, "queue_free"))


func _manual_board_arc_control_point(source: Vector2, target: Vector2) -> Vector2:
	var midpoint := (source + target) * 0.5
	var lift: float = clamp(source.distance_to(target) * 0.22, 48.0, 140.0)
	return midpoint + Vector2(0, -lift)


func _manual_node_center_in_layer(layer: Node2D, node: Node) -> Vector2:
	if node is Control:
		var rect := (node as Control).get_global_rect()
		return layer.to_local(rect.get_center())
	if node is Node2D:
		return layer.to_local((node as Node2D).global_position)
	return Vector2.ZERO


func _manual_capture_anchor_global_point(anchor: String) -> Array:
	if anchor == "":
		return []
	var node := _find_descendant_by_prefix(self, anchor)
	if node == null:
		return []
	var center := _manual_node_global_center(node)
	return [center.x, center.y]


func _manual_anchor_or_stored_point_in_layer(layer: Node2D, root: Node, anchor: String, global_data: Variant) -> Dictionary:
	var node := _find_descendant_by_prefix(root, anchor)
	if node != null:
		return {
			"ok": true,
			"point": _manual_node_center_in_layer(layer, node)
		}
	var stored := _manual_global_point_from_data(global_data)
	if bool(stored.get("ok", false)):
		return {
			"ok": true,
			"point": layer.to_local(stored.get("point", Vector2.ZERO))
		}
	return {
		"ok": false,
		"point": Vector2.ZERO
	}


func _manual_global_point_from_data(global_data: Variant) -> Dictionary:
	if typeof(global_data) == TYPE_ARRAY and global_data.size() >= 2:
		return {
			"ok": true,
			"point": Vector2(float(global_data[0]), float(global_data[1]))
		}
	return {
		"ok": false,
		"point": Vector2.ZERO
	}


func _manual_node_global_center(node: Node) -> Vector2:
	if node is Control:
		return (node as Control).get_global_rect().get_center()
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


func _find_descendant_by_prefix(root: Node, target_prefix: String) -> Node:
	if target_prefix == "":
		return null
	if String(root.name).begins_with(target_prefix):
		return root
	for child in root.get_children():
		var found := _find_descendant_by_prefix(child, target_prefix)
		if found != null:
			return found
	return null


func _add_manual_target_arc(parent: Node, animation: Dictionary) -> void:
	var source := Vector2(66, 66)
	var control := Vector2(245, 2)
	var target := Vector2(424, 66)
	var destination := Vector2(532, 66)

	var arc := Line2D.new()
	arc.name = "ManualTargetArc"
	arc.width = 4.0
	arc.default_color = _manual_arc_color(String(animation.get("verb", "Action")))
	arc.antialiased = true
	for i in range(18):
		var t := float(i) / 17.0
		var a := source.lerp(control, t)
		var b := control.lerp(target, t)
		arc.add_point(a.lerp(b, t))
	parent.add_child(arc)

	var arrow := Line2D.new()
	arrow.name = "ManualTargetArrowHead"
	arrow.width = 4.0
	arrow.default_color = arc.default_color
	arrow.antialiased = true
	arrow.add_point(target)
	arrow.add_point(target + Vector2(-16, -10))
	arrow.add_point(target)
	arrow.add_point(target + Vector2(-16, 10))
	parent.add_child(arrow)

	_add_manual_arc_marker(parent, "ManualArcSourceMarker", source, "SRC", String(animation.get("source_zone", "Source")), Color("#a9c7ff"))
	_add_manual_arc_marker(parent, "ManualArcTargetMarker", target, "TGT", String(animation.get("target_zone", "Target")), Color("#ffb3a6"))
	_add_manual_arc_marker(parent, "ManualArcDestinationMarker", destination, "DST", String(animation.get("destination_zone", "Destination")), Color("#9ee66e"))

	var tween := create_tween()
	arc.modulate = Color(1, 1, 1, 0.2)
	arrow.modulate = Color(1, 1, 1, 0.2)
	tween.tween_property(arc, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.parallel().tween_property(arrow, "modulate", Color(1, 1, 1, 1), 0.16)
	tween.tween_property(arc, "width", 6.0, 0.10)
	tween.parallel().tween_property(arrow, "width", 6.0, 0.10)
	tween.tween_property(arc, "width", 4.0, 0.12)
	tween.parallel().tween_property(arrow, "width", 4.0, 0.12)


func _manual_arc_color(verb: String) -> Color:
	match verb:
		"Attack":
			return Color("#f06f5f")
		"Cast":
			return Color("#7fb8ff")
		"Activate":
			return Color("#ffe08a")
		_:
			return Color("#9ee66e")


func _add_manual_arc_marker(parent: Node, node_name: String, position: Vector2, short_text: String, tooltip: String, color: Color) -> void:
	var marker := PanelContainer.new()
	marker.name = node_name
	marker.position = position - Vector2(28, 16)
	marker.custom_minimum_size = Vector2(56, 30)
	marker.tooltip_text = tooltip
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.55)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	marker.add_theme_stylebox_override("panel", style)
	parent.add_child(marker)

	var label := Label.new()
	label.text = short_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#eef3ff"))
	marker.add_child(label)


func _create_manual_animation_ghost(animation: Dictionary) -> PanelContainer:
	var card_id := String(animation.get("card_id", ""))
	var ghost := PanelContainer.new()
	ghost.name = "ManualMovingCardGhost"
	ghost.custom_minimum_size = Vector2(154, 58)
	ghost.position = Vector2(10, 14)
	ghost.pivot_offset = Vector2(77, 29)
	var style := StyleBoxFlat.new()
	style.bg_color = _combat_placeholder_color(card_id) if cards_by_id.has(card_id) else Color("#2d3442")
	style.border_color = Color("#ffe08a")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	ghost.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	ghost.add_child(margin)

	var label := Label.new()
	label.text = String(animation.get("card_name", "Card"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	margin.add_child(label)
	return ghost


func _animate_manual_ghost(ghost: Control) -> void:
	ghost.modulate = Color(1, 1, 1, 0.82)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "position", Vector2(150, 4), 0.18)
	tween.tween_property(ghost, "position", Vector2(330, 14), 0.24)
	tween.parallel().tween_property(ghost, "modulate", Color(1.18, 1.18, 1.18, 1.0), 0.18)
	tween.tween_property(ghost, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(ghost, "scale", Vector2.ONE, 0.12)


func _add_manual_impact_badge(parent: Node, badge: Dictionary) -> void:
	var impact := PanelContainer.new()
	impact.name = "ManualImpactBadge"
	impact.custom_minimum_size = Vector2(82, 42)
	impact.pivot_offset = Vector2(41, 21)
	var colors := _manual_impact_badge_colors(String(badge.get("kind", "log")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colors.get("background", "#26303d"))
	style.border_color = Color(colors.get("border", "#465060"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	impact.add_theme_stylebox_override("panel", style)
	parent.add_child(impact)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	impact.add_child(margin)

	var label := Label.new()
	label.name = "ManualImpactBadgeText"
	label.text = String(badge.get("text", "FX"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(colors.get("text", "#eef3ff")))
	label.tooltip_text = String(badge.get("line", ""))
	margin.add_child(label)

	_animate_manual_impact_badge(impact)


func _manual_impact_badge_colors(kind: String) -> Dictionary:
	match kind:
		"damage":
			return { "background": "#3a211f", "border": "#f06f5f", "text": "#ffb3a6" }
		"heal":
			return { "background": "#1f3323", "border": "#7fc46b", "text": "#bfe8a5" }
		"draw":
			return { "background": "#1d2a43", "border": "#6f99e8", "text": "#a9c7ff" }
		"ko":
			return { "background": "#371f2c", "border": "#d46a95", "text": "#ff9fc2" }
		"focus":
			return { "background": "#25351c", "border": "#a7d469", "text": "#d7ff9d" }
		_:
			return { "background": "#352d1c", "border": "#d6a84e", "text": "#ffe08a" }


func _animate_manual_impact_badge(badge: Control) -> void:
	badge.scale = Vector2(0.88, 0.88)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "scale", Vector2(1.18, 1.18), 0.12)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.16)


func _add_manual_battlefield(parent: Node) -> Control:
	var compact_duel := current_screen == "ui_combat"
	var playmat := PanelContainer.new()
	playmat.name = "ManualBattlefield"
	playmat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact_duel:
		playmat.custom_minimum_size = Vector2(1040, 860)
		playmat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16201c")
	style.border_color = Color("#526149")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	playmat.add_theme_stylebox_override("panel", style)
	parent.add_child(playmat)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6 if compact_duel else 10)
	margin.add_theme_constant_override("margin_right", 6 if compact_duel else 10)
	margin.add_theme_constant_override("margin_top", 6 if compact_duel else 10)
	margin.add_theme_constant_override("margin_bottom", 6 if compact_duel else 10)
	playmat.add_child(margin)

	var battlefield: Control
	if compact_duel:
		var canvas := Control.new()
		canvas.clip_contents = true
		canvas.mouse_filter = Control.MOUSE_FILTER_STOP
		battlefield = canvas
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		battlefield = row
	battlefield.name = "ManualBattlefield"
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(battlefield)
	return battlefield


func _add_manual_inspect_panel(parent: Node, state: Dictionary) -> void:
	var compact_duel := current_screen == "ui_combat"
	if compact_duel:
		var stored_inspect: Dictionary = run.get("manual_inspect", {})
		var stored_card := String(stored_inspect.get("card_id", ""))
		if not bool(stored_inspect.get("pinned", false)) or not cards_by_id.has(stored_card):
			return

	var inspect := PanelContainer.new()
	inspect.name = "ManualInspectPanelOverlay" if compact_duel else "ManualInspectPanel"
	inspect.set_meta("ui_combat_overlay", compact_duel)
	inspect.custom_minimum_size = Vector2(224 if compact_duel else 310, 0)
	inspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect.mouse_filter = Control.MOUSE_FILTER_PASS
	if compact_duel:
		inspect.z_index = 180
		inspect.anchor_left = 0.0
		inspect.anchor_top = 0.0
		inspect.anchor_right = 0.0
		inspect.anchor_bottom = 1.0
		inspect.offset_left = 14.0
		inspect.offset_top = 10.0
		inspect.offset_right = 232.0
		inspect.offset_bottom = -10.0
	var style := StyleBoxFlat.new()
	var inspect_bg := Color("#101722")
	var inspect_border := Color("#52617a")
	if compact_duel:
		inspect_bg.a = 0.84
		inspect_border.a = 0.72
	style.bg_color = inspect_bg
	style.border_color = inspect_border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	inspect.add_theme_stylebox_override("panel", style)
	parent.add_child(inspect)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_right", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_top", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_bottom", 9 if compact_duel else 10)
	inspect.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7 if compact_duel else 8)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = "CARD INSPECT"
	heading.add_theme_font_size_override("font_size", 14 if compact_duel else 18)
	heading.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(heading)

	manual_inspect_art_panel = PanelContainer.new()
	manual_inspect_art_panel.name = "ManualInspectArt"
	manual_inspect_art_panel.custom_minimum_size = Vector2(0, 100 if compact_duel else 168)
	box.add_child(manual_inspect_art_panel)

	var art_margin := MarginContainer.new()
	art_margin.add_theme_constant_override("margin_left", 10)
	art_margin.add_theme_constant_override("margin_right", 10)
	art_margin.add_theme_constant_override("margin_top", 10)
	art_margin.add_theme_constant_override("margin_bottom", 10)
	manual_inspect_art_panel.add_child(art_margin)

	var art_label := Label.new()
	art_label.name = "ManualInspectArtLabel"
	art_label.text = "PLACEHOLDER ART"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_color_override("font_color", Color("#f3efe4"))
	art_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_margin.add_child(art_label)

	manual_inspect_name_label = Label.new()
	manual_inspect_name_label.name = "ManualInspectName"
	manual_inspect_name_label.add_theme_font_size_override("font_size", 16 if compact_duel else 20)
	manual_inspect_name_label.add_theme_color_override("font_color", Color("#f3efe4"))
	manual_inspect_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_name_label)

	manual_inspect_type_panel = PanelContainer.new()
	manual_inspect_type_panel.name = "ManualInspectTypeStrip"
	manual_inspect_type_panel.custom_minimum_size = Vector2(0, 18 if compact_duel else 24)
	box.add_child(manual_inspect_type_panel)

	var type_margin := MarginContainer.new()
	type_margin.add_theme_constant_override("margin_left", 6)
	type_margin.add_theme_constant_override("margin_right", 6)
	type_margin.add_theme_constant_override("margin_top", 1)
	type_margin.add_theme_constant_override("margin_bottom", 1)
	manual_inspect_type_panel.add_child(type_margin)

	manual_inspect_type_label = Label.new()
	manual_inspect_type_label.name = "ManualInspectTypeLabel"
	manual_inspect_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_inspect_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	manual_inspect_type_label.clip_text = true
	manual_inspect_type_label.add_theme_font_size_override("font_size", 9 if compact_duel else 12)
	type_margin.add_child(manual_inspect_type_label)

	manual_inspect_meta_label = Label.new()
	manual_inspect_meta_label.name = "ManualInspectMeta"
	manual_inspect_meta_label.add_theme_color_override("font_color", Color("#c7d0df"))
	manual_inspect_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_meta_label)

	manual_inspect_stats_label = Label.new()
	manual_inspect_stats_label.name = "ManualInspectStats"
	manual_inspect_stats_label.add_theme_font_size_override("font_size", 13 if compact_duel else 16)
	manual_inspect_stats_label.add_theme_color_override("font_color", Color("#ffe08a"))
	manual_inspect_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_stats_label)

	manual_inspect_zone_label = Label.new()
	manual_inspect_zone_label.name = "ManualInspectZone"
	manual_inspect_zone_label.add_theme_color_override("font_color", Color("#a9c7ff"))
	manual_inspect_zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_zone_label)

	var rules_heading := Label.new()
	rules_heading.text = "EFFECT"
	rules_heading.add_theme_font_size_override("font_size", 12)
	rules_heading.add_theme_color_override("font_color", Color("#9ee66e"))
	box.add_child(rules_heading)

	manual_inspect_effect_label = Label.new()
	manual_inspect_effect_label.name = "ManualInspectEffect"
	manual_inspect_effect_label.add_theme_color_override("font_color", Color("#d8dfec"))
	manual_inspect_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_effect_label)

	var text_heading := Label.new()
	text_heading.text = "TEXT"
	text_heading.add_theme_font_size_override("font_size", 12)
	text_heading.add_theme_color_override("font_color", Color("#9ee66e"))
	box.add_child(text_heading)

	manual_inspect_text_label = Label.new()
	manual_inspect_text_label.name = "ManualInspectText"
	manual_inspect_text_label.add_theme_color_override("font_color", Color("#c7d0df"))
	manual_inspect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_text_label)

	var inspect_data := _manual_inspect_data_for_state(state)
	if cards_by_id.has(String(inspect_data.get("card_id", ""))):
		_manual_set_inspect_card(
			String(inspect_data.get("card_id", "")),
			String(inspect_data.get("zone", "Inspect")),
			String(inspect_data.get("current", "")),
			true
		)
	else:
		_refresh_manual_inspect_panel()


func _manual_inspect_data_for_state(state: Dictionary) -> Dictionary:
	var stored: Dictionary = run.get("manual_inspect", {})
	var stored_card := String(stored.get("card_id", ""))
	if cards_by_id.has(stored_card):
		return stored

	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			var selected_card := String(selection.get("card_id", ""))
			if cards_by_id.has(selected_card):
				return { "card_id": selected_card, "zone": "Hand", "current": "" }
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			if not attacker.is_empty():
				return {
					"card_id": String(attacker.get("card_id", "")),
					"zone": "Your Board",
					"current": _manual_current_unit_summary(attacker)
				}

	if current_screen == "ui_combat":
		return { "card_id": "", "zone": "Inspect", "current": "" }

	var player: Dictionary = state.get("player", {})
	for card_id in player.get("hand", []):
		if cards_by_id.has(String(card_id)):
			return { "card_id": String(card_id), "zone": "Hand", "current": "" }
	for unit in player.get("board", []):
		if cards_by_id.has(String(unit.get("card_id", ""))):
			return {
				"card_id": String(unit.get("card_id", "")),
				"zone": "Your Board",
				"current": _manual_current_unit_summary(unit)
			}

	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		if cards_by_id.has(String(unit.get("card_id", ""))):
			return {
				"card_id": String(unit.get("card_id", "")),
				"zone": "Opponent Board",
				"current": _manual_current_unit_summary(unit)
			}

	return { "card_id": "", "zone": "Inspect", "current": "" }


func _manual_set_inspect_card(card_id: String, zone: String, current_summary: String = "", pinned: bool = true) -> void:
	if run.is_empty():
		return
	if not cards_by_id.has(card_id):
		run.manual_inspect = {}
		_refresh_manual_inspect_panel()
		return
	run.manual_inspect = {
		"card_id": card_id,
		"zone": zone,
		"current": current_summary,
		"pinned": pinned
	}
	_refresh_manual_inspect_panel()


func _manual_clear_hover_inspect(card_id: String, zone: String, current_summary: String = "") -> void:
	if run.is_empty():
		return
	var inspect_data: Dictionary = run.get("manual_inspect", {})
	if bool(inspect_data.get("pinned", false)):
		return
	if String(inspect_data.get("card_id", "")) != card_id:
		return
	if String(inspect_data.get("zone", "")) != zone:
		return
	if String(inspect_data.get("current", "")) != current_summary:
		return
	run.manual_inspect = {}
	_refresh_manual_inspect_panel()


func _refresh_manual_inspect_panel() -> void:
	if manual_inspect_name_label == null or not is_instance_valid(manual_inspect_name_label):
		return
	var inspect_data: Dictionary = run.get("manual_inspect", {})
	var card_id := String(inspect_data.get("card_id", ""))
	if not cards_by_id.has(card_id):
		manual_inspect_name_label.text = "Inspect"
		if manual_inspect_type_panel != null and is_instance_valid(manual_inspect_type_panel):
			manual_inspect_type_panel.visible = false
		if manual_inspect_type_label != null and is_instance_valid(manual_inspect_type_label):
			manual_inspect_type_label.text = ""
		manual_inspect_meta_label.text = "Hover for a quick look. Click a card to pin it."
		manual_inspect_stats_label.text = ""
		manual_inspect_zone_label.text = ""
		manual_inspect_effect_label.text = ""
		manual_inspect_text_label.text = ""
		_set_manual_inspect_art_color(Color("#1f2732"))
		return

	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = card.get("combat", {})
	var kind := String(combat.get("kind", _combat_card_type(card))).capitalize()
	manual_inspect_name_label.text = String(card.get("name", card_id))
	if manual_inspect_type_panel != null and is_instance_valid(manual_inspect_type_panel):
		manual_inspect_type_panel.visible = true
		_style_card_type_strip(manual_inspect_type_panel, _card_animal_type(card), current_screen == "ui_combat")
	if manual_inspect_type_label != null and is_instance_valid(manual_inspect_type_label):
		manual_inspect_type_label.text = _combat_card_type_line(card)
		manual_inspect_type_label.add_theme_color_override("font_color", _affinity_color(_card_animal_type(card)).lightened(0.68))
	manual_inspect_meta_label.text = "%s | %s | Cost %d" % [
		String(card.get("rarity", "common")).capitalize(),
		kind,
		int(card.get("cost", 0))
	]
	manual_inspect_stats_label.text = _manual_inspect_stats(card, String(inspect_data.get("current", "")))
	manual_inspect_zone_label.text = "Zone: " + String(inspect_data.get("zone", "Inspect"))
	manual_inspect_effect_label.text = _combat_effect_summary(card)
	manual_inspect_text_label.text = String(card.get("text", ""))
	_set_manual_inspect_art_color(_combat_placeholder_color(card_id))


func _manual_inspect_stats(card: Dictionary, current_summary: String) -> String:
	if current_summary != "":
		return current_summary
	var combat: Dictionary = card.get("combat", {})
	match String(combat.get("kind", "")):
		"unit":
			return "Base %d/%d%s" % [
				int(combat.get("attack", 0)),
				int(combat.get("health", 0)),
				" | " + ", ".join(PackedStringArray(combat.get("keywords", []))) if not combat.get("keywords", []).is_empty() else ""
			]
		"action":
			return _manual_target_mode_label(card)
		"engine":
			return "Engine"
		_:
			return String(card.get("role", "Card")).capitalize()


func _manual_current_unit_summary(unit: Dictionary) -> String:
	return "Current %d/%d%s" % [
		int(unit.get("attack", 0)),
		int(unit.get("health", 0)),
		" | Ready" if bool(unit.get("ready", false)) else ""
	]


func _set_manual_inspect_art_color(color: Color) -> void:
	if manual_inspect_art_panel == null or not is_instance_valid(manual_inspect_art_panel):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.25)
	style.border_color = color.lightened(0.25)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	manual_inspect_art_panel.add_theme_stylebox_override("panel", style)


func _add_manual_feedback_chip(parent: Node, line: String) -> void:
	var feedback := _manual_feedback_data(line)
	var chip := PanelContainer.new()
	chip.name = "ManualFeedbackChip"
	chip.custom_minimum_size = Vector2(132 if current_screen == "ui_combat" else 170, 0)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(feedback.get("background", "#26303d"))
	style.border_color = Color(feedback.get("border", "#465060"))
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var tag := Label.new()
	tag.name = "ManualFeedbackKind"
	tag.text = String(feedback.get("tag", "LOG"))
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(feedback.get("color", "#d8dfec")))
	box.add_child(tag)

	var body := Label.new()
	body.name = "ManualFeedbackText"
	body.text = line
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#eef3ff"))
	box.add_child(body)


func _manual_feedback_data(line: String) -> Dictionary:
	var lower := line.to_lower()
	if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("trades"):
		return { "tag": "DMG", "color": "#ffb3a6", "background": "#3a211f", "border": "#f06f5f" }
	if lower.contains("dies") or lower.contains("destroy"):
		return { "tag": "KO", "color": "#ff9fc2", "background": "#371f2c", "border": "#d46a95" }
	if lower.contains("restore") or lower.contains("heal"):
		return { "tag": "HEAL", "color": "#bfe8a5", "background": "#1f3323", "border": "#7fc46b" }
	if lower.contains("draw"):
		return { "tag": "DRAW", "color": "#a9c7ff", "background": "#1d2a43", "border": "#6f99e8" }
	if lower.contains("create") or lower.contains("token") or lower.contains("plays"):
		return { "tag": "PLAY", "color": "#ffe08a", "background": "#352d1c", "border": "#d6a84e" }
	if lower.contains("turn") or lower.contains("focus"):
		return { "tag": "TURN", "color": "#c7d0df", "background": "#242b36", "border": "#5d6a7a" }
	return { "tag": "LOG", "color": "#d8dfec", "background": "#26303d", "border": "#465060" }


func _manual_log_line_color(line: String) -> Color:
	var lower := line.to_lower()
	if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("trades") or lower.contains("dies"):
		return Color("#ffb3a6")
	if lower.contains("restore") or lower.contains("draw") or lower.contains("creates"):
		return Color("#bfe8a5")
	if lower.contains("turn"):
		return Color("#a9c7ff")
	return Color("#d8dfec")


func _add_manual_combatant_panel(parent: Node, label: String, combatant: Dictionary, is_player: bool, state: Dictionary) -> void:
	var panel := _add_panel(parent, label, "#1f3140" if is_player else "#34232d")
	panel.name = "ManualPlayerPanel" if is_player else "ManualOpponentPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if current_screen == "ui_combat" else Control.SIZE_SHRINK_BEGIN
	if combatant.is_empty():
		_add_body_text(panel, "No combatant data.")
		return

	_add_body_text(panel, "Life %d | Focus %d/%d%s | Deck %d | Hand %d | Discard %d | Fatigue %d" % [
		int(combatant.get("life", 0)),
		int(combatant.get("focus", 0)),
		int(combatant.get("max_focus", 0)),
		_manual_restricted_focus_text(combatant),
		combatant.get("deck", []).size(),
		combatant.get("hand", []).size(),
		combatant.get("discard", []).size(),
		int(combatant.get("fatigue", 0))
	])

	if current_screen == "ui_combat":
		if is_player:
			_add_manual_board(panel, combatant.get("board", []), is_player, state)
			_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
			_add_manual_hand(panel, combatant, state)
		else:
			_add_manual_hidden_hand_zone(panel, combatant.get("hand", []).size())
			_add_manual_face_target(panel, state)
			_add_manual_board(panel, combatant.get("board", []), is_player, state)
			_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
		return

	if not is_player:
		_add_manual_face_target(panel, state)

	_add_manual_board(panel, combatant.get("board", []), is_player, state)

	_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
	if is_player:
		_add_manual_hand(panel, combatant, state)
	else:
		_add_manual_hidden_hand_zone(panel, combatant.get("hand", []).size())
	_add_manual_summary_zone(
		panel,
		"Discard Zone",
		_summarize_card_ids(combatant.get("discard", [])).slice(0, 8),
		"PlayerDiscard" if is_player else "OpponentDiscard",
		0,
		"#211d24"
	)


func _add_manual_zone(parent: Node, title: String, zone_name: String, accent: String) -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var panel := PanelContainer.new()
	panel.name = "ManualZone_" + zone_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact_duel:
		var fixed_height := _ui_combat_zone_height(zone_name)
		if fixed_height > 0.0:
			panel.custom_minimum_size = Vector2(0, fixed_height)
			panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		panel.clip_contents = zone_name != "PlayerHand"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent)
	style.border_color = Color("#586575")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5 if compact_duel else 8)
	margin.add_theme_constant_override("margin_right", 5 if compact_duel else 8)
	margin.add_theme_constant_override("margin_top", 2 if compact_duel else 6)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2 if compact_duel else 6)
	margin.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 9 if compact_duel else 13)
	label.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(label)
	return box


func _ui_combat_zone_height(zone_name: String) -> float:
	match zone_name:
		"OpponentHand":
			return 46.0
		"OpponentEngine", "PlayerEngine":
			return 38.0
		"OpponentBoard", "PlayerBoard":
			return 190.0
		"PlayerHand":
			return 240.0
		_:
			return 0.0


func _add_manual_summary_zone(parent: Node, title: String, entries: Array, zone_name: String, slot_count: int, accent: String) -> void:
	var zone := _add_manual_zone(parent, title, zone_name, accent)
	var columns: int = max(1, slot_count if slot_count > 0 else min(4, max(1, entries.size())))
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)

	for entry in entries:
		var card_id := String(entry.get("card_id", ""))
		var summary := "%s x%d" % [
			String(entry.get("name", "Unknown")),
			int(entry.get("count", 1))
		]
		if entry.has("cost"):
			summary += " | cost %d" % int(entry.get("cost", 0))
		_add_manual_zone_item(grid, summary, card_id, title)

	if entries.is_empty() and slot_count <= 0:
		_add_manual_empty_zone_slot(grid, "No Cards")
		return

	for i in range(max(0, slot_count - entries.size())):
		_add_manual_empty_zone_slot(grid, "Open Slot")


func _add_manual_engine_zone(parent: Node, engines: Array, is_player: bool) -> void:
	var zone_name := "PlayerEngine" if is_player else "OpponentEngine"
	var zone := _add_manual_zone(parent, "Engine Zone", zone_name, "#18232d")
	var grid := GridContainer.new()
	grid.columns = COMBAT_ENGINE_SLOTS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)

	var slotted_engines := _manual_engines_by_slot(engines)
	for slot_index in range(COMBAT_ENGINE_SLOTS):
		var slot := _add_manual_engine_slot(grid, is_player, slot_index)
		var engine: Dictionary = slotted_engines[slot_index]
		if engine.is_empty():
			_add_manual_empty_zone_slot(slot, "Open Slot")
			continue

		var card_id := String(engine.get("card_id", ""))
		var summary := "Unknown Engine"
		if cards_by_id.has(card_id):
			var card: Dictionary = cards_by_id[card_id]
			summary = String(card.get("name", card_id))
			if card.has("cost"):
				summary += " | cost %d" % int(card.get("cost", 0))
		_add_manual_zone_item(slot, summary, card_id, "Engine Zone")


func _add_manual_engine_slot(parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var slot := PanelContainer.new()
	slot.name = _manual_engine_slot_anchor(is_player, slot_index)
	slot.custom_minimum_size = Vector2(96, 24) if compact_duel else Vector2(132, 44)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111922")
	style.border_color = Color("#3f4a59")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	slot.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "ManualEngineSlotContents"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	return box


func _add_manual_hidden_hand_zone(parent: Node, hand_count: int) -> void:
	var zone := _add_manual_zone(parent, "Hand Zone", "OpponentHand", "#261f32")
	var grid := GridContainer.new()
	grid.columns = max(1, min(5, hand_count))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)
	for i in range(hand_count):
		_add_manual_card_back_slot(grid, "Hidden Card")
	if hand_count <= 0:
		_add_manual_empty_zone_slot(grid, "Empty Hand")


func _add_manual_zone_item(parent: Node, text: String, card_id: String = "", zone_label: String = "") -> void:
	var compact_duel := current_screen == "ui_combat"
	var item := PanelContainer.new()
	item.name = "ManualZoneItem"
	item.custom_minimum_size = Vector2(96, 24) if compact_duel else Vector2(132, 44)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = _combat_placeholder_color(card_id).darkened(0.2) if cards_by_id.has(card_id) else Color("#252d38")
	style.border_color = Color("#465060")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	item.add_theme_stylebox_override("panel", style)
	parent.add_child(item)
	if card_id != "":
		_apply_combat_card_motion(item, card_id, zone_label, "")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	item.add_child(margin)

	var label := Label.new()
	label.text = text
	if compact_duel:
		label.add_theme_font_size_override("font_size", 8)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#d8dfec"))
	margin.add_child(label)


func _add_manual_empty_zone_slot(parent: Node, text: String) -> void:
	var compact_duel := current_screen == "ui_combat"
	var slot := PanelContainer.new()
	slot.name = "ManualEmptyZoneSlot"
	slot.custom_minimum_size = Vector2(96, 24) if compact_duel else Vector2(132, 44)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#141a22")
	style.border_color = Color("#3f4a59")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	slot.add_child(margin)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if compact_duel:
		label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("#7e8794"))
	margin.add_child(label)


func _add_manual_card_back_slot(parent: Node, text: String) -> void:
	var compact_duel := current_screen == "ui_combat"
	var back := PanelContainer.new()
	back.name = "ManualCardBackSlot"
	back.custom_minimum_size = Vector2(70, 30) if compact_duel else Vector2(96, 44)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171c2b")
	style.border_color = Color("#6f99e8")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	back.add_theme_stylebox_override("panel", style)
	parent.add_child(back)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	back.add_child(margin)

	var label := Label.new()
	label.text = "Card" if compact_duel else text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if compact_duel:
		label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#a9c7ff"))
	margin.add_child(label)


func _add_manual_board_slot(parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var slot := PanelContainer.new()
	slot.name = "ManualBoardSlot_%s_%d" % ["Player" if is_player else "Opponent", slot_index + 1]
	slot.custom_minimum_size = Vector2(108, 166) if compact_duel else Vector2(188, 250)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#14221a") if is_player else Color("#24171d")
	style.border_color = Color("#445443") if is_player else Color("#5a404a")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	slot.add_theme_stylebox_override("panel", style)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3 if compact_duel else 4)
	margin.add_theme_constant_override("margin_right", 3 if compact_duel else 4)
	margin.add_theme_constant_override("margin_top", 2 if compact_duel else 4)
	margin.add_theme_constant_override("margin_bottom", 2 if compact_duel else 4)
	slot.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "ManualBoardSlotContents"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2 if compact_duel else 4)
	margin.add_child(box)

	var label := Label.new()
	label.text = "Slot %d" % (slot_index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8 if compact_duel else 10)
	label.add_theme_color_override("font_color", Color("#7e8794"))
	box.add_child(label)
	return box


func _add_manual_board(parent: VBoxContainer, units: Array, is_player: bool, state: Dictionary) -> void:
	var zone := _add_manual_zone(parent, "Board Zone", "PlayerBoard" if is_player else "OpponentBoard", "#1c2a24" if is_player else "#2b2026")

	var grid := GridContainer.new()
	grid.columns = COMBAT_BOARD_SLOTS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 8)
	grid.add_theme_constant_override("v_separation", 2 if current_screen == "ui_combat" else 8)
	zone.add_child(grid)

	var slotted_units := _manual_units_by_board_slot(units)
	for slot_index in range(COMBAT_BOARD_SLOTS):
		var slot := _add_manual_board_slot(grid, is_player, slot_index)
		var unit: Dictionary = slotted_units[slot_index]
		if unit.is_empty():
			_add_manual_empty_zone_slot(slot, "Open Board Slot")
			continue

		var border_color := Color("#465060")
		var border_width := 1
		var selected_attacker := is_player and _manual_selection_is_attacker(unit)
		var legal_target := not is_player and _manual_selected_can_target_unit(state, unit)
		if selected_attacker:
			border_color = Color("#ffe08a")
			border_width = 3
		elif legal_target:
			border_color = Color("#9ee66e")
			border_width = 4

		var card_box := _add_combat_placeholder_card(
			slot,
			String(unit.get("name", "Unknown")),
			"%d/%d%s" % [
				int(unit.get("attack", 0)),
				int(unit.get("health", 0)),
				" Ready" if bool(unit.get("ready", false)) else ""
			],
			_manual_unit_keyword_text(unit),
			_combat_placeholder_color(unit.get("card_id", "")),
			border_color,
			border_width,
			String(unit.get("card_id", "")),
			"Your Board" if is_player else "Opponent Board",
			_manual_current_unit_summary(unit),
			_manual_unit_card_anchor(is_player, int(unit.get("instance_id", -1))),
			_unit_card_type_line(unit),
			_unit_animal_type(unit)
		)

		if selected_attacker:
			_add_manual_card_badge(card_box, "ATTACKER SELECTED", Color("#ffe08a"))
		elif is_player and bool(unit.get("ready", false)):
			_add_manual_card_badge(card_box, "READY", Color("#a9c7ff"))
		elif legal_target:
			_add_manual_card_badge(card_box, "LEGAL TARGET", Color("#9ee66e"))

		if is_player and _manual_combat_accepts_input(state) and bool(unit.get("ready", false)):
			var instance_id := int(unit.get("instance_id", -1))
			var attack_button := _make_button("Selected" if _manual_selection_is_attacker(unit) else ("Attack" if current_screen == "ui_combat" else "Select Attack"))
			attack_button.name = "ManualAttackSelectButton"
			_style_button(attack_button, "selected" if _manual_selection_is_attacker(unit) else "action")
			_compact_manual_card_button(attack_button)
			if _manual_selection_is_attacker(unit):
				_connect_pressed(attack_button, _manual_clear_selection)
			else:
				_connect_pressed(attack_button, func() -> void: _manual_select_attacker(instance_id))
			card_box.add_child(attack_button)
		elif legal_target:
			var target_instance_id := int(unit.get("instance_id", -1))
			var target_button := _make_button("Target" if current_screen == "ui_combat" else _manual_target_action_label() + " Target")
			target_button.name = "ManualUnitTargetButton"
			_style_button(target_button, "target")
			_compact_manual_card_button(target_button)
			_connect_pressed(target_button, func() -> void: _manual_target_unit(target_instance_id))
			card_box.add_child(target_button)

		if is_player and _manual_combat_accepts_input(state):
			_add_manual_ability_buttons(card_box, unit, state)


func _add_manual_hand(parent: VBoxContainer, combatant: Dictionary, state: Dictionary) -> void:
	var zone := _add_manual_zone(parent, "Hand Zone", "PlayerHand", "#182537")
	if current_screen == "ui_combat":
		zone.custom_minimum_size = Vector2(0, _ui_combat_zone_height("PlayerHand"))
		zone.size_flags_vertical = Control.SIZE_SHRINK_END

	var hand: Array = combatant.get("hand", [])
	if hand.is_empty():
		_add_manual_empty_zone_slot(zone, "Empty Hand")
		return
	if current_screen == "ui_combat":
		_add_manual_fanned_hand(zone, hand, state)
		return

	var grid := GridContainer.new()
	grid.columns = min(5, max(1, hand.size()))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	zone.add_child(grid)

	for hand_index in range(hand.size()):
		var card_id := String(hand[hand_index])
		var card: Dictionary = cards_by_id[card_id]
		var selected := _manual_selection_is_card(card_id)
		var border_color := Color("#465060")
		var border_width := 1
		if selected:
			border_color = Color("#ffe08a")
			border_width = 3
		var card_box := _add_combat_placeholder_card(
			grid,
			String(card.get("name", card_id)),
			"Cost %d" % int(card.get("cost", 0)),
			_combat_effect_summary(card),
			_combat_placeholder_color(card_id),
			border_color,
			border_width,
			card_id,
			"Hand",
			"",
			_manual_hand_card_anchor(card_id, hand_index)
		)
		card_box.tooltip_text = card.get("text", "")
		if selected:
			_add_manual_card_badge(card_box, "SELECTED", Color("#ffe08a"))

		var selected_card_id := card_id
		var can_play := _manual_can_play_card(state, card_id)
		if _manual_card_needs_target(card):
			var select_button := _make_button("Selected" if selected else "Select")
			select_button.name = "ManualCardSelectButton"
			_style_button(select_button, "selected" if selected else "action")
			_compact_manual_card_button(select_button)
			select_button.disabled = not can_play and not selected
			if selected:
				_connect_pressed(select_button, _manual_clear_selection)
			else:
				_connect_pressed(select_button, func() -> void: _manual_select_card(selected_card_id))
			card_box.add_child(select_button)
		else:
			var play_button := _make_button("Play")
			play_button.name = "ManualCardPlayButton"
			_style_button(play_button, "action")
			_compact_manual_card_button(play_button)
			play_button.disabled = not can_play
			_connect_pressed(play_button, func() -> void: _manual_play_card(selected_card_id))
			card_box.add_child(play_button)


func _add_manual_fanned_hand(parent: VBoxContainer, hand: Array, state: Dictionary) -> void:
	var fan := Control.new()
	fan.name = "ManualFanHand"
	fan.custom_minimum_size = Vector2(0, 216)
	fan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(fan)

	for hand_index in range(hand.size()):
		var card_id := String(hand[hand_index])
		var card: Dictionary = cards_by_id[card_id]
		var selected := _manual_selection_is_card(card_id)
		var border_color := Color("#465060")
		var border_width := 1
		if selected:
			border_color = Color("#ffe08a")
			border_width = 3
		var card_box := _add_combat_placeholder_card(
			fan,
			String(card.get("name", card_id)),
			"Cost %d" % int(card.get("cost", 0)),
			_combat_effect_summary(card),
			_combat_placeholder_color(card_id),
			border_color,
			border_width,
			card_id,
			"Hand",
			"",
			_manual_hand_card_anchor(card_id, hand_index)
		)
		var card_panel := _manual_card_panel_from_contents(card_box)
		if card_panel != null:
			card_panel.size = card_panel.custom_minimum_size
			card_panel.position = Vector2(16 + hand_index * 52, 12)
			card_panel.z_index = hand_index
		card_box.tooltip_text = card.get("text", "")
		if selected:
			_add_manual_card_badge(card_box, "SELECTED", Color("#ffe08a"))

		var selected_card_id := card_id
		var can_play := _manual_can_play_card(state, card_id)
		if _manual_card_needs_target(card):
			var select_button := _make_button("Selected" if selected else "Select")
			select_button.name = "ManualCardSelectButton"
			_style_button(select_button, "selected" if selected else "action")
			_compact_manual_card_button(select_button)
			select_button.disabled = not can_play and not selected
			if selected:
				_connect_pressed(select_button, _manual_clear_selection)
			else:
				_connect_pressed(select_button, func() -> void: _manual_select_card(selected_card_id))
			card_box.add_child(select_button)
		else:
			var play_button := _make_button("Play")
			play_button.name = "ManualCardPlayButton"
			_style_button(play_button, "action")
			_compact_manual_card_button(play_button)
			play_button.disabled = not can_play
			_connect_pressed(play_button, func() -> void: _manual_play_card(selected_card_id))
			card_box.add_child(play_button)

	call_deferred("_layout_manual_fanned_hand", fan)


func _layout_manual_fanned_hand(fan: Control) -> void:
	if not is_instance_valid(fan):
		return
	var card_panels: Array = []
	for child in fan.get_children():
		if child is Control and String(child.name).begins_with("CombatCardPanel_Hand"):
			card_panels.append(child)
	var count := card_panels.size()
	if count <= 0:
		return
	var card_size: Vector2 = card_panels[0].custom_minimum_size
	var available_width := fan.size.x
	if available_width <= 1.0:
		available_width = max(card_size.x, card_size.x + 58.0 * float(max(0, count - 1)))
	var spread: float = 0.0 if count == 1 else clamp((available_width - card_size.x) / float(count - 1), 58.0, 88.0)
	var total_width: float = card_size.x + spread * float(max(0, count - 1))
	var start_x: float = max(0.0, (available_width - total_width) * 0.5)
	var center_index: float = float(count - 1) * 0.5
	var base_y := -12.0 if current_screen == "ui_combat" else 0.0
	for index in range(count):
		var card_panel: Control = card_panels[index]
		var offset: float = float(index) - center_index
		card_panel.size = card_panel.custom_minimum_size
		card_panel.pivot_offset = card_panel.custom_minimum_size * 0.5
		card_panel.position = Vector2(start_x + spread * float(index), base_y + abs(offset) * 2.8)
		card_panel.rotation_degrees = offset * 7.0
		card_panel.z_index = index


func _manual_card_panel_from_contents(contents: Node) -> Control:
	var node := contents
	while node != null:
		if node is PanelContainer and (String(node.name).begins_with("CombatCardPanel") or String(node.name).begins_with("ManualDragCardGhost")):
			return node as Control
		node = node.get_parent()
	return null


func _manual_handle_hand_card_drag_input(event: InputEvent) -> bool:
	if manual_drag_candidate.is_empty() and manual_drag_state.is_empty():
		return false
	if event is InputEventMouseMotion:
		_manual_update_hand_card_drag(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_manual_finish_hand_card_drag(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return true
	return false


func _manual_try_begin_hand_card_drag(card_id: String, source_panel: Control) -> bool:
	if current_screen != "ui_combat":
		return false
	if not _manual_can_drag_hand_card(card_id):
		return false
	if source_panel == null or not is_instance_valid(source_panel):
		return false
	_manual_free_orphan_hand_drag_ghosts()
	var source_rect := source_panel.get_global_rect()
	manual_drag_candidate = {
		"card_id": card_id,
		"start_global": get_global_mouse_position(),
		"source_global": source_rect.get_center()
	}
	return true


func _manual_can_drag_hand_card(card_id: String) -> bool:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return false
	if not cards_by_id.has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	var combat_type := _combat_card_type(card)
	if not _manual_can_play_card(run.manual_combat, card_id):
		return false
	if combat_type == "threat" or combat_type == "engine":
		return true
	return combat_type == "action" and _manual_card_needs_target(card)


func _manual_update_hand_card_drag(global_position: Vector2) -> void:
	if manual_drag_state.is_empty():
		if manual_drag_candidate.is_empty():
			return
		var start: Vector2 = manual_drag_candidate.get("start_global", global_position)
		if start.distance_to(global_position) < 8.0:
			return
		_manual_start_hand_card_drag()

	if manual_drag_state.is_empty():
		return

	_manual_position_hand_drag_ghost(global_position)
	var card_id := String(manual_drag_state.get("card_id", ""))
	var drop_target := _manual_hand_card_drag_target(card_id, global_position)
	var valid_drop := not drop_target.is_empty()
	manual_drag_state["drop_target"] = drop_target
	manual_drag_state["global_position"] = [global_position.x, global_position.y]
	manual_drag_state["valid_drop"] = valid_drop
	_manual_set_hand_drag_visual_state(valid_drop)
	_manual_refresh_drag_preview_layer()


func _manual_start_hand_card_drag() -> void:
	if manual_drag_candidate.is_empty():
		return
	var card_id := String(manual_drag_candidate.get("card_id", ""))
	if not _manual_can_drag_hand_card(card_id):
		_manual_clear_hand_card_drag()
		return
	var source_global: Vector2 = manual_drag_candidate.get("source_global", get_global_mouse_position())
	manual_drag_state = {
		"card_id": card_id,
		"source_global": source_global,
		"valid_drop": false
	}
	manual_drag_ghost = _create_manual_hand_drag_ghost(card_id)
	_manual_position_hand_drag_ghost(get_global_mouse_position())
	_manual_set_drag_board_highlight(true)
	_set_footer(_manual_drag_footer_text(card_id))


func _manual_finish_hand_card_drag(global_position: Vector2) -> void:
	if manual_drag_state.is_empty():
		if not manual_drag_candidate.is_empty():
			var clicked_card_id := String(manual_drag_candidate.get("card_id", ""))
			_manual_clear_hand_card_drag()
			if cards_by_id.has(clicked_card_id):
				_manual_set_inspect_card(clicked_card_id, "Hand", "", true)
				call_deferred("_show_active_combat_screen")
		return

	var card_id := String(manual_drag_state.get("card_id", ""))
	var drop_target := _manual_hand_card_drag_target(card_id, global_position)
	var valid_drop := not drop_target.is_empty()
	var source_global: Vector2 = manual_drag_state.get("source_global", global_position)
	if valid_drop:
		_manual_clear_hand_card_drag()
		match String(drop_target.get("kind", "")):
			"board_slot", "engine_slot":
				_manual_play_card_to_slot(card_id, int(drop_target.get("slot_index", -1)))
			"action_target":
				_manual_play_card_target(card_id, String(drop_target.get("target_type", "face")), int(drop_target.get("target_instance_id", -1)))
	else:
		_manual_snap_back_hand_drag_ghost(source_global)
		manual_drag_candidate = {}
		manual_drag_state = {}
		_manual_set_drag_board_highlight(false)
		_set_footer(_manual_drag_footer_text(card_id))


func _manual_clear_hand_card_drag() -> void:
	manual_drag_candidate = {}
	manual_drag_state = {}
	_manual_set_drag_board_highlight(false)
	if manual_drag_ghost != null and is_instance_valid(manual_drag_ghost):
		manual_drag_ghost.queue_free()
	manual_drag_ghost = null
	_manual_free_orphan_hand_drag_ghosts()
	_manual_refresh_drag_preview_layer()


func _manual_free_orphan_hand_drag_ghosts() -> void:
	_manual_free_descendants_by_prefix(self, "ManualDragCardGhost")


func _manual_free_descendants_by_prefix(root: Node, target_prefix: String) -> void:
	for child in root.get_children():
		if String(child.name).begins_with(target_prefix):
			child.queue_free()
		else:
			_manual_free_descendants_by_prefix(child, target_prefix)


func _manual_snap_back_hand_drag_ghost(source_global: Vector2) -> void:
	if manual_drag_ghost == null or not is_instance_valid(manual_drag_ghost):
		manual_drag_ghost = null
		return
	var ghost := manual_drag_ghost
	manual_drag_ghost = null
	var ghost_size := ghost.custom_minimum_size
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "global_position", source_global - ghost_size * 0.5, 0.14)
	tween.parallel().tween_property(ghost, "modulate", Color(1, 1, 1, 0.0), 0.14)
	tween.tween_callback(Callable(ghost, "queue_free"))


func _manual_position_hand_drag_ghost(global_position: Vector2) -> void:
	if manual_drag_ghost == null or not is_instance_valid(manual_drag_ghost):
		return
	var ghost_size := manual_drag_ghost.custom_minimum_size
	manual_drag_ghost.global_position = global_position - ghost_size * 0.5
	manual_drag_ghost.visible = true


func _manual_set_hand_drag_visual_state(valid_drop: bool) -> void:
	if manual_drag_ghost != null and is_instance_valid(manual_drag_ghost):
		manual_drag_ghost.modulate = Color(0.92, 1.08, 0.95, 0.94) if valid_drop else Color(1.08, 0.92, 0.92, 0.88)
	var card_id := String(manual_drag_state.get("card_id", manual_drag_candidate.get("card_id", "")))
	_manual_apply_drag_zone_highlight(card_id, valid_drop, true)


func _manual_set_drag_board_highlight(active: bool) -> void:
	var card_id := String(manual_drag_state.get("card_id", manual_drag_candidate.get("card_id", "")))
	_manual_apply_drag_zone_highlight(card_id, false, active)


func _manual_refresh_drag_preview_layer() -> void:
	var layer := _find_descendant_by_prefix(self, "ManualBoardArcLayer")
	if layer != null and layer is Node2D:
		_refresh_manual_board_arc_layer(layer)


func _manual_hand_card_drag_drop_is_valid(card_id: String, global_position: Vector2) -> bool:
	return not _manual_hand_card_drag_target(card_id, global_position).is_empty()


func _manual_hand_card_drag_target(card_id: String, global_position: Vector2) -> Dictionary:
	if not _manual_can_drag_hand_card(card_id):
		return {}
	var card: Dictionary = cards_by_id[card_id]
	match _combat_card_type(card):
		"threat":
			var board_slot := _manual_hand_card_drag_target_slot(global_position)
			if board_slot >= 0 and _manual_board_slot_is_open(run.manual_combat.get("player", {}), board_slot):
				return { "kind": "board_slot", "slot_index": board_slot }
		"engine":
			var engine_slot := _manual_hand_card_drag_engine_target_slot(global_position)
			if engine_slot >= 0 and _manual_engine_slot_is_open(run.manual_combat.get("player", {}), engine_slot):
				return { "kind": "engine_slot", "slot_index": engine_slot }
		"action":
			return _manual_hand_card_drag_action_target(card_id, global_position)
	return {}


func _manual_hand_card_drag_target_slot(global_position: Vector2) -> int:
	for slot_index in range(COMBAT_BOARD_SLOTS):
		var slot := _find_descendant_by_prefix(self, _manual_board_slot_anchor(true, slot_index))
		if slot != null and slot is Control and (slot as Control).get_global_rect().has_point(global_position):
			return slot_index
	return -1


func _manual_hand_card_drag_engine_target_slot(global_position: Vector2) -> int:
	for slot_index in range(COMBAT_ENGINE_SLOTS):
		var slot := _find_descendant_by_prefix(self, _manual_engine_slot_anchor(true, slot_index))
		if slot != null and slot is Control and (slot as Control).get_global_rect().has_point(global_position):
			return slot_index
	return -1


func _manual_hand_card_drag_action_target(card_id: String, global_position: Vector2) -> Dictionary:
	if not cards_by_id.has(card_id):
		return {}
	var card: Dictionary = cards_by_id[card_id]
	var state: Dictionary = run.get("manual_combat", {})
	if state.is_empty():
		return {}
	if _manual_card_can_target_units(card):
		var opponent: Dictionary = state.get("opponent", {})
		for unit in opponent.get("board", []):
			var instance_id := int(unit.get("instance_id", -1))
			var anchor := _manual_unit_card_anchor(false, instance_id)
			if _manual_global_point_hits_anchor(anchor, global_position):
				return {
					"kind": "action_target",
					"target_type": "unit",
					"target_instance_id": instance_id
				}
	if _manual_card_can_target_face(card) and _manual_global_point_hits_anchor("ManualOpponentFanHand", global_position):
		return {
			"kind": "action_target",
			"target_type": "face",
			"target_instance_id": -1
		}
	return {}


func _manual_global_point_hits_anchor(anchor: String, global_position: Vector2) -> bool:
	var node := _find_descendant_by_prefix(self, anchor)
	return node != null and node is Control and (node as Control).get_global_rect().has_point(global_position)


func _manual_apply_drag_zone_highlight(card_id: String, valid_drop: bool, active: bool) -> void:
	var anchors := [
		"ManualZone_PlayerBoard",
		"ManualZone_PlayerEngine",
		"ManualOpponentFanHand",
		"ManualZone_OpponentBoard"
	]
	for anchor in anchors:
		var node := _find_descendant_by_prefix(self, anchor)
		if node != null and node is Control:
			(node as Control).modulate = Color.WHITE
	var state: Dictionary = run.get("manual_combat", {})
	var opponent: Dictionary = state.get("opponent", {})
	for unit_value in opponent.get("board", []):
		var unit: Dictionary = unit_value
		var unit_anchor := _manual_unit_card_anchor(false, int(unit.get("instance_id", -1)))
		var unit_node := _find_descendant_by_prefix(self, unit_anchor)
		if unit_node != null and unit_node is Control:
			(unit_node as Control).modulate = Color.WHITE
	if not active or not cards_by_id.has(card_id):
		return

	var color := Color(1.08, 1.16, 1.08, 1.0) if valid_drop else Color(1.12, 1.02, 1.02, 1.0)
	var card: Dictionary = cards_by_id[card_id]
	var target_anchors: Array = []
	match _combat_card_type(card):
		"threat":
			target_anchors.append("ManualZone_PlayerBoard")
		"engine":
			target_anchors.append("ManualZone_PlayerEngine")
		"action":
			if _manual_card_can_target_face(card):
				target_anchors.append("ManualOpponentFanHand")
			if _manual_card_can_target_units(card):
				target_anchors.append("ManualZone_OpponentBoard")
	for anchor in target_anchors:
		var node := _find_descendant_by_prefix(self, anchor)
		if node != null and node is Control:
			(node as Control).modulate = color
	if valid_drop:
		var drop_target: Dictionary = manual_drag_state.get("drop_target", {})
		if String(drop_target.get("kind", "")) == "action_target":
			var exact_anchor := ""
			match String(drop_target.get("target_type", "")):
				"face":
					exact_anchor = "ManualOpponentFanHand"
				"unit":
					exact_anchor = _manual_unit_card_anchor(false, int(drop_target.get("target_instance_id", -1)))
			if exact_anchor != "":
				var exact_node := _find_descendant_by_prefix(self, exact_anchor)
				if exact_node != null and exact_node is Control:
					(exact_node as Control).modulate = Color(1.18, 1.24, 1.08, 1.0)


func _manual_drag_footer_text(card_id: String) -> String:
	if not cards_by_id.has(card_id):
		return "Drop the card on a legal target."
	var card: Dictionary = cards_by_id[card_id]
	var name := String(card.get("name", card_id))
	match _combat_card_type(card):
		"threat":
			return "Drag onto an open board slot to play " + name + "."
		"engine":
			return "Drag onto an open engine slot to play " + name + "."
		"action":
			return "Drag onto the opponent hand or a legal unit target to cast " + name + "."
	return "Drop " + name + " on a legal target."


func _create_manual_hand_drag_ghost(card_id: String) -> Control:
	var box: VBoxContainer = card_frame_factory.add_frame(
		self,
		_card_frame_data(card_id),
		{
			"panel_name": "ManualDragCardGhost",
			"contents_name": "ManualDragCardGhostContents",
			"name_prefix": "ManualDragCard",
			"compact": true,
			"min_size": Vector2(104, 154),
			"mouse_filter": Control.MOUSE_FILTER_IGNORE,
			"show_deck_stats": false,
			"show_rules_text": false,
			"border_color": Color("#ffe08a"),
			"border_width": 2
		}
	)
	var ghost := _manual_card_panel_from_contents(box)
	if ghost == null:
		return box
	ghost.set_as_top_level(true)
	ghost.z_index = 420
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = ghost.custom_minimum_size
	ghost.scale = Vector2(1.08, 1.08)
	ghost.modulate = Color(1, 1, 1, 0.92)
	ghost.visible = false
	return ghost


func _add_manual_ability_buttons(card_box: VBoxContainer, unit: Dictionary, state: Dictionary) -> void:
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return
	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = card.get("combat", {})
	var abilities: Array = combat.get("abilities", [])
	for index in range(abilities.size()):
		var ability: Dictionary = abilities[index]
		var instance_id := int(unit.get("instance_id", -1))
		var ability_index := index
		var label := String(ability.get("label", "Ability"))
		var cost := int(ability.get("cost", 0))
		var button := _make_button("Use [%d]" % cost if current_screen == "ui_combat" else "%s [%d]" % [label, cost])
		button.name = "ManualAbilityButton"
		_style_button(button, "action")
		_compact_manual_card_button(button)
		button.disabled = not _manual_can_activate_ability(state, unit, ability, index)
		_connect_pressed(button, func() -> void: _manual_activate_unit_ability(instance_id, ability_index))
		card_box.add_child(button)


func _add_manual_card_badge(parent: Node, text: String, color: Color) -> void:
	var compact_duel := current_screen == "ui_combat"
	var badge := Label.new()
	badge.name = "ManualTargetBadge" if text == "LEGAL TARGET" else "ManualCardBadge"
	var display_text := text
	if compact_duel:
		match text:
			"ATTACKER SELECTED":
				display_text = "ATTACKER"
			"LEGAL TARGET":
				display_text = "TARGET"
			"SELECTED":
				display_text = "SEL"
	badge.text = display_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 9 if compact_duel else 11)
	badge.add_theme_color_override("font_color", color)
	parent.add_child(badge)


func _add_combat_placeholder_card(parent: Node, title: String, subtitle: String, body: String, accent: Color, border_color: Color = Color("#465060"), border_width: int = 1, inspect_card_id: String = "", inspect_zone: String = "", inspect_current: String = "", node_anchor: String = "", printed_type: String = "", printed_animal_type: String = "") -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var type_text := printed_type
	var animal_type := printed_animal_type if printed_animal_type != "" else "neutral"
	if inspect_card_id != "" and cards_by_id.has(inspect_card_id):
		var inspect_card: Dictionary = cards_by_id[inspect_card_id]
		type_text = _combat_card_type_line(inspect_card) if type_text == "" else type_text
		animal_type = _card_animal_type(inspect_card) if printed_animal_type == "" else printed_animal_type
	elif type_text == "":
		animal_type = "neutral"

	var frame_data := _card_frame_data(inspect_card_id, {
		"title": title,
		"type_line": type_text,
		"animal_color": _affinity_color(animal_type),
		"frame_color": accent,
		"border_color": border_color,
		"border_width": border_width,
		"combat_stats": inspect_current if inspect_current != "" else subtitle,
		"effect_text": _combat_effect_summary(cards_by_id[inspect_card_id]) if inspect_card_id != "" and cards_by_id.has(inspect_card_id) else body,
		"rules_text": String(cards_by_id[inspect_card_id].get("text", "")) if inspect_card_id != "" and cards_by_id.has(inspect_card_id) else body,
		"art_text": "",
		"area_text": ""
	})
	var current_stats := _attack_health_from_text(inspect_current if inspect_current != "" else subtitle)
	if not current_stats.is_empty():
		frame_data.attack = int(current_stats.attack)
		frame_data.health = int(current_stats.health)
		frame_data.show_attack_health = true

	var box: VBoxContainer = card_frame_factory.add_frame(
		parent,
		frame_data,
		{
			"panel_name": node_anchor if node_anchor != "" else "CombatCardPanel",
			"contents_name": "CombatCardContents",
			"name_prefix": "CombatCardFrame",
			"compact": compact_duel,
			"min_size": Vector2(104, 154) if compact_duel else Vector2(176, 236),
			"border_color": border_color,
			"border_width": border_width,
			"show_deck_stats": false,
			"show_rules_text": not compact_duel
		}
	)
	var panel := _manual_card_panel_from_contents(box)
	if panel != null:
		_apply_combat_card_motion(panel, inspect_card_id, inspect_zone, inspect_current)
	return box


func _attack_health_from_text(text: String) -> Dictionary:
	var slash_index := text.find("/")
	if slash_index < 0:
		return {}

	var attack_start := slash_index - 1
	while attack_start >= 0 and _is_digit(text.substr(attack_start, 1)):
		attack_start -= 1
	attack_start += 1

	var health_end := slash_index + 1
	while health_end < text.length() and _is_digit(text.substr(health_end, 1)):
		health_end += 1

	if attack_start >= slash_index or health_end <= slash_index + 1:
		return {}

	return {
		"attack": int(text.substr(attack_start, slash_index - attack_start)),
		"health": int(text.substr(slash_index + 1, health_end - slash_index - 1))
	}


func _is_digit(character: String) -> bool:
	return character >= "0" and character <= "9"


func _apply_combat_card_motion(card_panel: Control, inspect_card_id: String = "", inspect_zone: String = "", inspect_current: String = "") -> void:
	card_panel.mouse_entered.connect(func() -> void:
		if inspect_card_id != "" and current_screen != "ui_combat":
			_manual_set_inspect_card(inspect_card_id, inspect_zone, inspect_current, false)
		_tween_control_feedback(card_panel, Vector2(1.035, 1.035), Color(1.12, 1.12, 1.12, 1.0), 0.08)
	)
	card_panel.mouse_exited.connect(func() -> void:
		if inspect_card_id != "" and current_screen != "ui_combat":
			_manual_clear_hover_inspect(inspect_card_id, inspect_zone, inspect_current)
		_tween_control_feedback(card_panel, Vector2.ONE, Color.WHITE, 0.10)
	)
	card_panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				card_panel.accept_event()
				if _manual_try_begin_hand_card_drag(inspect_card_id, card_panel):
					_tween_control_feedback(card_panel, Vector2(1.035, 1.035), Color(1.10, 1.10, 1.10, 1.0), 0.06)
					return
				if inspect_card_id != "":
					_manual_set_inspect_card(inspect_card_id, inspect_zone, inspect_current, true)
					if current_screen == "ui_combat":
						call_deferred("_show_active_combat_screen")
				_tween_control_feedback(card_panel, Vector2(0.985, 0.985), Color(0.95, 0.95, 0.95, 1.0), 0.05)
			else:
				card_panel.accept_event()
				_tween_control_feedback(card_panel, Vector2(1.035, 1.035), Color(1.12, 1.12, 1.12, 1.0), 0.07)
	)


func _tween_control_feedback(control: Control, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if not is_instance_valid(control):
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target_scale, duration)
	tween.parallel().tween_property(control, "modulate", target_modulate, duration)


func _add_manual_face_target(parent: VBoxContainer, state: Dictionary) -> void:
	if not _manual_selection_can_try_face(state):
		return

	var selected_can_face := _manual_selected_can_target_face(state)
	var target_panel := PanelContainer.new()
	target_panel.name = "ManualFaceTargetAffordance"
	target_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#203421") if selected_can_face else Color("#372323")
	style.border_color = Color("#9ee66e") if selected_can_face else Color("#d8a0a0")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	target_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(target_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	target_panel.add_child(margin)

	var face_row := HBoxContainer.new()
	face_row.add_theme_constant_override("separation", 6)
	margin.add_child(face_row)

	var face_label := Label.new()
	face_label.text = "OPPONENT FACE"
	face_label.add_theme_color_override("font_color", Color("#9ee66e") if selected_can_face else Color("#d8a0a0"))
	face_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	face_row.add_child(face_label)

	var face_button := _make_button(_manual_target_action_label() + " Face")
	face_button.name = "ManualFaceTargetButton"
	_style_button(face_button, "target" if selected_can_face else "danger")
	face_button.disabled = not selected_can_face
	if not selected_can_face:
		face_button.tooltip_text = _manual_face_block_reason(state)
	_connect_pressed(face_button, _manual_target_face)
	face_row.add_child(face_button)


func _manual_target_action_label() -> String:
	match String(_manual_selection().get("kind", "")):
		"attacker":
			return "Attack"
		"card":
			return "Cast At"
		_:
			return "Target"


func _manual_selection() -> Dictionary:
	if run.is_empty():
		return {}
	if not run.has("manual_selection"):
		run.manual_selection = {}
	return run.manual_selection


func _manual_selection_label(state: Dictionary) -> String:
	if _manual_has_pending_action():
		var animation: Dictionary = run.get("manual_animation", {})
		if not animation.is_empty():
			return "Resolving %s..." % String(animation.get("card_name", "action"))
		return "Resolving action..."
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			if cards_by_id.has(card_id):
				var card: Dictionary = cards_by_id[card_id]
				return "Selected card: %s | %s" % [card.get("name", card_id), _manual_target_mode_label(card)]
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			if not attacker.is_empty():
				return "Selected attacker: %s %d/%d" % [
					attacker.get("name", "Threat"),
					int(attacker.get("attack", 0)),
					int(attacker.get("health", 0))
				]
	return "Select a playable card or ready attacker."


func _manual_selection_is_card(card_id: String) -> bool:
	var selection := _manual_selection()
	return String(selection.get("kind", "")) == "card" and String(selection.get("card_id", "")) == card_id


func _manual_selection_is_attacker(unit: Dictionary) -> bool:
	var selection := _manual_selection()
	return String(selection.get("kind", "")) == "attacker" and int(selection.get("instance_id", -1)) == int(unit.get("instance_id", -2))


func _manual_selection_can_try_face(state: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_card_can_target_face(cards_by_id[card_id])
		"attacker":
			return not _manual_find_player_unit(state, int(selection.get("instance_id", -1))).is_empty()
	return false


func _manual_selected_can_target_face(state: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_can_play_card(state, card_id) and _manual_card_can_target_face(cards_by_id[card_id])
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			return not attacker.is_empty() and bool(attacker.get("ready", false)) and _manual_guard_unit(state).is_empty()
	return false


func _manual_selected_can_target_unit(state: Dictionary, unit: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	if unit.is_empty():
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_can_play_card(state, card_id) and _manual_card_can_target_units(cards_by_id[card_id])
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			return not attacker.is_empty() and bool(attacker.get("ready", false))
	return false


func _manual_find_player_unit(state: Dictionary, instance_id: int) -> Dictionary:
	var player: Dictionary = state.get("player", {})
	for unit in player.get("board", []):
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit
	return {}


func _manual_face_block_reason(state: Dictionary) -> String:
	var guard_unit := _manual_guard_unit(state)
	if not guard_unit.is_empty():
		return "%s is blocking face attacks." % guard_unit.get("name", "A guard")
	return "Face is not a legal target for the current selection."


func _manual_target_mode_label(card: Dictionary) -> String:
	match _manual_action_target_mode(card):
		"none":
			return "No target"
		"enemy_player":
			return "Targets face"
		"enemy_unit":
			return "Targets units"
		"any_enemy":
			return "Targets face or units"
		_:
			return "Unknown target mode"


func _combat_placeholder_color(card_id: String) -> Color:
	if not cards_by_id.has(String(card_id)):
		return Color("#28313d")
	var card: Dictionary = cards_by_id[String(card_id)]
	var base := _affinity_color(_card_animal_type(card))
	match String(card.get("rarity", "common")):
		"uncommon":
			return base.darkened(0.42)
		"rare":
			return base.darkened(0.32)
		"mythic":
			return base.darkened(0.22)
		_:
			return base.darkened(0.55)


func _combat_effect_summary(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	if combat.is_empty():
		return String(card.get("text", ""))

	match String(combat.get("kind", "")):
		"unit":
			var keywords: Array = combat.get("keywords", [])
			var keyword_text := ""
			if not keywords.is_empty():
				keyword_text = " | " + ", ".join(PackedStringArray(keywords))
			var on_play_text := ""
			if not combat.get("onPlay", []).is_empty():
				on_play_text = " | On play: " + _effect_list_summary(combat.get("onPlay", []))
			var trigger_text := ""
			if not combat.get("triggers", []).is_empty():
				var trigger_pieces: Array = []
				for trigger in combat.get("triggers", []):
					trigger_pieces.append("%s: %s" % [
						String(trigger.get("timing", "trigger")).replace("_", " ").capitalize(),
						_effect_list_summary(trigger.get("effects", []))
					])
				trigger_text = " | " + " | ".join(PackedStringArray(trigger_pieces))
			var ability_text := ""
			if not combat.get("abilities", []).is_empty():
				var ability_pieces: Array = []
				for ability in combat.get("abilities", []):
					ability_pieces.append("%s [%d]: %s" % [
						String(ability.get("label", "Ability")),
						int(ability.get("cost", 0)),
						_effect_list_summary(ability.get("effects", []))
					])
				ability_text = " | " + " | ".join(PackedStringArray(ability_pieces))
			return "%d/%d%s%s" % [
				int(combat.get("attack", 0)),
				int(combat.get("health", 0)),
				keyword_text,
				on_play_text + trigger_text + ability_text
			]
		"action":
			return _effect_list_summary(combat.get("effects", []))
		"engine":
			var pieces: Array = []
			for trigger in combat.get("triggers", []):
				pieces.append("%s: %s" % [
					String(trigger.get("timing", "start")).replace("_", " ").capitalize(),
					_effect_list_summary(trigger.get("effects", []))
				])
			return " | ".join(PackedStringArray(pieces))
		_:
			return String(card.get("text", ""))


func _effect_list_summary(effects: Array) -> String:
	var pieces: Array = []
	for effect in effects:
		var amount := int(effect.get("amount", 1))
		var amount_text := _effect_amount_summary(effect, amount)
		match String(effect.get("type", "")):
			"damage":
				pieces.append("%s damage" % amount_text)
			"draw":
				pieces.append("Draw %s" % amount_text)
			"heal":
				pieces.append("Heal %s" % amount_text)
			"summon":
				pieces.append("Create %s %d/%d" % [
					String(effect.get("name", "Token")),
					int(effect.get("attack", 1)),
					int(effect.get("health", 1))
				])
			"buff":
				pieces.append("+%d/+%d" % [
					int(effect.get("amount_attack", effect.get("amount", 0))),
					int(effect.get("amount_health", effect.get("amount", 0)))
				])
			"debuff":
				pieces.append("-%d/-%d" % [
					int(effect.get("amount_attack", effect.get("amount", 0))),
					int(effect.get("amount_health", effect.get("amount", 0)))
				])
			"destroy":
				pieces.append("Destroy")
			"exhaust":
				pieces.append("Exhaust")
			"grant_keyword":
				pieces.append("Grant " + String(effect.get("keyword", "")))
			"discard":
				pieces.append("Discard %s" % amount_text)
			"recover":
				pieces.append("Recover %s" % amount_text)
			"gain_focus":
				var restriction := String(effect.get("restrictedTo", ""))
				if restriction == "":
					pieces.append("+%s focus" % amount_text)
				else:
					pieces.append("+%s %s focus" % [amount_text, _archetype_label(restriction)])
	return " | ".join(PackedStringArray(pieces))


func _effect_amount_summary(effect: Dictionary, fallback: int) -> String:
	match String(effect.get("amountSource", "")):
		"source_attack":
			return "source attack"
		"enemy_hand_size":
			return "enemy hand"
		"enemy_discard_size":
			return "enemy discard"
		"own_discard_size":
			return "discard"
		"current_focus":
			return "focus"
		"played_card_cost":
			return "played cost"
		"friendly_animal_type_count":
			return "your " + _affinity_label(String(effect.get("animalType", effect.get("conditionValue", ""))))
		"enemy_animal_type_count":
			return "enemy " + _affinity_label(String(effect.get("animalType", effect.get("conditionValue", ""))))
		_:
			return str(fallback)


func _manual_unit_keyword_text(unit: Dictionary) -> String:
	var pieces: Array = []
	if bool(unit.get("ready", false)):
		pieces.append("Ready")
	var tags: Array = unit.get("tags", [])
	if tags.has("guard") or tags.has("stabilizer"):
		pieces.append("Guard")
	if tags.has("fast"):
		pieces.append("Fast")
	if tags.has("token"):
		pieces.append("Token")
	return " | ".join(PackedStringArray(pieces))


func _manual_card_needs_target(card: Dictionary) -> bool:
	if _combat_card_type(card) != "action":
		return false
	return _manual_action_target_mode(card) != "none"


func _manual_card_can_target_face(card: Dictionary) -> bool:
	var mode := _manual_action_target_mode(card)
	return mode == "enemy_player" or mode == "any_enemy"


func _manual_card_can_target_units(card: Dictionary) -> bool:
	var mode := _manual_action_target_mode(card)
	return mode == "enemy_unit" or mode == "any_enemy"


func _manual_action_target_mode(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	if combat.has("targetMode"):
		return String(combat.get("targetMode", "none"))
	var role := String(card.get("role", "answer"))
	match role:
		"answer", "tech":
			return "any_enemy"
		"filter":
			return "none"
		_:
			return "enemy_player"


func _manual_guard_unit(state: Dictionary) -> Dictionary:
	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		var tags: Array = unit.get("tags", [])
		if tags.has("guard") or tags.has("stabilizer"):
			return unit
	return {}


func _manual_combat_accepts_input(state: Dictionary) -> bool:
	return not _manual_has_pending_action() and not bool(state.get("game_over", false)) and String(state.get("phase", "")) == "player_main"


func _manual_can_play_card(state: Dictionary, card_id: String) -> bool:
	if not _manual_combat_accepts_input(state):
		return false
	var player: Dictionary = state.get("player", {})
	if not player.get("hand", []).has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	if int(card.get("cost", 0)) > _manual_available_focus_for_card(player, card):
		return false
	var combat_type := _combat_card_type(card)
	if combat_type == "threat" and player.get("board", []).size() >= 5:
		return false
	if combat_type == "engine" and player.get("engines", []).size() >= 3:
		return false
	if combat_type == "action" and _manual_action_target_mode(card) == "enemy_unit":
		var opponent: Dictionary = state.get("opponent", {})
		if opponent.get("board", []).is_empty():
			return false
	return true


func _manual_can_activate_ability(state: Dictionary, unit: Dictionary, ability: Dictionary, ability_index: int) -> bool:
	if not _manual_combat_accepts_input(state):
		return false
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	var player: Dictionary = state.get("player", {})
	if bool(ability.get("requiresReady", false)) and not bool(unit.get("ready", false)):
		return false
	if bool(ability.get("oncePerTurn", false)):
		var used: Dictionary = unit.get("used_abilities", {})
		var key := "%s:%d" % [String(ability.get("id", "ability_%d" % ability_index)), int(player.get("turns_taken", 0))]
		if used.has(key):
			return false
	if int(ability.get("cost", 0)) > _manual_available_focus_for_card(player, card):
		return false
	return String(ability.get("targetMode", "none")) == "none"


func _manual_available_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	return int(combatant.get("focus", 0)) + _manual_restricted_focus_for_card(combatant, card)


func _manual_restricted_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	var archetype := String(card.get("archetype", ""))
	if archetype == "" or archetype == "neutral":
		return 0
	var restricted: Dictionary = combatant.get("restricted_focus", {})
	return int(restricted.get(archetype, 0))


func _manual_restricted_focus_text(combatant: Dictionary) -> String:
	var restricted: Dictionary = combatant.get("restricted_focus", {})
	if restricted.is_empty():
		return ""
	var pieces: Array = []
	for archetype in restricted.keys():
		var amount := int(restricted[archetype])
		if amount <= 0:
			continue
		pieces.append("+%d %s" % [amount, _archetype_label(String(archetype))])
	if pieces.is_empty():
		return ""
	return " (%s)" % ", ".join(PackedStringArray(pieces))


func _combat_card_type(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	match String(combat.get("kind", "")):
		"unit":
			return "threat"
		"action":
			return "action"
		"engine":
			return "engine"

	var role := String(card.get("role", "threat"))
	match role:
		"threat", "finisher":
			return "threat"
		"engine":
			return "engine"
		_:
			return "action"


func _summarize_combatant(combatant: Dictionary) -> Dictionary:
	return {
		"life": int(combatant.get("life", 0)),
		"focus": int(combatant.get("focus", 0)),
		"max_focus": int(combatant.get("max_focus", 0)),
		"restricted_focus": combatant.get("restricted_focus", {}),
		"deck_count": combatant.get("deck", []).size(),
		"discard_count": combatant.get("discard", []).size(),
		"fatigue": int(combatant.get("fatigue", 0)),
		"hand": _summarize_card_ids(combatant.get("hand", [])),
		"discard": _summarize_card_ids(combatant.get("discard", [])),
		"engines": _summarize_engines(combatant.get("engines", [])),
		"board": _summarize_units(combatant.get("board", []))
	}


func _summarize_card_ids(card_ids: Array) -> Array:
	var counts := {}
	for card_id in card_ids:
		counts[String(card_id)] = int(counts.get(String(card_id), 0)) + 1

	var summaries: Array = []
	for card_id in counts.keys():
		var card: Dictionary = cards_by_id[String(card_id)]
		summaries.append({
			"card_id": String(card_id),
			"name": card.get("name", card_id),
			"count": int(counts[card_id]),
			"rarity": card.get("rarity", "common"),
			"role": card.get("role", "threat"),
			"cost": int(card.get("cost", 0))
		})
	summaries.sort_custom(func(a, b) -> bool:
		if int(a["cost"]) != int(b["cost"]):
			return int(a["cost"]) < int(b["cost"])
		return String(a["name"]) < String(b["name"])
	)
	return summaries


func _summarize_engines(engines: Array) -> Array:
	var card_ids: Array = []
	for engine in engines:
		card_ids.append(String(engine.get("card_id", "")))
	return _summarize_card_ids(card_ids)


func _summarize_units(units: Array) -> Array:
	var summaries: Array = []
	for unit in units:
		summaries.append({
			"name": unit.get("name", "Unknown"),
			"card_id": unit.get("card_id", ""),
			"attack": int(unit.get("attack", 0)),
			"health": int(unit.get("health", 0)),
			"max_health": int(unit.get("max_health", 0)),
			"ready": bool(unit.get("ready", false))
		})
	summaries.sort_custom(func(a, b) -> bool:
		var power_a := int(a["attack"]) + int(a["health"])
		var power_b := int(b["attack"]) + int(b["health"])
		if power_a != power_b:
			return power_a > power_b
		return String(a["name"]) < String(b["name"])
	)
	return summaries


func _add_combatant_snapshot(parent: Node, label: String, snapshot: Dictionary) -> void:
	var panel := _add_panel(parent, label)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if snapshot.is_empty():
		_add_body_text(panel, "No combat snapshot yet.")
		return

	_add_body_text(panel, "Life %d | Focus %d/%d%s | Deck %d | Discard %d | Fatigue %d" % [
		int(snapshot.get("life", 0)),
		int(snapshot.get("focus", 0)),
		int(snapshot.get("max_focus", 0)),
		_manual_restricted_focus_text(snapshot),
		int(snapshot.get("deck_count", 0)),
		int(snapshot.get("discard_count", 0)),
		int(snapshot.get("fatigue", 0))
	])
	_add_combat_zone(panel, "Board", snapshot.get("board", []), true)
	_add_combat_zone(panel, "Engines", snapshot.get("engines", []), false)
	_add_combat_zone(panel, "Hand", snapshot.get("hand", []), false)
	_add_combat_zone(panel, "Discard Highlights", snapshot.get("discard", []).slice(0, 8), false)


func _add_combat_zone(parent: VBoxContainer, title: String, entries: Array, is_board: bool) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color", Color("#f3efe4"))
	parent.add_child(heading)

	if entries.is_empty():
		_add_body_text(parent, "None")
		return

	for entry in entries:
		if is_board:
			_add_body_text(parent, "%s %d/%d%s" % [
				String(entry.get("name", "Unknown")),
				int(entry.get("attack", 0)),
				int(entry.get("health", 0)),
				" ready" if bool(entry.get("ready", false)) else ""
			])
		else:
			_add_body_text(parent, "%s x%d | %s | cost %d" % [
				String(entry.get("name", "Unknown")),
				int(entry.get("count", 1)),
				String(entry.get("role", "card")).capitalize(),
				int(entry.get("cost", 0))
			])


func _show_tournament() -> void:
	if _guard_run_over():
		return
	current_screen = "tournament"
	_render_nav()
	_clear(content)
	_update_status()

	var event: Dictionary = tournaments_by_id["weekly_locals"]
	var legal := _deck_is_legal()
	var panel := _add_panel(content, event.name)
	_add_body_text(panel, "Format: 3 rounds, best-of-three matches. You need 2 wins to keep the run alive.")
	_add_body_text(panel, "Entry fee: $%d | Current money: $%d" % [event.entryFee, run.money])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var enter := _make_button("Enter Weekly Locals")
	enter.disabled = not legal.ok or run.money < int(event.entryFee)
	_connect_pressed(enter, _run_tournament)
	panel.add_child(enter)

	if run.last_result.size() > 0:
		var last := _add_panel(content, "Last Tournament")
		for line in run.last_result:
			_add_body_text(last, line)


func _run_tournament() -> void:
	var event: Dictionary = tournaments_by_id["weekly_locals"]
	var legal := _deck_is_legal()
	if not legal.ok:
		_set_footer(legal.reason)
		return
	if run.money < int(event.entryFee):
		_set_footer("You cannot afford the entry fee.")
		return

	run.money -= int(event.entryFee)

	var logs := []
	var wins := 0
	var losses := 0
	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)

	logs.append("Entered %s with %s. Entry paid: $%d." % [event.name, archetypes_by_id[deck_metrics.primary].name, event.entryFee])

	for round_number in range(1, int(event.rounds) + 1):
		var opponent := _generate_opponent(round_number, deck_metrics)
		var result := _simulate_combat_match(opponent, deck_metrics)
		if result.won:
			wins += 1
		else:
			losses += 1

		logs.append(
			"Round %d vs %s on %s: %s %d-%d. Estimated match odds: %d%%."
			% [
				round_number,
				opponent.name,
				archetypes_by_id[opponent.archetype].name,
				"Won" if result.won else "Lost",
				result.player_game_wins,
				result.opponent_game_wins,
				int(round(result.display_probability * 100.0))
			]
		)
		for game_summary in result.get("game_summaries", []):
			logs.append("  " + String(game_summary))

	var reward_money := 0
	var reward_packs := 0
	if wins >= int(event.requiredWins):
		reward_money = int(event.rewardMoney.get(str(wins), 0))
		reward_packs = int(event.rewardPacks.get(str(wins), 0))
		run.money += reward_money
		run.prize_packs += reward_packs
		run.week = int(run.week) + 1
		logs.append("Record: %d-%d. Run continues. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
	else:
		run.run_over = true
		logs.append("Record: %d-%d. Required record missed. The season ends here." % [wins, losses])

	_update_meta_after_event(deck_metrics.primary, wins, int(event.rounds))
	_generate_shop_inventory()
	run.last_result = logs
	_show_tournament_result(logs, wins >= int(event.requiredWins))


func _show_tournament_result(logs: Array, survived: bool) -> void:
	current_screen = "result"
	_render_nav()
	_clear(content)
	_update_status()

	var panel := _add_panel(content, "Tournament Result", "#253044" if survived else "#442525")
	for line in logs:
		_add_body_text(panel, line)

	if survived:
		var continue_button := _make_button("Return to Card Shop")
		_connect_pressed(continue_button, _show_shop)
		panel.add_child(continue_button)
	else:
		var restart_button := _make_button("Start New Run")
		_connect_pressed(restart_button, _show_start)
		panel.add_child(restart_button)


func _generate_opponent(round_number: int, deck_metrics: Dictionary) -> Dictionary:
	var names := ["Mina", "Owen", "Priya", "Cal", "Nico", "Sam", "Jules", "Iris"]
	if round_number == 3:
		var boss_archetype: String = _predator_archetype(String(deck_metrics.primary))
		return {
			"name": "Local Rival Tess",
			"archetype": boss_archetype,
			"quality": 52.0 + float(run.week) * 1.8,
			"tags": archetypes_by_id[boss_archetype].tags
		}

	var archetype_id: String = _weighted_meta_pick()
	return {
		"name": names[rng.randi_range(0, names.size() - 1)],
		"archetype": archetype_id,
		"quality": 43.0 + float(round_number) * 3.0 + float(run.week) * 1.2 + rng.randf_range(-3.0, 3.0),
		"tags": archetypes_by_id[archetype_id].tags
	}


func _weighted_meta_pick() -> String:
	var roll := rng.randf()
	var cursor := 0.0
	for archetype_id in ARCHETYPE_ORDER:
		cursor += float(run.meta.get(archetype_id, 0.0))
		if roll <= cursor:
				return String(archetype_id)
	return String(ARCHETYPE_ORDER.back())


func _predator_archetype(archetype_id: String) -> String:
	return run_state_service.predator_archetype(archetype_id)


func _simulate_combat_match(opponent: Dictionary, deck_metrics: Dictionary) -> Dictionary:
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[String(opponent.archetype)].get("starterDeck", []))
	var player_game_wins := 0
	var opponent_game_wins := 0
	var game_number := 1
	var game_summaries: Array = []

	while player_game_wins < 2 and opponent_game_wins < 2:
		var seed_value := rng.randi()
		var result: Dictionary = combat_service.auto_play_game(run.deck, String(deck_metrics.primary), opponent_deck, String(opponent.archetype), seed_value)
		if String(result.get("winner", "")) == "player":
			player_game_wins += 1
		else:
			opponent_game_wins += 1

		game_summaries.append("Game %d: %s on turn %d. Life %d-%d. Seed %d." % [
			game_number,
			"Won" if String(result.get("winner", "")) == "player" else "Lost",
			int(result.get("turn", 0)),
			int(result.get("player", {}).get("life", 0)),
			int(result.get("opponent", {}).get("life", 0)),
			seed_value
		])
		game_number += 1

	return {
		"won": player_game_wins > opponent_game_wins,
		"player_game_wins": player_game_wins,
		"opponent_game_wins": opponent_game_wins,
		"display_probability": _estimate_match_probability(opponent, deck_metrics),
		"game_summaries": game_summaries
	}


func _estimate_match_probability(opponent: Dictionary, deck_metrics: Dictionary) -> float:
	var player_score := float(deck_metrics.score)
	player_score += _matchup_tech_bonus(opponent.tags)
	player_score += rng.randf_range(-2.0, 2.0)

	var opponent_score := float(opponent.quality)
	var matchup_mod := 0.0
	var player_archetype: Dictionary = archetypes_by_id[deck_metrics.primary]
	if player_archetype.get("matchups", {}).has(opponent.archetype):
		matchup_mod = float(player_archetype.matchups[opponent.archetype])

	var base_probability: float = clamp(0.5 + ((player_score - opponent_score) * 0.018) + matchup_mod, 0.08, 0.92)
	return base_probability


func _matchup_tech_bonus(target_tags: Array) -> float:
	var bonus := 0.0
	for deck_source in [run.deck, run.sideboard]:
		var side_multiplier := 1.4 if deck_source == run.sideboard else 1.0
		for card_id in deck_source.keys():
			var card: Dictionary = cards_by_id[card_id]
			for modifier in card.get("matchupModifiers", []):
				if target_tags.has(modifier.get("target", "")):
					bonus += float(modifier.get("value", 0)) * int(deck_source[card_id]) * side_multiplier
	return min(bonus, 8.0)


func _update_meta_after_event(primary: String, wins: int, rounds: int) -> void:
	var performance := (float(wins) / float(rounds)) - 0.5
	run.meta[primary] = float(run.meta.get(primary, 0.5)) + performance * 0.10

	var dominant: String = _dominant_archetype()
	var predator: String = _predator_archetype(dominant)
	if float(run.meta.get(dominant, 0.0)) > 0.42:
		run.meta[predator] = float(run.meta.get(predator, 0.0)) + 0.04

	for archetype_id in ARCHETYPE_ORDER:
		run.meta[archetype_id] = max(0.12, float(run.meta.get(archetype_id, 0.0)) + rng.randf_range(-0.015, 0.015))

	_normalize_meta()

	var reports: Array = []
	var leader: String = _dominant_archetype()
	reports.append("%s is the deck people are talking about this week." % archetypes_by_id[leader].name)
	match leader:
		"flightless_birds":
			reports.append("Snake pilots are buying time and sweepers for the bird rush.")
		"snake":
			reports.append("Oxen players are trying to ramp past one-for-one answers.")
		"oxen":
			reports.append("Bird pilots are cutting clunky cards and trying to finish before the pasture turns on.")
		"glires":
			reports.append("Insect pilots are leaning on revive loops to outlast the warren.")
		"insect":
			reports.append("Bird pilots are cutting clunky cards and trying to finish before the hive turns on.")

	if wins == rounds:
		reports.append("Your undefeated run is getting noticed. Expect sharper sideboards next week.")
	elif wins == 0:
		reports.append("The room is not adapting to you yet. That can be useful.")
	else:
		reports.append("The meta shifts a little, but nobody agrees on the best deck yet.")

	run.reports = reports


func _normalize_meta() -> void:
	run_state_service.normalize_meta(run)


func _dominant_archetype() -> String:
	return run_state_service.dominant_archetype(run)


func _show_meta() -> void:
	if _guard_run_over():
		return
	current_screen = "meta"
	_render_nav()
	_clear(content)
	_update_status()

	var panel := _add_panel(content, "Metagame Board")
	_add_body_text(panel, "The metagame changes after each tournament. Reports are intentionally partial, like real shop talk.")

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var share := float(run.meta.get(archetype_id, 0.0))
		var line := "%s: %d%% of expected locals field. %s" % [archetype.name, int(round(share * 100.0)), archetype.summary]
		_add_body_text(panel, line)

	var report_panel := _add_panel(content, "Reports")
	for line in run.reports:
		_add_body_text(report_panel, "• " + line)


func _calculate_deck_metrics(deck: Dictionary, sideboard: Dictionary) -> Dictionary:
	return deck_metrics_service.calculate(deck, sideboard)


func _deck_is_legal() -> Dictionary:
	return run_state_service.deck_is_legal(run)


func _format_metrics(metrics: Dictionary) -> String:
	return "Primary: %s | Fit: %d%% | Score: %.1f\nSpeed %.1f | Power %.1f | Interaction %.1f | Resilience %.1f | Advantage %.1f | Consistency %.1f\nRole balance: %d%% | %s" % [
		archetypes_by_id[metrics.primary].name,
		int(round(float(metrics.fit) * 100.0)),
		float(metrics.score),
		float(metrics.speed),
		float(metrics.power),
		float(metrics.interaction),
		float(metrics.resilience),
		float(metrics.advantage),
		float(metrics.consistency),
		int(round(float(metrics.role_score) * 100.0)),
		metrics.curve_warning
	]


func _format_metrics_short(metrics: Dictionary) -> String:
	return "Starter score %.1f | Fit %d%% | %s" % [
		float(metrics.score),
		int(round(float(metrics.fit) * 100.0)),
		metrics.curve_warning
	]


func _owned_count(card_id: String) -> int:
	return run_state_service.owned_count(run, card_id)


func _deck_count(card_id: String) -> int:
	return run_state_service.deck_count(run, card_id)


func _sideboard_count(card_id: String) -> int:
	return run_state_service.sideboard_count(run, card_id)


func _available_count(card_id: String) -> int:
	return run_state_service.available_count(run, card_id)


func _deck_limit(card_id: String) -> int:
	return run_state_service.deck_limit(card_id)


func _deck_total(deck: Dictionary) -> int:
	return run_state_service.deck_total(deck)


func _add_to_collection(card_id: String, count: int) -> void:
	run_state_service.add_to_collection(run, card_id, count)


func _add_panel(parent: Node, title: String, accent: String = "#202734") -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent)
	style.border_color = Color("#3a4352")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8 if compact_duel else 12)
	margin.add_theme_constant_override("margin_right", 8 if compact_duel else 12)
	margin.add_theme_constant_override("margin_top", 6 if compact_duel else 10)
	margin.add_theme_constant_override("margin_bottom", 6 if compact_duel else 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4 if compact_duel else 6)
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title
		label.add_theme_font_size_override("font_size", 14 if compact_duel else 18)
		label.add_theme_color_override("font_color", Color("#f3efe4"))
		box.add_child(label)

	return box


func _add_card_panel(parent: Node, card_id: String, note: String = "") -> VBoxContainer:
	var card: Dictionary = cards_by_id[card_id]
	var accent := "#2d3442"
	match card.get("rarity", "common"):
		"common":
			accent = "#29313b"
		"uncommon":
			accent = "#243b36"
		"rare":
			accent = "#433823"
		"mythic":
			accent = "#472637"

	var box := _add_panel(parent, card.name, accent)
	box.custom_minimum_size = Vector2(240, 0)

	var meta := "%s | %s | %s | cost %d | $%d" % [
		card.rarity.capitalize(),
		_affinity_label(_card_animal_type(card)),
		card.role.capitalize(),
		int(card.cost),
		_card_price(card_id) if not run.is_empty() else int(card.value)
	]
	_add_body_text(box, meta)
	if note != "":
		var note_label := Label.new()
		note_label.text = note
		note_label.add_theme_color_override("font_color", Color("#ffe08a"))
		box.add_child(note_label)
	return box


func _archetype_label(archetype_id: String) -> String:
	if archetypes_by_id.has(archetype_id):
		return archetypes_by_id[archetype_id].name
	return "Neutral"


func _card_animal_type(card: Dictionary) -> String:
	return String(card.get("animalType", card.get("archetype", "neutral")))


func _unit_animal_type(unit: Dictionary) -> String:
	var card_id := String(unit.get("card_id", ""))
	if cards_by_id.has(card_id):
		return _card_animal_type(cards_by_id[card_id])
	var tags: Array = unit.get("tags", [])
	for archetype_id in ARCHETYPE_ORDER:
		if tags.has(archetype_id):
			return String(archetype_id)
	return "neutral"


func _combat_card_type_line(card: Dictionary) -> String:
	var animal := _affinity_label(_card_animal_type(card))
	var printed_role := String(card.get("role", _combat_card_type(card))).capitalize()
	match String(card.get("role", "")):
		"threat":
			printed_role = "Threat"
		"answer":
			printed_role = "Answer"
		"filter":
			printed_role = "Filter"
		"engine":
			printed_role = "Engine"
		"finisher":
			printed_role = "Finisher"
		"tech":
			printed_role = "Tech"
	return "%s | %s" % [animal, printed_role]


func _unit_card_type_line(unit: Dictionary) -> String:
	var animal_type := _unit_animal_type(unit)
	return "%s | Threat" % _affinity_label(animal_type)


func _style_card_type_strip(panel: PanelContainer, animal_type: String, compact_duel: bool) -> void:
	var color := _affinity_color(animal_type)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#121a24")
	style.bg_color.a = 0.78 if compact_duel else 0.86
	style.border_color = color.lightened(0.35)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)


func _affinity_label(archetype_id: String) -> String:
	match archetype_id:
		"flightless_birds":
			return "Flightless Birds"
		"snake":
			return "Snake"
		"oxen":
			return "Oxen"
		"glires":
			return "Glires"
		"insect":
			return "Insect"
		"neutral":
			return "Universal"
		_:
			return _archetype_label(archetype_id)


func _affinity_color(archetype_id: String) -> Color:
	match archetype_id:
		"flightless_birds":
			return Color("#e45a3c")
		"snake":
			return Color("#4cc9b0")
		"oxen":
			return Color("#8f9b4a")
		"glires":
			return Color("#d8a74b")
		"insect":
			return Color("#9b7bd5")
		"neutral":
			return Color("#c7d0df")
		_:
			return Color("#ffe08a")


func _rarity_line_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#232b35")
		"uncommon":
			return Color("#1f3530")
		"rare":
			return Color("#3d321f")
		"mythic":
			return Color("#442334")
		_:
			return Color("#232b35")


func _rarity_text_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#d8dfec")
		"uncommon":
			return Color("#96e6c8")
		"rare":
			return Color("#ffd37a")
		"mythic":
			return Color("#ff9fc2")
		_:
			return Color("#d8dfec")


func _add_body_text(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if current_screen == "ui_combat":
		label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#d8dfec"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 30)
	_style_button(button, "default")
	return button


func _compact_manual_card_button(button: Button) -> void:
	if current_screen != "ui_combat":
		return
	button.custom_minimum_size = Vector2(0, 22)
	button.add_theme_font_size_override("font_size", 10)


func _style_button(button: Button, variant: String = "default") -> void:
	var normal_color := Color("#2f3947")
	var hover_color := Color("#3d4a5b")
	var pressed_color := Color("#232b35")
	var border_color := Color("#5d6a7a")
	var text_color := Color("#eef3ff")

	match variant:
		"target":
			normal_color = Color("#24482c")
			hover_color = Color("#2f633a")
			pressed_color = Color("#1b3521")
			border_color = Color("#9ee66e")
			text_color = Color("#f1ffe8")
		"selected":
			normal_color = Color("#4a3b1b")
			hover_color = Color("#604e24")
			pressed_color = Color("#332914")
			border_color = Color("#ffe08a")
			text_color = Color("#fff4c2")
		"action":
			normal_color = Color("#273c58")
			hover_color = Color("#345174")
			pressed_color = Color("#1f3046")
			border_color = Color("#7fb8ff")
			text_color = Color("#eef7ff")
		"danger":
			normal_color = Color("#4a2727")
			hover_color = Color("#613333")
			pressed_color = Color("#331c1c")
			border_color = Color("#d8a0a0")
			text_color = Color("#ffe1df")

	button.add_theme_stylebox_override("normal", _button_stylebox(normal_color, border_color))
	button.add_theme_stylebox_override("hover", _button_stylebox(hover_color, border_color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_stylebox(pressed_color, border_color))
	button.add_theme_stylebox_override("disabled", _button_stylebox(Color("#242a33"), Color("#3a4352")))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("#7e8794"))


func _button_stylebox(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _update_status() -> void:
	if run.is_empty():
		status_label.text = "Prototype"
		return
	var main_count := _deck_total(run.deck)
	var side_count := _deck_total(run.sideboard)
	status_label.text = "Week %d | $%d | Main %d/%d | Side %d/%d" % [
		int(run.week),
		int(run.money),
		main_count,
		MAIN_DECK_SIZE,
		side_count,
		SIDEBOARD_SIZE
	]


func _set_footer(text: String) -> void:
	if footer_label == null:
		return
	footer_label.text = "[color=#c7d0df]" + text + "[/color]"


func _guard_run_over() -> bool:
	if run.is_empty():
		_show_start()
		return true
	if bool(run.get("run_over", false)):
		_show_tournament_result(run.get("last_result", ["The run is over."]), false)
		return true
	return false


func _save_run() -> void:
	var result: Dictionary = run_state_service.save_run(run)
	_set_footer(result.message)


func _load_run_from_disk() -> void:
	_manual_clear_hand_card_drag()
	var result: Dictionary = run_state_service.load_run()
	if not result.ok:
		_set_footer(result.message)
		return
	run = result.run
	if not run.has("combat_lab_opponent"):
		var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
		run.combat_lab_opponent = _predator_archetype(String(metrics.primary))
	_generate_shop_inventory()
	_set_footer(result.message)
	_show_shop()


func _migrate_legacy_run_archetypes() -> void:
	run_state_service.migrate_legacy_run_archetypes(run)
