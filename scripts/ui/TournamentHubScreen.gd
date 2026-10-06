extends Control
class_name TournamentHubScreen

## Behavior controller for the editable TournamentHubScreen.tscn scene.
## Layout, artwork, styles, and starting copy live in the scene so they can be
## repositioned visually in Godot without changing this script.

signal shop_requested
signal deck_requested
signal seller_requested
signal machine_requested
signal shop_closed
signal buy_requested(card_id: String)
signal reroll_requested(expected_cost: int)
signal remove_requested
signal heal_requested
signal upgrade_requested
signal seller_upgrade_requested
signal next_round_requested
signal save_requested
signal settings_requested

const DESIGN_SIZE := Vector2(1280, 720)
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")
const CARD_FACE := preload("res://scripts/CardFace.gd")
const UI := preload("res://scripts/ui/TopdeckUIComponents.gd")
const LOCALS_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")
const SHOP_VIEW := preload("res://scripts/ui/HubCounterShopView.gd")
const TOURNAMENT_SLIP := preload("res://scripts/ui/TournamentSlip.gd")
const DECKBOX_DISPLAY := preload("res://scripts/ui/DeckboxDisplay.gd")
const MODAL := preload("res://scripts/ui/GameModal.gd")
const SHOP_ZOOM := 2.15
const SELLER_ZOOM := 1.8
const MACHINE_ZOOM := 2.7
const SNACK_VIEW := preload("res://scripts/ui/HubVendingSnackView.gd")
const ZOOM_SECONDS := 0.72
const PANEL_DELAY_SECONDS := 0.10
const PARALLAX_FREQUENCY := 7.5
const SYMBOLS := preload("res://scripts/ui/MaterialSymbolsSharp.gd")
const HEART_BITES := preload("res://assets/illustrations/supplied_locals_2026_09_14/heart_bites.png")
const FOIL_CRUNCH := preload("res://assets/illustrations/supplied_locals_2026_09_14/foil_crunch.png")
const AREA_HIGHLIGHT := preload("res://assets/shaders/shop_area_highlight.gdshader")

var _snapshot: Dictionary = {}
var _canvas: Control
# Node2D preserves fractional motion; Control rounds translations to whole
# pixels in the renderer even when its position property stays fractional.
var _back_layer: Node2D
var _mid_layer: Node2D
var _front_layer: Node2D
var _display_window: Control
var _display_faces: Array[Control] = []
var _round_label: Label
var _life_label: Label
var _funds_label: Label
var _deck_label: Label
var _deck_button: Button
var _notice_label: Label
var _vending_status: Label
var _heal_button: Button
var _upgrade_button: Button
var _out_of_order: PanelContainer
var _next_round_button: Button
var _reduced_motion := false
var _parallax_target := Vector2.ZERO
var _parallax_position := Vector2.ZERO
var _parallax_velocity := Vector2.ZERO
var _room_camera: Node2D
var _shop_view: Control
var _seller_view: Control
var _machine_view: Control
var _machine_services: Control
var _snack_view: Control
var _machine_button: Button
var _machine_hint: Label
var _machine_used_sign: Label
var _seller_services: Control
var _seller_art: TextureRect
var _seller_button: Button
var _seller_hint: Label
var _seller_upgrade_button: Button
var _view_switch_button: Button
var _room_return_focus: Button
var _room_keyboard_highlight := false
var _shop_back: Button
var _reroll_button: Button
var _reroll_hint: Label
var _remove_button: Button
var _shop_open := false
var _seller_open := false
var _machine_open := false
var _shop_zoom := 0.0
var _seller_zoom := 0.0
var _machine_zoom := 0.0
var _zoom_tween: Tween
var _transitioning := false
var _extra_height := 0.0
var _tournament_slip: Control
var _deckbox_button: Button
var _deckbox_art: Control
var _deckbox_name: Label
var _deckbox_effect: Label
var _deckbox_inspection: Control
var _table_receipt: Control
var _cabinet_snacks: Array[TextureRect] = []


func _ready() -> void:
	_bind_scene_nodes()
	if not _scene_is_complete():
		set_process(false)
		return
	_create_shop_view()
	_create_machine_view()
	_connect_scene_actions()
	_apply_production_style()
	_create_tournament_kit()
	_create_deck_button()
	_create_room_highlights()
	_layout_painted_status()
	resized.connect(_layout_canvas)
	_layout_canvas()
	refresh(_snapshot)
	set_process(true)


func configure(snapshot: Dictionary, reduced_motion: bool = false) -> void:
	_snapshot = snapshot.duplicate(true)
	_reduced_motion = reduced_motion
	if is_node_ready():
		refresh(_snapshot)
		if _reduced_motion and _transitioning:
			_set_view("machine" if _machine_open else "seller" if _seller_open else "counter" if _shop_open else "room", false)


func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if _round_label == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	_refresh_shop_cards()
	_refresh_held_card()
	var round_number := int(_snapshot.get("round", 1))
	var total_rounds := maxi(1, int(_snapshot.get("total_rounds", 4)))
	var life := int(_snapshot.get("life", 0))
	var max_life := maxi(1, int(_snapshot.get("max_life", 40)))
	var floor_name := String(_snapshot.get("floor", "Locals")).to_upper()
	(find_child("HubFloorLabel", true, false) as Label).text = floor_name
	_round_label.text = "WEEK %d · ROUND %d/%d" % [int(_snapshot.get("week", 1)), round_number, total_rounds]
	_round_label.add_theme_font_size_override("font_size", 16)
	(find_child("HubRoundProgress", true, false)).configure(round_number, bool(_snapshot.get("break_used", false)), total_rounds)
	_tournament_slip.configure(int(_snapshot.get("week", 1)), round_number, total_rounds, floor_name)
	_update_round_board(round_number)
	_life_label.text = "%d / %d" % [life, max_life]
	_life_label.add_theme_color_override("font_color", PALETTE.SIGNAL_RED.darkened(0.24) if life <= max_life / 4 else PALETTE.PEACH_INK)
	_funds_label.text = "$%d" % int(_snapshot.get("money", 0))
	_funds_label.add_theme_color_override("font_color", PALETTE.PEACH_INK)
	_deck_label.text = "%d cards" % int(_snapshot.get("deck_count", 0))
	var next_label := String(_snapshot.get("next_label", "Report to the next table"))
	_next_round_button.text = "Next Round"
	(find_child("HubNextMatchLabel", true, false) as Label).text = next_label
	(find_child("HubNextEyebrow", true, false) as Label).text = "UP NEXT  /  ROUND %02d" % round_number
	var notice := String(_snapshot.get("notice", ""))
	show_notice(notice)
	_refresh_deckbox()

	var break_used := bool(_snapshot.get("break_used", false))
	var break_choice := String(_snapshot.get("break_choice", ""))
	_heal_button.text = "Heal %d HP" % int(_snapshot.get("bye_heal", 5))
	_heal_button.tooltip_text = "Your life is already full." if life >= max_life else "Heart Bites: recover life now, or save your one weekly bye for Foil Crunch and a card upgrade."
	_upgrade_button.tooltip_text = "No eligible cards to upgrade." if not bool(_snapshot.get("can_upgrade", true)) and not break_used else "Foil Crunch: choose one card to upgrade for free. Cancelling keeps your weekly bye available."
	_snack_view._reduced_motion = _reduced_motion
	_snack_view.configure(_snapshot)
	_out_of_order.visible = break_used
	_machine_used_sign.visible = break_used
	for snack in _cabinet_snacks:
		snack.modulate.a = 0.35 if break_used else 1.0
	(find_child("VendingInstructionLabel", true, false) as Label).hide()
	_vending_status.text = "Your free bye is used for this week." if break_used else "One choice. On the house."
	(find_child("VendingTitleLabel", true, false) as Label).text = "Take a breather"
	_vending_status.add_theme_color_override("font_color", PALETTE.PEACH_INK_SOFT if break_used else PALETTE.PEACH_INK)
	(find_child("HubByeHint", true, false) as Label).text = ("Card upgraded" if break_choice == "upgrade" else "Life restored") if break_used else "Heal or upgrade · one shared weekly use"
	_machine_button.tooltip_text = "Your free bye is used for this week." if break_used else "Take your one free bye: heal or upgrade a card."
	_machine_button.accessibility_name = "Vending machine. " + _machine_button.tooltip_text
	(find_child("VendingMachineBody", true, false) as Control).self_modulate = Color.WHITE
	var shop_button := find_child("HubShopButton", true, false) as Button
	var stock_count := (_snapshot.get("shop_cards", []) as Array).size()
	shop_button.text = ""
	shop_button.tooltip_text = "Browse %d cards. Purchases go straight into your deck." % stock_count if stock_count > 0 else "Singles case · Sold out"
	shop_button.accessibility_name = "Display case. " + shop_button.tooltip_text
	_next_round_button.tooltip_text = "Begin the next match with your current life and deck."
	_shop_view._reduced_motion = _reduced_motion
	if _seller_art.reduced_motion != _reduced_motion:
		_seller_art.set_reduced_motion(_reduced_motion)
	_shop_view.configure(_snapshot)
	_update_shop_chrome()
	_update_focus_order()
	_apply_camera_pose()
	if is_instance_valid(focused) and focused is Button and (not focused.is_visible_in_tree() or focused.disabled):
		(_shop_back if _shop_open or _seller_open or _machine_open else _next_round_button).grab_focus()


