extends RefCounted
class_name DeckbuilderScreen

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const MATERIAL_SYMBOLS := preload("res://scripts/ui/MaterialSymbolsSharp.gd")
const ANGULAR_SURFACE_SCRIPT := preload("res://scripts/ui/BattleAngularSurface.gd")
const ANGULAR_BUTTON_FACE_SCRIPT := preload("res://scripts/ui/BattleAngularButtonFace.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"

const COLLECTION_COLUMNS := 4
const DECK_COLUMNS := 8
const COLLECTION_CARD_SIZE := Vector2(150, 213)
const DECK_CARD_SIZE := Vector2(136, 194)
const HOVER_CARD_SIZE := Vector2(300, 426)
const HOVER_PREVIEW_SIZE := Vector2(326, 466)
const HOVER_DELAY_SECONDS := 0.38
const WORKSHOP_SURFACE := PALETTE.CARBON
const WORKSHOP_PANEL := PALETTE.SURFACE_PAPER_MUTED
const WORKSHOP_TILE := PALETTE.SURFACE_PAPER

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

	var workshop_shell := PanelContainer.new()
	workshop_shell.name = "DeckbuilderWorkshopShell"
	workshop_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workshop_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	host.content.add_child(workshop_shell)
	_apply_angular_surface(workshop_shell, PALETTE.CARBON.darkened(0.10), PALETTE.STEEL, true)
	var shell_margin := MarginContainer.new()
	shell_margin.add_theme_constant_override("margin_left", 10)
	shell_margin.add_theme_constant_override("margin_right", 10)
	shell_margin.add_theme_constant_override("margin_top", 10)
	shell_margin.add_theme_constant_override("margin_bottom", 10)
	workshop_shell.add_child(shell_margin)
	var workshop_content := VBoxContainer.new()
	workshop_content.name = "DeckbuilderWorkshopContent"
	workshop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workshop_content.add_theme_constant_override("separation", 10)
	shell_margin.add_child(workshop_content)

	_add_back_bar(host, workshop_content)

	var workspace := VBoxContainer.new()
	workspace.name = "DeckbuilderWorkspace"
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.custom_minimum_size = Vector2(0, 600)
	workshop_content.add_child(workspace)

	_add_deck_rail(host, workspace)
	_create_hover_preview(host)


func _add_back_bar(host, parent: Node) -> void:
	var bar := PanelContainer.new()
	bar.name = "DeckbuilderTopBar"
	bar.custom_minimum_size = Vector2(0, 48)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(bar)
	_apply_angular_surface(bar, WORKSHOP_SURFACE, PALETTE.ELECTRIC_CYAN, true)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)
	var back_button: Button = host._add_deckbuilder_back_button(row)
	back_button.custom_minimum_size = Vector2(112, 36)
	_style_deck_button(back_button, "secondary")
	MATERIAL_SYMBOLS.apply_to_button(back_button, "back", 18)


