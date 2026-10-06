extends Control
class_name TitleMenu

signal start_requested
signal continue_requested
signal tutorial_requested
signal exit_requested
signal settings_requested
signal debug_requested
signal food_prototype_requested

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const MENU_NOTE_SCRIPT := preload("res://scripts/ui/TitleMenuNote.gd")
# Owner-supplied room frames; brand, controls and state remain native.
# Optional loading keeps the drawn title usable without the illustration files.
const TITLE_FRAME_PATHS := [
	"res://assets/illustrations/supplied_locals_2026_09_14/title_frame_1.png",
	"res://assets/illustrations/supplied_locals_2026_09_14/title_frame_2.png",
	"res://assets/illustrations/supplied_locals_2026_09_14/title_frame_3.png",
]
const TITLE_FRAME_SECONDS := 0.125
const SWIRL_CARD_IDS := [
	"spicy_wasabi_wasp",
	"spicy_sriracharrow",
	"item_wooden_spoon",
	"hearty_french_bread_dog",
	"funky_eggplant_ant",
	"spicy_sriracharrow",
	"item_switchblade",
	"fresh_spicy_mexican_sweet_corino",
]
const CARD_NATIVE_SIZE := Vector2(250.0, 355.0)
const SWIRL_CARD_SCALE := 0.58
const MAIN_ACTION_WIDTH := 380.0
const MAIN_ACTION_HEIGHT := 58.0
const MAIN_ACTION_HEIGHT_COMPACT := 50.0
const MAIN_ACTION_GAP := 10.0
const DISCORD_INVITE_URL := "https://discord.gg/EK6AmYgnPZ"
const ATTRIBUTION_TEXT := """3D ASSETS
Pandazole Simple Game Pack by Pandazole — CC BY 4.0 — skfb.ly/o87ID
Stylized interior plants by redlupa — CC BY 4.0

INTERFACE
Save icons by Yogi Aprelliyanto; gaming icons by Icongeek26; settings icons by logisstudio — Flaticon
Pattern Pack Extra by Kenney — CC0 1.0
Cozy UI demo by dobo_ui — licensed source shapes, conventionally recolored for this game

AUDIO
Cute & Cozy UI Audio Pack by Case Portman Audio — owner-supplied, royalty-free commercial license
Archived Cute & Cozy Free Sample by Case Portman Audio — attribution retained
Sunlit Balearic Downtempo Sunset Lounge and Upbeat Funky Groove by PWLPL — Pixabay Content License
Kenney Casino Audio and Impact Sounds — CC0 1.0
Original shop-door bell restored from the earlier build.
Legacy battle audio credits remain in CREDITS.md.

PROJECT-OWNER ASSETS
Illustrated chef-hat card back supplied by the project owner — CC0.
Archived healing/buff sparkle and TOP CUT: Locals to Worlds logo supplied by the project owner — CC0.

SEE YOU AT LOCALS IDENTITY
The hanging title logo was supplied by the project owner as IMG_0477.PNG. Its original colors and transparency are preserved. The card-club app icon and tabletop menu details remain editable typography and vector shapes.
Replaceable generated illustrations are recorded in docs/generated-art-register.md.

TITLE ROOM ILLUSTRATION — OWNER-SUPPLIED
The project owner supplied the three illustrated title frames on September 14, 2026. The logo is a separate supplied illustration and all controls remain native. Source records are included in assets/illustrations/supplied_locals_2026_09_14/manifest.json and assets/logos/see_you_at_locals_supplied.provenance.json.

Complete source URLs and license details are included in CREDITS.md with the downloadable build."""

@export var use_supplied_title_art := true

var development_tools_enabled := false
var transition_in_progress := false
var swirl_elapsed := 0.0
var swirl_cards: Array[Node2D] = []
var reduced_motion := false
var continue_available := false
var saved_context: Dictionary = {}
var supplied_title_art_active := false
var title_room: TextureRect
var title_frames: Array[Texture2D] = []
var title_frame_index := 0
var title_frame_timer: Timer
var menu_note: Control
var food_prototype_button: Button

