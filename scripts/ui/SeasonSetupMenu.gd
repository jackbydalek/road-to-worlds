extends Control
class_name SeasonSetupMenu

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PAPER := preload("res://scripts/ui/StarterSelectionSurface.gd")
const TABLE := preload("res://scripts/ui/StarterTableSurface.gd")
const BOX := preload("res://scripts/ui/StarterDeckBox.gd")
const FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const RUN_SERVICE := preload("res://scripts/RunStateService.gd")
const ROUTE_SERVICE := preload("res://scripts/RouteRunService.gd")
const WEEKLY_SERVICE := preload("res://scripts/WeeklyDemoService.gd")
const BASE_SIZE := Vector2(1440, 900)
const STARTER_IDS := ["spicy", "hearty", "sweet"]
const STARTER_TITLES := ["Spicy", "Hearty", "Sweet"]
const STARTER_TAGLINES := ["Pressure & tempo", "Protection & resilience", "Draw & clever combos"]
const COVER_IDS := ["spicy_sriracharrow", "hearty_gravy_gazelle", "sweet_strawberry_sharkcake"]
const STARTER_ACCENTS := [PALETTE.AFFINITY_SPICY, PALETTE.AFFINITY_HEARTY, PALETTE.AFFINITY_SWEET]
const BORDER_IDS := ["white", "blue", "yellow", "silver", "gold"]
const BORDER_NAMES := ["Black", "Blue", "Yellow", "Silver", "Gold"]
const BORDER_COLORS := [PALETTE.CARD_BORDER_BLACK, PALETTE.CARD_BORDER_BLUE, PALETTE.CARD_BORDER_YELLOW, PALETTE.CARD_BORDER_SILVER, PALETTE.CARD_BORDER_GOLD]
const REST_POSITIONS := [Vector2(212, 239), Vector2(579, 188), Vector2(947, 224)]
const REST_SCALES := [Vector2(0.92, 0.84), Vector2(0.90, 0.82), Vector2(0.94, 0.86)]
const REST_ROTATIONS := [-0.075, 0.028, 0.065]

signal back_requested
signal starter_selected_requested(index: int)
signal deck_list_requested(index: int)
signal difficulty_selected_requested(index: int)
signal previous_border_requested
signal next_border_requested
signal confirm_requested
signal difficulty_closed_requested

# Retain these hidden compatibility mounts for Main's existing setup adapter.
@onready var starter_art_mount: CenterContainer = %SelectedStarterArtMount
@onready var starter_symbol_mount: CenterContainer = %StarterInfoSymbolMount
@onready var difficulty_scrim: ColorRect = %DifficultyScrim

var flow_root: Control
var panel_stage: Control
var boxes: Array[Button] = []
var deck_labels: Array[Control] = []
var difficulty_buttons: Array[Button] = []
var starter_profiles: Array = []
var difficulty_options: Array = []
var selected_index := -1
var selected_difficulty_index := -1
var selected_difficulty_id := "white"
var starting := false
var view_state := "table"
var start_sequence := 0
var layout_tween: Tween
var weekly_service = WEEKLY_SERVICE.new()
var welcome_note: Control
var welcome_title: Label
var welcome_prompt: Label
var back_button: Button
var receipt: Control
var receipt_title: Label
var receipt_intro: Label
var border_rules: Label
var choice_status: Label
var start_button: Button
var deck_list_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2.ZERO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Old shelf resources stay compatible with the scene, but never render or
	# animate behind this entirely native table.
	for child in get_children():
		if child is CanvasItem:
			child.hide()
	for viewport in find_children("*", "SubViewport", true, false):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	%DraftNightButton.visible = false
	_build_table()
	resized.connect(_fit_table)
	call_deferred("_fit_table")

