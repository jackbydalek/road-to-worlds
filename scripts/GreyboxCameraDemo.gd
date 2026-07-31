extends Control

signal exit_requested
signal packs_requested
signal tournament_requested
signal deck_requested
signal calendar_requested
signal save_requested
signal settings_requested
signal single_purchase_requested(card_id: String)
signal trade_extras_requested

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const WORKSPACE_UI := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")

const OVERVIEW_SIZE := 11.5
const SHOPKEEPER_SIZE := 4.0
const SHOPKEEPER_FOCUS_HEIGHT := 1.55
const SHOPKEEPER_CAMERA_OFFSET := Vector3(0.85, 0.55, 5.5)
const SHOPKEEPER_ARROW_HEIGHT := 2.45
const SHOPKEEPER_ARROW_BOB_DISTANCE := 12.0
const TRANSITION_SECONDS := 0.75
const CARD_HOVER_DELAY_SECONDS := 0.38

@onready var camera_rig: Node3D = $ViewportContainer/SubViewport/World/CameraRig
@onready var camera: Camera3D = $ViewportContainer/SubViewport/World/CameraRig/Camera3D
@onready var shopkeeper_model: Node3D = $ViewportContainer/SubViewport/World/NPC/ShopkeeperModel
@onready var overview_target: Marker3D = $ViewportContainer/SubViewport/World/CameraTargets/OverviewTarget
@onready var menu_target: Marker3D = $ViewportContainer/SubViewport/World/CameraTargets/MenuTarget
@onready var shot_label: Label = $Interface/TopBar/TopMargin/TopContent/ShotLabel
@onready var top_bar: PanelContainer = $Interface/TopBar
@onready var cash_hud_button: Button = $Interface/ShopHud/CashButton
@onready var deck_hud_button: Button = $Interface/ShopHud/DeckButton
@onready var save_hud_button: Button = $Interface/ShopHud/SaveButton
@onready var settings_hud_button: Button = $Interface/ShopHud/SettingsButton
@onready var menu_panel: PanelContainer = $Interface/MenuPanel
@onready var menu_content: VBoxContainer = $Interface/MenuPanel/Margin/Content
@onready var menu_heading: Label = $Interface/MenuPanel/Margin/Content/Heading
@onready var menu_description: Label = $Interface/MenuPanel/Margin/Content/Description
@onready var station_panel: PanelContainer = $Interface/CombatPanel
@onready var station_heading: Label = $Interface/CombatPanel/Margin/Content/Heading
@onready var station_description: Label = $Interface/CombatPanel/Margin/Content/Explanation
@onready var buy_singles_button: Button = $Interface/MenuPanel/Margin/Content/BuySingles
@onready var buy_pack_button: Button = $Interface/MenuPanel/Margin/Content/BuyPack
@onready var meta_menu_button: Button = $Interface/MenuPanel/Margin/Content/Meta
@onready var calendar_menu_button: Button = $Interface/MenuPanel/Margin/Content/Calendar
@onready var leave_menu_button: Button = $Interface/MenuPanel/Margin/Content/Leave
@onready var overview_round_button: Button = $Interface/OverviewRoundButton

var camera_tween: Tween
var overlay_tween: Tween
var transition_generation := 0
var shop_context: Dictionary = {}
var station_actions: VBoxContainer
var singles_panel: PanelContainer
var singles_grid: GridContainer
var singles_wallet_label: Label
var singles_message_label: Label
var trade_panel: PanelContainer
var trade_list: VBoxContainer
var trade_wallet_label: Label
var trade_message_label: Label
var trade_action_button: Button
var meta_panel: PanelContainer
var meta_list: VBoxContainer
var meta_report_list: VBoxContainer
var shopkeeper_hotspot: Button
var shopkeeper_arrow: Control
var shopkeeper_arrow_tween: Tween
var overview_round_tween: Tween
var shopkeeper_highlight_material: StandardMaterial3D
var shopkeeper_original_overlays: Dictionary = {}
var shopkeeper_hover_enabled := true
var overview_active := true
var selected_single_id := ""
var menu_cash_status_label: Label
var menu_prize_status_label: Label
var external_overlay: Control
var card_hover_preview: PanelContainer
var card_hover_preview_body: CenterContainer
var card_hover_request_id := 0


func _ready() -> void:
	cash_hud_button.name = "ShopHudCashButton"
	deck_hud_button.name = "ShopHudDeckButton"
	save_hud_button.name = "ShopHudSaveButton"
	settings_hud_button.name = "ShopHudSettingsButton"
	_style_store_top_bar()
	_style_shop_hud_buttons()
	_style_shopkeeper_menu()
	cash_hud_button.pressed.connect(func() -> void: trade_extras_requested.emit())
	deck_hud_button.pressed.connect(func() -> void: deck_requested.emit())
	save_hud_button.pressed.connect(func() -> void: save_requested.emit())
	settings_hud_button.pressed.connect(func() -> void: settings_requested.emit())
	buy_singles_button.pressed.connect(_show_singles_case)
	buy_pack_button.pressed.connect(func() -> void: packs_requested.emit())
	meta_menu_button.pressed.connect(_show_meta_analysis)
	calendar_menu_button.pressed.connect(func() -> void: calendar_requested.emit())
	leave_menu_button.text = "Back to Store"
	leave_menu_button.pressed.connect(_show_overview)
	overview_round_button.name = "StoreOverviewRoundButton"
	overview_round_button.pressed.connect(func() -> void: tournament_requested.emit())
	_add_station_actions_container()
	_add_singles_panel()
	_add_trade_panel()
	_add_meta_panel()
	_add_card_hover_preview()
	_add_world_hotspots()
	_start_shopkeeper_idle()
	camera_rig.global_transform = overview_target.global_transform
	camera.size = OVERVIEW_SIZE
	menu_panel.visible = false
	station_panel.visible = false
	shot_label.text = _overview_description()
	_apply_shop_context()
	_render_singles_case()
	_render_trade_binder()
	_render_meta_analysis()
	resized.connect(_position_shopkeeper_hotspot)
	call_deferred("_position_shopkeeper_hotspot")