func _add_collection_binder(host, workspace: HBoxContainer, collection_ids: Array, compact_workspace: bool) -> void:
	var collection_panel := _add_workspace_panel(
		host,
		workspace,
		"CARD COLLECTION",
		WORKSHOP_PANEL,
		PALETTE.ELECTRIC_CYAN
	)
	collection_panel.name = "DeckbuilderCollectionPanel"
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_panel.custom_minimum_size = Vector2(770 if compact_workspace else 700, 0)

	var hint := Label.new()
	hint.text = "Hover to inspect  •  Add owned copies to your deck"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", PALETTE.TEXT_ON_LIGHT_SECONDARY)
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
	var card: Dictionary = _route_display_card(host, card_id, host.cards_by_id[card_id])
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
		PALETTE.STEEL.darkened(0.12),
		PALETTE.COOL_WHITE
	)
	owned_badge.name = "DeckbuilderOwnedBadge"

	var available_label := Label.new()
	available_label.text = "%d free" % available
	available_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	available_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	available_label.add_theme_font_size_override("font_size", 12)
	available_label.add_theme_color_override("font_color", PALETTE.EMERALD.darkened(0.30) if available > 0 else Color(PALETTE.TEXT_ON_LIGHT, 0.48))
	info_row.add_child(available_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	tile.add_child(actions)
	if String(host.run.get("run_loop", "")) == "route":
		var route_note := Label.new()
		route_note.text = "Added through route rewards"
		route_note.add_theme_font_size_override("font_size", 11)
		route_note.add_theme_color_override("font_color", PALETTE.TEXT_ON_LIGHT_SECONDARY)
		actions.add_child(route_note)
		_bind_card_hover(host, tile, card_id)
		return

	var add_main: Button = host._make_button("+  MAIN DECK")
	add_main.name = "DeckbuilderAddMainButton"
	add_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_main.disabled = (
		available <= 0
	)
	host._style_button(add_main, "action")
	_style_deck_button(add_main, "primary")
	MATERIAL_SYMBOLS.apply_to_button(add_main, "add", 17)
	var main_id := card_id
	host._connect_pressed(add_main, func() -> void: host._add_to_deck(main_id))
	actions.add_child(add_main)

	if not compact_workspace:
		var add_side: Button = host._make_button("+ SIDE")
		add_side.name = "DeckbuilderAddSideButton"
		add_side.disabled = (
			available <= 0
			or host._deck_total(host.run.sideboard) >= host.run_state_service.sideboard_size
		)
		var side_id := card_id
		_style_deck_button(add_side)
		MATERIAL_SYMBOLS.apply_to_button(add_side, "add", 17)
		host._connect_pressed(add_side, func() -> void: host._add_to_sideboard(side_id))
		actions.add_child(add_side)

	_bind_card_hover(host, tile, card_id)


func _add_deck_rail(host, workspace: Node) -> void:
	var rail := _add_workspace_panel(host, workspace, "ACTIVE DECK", WORKSHOP_PANEL, PALETTE.SELECTION_BLUE)
	rail.name = "DeckbuilderDeckRail"
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var deck_panel := _add_deck_tab(
		host,
		rail,
		"Main Deck  %d cards" % host._deck_total(host.run.deck),
		"DeckbuilderMainDeckPanel"
	)
	_add_deck_grid(host, deck_panel, host.run.deck, true, "DeckbuilderMainDeckScroll")


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
		title_label.add_theme_font_override("font", DISPLAY_FONT)
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", PALETTE.TEXT_ON_LIGHT)
		panel.add_child(title_label)
	else:
		(parent as TabContainer).set_tab_title((parent as TabContainer).get_tab_count() - 1, title)

	var hint := Label.new()
	hint.text = "Hover to inspect" if String(host.run.get("run_loop", "")) == "route" else "Hover to inspect  •  Remove a card with −"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", PALETTE.TEXT_ON_LIGHT_SECONDARY)
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
	grid.columns = clampi(floori((host.get_viewport_rect().size.x - 100.0) / 164.0), 3, DECK_COLUMNS)
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
		var copy_count := maxi(0, int(deck[card_id]))
		for copy_index in range(copy_count):
			var display_card := _route_display_card_copy(host, card_id, card, copy_index)
			var tile := _add_card_tile(host, grid, card_id, display_card, "DeckbuilderDeckCard")
			tile.set_meta("copy_index", copy_index)
			tile.custom_minimum_size = Vector2(154, 226)

			var art_center := CenterContainer.new()
			art_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.add_child(art_center)
			art_center.add_child(_make_visual_card(host, display_card, DECK_CARD_SIZE))

			if String(host.run.get("run_loop", "")) != "route":
				var controls := HBoxContainer.new()
				controls.alignment = BoxContainer.ALIGNMENT_END
				tile.add_child(controls)
				var remove: Button = host._make_button("")
				remove.name = "DeckbuilderRemoveMainButton" if is_main else "DeckbuilderRemoveSideButton"
				remove.custom_minimum_size = Vector2(32, 28)
				_style_deck_button(remove, "icon")
				remove.tooltip_text = "Remove this copy"
				MATERIAL_SYMBOLS.apply_to_button(remove, "remove", 18, HORIZONTAL_ALIGNMENT_CENTER)
				var selected_id := card_id
				if is_main:
					host._connect_pressed(remove, func() -> void: host._remove_from_deck(selected_id))
				else:
					host._connect_pressed(remove, func() -> void: host._remove_from_sideboard(selected_id))
				controls.add_child(remove)

			_bind_card_hover(host, tile, card_id, copy_index)


func _add_workspace_panel(host, parent: Node, title: String, background: Color, accent: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(panel)
	_apply_angular_surface(panel, background, accent, false)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var title_bar := PanelContainer.new()
	title_bar.add_theme_stylebox_override(
		"panel",
		_clean_style(PALETTE.CARBON.lightened(0.035), accent, 0, 2, Vector4(10, 5, 10, 5), 5)
	)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_override("font", DISPLAY_FONT)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	title_bar.add_child(title_label)
	box.add_child(title_bar)
	return box


func _add_card_tile(host, parent: Node, card_id: String, card: Dictionary, node_name: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.set_meta("card_id", card_id)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tile_fill := WORKSHOP_TILE
	var tile_accent: Color = host._rarity_line_color(card.get("rarity", "common")).darkened(0.30)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(panel)
	var angular_surface = _apply_angular_surface(panel, tile_fill, tile_accent, false)
	panel.set_meta("deckbuilder_tile_surface", angular_surface)
	panel.set_meta("deckbuilder_tile_fill", tile_fill)
	panel.set_meta("deckbuilder_tile_accent", tile_accent)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
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


func _route_display_card(host, card_id: String, card: Dictionary) -> Dictionary:
	if (
		String(host.run.get("run_loop", "")) != "route"
		or host.route_run_service.upgrade_count(host.run, card_id) <= 0
	):
		return card
	var upgraded_card := card.duplicate(true)
	upgraded_card["upgraded"] = true
	return upgraded_card


func _route_display_card_copy(host, card_id: String, card: Dictionary, copy_index: int) -> Dictionary:
	if (
		String(host.run.get("run_loop", "")) != "route"
		or copy_index < 0
		or copy_index >= host.route_run_service.upgrade_count(host.run, card_id)
	):
		return card
	var upgraded_card := card.duplicate(true)
	upgraded_card["upgraded"] = true
	return upgraded_card


func _add_badge(parent: Node, text: String, background: Color, foreground: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		_clean_style(background, foreground, 1, 3, Vector4(9, 5, 9, 5))
	)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", foreground)
	badge.add_child(label)
	parent.add_child(badge)
	return badge


func _create_hover_preview(host) -> void:
	_hover_preview = PanelContainer.new()
	_hover_preview.name = "DeckbuilderHoverPreview"
	_hover_preview.custom_minimum_size = HOVER_PREVIEW_SIZE
	_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_preview.z_index = 1800
	_hover_preview.visible = false

	_hover_preview.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	host.add_child(_hover_preview)
	_apply_angular_surface(_hover_preview, WORKSHOP_SURFACE, PALETTE.ELECTRIC_CYAN, true)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 10)
	preview_margin.add_theme_constant_override("margin_right", 10)
	preview_margin.add_theme_constant_override("margin_top", 10)
	preview_margin.add_theme_constant_override("margin_bottom", 10)
	preview_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_preview.add_child(preview_margin)
	_hover_preview_body = CenterContainer.new()
	_hover_preview_body.name = "DeckbuilderHoverPreviewBody"
	_hover_preview_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_margin.add_child(_hover_preview_body)


func _remove_hover_preview(host) -> void:
	_hover_request_id += 1
	var existing: Node = host.find_child("DeckbuilderHoverPreview", true, false)
	if existing != null:
		existing.free()
	_hover_preview = null
	_hover_preview_body = null


func _bind_card_hover(host, control: Control, card_id: String, copy_index: int = -1) -> void:
	var tile_panel := control.get_parent().get_parent() as PanelContainer
	control.mouse_entered.connect(func() -> void:
		_set_card_tile_hover(tile_panel, true)
		_queue_hover_preview(host, control, card_id, copy_index)
	)
	control.mouse_exited.connect(func() -> void:
		_set_card_tile_hover(tile_panel, false)
		_hide_hover_preview()
	)


func _queue_hover_preview(host, source: Control, card_id: String, copy_index: int = -1) -> void:
	_hover_request_id += 1
	var request_id := _hover_request_id
	await host.get_tree().create_timer(HOVER_DELAY_SECONDS).timeout
	if (
		request_id != _hover_request_id
		or not is_instance_valid(source)
		or not source.get_global_rect().has_point(host.get_viewport().get_mouse_position())
	):
		return
	_show_hover_preview(host, source, card_id, copy_index)


func _show_hover_preview(host, source: Control, card_id: String, copy_index: int = -1) -> void:
	if (
		_hover_preview == null
		or not is_instance_valid(_hover_preview)
		or _hover_preview_body == null
		or not host.cards_by_id.has(card_id)
	):
		return

	for child in _hover_preview_body.get_children():
		child.free()
	var source_card: Dictionary = host.cards_by_id[card_id]
	var card: Dictionary = (
		_route_display_card_copy(host, card_id, source_card, copy_index)
		if copy_index >= 0
		else _route_display_card(host, card_id, source_card)
	)
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
		heading.add_theme_font_override("font", DISPLAY_FONT)
		heading.add_theme_font_size_override("font_size", 12)
		heading.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
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
	sort_label.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.62))
	parent.add_child(sort_label)

	_add_sort_button(host, parent, "Affinity", SORT_AFFINITY)
	_add_sort_button(host, parent, "Rarity", SORT_RARITY)
	_add_sort_button(host, parent, "Name", SORT_NAME)


