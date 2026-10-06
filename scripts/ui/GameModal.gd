extends Control
## Shared modal navigation. Content expands; actions stay outside its scroll area.
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
var close_action: Callable
var previous_focus: WeakRef
var body: VBoxContainer
var actions: HBoxContainer
var back: Button

static func create(parent: Control, title: String, node_name: String, on_close: Callable) -> Control:
	var modal = load("res://scripts/ui/GameModal.gd").new()
	modal.name = node_name
	modal.close_action = on_close
	var focused := parent.get_viewport().gui_get_focus_owner()
	if focused != null:
		modal.previous_focus = weakref(focused)
	parent.add_child(modal)
	modal._build(title)
	return modal

func _build(title: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 2500
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dimmer := ColorRect.new()
	dimmer.color = PALETTE.OVERLAY_DIM
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % edge, 32)
	add_child(margin)
	var parts := UI.make_surface_panel(node_name_for_panel(), PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, Vector2.ZERO, Vector4(24, 22, 24, 22), false)
	margin.add_child(parts.panel)
	var layout := parts.body as VBoxContainer
	layout.add_theme_constant_override("separation", 20)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 22)
	layout.add_child(header)
	back = UI.make_button("Back", "secondary", Vector2(120, 48), "%sBack" % name)
	back.pressed.connect(dismiss)
	header.add_child(back)
	header.add_child(UI.make_label(title, "screen_title"))
	body = VBoxContainer.new()
	body.name = "%sContent" % name
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	actions = HBoxContainer.new()
	actions.name = "%sActions" % name
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 14)
	layout.add_child(actions)
	back.grab_focus()
	UI.enter(self)

func node_name_for_panel() -> String:
	return "%sPanel" % name

func dismiss() -> void:
	if is_queued_for_deletion():
		return
	if close_action.is_valid():
		close_action.call()
	if previous_focus != null:
		var source := previous_focus.get_ref() as Control
		if source != null and source.is_visible_in_tree():
			source.grab_focus()
	hide()
	queue_free()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey and event.pressed):
		return
	if get_meta("busy", false):
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
	elif event.keycode == KEY_TAB:
		# Keep keyboard navigation in the top modal, including dynamic card grids.
		var focusables: Array[Control] = []
		for candidate in find_children("*", "Control", true, false):
			if candidate.is_visible_in_tree() and candidate.focus_mode == Control.FOCUS_ALL and not (candidate is BaseButton and candidate.disabled):
				focusables.append(candidate)
		if not focusables.is_empty():
			var current := focusables.find(get_viewport().gui_get_focus_owner())
			focusables[posmod(current + (-1 if event.shift_pressed else 1), focusables.size())].grab_focus()
			get_viewport().set_input_as_handled()
