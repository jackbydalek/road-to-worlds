extends Control
class_name TournamentHubScreen

## A deliberately low-detail, front-on parallax greybox for the tournament hub.
## The blocks are labelled so layout and interaction can be tuned before final
## environment art replaces them.

signal shop_requested
signal heal_requested
signal upgrade_requested
signal next_round_requested
signal save_requested
signal settings_requested

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const TOPDECK_UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const BODY_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const DESIGN_SIZE := Vector2(1280, 720)

var _snapshot: Dictionary = {}
var _canvas: Control
var _back_layer: Control
var _mid_layer: Control
var _front_layer: Control
var _round_label: Label
var _life_label: Label
var _funds_label: Label
var _deck_label: Label
var _notice_label: Label
var _vending_status: Label
var _heal_button: Button
var _upgrade_button: Button
var _out_of_order: PanelContainer
var _next_round_button: Button
var _reduced_motion := false
var _parallax_target := Vector2.ZERO


func _ready() -> void:
	name = "TournamentHub"
	custom_minimum_size = Vector2(1120, 630)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	resized.connect(_layout_canvas)
	_layout_canvas()
	refresh(_snapshot)
	set_process(true)


func configure(snapshot: Dictionary, reduced_motion: bool = false) -> void:
	_snapshot = snapshot.duplicate(true)
	_reduced_motion = reduced_motion
	if is_node_ready():
		refresh(_snapshot)


func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if _round_label == null:
		return
	var round_number := int(_snapshot.get("round", 1))
	var total_rounds := maxi(1, int(_snapshot.get("total_rounds", 4)))
	var life := int(_snapshot.get("life", 0))
	var max_life := maxi(1, int(_snapshot.get("max_life", 40)))
	var floor_name := String(_snapshot.get("floor", "Locals")).to_upper()
	_round_label.text = "ROUND %d / %d" % [round_number, total_rounds]
	_life_label.text = "LIFE %d / %d" % [life, max_life]
	_funds_label.text = "$%d" % int(_snapshot.get("money", 0))
	_deck_label.text = "LOCKED DECK  •  %d CARDS" % int(_snapshot.get("deck_count", 0))
	var next_label := String(_snapshot.get("next_label", "Report to the next table"))
	_next_round_button.text = "NEXT ROUND\n%s" % next_label
	var notice := String(_snapshot.get("notice", "Choose the shop, use your one break, or report to the next round."))
	_notice_label.text = "%s  •  %s" % [floor_name, notice]

	var break_used := bool(_snapshot.get("break_used", false))
	var break_choice := String(_snapshot.get("break_choice", ""))
	_heal_button.disabled = break_used or not bool(_snapshot.get("can_heal", true))
	_upgrade_button.disabled = break_used or not bool(_snapshot.get("can_upgrade", true))
	_heal_button.visible = not break_used
	_upgrade_button.visible = not break_used
	_out_of_order.visible = break_used
	if break_used:
		_vending_status.text = "BREAK USED  •  %s" % ("CARD UPGRADED" if break_choice == "upgrade" else "LIFE RECOVERED")
	else:
		_vending_status.text = "ONE USE THIS FLOOR"


func _process(delta: float) -> void:
	if _canvas == null:
		return
	if _reduced_motion:
		_parallax_target = Vector2.ZERO
	else:
		var local_mouse := get_local_mouse_position()
		var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
		var normalized := Vector2(
			clampf(local_mouse.x / safe_size.x, 0.0, 1.0) - 0.5,
			clampf(local_mouse.y / safe_size.y, 0.0, 1.0) - 0.5
		)
		_parallax_target = normalized * 2.0
	var blend := clampf(delta * 8.0, 0.0, 1.0)
	_back_layer.position = _back_layer.position.lerp(_parallax_target * -4.0, blend)
	_mid_layer.position = _mid_layer.position.lerp(_parallax_target * -9.0, blend)
	_front_layer.position = _front_layer.position.lerp(_parallax_target * -15.0, blend)


