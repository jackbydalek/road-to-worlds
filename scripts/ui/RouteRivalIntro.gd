extends Control

signal continue_requested

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const TOPDECK_UI := preload("res://scripts/ui/TopdeckUIComponents.gd")

var dimmer: ColorRect
var portrait_stage: Control
var portrait: TextureRect
var dialogue_panel: PanelContainer
var continue_button: Button
var wipe_layer: Control
var accent := PALETTE.FOCUS_EDGE
var reduced_motion := false
var automated_test := false
var entrance_started := false


func configure(
	portrait_texture: Texture2D,
	speaker_name: String,
	dialogue: String,
	accent_color: Color,
	reduce_motion: bool,
	is_automated_test: bool
) -> void:
	accent = accent_color
	reduced_motion = reduce_motion
	automated_test = is_automated_test
	_build_overlay(
		portrait_texture,
		speaker_name,
		dialogue
	)
	if reduced_motion or automated_test:
		continue_button.disabled = false
	else:
		call_deferred("_play_entrance")


func _build_overlay(
	portrait_texture: Texture2D,
	speaker_name: String,
	dialogue: String
) -> void:
	name = "RouteEncounterOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2400

	dimmer = ColorRect.new()
	dimmer.name = "RouteEncounterDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = PALETTE.OVERLAY_DIM
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var portrait_backing := ColorRect.new()
	portrait_backing.name = "RouteRivalPortraitBacking"
	_set_anchors(portrait_backing, 0.54, 0.055, 0.94, 0.765)
	portrait_backing.color = Color(PALETTE.COOL_WHITE, 0.075)
	portrait_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait_backing)

	var backing_accent := ColorRect.new()
	backing_accent.name = "RouteRivalBackingAccent"
	backing_accent.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backing_accent.custom_minimum_size.y = 5.0
	backing_accent.offset_bottom = 5.0
	backing_accent.color = accent
	backing_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_backing.add_child(backing_accent)

	portrait_stage = Control.new()
	portrait_stage.name = "RouteRivalPortraitStage"
	portrait_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait_stage)

	portrait = TextureRect.new()
	portrait.name = "RouteRivalPortrait"
	portrait.texture = portrait_texture
	_set_anchors(portrait, 0.49, 0.02, 0.985, 0.82)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stage.add_child(portrait)

	var dialogue_parts := TOPDECK_UI.make_surface_panel(
		"RouteRivalDialoguePanel",
		PALETTE.SURFACE_RAISED,
		accent,
		Vector2(0, 190),
		Vector4(26, 18, 22, 18),
		true
	)
	dialogue_panel = dialogue_parts.panel as PanelContainer
	_set_anchors(dialogue_panel, 0.055, 0.715, 0.945, 0.96)
	add_child(dialogue_panel)

	var dialogue_row := HBoxContainer.new()
	dialogue_row.name = "RouteRivalDialogueRow"
	dialogue_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_row.add_theme_constant_override("separation", 24)
	(dialogue_parts.body as VBoxContainer).add_child(dialogue_row)

	var copy := VBoxContainer.new()
	copy.name = "RouteRivalDialogueCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	dialogue_row.add_child(copy)

	var speaker := TOPDECK_UI.make_label(speaker_name.to_upper(), "section", PALETTE.TEXT_PRIMARY)
	speaker.name = "RouteRivalSpeaker"
	copy.add_child(speaker)

	var dialogue_label := TOPDECK_UI.make_label("“%s”" % dialogue, "body", PALETTE.TEXT_PRIMARY)
	dialogue_label.name = "RouteRivalDialogueText"
	dialogue_label.add_theme_font_size_override("font_size", 21)
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(dialogue_label)

	var action_column := VBoxContainer.new()
	action_column.name = "RouteRivalDialogueActions"
	action_column.custom_minimum_size.x = 220.0
	action_column.alignment = BoxContainer.ALIGNMENT_END
	dialogue_row.add_child(action_column)
	continue_button = TOPDECK_UI.make_button(
		"CONTINUE  >",
		"primary",
		Vector2(220, 58),
		"BeginRouteEncounterButton"
	)
	continue_button.disabled = not (reduced_motion or automated_test)
	continue_button.pressed.connect(_on_continue_pressed)
	action_column.add_child(continue_button)


func _set_anchors(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.set_anchor(SIDE_LEFT, left)
	node.set_anchor(SIDE_TOP, top)
	node.set_anchor(SIDE_RIGHT, right)
	node.set_anchor(SIDE_BOTTOM, bottom)
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _play_entrance() -> void:
	if entrance_started or not is_inside_tree():
		return
	entrance_started = true
	await get_tree().process_frame
	if not is_instance_valid(portrait_stage) or not is_instance_valid(dialogue_panel):
		return
	var portrait_target_x := portrait_stage.position.x
	var dialogue_target_y := dialogue_panel.position.y
	dimmer.modulate.a = 0.0
	portrait_stage.position.x = portrait_target_x + maxf(size.x * 0.46, 560.0)
	portrait_stage.modulate.a = 0.72
	dialogue_panel.position.y = dialogue_target_y + 96.0
	dialogue_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.22)
	tween.tween_property(portrait_stage, "position:x", portrait_target_x, 0.48).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait_stage, "modulate:a", 1.0, 0.24)
	tween.tween_property(dialogue_panel, "position:y", dialogue_target_y, 0.34).set_delay(0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.22).set_delay(0.17)
	await tween.finished
	if is_instance_valid(continue_button):
		continue_button.disabled = false
		continue_button.grab_focus()


func _on_continue_pressed() -> void:
	if continue_button.disabled:
		return
	continue_button.disabled = true
	continue_requested.emit()


func wipe_to_cover() -> void:
	if is_instance_valid(wipe_layer):
		return
	wipe_layer = Control.new()
	wipe_layer.name = "RouteEncounterRightWipe"
	wipe_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wipe_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	wipe_layer.z_index = 100
	add_child(wipe_layer)

	var cover := ColorRect.new()
	cover.name = "RouteEncounterWipeCover"
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.color = PALETTE.CARBON
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wipe_layer.add_child(cover)

	var edge := ColorRect.new()
	edge.name = "RouteEncounterWipeEdge"
	edge.set_anchor(SIDE_LEFT, 1.0)
	edge.set_anchor(SIDE_TOP, 0.0)
	edge.set_anchor(SIDE_RIGHT, 1.0)
	edge.set_anchor(SIDE_BOTTOM, 1.0)
	edge.offset_left = -14.0
	edge.offset_right = 0.0
	edge.color = accent
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wipe_layer.add_child(edge)

	await get_tree().process_frame
	var travel_width := maxf(size.x, 960.0) + 24.0
	wipe_layer.position.x = -travel_width
	var tween := create_tween()
	tween.tween_property(wipe_layer, "position:x", 0.0, 0.34).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func reveal_after_cover() -> void:
	if not is_instance_valid(wipe_layer):
		return
	var travel_width := maxf(size.x, 960.0) + 24.0
	var tween := create_tween()
	tween.tween_property(wipe_layer, "position:x", travel_width, 0.34).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