func _add_sort_button(host, parent: HBoxContainer, label: String, mode: String) -> void:
	var selected: bool = host.deckbuilder_sort_mode == mode
	var button: Button = host._make_button(label)
	button.name = "DeckbuilderSort" + mode.capitalize()
	button.custom_minimum_size = Vector2(84, 36)
	button.toggle_mode = true
	button.button_pressed = selected
	_style_deck_button(button, "selected" if selected else "secondary")
	MATERIAL_SYMBOLS.apply_to_button(button, "check" if selected else "sort", 16)
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
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(panel)
	_apply_angular_surface(panel, WORKSHOP_SURFACE, accent, true)
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
	heading.add_theme_font_override("font", DISPLAY_FONT)
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	body.add_child(heading)
	var accent_rule := ColorRect.new()
	accent_rule.custom_minimum_size = Vector2(116, 3)
	accent_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	accent_rule.color = accent
	accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(accent_rule)
	return body


func _style_deck_button(button: Button, variant: String = "secondary") -> void:
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", false)
	button.set_meta("ui_button_quiet_keyline", true)
	button.theme_type_variation = &""
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 34.0)
	var spacing := StyleBoxFlat.new()
	spacing.bg_color = Color.TRANSPARENT
	spacing.border_color = Color.TRANSPARENT
	spacing.content_margin_left = 13
	spacing.content_margin_right = 13
	spacing.content_margin_top = 7
	spacing.content_margin_bottom = 7
	spacing.set_meta("global_angular_button_spacing", true)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, spacing.duplicate())
	button.add_theme_font_override("font", BODY_FONT)
	button.add_theme_font_size_override("font_size", 13)
	var face = button.get_node_or_null("DeckbuilderAngularButtonFace")
	if face == null:
		face = ANGULAR_BUTTON_FACE_SCRIPT.new()
		face.name = "DeckbuilderAngularButtonFace"
		button.add_child(face)
	face.configure(button, variant)
	var text_color: Color = face.text_color()
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, text_color)
	button.add_theme_color_override("font_disabled_color", Color(PALETTE.COOL_WHITE, 0.46))