func _exit_tree() -> void:
	if overview_round_tween != null and overview_round_tween.is_valid():
		overview_round_tween.kill()


func _style_shop_hud_buttons() -> void:
	for button in [cash_hud_button, deck_hud_button, save_hud_button, settings_hud_button]:
		button.add_theme_stylebox_override(
			"normal",
			WORKSPACE_UI.clean_style(
				WORKSPACE_UI.TEAL_SOFT if button == cash_hud_button else WORKSPACE_UI.SURFACE,
				WORKSPACE_UI.TEAL if button == cash_hud_button else WORKSPACE_UI.BORDER_SOFT,
				1,
				7,
				Vector4(10, 7, 10, 7)
			)
		)
		button.add_theme_stylebox_override(
			"hover",
			WORKSPACE_UI.clean_style(
				WORKSPACE_UI.MUSTARD_SOFT,
				WORKSPACE_UI.MUSTARD.darkened(0.18),
				1,
				7,
				Vector4(10, 7, 10, 7)
			)
		)
		button.add_theme_stylebox_override(
			"pressed",
			WORKSPACE_UI.clean_style(
				WORKSPACE_UI.MUSTARD_SOFT.darkened(0.06),
				WORKSPACE_UI.TEAL,
				2,
				7,
				Vector4(10, 8, 10, 6)
			)
		)
		button.add_theme_stylebox_override(
			"focus",
			WORKSPACE_UI.clean_style(Color.TRANSPARENT, WORKSPACE_UI.TEAL, 2, 7)
		)
		button.add_theme_color_override("font_color", Color("#10141b"))
		button.add_theme_color_override("font_hover_color", Color("#10141b"))
		button.add_theme_color_override("font_pressed_color", Color("#10141b"))
		button.add_theme_font_override("font", SKETCH_UI.body_font(0.56))
	for icon_button in [deck_hud_button, save_hud_button, settings_hud_button]:
		icon_button.add_theme_constant_override("icon_max_width", 24)


func _style_store_top_bar() -> void:
	top_bar.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			Color("#FFFCF6F2"),
			WORKSPACE_UI.BORDER_SOFT,
			1,
			8,
			Vector4.ZERO,
			4,
			true
		)
	)
	shot_label.add_theme_font_override("font", SKETCH_UI.body_font(0.48))
	shot_label.add_theme_font_size_override("font_size", 16)
	shot_label.add_theme_color_override("font_color", SKETCH_UI.INK)


func _style_shopkeeper_menu() -> void:
	menu_panel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.SURFACE,
			SKETCH_UI.TEAL,
			1,
			12,
			Vector4.ZERO,
			5,
			true
		)
	)
	menu_content.add_theme_constant_override("separation", 10)
	menu_heading.add_theme_font_override("font", SKETCH_UI.body_font(0.72))
	menu_heading.add_theme_font_size_override("font_size", 30)
	menu_heading.add_theme_color_override("font_color", SKETCH_UI.INK)
	menu_description.add_theme_font_override("font", SKETCH_UI.body_font(0.3))
	menu_description.add_theme_font_size_override("font_size", 14)
	menu_description.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)

	var status_row := HBoxContainer.new()
	status_row.name = "ShopkeeperStatus"
	status_row.add_theme_constant_override("separation", 8)
	menu_content.add_child(status_row)
	menu_content.move_child(status_row, menu_description.get_index() + 1)
	menu_cash_status_label = _add_shopkeeper_status_badge(status_row, "Cash")
	menu_prize_status_label = _add_shopkeeper_status_badge(status_row, "Prize packs")

	var buy_section := _make_shopkeeper_section_label("BUY CARDS")
	menu_content.add_child(buy_section)
	menu_content.move_child(buy_section, buy_singles_button.get_index())

	var plan_section := _make_shopkeeper_section_label("PLAN YOUR WEEK")
	menu_content.add_child(plan_section)
	menu_content.move_child(plan_section, meta_menu_button.get_index())

	var exit_separator := HSeparator.new()
	exit_separator.name = "ShopkeeperExitSeparator"
	exit_separator.add_theme_constant_override("separation", 4)
	exit_separator.add_theme_stylebox_override(
		"separator",
		WORKSPACE_UI.clean_style(Color("#DDD3C4"), Color.TRANSPARENT, 0, 0)
	)
	menu_content.add_child(exit_separator)
	menu_content.move_child(exit_separator, leave_menu_button.get_index())

	_style_shopkeeper_action(buy_singles_button, "primary", "Choose from eight individual cards")
	_style_shopkeeper_action(buy_pack_button, "target", "Open a sealed booster pack")
	_style_shopkeeper_action(meta_menu_button, "secondary", "Review the local archetype field")
	_style_shopkeeper_action(calendar_menu_button, "secondary", "See this season's upcoming events")
	_style_shopkeeper_action(leave_menu_button, "secondary", "Return to the store floor")
	_style_overview_round_button()


func _add_shopkeeper_status_badge(parent: HBoxContainer, title: String) -> Label:
	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			WORKSPACE_UI.TEAL_SOFT,
			SKETCH_UI.TEAL,
			1,
			6,
			Vector4(10, 6, 10, 6)
		)
	)
	parent.add_child(badge)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", SKETCH_UI.body_font(0.5))
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", SKETCH_UI.TEAL.darkened(0.22))
	badge.add_child(label)
	return label


func _make_shopkeeper_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", SKETCH_UI.body_font(0.62))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", SKETCH_UI.TEAL)
	return label


func _style_shopkeeper_action(button: Button, variant: String, tooltip: String) -> void:
	WORKSPACE_UI.style_button(button, variant)
	button.custom_minimum_size = Vector2(0, 46)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", SKETCH_UI.body_font(0.56))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_constant_override("outline_size", 0)
	button.tooltip_text = tooltip


