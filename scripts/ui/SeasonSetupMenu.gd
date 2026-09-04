extends Control
class_name SeasonSetupMenu

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const STARTER_SURFACE := preload("res://scripts/ui/StarterSelectionSurface.gd")
const CHARACTER_WASH_SHADER := preload("res://assets/shaders/character_select_wash.gdshader")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

signal back_requested
signal starter_selected_requested(index: int)
signal deck_list_requested(index: int)
signal previous_border_requested
signal next_border_requested
signal confirm_requested
signal difficulty_closed_requested

@onready var starter_art_mount: CenterContainer = %SelectedStarterArtMount
@onready var starter_symbol_mount: CenterContainer = %StarterInfoSymbolMount
@onready var difficulty_scrim: ColorRect = %DifficultyScrim
@onready var border_frame_preview: TextureRect = %BorderFramePreview
@onready var selected_product_pivot: Node3D = %SelectedProductPivot
@onready var shelf_viewport: SubViewport = $ShelfViewportContainer/ShelfViewport
@onready var selected_product_viewport: SubViewport = $DifficultyScrim/PreviewOverlay/PreviewColumn/SelectedProductViewportContainer/SelectedProductViewport
@onready var selected_product_container: SubViewportContainer = $DifficultyScrim/PreviewOverlay/PreviewColumn/SelectedProductViewportContainer

const BORDER_FRAME_TEXTURES: Array[Texture2D] = [
	preload("res://assets/season_setup/frames/black.png"),
	preload("res://assets/season_setup/frames/blue.png"),
	preload("res://assets/season_setup/frames/yellow.png"),
	preload("res://assets/season_setup/frames/silver.png"),
	preload("res://assets/season_setup/frames/gold.png"),
]
const STARTER_IDS := ["spicy", "hearty", "sweet"]
const STARTER_TITLES := ["SPICY", "HEARTY", "SWEET"]
const STARTER_TAGLINES := ["PRESSURE & TEMPO", "PROTECTION & RESILIENCE", "DRAW & CLEVER COMBOS"]
const STARTER_ACCENTS := [PALETTE.AFFINITY_SPICY, PALETTE.AFFINITY_HEARTY, PALETTE.AFFINITY_SWEET]
const STARTER_IDLE_ART: Array[Texture2D] = [
	preload("res://assets/overworld/player_idle.png"),
	preload("res://assets/overworld/hearty_player_idle.png"),
	preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
]
const STARTER_VICTORY_ART: Array[Texture2D] = [
	preload("res://assets/overworld/player_victory.png"),
	preload("res://assets/overworld/hearty_player_victory.png"),
	preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
]
const PRODUCT_SCENES: Array[PackedScene] = [
	preload("res://assets/season_setup/starter_spicy.tscn"),
	preload("res://assets/season_setup/starter_hearty.tscn"),
	preload("res://assets/season_setup/starter_sweet.tscn"),
	preload("res://assets/season_setup/booster_box.tscn"),
]
const PRODUCT_PREVIEW_ROTATION_SPEED := 0.78

var flow_root: Control
var panel_stage: Control
var panels: Array[Control] = []
var panel_surfaces: Array[Control] = []
var panel_art: Array[TextureRect] = []
var panel_details: Array[Control] = []
var panel_name_labels: Array[Label] = []
var panel_tagline_labels: Array[Label] = []
var deck_mounts: Array[Control] = []
var play_buttons: Array[Button] = []
var starter_profiles: Array = []
var selected_index := -1
var start_sequence := 0
var starting := false
var layout_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(0, 720)
	_flatten_display_lighting($ShelfViewportContainer/ShelfViewport/World)
	shelf_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	call_deferred("_freeze_static_shelf")
	%SeasonSetupBackButton.pressed.connect(back_requested.emit)
	%SpicyStarterButton.pressed.connect(func() -> void: select_starter(0))
	%HeartyStarterButton.pressed.connect(func() -> void: select_starter(1))
	%SweetStarterButton.pressed.connect(func() -> void: select_starter(2))
	%DraftNightButton.pressed.connect(func() -> void: starter_selected_requested.emit(3))
	%StarterDeckContentsButton.pressed.connect(func() -> void: deck_list_requested.emit(maxi(0, selected_index)))
	%PreviousBorderButton.pressed.connect(previous_border_requested.emit)
	%NextBorderButton.pressed.connect(next_border_requested.emit)
	%ConfirmSeasonStartButton.pressed.connect(_begin_selected_run)
	%CloseDifficultyButton.pressed.connect(_collapse_selection)
	_build_character_flow()