func _build() -> void:
	var root_fill := ColorRect.new()
	root_fill.name = "HubRootFill"
	root_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_fill.color = Color("#D9DEE5")
	root_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_fill)
	var root_floor := ColorRect.new()
	root_floor.name = "HubRootFloor"
	root_floor.anchor_top = 0.56
	root_floor.anchor_right = 1.0
	root_floor.anchor_bottom = 1.0
	root_floor.color = Color("#AEB7C2")
	root_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_floor)

	_canvas = Control.new()
	_canvas.name = "HubDesignCanvas"
	_canvas.size = DESIGN_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_canvas)

	_back_layer = _make_layer("HubBackLayer")
	_mid_layer = _make_layer("HubMidLayer")
	_front_layer = _make_layer("HubFrontLayer")
	_canvas.add_child(_back_layer)
	_canvas.add_child(_mid_layer)
	_canvas.add_child(_front_layer)

	_build_room()
	_build_shop_kiosk()
	_build_vending_machine()
	_build_match_table()
	_build_hud()


func _build_room() -> void:
	_back_layer.add_child(_box("BackWall", Rect2(0, 0, 1280, 500), Color("#D9DEE5"), PALETTE.STEEL, 0))
	_back_layer.add_child(_box("Floor", Rect2(-20, 455, 1320, 285), Color("#AEB7C2"), PALETTE.STEEL, 0))
	_back_layer.add_child(_box("Window", Rect2(38, 92, 300, 178), Color("#9CCFE0"), PALETTE.GRAPHITE, 3))
	_add_centered_label(_back_layer, "WINDOW / STREET", Rect2(38, 92, 300, 178), 18, PALETTE.CARBON)
	_back_layer.add_child(_box("LeagueBoard", Rect2(435, 82, 410, 172), PALETTE.GRAPHITE, PALETTE.ELECTRIC_CYAN, 4))
	_add_centered_label(_back_layer, "LOCALS BRACKET BOARD\nTOP 8  →  TOP 4  →  FINAL", Rect2(450, 98, 380, 140), 20, PALETTE.COOL_WHITE)
	_back_layer.add_child(_box("PosterLeft", Rect2(360, 116, 54, 116), PALETTE.SELECTION_BLUE, PALETTE.CARBON, 2))
	_add_centered_label(_back_layer, "CARD\nPOSTER", Rect2(360, 116, 54, 116), 11, PALETTE.COOL_WHITE)
	_back_layer.add_child(_box("PosterRight", Rect2(866, 116, 54, 116), PALETTE.SIGNAL_RED, PALETTE.CARBON, 2))
	_add_centered_label(_back_layer, "CARD\nPOSTER", Rect2(866, 116, 54, 116), 11, PALETTE.COOL_WHITE)


func _build_shop_kiosk() -> void:
	var kiosk := _box("ShopKiosk", Rect2(45, 276, 360, 284), Color("#C9D2DB"), PALETTE.EMERALD, 5)
	_mid_layer.add_child(kiosk)
	_add_centered_label(_mid_layer, "CARD SHOP KIOSK", Rect2(62, 292, 326, 40), 23, PALETTE.CARBON)
	_mid_layer.add_child(_box("KioskComputer", Rect2(102, 352, 180, 76), PALETTE.GRAPHITE, PALETTE.ELECTRIC_CYAN, 4))
	_add_centered_label(_mid_layer, "COMPUTER\nCHECKOUT", Rect2(102, 352, 180, 76), 16, PALETTE.COOL_WHITE)
	for index in range(5):
		var card_rect := Rect2(72 + index * 60, 449, 45, 63)
		_mid_layer.add_child(_box("KioskCard%d" % index, card_rect, PALETTE.COOL_WHITE, [PALETTE.SIGNAL_RED, PALETTE.EMERALD, PALETTE.SELECTION_BLUE, PALETTE.SIGNAL_YELLOW, PALETTE.INTERFACE_VIOLET][index], 2))
		_add_centered_label(_mid_layer, "CARD", card_rect, 10, PALETTE.CARBON)
	var shop_button := TOPDECK_UI.make_button("OPEN SHOP", "confirm", Vector2(238, 46), "HubShopButton")
	shop_button.position = Vector2(104, 514)
	shop_button.pressed.connect(func() -> void: shop_requested.emit())
	_mid_layer.add_child(shop_button)