func show_notice(message: String, positive: bool = false) -> void:
	_notice_label.text = message
	_notice_label.visible = not message.is_empty()
	_notice_label.tooltip_text = message
	_notice_label.add_theme_color_override("font_color", PALETTE.PEACH_TEAL if positive else PALETTE.PEACH_INK_SOFT)
	_layout_table_receipt()


func _panel_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := SHAPES.style(fill, Vector4.ZERO)
	style.border_color = edge
	style.set_border_width_all(0)
	style.set_corner_radius_all(7)
	return style


func _apply_production_style() -> void:
	for node in find_children("*", "Label", true, false):
		var label := node as Label
		# Style the authored room labels, not typography inside live card faces.
		if label.owner != self:
			continue
		label.add_theme_font_override("font", LOCALS_FONT)
		label.add_theme_color_override("font_color", PALETTE.PEACH_INK)
		label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		label.add_theme_constant_override("outline_size", 0)
	for node_name in ["HubLifeLabel", "HubFundsLabel", "HubDeckLabel"]:
		var label := find_child(node_name, true, false) as Label
		label.add_theme_stylebox_override("normal", UI.stat_chip_style(PALETTE.PEACH_INK))
	var life_style := UI.stat_chip_style(PALETTE.PEACH_INK)
	life_style.content_margin_left = 48.0
	_life_label.add_theme_stylebox_override("normal", life_style)
	_life_label.tooltip_text = "Life remaining / maximum life. Life carries between rounds."
	_deck_label.tooltip_text = "Purchases and rewards join your run deck. The shopkeeper can remove one card for $3."
	for label in [_life_label, _deck_label, _notice_label]:
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	_add_stat_icon(_life_label, "HubLifeHeart", "heart", PALETTE.SIGNAL_RED.darkened(0.20))
	var deck_style := UI.stat_chip_style(PALETTE.PEACH_INK)
	deck_style.content_margin_left = 32.0
	_deck_label.add_theme_stylebox_override("normal", deck_style)
	_add_stat_icon(_deck_label, "HubDeckIcon", "cards", PALETTE.PEACH_INK_SOFT)
	for node_name in ["HubTopBar", "HubActionBar"]:
		(find_child(node_name, true, false) as Panel).add_theme_stylebox_override("panel", _panel_style(PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE))
	var service_style := UI.flat_style(PALETTE.PEACH_PAPER)
	service_style.border_color = PALETTE.PEACH_INK
	service_style.set_border_width_all(2)
	service_style.set_corner_radius_all(6)
	service_style.shadow_color = Color(PALETTE.PEACH_INK, 0.22)
	service_style.shadow_size = 1
	service_style.shadow_offset = Vector2(0, 3)
	(find_child("HubSellerServicesBacking", true, false) as Panel).add_theme_stylebox_override("panel", service_style)
	_seller_hint.add_theme_stylebox_override("normal", UI.flat_style(PALETTE.PEACH_PAPER, 4))
	for hint_name in ["HubSellerUpgradeHint", "HubSellerRemoveHint"]:
		(find_child(hint_name, true, false) as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK_SOFT)
	for hint_name in ["HubSellerServicesEyebrow", "HubSellerServicesWelcome"]:
		(find_child(hint_name, true, false) as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK_SOFT)
	for node_name in ["HubAreaEyebrow", "HubNextEyebrow", "HubNoticeLabel", "HubNextRoundHint", "HubByeHint"]:
		(find_child(node_name, true, false) as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK_SOFT)
	(find_child("HubRoundBoardTitle", true, false) as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK)
	var machine_title := find_child("VendingTitleLabel", true, false) as Label
	var title_style := UI.stat_chip_style(PALETTE.PEACH_EDGE)
	title_style.bg_color = PALETTE.PEACH_PAPER
	machine_title.add_theme_stylebox_override("normal", title_style)
	for node_name in ["HubVendingStatus", "VendingInstructionLabel", "HubByeHint"]:
		var paper_label := _panel_style(PALETTE.PEACH_PAPER_MUTED, Color.TRANSPARENT)
		paper_label.set_border_width_all(0)
		paper_label.shadow_size = 0
		(find_child(node_name, true, false) as Label).add_theme_stylebox_override("normal", paper_label)
	(find_child("HubRootFill", true, false) as ColorRect).color = PALETTE.PEACH_TABLE
	var used_style := _panel_style(PALETTE.PEACH_PAPER, PALETTE.SIGNAL_RED.darkened(0.24))
	used_style.set_border_width_all(3)
	used_style.content_margin_top = 10
	used_style.content_margin_bottom = 10
	_out_of_order.add_theme_stylebox_override("panel", used_style)
	(find_child("HubVendingOutOfOrderLabel", true, false) as Label).add_theme_color_override("font_color", PALETTE.ACTION_DANGER.darkened(0.24))
	SYMBOLS.apply_to_button(_next_round_button, "forward", 22, HORIZONTAL_ALIGNMENT_RIGHT)
	SYMBOLS.apply_to_button(find_child("HubSaveButton", true, false) as Button, "save", 18)
	(find_child("HubSettingsButton", true, false) as Button).tooltip_text = "Game settings and accessibility"
	# Keep the authored rectangles and text layout; only the visible paper edge
	# uses the same steady ink contour as the battle interface.
	for node_name in ["HubTopBar", "HubActionBar", "HubSellerServicesBacking", "HubRoundBoard"]:
		_ink_paper(find_child(node_name, true, false) as Control, PALETTE.PEACH_PAPER)
	_ink_paper(_seller_hint, PALETTE.PEACH_PAPER, PALETTE.PEACH_EDGE, false, 1.0)
	_ink_paper(_out_of_order, PALETTE.PEACH_PAPER, PALETTE.ACTION_DANGER.darkened(0.24), true, 2.0)
	_polish_hud_and_services()


func _polish_hud_and_services() -> void:
	# Live values share one painted status shape; no framed chips or caption rail.
	for item in [[_life_label, 36.0], [_funds_label, 0.0], [_deck_label, 32.0]]:
		var label := item[0] as Label
		var spacing := StyleBoxEmpty.new()
		spacing.content_margin_left = float(item[1])
		label.add_theme_stylebox_override("normal", spacing)
		label.add_theme_font_size_override("font_size", 21 if label != _deck_label else 19)
		label.minimum_size_changed.connect(_layout_painted_status)
		for icon in label.get_children():
			if icon is TextureRect:
				icon.position = Vector2(10, 8)
	for node_name in ["HubSaveButton", "HubSettingsButton", "HubShopViewSwitchButton", "RouteShopContinueButton"]:
		var button := find_child(node_name, true, false) as Button
		button.set_meta("ui_button_variant", "light")
		button.set_meta("ui_button_shape", "round")
	(find_child("HubSaveButton", true, false) as Button).text = "Save"
	(find_child("HubSettingsButton", true, false) as Button).text = "Settings"
	for button in [_next_round_button, _seller_upgrade_button, _remove_button, _heal_button, _upgrade_button]:
		button.set_meta("ui_button_shape", "round")
	_seller_upgrade_button.set_meta("ui_button_variant", "primary")
	# This opens the removal picker; its destructive confirmation stays in that
	# picker. The browsing service need not dominate the room in alarm red.
	_remove_button.set_meta("ui_button_variant", "primary")
	SYMBOLS.apply_to_button(_remove_button, "close", 20)
	_upgrade_button.set_meta("ui_button_variant", "primary")
	_heal_button.set_meta("ui_button_variant", "primary")
	SYMBOLS.apply_to_button(_seller_upgrade_button, "upgrade", 20)
	SYMBOLS.apply_to_button(_shop_back, "back", 18)
	SYMBOLS.apply_to_button(find_child("HubSettingsButton", true, false) as Button, "settings", 18)
	for node_name in ["VendingTitleLabel", "HubVendingStatus", "VendingInstructionLabel", "HubByeHint"]:
		(find_child(node_name, true, false) as Label).add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var service_backing := find_child("HubSellerServicesBacking", true, false) as Control
	service_backing.set_meta("cozy_service_slip", true)
	var machine_backing := find_child("HubMachineServicesBacking", true, false) as Control
	machine_backing.set_meta("cozy_service_slip", true)
	for backing in [service_backing, machine_backing]:
		_ink_paper(backing, PALETTE.PEACH_PAPER, PALETTE.PEACH_INK_SOFT)
	for rail_name in ["HubTopBar", "HubActionBar"]:
		var rail := find_child(rail_name, true, false) as Control
		rail.set_meta("cozy_info_rail", true)
		(rail.get_node("WarmSketchPaper") as Control).queue_redraw()


