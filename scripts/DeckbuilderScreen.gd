extends RefCounted
class_name DeckbuilderScreen

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"

const COLLECTION_COLUMNS := 4
const DECK_COLUMNS := 3
const COLLECTION_CARD_SIZE := Vector2(150, 213)
const DECK_CARD_SIZE := Vector2(92, 131)
const HOVER_CARD_SIZE := Vector2(300, 426)
const HOVER_PREVIEW_SIZE := Vector2(326, 466)
const HOVER_DELAY_SECONDS := 0.38
const SURFACE := WORKSPACE_UI.SURFACE
const SURFACE_WARM := WORKSPACE_UI.SURFACE_WARM
const BORDER_SOFT := WORKSPACE_UI.BORDER_SOFT
const WORKSHOP_CREAM := PALETTE.CREAM
const COLLECTION_LAVENDER := Color("#F3EFFA")
const DECK_BLUSH := Color("#FBE5EC")
const CARD_PAPER := Color("#FFF9F5")

var _hover_preview: PanelContainer
var _hover_preview_body: CenterContainer
var _hover_request_id := 0


func show(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "deck"
	host._render_nav()
	host._clear(host.content)
	host._update_status()
	_remove_hover_preview(host)

	var metrics: Dictionary = host._calculate_deck_metrics(host.run.deck, host.run.sideboard)
	var legal: Dictionary = host._deck_is_legal()
	var collection_ids: Array = _sorted_card_ids(host, host.run.collection.keys(), metrics.primary)
	var compact_workspace: bool = host._run_mode() == "season"

	_add_header(host, metrics, legal)

	var workspace := HBoxContainer.new()
	workspace.name = "DeckbuilderWorkspace"
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.custom_minimum_size = Vector2(0, 560 if compact_workspace else 600)
	workspace.add_theme_constant_override("separation", 16)
	host.content.add_child(workspace)

	_add_collection_binder(host, workspace, collection_ids, compact_workspace)
	_add_deck_rail(host, workspace, compact_workspace)
	_create_hover_preview(host)

	if host._run_mode() == "season":
		var back_button: Button = host._add_deckbuilder_back_button(host.content)
		_style_deck_button(back_button)


func _add_header(host, metrics: Dictionary, legal: Dictionary) -> void:
	var header: VBoxContainer = _add_clean_panel(
		host.content,
		"DECK WORKSHOP",
		PALETTE.CORAL,
		Vector2(0, 82)
	)
	header.name = "DeckbuilderHeader"

	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_theme_constant_override("separation", 10)
	header.add_child(toolbar)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 2)
	toolbar.add_child(identity)

	var collection_label := Label.new()
	collection_label.name = "DeckbuilderCollectionSummary"
	collection_label.text = "COLLECTION  •  %d unique cards" % host.run.collection.size()
	collection_label.add_theme_font_size_override("font_size", 13)
	collection_label.add_theme_color_override("font_color", PALETTE.NAVY)
	identity.add_child(collection_label)

	var metrics_label := Label.new()
	metrics_label.name = "DeckbuilderMetricsSummary"
	metrics_label.text = host._format_metrics_short(metrics)
	metrics_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	metrics_label.add_theme_font_size_override("font_size", 13)
	metrics_label.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(metrics_label)

	var legality := _add_badge(
		toolbar,
		"✓  EVENT LEGAL" if bool(legal.ok) else "!  " + String(legal.reason).to_upper(),
		PALETTE.SKY.lightened(0.42) if bool(legal.ok) else PALETTE.BLUSH.lightened(0.30),
		PALETTE.NAVY if bool(legal.ok) else PALETTE.BRICK_DARK
	)
	legality.name = "DeckbuilderLegalityBadge"

	_add_sort_controls(host, toolbar)


func _add_collection_binder(host, workspace: HBoxContainer, collection_ids: Array, compact_workspace: bool) -> void:
	var collection_panel := _add_workspace_panel(
		host,
		workspace,
		"CARD COLLECTION",
		COLLECTION_LAVENDER,
		PALETTE.PERIWINKLE
	)
	collection_panel.name = "DeckbuilderCollectionPanel"
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_panel.custom_minimum_size = Vector2(770 if compact_workspace else 700, 0)

	var hint := Label.new()
	hint.text = "Hover to inspect  •  Add owned copies to your deck"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	collection_panel.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.name = "DeckbuilderCollectionScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	collection_panel.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "DeckbuilderCollectionGrid"
	grid.columns = COLLECTION_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	if collection_ids.is_empty():
		host._add_body_text(grid, "Your collection is empty.")
		return

	for card_id_value in collection_ids:
		var card_id := String(card_id_value)
		_add_collection_card(host, grid, card_id, compact_workspace)


