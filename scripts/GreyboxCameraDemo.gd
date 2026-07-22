extends Control

signal exit_requested
signal packs_requested
signal tournament_requested
signal deck_requested
signal calendar_requested
signal save_requested
signal single_purchase_requested(card_id: String)
signal trade_extras_requested

const OVERVIEW_SIZE := 11.5
const SHOPKEEPER_SIZE := 4.0
const SHOPKEEPER_FOCUS_HEIGHT := 1.55
const SHOPKEEPER_CAMERA_OFFSET := Vector3(0.85, 0.55, 5.5)
const TRANSITION_SECONDS := 0.75

@onready var camera_rig: Node3D = $ViewportContainer/SubViewport/World/CameraRig
@onready var camera: Camera3D = $ViewportContainer/SubViewport/World/CameraRig/Camera3D
@onready var shopkeeper_model: Node3D = $ViewportContainer/SubViewport/World/NPC/ShopkeeperModel
@onready var overview_target: Marker3D = $ViewportContainer/SubViewport/World/CameraTargets/OverviewTarget
@onready var menu_target: Marker3D = $ViewportContainer/SubViewport/World/CameraTargets/MenuTarget
@onready var shot_label: Label = $Interface/TopBar/TopMargin/TopContent/ShotLabel
@onready var cash_hud_button: Button = $Interface/ShopHud/CashButton
@onready var deck_hud_button: Button = $Interface/ShopHud/DeckButton
@onready var save_hud_button: Button = $Interface/ShopHud/SaveButton
@onready var settings_hud_button: Button = $Interface/ShopHud/SettingsButton
@onready var menu_panel: PanelContainer = $Interface/MenuPanel
@onready var menu_description: Label = $Interface/MenuPanel/Margin/Content/Description
@onready var station_panel: PanelContainer = $Interface/CombatPanel
@onready var station_heading: Label = $Interface/CombatPanel/Margin/Content/Heading
@onready var station_description: Label = $Interface/CombatPanel/Margin/Content/Explanation
@onready var buy_singles_button: Button = $Interface/MenuPanel/Margin/Content/BuySingles
@onready var buy_pack_button: Button = $Interface/MenuPanel/Margin/Content/BuyPack
@onready var meta_menu_button: Button = $Interface/MenuPanel/Margin/Content/Meta
@onready var calendar_menu_button: Button = $Interface/MenuPanel/Margin/Content/Calendar
@onready var tournament_menu_button: Button = $Interface/MenuPanel/Margin/Content/Tournament
@onready var leave_menu_button: Button = $Interface/MenuPanel/Margin/Content/Leave

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


func _ready() -> void:
	cash_hud_button.name = "ShopHudCashButton"
	deck_hud_button.name = "ShopHudDeckButton"
	save_hud_button.name = "ShopHudSaveButton"
	settings_hud_button.name = "ShopHudSettingsButton"
	_style_shop_hud_buttons()
	cash_hud_button.pressed.connect(func() -> void: trade_extras_requested.emit())
	deck_hud_button.pressed.connect(func() -> void: deck_requested.emit())
	save_hud_button.pressed.connect(func() -> void: save_requested.emit())
	settings_hud_button.pressed.connect(_show_settings_menu)
	buy_singles_button.pressed.connect(_show_singles_case)
	buy_pack_button.pressed.connect(func() -> void: packs_requested.emit())
	meta_menu_button.pressed.connect(_show_meta_analysis)
	calendar_menu_button.pressed.connect(func() -> void: calendar_requested.emit())
	tournament_menu_button.pressed.connect(func() -> void: tournament_requested.emit())
	leave_menu_button.text = "Back to Store"
	leave_menu_button.pressed.connect(_show_overview)
	_add_station_actions_container()
	_add_singles_panel()
	_add_trade_panel()
	_add_meta_panel()
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
	call_deferred("_position_shopkeeper_hotspot")


