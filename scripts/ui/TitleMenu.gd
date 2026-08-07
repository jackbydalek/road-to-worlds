extends Control
class_name TitleMenu

signal start_requested
signal tutorial_requested
signal exit_requested
signal settings_requested
signal debug_requested

const STOREFRONT_REFERENCE_SIZE := Vector2(1440, 900)
const POSTER_LAYER_REFERENCE_OFFSET := Vector2(-75, 2)
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const LOGO_SPARKLE_COUNT := 8
const DISCORD_INVITE_URL := "https://discord.gg/EK6AmYgnPZ"
const ATTRIBUTION_TEXT := """3D ASSETS
Pandazole Simple Game Pack by Pandazole — CC BY 4.0 — skfb.ly/o87ID
Low Poly Cafe by vadzaecc — CC BY 4.0
Stylized interior plants by redlupa — CC BY 4.0
3D low poly coffee table set by MrMcChickenXD — Sketchfab Standard License

INTERFACE
Cozy Café UI Kit Premium by Nexa Visuals — commercial runtime license
Save icons by Yogi Aprelliyanto; gaming icons by Icongeek26; settings icons by logisstudio — Flaticon

AUDIO
Modern UI SFX by Andrea Baroni / Cyberleaf Studio — included pack license
Sunlit Balearic Downtempo Sunset Lounge and Upbeat Funky Groove by PWLPL — Pixabay Content License
Epic Spell Impact by DRAGON-STUDIO; Healing Magic (6) by Yodguard; Ground Impact by Universfield; Thud Impact Sound SFX by Virtual_Vibes — Pixabay Content License
Kenney Casino Audio and Impact Sounds — CC0 1.0

PROJECT-OWNER ASSETS
Healing/buff sparkle, illustrated card back, and Topdeck to Worlds logo supplied by the project owner — CC0.

Complete source URLs and license details are included in CREDITS.md with the downloadable build."""

var development_tools_enabled := false
var transition_in_progress := false
var logo_sparkle_layer: Control
var logo_sparkle_elapsed := 0.0

@onready var storefront: StorefrontBackdrop = $StorefrontBackdrop
@onready var poster_layer: Control = $PosterLayer
@onready var shop_sign: Control = $ShopSign
@onready var options_panel: PanelContainer = $TitleOptionsPanel
@onready var options_button: Button = $TitleOptionsButton
@onready var debug_button: Button = $TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/OpenDebugMenuButton
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var attribution_label: Label = $CreditsPanel/CreditsMargin/CreditsContent/CreditsScroll/Attribution
@onready var discord_button: Button = $CreditsPanel/CreditsMargin/CreditsContent/DiscordCommunityButton


func _ready() -> void:
	$PosterLayer/GameStartButton.pressed.connect(_request_start)
	$PosterLayer/TitleHowToPlayButton.pressed.connect(tutorial_requested.emit)
	$PosterLayer/CreditsPosterButton.pressed.connect(func() -> void: credits_panel.visible = true)
	$CreditsPanel/CreditsMargin/CreditsContent/CloseCreditsButton.pressed.connect(func() -> void: credits_panel.visible = false)
	attribution_label.text = ATTRIBUTION_TEXT
	discord_button.pressed.connect(func() -> void: OS.shell_open(DISCORD_INVITE_URL))
	$TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/TitleSettingsButton.pressed.connect(settings_requested.emit)
	$TitleOptionsPanel/OptionsFrame/OptionsMargin/Options/ExitGameButton.pressed.connect(exit_requested.emit)
	debug_button.pressed.connect(debug_requested.emit)
	options_button.pressed.connect(_toggle_options)
	resized.connect(_sync_storefront_overlay)
	_build_logo_sparkles()
	_apply_development_tools()
	call_deferred("_sync_storefront_overlay")
	call_deferred("_position_logo_sparkles")
	set_process(not bool(get_tree().root.get_meta("reduced_motion", false)))


func _process(delta: float) -> void:
	logo_sparkle_elapsed += delta
	_position_logo_sparkles()