func _add_collection_card(host, parent: GridContainer, card_id: String, compact_workspace: bool) -> void:
	var card: Dictionary = host.cards_by_id[card_id]
	var owned: int = host._owned_count(card_id)
	var available: int = host._available_count(card_id)
	var tile := _add_card_tile(host, parent, card_id, card, "DeckbuilderCollectionCard")
	tile.custom_minimum_size = Vector2(176, 269 if compact_workspace else 305)

	var art_center := CenterContainer.new()
	art_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_child(art_center)
	art_center.add_child(_make_visual_card(host, card, COLLECTION_CARD_SIZE))

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 5)
	tile.add_child(info_row)

	var owned_badge := _add_badge(
		info_row,
		"OWNED ×%d" % owned,
		PALETTE.LAVENDER_GLASS,
		PALETTE.NAVY
	)
	owned_badge.name = "DeckbuilderOwnedBadge"

	var available_label := Label.new()
	available_label.text = "%d free" % available
	available_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	available_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	available_label.add_theme_font_size_override("font_size", 12)
	available_label.add_theme_color_override("font_color", PALETTE.NAVY if available > 0 else Color("#85829A"))
	info_row.add_child(available_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	tile.add_child(actions)

	var add_main: Button = host._make_button("+  MAIN DECK")
	add_main.name = "DeckbuilderAddMainButton"
	add_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_main.disabled = (
		available <= 0
		or host._deck_total(host.run.deck) >= host.run_state_service.max_main_deck_size
		or host._deck_count(card_id) >= host._deck_limit(card_id)
	)
	host._style_button(add_main, "action")
	_style_deck_button(add_main, "primary")
	var main_id := card_id
	host._connect_pressed(add_main, func() -> void: host._add_to_deck(main_id))
	actions.add_child(add_main)

	if not compact_workspace:
		var add_side: Button = host._make_button("+ SIDE")
		add_side.name = "DeckbuilderAddSideButton"
		add_side.disabled = (
			available <= 0
			or host._deck_total(host.run.sideboard) >= host.run_state_service.sideboard_size
			or host._sideboard_count(card_id) >= host._deck_limit(card_id)
		)
		var side_id := card_id
		_style_deck_button(add_side)
		host._connect_pressed(add_side, func() -> void: host._add_to_sideboard(side_id))
		actions.add_child(add_side)

	_bind_card_hover(host, tile, card_id)


func _add_deck_rail(host, workspace: HBoxContainer, compact_workspace: bool) -> void:
	var rail := _add_workspace_panel(host, workspace, "MY DECKS", DECK_BLUSH, PALETTE.CORAL)
	rail.name = "DeckbuilderDeckRail"
	rail.custom_minimum_size = Vector2(380 if compact_workspace else 364, 0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if compact_workspace:
		var deck_panel := _add_deck_tab(
			host,
			rail,
			"Main Deck  %d/%d" % [host._deck_total(host.run.deck), host.run_state_service.max_main_deck_size],
			"DeckbuilderMainDeckPanel"
		)
		_add_deck_grid(host, deck_panel, host.run.deck, true, "DeckbuilderMainDeckScroll")
		return

	var tabs := TabContainer.new()
	tabs.name = "DeckbuilderDeckTabs"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel", _clean_style(SURFACE, BORDER_SOFT, 1, 7, Vector4(8, 8, 8, 8)))
	rail.add_child(tabs)

	var main_panel := _add_deck_tab(
		host,
		tabs,
		"Main %d/%d" % [host._deck_total(host.run.deck), host.run_state_service.max_main_deck_size],
		"DeckbuilderMainDeckPanel"
	)
	_add_deck_grid(host, main_panel, host.run.deck, true, "DeckbuilderMainDeckScroll")

	var side_panel := _add_deck_tab(
		host,
		tabs,
		"Sideboard %d/%d" % [host._deck_total(host.run.sideboard), host.run_state_service.sideboard_size],
		"DeckbuilderSideboardPanel"
	)
	_add_deck_grid(host, side_panel, host.run.sideboard, false, "DeckbuilderSideboardScroll")


func _add_deck_tab(host, parent: Node, title: String, node_name: String) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.name = node_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 7)
	parent.add_child(panel)

	if parent is not TabContainer:
		var title_label := Label.new()
		title_label.text = title.to_upper()
		title_label.add_theme_font_override("font", SKETCH_UI.display_font(0.68))
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", SKETCH_UI.INK)
		panel.add_child(title_label)
	else:
		(parent as TabContainer).set_tab_title((parent as TabContainer).get_tab_count() - 1, title)

	var hint := Label.new()
	hint.text = "Hover to inspect  •  Remove with −"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	panel.add_child(hint)
	return panel


func _add_deck_grid(host, parent: VBoxContainer, deck: Dictionary, is_main: bool, scroll_name: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = scroll_name + "Grid"
	grid.columns = DECK_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 7)
	scroll.add_child(grid)

	var metrics: Dictionary = host._calculate_deck_metrics(host.run.deck, host.run.sideboard)
	var ids: Array = _sorted_card_ids(host, deck.keys(), metrics.primary)
	if ids.is_empty():
		host._add_body_text(grid, "No cards yet.")
		return

	for card_id_value in ids:
		var card_id := String(card_id_value)
		var card: Dictionary = host.cards_by_id[card_id]
		var tile := _add_card_tile(host, grid, card_id, card, "DeckbuilderDeckCard")
		tile.custom_minimum_size = Vector2(108, 181)

		var art_center := CenterContainer.new()
		art_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_child(art_center)
		art_center.add_child(_make_visual_card(host, card, DECK_CARD_SIZE))

		var controls := HBoxContainer.new()
		controls.add_theme_constant_override("separation", 3)
		tile.add_child(controls)

		var count := Label.new()
		count.text = "×%d" % int(deck[card_id])
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count.add_theme_font_size_override("font_size", 15)
		count.add_theme_color_override("font_color", PALETTE.NAVY)
		controls.add_child(count)

		var remove: Button = host._make_button("−")
		remove.name = "DeckbuilderRemoveMainButton" if is_main else "DeckbuilderRemoveSideButton"
		remove.custom_minimum_size = Vector2(32, 28)
		_style_deck_button(remove, "icon")
		var selected_id := card_id
		if is_main:
			host._connect_pressed(remove, func() -> void: host._remove_from_deck(selected_id))
		else:
			host._connect_pressed(remove, func() -> void: host._remove_from_sideboard(selected_id))
		controls.add_child(remove)

		_bind_card_hover(host, tile, card_id)


func _add_workspace_panel(host, parent: Node, title: String, background: Color, accent: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_clean_style(background, PALETTE.NAVY, 2, 14, Vector4.ZERO, 0, true)
	)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_override("font", SKETCH_UI.body_font(0.5))
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", PALETTE.NAVY)
	box.add_child(title_label)
	var accent_rule := ColorRect.new()
	accent_rule.custom_minimum_size = Vector2(0, 3)
	accent_rule.color = accent
	accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(accent_rule)
	return box


func _add_card_tile(host, parent: Node, card_id: String, card: Dictionary, node_name: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.set_meta("card_id", card_id)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tile_fill := CARD_PAPER.lerp(
		host._rarity_line_color(card.get("rarity", "common")),
		0.035
	)
	panel.add_theme_stylebox_override(
		"panel",
		_clean_style(
			tile_fill,
			PALETTE.NAVY,
			2,
			11,
			Vector4.ZERO,
			0,
			true
		)
	)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var tile := VBoxContainer.new()
	tile.name = node_name + "Body"
	tile.set_meta("card_id", card_id)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_constant_override("separation", 5)
	margin.add_child(tile)
	return tile


func _make_visual_card(host, card: Dictionary, size: Vector2) -> Control:
	if host._card_uses_authored_face(card):
		return host._make_card_face(card, size, true)

	var fallback := PanelContainer.new()
	fallback.custom_minimum_size = size
	var fallback_style := StyleBoxFlat.new()
	fallback_style.bg_color = PALETTE.INK
	fallback_style.border_color = host._affinity_color(host._card_archetype(card))
	fallback_style.set_border_width_all(2)
	fallback_style.set_corner_radius_all(8)
	fallback.add_theme_stylebox_override("panel", fallback_style)
	var title := Label.new()
	title.text = host._card_display_name(card)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", PALETTE.GHOST)
	fallback.add_child(title)
	return fallback


func _add_badge(parent: Node, text: String, background: Color, foreground: Color) -> PanelContainer:
	var badge := WORKSPACE_UI.make_badge(text, background, foreground)
	parent.add_child(badge)
	return badge


func _create_hover_preview(host) -> void:
	_hover_preview = PanelContainer.new()
	_hover_preview.name = "DeckbuilderHoverPreview"
	_hover_preview.custom_minimum_size = HOVER_PREVIEW_SIZE
	_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_preview.z_index = 1800
	_hover_preview.visible = false

	_hover_preview.add_theme_stylebox_override(
		"panel",
		_clean_style(WORKSHOP_CREAM, PALETTE.NAVY, 3, 16, Vector4(12, 12, 12, 12), 0, true)
	)
	host.add_child(_hover_preview)

	_hover_preview_body = CenterContainer.new()
	_hover_preview_body.name = "DeckbuilderHoverPreviewBody"
	_hover_preview_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_preview.add_child(_hover_preview_body)


func _remove_hover_preview(host) -> void:
	_hover_request_id += 1
	var existing: Node = host.find_child("DeckbuilderHoverPreview", true, false)
	if existing != null:
		existing.free()
	_hover_preview = null
	_hover_preview_body = null


func _bind_card_hover(host, control: Control, card_id: String) -> void:
	control.mouse_entered.connect(func() -> void: _queue_hover_preview(host, control, card_id))
	control.mouse_exited.connect(_hide_hover_preview)


func _queue_hover_preview(host, source: Control, card_id: String) -> void:
	_hover_request_id += 1
	var request_id := _hover_request_id
	await host.get_tree().create_timer(HOVER_DELAY_SECONDS).timeout
	if (
		request_id != _hover_request_id
		or not is_instance_valid(source)
		or not source.get_global_rect().has_point(host.get_viewport().get_mouse_position())
	):
		return
	_show_hover_preview(host, source, card_id)


func _show_hover_preview(host, source: Control, card_id: String) -> void:
	if (
		_hover_preview == null
		or not is_instance_valid(_hover_preview)
		or _hover_preview_body == null
		or not host.cards_by_id.has(card_id)
	):
		return

	for child in _hover_preview_body.get_children():
		child.free()
	var card: Dictionary = host.cards_by_id[card_id]
	var known_keywords: Array[String] = []
	for keyword_value in card.get("keywords", []):
		var keyword_id := String(keyword_value)
		if host.KEYWORD_TOOLTIPS.has(keyword_id):
			known_keywords.append(keyword_id)
	var preview_width := HOVER_PREVIEW_SIZE.x if known_keywords.is_empty() else 594.0
	_hover_preview.custom_minimum_size = Vector2(preview_width, HOVER_PREVIEW_SIZE.y)

	var preview_row := HBoxContainer.new()
	preview_row.name = "DeckbuilderHoverPreviewContent"
	preview_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_row.add_theme_constant_override("separation", 12)
	_hover_preview_body.add_child(preview_row)
	preview_row.add_child(_make_visual_card(host, card, HOVER_CARD_SIZE))
	if not known_keywords.is_empty():
		var glossary := VBoxContainer.new()
		glossary.name = "DeckbuilderKeywordGlossary"
		glossary.custom_minimum_size = Vector2(244, 0)
		glossary.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glossary.add_theme_constant_override("separation", 9)
		preview_row.add_child(glossary)
		var heading := Label.new()
		heading.text = "KEYWORD GUIDE"
		heading.add_theme_font_override("font", SKETCH_UI.display_font(0.68))
		heading.add_theme_font_size_override("font_size", 12)
		heading.add_theme_color_override("font_color", PALETTE.NAVY)
		glossary.add_child(heading)
		for keyword_id in known_keywords:
			host._add_keyword_explanation(glossary, keyword_id, "DeckbuilderKeyword")
	_hover_preview.visible = true

	var source_rect := source.get_global_rect()
	var viewport_size: Vector2 = host.get_viewport_rect().size
	var preview_position := Vector2(source_rect.end.x + 14.0, source_rect.position.y - 78.0)
	if preview_position.x + preview_width > viewport_size.x - 12.0:
		preview_position.x = source_rect.position.x - preview_width - 14.0
	preview_position.x = clampf(preview_position.x, 12.0, maxf(12.0, viewport_size.x - preview_width - 12.0))
	preview_position.y = clampf(preview_position.y, 12.0, maxf(12.0, viewport_size.y - HOVER_PREVIEW_SIZE.y - 12.0))
	_hover_preview.global_position = preview_position


func _hide_hover_preview() -> void:
	_hover_request_id += 1
	if _hover_preview != null and is_instance_valid(_hover_preview):
		_hover_preview.visible = false


func _add_sort_controls(host, parent: HBoxContainer) -> void:
	var sort_label := Label.new()
	sort_label.text = "SORT"
	sort_label.add_theme_font_size_override("font_size", 12)
	sort_label.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	parent.add_child(sort_label)

	_add_sort_button(host, parent, "Affinity", SORT_AFFINITY)
	_add_sort_button(host, parent, "Rarity", SORT_RARITY)
	_add_sort_button(host, parent, "Name", SORT_NAME)


func _add_sort_button(host, parent: HBoxContainer, label: String, mode: String) -> void:
	var selected: bool = host.deckbuilder_sort_mode == mode
	var button: Button = host._make_button(("✓ " if selected else "") + label)
	button.name = "DeckbuilderSort" + mode.capitalize()
	button.custom_minimum_size = Vector2(84, 36)
	button.disabled = selected
	_style_deck_button(button, "selected" if selected else "secondary")
	host._connect_pressed(button, func() -> void: _set_sort_mode(host, mode))
	parent.add_child(button)


func _add_clean_panel(
	parent: Node,
	title: String,
	accent: Color,
	minimum_size: Vector2 = Vector2.ZERO
) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_clean_style(WORKSHOP_CREAM, PALETTE.NAVY, 2, 14, Vector4.ZERO, 0, true)
	)
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	margin.add_child(body)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_override("font", SKETCH_UI.body_font(0.62))
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", PALETTE.NAVY)
	body.add_child(heading)
	var accent_rule := ColorRect.new()
	accent_rule.custom_minimum_size = Vector2(116, 3)
	accent_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	accent_rule.color = accent
	accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(accent_rule)
	return body


func _style_deck_button(button: Button, variant: String = "secondary") -> void:
	WORKSPACE_UI.style_button(button, variant)


func _clean_style(
	background: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 7,
	content_margins: Vector4 = Vector4.ZERO,
	accent_width: int = 0,
	with_shadow: bool = false
) -> StyleBoxFlat:
	return WORKSPACE_UI.clean_style(
		background,
		border,
		border_width,
		radius,
		content_margins,
		accent_width,
		with_shadow
	)


func _set_sort_mode(host, mode: String) -> void:
	host.deckbuilder_sort_mode = mode
	host._set_footer("Deckbuilder sorted by " + mode + ".")
	show(host)


func _sorted_card_ids(host, ids: Array, primary_archetype: String) -> Array:
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort_custom(func(a, b) -> bool: return _card_id_comes_before(host, String(a), String(b), primary_archetype))
	return sorted_ids


func _card_id_comes_before(host, a: String, b: String, primary_archetype: String) -> bool:
	var card_a: Dictionary = host.cards_by_id[a]
	var card_b: Dictionary = host.cards_by_id[b]

	match host.deckbuilder_sort_mode:
		SORT_RARITY:
			var rarity_a: int = host._rarity_rank(card_a.get("rarity", "common"))
			var rarity_b: int = host._rarity_rank(card_b.get("rarity", "common"))
			if rarity_a != rarity_b:
				return rarity_a > rarity_b
		SORT_AFFINITY:
			var affinity_a := _affinity_rank(card_a.get("archetype", "neutral"), primary_archetype)
			var affinity_b := _affinity_rank(card_b.get("archetype", "neutral"), primary_archetype)
			if affinity_a != affinity_b:
				return affinity_a < affinity_b
			var rarity_a: int = host._rarity_rank(card_a.get("rarity", "common"))
			var rarity_b: int = host._rarity_rank(card_b.get("rarity", "common"))
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