func _style_shop_hud_buttons() -> void:
	var normal_style := _shop_hud_button_style(0.34)
	var hover_style := _shop_hud_button_style(0.52)
	var pressed_style := _shop_hud_button_style(0.68)
	var focus_style := _shop_hud_button_style(0.46, 2)
	for button in [cash_hud_button, deck_hud_button, save_hud_button, settings_hud_button]:
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_stylebox_override("focus", focus_style)
		button.add_theme_color_override("font_color", Color("#10141b"))
		button.add_theme_color_override("font_hover_color", Color("#10141b"))
		button.add_theme_color_override("font_pressed_color", Color("#10141b"))


func _shop_hud_button_style(alpha: float, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, alpha)
	style.border_color = Color(1, 1, 1, minf(1.0, alpha + 0.28))
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


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


func _apply_shop_context() -> void:
	if shot_label == null:
		return
	var event_name := String(shop_context.get("event_name", "Weekly Locals"))
	var money := int(shop_context.get("money", 0))
	var prize_packs := int(shop_context.get("prize_packs", 0))
	var difficulty := String(shop_context.get("difficulty_name", "Black"))
	var tournament_active := bool(shop_context.get("tournament_active", false))
	var tournament_round := int(shop_context.get("tournament_round", 1))
	cash_hud_button.text = "$%d" % money
	tournament_menu_button.text = "Start Tournament Round %d" % tournament_round if tournament_active else "Register for Tournament"
	menu_description.text = "$%d cash  •  %d prize pack(s)\n%s frame  •  %s" % [money, prize_packs, difficulty, event_name]
	if not menu_panel.visible and not station_panel.visible and (singles_panel == null or not singles_panel.visible) and (trade_panel == null or not trade_panel.visible) and (meta_panel == null or not meta_panel.visible):
		shot_label.text = "CARD STORE  •  %s frame  •  %s  •  %d prize pack(s)" % [difficulty, event_name, prize_packs]


func _overview_description() -> String:
	return "CARD STORE  •  click the shopkeeper"


func _add_station_actions_container() -> void:
	station_actions = VBoxContainer.new()
	station_actions.name = "StationActions"
	station_actions.add_theme_constant_override("separation", 8)
	$Interface/CombatPanel/Margin/Content.add_child(station_actions)