@onready var card_swirl_layer: Control = $CardSwirlLayer
@onready var poster_layer: Control = $PosterLayer
@onready var shop_sign: Control = $ShopSign
@onready var continue_button: Button = $PosterLayer/ContinueRunButton
@onready var start_button: Button = $PosterLayer/GameStartButton
@onready var how_to_play_button: Button = $PosterLayer/TitleHowToPlayButton
@onready var credits_button: Button = $PosterLayer/CreditsPosterButton
@onready var options_panel: PanelContainer = $TitleOptionsPanel
@onready var options_button: Button = $TitleOptionsButton
@onready var debug_button: Button = $TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/OpenDebugMenuButton
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var attribution_label: Label = $CreditsPanel/CreditsMargin/CreditsContent/CreditsScroll/Attribution
@onready var discord_button: Button = $CreditsPanel/CreditsMargin/CreditsContent/DiscordCommunityButton


func _ready() -> void:
	food_prototype_button = preload("res://scripts/ui/TopdeckUIComponents.gd").make_button("Food Prototype", "secondary", Vector2.ZERO, "FoodPrototypeButton")
	poster_layer.add_child(food_prototype_button)
	food_prototype_button.pressed.connect(food_prototype_requested.emit)
	continue_button.pressed.connect(_request_continue)
	start_button.pressed.connect(_request_start)
	$PosterLayer/TitleHowToPlayButton.pressed.connect(tutorial_requested.emit)
	$PosterLayer/CreditsPosterButton.pressed.connect(func() -> void: credits_panel.visible = true)
	$CreditsPanel/CreditsMargin/CreditsContent/CloseCreditsButton.pressed.connect(func() -> void: credits_panel.visible = false)
	attribution_label.text = ATTRIBUTION_TEXT
	discord_button.pressed.connect(func() -> void: OS.shell_open(DISCORD_INVITE_URL))
	$TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/TitleSettingsButton.pressed.connect(settings_requested.emit)
	$TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/ExitGameButton.pressed.connect(exit_requested.emit)
	debug_button.pressed.connect(debug_requested.emit)
	options_button.pressed.connect(_toggle_options)
	reduced_motion = bool(get_tree().root.get_meta("reduced_motion", false))
	menu_note = MENU_NOTE_SCRIPT.new()
	menu_note.name = "MenuNote"
	poster_layer.add_child(menu_note)
	poster_layer.move_child(menu_note, 0)
	for button in [continue_button, start_button]:
		button.set_meta("ui_button_shape", "round")
	for button in [how_to_play_button, credits_button, options_button]:
		button.set_meta("ui_button_shape", "square")
	_apply_title_art()
	if not supplied_title_art_active:
		_build_card_swirl()
	_apply_development_tools()
	_apply_continue_state()
	card_swirl_layer.resized.connect(_layout_card_swirl)
	poster_layer.resized.connect(_layout_main_actions)
	call_deferred("_layout_card_swirl")
	call_deferred("_layout_main_actions")
	_apply_locals_style()
	set_process(false)


func _apply_title_art() -> void:
	if not use_supplied_title_art:
		return
	for frame_path in TITLE_FRAME_PATHS:
		if not ResourceLoader.exists(frame_path, "Texture2D"):
			title_frames.clear()
			return
		var frame := load(frame_path) as Texture2D
		if frame == null:
			title_frames.clear()
			return
		title_frames.append(frame)
	title_room = TextureRect.new()
	title_room.name = "SuppliedTitleRoom"
	title_room.texture = title_frames[0]
	title_room.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_room.set_meta("owner_supplied", true)
	title_room.set_meta("source_manifest", "res://assets/illustrations/supplied_locals_2026_09_14/manifest.json")
	add_child(title_room)
	move_child(title_room, 0)
	title_room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	supplied_title_art_active = true
	$TitlePattern.menu_only = true
	card_swirl_layer.hide()
	# Three resident textures keep the authored line boil crisp; no image loading,
	# shader distortion or texture rebuilding happens on an animation tick.
	title_frame_timer = Timer.new()
	title_frame_timer.name = "TitleFrameTimer"
	title_frame_timer.wait_time = TITLE_FRAME_SECONDS
	title_frame_timer.timeout.connect(_advance_title_frame)
	add_child(title_frame_timer)
	title_frame_timer.start()