func _build_vending_machine() -> void:
	var machine := _box("VendingMachine", Rect2(478, 286, 292, 330), PALETTE.GRAPHITE, PALETTE.SIGNAL_YELLOW, 6)
	_mid_layer.add_child(machine)
	_add_centered_label(_mid_layer, "PLAYER BREAK MACHINE", Rect2(494, 301, 260, 36), 18, PALETTE.COOL_WHITE)
	_vending_status = _make_label("ONE USE THIS FLOOR", 14, PALETTE.SIGNAL_YELLOW)
	_vending_status.name = "HubVendingStatus"
	_vending_status.position = Vector2(502, 342)
	_vending_status.size = Vector2(244, 30)
	_vending_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mid_layer.add_child(_vending_status)
	_mid_layer.add_child(_box("VendingWindow", Rect2(510, 379, 228, 72), PALETTE.CARBON, PALETTE.STEEL, 3))
	_add_centered_label(_mid_layer, "CHOOSE ONE OPTION\nMACHINE LOCKS AFTER USE", Rect2(510, 379, 228, 72), 13, PALETTE.TEXT_SECONDARY)

	_heal_button = TOPDECK_UI.make_button("HEAL +8 LIFE", "confirm", Vector2(228, 48), "HubVendingHealButton")
	_heal_button.position = Vector2(510, 468)
	_heal_button.pressed.connect(func() -> void: heal_requested.emit())
	_mid_layer.add_child(_heal_button)
	_upgrade_button = TOPDECK_UI.make_button("UPGRADE 1 CARD", "special", Vector2(228, 48), "HubVendingUpgradeButton")
	_upgrade_button.position = Vector2(510, 526)
	_upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	_mid_layer.add_child(_upgrade_button)

	_out_of_order = PanelContainer.new()
	_out_of_order.name = "HubVendingOutOfOrder"
	_out_of_order.position = Vector2(510, 468)
	_out_of_order.size = Vector2(228, 106)
	_out_of_order.add_theme_stylebox_override("panel", _style(PALETTE.CARBON, PALETTE.SIGNAL_RED, 4, 4))
	var out_label := _make_label("OUT OF ORDER\nBREAK ALREADY USED", 19, PALETTE.SIGNAL_RED)
	out_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	out_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_out_of_order.add_child(out_label)
	_mid_layer.add_child(_out_of_order)


func _build_match_table() -> void:
	_front_layer.add_child(_box("SpectatorRail", Rect2(806, 300, 436, 18), PALETTE.STEEL, PALETTE.CARBON, 2))
	var table := _box("MatchTable", Rect2(845, 433, 348, 170), PALETTE.TOURNAMENT_WOOD_BASE, PALETTE.GRAPHITE, 8)
	_front_layer.add_child(table)
	_add_centered_label(_front_layer, "TABLE 2  •  MATCH IN PROGRESS", Rect2(884, 397, 270, 28), 14, PALETTE.CARBON)
	for index in range(4):
		var table_card := Rect2(925 + (index % 2) * 58, 447 + (index / 2) * 80, 42, 60)
		_front_layer.add_child(_box("TableCard%d" % index, table_card, PALETTE.COOL_WHITE, PALETTE.SELECTION_BLUE if index < 2 else PALETTE.SIGNAL_RED, 2))

	_front_layer.add_child(_circle("PlayerAHead", Rect2(810, 358, 70, 70), Color("#D8A07F"), PALETTE.CARBON))
	_front_layer.add_child(_box("PlayerABody", Rect2(798, 412, 94, 122), PALETTE.SELECTION_BLUE, PALETTE.CARBON, 5))
	_add_centered_label(_front_layer, "PLAYER A", Rect2(790, 535, 110, 25), 12, PALETTE.CARBON)
	_front_layer.add_child(_circle("PlayerBHead", Rect2(1152, 358, 70, 70), Color("#C98B6A"), PALETTE.CARBON))
	_front_layer.add_child(_box("PlayerBBody", Rect2(1140, 412, 94, 122), PALETTE.SIGNAL_RED, PALETTE.CARBON, 5))
	_add_centered_label(_front_layer, "PLAYER B", Rect2(1132, 535, 110, 25), 12, PALETTE.CARBON)