func _build_table() -> void:
	flow_root = Control.new()
	flow_root.name = "StarterTableFlow"
	flow_root.size = BASE_SIZE
	flow_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(flow_root)
	var backdrop := TABLE.new()
	backdrop.name = "StarterTableBackdrop"
	backdrop.size = BASE_SIZE
	flow_root.add_child(backdrop)
	panel_stage = Control.new()
	panel_stage.name = "StarterBoxStage"
	panel_stage.size = BASE_SIZE
	panel_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_root.add_child(panel_stage)
	for index in range(3):
		var box := BOX.new()
		box.name = "StarterDeckBoxButton_%s" % STARTER_IDS[index]
		panel_stage.add_child(box)
		box.pressed.connect(select_starter.bind(index, true))
		boxes.append(box)
		var tag := PAPER.new()
		tag.name = "%sDeckTag" % STARTER_TITLES[index]
		tag.size = Vector2(284, 100)
		tag.accent = PALETTE.PEACH_TABLE if index == 1 else PALETTE.PEACH_MINT
		panel_stage.add_child(tag)
		var label := _label(STARTER_TITLES[index], 25)
		label.name = "DeckName"
		label.position = Vector2(17, 10)
		label.size = Vector2(250, 43)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(label)
		var detail := _label(STARTER_TAGLINES[index], 18, PALETTE.PEACH_INK_SOFT)
		detail.position = Vector2(12, 56)
		detail.size = Vector2(260, 34)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(detail)
		deck_labels.append(tag)
	back_button = UI.make_button("Back", "secondary", Vector2(134, 60))
	back_button.name = "StarterTableBackButton"
	back_button.position = Vector2(38, 29)
	back_button.size = Vector2(134, 60)
	back_button.pressed.connect(_handle_back)
	flow_root.add_child(back_button)
	welcome_note = PAPER.new()
	welcome_note.name = "StarterWelcomeNote"
	welcome_note.position = Vector2(249, 65)
	welcome_note.size = Vector2(394, 121)
	welcome_note.rotation = -0.035
	flow_root.add_child(welcome_note)
	welcome_title = _label("Your first locals", 32)
	welcome_title.position = Vector2(24, 16)
	welcome_title.size = Vector2(350, 57)
	welcome_note.add_child(welcome_title)
	welcome_prompt = _label("Choose a box, then a border.", 20, PALETTE.PEACH_INK_SOFT)
	welcome_prompt.position = Vector2(24, 78)
	welcome_prompt.size = Vector2(350, 35)
	welcome_note.add_child(welcome_prompt)
	_build_receipt()
	_apply_table_pose(false)
	_wire_focus()

func _build_receipt() -> void:
	receipt = PAPER.new()
	receipt.name = "StarterDifficultyReceipt"
	receipt.position = Vector2(743, 217)
	receipt.size = Vector2(578, 590)
	receipt.show_tape = false
	receipt.use_cozy_panel = true
	receipt.mouse_filter = Control.MOUSE_FILTER_STOP
	flow_root.add_child(receipt)
	receipt.hide()
	receipt_title = _label("Choose your border", 34)
	receipt_title.position = Vector2(28, 21)
	receipt_title.size = Vector2(522, 65)
	receipt.add_child(receipt_title)
	receipt_intro = _label("Difficulty, shown on your cards.", 20, PALETTE.PEACH_INK_SOFT)
	receipt_intro.position = Vector2(28, 89)
	receipt_intro.size = Vector2(522, 38)
	receipt.add_child(receipt_intro)
	for index in range(5):
		var button := UI.make_button(BORDER_NAMES[index], "secondary", Vector2(94, 126))
		button.name = "StarterBorder_%s" % BORDER_IDS[index]
		button.position = Vector2(28 + index * 107, 136)
		button.size = Vector2(94, 126)
		button.custom_minimum_size = Vector2(94, 126)
		button.toggle_mode = true
		button.text = ""
		button.tooltip_text = "%s border" % BORDER_NAMES[index]
		button.accessibility_name = button.tooltip_text
		button.draw.connect(_draw_border_swatch.bind(button, index))
		button.pressed.connect(select_difficulty.bind(index))
		receipt.add_child(button)
		var label := _label(BORDER_NAMES[index], 19)
		label.name = "BorderName"
		label.position = Vector2(0, 86)
		label.size = Vector2(94, 38)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_child(label)
		difficulty_buttons.append(button)
	border_rules = _label("Choose a border to see your starting setup.", 21, PALETTE.PEACH_INK_SOFT)
	border_rules.name = "StarterBorderRules"
	border_rules.position = Vector2(30, 276)
	border_rules.size = Vector2(516, 120)
	border_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt.add_child(border_rules)
	choice_status = _label("Choose a border to start.", 19)
	choice_status.name = "StarterChoiceStatus"
	choice_status.position = Vector2(30, 399)
	choice_status.size = Vector2(516, 38)
	receipt.add_child(choice_status)
	start_button = UI.make_button("Start", "confirm", Vector2(518, 65))
	start_button.name = "StarterTableStartButton"
	start_button.position = Vector2(30, 446)
	start_button.size = Vector2(518, 65)
	start_button.disabled = true
	start_button.pressed.connect(_begin_selected_run)
	receipt.add_child(start_button)
	deck_list_button = UI.make_button("View deck", "secondary", Vector2(518, 54))
	deck_list_button.name = "StarterDeckContentsButtonNative"
	deck_list_button.position = Vector2(30, 529)
	deck_list_button.size = Vector2(518, 54)
	deck_list_button.pressed.connect(func() -> void:
		if selected_index >= 0:
			deck_list_requested.emit(selected_index)
	)
	receipt.add_child(deck_list_button)