func _apply_angular_surface(panel: Control, fill: Color, accent: Color, dark: bool):
	var surface = ANGULAR_SURFACE_SCRIPT.new()
	surface.name = "DeckbuilderAngularSurface"
	surface.show_behind_parent = true
	panel.add_child(surface)
	surface.configure(fill, accent, dark, false)
	return surface


func _set_card_tile_hover(panel: PanelContainer, hovered: bool) -> void:
	if not is_instance_valid(panel):
		return
	var surface = panel.get_meta("deckbuilder_tile_surface", null)
	if not is_instance_valid(surface):
		return
	var base_fill: Color = panel.get_meta("deckbuilder_tile_fill", WORKSHOP_TILE)
	var base_accent: Color = panel.get_meta("deckbuilder_tile_accent", PALETTE.STEEL)
	surface.configure(
		PALETTE.SURFACE_PAPER_MUTED if hovered else base_fill,
		PALETTE.ELECTRIC_CYAN if hovered else base_accent,
		false,
		false
	)


func _clean_style(
	background: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 7,
	content_margins: Vector4 = Vector4.ZERO,
	accent_width: int = 0,
	with_shadow: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.border_width_left = maxi(border_width, accent_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	if with_shadow:
		style.shadow_color = Color(PALETTE.CARBON, 0.20)
		style.shadow_size = 2
		style.shadow_offset = Vector2(3, 3)
	return style


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
