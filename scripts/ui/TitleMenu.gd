extends Control
class_name TitleMenu

signal start_requested
signal continue_requested
signal tutorial_requested
signal exit_requested
signal settings_requested
signal debug_requested

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const SWIRL_CARD_IDS := [
	"spicy_hot_honey_bee",
	"fresh_sprout_squirrel",
	"sweet_jellyfish",
	"hearty_french_bread_dog",
	"funky_eggplant_ant",
	"spicy_sriracharrow",
	"item_switchblade",
	"fresh_spicy_mexican_sweet_corino",
]
const CARD_NATIVE_SIZE := Vector2(250.0, 355.0)
const SWIRL_CARD_SCALE := 0.48
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

AUDIO
Cute & Cozy UI Audio Free Sample by Case Portman Audio — royalty-free license, attribution required
Sunlit Balearic Downtempo Sunset Lounge and Upbeat Funky Groove by PWLPL — Pixabay Content License
Epic Spell Impact by DRAGON-STUDIO; Healing Magic (6) by Yodguard; Ground Impact by Universfield; Thud Impact Sound SFX by Virtual_Vibes — Pixabay Content License
Kenney Casino Audio and Impact Sounds — CC0 1.0

PROJECT-OWNER ASSETS
Healing/buff sparkle, illustrated card back, and TOP CUT: Locals to Worlds logo supplied by the project owner — CC0.

Complete source URLs and license details are included in CREDITS.md with the downloadable build."""

var development_tools_enabled := false
var transition_in_progress := false
var swirl_elapsed := 0.0
var swirl_cards: Array[Node2D] = []
var reduced_motion := false
var continue_available := false

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
	_build_card_swirl()
	_apply_development_tools()
	_apply_continue_state()
	card_swirl_layer.resized.connect(_layout_card_swirl)
	poster_layer.resized.connect(_layout_main_actions)
	call_deferred("_layout_card_swirl")
	call_deferred("_layout_main_actions")
	set_process(not reduced_motion)


func _process(delta: float) -> void:
	swirl_elapsed += delta
	_layout_card_swirl()


func _build_card_swirl() -> void:
	if not swirl_cards.is_empty():
		return
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		push_warning("Title card swirl could not load the card catalog.")
		return
	for card_index in range(SWIRL_CARD_IDS.size()):
		var card_id := String(SWIRL_CARD_IDS[card_index])
		var card: Dictionary = catalog.cards_by_id.get(card_id, {})
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
	if reduced_motion:
		_layout_static_cards()
		return

	var center := Vector2(card_swirl_layer.size.x * 0.5, card_swirl_layer.size.y * 0.39)
	var outer_radius := maxf(card_swirl_layer.size.x, card_swirl_layer.size.y) * 0.76
	for card_index in range(swirl_cards.size()):
		var holder := swirl_cards[card_index]
		var duration := float(holder.get_meta("duration", 9.0))
		var progress := fmod(swirl_elapsed / duration + float(holder.get_meta("phase", 0.0)), 1.0)
		var direction := float(holder.get_meta("direction", 1.0))
		var angle := float(holder.get_meta("base_angle", 0.0)) + direction * TAU * 1.28 * progress
		var radius_scale := float(holder.get_meta("radius_scale", 1.0))
		var radius := lerpf(34.0, outer_radius * radius_scale, pow(1.0 - progress, 0.72))
		var vertical_ratio := 0.72
		holder.position = center + Vector2(cos(angle) * radius, sin(angle) * radius * vertical_ratio)
		holder.rotation = angle + direction * PI * 0.5 + sin(progress * TAU + float(card_index)) * 0.12
		var card_scale := lerpf(SWIRL_CARD_SCALE * 0.5, SWIRL_CARD_SCALE, pow(1.0 - progress, 0.42))
		holder.scale = Vector2.ONE * card_scale
		var fade_in := smoothstep(0.0, 0.08, progress)
		var fade_out := 1.0 - smoothstep(0.78, 1.0, progress)
		holder.modulate.a = minf(fade_in, fade_out) * 0.94
		holder.z_index = int((1.0 - progress) * 5.0)


func _layout_static_cards() -> void:
	var positions := [
		Vector2(0.10, 0.19), Vector2(0.27, 0.83), Vector2(0.45, 0.73), Vector2(0.66, 0.81),
		Vector2(0.87, 0.22), Vector2(0.93, 0.66), Vector2(0.07, 0.62), Vector2(0.74, 0.12),
	]
	for card_index in range(swirl_cards.size()):
		var holder := swirl_cards[card_index]
		holder.position = card_swirl_layer.size * positions[card_index % positions.size()]
		holder.rotation = deg_to_rad(-14.0 + float(card_index % 5) * 7.0)
		holder.scale = Vector2.ONE * SWIRL_CARD_SCALE * 0.86
		holder.modulate.a = 0.72


func configure(show_development_tools: bool, has_continue: bool = false, saved_run_finished: bool = false) -> void:
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
	_layout_main_actions()


func _layout_main_actions() -> void:
	if poster_layer.size.x <= 1.0:
		return
	var actions: Array[Button] = []
	for button in [continue_button, start_button, how_to_play_button, credits_button]:
		if button.visible:
			actions.append(button)
	if actions.is_empty():
		return

	var compact := poster_layer.size.y < 800.0
	var button_height := MAIN_ACTION_HEIGHT_COMPACT if compact else MAIN_ACTION_HEIGHT
	var gap := 8.0 if compact else MAIN_ACTION_GAP
	var stack_height := button_height * float(actions.size()) + gap * float(actions.size() - 1)
	var logo_bottom := shop_sign.position.y + shop_sign.size.y
	var minimum_top := logo_bottom + (12.0 if compact else 18.0)
	var preferred_top := (poster_layer.size.y - stack_height) * 0.58
	var maximum_top := maxf(minimum_top, poster_layer.size.y - stack_height - 72.0)
	var top := clampf(preferred_top, minimum_top, maximum_top)
	var left := (poster_layer.size.x - MAIN_ACTION_WIDTH) * 0.5

	for action_index in range(actions.size()):
		var button := actions[action_index]
		button.position = Vector2(left, top + float(action_index) * (button_height + gap))
		button.size = Vector2(MAIN_ACTION_WIDTH, button_height)
		button.focus_neighbor_top = button.get_path_to(actions[maxi(0, action_index - 1)]) if action_index > 0 else NodePath()
		button.focus_neighbor_bottom = button.get_path_to(actions[mini(actions.size() - 1, action_index + 1)]) if action_index < actions.size() - 1 else NodePath()


func _apply_development_tools() -> void:
	debug_button.visible = development_tools_enabled
	options_panel.offset_top = -338.0 if development_tools_enabled else -278.0
	options_panel.offset_bottom = -100.0
	options_panel.custom_minimum_size.y = 238.0 if development_tools_enabled else 178.0