func _create_tournament_kit() -> void:
	var interface := find_child("HubInterfaceLayer", true, false) as Control
	# One compact status group holds venue, round, life, money and the live deck.
	# Legacy named labels remain available to the existing screen contracts.
	for node_name in ["HubAreaEyebrow", "HubFloorLabel", "HubRoundLabel", "HubRoundProgress", "HubRoundBoard", "HubActionBar"]:
		(find_child(node_name, true, false) as Control).hide()
	_tournament_slip = TOURNAMENT_SLIP.new()
	_tournament_slip.name = "HubTournamentSlip"
	_tournament_slip.header_only = true
	_tournament_slip.position = Vector2(744, 21)
	_tournament_slip.size = Vector2(512, 36)
	interface.add_child(_tournament_slip)
	_deckbox_button = Button.new()
	_deckbox_button.name = "HubDeckboxButton"
	_deckbox_button.position = Vector2(760, 116)
	_deckbox_button.size = Vector2(480, 54)
	_deckbox_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_deckbox_button.set_meta("ui_button_style_exempt", true)
	for state in ["normal", "pressed", "disabled"]:
		_deckbox_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var hover_style := SHAPES.style(PALETTE.PEACH_MINT, Vector4.ZERO)
	_deckbox_button.add_theme_stylebox_override("hover", hover_style)
	var focus_style := SHAPES.style(Color.TRANSPARENT, Vector4.ZERO)
	focus_style.set_border_width_all(2)
	focus_style.border_color = PALETTE.PEACH_TEAL
	_deckbox_button.add_theme_stylebox_override("focus", focus_style)
	_deckbox_button.pressed.connect(_inspect_deckbox)
	interface.add_child(_deckbox_button)
	_deckbox_art = DECKBOX_DISPLAY.new()
	_deckbox_art.name = "HubDeckboxObject"
	_deckbox_art.position = Vector2(1, 1)
	_deckbox_art.size = Vector2(52, 52)
	_deckbox_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deckbox_button.add_child(_deckbox_art)
	_deckbox_name = UI.make_label("", "body", PALETTE.PEACH_INK)
	_deckbox_name.name = "HubDeckboxName"
	_deckbox_name.position = Vector2(64, 3)
	_deckbox_name.size = Vector2(406, 24)
	_deckbox_name.add_theme_font_size_override("font_size", 17)
	_deckbox_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_deckbox_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_deckbox_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deckbox_button.add_child(_deckbox_name)
	_deckbox_effect = UI.make_label("", "caption", PALETTE.PEACH_INK_SOFT)
	_deckbox_effect.name = "HubDeckboxEffect"
	_deckbox_effect.position = Vector2(64, 30)
	_deckbox_effect.size = Vector2(406, 20)
	_deckbox_effect.add_theme_font_size_override("font_size", 13)
	_deckbox_effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_deckbox_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deckbox_button.add_child(_deckbox_effect)
	_table_receipt = Panel.new()
	_table_receipt.name = "HubTableReceipt"
	_table_receipt.position = Vector2(326, 646)
	_table_receipt.size = Vector2(366, 60)
	_table_receipt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(_table_receipt)
	interface.move_child(_table_receipt, (find_child("HubActionBar", true, false) as Control).get_index() + 1)
	# These authored utilities used to sit in the header. Keep them above the
	# footer's paper after moving them alongside the next-table receipt.
	for node_name in ["HubSaveButton", "HubSettingsButton"]:
		interface.move_child(find_child(node_name, true, false), interface.get_child_count() - 1)
	_table_receipt.set_meta("cozy_table_receipt", true)
	_ink_paper(_table_receipt, PALETTE.PEACH_PAPER, PALETTE.PEACH_INK_SOFT, true, 1.1)
	_seller_hint.hide()
	(find_child("HubSellerServicesTitle", true, false) as Label).text = "A little tune-up?"
	(find_child("HubSellerServicesEyebrow", true, false) as Label).hide()
	(find_child("HubSellerServicesWelcome", true, false) as Label).hide()
	(find_child("HubSellerUpgradeHint", true, false) as Label).text = "Once this week"
	(find_child("HubSellerRemoveHint", true, false) as Label).text = "Once this round"
	for label_name in ["HubSellerUpgradeHint", "HubSellerRemoveHint"]:
		(find_child(label_name, true, false) as Label).add_theme_font_size_override("font_size", 15)
	(find_child("HubNextMatchLabel", true, false) as Label).add_theme_font_size_override("font_size", 17)
	(find_child("HubNextEyebrow", true, false) as Label).add_theme_font_size_override("font_size", 22)
	# This caption now sits directly on the painted floor, so use full ink.
	(find_child("HubNextEyebrow", true, false) as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK)
	(find_child("HubNextRoundHint", true, false) as Label).add_theme_font_size_override("font_size", 11)
	_vending_status.add_theme_font_size_override("font_size", 17)
	(find_child("HubByeHint", true, false) as Label).add_theme_font_size_override("font_size", 15)
	for node_name in ["HubNextEyebrow", "HubNextMatchLabel", "HubNoticeLabel"]:
		(find_child(node_name, true, false) as Label).minimum_size_changed.connect(_layout_table_receipt)
	_next_round_button.position = Vector2(408, 628)
	_next_round_button.size = Vector2(464, 76)
	_next_round_button.add_theme_font_size_override("font_size", 28)
	_layout_table_receipt()


func _layout_table_receipt() -> void:
	if not is_instance_valid(_table_receipt):
		return
	var closeup := _shop_open or _seller_open or _machine_open
	var heading := find_child("HubNextEyebrow", true, false) as Label
	var next_match := find_child("HubNextMatchLabel", true, false) as Label
	heading.hide()
	next_match.hide()
	heading.position = Vector2(708, 658 + _extra_height)
	heading.size = Vector2(214, 36)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_table_receipt.visible = _notice_label.visible and not closeup
	var notice_height := maxf(50, _notice_label.get_minimum_size().y + 20)
	_table_receipt.position = Vector2(16, 710 + _extra_height - notice_height)
	_table_receipt.size = Vector2(380, notice_height)
	_notice_label.position = _table_receipt.position + Vector2(12, 10)
	_notice_label.size = Vector2(356, notice_height - 20)
	_notice_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Close-up navigation has its own actions; persistent notices remain readable.
	if closeup:
		_notice_label.position = Vector2(22 if _shop_open else 570, 646 + _extra_height)
		_notice_label.size = Vector2(356, 54)
		_ink_paper(_notice_label, PALETTE.PEACH_PAPER)
	else:
		var notice_backing := _notice_label.get_node_or_null("WarmSketchPaper") as Control
		if notice_backing != null:
			notice_backing.hide()