func _style_overview_round_button() -> void:
	overview_round_button.custom_minimum_size = Vector2(500, 84)
	overview_round_button.add_theme_font_override("font", SKETCH_UI.body_font(0.8))
	overview_round_button.add_theme_font_size_override("font_size", 28)
	overview_round_button.add_theme_color_override("font_color", WORKSPACE_UI.INK)
	overview_round_button.add_theme_color_override("font_hover_color", WORKSPACE_UI.INK)
	overview_round_button.add_theme_color_override("font_pressed_color", WORKSPACE_UI.INK)
	overview_round_button.add_theme_color_override("font_focus_color", WORKSPACE_UI.INK)
	overview_round_button.add_theme_color_override("font_disabled_color", WORKSPACE_UI.MUTED_INK)
	var normal := WORKSPACE_UI.clean_style(
		Color("#F4C95D"),
		SKETCH_UI.TEAL.darkened(0.28),
		3,
		14,
		Vector4(34, 18, 34, 19),
		6,
		true
	)
	normal.shadow_color = Color(0.08, 0.07, 0.05, 0.34)
	normal.shadow_size = 13
	normal.shadow_offset = Vector2(0, 6)
	overview_round_button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#FFDA78")
	hover.border_color = SKETCH_UI.ORANGE
	hover.set_border_width_all(4)
	hover.border_width_left = 7
	hover.shadow_color = Color(SKETCH_UI.MUSTARD.r, SKETCH_UI.MUSTARD.g, SKETCH_UI.MUSTARD.b, 0.42)
	hover.shadow_size = 16
	overview_round_button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#E8B94C")
	pressed.border_color = SKETCH_UI.TEAL.darkened(0.18)
	pressed.content_margin_top = 21
	pressed.content_margin_bottom = 16
	pressed.shadow_size = 5
	pressed.shadow_offset = Vector2(0, 2)
	overview_round_button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#D8CFB6")
	disabled.border_color = WORKSPACE_UI.BORDER_SOFT
	disabled.shadow_size = 3
	overview_round_button.add_theme_stylebox_override("disabled", disabled)
	overview_round_button.add_theme_stylebox_override(
		"focus",
		WORKSPACE_UI.clean_style(Color.TRANSPARENT, Color.WHITE, 4, 14)
	)
	overview_round_button.tooltip_text = "Start the next tournament match."


func _update_overview_round_button() -> void:
	if overview_round_button == null:
		return
	var tournament_active := bool(shop_context.get("tournament_active", false))
	var tournament_round := int(shop_context.get("tournament_round", 1))
	overview_round_button.text = "START ROUND %d   →" % tournament_round
	overview_round_button.tooltip_text = (
		"Start the next tournament match."
		if tournament_active
		else "Register for the selected tournament and start Round 1."
	)
	overview_round_button.visible = overview_active
	call_deferred("_refresh_overview_round_attention")


func _refresh_overview_round_attention() -> void:
	if overview_round_tween != null and overview_round_tween.is_valid():
		overview_round_tween.kill()
	overview_round_button.scale = Vector2.ONE
	if not overview_round_button.visible or bool(get_tree().root.get_meta("reduced_motion", false)):
		return
	overview_round_button.pivot_offset = overview_round_button.size * 0.5
	overview_round_tween = create_tween().set_loops()
	overview_round_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	overview_round_tween.tween_property(overview_round_button, "scale", Vector2(1.014, 1.014), 0.82)
	overview_round_tween.tween_property(overview_round_button, "scale", Vector2.ONE, 0.82)


func _start_shopkeeper_idle() -> void:
	if shopkeeper_model == null:
		return
	var animation_player := shopkeeper_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null:
		return
	var animations := animation_player.get_animation_list()
	if animations.is_empty():
		return
	var idle_name: StringName = &"Animation" if animation_player.has_animation(&"Animation") else animations[0]
	var idle_animation := animation_player.get_animation(idle_name)
	if idle_animation != null:
		idle_animation.loop_mode = Animation.LOOP_LINEAR
	animation_player.play(idle_name)


func configure_shop(context: Dictionary) -> void:
	shop_context = context.duplicate(true)
	if is_node_ready():
		_apply_shop_context()
		_render_singles_case()
		_render_trade_binder()
		_render_meta_analysis()


func update_shop_context(context: Dictionary, message: String = "", message_target: String = "singles") -> void:
	shop_context = context.duplicate(true)
	_apply_shop_context()
	_render_singles_case(message if message_target == "singles" else "")
	_render_trade_binder(message if message_target == "trade" else "")
	_render_meta_analysis()


func current_menu_view() -> String:
	if external_overlay != null and external_overlay.visible:
		return "packs"
	if singles_panel != null and singles_panel.visible:
		return "singles"
	if trade_panel != null and trade_panel.visible:
		return "trade"
	if meta_panel != null and meta_panel.visible:
		return "meta"
	if menu_panel.visible:
		return "shopkeeper"
	return "overview"


func restore_menu_view(view: String) -> void:
	if view == "overview":
		return
	transition_generation += 1
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	_hide_overlays()
	overview_active = false
	_update_overview_round_button()
	shopkeeper_hover_enabled = false
	_set_shopkeeper_highlighted(false)
	if shopkeeper_arrow != null:
		shopkeeper_arrow.visible = false

	var focus_point := shopkeeper_model.global_position + Vector3(0, SHOPKEEPER_FOCUS_HEIGHT, 0)
	menu_target.global_position = focus_point + SHOPKEEPER_CAMERA_OFFSET
	menu_target.look_at(focus_point, Vector3.UP)
	camera_rig.global_transform = menu_target.global_transform
	camera.size = SHOPKEEPER_SIZE

	match view:
		"singles":
			shot_label.text = "SINGLES CASE — buy cards without leaving the store"
			singles_panel.visible = true
			singles_panel.modulate.a = 1.0
		"trade":
			_render_trade_binder()
			shot_label.text = "TRADE BINDER — review safe extras without leaving the store"
			trade_panel.visible = true
			trade_panel.modulate.a = 1.0
		"meta":
			_render_meta_analysis()
			shot_label.text = "META ANALYSIS — local field shares and shop talk"
			meta_panel.visible = true
			meta_panel.modulate.a = 1.0
		_:
			shot_label.text = "SHOPKEEPER — packs, singles, trades, meta, and events"
			menu_panel.visible = true
			menu_panel.modulate.a = 1.0