func _freeze_static_shelf() -> void:
	await RenderingServer.frame_post_draw
	if is_instance_valid(shelf_viewport):
		shelf_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(_delta: float) -> void:
	if selected_index >= 0:
		selected_product_pivot.rotation.y = _current_product_rotation()


func _build_character_flow() -> void:
	$ShelfViewportContainer.visible = false
	$NightColorGrade.visible = false
	$SeasonSetupBanner.visible = false
	$StarterButtons.visible = false
	difficulty_scrim.visible = false
	flow_root = Control.new()
	flow_root.name = "CharacterSelectionFlow"
	flow_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flow_root)
	var backdrop := ColorRect.new()
	backdrop.name = "CharacterSelectionBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = PALETTE.CARBON
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_root.add_child(backdrop)
	panel_stage = Control.new()
	panel_stage.name = "CharacterPanelStage"
	panel_stage.anchor_right = 1.0
	panel_stage.anchor_bottom = 1.0
	panel_stage.offset_top = 104.0
	flow_root.add_child(panel_stage)
	panel_stage.resized.connect(func() -> void: _layout_character_panels(false))
	for index in range(STARTER_IDS.size()):
		_build_character_panel(index)
	var title := Label.new()
	title.name = "CharacterSelectTitle"
	title.text = "CHOOSE YOUR PLAYER"
	title.position = Vector2(230, 16)
	title.size = Vector2(560, 48)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	flow_root.add_child(title)
	var prompt := Label.new()
	prompt.name = "CharacterSelectPrompt"
	prompt.text = "YOUR PLAYER SETS THE STARTER DECK AND CARD ECOSYSTEM"
	prompt.position = Vector2(232, 51)
	prompt.size = Vector2(680, 24)
	prompt.add_theme_font_override("font", BODY_FONT)
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.66))
	flow_root.add_child(prompt)
	var back_button := Button.new()
	back_button.name = "CharacterSelectBackButton"
	back_button.text = "‹  BACK"
	back_button.position = Vector2(16, 18)
	back_button.custom_minimum_size = Vector2(188, 48)
	back_button.size = Vector2(188, 48)
	back_button.add_theme_font_override("font", BODY_FONT)
	back_button.add_theme_font_size_override("font_size", 15)
	_apply_button_style(back_button, PALETTE.GRAPHITE, PALETTE.SELECTION_BLUE)
	back_button.pressed.connect(_handle_back)
	flow_root.add_child(back_button)
	call_deferred("_layout_character_panels", false)


func _build_character_panel(index: int) -> void:
	var panel := Control.new()
	panel.name = "%sCharacterPanel" % STARTER_TITLES[index].capitalize()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_stage.add_child(panel)
	panels.append(panel)
	var surface = STARTER_SURFACE.new()
	surface.name = "PanelSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.accent = STARTER_ACCENTS[index]
	surface.side = index - 1
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(surface)
	panel_surfaces.append(surface)
	var art := TextureRect.new()
	art.name = "%sPlayerArtwork" % STARTER_TITLES[index].capitalize()
	art.texture = STARTER_IDLE_ART[index]
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wash_material := ShaderMaterial.new()
	wash_material.shader = CHARACTER_WASH_SHADER
	art.material = wash_material
	panel.add_child(art)
	panel_art.append(art)
	var name_label := Label.new()
	name_label.name = "CharacterName"
	name_label.text = STARTER_TITLES[index]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", DISPLAY_FONT)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_label)
	panel_name_labels.append(name_label)
	var tagline := Label.new()
	tagline.name = "CharacterTagline"
	tagline.text = STARTER_TAGLINES[index]
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_override("font", BODY_FONT)
	tagline.add_theme_font_size_override("font_size", 13)
	tagline.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.72))
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tagline)
	panel_tagline_labels.append(tagline)
	var hit := Button.new()
	hit.name = "Select%sButton" % STARTER_TITLES[index].capitalize()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var captured_index := index
	hit.mouse_entered.connect(func() -> void: _set_panel_hover(captured_index, true))
	hit.mouse_exited.connect(func() -> void: _set_panel_hover(captured_index, false))
	hit.pressed.connect(func() -> void: select_starter(captured_index))
	panel.add_child(hit)
	var details := _build_selected_details(index)
	panel.add_child(details)
	panel_details.append(details)


