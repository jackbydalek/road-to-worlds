extends VBoxContainer
## A copy-aware browser shared by live decks, starter lists and finished decks.
signal card_selected(entry: Dictionary)
signal remove_requested(card_id: String)
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CONTENT := preload("res://scripts/ui/CardInspectionContent.gd")
const HOVER := preload("res://scripts/ui/CardHoverPreview.gd")
const INSPECTION := preload("res://scripts/ui/CardInspectionOverlay.gd")
var entries: Array = []
var displayed_entries: Array = []
var difficulty := "white"
var prefix := "CardBrowser"
var selection_mode := false
var compact := false
var allow_remove := false
var query := ""
var type_filter := ""
var keyword_filter := ""
var sort_mode := "name"
var grouped := true
var selected_key := ""
var grid: GridContainer
var scroll: ScrollContainer
var count: Label
var search: LineEdit

func configure(values: Array, border: String = "white", node_prefix: String = "CardBrowser", choose: bool = false, compact_filters: bool = false) -> void:
	entries = values.duplicate(true)
	difficulty = border
	prefix = node_prefix
	selection_mode = choose
	compact = compact_filters
	if is_inside_tree():
		_build()

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 18)
	var toolbar := HFlowContainer.new()
	toolbar.name = prefix + "Filters"
	toolbar.add_theme_constant_override("h_separation", 10)
	toolbar.add_theme_constant_override("v_separation", 8)
	add_child(toolbar)
	search = LineEdit.new()
	search.name = prefix + "Search"
	search.placeholder_text = "Search cards"
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(230, 46)
	search.text = query
	_style_input(search)
	search.text_changed.connect(func(value: String) -> void: query = value; _render())
	toolbar.add_child(search)
	if not compact:
		var types := _filter("Type", ["ingredient", "meal", "chef", "tool", "spice", "environment"], prefix + "TypeFilter")
		types.item_selected.connect(func(index: int) -> void: type_filter = String(types.get_item_metadata(index)); _render())
		toolbar.add_child(types)
		var keywords: Array = []
		for entry in entries:
			for keyword in entry.card.get("keywords", []):
				if not keywords.has(keyword):
					keywords.append(keyword)
		keywords.sort()
		var keyword_choice := _filter("Keyword", keywords, prefix + "KeywordFilter")
		keyword_choice.item_selected.connect(func(index: int) -> void: keyword_filter = String(keyword_choice.get_item_metadata(index)); _render())
		toolbar.add_child(keyword_choice)
		var sorting := _filter("Sort: name", ["attack", "health", "copies", "type"], prefix + "Sort")
		sorting.item_selected.connect(func(index: int) -> void: sort_mode = "name" if index == 0 else String(sorting.get_item_metadata(index)); _render())
		toolbar.add_child(sorting)
		var grouping := CheckButton.new()
		grouping.name = prefix + "GroupCopies"
		grouping.text = "Group copies"
		grouping.button_pressed = grouped
		grouping.custom_minimum_size.y = 46
		grouping.toggled.connect(func(value: bool) -> void: grouped = value; _render())
		_style_input(grouping)
		toolbar.add_child(grouping)
	count = UI.make_label("", "small")
	count.name = prefix + "Count"
	add_child(count)
	scroll = ScrollContainer.new()
	scroll.name = prefix + "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	UI.style_scroll(scroll)
	add_child(scroll)
	grid = GridContainer.new()
	grid.name = prefix + "Grid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	scroll.resized.connect(_layout_grid)
	_layout_grid()
	_render()

func _filter(title: String, values: Array, node_name: String) -> OptionButton:
	var choice := OptionButton.new()
	choice.name = node_name
	choice.custom_minimum_size = Vector2(150, 46)
	choice.add_item(title)
	choice.set_item_metadata(0, "")
	for value in values:
		choice.add_item(String(value).replace("_", " ").capitalize())
		choice.set_item_metadata(choice.item_count - 1, value)
	_style_input(choice)
	return choice

func _style_input(control: Control) -> void:
	control.add_theme_font_override("font", UI.BODY_FONT)
	control.add_theme_font_size_override("font_size", 16)
	control.add_theme_color_override("font_color", PALETTE.PEACH_INK)
	control.set_meta("ui_button_variant", "secondary")
	if control is LineEdit:
		control.add_theme_color_override("font_placeholder_color", PALETTE.PEACH_INK_SOFT)
		control.add_theme_color_override("font_uneditable_color", PALETTE.PEACH_INK_SOFT.darkened(0.10))
		control.add_theme_color_override("font_selected_color", PALETTE.PEACH_PAPER)
		control.add_theme_color_override("selection_color", PALETTE.PEACH_TEAL)
		control.add_theme_color_override("caret_color", PALETTE.PEACH_INK)
		control.add_theme_color_override("clear_button_color", PALETTE.PEACH_INK_SOFT)
		control.add_theme_color_override("clear_button_color_pressed", PALETTE.PEACH_INK)
		control.add_theme_stylebox_override("normal", UI.paper_style(PALETTE.PEACH_PAPER, 12))
		control.add_theme_stylebox_override("read_only", UI.paper_style(PALETTE.PEACH_PAPER_MUTED, 12))
		control.add_theme_stylebox_override("focus", CONTENT.focus_style())
	elif control is OptionButton:
		var popup := (control as OptionButton).get_popup()
		popup.add_theme_font_override("font", UI.BODY_FONT)
		popup.add_theme_font_size_override("font_size", 16)
		popup.add_theme_color_override("font_color", PALETTE.PEACH_INK)
		popup.add_theme_color_override("font_hover_color", PALETTE.PEACH_PAPER)
		popup.add_theme_color_override("font_disabled_color", PALETTE.PEACH_INK_SOFT.darkened(0.10))
		popup.add_theme_stylebox_override("panel", UI.paper_style(PALETTE.PEACH_PAPER, 8))
		var highlight := UI.paper_style(PALETTE.PEACH_TEAL, 10)
		highlight.shadow_size = 0
		highlight.shadow_offset = Vector2.ZERO
		highlight.border_color = PALETTE.PEACH_TEAL
		popup.add_theme_stylebox_override("hover", highlight)
		popup.add_theme_constant_override("v_separation", 12)