func _layout_painted_status() -> void:
	if not is_instance_valid(_tournament_slip) or not is_instance_valid(_deck_button):
		return
	var status := find_child("HubTopBar", true, false) as Control
	var status_x := 14.0
	var header_height := maxf(36, _tournament_slip.get_combined_minimum_size().y)
	_tournament_slip.position = Vector2(status_x, 20)
	_tournament_slip.size = Vector2(512, header_height)
	var row_y := 24 + header_height
	var row_height := maxf(44, maxf(_life_label.get_minimum_size().y, maxf(_funds_label.get_minimum_size().y, _deck_label.get_minimum_size().y)) + 8)
	_life_label.position = Vector2(status_x + 18, row_y)
	_life_label.size = Vector2(156, row_height)
	_funds_label.position = Vector2(status_x + 184, row_y)
	_funds_label.size = Vector2(114, row_height)
	_deck_label.position = Vector2(status_x + 314, row_y)
	_deck_label.size = Vector2(184, row_height)
	_deck_button.position = _deck_label.position
	_deck_button.size = _deck_label.size
	_deckbox_button.position = Vector2(status_x + 16, row_y + row_height + 6)
	status.position = Vector2(status_x, 14)
	status.size = Vector2(512, row_y + row_height - 2 + (62 if _deckbox_button.visible else 0))
	var save := find_child("HubSaveButton", true, false) as Button
	var settings := find_child("HubSettingsButton", true, false) as Button
	settings.position = Vector2(DESIGN_SIZE.x - 24 - settings.size.x, 20)
	save.position = Vector2(settings.position.x - 12 - save.size.x, 20)
	_layout_room_kiosk(status)


func _layout_room_kiosk(status: Control) -> void:
	# Keep Mina's entire portrait below the status, and the cabinet above the
	# primary action. Taller windows retain the supplied furniture's full size.
	var kiosk := find_child("ShopKiosk", true, false) as Control
	var top := status.position.y + status.size.y + 12.0
	var bottom := 628.0 + _extra_height - 12.0
	# Keep the room fit anchored while Mina sits lower, over the countertop.
	var artwork_top := 82.0
	var artwork_bottom := (find_child("HubShopDesk", true, false) as Control).get_rect().end.y
	var fit := minf(1.0, (bottom - top) / (artwork_bottom - artwork_top))
	kiosk.scale = Vector2.ONE * fit
	kiosk.position = Vector2(lerpf(12, -24, clampf(_extra_height / 80.0, 0.0, 1.0)), top - artwork_top * fit)


func _refresh_deckbox() -> void:
	var box: Dictionary = _snapshot.get("deckbox", {})
	_deckbox_button.visible = not box.is_empty()
	_deckbox_button.disabled = box.is_empty() or _transitioning
	_layout_painted_status()
	if box.is_empty():
		return
	_deckbox_art.configure(box)
	_deckbox_name.text = String(box.get("name", "Deckbox"))
	_deckbox_effect.text = _deckbox_summary(box)
	_deckbox_button.tooltip_text = "%s\n%s\nInspect your active run bonus." % [String(box.get("name", "Deckbox")), String(box.get("description", ""))]


func _create_deck_button() -> void:
	# The caption, sleeve icon and live count form one keyboard-accessible target.
	_deck_button = Button.new()
	_deck_button.name = "HubDeckButton"
	_deck_button.position = Vector2(_deck_label.position.x, 18)
	_deck_button.size = Vector2(_deck_label.size.x, 60)
	_deck_button.tooltip_text = "View cards in your deck"
	_deck_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_deck_button.set_meta("ui_button_style_exempt", true)
	for state in ["normal", "pressed", "disabled"]:
		_deck_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_deck_button.add_theme_stylebox_override("hover", _panel_style(PALETTE.PEACH_MINT, PALETTE.PEACH_TEAL))
	var focus_style := _panel_style(Color.TRANSPARENT, PALETTE.PEACH_TEAL)
	focus_style.set_border_width_all(2)
	_deck_button.add_theme_stylebox_override("focus", focus_style)
	_deck_button.pressed.connect(func() -> void:
		if not _transitioning:
			_deck_button.grab_focus()
			deck_requested.emit()
	)
	var interface := _deck_label.get_parent()
	interface.add_child(_deck_button)
	# Keep the live text and icon above the button's hover/focus paper.
	interface.move_child(_deck_button, _deck_label.get_index())
	_deck_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_label.tooltip_text = ""


func _deckbox_summary(box: Dictionary) -> String:
	var effects: Dictionary = box.get("effects", {})
	# Big Lunch's on-choice healing must not read as repeatable recovery.
	if effects.has("max_life"):
		return "+%d maximum life" % int(effects.max_life)
	if effects.has("match_money"):
		return "+$%d after each game" % int(effects.match_money)
	if effects.has("reshuffle_damage_reduction"):
		return "−%d reshuffle damage" % int(effects.reshuffle_damage_reduction)
	var reward: Dictionary = _snapshot.get("deckbox_reward", {})
	if effects.has("remove_cards") or effects.has("upgrade_cards"):
		return "%d cards %s" % [int(reward.get("applied", 0)), "removed" if effects.has("remove_cards") else "upgraded"]
	return String(box.get("description", "Inspect run bonus"))


func _inspect_deckbox() -> void:
	var box: Dictionary = _snapshot.get("deckbox", {})
	if box.is_empty() or is_instance_valid(_deckbox_inspection) or _transitioning:
		return
	_deckbox_inspection = MODAL.create(self, String(box.get("name", "Your deckbox")), "HubDeckboxInspection", func() -> void:
		_deckbox_inspection = null
	)
	var row := HBoxContainer.new()
	row.name = "HubDeckboxInspectionRow"
	row.add_theme_constant_override("separation", 24)
	_deckbox_inspection.body.add_child(row)
	var art := DECKBOX_DISPLAY.new()
	art.name = "HubInspectedDeckboxObject"
	art.custom_minimum_size = Vector2(130, 130)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.configure(box)
	row.add_child(art)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	row.add_child(details)
	var active := UI.make_label("YOUR ACTIVE RUN DECKBOX", "caption", PALETTE.PEACH_TEAL)
	details.add_child(active)
	var description := UI.make_label(String(box.get("description", "")), "body", PALETTE.PEACH_INK)
	description.name = "HubDeckboxExactEffect"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(description)
	var note := UI.make_label("Chosen after Week 1. This bonus stays with your run.", "caption", PALETTE.PEACH_INK_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(note)
	_fit_deckbox_inspection()


func _fit_deckbox_inspection() -> void:
	if not is_instance_valid(_deckbox_inspection):
		return
	var margin := _deckbox_inspection.get_child(1) as MarginContainer
	var horizontal := maxi(16, int((size.x - 660) * 0.5))
	var vertical := maxi(16, int((size.y - 350) * 0.5))
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % edge, horizontal)
	for edge in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % edge, vertical)


func _ink_paper(target: Control, fill: Color, ink: Color = PALETTE.PEACH_INK, shadow: bool = true, line_width: float = 1.6) -> void:
	var style_name := "normal" if target is Label else "panel"
	if target is Label or target is Panel or target is PanelContainer:
		var metrics := target.get_theme_stylebox(style_name).duplicate() as StyleBox
		var empty := StyleBoxEmpty.new()
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			empty.set_content_margin(side, metrics.get_content_margin(side))
		target.add_theme_stylebox_override(style_name, empty)
	var backing := target.get_node_or_null("WarmSketchPaper") as Control
	if backing == null:
		backing = Control.new()
		backing.name = "WarmSketchPaper"
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backing.show_behind_parent = true
		target.add_child(backing)
		backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backing.draw.connect(_draw_ink_paper.bind(backing))
		backing.resized.connect(backing.queue_redraw)
	backing.show()
	backing.set_meta("paper_fill", fill)
	backing.set_meta("paper_ink", ink)
	backing.set_meta("paper_shadow", shadow)
	backing.set_meta("paper_width", line_width)
	backing.queue_redraw()


func _draw_ink_paper(backing: Control) -> void:
	var rect := Rect2(Vector2(1, 1), backing.size - Vector2(2, 2))
	SHAPES.draw_surface(backing, rect, backing.get_meta("paper_fill"), 37, 8.0)