func _advance_title_frame() -> void:
	if not is_visible_in_tree() or title_frames.is_empty():
		return
	reduced_motion = bool(get_tree().root.get_meta("reduced_motion", false))
	var next_frame := 0 if reduced_motion else (title_frame_index + 1) % title_frames.size()
	if next_frame != title_frame_index:
		title_frame_index = next_frame
		title_room.texture = title_frames[title_frame_index]


func get_title_room_rect() -> Rect2:
	if title_room == null or title_room.texture == null:
		return Rect2()
	var image_size := title_room.texture.get_size()
	var cover_scale := maxf(size.x / image_size.x, size.y / image_size.y)
	var drawn_size := image_size * cover_scale
	return Rect2((size - drawn_size) * 0.5, drawn_size)


func _build_card_swirl() -> void:
	if not swirl_cards.is_empty():
		return
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_warning("Title card swirl could not load the card catalog.")
		return
	for card_index in range(SWIRL_CARD_IDS.size()):
		var card_id := String(SWIRL_CARD_IDS[card_index])
		var card: Dictionary = catalog.cards_by_id.get(card_id, {}).duplicate(true)
		card["peach_soda_frame"] = true
		if card.is_empty():
			continue
		var holder := Node2D.new()
		holder.name = "TitleSwirlCard%d" % card_index
		holder.set_meta("card_id", card_id)
		holder.set_meta("phase", float(card_index) / float(SWIRL_CARD_IDS.size()))
		holder.set_meta("base_angle", TAU * float(card_index) / float(SWIRL_CARD_IDS.size()) + float(card_index % 3) * 0.31)
		holder.set_meta("direction", -1.0 if card_index % 2 == 0 else 1.0)
		holder.set_meta("duration", 8.2 + float(card_index % 4) * 0.65)
		holder.set_meta("radius_scale", 0.92 + float(card_index % 3) * 0.08)
		card_swirl_layer.add_child(holder)

		var face := CARD_FACE_SCRIPT.new() as CardFace
		face.name = "CardFace"
		face.configure(card, "white", false, false, true)
		face.custom_minimum_size = Vector2.ZERO
		face.size = CARD_NATIVE_SIZE
		face.position = -CARD_NATIVE_SIZE * 0.5
		holder.add_child(face)
		swirl_cards.append(holder)


func _layout_card_swirl() -> void:
	if card_swirl_layer.size.x <= 1.0 or swirl_cards.is_empty():
		return
	_layout_static_cards()


func _layout_static_cards() -> void:
	# One real-card fan balances the oversized wordmark. The cards keep their
	# authored illustrations and affinity colors, with no title-screen animation.
	var wide := card_swirl_layer.size.x >= 1000.0
	var scale_factor := minf(card_swirl_layer.size.y / 900.0, 1.16)
	for card_index in range(swirl_cards.size()):
		var holder := swirl_cards[card_index]
		holder.visible = wide and card_index < 3
		var offset := float(card_index) - 1.0
		holder.position = Vector2(card_swirl_layer.size.x * 0.78 + offset * 91.0 * scale_factor, card_swirl_layer.size.y * 0.65 + absf(offset) * 27.0 * scale_factor)
		holder.rotation = deg_to_rad(offset * 13.0)
		holder.scale = Vector2.ONE * 1.1 * scale_factor
		holder.modulate.a = 1.0
		holder.z_index = 3 if card_index == 1 else card_index


func _apply_locals_style() -> void:
	for panel in [credits_panel, options_panel]:
		panel.configure(PALETTE.PEACH_PAPER, PALETTE.PEACH_INK, PALETTE.PEACH_TEAL, Vector4(18, 18, 18, 18))
	for label in credits_panel.find_children("*", "Label", true, false):
		(label as Label).add_theme_color_override("font_color", PALETTE.PEACH_INK)


func configure(show_development_tools: bool, has_continue: bool = false, saved_run_finished: bool = false, saved_run: Dictionary = {}) -> void:
	saved_context = saved_run.duplicate(true)
	development_tools_enabled = show_development_tools
	continue_available = has_continue and not saved_run_finished
	if is_node_ready():
		_apply_development_tools()
		_apply_continue_state()


func _toggle_options() -> void:
	options_panel.visible = not options_panel.visible