func _layout_grid() -> void:
	if is_instance_valid(grid):
		grid.columns = maxi(1, int((scroll.size.x + 20) / 200))

func _key(entry: Dictionary) -> String:
	return "%s:%s" % [entry.id, str(bool(entry.card.get("upgraded", false)))]

func _render() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	displayed_entries.clear()
	var total := 0
	var matches := 0
	var grouped_indices := {}
	for value in entries:
		var entry: Dictionary = value.duplicate(true)
		var card: Dictionary = entry.card
		var copies := int(entry.get("count", 1))
		total += copies
		if not type_filter.is_empty() and String(card.get("card_type", "")) != type_filter:
			continue
		if not keyword_filter.is_empty() and not card.get("keywords", []).has(keyword_filter):
			continue
		var searchable := "%s %s %s" % [card.get("name", ""), card.get("text", ""), " ".join(card.get("keywords", []))]
		if not query.strip_edges().is_empty() and not searchable.to_lower().contains(query.strip_edges().to_lower()):
			continue
		matches += copies
		entry.count = copies
		var key := _key(entry)
		if grouped and grouped_indices.has(key):
			displayed_entries[int(grouped_indices[key])].count += copies
		else:
			grouped_indices[key] = displayed_entries.size()
			displayed_entries.append(entry)
	displayed_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if sort_mode in ["attack", "health"] and int(a.card.get(sort_mode, 0)) != int(b.card.get(sort_mode, 0)):
			return int(a.card.get(sort_mode, 0)) > int(b.card.get(sort_mode, 0))
		if sort_mode == "copies" and int(a.count) != int(b.count):
			return int(a.count) > int(b.count)
		if sort_mode == "type" and a.card.get("card_type", "") != b.card.get("card_type", ""):
			return String(a.card.get("card_type", "")) < String(b.card.get("card_type", ""))
		return String(a.card.get("name", a.id)).naturalnocasecmp_to(String(b.card.get("name", b.id))) < 0
	)
	count.text = "%d cards" % total if matches == total else "%d / %d cards" % [matches, total]
	if displayed_entries.is_empty():
		grid.add_child(UI.make_label("No matching cards", "section"))
	for entry in displayed_entries:
		var tile := VBoxContainer.new()
		tile.name = "%sCard_%s_%d" % [prefix, entry.id, int(entry.get("copy_index", 0))]
		tile.custom_minimum_size.x = 180
		tile.set_meta("card_id", entry.id)
		tile.set_meta("copy_index", entry.get("copy_index", 0))
		tile.add_theme_constant_override("separation", 8)
		grid.add_child(tile)
		var face := CONTENT.make_face(entry.card, Vector2(180, 256), difficulty)
		face.mouse_filter = Control.MOUSE_FILTER_STOP
		face.set_meta("card_id", entry.id)
		face.set_meta("copy_index", entry.get("copy_index", 0))
		tile.add_child(face)
		HOVER.bind(face, entry.card, difficulty)
		INSPECTION.bind(face, entry.card, difficulty, not selection_mode)
		if selection_mode:
			var selected_edge := Panel.new()
			selected_edge.name = "SelectedCopyEdge"
			selected_edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			selected_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			selected_edge.add_theme_stylebox_override("panel", CONTENT.focus_style())
			selected_edge.set_meta("selection_key", _key(entry))
			selected_edge.visible = selected_key == _key(entry)
			face.add_child(selected_edge)
			face.gui_input.connect(func(event: InputEvent) -> void:
				if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE]):
					selected_key = _key(entry)
					_update_selection()
					face.grab_focus()
					card_selected.emit(entry)
					face.accept_event()
			)
		var caption := UI.make_label("×%d%s" % [entry.count, "  ·  Upgraded" if bool(entry.card.get("upgraded", false)) else ""], "small", PALETTE.SIGNAL_YELLOW.darkened(0.54) if bool(entry.card.get("upgraded", false)) else PALETTE.PEACH_INK_SOFT)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(caption)
		if allow_remove:
			var remove := UI.make_button("Remove", "secondary", Vector2(0, 46))
			remove.pressed.connect(func() -> void: remove_requested.emit(String(entry.id)))
			tile.add_child(remove)

func _update_selection() -> void:
	for edge in grid.find_children("SelectedCopyEdge", "", true, false):
		edge.visible = edge.get_meta("selection_key", "") == selected_key