func _add_stat_icon(label: Label, node_name: String, symbol: String, color: Color) -> void:
	var icon := TextureRect.new()
	icon.name = node_name
	# Set expansion before assigning a full-resolution pack icon. Otherwise the
	# first minimum-size calculation can hold its source dimensions for a frame.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = SYMBOLS.icon(symbol)
	icon.modulate = color
	icon.position = Vector2(14, 11)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(22, 22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(icon)


func _update_round_board(current_round: int) -> void:
	var titles := ["Opening match", "Swiss rival", "Top Cut", "Locals final"]
	for index in range(titles.size()):
		var step := find_child("HubRoundStep%d" % index, true, false) as Label
		var completed := index + 1 < current_round
		var current := index + 1 == current_round
		step.text = "%s   %s" % ["DONE" if completed else "%02d" % (index + 1), titles[index]]
		step.add_theme_color_override("font_color", PALETTE.PEACH_PAPER if current else PALETTE.PEACH_TEAL if completed else PALETTE.PEACH_INK_SOFT)
		var style := StyleBoxFlat.new()
		style.bg_color = PALETTE.PEACH_TEAL.darkened(0.06) if current else Color.TRANSPARENT
		style.set_corner_radius_all(3)
		style.content_margin_left = 8
		style.border_width_bottom = 1
		style.border_color = PALETTE.PEACH_PAPER_MUTED
		step.add_theme_stylebox_override("normal", style)
		_ink_paper(step, PALETTE.PEACH_TEAL if current else PALETTE.PEACH_MINT if completed else PALETTE.PEACH_PAPER_MUTED, PALETTE.PEACH_INK if current else PALETTE.PEACH_EDGE, false, 1.0)


func _update_focus_order() -> void:
	var candidates: Array = [_seller_button, find_child("HubShopButton", true, false), _machine_button, _next_round_button]
	if _shop_open:
		candidates = [_shop_back, _view_switch_button, _reroll_button]
		candidates.append_array(_shop_view.focus_controls())
	elif _seller_open:
		candidates = [_shop_back, _seller_upgrade_button, _remove_button, _view_switch_button]
	elif _machine_open:
		candidates = [_shop_back]
		candidates.append_array(_snack_view.focus_controls())
	if is_instance_valid(_deck_button):
		candidates.append(_deck_button)
	if is_instance_valid(_deckbox_button):
		candidates.append(_deckbox_button)
	candidates.append_array([find_child("HubSaveButton", true, false), find_child("HubSettingsButton", true, false)])
	var controls: Array[Control] = []
	for node in candidates:
		if node.is_visible_in_tree() and not node.disabled:
			controls.append(node)
	for index in range(controls.size()):
		var control := controls[index]
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[(index - 1 + controls.size()) % controls.size()])


func _refresh_held_card() -> void:
	var holder := find_child("HubShopkeeperHeldCard", true, false) as Control
	var portrait := find_child("HubShopkeeper", true, false) as TextureRect
	# Supplied Mina already has her complete resting hands. Do not add a card at
	# the legacy clerk's old grip coordinates or repaint the supplied portrait.
	if portrait.has_meta("supplied_character_id"):
		holder.hide()
		return
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	var cards: Array = _snapshot.get("shop_cards", [])
	if portrait.texture == null:
		return
	var face: Control
	if cards.is_empty():
		var card_back := TextureRect.new()
		card_back.name = "HubShopkeeperCardBack"
		card_back.texture = preload("res://assets/cards/card_backs/living_table.png")
		card_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face = card_back
	else:
		var card: Dictionary = cards[0]
		face = CARD_FACE.new()
		face.name = "HubShopkeeperHeldCardFace"
		face.configure(card, String(_snapshot.get("difficulty", "white")), not _reduced_motion, true)
		face.set_meta("card_id", String(card.get("id", "")))
	face.size = Vector2(250, 355)
	face.position = Vector2.ZERO
	var texture_size := portrait.texture.get_size()
	var portrait_scale := minf(portrait.size.x / texture_size.x, portrait.size.y / texture_size.y)
	var origin := portrait.position + (portrait.size - texture_size * portrait_scale) * 0.5
	holder.size = Vector2(175, 248) * portrait_scale
	holder.position = origin + Vector2(-50, 320) * portrait_scale
	holder.pivot_offset = holder.size * 0.5
	face.scale = holder.size / face.size
	holder.add_child(face)


func _refresh_shop_cards() -> void:
	var display := find_child("HubShopCards", true, false) as Control
	_display_faces.clear()
	for child in display.get_children():
		display.remove_child(child)
		child.queue_free()
	var cards: Array = _snapshot.get("shop_cards", [])
	if cards.is_empty():
		var sold_out := Label.new()
		sold_out.name = "HubShopSoldOutTag"
		sold_out.text = "Sold out"
		# Rasterize the lettering at close-up resolution, then fit it in the case.
		sold_out.scale = Vector2.ONE / SHOP_ZOOM
		sold_out.add_theme_font_override("font", LOCALS_FONT)
		sold_out.add_theme_font_size_override("font_size", 48)
		sold_out.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sold_out.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sold_out.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sold_out.add_theme_color_override("font_color", PALETTE.PEACH_INK)
		sold_out.add_theme_stylebox_override("normal", UI.paper_style(PALETTE.PEACH_PAPER, 18))
		display.add_child(sold_out)
		_ink_paper(sold_out, PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, true, 2.0)
		sold_out.size = sold_out.get_combined_minimum_size()
		sold_out.position = (display.size - sold_out.size / SHOP_ZOOM) * 0.5
		return
	var card_size := Vector2(90, 128)
	var spacing := 62.0
	var row_width := 4 * card_size.x + 3 * spacing
	for index in range(cards.size()):
		var card: Dictionary = cards[index]
		var face := CARD_FACE.new()
		face.name = "HubDisplayCard%d" % index
		face.configure(card, String(_snapshot.get("difficulty", "white")), false)
		face.size = Vector2(250, 355)
		face.scale = card_size / face.size
		face.position = Vector2((display.size.x - row_width) * 0.5 + index * (card_size.x + spacing), 6)
		face.set_meta("card_id", String(card.get("id", "")))
		display.add_child(face)
		_display_faces.append(face)


func _process(delta: float) -> void:
	if _canvas == null or _room_camera == null:
		return
	var target := Vector2.ZERO
	var local_mouse := get_local_mouse_position()
	if not _shop_open and not _seller_open and not _machine_open and Rect2(Vector2.ZERO, size).has_point(local_mouse):
		target = (local_mouse / size - Vector2.ONE * 0.5) * 2.0
	_advance_parallax(target, delta)
	_apply_camera_pose()


func _advance_parallax(target: Vector2, delta: float) -> void:
	_parallax_target = target
	if _reduced_motion:
		_parallax_position = Vector2.ZERO
		_parallax_velocity = Vector2.ZERO
	else:
		# Exact critically damped spring: continuous velocity on pointer reversals
		# and the same settling behavior at 30, 60, or 144 frames per second.
		var offset := _parallax_position - target
		var impulse := _parallax_velocity + offset * PARALLAX_FREQUENCY
		var decay := exp(-PARALLAX_FREQUENCY * delta)
		_parallax_position = target + (offset + impulse * delta) * decay
		_parallax_velocity = (_parallax_velocity - impulse * PARALLAX_FREQUENCY * delta) * decay
	_back_layer.position = _parallax_position * -2.0
	_mid_layer.position = _parallax_position * -4.0
	_front_layer.position = _parallax_position * -7.0


func _create_shop_view() -> void:
	_shop_view = SHOP_VIEW.new()
	_shop_view.name = "HubCounterShopView"
	_shop_view.position = Vector2(0, 78)
	_shop_view.size = Vector2(1280, 554)
	_shop_view.visible = false
	var interface := find_child("HubInterfaceLayer", true, false)
	interface.add_child(_shop_view)
	interface.move_child(_shop_view, 0)
	_shop_view.buy_requested.connect(func(card_id: String) -> void: buy_requested.emit(card_id))
	_shop_view.close_requested.connect(func() -> void: shop_closed.emit())
	_shop_view.focus_order_changed.connect(_on_shop_actions_changed)
	_reroll_button.pressed.connect(_request_reroll)
	_shop_back.pressed.connect(func() -> void: shop_closed.emit())
	_remove_button.pressed.connect(func() -> void:
		_shop_view.close_inspection()
		remove_requested.emit()
	)
	_seller_upgrade_button.pressed.connect(func() -> void: seller_upgrade_requested.emit())
	_view_switch_button.pressed.connect(func() -> void:
		if _seller_open:
			shop_requested.emit()
		else:
			seller_requested.emit()
	)
	_reroll_hint.add_theme_font_override("font", LOCALS_FONT)
	var hint_spacing := StyleBoxEmpty.new()
	hint_spacing.content_margin_left = 16
	hint_spacing.content_margin_right = 16
	_reroll_hint.add_theme_stylebox_override("normal", hint_spacing)
	_ink_paper(_reroll_hint, PALETTE.PEACH_PAPER)