func _build_selected_details(index: int) -> Control:
	var details := Control.new()
	details.name = "Selected%sDeckDetails" % STARTER_TITLES[index].capitalize()
	details.anchor_left = 0.45
	details.anchor_top = 0.12
	details.anchor_right = 0.96
	details.anchor_bottom = 0.94
	details.visible = false
	var eyebrow := Label.new()
	eyebrow.name = "DeckEyebrow"
	eyebrow.text = "STARTER DECK"
	eyebrow.position = Vector2(0, 0)
	eyebrow.size = Vector2(330, 25)
	eyebrow.add_theme_font_override("font", BODY_FONT)
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.68))
	details.add_child(eyebrow)
	var deck_title := Label.new()
	deck_title.name = "DeckTitle"
	deck_title.position = Vector2(0, 22)
	deck_title.size = Vector2(390, 48)
	deck_title.add_theme_font_override("font", DISPLAY_FONT)
	deck_title.add_theme_font_size_override("font_size", 34)
	deck_title.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	details.add_child(deck_title)
	var description := Label.new()
	description.name = "DeckDescription"
	description.position = Vector2(0, 72)
	description.size = Vector2(390, 100)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_override("font", BODY_FONT)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.9))
	details.add_child(description)
	var deck_mount := Control.new()
	deck_mount.name = "RotatingDeckBoxMount"
	deck_mount.anchor_top = 0.31
	deck_mount.anchor_right = 0.52
	deck_mount.anchor_bottom = 0.64
	deck_mount.clip_contents = true
	deck_mount.mouse_filter = Control.MOUSE_FILTER_PASS
	details.add_child(deck_mount)
	deck_mounts.append(deck_mount)
	var box_back := Panel.new()
	box_back.name = "DeckBoxChassis"
	box_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(PALETTE.GRAPHITE, 0.86)
	box_style.border_color = PALETTE.CARBON
	box_style.set_border_width_all(3)
	box_style.set_corner_radius_all(4)
	box_back.add_theme_stylebox_override("panel", box_style)
	deck_mount.add_child(box_back)
	var deck_button := Button.new()
	deck_button.name = "StarterDeckBoxButton_%s" % STARTER_IDS[index]
	deck_button.tooltip_text = "View deck contents"
	deck_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_button.flat = true
	deck_button.focus_mode = Control.FOCUS_ALL
	deck_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	deck_button.add_theme_stylebox_override("hover", _outline_style(PALETTE.ELECTRIC_CYAN, 4))
	deck_button.add_theme_stylebox_override("focus", _outline_style(PALETTE.ELECTRIC_CYAN, 4))
	deck_button.add_theme_stylebox_override("pressed", _outline_style(PALETTE.COOL_WHITE, 4))
	deck_button.pressed.connect(func() -> void: deck_list_requested.emit(index))
	deck_mount.add_child(deck_button)
	var deck_hint := Label.new()
	deck_hint.name = "DeckBoxHint"
	deck_hint.text = "CLICK TO VIEW DECK"
	deck_hint.anchor_top = 0.65
	deck_hint.anchor_right = 0.52
	deck_hint.anchor_bottom = 0.71
	deck_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_hint.add_theme_font_override("font", BODY_FONT)
	deck_hint.add_theme_font_size_override("font_size", 12)
	deck_hint.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	deck_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(deck_hint)
	var stats := Label.new()
	stats.name = "DeckStats"
	stats.anchor_left = 0.56
	stats.anchor_top = 0.43
	stats.anchor_right = 1.0
	stats.anchor_bottom = 0.64
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_override("font", BODY_FONT)
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(PALETTE.COOL_WHITE, 0.76))
	stats.visible = false
	details.add_child(stats)
	var play := Button.new()
	play.name = "Play%sButton" % STARTER_TITLES[index].capitalize()
	play.text = "PLAY  ›"
	play.anchor_top = 0.76
	play.anchor_right = 0.52
	play.anchor_bottom = 0.95
	play.add_theme_font_override("font", DISPLAY_FONT)
	play.add_theme_font_size_override("font_size", 29)
	_apply_button_style(play, PALETTE.GRAPHITE, PALETTE.EMERALD)
	play.pressed.connect(func() -> void: _begin_selected_run(index))
	details.add_child(play)
	play_buttons.append(play)
	return details