func configure(data: Dictionary, starter_art: Control) -> void:
	starter_profiles = data.get("starter_profiles", [])
	difficulty_options = data.get("difficulty_options", [])
	for child in starter_art_mount.get_children():
		child.queue_free()
	starter_art_mount.add_child(starter_art)
	for child in starter_symbol_mount.get_children():
		child.queue_free()
	for index in range(3):
		var tint: Color = STARTER_ACCENTS[index].lerp(PALETTE.PEACH_PAPER, 0.70)
		if index == 1:
			tint = PALETTE.PEACH_MINT
		boxes[index].configure(STARTER_IDS[index], _cover_data(index), STARTER_ACCENTS[index], tint)
	selected_index = clampi(int(data.get("starter_index", 0)), 0, 2) if bool(data.get("difficulty_open", false)) else -1
	selected_difficulty_index = clampi(int(data.get("difficulty_index", 0)), 0, 4) if bool(data.get("difficulty_chosen", false)) else -1
	selected_difficulty_id = BORDER_IDS[maxi(0, selected_difficulty_index)]
	view_state = "difficulty" if selected_index >= 0 else "table"
	_apply_table_pose(false)
	_refresh_difficulty()
	_fit_table()
	_wire_focus()
	call_deferred("_focus_initial_choice")

func _focus_initial_choice() -> void:
	if selected_index < 0:
		boxes[0].grab_focus()
	elif view_state == "difficulty":
		difficulty_buttons[maxi(0, selected_difficulty_index)].grab_focus()

func get_symbol_mount() -> CenterContainer:
	return starter_symbol_mount

func _cover_data(index: int) -> Dictionary:
	var profile: Dictionary = starter_profiles[index] if index < starter_profiles.size() else {}
	if profile.get("cover_card") is Dictionary and not profile.cover_card.is_empty():
		return profile.cover_card
	for card in profile.get("sample_cards", []):
		if String(card.get("id", "")) == COVER_IDS[index]:
			return card
	# Native catalog fallback also supports opening this scene in a capture tool.
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if catalog is Dictionary:
		for card in catalog.get("cards", []):
			if String(card.get("id", "")) == COVER_IDS[index]:
				return card
	return {}

func select_starter(index: int, animate := true) -> void:
	if starting or index < 0 or index >= boxes.size():
		return
	_cancel_transition()
	selected_index = index
	selected_difficulty_index = -1
	selected_difficulty_id = "white"
	starter_selected_requested.emit(index)
	view_state = "moving" if animate and not _reduced_motion() else "difficulty"
	_refresh_difficulty()
	_apply_table_pose(view_state == "moving")
	_wire_focus()
	if view_state == "moving":
		back_button.grab_focus()
	else:
		difficulty_buttons[0].grab_focus()

