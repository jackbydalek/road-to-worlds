extends Control
## Shared paper surfaces and live controls for the between-week prize.
signal deckbox_chosen(id: String)
signal continue_requested
signal save_requested
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")
const BOX_DISPLAY := preload("res://scripts/ui/DeckboxDisplay.gd")
const CLOTH := preload("res://scripts/ui/RewardTableSurface.gd")
const WEEKLY := preload("res://scripts/WeeklyDemoService.gd")
var _chosen_id := ""
var _run: Dictionary = {}
var _choice_views: Array[Dictionary] = []
var _confirm: Button
var _consequence: Label
var _consequence_heading: Label
var _prize_grid: GridContainer
var _prize_stage: MarginContainer
var _prize_actions: HFlowContainer
var _prize_receipt: PanelContainer
var _choosing := false

func configure(run: Dictionary, choices: Array) -> void:
	_run = run.duplicate(true)
	_choosing = String(run.get("week_transition", "")) == "deckbox"
	if not _choosing:
		_configure_intro(run)
		return
	name = "WeeklyDemoScreen"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(_update_prize_layout)
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	add_child(page)
	var rail := UI.make_surface_panel("WeeklyDemoStatus", PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(24, 12, 24, 12), false)
	page.add_child(rail.panel)
	var status_row := HFlowContainer.new()
	status_row.add_theme_constant_override("h_separation", 24)
	status_row.add_theme_constant_override("v_separation", 8)
	rail.body.add_child(status_row)
	var venue := UI.make_label("YOUR AFTERNOON AT LOCALS", "eyebrow", PALETTE.PEACH_INK)
	venue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(venue)
	status_row.add_child(UI.make_label("LIFE  %d / %d    ·    FUNDS  $%d    ·    DECK  %d cards" % [int(run.get("life", 0)), int(run.get("max_life", 40)), int(run.get("money", 0)), _deck_count(run.get("deck", {}))], "body", PALETTE.PEACH_INK))
	var save := UI.make_button("Save", "secondary", Vector2(110, 46), "WeeklyDemoSave")
	save.pressed.connect(func() -> void: save_requested.emit())
	status_row.add_child(save)
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	for edge in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 18)
	page.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 5)
	body.add_child(heading)
	for entry in [["WEEK 1 COMPLETE", "eyebrow"], ["Choose your deckbox", "screen_title"], ["One prize to shape the rest of your run.", "body"]]:
		var label := UI.make_label(entry[0], entry[1], PALETTE.PEACH_TEAL if entry[1] == "eyebrow" else PALETTE.PEACH_INK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.name = "WeeklyDemoPrizeScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	UI.style_scroll(scroll)
	body.add_child(scroll)
	var stage := MarginContainer.new()
	_prize_stage = stage
	stage.name = "WeeklyDemoPrizeTable"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right"]:
		stage.add_theme_constant_override("margin_" + edge, 25)
	stage.add_theme_constant_override("margin_top", 14)
	stage.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(stage)
	var cloth := CLOTH.new()
	cloth.name = "PrizeCloth"
	cloth.show_behind_parent = true
	stage.add_child(cloth)
	_prize_grid = GridContainer.new()
	_prize_grid.name = "WeeklyDemoChoices"
	_prize_grid.columns = 3
	_prize_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prize_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_prize_grid.add_theme_constant_override("h_separation", 24)
	_prize_grid.add_theme_constant_override("v_separation", 18)
	stage.add_child(_prize_grid)
	for entry in choices:
		_prize_grid.add_child(_choice_card(entry))
	var actions := HFlowContainer.new()
	_prize_actions = actions
	actions.name = "WeeklyDemoDecision"
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("h_separation", 18)
	actions.add_theme_constant_override("v_separation", 10)
	var decision_center := CenterContainer.new()
	body.add_child(decision_center)
	decision_center.add_child(actions)
	var receipt := UI.make_surface_panel("DeckboxConsequence", PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2(260, 0), Vector4(18, 10, 18, 10), false)
	_prize_receipt = receipt.panel
	receipt.panel.size_flags_horizontal = Control.SIZE_FILL
	actions.add_child(receipt.panel)
	receipt.body.add_theme_constant_override("separation", 3)
	_consequence_heading = UI.make_label("ONE PRIZE TO TAKE HOME", "eyebrow", PALETTE.PEACH_TEAL)
	receipt.body.add_child(_consequence_heading)
	_consequence = UI.make_label("Select a deckbox to preview its bonus.", "body", PALETTE.PEACH_INK)
	_consequence.name = "DeckboxConsequenceLabel"
	receipt.body.add_child(_consequence)
	_confirm = UI.make_button("Choose a deckbox", "primary", Vector2(320, 58), "WeeklyDemoContinue")
	_confirm.disabled = true
	_confirm.tooltip_text = "Select one deckbox above before taking your prize."
	_confirm.pressed.connect(func() -> void:
		if not _chosen_id.is_empty():
			deckbox_chosen.emit(_chosen_id)
	)
	actions.add_child(_confirm)
	if not _choice_views.is_empty():
		_choice_views[0].button.call_deferred("grab_focus")
	call_deferred("_update_prize_layout")

func _configure_intro(run: Dictionary) -> void:
	name = "WeeklyDemoScreen"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	add_child(margin)
	var parts := UI.make_surface_panel("WeeklyDemoPaper", PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(24, 20, 24, 20), false)
	margin.add_child(parts.panel)
	var body: VBoxContainer = parts.body
	body.add_theme_constant_override("separation", 18)
	body.add_child(UI.make_label("WEEK 1 COMPLETE", "eyebrow", PALETTE.PEACH_TEAL))
	body.add_child(UI.make_label("See you next week", "screen_title", PALETTE.PEACH_INK))
	var benefit := String(run.get("deckbox", {}).get("description", ""))
	var reward: Dictionary = run.get("deckbox_reward", {})
	if String(reward.get("kind", "")) in ["remove", "upgrade"]:
		benefit = "%d cards %s. Your updated deck carries into next week." % [int(reward.get("applied", 0)), "removed" if reward.kind == "remove" else "upgraded"]
	body.add_child(UI.make_label("%s — %s" % [String(run.get("deckbox", {}).get("name", "Your deckbox")), benefit], "body", PALETTE.PEACH_INK_SOFT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "WeeklyDemoChoices"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	var recovery: Dictionary = WEEKLY.new().week_health_recovery(run)
	var recovery_text := "Start the week at full life." if recovery.full_heal else "Heal %d life at the start of the week, up to your maximum." % int(recovery.amount)
	for entry in [
		["Second Helpings", "A free five-card pack introduces Special Serve Meals and Spices. Take any or all of its cards."],
		["Special Serve", "Meals can use their normal recipe OR their Special Serve condition. Special Serves are unlimited per turn and do not spend your normal Meal."],
		["Week 2 at Locals", "Your deck, upgrades, money and deckbox carry over. %s Your bye and shop services refresh. Win four more rounds to finish the demo." % recovery_text]
	]:
		var info := UI.make_surface_panel("WeekIntroCard", PALETTE.PEACH_PAPER_MUTED, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(18, 18, 18, 18), false)
		info.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.body.add_child(UI.make_label(entry[0], "section", PALETTE.PEACH_INK))
		var description := UI.make_label(entry[1], "body", PALETTE.PEACH_INK_SOFT)
		if entry[0] == "Week 2 at Locals":
			description.name = "WeeklyRecoveryRules"
		info.body.add_child(description)
		grid.add_child(info.panel)
	body.add_child(UI.make_label("Spices: select one of your units, choose Season This Card, then play a Spice. A unit can hold one Spice. Sacrificing it also discards its Spice.", "small", PALETTE.PEACH_INK_SOFT))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	body.add_child(actions)
	var save := UI.make_button("Save", "secondary", Vector2(120, 48), "WeeklyDemoSave")
	save.pressed.connect(func() -> void: save_requested.emit())
	actions.add_child(save)
	var status := UI.make_label("%d / %d life  •  $%d  •  %d cards" % [int(run.get("life", 0)), int(run.get("max_life", 40)), int(run.get("money", 0)), _deck_count(run.get("deck", {}))], "small", PALETTE.PEACH_INK_SOFT)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(status)
	var confirm := UI.make_button("Start Week 2 · Open pack", "primary", Vector2(290, 54), "WeeklyDemoContinue")
	confirm.pressed.connect(func() -> void: continue_requested.emit())
	actions.add_child(confirm)
	resized.connect(func() -> void: grid.columns = 1 if size.x < 760 else 3)
	confirm.call_deferred("grab_focus")

func _choice_card(entry: Dictionary) -> Control:
	var button := Button.new()
	button.name = "DeckboxChoice_" + String(entry.id)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.accessibility_name = "%s. %s. Select this deckbox." % [String(entry.name), String(entry.description)]
	button.tooltip_text = String(entry.description)
	button.set_meta("ui_button_style_exempt", true)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = PALETTE.PEACH_PAPER
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", focus)
	var contents := VBoxContainer.new()
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.add_theme_constant_override("separation", 0)
	button.add_child(contents)
	var illustration := BOX_DISPLAY.new()
	illustration.name = "DeckboxIllustration"
	illustration.custom_minimum_size = Vector2(0, 230)
	illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	illustration.configure(entry)
	contents.add_child(illustration)
	var tag := UI.make_surface_panel("DeckboxTag_" + String(entry.id), PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(14, 9, 14, 12), false)
	contents.add_child(tag.panel)
	tag.body.add_theme_constant_override("separation", 5)
	var selection_panel := PanelContainer.new()
	selection_panel.name = "DeckboxSelectionTab"
	var selection := UI.make_label("SELECT", "eyebrow", PALETTE.PEACH_INK_SOFT)
	selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_panel.add_child(selection)
	tag.body.add_child(selection_panel)
	var title := UI.make_label(String(entry.name), "section", PALETTE.PEACH_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.body.add_child(title)
	var description := UI.make_label(String(entry.description), "body", PALETTE.PEACH_INK)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.custom_minimum_size.y = 49
	tag.body.add_child(description)
	var view := {"button": button, "display": illustration, "selection": selection, "tab": selection_panel, "entry": entry.duplicate(true)}
	_choice_views.append(view)
	_set_choice_state(view, false)
	_ignore_mouse(contents)
	contents.minimum_size_changed.connect(func() -> void: button.custom_minimum_size = contents.get_combined_minimum_size())
	button.custom_minimum_size = contents.get_combined_minimum_size()
	button.pressed.connect(func() -> void: _select_box(entry))
	return button

func _select_box(entry: Dictionary) -> void:
	_chosen_id = String(entry.id)
	set_meta("chosen_deckbox_id", _chosen_id)
	for view in _choice_views:
		_set_choice_state(view, String(view.entry.id) == _chosen_id)
	_confirm.text = "Take " + String(entry.name)
	_confirm.disabled = false
	_confirm.tooltip_text = "Keep this one deckbox for the rest of your run."
	_consequence_heading.text = "FOR THE REST OF YOUR RUN"
	_consequence.text = String(entry.description)
	var effects: Dictionary = entry.get("effects", {})
	if effects.has("remove_cards") or effects.has("upgrade_cards"):
		_consequence_heading.text = "CHOOSE YOUR CARDS NEXT"
	var life_bonus := int(entry.get("effects", {}).get("max_life", 0))
	if life_bonus != 0:
		var before_life := int(_run.get("life", 0))
		var before_max := int(_run.get("max_life", 40))
		var after_max := before_max + life_bonus
		_consequence_heading.text = "WHEN CHOSEN"
		_consequence.text = "Life %d / %d  →  %d / %d" % [before_life, before_max, mini(after_max, before_life + life_bonus), after_max]

func _set_choice_state(view: Dictionary, value: bool) -> void:
	view.display.set_selected(value)
	view.selection.text = "✓ SELECTED" if value else "SELECT"
	view.selection.add_theme_color_override("font_color", PALETTE.PEACH_PAPER if value else PALETTE.PEACH_INK_SOFT)
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.PEACH_TEAL if value else Color.TRANSPARENT
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.set_corner_radius_all(4)
	view.tab.add_theme_stylebox_override("panel", style)
	view.button.accessibility_name = "%s. %s. %s" % [String(view.entry.name), String(view.entry.description), "Selected." if value else "Select this deckbox."]
	view.button.set_meta("selected", value)

func _update_prize_layout() -> void:
	queue_redraw()
	if not is_instance_valid(_prize_grid):
		return
	_prize_grid.columns = 1 if size.x < 800 else 3
	var side_margin := maxi(25, roundi((size.x - 1256.0) * 0.5))
	_prize_stage.add_theme_constant_override("margin_left", side_margin)
	_prize_stage.add_theme_constant_override("margin_right", side_margin)
	_prize_actions.custom_minimum_size.x = minf(1080.0, maxf(260.0, size.x - 56.0))
	_prize_receipt.custom_minimum_size.x = minf(420.0, maxf(230.0, size.x - 68.0))
	var illustration_height := clampf(size.y * 0.33, 180.0, 300.0)
	for view in _choice_views:
		view.display.custom_minimum_size.y = illustration_height
	_confirm.custom_minimum_size.x = minf(440.0, maxf(180.0, size.x - 68))

func _draw() -> void:
	if not _choosing:
		return
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.PEACH_TABLE)
	for y in range(15, int(size.y), 127):
		SKETCH.line(self, Vector2(0, y), Vector2(size.x, y + 3), Color(PALETTE.PEACH_INK, 0.10), 1.0)
		SKETCH.line(self, Vector2(size.x * 0.67, y + 12), Vector2(size.x * 0.95, y + 14), Color(PALETTE.PEACH_PAPER, 0.27), 1.0)

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _deck_count(deck: Dictionary) -> int:
	var total := 0
	for count in deck.values():
		total += int(count)
	return total