func _build_logo_sparkles() -> void:
	if is_instance_valid(logo_sparkle_layer):
		return
	logo_sparkle_layer = Control.new()
	logo_sparkle_layer.name = "LogoSparkleOrbit"
	logo_sparkle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_sparkle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_sparkle_layer.z_index = 2
	shop_sign.add_child(logo_sparkle_layer)
	logo_sparkle_layer.resized.connect(_position_logo_sparkles)
	var colors: Array[Color] = [PALETTE.CREAM, PALETTE.FRESH_YELLOW, PALETTE.SKY, PALETTE.BLUSH]
	for sparkle_index in range(LOGO_SPARKLE_COUNT):
		var sparkle := Node2D.new()
		sparkle.name = "LogoSparkle%d" % sparkle_index
		sparkle.set_meta("base_angle", TAU * float(sparkle_index) / float(LOGO_SPARKLE_COUNT))
		sparkle.set_meta("orbit_speed", 0.19 + float(sparkle_index % 3) * 0.035)
		sparkle.set_meta("pulse_offset", float(sparkle_index) * 0.83)
		var radius := 8.0 + float(sparkle_index % 3) * 2.4
		var outline := Polygon2D.new()
		outline.polygon = _sparkle_polygon(radius + 2.2)
		outline.color = PALETTE.NAVY
		sparkle.add_child(outline)
		var fill := Polygon2D.new()
		fill.polygon = _sparkle_polygon(radius)
		fill.color = colors[sparkle_index % colors.size()]
		sparkle.add_child(fill)
		logo_sparkle_layer.add_child(sparkle)


func _position_logo_sparkles() -> void:
	if not is_instance_valid(logo_sparkle_layer) or logo_sparkle_layer.size.x <= 1.0:
		return
	var center := logo_sparkle_layer.size * 0.5
	var orbit_radius := Vector2(logo_sparkle_layer.size.x * 0.455, logo_sparkle_layer.size.y * 0.39)
	for sparkle_index in range(logo_sparkle_layer.get_child_count()):
		var sparkle := logo_sparkle_layer.get_child(sparkle_index) as Node2D
		var angle := float(sparkle.get_meta("base_angle", 0.0))
		angle += logo_sparkle_elapsed * float(sparkle.get_meta("orbit_speed", 0.2))
		var pulse := 0.5 + 0.5 * sin(logo_sparkle_elapsed * 2.4 + float(sparkle.get_meta("pulse_offset", 0.0)))
		sparkle.position = center + Vector2(cos(angle) * orbit_radius.x, sin(angle) * orbit_radius.y)
		sparkle.rotation = angle * 0.35 + logo_sparkle_elapsed * 0.12
		sparkle.scale = Vector2.ONE * lerpf(0.72, 1.05, pulse)
		sparkle.modulate.a = lerpf(0.62, 1.0, pulse)


func _sparkle_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(8):
		var angle := -PI * 0.5 + float(point_index) * PI * 0.25
		var point_radius := radius if point_index % 2 == 0 else radius * 0.28
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	return points


func configure(show_development_tools: bool) -> void:
	development_tools_enabled = show_development_tools
	if is_node_ready():
		_apply_development_tools()


func _toggle_options() -> void:
	options_panel.visible = not options_panel.visible


func _request_start() -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	poster_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.visible = false
	var fade := create_tween().set_parallel(true)
	fade.tween_property(poster_layer, "modulate:a", 0.0, 0.26)
	fade.tween_property(shop_sign, "modulate:a", 0.0, 0.26)
	await storefront.transition_to("door")
	start_requested.emit()


func _apply_development_tools() -> void:
	debug_button.visible = development_tools_enabled
	options_panel.offset_top = -338.0 if development_tools_enabled else -278.0
	options_panel.offset_bottom = -100.0
	options_panel.custom_minimum_size.y = 238.0 if development_tools_enabled else 178.0


func _sync_storefront_overlay() -> void:
	var backdrop_size := storefront.size
	if backdrop_size.x <= 0.0 or backdrop_size.y <= 0.0:
		return
	var storefront_scale := Vector2(
		backdrop_size.x / STOREFRONT_REFERENCE_SIZE.x,
		backdrop_size.y / STOREFRONT_REFERENCE_SIZE.y
	)
	poster_layer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	poster_layer.position = POSTER_LAYER_REFERENCE_OFFSET * storefront_scale
	poster_layer.size = STOREFRONT_REFERENCE_SIZE
	poster_layer.pivot_offset = Vector2.ZERO
	poster_layer.scale = storefront_scale