func select_difficulty(index: int) -> void:
	if starting or view_state != "difficulty" or index < 0 or index >= 5:
		return
	selected_difficulty_index = index
	selected_difficulty_id = BORDER_IDS[index]
	difficulty_selected_requested.emit(index)
	_refresh_difficulty()
	_wire_focus()

func _refresh_difficulty() -> void:
	for index in range(difficulty_buttons.size()):
		var active := index == selected_difficulty_index
		difficulty_buttons[index].set_pressed_no_signal(active)
		difficulty_buttons[index].tooltip_text = "%s border%s" % [BORDER_NAMES[index], " selected" if active else ""]
		difficulty_buttons[index].accessibility_name = difficulty_buttons[index].tooltip_text
		(difficulty_buttons[index].get_node("BorderName") as Label).text = "%s%s" % ["✓ " if active else "", BORDER_NAMES[index]]
		difficulty_buttons[index].queue_redraw()
	for index in range(boxes.size()):
		var color_index := selected_difficulty_index if index == selected_index and selected_difficulty_index >= 0 else 0
		boxes[index].set_difficulty(BORDER_IDS[color_index], BORDER_COLORS[color_index])
	start_button.disabled = selected_difficulty_index < 0 or selected_index < 0 or starting
	if selected_difficulty_index < 0:
		border_rules.text = "Choose a border to see your starting setup."
		choice_status.text = "Choose a border to start."
	else:
		var option: Dictionary = difficulty_options[selected_difficulty_index] if selected_difficulty_index < difficulty_options.size() else {}
		var economy = RUN_SERVICE.new()
		var money := int(option.get("starting_money", economy.starting_money_for_difficulty(selected_difficulty_id)))
		var life := int(option.get("starting_life", ROUTE_SERVICE.STARTING_LIFE))
		var recovery: Dictionary = weekly_service.week_health_recovery({"difficulty": selected_difficulty_id})
		var recovery_text := "Full heal each new week." if recovery.full_heal else "Heal %d each new week, up to max." % int(recovery.amount)
		border_rules.text = "%s border · %d starting life · $%d\nLife carries between rounds.\n%s" % [BORDER_NAMES[selected_difficulty_index], life, money, recovery_text]
		choice_status.text = "✓ %s deck · %s border" % [STARTER_TITLES[selected_index], BORDER_NAMES[selected_difficulty_index]]
	start_button.text = "Start" if not starting else "Starting…"

func _collapse_selection() -> void:
	if selected_index < 0 or starting:
		return
	var restore_index := selected_index
	_cancel_transition()
	selected_index = -1
	selected_difficulty_index = -1
	selected_difficulty_id = "white"
	view_state = "table"
	difficulty_closed_requested.emit()
	_refresh_difficulty()
	_apply_table_pose(false)
	_wire_focus()
	boxes[restore_index].grab_focus()

func _handle_back() -> void:
	if starting:
		return
	if selected_index >= 0:
		_collapse_selection()
	else:
		back_requested.emit()

func _begin_selected_run(requested_index := -1) -> void:
	if requested_index >= 0 and requested_index != selected_index:
		select_starter(requested_index)
		return
	if starting or view_state != "difficulty" or selected_index < 0 or selected_difficulty_index < 0:
		return
	starting = true
	view_state = "starting"
	start_button.disabled = true
	start_button.text = "Starting…"
	confirm_requested.emit()

func _cancel_transition() -> void:
	start_sequence += 1
	if layout_tween != null and layout_tween.is_valid():
		layout_tween.kill()