func _request_start() -> void:
	if await _fade_out_title():
		start_requested.emit()


func _request_continue() -> void:
	if not continue_available:
		return
	if await _fade_out_title():
		continue_requested.emit()


func _fade_out_title() -> bool:
	if transition_in_progress:
		return false
	transition_in_progress = true
	poster_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.visible = false
	var fade := create_tween().set_parallel(true)
	fade.tween_property(poster_layer, "modulate:a", 0.0, 0.26)
	fade.tween_property(shop_sign, "modulate:a", 0.0, 0.26)
	fade.tween_property(card_swirl_layer, "modulate:a", 0.0, 0.26)
	await fade.finished
	return true


func _apply_continue_state() -> void:
	continue_button.visible = continue_available
	continue_button.disabled = not continue_available
	start_button.set_meta("ui_button_variant", "secondary" if continue_available else "primary")
	start_button.set_meta("ui_button_variant_inferred", false)
	get_tree().call_group("ui_button_style_controller", "refresh_button_by_id", start_button.get_instance_id())
	continue_button.text = "Continue · Round %d" % int(saved_context.get("hub_round", 1)) if saved_context.get("run_loop", "") == "route" else "Continue"
	continue_button.tooltip_text = "%s · %d/%d life" % [String(saved_context.get("starter", saved_context.get("archetype", ""))).capitalize(), int(saved_context.get("life", 0)), int(saved_context.get("max_life", 40))] if continue_available else ""
	_layout_main_actions()


func _layout_main_actions() -> void:
	if poster_layer.size.x <= 1.0:
		return
	var actions: Array[Button] = []
	for button in [continue_button, start_button, food_prototype_button, how_to_play_button, credits_button]:
		if button.visible:
			actions.append(button)
	if actions.is_empty():
		return
	if supplied_title_art_active:
		_layout_room_actions(actions)
		return
	var viewport_size := poster_layer.size
	var wide := viewport_size.x >= 1000.0
	var compact := viewport_size.y < 800.0
	var logo_width := minf(viewport_size.x * 0.54, 800.0) if wide else minf(viewport_size.x - 96.0, 610.0)
	var logo_height := minf(viewport_size.y * 0.43, 374.0)
	var logo_left := viewport_size.x * 0.075 if wide else (viewport_size.x - logo_width) * 0.5
	shop_sign.position = Vector2(logo_left, viewport_size.y * 0.105)
	shop_sign.size = Vector2(logo_width, logo_height)
	var button_width := minf(438.0, viewport_size.x * 0.34) if wide else minf(380.0, viewport_size.x - 112.0)
	var button_height := 48.0 if compact else 54.0
	var gap := 7.0
	var stack_height := button_height * float(actions.size()) + gap * float(actions.size() - 1)
	var top := minf(shop_sign.position.y + shop_sign.size.y + 28.0, viewport_size.y - stack_height - 112.0)
	shop_sign.size.y = minf(shop_sign.size.y, maxf(120.0, top - shop_sign.position.y - 16.0))
	var left := viewport_size.x * 0.095 if wide else (viewport_size.x - button_width) * 0.5
	for action_index in range(actions.size()):
		var button := actions[action_index]
		button.position = Vector2(left, top + float(action_index) * (button_height + gap))
		button.size = Vector2(button_width, button_height)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 21 if compact else 23)
		button.focus_neighbor_top = button.get_path_to(actions[maxi(0, action_index - 1)]) if action_index > 0 else NodePath()
		button.focus_neighbor_bottom = button.get_path_to(actions[mini(actions.size() - 1, action_index + 1)]) if action_index < actions.size() - 1 else NodePath()
	$TitlePattern.menu_sheet_rect = Rect2(Vector2(left - 18.0, top - 17.0), Vector2(button_width + 36.0, stack_height + 34.0))
	_set_menu_note($TitlePattern.menu_sheet_rect)