func _on_shop_actions_changed() -> void:
	_refresh_reroll_action()
	_update_focus_order()


func _refresh_reroll_action() -> void:
	if _reroll_button == null or _shop_view == null:
		return
	var cost := int(_snapshot.get("reroll_cost", 5))
	var money := int(_snapshot.get("money", 0))
	var visible_in_counter := _shop_open and not _transitioning
	var busy: bool = bool(_snapshot.get("shop_purchase_busy", false)) or _shop_view._busy
	_reroll_button.visible = visible_in_counter
	_reroll_hint.hide()
	_reroll_button.text = "Reroll · $%d" % cost
	_reroll_button.disabled = not visible_in_counter or not _shop_view._interactive or busy or not bool(_snapshot.get("can_reroll", false))
	_reroll_button.focus_mode = Control.FOCUS_ALL if visible_in_counter else Control.FOCUS_NONE
	var explanation := "Replace the displayed cards."
	if money < cost:
		explanation = "Need $%d more to replace the displayed cards." % (cost - money)
	elif busy:
		explanation = "Finishing your purchase…"
	elif not bool(_snapshot.get("can_reroll", false)):
		explanation = "Reroll is currently unavailable."
	_reroll_hint.text = "%s\n+$1 each use · Resets to $5 after battle" % explanation
	_reroll_hint.add_theme_color_override("font_color", PALETTE.PEACH_INK_SOFT if money < cost or busy else PALETTE.PEACH_INK)
	_reroll_button.tooltip_text = "Spend $%d to replace the displayed cards. Each use costs $1 more; the price resets to $5 after battle." % cost
	if money < cost:
		_reroll_button.tooltip_text = "Need $%d more. %s" % [cost - money, _reroll_button.tooltip_text]


func _request_reroll() -> void:
	_refresh_reroll_action()
	if not _reroll_button.disabled:
		reroll_requested.emit(int(_snapshot.get("reroll_cost", 5)))


func clear_reroll_selection() -> void:
	_shop_view.clear_reroll_selection()


func _create_machine_view() -> void:
	_seller_art.configure("mina", false, _reduced_motion)
	var interface := find_child("HubInterfaceLayer", true, false)
	_machine_view = Control.new()
	_machine_view.name = "HubMachineView"
	_machine_view.size = Vector2(1280, 720)
	_machine_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_machine_view.hide()
	interface.add_child(_machine_view)
	interface.move_child(_machine_view, 0)
	_machine_services = Control.new()
	_machine_services.name = "HubMachineServices"
	_machine_services.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_machine_view.add_child(_machine_services)
	# Retain named legacy controls for existing service contracts, but let the
	# supplied cabinet and its packets be the entire visible browse surface.
	var backing := Panel.new()
	backing.name = "HubMachineServicesBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.hide()
	_machine_services.add_child(backing)
	for node_name in ["VendingTitleLabel", "HubVendingStatus", "VendingInstructionLabel", "HubByeHint"]:
		var control := find_child(node_name, true, false) as Control
		control.reparent(_machine_services, false)
		control.hide()
	_out_of_order.reparent(_machine_services, false)
	_out_of_order.size = Vector2(320, 76)
	_out_of_order.z_index = 4
	var used_label := find_child("HubVendingOutOfOrderLabel", true, false) as Label
	used_label.text = "OUT OF ORDER"
	used_label.add_theme_font_size_override("font_size", 24)
	_snack_view = SNACK_VIEW.new()
	_snack_view.name = "HubVendingSnackView"
	_machine_view.add_child(_snack_view)
	_snack_view.setup(_heal_button, _upgrade_button, HEART_BITES, FOIL_CRUNCH)
	_snack_view.focus_order_changed.connect(_update_focus_order)
	var machine := find_child("VendingMachine", true, false) as Control
	# Packets register to the same glass in every view. The close-up projects
	# these positions into an interactive foreground layer for inspection.
	_cabinet_snacks.append(_snack_art(machine, HEART_BITES, "HeartBitesInMachine", Rect2(89, 112, 60, 84)))
	_cabinet_snacks.append(_snack_art(machine, FOIL_CRUNCH, "FoilCrunchInMachine", Rect2(157, 112, 60, 84)))
	_machine_button = Button.new()
	_machine_button.name = "HubMachineButton"
	_machine_button.size = machine.size
	_machine_button.flat = true
	_machine_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_machine_button.set_meta("ui_button_style_exempt", true)
	_machine_button.tooltip_text = "Take your one free bye: heal or upgrade a card."
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_machine_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	machine.add_child(_machine_button)
	_machine_button.pressed.connect(func() -> void: machine_requested.emit())
	for signal_name in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited"]:
		_machine_button.connect(signal_name, _refresh_machine_hover)
	_machine_hint = UI.make_label("Vending machine", "body", PALETTE.PEACH_INK)
	_machine_hint.name = "HubMachineHint"
	_machine_hint.position = Vector2(20, 380)
	_machine_hint.size = Vector2(252, 35)
	_machine_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_machine_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	machine.add_child(_machine_hint)
	_machine_hint.hide()
	_ink_paper(_machine_hint, PALETTE.PEACH_PAPER)
	_machine_used_sign = UI.make_label("OUT OF ORDER", "body", PALETTE.ACTION_DANGER.darkened(0.2))
	_machine_used_sign.name = "HubMachineUsedSign"
	_machine_used_sign.position = Vector2(75, 131)
	_machine_used_sign.size = Vector2(160, 40)
	_machine_used_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_machine_used_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	machine.add_child(_machine_used_sign)
	_ink_paper(_machine_used_sign, PALETTE.PEACH_PAPER)
	_shop_back.text = "Back to shop"
	_seller_hint.text = "Shopkeeper"
	(find_child("HubAreaEyebrow", true, false) as Label).text = "YOUR AFTERNOON AT"


func _snack_art(parent: Control, texture: Texture2D, node_name: String, rect: Rect2) -> TextureRect:
	var art := TextureRect.new()
	art.name = node_name
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.position = rect.position
	art.size = rect.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_meta("asset_origin", "owner_supplied_snack")
	parent.add_child(art)
	return art


func set_shop_open(open: bool, animated: bool = true) -> void:
	_set_view("counter" if open else "room", animated)


func set_seller_open(open: bool, animated: bool = true) -> void:
	_set_view("seller" if open else "room", animated)


func set_machine_open(open: bool, animated: bool = true) -> void:
	_set_view("machine" if open else "room", animated)


func _set_view(view: String, animated: bool) -> void:
	var open_counter := view == "counter"
	var open_seller := view == "seller"
	var open_machine := view == "machine"
	var target := Vector3(1.0 if open_counter else 0.0, 1.0 if open_seller else 0.0, 1.0 if open_machine else 0.0)
	var current := Vector3(_shop_zoom, _seller_zoom, _machine_zoom)
	if _shop_open == open_counter and _seller_open == open_seller and _machine_open == open_machine and current.is_equal_approx(target) and not _transitioning:
		_shop_view.set_interactive(open_counter)
		_update_shop_chrome()
		_update_focus_order()
		return
	if _shop_open == open_counter and _seller_open == open_seller and _machine_open == open_machine and _transitioning and animated and not _reduced_motion:
		return
	if open_seller or open_counter or open_machine:
		_room_return_focus = _machine_button if open_machine else _seller_button if open_seller else find_child("HubShopButton", true, false) as Button
	_snack_view.clear_selection()
	_shop_open = open_counter
	_seller_open = open_seller
	_machine_open = open_machine
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_shop_view.close_inspection()
	_shop_view.set_interactive(false)
	_transitioning = animated and not _reduced_motion and not current.is_equal_approx(target)
	if open_counter or open_seller or open_machine:
		show_notice("")
	_update_shop_chrome()
	_update_focus_order()
	if not _transitioning:
		_set_zoom_blend(target)
		_finish_shop_transition()
		return
	_zoom_tween = create_tween()
	var distance := maxf(maxf(absf(target.x - current.x), absf(target.y - current.y)), absf(target.z - current.z))
	_zoom_tween.tween_method(_set_zoom_blend, current, target, ZOOM_SECONDS * distance).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_interval(PANEL_DELAY_SECONDS)
	_zoom_tween.finished.connect(_finish_shop_transition)