func configure(data: Dictionary, starter_art: Control) -> void:
	starter_profiles = data.get("starter_profiles", [])
	%DraftNightButton.visible = false
	for child in starter_art_mount.get_children():
		child.queue_free()
	starter_art_mount.add_child(starter_art)
	for child in starter_symbol_mount.get_children():
		child.queue_free()
	%SeasonStarterCard.set_meta("starter_id", String(data.get("starter_id", "")))
	%SeasonBorderCard.set_meta("difficulty_id", String(data.get("difficulty_id", "white")))
	%StarterNameLabel.text = String(data.get("starter_title", "")).to_upper()
	%StarterInfoTitle.text = String(data.get("info_title", ""))
	%StarterInfoDetail.text = String(data.get("info_detail", ""))
	%BorderTitle.text = "STARTER CITY RUN"
	%BorderRules.text = String(data.get("difficulty_rules", ""))
	%BorderStats.text = String(data.get("border_stats", ""))
	%RouteHint.text = String(data.get("route_hint", "STARTS IN STARTER CITY"))
	difficulty_scrim.visible = false
	var selected_difficulty := int(data.get("difficulty_index", 0))
	border_frame_preview.texture = BORDER_FRAME_TEXTURES[clampi(selected_difficulty, 0, BORDER_FRAME_TEXTURES.size() - 1)]
	selected_index = int(data.get("starter_index", 0)) if bool(data.get("difficulty_open", false)) else -1
	if selected_index >= STARTER_IDS.size():
		selected_index = -1
	_refresh_profile_copy()
	_refresh_character_states()
	_configure_product_preview(selected_index)
	selected_product_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if selected_index >= 0 else SubViewport.UPDATE_DISABLED
	_layout_character_panels(false)


func get_symbol_mount() -> CenterContainer:
	return starter_symbol_mount


func select_starter(index: int, animate := true) -> void:
	if index < 0 or index >= STARTER_IDS.size():
		return
	_cancel_start_sequence()
	selected_index = index
	starter_selected_requested.emit(index)
	_refresh_profile_copy()
	_refresh_character_states()
	_configure_product_preview(index)
	selected_product_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_layout_character_panels(animate)


func _collapse_selection() -> void:
	if selected_index < 0:
		return
	_cancel_start_sequence()
	selected_index = -1
	difficulty_closed_requested.emit()
	_refresh_character_states()
	_configure_product_preview(-1)
	selected_product_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_layout_character_panels(true)


func _handle_back() -> void:
	if selected_index >= 0:
		_collapse_selection()
	else:
		back_requested.emit()


func _begin_selected_run(requested_index := -1) -> void:
	if requested_index >= 0 and requested_index != selected_index:
		select_starter(requested_index)
		return
	if selected_index < 0 or starting:
		return
	starting = true
	start_sequence += 1
	var sequence := start_sequence
	panel_art[selected_index].texture = STARTER_VICTORY_ART[selected_index]
	play_buttons[selected_index].text = "LET'S GO!"
	play_buttons[selected_index].disabled = true
	var celebration_target: Control = panel_art[selected_index]
	var bounce := create_tween()
	bounce.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.tween_property(celebration_target, "scale", Vector2(1.055, 1.055), 0.18)
	bounce.tween_property(celebration_target, "scale", Vector2.ONE, 0.18)
	await get_tree().create_timer(0.72).timeout
	if starting and sequence == start_sequence and selected_index >= 0:
		confirm_requested.emit()