func _apply_shop_context() -> void:
	if shot_label == null:
		return
	var event_name := String(shop_context.get("event_name", "Weekly Locals"))
	var money := int(shop_context.get("money", 0))
	var prize_packs := int(shop_context.get("prize_packs", 0))
	var difficulty := String(shop_context.get("difficulty_name", "Black"))
	cash_hud_button.text = "$%d" % money
	_update_overview_round_button()
	menu_description.text = "%s  •  %s frame" % [event_name, difficulty]
	if menu_cash_status_label != null:
		menu_cash_status_label.text = "$%d cash" % money
	if menu_prize_status_label != null:
		menu_prize_status_label.text = "%d prize pack%s" % [prize_packs, "" if prize_packs == 1 else "s"]
	if not menu_panel.visible and not station_panel.visible and (singles_panel == null or not singles_panel.visible) and (trade_panel == null or not trade_panel.visible) and (meta_panel == null or not meta_panel.visible):
		shot_label.text = "CARD STORE  •  %s frame  •  %s  •  %d prize pack(s)" % [difficulty, event_name, prize_packs]


func _overview_description() -> String:
	return "CARD STORE  •  click the shopkeeper"


func _add_station_actions_container() -> void:
	station_actions = VBoxContainer.new()
	station_actions.name = "StationActions"
	station_actions.add_theme_constant_override("separation", 8)
	$Interface/CombatPanel/Margin/Content.add_child(station_actions)


func show_external_overlay(overlay: Control, description: String) -> void:
	_hide_overlays()
	overview_active = false
	_update_overview_round_button()
	shopkeeper_hover_enabled = false
	_set_shopkeeper_highlighted(false)
	if shopkeeper_arrow != null:
		shopkeeper_arrow.visible = false
	external_overlay = overlay
	shot_label.text = description
	_fade_in_overlay(overlay)


func close_external_overlay(overlay: Control) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	if external_overlay == overlay:
		external_overlay = null
	_return_to_shopkeeper_menu()


func _add_card_hover_preview() -> void:
	card_hover_preview = SKETCH_UI.make_rough_panel(
		Vector2(326, 466), SKETCH_UI.PAPER, SKETCH_UI.INK, SKETCH_UI.TEAL, Vector4(12, 12, 12, 12), 1
	)
	card_hover_preview.name = "ShopCardHoverPreview"
	card_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_hover_preview.z_index = 400
	card_hover_preview.visible = false
	$Interface.add_child(card_hover_preview)
	card_hover_preview_body = CenterContainer.new()
	card_hover_preview_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_hover_preview.add_child(card_hover_preview_body)


func _queue_card_hover_preview(source: Control, card: Dictionary) -> void:
	card_hover_request_id += 1
	var request_id := card_hover_request_id
	await get_tree().create_timer(CARD_HOVER_DELAY_SECONDS).timeout
	if (
		request_id != card_hover_request_id
		or not is_instance_valid(source)
		or not singles_panel.visible
		or not source.get_global_rect().has_point(get_viewport().get_mouse_position())
	):
		return
	_show_card_hover_preview(source, card)


func _show_card_hover_preview(source: Control, card: Dictionary) -> void:
	if card_hover_preview == null or card_hover_preview_body == null or card.is_empty():
		return
	for child in card_hover_preview_body.get_children():
		child.queue_free()
	var card_face := CARD_FACE_SCRIPT.new()
	card_face.configure(card, "white", false)
	card_face.custom_minimum_size = Vector2(300, 426)
	card_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_hover_preview_body.add_child(card_face)
	card_hover_preview.visible = true
	var preview_size := Vector2(326, 466)
	var source_rect := source.get_global_rect()
	var viewport_size := get_viewport_rect().size
	card_hover_preview.global_position = Vector2(
		clampf(source_rect.end.x + 14, 12, viewport_size.x - preview_size.x - 12),
		clampf(source_rect.position.y - 110, 12, viewport_size.y - preview_size.y - 12)
	)


func _hide_card_hover_preview() -> void:
	card_hover_request_id += 1
	if card_hover_preview != null:
		card_hover_preview.visible = false