func _set_zoom_blend(progress: Vector3) -> void:
	_shop_zoom = progress.x
	_seller_zoom = progress.y
	_machine_zoom = progress.z
	_apply_camera_pose()


func _finish_shop_transition() -> void:
	_transitioning = false
	_shop_view.set_interactive(_shop_open)
	_update_shop_chrome()
	_update_focus_order()
	if _shop_open or _seller_open or _machine_open:
		_shop_back.grab_focus()
	elif is_visible_in_tree():
		(_room_return_focus if is_instance_valid(_room_return_focus) else _seller_button).grab_focus()


func _apply_camera_pose() -> void:
	if _room_camera == null or _shop_view == null:
		return
	var focus_point := _room_camera.get_global_transform().affine_inverse() * _display_window.get_global_rect().get_center()
	var seller_focus := _room_camera.get_global_transform().affine_inverse() * _seller_art.get_global_rect().get_center()
	var machine_focus := _room_camera.get_global_transform().affine_inverse() * (find_child("VendingMachine", true, false) as Control).get_global_rect().get_center()
	var target_center := Vector2(640, 385 + _extra_height * 0.35)
	var seller_center := Vector2(400, 330 + _extra_height * 0.35)
	var machine_center := Vector2(414, 512 + _extra_height * 0.35)
	_room_camera.scale = Vector2.ONE * (1.0 + (SHOP_ZOOM - 1.0) * _shop_zoom + (SELLER_ZOOM - 1.0) * _seller_zoom + (MACHINE_ZOOM - 1.0) * _machine_zoom)
	_room_camera.position = (target_center - focus_point * SHOP_ZOOM) * _shop_zoom + (seller_center - seller_focus * SELLER_ZOOM) * _seller_zoom + (machine_center - machine_focus * MACHINE_ZOOM) * _machine_zoom
	# Do not preview service menus while traveling. Prices, hit areas and actions
	# become visible together after the camera and brief settling pause finish.
	_shop_view.visible = _shop_open and not _transitioning
	_seller_view.visible = _seller_open and not _transitioning
	_machine_view.visible = _machine_open and not _transitioning
	_seller_services.position.y = 124 + _extra_height * 0.35
	_out_of_order.position = Vector2(245, 325 + _extra_height * 0.35)
	_machine_used_sign.visible = bool(_snapshot.get("break_used", false)) and not _machine_view.visible
	var canvas_inverse := _canvas.get_global_transform().affine_inverse()
	for face in _display_faces:
		var rect := (face as Control).get_global_rect()
		var local_rect := Rect2(canvas_inverse * rect.position, rect.size / _canvas.scale)
		_shop_view.project_card(String(face.get_meta("card_id", "")), local_rect)
		face.modulate.a = 0.0 if _shop_view.replaces_card(String(face.get_meta("card_id", ""))) else 1.0
	for index in range(_cabinet_snacks.size()):
		var snack := _cabinet_snacks[index]
		var rect := snack.get_global_rect()
		_snack_view.project_snack("heal" if index == 0 else "upgrade", Rect2(canvas_inverse * rect.position, rect.size / _canvas.scale))
		snack.visible = not _machine_view.visible
	_layout_closeup_navigation()


func _update_shop_chrome() -> void:
	_refresh_reroll_action()
	var closeup := _shop_open or _seller_open or _machine_open
	_layout_painted_status()
	if is_instance_valid(_table_receipt):
		_table_receipt.visible = not closeup and _notice_label.visible
	if is_instance_valid(_deck_button):
		_deck_button.disabled = _transitioning
	if is_instance_valid(_deckbox_button):
		_deckbox_button.disabled = _snapshot.get("deckbox", {}).is_empty() or _transitioning
	_next_round_button.visible = not closeup and not _transitioning
	_next_round_button.disabled = _transitioning
	var shop_button := find_child("HubShopButton", true, false) as Button
	for room_action in [_seller_button, _machine_button, shop_button]:
		room_action.focus_mode = Control.FOCUS_NONE if closeup or _transitioning else Control.FOCUS_ALL
		room_action.mouse_filter = Control.MOUSE_FILTER_IGNORE if closeup or _transitioning else Control.MOUSE_FILTER_STOP
		room_action.disabled = closeup or _transitioning
	_refresh_seller_hover()
	_refresh_machine_hover()
	_refresh_counter_hover()
	_display_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_back.visible = closeup
	_view_switch_button.visible = (_shop_open or _seller_open) and not _transitioning
	_view_switch_button.disabled = _transitioning
	_view_switch_button.text = "Browse cards" if _seller_open else "Talk to shopkeeper"
	_remove_button.visible = _seller_open
	var removal_used := bool(_snapshot.get("remove_used", false))
	var cost := int(_snapshot.get("remove_cost", 3))
	_remove_button.text = "Removal used" if removal_used else "Remove a card  ·  $%d" % cost
	_remove_button.disabled = not _seller_open or _transitioning or not bool(_snapshot.get("can_remove", false))
	_remove_button.tooltip_text = "Available next round." if removal_used else "Remove one copy from your deck for $%d. Once per round; keep at least one card." % cost
	var upgrade_used := bool(_snapshot.get("shop_upgrade_used", false))
	var upgrade_cost := int(_snapshot.get("shop_upgrade_cost", 5))
	_seller_upgrade_button.disabled = not _seller_open or _transitioning or not bool(_snapshot.get("can_shop_upgrade", false))
	_seller_upgrade_button.text = "Upgrade used" if upgrade_used else "Upgrade a card  ·  $%d" % upgrade_cost
	_seller_upgrade_button.tooltip_text = "Already used this week." if upgrade_used else "No eligible cards to upgrade." if not bool(_snapshot.get("can_upgrade", false)) else "Upgrade one card for $%d. Once per week; keeps your bye available." % upgrade_cost
	var money := int(_snapshot.get("money", 0))
	(find_child("HubSellerUpgradeHint", true, false) as Label).text = "Used this week" if upgrade_used else "No eligible cards to upgrade" if not bool(_snapshot.get("can_upgrade", false)) else "Need $%d more" % (upgrade_cost - money) if money < upgrade_cost else "Once this week"
	(find_child("HubSellerRemoveHint", true, false) as Label).text = "Used this round · refreshes next round" if removal_used else "Keep at least one card in your deck" if int(_snapshot.get("deck_count", 0)) <= 1 else "Need $%d more" % (cost - money) if money < cost else "Once this round"
	_snack_view.set_interactive(_machine_open and not _transitioning)
	shop_button.visible = not closeup and not _transitioning
	_machine_hint.hide()
	var eyebrow := find_child("HubNextEyebrow", true, false) as Label
	var title := find_child("HubNextMatchLabel", true, false) as Label
	eyebrow.add_theme_font_size_override("font_size", 20)
	if _seller_open:
		eyebrow.text = "SHOPKEEPER"
		title.text = "Make it your deck"
	elif _shop_open:
		eyebrow.text = "CARD COUNTER"
		title.text = "Find your next winning card"
	elif _machine_open:
		eyebrow.text = "VENDING MACHINE"
		title.text = "One little break, your choice"
	else:
		# Table assignments are authored independently of the round number.
		eyebrow.text = String(_snapshot.get("next_label", "Next round")).trim_prefix("Report to ").trim_prefix("Play ").trim_prefix("the ")
		title.text = "Ready when you are"
	_apply_camera_pose()
	_layout_table_receipt()


func _bind_scene_nodes() -> void:
	_canvas = find_child("HubDesignCanvas", true, false) as Control
	_room_camera = find_child("HubRoomCamera", true, false) as Node2D
	_display_window = find_child("HubShopDisplayWindow", true, false) as Control
	_seller_art = find_child("HubShopkeeper", true, false) as TextureRect
	_seller_button = find_child("HubSellerButton", true, false) as Button
	_seller_hint = find_child("HubSellerHint", true, false) as Label
	_seller_view = find_child("HubSellerView", true, false) as Control
	_seller_services = find_child("HubSellerServices", true, false) as Control
	_seller_upgrade_button = find_child("HubSellerUpgradeButton", true, false) as Button
	_view_switch_button = find_child("HubShopViewSwitchButton", true, false) as Button
	_shop_back = find_child("RouteShopContinueButton", true, false) as Button
	_reroll_button = find_child("RouteShopRerollButton", true, false) as Button
	_reroll_hint = find_child("HubShopRerollHint", true, false) as Label
	_remove_button = find_child("RouteShopRemoveButton", true, false) as Button
	_back_layer = find_child("HubBackLayer", true, false) as Node2D
	_mid_layer = find_child("HubMidLayer", true, false) as Node2D
	_front_layer = find_child("HubFrontLayer", true, false) as Node2D
	_round_label = find_child("HubRoundLabel", true, false) as Label
	_life_label = find_child("HubLifeLabel", true, false) as Label
	_funds_label = find_child("HubFundsLabel", true, false) as Label
	_deck_label = find_child("HubDeckLabel", true, false) as Label
	_notice_label = find_child("HubNoticeLabel", true, false) as Label
	_vending_status = find_child("HubVendingStatus", true, false) as Label
	_heal_button = find_child("HubVendingHealButton", true, false) as Button
	_upgrade_button = find_child("HubVendingUpgradeButton", true, false) as Button
	_out_of_order = find_child("HubVendingOutOfOrder", true, false) as PanelContainer
	_next_round_button = find_child("HubNextRoundButton", true, false) as Button