func _cancel_start_sequence() -> void:
	start_sequence += 1
	starting = false
	for index in range(panel_art.size()):
		panel_art[index].texture = STARTER_IDLE_ART[index]
		panel_art[index].scale = Vector2.ONE
		play_buttons[index].text = "PLAY  ›"
		play_buttons[index].disabled = false


func _refresh_profile_copy() -> void:
	for index in range(panel_details.size()):
		var profile: Dictionary = starter_profiles[index] if index < starter_profiles.size() else {}
		var details := panel_details[index]
		(details.get_node("DeckTitle") as Label).text = String(profile.get("deck_title", "%s DECK" % STARTER_TITLES[index]))
		(details.get_node("DeckDescription") as Label).text = String(profile.get("description", STARTER_TAGLINES[index]))
		(details.get_node("DeckStats") as Label).text = String(profile.get("detail", "15-card starter\n40 persistent life"))


func _refresh_character_states() -> void:
	for index in range(panels.size()):
		var active := index == selected_index
		panel_surfaces[index].selected = active
		panel_details[index].visible = active
		panel_name_labels[index].visible = not active
		panel_tagline_labels[index].visible = not active
		var material := panel_art[index].material as ShaderMaterial
		material.set_shader_parameter("washout", 0.18 if active else 0.58)
		material.set_shader_parameter("brightness", 0.92 if active else 0.62)
		panels[index].z_index = 3 if active else index
	if selected_index >= 0:
		_move_product_viewport(selected_index)


func _layout_character_panels(animate: bool) -> void:
	if panel_stage == null or panels.size() != 3:
		return
	var width := panel_stage.size.x
	var height := panel_stage.size.y
	if width < 100.0 or height < 100.0:
		return
	var targets: Array[Rect2] = []
	if selected_index < 0:
		var third := width / 3.0
		targets = [Rect2(0, 0, third + 30.0, height), Rect2(third - 15.0, 0, third + 30.0, height), Rect2(third * 2.0 - 30.0, 0, third + 30.0, height)]
	elif selected_index == 0:
		targets = [Rect2(0, 0, width * 0.70, height), Rect2(width * 0.66, 0, width * 0.20, height), Rect2(width * 0.82, 0, width * 0.18, height)]
	elif selected_index == 1:
		targets = [Rect2(0, 0, width * 0.19, height), Rect2(width * 0.15, 0, width * 0.70, height), Rect2(width * 0.81, 0, width * 0.19, height)]
	else:
		targets = [Rect2(0, 0, width * 0.18, height), Rect2(width * 0.14, 0, width * 0.20, height), Rect2(width * 0.30, 0, width * 0.70, height)]
	if layout_tween != null and layout_tween.is_valid():
		layout_tween.kill()
	if animate:
		layout_tween = create_tween().set_parallel(true)
		layout_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	for index in range(panels.size()):
		var target := targets[index]
		if animate:
			layout_tween.tween_property(panels[index], "position", target.position, 0.34)
			layout_tween.tween_property(panels[index], "size", target.size, 0.34)
		else:
			panels[index].position = target.position
			panels[index].size = target.size
		_layout_panel_contents(index, target.size)


func _layout_panel_contents(index: int, panel_size: Vector2) -> void:
	var active := index == selected_index
	var art := panel_art[index]
	if active:
		art.position = Vector2(panel_size.x * 0.03, panel_size.y * 0.08)
		art.size = Vector2(panel_size.x * 0.43, panel_size.y * 0.86)
	else:
		art.position = Vector2(panel_size.x * 0.08, panel_size.y * 0.12)
		art.size = Vector2(panel_size.x * 0.84, panel_size.y * 0.73)
	panel_name_labels[index].position = Vector2(28, panel_size.y - 100)
	panel_name_labels[index].size = Vector2(maxf(40.0, panel_size.x - 56.0), 40)
	panel_tagline_labels[index].position = Vector2(24, panel_size.y - 62)
	panel_tagline_labels[index].size = Vector2(maxf(40.0, panel_size.x - 48.0), 28)


func _set_panel_hover(index: int, hovered: bool) -> void:
	if index >= 0 and index < panel_surfaces.size():
		panel_surfaces[index].hovered = hovered