func _build_hud() -> void:
	var ui_layer := Control.new()
	ui_layer.name = "HubInterfaceLayer"
	ui_layer.size = DESIGN_SIZE
	ui_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(ui_layer)
	ui_layer.add_child(_box("HubTopBar", Rect2(0, 0, 1280, 66), PALETTE.CARBON, PALETTE.ELECTRIC_CYAN, 0))
	_add_centered_label(ui_layer, "LOCALS", Rect2(18, 12, 160, 42), 25, PALETTE.COOL_WHITE)
	_round_label = _make_hud_chip(ui_layer, "ROUND 1 / 4", Rect2(205, 13, 184, 40), PALETTE.ELECTRIC_CYAN, "HubRoundLabel")
	_life_label = _make_hud_chip(ui_layer, "LIFE 40 / 40", Rect2(410, 13, 190, 40), PALETTE.SIGNAL_RED, "HubLifeLabel")
	_funds_label = _make_hud_chip(ui_layer, "$8", Rect2(621, 13, 130, 40), PALETTE.EMERALD, "HubFundsLabel")
	_deck_label = _make_hud_chip(ui_layer, "LOCKED DECK", Rect2(772, 13, 254, 40), PALETTE.STRUCTURAL_EDGE, "HubDeckLabel")
	var save := TOPDECK_UI.make_button("SAVE", "secondary", Vector2(98, 40), "HubSaveButton")
	save.position = Vector2(1042, 13)
	save.pressed.connect(func() -> void: save_requested.emit())
	ui_layer.add_child(save)
	var settings := TOPDECK_UI.make_button("OPTIONS", "secondary", Vector2(110, 40), "HubSettingsButton")
	settings.position = Vector2(1150, 13)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	ui_layer.add_child(settings)

	_notice_label = _make_label("LOCALS", 12, PALETTE.CARBON)
	_notice_label.name = "HubNoticeLabel"
	_notice_label.position = Vector2(24, 657)
	_notice_label.size = Vector2(380, 50)
	_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_layer.add_child(_notice_label)

	_next_round_button = TOPDECK_UI.make_button("NEXT ROUND", "primary", Vector2(420, 76), "HubNextRoundButton")
	_next_round_button.position = Vector2(430, 626)
	_next_round_button.add_theme_font_override("font", DISPLAY_FONT)
	_next_round_button.add_theme_font_size_override("font_size", 19)
	_next_round_button.pressed.connect(func() -> void: next_round_requested.emit())
	ui_layer.add_child(_next_round_button)


func _layout_canvas() -> void:
	if _canvas == null:
		return
	var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var canvas_scale := minf(safe_size.x / DESIGN_SIZE.x, safe_size.y / DESIGN_SIZE.y)
	_canvas.scale = Vector2.ONE * canvas_scale
	_canvas.position = (safe_size - DESIGN_SIZE * canvas_scale) * 0.5


func _make_layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.size = DESIGN_SIZE
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	return layer


func _box(node_name: String, rect: Rect2, fill: Color, edge: Color, border_width: int = 2) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, edge, border_width, 3))
	return panel


func _circle(node_name: String, rect: Rect2, fill: Color, edge: Color) -> Panel:
	var panel := _box(node_name, rect, fill, edge, 3)
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	var radius := roundi(minf(rect.size.x, rect.size.y) * 0.5)
	style.set_corner_radius_all(radius)
	return panel


func _style(fill: Color, edge: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius + 5
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius + 5
	return style


func _add_centered_label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", BODY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_hud_chip(parent: Node, text: String, rect: Rect2, accent: Color, node_name: String) -> Label:
	var chip := _make_label(text, 15, PALETTE.COOL_WHITE)
	chip.name = node_name
	chip.position = rect.position
	chip.size = rect.size
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_theme_stylebox_override("normal", TOPDECK_UI.stat_chip_style(accent))
	parent.add_child(chip)
	return chip
