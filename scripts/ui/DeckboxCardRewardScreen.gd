extends Control
## One-time deckbox choices use the same copy-aware browser as the live deck.
signal card_confirmed(entry: Dictionary)
signal save_requested
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const BROWSER := preload("res://scripts/ui/CardBrowser.gd")
const CONTENT := preload("res://scripts/ui/CardInspectionContent.gd")
const INSPECTION := preload("res://scripts/ui/CardInspectionOverlay.gd")
var browser: Control
var before_visual: Control
var before_face: Control
var _preview: VBoxContainer
var _confirm: Button
var _selection: Dictionary = {}
var _upgrades: Dictionary = {}
var _kind := ""
var _border := "white"
var _deck_count := 0

func _ready() -> void:
	browser.search.call_deferred("grab_focus")

func configure(run: Dictionary, entries: Array, upgrades: Dictionary, border: String) -> void:
	name = "DeckboxCardRewardScreen"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_kind = String(run.get("deckbox_reward", {}).get("kind", ""))
	_border = border
	_upgrades = upgrades
	for value in run.get("deck", {}).values():
		_deck_count += int(value)
	var remaining := int(run.get("deckbox_reward", {}).get("remaining", 0))
	var verb := "Remove" if _kind == "remove" else "Upgrade"
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	add_child(margin)
	var parts := UI.make_surface_panel("DeckboxRewardPaper", PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(24, 20, 24, 20), false)
	margin.add_child(parts.panel)
	var body: VBoxContainer = parts.body
	body.add_theme_constant_override("separation", 14)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	body.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	heading.add_child(UI.make_label(String(run.deckbox.name).to_upper(), "eyebrow", PALETTE.PEACH_TEAL))
	var title := UI.make_label("%s %d card%s" % [verb, remaining, "" if remaining == 1 else "s"], "screen_title")
	title.name = "DeckboxRewardTitle"
	heading.add_child(title)
	var save := UI.make_button("Save", "secondary", Vector2(110, 46), "DeckboxRewardSave")
	save.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	save.pressed.connect(func() -> void: save_requested.emit())
	header.add_child(save)
	var instruction := UI.make_label("Choose one copy at a time. Keep at least one card in your deck." if _kind == "remove" else "Choose one copy at a time. Each copy can be upgraded once.", "body", PALETTE.PEACH_INK_SOFT)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(instruction)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	body.add_child(columns)
	browser = BROWSER.new()
	browser.name = "DeckboxRewardBrowser"
	browser.configure(entries, border, "DeckboxReward", true, true)
	browser.card_selected.connect(_select_card)
	columns.add_child(browser)
	var preview_scroll := ScrollContainer.new()
	preview_scroll.name = "DeckboxRewardPreviewScroll"
	preview_scroll.custom_minimum_size.x = 420 if _kind == "upgrade" else 310
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.style_scroll(preview_scroll)
	columns.add_child(preview_scroll)
	_preview = VBoxContainer.new()
	_preview.name = "DeckboxRewardPreview"
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview.add_theme_constant_override("separation", 12)
	preview_scroll.add_child(_preview)
	_preview.add_child(UI.make_label("Select a card to preview", "section", PALETTE.PEACH_INK_SOFT))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	body.add_child(actions)
	var progress := UI.make_label("%d remaining · Free deckbox reward" % remaining, "body", PALETTE.PEACH_INK_SOFT)
	progress.name = "DeckboxRewardProgress"
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(progress)
	_confirm = UI.make_button(verb + " selected card", "danger" if _kind == "remove" else "confirm", Vector2(240, 54), "DeckboxRewardConfirm")
	_confirm.disabled = true
	_confirm.pressed.connect(func() -> void:
		if not _selection.is_empty() and not get_meta("busy", false):
			card_confirmed.emit(_selection.duplicate(true))
	)
	actions.add_child(_confirm)

func _select_card(entry: Dictionary) -> void:
	if get_meta("busy", false):
		return
	_selection = entry.duplicate(true)
	for child in _preview.get_children():
		_preview.remove_child(child)
		child.queue_free()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	_preview.add_child(row)
	for stage in ["Before", "After"] if _kind == "upgrade" else ["Remove"]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		row.add_child(column)
		var caption := UI.make_label(stage, "eyebrow", PALETTE.PEACH_INK_SOFT)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		var data: Dictionary = _upgrades[String(entry.id)] if stage == "After" else entry.card
		var face_size := Vector2(180, 256) if _kind == "upgrade" else Vector2(240, 341)
		var visual := Control.new()
		visual.custom_minimum_size = face_size
		visual.size = face_size
		column.add_child(visual)
		var face := CONTENT.make_face(data, face_size, _border)
		visual.add_child(face)
		INSPECTION.bind(face, data, _border, true)
		if stage != "After":
			before_visual = visual
			before_face = face
	var description := "%d → %d cards in your deck" % [_deck_count, _deck_count - 1] if _kind == "remove" else "Upgrade this copy permanently."
	var delta := UI.make_label(description, "body", PALETTE.PEACH_TEAL)
	delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview.add_child(delta)
	_confirm.disabled = false

func set_busy() -> void:
	set_meta("busy", true)
	for button in find_children("*", "BaseButton", true, false):
		button.disabled = true
	browser.search.editable = false