func _add_singles_panel() -> void:
	singles_panel = PanelContainer.new()
	singles_panel.name = "InSceneSinglesCase"
	singles_panel.visible = false
	singles_panel.set_anchors_preset(Control.PRESET_CENTER)
	singles_panel.offset_left = -540.0
	singles_panel.offset_top = -310.0
	singles_panel.offset_right = 540.0
	singles_panel.offset_bottom = 310.0
	singles_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#121923ee")
	panel_style.border_color = Color("#d6b866")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	singles_panel.add_theme_stylebox_override("panel", panel_style)
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
	heading.add_theme_font_size_override("font_size", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	singles_wallet_label = Label.new()
	singles_wallet_label.add_theme_font_size_override("font_size", 22)
	singles_wallet_label.add_theme_color_override("font_color", Color("#f2d478"))
	header.add_child(singles_wallet_label)

	singles_message_label = Label.new()
	singles_message_label.text = "Click a card to buy a copy. The store stays visible behind the case."
	singles_message_label.add_theme_color_override("font_color", Color("#cbd5e3"))
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
	back_button.pressed.connect(_return_to_shopkeeper_menu)
	actions.add_child(back_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var store_button := Button.new()
	store_button.text = "Exit to Card Store"
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
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#121923ee")
	panel_style.border_color = Color(accent_hex)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
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
	heading.add_theme_font_size_override("font_size", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var status := Label.new()
	status.name = node_name + "Status"
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(accent_hex))
	header.add_child(status)

	var message := Label.new()
	message.name = node_name + "Message"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color("#cbd5e3"))
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
	if singles.is_empty():
		var empty_label := Label.new()
		empty_label.text = "The singles case is sold out. New cards arrive after the next tournament round."
		singles_grid.add_child(empty_label)
		return
	for entry_value in singles:
		_add_single_card_tile(entry_value)


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
		label.add_theme_color_override("font_color", Color("#e2f3eb"))
		row.add_child(label)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No safe extra copies are available to trade right now."
		empty.add_theme_color_override("font_color", Color("#aeb9c8"))
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
	entries_heading.add_theme_color_override("font_color", Color("#9fd0ff"))
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
	reports_heading.add_theme_color_override("font_color", Color("#9fd0ff"))
	meta_list.add_child(reports_heading)
	meta_report_list = VBoxContainer.new()
	meta_report_list.name = "InSceneMetaReports"
	meta_report_list.add_theme_constant_override("separation", 6)
	meta_list.add_child(meta_report_list)
	for report_value in shop_context.get("reports", []):
		var report := Label.new()
		report.text = "• " + String(report_value)
		report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		report.add_theme_color_override("font_color", Color("#cbd5e3"))
		meta_report_list.add_child(report)


func _clear_dynamic_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()


func _overlay_row_style(background_hex: String, border_hex: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background_hex)
	style.border_color = Color(border_hex)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _add_single_card_tile(entry_value: Variant) -> void:
	var entry: Dictionary = entry_value
	var card_id := String(entry.get("id", ""))
	var rarity := String(entry.get("rarity", "common"))
	var price := int(entry.get("price", 0))
	var tile := PanelContainer.new()
	tile.name = "InSceneSingle_%s" % card_id
	tile.custom_minimum_size = Vector2(245, 190)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = _rarity_background(rarity)
	tile_style.border_color = _rarity_accent(rarity)
	tile_style.set_border_width_all(2)
	tile_style.set_corner_radius_all(8)
	tile.add_theme_stylebox_override("panel", tile_style)
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
	var name_label := Label.new()
	name_label.text = String(entry.get("name", card_id))
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", _rarity_accent(rarity))
	name_label.clip_text = true
	box.add_child(name_label)
	var type_label := Label.new()
	type_label.text = "%s  •  %s" % [rarity.capitalize(), String(entry.get("descriptor", "Card"))]
	type_label.add_theme_color_override("font_color", Color("#d7deea"))
	box.add_child(type_label)
	var rules_label := Label.new()
	rules_label.text = String(entry.get("text", ""))
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.max_lines_visible = 2
	rules_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_label.add_theme_font_size_override("font_size", 12)
	rules_label.add_theme_color_override("font_color", Color("#aeb9c8"))
	box.add_child(rules_label)
	var owned_label := Label.new()
	owned_label.text = "Owned %d  •  Deck %d" % [int(entry.get("owned", 0)), int(entry.get("deck", 0))]
	owned_label.add_theme_color_override("font_color", Color("#cbd5e3"))
	box.add_child(owned_label)
	var buy_button := Button.new()
	buy_button.name = "BuyInScene_%s" % card_id
	buy_button.text = "Buy  $%d" % price
	buy_button.disabled = int(shop_context.get("money", 0)) < price
	buy_button.pressed.connect(func() -> void: single_purchase_requested.emit(card_id))
	box.add_child(buy_button)


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


func _show_overview() -> void:
	_move_to_shot(overview_target, OVERVIEW_SIZE, _overview_description(), null)


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
	var focus_point := shopkeeper_model.global_position + Vector3(0, SHOPKEEPER_FOCUS_HEIGHT, 0)
	menu_target.global_position = focus_point + SHOPKEEPER_CAMERA_OFFSET
	menu_target.look_at(focus_point, Vector3.UP)
	_move_to_shot(menu_target, SHOPKEEPER_SIZE, "SHOPKEEPER — packs, singles, trades, meta, and events", menu_panel)


func _return_to_shopkeeper_menu() -> void:
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
	menu_panel.visible = false
	station_panel.visible = false
	if singles_panel != null:
		singles_panel.visible = false
	if trade_panel != null:
		trade_panel.visible = false
	if meta_panel != null:
		meta_panel.visible = false


func _fade_in_overlay(overlay: Control) -> void:
	overlay.visible = true
	overlay.modulate.a = 0.0
	overlay_tween = create_tween()
	overlay_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	overlay_tween.tween_property(overlay, "modulate:a", 1.0, 0.22)