func _layout_room_actions(actions: Array[Button]) -> void:
	# Keep the supplied sign above a small, quiet group on the lower-left
	# counter. The room and people stay visible around the matte controls.
	var room_rect := get_title_room_rect()
	var compact := size.y < 800.0
	shop_sign.position = room_rect.position + room_rect.size * Vector2(0.355, 0.045)
	shop_sign.size = room_rect.size * Vector2(0.26, 0.20)
	var note_width := clampf(room_rect.size.x * 0.255, 340.0, 372.0)
	var left_inset := 20.0
	var right_inset := 20.0
	var gap := 10.0
	var button_width := note_width - left_inset - right_inset
	var primary_height := 54.0 if compact else 58.0
	var secondary_height := 46.0
	var note_height := 32.0 + primary_height + 18.0 + secondary_height + 24.0
	note_height += secondary_height + gap
	if continue_available:
		note_height += secondary_height + gap
	var left := room_rect.position.x + room_rect.size.x * 0.02
	left = clampf(left, 24.0, maxf(24.0, size.x - note_width - 24.0))
	var top := size.y - note_height - 22.0
	_set_menu_note(Rect2(left, top, note_width, note_height))
	var action_left := left + left_inset
	var action_top := top + 32.0
	var main_button := continue_button if continue_available else start_button
	main_button.position = Vector2(action_left, action_top)
	main_button.size = Vector2(button_width, primary_height)
	main_button.add_theme_font_size_override("font_size", 22 if compact else 24)
	action_top += primary_height
	if continue_available:
		start_button.position = Vector2(action_left, action_top + gap)
		start_button.size = Vector2(button_width, secondary_height)
		start_button.add_theme_font_size_override("font_size", 19)
		action_top += secondary_height + gap
	food_prototype_button.position = Vector2(action_left, action_top + gap)
	food_prototype_button.size = Vector2(button_width, secondary_height)
	food_prototype_button.add_theme_font_size_override("font_size", 19)
	action_top += secondary_height + gap
	var secondary_width := (button_width - gap) * 0.5
	how_to_play_button.position = Vector2(action_left, action_top + 18.0)
	how_to_play_button.size = Vector2(secondary_width, secondary_height)
	credits_button.position = Vector2(action_left + secondary_width + gap, action_top + 18.0)
	credits_button.size = Vector2(secondary_width, secondary_height)
	for button in [how_to_play_button, credits_button]:
		button.add_theme_font_size_override("font_size", 17 if compact else 18)
	for action_index in range(actions.size()):
		var button := actions[action_index]
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.focus_neighbor_top = button.get_path_to(actions[action_index - 1]) if action_index > 0 else NodePath()
		button.focus_neighbor_bottom = button.get_path_to(actions[action_index + 1]) if action_index < actions.size() - 1 else button.get_path_to(options_button)
		button.focus_next = button.get_path_to(actions[action_index + 1]) if action_index < actions.size() - 1 else button.get_path_to(options_button)
		button.focus_previous = button.get_path_to(actions[action_index - 1]) if action_index > 0 else button.get_path_to(options_button)
	options_button.focus_neighbor_top = options_button.get_path_to(actions.back())
	options_button.focus_next = options_button.get_path_to(actions.front())
	options_button.focus_previous = options_button.get_path_to(actions.back())
	how_to_play_button.focus_neighbor_right = how_to_play_button.get_path_to(credits_button)
	credits_button.focus_neighbor_left = credits_button.get_path_to(how_to_play_button)
	credits_button.focus_neighbor_top = credits_button.get_path_to(food_prototype_button)
	how_to_play_button.focus_neighbor_top = how_to_play_button.get_path_to(food_prototype_button)


func _set_menu_note(rect: Rect2) -> void:
	# One lineless painted surface replaces the former ruled notebook sheet.
	$TitlePattern.menu_sheet_rect = Rect2()
	if menu_note != null:
		menu_note.position = rect.position
		menu_note.size = rect.size


func get_menu_sheet_rect() -> Rect2:
	return menu_note.get_rect() if menu_note != null else Rect2()


func _apply_development_tools() -> void:
	debug_button.visible = development_tools_enabled
	options_panel.offset_top = -338.0 if development_tools_enabled else -278.0
	options_panel.offset_bottom = -100.0
	options_panel.custom_minimum_size.y = 238.0 if development_tools_enabled else 178.0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if credits_panel.visible:
			credits_panel.hide()
			credits_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif options_panel.visible:
			options_panel.hide()
			options_button.grab_focus()
			get_viewport().set_input_as_handled()
