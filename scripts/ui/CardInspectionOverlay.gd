extends Control
## A read-only, keyboard-accessible close-up. It never plays or purchases a card.
const CONTENT := preload("res://scripts/ui/CardInspectionContent.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var _source: WeakRef
var _card: Dictionary
var _difficulty := "white"
var _close: Button


static func open_for(source: Control, card: Dictionary, difficulty: String = "white") -> Control:
	for existing in source.get_tree().get_nodes_in_group("shared_card_inspection"):
		existing.dismiss(false)
	var overlay = load("res://scripts/ui/CardInspectionOverlay.gd").new()
	overlay.name = "SharedCardInspection"
	overlay._source = weakref(source)
	overlay._card = card.duplicate(true)
	overlay._difficulty = difficulty
	source.get_tree().root.add_child(overlay)
	return overlay


static func bind(source: Control, card: Dictionary, difficulty: String = "white", click_to_inspect: bool = false) -> void:
	source.set_meta("inspection_card", card.duplicate(true))
	source.set_meta("inspection_difficulty", difficulty)
	source.set_meta("inspection_left_click", click_to_inspect or bool(source.get_meta("inspection_left_click", false)))
	if source.has_meta("shared_inspection_bound"):
		return
	source.set_meta("shared_inspection_bound", true)
	source.focus_mode = Control.FOCUS_ALL
	if source is Button:
		source.add_theme_stylebox_override("focus", CONTENT.focus_style())
	else:
		var focus := Panel.new()
		focus.name = "CardInspectionFocus"
		focus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus.add_theme_stylebox_override("panel", CONTENT.focus_style())
		focus.visible = false
		source.add_child(focus)
		source.focus_entered.connect(focus.show)
		source.focus_exited.connect(focus.hide)
	source.gui_input.connect(func(event: InputEvent) -> void:
		if not bool(source.get_meta("inspection_available", true)):
			return
		var mouse_inspect: bool = event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_RIGHT or (bool(source.get_meta("inspection_left_click", false)) and event.button_index == MOUSE_BUTTON_LEFT))
		var key_inspect: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_I or (bool(source.get_meta("inspection_left_click", false)) and event.keycode in [KEY_ENTER, KEY_SPACE]))
		if mouse_inspect or key_inspect:
			source.accept_event()
			open_for(source, source.get_meta("inspection_card"), String(source.get_meta("inspection_difficulty", "white")))
	)


func _ready() -> void:
	add_to_group("shared_card_inspection")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 3900
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = PALETTE.OVERLAY_DIM
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dismiss()
	)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var parts := UI.make_surface_panel("CardInspectionPanel", PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(24, 20, 24, 20), false)
	center.add_child(parts.panel)
	var body := parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 16)
	var header := HBoxContainer.new()
	body.add_child(header)
	_close = UI.make_button("Back", "secondary", Vector2(120, 48), "CardInspectionClose")
	_close.pressed.connect(dismiss)
	_close.focus_next = NodePath(".")
	_close.focus_previous = NodePath(".")
	header.add_child(_close)
	body.add_child(CONTENT.make_content(_card, _difficulty))
	UI.enter(self)
	_close.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()


func _process(_delta: float) -> void:
	var source := _source.get_ref() as Control
	if source == null or not source.is_visible_in_tree() or source.is_queued_for_deletion():
		dismiss(false)


func dismiss(restore_focus: bool = true) -> void:
	if is_queued_for_deletion():
		return
	var source := _source.get_ref() as Control
	if restore_focus and source != null and source.is_visible_in_tree():
		source.grab_focus()
	hide()
	queue_free()