func _move_product_viewport(index: int) -> void:
	if index < 0 or index >= deck_mounts.size():
		return
	if selected_product_container.get_parent() != deck_mounts[index]:
		selected_product_container.reparent(deck_mounts[index])
	selected_product_container.custom_minimum_size = Vector2.ZERO
	selected_product_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selected_product_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_product_container.show()
	var product_camera := selected_product_viewport.get_node("SelectedProductWorld/SelectedProductCamera") as Camera3D
	product_camera.size = 4.05
	deck_mounts[index].move_child(selected_product_container, 1)


func _configure_product_preview(index: int) -> void:
	for child in selected_product_pivot.get_children():
		selected_product_pivot.remove_child(child)
		child.queue_free()
	selected_product_pivot.rotation = Vector3(0, _current_product_rotation(), 0)
	if index < 0 or index >= PRODUCT_SCENES.size():
		selected_product_container.hide()
		return
	selected_product_container.show()
	var product := PRODUCT_SCENES[index].instantiate() as Node3D
	selected_product_pivot.add_child(product)
	product.rotation_degrees = Vector3(0, -90, 0)
	_flatten_display_lighting(product)
	_fit_product_to_preview(product)


func _current_product_rotation() -> float:
	return fmod(Time.get_ticks_msec() * 0.001 * PRODUCT_PREVIEW_ROTATION_SPEED, TAU)


func _fit_product_to_preview(product: Node3D) -> void:
	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_preview_meshes(product, mesh_nodes)
	if mesh_nodes.is_empty():
		return
	var pivot_inverse := selected_product_pivot.global_transform.affine_inverse()
	var bounds := AABB()
	var has_point := false
	for mesh_node in mesh_nodes:
		var mesh_to_pivot := pivot_inverse * mesh_node.global_transform
		var mesh_bounds := mesh_node.get_aabb()
		for endpoint_index in range(8):
			var point := mesh_to_pivot * mesh_bounds.get_endpoint(endpoint_index)
			if has_point:
				bounds = bounds.expand(point)
			else:
				bounds = AABB(point, Vector3.ZERO)
				has_point = true
	var widest_side := maxf(bounds.size.x, bounds.size.z)
	var fit_scale := minf(2.45 / maxf(bounds.size.y, 0.001), 2.55 / maxf(widest_side, 0.001))
	product.scale = Vector3.ONE * fit_scale
	product.position = -bounds.get_center() * fit_scale


func _collect_preview_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_preview_meshes(child, meshes)


func _flatten_display_lighting(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh_instance.material_override is BaseMaterial3D:
			var flat_override := mesh_instance.material_override.duplicate() as BaseMaterial3D
			flat_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh_instance.material_override = flat_override
		elif mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material := mesh_instance.get_active_material(surface_index)
				if source_material is BaseMaterial3D:
					var flat_surface := source_material.duplicate() as BaseMaterial3D
					flat_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mesh_instance.set_surface_override_material(surface_index, flat_surface)
	for child in node.get_children():
		_flatten_display_lighting(child)


func _apply_button_style(button: Button, normal_color: Color, active_color: Color) -> void:
	button.add_theme_color_override("font_color", PALETTE.COOL_WHITE)
	button.add_theme_color_override("font_hover_color", PALETTE.COOL_WHITE)
	button.add_theme_color_override("font_pressed_color", PALETTE.COOL_WHITE)
	button.add_theme_color_override("font_disabled_color", Color(PALETTE.COOL_WHITE, 0.72))
	button.add_theme_stylebox_override("normal", _button_style(normal_color, PALETTE.CARBON, 3))
	button.add_theme_stylebox_override("hover", _button_style(active_color, PALETTE.COOL_WHITE, 3))
	button.add_theme_stylebox_override("focus", _button_style(active_color, PALETTE.ELECTRIC_CYAN, 3))
	button.add_theme_stylebox_override("pressed", _button_style(active_color.darkened(0.16), PALETTE.COOL_WHITE, 3))
	button.add_theme_stylebox_override("disabled", _button_style(PALETTE.STEEL, PALETTE.CARBON, 3))


func _button_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(PALETTE.TRUE_BLACK, 0.42)
	style.shadow_size = 4
	style.shadow_offset = Vector2(4, 4)
	return style


func _outline_style(color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.08)
	style.border_color = color
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	return style
