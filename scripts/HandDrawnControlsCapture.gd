extends SceneTree

## Development-only sampler and focused screen captures. All controls use the
## shipped theme and global button renderer; no save data or art is generated.
## Godot --path . --script scripts/HandDrawnControlsCapture.gd
const MAIN_SCENE := preload("res://scenes/Main.tscn")
const THEME := preload("res://scripts/ui/KitchenGlassTheme.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const OUTPUT_DIR := "res://outputs/hand_drawn_ui"

var failures: Array[String] = []
var records: Array[Dictionary] = []
var capture_size := Vector2i.ZERO
var hover_button: Button
var focus_button: Button
var disabled_button: Button
var sampler_controls: Array[Control] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.set_meta("reduced_motion", true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for output_size in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		capture_size = output_size
		root.size = output_size
		var sampler := _build_sampler()
		root.add_child(sampler)
		await _settle()
		focus_button.grab_focus()
		_pointer_to(hover_button.get_global_rect().get_center())
		await _settle()
		_check(focus_button.has_focus(), "The sampler did not show real keyboard focus at %s." % output_size)
		_check(hover_button.is_hovered(), "The sampler did not show real pointer hover at %s." % output_size)
		_check(disabled_button.disabled and not disabled_button.has_focus(), "The disabled sample became interactive.")
		_audit_sampler_bounds()
		await _capture("01_controls", sampler)
		_pointer_to(Vector2(4, 4))
		sampler.queue_free()
		await _settle()

		main = MAIN_SCENE.instantiate()
		main.autosave_enabled = false
		main.autosave_suspended = true
		main.settings_path = "/tmp/chilling-at-locals-hand-drawn-capture-settings.json"
		root.add_child(main)
		# Main._ready applies its display defaults. Restore the requested physical
		# window size before evaluating responsive layout and taking screenshots.
		main.autosave_enabled = false
		main.player_settings.reduced_motion = true
		main.player_settings.resolution = [output_size.x, output_size.y]
		main._apply_player_settings(false)
		root.size = output_size
		await _settle()
		main._show_start()
		await _capture("02_title", main)
		main._show_settings()
		await _capture_settings("03_settings_display", "SettingsDisplayPanel")
		var audio_category := main.find_child("SettingsCategoryAudio", true, false) as Button
		_check(audio_category != null, "The actual settings Audio navigation is missing.")
		if audio_category != null:
			audio_category.pressed.emit()
			await _capture_settings("04_settings_audio", "SettingsAudioPanel")
		var accessibility_category := main.find_child("SettingsCategoryAccessibility", true, false) as Button
		_check(accessibility_category != null, "The actual settings Accessibility navigation is missing.")
		if accessibility_category != null:
			accessibility_category.pressed.emit()
			await _capture_settings("05_settings_accessibility", "SettingsAccessibilityPanel")
		main._release_audio_streams()
		main.queue_free()
		await _settle()
	_write_review_record()
	for failure in failures:
		push_error(failure)
	print("HAND_DRAWN_CONTROLS_CAPTURE_%s: %d views; %d failures" % ["OK" if failures.is_empty() else "FAILED", records.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)


func _build_sampler() -> Control:
	sampler_controls.clear()
	var canvas := Control.new()
	canvas.name = "HandDrawnControlSampler"
	canvas.theme = THEME.build(UI.BODY_FONT)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = PALETTE.PEACH_PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	canvas.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	margin.add_child(body)
	var heading := _section(body, "Hand-drawn controls", 30)
	heading.add_child(_label("Warm paper, loose ink, clear choices  ·  %d × %d" % [capture_size.x, capture_size.y], 15, PALETTE.PEACH_INK_SOFT))

	var roles := _row(_section(body, "Everyday actions", 18))
	_add_labeled_button(roles, "Primary", "Take a seat", "primary")
	_add_labeled_button(roles, "Secondary", "Back to the shop", "secondary")
	_add_labeled_button(roles, "Danger", "Abandon run", "danger")
	var states := _row(_section(body, "State and feedback", 18))
	_add_labeled_button(states, "Normal", "At rest", "secondary")
	hover_button = _add_labeled_button(states, "Pointer hover", "Hovering", "secondary")
	focus_button = _add_labeled_button(states, "Keyboard focus", "Focused", "secondary")
	var selected := _add_labeled_button(states, "Selected", "Selected", "selected")
	selected.toggle_mode = true
	selected.button_pressed = true
	disabled_button = _add_labeled_button(states, "Disabled", "Unavailable", "secondary")
	disabled_button.disabled = true

	var columns := _row(body)
	columns.add_theme_constant_override("separation", 32)
	var choices := _section(columns, "Switches and choices", 18)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var toggles := _row(choices)
	_add_toggle(toggles, "Sound on", true)
	_add_toggle(toggles, "Hints off", false)
	var unavailable_toggle := _add_toggle(toggles, "Disabled", false)
	unavailable_toggle.disabled = true
	var checks := _row(choices)
	_add_check(checks, "Checked", true)
	_add_check(checks, "Unchecked", false)
	var unavailable_check := _add_check(checks, "Disabled", true)
	unavailable_check.disabled = true
	var radios := _row(choices)
	var group := ButtonGroup.new()
	for index in 3:
		var radio := _add_check(radios, ["Casual", "Standard", "Expert"][index], index == 1)
		radio.button_group = group
		if index == 2:
			radio.disabled = true

	var fields := _section(columns, "Levels and fields", 18)
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_slider(fields, "Music", 68, true)
	_add_slider(fields, "Disabled", 35, false)
	var inputs := _row(fields)
	var editable := LineEdit.new()
	editable.placeholder_text = "Your name"
	editable.clear_button_enabled = true
	_add_control(inputs, editable, Vector2(0, 44))
	var read_only := LineEdit.new()
	read_only.text = "Read only"
	read_only.editable = false
	_add_control(inputs, read_only, Vector2(0, 44))
	var dropdown := OptionButton.new()
	dropdown.add_item("Normal speed")
	dropdown.add_item("Relaxed speed")
	dropdown.add_item("Fast speed")
	_add_control(fields, dropdown, Vector2(0, 44))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	body.add_child(_label("Native game controls · real hover and focus states · no image generation", 14, PALETTE.PEACH_INK_SOFT))
	return canvas


func _section(parent: Node, title: String, font_size: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	parent.add_child(section)
	section.add_child(_label(title, font_size))
	return section


func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	return row


func _label(value: String, font_size: int, color: Color = PALETTE.PEACH_INK) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", UI.BODY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_labeled_button(parent: Node, caption: String, text_value: String, variant: String) -> Button:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	column.add_child(_label(caption, 14, PALETTE.PEACH_INK_SOFT))
	var button := UI.make_button(text_value, variant, Vector2(0, 48))
	_add_control(column, button, Vector2(0, 48))
	return button


func _add_toggle(parent: Node, text_value: String, selected: bool) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text_value
	toggle.button_pressed = selected
	_add_control(parent, toggle, Vector2(0, 46))
	return toggle


func _add_check(parent: Node, text_value: String, selected: bool) -> CheckBox:
	var check := CheckBox.new()
	check.text = text_value
	check.button_pressed = selected
	_add_control(parent, check, Vector2(0, 46))
	return check


func _add_slider(parent: Node, caption: String, value: float, editable: bool) -> void:
	var row := _row(parent)
	var label := _label(caption, 15, PALETTE.PEACH_INK_SOFT)
	label.custom_minimum_size.x = 80
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.editable = editable
	_add_control(row, slider, Vector2(180, 30))


func _add_control(parent: Node, control: Control, minimum: Vector2) -> void:
	control.custom_minimum_size = minimum
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	sampler_controls.append(control)


func _pointer_to(point: Vector2, warp_system_pointer: bool = true) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	if warp_system_pointer and DisplayServer.get_name() != "headless":
		Input.warp_mouse(point)


func _audit_sampler_bounds() -> void:
	var viewport := root.get_visible_rect()
	for control in sampler_controls:
		_check(control.is_visible_in_tree() and viewport.encloses(control.get_global_rect()), "A sampler control clips at %s: %s." % [capture_size, control.get_class()])
	for button in [hover_button, focus_button, disabled_button]:
		_check(button.get_node_or_null("BattleAngularButtonFace") != null, "A sampler button bypassed the shared renderer.")


func _capture_settings(label: String, panel_name: String) -> void:
	await _settle()
	var panel := main.find_child(panel_name, true, false) as Control
	var shell := main.find_child("SettingsMenuShell", true, false) as Control
	_check(panel != null and panel.is_visible_in_tree(), "The actual settings category did not open: " + panel_name)
	_check(shell != null and root.get_visible_rect().encloses(shell.get_global_rect()), "The actual settings shell clips at %s." % capture_size)
	await _capture(label, main)


func _capture(label: String, scope: Control) -> void:
	await _settle()
	await create_timer(0.22).timeout
	if label == "01_controls":
		# OS pointer events can arrive while a native window opens or resizes.
		# Send the real viewport hover input again immediately before rendering.
		focus_button.grab_focus()
		for frame in 3:
			_pointer_to(hover_button.get_global_rect().get_center(), false)
			await process_frame
		_pointer_to(hover_button.get_global_rect().get_center(), false)
		hover_button.get_node("BattleAngularButtonFace").queue_redraw()
	_check(root.size == capture_size, "The window changed size before %s: expected %s, got %s." % [label, capture_size, root.size])
	var destination := OUTPUT_DIR.path_join("%dx%d_%s.png" % [capture_size.x, capture_size.y, label])
	var saved := false
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		if label == "01_controls":
			var hover_face := hover_button.get_node("BattleAngularButtonFace")
			_check(hover_button.is_hovered() and not hover_button.has_focus(), "The real pointer hover was lost before saving " + destination)
			_check(bool(hover_face.get("_last_hovered")), "The shared button face did not register hover before saving " + destination)
			_check(hover_face.fill_color_for_state("hover") == PALETTE.PEACH_MINT, "The shared hover face lost its mint feedback.")
			_check(focus_button.has_focus() and disabled_button.disabled, "The focus or disabled state changed before saving " + destination)
		var screenshot := root.get_texture().get_image()
		_check(screenshot != null and screenshot.get_size() == capture_size, "The rendered image does not match the requested dimensions for " + destination)
		saved = screenshot != null and screenshot.save_png(ProjectSettings.globalize_path(destination)) == OK
		_check(saved, "Could not save " + destination)
	records.append({"screen": label, "viewport": [capture_size.x, capture_size.y], "path": destination, "saved_png": saved, "scope": String(scope.name)})
	print("HAND_DRAWN_UI " + destination)


func _write_review_record() -> void:
	var file := FileAccess.open(OUTPUT_DIR.path_join("capture-review.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "Could not write the component capture review.")
		return
	file.store_string(JSON.stringify({"renderer": "native Godot controls", "ai_image_generation": false, "headless": DisplayServer.get_name() == "headless", "failures": failures, "views": records}, "\t") + "\n")


func _settle() -> void:
	for frame in 8:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
