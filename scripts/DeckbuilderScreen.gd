extends RefCounted
class_name DeckbuilderScreen

const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"


func show(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "deck"
	host._render_nav()
	host._clear(host.content)
	host._update_status()

	var metrics: Dictionary = host._calculate_deck_metrics(host.run.deck, host.run.sideboard)
	var legal: Dictionary = host._deck_is_legal()
	var collection_ids: Array = _sorted_card_ids(host, host.run.collection.keys(), metrics.primary)
	var preview_card_id := ""
	if not collection_ids.is_empty():
		preview_card_id = String(collection_ids[0])

	var summary: VBoxContainer = host._add_panel(host.content, "Deckbuilder")
	host._add_body_text(summary, host._format_metrics(metrics))
	host._add_body_text(summary, "Legality: " + ("Legal for selected event" if legal.ok else legal.reason))
	_add_sort_controls(host, summary)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	host.content.add_child(columns)

	var collection_panel: VBoxContainer = host._add_panel(columns, "Collection")
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for card_id in collection_ids:
		var owned: int = host._owned_count(card_id)
		var available: int = host._available_count(card_id)
		var card: Dictionary = host.cards_by_id[card_id]
		var row_panel := _add_card_row_panel(host, collection_panel, card_id, card)
		var row := _add_card_row_contents(row_panel)

		var dot := Label.new()
		dot.text = "●"
		dot.tooltip_text = host._affinity_label(host._card_animal_type(card))
		dot.add_theme_color_override("font_color", host._affinity_color(host._card_animal_type(card)))
		row.add_child(dot)

		var label := Label.new()
		label.text = "%s x%d | %s %s | cost %d | %s" % [
			card.name,
			owned,
			String(card.rarity).capitalize(),
			String(card.role).capitalize(),
			int(card.cost),
			host._affinity_label(host._card_animal_type(card))
		]
		label.tooltip_text = card.text
		label.add_theme_color_override("font_color", host._rarity_text_color(card.get("rarity", "common")))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var add_main: Button = host._make_button("+ Main")
		add_main.disabled = available <= 0 or host._deck_total(host.run.deck) >= host.run_state_service.main_deck_size or host._deck_count(card_id) >= host._deck_limit(card_id)
		var main_id := String(card_id)
		host._connect_pressed(add_main, func() -> void: host._add_to_deck(main_id))
		row.add_child(add_main)

		var add_side: Button = host._make_button("+ Side")
		add_side.disabled = available <= 0 or host._deck_total(host.run.sideboard) >= host.run_state_service.sideboard_size or host._sideboard_count(card_id) >= host._deck_limit(card_id)
		var side_id := String(card_id)
		host._connect_pressed(add_side, func() -> void: host._add_to_sideboard(side_id))
		row.add_child(add_side)

	var preview_panel: VBoxContainer = host._add_panel(columns, "Card Preview")
	preview_panel.name = "DeckbuilderCardPreview"
	preview_panel.custom_minimum_size = Vector2(260, 0)
	var preview_body := VBoxContainer.new()
	preview_body.name = "DeckbuilderCardPreviewBody"
	preview_body.add_theme_constant_override("separation", 6)
	preview_panel.add_child(preview_body)
	_show_card_preview(host, preview_body, preview_card_id)

	for row_panel in collection_panel.get_children():
		if row_panel is Control and row_panel.has_meta("card_id"):
			_bind_card_hover(host, row_panel, String(row_panel.get_meta("card_id")), preview_body)

	var deck_panel: VBoxContainer = host._add_panel(columns, "Main Deck %d/%d" % [host._deck_total(host.run.deck), host.run_state_service.main_deck_size])
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_deck_list(host, deck_panel, host.run.deck, true, preview_body)

	var side_panel: VBoxContainer = host._add_panel(columns, "Sideboard %d/%d" % [host._deck_total(host.run.sideboard), host.run_state_service.sideboard_size])
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_deck_list(host, side_panel, host.run.sideboard, false, preview_body)


func _add_deck_list(host, parent: VBoxContainer, deck: Dictionary, is_main: bool, preview_body: VBoxContainer = null) -> void:
	var metrics: Dictionary = host._calculate_deck_metrics(host.run.deck, host.run.sideboard)
	var ids: Array = _sorted_card_ids(host, deck.keys(), metrics.primary)
	if ids.is_empty():
		host._add_body_text(parent, "No cards yet.")
		return

	for card_id in ids:
		var card: Dictionary = host.cards_by_id[card_id]
		var row_panel := _add_card_row_panel(host, parent, String(card_id), card)
		var row := _add_card_row_contents(row_panel)

		var dot := Label.new()
		dot.text = "●"
		dot.tooltip_text = host._affinity_label(host._card_animal_type(card))
		dot.add_theme_color_override("font_color", host._affinity_color(host._card_animal_type(card)))
		row.add_child(dot)

		var label := Label.new()
		label.text = "%s x%d | %s | cost %d" % [
			card.name,
			int(deck[card_id]),
			String(card.rarity).capitalize(),
			int(card.cost)
		]
		label.tooltip_text = card.text
		label.add_theme_color_override("font_color", host._rarity_text_color(card.get("rarity", "common")))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var button: Button = host._make_button("−")
		button.tooltip_text = "Remove " + String(card.name)
		var selected_id := String(card_id)
		if is_main:
			host._connect_pressed(button, func() -> void: host._remove_from_deck(selected_id))
		else:
			host._connect_pressed(button, func() -> void: host._remove_from_sideboard(selected_id))
		row.add_child(button)
		_bind_card_hover(host, row_panel, String(card_id), preview_body)


func _add_card_row_panel(host, parent: Node, card_id: String, card: Dictionary) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.name = "DeckbuilderCardRow"
	row_panel.set_meta("card_id", card_id)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = host._rarity_line_color(card.get("rarity", "common"))
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
	return row_panel


func _add_card_row_contents(row_panel: PanelContainer) -> HBoxContainer:
	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 6)
	row_margin.add_theme_constant_override("margin_right", 6)
	row_margin.add_theme_constant_override("margin_top", 4)
	row_margin.add_theme_constant_override("margin_bottom", 4)
	row_panel.add_child(row_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row_margin.add_child(row)
	return row


func _bind_card_hover(host, control: Control, card_id: String, preview_body: VBoxContainer) -> void:
	if control == null or preview_body == null:
		return
	control.mouse_entered.connect(func() -> void: _show_card_preview(host, preview_body, card_id))


func _show_card_preview(host, preview_body: VBoxContainer, card_id: String) -> void:
	if preview_body == null or not is_instance_valid(preview_body):
		return
	for child in preview_body.get_children():
		child.free()
	if not host.cards_by_id.has(card_id):
		return

	host.card_frame_factory.add_frame(
		preview_body,
		host._card_frame_data(card_id),
		{
			"panel_name": "DeckbuilderPreviewFrame",
			"contents_name": "DeckbuilderPreviewContents",
			"name_prefix": "DeckbuilderPreview",
			"compact": false,
			"min_size": Vector2(248, 0),
			"show_combat_stats": true,
			"show_deck_stats": true,
			"show_rules_text": true,
			"border_width": 2
		}
	)


func _add_sort_controls(host, parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Sort cards:"
	label.add_theme_color_override("font_color", Color("#c7d0df"))
	row.add_child(label)

	_add_sort_button(host, row, "Deck Affinity", SORT_AFFINITY)
	_add_sort_button(host, row, "Rarity", SORT_RARITY)
	_add_sort_button(host, row, "Name", SORT_NAME)


func _add_sort_button(host, parent: HBoxContainer, label: String, mode: String) -> void:
	var button: Button = host._make_button(label)
	button.disabled = host.deckbuilder_sort_mode == mode
	host._connect_pressed(button, func() -> void: _set_sort_mode(host, mode))
	parent.add_child(button)


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