func _apply_table_pose(animate: bool) -> void:
	if boxes.size() != 3:
		return
	receipt.visible = view_state == "difficulty" or view_state == "starting"
	back_button.text = "Other decks" if selected_index >= 0 else "Back"
	back_button.custom_minimum_size.x = 163 if selected_index >= 0 else 134
	back_button.size.x = back_button.custom_minimum_size.x
	welcome_note.position = Vector2(751, 65) if selected_index >= 0 else Vector2(249, 65)
	welcome_note.size.x = 551 if selected_index >= 0 else 394
	welcome_title.text = "%s is on the table" % STARTER_TITLES[selected_index] if selected_index >= 0 else "Your first locals"
	welcome_title.size.x = welcome_note.size.x - 48
	welcome_prompt.size.x = welcome_note.size.x - 48
	welcome_prompt.text = "Choose your border, then settle in." if selected_index >= 0 else "Choose a box, then a border."
	if animate:
		layout_tween = create_tween().set_parallel(true)
		layout_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	for index in range(boxes.size()):
		var active := index == selected_index
		var box := boxes[index]
		box.selected = active
		box.disabled = selected_index >= 0
		box.focus_mode = Control.FOCUS_ALL if selected_index < 0 else Control.FOCUS_NONE
		box.mouse_filter = Control.MOUSE_FILTER_STOP if selected_index < 0 else Control.MOUSE_FILTER_IGNORE
		box.visible = selected_index < 0 or active
		box.z_index = 5 if active else index
		deck_labels[index].visible = selected_index < 0
		var target_position: Vector2 = Vector2(298, 205) if active else REST_POSITIONS[index]
		var target_scale: Vector2 = Vector2(1.0, 0.94) if active else REST_SCALES[index]
		var target_rotation: float = -0.018 if active else REST_ROTATIONS[index]
		if animate and active:
			layout_tween.tween_property(box, "position", target_position, 0.34)
			layout_tween.tween_property(box, "scale", target_scale, 0.34)
			layout_tween.tween_property(box, "rotation", target_rotation, 0.34)
		else:
			box.position = target_position
			box.scale = target_scale
			box.rotation = target_rotation
		deck_labels[index].position = Vector2(REST_POSITIONS[index].x - 1, 772 if index != 1 else 721)
		deck_labels[index].rotation = -0.03 if index != 1 else 0.035
	if animate:
		var sequence := start_sequence
		layout_tween.chain().tween_callback(func() -> void:
			if sequence != start_sequence or selected_index < 0:
				return
			view_state = "difficulty"
			receipt.show()
			_wire_focus()
			difficulty_buttons[0].grab_focus()
		)

func _fit_table() -> void:
	if not is_instance_valid(flow_root) or size.x <= 0 or size.y <= 0:
		return
	var fit := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
	flow_root.scale = Vector2.ONE * fit
	flow_root.position = (size - BASE_SIZE * fit) * 0.5

func _wire_focus() -> void:
	var controls: Array[Control] = [back_button]
	if selected_index < 0:
		for box in boxes:
			controls.append(box)
	elif view_state == "difficulty":
		for button in difficulty_buttons:
			controls.append(button)
		if not start_button.disabled:
			controls.append(start_button)
		controls.append(deck_list_button)
	for index in range(controls.size()):
		var before := controls[posmod(index - 1, controls.size())]
		var after := controls[(index + 1) % controls.size()]
		controls[index].focus_previous = controls[index].get_path_to(before)
		controls[index].focus_next = controls[index].get_path_to(after)
		controls[index].focus_neighbor_left = controls[index].get_path_to(before)
		controls[index].focus_neighbor_right = controls[index].get_path_to(after)

func _draw_border_swatch(button: Button, index: int) -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = PALETTE.PEACH_PAPER
	frame.border_color = BORDER_COLORS[index]
	frame.set_border_width_all(6)
	frame.set_corner_radius_all(6)
	button.draw_style_box(frame, Rect2(24, 13, 47, 66))
	if index == selected_difficulty_index:
		button.draw_circle(Vector2(72, 15), 11, PALETTE.PEACH_TEAL, true, -1, true)
		button.draw_line(Vector2(66, 15), Vector2(70, 19), PALETTE.PEACH_PAPER, 2, true)
		button.draw_line(Vector2(70, 19), Vector2(78, 10), PALETTE.PEACH_PAPER, 2, true)

func _label(copy: String, font_size: int, color: Color = PALETTE.PEACH_INK) -> Label:
	var label := Label.new()
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _reduced_motion() -> bool:
	return bool(get_tree().root.get_meta("reduced_motion", false))