func _add_singles_panel() -> void:
	singles_panel = PanelContainer.new()
	singles_panel.name = "InSceneSinglesCase"
	singles_panel.visible = false
	singles_panel.set_anchors_preset(Control.PRESET_CENTER)
	singles_panel.offset_left = -540.0
	singles_panel.offset_top = -350.0
	singles_panel.offset_right = 540.0
	singles_panel.offset_bottom = 350.0
	singles_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	singles_panel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI.clean_style(
			Color("#FFFCF6F7"),
			SKETCH_UI.TEAL,
			1,
			10,
			Vector4.ZERO,
			4,
			true
		)
	)
	$Interface.add_child(singles_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	singles_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	var heading := Label.new()
	heading.text = "SHOPKEEPER'S SINGLES CASE"
	heading.add_theme_font_override("font", SKETCH_UI.body_font(0.62))
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", SKETCH_UI.INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	singles_wallet_label = Label.new()
	singles_wallet_label.add_theme_font_size_override("font_size", 22)
	singles_wallet_label.add_theme_color_override("font_color", SKETCH_UI.ORANGE)
	header.add_child(singles_wallet_label)

	singles_message_label = Label.new()
	singles_message_label.text = "Click a card to buy a copy. The store stays visible behind the case."
	singles_message_label.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	singles_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(singles_message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	singles_grid = GridContainer.new()
	singles_grid.name = "InSceneSinglesGrid"
	singles_grid.columns = 4
	singles_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	singles_grid.add_theme_constant_override("h_separation", 8)
	singles_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(singles_grid)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var back_button := Button.new()
	back_button.name = "InSceneSinglesCaseBack"
	back_button.text = "Back to Shopkeeper"
	WORKSPACE_UI.style_button(back_button)
	back_button.pressed.connect(_return_to_shopkeeper_menu)
	actions.add_child(back_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var store_button := Button.new()
	store_button.text = "Exit to Card Store"
	WORKSPACE_UI.style_button(store_button)
	store_button.pressed.connect(_show_overview)
	actions.add_child(store_button)


func _add_trade_panel() -> void:
	var overlay := _create_detail_overlay("InSceneTradeBinder", "#70d6a5")
	trade_panel = overlay.panel
	trade_wallet_label = overlay.status
	trade_message_label = overlay.message
	trade_list = overlay.body
	trade_action_button = overlay.primary
	trade_action_button.name = "TradeAllExtraCopiesButton"
	trade_action_button.pressed.connect(func() -> void: trade_extras_requested.emit())
	(overlay.back as Button).text = "Back to Shopkeeper"
	(overlay.back as Button).pressed.connect(_return_to_shopkeeper_menu)
	(overlay.exit as Button).pressed.connect(_show_overview)


func _add_meta_panel() -> void:
	var overlay := _create_detail_overlay("InSceneMetaAnalysis", "#77b9f2")
	meta_panel = overlay.panel
	meta_list = overlay.body
	meta_report_list = VBoxContainer.new()
	meta_report_list.name = "InSceneMetaReports"
	meta_report_list.add_theme_constant_override("separation", 6)
	meta_list.add_child(meta_report_list)
	(overlay.primary as Button).visible = false
	(overlay.back as Button).text = "Back to Shopkeeper"
	(overlay.back as Button).pressed.connect(_return_to_shopkeeper_menu)
	(overlay.exit as Button).pressed.connect(_show_overview)


func _create_detail_overlay(node_name: String, accent_hex: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -500.0
	panel.offset_top = -300.0
	panel.offset_right = 500.0
	panel.offset_bottom = 300.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel",
		SKETCH_UI.texture_style(
			SKETCH_UI.PANEL_PAPER,
			Color("#FFFAF0F7"),
			Vector4(24, 24, 24, 24),
			Vector4.ZERO
		)
	)
	$Interface.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	var heading := Label.new()
	heading.name = node_name + "Heading"
	heading.add_theme_font_override("font", SKETCH_UI.display_font(0.88))
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", SKETCH_UI.INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var status := Label.new()
	status.name = node_name + "Status"
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(accent_hex).darkened(0.28))
	header.add_child(status)

	var message := Label.new()
	message.name = node_name + "Message"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	content.add_child(message)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var body := VBoxContainer.new()
	body.name = node_name + "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var primary := Button.new()
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(primary)
	var back := Button.new()
	back.name = node_name + "Back"
	actions.add_child(back)
	var exit := Button.new()
	exit.text = "Exit to Card Store"
	actions.add_child(exit)
	return {"panel": panel, "heading": heading, "status": status, "message": message, "body": body, "primary": primary, "back": back, "exit": exit}


func _render_singles_case(message: String = "") -> void:
	if singles_grid == null:
		return
	for child in singles_grid.get_children():
		singles_grid.remove_child(child)
		child.queue_free()
	singles_wallet_label.text = "WALLET  $%d" % int(shop_context.get("money", 0))
	if message != "":
		singles_message_label.text = message
	else:
		singles_message_label.text = "Click a card to buy a copy. The store stays visible behind the case."
	var singles: Array = shop_context.get("singles", [])
	if not singles.any(func(entry_value) -> bool:
		return String((entry_value as Dictionary).get("id", "")) == selected_single_id
	):
		selected_single_id = ""
	if singles.is_empty():
		var empty_label := Label.new()
		empty_label.text = "The singles case is sold out. New cards arrive after the next tournament round."
		singles_grid.add_child(empty_label)
		return
	for entry_value in singles:
		_add_single_card_tile(entry_value)
	_update_in_scene_single_selection()


func _render_trade_binder(message: String = "") -> void:
	if trade_list == null:
		return
	_clear_dynamic_list(trade_list)
	var heading := trade_panel.find_child("InSceneTradeBinderHeading", true, false) as Label
	if heading != null:
		heading.text = "TRADE BINDER"
	trade_wallet_label.text = "WALLET  $%d" % int(shop_context.get("money", 0))
	trade_message_label.text = message if message != "" else "The traders will buy copies beyond the safe deck limit. Cards used by your deck are protected."
	var entries: Array = shop_context.get("trade_entries", [])
	var total_cards := 0
	var total_value := 0
	for entry_value in entries:
		var entry: Dictionary = entry_value
		var copies := int(entry.get("copies", 0))
		var value := int(entry.get("total_value", 0))
		total_cards += copies
		total_value += value
		var row := PanelContainer.new()
		row.name = "InSceneTradeEntry"
		row.add_theme_stylebox_override("panel", _overlay_row_style("#26352f", "#70d6a5"))
		trade_list.add_child(row)
		var label := Label.new()
		label.text = "%s  •  %d extra cop%s  •  $%d offer" % [String(entry.get("name", "Card")), copies, "y" if copies == 1 else "ies", value]
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", SKETCH_UI.INK)
		row.add_child(label)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No safe extra copies are available to trade right now."
		empty.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
		trade_list.add_child(empty)
	trade_action_button.text = "Trade %d Extra Card%s  •  Receive $%d" % [total_cards, "" if total_cards == 1 else "s", total_value]
	trade_action_button.disabled = total_cards <= 0


func _render_meta_analysis() -> void:
	if meta_list == null:
		return
	_clear_dynamic_list(meta_list)
	var heading := meta_panel.find_child("InSceneMetaAnalysisHeading", true, false) as Label
	if heading != null:
		heading.text = "META ANALYSIS"
	var status := meta_panel.find_child("InSceneMetaAnalysisStatus", true, false) as Label
	if status != null:
		status.text = String(shop_context.get("event_name", "Weekly Locals"))
	var message := meta_panel.find_child("InSceneMetaAnalysisMessage", true, false) as Label
	if message != null:
		message.text = "Expected field shares and the latest rumors from players at the shop."
	var entries_heading := Label.new()
	entries_heading.text = "EXPECTED FIELD"
	entries_heading.add_theme_font_size_override("font_size", 18)
	entries_heading.add_theme_color_override("font_color", SKETCH_UI.TEAL)
	meta_list.add_child(entries_heading)
	var entries := VBoxContainer.new()
	entries.name = "InSceneMetaEntries"
	entries.add_theme_constant_override("separation", 6)
	meta_list.add_child(entries)
	for entry_value in shop_context.get("meta_entries", []):
		var entry: Dictionary = entry_value
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		entries.add_child(row)
		var line := Label.new()
		line.text = "%s  •  %d%%" % [String(entry.get("name", "Deck")), int(entry.get("share", 0))]
		line.add_theme_font_size_override("font_size", 16)
		line.tooltip_text = String(entry.get("summary", ""))
		row.add_child(line)
		var share_bar := ProgressBar.new()
		share_bar.max_value = 100.0
		share_bar.value = float(entry.get("share", 0))
		share_bar.show_percentage = false
		share_bar.custom_minimum_size = Vector2(0, 12)
		row.add_child(share_bar)
	var reports_heading := Label.new()
	reports_heading.text = "SHOP TALK"
	reports_heading.add_theme_font_size_override("font_size", 18)
	reports_heading.add_theme_color_override("font_color", SKETCH_UI.TEAL)
	meta_list.add_child(reports_heading)
	meta_report_list = VBoxContainer.new()
	meta_report_list.name = "InSceneMetaReports"
	meta_report_list.add_theme_constant_override("separation", 6)
	meta_list.add_child(meta_report_list)
	for report_value in shop_context.get("reports", []):
		var report := Label.new()
		report.text = "• " + String(report_value)
		report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		report.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
		meta_report_list.add_child(report)


func _clear_dynamic_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()


func _overlay_row_style(background_hex: String, border_hex: String) -> StyleBoxFlat:
	return SKETCH_UI.flat_style(
		SKETCH_UI.PAPER.lerp(Color(background_hex), 0.08),
		Color(border_hex).darkened(0.24),
		2,
		Vector4(12, 8, 12, 8)
	)


func _add_single_card_tile(entry_value: Variant) -> void:
	var entry: Dictionary = entry_value
	var card_id := String(entry.get("id", ""))
	var rarity := String(entry.get("rarity", "common"))
	var price := int(entry.get("price", 0))
	var card: Dictionary = entry.get("card", {})
	var tile := PanelContainer.new()
	tile.name = "InSceneSingle_%s" % card_id
	tile.set_meta("card_id", card_id)
	tile.custom_minimum_size = Vector2(245, 270)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.set_meta("tile_fill", WORKSPACE_UI.SURFACE.lerp(_rarity_background(rarity), 0.07))
	tile.set_meta("tile_accent", _rarity_accent(rarity).darkened(0.32))
	singles_grid.add_child(tile)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	tile.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var face_center := CenterContainer.new()
	face_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(face_center)
	var card_stack := Control.new()
	card_stack.custom_minimum_size = Vector2(145, 206)
	face_center.add_child(card_stack)
	if not card.is_empty() and CARD_FACE_SCRIPT.supports_card(card):
		var face := CARD_FACE_SCRIPT.new()
		face.configure(card, String(entry.get("difficulty", "white")), false)
		face.custom_minimum_size = Vector2(145, 206)
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_stack.add_child(face)
	else:
		var fallback := Label.new()
		fallback.text = String(entry.get("name", card_id))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_stack.add_child(fallback)

	var sticker: PanelContainer = WORKSPACE_UI.make_price_sticker(price, Vector2(66, 44))
	sticker.position = Vector2(74, 45)
	card_stack.add_child(sticker)
	var select_button := Button.new()
	select_button.name = "InSceneSingleSelect_%s" % card_id
	select_button.text = ""
	select_button.tooltip_text = "Select %s to reveal its Buy button." % String(entry.get("name", card_id))
	select_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		select_button.add_theme_stylebox_override(
			state,
			WORKSPACE_UI.clean_style(
				Color("#FFFFFF08") if state == "hover" else Color.TRANSPARENT,
				Color.TRANSPARENT,
				0,
				5
			)
		)
	select_button.pressed.connect(func() -> void: _select_in_scene_single(card_id))
	select_button.mouse_entered.connect(func() -> void: _queue_card_hover_preview(select_button, card))
	select_button.mouse_exited.connect(_hide_card_hover_preview)
	card_stack.add_child(select_button)

	var owned_label := Label.new()
	owned_label.text = "Owned %d  •  Deck %d" % [int(entry.get("owned", 0)), int(entry.get("deck", 0))]
	owned_label.add_theme_color_override("font_color", SKETCH_UI.MUTED_INK)
	box.add_child(owned_label)
	var buy_button := Button.new()
	buy_button.name = "BuyInScene_%s" % card_id
	buy_button.text = "Buy"
	buy_button.disabled = int(shop_context.get("money", 0)) < price
	buy_button.visible = false
	buy_button.tooltip_text = "Buy %s for $%d." % [String(entry.get("name", card_id)), price]
	WORKSPACE_UI.style_button(buy_button, "primary")
	buy_button.pressed.connect(func() -> void: single_purchase_requested.emit(card_id))
	box.add_child(buy_button)


func _select_in_scene_single(card_id: String) -> void:
	selected_single_id = card_id
	_update_in_scene_single_selection()
	for entry_value in shop_context.get("singles", []):
		var entry: Dictionary = entry_value
		if String(entry.get("id", "")) != card_id:
			continue
		singles_message_label.text = "%s selected — $%d. Click Buy to add it to your collection." % [
			String(entry.get("name", card_id)),
			int(entry.get("price", 0)),
		]
		break


func _update_in_scene_single_selection() -> void:
	if singles_grid == null:
		return
	for candidate in singles_grid.get_children():
		var tile := candidate as PanelContainer
		if tile == null:
			continue
		var card_id := String(tile.get_meta("card_id", ""))
		var selected := card_id == selected_single_id
		var fill: Color = tile.get_meta("tile_fill", WORKSPACE_UI.SURFACE)
		var accent: Color = tile.get_meta("tile_accent", WORKSPACE_UI.BORDER_SOFT)
		tile.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI.clean_style(
				fill,
				WORKSPACE_UI.MUSTARD if selected else accent,
				3 if selected else 1,
				8 if selected else 7,
				Vector4.ZERO,
				4 if selected else 3,
				selected
			)
		)
		var buy_button := tile.find_child("BuyInScene_*", true, false) as Button
		if buy_button != null:
			buy_button.visible = selected


func _rarity_background(rarity: String) -> Color:
	match rarity:
		"mythic": return Color("#3b243e")
		"rare": return Color("#40351f")
		"uncommon": return Color("#183a35")
		_: return Color("#202936")


func _rarity_accent(rarity: String) -> Color:
	match rarity:
		"mythic": return Color("#ef9cff")
		"rare": return Color("#f2d478")
		"uncommon": return Color("#77dbc8")
		_: return Color("#bdc9da")


func _add_world_hotspots() -> void:
	shopkeeper_hotspot = _add_hotspot("ShopkeeperHotspot", Vector2(280, 360), _show_menu)
	shopkeeper_hotspot.mouse_entered.connect(func() -> void: _set_shopkeeper_highlighted(true))
	shopkeeper_hotspot.mouse_exited.connect(func() -> void: _set_shopkeeper_highlighted(false))
	_add_shopkeeper_arrow()


func _add_shopkeeper_arrow() -> void:
	shopkeeper_arrow = Control.new()
	shopkeeper_arrow.name = "ShopkeeperArrow"
	shopkeeper_arrow.visible = false
	shopkeeper_arrow.size = Vector2(72, 72)
	shopkeeper_arrow.pivot_offset = shopkeeper_arrow.size * 0.5
	shopkeeper_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shopkeeper_arrow.z_index = 30
	$Interface.add_child(shopkeeper_arrow)

	var arrow_outline := Polygon2D.new()
	arrow_outline.name = "ArrowOutline"
	arrow_outline.polygon = PackedVector2Array([
		Vector2(22, 4),
		Vector2(50, 4),
		Vector2(50, 29),
		Vector2(66, 29),
		Vector2(36, 68),
		Vector2(6, 29),
		Vector2(22, 29),
	])
	arrow_outline.color = Color("#2a1d0b")
	shopkeeper_arrow.add_child(arrow_outline)

	var arrow_fill := Polygon2D.new()
	arrow_fill.name = "ArrowFill"
	arrow_fill.polygon = PackedVector2Array([
		Vector2(29, 12),
		Vector2(43, 12),
		Vector2(43, 37),
		Vector2(51, 37),
		Vector2(36, 57),
		Vector2(21, 37),
		Vector2(29, 37),
	])
	arrow_fill.color = Color("#ffd54a")
	shopkeeper_arrow.add_child(arrow_fill)


func _start_shopkeeper_arrow_bob() -> void:
	if shopkeeper_arrow == null:
		return
	if shopkeeper_arrow_tween != null and shopkeeper_arrow_tween.is_valid():
		shopkeeper_arrow_tween.kill()
	var rest_y := shopkeeper_arrow.position.y
	if bool(get_tree().root.get_meta("reduced_motion", false)):
		shopkeeper_arrow.position.y = rest_y
		return
	shopkeeper_arrow_tween = create_tween().set_loops()
	shopkeeper_arrow_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shopkeeper_arrow_tween.tween_property(
		shopkeeper_arrow,
		"position:y",
		rest_y + SHOPKEEPER_ARROW_BOB_DISTANCE,
		0.58
	)
	shopkeeper_arrow_tween.tween_property(shopkeeper_arrow, "position:y", rest_y, 0.58)


func _set_shopkeeper_highlighted(highlighted: bool) -> void:
	if shopkeeper_model == null:
		return
	highlighted = highlighted and shopkeeper_hover_enabled
	if highlighted and shopkeeper_highlight_material == null:
		shopkeeper_highlight_material = StandardMaterial3D.new()
		shopkeeper_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shopkeeper_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shopkeeper_highlight_material.albedo_color = Color(1.0, 0.78, 0.22, 0.34)
		shopkeeper_highlight_material.emission_enabled = true
		shopkeeper_highlight_material.emission = Color(1.0, 0.67, 0.08)
		shopkeeper_highlight_material.emission_energy_multiplier = 1.5
		shopkeeper_highlight_material.render_priority = 1
	for child in shopkeeper_model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		if highlighted:
			if not shopkeeper_original_overlays.has(mesh):
				shopkeeper_original_overlays[mesh] = mesh.material_overlay
			mesh.material_overlay = shopkeeper_highlight_material
		else:
			mesh.material_overlay = shopkeeper_original_overlays.get(mesh)
	if not highlighted:
		shopkeeper_original_overlays.clear()


func _add_hotspot(node_name: String, size_value: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.size = size_value
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.modulate = Color(1, 1, 1, 0)
	button.tooltip_text = "Shopkeeper"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	$Interface.add_child(button)
	$Interface.move_child(button, 1)
	return button


func _position_shopkeeper_hotspot() -> void:
	if shopkeeper_hotspot == null or shopkeeper_model == null:
		return
	var viewport_size := Vector2($ViewportContainer/SubViewport.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var screen_position := camera.unproject_position(shopkeeper_model.global_position + Vector3(0, 0.9, 0))
	var interface_scale: Vector2 = $Interface.size / viewport_size
	shopkeeper_hotspot.position = screen_position * interface_scale - shopkeeper_hotspot.size * 0.5
	if shopkeeper_arrow != null:
		var arrow_screen_position := camera.unproject_position(
			shopkeeper_model.global_position + Vector3(0, SHOPKEEPER_ARROW_HEIGHT, 0)
		)
		shopkeeper_arrow.position = (
			arrow_screen_position * interface_scale
			- Vector2(shopkeeper_arrow.size.x * 0.5, shopkeeper_arrow.size.y)
		)
		shopkeeper_arrow.visible = overview_active
		_start_shopkeeper_arrow_bob()


func _show_overview() -> void:
	overview_active = false
	_update_overview_round_button()
	if shopkeeper_arrow != null:
		shopkeeper_arrow.visible = false
	shopkeeper_hover_enabled = false
	_set_shopkeeper_highlighted(false)
	var overview_generation := transition_generation + 1
	await _move_to_shot(overview_target, OVERVIEW_SIZE, _overview_description(), null)
	if transition_generation != overview_generation:
		return
	overview_active = true
	_update_overview_round_button()
	_position_shopkeeper_hotspot()
	shopkeeper_hover_enabled = true
	if shopkeeper_hotspot != null and shopkeeper_hotspot.is_hovered():
		_set_shopkeeper_highlighted(true)


func _show_settings_menu() -> void:
	_show_station(
		overview_target,
		OVERVIEW_SIZE,
		"SETTINGS / SAVE — manage the current demo run",
		"Settings / Save",
		"Save your current run or return to the main menu.",
		[
			{"text": "Save Game", "callback": func() -> void: save_requested.emit()},
			{"text": "Main Menu", "callback": func() -> void: exit_requested.emit()}
		]
	)


func _show_menu() -> void:
	overview_active = false
	_update_overview_round_button()
	if shopkeeper_arrow != null:
		shopkeeper_arrow.visible = false
	shopkeeper_hover_enabled = false
	_set_shopkeeper_highlighted(false)
	var focus_point := shopkeeper_model.global_position + Vector3(0, SHOPKEEPER_FOCUS_HEIGHT, 0)
	menu_target.global_position = focus_point + SHOPKEEPER_CAMERA_OFFSET
	menu_target.look_at(focus_point, Vector3.UP)
	_move_to_shot(menu_target, SHOPKEEPER_SIZE, "SHOPKEEPER — packs, singles, trades, meta, and events", menu_panel)


func _return_to_shopkeeper_menu() -> void:
	overview_active = false
	_update_overview_round_button()
	transition_generation += 1
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if overlay_tween != null and overlay_tween.is_valid():
		overlay_tween.kill()
	var outgoing_overlay: Control
	for candidate in [singles_panel, trade_panel, meta_panel]:
		if candidate != null and candidate.visible:
			outgoing_overlay = candidate
			break
	station_panel.visible = false
	shot_label.text = "SHOPKEEPER — packs, singles, trades, meta, and events"
	menu_panel.visible = true
	menu_panel.modulate.a = 0.0
	overlay_tween = create_tween().set_parallel(true)
	overlay_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if outgoing_overlay != null:
		overlay_tween.tween_property(outgoing_overlay, "modulate:a", 0.0, 0.14)
	overlay_tween.tween_property(menu_panel, "modulate:a", 1.0, 0.20)
	overlay_tween.chain().tween_callback(func() -> void:
		if outgoing_overlay != null:
			outgoing_overlay.visible = false
			outgoing_overlay.modulate.a = 1.0
	)


func _show_singles_case() -> void:
	_hide_overlays()
	shot_label.text = "SINGLES CASE — buy cards without leaving the store"
	_fade_in_overlay(singles_panel)


func _show_trade_binder() -> void:
	_hide_overlays()
	_render_trade_binder()
	shot_label.text = "TRADE BINDER — review safe extras without leaving the store"
	_fade_in_overlay(trade_panel)


func _show_meta_analysis() -> void:
	_hide_overlays()
	_render_meta_analysis()
	shot_label.text = "META ANALYSIS — local field shares and shop talk"
	_fade_in_overlay(meta_panel)


func _show_station(target: Marker3D, target_size: float, description: String, heading: String, body: String, actions: Array) -> void:
	overview_active = false
	_update_overview_round_button()
	if shopkeeper_arrow != null:
		shopkeeper_arrow.visible = false
	station_heading.text = heading
	station_description.text = body
	for child in station_actions.get_children():
		child.queue_free()
	for action_data in actions:
		var action_button := Button.new()
		action_button.text = String(action_data.get("text", "Open"))
		action_button.pressed.connect(action_data.get("callback", Callable()))
		station_actions.add_child(action_button)
	var back_button := Button.new()
	back_button.text = "Back to Store"
	back_button.pressed.connect(_show_overview)
	station_actions.add_child(back_button)
	_move_to_shot(target, target_size, description, station_panel)


func _move_to_shot(target: Marker3D, target_size: float, description: String, overlay: Control) -> void:
	transition_generation += 1
	var generation := transition_generation
	_hide_overlays()
	shot_label.text = "MOVING CAMERA..."
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera_rig, "global_position", target.global_position, TRANSITION_SECONDS)
	camera_tween.tween_property(camera_rig, "global_rotation", target.global_rotation, TRANSITION_SECONDS)
	camera_tween.tween_property(camera, "size", target_size, TRANSITION_SECONDS)
	await camera_tween.finished
	if generation != transition_generation:
		return
	shot_label.text = description
	if overlay != null:
		_fade_in_overlay(overlay)


func _hide_overlays() -> void:
	if overlay_tween != null and overlay_tween.is_valid():
		overlay_tween.kill()
	_hide_card_hover_preview()
	menu_panel.visible = false
	station_panel.visible = false
	if singles_panel != null:
		singles_panel.visible = false
	if trade_panel != null:
		trade_panel.visible = false
	if meta_panel != null:
		meta_panel.visible = false
	if external_overlay != null:
		external_overlay.visible = false


func _fade_in_overlay(overlay: Control) -> void:
	overlay.visible = true
	overlay.modulate.a = 0.0
	overlay_tween = create_tween()
	overlay_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	overlay_tween.tween_property(overlay, "modulate:a", 1.0, 0.22)
