extends Control

const MAIN_DECK_SIZE := 20
const MIN_MAIN_DECK_SIZE := 1
# Zero means unlimited; the one-card minimum is enforced by RunStateService.
const MAX_MAIN_DECK_SIZE := 0
const STARTING_CHEF_LIFE := 20
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 8
const SAVE_PATH := "user://topdeck_to_worlds_season_run.json"
const SETTINGS_PATH := "user://topdeck_to_worlds_settings.json"
const LEGACY_BATTLE_SETTINGS_PATH := "user://topdeck_to_worlds_readability.cfg"
const DEVELOPMENT_FLAGS := ["--dev", "--debug-menu"]
## Populate these when the public pages are ready. The finale keeps honest
## coming-soon labels instead of presenting disabled controls as working links.
const STEAM_STORE_URL := ""
const DISCORD_INVITE_URL := "https://discord.gg/EK6AmYgnPZ"
const RESOLUTION_OPTIONS := [
	Vector2i(1280, 720),
	Vector2i(1440, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const DEFAULT_TEXT_SCALE := 1.0
const DEFAULT_BATTLE_TEXT_SCALE := 1.0
const TEXT_SCALE_OPTIONS := [0.9, 1.0, 1.1, 1.25]
const BATTLE_TEXT_SCALE_OPTIONS := [1.0, 1.25, 1.5]
const PLAY_SPEED_OPTIONS := [
	{"id": "fast", "label": "Fast"},
	{"id": "normal", "label": "Normal"},
	{"id": "slow", "label": "Slow"},
]
const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"
const ARCHETYPE_ORDER := ["spicy", "hearty", "sweet", "fresh"]
const PACK_AFFINITY_ORDER := ["spicy", "hearty", "sweet", "fresh", "funky"]
const SET_LIST_AFFINITY_ORDER := ["spicy", "hearty", "sweet", "fresh", "funky", "neutral"]
const SET_LIST_CARD_TYPE_ORDER := ["ingredient", "meal", "chef", "tool", "environment", "spice"]
const DRAFT_NIGHT_ID := "draft_night"
const DEMO_STARTER_ORDER := ["spicy", "hearty", "sweet"]
const DIFFICULTY_ORDER := ["white", "blue", "yellow", "silver", "gold"]
const BASE_BOOSTER_ID := "base_standard_pack"
const PRIZE_BOOSTER_ID := "season_prize_pack"
const DRAFT_DECK_SIZE := MAIN_DECK_SIZE
const DRAFT_OFFER_SIZE := 3
const DRAFT_SORT_NAME := "name"
const DRAFT_SORT_TYPE := "type"
const DRAFT_SORT_AFFINITY := "affinity"
const CARD_HOVER_DELAY_SECONDS := 0.38
const KEYWORD_TOOLTIPS := {
	"stalwart": {"title": "Stalwart", "body": "This card can attack the opposing Chef even while they control Plated cards."},
	"piercing": {"title": "Piercing", "body": "This card deals excess combat damage to the opposing Chef through a Defending unit."},
	"taunt": {"title": "Taunt", "body": "While any Taunt unit is Plated, attackers must target a Taunt before other cards or the Chef. If there are multiple Taunt units, the attacker chooses among them."},
	"hand_trap": {"title": "Handtrap", "body": "Discard this card from your hand to perform its action in response to an opponent's action."},
}
const AUTOSAVE_POLL_SECONDS := 0.4
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const DECK_METRICS_SERVICE_SCRIPT := preload("res://scripts/DeckMetricsService.gd")
const RUN_STATE_SERVICE_SCRIPT := preload("res://scripts/RunStateService.gd")
const SHOP_ECONOMY_SERVICE_SCRIPT := preload("res://scripts/ShopEconomyService.gd")
const CARD_SHOP_SCREEN_SCRIPT := preload("res://scripts/CardShopScreen.gd")
const PACK_OPENING_SCREEN_SCRIPT := preload("res://scripts/PackOpeningScreen.gd")
const DECKBUILDER_SCREEN_SCRIPT := preload("res://scripts/DeckbuilderScreen.gd")
const SEASON_HUB_SCREEN_SCRIPT := preload("res://scripts/SeasonHubScreen.gd")
const SEASON_FLOW_SERVICE_SCRIPT := preload("res://scripts/SeasonFlowService.gd")
const TOURNAMENT_SERVICE_SCRIPT := preload("res://scripts/TournamentService.gd")
const ROUTE_RUN_SERVICE_SCRIPT := preload("res://scripts/RouteRunService.gd")
const CARD_EFFECT_LAB_SCRIPT := preload("res://scripts/CardEffectLab.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const UI_THEME_SCRIPT := preload("res://scripts/ui/KitchenGlassTheme.gd")
const UI_SOUND_CONTROLLER_SCRIPT := preload("res://scripts/ui/UiSoundController.gd")
const MENU_SPARKLE_CONTROLLER_SCRIPT := preload("res://scripts/ui/MenuSparkleController.gd")
const CARD_UPGRADE_REVEAL_SCRIPT := preload("res://scripts/ui/CardUpgradeReveal.gd")
const ROUTE_RIVAL_INTRO_SCRIPT := preload("res://scripts/ui/RouteRivalIntro.gd")
const SKETCH_THEME_SCRIPT := preload("res://scripts/ui/SketchTheme.gd")
const WORKSPACE_THEME_SCRIPT := preload("res://scripts/ui/WorkspaceTheme.gd")
const BUTTON_MOTION_SCRIPT := preload("res://scripts/ui/AudaciousButtonMotion.gd")
const SKETCH_UI_SCRIPT := preload("res://scripts/ui/SketchUIComponents.gd")
const WORKSPACE_UI_SCRIPT := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const TOPDECK_UI_SCRIPT := preload("res://scripts/ui/TopdeckUIComponents.gd")
const MATERIAL_SYMBOLS := preload("res://scripts/ui/MaterialSymbolsSharp.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const ANGULAR_SURFACE_SCRIPT := preload("res://scripts/ui/BattleAngularSurface.gd")
const DISPLAY_FONT := preload("res://assets/fonts/Oxanium-SemiBold.ttf")
const PASTEL_WORKSPACE_BACKGROUND_SHADER := preload("res://assets/shaders/pastel_workspace_background.gdshader")
const INTRO_MUSIC_PATH := "res://assets/audio/intro.mp3"
const CARD_SHOP_MUSIC_PATH := "res://assets/audio/shop.mp3"
const BATTLE_MUSIC_PATH := "res://assets/audio/combat.mp3"
const ROUTE_REWARD_PACK_ART_BY_NODE := {
	"enemy": preload("res://assets/card pack/route_regular_reward.png"),
	"mini_boss": preload("res://assets/card pack/route_miniboss_reward.png"),
	"final_boss": preload("res://assets/card pack/route_floor_boss_reward.png"),
}
const ROUTE_PACK_OPEN_SOUND_PATHS := [
	"res://assets/audio/kenney_casino/cards-pack-open-1.ogg",
	"res://assets/audio/kenney_casino/cards-pack-open-2.ogg",
]
const ROUTE_NODE_ICONS := {
	"enemy": preload("res://assets/overworld/route_icons/enemy.png"),
	"mini_boss": preload("res://assets/overworld/route_icons/mini_boss.png"),
	"final_boss": preload("res://assets/overworld/route_icons/final_boss.png"),
	"shop": preload("res://assets/overworld/route_icons/shop.png"),
	"event": preload("res://assets/overworld/route_icons/event.png"),
}
const ROUTE_SHOPKEEPER_ART := preload("res://assets/characters/shopkeeper/route_shopkeeper_card_pose.png")
const ROUTE_RIVAL_PORTRAITS := {
	"npc1": preload("res://assets/characters/rivals/route_rival_npc_01.png"),
	"npc2": preload("res://assets/characters/rivals/route_rival_npc_02.png"),
}
const SHOP_MUSIC_VOLUME_DB := -16.0
const MENU_MUSIC_VOLUME_DB := -24.0
const BATTLE_MUSIC_VOLUME_DB := -10.0
const ICON_STAR := preload("res://assets/ui/audacious/star-four-bold.svg")
const STARTER_IDLE_POSES := {
	"spicy": preload("res://assets/overworld/player_idle.png"),
	"hearty": preload("res://assets/overworld/hearty_player_idle.png"),
	"sweet": preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
}
const STARTER_VICTORY_POSES := {
	"spicy": preload("res://assets/overworld/player_victory.png"),
	"hearty": preload("res://assets/overworld/hearty_player_victory.png"),
	"sweet": preload("res://assets/characters/protagonists/sweet_player_neutral.png"),
}
const TITLE_MENU_SCENE := preload("res://scenes/ui/TitleMenu.tscn")
const SEASON_SETUP_MENU_SCENE := preload("res://scenes/ui/SeasonSetupMenu.tscn")
const DRAFT_MENU_SCENE := preload("res://scenes/ui/DraftMenu.tscn")
const GREYBOX_CAMERA_DEMO_SCENE_PATH := "res://scenes/GreyboxCameraDemo.tscn"
const TABLETOP_3D_PROTOTYPE_SCENE_PATH := "res://scenes/Tabletop3DPrototype.tscn"
const OVERWORLD_SCENE_PATH := "res://scenes/StarterCityOverworld.tscn"

var rng := RandomNumberGenerator.new()
var content_catalog: RefCounted
var deck_metrics_service: RefCounted
var run_state_service: RefCounted
var shop_economy_service: RefCounted
var card_shop_screen: RefCounted
var pack_opening_screen: RefCounted
var deckbuilder_screen: RefCounted
var season_hub_screen: RefCounted
var season_flow_service: RefCounted
var tournament_service: RefCounted
var route_run_service: RefCounted
var card_effect_lab: RefCounted

var cards: Array = []
var cards_by_id: Dictionary = {}
var expansions: Array = []
var expansions_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var tournaments_by_id: Dictionary = {}

var run: Dictionary = {}
var current_screen := "start"
var deckbuilder_sort_mode := SORT_AFFINITY
var season_setup_archetype_index := 0
var season_setup_difficulty_index := 0
var season_setup_difficulty_open := false
var draft_deck: Dictionary = {}
var draft_offer: Array[String] = []
var draft_picks: Array[String] = []
var draft_signpost_chosen := false
var draft_menu_sort_mode := DRAFT_SORT_NAME
var draft_pick_animating := false
var draft_difficulty_id := "white"
var draft_hover_preview: PanelContainer
var draft_hover_preview_body: CenterContainer
var draft_hover_request_id := 0
var deckbuilder_scroll_positions: Dictionary = {}
var starter_deck_hover_preview: PanelContainer
var starter_deck_hover_preview_body: CenterContainer
var starter_deck_hover_request_id := 0

var root_margin: MarginContainer
var shell: VBoxContainer
var header_bar: HBoxContainer
var title_label: Label
var status_label: Label
var nav: HBoxContainer
var scroll: ScrollContainer
var content: VBoxContainer
var footer_label: RichTextLabel
var round_result_popup: Control
var autosave_label: Label
var autosave_tween: Tween
var card_shop_music_player: AudioStreamPlayer
var battle_music_player: AudioStreamPlayer
var music_mix_tween: Tween
var music_mode := ""
var suspended_tabletop: Control
var suspended_tabletop_screen := ""
var ui_sound_controller
var menu_sparkle_controller
var autosave_enabled := true
var autosave_suspended := false
var autosave_poll_elapsed := 0.0
var last_autosave_fingerprint := ""
var last_autosave_screen := ""
var base_ui_theme: Theme
var sketch_ui_theme: Theme
var workspace_ui_theme: Theme
var player_settings: Dictionary = {
	"fullscreen": false,
	"resolution": [1440, 900],
	"master_volume": 80.0,
	"music_volume": 70.0,
	"sfx_volume": 85.0,
	"text_scale": DEFAULT_TEXT_SCALE,
	"battle_text_scale": DEFAULT_BATTLE_TEXT_SCALE,
	"play_speed": "normal",
	"show_board_info": false,
	"high_contrast": false,
	"reduced_motion": false,
}
var settings_return_screen := "start"
var settings_active_category := "display"
var settings_path := SETTINGS_PATH
var deckbuilder_return_screen := ""
var deckbuilder_return_shop_view := ""
var cached_shop_overworld: Control
var cached_shop_menu_view := "overview"
var selected_route_reward_card_id := ""
var selected_route_shop_card_id := ""
var selected_route_service_card_id := ""
var last_card_add_effect_context := ""
var last_route_shop_purchase_effect_stages: Array[String] = []
var last_card_upgrade_animation_stages: Array[String] = []
var last_route_trade_animation_stages: Array[String] = []
var route_reward_overlay: Control
var route_shop_service_overlay: Control
var route_encounter_overlay: Control
var route_encounter_transitioning := false


func _ready() -> void:
	var scoped_ui_font := AFFINITY_VISUALS.default_ui_font_with_symbols()
	base_ui_theme = UI_THEME_SCRIPT.build(scoped_ui_font)
	sketch_ui_theme = SKETCH_THEME_SCRIPT.build(scoped_ui_font)
	workspace_ui_theme = WORKSPACE_THEME_SCRIPT.build(scoped_ui_font)
	theme = base_ui_theme
	autosave_enabled = not _running_automated_test()
	_load_player_settings()
	_ensure_audio_buses()
	ui_sound_controller = UI_SOUND_CONTROLLER_SCRIPT.new()
	ui_sound_controller.name = "UiSoundController"
	ui_sound_controller.enabled = not _running_automated_test()
	add_child(ui_sound_controller)
	menu_sparkle_controller = MENU_SPARKLE_CONTROLLER_SCRIPT.new()
	menu_sparkle_controller.name = "MenuSparkleController"
	menu_sparkle_controller.enabled = not _running_automated_test()
	add_child(menu_sparkle_controller)
	_apply_player_settings(not _running_automated_test())
	get_tree().node_added.connect(_on_ui_node_added)
	get_tree().auto_accept_quit = false
	rng.randomize()
	_load_content()
	deck_metrics_service = DECK_METRICS_SERVICE_SCRIPT.new()
	deck_metrics_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE)
	run_state_service = RUN_STATE_SERVICE_SCRIPT.new()
	run_state_service.setup(
		cards_by_id,
		archetypes_by_id,
		ARCHETYPE_ORDER,
		MIN_MAIN_DECK_SIZE,
		SIDEBOARD_SIZE,
		STARTING_MONEY,
		SAVE_PATH,
		MAX_MAIN_DECK_SIZE
	)
	shop_economy_service = SHOP_ECONOMY_SERVICE_SCRIPT.new()
	shop_economy_service.setup(cards, cards_by_id, boosters_by_id, rng)
	card_shop_screen = CARD_SHOP_SCREEN_SCRIPT.new()
	pack_opening_screen = PACK_OPENING_SCREEN_SCRIPT.new()
	deckbuilder_screen = DECKBUILDER_SCREEN_SCRIPT.new()
	season_hub_screen = SEASON_HUB_SCREEN_SCRIPT.new()
	season_flow_service = SEASON_FLOW_SERVICE_SCRIPT.new()
	season_flow_service.setup(run_state_service, tournaments_by_id)
	tournament_service = TOURNAMENT_SERVICE_SCRIPT.new()
	route_run_service = ROUTE_RUN_SERVICE_SCRIPT.new()
	route_run_service.setup(cards, cards_by_id)
	card_effect_lab = CARD_EFFECT_LAB_SCRIPT.new()
	_build_shell()
	_show_start()
	last_autosave_screen = current_screen


func _process(delta: float) -> void:
	if not autosave_enabled or autosave_suspended or run.is_empty():
		return
	autosave_poll_elapsed += delta
	if current_screen != last_autosave_screen:
		_autosave_now(current_screen)
		return
	if autosave_poll_elapsed < AUTOSAVE_POLL_SECONDS:
		return
	autosave_poll_elapsed = 0.0
	_capture_live_kitchen_match_state()
	if _run_fingerprint() != last_autosave_fingerprint:
		_autosave_now(current_screen)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if autosave_enabled and not run.is_empty():
		_autosave_now(current_screen)
	get_tree().quit()


func _exit_tree() -> void:
	# Explicitly release looping stream playback before the shell is destroyed.
	# This matters for repeated scene/test teardown and avoids leaving WebAudio or
	# native audio playback objects alive while changing or closing the app.
	_kill_music_tween()
	if autosave_tween != null and autosave_tween.is_valid():
		autosave_tween.kill()
	autosave_tween = null
	_release_audio_streams()


func _release_audio_streams() -> void:
	for player_node in find_children("*", "AudioStreamPlayer", true, false):
		var player := player_node as AudioStreamPlayer
		player.stop()
		player.stream = null


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return
	if find_child("StarterDeckPreview", true, false) != null:
		_close_starter_deck_preview()
		return
	if current_screen == "kitchen_match":
		if is_instance_valid(round_result_popup):
			return
		call_deferred("_on_kitchen_exit_requested")


func _running_automated_test() -> bool:
	for argument in OS.get_cmdline_args():
		if "SmokeTest.gd" in String(argument):
			return true
	return false


func _development_tools_enabled() -> bool:
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	if "--public" in arguments:
		return false
	if _running_automated_test():
		return true
	for argument in arguments:
		if String(argument) in DEVELOPMENT_FLAGS:
			return true
	return false


func _default_player_settings() -> Dictionary:
	return {
		"fullscreen": false,
		"resolution": [1440, 900],
		"master_volume": 80.0,
		"music_volume": 70.0,
		"sfx_volume": 85.0,
		"text_scale": DEFAULT_TEXT_SCALE,
		"battle_text_scale": DEFAULT_BATTLE_TEXT_SCALE,
		"play_speed": "normal",
		"show_board_info": false,
		"high_contrast": false,
		"reduced_motion": false,
	}


func _load_player_settings() -> void:
	var defaults := _default_player_settings()
	player_settings = defaults.duplicate(true)
	var parsed: Dictionary = {}
	if FileAccess.file_exists(settings_path):
		var file := FileAccess.open(settings_path, FileAccess.READ)
		if file != null:
			var loaded_value = JSON.parse_string(file.get_as_text())
			if loaded_value is Dictionary:
				parsed = loaded_value
	for key in defaults:
		if parsed.has(key):
			player_settings[key] = parsed[key]
	if not parsed.has("play_speed") or not parsed.has("battle_text_scale"):
		var legacy_config := ConfigFile.new()
		if legacy_config.load(LEGACY_BATTLE_SETTINGS_PATH) == OK:
			if not parsed.has("play_speed"):
				player_settings.play_speed = String(legacy_config.get_value("readability", "rival_pacing", "normal"))
			if not parsed.has("battle_text_scale"):
				player_settings.battle_text_scale = float(legacy_config.get_value(
					"readability",
					"text_scale",
					DEFAULT_BATTLE_TEXT_SCALE
				))
	_sanitize_player_settings()


func _sanitize_player_settings() -> void:
	player_settings.fullscreen = bool(player_settings.get("fullscreen", false))
	var resolution_value = player_settings.get("resolution", [1440, 900])
	if not (resolution_value is Array) or resolution_value.size() < 2:
		resolution_value = [1440, 900]
	var requested_resolution := Vector2i(
		clampi(int(resolution_value[0]), 960, 7680),
		clampi(int(resolution_value[1]), 540, 4320)
	)
	var supported := false
	for option in RESOLUTION_OPTIONS:
		if option == requested_resolution:
			supported = true
			break
	if not supported:
		requested_resolution = Vector2i(1440, 900)
	player_settings.resolution = [requested_resolution.x, requested_resolution.y]
	player_settings.master_volume = clampf(float(player_settings.get("master_volume", 80.0)), 0.0, 100.0)
	player_settings.music_volume = clampf(float(player_settings.get("music_volume", 70.0)), 0.0, 100.0)
	player_settings.sfx_volume = clampf(float(player_settings.get("sfx_volume", 85.0)), 0.0, 100.0)
	var requested_scale := float(player_settings.get("text_scale", DEFAULT_TEXT_SCALE))
	var closest_scale := DEFAULT_TEXT_SCALE
	var closest_distance := INF
	for option in TEXT_SCALE_OPTIONS:
		var distance := absf(float(option) - requested_scale)
		if distance < closest_distance:
			closest_distance = distance
			closest_scale = float(option)
	player_settings.text_scale = closest_scale
	var requested_battle_scale := float(player_settings.get("battle_text_scale", DEFAULT_BATTLE_TEXT_SCALE))
	var closest_battle_scale := DEFAULT_BATTLE_TEXT_SCALE
	var closest_battle_distance := INF
	for option in BATTLE_TEXT_SCALE_OPTIONS:
		var battle_distance := absf(float(option) - requested_battle_scale)
		if battle_distance < closest_battle_distance:
			closest_battle_distance = battle_distance
			closest_battle_scale = float(option)
	player_settings.battle_text_scale = closest_battle_scale
	var requested_play_speed := String(player_settings.get("play_speed", "normal"))
	player_settings.play_speed = requested_play_speed if requested_play_speed in ["fast", "normal", "slow"] else "normal"
	player_settings.show_board_info = bool(player_settings.get("show_board_info", false))
	player_settings.high_contrast = bool(player_settings.get("high_contrast", false))
	player_settings.reduced_motion = bool(player_settings.get("reduced_motion", false))


func _save_player_settings() -> void:
	_sanitize_player_settings()
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(player_settings, "\t"))


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	var menu_music_index := AudioServer.get_bus_index("MenuMusic")
	if menu_music_index < 0:
		AudioServer.add_bus()
		menu_music_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(menu_music_index, "MenuMusic")
	AudioServer.set_bus_send(menu_music_index, "Music")
	if AudioServer.get_bus_effect_count(menu_music_index) == 0:
		var outside_filter := AudioEffectLowPassFilter.new()
		outside_filter.cutoff_hz = 1850.0
		outside_filter.resonance = 0.18
		AudioServer.add_bus_effect(menu_music_index, outside_filter)


func _apply_player_settings(apply_display: bool = true) -> void:
	_sanitize_player_settings()
	_apply_audio_settings()
	get_tree().root.set_meta("reduced_motion", bool(player_settings.reduced_motion))
	get_tree().root.set_meta("high_contrast", bool(player_settings.high_contrast))
	if apply_display and DisplayServer.get_name() != "headless":
		var fullscreen := bool(player_settings.fullscreen)
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
		if not fullscreen:
			var resolution := Vector2i(
				int(player_settings.resolution[0]),
				int(player_settings.resolution[1])
			)
			DisplayServer.window_set_size(resolution)
			var screen_size := DisplayServer.screen_get_size()
			DisplayServer.window_set_position((screen_size - resolution) / 2)
	_apply_accessibility_to_tree()


func _apply_audio_settings() -> void:
	_set_audio_bus_level("Master", float(player_settings.master_volume))
	_set_audio_bus_level("Music", float(player_settings.music_volume))
	_set_audio_bus_level("SFX", float(player_settings.sfx_volume))


func _set_audio_bus_level(bus_name: String, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var normalized := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(index, normalized <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(normalized, 0.001)))


func _on_ui_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_accessibility_to_instance", node.get_instance_id())


func _apply_accessibility_to_instance(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Control:
		_apply_accessibility_to_control(node)


func _apply_accessibility_to_tree() -> void:
	if theme != null:
		theme.default_font_size = roundi(16.0 * float(player_settings.text_scale))
	_apply_accessibility_to_control(self)
	for node in find_children("*", "Control", true, false):
		_apply_accessibility_to_control(node)


func _apply_accessibility_to_control(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var text_scale := float(player_settings.get("text_scale", DEFAULT_TEXT_SCALE))
	if node.has_theme_font_size_override("font_size"):
		if not node.has_meta("accessibility_base_font_size"):
			node.set_meta("accessibility_base_font_size", node.get_theme_font_size("font_size"))
		var base_size := int(node.get_meta("accessibility_base_font_size", node.get_theme_font_size("font_size")))
		node.add_theme_font_size_override("font_size", maxi(8, roundi(float(base_size) * text_scale)))
	var text_control := node is Label or node is Button or node is RichTextLabel or node is LineEdit
	if not text_control:
		return
	if bool(player_settings.get("high_contrast", false)):
		node.add_theme_color_override("font_outline_color", Color("#000000E8"))
		node.add_theme_constant_override("outline_size", 2)
		node.set_meta("accessibility_outline_added", true)
	elif bool(node.get_meta("accessibility_outline_added", false)):
		node.remove_theme_color_override("font_outline_color")
		node.remove_theme_constant_override("outline_size")
		node.remove_meta("accessibility_outline_added")


func _reduced_motion_enabled() -> bool:
	return bool(player_settings.get("reduced_motion", false))


func _run_fingerprint() -> String:
	# Hash the Variant tree directly so the frequent autosave poll does not build
	# a complete JSON copy of the run just to detect whether it changed.
	return str(hash(run))


func _autosave_now(resume_screen: String = "") -> Dictionary:
	if not autosave_enabled or autosave_suspended or run.is_empty():
		return {"ok": false, "message": "Autosave skipped."}
	_capture_live_kitchen_match_state()
	var target_screen := resume_screen if resume_screen != "" else current_screen
	if target_screen == "settings" and is_instance_valid(suspended_tabletop) and suspended_tabletop_screen == "kitchen_match":
		target_screen = "kitchen_match"
	_show_autosave_indicator()
	var result: Dictionary = run_state_service.save_run(run, target_screen)
	if bool(result.get("ok", false)):
		last_autosave_fingerprint = _run_fingerprint()
		last_autosave_screen = target_screen
		autosave_poll_elapsed = 0.0
	else:
		_show_autosave_failure()
	return result


func _show_autosave_indicator() -> void:
	if autosave_label == null:
		return
	if autosave_tween != null and autosave_tween.is_valid():
		autosave_tween.kill()
	autosave_label.visible = true
	autosave_label.text = "◆"
	autosave_label.rotation = 0.0
	autosave_label.scale = Vector2.ONE
	autosave_label.modulate = Color(1, 1, 1, 0.72)
	autosave_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.TEAL_DEEP)
	autosave_tween = create_tween()
	if not _reduced_motion_enabled():
		autosave_tween.set_parallel(true)
		autosave_tween.tween_property(autosave_label, "rotation", TAU, 0.52).set_trans(Tween.TRANS_SINE)
		autosave_tween.tween_property(autosave_label, "scale", Vector2(0.82, 0.82), 0.26).set_trans(Tween.TRANS_SINE)
		autosave_tween.chain().tween_property(autosave_label, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_SINE)
		autosave_tween.chain()
	else:
		autosave_tween.tween_interval(0.42)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.35)
	autosave_tween.tween_callback(func() -> void:
		autosave_label.visible = false
		autosave_label.rotation = 0.0
		autosave_label.scale = Vector2.ONE
	)


func _show_autosave_failure() -> void:
	if autosave_label == null:
		return
	if is_instance_valid(ui_sound_controller):
		ui_sound_controller.play_error()
	if autosave_tween != null and autosave_tween.is_valid():
		autosave_tween.kill()
	autosave_label.visible = true
	autosave_label.text = "!"
	autosave_label.rotation = 0.0
	autosave_label.scale = Vector2.ONE
	autosave_label.modulate = Color.WHITE
	autosave_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.DANGER)
	autosave_tween = create_tween()
	autosave_tween.tween_interval(1.4)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.4)
	autosave_tween.tween_callback(func() -> void: autosave_label.visible = false)


func _build_shell() -> void:
	var background := SKETCH_UI_SCRIPT.make_paper_background()
	background.name = "PaperBackground"
	add_child(background)
	var workspace_background := ColorRect.new()
	workspace_background.name = "PastelWorkspaceBackground"
	workspace_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	workspace_background.color = Color.WHITE
	var workspace_background_material := ShaderMaterial.new()
	workspace_background_material.shader = PASTEL_WORKSPACE_BACKGROUND_SHADER
	workspace_background.material = workspace_background_material
	workspace_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workspace_background.visible = false
	add_child(workspace_background)
	var route_background := ColorRect.new()
	route_background.name = "RoutePresentationBackground"
	route_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	route_background.color = PALETTE.SURFACE_ROOT
	route_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_background.visible = false
	add_child(route_background)

	root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(root_margin)

	shell = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	root_margin.add_child(shell)

	header_bar = HBoxContainer.new()
	header_bar.add_theme_constant_override("separation", 14)
	shell.add_child(header_bar)

	title_label = Label.new()
	title_label.text = "TOP CUT: Locals to Worlds"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.INK)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.TEAL_DEEP)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(status_label)

	autosave_label = Label.new()
	autosave_label.name = "AutosaveIndicator"
	autosave_label.text = "◆"
	autosave_label.visible = false
	autosave_label.z_index = 2000
	autosave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	autosave_label.offset_left = -54.0
	autosave_label.offset_top = 78.0
	autosave_label.offset_right = -18.0
	autosave_label.offset_bottom = 114.0
	autosave_label.pivot_offset = Vector2(18, 18)
	autosave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autosave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autosave_label.add_theme_font_size_override("font_size", 15)
	autosave_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.TEAL_DEEP)
	autosave_label.add_theme_stylebox_override(
		"normal",
		WORKSPACE_UI_SCRIPT.clean_style(
			WORKSPACE_UI_SCRIPT.SURFACE,
			WORKSPACE_UI_SCRIPT.TEAL,
			1,
			18,
			Vector4(4, 4, 4, 4),
			0,
			true
		)
	)
	autosave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(autosave_label)

	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	shell.add_child(nav)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	footer_label = RichTextLabel.new()
	footer_label.custom_minimum_size = Vector2(0, 78)
	footer_label.bbcode_enabled = true
	footer_label.fit_content = false
	footer_label.scroll_active = true
	footer_label.add_theme_color_override("default_color", UI_THEME_SCRIPT.INK_MUTED)
	shell.add_child(footer_label)


func _load_content() -> void:
	content_catalog = CONTENT_CATALOG_SCRIPT.new()
	content_catalog.load_all()

	cards = content_catalog.cards
	cards_by_id = content_catalog.cards_by_id
	expansions = content_catalog.expansions
	expansions_by_id = content_catalog.expansions_by_id
	archetypes_by_id = content_catalog.archetypes_by_id
	boosters_by_id = content_catalog.boosters_by_id
	tournaments_by_id = content_catalog.tournaments_by_id


func _clear(node: Node) -> void:
	if node == content and node.get_child_count() > 0 and is_instance_valid(ui_sound_controller):
		ui_sound_controller.play_transition()
	if node == content:
		_sync_music_for_current_screen()
	for child in node.get_children():
		# Screen rebuilds are often triggered by button signals; queue deletion so the
		# emitting button is not freed while Godot is still dispatching its signal.
		child.queue_free()


func _sync_music_for_current_screen() -> void:
	if current_screen in ["kitchen_match", "tutorial"]:
		_play_battle_music()
	elif current_screen in ["start", "new_game", "season_setup", "draft", "season"]:
		_play_card_shop_music(true)
	elif current_screen == "shop" or (current_screen == "deck" and deckbuilder_return_screen == "shop"):
		_play_card_shop_music(false)
	elif current_screen == "settings" and settings_return_screen in ["start", "new_game", "season_setup", "draft", "season"]:
		_play_card_shop_music(true)
	elif current_screen == "settings" and (
		settings_return_screen == "shop"
		or (settings_return_screen == "deck" and deckbuilder_return_screen == "shop")
	):
		_play_card_shop_music(false)
	elif current_screen == "settings" and settings_return_screen in ["kitchen_match", "tutorial"]:
		_play_battle_music()
	else:
		_fade_out_music()


func _play_card_shop_music(menu_mix: bool = false) -> void:
	var next_mode := "menu" if menu_mix else "shop"
	var target_volume := MENU_MUSIC_VOLUME_DB if menu_mix else SHOP_MUSIC_VOLUME_DB
	if card_shop_music_player == null:
		card_shop_music_player = AudioStreamPlayer.new()
		card_shop_music_player.name = "CardShopMusic"
		add_child(card_shop_music_player)
	if music_mode != next_mode:
		var source_path := INTRO_MUSIC_PATH if menu_mix else CARD_SHOP_MUSIC_PATH
		var source_stream := load(source_path) as AudioStreamMP3
		assert(source_stream != null, "Unable to load music stream: %s" % source_path)
		var music_stream := source_stream.duplicate() as AudioStreamMP3
		music_stream.resource_name = source_stream.resource_path
		music_stream.loop = true
		card_shop_music_player.stream = music_stream
		card_shop_music_player.stop()
	card_shop_music_player.bus = &"MenuMusic" if menu_mix else &"Music"
	music_mode = next_mode
	_kill_music_tween()
	music_mix_tween = create_tween().set_parallel(true)
	if not card_shop_music_player.playing:
		card_shop_music_player.volume_db = -36.0
		card_shop_music_player.play()
	music_mix_tween.tween_property(card_shop_music_player, "volume_db", target_volume, 0.9)
	if battle_music_player != null and battle_music_player.playing:
		music_mix_tween.tween_property(battle_music_player, "volume_db", -36.0, 0.55)
		music_mix_tween.chain().tween_callback(func() -> void:
			if music_mode == next_mode and battle_music_player != null:
				battle_music_player.stop()
		)


func _play_battle_music() -> void:
	if battle_music_player == null:
		battle_music_player = AudioStreamPlayer.new()
		battle_music_player.name = "BattleMusic"
		var source_stream := load(BATTLE_MUSIC_PATH) as AudioStreamMP3
		assert(source_stream != null, "Unable to load battle music: %s" % BATTLE_MUSIC_PATH)
		var music_stream := source_stream.duplicate() as AudioStreamMP3
		music_stream.resource_name = source_stream.resource_path
		music_stream.loop = true
		battle_music_player.stream = music_stream
		battle_music_player.bus = &"Music"
		add_child(battle_music_player)
	music_mode = "battle"
	_kill_music_tween()
	music_mix_tween = create_tween().set_parallel(true)
	if not battle_music_player.playing:
		battle_music_player.volume_db = -34.0
		battle_music_player.play()
	music_mix_tween.tween_property(battle_music_player, "volume_db", BATTLE_MUSIC_VOLUME_DB, 0.8)
	if card_shop_music_player != null and card_shop_music_player.playing:
		music_mix_tween.tween_property(card_shop_music_player, "volume_db", -36.0, 0.55)
		music_mix_tween.chain().tween_callback(func() -> void:
			if music_mode == "battle" and card_shop_music_player != null:
				card_shop_music_player.stop()
		)


func _fade_out_music() -> void:
	if music_mode == "none":
		return
	music_mode = "none"
	_kill_music_tween()
	music_mix_tween = create_tween().set_parallel(true)
	if card_shop_music_player != null and card_shop_music_player.playing:
		music_mix_tween.tween_property(card_shop_music_player, "volume_db", -36.0, 0.45)
	if battle_music_player != null and battle_music_player.playing:
		music_mix_tween.tween_property(battle_music_player, "volume_db", -36.0, 0.45)
	music_mix_tween.chain().tween_callback(func() -> void:
		if music_mode != "none":
			return
		if card_shop_music_player != null:
			card_shop_music_player.stop()
		if battle_music_player != null:
			battle_music_player.stop()
	)


func _kill_music_tween() -> void:
	if music_mix_tween != null and music_mix_tween.is_valid():
		music_mix_tween.kill()
	music_mix_tween = null


func _stop_card_shop_music() -> void:
	if card_shop_music_player != null and card_shop_music_player.playing:
		card_shop_music_player.stop()


func _make_front_door_screen(node_name: String) -> Control:
	var screen := Control.new()
	screen.name = node_name
	screen.custom_minimum_size = Vector2(0, 840)
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(screen)
	return screen


func _anchor_rect(
	control: Control,
	left: float,
	right: float,
	top: float,
	bottom: float,
	offset_left: float,
	offset_top: float,
	offset_right: float,
	offset_bottom: float
) -> void:
	control.anchor_left = left
	control.anchor_right = right
	control.anchor_top = top
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom


func _make_menu_deck_art(
	starter_id: String,
	display_name: String,
	draft_night: bool,
	minimum_size: Vector2
) -> PanelContainer:
	var accent := Color("#176985") if draft_night else _affinity_color(starter_id).darkened(0.18)
	if starter_id == "" and not draft_night:
		accent = Color("#6F7478")
	var art := SKETCH_UI_SCRIPT.make_rough_panel(
		minimum_size,
		SKETCH_UI_SCRIPT.PAPER.lerp(accent, 0.22),
		SKETCH_UI_SCRIPT.INK,
		accent,
		Vector4(18, 18, 18, 20),
		1 if draft_night else max(0, DEMO_STARTER_ORDER.find(starter_id))
	)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 10)
	art.add_child(body)

	if draft_night:
		var star_center := CenterContainer.new()
		body.add_child(star_center)
		var star := SKETCH_UI_SCRIPT.make_draft_star(Vector2(82, 82))
		star.name = "DeckArtworkDraftStar"
		star_center.add_child(star)
	elif STARTER_IDLE_POSES.has(starter_id):
		var player_art := TextureRect.new()
		player_art.name = starter_id.capitalize() + "PlayerArtwork"
		player_art.texture = STARTER_IDLE_POSES[starter_id]
		player_art.custom_minimum_size = Vector2(160, 205)
		player_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		player_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		player_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(player_art)
	else:
		var symbol := Label.new()
		symbol.name = "DeckArtworkAffinitySymbol"
		symbol.text = _affinity_symbol(starter_id) if starter_id != "" else "?"
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.add_theme_font_override("font", AFFINITY_VISUALS.monochrome_symbol_font())
		symbol.add_theme_font_size_override("font_size", 64)
		symbol.add_theme_color_override("font_color", accent.darkened(0.42))
		body.add_child(symbol)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.68))
	name_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	body.add_child(name_label)
	return art


func _add_starter_info_symbol(parent: Node, starter_id: String, draft_night: bool) -> void:
	var symbol_host := CenterContainer.new()
	symbol_host.custom_minimum_size = Vector2(72, 72)
	parent.add_child(symbol_host)
	if draft_night:
		var star := SKETCH_UI_SCRIPT.make_draft_star(Vector2(64, 64))
		star.name = "DraftNightStar"
		symbol_host.add_child(star)
		return
	var symbol := Label.new()
	symbol.name = "StarterDeckSymbol"
	symbol.text = _affinity_symbol(starter_id)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_font_override("font", AFFINITY_VISUALS.monochrome_symbol_font())
	symbol.add_theme_font_size_override("font_size", 50)
	symbol.add_theme_color_override("font_color", Color("#102D37"))
	symbol_host.add_child(symbol)


func _add_sketch_status_text(parent: Node, text: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.18))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _make_sketch_arrow_button(direction: int, minimum_size: Vector2) -> Button:
	return SKETCH_UI_SCRIPT.make_arrow_button(direction, minimum_size)


func _make_title_route_menu(screen: Control, node_name: String) -> PanelContainer:
	var menu_panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(310, 304 if _development_tools_enabled() else 236),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(28, 24, 28, 30),
		1
	)
	menu_panel.name = node_name
	menu_panel.visible = false
	_anchor_rect(menu_panel, 1.0, 1.0, 1.0, 1.0, -424, -332, -100, -82)
	screen.add_child(menu_panel)
	var actions := VBoxContainer.new()
	actions.name = "TitleRouteMenuActions"
	actions.add_theme_constant_override("separation", 4)
	menu_panel.add_child(actions)

	var tutorial_button := SKETCH_UI_SCRIPT.make_button(
		"HOW TO PLAY",
		Vector2(250, 58),
		false,
		19,
		false
	)
	tutorial_button.name = "GameStartTutorialButton"
	_connect_pressed(tutorial_button, _show_tutorial)
	actions.add_child(tutorial_button)

	var settings_button := SKETCH_UI_SCRIPT.make_button(
		"SETTINGS",
		Vector2(250, 58),
		false,
		19,
		true
	)
	settings_button.name = "GameStartSettingsButton"
	_connect_pressed(settings_button, _show_settings)
	actions.add_child(settings_button)

	if _development_tools_enabled():
		var debug_button := SKETCH_UI_SCRIPT.make_button(
			"DEBUG MENU",
			Vector2(250, 58),
			false,
			19,
			true
		)
		debug_button.name = "GameStartDebugButton"
		_connect_pressed(debug_button, _show_debug_starter_selection)
		actions.add_child(debug_button)
	return menu_panel


func _show_starter_deck_preview(starter_id: String) -> void:
	if current_screen != "season_setup" or find_child("StarterDeckPreview", true, false) != null:
		return
	if is_instance_valid(ui_sound_controller):
		ui_sound_controller.play_popup()
	var draft_night := starter_id == DRAFT_NIGHT_ID
	var display_name := "Draft Night" if draft_night else _archetype_label(starter_id)
	var entries := _starter_deck_preview_entries(starter_id)
	var total_cards := 0
	for entry in entries:
		total_cards += int(entry.count)

	var overlay := Control.new()
	overlay.name = "StarterDeckPreview"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1800
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.name = "StarterDeckPreviewDimmer"
	dimmer.color = Color(PALETTE.NAVY, 0.46)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_close_starter_deck_preview()
	)
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 690)
	panel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI_SCRIPT.clean_style(
			Color(PALETTE.CREAM, 0.985),
			PALETTE.NAVY,
			2,
			18,
			Vector4(46, 38, 46, 42),
			0,
			true
		)
	)
	panel.name = "StarterDeckPreviewPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var banner_parts := WORKSPACE_UI_SCRIPT.make_section(
		"DRAFT NIGHT" if draft_night else "%s DECK" % display_name.to_upper(),
		WORKSPACE_UI_SCRIPT.TEAL,
		Vector2(650, 96),
		false,
		Vector4(20, 12, 20, 12)
	)
	var banner := banner_parts.panel as PanelContainer
	var banner_heading := banner_parts.heading as Label
	banner.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI_SCRIPT.clean_style(
			Color(PALETTE.LAVENDER_GLASS, 0.92),
			PALETTE.PERIWINKLE,
			2,
			14,
			Vector4.ZERO
		)
	)
	banner_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_heading.add_theme_font_size_override("font_size", 28)
	banner_heading.add_theme_color_override("font_color", PALETTE.NAVY)
	var banner_subtitle := Label.new()
	banner_subtitle.text = (
		"Build your season deck one pick at a time."
		if draft_night
		else "Review the cards before committing to this season."
	)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_subtitle.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	banner_parts.body.add_child(banner_subtitle)
	banner.name = "StarterDeckPreviewBanner"
	layout.add_child(banner)

	var flexible_body: Control
	if draft_night:
		var empty_panel := PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(0, 420)
		empty_panel.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI_SCRIPT.clean_style(
				Color(PALETTE.LAVENDER_GLASS, 0.62),
				PALETTE.PERIWINKLE,
				2,
				14,
				Vector4(42, 34, 42, 34)
			)
		)
		empty_panel.name = "DraftNightDeckPreviewEmptyState"
		layout.add_child(empty_panel)
		flexible_body = empty_panel
		var empty_copy := VBoxContainer.new()
		empty_copy.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_copy.add_theme_constant_override("separation", 16)
		empty_panel.add_child(empty_copy)
		var star_center := CenterContainer.new()
		empty_copy.add_child(star_center)
		var star := SKETCH_UI_SCRIPT.make_draft_star(Vector2(90, 90))
		star_center.add_child(star)
		var heading := Label.new()
		heading.text = "YOUR DECK IS BUILT DURING DRAFT NIGHT"
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.76))
		heading.add_theme_font_size_override("font_size", 27)
		heading.add_theme_color_override("font_color", PALETTE.NAVY)
		empty_copy.add_child(heading)
		for line in [
			"Choose an opening dual-flavor Meal.",
			"Make 20 picks from rotating three-card offers.",
			"Every drafted card becomes part of your season collection.",
		]:
			var detail := Label.new()
			detail.text = line
			detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.14))
			detail.add_theme_font_size_override("font_size", 19)
			detail.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
			empty_copy.add_child(detail)
	else:
		var summary := Label.new()
		summary.name = "StarterDeckPreviewSummary"
		summary.text = "%d cards  •  %d unique cards" % [total_cards, entries.size()]
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
		summary.add_theme_font_size_override("font_size", 18)
		summary.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
		layout.add_child(summary)

		var list_panel := PanelContainer.new()
		list_panel.custom_minimum_size = Vector2(0, 420)
		list_panel.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI_SCRIPT.clean_style(
				Color(PALETTE.LAVENDER_GLASS, 0.56),
				PALETTE.PERIWINKLE,
				2,
				14,
				Vector4(22, 16, 22, 16)
			)
		)
		layout.add_child(list_panel)
		flexible_body = list_panel
		var list_scroll := ScrollContainer.new()
		list_scroll.name = "StarterDeckPreviewScroll"
		list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		list_panel.add_child(list_scroll)
		var list := VBoxContainer.new()
		list.name = "StarterDeckPreviewList"
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 4)
		list_scroll.add_child(list)
		_create_starter_deck_hover_preview(overlay)
		for entry in entries:
			_add_starter_deck_preview_row(list, entry)

	var close_button := Button.new()
	close_button.text = "CLOSE" if draft_night else "CLOSE DECK LIST"
	close_button.custom_minimum_size = Vector2(360, 64)
	close_button.focus_mode = Control.FOCUS_NONE
	WORKSPACE_UI_SCRIPT.style_button(close_button, "primary")
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.name = "CloseStarterDeckPreviewButton"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_connect_pressed(close_button, _close_starter_deck_preview)
	layout.add_child(close_button)
	overlay.resized.connect(_layout_starter_deck_preview.bind(panel, flexible_body))
	_layout_starter_deck_preview(panel, flexible_body)
	call_deferred("_layout_starter_deck_preview", panel, flexible_body)


func _layout_starter_deck_preview(panel: PanelContainer, flexible_body: Control) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(flexible_body):
		return
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(
		minf(780.0, maxf(520.0, viewport_size.x - 32.0)),
		minf(690.0, maxf(480.0, viewport_size.y - 32.0))
	)
	panel.custom_minimum_size = panel_size
	flexible_body.custom_minimum_size.y = clampf(panel_size.y - 310.0, 220.0, 380.0)
	panel.reset_size()
	var center := panel.get_parent() as Container
	if center != null:
		center.queue_sort()


func _starter_deck_preview_entries(starter_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not archetypes_by_id.has(starter_id):
		return entries
	var archetype: Dictionary = archetypes_by_id[starter_id]
	var deck: Dictionary = route_run_service.compact_starter_deck(_deck_entries_to_dict(archetype.get("starterDeck", [])), 15)
	for card_id_value in deck:
		var card_id := String(card_id_value)
		if not cards_by_id.has(card_id):
			continue
		var card: Dictionary = cards_by_id[card_id]
		entries.append({
			"id": card_id,
			"name": String(card.get("name", card_id)),
			"count": int(deck[card_id]),
			"type": String(card.get("card_type", "card")).capitalize(),
			"affinity": _draft_card_affinity_text(card),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var type_compare := String(a.type).naturalnocasecmp_to(String(b.type))
		if type_compare != 0:
			return type_compare < 0
		return String(a.name).naturalnocasecmp_to(String(b.name)) < 0
	)
	return entries


func _add_starter_deck_preview_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var card_id := String(entry.id)
	var card: Dictionary = cards_by_id[card_id]
	var row := HBoxContainer.new()
	row.name = "StarterDeckPreviewEntry_%s" % card_id
	row.custom_minimum_size = Vector2(0, 38)
	row.add_theme_constant_override("separation", 12)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(row)

	var count := Label.new()
	count.text = "×%d" % int(entry.count)
	count.custom_minimum_size = Vector2(48, 0)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.48))
	count.add_theme_font_size_override("font_size", 19)
	count.add_theme_color_override("font_color", PALETTE.CORAL.darkened(0.18))
	row.add_child(count)

	var name := Label.new()
	name.text = _card_display_name(card)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.12))
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", PALETTE.NAVY)
	row.add_child(name)

	var classification := Label.new()
	classification.text = "%s  •  %s" % [String(entry.type), String(entry.affinity)]
	classification.custom_minimum_size = Vector2(270, 0)
	classification.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	classification.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	classification.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	classification.add_theme_font_size_override("font_size", 15)
	classification.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	row.add_child(classification)
	row.mouse_entered.connect(func() -> void: _queue_starter_deck_hover_preview(row, card_id))
	row.mouse_exited.connect(_hide_starter_deck_hover_preview)


func _create_starter_deck_hover_preview(overlay: Control) -> void:
	starter_deck_hover_request_id += 1
	starter_deck_hover_preview = PanelContainer.new()
	starter_deck_hover_preview.custom_minimum_size = Vector2(310, 448)
	starter_deck_hover_preview.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI_SCRIPT.clean_style(
			Color(PALETTE.CREAM, 0.985),
			PALETTE.PERIWINKLE,
			2,
			14,
			Vector4(16, 16, 16, 18),
			0,
			true
		)
	)
	starter_deck_hover_preview.name = "StarterDeckCardHoverPreview"
	starter_deck_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	starter_deck_hover_preview.z_index = 1810
	starter_deck_hover_preview.visible = false
	overlay.add_child(starter_deck_hover_preview)
	starter_deck_hover_preview_body = CenterContainer.new()
	starter_deck_hover_preview_body.name = "StarterDeckCardHoverPreviewBody"
	starter_deck_hover_preview_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	starter_deck_hover_preview.add_child(starter_deck_hover_preview_body)


func _queue_starter_deck_hover_preview(source: Control, card_id: String) -> void:
	starter_deck_hover_request_id += 1
	var request_id := starter_deck_hover_request_id
	await get_tree().create_timer(CARD_HOVER_DELAY_SECONDS).timeout
	if (
		request_id != starter_deck_hover_request_id
		or current_screen != "season_setup"
		or not is_instance_valid(source)
		or find_child("StarterDeckPreview", true, false) == null
		or not source.get_global_rect().has_point(get_viewport().get_mouse_position())
	):
		return
	_show_starter_deck_hover_preview(source, card_id)


func _show_starter_deck_hover_preview(source: Control, card_id: String) -> void:
	if (
		starter_deck_hover_preview == null
		or starter_deck_hover_preview_body == null
		or not cards_by_id.has(card_id)
	):
		return
	for child in starter_deck_hover_preview_body.get_children():
		child.queue_free()
	var card_face := _make_card_face(cards_by_id[card_id], Vector2(274, 390), true)
	card_face.name = "StarterDeckHoveredCardFace"
	card_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	starter_deck_hover_preview_body.add_child(card_face)
	starter_deck_hover_preview.visible = true

	var preview_size := Vector2(310, 448)
	var popup_panel := find_child("StarterDeckPreviewPanel", true, false) as Control
	var popup_rect := popup_panel.get_global_rect() if popup_panel != null else Rect2(Vector2(330, 100), Vector2(780, 690))
	var source_rect := source.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var preview_x := popup_rect.end.x + 10
	if preview_x + preview_size.x > viewport_size.x - 8:
		preview_x = popup_rect.position.x - preview_size.x - 10
	var preview_y := source_rect.get_center().y - preview_size.y * 0.5
	starter_deck_hover_preview.global_position = Vector2(
		clampf(preview_x, 8, viewport_size.x - preview_size.x - 8),
		clampf(preview_y, 8, viewport_size.y - preview_size.y - 8)
	)


func _hide_starter_deck_hover_preview() -> void:
	starter_deck_hover_request_id += 1
	if starter_deck_hover_preview != null:
		starter_deck_hover_preview.visible = false


func _close_starter_deck_preview() -> void:
	_hide_starter_deck_hover_preview()
	starter_deck_hover_preview = null
	starter_deck_hover_preview_body = null
	var overlay := find_child("StarterDeckPreview", true, false)
	if overlay == null:
		return
	if is_instance_valid(ui_sound_controller):
		ui_sound_controller.play_transition()
	overlay.name = "StarterDeckPreviewClosing"
	overlay.queue_free()


func _connect_pressed(button: Button, callback: Callable) -> void:
	button.pressed.connect(callback, CONNECT_DEFERRED)


func _connect_external_link(button: Button, url: String) -> void:
	# Browser exports require shell_open to run inside the original click gesture;
	# a deferred signal can be treated as a blocked popup.
	button.pressed.connect(func() -> void: OS.shell_open(url))


func _show_start() -> void:
	_dispose_cached_shop_overworld()
	if not run.is_empty():
		_autosave_now(current_screen)
	current_screen = "start"
	run = {}
	season_setup_archetype_index = 0
	season_setup_difficulty_index = 0
	draft_deck = {}
	draft_offer = []
	draft_picks = []
	draft_signpost_chosen = false
	draft_menu_sort_mode = DRAFT_SORT_NAME
	draft_difficulty_id = "white"
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("")

	var screen = TITLE_MENU_SCENE.instantiate()
	screen.name = "BootLanding"
	var saved_result: Dictionary = run_state_service.load_run()
	var has_save := bool(saved_result.get("ok", false))
	var saved_run: Dictionary = saved_result.get("run", {}) if has_save else {}
	var saved_run_finished := has_save and bool(saved_run.get("run_over", false))
	screen.configure(_development_tools_enabled(), has_save, saved_run_finished)
	screen.continue_requested.connect(_continue_run_to_shop, CONNECT_DEFERRED)
	screen.start_requested.connect(_show_season_run_setup, CONNECT_DEFERRED)
	screen.tutorial_requested.connect(_show_tutorial, CONNECT_DEFERRED)
	screen.exit_requested.connect(_quit_from_title, CONNECT_DEFERRED)
	screen.settings_requested.connect(_show_settings, CONNECT_DEFERRED)
	screen.debug_requested.connect(_show_debug_starter_selection, CONNECT_DEFERRED)
	content.add_child(screen)

func _show_new_game_menu() -> void:
	current_screen = "new_game"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose how you want to play.")

	var intro := _add_panel(content, "New Game")
	_add_body_text(intro, "Choose a starter and begin your climb.")

	var mode_row := HBoxContainer.new()
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("separation", 10)
	content.add_child(mode_row)

	var season_panel := _add_panel(mode_row, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(season_panel, "Build your deck, win events, and earn your shot at Worlds.")
	var season_button := _make_button("Start Season Run")
	season_button.name = "NewSeasonRunButton"
	_style_button(season_button, "action")
	_connect_pressed(season_button, _show_season_run_setup)
	season_panel.add_child(season_button)

	if _development_tools_enabled():
		var debug_panel := _add_panel(mode_row, "Debug Sandbox", "#2b2f44")
		debug_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_body_text(debug_panel, "Jump directly to development tools and test matches.")
		var debug_button := _make_button("Open Debug Sandbox")
		debug_button.name = "NewDebugRunButton"
		_connect_pressed(debug_button, _show_debug_starter_selection)
		debug_panel.add_child(debug_button)

	var back_button := _make_button("Back")
	_connect_pressed(back_button, _show_start)
	content.add_child(back_button)


func _show_settings() -> void:
	if current_screen != "settings":
		settings_return_screen = current_screen
	if current_screen == "shop":
		_cache_active_shop_overworld()
	current_screen = "settings"
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Changes are saved automatically.")

	var settings_shell := PanelContainer.new()
	settings_shell.name = "SettingsMenuShell"
	settings_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	content.add_child(settings_shell)
	_add_settings_angular_surface(settings_shell, PALETTE.SURFACE_PAPER_MUTED, PALETTE.STRUCTURAL_EDGE)
	var shell_margin := MarginContainer.new()
	for side_name in ["left", "right", "top", "bottom"]:
		shell_margin.add_theme_constant_override("margin_%s" % side_name, 12)
	settings_shell.add_child(shell_margin)
	var settings_body := VBoxContainer.new()
	settings_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_body.add_theme_constant_override("separation", 10)
	shell_margin.add_child(settings_body)

	var header_parts := _make_settings_section("OPTIONS", PALETTE.CARBON, PALETTE.ELECTRIC_CYAN, Vector2(0, 54), Vector4(18, 8, 18, 8))
	var header_panel := header_parts.panel as PanelContainer
	header_panel.name = "SettingsHeader"
	settings_body.add_child(header_panel)
	var header_body := header_parts.body as VBoxContainer
	var header_heading := header_parts.heading as Label
	header_heading.name = "SettingsTitle"
	header_heading.add_theme_font_size_override("font_size", 25)
	header_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var header_row := HBoxContainer.new()
	header_row.name = "SettingsHeaderRow"
	header_row.add_theme_constant_override("separation", 12)
	header_body.add_child(header_row)
	header_body.move_child(header_row, 0)
	header_heading.reparent(header_row)
	var reset_button := _make_button("Restore Defaults")
	reset_button.set_meta("ui_button_quiet_keyline", true)
	reset_button.name = "SettingsResetButton"
	reset_button.custom_minimum_size = Vector2(190, 38)
	reset_button.focus_mode = Control.FOCUS_ALL
	_style_button(reset_button, "light")
	_connect_pressed(reset_button, _reset_player_settings)
	header_row.add_child(reset_button)

	var columns := HBoxContainer.new()
	columns.name = "SettingsColumns"
	columns.custom_minimum_size = Vector2(0, 410)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	settings_body.add_child(columns)

	var category_parts := _make_settings_section("CATEGORIES", PALETTE.SURFACE_PAPER_MUTED, PALETTE.STRUCTURAL_EDGE, Vector2(255, 410), Vector4(14, 12, 14, 14))
	var category_frame := category_parts.panel as PanelContainer
	category_frame.name = "SettingsCategoryRail"
	columns.add_child(category_frame)
	var category_list := category_parts.body as VBoxContainer
	category_list.add_theme_constant_override("separation", 8)

	var content_stack := VBoxContainer.new()
	content_stack.name = "SettingsCategoryContent"
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(content_stack)

	var category_panels := {}
	var category_buttons := {}
	var category_symbols := {
		"display": "display",
		"audio": "volume",
		"battle": "swords",
		"accessibility": "accessibility",
	}
	for category_id in ["display", "audio", "battle", "accessibility"]:
		var category_button := _make_button(String(category_id).to_upper())
		category_button.name = "SettingsCategory%s" % String(category_id).capitalize()
		category_button.custom_minimum_size = Vector2(0, 58)
		category_button.set_meta("ui_button_quiet_keyline", true)
		category_button.focus_mode = Control.FOCUS_ALL
		category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_buttons[category_id] = category_button
		category_list.add_child(category_button)
		MATERIAL_SYMBOLS.apply_to_button(category_button, String(category_symbols[category_id]), 21)
		category_button.pressed.connect(_select_settings_category.bind(category_id, category_panels, category_buttons))

	var display_parts := _make_settings_section("DISPLAY", PALETTE.SURFACE_PAPER, PALETTE.ELECTRIC_CYAN, Vector2(0, 410), Vector4(18, 13, 18, 15))
	var display_frame := display_parts.panel as PanelContainer
	display_frame.name = "SettingsDisplayPanel"
	display_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_child(display_frame)
	category_panels.display = display_frame
	var display_panel := display_parts.body as VBoxContainer
	display_panel.add_theme_constant_override("separation", 10)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.name = "FullscreenToggle"
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = bool(player_settings.fullscreen)
	fullscreen_toggle.focus_mode = Control.FOCUS_ALL
	fullscreen_toggle.set_meta("ui_button_quiet_keyline", true)
	fullscreen_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(fullscreen_toggle)
	_add_settings_control_panel(display_panel, fullscreen_toggle)

	var resolution_row := _add_settings_option_row(display_panel, "ResolutionRow")
	var resolution_label := Label.new()
	resolution_label.text = "Resolution"
	resolution_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(resolution_label)
	resolution_row.add_child(resolution_label)
	var resolution_select := OptionButton.new()
	resolution_select.name = "ResolutionSelect"
	resolution_select.custom_minimum_size = Vector2(220, 42)
	resolution_select.set_meta("ui_button_quiet_keyline", true)
	for option in RESOLUTION_OPTIONS:
		resolution_select.add_item("%d × %d" % [option.x, option.y])
		if int(player_settings.resolution[0]) == option.x and int(player_settings.resolution[1]) == option.y:
			resolution_select.select(resolution_select.item_count - 1)
	resolution_select.disabled = bool(player_settings.fullscreen)
	resolution_row.add_child(resolution_select)

	var text_scale_row := _add_settings_option_row(display_panel, "TextScaleRow")
	var text_scale_label := Label.new()
	text_scale_label.text = "Menu text size"
	text_scale_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(text_scale_label)
	text_scale_row.add_child(text_scale_label)
	var text_scale_select := OptionButton.new()
	text_scale_select.name = "TextScaleSelect"
	text_scale_select.custom_minimum_size = Vector2(220, 42)
	text_scale_select.set_meta("ui_button_quiet_keyline", true)
	for option in TEXT_SCALE_OPTIONS:
		text_scale_select.add_item("%d%%" % roundi(float(option) * 100.0))
		if is_equal_approx(float(option), float(player_settings.text_scale)):
			text_scale_select.select(text_scale_select.item_count - 1)
	text_scale_row.add_child(text_scale_select)

	var audio_parts := _make_settings_section("AUDIO", PALETTE.SURFACE_PAPER, PALETTE.EMERALD, Vector2(0, 410), Vector4(18, 13, 18, 15))
	var audio_frame := audio_parts.panel as PanelContainer
	audio_frame.name = "SettingsAudioPanel"
	audio_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_child(audio_frame)
	category_panels.audio = audio_frame
	var audio_panel := audio_parts.body as VBoxContainer
	audio_panel.add_theme_constant_override("separation", 8)
	var master_slider := _add_volume_setting(audio_panel, "Master", "master_volume")
	var music_slider := _add_volume_setting(audio_panel, "Music", "music_volume")
	var sfx_slider := _add_volume_setting(audio_panel, "Sound effects", "sfx_volume")

	var battle_parts := _make_settings_section("BATTLE", PALETTE.SURFACE_PAPER, PALETTE.SIGNAL_YELLOW, Vector2(0, 410), Vector4(18, 13, 18, 15))
	var battle_frame := battle_parts.panel as PanelContainer
	battle_frame.name = "SettingsBattlePanel"
	battle_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_child(battle_frame)
	category_panels.battle = battle_frame
	var battle_panel := battle_parts.body as VBoxContainer
	battle_panel.add_theme_constant_override("separation", 10)
	var play_speed_row := _add_settings_option_row(battle_panel, "PlaySpeedRow")
	var play_speed_label := Label.new()
	play_speed_label.text = "Play speed"
	play_speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(play_speed_label)
	play_speed_row.add_child(play_speed_label)
	var play_speed_select := OptionButton.new()
	play_speed_select.name = "PlaySpeedSelect"
	play_speed_select.custom_minimum_size = Vector2(220, 42)
	play_speed_select.set_meta("ui_button_quiet_keyline", true)
	for option in PLAY_SPEED_OPTIONS:
		play_speed_select.add_item(String(option.label))
		if String(option.id) == String(player_settings.play_speed):
			play_speed_select.select(play_speed_select.item_count - 1)
	play_speed_row.add_child(play_speed_select)
	var battle_text_row := _add_settings_option_row(battle_panel, "BattleTextScaleRow")
	var battle_text_label := Label.new()
	battle_text_label.text = "Battle text size"
	battle_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(battle_text_label)
	battle_text_row.add_child(battle_text_label)
	var battle_text_select := OptionButton.new()
	battle_text_select.name = "BattleTextScaleSelect"
	battle_text_select.custom_minimum_size = Vector2(220, 42)
	battle_text_select.set_meta("ui_button_quiet_keyline", true)
	for option in BATTLE_TEXT_SCALE_OPTIONS:
		battle_text_select.add_item("%d%%" % roundi(float(option) * 100.0))
		if is_equal_approx(float(option), float(player_settings.battle_text_scale)):
			battle_text_select.select(battle_text_select.item_count - 1)
	battle_text_row.add_child(battle_text_select)
	var board_info_toggle := CheckButton.new()
	board_info_toggle.name = "BoardInfoToggle"
	board_info_toggle.text = "Show board labels and pile counts"
	board_info_toggle.button_pressed = bool(player_settings.show_board_info)
	board_info_toggle.focus_mode = Control.FOCUS_ALL
	board_info_toggle.set_meta("ui_button_quiet_keyline", true)
	board_info_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(board_info_toggle)
	_add_settings_control_panel(battle_panel, board_info_toggle)

	var accessibility_parts := _make_settings_section("ACCESSIBILITY", PALETTE.SURFACE_PAPER, PALETTE.INTERFACE_VIOLET, Vector2(0, 410), Vector4(18, 13, 18, 15))
	var accessibility_frame := accessibility_parts.panel as PanelContainer
	accessibility_frame.name = "SettingsAccessibilityPanel"
	accessibility_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accessibility_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_child(accessibility_frame)
	category_panels.accessibility = accessibility_frame
	var accessibility_panel := accessibility_parts.body as VBoxContainer
	accessibility_panel.add_theme_constant_override("separation", 10)
	var high_contrast_toggle := CheckButton.new()
	high_contrast_toggle.name = "HighContrastToggle"
	high_contrast_toggle.text = "High-contrast text"
	high_contrast_toggle.button_pressed = bool(player_settings.high_contrast)
	high_contrast_toggle.focus_mode = Control.FOCUS_ALL
	high_contrast_toggle.set_meta("ui_button_quiet_keyline", true)
	high_contrast_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(high_contrast_toggle)
	_add_settings_control_panel(accessibility_panel, high_contrast_toggle)
	var reduced_motion_toggle := CheckButton.new()
	reduced_motion_toggle.name = "ReducedMotionToggle"
	reduced_motion_toggle.text = "Reduce menu motion"
	reduced_motion_toggle.button_pressed = bool(player_settings.reduced_motion)
	reduced_motion_toggle.focus_mode = Control.FOCUS_ALL
	reduced_motion_toggle.set_meta("ui_button_quiet_keyline", true)
	reduced_motion_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(reduced_motion_toggle)
	_add_settings_control_panel(accessibility_panel, reduced_motion_toggle)

	var actions := HBoxContainer.new()
	actions.name = "SettingsActions"
	actions.add_theme_constant_override("separation", 10)
	settings_body.add_child(actions)
	var back_button := _make_button("Back")
	back_button.set_meta("ui_button_quiet_keyline", true)
	back_button.name = "SettingsBackButton"
	back_button.custom_minimum_size.y = 50
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(back_button, "target")
	back_button.add_theme_font_size_override("font_size", 18)
	_connect_pressed(back_button, _return_from_settings)
	actions.add_child(back_button)
	var abandon_button := _make_button("Abandon Run")
	abandon_button.set_meta("ui_button_quiet_keyline", true)
	abandon_button.name = "SettingsAbandonRunButton"
	abandon_button.custom_minimum_size.y = 50
	abandon_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abandon_button.disabled = run.is_empty() and not run_state_service.has_saved_run()
	_style_button(abandon_button, "danger")
	abandon_button.add_theme_font_size_override("font_size", 18)
	actions.add_child(abandon_button)

	var abandon_confirmation := HBoxContainer.new()
	abandon_confirmation.name = "AbandonRunConfirmation"
	abandon_confirmation.visible = false
	abandon_confirmation.add_theme_constant_override("separation", 10)
	settings_body.add_child(abandon_confirmation)
	var confirmation_copy := Label.new()
	confirmation_copy.text = "Abandon this run? Your deck, money, and season progress cannot be recovered."
	confirmation_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(confirmation_copy, true)
	abandon_confirmation.add_child(confirmation_copy)
	var cancel_abandon_button := _make_button("Keep Playing")
	cancel_abandon_button.name = "CancelAbandonRunButton"
	cancel_abandon_button.set_meta("ui_button_quiet_keyline", true)
	_style_button(cancel_abandon_button, "default")
	abandon_confirmation.add_child(cancel_abandon_button)
	var confirm_abandon_button := _make_button("Yes, Abandon Run")
	confirm_abandon_button.name = "ConfirmAbandonRunButton"
	confirm_abandon_button.set_meta("ui_button_quiet_keyline", true)
	_style_button(confirm_abandon_button, "danger")
	abandon_confirmation.add_child(confirm_abandon_button)
	_connect_pressed(abandon_button, func() -> void:
		abandon_button.visible = false
		abandon_confirmation.visible = true
	)
	_connect_pressed(cancel_abandon_button, func() -> void:
		abandon_confirmation.visible = false
		abandon_button.visible = true
	)
	_connect_pressed(confirm_abandon_button, _abandon_current_run)

	_select_settings_category(settings_active_category, category_panels, category_buttons)

	fullscreen_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.fullscreen = enabled
		resolution_select.disabled = enabled
		_commit_player_settings()
	)
	resolution_select.item_selected.connect(func(index: int) -> void:
		if index < 0 or index >= RESOLUTION_OPTIONS.size():
			return
		var resolution: Vector2i = RESOLUTION_OPTIONS[index]
		player_settings.resolution = [resolution.x, resolution.y]
		_commit_player_settings()
	)
	text_scale_select.item_selected.connect(func(index: int) -> void:
		if index < 0 or index >= TEXT_SCALE_OPTIONS.size():
			return
		player_settings.text_scale = float(TEXT_SCALE_OPTIONS[index])
		_commit_player_settings()
	)
	play_speed_select.item_selected.connect(func(index: int) -> void:
		if index < 0 or index >= PLAY_SPEED_OPTIONS.size():
			return
		player_settings.play_speed = String(PLAY_SPEED_OPTIONS[index].id)
		_commit_player_settings()
	)
	battle_text_select.item_selected.connect(func(index: int) -> void:
		if index < 0 or index >= BATTLE_TEXT_SCALE_OPTIONS.size():
			return
		player_settings.battle_text_scale = float(BATTLE_TEXT_SCALE_OPTIONS[index])
		_commit_player_settings()
	)
	board_info_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.show_board_info = enabled
		_commit_player_settings()
	)
	high_contrast_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.high_contrast = enabled
		_commit_player_settings()
	)
	reduced_motion_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.reduced_motion = enabled
		_commit_player_settings()
	)
	_increase_options_text_sizes(settings_shell, 3)


func _increase_options_text_sizes(settings_root: Control, increase: int) -> void:
	if not is_instance_valid(settings_root) or bool(settings_root.get_meta("options_text_size_increased", false)):
		return
	settings_root.set_meta("options_text_size_increased", true)
	var nodes: Array[Node] = [settings_root]
	nodes.append_array(settings_root.find_children("*", "", true, false))
	for node in nodes:
		if node is Label or node is BaseButton:
			var text_control := node as Control
			text_control.add_theme_font_size_override(
				"font_size",
				text_control.get_theme_font_size("font_size") + increase
			)
		if node is OptionButton:
			var popup := (node as OptionButton).get_popup()
			popup.add_theme_font_size_override(
				"font_size",
				popup.get_theme_font_size("font_size") + increase
			)


func _add_settings_angular_surface(panel: Control, fill: Color, accent: Color):
	var surface = ANGULAR_SURFACE_SCRIPT.new()
	surface.name = "SettingsAngularSurface"
	surface.show_behind_parent = true
	panel.add_child(surface)
	surface.configure(fill, accent, fill.get_luminance() < 0.56, false)
	return surface


func _add_settings_option_row(parent: VBoxContainer, row_name: String) -> HBoxContainer:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override(
		"panel",
		_settings_row_style(Vector4(14, 6, 10, 6))
	)
	parent.add_child(row_panel)
	var row := HBoxContainer.new()
	row.name = row_name
	row.custom_minimum_size = Vector2(0, 48)
	row.add_theme_constant_override("separation", 12)
	row_panel.add_child(row)
	return row


func _add_settings_control_panel(parent: VBoxContainer, control: Control) -> void:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override(
		"panel",
		_settings_row_style(Vector4(14, 6, 10, 6))
	)
	row_panel.add_child(control)
	parent.add_child(row_panel)


func _select_settings_category(
	category_id: String,
	panels: Dictionary,
	buttons: Dictionary
) -> void:
	if not panels.has(category_id):
		category_id = "display"
	settings_active_category = category_id
	for panel_id in panels:
		var panel := panels[panel_id] as Control
		if is_instance_valid(panel):
			panel.visible = String(panel_id) == category_id
	for button_id in buttons:
		var button := buttons[button_id] as Button
		if not is_instance_valid(button):
			continue
		var selected := String(button_id) == category_id
		button.text = String(button_id).to_upper()
		_style_button(button, "selected" if selected else "default")


func _make_settings_section(
	title: String,
	fill: Color,
	accent: Color,
	minimum_size: Vector2,
	margins: Vector4
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_settings_angular_surface(panel, fill, accent)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(margins.x))
	margin.add_theme_constant_override("margin_top", int(margins.y))
	margin.add_theme_constant_override("margin_right", int(margins.z))
	margin.add_theme_constant_override("margin_bottom", int(margins.w))
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	margin.add_child(body)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_override("font", DISPLAY_FONT)
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override(
		"font_color",
		PALETTE.TEXT_PRIMARY if fill.get_luminance() < 0.56 else PALETTE.TEXT_ON_LIGHT
	)
	body.add_child(heading)
	var accent_rule := ColorRect.new()
	accent_rule.name = "%sAccentRule" % title.capitalize().replace(" ", "")
	accent_rule.custom_minimum_size = Vector2(0, 4)
	accent_rule.color = accent
	accent_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(accent_rule)
	body.move_child(accent_rule, 1)
	return {"panel": panel, "body": body, "heading": heading}


func _style_settings_text_control(control: Control, muted: bool = false) -> void:
	var color := PALETTE.TEXT_ON_LIGHT_SECONDARY if muted else PALETTE.TEXT_ON_LIGHT
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, color)


func _style_settings_slider(slider: HSlider) -> void:
	var track := StyleBoxLine.new()
	track.color = PALETTE.STEEL
	track.thickness = 6
	track.grow_begin = 2
	track.grow_end = 2
	slider.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxLine.new()
	fill.color = PALETTE.SELECTION_BLUE
	fill.thickness = 6
	fill.grow_begin = 2
	fill.grow_end = 2
	slider.add_theme_stylebox_override("grabber_area", fill)
	var highlight_fill := StyleBoxLine.new()
	highlight_fill.color = PALETTE.ELECTRIC_CYAN
	highlight_fill.thickness = 6
	highlight_fill.grow_begin = 2
	highlight_fill.grow_end = 2
	slider.add_theme_stylebox_override("grabber_area_highlight", highlight_fill)


func _settings_row_style(margins: Vector4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.SURFACE_PAPER_MUTED
	style.border_color = PALETTE.STRUCTURAL_EDGE
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 5
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style


func _abandon_current_run() -> void:
	autosave_suspended = true
	var clear_result: Dictionary = run_state_service.clear_saved_run()
	if not bool(clear_result.get("ok", false)):
		autosave_suspended = false
		_set_footer(String(clear_result.get("message", "Could not remove the saved run.")))
		return
	if is_instance_valid(suspended_tabletop):
		suspended_tabletop.queue_free()
	suspended_tabletop = null
	suspended_tabletop_screen = ""
	run = {}
	draft_deck = {}
	draft_offer.clear()
	draft_picks.clear()
	draft_signpost_chosen = false
	last_autosave_fingerprint = ""
	last_autosave_screen = ""
	autosave_suspended = false
	_show_start()


func _add_volume_setting(parent: Node, label_text: String, setting_key: String) -> HSlider:
	var setting_panel := PanelContainer.new()
	setting_panel.add_theme_stylebox_override(
		"panel",
		_settings_row_style(Vector4(14, 6, 14, 6))
	)
	parent.add_child(setting_panel)
	var box := VBoxContainer.new()
	box.name = "%sVolumeSetting" % label_text.replace(" ", "")
	box.add_theme_constant_override("separation", 2)
	setting_panel.add_child(box)
	var heading_row := HBoxContainer.new()
	box.add_child(heading_row)
	var heading := Label.new()
	heading.text = label_text
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_settings_text_control(heading)
	heading_row.add_child(heading)
	var value_label := Label.new()
	value_label.name = "%sVolumeValue" % label_text.replace(" ", "")
	value_label.text = "%d%%" % roundi(float(player_settings.get(setting_key, 80.0)))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 58
	_style_settings_text_control(value_label)
	heading_row.add_child(value_label)
	var slider := HSlider.new()
	slider.name = "%sVolumeSlider" % label_text.replace(" ", "")
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = float(player_settings.get(setting_key, 80.0))
	slider.custom_minimum_size = Vector2(0, 34)
	_style_settings_slider(slider)
	slider.value_changed.connect(func(value: float) -> void:
		player_settings[setting_key] = value
		value_label.text = "%d%%" % roundi(value)
		_apply_audio_settings()
		_save_player_settings()
	)
	box.add_child(slider)
	return slider


func _commit_player_settings() -> void:
	_apply_player_settings(not _running_automated_test())
	_save_player_settings()


func _reset_player_settings() -> void:
	player_settings = _default_player_settings()
	_commit_player_settings()
	_show_settings()


func _return_from_settings() -> void:
	match settings_return_screen:
		"start":
			_show_start()
		"season":
			_show_season_run()
		"deck":
			_show_deckbuilder()
		"packs":
			_show_packs()
		"tournament":
			_show_tournament()
		"meta":
			_show_meta()
		"kitchen_match", "tutorial":
			_restore_tabletop_after_settings()
		_:
			if not run.is_empty():
				_show_shop()
			else:
				_show_start()


func _show_tutorial() -> void:
	run = {}
	current_screen = "tutorial"
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("")
	var tutorial_game = _instantiate_scene(TABLETOP_3D_PROTOTYPE_SCENE_PATH)
	tutorial_game.configure_tutorial()
	tutorial_game.configure_battle_preferences(
		String(player_settings.play_speed),
		float(player_settings.battle_text_scale),
		bool(player_settings.reduced_motion),
		bool(player_settings.show_board_info)
	)
	tutorial_game.custom_minimum_size = Vector2(0, 820)
	tutorial_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_game.exit_requested.connect(_show_start)
	tutorial_game.settings_requested.connect(func() -> void: _show_settings_from_tabletop(tutorial_game))
	tutorial_game.battle_preferences_changed.connect(_on_battle_preferences_changed)
	content.add_child(tutorial_game)


func _show_debug_starter_selection() -> void:
	if not _development_tools_enabled():
		_show_start()
		return
	current_screen = "debug_starter"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose a starter deck for the debug sandbox.")

	var intro := _add_panel(content, "Choose Debug Starter")
	_add_body_text(intro, "Debug starts with every season system and the Kitchen Match surface unlocked for quick testing.")

	var starter_grid := HBoxContainer.new()
	starter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starter_grid.add_theme_constant_override("separation", 10)
	intro.add_child(starter_grid)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var box := _add_panel(starter_grid, _starter_label(archetype_id), archetype.get("color", "#2d3442"))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_body_text(box, archetype.get("summary", ""))
		var metrics := _calculate_deck_metrics(_deck_entries_to_dict(archetype.get("starterDeck", [])), {})
		_add_body_text(box, _format_metrics_short(metrics))
		var button := _make_button("Start With " + _starter_label(archetype_id))
		var selected_id: String = archetype_id
		_connect_pressed(button, func() -> void: _start_new_run_with_mode(selected_id, "debug", "white"))
		box.add_child(button)

	var back_button := _make_button("Back")
	_connect_pressed(back_button, _show_start)
	content.add_child(back_button)


func _show_season_run_setup() -> void:
	if current_screen != "season_setup":
		season_setup_difficulty_open = false
	current_screen = "season_setup"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose a starter deck, then begin your route through Starter City.")

	var selected_starter_id := String(DEMO_STARTER_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	var difficulty := _difficulty_data(selected_difficulty_id)
	var draft_night_selected := selected_starter_id == DRAFT_NIGHT_ID
	var starter_title := "Draft Night"
	var starter_summary := "Build your season deck one choice at a time from rotating three-card offers."
	var starter_detail := "20 picks  •  Opening signpost Meal  •  Drafted cards become your collection"
	if not draft_night_selected:
		var archetype: Dictionary = archetypes_by_id[selected_starter_id]
		var starter_deck: Dictionary = route_run_service.compact_starter_deck(_deck_entries_to_dict(archetype.get("starterDeck", [])), 15)
		var metrics := _calculate_deck_metrics(starter_deck, {})
		starter_title = _archetype_label(selected_starter_id)
		starter_summary = String(archetype.get("summary", ""))
		starter_detail = "%s  •  Starter deck: %d cards  •  40 persistent life" % [
			_format_metrics_short(metrics),
			_deck_total(starter_deck),
		]

	var starter_art := _make_menu_deck_art(
		selected_starter_id,
		starter_title,
		draft_night_selected,
		Vector2(236, 292)
	)
	starter_art.name = "SelectedStarterArtwork"
	var starter_profiles: Array[Dictionary] = []
	for profile_id in ["spicy", "hearty", "sweet"]:
		var profile_archetype: Dictionary = archetypes_by_id[profile_id]
		var profile_deck: Dictionary = route_run_service.compact_starter_deck(
			_deck_entries_to_dict(profile_archetype.get("starterDeck", [])),
			15
		)
		starter_profiles.append({
			"id": profile_id,
			"deck_title": "%s DECK" % _archetype_label(profile_id).to_upper(),
			"description": String(profile_archetype.get("summary", "")),
			"detail": "%s\n%d-card starter  •  40 persistent life" % [
				_format_metrics_short(_calculate_deck_metrics(profile_deck, {})),
				_deck_total(profile_deck),
			],
		})
	var screen = SEASON_SETUP_MENU_SCENE.instantiate()
	screen.name = "SeasonRegistration"
	screen.back_requested.connect(_show_start, CONNECT_DEFERRED)
	screen.starter_selected_requested.connect(_select_season_setup_archetype, CONNECT_DEFERRED)
	screen.deck_list_requested.connect(
		func(index: int) -> void:
			var requested_index := clampi(index, 0, 2)
			_show_starter_deck_preview(String(DEMO_STARTER_ORDER[requested_index])),
		CONNECT_DEFERRED
	)
	screen.previous_border_requested.connect(func() -> void: _shift_season_setup_difficulty(-1), CONNECT_DEFERRED)
	screen.next_border_requested.connect(func() -> void: _shift_season_setup_difficulty(1), CONNECT_DEFERRED)
	screen.confirm_requested.connect(_confirm_season_run_setup, CONNECT_DEFERRED)
	screen.difficulty_closed_requested.connect(_close_season_setup_difficulty, CONNECT_DEFERRED)
	content.add_child(screen)
	screen.configure({
		"route_mode": true,
		"starter_id": selected_starter_id,
		"starter_index": season_setup_archetype_index,
		"difficulty_id": selected_difficulty_id,
		"difficulty_index": season_setup_difficulty_index,
		"difficulty_open": season_setup_difficulty_open,
		"starter_title": starter_title,
		"info_title": "Draft Night" if draft_night_selected else "%s Deck" % starter_title,
		"info_detail": "%s  •  %s" % [starter_summary, starter_detail],
		"difficulty_name": String(difficulty.get("name", "Black")),
		"difficulty_rules": "Begin with 40 persistent life. Choose connected stops, grow a 15-card starter, and defeat the city champion.",
		"border_stats": "Enemy • Shop • Event • Local Champion • City Champion",
		"route_hint": "STARTS AT DRAFT NIGHT" if draft_night_selected else "STARTS IN STARTER CITY",
		"starter_profiles": starter_profiles,
	}, starter_art)
	_add_starter_info_symbol(screen.get_symbol_mount(), selected_starter_id, draft_night_selected)


func _begin_draft(difficulty_id: String = "white") -> void:
	run = {}
	draft_deck = {}
	draft_offer = []
	draft_picks = []
	draft_signpost_chosen = false
	draft_menu_sort_mode = DRAFT_SORT_NAME
	draft_difficulty_id = difficulty_id
	_roll_draft_offer(true)
	_show_draft()


func _show_draft() -> void:
	current_screen = "draft"
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_remove_draft_hover_preview()
	_update_status()
	var drafted_count := _draft_total()
	var signpost_step := not draft_signpost_chosen
	_set_footer("Click a card to add it to your deck.")

	var screen = DRAFT_MENU_SCENE.instantiate()
	screen.name = "DraftWorkspaceScreen"
	screen.abandon_requested.connect(_show_start, CONNECT_DEFERRED)
	content.add_child(screen)
	screen.configure(
		"Choose your opening dual-flavor Meal."
		if signpost_step
		else "Pick %d of %d  •  Click one card to add it to your deck." % [drafted_count + 1, DRAFT_DECK_SIZE],
		"%02d / %02d" % [drafted_count, DRAFT_DECK_SIZE]
	)
	_populate_draft_offer_row(screen.get_offer_row())
	_add_draft_deck_rail(screen.get_workspace())
	_create_draft_hover_preview()
	_add_draft_distribution_charts(screen)


func _populate_draft_offer_row(offer_row: HBoxContainer) -> void:
	var offer_slots := offer_row.get_children()
	for index in range(offer_slots.size()):
		var slot := offer_slots[index] as PanelContainer
		slot.visible = index < draft_offer.size()
		if not slot.visible:
			continue
		for child in slot.get_children():
			child.queue_free()
	for offer_index in range(draft_offer.size()):
		var card_id_value = draft_offer[offer_index]
		var card_id := String(card_id_value)
		var card: Dictionary = cards_by_id[card_id]
		var choice_panel := offer_slots[offer_index] as PanelContainer
		choice_panel.name = "DraftOffer_%s" % card_id
		var choice := VBoxContainer.new()
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.add_theme_constant_override("separation", 6)
		choice.set_meta("light_surface", true)
		choice_panel.add_child(choice)
		choice_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		choice_panel.add_theme_stylebox_override("panel", _draft_offer_panel_style(false))
		if _card_uses_authored_face(card):
			var face := _make_card_face(card, Vector2(176, 250), true)
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			choice.add_child(face)
		else:
			_add_body_text(choice, "%s • %s" % [String(card.get("rarity", "common")).capitalize(), _card_descriptor(card)])
			_add_body_text(choice, String(card.get("text", "")))
		var selected_card_id := card_id
		var hovered_card_id := card_id
		var pick_button := Button.new()
		pick_button.name = "DraftPick_%s" % card_id
		pick_button.text = "PICK THIS CARD"
		pick_button.focus_mode = Control.FOCUS_NONE
		WORKSPACE_UI_SCRIPT.style_button(pick_button, "primary")
		pick_button.pressed.connect(func() -> void: _draft_pick(selected_card_id, choice_panel), CONNECT_DEFERRED)
		choice.add_child(pick_button)
		choice_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_draft_pick(selected_card_id, choice_panel)
		)
		choice_panel.mouse_entered.connect(func() -> void:
			choice_panel.add_theme_stylebox_override("panel", _draft_offer_panel_style(true))
			_queue_draft_hover_preview(choice_panel, hovered_card_id)
		)
		choice_panel.mouse_exited.connect(func() -> void:
			choice_panel.add_theme_stylebox_override("panel", _draft_offer_panel_style(false))
			_hide_draft_hover_preview()
		)


func _draft_offer_panel_style(hovered: bool) -> StyleBoxFlat:
	return WORKSPACE_UI_SCRIPT.clean_style(
		Color(PALETTE.BLUSH, 0.34) if hovered else Color(PALETTE.CREAM, 0.96),
		PALETTE.SKY if hovered else PALETTE.NAVY,
		3 if hovered else 2,
		16,
		Vector4(12, 10, 12, 12),
		0,
		true
	)


func _add_draft_deck_rail(parent: HBoxContainer) -> void:
	var rail_panel := parent.get_node_or_null("DraftDeckRail") as PanelContainer
	if rail_panel == null:
		rail_panel = PanelContainer.new()
		rail_panel.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI_SCRIPT.clean_style(
				WORKSPACE_UI_SCRIPT.SURFACE,
				WORKSPACE_UI_SCRIPT.TEAL,
				2,
				10,
				Vector4(18, 16, 18, 18),
				4,
				true
			)
		)
		rail_panel.name = "DraftDeckRail"
		parent.add_child(rail_panel)
	rail_panel.custom_minimum_size = Vector2(264, 318)
	rail_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	rail_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 6)
	rail_panel.add_child(rail)
	var heading := Label.new()
	heading.text = "YOUR DECK"
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.76))
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", PALETTE.NAVY)
	rail.add_child(heading)
	var hint := Label.new()
	hint.text = "%d/%d cards  •  Hover to inspect" % [_draft_total(), DRAFT_DECK_SIZE]
	hint.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	rail.add_child(hint)

	var scroll_box := ScrollContainer.new()
	scroll_box.custom_minimum_size = Vector2(0, 228)
	scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rail.add_child(scroll_box)
	var grid := GridContainer.new()
	grid.name = "DraftDeckGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 6)
	scroll_box.add_child(grid)
	var entries := _draft_summary_entries(DRAFT_SORT_AFFINITY)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "Your picks will land here."
		empty.add_theme_color_override("font_color", Color("#7f8d9e"))
		grid.add_child(empty)
		return
	for entry in entries:
		var card_id := String(entry.id)
		var card: Dictionary = cards_by_id[card_id]
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(70, 116)
		tile.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI_SCRIPT.clean_style(
				Color(PALETTE.CREAM, 0.96),
				_affinity_color(_card_archetype(card)).darkened(0.28),
				2,
				7,
				Vector4(3, 3, 3, 3)
			)
		)
		tile.name = "DraftDeckCard_%s" % card_id
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(tile)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 2)
		tile.add_child(stack)
		var face := _make_card_face(card, Vector2(66, 94), true)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(face)
		var count := Label.new()
		count.text = "×%d" % int(entry.count)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size", 13)
		count.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(count)
		var hover_card_id := card_id
		tile.mouse_entered.connect(func() -> void: _queue_draft_hover_preview(tile, hover_card_id))
		tile.mouse_exited.connect(_hide_draft_hover_preview)


func _create_draft_hover_preview() -> void:
	draft_hover_preview = PanelContainer.new()
	draft_hover_preview.custom_minimum_size = Vector2(326, 466)
	draft_hover_preview.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI_SCRIPT.clean_style(
			WORKSPACE_UI_SCRIPT.SURFACE,
			WORKSPACE_UI_SCRIPT.TEAL,
			2,
			10,
			Vector4(12, 12, 12, 12),
			4,
			true
		)
	)
	draft_hover_preview.name = "DraftHoverPreview"
	draft_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draft_hover_preview.z_index = 1800
	draft_hover_preview.visible = false
	add_child(draft_hover_preview)
	draft_hover_preview_body = CenterContainer.new()
	draft_hover_preview_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draft_hover_preview.add_child(draft_hover_preview_body)


func _remove_draft_hover_preview() -> void:
	draft_hover_request_id += 1
	var existing := find_child("DraftHoverPreview", true, false)
	if existing != null:
		existing.queue_free()
	draft_hover_preview = null
	draft_hover_preview_body = null


func _queue_draft_hover_preview(source: Control, card_id: String) -> void:
	draft_hover_request_id += 1
	var request_id := draft_hover_request_id
	await get_tree().create_timer(CARD_HOVER_DELAY_SECONDS).timeout
	if (
		request_id != draft_hover_request_id
		or not is_instance_valid(source)
		or not source.get_global_rect().has_point(get_viewport().get_mouse_position())
	):
		return
	_show_draft_hover_preview(source, card_id)


func _show_draft_hover_preview(source: Control, card_id: String) -> void:
	if draft_hover_preview == null or draft_hover_preview_body == null or not cards_by_id.has(card_id):
		return
	for child in draft_hover_preview_body.get_children():
		child.queue_free()
	var card: Dictionary = cards_by_id[card_id]
	var keywords: Array = card.get("keywords", [])
	var known_keywords: Array[String] = []
	for keyword_value in keywords:
		var keyword_id := String(keyword_value)
		if KEYWORD_TOOLTIPS.has(keyword_id):
			known_keywords.append(keyword_id)
	var preview_width := 326.0 if known_keywords.is_empty() else 594.0
	draft_hover_preview.custom_minimum_size = Vector2(preview_width, 466)

	var preview_row := HBoxContainer.new()
	preview_row.name = "DraftHoverPreviewContent"
	preview_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_row.add_theme_constant_override("separation", 12)
	draft_hover_preview_body.add_child(preview_row)
	preview_row.add_child(_make_card_face(card, Vector2(300, 426), true))
	if not known_keywords.is_empty():
		var glossary := VBoxContainer.new()
		glossary.name = "DraftKeywordGlossary"
		glossary.custom_minimum_size = Vector2(244, 0)
		glossary.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glossary.add_theme_constant_override("separation", 9)
		preview_row.add_child(glossary)
		var heading := Label.new()
		heading.text = "KEYWORD GUIDE"
		heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.66))
		heading.add_theme_font_size_override("font_size", 12)
		heading.add_theme_color_override("font_color", PALETTE.NAVY)
		glossary.add_child(heading)
		for keyword_id in known_keywords:
			_add_draft_keyword_explanation(glossary, keyword_id)
	draft_hover_preview.visible = true
	var source_rect := source.get_global_rect()
	var viewport_size := get_viewport_rect().size
	var preview_position := Vector2(source_rect.position.x - preview_width - 14, source_rect.position.y - 110)
	preview_position.x = clampf(preview_position.x, 12, viewport_size.x - preview_width - 12)
	preview_position.y = clampf(preview_position.y, 12, viewport_size.y - 478)
	draft_hover_preview.global_position = preview_position


func _add_draft_keyword_explanation(parent: VBoxContainer, keyword_id: String) -> void:
	_add_keyword_explanation(parent, keyword_id, "DraftKeyword")


func _add_keyword_explanation(parent: VBoxContainer, keyword_id: String, node_prefix: String) -> void:
	var tooltip: Dictionary = KEYWORD_TOOLTIPS.get(keyword_id, {})
	if tooltip.is_empty():
		return
	var accent := _keyword_accent_color(keyword_id)
	var panel := PanelContainer.new()
	panel.clip_contents = true
	panel.add_theme_stylebox_override(
		"panel",
		WORKSPACE_UI_SCRIPT.clean_style(
			PALETTE.CREAM,
			PALETTE.NAVY,
			2,
			12,
			Vector4.ZERO,
			0,
			true
		)
	)
	panel.name = "%s_%s" % [node_prefix, keyword_id]
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var accent_bar := ColorRect.new()
	accent_bar.name = "KeywordAccentBar"
	accent_bar.color = accent
	accent_bar.custom_minimum_size = Vector2(7, 0)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent_bar)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	row.add_child(margin)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 8)
	margin.add_child(copy)
	var title_badge := WORKSPACE_UI_SCRIPT.make_badge(
		String(tooltip.title).to_upper(),
		accent.lightened(0.50),
		PALETTE.NAVY
	)
	title_badge.name = "KeywordTitleBadge"
	title_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	copy.add_child(title_badge)
	var body := Label.new()
	body.text = String(tooltip.body)
	body.custom_minimum_size = Vector2(214, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", PALETTE.NAVY)
	body.add_theme_constant_override("line_spacing", 2)
	copy.add_child(body)


func _keyword_accent_color(keyword_id: String) -> Color:
	match keyword_id:
		"piercing":
			return PALETTE.CORAL
		"stalwart":
			return PALETTE.PERIWINKLE
		"taunt":
			return PALETTE.FRESH_YELLOW
		"hand_trap":
			return PALETTE.FUNKY_PLUM
		_:
			return PALETTE.SKY


func _hide_draft_hover_preview() -> void:
	draft_hover_request_id += 1
	if draft_hover_preview != null and is_instance_valid(draft_hover_preview):
		draft_hover_preview.visible = false


func _add_draft_distribution_charts(parent: VBoxContainer) -> void:
	var charts := parent.get_node_or_null("DraftDistributionCharts") as HBoxContainer
	if charts == null:
		charts = HBoxContainer.new()
		charts.name = "DraftDistributionCharts"
		parent.add_child(charts)
	charts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charts.add_theme_constant_override("separation", 12)
	var type_counts := {"ingredient": 0, "meal": 0, "chef": 0, "tool": 0, "environment": 0, "spice": 0}
	var flavor_counts := {"spicy": 0, "hearty": 0, "sweet": 0, "fresh": 0, "funky": 0}
	for card_id in draft_deck:
		var card: Dictionary = cards_by_id[card_id]
		var copies := int(draft_deck[card_id])
		var type_id := String(card.get("card_type", "other"))
		type_counts[type_id] = int(type_counts.get(type_id, 0)) + copies
		for flavor_id in _draft_card_affinities(card):
			if flavor_counts.has(flavor_id):
				flavor_counts[flavor_id] = int(flavor_counts[flavor_id]) + copies
	_add_draft_bar_chart(charts, "CARDS BY TYPE", type_counts, [
		["ingredient", "Ingredients", Color("#65b8e8")],
		["meal", "Meals", Color("#f1a55b")],
		["chef", "Chefs", Color("#d5c2ee")],
		["tool", "Tools", Color("#9daab7")],
		["environment", "Environments", Color("#73bc8c")],
		["spice", "Spices", Color("#df7272")],
	])
	_add_draft_bar_chart(charts, "CARDS BY FLAVOR", flavor_counts, [
		["spicy", "Spicy", _affinity_color("spicy")],
		["hearty", "Hearty", _affinity_color("hearty")],
		["sweet", "Sweet", _affinity_color("sweet")],
		["fresh", "Fresh", Color("#4fae85")],
		["funky", "Funky", Color("#8a6fd1")],
	])


func _add_draft_bar_chart(parent: HBoxContainer, title: String, counts: Dictionary, rows: Array) -> void:
	var panel_name := "DraftFlavorChartPanel" if "FLAVOR" in title else "DraftTypeChartPanel"
	var chart_panel := parent.get_node_or_null(panel_name) as PanelContainer
	if chart_panel == null:
		chart_panel = PanelContainer.new()
		chart_panel.add_theme_stylebox_override(
			"panel",
			WORKSPACE_UI_SCRIPT.clean_style(
				WORKSPACE_UI_SCRIPT.SURFACE,
				WORKSPACE_UI_SCRIPT.TEAL if "FLAVOR" in title else WORKSPACE_UI_SCRIPT.PALETTE.SLATE,
				2,
				10,
				Vector4(18, 14, 18, 16)
			)
		)
		chart_panel.name = panel_name
		parent.add_child(chart_panel)
	else:
		for child in chart_panel.get_children():
			child.queue_free()
	chart_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chart := VBoxContainer.new()
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.add_theme_constant_override("separation", 6)
	chart_panel.add_child(chart)
	var chart_title := Label.new()
	chart_title.text = title
	chart_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	chart_title.add_theme_font_size_override("font_size", 19)
	chart_title.add_theme_color_override("font_color", PALETTE.NAVY)
	chart.add_child(chart_title)
	var columns := HBoxContainer.new()
	columns.name = title.to_pascal_case() + "Graph"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_theme_constant_override("separation", 16)
	chart.add_child(columns)
	for row_index in range(rows.size()):
		var row: Array = rows[row_index]
		var count := int(counts.get(String(row[0]), 0))
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(62, 0)
		column.alignment = BoxContainer.ALIGNMENT_END
		column.add_theme_constant_override("separation", 4)
		columns.add_child(column)

		var value := Label.new()
		value.text = str(count)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", row[2] if count > 0 else Color("#8B827A"))
		column.add_child(value)

		var bar_center := CenterContainer.new()
		bar_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(bar_center)
		var bar_track := PanelContainer.new()
		bar_track.custom_minimum_size = Vector2(38, 68)
		var track_style := StyleBoxFlat.new()
		track_style.bg_color = Color(PALETTE.LAVENDER_GLASS, 0.82)
		track_style.border_color = PALETTE.NAVY_MUTED
		track_style.set_border_width_all(1)
		track_style.set_corner_radius_all(5)
		bar_track.add_theme_stylebox_override("panel", track_style)
		bar_center.add_child(bar_track)

		# PanelContainer owns its direct child's layout. This plain host gives the
		# colored fill freedom to anchor to the bottom and grow independently.
		var fill_host := Control.new()
		fill_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_track.add_child(fill_host)
		var bar := ColorRect.new()
		bar.color = row[2]
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 1.0
		bar.anchor_bottom = 1.0
		bar.offset_left = 3.0
		bar.offset_right = -3.0
		bar.offset_top = 0.0
		bar.offset_bottom = 0.0
		fill_host.add_child(bar)
		var target_top := 1.0 - clampf(float(count) / float(DRAFT_DECK_SIZE), 0.0, 1.0)
		if count > 0 and not _running_automated_test() and not _reduced_motion_enabled():
			var graph_tween := create_tween()
			graph_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			graph_tween.tween_interval(0.04 * float(row_index))
			graph_tween.tween_property(bar, "anchor_top", target_top, 0.42)
		else:
			bar.anchor_top = target_top

		var label := Label.new()
		label.text = String(row[1])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
		column.add_child(label)


func _draft_pick(card_id: String, source: Control = null) -> void:
	if draft_pick_animating or current_screen != "draft" or not draft_offer.has(card_id) or not cards_by_id.has(card_id):
		return
	if source != null and is_instance_valid(source) and not _running_automated_test() and not _reduced_motion_enabled():
		draft_pick_animating = true
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var flying_card := _make_card_face(cards_by_id[card_id], Vector2(176, 250), false)
		flying_card.name = "DraftPickAnimation"
		flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flying_card.z_index = 1700
		flying_card.global_position = source.get_global_rect().get_center() - Vector2(88, 125)
		add_child(flying_card)
		var rail := find_child("DraftDeckRail", true, false) as Control
		var destination := Vector2(get_viewport_rect().size.x - 95, 150)
		if rail != null:
			destination = rail.get_global_rect().get_center() - Vector2(35, 50)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(flying_card, "global_position", destination, 0.38)
		tween.tween_property(flying_card, "scale", Vector2(0.36, 0.36), 0.38)
		tween.tween_property(flying_card, "rotation", 0.12, 0.38)
		tween.tween_property(flying_card, "modulate:a", 0.25, 0.38).set_delay(0.22)
		tween.chain().tween_callback(func() -> void:
			flying_card.queue_free()
			draft_pick_animating = false
			_commit_draft_pick(card_id)
		)
		return
	_commit_draft_pick(card_id)


func _commit_draft_pick(card_id: String) -> void:
	draft_deck[card_id] = int(draft_deck.get(card_id, 0)) + 1
	draft_picks.append(card_id)
	if not draft_signpost_chosen:
		draft_signpost_chosen = true
	if _draft_total() >= DRAFT_DECK_SIZE:
		_finish_draft()
		return
	_roll_draft_offer(false)
	_show_draft()


func _roll_draft_offer(signpost_offer: bool) -> void:
	draft_offer = _draft_signpost_offer() if signpost_offer else _draft_random_offer()


func _draft_signpost_offer() -> Array[String]:
	var groups := {}
	for card in cards:
		if String(card.get("card_type", "")) != "meal":
			continue
		var card_archetypes: Array = card.get("archetypes", [])
		if card_archetypes.size() != 2:
			continue
		var pair: Array[String] = [String(card_archetypes[0]), String(card_archetypes[1])]
		pair.sort()
		var pair_key := "|".join(pair)
		if not groups.has(pair_key):
			groups[pair_key] = []
		groups[pair_key].append(String(card.id))

	var pair_keys: Array = groups.keys()
	_shuffle_draft_values(pair_keys)
	var result: Array[String] = []
	for pair_index in range(mini(DRAFT_OFFER_SIZE, pair_keys.size())):
		var candidates: Array = groups[pair_keys[pair_index]]
		result.append(String(candidates[rng.randi_range(0, candidates.size() - 1)]))
	return result


func _draft_random_offer() -> Array[String]:
	var candidates: Array = []
	for card in cards:
		var card_id := String(card.get("id", ""))
		if card_id == "":
			continue
		candidates.append(card_id)
	_shuffle_draft_values(candidates)
	var result: Array[String] = []
	for index in range(mini(DRAFT_OFFER_SIZE, candidates.size())):
		result.append(String(candidates[index]))
	return result


func _shuffle_draft_values(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held_value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held_value


func _draft_total() -> int:
	return _deck_total(draft_deck)


func _draft_summary_text() -> String:
	if draft_deck.is_empty():
		return "No cards drafted yet."
	var entries := _draft_summary_entries()
	var parts: Array[String] = []
	for entry in entries:
		parts.append("%s ×%d" % [String(entry.name), int(entry.count)])
	return "  •  ".join(parts)


func _draft_summary_entries(sort_mode: String = "") -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for card_id in draft_deck:
		var card: Dictionary = cards_by_id[card_id]
		entries.append({
			"id": String(card_id),
			"name": String(card.get("name", card_id)),
			"count": int(draft_deck[card_id]),
			"type": String(card.get("card_type", "card")).capitalize(),
			"affinity": _draft_card_affinity_text(card),
			"affinity_sort": _draft_card_affinity_sort_key(card),
		})
	var selected_sort := draft_menu_sort_mode if sort_mode == "" else sort_mode
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_key := _draft_entry_sort_key(a, selected_sort)
			var b_key := _draft_entry_sort_key(b, selected_sort)
			return a_key < b_key
	)
	return entries


func _draft_card_affinities(card: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var authored_affinities: Array = card.get("archetypes", [])
	if authored_affinities.is_empty():
		authored_affinities = card.get("ingredient_types", [])
	for affinity_value in authored_affinities:
		var affinity_id := String(affinity_value)
		if affinity_id != "" and not result.has(affinity_id):
			result.append(affinity_id)
	if result.is_empty():
		result.append(String(card.get("archetype", "neutral")))
	return result


func _draft_card_affinity_text(card: Dictionary) -> String:
	var labels: Array[String] = []
	for affinity_id in _draft_card_affinities(card):
		labels.append(_affinity_label(affinity_id))
	return " / ".join(labels)


func _draft_card_affinity_sort_key(card: Dictionary) -> String:
	var affinities := _draft_card_affinities(card)
	affinities.sort()
	return "|".join(affinities)


func _draft_entry_sort_key(entry: Dictionary, sort_mode: String) -> String:
	var name_key := String(entry.name).to_lower()
	if sort_mode == DRAFT_SORT_TYPE:
		return "%s|%s|%s" % [String(entry.type).to_lower(), String(entry.affinity_sort), name_key]
	if sort_mode == DRAFT_SORT_AFFINITY:
		return "%s|%s|%s" % [String(entry.affinity_sort), String(entry.type).to_lower(), name_key]
	return name_key


func _show_drafted_cards_menu() -> void:
	if current_screen != "draft" or find_child("DraftedCardsMenu", true, false) != null:
		return
	var overlay := Control.new()
	overlay.name = "DraftedCardsMenu"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1500
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.12, 0.09, 0.07, 0.76)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var menu_panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(660, 0),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(30, 26, 30, 28),
		1
	)
	menu_panel.name = "DraftedCardsMenuPanel"
	center.add_child(menu_panel)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.set_meta("light_surface", true)
	menu_panel.add_child(menu)
	var heading := Label.new()
	heading.text = "DRAFTED DECK — %d/%d CARDS" % [_draft_total(), DRAFT_DECK_SIZE]
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.82))
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	menu.add_child(heading)

	var sort_row := HBoxContainer.new()
	sort_row.name = "DraftedCardsSortRow"
	sort_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort_row.add_theme_constant_override("separation", 8)
	menu.add_child(sort_row)
	for sort_option in [
		{"id": DRAFT_SORT_NAME, "label": "Name", "node_name": "DraftSortNameButton"},
		{"id": DRAFT_SORT_TYPE, "label": "Card Type", "node_name": "DraftSortTypeButton"},
		{"id": DRAFT_SORT_AFFINITY, "label": "Affinity", "node_name": "DraftSortAffinityButton"},
	]:
		var sort_mode := String(sort_option.id)
		var sort_button := SKETCH_UI_SCRIPT.make_button(
			("✓ " if sort_mode == draft_menu_sort_mode else "") + String(sort_option.label).to_upper(),
			Vector2(0, 58),
			sort_mode == draft_menu_sort_mode,
			18,
			sort_mode != draft_menu_sort_mode
		)
		sort_button.name = String(sort_option.node_name)
		sort_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_connect_pressed(sort_button, func() -> void: _set_drafted_cards_sort_mode(sort_mode))
		sort_row.add_child(sort_button)

	var entries := _draft_summary_entries()
	if entries.is_empty():
		_add_body_text(menu, "You have not drafted any cards yet.")
	else:
		var list_scroll := ScrollContainer.new()
		list_scroll.name = "DraftedCardsMenuScroll"
		list_scroll.custom_minimum_size = Vector2(0, minf(420.0, 18.0 + float(entries.size()) * 42.0))
		list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		menu.add_child(list_scroll)

		var list := VBoxContainer.new()
		list.name = "DraftedCardsMenuList"
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 6)
		list_scroll.add_child(list)

		for entry in entries:
			var card_id := String(entry.id)
			var card: Dictionary = cards_by_id[card_id]
			var row := HBoxContainer.new()
			row.name = "DraftedCardEntry_%s" % card_id
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 12)
			list.add_child(row)

			var card_label := Label.new()
			card_label.text = "%s  —  %s  —  %s" % [
				_card_display_name(card),
				String(entry.type),
				String(entry.affinity),
			]
			card_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.12))
			card_label.add_theme_font_size_override("font_size", 17)
			card_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
			row.add_child(card_label)

			var count_label := Label.new()
			count_label.name = "DraftedCardCount_%s" % card_id
			count_label.text = "×%d" % int(entry.count)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.add_theme_font_size_override("font_size", 18)
			count_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
			row.add_child(count_label)

	var close_button := SKETCH_UI_SCRIPT.make_button(
		"CLOSE DRAFTED DECK",
		Vector2(0, 68),
		true,
		22,
		false
	)
	close_button.name = "CloseDraftedCardsButton"
	_connect_pressed(close_button, _close_drafted_cards_menu)
	menu.add_child(close_button)


func _close_drafted_cards_menu() -> void:
	var overlay := find_child("DraftedCardsMenu", true, false)
	if overlay != null:
		overlay.queue_free()


func _set_drafted_cards_sort_mode(sort_mode: String) -> void:
	if sort_mode not in [DRAFT_SORT_NAME, DRAFT_SORT_TYPE, DRAFT_SORT_AFFINITY]:
		return
	draft_menu_sort_mode = sort_mode
	var overlay := find_child("DraftedCardsMenu", true, false)
	if overlay != null:
		overlay.name = "DraftedCardsMenuClosing"
		overlay.queue_free()
	call_deferred("_show_drafted_cards_menu")


func _finish_draft() -> void:
	if _draft_total() != DRAFT_DECK_SIZE:
		return
	var metrics := _calculate_deck_metrics(draft_deck, {})
	var primary := String(metrics.get("primary", ARCHETYPE_ORDER[0]))
	if not archetypes_by_id.has(primary):
		primary = String(ARCHETYPE_ORDER[0])
	var completed_deck := draft_deck.duplicate(true)
	run = run_state_service.create_run(primary, completed_deck, _predator_archetype(primary), "season", draft_difficulty_id)
	run["drafted"] = true
	run["draft_picks"] = draft_picks.duplicate()
	_generate_shop_inventory()
	_show_shop()
	_set_footer("Draft complete: your 20-card deck and drafted collection are ready.")


func _shift_season_setup_archetype(delta: int) -> void:
	season_setup_archetype_index = posmod(season_setup_archetype_index + delta, DEMO_STARTER_ORDER.size())
	_show_season_run_setup()


func _select_season_setup_archetype(index: int) -> void:
	season_setup_archetype_index = clampi(index, 0, DEMO_STARTER_ORDER.size() - 1)
	season_setup_difficulty_open = true
	var setup := find_child("SeasonRegistration", true, false) as SeasonSetupMenu
	if setup != null and setup.selected_index != season_setup_archetype_index:
		setup.select_starter(season_setup_archetype_index)


func _close_season_setup_difficulty() -> void:
	season_setup_difficulty_open = false
	var setup := find_child("SeasonRegistration", true, false) as SeasonSetupMenu
	if setup != null and setup.selected_index >= 0:
		setup._collapse_selection()


func _shift_season_setup_difficulty(delta: int) -> void:
	season_setup_difficulty_index = posmod(season_setup_difficulty_index + delta, DIFFICULTY_ORDER.size())
	_show_season_run_setup()


func _confirm_season_run_setup() -> void:
	var selected_starter_id := String(DEMO_STARTER_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	if selected_starter_id == DRAFT_NIGHT_ID:
		_begin_draft(selected_difficulty_id)
		return
	_start_new_run_with_mode(selected_starter_id, "season", selected_difficulty_id)


func _start_new_run(archetype_id: String) -> void:
	if not _development_tools_enabled():
		_start_new_run_with_mode(archetype_id, "season", "white")
		return
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id), "unselected", "white")
	run.run_mode = "unselected"

	_generate_shop_inventory()
	_set_footer("Starter chosen. Choose a play route.")
	_show_run_path_choice()


func _start_new_run_with_mode(archetype_id: String, mode: String, difficulty_id: String = "white") -> void:
	if mode == "debug" and not _development_tools_enabled():
		mode = "season"
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id), mode, difficulty_id)
	match mode:
		"season":
			route_run_service.initialize_run(run, rng.randi())
			_generate_shop_inventory()
			_set_footer("Your %s run begins in Starter City." % _starter_label(archetype_id))
			_show_run_map()
			_autosave_now("route_map")
		_:
			_generate_shop_inventory()
			_set_footer("Debug Sandbox started with " + _starter_label(archetype_id) + ".")
			_show_shop()


func _show_run_path_choice() -> void:
	if run.is_empty():
		_show_start()
		return
	current_screen = "path_choice"
	_render_nav()
	_clear(content)
	_update_status()

	var starter_id := String(run.get("starter", ""))
	var starter_name := _starter_label(starter_id)
	var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))

	var intro := _add_panel(content, "Choose Your Path", "#222936")
	_add_body_text(intro, "Starter: %s | Money: $%d | Main deck: %d cards | Minimum %d • No maximum" % [
		starter_name,
		int(run.get("money", 0)),
		_deck_total(run.get("deck", {})),
		MIN_MAIN_DECK_SIZE
	])
	_add_body_text(intro, _format_metrics_short(metrics))

	var options := HBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 10)
	content.add_child(options)

	var season_panel := _add_panel(options, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(season_panel, "Build, trade, and compete your way through the season.")
	var season_button := _make_button("Start Season Run")
	_connect_pressed(season_button, func() -> void: _choose_run_path("season"))
	season_panel.add_child(season_button)

	if _development_tools_enabled():
		var debug_panel := _add_panel(options, "Debug Sandbox", "#2b2f44")
		debug_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_body_text(debug_panel, "Jump to any system for development and testing.")
		var debug_button := _make_button("Open Debug Menu")
		_connect_pressed(debug_button, func() -> void: _choose_run_path("debug"))
		debug_panel.add_child(debug_button)


func _choose_run_path(mode: String) -> void:
	if run.is_empty():
		_show_start()
		return
	if mode == "debug" and not _development_tools_enabled():
		mode = "season"
	run.run_mode = mode
	match mode:
		"season":
			_set_footer("Season Run selected. Follow the weekly loop: shop, tune, enter the event, survive.")
			_show_season_run()
		_:
			_set_footer("Debug Sandbox selected. All season and Kitchen Match tools are available.")
			_show_shop()


func _deck_entries_to_dict(entries: Array) -> Dictionary:
	return content_catalog.deck_entries_to_dict(entries)


func _render_nav() -> void:
	_clear(nav)
	_apply_screen_chrome()
	if run.is_empty():
		return

	var mode := _run_mode()
	if mode == "unselected":
		_add_nav_button("Choose Path", _show_run_path_choice)
		var unselected_spacer := Control.new()
		unselected_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(unselected_spacer)
		_add_nav_button("Save", _save_run)
		_add_nav_button("Load", _load_run_from_disk)
		_add_nav_button("New Run", _show_start)
		return

	if mode == "season":
		# The public demo is navigated from clickable objects in the 3D store.
		# Keeping this strip empty guarantees that every required route is mouse-led
		# and returns through an explicit Exit button.
		return
	if not _development_tools_enabled():
		return

	_add_nav_button("Shop", _show_shop)
	_add_nav_button("Scene Shop", _show_card_shop_scene_test)
	_add_nav_button("Packs", _show_packs)
	_add_nav_button("Deckbuilder", _show_deckbuilder)
	_add_nav_button("Living Table Match", _start_debug_kitchen_match)
	_add_nav_button("Camera Demo", _show_greybox_camera_demo)
	_add_nav_button("Card Lab", _show_card_effect_lab)
	_add_nav_button("Tournament", _show_tournament)
	_add_nav_button("Metagame", _show_meta)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)

	_add_nav_button("Save", _save_run)
	_add_nav_button("Load", _load_run_from_disk)
	_add_nav_button("New Run", _show_start)


func _run_mode() -> String:
	if run.is_empty():
		return "debug" if _development_tools_enabled() else "season"
	var mode := String(run.get("run_mode", "season"))
	if mode == "debug" and not _development_tools_enabled():
		return "season"
	return mode


func _run_difficulty_id() -> String:
	if run.is_empty():
		return "white"
	return String(run.get("difficulty", "white"))


func _difficulty_data(difficulty_id: String) -> Dictionary:
	match difficulty_id:
		"blue":
			return {
				"id": "blue",
				"name": "Blue",
				"accent": "#20334a",
				"border_color": "#6aa8ff",
				"summary": "Rivals upgrade their decks and decisions earlier.",
				"rules_text": "Blue modifier: rivals get a quality bump, swap weak starter cards sooner, and advance one AI skill tier earlier."
			}
		"yellow":
			return {
				"id": "yellow",
				"name": "Yellow",
				"accent": "#44391e",
				"border_color": "#f0c94a",
				"summary": "Blue rules plus a tighter starting budget.",
				"rules_text": "Includes Blue. Yellow modifier: you start with less money, so every pack and single matters more."
			}
		"silver":
			return {
				"id": "silver",
				"name": "Silver",
				"accent": "#30343a",
				"border_color": "#cfd6df",
				"summary": "Blue and Yellow rules, tougher decks, and only one life.",
				"rules_text": "Includes Blue + Yellow. Silver modifier: rivals gain another deck-quality bump and you have only one season life."
			}
		"gold":
			return {
				"id": "gold",
				"name": "Gold",
				"accent": "#42351c",
				"border_color": "#e2b84c",
				"summary": "Every previous modifier plus uncertain turn order.",
				"rules_text": "Includes Blue + Yellow + Silver. Gold modifier: each tournament round may change which chef takes the opening turn."
			}
		_:
			return {
				"id": "white",
				"name": "Black",
				"accent": "#171717",
				"border_color": "#090909",
				"summary": "Base season rules.",
				"rules_text": "Normal money, normal lives, starter-level opponents, and you begin each match."
			}


func _apply_screen_chrome() -> void:
	if footer_label == null:
		return
	if current_screen not in ["route_remove", "route_upgrade"] and is_instance_valid(route_shop_service_overlay):
		_clear_route_shop_service_overlay()
	if title_label != null:
		title_label.add_theme_color_override("font_color", PALETTE.NAVY if _uses_workspace_interface() or current_screen == "result" else UI_THEME_SCRIPT.INK)
	if status_label != null:
		status_label.add_theme_color_override("font_color", PALETTE.NAVY_MUTED if _uses_workspace_interface() or current_screen == "result" else UI_THEME_SCRIPT.TEAL_DEEP)
	theme = (
		workspace_ui_theme
		if _uses_workspace_interface()
		else sketch_ui_theme
		if _uses_sketch_interface()
		else base_ui_theme
	)
	var compact_duel := current_screen in ["kitchen_match", "tutorial"]
	var compact_deck := current_screen == "deck" and _run_mode() == "season"
	var title_flow := current_screen in ["start", "season_setup"]
	var store_chrome := current_screen == "shop" and _run_mode() == "season"
	var season_menu := current_screen == "season"
	var pack_screen := current_screen == "packs"
	var finale_screen := current_screen == "thanks"
	var route_map_screen := current_screen == "route_map"
	var route_encounter_screen := current_screen in [
		"route_encounter_intro", "route_shop", "route_remove", "route_upgrade",
		"route_event", "route_game_over", "route_victory",
	]
	var route_presentation_screen := route_encounter_screen or current_screen in ["route_reward_reveal", "route_reward_pack", "route_reward"]
	var full_frame_screen := current_screen in ["deck", "settings"]
	var immersive_screen := pack_screen or finale_screen or route_map_screen or route_encounter_screen
	var hide_footer := title_flow or compact_duel or compact_deck or full_frame_screen or season_menu or immersive_screen or route_presentation_screen or current_screen == "draft" or (current_screen == "shop" and _run_mode() == "season")
	var shell_background := get_node_or_null("PaperBackground") as ColorRect
	var pastel_workspace_background := get_node_or_null("PastelWorkspaceBackground") as ColorRect
	var route_presentation_background := get_node_or_null("RoutePresentationBackground") as ColorRect
	var pastel_workspace_screens := [
		"new_game", "settings", "draft", "path_choice", "season", "singles",
		"trading", "deck", "tournament", "result", "thanks", "meta", "card_lab",
	]
	var use_pastel_workspace := current_screen in pastel_workspace_screens
	if shell_background != null:
		shell_background.visible = not use_pastel_workspace and not route_encounter_screen
	if pastel_workspace_background != null:
		pastel_workspace_background.visible = use_pastel_workspace
	if route_presentation_background != null:
		route_presentation_background.visible = route_encounter_screen
	if header_bar != null:
		header_bar.visible = not compact_duel and not full_frame_screen and not title_flow and not store_chrome and not season_menu and not immersive_screen and not route_presentation_screen
	if nav != null:
		nav.visible = not compact_duel and not full_frame_screen and not title_flow and not store_chrome and not immersive_screen and not route_presentation_screen
	footer_label.visible = not hide_footer
	footer_label.custom_minimum_size = Vector2(0, 0 if hide_footer else 78)
	var compact_margin := compact_duel or compact_deck
	var immersive_margin := 0 if pack_screen else 12
	root_margin.add_theme_constant_override("margin_left", 0 if compact_duel or full_frame_screen else (immersive_margin if immersive_screen else (6 if compact_margin else (0 if store_chrome else (12 if season_menu else (0 if title_flow else 18))))))
	root_margin.add_theme_constant_override("margin_right", 0 if compact_duel or full_frame_screen else (immersive_margin if immersive_screen else (6 if compact_margin else (0 if store_chrome else (12 if season_menu else (0 if title_flow else 18))))))
	root_margin.add_theme_constant_override("margin_top", 0 if compact_duel or full_frame_screen else (immersive_margin if immersive_screen else (4 if compact_margin else (0 if store_chrome else (12 if season_menu else (0 if title_flow else 14))))))
	root_margin.add_theme_constant_override("margin_bottom", 0 if compact_duel or full_frame_screen else (immersive_margin if immersive_screen else (4 if compact_margin else (0 if store_chrome else (12 if season_menu else (0 if title_flow else 14))))))
	shell.add_theme_constant_override("separation", 0 if pack_screen or full_frame_screen else (3 if compact_margin else (0 if title_flow or store_chrome else 10)))
	content.add_theme_constant_override("separation", 0 if full_frame_screen or title_flow else (4 if compact_margin else 10))
	if scroll != null:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck or title_flow or pack_screen else ScrollContainer.SCROLL_MODE_AUTO
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck or title_flow or pack_screen or season_menu else ScrollContainer.SCROLL_MODE_AUTO


func _uses_sketch_interface() -> bool:
	return current_screen in [
		"start",
		"season_setup",
		"season",
		"shop",
		"singles",
		"trading",
		"packs",
		"deck",
		"tournament",
			"result",
			"thanks",
			"meta",
		]


func _uses_workspace_interface() -> bool:
	return current_screen in ["deck", "singles", "draft", "settings"]


func _add_nav_button(label: String, callback: Callable) -> void:
	var button := _make_button(label)
	_connect_pressed(button, callback)
	nav.add_child(button)


func _normalize_season_calendar_state() -> void:
	season_flow_service.normalize_calendar_state(run)


func _season_calendar_ids() -> Array:
	return season_flow_service.calendar_ids(run)


func _season_event_index(event_id: String) -> int:
	return season_flow_service.event_index(run, event_id)


func _season_event_by_id(event_id: String) -> Dictionary:
	return season_flow_service.event_by_id(event_id)


func _first_selectable_season_event_id() -> String:
	return season_flow_service.first_selectable_event_id(run)


func _selected_season_event_id() -> String:
	return season_flow_service.selected_event_id(run)


func _selected_season_event() -> Dictionary:
	return season_flow_service.selected_event(run)


func _selected_tournament_event() -> Dictionary:
	if _run_mode() == "season":
		return _selected_season_event()
	return _season_event_by_id("weekly_locals")


func _season_event_completed(event_id: String) -> bool:
	return season_flow_service.event_completed(run, event_id)


func _season_event_unlocked(event_id: String) -> bool:
	return season_flow_service.event_unlocked(run, event_id)


func _season_event_selectable(event_id: String) -> bool:
	return season_flow_service.event_selectable(run, event_id, _season_tournament_active())


func _select_season_event(event_id: String) -> void:
	if _season_tournament_active():
		_set_footer("Finish the active tournament before choosing another event.")
		return
	if _season_event_completed(event_id):
		_set_footer("%s is already cleared." % String(_season_event_by_id(event_id).get("name", event_id)))
		return
	if not _season_event_unlocked(event_id):
		_set_footer("Clear the earlier calendar events before registering for %s." % String(_season_event_by_id(event_id).get("name", event_id)))
		return
	run.selected_event_id = event_id
	_set_footer("Preparing for %s. Buy packs, check singles, tune your deck, then register." % String(_season_event_by_id(event_id).get("name", event_id)))
	_show_shop()


func _season_completed_count() -> int:
	return season_flow_service.completed_count(run)


func _season_event_is_final(event_id: String) -> bool:
	return season_flow_service.event_is_final(run, event_id)


func _season_mark_event_completed(event_id: String) -> void:
	season_flow_service.mark_event_completed(run, event_id)


func _set_calendar_prep_notice(event_id: String) -> void:
	season_flow_service.set_prep_notice(run, event_id)


func _show_run_map(resolve_pending: bool = true) -> void:
	if _guard_run_over():
		return
	_clear_route_reward_overlay()
	_clear_route_encounter_overlay()
	route_encounter_transitioning = false
	if resolve_pending and not run.get("pending_route_node", {}).is_empty():
		_resolve_pending_route_node()
		return
	current_screen = "route_map"
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Choose one connected destination. You cannot return to earlier stops.")

	var hud := TOPDECK_UI_SCRIPT.make_hud_bar("Route Navigation", "Starter City")
	var run_panel := hud.panel as PanelContainer
	run_panel.name = "RouteRunBar"
	(hud.surface as Node).name = "RouteRunBarSurface"
	content.add_child(run_panel)
	var route_identity := hud.identity as VBoxContainer
	(route_identity.get_child(0) as Label).name = "RouteHudEyebrow"
	(route_identity.get_child(1) as Label).name = "RouteLocationLabel"
	var stats := hud.stats as HBoxContainer
	stats.name = "RouteHudStats"
	var run_bar := hud.row as HBoxContainer
	var life := int(run.get("life", 0))
	var max_life := maxi(1, int(run.get("max_life", 40)))
	stats.add_child(_route_hud_chip(
		"LIFE  %d / %d" % [life, max_life],
		PALETTE.SIGNAL_RED if float(life) / float(max_life) <= 0.5 else PALETTE.EMERALD,
		"RouteLifeChip"
	))
	stats.add_child(_route_hud_chip(
		"FUNDS  $%d" % int(run.get("money", 0)), PALETTE.SIGNAL_YELLOW, "RouteFundsChip"
	))
	stats.add_child(_route_hud_chip(
		"DECK  %d" % _deck_total(run.get("deck", {})), PALETTE.INTERFACE_VIOLET, "RouteDeckChip"
	))

	var deck_button := TOPDECK_UI_SCRIPT.make_button("VIEW DECK", "secondary", Vector2(142, 46), "RouteViewDeckButton")
	MATERIAL_SYMBOLS.apply_to_button(deck_button, "cards", 20)
	deck_button.disabled = not resolve_pending
	_connect_pressed(deck_button, _show_deckbuilder)
	run_bar.add_child(deck_button)
	var save_button := TOPDECK_UI_SCRIPT.make_button("SAVE", "primary", Vector2(112, 46), "RouteSaveButton")
	MATERIAL_SYMBOLS.apply_to_button(save_button, "save", 20)
	save_button.disabled = not resolve_pending
	_connect_pressed(save_button, _save_run)
	run_bar.add_child(save_button)
	var settings_button := TOPDECK_UI_SCRIPT.make_button("SETTINGS", "secondary", Vector2(126, 46), "RouteSettingsButton")
	MATERIAL_SYMBOLS.apply_to_button(settings_button, "settings", 20)
	settings_button.disabled = not resolve_pending
	_connect_pressed(settings_button, _show_settings)
	run_bar.add_child(settings_button)

	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "StarterCityMap"
	viewport_container.custom_minimum_size = Vector2(1120, 680)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	content.add_child(viewport_container)
	var map_viewport := SubViewport.new()
	map_viewport.name = "StarterCityViewport"
	map_viewport.size = Vector2i(1280, 720)
	map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(map_viewport)
	var stage := _instantiate_scene(OVERWORLD_SCENE_PATH)
	stage.name = "StarterCityOverworld"
	var graph := stage.get_node("RouteGraph")
	var map_player := stage.get_node_or_null("Player")
	if map_player != null and map_player.has_method("configure_character"):
		map_player.call("configure_character", String(run.get("starter", "spicy")))
	var graph_state: Dictionary = run.get("route_graph", {}).duplicate(true)
	graph_state.seed = int(run.get("route_seed", 1))
	graph_state.current = String(run.get("route_current", "start"))
	graph_state.visited = run.get("route_visited", ["start"]).duplicate()
	graph.call("configure", graph_state)
	graph.connect("route_ready", _on_route_map_ready)
	graph.connect("node_reached", _on_route_node_reached.bind(graph))
	if stage.has_signal("starter_shop_requested"):
		stage.connect("starter_shop_requested", _on_town_start_shop_requested)
	map_viewport.add_child(stage)
	if not resolve_pending:
		graph.call("set_choices_locked", true)
	_play_card_shop_music()


func _route_hud_chip(text: String, accent: Color, chip_name: String) -> Label:
	return TOPDECK_UI_SCRIPT.make_stat_chip(text, accent, chip_name)


func _on_route_map_ready(snapshot: Dictionary) -> void:
	run.route_graph = snapshot.duplicate(true)


func _on_route_node_reached(node_id: String, graph: Node) -> void:
	var node: Dictionary = graph.call("node_data", node_id)
	node["id"] = node_id
	run.route_current = node_id
	run.route_visited = graph.visited.duplicate()
	run.route_graph = graph.call("snapshot")
	run.pending_route_node = node
	graph.call("set_choices_locked", true)
	_autosave_now("route_map")
	call_deferred("_resolve_pending_route_node")


func _on_town_start_shop_requested() -> void:
	var shop_state := run.get("town_start_shop", {}) as Dictionary
	if shop_state.is_empty():
		shop_state = {
			"id": "starter_shop",
			"type": "shop",
			"label": "Neighborhood Card Shop",
			"town_optional_shop": true,
		}
	else:
		shop_state = shop_state.duplicate(true)
		shop_state.town_optional_shop = true
	run.pending_route_node = shop_state
	_autosave_now("route_map")
	_show_route_shop()


func _resolve_pending_route_node() -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	if node.is_empty():
		_show_run_map()
		return
	match String(node.get("type", "enemy")):
		"enemy", "mini_boss", "final_boss":
			if not run.get("reward_offer", []).is_empty():
				if bool(run.get("route_pack_opened", false)) or bool(run.get("route_reward_intro_seen", false)):
					_show_route_card_reward()
				elif bool(run.get("route_pack_presented", false)):
					_show_route_sealed_pack()
				else:
					_show_route_reward_reveal()
			elif bool(run.get("route_battle", {}).get("active", false)):
				_start_route_battle(true)
			else:
				_start_route_battle()
		"shop":
			_show_route_shop()
		"event":
			if bool(node.get("event_resolved", false)):
				_complete_route_node()
			else:
				_show_route_event()
		_:
			_complete_route_node()


func _start_route_battle(resume_saved: bool = false) -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	if node.is_empty():
		_show_run_map()
		return
	var node_type := String(node.get("type", "enemy"))
	var node_id := String(node.get("id", "route"))
	var battle: Dictionary = run.get("route_battle", {})
	if not resume_saved or battle.is_empty():
		var encounter_seed := int(run.get("route_seed", 1)) ^ hash(node_id)
		var affinity_index := posmod(encounter_seed, ARCHETYPE_ORDER.size())
		var has_town_affinity := node.has("npc_archetype")
		var opponent_affinity := String(node.get("npc_archetype", ARCHETYPE_ORDER[affinity_index]))
		if opponent_affinity not in ARCHETYPE_ORDER:
			opponent_affinity = String(ARCHETYPE_ORDER[affinity_index])
		if not has_town_affinity and opponent_affinity == String(run.get("starter", "")):
			opponent_affinity = _predator_archetype(opponent_affinity)
		var rival_name := String(node.get("label", "League Player"))
		if node_type == "mini_boss":
			rival_name = "Local Champion Mina"
		elif node_type == "final_boss":
			rival_name = "Starter City Champion Tess"
		battle = {
			"active": true,
			"node_id": node_id,
			"node_type": node_type,
			"label": rival_name,
			"seed": encounter_seed,
			"rival_portrait_id": String(node.get(
				"npc_portrait_id", _route_rival_portrait_id(node_type, encounter_seed)
			)),
			"npc_personality": String(node.get("npc_personality", "competitive")),
			"opponent_affinity": opponent_affinity,
			"opponent_life": route_run_service.encounter_life(node_type),
			"ai": route_run_service.encounter_ai(node_type),
			"intro_seen": false,
			"location": ["Park Table", "Sidewalk Table", "Waterfront Table"][posmod(encounter_seed, 3)],
		}
		run.route_battle = battle
	elif not battle.has("rival_portrait_id"):
		battle.rival_portrait_id = _route_rival_portrait_id(
			String(battle.get("node_type", node_type)),
			int(battle.get("seed", int(run.get("route_seed", 1)) ^ hash(node_id)))
		)
		run.route_battle = battle
	if not bool(battle.get("intro_seen", false)):
		_autosave_now("route_encounter_intro")
		_show_route_encounter_intro()
		return
	var ai := String(battle.get("ai", "medium"))
	var rival_deck := _opponent_deck_for_round(String(battle.opponent_affinity), 1, {}, ai)
	var resume_snapshot: Dictionary = run.get("kitchen_match", {}).get("snapshot", {}).duplicate(true) if resume_saved else {}
	_begin_kitchen_match(
		run.deck,
		rival_deck,
		String(battle.label),
		false,
		int(battle.seed),
		"player",
		ai,
		resume_snapshot,
		{
			"player_life": int(run.get("life", 40)),
			"player_max_life": int(run.get("max_life", 40)),
			"opponent_life": int(battle.opponent_life),
			"opponent_max_life": int(battle.opponent_life),
			"turn_hand_floor": 3,
			"reshuffle_pressure": true,
			"reshuffle_damage": [3, 5, 7],
		}
	)


func _show_route_encounter_intro() -> void:
	if find_child("StarterCityMap", true, false) == null:
		_show_run_map(false)
	current_screen = "route_encounter_intro"
	_apply_screen_chrome()
	_render_nav()
	_update_status()
	var battle: Dictionary = run.get("route_battle", {})
	if battle.is_empty():
		_show_run_map()
		return
	_clear_route_encounter_overlay()
	var affinity := String(battle.get("opponent_affinity", "neutral"))
	var node_type := String(battle.get("node_type", "enemy"))
	var portrait_id := String(battle.get(
		"rival_portrait_id",
		_route_rival_portrait_id(node_type, int(battle.get("seed", 0)))
	))
	battle.rival_portrait_id = portrait_id
	run.route_battle = battle
	route_encounter_overlay = ROUTE_RIVAL_INTRO_SCRIPT.new()
	add_child(route_encounter_overlay)
	route_encounter_overlay.call(
		"configure",
		_route_rival_portrait(portrait_id),
		String(battle.get("label", "Starter City Rival")),
		_route_rival_intro_line(affinity, node_type, portrait_id),
		_route_rival_intro_accent(node_type),
		_reduced_motion_enabled(),
		_running_automated_test()
	)
	route_encounter_overlay.connect("continue_requested", _begin_route_battle_from_intro)


func _route_rival_intro_line(affinity: String, node_type: String = "enemy", portrait_id: String = "npc1") -> String:
	if node_type == "final_boss":
		return "One last table stands between you and the road ahead. Show me your best game."
	if node_type == "mini_boss":
		return "Every choice brought you to this table. Let’s see how well your deck holds together."
	if portrait_id == "npc1":
		match affinity:
			"spicy":
				return "I’ve been waiting for a fast match. Show me if you can keep the pressure on."
			"hearty":
				return "I brought a deck that can take a hit. You’ll have to earn every opening."
			"sweet":
				return "I’ve got a few surprises sleeved up. Let’s make this a good one."
			"fresh":
				return "The table never stays the same for long. Keep up with me."
			_:
				return "I’ve been tuning this list all week. Show me what your deck can do."
	match affinity:
		"spicy":
			return "I only need one opening. Choose your blocks carefully."
		"hearty":
			return "Rushing won’t be enough. I planned for the long game."
		"sweet":
			return "Every card has a place in my plan. Let’s see where yours fit."
		"fresh":
			return "A good plan survives a changing table. Does yours?"
		_:
			return "I studied the route you took here. Now show me the deck it built."


func _route_rival_portrait_id(node_type: String, encounter_seed: int) -> String:
	if node_type == "mini_boss":
		return "npc2"
	if node_type == "final_boss":
		return "npc1"
	return "npc1" if posmod(encounter_seed, 2) == 0 else "npc2"


func _route_rival_portrait(portrait_id: String) -> Texture2D:
	return ROUTE_RIVAL_PORTRAITS.get(portrait_id, ROUTE_RIVAL_PORTRAITS.npc1) as Texture2D


func _route_rival_intro_accent(node_type: String) -> Color:
	match node_type:
		"mini_boss":
			return PALETTE.INTERFACE_VIOLET
		"final_boss":
			return PALETTE.SIGNAL_YELLOW
		_:
			return PALETTE.ELECTRIC_CYAN


func _route_node_icon(node_type: String) -> Texture2D:
	return ROUTE_NODE_ICONS.get(node_type, ROUTE_NODE_ICONS.enemy) as Texture2D


func _route_run_stats_text() -> String:
	return "LIFE %d/%d  •  FUNDS $%d  •  DECK %d" % [
		int(run.get("life", 0)),
		int(run.get("max_life", 40)),
		int(run.get("money", 0)),
		_deck_total(run.get("deck", {})),
	]


func _begin_route_battle_from_intro() -> void:
	if route_encounter_transitioning:
		return
	var battle: Dictionary = run.get("route_battle", {})
	if battle.is_empty():
		_clear_route_encounter_overlay()
		_show_run_map()
		return
	route_encounter_transitioning = true
	battle.intro_seen = true
	run.route_battle = battle
	_autosave_now("kitchen_match")
	var intro_overlay := route_encounter_overlay
	if (
		is_instance_valid(intro_overlay)
		and not _reduced_motion_enabled()
		and not _running_automated_test()
	):
		await intro_overlay.call("wipe_to_cover")
		if not is_instance_valid(intro_overlay):
			route_encounter_transitioning = false
			return
		_start_route_battle(true)
		await get_tree().process_frame
		if is_instance_valid(intro_overlay):
			await intro_overlay.call("reveal_after_cover")
		if is_instance_valid(intro_overlay):
			intro_overlay.queue_free()
		route_encounter_overlay = null
		route_encounter_transitioning = false
		return
	_clear_route_encounter_overlay()
	_start_route_battle(true)
	route_encounter_transitioning = false


func _clear_route_encounter_overlay() -> void:
	if is_instance_valid(route_encounter_overlay):
		route_encounter_overlay.queue_free()
	route_encounter_overlay = null


func _finish_route_battle(won: bool, remaining_life: int) -> void:
	var battle: Dictionary = run.get("route_battle", {})
	if battle.is_empty():
		return
	battle.active = false
	run.route_battle = battle
	run.life = maxi(0, remaining_life)
	if not won:
		run.run_over = true
		run.last_result = ["Your Starter City run ended at %s." % String(battle.get("label", "a rival"))]
		_autosave_now("route_game_over")
		_show_route_game_over()
		return
	var node_type := String(battle.get("node_type", "enemy"))
	var cash_reward := 8 if node_type == "final_boss" else 5 if node_type == "mini_boss" else 2
	run.reward_offer = route_run_service.generate_reward_offer(
		String(run.get("starter", "spicy")), node_type, int(battle.get("seed", 1)) + 97
	)
	run.reward_picks_remaining = route_run_service.reward_pick_count(node_type)
	run.reward_selected = []
	run.route_reward_cash = cash_reward
	run.route_reward_cash_awarded = false
	run.route_reward_intro_seen = false
	run.route_pack_presented = false
	run.route_pack_opened = false
	selected_route_reward_card_id = ""
	_clear_kitchen_match_state()
	_autosave_now("route_reward_reveal")
	_show_route_post_battle_map()


func _show_route_post_battle_map() -> void:
	_show_run_map(false)
	current_screen = "route_reward_reveal"
	call_deferred("_play_route_post_battle_sequence")


func _play_route_post_battle_sequence() -> void:
	await get_tree().process_frame
	if current_screen != "route_reward_reveal" or run.get("reward_offer", []).is_empty():
		return
	var map_player := find_child("Player", true, false)
	if map_player != null and map_player.has_method("celebrate"):
		map_player.call("celebrate", 0.65)
	if not _reduced_motion_enabled() and not _running_automated_test():
		await get_tree().create_timer(0.68).timeout
	if current_screen != "route_reward_reveal":
		return
	var cash_reward := int(run.get("route_reward_cash", 0))
	if not bool(run.get("route_reward_cash_awarded", false)):
		var starting_money := int(run.get("money", 0))
		run.money = starting_money + cash_reward
		run.route_reward_cash_awarded = true
		await _animate_route_funds_gain(starting_money, int(run.money), cash_reward)
	run.route_pack_presented = true
	_autosave_now("route_reward_pack")
	_show_route_sealed_pack()


func _animate_route_funds_gain(starting_money: int, ending_money: int, cash_reward: int) -> void:
	var funds_chip := find_child("RouteFundsChip", true, false) as Label
	if funds_chip == null:
		return
	var gain := Label.new()
	gain.name = "RouteFundsGain"
	gain.text = "+$%d" % cash_reward
	gain.add_theme_font_size_override("font_size", 22)
	gain.add_theme_color_override("font_color", PALETTE.SIGNAL_YELLOW)
	gain.add_theme_color_override("font_outline_color", PALETTE.CARBON)
	gain.add_theme_constant_override("outline_size", 5)
	gain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gain.position = funds_chip.global_position + Vector2(funds_chip.size.x * 0.5 - 24.0, -16.0)
	gain.z_index = 850
	add_child(gain)
	if _reduced_motion_enabled() or _running_automated_test():
		funds_chip.text = "FUNDS  $%d" % ending_money
		gain.queue_free()
		return
	funds_chip.pivot_offset = funds_chip.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(value: float) -> void:
		funds_chip.text = "FUNDS  $%d" % roundi(lerpf(float(starting_money), float(ending_money), value)),
		0.0, 1.0, 0.7
	)
	tween.tween_property(funds_chip, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(gain, "position:y", gain.position.y - 42.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gain, "modulate:a", 0.0, 0.3).set_delay(0.42)
	await tween.finished
	funds_chip.scale = Vector2.ONE
	funds_chip.text = "FUNDS  $%d" % ending_money
	gain.queue_free()


func _show_route_reward_reveal() -> void:
	_show_route_post_battle_map()


func _open_route_victory_pack() -> void:
	run.route_pack_presented = true
	run.route_pack_opened = false
	_autosave_now("route_reward_pack")
	_show_route_sealed_pack()


func _show_route_sealed_pack() -> void:
	if find_child("StarterCityMap", true, false) == null:
		_show_run_map(false)
	current_screen = "route_reward_pack"
	_update_status()
	var reward_host := _route_reward_overlay_host()
	var panel_parts := TOPDECK_UI_SCRIPT.make_surface_panel(
		"RouteSealedPackScreen",
		PALETTE.SURFACE_RAISED,
		PALETTE.STATE_REWARD,
		Vector2(0, 520),
		Vector4(20, 20, 20, 20),
		true
	)
	var panel := panel_parts.panel as PanelContainer
	panel.name = "RouteSealedPackScreen"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_host.add_child(panel)
	(panel_parts.surface as Node).name = "RouteSealedPackAngularSurface"
	var pack_center := CenterContainer.new()
	pack_center.custom_minimum_size = Vector2(0, 520)
	pack_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(panel_parts.body as VBoxContainer).add_child(pack_center)
	var pack_stack := VBoxContainer.new()
	pack_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	pack_center.add_child(pack_stack)
	var pack_button := TextureButton.new()
	pack_button.name = "RouteSealedPackButton"
	pack_button.custom_minimum_size = Vector2(285, 390)
	pack_button.texture_normal = _route_reward_pack_art()
	pack_button.ignore_texture_size = true
	pack_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pack_button.tooltip_text = ""
	pack_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pack_button.pivot_offset = pack_button.custom_minimum_size * 0.5
	pack_button.pressed.connect(_crack_route_victory_pack, CONNECT_DEFERRED)
	pack_stack.add_child(pack_button)
	if not _reduced_motion_enabled():
		var float_tween := create_tween().set_loops(6)
		float_tween.tween_property(pack_button, "scale", Vector2(1.035, 1.035), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(pack_button, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _route_reward_pack_art() -> Texture2D:
	var node_type := String(run.get("pending_route_node", {}).get("type", "enemy"))
	return ROUTE_REWARD_PACK_ART_BY_NODE.get(node_type, ROUTE_REWARD_PACK_ART_BY_NODE.enemy) as Texture2D


func _crack_route_victory_pack() -> void:
	if bool(run.get("route_pack_opened", false)):
		return
	run.route_pack_presented = true
	run.route_pack_opened = true
	run.route_reward_intro_seen = true
	selected_route_reward_card_id = ""
	_play_route_pack_open_sound()
	_autosave_now("route_reward")
	_show_route_card_reward(true)


func _play_route_pack_open_sound() -> void:
	if _running_automated_test() or ROUTE_PACK_OPEN_SOUND_PATHS.is_empty():
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(String(ROUTE_PACK_OPEN_SOUND_PATHS[rng.randi_range(0, ROUTE_PACK_OPEN_SOUND_PATHS.size() - 1)])) as AudioStream
	player.bus = &"SFX"
	player.volume_db = -4.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _show_route_card_reward(animate_from_pack: bool = false) -> void:
	if find_child("StarterCityMap", true, false) == null:
		_show_run_map(false)
	current_screen = "route_reward"
	_update_status()
	var reward_host := _route_reward_overlay_host()
	var node_type := String(run.get("pending_route_node", {}).get("type", "enemy"))
	var picks := int(run.get("reward_picks_remaining", 1))
	var reward_instruction := "Click a card to lift it, then choose Add to Deck. Take any or all %d remaining card%s, or skip the rest." % [picks, "s" if picks != 1 else ""]
	var reward_stats := "Life %d/%d  •  Deck %d cards  •  Reward tier: %s" % [
		int(run.get("life", 0)), int(run.get("max_life", 40)), _deck_total(run.deck),
		"City Champion" if node_type == "final_boss" else "Local Champion" if node_type == "mini_boss" else "Regular Rival"
	]
	var header_parts := TOPDECK_UI_SCRIPT.make_reward_header(
		"Choose Your Cards", reward_instruction, reward_stats, PALETTE.FOCUS_EDGE
	)
	var header := header_parts.panel as PanelContainer
	header.name = "RouteCardRewardScreen"
	(header_parts.surface as Node).name = "RouteCardRewardHeaderAngularSurface"
	(header_parts.title as Label).name = "RouteCardRewardTitle"
	(header_parts.instruction as Label).name = "RouteCardRewardInstruction"
	(header_parts.stats as Label).name = "RouteCardRewardStats"
	reward_host.add_child(header)
	var offer_ids: Array[String] = []
	for card_id_value in run.get("reward_offer", []):
		var offered_id := String(card_id_value)
		if cards_by_id.has(offered_id):
			offer_ids.append(offered_id)
	if not offer_ids.has(selected_route_reward_card_id):
		selected_route_reward_card_id = ""
	var fan_center := CenterContainer.new()
	fan_center.name = "RouteRewardFanCenter"
	fan_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fan_height := 400.0 if offer_ids.size() <= 5 else 680.0
	fan_center.custom_minimum_size = Vector2(0, fan_height)
	reward_host.add_child(fan_center)
	var fan := Control.new()
	fan.name = "RouteRewardFan"
	fan.custom_minimum_size = Vector2(1160, fan_height)
	fan.size = fan.custom_minimum_size
	fan_center.add_child(fan)
	var card_size := Vector2(220, 310) if offer_ids.size() <= 3 else Vector2(180, 254) if offer_ids.size() <= 5 else Vector2(175, 247)
	var columns := offer_ids.size() if offer_ids.size() <= 5 else 4
	var gap_x := 64.0 if offer_ids.size() <= 3 else 42.0 if offer_ids.size() <= 5 else 54.0
	var row_step := card_size.y + 82.0
	for card_index in range(offer_ids.size()):
		var card_id := offer_ids[card_index]
		var row_index := int(card_index / columns)
		var column_index := card_index % columns
		var row_count := mini(columns, offer_ids.size() - row_index * columns)
		var row_width := card_size.x * row_count + gap_x * maxi(0, row_count - 1)
		var base_position := Vector2((1160.0 - row_width) * 0.5 + column_index * (card_size.x + gap_x), 10.0 + row_index * row_step)
		var choice := Control.new()
		choice.name = "RouteReward_%s" % card_id
		choice.custom_minimum_size = Vector2(card_size.x, card_size.y + 60.0)
		choice.size = choice.custom_minimum_size
		choice.position = base_position
		choice.pivot_offset = Vector2(card_size.x * 0.5, card_size.y * 0.5)
		choice.set_meta("base_position", base_position)
		choice.set_meta("card_id", card_id)
		var face := _make_card_face(cards_by_id[card_id], card_size, true)
		face.position = Vector2.ZERO
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice.add_child(face)
		var select_button := Button.new()
		select_button.name = "RouteRewardCardButton_%s" % card_id
		select_button.flat = true
		select_button.position = Vector2.ZERO
		select_button.size = card_size
		select_button.tooltip_text = "Select %s" % String(cards_by_id[card_id].get("name", "card"))
		select_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		select_button.pressed.connect(_select_route_reward_card.bind(card_id), CONNECT_DEFERRED)
		choice.add_child(select_button)
		var add_button := TOPDECK_UI_SCRIPT.make_button(
			"Add to Deck", "confirm", Vector2(card_size.x, 48), "RouteRewardAddButton_%s" % card_id
		)
		add_button.position = Vector2(0, card_size.y + 10.0)
		add_button.size = Vector2(card_size.x, 48)
		add_button.visible = selected_route_reward_card_id == card_id
		_connect_pressed(add_button, _pick_route_reward.bind(card_id))
		choice.add_child(add_button)
		if selected_route_reward_card_id == card_id:
			choice.position.y -= 24.0
			choice.scale = Vector2(1.025, 1.025)
		fan.add_child(choice)
	var actions := HBoxContainer.new()
	actions.name = "RouteRewardActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	reward_host.add_child(actions)
	var add_all := TOPDECK_UI_SCRIPT.make_button("Add All", "confirm", Vector2(210, 54), "RouteRewardAddAllButton")
	_connect_pressed(add_all, _add_all_route_rewards)
	actions.add_child(add_all)
	var skip := TOPDECK_UI_SCRIPT.make_button("Skip", "secondary", Vector2(210, 54), "RouteRewardSkipButton")
	_connect_pressed(skip, _finish_route_reward)
	actions.add_child(skip)
	if animate_from_pack:
		_animate_route_reward_cards_from_pack(fan)


func _select_route_reward_card(card_id: String) -> void:
	if not run.get("reward_offer", []).has(card_id):
		return
	selected_route_reward_card_id = card_id
	var fan := find_child("RouteRewardFan", true, false)
	if fan == null:
		return
	for choice_node in fan.get_children():
		if not choice_node is Control or not choice_node.has_meta("card_id"):
			continue
		var choice := choice_node as Control
		var choice_id := String(choice.get_meta("card_id", ""))
		var selected := choice_id == card_id
		var base_position: Vector2 = choice.get_meta("base_position", choice.position)
		var target_position := base_position + Vector2(0, -24.0 if selected else 0.0)
		var target_scale := Vector2(1.025, 1.025) if selected else Vector2.ONE
		var add_button := choice.get_node_or_null("RouteRewardAddButton_%s" % choice_id) as Button
		if add_button != null:
			add_button.visible = selected
		if _reduced_motion_enabled() or _running_automated_test():
			choice.position = target_position
			choice.scale = target_scale
		else:
			var tween := create_tween().set_parallel(true)
			tween.tween_property(choice, "position", target_position, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(choice, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_route_reward_cards_from_pack(fan: Control) -> void:
	if _reduced_motion_enabled() or _running_automated_test():
		return
	var pack_remnant := TextureRect.new()
	pack_remnant.name = "RouteOpenedPackArtwork"
	pack_remnant.texture = _route_reward_pack_art()
	pack_remnant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pack_remnant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pack_remnant.size = Vector2(165, 225)
	pack_remnant.position = Vector2((fan.size.x - pack_remnant.size.x) * 0.5, (fan.size.y - pack_remnant.size.y) * 0.5)
	pack_remnant.pivot_offset = pack_remnant.size * 0.5
	pack_remnant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fan.add_child(pack_remnant)
	fan.move_child(pack_remnant, 0)
	var pack_tween := create_tween().set_parallel(true)
	pack_tween.tween_property(pack_remnant, "scale", Vector2(1.3, 0.2), 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pack_tween.tween_property(pack_remnant, "modulate:a", 0.0, 0.34)
	pack_tween.finished.connect(pack_remnant.queue_free)
	var card_index := 0
	for choice_node in fan.get_children():
		if not choice_node is Control or not choice_node.has_meta("card_id"):
			continue
		var choice := choice_node as Control
		var final_position: Vector2 = choice.get_meta("base_position", choice.position)
		choice.position = Vector2((fan.size.x - choice.size.x) * 0.5, (fan.size.y - choice.size.y) * 0.5)
		choice.scale = Vector2(0.18, 0.18)
		choice.rotation = deg_to_rad(-12.0 + float(card_index % 5) * 6.0)
		choice.modulate.a = 0.0
		var card_tween := create_tween()
		card_tween.tween_interval(float(card_index) * 0.075)
		card_tween.set_parallel(true)
		card_tween.tween_property(choice, "position", final_position, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(choice, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(choice, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
		card_tween.tween_property(choice, "modulate:a", 1.0, 0.22)
		card_index += 1


func _pick_route_reward(card_id: String) -> void:
	if int(run.get("reward_picks_remaining", 0)) <= 0 or not run.get("reward_offer", []).has(card_id):
		return
	run.deck[card_id] = int(run.deck.get(card_id, 0)) + 1
	run.collection[card_id] = int(run.collection.get(card_id, 0)) + 1
	run.reward_offer.erase(card_id)
	run.reward_picks_remaining = int(run.reward_picks_remaining) - 1
	run.reward_selected.append(card_id)
	selected_route_reward_card_id = ""
	if int(run.reward_picks_remaining) <= 0:
		_finish_route_reward()
	else:
		_continue_route_reward_after_pick(card_id)


func _continue_route_reward_after_pick(card_id: String) -> void:
	# Keep the live map, dimmer, header, and reward fan in place. Rebuilding the
	# overlay here momentarily exposed the undimmed map and made every individual
	# pick feel like leaving and re-entering the reward screen.
	var fan := find_child("RouteRewardFan", true, false) as Control
	if fan == null:
		_show_route_card_reward()
		return
	var picked_choice := fan.get_node_or_null("RouteReward_%s" % card_id) as Control
	if picked_choice == null:
		_show_route_card_reward()
		return
	var active_overlay := find_child("RouteRewardOverlay", true, false) as Control
	if active_overlay != null:
		for button_node in active_overlay.find_children("*", "Button", true, false):
			(button_node as Button).disabled = true
	var add_button := picked_choice.get_node_or_null("RouteRewardAddButton_%s" % card_id) as Button
	if add_button != null:
		add_button.disabled = true
	var select_button := picked_choice.get_node_or_null("RouteRewardCardButton_%s" % card_id) as Button
	if select_button != null:
		select_button.disabled = true
	await _animate_card_added_to_deck(picked_choice, "reward_pack")
	if current_screen != "route_reward" or not is_instance_valid(fan):
		return
	if is_instance_valid(picked_choice):
		fan.remove_child(picked_choice)
		picked_choice.queue_free()
	_refresh_route_reward_copy()
	_recenter_route_reward_choices(fan)
	if is_instance_valid(active_overlay):
		for button_node in active_overlay.find_children("*", "Button", true, false):
			(button_node as Button).disabled = false


func _animate_card_added_to_deck(card_control: Control, context: String) -> void:
	last_card_add_effect_context = context
	if card_control == null:
		return
	card_control.set_meta("card_add_effect_context", context)
	if _reduced_motion_enabled() or _running_automated_test():
		return
	var collect_tween := create_tween().set_parallel(true)
	collect_tween.tween_property(card_control, "position:y", card_control.position.y - 46.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collect_tween.tween_property(card_control, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	collect_tween.tween_property(card_control, "modulate:a", 0.0, 0.18).set_delay(0.06)
	await collect_tween.finished


func _refresh_route_reward_copy() -> void:
	var picks := int(run.get("reward_picks_remaining", 0))
	var instruction := find_child("RouteCardRewardInstruction", true, false) as Label
	if instruction != null:
		instruction.text = "Click a card to lift it, then choose Add to Deck. Take any or all %d remaining card%s, or skip the rest." % [picks, "s" if picks != 1 else ""]
	var stats := find_child("RouteCardRewardStats", true, false) as Label
	if stats != null:
		var node_type := String(run.get("pending_route_node", {}).get("type", "enemy"))
		stats.text = "Life %d/%d  •  Deck %d cards  •  Reward tier: %s" % [
			int(run.get("life", 0)), int(run.get("max_life", 40)), _deck_total(run.deck),
			"City Champion" if node_type == "final_boss" else "Local Champion" if node_type == "mini_boss" else "Regular Rival"
		]


func _recenter_route_reward_choices(fan: Control) -> void:
	var choices: Array[Control] = []
	for choice_node in fan.get_children():
		if choice_node is Control and choice_node.has_meta("card_id"):
			choices.append(choice_node as Control)
	if choices.is_empty():
		return
	var card_size := Vector2(choices[0].size.x, choices[0].size.y - 60.0)
	var columns := choices.size() if choices.size() <= 5 else 4
	var gap_x := 64.0 if choices.size() <= 3 else 42.0 if choices.size() <= 5 else 54.0
	var row_step := card_size.y + 82.0
	for card_index in range(choices.size()):
		var choice := choices[card_index]
		var row_index := int(card_index / columns)
		var column_index := card_index % columns
		var row_count := mini(columns, choices.size() - row_index * columns)
		var row_width := card_size.x * row_count + gap_x * maxi(0, row_count - 1)
		var target_position := Vector2((fan.size.x - row_width) * 0.5 + column_index * (card_size.x + gap_x), 10.0 + row_index * row_step)
		choice.set_meta("base_position", target_position)
		if _reduced_motion_enabled() or _running_automated_test():
			choice.position = target_position
			choice.scale = Vector2.ONE
		else:
			var settle_tween := create_tween().set_parallel(true)
			settle_tween.tween_property(choice, "position", target_position, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			settle_tween.tween_property(choice, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _add_all_route_rewards() -> void:
	var offer_ids: Array[String] = []
	for card_id_value in run.get("reward_offer", []):
		var card_id := String(card_id_value)
		if cards_by_id.has(card_id):
			offer_ids.append(card_id)
	for card_id in offer_ids:
		run.deck[card_id] = int(run.deck.get(card_id, 0)) + 1
		run.collection[card_id] = int(run.collection.get(card_id, 0)) + 1
		run.reward_selected.append(card_id)
	run.reward_offer = []
	run.reward_picks_remaining = 0
	selected_route_reward_card_id = ""
	_finish_route_reward()


func _finish_route_reward() -> void:
	run.reward_offer = []
	run.reward_picks_remaining = 0
	run.route_reward_cash = 0
	run.route_reward_intro_seen = false
	run.route_pack_presented = false
	run.route_pack_opened = false
	run.route_reward_cash_awarded = false
	selected_route_reward_card_id = ""
	_complete_route_node()


func _route_reward_overlay_host() -> VBoxContainer:
	_clear_route_reward_overlay()
	route_reward_overlay = Control.new()
	route_reward_overlay.name = "RouteRewardOverlay"
	route_reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	route_reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	route_reward_overlay.z_index = 900
	add_child(route_reward_overlay)
	var dimmer := ColorRect.new()
	dimmer.name = "RouteRewardDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = PALETTE.OVERLAY_DIM
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	route_reward_overlay.add_child(dimmer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_bottom", 34)
	route_reward_overlay.add_child(margin)
	var scroll_host := ScrollContainer.new()
	scroll_host.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll_host)
	var host := VBoxContainer.new()
	host.name = "RouteRewardModalContent"
	host.custom_minimum_size.x = 1160
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_theme_constant_override("separation", 12)
	scroll_host.add_child(host)
	if not _reduced_motion_enabled() and not _running_automated_test():
		dimmer.modulate.a = 0.0
		host.modulate.a = 0.0
		host.position.y = 18.0
		var reveal := create_tween().set_parallel(true)
		reveal.tween_property(dimmer, "modulate:a", 1.0, 0.22)
		reveal.tween_property(host, "modulate:a", 1.0, 0.24).set_delay(0.08)
		reveal.tween_property(host, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return host


func _clear_route_reward_overlay() -> void:
	if is_instance_valid(route_reward_overlay):
		route_reward_overlay.queue_free()
	route_reward_overlay = null


func _show_route_shop() -> void:
	_clear_route_shop_service_overlay()
	current_screen = "route_shop"
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	var node: Dictionary = run.get("pending_route_node", {})
	if not node.has("inventory"):
		_generate_shop_inventory()
		node.inventory = run.shop.slice(0, 4)
		run.pending_route_node = node
	selected_route_shop_card_id = ""
	var held_card_id := _route_shopkeeper_card_for_visit(node)
	var shell_parts := TOPDECK_UI_SCRIPT.make_encounter_shell(
		"RouteShopEncounter",
		"",
		"",
		"",
		PALETTE.STATE_REWARD,
		_route_run_stats_text(),
		ROUTE_SHOPKEEPER_ART,
		"RouteShopArtwork"
	)
	content.add_child(shell_parts.panel)
	var shop_media := shell_parts.media as PanelContainer
	shop_media.size_flags_stretch_ratio = 1.0
	shop_media.clip_contents = false
	_configure_route_shopkeeper_media(shell_parts, held_card_id, "RouteShopArtwork", 600.0, 0.68, Vector2(0, -155))
	var encounter_body := shell_parts.content as VBoxContainer
	encounter_body.size_flags_stretch_ratio = 0.0
	var shopkeeper_stage := shop_media.find_child("RouteShopkeeperStage", true, false) as Control
	var service_parts := TOPDECK_UI_SCRIPT.make_section("", PALETTE.STATE_REWARD)
	var service_panel := service_parts.panel as PanelContainer
	service_panel.name = "RouteShopServicesPanel"
	service_panel.custom_minimum_size = Vector2(435, 252)
	if shopkeeper_stage != null:
		shopkeeper_stage.add_child(service_panel)
		service_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		service_panel.offset_left = -455.0
		service_panel.offset_top = 48.0
		service_panel.offset_right = -16.0
		service_panel.offset_bottom = 300.0
		service_panel.z_index = 20
		encounter_body.visible = false
	else:
		service_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		encounter_body.add_child(service_panel)
	var service_body := service_parts.body as VBoxContainer
	service_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	var services := VBoxContainer.new()
	services.name = "RouteShopServices"
	services.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	services.add_theme_constant_override("separation", 14)
	service_body.add_child(services)
	var heal := TOPDECK_UI_SCRIPT.make_button(
		"Heal %d Life — $%d" % [route_run_service.SHOP_HEAL_AMOUNT, route_run_service.SHOP_HEAL_COST],
		"confirm", Vector2(0, 64), "RouteShopHealButton"
	)
	heal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heal.disabled = int(run.money) < route_run_service.SHOP_HEAL_COST or int(run.life) >= int(run.max_life)
	_connect_pressed(heal, _route_shop_heal)
	services.add_child(heal)
	var removal_used := bool(node.get("remove_purchased", false))
	var remove := TOPDECK_UI_SCRIPT.make_button(
		"Remove a Card — SOLD OUT" if removal_used else "Remove a Card — $%d" % route_run_service.SHOP_REMOVE_COST,
		"danger", Vector2(0, 64), "RouteShopRemoveButton"
	)
	remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove.disabled = removal_used or int(run.money) < route_run_service.SHOP_REMOVE_COST or _deck_total(run.deck) <= MIN_MAIN_DECK_SIZE
	_connect_pressed(remove, _show_route_remove_card)
	services.add_child(remove)
	var upgrade_used := bool(node.get("upgrade_purchased", false))
	var upgrade := TOPDECK_UI_SCRIPT.make_button(
		"Upgrade a Card — SOLD OUT" if upgrade_used else "Upgrade a Card — $%d" % route_run_service.SHOP_UPGRADE_COST,
		"special", Vector2(0, 64), "RouteShopUpgradeButton"
	)
	upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade.disabled = upgrade_used or int(run.money) < route_run_service.SHOP_UPGRADE_COST or route_run_service.upgradeable_card_ids(run).is_empty()
	_connect_pressed(upgrade, _show_route_upgrade_card)
	services.add_child(upgrade)
	var inventory_parts := TOPDECK_UI_SCRIPT.make_section("", PALETTE.STATE_REWARD)
	(inventory_parts.panel as PanelContainer).name = "RouteShopDisplayCase"
	if shopkeeper_stage != null:
		var display_case := inventory_parts.panel as PanelContainer
		shopkeeper_stage.add_child(display_case)
		display_case.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		display_case.offset_left = 110.0
		display_case.offset_top = -315.0
		display_case.offset_right = -130.0
		display_case.offset_bottom = -8.0
		display_case.z_index = 30
		(inventory_parts.body as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		encounter_body.add_child(inventory_parts.panel)
	var cards_row := HBoxContainer.new()
	cards_row.name = "RouteShopCardOffers"
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 10)
	(inventory_parts.body as VBoxContainer).add_child(cards_row)
	for card_id_value in node.get("inventory", []):
		var card_id := String(card_id_value)
		if not cards_by_id.has(card_id):
			continue
		_add_route_shop_card_offer(cards_row, card_id, true)
	var leave := TOPDECK_UI_SCRIPT.make_button("Continue on Route     >", "primary", Vector2(360, 64), "RouteShopContinueButton")
	_connect_pressed(leave, _complete_route_node)
	(shell_parts.actions as HBoxContainer).add_child(leave)


func _route_shopkeeper_card_for_visit(node: Dictionary) -> String:
	var existing_id := String(node.get("shopkeeper_card_id", ""))
	if cards_by_id.has(existing_id):
		run.last_route_shopkeeper_card_id = existing_id
		return existing_id

	var candidates: Array[String] = []
	var inventory: Array = node.get("inventory", run.get("shop", []))
	for card_id_value in inventory:
		var card_id := String(card_id_value)
		if card_id not in candidates and cards_by_id.has(card_id) and _card_uses_authored_face(cards_by_id[card_id]):
			candidates.append(card_id)
	if candidates.is_empty():
		return ""

	var previous_id := String(run.get("last_route_shopkeeper_card_id", ""))
	if candidates.size() > 1 and previous_id in candidates:
		candidates.erase(previous_id)
	var picker := RandomNumberGenerator.new()
	picker.seed = int(run.get("route_seed", 1)) ^ hash("route_shopkeeper:%s" % String(node.get("id", "shop")))
	var selected_id := candidates[picker.randi_range(0, candidates.size() - 1)]
	node.shopkeeper_card_id = selected_id
	run.pending_route_node = node
	run.last_route_shopkeeper_card_id = selected_id
	return selected_id


func _configure_route_shopkeeper_media(
	shell_parts: Dictionary,
	held_card_id: String,
	artwork_name: String,
	stage_height: float = 360.0,
	portrait_zoom: float = 1.0,
	portrait_offset: Vector2 = Vector2.ZERO
) -> void:
	var media := shell_parts.get("media") as PanelContainer
	if media == null:
		return
	var artwork := media.find_child(artwork_name, true, false) as TextureRect
	if artwork == null:
		return
	var media_body := artwork.get_parent() as VBoxContainer
	if media_body == null:
		return
	media_body.remove_child(artwork)

	var stage := Control.new()
	stage.name = "RouteShopkeeperStage"
	stage.custom_minimum_size = Vector2(250, stage_height)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if stage_height >= 500.0:
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		media_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_body.add_child(stage)
	var paper := ColorRect.new()
	paper.name = "RouteShopkeeperPaper"
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.color = PALETTE.SURFACE_PAPER_MUTED
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(paper)

	if cards_by_id.has(held_card_id):
		var held_card := Control.new()
		held_card.name = "RouteShopkeeperHeldCard"
		held_card.rotation_degrees = -8.0
		held_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		held_card.set_meta("card_id", held_card_id)
		stage.add_child(held_card)

		# CardFace is authored against a full card canvas. Keep that native canvas
		# intact and scale it as one unit so its labels and drawn chassis cannot
		# escape their frame at the small, in-hand presentation size.
		var native_card_size := Vector2(250, 355)
		var held_face := CARD_FACE_SCRIPT.new()
		held_face.name = "RouteShopkeeperHeldCardFace"
		held_face.configure(cards_by_id[held_card_id], _run_difficulty_id(), not _reduced_motion_enabled(), true)
		held_face.custom_minimum_size = native_card_size
		held_face.size = native_card_size
		held_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		held_card.add_child(held_face)
		stage.resized.connect(_layout_route_shopkeeper_held_card.bind(stage, held_card, held_face, artwork.texture, portrait_zoom, portrait_offset))
		_layout_route_shopkeeper_held_card(stage, held_card, held_face, artwork.texture, portrait_zoom, portrait_offset)

	artwork.name = "RouteShopkeeperArtwork"
	artwork.custom_minimum_size = Vector2.ZERO
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(artwork)
	stage.resized.connect(_layout_route_shopkeeper_art.bind(stage, artwork, portrait_zoom, portrait_offset))
	_layout_route_shopkeeper_art(stage, artwork, portrait_zoom, portrait_offset)


func _layout_route_shopkeeper_art(stage: Control, artwork: TextureRect, portrait_zoom: float, portrait_offset: Vector2) -> void:
	artwork.pivot_offset = stage.size * 0.5
	artwork.scale = Vector2.ONE * portrait_zoom
	artwork.position = portrait_offset


func _layout_route_shopkeeper_held_card(
	stage: Control,
	holder: Control,
	face: Control,
	portrait: Texture2D,
	portrait_zoom: float = 1.0,
	portrait_offset: Vector2 = Vector2.ZERO
) -> void:
	if portrait == null or stage.size.x <= 1.0 or stage.size.y <= 1.0:
		return
	var portrait_size := Vector2(portrait.get_width(), portrait.get_height())
	var portrait_scale := minf(stage.size.x / portrait_size.x, stage.size.y / portrait_size.y) * portrait_zoom
	var portrait_origin := (stage.size - portrait_size * portrait_scale) * 0.5 + portrait_offset
	# Coordinates are relative to the supplied transparent portrait. The card's
	# lower-right edge meets the open fingers while the portrait remains above
	# it in sibling order, allowing the fingers to occlude it naturally.
	var held_size := Vector2(175, 248) * portrait_scale
	holder.size = held_size
	holder.position = portrait_origin + Vector2(-50, 320) * portrait_scale
	holder.pivot_offset = held_size * 0.5
	face.scale = Vector2(held_size.x / 250.0, held_size.y / 355.0)


func _add_route_shop_card_offer(parent: Node, card_id: String, compact_display: bool = false) -> void:
	var card: Dictionary = cards_by_id[card_id]
	if compact_display:
		var display_offer := VBoxContainer.new()
		display_offer.name = "RouteShopDisplayOffer_%s" % card_id
		display_offer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		display_offer.add_theme_constant_override("separation", 4)
		display_offer.set_meta("card_id", card_id)
		parent.add_child(display_offer)
		var display_card_center := CenterContainer.new()
		display_card_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		display_card_center.custom_minimum_size = Vector2(136, 209)
		display_offer.add_child(display_card_center)
		var card_anchor := Control.new()
		card_anchor.custom_minimum_size = Vector2(136, 193)
		card_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		display_card_center.add_child(card_anchor)
		var card_choice := Control.new()
		card_choice.name = "RouteShopCardChoice_%s" % card_id
		card_choice.size = Vector2(136, 193)
		card_choice.position = Vector2(0, 8)
		card_choice.pivot_offset = card_choice.size * 0.5
		card_choice.set_meta("base_position", card_choice.position)
		card_choice.set_meta("card_id", card_id)
		card_anchor.add_child(card_choice)
		var card_face := _make_card_face(card, card_choice.size, true)
		card_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_choice.add_child(card_face)
		var select_card := Button.new()
		select_card.name = "RouteShopCardButton_%s" % card_id
		select_card.flat = true
		select_card.size = card_choice.size
		select_card.tooltip_text = "Select %s" % String(card.get("name", "card"))
		select_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		select_card.pressed.connect(_select_route_shop_card.bind(card_id), CONNECT_DEFERRED)
		card_choice.add_child(select_card)
		var display_price := TOPDECK_UI_SCRIPT.make_label("$%d" % _card_price(card_id), "small", PALETTE.STATE_REWARD)
		display_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		display_offer.add_child(display_price)
		var purchase_slot := CenterContainer.new()
		purchase_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		purchase_slot.custom_minimum_size = Vector2(0, 42)
		display_offer.add_child(purchase_slot)
		var display_buy := TOPDECK_UI_SCRIPT.make_button(
			"Buy Card", "primary", Vector2(136, 42), "RouteShopBuy_%s" % card_id
		)
		display_buy.disabled = int(run.money) < _card_price(card_id)
		display_buy.visible = false
		_connect_pressed(display_buy, _route_shop_buy_card.bind(card_id))
		purchase_slot.add_child(display_buy)
		return
	var offer_parts := TOPDECK_UI_SCRIPT.make_section("", _affinity_color(_card_archetype(card)), Vector2(205, 0))
	var offer_panel := offer_parts.panel as PanelContainer
	offer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(offer_panel)
	var offer_body := offer_parts.body as VBoxContainer
	var card_center := CenterContainer.new()
	card_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_body.add_child(card_center)
	card_center.add_child(_make_card_face(card, Vector2(165, 232), true))
	var price := TOPDECK_UI_SCRIPT.make_label("$%d  •  ADD TO DECK" % _card_price(card_id), "small", PALETTE.STATE_REWARD)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_body.add_child(price)
	var buy := TOPDECK_UI_SCRIPT.make_button(
		"Buy Card", "primary", Vector2(0, 46), "RouteShopBuy_%s" % card_id
	)
	buy.disabled = int(run.money) < _card_price(card_id)
	_connect_pressed(buy, _route_shop_buy_card.bind(card_id))
	offer_body.add_child(buy)


func _select_route_shop_card(card_id: String) -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	if not node.get("inventory", []).has(card_id):
		return
	selected_route_shop_card_id = card_id
	var offers := find_child("RouteShopCardOffers", true, false)
	if offers == null:
		return
	for offer_node in offers.get_children():
		if not offer_node is Control or not offer_node.has_meta("card_id"):
			continue
		var offer := offer_node as Control
		var offer_id := String(offer.get_meta("card_id", ""))
		var selected := offer_id == card_id
		var choice := offer.find_child("RouteShopCardChoice_%s" % offer_id, true, false) as Control
		var buy_button := offer.find_child("RouteShopBuy_%s" % offer_id, true, false) as Button
		if buy_button != null:
			buy_button.visible = selected
		if choice == null:
			continue
		var base_position: Vector2 = choice.get_meta("base_position", choice.position)
		var target_position := base_position + Vector2(0, -12.0 if selected else 0.0)
		var target_scale := Vector2(1.035, 1.035) if selected else Vector2.ONE
		if _reduced_motion_enabled() or _running_automated_test():
			choice.position = target_position
			choice.scale = target_scale
		else:
			var tween := create_tween().set_parallel(true)
			tween.tween_property(choice, "position", target_position, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(choice, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _route_shop_heal() -> void:
	if int(run.money) < route_run_service.SHOP_HEAL_COST or int(run.life) >= int(run.max_life):
		return
	run.money = int(run.money) - route_run_service.SHOP_HEAL_COST
	run.life = mini(int(run.max_life), int(run.life) + route_run_service.SHOP_HEAL_AMOUNT)
	_show_route_shop()


func _route_shop_buy_card(card_id: String) -> void:
	var price := _card_price(card_id)
	var node: Dictionary = run.pending_route_node
	if int(run.money) < price or not node.get("inventory", []).has(card_id):
		return
	var starting_money := int(run.money)
	var starting_deck_size := _deck_total(run.deck)
	var purchased_choice := find_child("RouteShopCardChoice_%s" % card_id, true, false) as Control
	var shop_encounter := find_child("RouteShopEncounter", true, false)
	if shop_encounter != null:
		for button_node in shop_encounter.find_children("*", "Button", true, false):
			(button_node as Button).disabled = true
	run.money = int(run.money) - price
	run.deck[card_id] = int(run.deck.get(card_id, 0)) + 1
	run.collection[card_id] = int(run.collection.get(card_id, 0)) + 1
	node.inventory.erase(card_id)
	run.pending_route_node = node
	selected_route_shop_card_id = ""
	_update_status()
	var shop_stats := find_child("EncounterStats", true, false) as Label
	if shop_stats != null:
		shop_stats.text = _route_run_stats_text()
	await _animate_route_shop_purchase(
		purchased_choice,
		card_id,
		price,
		starting_money,
		starting_deck_size
	)
	if current_screen == "route_shop":
		_show_route_shop()


func _animate_route_shop_purchase(
	card_control: Control,
	card_id: String,
	price: int,
	starting_money: int,
	starting_deck_size: int
) -> void:
	last_card_add_effect_context = "route_shop"
	last_route_shop_purchase_effect_stages = ["sale_locked", "funds_debited", "card_collected", "deck_confirmed"]
	if card_control != null:
		card_control.set_meta("card_add_effect_context", "route_shop")
		card_control.set_meta("purchase_effect_stages", last_route_shop_purchase_effect_stages.duplicate())

	var ending_money := int(run.get("money", starting_money - price))
	var ending_deck_size := _deck_total(run.get("deck", {}))
	var funds_chip := find_child("RouteFundsChip", true, false) as Label
	var deck_chip := find_child("RouteDeckChip", true, false) as Label
	if funds_chip != null:
		funds_chip.text = "FUNDS  $%d" % ending_money
	if deck_chip != null:
		deck_chip.text = "DECK  %d" % ending_deck_size
	if _running_automated_test() or _reduced_motion_enabled() or card_control == null:
		if not _running_automated_test() and ui_sound_controller != null:
			ui_sound_controller.play_success()
		return

	if ui_sound_controller != null:
		ui_sound_controller.play_success()

	var effect_layer := Control.new()
	effect_layer.name = "RouteShopPurchaseEffect"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 975
	add_child(effect_layer)

	var card_rect := card_control.get_global_rect()
	var flying_card := _make_card_face(cards_by_id.get(card_id, {}), card_rect.size, true)
	flying_card.name = "RouteShopPurchasedCard"
	flying_card.position = card_rect.position
	flying_card.size = card_rect.size
	flying_card.pivot_offset = card_rect.size * 0.5
	flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(flying_card)
	card_control.modulate.a = 0.12

	var burst_center := card_rect.get_center()
	for spark_index in range(10):
		var spark := ColorRect.new()
		spark.name = "RouteShopPurchaseSpark%02d" % spark_index
		spark.color = PALETTE.STATE_REWARD if spark_index % 3 == 0 else PALETTE.ACTION_CONFIRM
		spark.size = Vector2(5, 18 if spark_index % 2 == 0 else 12)
		spark.position = burst_center - spark.size * 0.5
		spark.pivot_offset = spark.size * 0.5
		spark.rotation = TAU * float(spark_index) / 10.0
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(spark)
		var direction := Vector2.UP.rotated(TAU * float(spark_index) / 10.0)
		var spark_tween := create_tween().set_parallel(true)
		spark_tween.tween_property(spark, "position", spark.position + direction * (54.0 + float(spark_index % 3) * 9.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.2).set_delay(0.14)
		spark_tween.finished.connect(spark.queue_free)

	# This toast is deliberately a fixed Control instead of a Container. It is an
	# effect-layer element, so inheriting layout flags from the screen theme would
	# stretch it over the shop and bury the purchase moment it is confirming.
	var banner := Control.new()
	banner.name = "RouteShopPurchaseBanner"
	banner.size = Vector2(440, 92)
	banner.modulate.a = 0.0
	var banner_surface = ANGULAR_SURFACE_SCRIPT.new()
	banner_surface.name = "RouteShopPurchaseBannerSurface"
	banner_surface.configure(PALETTE.SURFACE_RAISED, PALETTE.ACTION_CONFIRM, true, true)
	banner.add_child(banner_surface)
	var banner_title := TOPDECK_UI_SCRIPT.make_label("DECK UPGRADED", "section", PALETTE.TEXT_PRIMARY)
	banner_title.position = Vector2(22, 11)
	banner_title.size = Vector2(396, 28)
	banner.add_child(banner_title)
	var card_name := String(cards_by_id.get(card_id, {}).get("name", card_id))
	var banner_detail := TOPDECK_UI_SCRIPT.make_label(
		"%s added  •  -$%d" % [card_name, price], "small", PALETTE.STATE_REWARD
	)
	banner_detail.position = Vector2(22, 48)
	banner_detail.size = Vector2(396, 24)
	banner.add_child(banner_detail)
	effect_layer.add_child(banner)
	# Keep the confirmation in the open area beside the shopkeeper so the toast
	# never covers her face or the card she is presenting.
	banner.position = Vector2(clampf(get_viewport_rect().size.x * 0.04, 24.0, 64.0), 104.0)

	if funds_chip != null:
		funds_chip.text = "FUNDS  $%d" % starting_money
		funds_chip.pivot_offset = funds_chip.size * 0.5
		var funds_tween := create_tween().set_parallel(true)
		funds_tween.tween_method(func(progress: float) -> void:
			funds_chip.text = "FUNDS  $%d" % roundi(lerpf(float(starting_money), float(ending_money), progress)),
			0.0, 1.0, 0.44
		)
		funds_tween.tween_property(funds_chip, "modulate", PALETTE.STATE_REWARD, 0.12)
		funds_tween.tween_property(funds_chip, "modulate", Color.WHITE, 0.24).set_delay(0.2)

	var lock_in := create_tween().set_parallel(true)
	lock_in.tween_property(flying_card, "scale", Vector2(1.13, 1.13), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lock_in.tween_property(flying_card, "rotation", deg_to_rad(-3.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lock_in.tween_property(banner, "modulate:a", 1.0, 0.16)
	lock_in.tween_property(banner, "position:y", 120.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await lock_in.finished

	var deck_target := Vector2(get_viewport_rect().size.x - 120.0, 58.0)
	if deck_chip != null:
		deck_target = deck_chip.get_global_rect().get_center()
	elif status_label != null:
		# Encounter screens use the compact combined status line instead of the
		# map's individual HUD chips. Land the card on its DECK readout rather
		# than sending it toward an unexplained corner of the screen.
		deck_target = status_label.global_position + Vector2(
			minf(status_label.size.x - 18.0, 255.0),
			status_label.size.y * 0.5
		)
	var flying_target := deck_target - flying_card.size * 0.5
	var collect := create_tween().set_parallel(true)
	collect.tween_property(flying_card, "position", flying_target, 0.48).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	collect.tween_property(flying_card, "scale", Vector2(0.24, 0.24), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collect.tween_property(flying_card, "rotation", deg_to_rad(8.0), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	collect.tween_property(flying_card, "modulate:a", 0.18, 0.13).set_delay(0.35)
	await collect.finished

	if deck_chip != null:
		deck_chip.text = "DECK  %d" % starting_deck_size
		deck_chip.pivot_offset = deck_chip.size * 0.5
		var deck_confirm := create_tween().set_parallel(true)
		deck_confirm.tween_method(func(progress: float) -> void:
			deck_chip.text = "DECK  %d" % roundi(lerpf(float(starting_deck_size), float(ending_deck_size), progress)),
			0.0, 1.0, 0.18
		)
		deck_confirm.tween_property(deck_chip, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await deck_confirm.finished
		var deck_settle := create_tween()
		deck_settle.tween_property(deck_chip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await deck_settle.finished
	elif status_label != null:
		status_label.pivot_offset = deck_target - status_label.global_position
		var status_confirm := create_tween().set_parallel(true)
		status_confirm.tween_property(status_label, "scale", Vector2(1.045, 1.045), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		status_confirm.tween_property(status_label, "modulate", PALETTE.ACTION_CONFIRM, 0.1)
		await status_confirm.finished
		var status_settle := create_tween().set_parallel(true)
		status_settle.tween_property(status_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		status_settle.tween_property(status_label, "modulate", Color.WHITE, 0.18)
		await status_settle.finished

	await get_tree().create_timer(0.24).timeout
	var dismiss := create_tween().set_parallel(true)
	dismiss.tween_property(banner, "modulate:a", 0.0, 0.16)
	dismiss.tween_property(banner, "position:y", 110.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await dismiss.finished
	if is_instance_valid(effect_layer):
		effect_layer.queue_free()


func _show_route_remove_card() -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	if bool(node.get("remove_purchased", false)) or int(run.get("money", 0)) < route_run_service.SHOP_REMOVE_COST:
		_show_route_shop()
		return
	if find_child("RouteShopEncounter", true, false) == null:
		_show_route_shop()
	current_screen = "route_remove"
	_apply_screen_chrome()
	_update_status()
	var candidates: Array[String] = []
	for card_id_value in run.deck.keys():
		var card_id := String(card_id_value)
		if cards_by_id.has(card_id) and int(run.deck.get(card_id, 0)) > 0:
			candidates.append(card_id)
	candidates.sort_custom(func(left: String, right: String) -> bool:
		return _card_display_name(cards_by_id[left]) < _card_display_name(cards_by_id[right])
	)
	_show_route_shop_service_picker(
		"remove",
		candidates,
		"Remove a Card — $%d" % route_run_service.SHOP_REMOVE_COST,
		"Choose one card to permanently remove. This service can be used once at this shop, and your deck cannot drop below %d card." % MIN_MAIN_DECK_SIZE,
		PALETTE.ACTION_DANGER
	)


func _route_remove_card(card_id: String) -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	var result: Dictionary = route_run_service.buy_card_removal(run, node, card_id, MIN_MAIN_DECK_SIZE)
	run.pending_route_node = node
	_set_footer(String(result.get("message", "Could not remove that card.")))
	_show_route_shop()


func _show_route_upgrade_card() -> void:
	var node: Dictionary = run.get("pending_route_node", {})
	if bool(node.get("upgrade_purchased", false)) or int(run.get("money", 0)) < route_run_service.SHOP_UPGRADE_COST:
		_show_route_shop()
		return
	if find_child("RouteShopEncounter", true, false) == null:
		_show_route_shop()
	current_screen = "route_upgrade"
	_apply_screen_chrome()
	_update_status()
	var candidates: Array[String] = route_run_service.upgradeable_card_ids(run)
	candidates.sort_custom(func(left: String, right: String) -> bool:
		return _card_display_name(cards_by_id[left]) < _card_display_name(cards_by_id[right])
	)
	_show_route_shop_service_picker(
		"upgrade",
		candidates,
		"Upgrade a Card — $%d" % route_run_service.SHOP_UPGRADE_COST,
		"Choose one copy to improve permanently. Units gain +1 Attack and +1 Health; cards with a discard cost also cost one fewer card to play. This service can be used once at this shop.",
		PALETTE.ACTION_SPECIAL
	)


func _show_route_shop_service_picker(
	service_kind: String,
	candidates: Array[String],
	title: String,
	description: String,
	accent: Color
) -> void:
	_clear_route_shop_service_overlay()
	selected_route_service_card_id = ""
	_set_route_shopkeeper_picker_visibility(false)

	route_shop_service_overlay = Control.new()
	route_shop_service_overlay.name = "RouteShopServiceOverlay"
	route_shop_service_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	route_shop_service_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	route_shop_service_overlay.z_index = 950
	route_shop_service_overlay.set_meta("service_kind", service_kind)
	add_child(route_shop_service_overlay)

	var dimmer := ColorRect.new()
	dimmer.name = "RouteShopServiceDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = PALETTE.OVERLAY_DIM
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	route_shop_service_overlay.add_child(dimmer)

	var margin := MarginContainer.new()
	margin.name = "RouteShopServiceMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 74)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 74)
	margin.add_theme_constant_override("margin_bottom", 28)
	route_shop_service_overlay.add_child(margin)

	var modal_parts := TOPDECK_UI_SCRIPT.make_surface_panel(
		"RouteShopServiceModal",
		PALETTE.SURFACE_RAISED,
		accent,
		Vector2.ZERO,
		Vector4(26, 18, 26, 20),
		true
	)
	var modal := modal_parts.panel as PanelContainer
	modal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(modal)
	var body := modal_parts.body as VBoxContainer
	body.add_theme_constant_override("separation", 8)

	body.add_child(TOPDECK_UI_SCRIPT.make_label("DECK SERVICE", "eyebrow", accent))
	var heading := TOPDECK_UI_SCRIPT.make_label(title.to_upper(), "screen_title", PALETTE.TEXT_PRIMARY)
	heading.name = "RouteShopServiceTitle"
	body.add_child(heading)
	var detail := TOPDECK_UI_SCRIPT.make_label(description, "body", PALETTE.TEXT_SECONDARY)
	detail.name = "RouteShopServiceDescription"
	body.add_child(detail)
	var stats := TOPDECK_UI_SCRIPT.make_label(_route_run_stats_text(), "status", PALETTE.STATE_REWARD)
	stats.name = "RouteShopServiceStats"
	body.add_child(stats)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = accent
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(divider)

	var card_scroll := ScrollContainer.new()
	card_scroll.name = "RouteShopServiceCardScroll"
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(card_scroll)
	var choices := GridContainer.new()
	choices.name = "RouteRemoveChoices" if service_kind == "remove" else "RouteUpgradeChoices"
	choices.columns = 6
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("h_separation", 20)
	choices.add_theme_constant_override("v_separation", 12)
	card_scroll.add_child(choices)
	for card_id in candidates:
		_add_route_shop_service_card_choice(choices, service_kind, card_id, accent)
	if candidates.is_empty():
		var empty_copy := TOPDECK_UI_SCRIPT.make_label(
			"Every eligible card in your deck has already been upgraded." if service_kind == "upgrade" else "There are no cards available for this service.",
			"body",
			PALETTE.TEXT_SECONDARY
		)
		empty_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choices.add_child(empty_copy)

	var actions := HBoxContainer.new()
	actions.name = "RouteShopServiceActions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 14)
	body.add_child(actions)
	var instruction := TOPDECK_UI_SCRIPT.make_label("Select a card to continue.", "small", PALETTE.TEXT_SECONDARY)
	instruction.name = "RouteShopServiceSelectionInstruction"
	instruction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions.add_child(instruction)
	var back_name := "RouteRemoveBackButton" if service_kind == "remove" else "RouteUpgradeBackButton"
	var back := TOPDECK_UI_SCRIPT.make_button("Back to Shop", "secondary", Vector2(210, 52), back_name)
	_connect_pressed(back, _close_route_shop_service_overlay)
	actions.add_child(back)
	var confirm_name := "RouteRemoveConfirmButton" if service_kind == "remove" else "RouteUpgradeConfirmButton"
	var confirm_text := "Remove Selected Card" if service_kind == "remove" else "Upgrade Selected Card"
	var confirm_variant := "danger" if service_kind == "remove" else "special"
	var confirm := TOPDECK_UI_SCRIPT.make_button(confirm_text, confirm_variant, Vector2(250, 52), confirm_name)
	confirm.disabled = true
	_connect_pressed(confirm, _confirm_route_shop_service_selection.bind(service_kind))
	actions.add_child(confirm)

	if not _reduced_motion_enabled() and not _running_automated_test():
		dimmer.modulate.a = 0.0
		modal.modulate.a = 0.0
		modal.position.y = 18.0
		var reveal := create_tween().set_parallel(true)
		reveal.tween_property(dimmer, "modulate:a", 1.0, 0.18)
		reveal.tween_property(modal, "modulate:a", 1.0, 0.22).set_delay(0.05)
		reveal.tween_property(modal, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_route_shop_service_card_choice(
	parent: GridContainer,
	service_kind: String,
	card_id: String,
	accent: Color
) -> void:
	if not cards_by_id.has(card_id):
		return
	var card: Dictionary = cards_by_id[card_id]
	var card_size := Vector2(166, 236)
	var choice := VBoxContainer.new()
	choice.name = "RouteServiceChoice_%s" % card_id
	choice.custom_minimum_size = Vector2(176, 278)
	choice.add_theme_constant_override("separation", 4)
	choice.set_meta("card_id", card_id)
	choice.set_meta("service_kind", service_kind)
	parent.add_child(choice)

	var card_visual := Control.new()
	card_visual.name = "RouteServiceCardVisual"
	card_visual.custom_minimum_size = card_size
	card_visual.size = card_size
	card_visual.pivot_offset = card_size * 0.5
	choice.add_child(card_visual)
	var face := _make_card_face(card, card_size, not _reduced_motion_enabled())
	face.name = "RouteServiceCardFace"
	face.size = card_size
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_visual.add_child(face)

	var outline := Panel.new()
	outline.name = "RouteServiceSelectionOutline"
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.z_index = 4
	outline.visible = false
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color.TRANSPARENT
	outline_style.border_color = accent
	outline_style.set_border_width_all(4)
	outline_style.corner_radius_top_left = 4
	outline_style.corner_radius_top_right = 4
	outline_style.corner_radius_bottom_right = 4
	outline_style.corner_radius_bottom_left = 4
	outline.add_theme_stylebox_override("panel", outline_style)
	card_visual.add_child(outline)

	var select_button := Button.new()
	select_button.name = ("RouteRemoveCard_%s" if service_kind == "remove" else "RouteUpgradeCard_%s") % card_id
	select_button.flat = true
	select_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_button.tooltip_text = "Select %s" % _card_display_name(card)
	select_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	select_button.pressed.connect(_select_route_shop_service_card.bind(service_kind, card_id), CONNECT_DEFERRED)
	card_visual.add_child(select_button)

	var quantity := TOPDECK_UI_SCRIPT.make_label("×%d" % int(run.deck.get(card_id, 0)), "small", PALETTE.TEXT_PRIMARY)
	quantity.name = "RouteServiceQuantity"
	quantity.position = Vector2(card_size.x - 49.0, 7.0)
	quantity.size = Vector2(42, 28)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quantity.z_index = 6
	var quantity_style := StyleBoxFlat.new()
	quantity_style.bg_color = Color(PALETTE.SURFACE_ROOT, 0.94)
	quantity_style.border_color = accent
	quantity_style.set_border_width_all(2)
	quantity_style.corner_radius_top_left = 3
	quantity_style.corner_radius_top_right = 6
	quantity_style.corner_radius_bottom_right = 3
	quantity_style.corner_radius_bottom_left = 6
	quantity.add_theme_stylebox_override("normal", quantity_style)
	card_visual.add_child(quantity)

	var info_text := "ONE COPY WILL BE REMOVED"
	if service_kind == "upgrade":
		var upgraded_count: int = route_run_service.upgrade_count(run, card_id)
		info_text = String(route_run_service.upgrade_summary(card_id)).to_upper()
		if upgraded_count > 0:
			info_text += "  •  %d UPGRADED" % upgraded_count
	var info := TOPDECK_UI_SCRIPT.make_label(info_text, "small", PALETTE.TEXT_SECONDARY)
	info.name = "RouteServiceCardInfo"
	info.custom_minimum_size = Vector2(0, 32)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	choice.add_child(info)


func _select_route_shop_service_card(service_kind: String, card_id: String) -> void:
	if not is_instance_valid(route_shop_service_overlay):
		return
	if String(route_shop_service_overlay.get_meta("service_kind", "")) != service_kind:
		return
	selected_route_service_card_id = card_id
	var choices_name := "RouteRemoveChoices" if service_kind == "remove" else "RouteUpgradeChoices"
	var choices := route_shop_service_overlay.find_child(choices_name, true, false)
	if choices != null:
		for choice_node in choices.get_children():
			if not choice_node is Control or not choice_node.has_meta("card_id"):
				continue
			var choice := choice_node as Control
			var selected := String(choice.get_meta("card_id", "")) == card_id
			var visual := choice.get_node_or_null("RouteServiceCardVisual") as Control
			var outline := choice.find_child("RouteServiceSelectionOutline", true, false) as Control
			if outline != null:
				outline.visible = selected
			if visual != null:
				var target_scale := Vector2(1.035, 1.035) if selected else Vector2.ONE
				if _reduced_motion_enabled() or _running_automated_test():
					visual.scale = target_scale
				else:
					create_tween().tween_property(visual, "scale", target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var confirm_name := "RouteRemoveConfirmButton" if service_kind == "remove" else "RouteUpgradeConfirmButton"
	var confirm := route_shop_service_overlay.find_child(confirm_name, true, false) as Button
	if confirm != null:
		confirm.disabled = false
	var instruction := route_shop_service_overlay.find_child("RouteShopServiceSelectionInstruction", true, false) as Label
	if instruction != null:
		instruction.text = "%s selected." % _card_display_name(cards_by_id.get(card_id, {}))


func _confirm_route_shop_service_selection(service_kind: String) -> void:
	if selected_route_service_card_id.is_empty():
		return
	if service_kind == "remove":
		_route_remove_card(selected_route_service_card_id)
	else:
		_route_upgrade_card(selected_route_service_card_id)


func _close_route_shop_service_overlay() -> void:
	current_screen = "route_shop"
	_clear_route_shop_service_overlay()
	_apply_screen_chrome()
	_update_status()


func _clear_route_shop_service_overlay() -> void:
	_set_route_shopkeeper_picker_visibility(true)
	if is_instance_valid(route_shop_service_overlay):
		route_shop_service_overlay.queue_free()
	route_shop_service_overlay = null
	selected_route_service_card_id = ""


func _set_route_shopkeeper_picker_visibility(show_shopkeeper: bool) -> void:
	for node_name in ["RouteShopkeeperArtwork", "RouteShopkeeperHeldCard"]:
		for item_node in find_children(node_name, "", true, false):
			var shopkeeper_item := item_node as CanvasItem
			if shopkeeper_item != null:
				shopkeeper_item.visible = show_shopkeeper


func _route_upgrade_card(card_id: String) -> void:
	var selected_choice := find_child("RouteServiceChoice_%s" % card_id, true, false) as Control
	var selected_visual := selected_choice.get_node_or_null("RouteServiceCardVisual") as Control if selected_choice != null else null
	var selected_face := selected_visual.get_node_or_null("RouteServiceCardFace") as Control if selected_visual != null else null
	if is_instance_valid(route_shop_service_overlay):
		for button_node in route_shop_service_overlay.find_children("*", "Button", true, false):
			(button_node as Button).disabled = true
	var node: Dictionary = run.get("pending_route_node", {})
	var result: Dictionary = route_run_service.buy_card_upgrade(run, node, card_id)
	run.pending_route_node = node
	_set_footer(String(result.get("message", "Could not upgrade that card.")))
	if not bool(result.get("ok", false)):
		_show_route_shop()
		return
	_update_status()
	var shop_stats := find_child("RouteShopServiceStats", true, false) as Label
	if shop_stats != null:
		shop_stats.text = _route_run_stats_text()
	await _play_route_card_upgrade_reveal(card_id, selected_visual, selected_face)
	if current_screen == "route_upgrade":
		_show_route_shop()


func _play_route_card_upgrade_reveal(
	card_id: String,
	card_visual: Control = null,
	card_face: Control = null
) -> void:
	if not cards_by_id.has(card_id):
		return
	var temporary_overlay: Control
	if card_visual == null or card_face == null:
		temporary_overlay = Control.new()
		temporary_overlay.name = "RouteCardUpgradeRevealOverlay"
		temporary_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		temporary_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		temporary_overlay.z_index = 1200
		add_child(temporary_overlay)
		var dimmer := ColorRect.new()
		dimmer.name = "RouteCardUpgradeRevealDimmer"
		dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dimmer.color = PALETTE.OVERLAY_DIM
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		temporary_overlay.add_child(dimmer)
		card_visual = Control.new()
		card_visual.name = "RouteEventUpgradeCardVisual"
		card_visual.set_anchors_preset(Control.PRESET_CENTER)
		card_visual.position = Vector2(-115.0, -163.0)
		card_visual.size = Vector2(230.0, 326.0)
		card_visual.custom_minimum_size = card_visual.size
		card_visual.pivot_offset = card_visual.size * 0.5
		temporary_overlay.add_child(card_visual)
		card_face = _make_card_face(cards_by_id[card_id], card_visual.size, not _reduced_motion_enabled())
		card_face.name = "RouteEventUpgradeCardFace"
		card_face.size = card_visual.size
		card_visual.add_child(card_face)

	var upgraded_card: Dictionary = route_run_service.upgraded_card_data(card_id)
	var reveal = CARD_UPGRADE_REVEAL_SCRIPT.new()
	last_card_upgrade_animation_stages = await reveal.play(
		self,
		card_visual,
		card_face,
		upgraded_card,
		_run_difficulty_id(),
		not _reduced_motion_enabled(),
		_reduced_motion_enabled(),
		_running_automated_test()
	)
	if is_instance_valid(temporary_overlay):
		temporary_overlay.queue_free()


func _show_route_event() -> void:
	current_screen = "route_event"
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	var node: Dictionary = run.get("pending_route_node", {})
	if not node.has("event_outcome") or String(node.get("event_outcome", "")).is_empty():
		node.event_outcome = route_run_service.event_outcome_for_node(int(run.get("route_seed", 1)), String(node.get("id", "event")))
		run.pending_route_node = node
	var outcome := String(node.get("event_outcome", "heal"))
	if outcome == "trade_card":
		node = _ensure_route_trade_offer(node)
		run.pending_route_node = node
	var presentation := _route_event_presentation(outcome)
	var trading_card_id := String(node.get("trading_card_id", ""))
	var getting_card_id := String(node.get("getting_card_id", ""))
	if outcome == "trade_card" and cards_by_id.has(trading_card_id) and cards_by_id.has(getting_card_id):
		presentation.description = "Do you want to trade %s for %s?" % [
			_card_display_name(cards_by_id[trading_card_id]),
			_card_display_name(cards_by_id[getting_card_id]),
		]
	var event_accent: Color = presentation.get("accent", PALETTE.ACTION_SPECIAL)
	var event_artwork: Texture2D = null if outcome == "trade_card" else _route_node_icon("event")
	var shell_parts := TOPDECK_UI_SCRIPT.make_encounter_shell(
		"RouteEventEncounter",
		"Surprise Event",
		String(presentation.get("title", node.get("label", "Surprise Event"))),
		String(presentation.get("description", "The route has an unexpected turn.")),
		event_accent,
		_route_run_stats_text(),
		event_artwork,
		"RouteEventArtwork"
	)
	content.add_child(shell_parts.panel)
	if outcome == "trade_card":
		_build_route_trade_offer(
			shell_parts.content as VBoxContainer,
			shell_parts.actions as HBoxContainer,
			node,
			event_accent
		)
		return
	var choices_parts := TOPDECK_UI_SCRIPT.make_section("Choose", event_accent)
	(shell_parts.content as VBoxContainer).add_child(choices_parts.panel)
	var choices := choices_parts.body as VBoxContainer
	match outcome:
		"heal":
			_add_route_event_button(choices, "Take the Snack  •  Heal %d" % route_run_service.EVENT_HEAL_AMOUNT, outcome)
		"max_life":
			_add_route_event_button(choices, "Learn the Routine  •  +%d Max Life" % route_run_service.EVENT_MAX_LIFE_AMOUNT, outcome)
		"money":
			_add_route_event_button(choices, "Collect the Fee  •  Gain $%d" % route_run_service.EVENT_MONEY_AMOUNT, outcome)
		"steal_money":
			_add_route_event_button(choices, "Check Your Wallet  •  Lose up to $%d" % route_run_service.EVENT_STEAL_AMOUNT, outcome)
		"remove_card":
			if _deck_total(run.deck) <= MIN_MAIN_DECK_SIZE:
				_add_route_event_button(choices, "Deck Already at Minimum  •  Continue", outcome)
			else:
				for card_id_value in run.deck.keys():
					var card_id := String(card_id_value)
					_add_route_event_button(choices, "Remove %s  ×%d" % [_card_display_name(cards_by_id[card_id]), int(run.deck[card_id])], outcome, card_id)
		"upgrade_card":
			var candidates: Array[String] = route_run_service.upgradeable_card_ids(run)
			if candidates.is_empty():
				_add_route_event_button(choices, "No Eligible Card  •  Continue Safely", outcome)
			else:
				for card_id in candidates:
					_add_route_event_button(choices, "Upgrade %s  •  %s  •  Take %d Damage" % [
						_card_display_name(cards_by_id[card_id]),
						route_run_service.upgrade_summary(card_id),
						route_run_service.EVENT_UPGRADE_DAMAGE,
					], outcome, card_id)
				_add_route_event_button(choices, "Decline the Offer  •  Continue", "decline")


func _ensure_route_trade_offer(node: Dictionary) -> Dictionary:
	var trading_card_id := String(node.get("trading_card_id", ""))
	var getting_card_id := String(node.get("getting_card_id", ""))
	if (
		int(run.get("deck", {}).get(trading_card_id, 0)) > 0
		and cards_by_id.has(trading_card_id)
		and cards_by_id.has(getting_card_id)
		and trading_card_id != getting_card_id
	):
		return node
	var offer: Dictionary = route_run_service.trade_offer_for_node(
		run,
		String(run.get("starter", "spicy")),
		int(run.get("route_seed", 1)),
		String(node.get("id", "event"))
	)
	node.trading_card_id = String(offer.get("trading_card_id", ""))
	node.getting_card_id = String(offer.get("getting_card_id", ""))
	return node


func _build_route_trade_offer(
	event_content: VBoxContainer,
	actions: HBoxContainer,
	node: Dictionary,
	event_accent: Color
) -> void:
	var trading_card_id := String(node.get("trading_card_id", ""))
	var getting_card_id := String(node.get("getting_card_id", ""))
	if not cards_by_id.has(trading_card_id) or not cards_by_id.has(getting_card_id):
		event_content.add_child(TOPDECK_UI_SCRIPT.make_label(
			"No one here has a compatible card to trade, so you continue safely.",
			"body",
			PALETTE.TEXT_SECONDARY
		))
		var continue_button := TOPDECK_UI_SCRIPT.make_button(
			"CONTINUE", "primary", Vector2(210, 52), "RouteEvent_decline_trade"
		)
		_connect_pressed(continue_button, _resolve_route_event.bind("decline_trade", "", ""))
		actions.add_child(continue_button)
		return

	var trade_parts := TOPDECK_UI_SCRIPT.make_section("", event_accent)
	var trade_panel := trade_parts.panel as PanelContainer
	trade_panel.name = "RouteTradeOffer"
	trade_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_content.add_child(trade_panel)
	var trade_body := trade_parts.body as VBoxContainer
	trade_body.alignment = BoxContainer.ALIGNMENT_CENTER
	var trade_row := HBoxContainer.new()
	trade_row.name = "RouteTradeCards"
	trade_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trade_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trade_row.add_theme_constant_override("separation", 20)
	trade_body.add_child(trade_row)
	trade_row.add_child(_make_route_trade_card_column(
		trading_card_id,
		"TRADING",
		PALETTE.SIGNAL_RED,
		"RouteTradeOutgoing"
	))

	var arrow_column := VBoxContainer.new()
	arrow_column.name = "RouteTradeArrowColumn"
	arrow_column.custom_minimum_size = Vector2(112, 0)
	arrow_column.alignment = BoxContainer.ALIGNMENT_CENTER
	arrow_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arrow_column.add_theme_constant_override("separation", 10)
	trade_row.add_child(arrow_column)
	var arrow_center := CenterContainer.new()
	arrow_center.custom_minimum_size = Vector2(112, 96)
	arrow_column.add_child(arrow_center)
	var arrows := TextureRect.new()
	arrows.name = "RouteTradeArrows"
	arrows.texture = MATERIAL_SYMBOLS.icon("swap")
	arrows.custom_minimum_size = Vector2(82, 82)
	arrows.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrows.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrows.modulate = event_accent
	arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_center.add_child(arrows)
	var one_for_one := TOPDECK_UI_SCRIPT.make_label("ONE FOR ONE", "eyebrow", PALETTE.TEXT_SECONDARY)
	one_for_one.name = "RouteTradeStatus"
	one_for_one.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_column.add_child(one_for_one)

	trade_row.add_child(_make_route_trade_card_column(
		getting_card_id,
		"GETTING",
		PALETTE.EMERALD,
		"RouteTradeIncoming"
	))

	var decline_button := TOPDECK_UI_SCRIPT.make_button(
		"KEEP MY CARD", "secondary", Vector2(220, 54), "RouteEvent_decline_trade"
	)
	_connect_pressed(decline_button, _resolve_route_event.bind("decline_trade", trading_card_id, getting_card_id))
	actions.add_child(decline_button)
	var trade_button := TOPDECK_UI_SCRIPT.make_button(
		"MAKE TRADE", "confirm", Vector2(230, 54), "RouteEvent_trade_card"
	)
	MATERIAL_SYMBOLS.apply_to_button(trade_button, "swap", 22)
	_connect_pressed(trade_button, _resolve_route_event.bind("trade_card", trading_card_id, getting_card_id))
	actions.add_child(trade_button)


func _make_route_trade_card_column(
	card_id: String,
	caption: String,
	caption_color: Color,
	node_prefix: String
) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = node_prefix + "Column"
	column.custom_minimum_size = Vector2(230, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var visual := Control.new()
	visual.name = node_prefix + "Visual"
	visual.custom_minimum_size = Vector2(205, 291)
	visual.size = visual.custom_minimum_size
	visual.set_meta("card_id", card_id)
	center.add_child(visual)
	var face := _make_card_face(cards_by_id[card_id], visual.size, not _reduced_motion_enabled())
	face.name = node_prefix + "CardFace"
	face.size = visual.size
	face.pivot_offset = face.size * 0.5
	visual.add_child(face)
	var label := TOPDECK_UI_SCRIPT.make_label(caption, "section", caption_color)
	label.name = node_prefix + "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	return column


func _route_event_presentation(outcome: String) -> Dictionary:
	match outcome:
		"heal":
			return {"title": "A Restorative Snack", "description": "A league regular shares a restorative snack before your next match.", "accent": PALETTE.ACTION_CONFIRM}
		"max_life":
			return {"title": "A Veteran's Routine", "description": "A veteran player talks you through a steadier tournament routine.", "accent": PALETTE.ACTION_CONFIRM}
		"money":
			return {"title": "Help Run a Side Event", "description": "You help run a quick side event and receive a small organizer's fee.", "accent": PALETTE.STATE_REWARD}
		"steal_money":
			return {"title": "A Distracted Crowd", "description": "The crowd passes. When it clears, some of your cash is gone.", "accent": PALETTE.ACTION_DANGER}
		"remove_card":
			return {"title": "Deck Check", "description": "The venue's deck check rejects one card. You must remove a card before continuing.", "accent": PALETTE.ACTION_DANGER}
		"upgrade_card":
			return {"title": "A Risky Tune-Up", "description": "A street-table expert offers to tune one card, but the rushed lesson costs you %d life." % route_run_service.EVENT_UPGRADE_DAMAGE, "accent": PALETTE.ACTION_SPECIAL}
		"trade_card":
			return {"title": "A Friendly Trade", "description": "Another player offers a one-for-one card trade.", "accent": PALETTE.ELECTRIC_CYAN}
		_:
			return {"title": "An Unexpected Stop", "description": "The route has an unexpected turn.", "accent": PALETTE.ACTION_SPECIAL}


func _add_route_event_button(parent: Node, text_value: String, outcome: String, card_id: String = "") -> void:
	var variant := "secondary"
	if outcome in ["heal", "max_life"]:
		variant = "confirm"
	elif outcome == "money":
		variant = "warning"
	elif outcome in ["steal_money", "remove_card"]:
		variant = "danger"
	elif outcome == "upgrade_card":
		variant = "special"
	var button := TOPDECK_UI_SCRIPT.make_button(
		text_value,
		variant,
		Vector2(0, 48),
		"RouteEvent_%s%s" % [outcome, "_%s" % card_id if not card_id.is_empty() else ""]
	)
	_connect_pressed(button, _resolve_route_event.bind(outcome, card_id))
	parent.add_child(button)


func _resolve_route_event(choice: String, card_id: String = "", replacement_card_id: String = "") -> void:
	var result: Dictionary = route_run_service.resolve_event(
		run,
		choice,
		card_id,
		MIN_MAIN_DECK_SIZE,
		replacement_card_id
	)
	if not bool(result.get("ok", false)):
		_set_footer(String(result.get("message", "That event could not be resolved.")))
		_show_route_event()
		return
	var node: Dictionary = run.get("pending_route_node", {})
	node.event_resolved = true
	run.pending_route_node = node
	_set_footer(String(result.get("message", "Event resolved.")))
	if choice == "upgrade_card" and not card_id.is_empty():
		for button_node in find_children("RouteEvent_*", "Button", true, false):
			(button_node as Button).disabled = true
		await _play_route_card_upgrade_reveal(card_id)
	elif choice == "trade_card" and not card_id.is_empty() and not replacement_card_id.is_empty():
		for button_node in find_children("RouteEvent_*", "Button", true, false):
			(button_node as Button).disabled = true
		await _play_route_trade_animation()
	if bool(result.get("run_over", false)):
		run.run_over = true
		run.last_result = ["The risky card upgrade left you with no life."]
	_complete_route_node()


func _play_route_trade_animation() -> void:
	last_route_trade_animation_stages = ["cross", "receive"]
	var outgoing := find_child("RouteTradeOutgoingCardFace", true, false) as Control
	var incoming := find_child("RouteTradeIncomingCardFace", true, false) as Control
	var arrows := find_child("RouteTradeArrows", true, false) as TextureRect
	var outgoing_label := find_child("RouteTradeOutgoingLabel", true, false) as Label
	var incoming_label := find_child("RouteTradeIncomingLabel", true, false) as Label
	var status_label := find_child("RouteTradeStatus", true, false) as Label
	if outgoing == null or incoming == null:
		return
	outgoing.z_index = 4
	incoming.z_index = 5
	if _reduced_motion_enabled() or _running_automated_test():
		outgoing.modulate.a = 0.0
		incoming.scale = Vector2(1.04, 1.04)
		await get_tree().process_frame
		incoming.scale = Vector2.ONE
		return

	var travel_distance := 285.0
	var cross_tween := create_tween().set_parallel(true)
	cross_tween.tween_property(outgoing, "position:x", outgoing.position.x + travel_distance, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cross_tween.tween_property(outgoing, "rotation", deg_to_rad(8.0), 0.42).set_trans(Tween.TRANS_SINE)
	cross_tween.tween_property(outgoing, "modulate:a", 0.0, 0.22).set_delay(0.16)
	cross_tween.tween_property(incoming, "position:x", incoming.position.x - travel_distance, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cross_tween.tween_property(incoming, "rotation", deg_to_rad(-5.0), 0.3).set_trans(Tween.TRANS_SINE)
	cross_tween.tween_property(incoming, "scale", Vector2(1.08, 1.08), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if arrows != null:
		arrows.pivot_offset = arrows.size * 0.5
		cross_tween.tween_property(arrows, "scale", Vector2(1.25, 1.25), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		cross_tween.tween_property(arrows, "modulate", PALETTE.EMERALD, 0.32)
	await cross_tween.finished
	if outgoing_label != null:
		outgoing_label.text = "RECEIVED"
		outgoing_label.add_theme_color_override("font_color", PALETTE.EMERALD)
	if incoming_label != null:
		incoming_label.text = ""
	if status_label != null:
		status_label.text = ""
	if arrows != null:
		arrows.modulate.a = 0.0
	var receive_tween := create_tween().set_parallel(true)
	receive_tween.tween_property(incoming, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	receive_tween.tween_property(incoming, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await receive_tween.finished
	# Let the received card land long enough to read before returning to town.
	await get_tree().create_timer(0.28).timeout


func _complete_route_node() -> void:
	_clear_route_reward_overlay()
	var node: Dictionary = run.get("pending_route_node", {})
	var node_id := String(node.get("id", ""))
	var node_type := String(node.get("type", ""))
	if bool(node.get("town_optional_shop", false)):
		run.town_start_shop = node.duplicate(true)
		run.pending_route_node = {}
		_clear_kitchen_match_state()
		_autosave_now("route_map")
		_show_run_map()
		return
	if node_id != "" and not run.route_resolved.has(node_id):
		run.route_resolved.append(node_id)
	run.pending_route_node = {}
	run.route_battle = {}
	run.reward_offer = []
	_clear_kitchen_match_state()
	if bool(run.get("run_over", false)):
		_autosave_now("route_game_over")
		_show_route_game_over()
		return
	if node_type == "final_boss":
		run.demo_complete = true
		run.run_over = true
		run.last_result = ["Starter City Champion defeated.", "Cloud City waits beyond the bridge."]
		_autosave_now("route_victory")
		_show_route_victory()
		return
	_autosave_now("route_map")
	_show_run_map()


func _show_route_game_over() -> void:
	current_screen = "route_game_over"
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	var shell_parts := TOPDECK_UI_SCRIPT.make_encounter_shell(
		"RouteGameOver",
		"Run Ended",
		"Run Over",
		String(run.get("last_result", ["Your run ended."])[0]),
		PALETTE.ACTION_DANGER,
		"STOPS %d  •  FINAL DECK %d CARDS" % [run.get("route_resolved", []).size() - 1, _deck_total(run.deck)],
		_route_node_icon("event"),
		"RouteGameOverArtwork"
	)
	content.add_child(shell_parts.panel)
	(shell_parts.content as VBoxContainer).add_child(
		TOPDECK_UI_SCRIPT.make_label("Starter City will generate a fresh route when you begin again.", "body", PALETTE.TEXT_SECONDARY)
	)
	var again := TOPDECK_UI_SCRIPT.make_button("Start a New Run", "primary", Vector2(240, 52), "RouteGameOverAgainButton")
	_connect_pressed(again, _show_season_run_setup)
	(shell_parts.actions as HBoxContainer).add_child(again)
	var title := TOPDECK_UI_SCRIPT.make_button("Return to Title", "secondary", Vector2(220, 52), "RouteGameOverTitleButton")
	_connect_pressed(title, _show_start)
	(shell_parts.actions as HBoxContainer).add_child(title)


func _show_route_victory() -> void:
	current_screen = "route_victory"
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	var starter_id := String(run.get("starter", "spicy"))
	var victory_art: Texture2D = STARTER_VICTORY_POSES.get(starter_id, _route_node_icon("final_boss"))
	var shell_parts := TOPDECK_UI_SCRIPT.make_encounter_shell(
		"RouteDemoComplete",
		"Starter City Complete",
		"Thanks for Playing!",
		"You started at a folding table and made it across Starter City. Beyond the championship bridge, Cloud City is waiting.",
		PALETTE.STATE_REWARD,
		"STARTER CITY CHAMPION",
		victory_art,
		"RouteVictoryArtwork"
	)
	var panel := shell_parts.panel as PanelContainer
	panel.name = "RouteDemoComplete"
	content.add_child(panel)
	var encounter_body := shell_parts.content as VBoxContainer
	var stats := HBoxContainer.new()
	stats.name = "RouteVictoryStats"
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	encounter_body.add_child(stats)
	_add_route_victory_stat(stats, "STOPS CLEARED", str(maxi(0, run.get("route_resolved", []).size() - 1)), PALETTE.ACTION_SPECIAL)
	_add_route_victory_stat(stats, "LIFE LEFT", "%d/%d" % [int(run.life), int(run.max_life)], PALETTE.ACTION_CONFIRM)
	_add_route_victory_stat(stats, "FINAL DECK", "%d CARDS" % _deck_total(run.deck), PALETTE.FOCUS_EDGE)
	_add_route_victory_stat(stats, "CASH", "$%d" % int(run.money), PALETTE.STATE_REWARD)
	var links := HBoxContainer.new()
	links.name = "RouteVictoryLinks"
	links.add_theme_constant_override("separation", 10)
	encounter_body.add_child(links)
	var discord := TOPDECK_UI_SCRIPT.make_button("Join the Discord", "primary", Vector2(0, 52), "RouteVictoryDiscordButton")
	discord.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_external_link(discord, DISCORD_INVITE_URL)
	links.add_child(discord)
	if not STEAM_STORE_URL.is_empty():
		var steam := TOPDECK_UI_SCRIPT.make_button("Wishlist on Steam", "warning", Vector2(0, 52), "RouteVictorySteamButton")
		steam.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_connect_external_link(steam, STEAM_STORE_URL)
		links.add_child(steam)
	var actions := HBoxContainer.new()
	actions.name = "RouteVictoryActions"
	actions.add_theme_constant_override("separation", 10)
	encounter_body.add_child(actions)
	var deck_button := TOPDECK_UI_SCRIPT.make_button("Review Winning Deck", "special", Vector2(0, 48), "RouteVictoryDeckButton")
	_connect_pressed(deck_button, _show_deckbuilder)
	deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(deck_button)
	var again := TOPDECK_UI_SCRIPT.make_button("Start Another Run", "primary", Vector2(0, 48), "RouteVictoryAgainButton")
	_connect_pressed(again, _show_season_run_setup)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(again)
	var title := TOPDECK_UI_SCRIPT.make_button("Return to Title", "secondary", Vector2(0, 48), "RouteVictoryTitleButton")
	_connect_pressed(title, _show_start)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(title)


func _add_route_victory_stat(parent: Node, label_text: String, value_text: String, accent: Color) -> void:
	var parts := TOPDECK_UI_SCRIPT.make_section("", accent, Vector2(160, 92))
	var stat := parts.panel as PanelContainer
	stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stat)
	var copy := parts.body as VBoxContainer
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	var value := TOPDECK_UI_SCRIPT.make_label(value_text, "section", PALETTE.TEXT_PRIMARY)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(value)
	var caption := TOPDECK_UI_SCRIPT.make_label(label_text, "small", PALETTE.TEXT_SECONDARY)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(caption)


func _show_season_run() -> void:
	if String(run.get("run_loop", "")) == "route":
		_show_run_map()
		return
	if current_screen == "shop":
		_cache_active_shop_overworld()
	season_hub_screen.show(self)


func _show_shop() -> void:
	# Leaving an untouched sealed pack keeps it available for later. Once the
	# wrapper has been opened, returning to the store finalizes the pack just as
	# the Done button does, including safely collecting any face-down cards.
	if current_screen == "packs" and bool(run.get("pack_opened", false)):
		shop_economy_service.reveal_all_cards(run, _current_primary_archetype())
		_finish_pack_state()
	if String(run.get("run_loop", "")) == "route":
		_show_run_map()
	elif _run_mode() == "season":
		_show_shop_overworld()
	else:
		card_shop_screen.show(self)
		_play_card_shop_music()


func _show_shop_overworld() -> void:
	if _guard_run_over():
		return
	_cache_active_shop_overworld()
	current_screen = "shop"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Your next round is waiting. Stock up, tune your deck, or talk to the clerk.")

	var shop_world := cached_shop_overworld
	if not is_instance_valid(shop_world):
		shop_world = _instantiate_scene(GREYBOX_CAMERA_DEMO_SCENE_PATH) as Control
		shop_world.name = "CardShopOverworld"
		shop_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shop_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
		shop_world.connect("single_purchase_requested", _buy_single_from_overworld)
		shop_world.connect("trade_extras_requested", _trade_extra_copies_from_overworld)
		shop_world.connect("packs_requested", _show_packs)
		shop_world.connect("tournament_requested", _on_shop_tournament_requested)
		shop_world.connect("deck_requested", _show_deckbuilder)
		shop_world.connect("calendar_requested", _show_season_run)
		shop_world.connect("save_requested", _save_run)
		shop_world.connect("settings_requested", _show_settings)
		shop_world.connect("exit_requested", _show_start)
		cached_shop_overworld = shop_world
	if shop_world.get_parent() != null:
		shop_world.reparent(content)
	else:
		content.add_child(shop_world)
	shop_world.visible = true
	shop_world.process_mode = Node.PROCESS_MODE_INHERIT
	if bool(shop_world.get_meta("shop_configured", false)):
		shop_world.call("update_shop_context", _shop_overworld_context(false))
		shop_world.call("restore_menu_view", cached_shop_menu_view)
	else:
		shop_world.call("configure_shop", _shop_overworld_context())
		shop_world.set_meta("shop_configured", true)
	_play_card_shop_music()


func _cache_active_shop_overworld() -> void:
	var shop_world := content.find_child("CardShopOverworld", true, false) as Control if content != null else null
	if shop_world == null:
		return
	if shop_world.has_method("current_menu_view"):
		cached_shop_menu_view = String(shop_world.call("current_menu_view"))
	content.remove_child(shop_world)
	add_child(shop_world)
	shop_world.visible = false
	shop_world.process_mode = Node.PROCESS_MODE_DISABLED
	cached_shop_overworld = shop_world


func _dispose_cached_shop_overworld() -> void:
	if not is_instance_valid(cached_shop_overworld):
		cached_shop_overworld = null
		cached_shop_menu_view = "overview"
		return
	if cached_shop_overworld.get_parent() != content:
		cached_shop_overworld.queue_free()
	cached_shop_overworld = null
	cached_shop_menu_view = "overview"


func _shop_overworld_context(include_set_entries: bool = true) -> Dictionary:
	var active: Dictionary = run.get("active_tournament", {})
	var booster_price := 0
	if boosters_by_id.has(BASE_BOOSTER_ID):
		booster_price = int(boosters_by_id[BASE_BOOSTER_ID].get("price", 0))
	var context := {
		"money": int(run.get("money", 0)),
		"prize_packs": int(run.get("prize_packs", 0)),
		"booster_price": booster_price,
		"pack_needs_attention": _current_pack_needs_attention(),
		"event_name": String(_selected_season_event().get("name", "Weekly Locals")),
		"difficulty_name": String(_difficulty_data(_run_difficulty_id()).get("name", "Black")),
		"tournament_active": _season_tournament_active(),
		"tournament_round": int(active.get("round", 1)),
		"singles": _shop_overworld_single_entries(),
		"trade_entries": _shop_overworld_trade_entries(),
		"meta_entries": _shop_overworld_meta_entries(),
		"reports": run.get("reports", []).duplicate(true)
	}
	if include_set_entries:
		context.set_entries = _shop_overworld_set_entries()
	return context


func _on_shop_tournament_requested() -> void:
	if _season_tournament_active() and run.get("kitchen_match_result", {}).is_empty():
		_start_season_tournament_round()
		return
	var event: Dictionary = _selected_season_event()
	var event_id := String(event.get("id", _selected_season_event_id()))
	var legal: Dictionary = _deck_is_legal()
	var can_enter := (
		bool(legal.get("ok", false))
		and _season_event_selectable(event_id)
	)
	if can_enter:
		_start_season_tournament()
		return
	_show_tournament()


func _shop_overworld_single_entries() -> Array:
	var entries: Array = []
	for card_id_value in run.get("shop", []):
		var card_id := String(card_id_value)
		if not cards_by_id.has(card_id):
			continue
		var card: Dictionary = cards_by_id[card_id]
		entries.append({
			"id": card_id,
			"name": _card_display_name(card),
			"card": card.duplicate(true),
			"difficulty": _run_difficulty_id(),
			"descriptor": _card_descriptor(card),
			"rarity": String(card.get("rarity", "common")),
			"text": String(card.get("text", "")),
			"price": _card_price(card_id),
			"owned": _owned_count(card_id),
			"deck": _deck_count(card_id)
		})
	return entries


func _shop_overworld_set_entries() -> Array:
	var grouped_cards := {}
	for card_value in cards:
		var card: Dictionary = card_value
		var expansion_id := String(card.get("expansion_id", "core"))
		if not grouped_cards.has(expansion_id):
			grouped_cards[expansion_id] = []
		grouped_cards[expansion_id].append({
			"id": String(card.get("id", "")),
			"name": _card_display_name(card),
			"sort_name": String(card.get("name", "")),
			"card": card.duplicate(true),
			"difficulty": _run_difficulty_id(),
			"card_type": String(card.get("card_type", "card")),
			"affinity": _card_archetype(card),
			"rarity": String(card.get("rarity", "common")),
		})

	var ordered_expansions: Array = expansions.duplicate(true)
	for expansion_id_value in grouped_cards.keys():
		var expansion_id := String(expansion_id_value)
		if expansions_by_id.has(expansion_id):
			continue
		ordered_expansions.append({
			"id": expansion_id,
			"name": expansion_id.replace("_", " ").capitalize(),
			"code": expansion_id.to_upper(),
			"release_order": 9999,
		})
	ordered_expansions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_order := int(a.get("release_order", 0))
		var b_order := int(b.get("release_order", 0))
		if a_order == b_order:
			return String(a.get("name", "")) < String(b.get("name", ""))
		return a_order < b_order
	)

	var set_entries: Array = []
	for expansion_value in ordered_expansions:
		var expansion: Dictionary = expansion_value
		var expansion_id := String(expansion.get("id", ""))
		var expansion_cards: Array = grouped_cards.get(expansion_id, [])
		if expansion_cards.is_empty():
			continue
		expansion_cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_affinity := String(a.get("affinity", "neutral"))
			var b_affinity := String(b.get("affinity", "neutral"))
			var a_affinity_rank := SET_LIST_AFFINITY_ORDER.find(a_affinity)
			var b_affinity_rank := SET_LIST_AFFINITY_ORDER.find(b_affinity)
			if a_affinity_rank < 0:
				a_affinity_rank = SET_LIST_AFFINITY_ORDER.size()
			if b_affinity_rank < 0:
				b_affinity_rank = SET_LIST_AFFINITY_ORDER.size()
			if a_affinity_rank != b_affinity_rank:
				return a_affinity_rank < b_affinity_rank
			if a_affinity != b_affinity:
				return a_affinity.naturalnocasecmp_to(b_affinity) < 0

			var a_type := String(a.get("card_type", "card"))
			var b_type := String(b.get("card_type", "card"))
			var a_type_rank := SET_LIST_CARD_TYPE_ORDER.find(a_type)
			var b_type_rank := SET_LIST_CARD_TYPE_ORDER.find(b_type)
			if a_type_rank < 0:
				a_type_rank = SET_LIST_CARD_TYPE_ORDER.size()
			if b_type_rank < 0:
				b_type_rank = SET_LIST_CARD_TYPE_ORDER.size()
			if a_type_rank != b_type_rank:
				return a_type_rank < b_type_rank
			if a_type != b_type:
				return a_type.naturalnocasecmp_to(b_type) < 0

			var name_order := String(a.get("sort_name", a.get("name", ""))).naturalnocasecmp_to(
				String(b.get("sort_name", b.get("name", "")))
			)
			if name_order == 0:
				return String(a.get("id", "")) < String(b.get("id", ""))
			return name_order < 0
		)
		set_entries.append({
			"id": expansion_id,
			"name": String(expansion.get("name", expansion_id)),
			"code": String(expansion.get("code", expansion_id.to_upper())),
			"release_order": int(expansion.get("release_order", 0)),
			"cards": expansion_cards,
		})
	return set_entries


func _buy_single_from_overworld(card_id: String) -> void:
	var result: Dictionary = shop_economy_service.buy_single(run, card_id)
	var message := String(result.get("message", "Could not buy that card."))
	_set_footer(message)
	_update_status()
	var shop_world := content.find_child("CardShopOverworld", true, false)
	if shop_world != null:
		shop_world.call("update_shop_context", _shop_overworld_context(false), message)


func _shop_overworld_trade_entries() -> Array:
	var entries: Array = []
	for card_id_value in run.get("collection", {}).keys():
		var card_id := String(card_id_value)
		if not cards_by_id.has(card_id):
			continue
		var owned := _owned_count(card_id)
		var in_use := _deck_count(card_id) + _sideboard_count(card_id)
		var keep := in_use
		var copies: int = owned - keep
		if copies <= 0:
			continue
		var per_copy: int = max(1, int(floor(float(cards_by_id[card_id].get("value", 1)) * 0.45)))
		entries.append({
			"id": card_id,
			"name": _card_display_name(cards_by_id[card_id]),
			"copies": copies,
			"total_value": copies * per_copy
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("name", "")) < String(b.get("name", "")))
	return entries


func _shop_overworld_meta_entries() -> Array:
	var entries: Array = []
	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		entries.append({
			"id": archetype_id,
			"name": String(archetype.get("name", archetype_id)),
			"share": int(round(float(run.get("meta", {}).get(archetype_id, 0.0)) * 100.0)),
			"summary": String(archetype.get("summary", ""))
		})
	return entries


func _trade_extra_copies_from_overworld() -> void:
	var total: int = run_state_service.sell_extra_copies(run)
	var message := "Traded extra copies for $%d." % total if total > 0 else "No safe extra copies to trade."
	_set_footer(message)
	_update_status()
	var shop_world := content.find_child("CardShopOverworld", true, false)
	if shop_world != null:
		shop_world.call("update_shop_context", _shop_overworld_context(false), message, "trade")


func _show_singles_shop() -> void:
	card_shop_screen.show_singles(self)


func _show_trading_station() -> void:
	if _guard_run_over():
		return
	current_screen = "trading"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Trade safe extra copies for cash, then exit back to the card store.")

	var panel := _add_panel(content, "Trading Table", "#2b263b")
	_add_body_text(panel, "Two local players are comparing binders. They will buy unassigned copies without removing cards used by your deck or sideboard.")
	var sell_button := _make_button("Trade Extra Copies")
	sell_button.name = "TradeExtraCopiesButton"
	_style_button(sell_button, "action")
	_connect_pressed(sell_button, _sell_extra_copies)
	panel.add_child(sell_button)
	_add_exit_to_store_button(panel)


func _add_exit_to_store_button(parent: Node) -> Button:
	var exit_button := _make_button("Exit to Card Store")
	exit_button.name = "ExitToCardStoreButton"
	_connect_pressed(exit_button, _show_shop)
	parent.add_child(exit_button)
	return exit_button


func _show_card_shop_scene_test() -> void:
	card_shop_screen.show_scene_test(self)


func _show_card_effect_lab() -> void:
	if _guard_run_over():
		return
	card_effect_lab.show(self)


func _show_packs() -> void:
	if _run_mode() == "season":
		var shop_world := content.find_child("CardShopOverworld", true, false) as Control
		if shop_world == null:
			_show_shop_overworld()
			shop_world = content.find_child("CardShopOverworld", true, false) as Control
		if shop_world != null:
			pack_opening_screen.show_in_shop_overlay(self, shop_world)
			return
	pack_opening_screen.show(self)


func _buy_and_open_pack() -> void:
	var result: Dictionary = shop_economy_service.buy_and_open_pack(run, BASE_BOOSTER_ID, _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _open_prize_pack() -> void:
	var result: Dictionary = shop_economy_service.open_prize_pack(run, PRIZE_BOOSTER_ID, _strongest_pack_affinity())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _start_pack(pack: Array) -> void:
	shop_economy_service.start_pack(run, pack)


func _generate_pack(booster_id: String) -> Array:
	var affinity := _strongest_pack_affinity() if booster_id == PRIZE_BOOSTER_ID else _current_primary_archetype()
	return shop_economy_service.generate_pack(booster_id, affinity)


func _pick_card_by_rarity(rarity: String) -> String:
	return shop_economy_service.pick_card_by_rarity(rarity, _current_primary_archetype())


func _rarity_rank(rarity: String) -> int:
	return shop_economy_service.rarity_rank(rarity)


func _reveal_next_card() -> void:
	shop_economy_service.reveal_next_card(run, _current_primary_archetype())
	_show_packs()


func _reveal_pack_card(pack_index: int) -> void:
	shop_economy_service.reveal_pack_card(run, pack_index, _current_primary_archetype())
	_show_packs()


func _reveal_all_cards() -> void:
	shop_economy_service.reveal_all_cards(run, _current_primary_archetype())
	_show_packs()


func _card_matches_current_deck(card_id: String) -> bool:
	return shop_economy_service.card_matches_current_deck(card_id, _current_primary_archetype())


func _buy_single(card_id: String) -> void:
	var result: Dictionary = shop_economy_service.buy_single(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_singles_shop()


func _sell_extra_copies() -> void:
	var total: int = run_state_service.sell_extra_copies(run)
	if total > 0:
		_set_footer("Sold extra copies for $%d." % total)
	else:
		_set_footer("No safe extra copies to sell.")
	if _run_mode() == "season":
		_show_trading_station()
	else:
		_show_shop()


func _generate_shop_inventory() -> void:
	shop_economy_service.generate_shop_inventory(run, _current_primary_archetype())


func _pick_shop_card(rarity: String, primary: String, excluded: Array) -> String:
	return shop_economy_service.pick_shop_card(rarity, primary, excluded)


func _card_price(card_id: String) -> int:
	return shop_economy_service.card_price(run, card_id)


func _current_primary_archetype() -> String:
	if run.is_empty():
		return String(ARCHETYPE_ORDER[0])
	# Rewards, packs, and shop offers are keyed to the starter identity, rather
	# than the deck's current majority, so a run cannot discover a fourth color.
	var starter := String(run.get("starter", ""))
	if starter in ["spicy", "sweet", "hearty"]:
		return starter
	return String(_calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {})).primary)


func _strongest_pack_affinity() -> String:
	if run.is_empty():
		return String(PACK_AFFINITY_ORDER[0])
	var starter := String(run.get("starter", ""))
	if starter in ["spicy", "sweet", "hearty"]:
		return starter
	return shop_economy_service.strongest_affinity_for_deck(run.get("deck", {}), PACK_AFFINITY_ORDER)


func _show_deckbuilder() -> void:
	var rebuilding_deckbuilder := current_screen == "deck"
	if rebuilding_deckbuilder:
		_capture_deckbuilder_scroll_positions()
	else:
		deckbuilder_scroll_positions.clear()
	if current_screen != "deck":
		deckbuilder_return_screen = current_screen
		deckbuilder_return_shop_view = ""
		if current_screen == "shop":
			var shop_world := content.find_child("CardShopOverworld", true, false)
			if shop_world != null and shop_world.has_method("current_menu_view"):
				deckbuilder_return_shop_view = String(shop_world.call("current_menu_view"))
	if current_screen == "shop":
		_cache_active_shop_overworld()
	deckbuilder_screen.show(self)
	if rebuilding_deckbuilder:
		_restore_deckbuilder_scroll_positions()


func _capture_deckbuilder_scroll_positions() -> void:
	deckbuilder_scroll_positions.clear()
	for scroll_name in ["DeckbuilderMainDeckScroll"]:
		var deck_scroll := content.find_child(scroll_name, true, false) as ScrollContainer
		if deck_scroll != null:
			deckbuilder_scroll_positions[scroll_name] = deck_scroll.scroll_vertical


func _restore_deckbuilder_scroll_positions() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if current_screen != "deck":
		return
	for scroll_name in deckbuilder_scroll_positions:
		var deck_scroll := content.find_child(String(scroll_name), true, false) as ScrollContainer
		if deck_scroll != null:
			deck_scroll.scroll_vertical = int(deckbuilder_scroll_positions[scroll_name])


func _add_deckbuilder_back_button(parent: Node) -> Button:
	var back_button := _make_button("Back")
	back_button.name = "DeckbuilderBackButton"
	_connect_pressed(back_button, _return_from_deckbuilder)
	parent.add_child(back_button)
	return back_button


func _return_from_deckbuilder() -> void:
	var return_screen := deckbuilder_return_screen
	var return_shop_view := deckbuilder_return_shop_view
	deckbuilder_return_screen = ""
	deckbuilder_return_shop_view = ""
	match return_screen:
		"start":
			_show_start()
		"new_game":
			_show_new_game_menu()
		"path_choice":
			_show_run_path_choice()
		"season":
			_show_season_run()
		"route_map":
			_show_run_map()
		"route_shop":
			_show_route_shop()
		"route_event":
			_show_route_event()
		"route_reward":
			_show_route_card_reward()
		"route_victory":
			_show_route_victory()
		"shop":
			_show_shop()
			if return_shop_view != "":
				var shop_world := content.find_child("CardShopOverworld", true, false)
				if shop_world != null and shop_world.has_method("restore_menu_view"):
					shop_world.call("restore_menu_view", return_shop_view)
		"singles":
			_show_singles_shop()
		"trading":
			_show_trading_station()
		"packs":
			_show_packs()
		"tournament":
			_show_tournament()
		"result":
			var summary: Dictionary = run.get("last_event_result", {})
			_show_tournament_result(run.get("last_result", []), bool(summary.get("run_continues", true)))
		"thanks":
			_show_thanks_for_playing()
		"meta":
			_show_meta()
		"camera_demo":
			_show_greybox_camera_demo()
		"card_lab":
			_show_card_effect_lab()
		_:
			if _run_mode() == "season":
				_show_season_run()
			else:
				_show_run_path_choice()


func _show_greybox_camera_demo() -> void:
	if _guard_run_over():
		return
	current_screen = "camera_demo"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Graybox camera proof of concept: use the shot buttons or press 1, 2, and 3.")
	var demo := _instantiate_scene(GREYBOX_CAMERA_DEMO_SCENE_PATH) as Control
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	demo.connect("exit_requested", _show_shop)
	content.add_child(demo)


func _show_tabletop_3d_prototype() -> void:
	_start_debug_3d_arena()


func _add_to_deck(card_id: String) -> void:
	var result: Dictionary = run_state_service.add_to_deck(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_show_deckbuilder()


func _remove_from_deck(card_id: String) -> void:
	if run_state_service.remove_from_deck(run, card_id):
		_show_deckbuilder()


func _add_to_sideboard(card_id: String) -> void:
	var result: Dictionary = run_state_service.add_to_sideboard(run, card_id)
	if not result.ok:
		_set_footer(result.message)
		return
	_show_deckbuilder()


func _remove_from_sideboard(card_id: String) -> void:
	if run_state_service.remove_from_sideboard(run, card_id):
		_show_deckbuilder()



func _start_debug_kitchen_match(resume_snapshot: Dictionary = {}) -> void:
	if _guard_run_over():
		return
	var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
	var opponent_archetype := _predator_archetype(String(metrics.get("primary", ARCHETYPE_ORDER[0])))
	var opponent_deck := _opponent_deck_for_round(opponent_archetype, 1)
	var seed_value := rng.randi()
	if not resume_snapshot.is_empty():
		seed_value = int(run.get("kitchen_match", {}).get("seed", seed_value))
	_begin_kitchen_match(
		run.get("deck", {}),
		opponent_deck,
		"Practice %s Chef" % _archetype_label(opponent_archetype),
		false,
		seed_value,
		String(run.get("kitchen_match", {}).get("first_side", "player")),
		String(run.get("kitchen_match", {}).get("ai_difficulty", "easy")),
		resume_snapshot
	)


func _start_debug_3d_arena() -> void:
	if _guard_run_over():
		return
	_set_footer("Opened a production-configured Living Table practice match using your current deck.")
	var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
	var opponent_archetype := _predator_archetype(String(metrics.get("primary", ARCHETYPE_ORDER[0])))
	var opponent_deck := _opponent_deck_for_round(opponent_archetype, 1)
	_begin_kitchen_match(
		run.get("deck", {}),
		opponent_deck,
		"3D Practice %s Chef" % _archetype_label(opponent_archetype),
		false,
		rng.randi(),
		"player",
		"easy"
	)


func _begin_kitchen_match(player_deck: Dictionary, opponent_deck: Dictionary, opponent_name: String, tournament_round: bool, seed_value: int, first_side: String = "player", ai_difficulty: String = "easy", resume_snapshot: Dictionary = {}, match_rules: Dictionary = {}) -> void:
	_dismiss_round_result_popup()
	current_screen = "kitchen_match"
	_render_nav()
	_clear(content)
	_update_status()
	var metrics := _calculate_deck_metrics(player_deck, {})
	var opponent_metrics := _calculate_deck_metrics(opponent_deck, {})
	var player_name := String(archetypes_by_id.get(String(metrics.get("primary", ARCHETYPE_ORDER[0])), {}).get("name", "Your Kitchen"))
	var kitchen_game = _instantiate_scene(TABLETOP_3D_PROTOTYPE_SCENE_PATH)
	var active: Dictionary = run.get("active_tournament", {})
	var configured_player_deck := player_deck.duplicate(true)
	var configured_match_rules := match_rules.duplicate(true)
	var match_context := {
		"tournament_round": tournament_round,
		"player_starter": String(run.get("starter", metrics.get("primary", ""))),
		"opponent_affinity": String(opponent_metrics.get("primary", "neutral")),
		"event_id": String(active.get("event_id", "")) if tournament_round else "",
		"event_name": String(active.get("event_name", "Tournament")) if tournament_round else "Practice Match",
		"round": int(active.get("round", 0)) if tournament_round else 0,
		"rounds": int(active.get("rounds", 0)) if tournament_round else 0
	}
	var route_battle: Dictionary = run.get("route_battle", {})
	if bool(route_battle.get("active", false)):
		var prepared_deck: Dictionary = route_run_service.prepare_player_combat_deck(run, player_deck)
		configured_player_deck = prepared_deck.get("deck", player_deck).duplicate(true)
		configured_match_rules.custom_cards = prepared_deck.get("cards", {}).duplicate(true)
		match_context = {
			"route_encounter": true,
			"player_starter": String(run.get("starter", metrics.get("primary", ""))),
			"opponent_affinity": String(route_battle.get("opponent_affinity", "neutral")),
			"rival_portrait_id": String(route_battle.get("rival_portrait_id", "npc1")),
			"node_id": String(route_battle.get("node_id", "")),
			"node_type": String(route_battle.get("node_type", "enemy")),
			"event_name": String(route_battle.get("label", "Starter City Rival")),
			"location": String(route_battle.get("location", "Starter City Table")),
		}
	kitchen_game.configure_match(
		configured_player_deck,
		opponent_deck,
		player_name,
		opponent_name,
		seed_value,
		first_side,
		"Forfeit / Return to Tournament" if tournament_round else "Exit Practice Match",
		ai_difficulty,
		_run_difficulty_id(),
		match_context,
		configured_match_rules
	)
	kitchen_game.configure_battle_preferences(
		String(player_settings.play_speed),
		float(player_settings.battle_text_scale),
		bool(player_settings.reduced_motion),
		bool(player_settings.show_board_info)
	)
	if not resume_snapshot.is_empty() and kitchen_game.has_method("configure_resume_snapshot"):
		kitchen_game.call("configure_resume_snapshot", resume_snapshot)
	kitchen_game.custom_minimum_size = Vector2(0, 820)
	kitchen_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kitchen_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kitchen_game.match_finished.connect(_on_kitchen_match_finished)
	kitchen_game.exit_requested.connect(_on_kitchen_exit_requested)
	kitchen_game.settings_requested.connect(func() -> void: _show_settings_from_tabletop(kitchen_game))
	kitchen_game.battle_preferences_changed.connect(_on_battle_preferences_changed)
	var match_checkpoint := {
		"active": true,
		"complete": false,
		"tournament_round": tournament_round,
		"seed": seed_value,
		"opponent_name": opponent_name,
		"ai_difficulty": ai_difficulty,
		"first_side": first_side,
		"presentation": "living_table",
		"match_context": match_context
	}
	if not resume_snapshot.is_empty():
		match_checkpoint["snapshot"] = resume_snapshot.duplicate(true)
	run.kitchen_match = match_checkpoint
	run.kitchen_match_result = {"game_over": false}
	content.add_child(kitchen_game)


func _capture_live_kitchen_match_state() -> void:
	if run.is_empty():
		return
	var tabletop: Node = suspended_tabletop if is_instance_valid(suspended_tabletop) else find_child("Tabletop3DPrototype", true, false)
	if tabletop == null or not tabletop.has_method("capture_match_snapshot"):
		return
	var snapshot: Variant = tabletop.call("capture_match_snapshot")
	if not (snapshot is Dictionary) or (snapshot as Dictionary).is_empty():
		return
	var match_checkpoint: Dictionary = run.get("kitchen_match", {}).duplicate(true)
	match_checkpoint["snapshot"] = (snapshot as Dictionary).duplicate(true)
	run.kitchen_match = match_checkpoint


func _show_settings_from_tabletop(tabletop: Control) -> void:
	if not is_instance_valid(tabletop) or current_screen not in ["kitchen_match", "tutorial"]:
		return
	suspended_tabletop = tabletop
	suspended_tabletop_screen = current_screen
	tabletop.reparent(self)
	tabletop.visible = false
	tabletop.process_mode = Node.PROCESS_MODE_DISABLED
	settings_active_category = "battle"
	_show_settings()


func _on_battle_preferences_changed(play_speed_id: String, battle_text_scale: float) -> void:
	player_settings.play_speed = play_speed_id
	player_settings.battle_text_scale = battle_text_scale
	_sanitize_player_settings()
	_save_player_settings()


func _restore_tabletop_after_settings() -> void:
	if not is_instance_valid(suspended_tabletop):
		if settings_return_screen == "tutorial":
			_show_tutorial()
		else:
			_resume_kitchen_match()
		return
	current_screen = suspended_tabletop_screen
	_apply_screen_chrome()
	_render_nav()
	_clear(content)
	_update_status()
	var tabletop := suspended_tabletop
	suspended_tabletop = null
	suspended_tabletop_screen = ""
	if tabletop.has_method("configure_battle_preferences"):
		tabletop.call(
			"configure_battle_preferences",
			String(player_settings.play_speed),
			float(player_settings.battle_text_scale),
			bool(player_settings.reduced_motion),
			bool(player_settings.show_board_info)
		)
	tabletop.reparent(content)
	tabletop.visible = true
	tabletop.process_mode = Node.PROCESS_MODE_INHERIT


func _resume_kitchen_match() -> void:
	if bool(run.get("route_battle", {}).get("active", false)):
		_start_route_battle(true)
	elif _season_tournament_active():
		_start_season_tournament_round()
	else:
		_start_debug_kitchen_match()


func _on_kitchen_match_finished(result: Dictionary) -> void:
	var match_state: Dictionary = run.get("kitchen_match", {})
	match_state.merge(result, true)
	match_state.active = false
	match_state.complete = true
	run.kitchen_match = match_state
	run.kitchen_match_result = {
		"game_over": true,
		"winner": String(result.get("winner", "opponent")),
		"turn": int(result.get("turn", 0)),
		"player": {"life": int(result.get("player_life", 0))},
		"opponent": {"life": int(result.get("opponent_life", 0))}
	}
	if bool(run.get("route_battle", {}).get("active", false)):
		call_deferred("_finish_route_battle", String(result.get("winner", "opponent")) == "player", int(result.get("player_life", 0)))
	elif _season_tournament_active():
		_set_footer("Kitchen match complete. Choose how to continue.")
		call_deferred("_show_season_round_result_popup", String(result.get("winner", "opponent")) == "player")
	else:
		_set_footer("Kitchen match complete. Return to the shop when ready.")


func _show_season_round_result_popup(won: bool) -> void:
	if not _season_tournament_active() or current_screen != "kitchen_match":
		return
	_dismiss_round_result_popup()
	if is_instance_valid(ui_sound_controller):
		if won:
			ui_sound_controller.play_success()
		else:
			ui_sound_controller.play_error()

	var active: Dictionary = run.get("active_tournament", {})
	var round_number := int(active.get("round", 1))
	var final_round := round_number >= int(active.get("rounds", round_number))
	var event := _season_event_by_id(String(active.get("event_id", _selected_season_event_id())))
	var round_cash: int = tournament_service.round_cash_reward(event, round_number)
	var accent := Color("#80d98b") if won else Color("#ef8e86")

	var overlay := Control.new()
	overlay.name = "SeasonRoundResultPopup"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1000
	add_child(overlay)
	round_result_popup = overlay

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.12, 0.09, 0.07, 0.62)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_stylebox_override(
		"panel",
		SKETCH_UI_SCRIPT.texture_style(
			SKETCH_UI_SCRIPT.PANEL_PAPER,
			Color.WHITE,
			Vector4(24, 24, 24, 24),
			Vector4.ZERO
		)
	)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var heading := Label.new()
	heading.name = "SeasonRoundResultHeading"
	heading.text = "YOU WON!" if won else "YOU LOST"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.9))
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", accent)
	box.add_child(heading)

	var detail := Label.new()
	detail.text = (
		"Round %d is complete. Lock in the win and view your tournament results." % round_number
		if won and final_round
		else "Round %d is complete. Continue now, or return to the shop to buy cards and edit your deck." % round_number
		if won
			else "Round %d was lost. Your season ends here." % round_number
	)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.12))
	detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	box.add_child(detail)

	var earnings := Label.new()
	earnings.name = "SeasonRoundCashReward"
	earnings.text = "ROUND EARNINGS  +$%d" % round_cash
	earnings.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	earnings.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	earnings.add_theme_font_size_override("font_size", 22)
	earnings.add_theme_color_override("font_color", Color("#3F826D"))
	box.add_child(earnings)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	var action := _make_button("View Results" if won and final_round else "Next Round" if won else "View Game Over")
	action.name = "SeasonRoundResultAction"
	action.custom_minimum_size = Vector2(0, 48)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.focus_mode = Control.FOCUS_ALL
	_style_button(action, "target" if won else "action")
	_connect_pressed(action, _on_season_round_win_continue if won else _on_season_round_loss_continue)
	actions.add_child(action)
	if won and not final_round:
		var shop_action := _make_button("Back to Shop")
		shop_action.name = "SeasonRoundResultShopAction"
		shop_action.custom_minimum_size = Vector2(0, 48)
		shop_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_connect_pressed(shop_action, _on_season_round_win_return_to_shop)
		actions.add_child(shop_action)
	action.grab_focus.call_deferred()


func _dismiss_round_result_popup() -> void:
	if is_instance_valid(round_result_popup):
		round_result_popup.queue_free()
	round_result_popup = null


func _on_season_round_win_continue() -> void:
	var state: Dictionary = run.get("kitchen_match_result", {})
	if String(state.get("winner", "")) != "player":
		return
	_dismiss_round_result_popup()
	_season_record_current_round_result(true)


func _on_season_round_win_return_to_shop() -> void:
	var state: Dictionary = run.get("kitchen_match_result", {})
	if String(state.get("winner", "")) != "player":
		return
	_dismiss_round_result_popup()
	_season_record_current_round_result(false, true)


func _on_season_round_loss_continue() -> void:
	var state: Dictionary = run.get("kitchen_match_result", {})
	if not _season_tournament_active() or String(state.get("winner", "player")) == "player":
		return
	_dismiss_round_result_popup()
	_season_record_current_round_result()


func _on_kitchen_exit_requested() -> void:
	var match_state: Dictionary = run.get("kitchen_match", {})
	if not bool(match_state.get("complete", false)):
		match_state.active = false
		match_state.complete = true
		match_state.winner = "opponent"
		match_state.turn = 0
		match_state.player_life = 0
		match_state.opponent_life = STARTING_CHEF_LIFE
		run.kitchen_match = match_state
		run.kitchen_match_result = {
			"game_over": true,
			"winner": "opponent",
			"turn": 0,
			"player": {"life": 0},
			"opponent": {"life": STARTING_CHEF_LIFE}
		}
		_set_footer("The kitchen match was forfeited.")
	if bool(run.get("route_battle", {}).get("active", false)):
		_finish_route_battle(false, 0)
	elif _season_tournament_active():
		_season_record_current_round_result()
	else:
		_show_shop()


func _clear_kitchen_match_state(clear_result: bool = true) -> void:
	if clear_result:
		run.kitchen_match_result = {}
		run.kitchen_match = {}


func _show_tournament() -> void:
	if _guard_run_over():
		return
	current_screen = "tournament"
	_render_nav()
	_clear(content)
	_update_status()

	if _run_mode() == "season" and _season_tournament_active():
		_add_season_tournament_progress(content)
		_add_exit_to_store_button(content)
		return

	var event: Dictionary = _selected_tournament_event()
	var event_id := String(event.get("id", "weekly_locals"))
	var legal := _deck_is_legal()
	var panel := _add_panel(content, String(event.get("name", event_id)))
	_add_body_text(panel, "Format: %d rounds. You need %d wins to keep the run alive." % [
		int(event.get("rounds", 3)),
		int(event.get("requiredWins", 2))
	])
	_add_body_text(panel, String(event.get("winConditionText", "")))
	if _run_mode() == "season":
		var difficulty := _difficulty_data(_run_difficulty_id())
		_add_body_text(panel, "%s Border: %s" % [
			String(difficulty.get("name", "Black")),
			String(difficulty.get("rules_text", ""))
		])
	if _run_mode() == "season":
		_add_body_text(panel, "Season mode uses live card matches for each round.")
	else:
		_add_body_text(panel, "Debug mode auto-resolves the full event for quick testing.")
	_add_body_text(panel, "Entry: Free | Current money: $%d" % int(run.get("money", 0)))
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var enter := _make_button("Enter %s" % String(event.get("name", event_id)))
	enter.disabled = not legal.ok or (_run_mode() == "season" and not _season_event_selectable(event_id))
	if _run_mode() == "season":
		_connect_pressed(enter, _start_season_tournament)
	else:
		_connect_pressed(enter, _run_tournament)
	panel.add_child(enter)

	if run.last_result.size() > 0:
		var last := _add_panel(content, "Last Tournament")
		for line in run.last_result:
			_add_body_text(last, line)
	if _run_mode() == "season":
		_add_exit_to_store_button(content)


func _add_season_tournament_progress(parent: Node) -> void:
	var active: Dictionary = run.get("active_tournament", {})
	var panel := _add_panel(parent, String(active.get("event_name", "Tournament")) + " In Progress", "#1f3329")
	var difficulty := _difficulty_data(_run_difficulty_id())
	_add_body_text(panel, "Round %d/%d | Record %d-%d | Need %d wins" % [
		int(active.get("round", 1)),
		int(active.get("rounds", 1)),
		int(active.get("wins", 0)),
		int(active.get("losses", 0)),
		int(active.get("required_wins", 1))
	])
	_add_body_text(panel, "%s Border | Lives %d/%d" % [
		String(difficulty.get("name", "Black")),
		int(run.get("season_lives", 0)),
		int(run.get("max_season_lives", 0))
	])
	_add_body_text(panel, "Cash earned this event: $%d | Next round pays: $%d" % [
		int(active.get("round_cash_earned", 0)),
		tournament_service.round_cash_reward(
			_season_event_by_id(String(active.get("event_id", _selected_season_event_id()))),
			int(active.get("round", 1))
		)
	])

	var current: Dictionary = run.get("kitchen_match_result", {})
	if not current.is_empty() and not bool(current.get("game_over", false)):
		var current_button := _make_button("Restart Current Kitchen Match")
		_connect_pressed(current_button, _resume_kitchen_match)
		panel.add_child(current_button)
	elif not current.is_empty() and bool(current.get("game_over", false)):
		var record_button := _make_button("Record Round Result")
		_connect_pressed(record_button, _season_record_current_round_result)
		panel.add_child(record_button)
	else:
		var next_button := _make_button("Start Round %d" % int(active.get("round", 1)))
		_connect_pressed(next_button, _start_season_tournament_round)
		panel.add_child(next_button)

	var logs: Array = active.get("logs", [])
	if not logs.is_empty():
		var log_panel := _add_panel(parent, "Event Log")
		for line in logs:
			_add_body_text(log_panel, "• " + String(line))


func _start_season_tournament() -> void:
	var event: Dictionary = _selected_season_event()
	var event_id := String(event.get("id", _selected_season_event_id()))
	var legal := _deck_is_legal()
	if not bool(legal.get("ok", false)):
		_set_footer(String(legal.get("reason", "")))
		return
	if not _season_event_selectable(event_id):
		_set_footer("Select an available calendar event before registering.")
		return

	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	run.active_tournament = tournament_service.create_active_tournament(self, event, deck_metrics)
	run.last_result = []
	_start_season_tournament_round()


func _start_season_tournament_round(reuse_current_opponent: bool = false, reuse_saved_setup: bool = false, resume_snapshot: Dictionary = {}) -> void:
	if not _season_tournament_active():
		_show_tournament()
		return
	if not reuse_current_opponent and not reuse_saved_setup:
		var legal := _deck_is_legal()
		if not bool(legal.get("ok", false)):
			_set_footer("Fix your deck before starting the next round: %s" % String(legal.get("reason", "Deck is not legal.")))
			_show_deckbuilder()
			return
	var active: Dictionary = run.get("active_tournament", {})
	var round_number := int(active.get("round", 1))
	var event := _season_event_by_id(String(active.get("event_id", "weekly_locals")))
	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var opponent: Dictionary = active.get("current_opponent", {}) if reuse_current_opponent else {}
	if opponent.is_empty():
		opponent = _generate_opponent(round_number, deck_metrics, event)
	var opponent_archetype := String(opponent.get("archetype", _predator_archetype(String(deck_metrics.primary))))
	var saved_seed := int(active.get("current_seed", 0))
	var seed_value := saved_seed if reuse_saved_setup and saved_seed != 0 else rng.randi()
	var first_side := String(active.get("current_first_side", "player")) if reuse_saved_setup else _season_round_first_side()
	var saved_ai := String(active.get("current_ai_difficulty", ""))
	var ai_difficulty: String = saved_ai if reuse_saved_setup and saved_ai != "" else tournament_service.ai_difficulty_for_round(self, event, round_number)
	var opponent_deck := _opponent_deck_for_round(opponent_archetype, round_number, event, ai_difficulty)

	active["current_opponent"] = opponent
	active["current_seed"] = seed_value
	active["current_first_side"] = first_side
	active["current_ai_difficulty"] = ai_difficulty
	active["round_result_recorded"] = false
	run.active_tournament = active
	_set_footer("%s round %d started. Win the match to add a win to your record." % [
		String(active.get("event_name", "Tournament")),
		round_number
	])
	if not reuse_saved_setup:
		await _play_round_circle_wipe(String(active.get("event_name", "Tournament")), round_number)
		if not _season_tournament_active():
			return
	_begin_kitchen_match(
		run.deck,
		opponent_deck,
		"%s — %s" % [String(opponent.get("name", "Opponent")), _archetype_label(opponent_archetype)],
		true,
		seed_value,
		first_side,
		ai_difficulty,
		resume_snapshot
	)


func _instantiate_scene(path: String) -> Node:
	var packed_scene := load(path) as PackedScene
	assert(packed_scene != null, "Unable to load scene: %s" % path)
	return packed_scene.instantiate()


func _play_round_circle_wipe(event_name: String, round_number: int) -> void:
	if _running_automated_test() or _reduced_motion_enabled():
		return
	var overlay := Control.new()
	overlay.name = "RoundCircleWipe"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 3000
	add_child(overlay)

	var wipe := ColorRect.new()
	wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		uniform float radius = 0.0;
		uniform vec4 paper_color : source_color;
		uniform vec4 accent_color : source_color;
		uniform vec4 highlight_color : source_color;
		void fragment() {
			vec2 point = (UV - vec2(0.5)) * vec2(1.78, 1.0);
			float distance_from_center = length(point);
			float paper_mask = 1.0 - smoothstep(radius, radius + 0.025, distance_from_center);
			float accent_band = 1.0 - smoothstep(0.0, 0.085, radius - distance_from_center);
			float cream_line = smoothstep(0.026, 0.042, radius - distance_from_center)
				* (1.0 - smoothstep(0.042, 0.058, radius - distance_from_center));
			vec3 color = mix(paper_color.rgb, accent_color.rgb, accent_band * 0.9);
			color = mix(color, highlight_color.rgb, cream_line);
			COLOR = vec4(color, paper_mask * paper_color.a);
		}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("radius", 0.0)
	material.set_shader_parameter("paper_color", PALETTE.PERIWINKLE.darkened(0.28))
	material.set_shader_parameter("accent_color", PALETTE.FRESH_YELLOW)
	material.set_shader_parameter("highlight_color", PALETTE.CREAM)
	wipe.material = material
	overlay.add_child(wipe)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var label := Label.new()
	label.text = "%s\nROUND %d" % [event_name.to_upper(), round_number]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", PALETTE.CREAM)
	label.add_theme_color_override("font_outline_color", PALETTE.NAVY)
	label.add_theme_constant_override("outline_size", 8)
	label.modulate.a = 0.0
	center.add_child(label)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(material, "shader_parameter/radius", 1.2, 0.38)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.2).set_delay(0.18)
	tween.tween_interval(0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(material, "shader_parameter/radius", 0.0, 0.38)
	await tween.finished
	overlay.queue_free()


func _season_record_current_round_result(auto_start_next_round: bool = false, return_to_shop: bool = false) -> void:
	if not _season_tournament_active():
		return
	var state: Dictionary = run.get("kitchen_match_result", {})
	if state.is_empty() or not bool(state.get("game_over", false)):
		_set_footer("Finish the current Kitchen Match before recording the result.")
		return
	var active: Dictionary = run.get("active_tournament", {})
	if bool(active.get("round_result_recorded", false)):
		_show_tournament()
		return

	var won := String(state.get("winner", "")) == "player"
	if won:
		active["wins"] = int(active.get("wins", 0)) + 1
	else:
		active["losses"] = int(active.get("losses", 0)) + 1

	var opponent: Dictionary = active.get("current_opponent", {})
	var round_number := int(active.get("round", 1))
	var event := _season_event_by_id(String(active.get("event_id", _selected_season_event_id())))
	var round_cash: int = tournament_service.round_cash_reward(event, round_number)
	run.money = int(run.get("money", 0)) + round_cash
	active["last_round_cash"] = round_cash
	active["round_cash_earned"] = int(active.get("round_cash_earned", 0)) + round_cash
	var player_life := int(state.get("player", {}).get("life", 0))
	var opponent_life := int(state.get("opponent", {}).get("life", 0))
	var round_results: Array = active.get("round_results", [])
	round_results.append({
		"round": round_number,
		"opponent_name": String(opponent.get("name", "Opponent")),
		"opponent_archetype": _archetype_label(String(opponent.get("archetype", ""))),
		"won": won,
		"turn": int(state.get("turn", 0)),
		"player_life": player_life,
		"opponent_life": opponent_life,
		"cash": round_cash,
	})
	active["round_results"] = round_results
	var logs: Array = active.get("logs", [])
	logs.append("Round %d vs %s on %s: %s. Turn %d, life %d-%d, seed %d." % [
		round_number,
		String(opponent.get("name", "Opponent")),
		_archetype_label(String(opponent.get("archetype", ""))),
		"Won" if won else "Lost",
		int(state.get("turn", 0)),
		player_life,
		opponent_life,
		int(active.get("current_seed", 0))
	])
	logs.append("Round %d earnings: +$%d. Event cash earned: $%d." % [
		round_number,
		round_cash,
		int(active.get("round_cash_earned", 0))
	])
	active["logs"] = logs
	active["round_result_recorded"] = true
	run.active_tournament = active
	_generate_shop_inventory()

	if _season_tournament_should_finish(active):
		_finish_season_tournament()
		return

	active["round"] = round_number + 1
	active["current_opponent"] = {}
	active["current_seed"] = 0
	active["round_result_recorded"] = false
	run.active_tournament = active
	_clear_kitchen_match_state()
	if return_to_shop:
		_set_footer("Round recorded. Visit the clerk when you are ready to start round %d." % int(active.get("round", 1)))
		_show_shop()
	elif auto_start_next_round:
		_set_footer("Round recorded. Starting round %d." % int(active.get("round", 1)))
		call_deferred("_start_season_tournament_round")
	else:
		_set_footer("Round recorded. Prepare for round %d." % int(active.get("round", 1)))
		_show_tournament()


func _season_tournament_should_finish(active: Dictionary) -> bool:
	return tournament_service.should_finish(active)


func _finish_season_tournament() -> void:
	var active: Dictionary = run.get("active_tournament", {})
	var event_id := String(active.get("event_id", "weekly_locals"))
	var event: Dictionary = _season_event_by_id(event_id)
	var wins := int(active.get("wins", 0))
	var losses := int(active.get("losses", 0))
	var required := int(active.get("required_wins", int(event.get("requiredWins", 2))))
	var logs: Array = active.get("logs", [])
	var made_record := wins >= required
	var run_continues := made_record
	var reward_money := 0
	var reward_packs := 0
	var round_cash_earned := int(active.get("round_cash_earned", 0))
	var lives_lost := 0
	if made_record:
		reward_money = int(event.get("rewardMoney", {}).get(str(wins), 0))
		reward_packs = int(event.get("rewardPacks", {}).get(str(wins), 0))
		run.money = int(run.money) + reward_money
		run.prize_packs = int(run.prize_packs) + reward_packs
		run.week = int(run.week) + 1
		_season_mark_event_completed(event_id)
		if _season_event_is_final(event_id):
			run.season_champion = true
			run.demo_complete = true
			run_continues = true
			logs.append("Record: %d-%d. League Cup cleared. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
		else:
			logs.append("Record: %d-%d. Calendar advanced. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
	else:
		lives_lost = 1
		run.season_lives = 0
		run.run_over = true
		run_continues = false
		run.season_notice = "%s ended after the first match loss." % String(event.get("name", event_id))
		logs.append("Record: %d-%d. The season ends here." % [wins, losses])

	_update_meta_after_event(String(active.get("deck_primary", _current_primary_archetype())), wins, max(1, wins + losses))
	run.last_result = logs
	var event_summary := _build_event_result_summary(
		event,
		wins,
		losses,
		required,
		made_record,
		reward_money,
		reward_packs,
		round_cash_earned,
		lives_lost,
		run_continues
	)
	event_summary["round_results"] = active.get("round_results", []).duplicate(true)
	run.last_event_result = event_summary
	run.active_tournament = {}
	_clear_kitchen_match_state()
	_show_tournament_result(logs, run_continues)


func _build_event_result_summary(
	event: Dictionary,
	wins: int,
	losses: int,
	required: int,
	made_record: bool,
	reward_money: int,
	reward_packs: int,
	round_cash_earned: int,
	lives_lost: int,
	run_continues: bool
) -> Dictionary:
	return tournament_service.build_event_result_summary(
		self,
		event,
		wins,
		losses,
		required,
		made_record,
		reward_money,
		reward_packs,
		round_cash_earned,
		lives_lost,
		run_continues
	)


func _season_forfeit_current_round() -> void:
	if not _season_tournament_active():
		return
	var state: Dictionary = run.get("kitchen_match_result", {})
	if state.is_empty():
		_show_tournament()
		return
	state["game_over"] = true
	state["winner"] = "opponent"
	state["player"] = {"life": 0}
	state["opponent"] = {"life": STARTING_CHEF_LIFE}
	state["turn"] = 0
	run.kitchen_match_result = state
	_set_footer("Round forfeited. Record the result to continue.")
	_show_tournament()


func _season_tournament_active() -> bool:
	if run.is_empty():
		return false
	var active: Dictionary = run.get("active_tournament", {})
	return not active.is_empty() and bool(active.get("active", false))


func _run_tournament() -> void:
	var event: Dictionary = _selected_tournament_event()
	var legal := _deck_is_legal()
	if not legal.ok:
		_set_footer(legal.reason)
		return

	var logs := []
	var wins := 0
	var losses := 0
	var round_cash_earned := 0
	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)

	logs.append("Entered %s with %s. Entry was free." % [event.name, archetypes_by_id[deck_metrics.primary].name])

	for round_number in range(1, int(event.rounds) + 1):
		var opponent := _generate_opponent(round_number, deck_metrics, event)
		var result := _simulate_combat_match(opponent, deck_metrics)
		var round_cash: int = tournament_service.round_cash_reward(event, round_number)
		round_cash_earned += round_cash
		run.money = int(run.get("money", 0)) + round_cash
		logs.append("Round %d earnings: +$%d. Event cash earned: $%d." % [
			round_number,
			round_cash,
			round_cash_earned
		])
		if result.won:
			wins += 1
		else:
			losses += 1

		logs.append(
			"Round %d vs %s on %s: %s %d-%d. Estimated match odds: %d%%."
			% [
				round_number,
				opponent.name,
				archetypes_by_id[opponent.archetype].name,
				"Won" if result.won else "Lost",
				result.player_game_wins,
				result.opponent_game_wins,
				int(round(result.display_probability * 100.0))
			]
		)
		for game_summary in result.get("game_summaries", []):
			logs.append("  " + String(game_summary))

	var reward_money := 0
	var reward_packs := 0
	if wins >= int(event.requiredWins):
		reward_money = int(event.rewardMoney.get(str(wins), 0))
		reward_packs = int(event.rewardPacks.get(str(wins), 0))
		run.money += reward_money
		run.prize_packs += reward_packs
		run.week = int(run.week) + 1
		logs.append("Record: %d-%d. Run continues. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
	else:
		run.run_over = true
		logs.append("Record: %d-%d. Required record missed. The season ends here." % [wins, losses])

	_update_meta_after_event(deck_metrics.primary, wins, int(event.rounds))
	_generate_shop_inventory()
	run.last_result = logs
	_show_tournament_result(logs, wins >= int(event.requiredWins))


func _show_tournament_result(logs: Array, survived: bool) -> void:
	current_screen = "result"
	_render_nav()
	_clear(content)
	_update_status()

	var champion := bool(run.get("season_champion", false))
	var result_summary: Dictionary = run.get("last_event_result", {})
	if result_summary.is_empty():
		result_summary = _result_summary_from_logs(logs, survived)
	var made_record := bool(result_summary.get("made_record", survived))
	var run_over := bool(result_summary.get("run_over", run.get("run_over", false)))
	if champion:
		_set_footer("League Cup cleared. Claim your prizes, then see what waits beyond the demo.")
	elif made_record:
		_set_footer("%s cleared. Your next event is waiting." % String(result_summary.get("event_name", "Event")))
	elif run_over:
		_set_footer("The season ends here. Review the run or begin a new road.")
	else:
		_set_footer("So close. Tune your deck and take another shot.")

	var screen := VBoxContainer.new()
	screen.name = "TournamentResultScreen"
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.add_theme_constant_override("separation", 12)
	content.add_child(screen)

	_add_tournament_result_hero(screen, result_summary, made_record, champion, run_over)
	if not champion and not run_over:
		_add_tournament_result_stats(screen, result_summary)
		_add_tournament_result_next_step(screen, result_summary, made_record, champion, run_over)
	_add_tournament_round_recap(screen, result_summary)

	if _development_tools_enabled():
		_add_tournament_result_technical_details(screen, logs)

	if _run_mode() == "season":
		_add_season_result_action_buttons(screen)
	else:
		var continue_button := _make_button("Return to Card Shop")
		continue_button.name = "TournamentResultContinueButton"
		continue_button.custom_minimum_size.y = 50
		_style_button(continue_button, "action")
		_connect_pressed(continue_button, _show_shop)
		screen.add_child(continue_button)

	if not _reduced_motion_enabled() and not _running_automated_test():
		screen.modulate.a = 0.0
		var result_tween := create_tween()
		result_tween.tween_property(screen, "modulate:a", 1.0, 0.24)


func _result_summary_from_logs(logs: Array, survived: bool) -> Dictionary:
	var wins := 0
	var losses := 0
	for line_value in logs:
		var line := String(line_value)
		if line.begins_with("Round ") and line.contains(": Won"):
			wins += 1
		elif line.begins_with("Round ") and line.contains(": Lost"):
			losses += 1
	return {
		"event_name": "Tournament",
		"stage": "Event",
		"wins": wins,
		"losses": losses,
		"rounds": maxi(1, wins + losses),
		"required_wins": wins if survived else wins + 1,
		"made_record": survived,
		"reward_money": 0,
		"reward_packs": 0,
		"round_cash_earned": 0,
		"run_over": not survived,
		"round_results": [],
	}


func _add_tournament_result_hero(
	parent: Node,
	summary: Dictionary,
	made_record: bool,
	champion: bool,
	run_over: bool
) -> void:
	var accent := PALETTE.FRESH_YELLOW if champion else (PALETTE.SKY if made_record else PALETTE.CORAL)
	var fill := (
		PALETTE.CREAM.lerp(PALETTE.FRESH_YELLOW, 0.22)
		if champion
		else PALETTE.CREAM.lerp(PALETTE.BLUSH, 0.25)
		if run_over
		else PALETTE.CREAM.lerp(PALETTE.SKY, 0.18)
		if made_record
		else PALETTE.CREAM.lerp(PALETTE.BLUSH, 0.18)
	)
	var hero := _make_cute_result_panel(
		Vector2(0, 166),
		fill,
		PALETTE.NAVY,
		Vector4(38, 18, 38, 20),
		22
	)
	hero.set_meta("result_accent", accent)
	hero.name = "TournamentResultHero"
	parent.add_child(hero)
	if champion or run_over:
		hero.custom_minimum_size.y = 220
		_add_season_result_list_hero(hero, summary, champion)
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	hero.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -1)
	row.add_child(copy)

	var event_label := Label.new()
	event_label.name = "TournamentResultEventName"
	event_label.text = ("%s  •  %s" % [
		String(summary.get("stage", "Event")),
		String(summary.get("event_name", "Tournament")),
	]).to_upper()
	event_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.46))
	event_label.add_theme_font_size_override("font_size", 15)
	event_label.add_theme_color_override("font_color", accent.darkened(0.18))
	copy.add_child(event_label)

	var outcome_label := Label.new()
	outcome_label.name = "TournamentResultOutcome"
	if champion:
		outcome_label.text = "LEAGUE CUP CHAMPION"
	elif made_record:
		outcome_label.text = "EVENT CLEARED"
	elif run_over:
		outcome_label.text = "SEASON ENDED"
	else:
		outcome_label.text = "ONE MORE TRY"
	outcome_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.9))
	outcome_label.add_theme_font_size_override("font_size", 42)
	outcome_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.PAPER if run_over else SKETCH_UI_SCRIPT.INK)
	copy.add_child(outcome_label)

	var detail := Label.new()
	detail.name = "TournamentResultOutcomeDetail"
	if champion:
		detail.text = "You conquered the local circuit. The road gets bigger from here."
	elif made_record:
		detail.text = "You made the cut. A tougher table is waiting."
	elif run_over:
		detail.text = "The run is over, but the deck—and everything you learned—is yours."
	else:
		detail.text = "The event stays open. Make an adjustment and run it back."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.16))
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color("#D7CBE0") if run_over else SKETCH_UI_SCRIPT.MUTED_INK)
	copy.add_child(detail)

	var record_box := VBoxContainer.new()
	record_box.name = "TournamentResultRecord"
	record_box.custom_minimum_size = Vector2(190, 0)
	record_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(record_box)
	var record := Label.new()
	record.text = "%d–%d" % [int(summary.get("wins", 0)), int(summary.get("losses", 0))]
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.94))
	record.add_theme_font_size_override("font_size", 64)
	record.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.PAPER if run_over else SKETCH_UI_SCRIPT.INK)
	record_box.add_child(record)
	var record_caption := Label.new()
	record_caption.text = "FINAL RECORD"
	record_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_caption.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
	record_caption.add_theme_font_size_override("font_size", 13)
	record_caption.add_theme_color_override("font_color", accent.lightened(0.12) if run_over else accent.darkened(0.18))
	record_box.add_child(record_caption)


func _add_season_result_list_hero(hero: PanelContainer, summary: Dictionary, champion: bool) -> void:
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 7)
	hero.add_child(copy)

	var eyebrow := Label.new()
	eyebrow.name = "TournamentResultEyebrow"
	eyebrow.text = "YOUR SEASON SCRAPBOOK" if not champion else "A SEASON TO REMEMBER"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.48))
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", PALETTE.CORAL.darkened(0.18) if not champion else PALETTE.FRESH_YELLOW.darkened(0.28))
	copy.add_child(eyebrow)

	var heading_row := HBoxContainer.new()
	heading_row.alignment = BoxContainer.ALIGNMENT_CENTER
	heading_row.add_theme_constant_override("separation", 16)
	copy.add_child(heading_row)
	var left_sparkle := TextureRect.new()
	left_sparkle.texture = ICON_STAR
	left_sparkle.custom_minimum_size = Vector2(30, 30)
	left_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_sparkle.modulate = PALETTE.FRESH_YELLOW
	left_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_row.add_child(left_sparkle)
	var outcome := Label.new()
	outcome.name = "TournamentResultOutcome"
	outcome.text = "SEASON WON" if champion else "SEASON ENDED"
	outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.9))
	outcome.add_theme_font_size_override("font_size", 45)
	outcome.add_theme_color_override("font_color", PALETTE.NAVY)
	heading_row.add_child(outcome)
	var right_sparkle := TextureRect.new()
	right_sparkle.texture = ICON_STAR
	right_sparkle.custom_minimum_size = Vector2(24, 24)
	right_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_sparkle.modulate = PALETTE.SKY
	right_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_row.add_child(right_sparkle)

	var encouragement := Label.new()
	encouragement.name = "TournamentResultEncouragement"
	encouragement.text = (
		"You cleared the local circuit. Keep this page—the road gets bigger from here."
		if champion
		else "The table is cleared, but every round leaves something worth carrying into your next run."
	)
	encouragement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encouragement.add_theme_font_size_override("font_size", 15)
	encouragement.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	copy.add_child(encouragement)

	var stat_row := HBoxContainer.new()
	stat_row.name = "TournamentResultSeasonStats"
	stat_row.add_theme_constant_override("separation", 10)
	copy.add_child(stat_row)
	_add_season_result_chip(
		stat_row,
		"LAST STOP",
		"%s · %s" % [String(summary.get("stage", "Season")), String(summary.get("event_name", "Final Event"))],
		"TournamentResultReached",
		PALETTE.CREAM.lerp(PALETTE.SKY, 0.19),
		PALETTE.SKY
	)
	_add_season_result_chip(
		stat_row,
		"FINAL RECORD",
		"%d–%d" % [int(summary.get("wins", 0)), int(summary.get("losses", 0))],
		"TournamentResultRecord",
		PALETTE.LAVENDER_GLASS,
		PALETTE.PERIWINKLE
	)
	_add_season_result_chip(
		stat_row,
		"TABLE EARNINGS",
		"$%d" % int(summary.get("round_cash_earned", 0)),
		"TournamentResultEarnings",
		PALETTE.CREAM.lerp(PALETTE.BLUSH, 0.19),
		PALETTE.CORAL
	)


func _add_season_result_chip(
	parent: Node,
	title: String,
	value: String,
	value_name: String,
	fill: Color,
	accent: Color
) -> void:
	var panel := _make_cute_result_panel(
		Vector2(0, 64),
		fill,
		PALETTE.NAVY,
		Vector4(14, 7, 14, 8),
		15
	)
	panel.set_meta("result_accent", accent)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var chip_copy := VBoxContainer.new()
	chip_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_copy.add_theme_constant_override("separation", -2)
	panel.add_child(chip_copy)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.44))
	heading.add_theme_font_size_override("font_size", 11)
	heading.add_theme_color_override("font_color", accent.darkened(0.24))
	chip_copy.add_child(heading)
	var amount := Label.new()
	amount.name = value_name
	amount.text = value
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	amount.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.7))
	amount.add_theme_font_size_override("font_size", 19)
	amount.add_theme_color_override("font_color", PALETTE.NAVY)
	chip_copy.add_child(amount)


func _add_tournament_result_stats(parent: Node, summary: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "TournamentResultRewards"
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	_add_tournament_result_stat(
		row,
		"TARGET",
		"%d WINS" % int(summary.get("required_wins", 0)),
		"%d rounds played" % maxi(1, int(summary.get("wins", 0)) + int(summary.get("losses", 0))),
		SKETCH_UI_SCRIPT.TEAL
	)
	_add_tournament_result_stat(
		row,
		"TABLE EARNINGS",
		"$%d" % int(summary.get("round_cash_earned", 0)),
		"earned match by match",
		SKETCH_UI_SCRIPT.ORANGE
	)
	var reward_packs := int(summary.get("reward_packs", 0))
	var reward_value := "$%d" % int(summary.get("reward_money", 0))
	if reward_packs > 0:
		reward_value += "  +  %d PACK%s" % [reward_packs, "" if reward_packs == 1 else "S"]
	_add_tournament_result_stat(
		row,
		"EVENT PRIZE",
		reward_value,
		"claimed for making the cut" if bool(summary.get("made_record", false)) else "no event prize",
		SKETCH_UI_SCRIPT.MUSTARD
	)


func _add_tournament_result_stat(
	parent: Node,
	title: String,
	value: String,
	detail: String,
	accent: Color
) -> void:
	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 105),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		accent,
		Vector4(20, 12, 20, 14),
		parent.get_child_count() % 2
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -1)
	panel.add_child(copy)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", accent.darkened(0.2))
	copy.add_child(heading)
	var amount := Label.new()
	amount.text = value
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.82))
	amount.add_theme_font_size_override("font_size", 27)
	amount.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	copy.add_child(amount)
	var caption := Label.new()
	caption.text = detail
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	copy.add_child(caption)


func _add_tournament_result_next_step(
	parent: Node,
	summary: Dictionary,
	made_record: bool,
	champion: bool,
	run_over: bool
) -> void:
	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 82),
		Color("#FFF8E9"),
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.MUSTARD if champion else SKETCH_UI_SCRIPT.TEAL,
		Vector4(26, 13, 26, 15),
		0
	)
	panel.name = "TournamentResultNextStep"
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var heading := Label.new()
	heading.custom_minimum_size = Vector2(260, 0)
	if champion:
		heading.text = "THE ROAD CONTINUES →"
	elif made_record:
		heading.text = "UP NEXT  •  %s →" % String(summary.get("next_event_name", "Next Event")).to_upper()
	elif run_over:
		heading.text = "THE ROAD ENDS HERE"
	else:
		heading.text = "EVENT STILL OPEN"
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.78))
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	row.add_child(heading)
	var detail := Label.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if champion:
		detail.text = "State Championships. Nationals. Worlds. This was only the first chapter."
	elif made_record:
		detail.text = "A stronger field and a bigger prize. Shop, tune, then take your seat."
	elif run_over:
		detail.text = "Start fresh with a new strategy, or look back at the deck that got you here."
	else:
		detail.text = "Your calendar spot is safe. Tune the list, then challenge the event again."
	detail.add_theme_font_size_override("font_size", 14)
	detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	row.add_child(detail)


func _add_tournament_round_recap(parent: Node, summary: Dictionary) -> void:
	var section := VBoxContainer.new()
	section.name = "TournamentResultRoundRecap"
	section.add_theme_constant_override("separation", 4)
	parent.add_child(section)
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 10)
	section.add_child(heading_row)
	var heading := Label.new()
	heading.text = "ROUND RECAP"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.7))
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", PALETTE.NAVY)
	heading_row.add_child(heading)
	var recap_note := Label.new()
	recap_note.text = "%d MATCHES  ·  $%d EARNED" % [
		maxi(1, int(summary.get("wins", 0)) + int(summary.get("losses", 0))),
		int(summary.get("round_cash_earned", 0)),
	]
	recap_note.add_theme_font_size_override("font_size", 12)
	recap_note.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	recap_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_row.add_child(recap_note)
	var list := VBoxContainer.new()
	list.name = "TournamentResultRoundList"
	list.add_theme_constant_override("separation", 5)
	section.add_child(list)

	var round_results: Array = summary.get("round_results", [])
	if round_results.is_empty():
		var wins := int(summary.get("wins", 0))
		var losses := int(summary.get("losses", 0))
		for round_index in range(maxi(1, wins + losses)):
			_add_tournament_round_card(
				list,
				round_index + 1,
				{"won": round_index < wins}
			)
		return
	for round_value in round_results:
		_add_tournament_round_card(list, int(round_value.get("round", list.get_child_count() + 1)), round_value)


func _add_tournament_round_card(parent: Node, round_number: int, result: Dictionary) -> void:
	var won := bool(result.get("won", false))
	var accent := PALETTE.SKY if won else PALETTE.CORAL
	var fill := PALETTE.CREAM.lerp(PALETTE.SKY if won else PALETTE.BLUSH, 0.16)
	var panel := _make_cute_result_panel(
		Vector2(0, 64),
		fill,
		PALETTE.NAVY,
		Vector4(16, 8, 16, 9),
		14
	)
	panel.set_meta("result_accent", accent)
	panel.name = "TournamentResultRoundCard_%d" % round_number
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var copy := HBoxContainer.new()
	copy.add_theme_constant_override("separation", 18)
	panel.add_child(copy)
	var top := Label.new()
	top.custom_minimum_size = Vector2(180, 0)
	top.text = "ROUND %d   •   %s" % [round_number, "WIN" if won else "LOSS"]
	top.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	top.add_theme_font_size_override("font_size", 19)
	top.add_theme_color_override("font_color", PALETTE.NAVY)
	top.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(top)
	var opponent_name := String(result.get("opponent_name", ""))
	var opponent_archetype := String(result.get("opponent_archetype", ""))
	var matchup := Label.new()
	matchup.text = (
		"vs %s  •  %s" % [opponent_name, opponent_archetype]
		if opponent_name != ""
		else ("Made the cut" if won else "Run ended")
	)
	matchup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	matchup.clip_text = true
	matchup.add_theme_font_size_override("font_size", 13)
	matchup.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	matchup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(matchup)
	if result.has("turn") or result.has("cash"):
		var detail := Label.new()
		detail.custom_minimum_size = Vector2(190, 0)
		detail.text = "Turn %d  •  %d life  •  +$%d" % [
			int(result.get("turn", 0)),
			int(result.get("player_life", 0)),
			int(result.get("cash", 0)),
		]
		detail.add_theme_font_size_override("font_size", 12)
		detail.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		copy.add_child(detail)


func _make_cute_result_panel(
	minimum_size: Vector2,
	fill: Color,
	border: Color,
	content_margins: Vector4,
	corner_radius: int
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.set_meta("cute_result_panel", true)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	style.shadow_color = Color(PALETTE.NAVY, 0.15)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _add_tournament_result_technical_details(parent: Node, logs: Array) -> void:
	var toggle := _make_button("Show Technical Details")
	toggle.name = "TournamentResultTechnicalToggle"
	toggle.custom_minimum_size.y = 34
	parent.add_child(toggle)
	var details := _add_panel(parent, "Technical Details", "#5D5148")
	details.name = "TournamentResultTechnicalDetails"
	details.visible = false
	for line in logs:
		_add_body_text(details, String(line))
	toggle.pressed.connect(func() -> void:
		details.visible = not details.visible
		toggle.text = "Hide Technical Details" if details.visible else "Show Technical Details"
	)


func _add_season_result_action_buttons(parent: Node) -> void:
	var actions := VBoxContainer.new()
	actions.name = "SeasonResultActions"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	parent.add_child(actions)

	var primary_action := _season_result_primary_action()
	if not primary_action.is_empty():
		var primary_callback: Callable = primary_action.get("callback", _show_season_run)
		_add_season_result_button(
			actions,
			String(primary_action.get("text", "Continue")),
			primary_callback,
			true,
			bool(primary_action.get("disabled", false))
		)

	var secondary := HBoxContainer.new()
	secondary.name = "SeasonResultSecondaryActions"
	secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary.add_theme_constant_override("separation", 8)
	actions.add_child(secondary)

	var summary: Dictionary = run.get("last_event_result", {})
	var made_record := bool(summary.get("made_record", true))
	var run_over := bool(summary.get("run_over", false))
	var seen_labels: Dictionary = {}
	if not primary_action.is_empty():
		seen_labels[String(primary_action.get("text", ""))] = true

	if run_over:
		_add_season_result_secondary_button(secondary, "Review Deck", _show_deckbuilder, seen_labels)
		_add_season_result_secondary_button(secondary, "Main Menu", _show_start, seen_labels)
		return

	if not made_record and not bool(summary.get("run_over", false)):
		var event_id := String(summary.get("event_id", _selected_season_event_id()))
		var event := _season_event_by_id(event_id)
		_add_season_result_secondary_button(
			secondary,
			"Retry %s" % String(event.get("name", event_id)),
			_show_tournament,
			seen_labels,
			not _deck_is_legal().ok
		)

	if int(run.get("prize_packs", 0)) > 0 or _current_pack_needs_attention():
		_add_season_result_secondary_button(
			secondary,
			"Open Prize Packs (%d)" % int(run.get("prize_packs", 0)),
			_open_reward_pack_flow,
			seen_labels
		)

	_add_season_result_secondary_button(secondary, "Tune Deck", _show_deckbuilder, seen_labels)
	_add_season_result_secondary_button(secondary, "Visit Card Shop", _show_shop, seen_labels)
	_add_season_result_secondary_button(secondary, "View Calendar", _show_season_run, seen_labels)


func _season_result_primary_action() -> Dictionary:
	var summary: Dictionary = run.get("last_event_result", {})
	if summary.is_empty():
		return { "text": "Visit Card Shop", "callback": _show_shop }
	if _current_pack_needs_attention():
		return { "text": "Continue Pack", "callback": _open_reward_pack_flow }
	if int(run.get("prize_packs", 0)) > 0:
		return { "text": "Open Prize Packs (%d)" % int(run.get("prize_packs", 0)), "callback": _open_reward_pack_flow }
	if bool(summary.get("season_champion", false)):
		return { "text": "Thanks for Playing", "callback": _show_thanks_for_playing }
	if bool(summary.get("run_over", false)):
		return { "text": "Start New Run", "callback": _show_start }
	if not bool(summary.get("made_record", true)):
		var event_id := String(summary.get("event_id", _selected_season_event_id()))
		var event := _season_event_by_id(event_id)
		return {
			"text": "Retry %s" % String(event.get("name", event_id)),
			"callback": _show_tournament,
			"disabled": not _deck_is_legal().ok
		}
	return { "text": "Visit Card Shop", "callback": _show_shop }


func _add_season_result_secondary_button(parent: Node, text: String, callback: Callable, seen_labels: Dictionary, disabled: bool = false) -> void:
	if seen_labels.has(text):
		return
	seen_labels[text] = true
	_add_season_result_button(parent, text, callback, false, disabled)


func _add_season_result_button(parent: Node, text: String, callback: Callable, primary: bool, disabled: bool = false) -> Button:
	var button := _make_button(text)
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 50 if primary else 44
	if primary:
		button.name = "SeasonResultPrimaryAction"
		_style_button(button, "action")
	else:
		button.name = "SeasonResultSecondaryAction"
	_style_season_result_button(button, primary)
	_connect_pressed(button, callback)
	parent.add_child(button)
	return button


func _style_season_result_button(button: Button, primary: bool) -> void:
	button.set_meta("ui_button_variant", "primary" if primary else "secondary")
	button.set_meta("ui_button_variant_inferred", false)
	var normal_fill := PALETTE.CORAL if primary else PALETTE.LAVENDER_GLASS
	var hover_fill := normal_fill.lightened(0.08) if primary else PALETTE.CREAM.lerp(PALETTE.SKY, 0.18)
	var pressed_fill := normal_fill.darkened(0.07)
	button.add_theme_stylebox_override("normal", _season_result_button_style(normal_fill, false))
	button.add_theme_stylebox_override("hover", _season_result_button_style(hover_fill, false, true))
	button.add_theme_stylebox_override("pressed", _season_result_button_style(pressed_fill, true))
	button.add_theme_stylebox_override("focus", _season_result_button_style(hover_fill, false, true))
	button.add_theme_stylebox_override("disabled", _season_result_button_style(Color(PALETTE.DISABLED, 0.72), false))
	for color_name in [
		"font_color", "font_hover_color", "font_pressed_color",
		"icon_normal_color", "icon_hover_color", "icon_pressed_color",
	]:
		button.add_theme_color_override(color_name, PALETTE.NAVY)
	button.add_theme_color_override("font_disabled_color", PALETTE.DISABLED_INK)
	button.add_theme_color_override("icon_disabled_color", PALETTE.DISABLED_INK)


func _season_result_button_style(fill: Color, pressed: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = PALETTE.SKY if hovered else PALETTE.NAVY
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 8 if not pressed else 10
	style.content_margin_bottom = 9 if not pressed else 7
	style.anti_aliasing = true
	if not pressed:
		style.shadow_color = Color(PALETTE.NAVY, 0.18 if not hovered else 0.24)
		style.shadow_size = 4 if not hovered else 6
		style.shadow_offset = Vector2(0, 3)
	return style


func _open_reward_pack_flow() -> void:
	var current_pack: Array = run.get("current_pack", [])
	if _current_pack_needs_attention():
		_show_packs()
		return
	if not current_pack.is_empty():
		_finish_pack_state()
	if int(run.get("prize_packs", 0)) > 0:
		_open_prize_pack()
		return
	_show_packs()


func _finish_pack_opening() -> void:
	_finish_pack_state()
	if int(run.get("prize_packs", 0)) > 0:
		_open_reward_pack_flow()
	elif bool(run.get("demo_complete", false)):
		_show_thanks_for_playing()
	else:
		_show_shop()


func _show_thanks_for_playing() -> void:
	current_screen = "thanks"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Your road has only just begun.")

	var finale := VBoxContainer.new()
	finale.name = "SeasonFinale"
	finale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finale.add_theme_constant_override("separation", 11)
	content.add_child(finale)

	var hero := PanelContainer.new()
	hero.name = "FinaleHero"
	hero.custom_minimum_size = Vector2(0, 184)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override(
		"panel",
		_finale_panel_style(
			Color(PALETTE.CREAM, 0.97),
			PALETTE.NAVY,
			20,
			Vector4(42, 24, 42, 26),
			0.18
		)
	)
	finale.add_child(hero)
	var hero_copy := VBoxContainer.new()
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", 5)
	hero.add_child(hero_copy)
	var eyebrow := Label.new()
	eyebrow.text = "DEMO COMPLETE  •  SEASON SCRAPBOOK"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.46))
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", PALETTE.TEAL_DARK)
	hero_copy.add_child(eyebrow)
	var champion_title := Label.new()
	champion_title.name = "FinaleChampionTitle"
	champion_title.text = "Thanks for Playing the Demo!"
	champion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	champion_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.9))
	champion_title.add_theme_font_size_override("font_size", 50)
	champion_title.add_theme_color_override("font_color", PALETTE.NAVY)
	hero_copy.add_child(champion_title)
	var hero_detail := Label.new()
	hero_detail.name = "FinaleHeroDetail"
	hero_detail.text = "Hope you liked it! The fact that people are actually getting to the end of my demo is dope so thank you!"
	hero_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.18))
	hero_detail.add_theme_font_size_override("font_size", 16)
	hero_detail.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	hero_copy.add_child(hero_detail)
	var hero_accent := ColorRect.new()
	hero_accent.custom_minimum_size = Vector2(180, 5)
	hero_accent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero_accent.color = PALETTE.CORAL
	hero_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_copy.add_child(hero_accent)

	var achievement_heading := Label.new()
	achievement_heading.text = "YOUR SEASON AT A GLANCE"
	achievement_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.7))
	achievement_heading.add_theme_font_size_override("font_size", 19)
	achievement_heading.add_theme_color_override("font_color", PALETTE.NAVY)
	finale.add_child(achievement_heading)

	var achievement_list := GridContainer.new()
	achievement_list.name = "FinaleAchievementList"
	achievement_list.columns = 2
	achievement_list.add_theme_constant_override("h_separation", 10)
	achievement_list.add_theme_constant_override("v_separation", 10)
	finale.add_child(achievement_list)
	_add_finale_milestone(achievement_list, "✓", "WEEKLY LOCALS", "Cleared", PALETTE.TEAL)
	_add_finale_milestone(achievement_list, "★", "LEAGUE CUP", "Champion", PALETTE.FRESH_YELLOW)
	_add_finale_milestone(
		achievement_list,
		"▣",
		"WINNING DECK",
		"%d cards" % _deck_total(run.get("deck", {})),
		PALETTE.PERIWINKLE
	)
	_add_finale_milestone(
		achievement_list,
		"$",
		"FINAL EARNINGS",
		"$%d" % int(run.get("money", 0)),
		PALETTE.CORAL
	)

	var road_ahead := PanelContainer.new()
	road_ahead.name = "FinaleTeaser"
	road_ahead.custom_minimum_size = Vector2(0, 112)
	road_ahead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road_ahead.add_theme_stylebox_override(
		"panel",
		_finale_panel_style(
			Color(PALETTE.LAVENDER_GLASS, 0.92),
			PALETTE.PERIWINKLE,
			16,
			Vector4(30, 16, 30, 18),
			0.14
		)
	)
	finale.add_child(road_ahead)
	var road_copy := VBoxContainer.new()
	road_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	road_copy.add_theme_constant_override("separation", 4)
	road_ahead.add_child(road_copy)
	var road_heading := Label.new()
	road_heading.text = "The Road Ahead"
	road_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	road_heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.75))
	road_heading.add_theme_font_size_override("font_size", 24)
	road_heading.add_theme_color_override("font_color", PALETTE.NAVY)
	road_copy.add_child(road_heading)
	var road_detail := Label.new()
	road_detail.name = "FinaleRoadDetail"
	road_detail.text = "Still working on getting multiple packs in and making the path all the way to worlds. Join the discord or comment your feedback to help make the game better!"
	road_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	road_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	road_detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.18))
	road_detail.add_theme_font_size_override("font_size", 15)
	road_detail.add_theme_color_override("font_color", PALETTE.NAVY_MUTED)
	road_copy.add_child(road_detail)

	var community_links := HBoxContainer.new()
	community_links.name = "FinaleCommunityLinks"
	community_links.add_theme_constant_override("separation", 10)
	finale.add_child(community_links)
	if not STEAM_STORE_URL.is_empty():
		var steam_button := _make_button("Wishlist on Steam")
		steam_button.name = "FinaleSteamWishlistButton"
		steam_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steam_button.custom_minimum_size.y = 46
		_style_season_result_button(steam_button, false)
		_connect_external_link(steam_button, STEAM_STORE_URL)
		community_links.add_child(steam_button)
	if not DISCORD_INVITE_URL.is_empty():
		var discord_button := _make_button("Join the Discord")
		discord_button.name = "FinaleDiscordButton"
		discord_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		discord_button.custom_minimum_size.y = 46
		_style_season_result_button(discord_button, true)
		_connect_external_link(discord_button, DISCORD_INVITE_URL)
		community_links.add_child(discord_button)

	var actions := HBoxContainer.new()
	actions.name = "FinaleActions"
	actions.add_theme_constant_override("separation", 10)
	finale.add_child(actions)
	var deck_button := _make_button("Review Winning Deck")
	deck_button.name = "FinaleDeckButton"
	deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_button.custom_minimum_size.y = 46
	_style_season_result_button(deck_button, false)
	_connect_pressed(deck_button, _show_deckbuilder)
	actions.add_child(deck_button)
	var title_button := _make_button("Return to Main Menu")
	title_button.name = "ThanksMainMenuButton"
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_button.custom_minimum_size.y = 46
	_style_season_result_button(title_button, false)
	_connect_pressed(title_button, _show_start)
	actions.add_child(title_button)

	if not _reduced_motion_enabled() and not _running_automated_test():
		hero.modulate.a = 0.0
		road_ahead.modulate.a = 0.0
		var finale_tween := create_tween()
		finale_tween.tween_property(hero, "modulate:a", 1.0, 0.28)
		finale_tween.tween_property(road_ahead, "modulate:a", 1.0, 0.32)


func _add_finale_milestone(parent: Node, symbol: String, title: String, status: String, accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 78)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_finale_panel_style(
			PALETTE.CREAM.lerp(accent, 0.10),
			PALETTE.NAVY,
			15,
			Vector4(18, 12, 18, 12),
			0.12
		)
	)
	parent.add_child(panel)
	var copy := HBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 12)
	panel.add_child(copy)
	var symbol_badge := PanelContainer.new()
	symbol_badge.custom_minimum_size = Vector2(44, 44)
	symbol_badge.add_theme_stylebox_override(
		"panel",
		_finale_panel_style(Color(accent, 0.22), accent, 12, Vector4(8, 6, 8, 6), 0.0)
	)
	copy.add_child(symbol_badge)
	var symbol_label := Label.new()
	symbol_label.text = symbol
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.78))
	symbol_label.add_theme_font_size_override("font_size", 23)
	symbol_label.add_theme_color_override("font_color", PALETTE.NAVY)
	symbol_badge.add_child(symbol_label)
	var heading := Label.new()
	heading.text = title
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", PALETTE.NAVY)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(heading)
	var detail := Label.new()
	detail.name = "FinaleMilestoneStatus"
	detail.text = status
	detail.custom_minimum_size = Vector2(100, 0)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.32))
	detail.add_theme_font_size_override("font_size", 18)
	detail.add_theme_color_override("font_color", accent.darkened(0.28))
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(detail)


func _finale_panel_style(
	fill: Color,
	border: Color,
	radius: int,
	margins: Vector4,
	shadow_strength: float
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	style.anti_aliasing = true
	if shadow_strength > 0.0:
		style.shadow_color = Color(PALETTE.NAVY, shadow_strength)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
	return style


func _add_finale_teaser(parent: Node, title: String, detail: String) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.68))
	heading.add_theme_font_size_override("font_size", 21)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
	box.add_child(heading)
	var copy := Label.new()
	copy.text = detail
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_theme_font_size_override("font_size", 13)
	copy.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	box.add_child(copy)


func _finish_pack_state() -> void:
	run.current_pack = []
	run.revealed_pack = []
	run.pack_index = 0
	run.pack_opened = false


func _current_pack_needs_attention() -> bool:
	var current_pack: Array = run.get("current_pack", [])
	if current_pack.is_empty():
		return false
	return int(run.get("pack_index", 0)) < current_pack.size()


func _add_event_result_summary(parent: Node) -> void:
	var summary: Dictionary = run.get("last_event_result", {})
	if summary.is_empty():
		return
	var made_record := bool(summary.get("made_record", false))
	var champion := bool(summary.get("season_champion", false))
	var run_over := bool(summary.get("run_over", false))
	var outcome := "Advanced"
	if champion:
		outcome = "Season Won"
	elif not made_record and run_over:
		outcome = "Season Ended"
	elif not made_record:
		outcome = "Retry Event"
	_add_body_text(parent, "%s Result: %s" % [String(summary.get("event_name", "Event")), outcome])
	_add_body_text(parent, "Record: %d-%d | Required: %d win(s) | Rounds: %d" % [
		int(summary.get("wins", 0)),
		int(summary.get("losses", 0)),
		int(summary.get("required_wins", 0)),
		int(summary.get("rounds", 0))
	])
	_add_body_text(parent, "Round earnings: $%d" % int(summary.get("round_cash_earned", 0)))
	if made_record:
		_add_body_text(parent, "Event prize: $%d | Prize packs: %d" % [
			int(summary.get("reward_money", 0)),
			int(summary.get("reward_packs", 0))
		])
		if not champion:
			_add_body_text(parent, "Next calendar event: %s" % String(summary.get("next_event_name", "Next Event")))
	else:
		_add_body_text(parent, "Season lives: %d/%d%s" % [
			int(summary.get("lives_remaining", 0)),
			int(summary.get("max_lives", 0)),
			" | Lost 1 life" if int(summary.get("lives_lost", 0)) > 0 else ""
		])
		if not run_over:
			_add_body_text(parent, "Retry available: %s stays selected on the calendar." % String(summary.get("event_name", "This event")))
	var primary_action := _season_result_primary_action()
	if not primary_action.is_empty():
		_add_body_text(parent, "Next step: %s" % String(primary_action.get("text", "Continue")))


func _generate_opponent(round_number: int, deck_metrics: Dictionary, event: Dictionary = {}) -> Dictionary:
	return tournament_service.generate_opponent(self, round_number, deck_metrics, event)


func _difficulty_opponent_quality_bonus() -> float:
	return tournament_service.difficulty_opponent_quality_bonus(self)


func _season_round_first_side() -> String:
	return tournament_service.season_round_first_side(self)


func _opponent_deck_for_round(opponent_archetype: String, round_number: int, event: Dictionary = {}, ai_difficulty: String = "easy") -> Dictionary:
	return tournament_service.opponent_deck_for_round(self, opponent_archetype, round_number, event, ai_difficulty)


func _weighted_meta_pick() -> String:
	var roll := rng.randf()
	var cursor := 0.0
	for archetype_id in ARCHETYPE_ORDER:
		cursor += float(run.meta.get(archetype_id, 0.0))
		if roll <= cursor:
			return String(archetype_id)
	return String(ARCHETYPE_ORDER.back())


func _predator_archetype(archetype_id: String) -> String:
	return run_state_service.predator_archetype(archetype_id)


func _simulate_combat_match(opponent: Dictionary, deck_metrics: Dictionary) -> Dictionary:
	return tournament_service.simulate_combat_match(self, opponent, deck_metrics)


func _estimate_match_probability(opponent: Dictionary, deck_metrics: Dictionary) -> float:
	return tournament_service.estimate_match_probability(self, opponent, deck_metrics)


func _matchup_tech_bonus(target_tags: Array) -> float:
	var bonus := 0.0
	for deck_source in [run.deck, run.sideboard]:
		var side_multiplier := 1.4 if deck_source == run.sideboard else 1.0
		for card_id in deck_source.keys():
			var card: Dictionary = cards_by_id[card_id]
			for modifier in card.get("matchupModifiers", []):
				if target_tags.has(modifier.get("target", "")):
					bonus += float(modifier.get("value", 0)) * int(deck_source[card_id]) * side_multiplier
	return min(bonus, 8.0)


func _update_meta_after_event(primary: String, wins: int, rounds: int) -> void:
	var performance := (float(wins) / float(rounds)) - 0.5
	run.meta[primary] = float(run.meta.get(primary, 0.5)) + performance * 0.10

	var dominant: String = _dominant_archetype()
	var predator: String = _predator_archetype(dominant)
	if float(run.meta.get(dominant, 0.0)) > 0.42:
		run.meta[predator] = float(run.meta.get(predator, 0.0)) + 0.04

	for archetype_id in ARCHETYPE_ORDER:
		run.meta[archetype_id] = max(0.12, float(run.meta.get(archetype_id, 0.0)) + rng.randf_range(-0.015, 0.015))

	_normalize_meta()

	var reports: Array = []
	var leader: String = _dominant_archetype()
	reports.append("%s is the deck people are talking about this week." % archetypes_by_id[leader].name)
	match leader:
		"spicy":
			reports.append("Hearty chefs are adding healing and Defending units to survive the early heat.")
		"hearty":
			reports.append("Sweet chefs are using draw and Prep support to out-value durable boards.")
		"sweet":
			reports.append("Spicy chefs are trying to end games before Sweet engines take over.")
		"fresh":
			reports.append("Spicy chefs are packing sweepers to clear Fresh token boards before the big serve.")
		"funky":
			reports.append("Fresh chefs are going wider to make Funky's one-for-one tricks less efficient.")

	if wins == rounds:
		reports.append("Your undefeated run is getting noticed. Expect sharper sideboards next week.")
	elif wins == 0:
		reports.append("The room is not adapting to you yet. That can be useful.")
	else:
		reports.append("The meta shifts a little, but nobody agrees on the best deck yet.")

	run.reports = reports


func _normalize_meta() -> void:
	run_state_service.normalize_meta(run)


func _dominant_archetype() -> String:
	return run_state_service.dominant_archetype(run)


func _show_meta() -> void:
	if _guard_run_over():
		return
	current_screen = "meta"
	_render_nav()
	_clear(content)
	_update_status()

	var panel := _add_panel(content, "Metagame Board")
	_add_body_text(panel, "The metagame changes after each tournament. Reports are intentionally partial, like real shop talk.")

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var share := float(run.meta.get(archetype_id, 0.0))
		var line := "%s: %d%% of expected locals field. %s" % [archetype.name, int(round(share * 100.0)), archetype.summary]
		_add_body_text(panel, line)

	var report_panel := _add_panel(content, "Reports")
	for line in run.reports:
		_add_body_text(report_panel, "• " + line)
	if _run_mode() == "season":
		_add_exit_to_store_button(content)


func _calculate_deck_metrics(deck: Dictionary, sideboard: Dictionary) -> Dictionary:
	return deck_metrics_service.calculate(deck, sideboard)


func _deck_is_legal() -> Dictionary:
	return run_state_service.deck_is_legal(run)


func _format_metrics(metrics: Dictionary) -> String:
	return "Primary: %s | Fit: %d%% | Score: %.1f\nSpeed %.1f | Power %.1f | Interaction %.1f | Resilience %.1f | Advantage %.1f | Consistency %.1f\nRole balance: %d%% | %s" % [
		archetypes_by_id[metrics.primary].name,
		int(round(float(metrics.fit) * 100.0)),
		float(metrics.score),
		float(metrics.speed),
		float(metrics.power),
		float(metrics.interaction),
		float(metrics.resilience),
		float(metrics.advantage),
		float(metrics.consistency),
		int(round(float(metrics.role_score) * 100.0)),
		metrics.curve_warning
	]


func _format_metrics_short(metrics: Dictionary) -> String:
	return "Starter score %.1f | Fit %d%% | %s" % [
		float(metrics.score),
		int(round(float(metrics.fit) * 100.0)),
		metrics.curve_warning
	]


func _owned_count(card_id: String) -> int:
	return run_state_service.owned_count(run, card_id)


func _deck_count(card_id: String) -> int:
	return run_state_service.deck_count(run, card_id)


func _sideboard_count(card_id: String) -> int:
	return run_state_service.sideboard_count(run, card_id)


func _available_count(card_id: String) -> int:
	return run_state_service.available_count(run, card_id)


func _deck_limit(card_id: String) -> int:
	return run_state_service.deck_limit(card_id)


func _deck_total(deck: Dictionary) -> int:
	return run_state_service.deck_total(deck)


func _add_to_collection(card_id: String, count: int) -> void:
	run_state_service.add_to_collection(run, card_id, count)


func _add_panel(parent: Node, title: String, accent: String = "#202734") -> VBoxContainer:
	var compact_duel := current_screen in ["kitchen_match", "tutorial"]
	var sketch_surface := _uses_sketch_interface() and not compact_duel
	var panel: PanelContainer
	if sketch_surface:
		panel = SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2.ZERO,
			SKETCH_UI_SCRIPT.PAPER.lerp(Color(accent), 0.08),
			SKETCH_UI_SCRIPT.INK,
			Color(accent),
			Vector4.ZERO,
			parent.get_child_count() % 2
		)
	else:
		panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not sketch_surface:
		var style := (
			UI_THEME_SCRIPT.dark_glass_style(Color("#576B72"), 1)
			if compact_duel
			else UI_THEME_SCRIPT.tinted_paper_style(Color(accent), 1)
		)
		panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8 if compact_duel else 12)
	margin.add_theme_constant_override("margin_right", 8 if compact_duel else 12)
	margin.add_theme_constant_override("margin_top", 6 if compact_duel else 10)
	margin.add_theme_constant_override("margin_bottom", 6 if compact_duel else 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4 if compact_duel else 6)
	box.set_meta("light_surface", not compact_duel or sketch_surface)
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title.to_upper() if sketch_surface else title
		if sketch_surface:
			label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
		else:
			label.add_theme_font_size_override("font_size", 14 if compact_duel else 18)
			label.add_theme_color_override("font_color", Color("#F3EFE4") if compact_duel else UI_THEME_SCRIPT.INK)
		box.add_child(label)

	return box


func _add_bordered_panel(parent: Node, title: String, accent: String, border: String, border_width: int = 2) -> VBoxContainer:
	var sketch_surface := _uses_sketch_interface()
	var panel: PanelContainer
	if sketch_surface:
		panel = SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2.ZERO,
			SKETCH_UI_SCRIPT.PAPER.lerp(Color(accent), 0.07),
			SKETCH_UI_SCRIPT.INK,
			Color(border),
			Vector4.ZERO,
			parent.get_child_count() % 2
		)
	else:
		panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not sketch_surface:
		var style := UI_THEME_SCRIPT.dark_glass_style(Color(border), border_width)
		panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	box.set_meta("light_surface", sketch_surface)
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title.to_upper() if sketch_surface else title
		if sketch_surface:
			label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
			label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
		else:
			label.add_theme_color_override("font_color", Color("#FFF9ED"))
		label.add_theme_font_size_override("font_size", 20)
		box.add_child(label)

	return box


func _add_card_panel(parent: Node, card_id: String, note: String = "") -> VBoxContainer:
	var card: Dictionary = cards_by_id[card_id]
	var accent := "#2d3442"
	match card.get("rarity", "common"):
		"common":
			accent = "#29313b"
		"uncommon":
			accent = "#243b36"
		"rare":
			accent = "#433823"
		"mythic":
			accent = "#472637"

	var box := _add_panel(parent, _card_display_name(card), accent)
	box.custom_minimum_size = Vector2(240, 0)

	var meta := "%s | %s | cost %d | $%d" % [
		card.rarity.capitalize(),
		_card_descriptor(card),
		int(card.cost),
		_card_price(card_id) if not run.is_empty() else int(card.value)
	]
	_add_body_text(box, meta)
	if note != "":
		var note_label := Label.new()
		note_label.text = note
		note_label.add_theme_color_override("font_color", Color("#ffe08a"))
		box.add_child(note_label)
	return box


func _archetype_label(archetype_id: String) -> String:
	if archetypes_by_id.has(archetype_id):
		return archetypes_by_id[archetype_id].name
	return "Neutral"


func _starter_label(archetype_id: String) -> String:
	var starter_name := _archetype_label(archetype_id)
	var affinity_symbol := _affinity_symbol(archetype_id)
	if affinity_symbol == "":
		return starter_name
	return "%s %s" % [affinity_symbol, starter_name]


func _card_archetype(card: Dictionary) -> String:
	return String(card.get("animalType", card.get("archetype", "neutral")))


func _affinity_label(archetype_id: String) -> String:
	return AFFINITY_VISUALS.label(archetype_id, _archetype_label(archetype_id))


func _affinity_symbol(archetype_id: String) -> String:
	return AFFINITY_VISUALS.symbol(archetype_id)


func _format_affinity_requirements(requirements: Array) -> String:
	return AFFINITY_VISUALS.format_requirements(requirements)


func _card_type_symbol(card_type: String) -> String:
	return AFFINITY_VISUALS.card_type_symbol(card_type)


func _card_type_label(card_type: String) -> String:
	return AFFINITY_VISUALS.card_type_label(card_type)


func _card_display_name(card: Dictionary) -> String:
	return AFFINITY_VISUALS.card_display_name(card)


func _card_classification_symbol(card: Dictionary) -> String:
	return AFFINITY_VISUALS.card_classification_symbol(card)


func _card_classification_label(card: Dictionary) -> String:
	return AFFINITY_VISUALS.card_classification_label(card)


func _card_descriptor(card: Dictionary) -> String:
	return AFFINITY_VISUALS.card_descriptor(card)


func _card_uses_authored_face(card: Dictionary) -> bool:
	return CARD_FACE_SCRIPT.supports_card(card)


func _make_card_face(card: Dictionary, minimum_size: Vector2 = Vector2(250, 355), animate_art: bool = true) -> Control:
	var face := CARD_FACE_SCRIPT.new()
	face.configure(card, _run_difficulty_id(), animate_art)
	face.custom_minimum_size = minimum_size
	return face


func _affinity_color(archetype_id: String) -> Color:
	match archetype_id:
		"spicy":
			return PALETTE.AFFINITY_SPICY
		"hearty":
			return PALETTE.AFFINITY_HEARTY
		"sweet":
			return PALETTE.AFFINITY_SWEET
		"fresh":
			return PALETTE.AFFINITY_FRESH
		"funky":
			return PALETTE.AFFINITY_FUNKY
		"neutral":
			return PALETTE.AFFINITY_NEUTRAL
		_:
			return PALETTE.AFFINITY_NEUTRAL


func _rarity_line_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#29233C")
		"uncommon":
			return Color("#314451")
		"rare":
			return Color("#443A52")
		"mythic":
			return Color("#49334E")
		_:
			return Color("#29233C")


func _rarity_text_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#D7CBE0")
		"uncommon":
			return Color("#A7BFA1")
		"rare":
			return Color("#D5C16D")
		"mythic":
			return Color("#D38BBC")
		_:
			return Color("#D7CBE0")


func _add_body_text(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if current_screen in ["kitchen_match", "tutorial"]:
		label.add_theme_font_size_override("font_size", 12)
	elif _uses_sketch_interface():
		label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.08))
	label.add_theme_color_override(
		"font_color",
		SKETCH_UI_SCRIPT.MUTED_INK
		if _uses_sketch_interface()
		else UI_THEME_SCRIPT.INK_MUTED
		if bool(parent.get_meta("light_surface", false))
		else Color("#D8DFEC")
	)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 38 if _uses_sketch_interface() else 30)
	_style_button(button, "default")
	return button


func _style_button(button: Button, variant: String = "default") -> void:
	button.set_meta("ui_button_variant", variant)
	button.set_meta("ui_button_variant_inferred", false)
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.remove_theme_stylebox_override(style_name)
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_disabled_color",
		"icon_normal_color",
		"icon_hover_color",
		"icon_pressed_color",
		"icon_disabled_color",
	]:
		button.remove_theme_color_override(color_name)
	button.theme_type_variation = (
		SKETCH_THEME_SCRIPT.button_variation(variant)
		if _uses_sketch_interface()
		else UI_THEME_SCRIPT.button_variation(variant)
	)
	var symbol_id := _button_symbol_id(button.text)
	if not symbol_id.is_empty():
		MATERIAL_SYMBOLS.apply_to_button(
			button,
			symbol_id,
			20,
			HORIZONTAL_ALIGNMENT_RIGHT if symbol_id == "forward" else HORIZONTAL_ALIGNMENT_LEFT
		)
	if not _uses_sketch_interface() and button.get_node_or_null("AudaciousButtonMotion") == null:
		var motion := BUTTON_MOTION_SCRIPT.new()
		motion.name = "AudaciousButtonMotion"
		button.add_child(motion)


func _style_cycle_button(button: Button, icon: Texture2D) -> void:
	button.set_meta("ui_button_variant", "secondary")
	button.set_meta("ui_button_variant_inferred", false)
	button.text = ""
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.theme_type_variation = UI_THEME_SCRIPT.button_variation("default")
	button.add_theme_constant_override("icon_max_width", 24)


func _button_symbol_id(label: String) -> String:
	var normalized := label.to_lower()
	if "close" in normalized:
		return "close"
	if "back" in normalized or "exit" in normalized or "return" in normalized:
		return "back"
	if "abandon" in normalized or "delete" in normalized:
		return "delete"
	if "restore" in normalized or "restart" in normalized:
		return "restart"
	if "settings" in normalized or "options" in normalized:
		return "settings"
	if "upgrade" in normalized:
		return "upgrade"
	if "remove" in normalized:
		return "remove"
	if normalized.begins_with("start"):
		return "forward"
	if "save" in normalized:
		return "save"
	if "calendar" in normalized or "season" in normalized or "event" in normalized:
		return "calendar"
	if "buy" in normalized or "sell" in normalized or "wallet" in normalized or "$" in normalized:
		return "money"
	if "draft" in normalized or "deck" in normalized:
		return "cards"
	if "tutorial" in normalized or "how to play" in normalized or "kitchen" in normalized:
		return "library"
	if "debug" in normalized or "menu" in normalized:
		return "settings"
	if "continue" in normalized or "resume" in normalized:
		return "forward"
	if "new run" in normalized or "worlds" in normalized:
		return "play"
	if (
		"start" in normalized
		or "open" in normalized
		or "next" in normalized
		or "play" in normalized
		or "register" in normalized
	):
		return "forward"
	return ""


func _update_status() -> void:
	if run.is_empty():
		match current_screen:
			"tutorial":
				status_label.text = "Learn to Play"
			"season_setup":
				status_label.text = "New Run"
			"settings":
				status_label.text = "Settings"
			"draft":
				status_label.text = "Draft Night"
			_:
				status_label.text = "Main Menu"
		return
	var main_count := _deck_total(run.deck)
	if String(run.get("run_loop", "")) == "route":
		status_label.text = "Starter City | Life %d/%d | $%d | Deck %d" % [
			int(run.get("life", 0)), int(run.get("max_life", 40)), int(run.get("money", 0)), main_count
		]
		return
	var difficulty := _difficulty_data(_run_difficulty_id())
	if _run_mode() == "season":
		var life_text := " | Lives %d/%d" % [
			int(run.get("season_lives", 0)),
			int(run.get("max_season_lives", 0))
		]
		status_label.text = "Week %d | $%d | %s Border%s | Main %d" % [
			int(run.week),
			int(run.money),
			String(difficulty.get("name", "Black")),
			life_text,
			main_count
		]
		return
	var side_count := _deck_total(run.sideboard)
	status_label.text = "Week %d | $%d | %s Border | Main %d | Side %d/%d" % [
		int(run.week),
		int(run.money),
		String(difficulty.get("name", "Black")),
		main_count,
		side_count,
		SIDEBOARD_SIZE
	]


func _set_footer(text: String) -> void:
	if footer_label == null:
		return
	footer_label.text = "[color=#5D5148]" + text + "[/color]"


func _guard_run_over() -> bool:
	if run.is_empty():
		_show_start()
		return true
	if bool(run.get("run_over", false)):
		_show_tournament_result(run.get("last_result", ["The run is over."]), false)
		return true
	return false


func _save_run() -> void:
	_capture_live_kitchen_match_state()
	var resume_screen := current_screen
	if resume_screen == "settings" and is_instance_valid(suspended_tabletop) and suspended_tabletop_screen == "kitchen_match":
		resume_screen = "kitchen_match"
	var result: Dictionary = _autosave_now(resume_screen) if autosave_enabled else run_state_service.save_run(run, resume_screen)
	_set_footer(result.message)


func _load_run_from_disk() -> void:
	autosave_suspended = true
	var result: Dictionary = run_state_service.load_run()
	if not result.ok:
		autosave_suspended = false
		_set_footer(result.message)
		return
	_prepare_loaded_run(result)
	_resume_loaded_screen(String(result.get("resume_screen", "")))
	_set_footer(result.message)
	call_deferred("_finish_autosave_resume")


func _quit_from_title() -> void:
	get_tree().quit()


func _continue_run_to_shop() -> void:
	autosave_suspended = true
	var result: Dictionary = run_state_service.load_run()
	if not bool(result.get("ok", false)):
		autosave_suspended = false
		_set_footer(String(result.get("message", "No valid saved run found.")))
		_show_start()
		return
	_prepare_loaded_run(result)
	_resume_loaded_screen(String(result.get("resume_screen", "")))
	_set_footer("Welcome back. Your last checkpoint has been restored.")
	call_deferred("_finish_autosave_resume")


func _prepare_loaded_run(result: Dictionary) -> void:
	run = result.run
	if String(run.get("run_mode", "season")) == "debug" and not _development_tools_enabled():
		run.run_mode = "season"
	_ensure_route_run(run)
	route_run_service.normalize_run(run)
	if not run.has("kitchen_opponent"):
		var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
		run.kitchen_opponent = _predator_archetype(String(metrics.primary))
	if not run.has("shop") or not (run.shop is Array):
		_generate_shop_inventory()


func _ensure_route_run(target_run: Dictionary) -> void:
	if String(target_run.get("run_mode", "season")) != "season" or String(target_run.get("run_loop", "")) == "route":
		return
	var starter_id := String(target_run.get("starter", "spicy"))
	if not archetypes_by_id.has(starter_id):
		starter_id = "spicy"
		target_run.starter = starter_id
	var source_deck: Dictionary = target_run.get("deck", {})
	if source_deck.is_empty():
		source_deck = _deck_entries_to_dict(archetypes_by_id[starter_id].get("starterDeck", []))
		target_run.deck = source_deck
	var migration_seed := absi(hash("%s:%s" % [starter_id, JSON.stringify(source_deck)]))
	if migration_seed == 0:
		migration_seed = 1
	route_run_service.initialize_run(target_run, migration_seed)
	_generate_shop_inventory_for_run(target_run)


func _generate_shop_inventory_for_run(target_run: Dictionary) -> void:
	var previous_run := run
	run = target_run
	shop_economy_service.generate_shop_inventory(target_run, _current_primary_archetype())
	run = previous_run


func _resume_loaded_screen(saved_screen: String) -> void:
	if bool(run.get("run_over", false)):
		if String(run.get("run_loop", "")) == "route":
			if bool(run.get("demo_complete", false)):
				_show_route_victory()
			else:
				_show_route_game_over()
		else:
			_show_tournament_result(run.get("last_result", ["The run is over."]), false)
		return
	if String(run.get("run_loop", "")) == "route":
		match saved_screen:
			"kitchen_match":
				_resume_autosaved_kitchen_match()
			"route_reward":
				_show_route_card_reward()
			"route_shop":
				_show_route_shop()
			"route_remove":
				_show_route_remove_card()
			"route_upgrade":
				_show_route_upgrade_card()
			"route_event":
				_show_route_event()
			_:
				if not run.get("pending_route_node", {}).is_empty():
					_resolve_pending_route_node()
				else:
					_show_run_map()
		return
	match saved_screen:
		"shop":
			_show_shop()
		"packs":
			_show_packs()
		"deck":
			_show_deckbuilder()
		"season":
			_show_season_run()
		"tournament":
			_show_tournament()
		"meta":
			_show_meta()
		"result":
			var summary: Dictionary = run.get("last_event_result", {})
			_show_tournament_result(run.get("last_result", []), bool(summary.get("run_continues", true)))
		"kitchen_match":
			_resume_autosaved_kitchen_match()
		"path_choice":
			if _development_tools_enabled():
				_show_run_path_choice()
			else:
				_show_season_run()
		"card_lab":
			if _development_tools_enabled():
				_show_card_effect_lab()
			else:
				_show_shop()
		_:
			match _run_mode():
				"season":
					_show_season_run()
				"unselected":
					_show_run_path_choice()
				_:
					_show_shop()


func _resume_autosaved_kitchen_match() -> void:
	var saved_match: Dictionary = run.get("kitchen_match", {}).duplicate(true)
	var saved_snapshot: Dictionary = saved_match.get("snapshot", {}).duplicate(true)
	if bool(run.get("route_battle", {}).get("active", false)):
		_start_route_battle(true)
		return
	if not _season_tournament_active():
		_start_debug_kitchen_match(saved_snapshot)
		return
	var saved_result: Dictionary = run.get("kitchen_match_result", {}).duplicate(true)
	_start_season_tournament_round(true, true, saved_snapshot)
	if bool(saved_result.get("game_over", false)):
		run.kitchen_match = saved_match
		run.kitchen_match_result = saved_result
		call_deferred("_show_season_round_result_popup", String(saved_result.get("winner", "opponent")) == "player")
	else:
		_set_footer("Battle restored at the saved turn.")


func _finish_autosave_resume() -> void:
	last_autosave_fingerprint = _run_fingerprint()
	last_autosave_screen = current_screen
	autosave_poll_elapsed = 0.0
	autosave_suspended = false


func _migrate_legacy_run_archetypes() -> void:
	run_state_service.migrate_legacy_run_archetypes(run)