func _scene_is_complete() -> bool:
	var required_nodes: Array[Node] = [
		_canvas,
		_room_camera,
		_display_window,
		_seller_art,
		_seller_button,
		_seller_hint,
		_seller_view,
		_seller_services,
		_seller_upgrade_button,
		_view_switch_button,
		_shop_back,
		_reroll_button,
		_reroll_hint,
		_remove_button,
		_back_layer,
		_mid_layer,
		_front_layer,
		_round_label,
		_life_label,
		_funds_label,
		_deck_label,
		_notice_label,
		_vending_status,
		_heal_button,
		_upgrade_button,
		_out_of_order,
		_next_round_button,
	]
	for node in required_nodes:
		if node == null:
			push_error("TournamentHubScreen.tscn is missing a required named node.")
			return false
	return true


func _connect_scene_actions() -> void:
	var shop_button := find_child("HubShopButton", true, false) as Button
	var save_button := find_child("HubSaveButton", true, false) as Button
	var settings_button := find_child("HubSettingsButton", true, false) as Button
	if shop_button != null:
		shop_button.pressed.connect(func() -> void: shop_requested.emit())
		shop_button.set_meta("ui_button_style_exempt", true)
		shop_button.flat = true
		shop_button.text = ""
		shop_button.position = Vector2(40, 378)
		shop_button.size = Vector2(754, 246)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			shop_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for signal_name in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited"]:
			shop_button.connect(signal_name, _refresh_counter_hover)
	_seller_button.pressed.connect(func() -> void: seller_requested.emit())
	_seller_button.accessibility_name = "Mina. Upgrade or remove a card."
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_seller_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for signal_name in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited"]:
		_seller_button.connect(signal_name, _refresh_seller_hover)
	_display_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heal_button.pressed.connect(func() -> void:
		if _heal_button.is_visible_in_tree() and not _heal_button.disabled:
			heal_requested.emit()
	)
	_upgrade_button.pressed.connect(func() -> void:
		if _upgrade_button.is_visible_in_tree() and not _upgrade_button.disabled:
			upgrade_requested.emit()
	)
	_next_round_button.pressed.connect(func() -> void: next_round_requested.emit())
	if save_button != null:
		save_button.pressed.connect(func() -> void: save_requested.emit())
	if settings_button != null:
		settings_button.pressed.connect(func() -> void: settings_requested.emit())


func _refresh_seller_hover() -> void:
	_seller_hint.hide()
	_refresh_room_highlight(_seller_button, _seller_art)


func _refresh_machine_hover() -> void:
	if _machine_button == null:
		return
	_refresh_room_highlight(_machine_button, find_child("VendingMachineBody", true, false) as Control)


func _refresh_counter_hover() -> void:
	_refresh_room_highlight(find_child("HubShopButton", true, false) as Button, find_child("HubShopDesk", true, false) as Control)


func _create_room_highlights() -> void:
	for artwork in [_seller_art, find_child("HubShopDesk", true, false), find_child("VendingMachineBody", true, false)]:
		var highlight := ShaderMaterial.new()
		highlight.shader = AREA_HIGHLIGHT
		highlight.set_shader_parameter("highlight_color", PALETTE.PEACH_PAPER.lerp(PALETTE.PEACH_MINT, 0.25))
		# Counter texture UVs retain full-source registration. Leave the plant
		# alone and brighten the painted cabinet below the countertop instead.
		highlight.set_shader_parameter("highlight_start_y", 0.60 if artwork.name == "HubShopDesk" else 0.0)
		artwork.material = highlight


func _refresh_room_highlight(button: Button, artwork: CanvasItem) -> void:
	# Back restores focus for keyboard navigation, but that must not keep an
	# old area lit while the player points at something else with the mouse.
	var indicated := button.has_focus() if _room_keyboard_highlight else button.is_hovered()
	var active := button.is_visible_in_tree() and not button.disabled and indicated
	button.set_meta("highlight_active", active)
	if artwork.material is ShaderMaterial:
		(artwork.material as ShaderMaterial).set_shader_parameter("highlight_strength", 1.0 if active else 0.0)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _machine_button == null:
		return
	var keyboard_highlight := _room_keyboard_highlight
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed):
		keyboard_highlight = false
	else:
		for action in ["ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", "ui_accept", "ui_cancel"]:
			if event.is_action_pressed(action):
				keyboard_highlight = true
				break
	if keyboard_highlight != _room_keyboard_highlight:
		_room_keyboard_highlight = keyboard_highlight
		_refresh_seller_hover()
		_refresh_counter_hover()
		_refresh_machine_hover()
		_snack_view.set_keyboard_highlight(keyboard_highlight)


func _unhandled_key_input(event: InputEvent) -> void:
	if (_seller_open or _machine_open or (_shop_open and _transitioning)) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _machine_open and not _snack_view._selected_id.is_empty():
			var snack_id: String = _snack_view._selected_id
			_snack_view.clear_selection()
			(_snack_view._offers[snack_id].hit as Button).grab_focus()
		else:
			shop_closed.emit()


func _layout_canvas() -> void:
	if _canvas == null:
		return
	var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var canvas_scale := minf(safe_size.x / DESIGN_SIZE.x, safe_size.y / DESIGN_SIZE.y)
	_canvas.scale = Vector2.ONE * canvas_scale
	_canvas.position = Vector2((safe_size.x - DESIGN_SIZE.x * canvas_scale) * 0.5, 0)
	# Keep the HUD pinned to the window. Taller displays reveal more of the
	# foreground floor instead of letterboxing the whole interface.
	var extra_height := maxf(0, safe_size.y / canvas_scale - DESIGN_SIZE.y)
	_extra_height = extra_height
	_shop_view.size.y = 554 + extra_height
	_seller_view.size.y = 554 + extra_height
	_machine_view.size.y = 720 + extra_height
	for node_name in ["HubActionBar", "HubTableReceipt", "HubNextEyebrow", "HubNextMatchLabel", "HubNoticeLabel", "HubNextRoundButton", "HubNextRoundHint", "RouteShopContinueButton", "HubShopViewSwitchButton", "RouteShopRerollButton", "HubShopRerollHint"]:
		var node := find_child(node_name, true, false) as Control
		if not node.has_meta("design_y"):
			node.set_meta("design_y", node.position.y)
		node.position.y = float(node.get_meta("design_y")) + extra_height

	_apply_camera_pose()
	_fit_deckbox_inspection()
	_layout_painted_status()
	_layout_table_receipt()


func _layout_closeup_navigation() -> void:
	if not is_instance_valid(_shop_back):
		return
	_shop_back.size = Vector2(480 if _shop_open else 312, 60 if _shop_open else 52)
	_shop_back.position = Vector2((1280 - _shop_back.size.x) * 0.5 if _shop_open else 941, 704 + _extra_height - _shop_back.size.y)
	if not _shop_open:
		_view_switch_button.position = Vector2(28, 651 + _extra_height)
		return
	# Keep the two counter utilities on its upper lip, clear of merchandise.
	var first_card_y := 224.0 + _extra_height * 0.35
	if not _display_faces.is_empty():
		first_card_y = (_canvas.get_global_transform().affine_inverse() * _display_faces[0].get_global_rect().position).y
	var utility_y := first_card_y - 102
	_reroll_button.size = Vector2(260, 52)
	_reroll_button.position = Vector2(510, utility_y)
	_view_switch_button.position = Vector2(944, utility_y)
