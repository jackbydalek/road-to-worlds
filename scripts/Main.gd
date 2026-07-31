extends Control

const MAIN_DECK_SIZE := 20
const MAX_MAIN_DECK_SIZE := 30
const STARTING_CHEF_LIFE := 20
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SAVE_PATH := "user://kitchen_table_season_run.json"
const SETTINGS_PATH := "user://kitchen_table_settings.json"
const DEVELOPMENT_FLAGS := ["--dev", "--debug-menu"]
const RESOLUTION_OPTIONS := [
	Vector2i(1280, 720),
	Vector2i(1440, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const TEXT_SCALE_OPTIONS := [0.9, 1.0, 1.1, 1.25]
const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"
const ARCHETYPE_ORDER := ["spicy", "hearty", "sweet"]
const PACK_AFFINITY_ORDER := ["spicy", "hearty", "sweet", "fresh", "funky"]
const DRAFT_NIGHT_ID := "draft_night"
const DEMO_STARTER_ORDER := ["spicy", "hearty", "sweet", DRAFT_NIGHT_ID]
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
const CARD_EFFECT_LAB_SCRIPT := preload("res://scripts/CardEffectLab.gd")
const AFFINITY_VISUALS := preload("res://scripts/AffinityVisuals.gd")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const UI_THEME_SCRIPT := preload("res://scripts/ui/KitchenGlassTheme.gd")
const SKETCH_THEME_SCRIPT := preload("res://scripts/ui/SketchTheme.gd")
const WORKSPACE_THEME_SCRIPT := preload("res://scripts/ui/WorkspaceTheme.gd")
const BUTTON_MOTION_SCRIPT := preload("res://scripts/ui/AudaciousButtonMotion.gd")
const SKETCH_UI_SCRIPT := preload("res://scripts/ui/SketchUIComponents.gd")
const WORKSPACE_UI_SCRIPT := preload("res://scripts/ui/WorkspaceUIComponents.gd")
const WIRED_TITLE_DOODLES_SCRIPT := preload("res://scripts/ui/WiredTitleDoodles.gd")
const CARD_SHOP_MUSIC := preload("res://assets/audio/card_shop_background.mp3")
const ICON_ARROW_OUT := preload("res://assets/ui/audacious/arrow-square-out-bold.svg")
const ICON_BOWL := preload("res://assets/ui/audacious/bowl-food-bold.svg")
const ICON_CALENDAR := preload("res://assets/ui/audacious/calendar-blank-bold.svg")
const ICON_CARET_LEFT := preload("res://assets/ui/audacious/caret-circle-left-bold.svg")
const ICON_CARET_RIGHT := preload("res://assets/ui/audacious/caret-circle-right-bold.svg")
const ICON_CLOSE := preload("res://assets/ui/audacious/x-bold.svg")
const ICON_ADD := preload("res://assets/ui/audacious/currency-circle-dollar-bold.svg")
const ICON_CURRENCY := preload("res://assets/ui/audacious/currency-circle-dollar-bold.svg")
const ICON_CUBE := preload("res://assets/ui/audacious/cube-bold.svg")
const ICON_FOLDER := preload("res://assets/ui/audacious/folder.svg")
const ICON_MENU := preload("res://assets/ui/audacious/dots-three-vertical-bold.svg")
const ICON_STAR := preload("res://assets/ui/audacious/star-four-bold.svg")
const GREYBOX_CAMERA_DEMO_SCENE := preload("res://scenes/GreyboxCameraDemo.tscn")
const TABLETOP_3D_PROTOTYPE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")

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
var card_effect_lab: RefCounted

var cards: Array = []
var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var tournaments_by_id: Dictionary = {}

var run: Dictionary = {}
var current_screen := "start"
var deckbuilder_sort_mode := SORT_AFFINITY
var season_setup_archetype_index := 0
var season_setup_difficulty_index := 0
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
	"text_scale": 1.0,
	"high_contrast": false,
	"reduced_motion": false,
}
var settings_return_screen := "start"
var settings_path := SETTINGS_PATH
var deckbuilder_return_screen := ""
var deckbuilder_return_shop_view := ""


func _ready() -> void:
	var scoped_ui_font := AFFINITY_VISUALS.default_ui_font_with_symbols()
	base_ui_theme = UI_THEME_SCRIPT.build(scoped_ui_font)
	sketch_ui_theme = SKETCH_THEME_SCRIPT.build(scoped_ui_font)
	workspace_ui_theme = WORKSPACE_THEME_SCRIPT.build(scoped_ui_font)
	theme = base_ui_theme
	autosave_enabled = not _running_automated_test()
	_load_player_settings()
	_ensure_audio_buses()
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
		MAIN_DECK_SIZE,
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
	if _run_fingerprint() != last_autosave_fingerprint:
		_autosave_now(current_screen)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if autosave_enabled and not run.is_empty():
		_autosave_now(current_screen)
	get_tree().quit()


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
		"text_scale": 1.0,
		"high_contrast": false,
		"reduced_motion": false,
	}


func _load_player_settings() -> void:
	var defaults := _default_player_settings()
	player_settings = defaults.duplicate(true)
	if not FileAccess.file_exists(settings_path):
		return
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	for key in defaults:
		if parsed.has(key):
			player_settings[key] = parsed[key]
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
	var requested_scale := float(player_settings.get("text_scale", 1.0))
	var closest_scale := 1.0
	var closest_distance := INF
	for option in TEXT_SCALE_OPTIONS:
		var distance := absf(float(option) - requested_scale)
		if distance < closest_distance:
			closest_distance = distance
			closest_scale = float(option)
	player_settings.text_scale = closest_scale
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
	var text_scale := float(player_settings.get("text_scale", 1.0))
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
	return str(JSON.stringify(run).hash())


func _autosave_now(resume_screen: String = "") -> Dictionary:
	if not autosave_enabled or autosave_suspended or run.is_empty():
		return {"ok": false, "message": "Autosave skipped."}
	var target_screen := resume_screen if resume_screen != "" else current_screen
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
	autosave_label.tooltip_text = "Saving"
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
	if autosave_tween != null and autosave_tween.is_valid():
		autosave_tween.kill()
	autosave_label.visible = true
	autosave_label.text = "!"
	autosave_label.tooltip_text = "Could not save"
	autosave_label.rotation = 0.0
	autosave_label.scale = Vector2.ONE
	autosave_label.modulate = Color.WHITE
	autosave_label.add_theme_color_override("font_color", UI_THEME_SCRIPT.DANGER)
	autosave_tween = create_tween()
	autosave_tween.tween_interval(1.4)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.4)
	autosave_tween.tween_callback(func() -> void: autosave_label.visible = false)


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#E9DFC9")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

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
	title_label.text = "Kitchen Table: Road to Worlds"
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
	autosave_label.tooltip_text = "Saving"
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
	archetypes_by_id = content_catalog.archetypes_by_id
	boosters_by_id = content_catalog.boosters_by_id
	tournaments_by_id = content_catalog.tournaments_by_id


func _clear(node: Node) -> void:
	if node == content:
		_stop_card_shop_music()
	for child in node.get_children():
		# Screen rebuilds are often triggered by button signals; queue deletion so the
		# emitting button is not freed while Godot is still dispatching its signal.
		child.queue_free()


func _play_card_shop_music() -> void:
	if card_shop_music_player == null:
		card_shop_music_player = AudioStreamPlayer.new()
		card_shop_music_player.name = "CardShopMusic"
		var music_stream := CARD_SHOP_MUSIC.duplicate() as AudioStreamMP3
		music_stream.loop = true
		card_shop_music_player.stream = music_stream
		card_shop_music_player.bus = &"Music"
		card_shop_music_player.volume_db = -10.0
		add_child(card_shop_music_player)
	if not card_shop_music_player.playing:
		card_shop_music_player.play()


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
	dimmer.color = Color(0.16, 0.10, 0.07, 0.70)
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

	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(780, 690),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.ORANGE,
		Vector4(46, 38, 46, 42),
		1
	)
	panel.name = "StarterDeckPreviewPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var banner := SKETCH_UI_SCRIPT.make_section_banner(
		"%s DECK" % display_name.to_upper(),
		"Review the cards before committing to this season.",
		Vector2(650, 96),
		SKETCH_UI_SCRIPT.TEAL
	)
	banner.name = "StarterDeckPreviewBanner"
	layout.add_child(banner)

	if draft_night:
		var empty_panel := SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2(0, 420),
			Color("#FFF3CF"),
			SKETCH_UI_SCRIPT.INK,
			SKETCH_UI_SCRIPT.MUSTARD,
			Vector4(42, 34, 42, 34),
			0
		)
		empty_panel.name = "DraftNightDeckPreviewEmptyState"
		layout.add_child(empty_panel)
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
		heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
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
			detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
			empty_copy.add_child(detail)
	else:
		var summary := Label.new()
		summary.name = "StarterDeckPreviewSummary"
		summary.text = "%d cards  •  %d unique cards" % [total_cards, entries.size()]
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
		summary.add_theme_font_size_override("font_size", 18)
		summary.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
		layout.add_child(summary)

		var list_panel := SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2(0, 420),
			Color("#FFF8E8"),
			SKETCH_UI_SCRIPT.INK,
			SKETCH_UI_SCRIPT.ORANGE,
			Vector4(22, 16, 22, 16),
			0
		)
		layout.add_child(list_panel)
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

	var close_button := SKETCH_UI_SCRIPT.make_button(
		"CLOSE DECK LIST",
		Vector2(360, 82),
		true,
		25,
		false
	)
	close_button.name = "CloseStarterDeckPreviewButton"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_connect_pressed(close_button, _close_starter_deck_preview)
	layout.add_child(close_button)


func _starter_deck_preview_entries(starter_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not archetypes_by_id.has(starter_id):
		return entries
	var archetype: Dictionary = archetypes_by_id[starter_id]
	var deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
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
	count.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.ORANGE)
	row.add_child(count)

	var name := Label.new()
	name.text = _card_display_name(card)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.12))
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	row.add_child(name)

	var classification := Label.new()
	classification.text = "%s  •  %s" % [String(entry.type), String(entry.affinity)]
	classification.custom_minimum_size = Vector2(270, 0)
	classification.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	classification.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	classification.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	classification.add_theme_font_size_override("font_size", 15)
	classification.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	row.add_child(classification)
	row.mouse_entered.connect(func() -> void: _queue_starter_deck_hover_preview(row, card_id))
	row.mouse_exited.connect(_hide_starter_deck_hover_preview)


func _create_starter_deck_hover_preview(overlay: Control) -> void:
	starter_deck_hover_request_id += 1
	starter_deck_hover_preview = SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(310, 448),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(16, 16, 16, 18),
		1
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
	overlay.name = "StarterDeckPreviewClosing"
	overlay.queue_free()


func _connect_pressed(button: Button, callback: Callable) -> void:
	button.pressed.connect(callback, CONNECT_DEFERRED)


func _show_start() -> void:
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

	var saved_result: Dictionary = run_state_service.load_run()
	var has_save := bool(saved_result.get("ok", false))
	var screen := _make_front_door_screen("BootLanding")

	var paper_background := ColorRect.new()
	paper_background.name = "WiredTitleBackground"
	paper_background.color = Color("#F3ECD9")
	paper_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(paper_background)

	var doodles := WIRED_TITLE_DOODLES_SCRIPT.new()
	doodles.name = "WiredTitleDoodles"
	doodles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(doodles)

	var title_banner := SKETCH_UI_SCRIPT.make_title_panel(
		"TOPDECK TO WORLDS",
		"Build your deck. Survive the season. Earn your seat at Worlds.",
		Vector2(1080, 230)
	)
	title_banner.name = "BootTitleBanner"
	_anchor_rect(title_banner, 0.5, 0.5, 0.0, 0.0, -540, 40, 540, 270)
	screen.add_child(title_banner)

	var landing_actions := VBoxContainer.new()
	landing_actions.name = "BootLandingPanel"
	landing_actions.add_theme_constant_override("separation", 6)
	_anchor_rect(landing_actions, 0.5, 0.5, 0.0, 0.0, -245, 326, 245, 650)
	screen.add_child(landing_actions)

	var game_start_button := SKETCH_UI_SCRIPT.make_button(
		"START GAME",
		Vector2(490, 102),
		true,
		36,
		false
	)
	game_start_button.name = "GameStartButton"
	_connect_pressed(game_start_button, _show_game_start)
	landing_actions.add_child(game_start_button)

	var collection_button := SKETCH_UI_SCRIPT.make_button(
		"COLLECTION",
		Vector2(490, 102),
		false,
		34,
		true
	)
	collection_button.name = "TitleCollectionButton"
	collection_button.disabled = not has_save
	collection_button.tooltip_text = (
		"Open the saved season's collection and deck."
		if has_save
		else "Start a season to build a collection."
	)
	_connect_pressed(collection_button, _open_saved_collection)
	landing_actions.add_child(collection_button)

	var exit_button := SKETCH_UI_SCRIPT.make_button(
		"EXIT GAME",
		Vector2(490, 102),
		false,
		34,
		false
	)
	exit_button.name = "ExitGameButton"
	_connect_pressed(exit_button, _quit_from_title)
	landing_actions.add_child(exit_button)

	var season_note := Label.new()
	season_note.name = "WiredSeasonNote"
	season_note.text = "20 CARDS   •   THREE ROUNDS   •   ONE SHOT AT WORLDS"
	season_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	season_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	season_note.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
	season_note.add_theme_font_size_override("font_size", 18)
	season_note.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
	_anchor_rect(season_note, 0.5, 0.5, 0.0, 0.0, -380, 752, 380, 792)
	screen.add_child(season_note)

	var left_caption := Label.new()
	left_caption.text = "BUILD\nSHOP\nCOMPETE"
	left_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_caption.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	left_caption.add_theme_font_size_override("font_size", 25)
	left_caption.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	_anchor_rect(left_caption, 0.0, 0.0, 0.0, 0.0, 102, 622, 282, 716)
	screen.add_child(left_caption)

	var right_caption := Label.new()
	right_caption.text = "LOCALS\nLEAGUE CUP\nWORLDS"
	right_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_caption.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	right_caption.add_theme_font_size_override("font_size", 25)
	right_caption.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	_anchor_rect(right_caption, 1.0, 1.0, 0.0, 0.0, -310, 622, -90, 716)
	screen.add_child(right_caption)

	var options_panel := SKETCH_UI_SCRIPT.make_panel(
		Vector2(310, 260 if _development_tools_enabled() else 190),
		Vector4(30, 27, 30, 31)
	)
	options_panel.name = "TitleOptionsPanel"
	options_panel.visible = false
	options_panel.z_index = 20
	_anchor_rect(options_panel, 1.0, 1.0, 1.0, 1.0, -430, -286, -104, -78)
	screen.add_child(options_panel)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 2)
	options_panel.add_child(options)

	var tutorial_button := SKETCH_UI_SCRIPT.make_button(
		"HOW TO PLAY",
		Vector2(250, 66),
		false,
		21,
		false
	)
	tutorial_button.name = "StartTutorialButton"
	_connect_pressed(tutorial_button, _show_tutorial)
	options.add_child(tutorial_button)

	var settings_button := SKETCH_UI_SCRIPT.make_button(
		"SETTINGS",
		Vector2(250, 66),
		false,
		21,
		true
	)
	settings_button.name = "TitleSettingsButton"
	_connect_pressed(settings_button, _show_settings)
	options.add_child(settings_button)

	if _development_tools_enabled():
		var debug_link := SKETCH_UI_SCRIPT.make_button(
			"DEBUG MENU",
			Vector2(250, 66),
			false,
			21,
			true
		)
		debug_link.name = "OpenDebugMenuButton"
		_connect_pressed(debug_link, _show_debug_starter_selection)
		options.add_child(debug_link)

	var options_button := SKETCH_UI_SCRIPT.make_button(
		"MORE",
		Vector2(126, 74),
		false,
		22,
		true
	)
	options_button.name = "TitleOptionsButton"
	options_button.tooltip_text = "How to Play and Settings"
	options_button.z_index = 20
	_anchor_rect(options_button, 1.0, 1.0, 1.0, 1.0, -154, -106, -28, -32)
	_connect_pressed(options_button, func() -> void: options_panel.visible = not options_panel.visible)
	screen.add_child(options_button)


func _show_game_start() -> void:
	current_screen = "game_start"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Pick up where you left off or begin a new season.")

	var saved_result: Dictionary = run_state_service.load_run()
	var has_save := bool(saved_result.get("ok", false))
	var saved_run: Dictionary = saved_result.get("run", {}) if has_save else {}
	var saved_run_finished := has_save and bool(saved_run.get("run_over", false))
	var saved_starter_id := String(saved_run.get("starter", ""))
	var saved_starter_name := "No saved deck"
	if has_save:
		saved_starter_name = (
			"Draft Night Deck"
			if bool(saved_run.get("drafted", false))
			else _archetype_label(saved_starter_id) if archetypes_by_id.has(saved_starter_id) else "Custom Deck"
		)

	var screen := _make_front_door_screen("GameStartGateway")
	var paper_background := ColorRect.new()
	paper_background.color = Color("#F3ECD9")
	paper_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(paper_background)

	var gateway_banner := SKETCH_UI_SCRIPT.make_section_banner(
		"GAME STATUS",
		"Continue your season or start fresh.",
		Vector2(1060, 126),
		SKETCH_UI_SCRIPT.TEAL
	)
	gateway_banner.name = "GameStatusBanner"
	_anchor_rect(gateway_banner, 0.5, 0.5, 0.0, 0.0, -530, 34, 530, 160)
	screen.add_child(gateway_banner)

	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 42)
	_anchor_rect(summary_row, 0.5, 0.5, 0.0, 0.0, -545, 186, 545, 532)
	screen.add_child(summary_row)

	var deck_frame := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(390, 346),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.ORANGE,
		Vector4(42, 32, 42, 34),
		0
	)
	deck_frame.name = "SavedDeckFrame"
	summary_row.add_child(deck_frame)

	var deck_center := CenterContainer.new()
	deck_frame.add_child(deck_center)
	var deck_art := _make_menu_deck_art(
		saved_starter_id,
		saved_starter_name,
		has_save and bool(saved_run.get("drafted", false)),
		Vector2(198, 270)
	)
	deck_art.name = "SavedDeckArtwork"
	deck_center.add_child(deck_art)

	var status_column := VBoxContainer.new()
	status_column.custom_minimum_size = Vector2(570, 346)
	summary_row.add_child(status_column)

	var status_outer := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(570, 346),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(40, 34, 40, 34),
		1
	)
	status_outer.name = "SavedGameStatusFrame"
	status_column.add_child(status_outer)
	var status_box := VBoxContainer.new()
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_box.add_theme_constant_override("separation", 10)
	status_outer.add_child(status_box)
	if has_save:
		var difficulty := _difficulty_data(String(saved_run.get("difficulty", "white")))
		_add_sketch_status_text(status_box, "%s  •  WEEK %d  •  ROUND %d" % [
			String(saved_run.get("active_event_name", "Season in progress")),
			int(saved_run.get("week", 1)),
			int(saved_run.get("active_tournament", {}).get("round", 0))
		], 21)
		_add_sketch_status_text(status_box, "$%d  •  %s BORDER  •  LIVES %d/%d" % [
			int(saved_run.get("money", 0)),
			String(difficulty.get("name", "Black")),
			int(saved_run.get("season_lives", 0)),
			int(saved_run.get("max_season_lives", 0))
		], 18)
		_add_sketch_status_text(status_box, "%d CARDS OWNED  •  MAIN DECK %d/%d" % [
			_deck_total(saved_run.get("collection", {})),
			_deck_total(saved_run.get("deck", {})),
			MAIN_DECK_SIZE
		], 18)
		_add_sketch_status_text(
			status_box,
			"This season has ended. Start a New Game to continue playing."
			if saved_run_finished
			else "Continue returns to the card shop.",
			17
		)
	else:
		_add_sketch_status_text(status_box, "NO SAVED SEASON YET", 25)
		_add_sketch_status_text(status_box, "Choose New Game to select a starter deck or begin Draft Night.", 18)

	var deck_action_row := HBoxContainer.new()
	deck_action_row.alignment = BoxContainer.ALIGNMENT_END
	status_box.add_child(deck_action_row)
	var current_deck_button := SKETCH_UI_SCRIPT.make_button(
		"VIEW DECK",
		Vector2(152, 62),
		false,
		19,
		true
	)
	current_deck_button.name = "SavedDeckCollectionButton"
	current_deck_button.tooltip_text = "Open the saved collection and deck"
	current_deck_button.disabled = not has_save
	_connect_pressed(current_deck_button, _open_saved_collection)
	deck_action_row.add_child(current_deck_button)

	var action_column := VBoxContainer.new()
	action_column.add_theme_constant_override("separation", 6)
	_anchor_rect(action_column, 0.5, 0.5, 0.0, 0.0, -245, 566, 245, 774)
	screen.add_child(action_column)

	var continue_button := SKETCH_UI_SCRIPT.make_button(
		"CONTINUE",
		Vector2(490, 98),
		true,
		35,
		false
	)
	continue_button.name = "ContinueRunButton"
	continue_button.disabled = not has_save or saved_run_finished
	_connect_pressed(continue_button, _continue_run_to_shop)
	action_column.add_child(continue_button)

	var new_game_button := SKETCH_UI_SCRIPT.make_button(
		"NEW GAME",
		Vector2(490, 98),
		false,
		34,
		true
	)
	new_game_button.name = "NewGameButton"
	_connect_pressed(new_game_button, _show_season_run_setup)
	action_column.add_child(new_game_button)

	var menu_panel := _make_title_route_menu(screen, "GameStartOptionsPanel")
	var menu_actions := menu_panel.get_node("TitleRouteMenuActions") as VBoxContainer
	var back_button := SKETCH_UI_SCRIPT.make_button(
		"BACK TO TITLE",
		Vector2(250, 58),
		false,
		19,
		false
	)
	back_button.name = "GameStartBackButton"
	_connect_pressed(back_button, _show_start)
	menu_actions.add_child(back_button)

	var menu_button := SKETCH_UI_SCRIPT.make_button(
		"MORE",
		Vector2(126, 74),
		false,
		22,
		true
	)
	menu_button.name = "GameStartOptionsButton"
	menu_button.tooltip_text = "Back, How to Play, and Settings"
	_anchor_rect(menu_button, 1.0, 1.0, 1.0, 1.0, -154, -106, -28, -32)
	_connect_pressed(menu_button, func() -> void: menu_panel.visible = not menu_panel.visible)
	screen.add_child(menu_button)


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
	current_screen = "settings"
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Changes are saved automatically.")

	var header := _add_bordered_panel(content, "SETTINGS", "#173B39", "#78AAA3", 3)
	header.name = "SettingsHeader"
	_add_body_text(header, "Set up the game for your screen, speakers, and play style.")

	var columns := HBoxContainer.new()
	columns.name = "SettingsColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	content.add_child(columns)

	var display_panel := _add_bordered_panel(columns, "DISPLAY", "#1E302E", "#78AAA3", 2)
	display_panel.name = "SettingsDisplayPanel"
	display_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display_panel.custom_minimum_size = Vector2(420, 0)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.name = "FullscreenToggle"
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = bool(player_settings.fullscreen)
	fullscreen_toggle.focus_mode = Control.FOCUS_ALL
	display_panel.add_child(fullscreen_toggle)

	var resolution_row := HBoxContainer.new()
	resolution_row.name = "ResolutionRow"
	resolution_row.add_theme_constant_override("separation", 10)
	display_panel.add_child(resolution_row)
	var resolution_label := Label.new()
	resolution_label.text = "Resolution"
	resolution_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_row.add_child(resolution_label)
	var resolution_select := OptionButton.new()
	resolution_select.name = "ResolutionSelect"
	resolution_select.custom_minimum_size = Vector2(190, 40)
	for option in RESOLUTION_OPTIONS:
		resolution_select.add_item("%d × %d" % [option.x, option.y])
		if (
			int(player_settings.resolution[0]) == option.x
			and int(player_settings.resolution[1]) == option.y
		):
			resolution_select.select(resolution_select.item_count - 1)
	resolution_select.disabled = bool(player_settings.fullscreen)
	resolution_row.add_child(resolution_select)

	var text_scale_row := HBoxContainer.new()
	text_scale_row.name = "TextScaleRow"
	text_scale_row.add_theme_constant_override("separation", 10)
	display_panel.add_child(text_scale_row)
	var text_scale_label := Label.new()
	text_scale_label.text = "Text size"
	text_scale_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scale_row.add_child(text_scale_label)
	var text_scale_select := OptionButton.new()
	text_scale_select.name = "TextScaleSelect"
	text_scale_select.custom_minimum_size = Vector2(190, 40)
	for option in TEXT_SCALE_OPTIONS:
		text_scale_select.add_item("%d%%" % roundi(float(option) * 100.0))
		if is_equal_approx(float(option), float(player_settings.text_scale)):
			text_scale_select.select(text_scale_select.item_count - 1)
	text_scale_row.add_child(text_scale_select)

	var audio_panel := _add_bordered_panel(columns, "AUDIO", "#30291E", "#E2B84C", 2)
	audio_panel.name = "SettingsAudioPanel"
	audio_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_panel.custom_minimum_size = Vector2(420, 0)
	_add_volume_setting(audio_panel, "Master", "master_volume")
	_add_volume_setting(audio_panel, "Music", "music_volume")
	_add_volume_setting(audio_panel, "Sound effects", "sfx_volume")

	var accessibility_panel := _add_bordered_panel(content, "ACCESSIBILITY", "#272338", "#A798D4", 2)
	accessibility_panel.name = "SettingsAccessibilityPanel"
	var high_contrast_toggle := CheckButton.new()
	high_contrast_toggle.name = "HighContrastToggle"
	high_contrast_toggle.text = "High-contrast text"
	high_contrast_toggle.tooltip_text = "Adds a strong outline to interface text."
	high_contrast_toggle.button_pressed = bool(player_settings.high_contrast)
	accessibility_panel.add_child(high_contrast_toggle)
	var reduced_motion_toggle := CheckButton.new()
	reduced_motion_toggle.name = "ReducedMotionToggle"
	reduced_motion_toggle.text = "Reduce menu motion"
	reduced_motion_toggle.tooltip_text = "Removes pulsing, bounce, and decorative menu movement."
	reduced_motion_toggle.button_pressed = bool(player_settings.reduced_motion)
	accessibility_panel.add_child(reduced_motion_toggle)

	var actions := HBoxContainer.new()
	actions.name = "SettingsActions"
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var back_button := _make_button("Back")
	back_button.name = "SettingsBackButton"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(back_button, "action")
	_connect_pressed(back_button, _return_from_settings)
	actions.add_child(back_button)
	var reset_button := _make_button("Restore Defaults")
	reset_button.name = "SettingsResetButton"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_pressed(reset_button, _reset_player_settings)
	actions.add_child(reset_button)

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
	high_contrast_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.high_contrast = enabled
		_commit_player_settings()
	)
	reduced_motion_toggle.toggled.connect(func(enabled: bool) -> void:
		player_settings.reduced_motion = enabled
		_commit_player_settings()
	)


func _add_volume_setting(parent: Node, label_text: String, setting_key: String) -> void:
	var box := VBoxContainer.new()
	box.name = "%sVolumeSetting" % label_text.replace(" ", "")
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var heading_row := HBoxContainer.new()
	box.add_child(heading_row)
	var heading := Label.new()
	heading.text = label_text
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var value_label := Label.new()
	value_label.name = "%sVolumeValue" % label_text.replace(" ", "")
	value_label.text = "%d%%" % roundi(float(player_settings.get(setting_key, 80.0)))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 58
	heading_row.add_child(value_label)
	var slider := HSlider.new()
	slider.name = "%sVolumeSlider" % label_text.replace(" ", "")
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = float(player_settings.get(setting_key, 80.0))
	slider.custom_minimum_size = Vector2(0, 34)
	slider.value_changed.connect(func(value: float) -> void:
		player_settings[setting_key] = value
		value_label.text = "%d%%" % roundi(value)
		_apply_audio_settings()
		_save_player_settings()
	)
	box.add_child(slider)


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
		"game_start":
			_show_game_start()
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
	var tutorial_game = TABLETOP_3D_PROTOTYPE_SCENE.instantiate()
	tutorial_game.configure_tutorial()
	tutorial_game.custom_minimum_size = Vector2(0, 820)
	tutorial_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_game.exit_requested.connect(_show_start)
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
	current_screen = "season_setup"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose a starter path and border, then begin the season.")

	var selected_starter_id := String(DEMO_STARTER_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	var difficulty := _difficulty_data(selected_difficulty_id)
	var draft_night_selected := selected_starter_id == DRAFT_NIGHT_ID

	var starter_title := "Draft Night"
	var starter_summary := "Build your season deck one choice at a time from rotating three-card offers."
	var starter_detail := "20 picks  •  Opening signpost Meal  •  Drafted cards become your collection"
	if not draft_night_selected:
		var archetype: Dictionary = archetypes_by_id[selected_starter_id]
		var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
		var metrics := _calculate_deck_metrics(starter_deck, {})
		starter_title = _archetype_label(selected_starter_id)
		starter_summary = String(archetype.get("summary", ""))
		starter_detail = "%s\nStarter deck: %d cards  •  Predator: %s" % [
			_format_metrics_short(metrics),
			_deck_total(starter_deck),
			_affinity_label(_predator_archetype(selected_starter_id))
		]

	var screen := _make_front_door_screen("SeasonRegistration")
	var paper_background := ColorRect.new()
	paper_background.color = Color("#F3ECD9")
	paper_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(paper_background)

	var setup_banner := SKETCH_UI_SCRIPT.make_section_banner(
		"CHOOSE YOUR RUN",
		"Pick a starter path and a season border.",
		Vector2(680, 104),
		SKETCH_UI_SCRIPT.ORANGE
	)
	setup_banner.name = "SeasonSetupBanner"
	_anchor_rect(setup_banner, 0.5, 0.5, 0.0, 0.0, -340, 14, 340, 118)
	screen.add_child(setup_banner)

	var back_button := SKETCH_UI_SCRIPT.make_button(
		"← BACK",
		Vector2(146, 72),
		false,
		22,
		false
	)
	back_button.name = "SeasonSetupBackButton"
	back_button.tooltip_text = "Back to saved-game menu"
	_anchor_rect(back_button, 0.0, 0.0, 0.0, 0.0, 24, 26, 170, 98)
	_connect_pressed(back_button, _show_game_start)
	screen.add_child(back_button)

	var selection_row := HBoxContainer.new()
	selection_row.add_theme_constant_override("separation", 42)
	_anchor_rect(selection_row, 0.5, 0.5, 0.0, 0.0, -620, 132, 620, 812)
	screen.add_child(selection_row)

	var starter_column := VBoxContainer.new()
	starter_column.custom_minimum_size = Vector2(700, 0)
	starter_column.add_theme_constant_override("separation", 10)
	selection_row.add_child(starter_column)

	var starter_accent := SKETCH_UI_SCRIPT.MUSTARD if draft_night_selected else _affinity_color(selected_starter_id)
	var deck_card := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(700, 490),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		starter_accent,
		Vector4(38, 30, 38, 32),
		season_setup_archetype_index
	)
	deck_card.name = "SeasonStarterCard"
	deck_card.set_meta("starter_id", selected_starter_id)
	starter_column.add_child(deck_card)

	var deck_stage := Control.new()
	deck_stage.custom_minimum_size = Vector2(624, 428)
	deck_card.add_child(deck_stage)

	var deck_art := _make_menu_deck_art(
		selected_starter_id,
		starter_title,
		draft_night_selected,
		Vector2(236, 292)
	)
	deck_art.name = "SelectedStarterArtwork"
	_anchor_rect(deck_art, 0.5, 0.5, 0.0, 0.0, -118, 22, 118, 314)
	deck_stage.add_child(deck_art)

	var previous_deck := _make_sketch_arrow_button(-1, Vector2(78, 78))
	previous_deck.name = "PreviousStarterButton"
	_anchor_rect(previous_deck, 0.0, 0.0, 0.5, 0.5, 10, -39, 88, 39)
	_connect_pressed(previous_deck, func() -> void: _shift_season_setup_archetype(-1))
	deck_stage.add_child(previous_deck)

	var next_deck := _make_sketch_arrow_button(1, Vector2(78, 78))
	next_deck.name = "NextStarterButton"
	_anchor_rect(next_deck, 1.0, 1.0, 0.5, 0.5, -88, -39, -10, 39)
	_connect_pressed(next_deck, func() -> void: _shift_season_setup_archetype(1))
	deck_stage.add_child(next_deck)

	var deck_name_banner := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(350, 76),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		starter_accent,
		Vector4(20, 10, 20, 12),
		season_setup_archetype_index + 1
	)
	deck_name_banner.name = "StarterNameBanner"
	_anchor_rect(deck_name_banner, 0.5, 0.5, 1.0, 1.0, -175, -84, 175, -8)
	deck_stage.add_child(deck_name_banner)
	var deck_name_label := Label.new()
	deck_name_label.text = starter_title.to_upper()
	deck_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_name_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.78))
	deck_name_label.add_theme_font_size_override("font_size", 30)
	deck_name_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	deck_name_banner.add_child(deck_name_label)

	var info_bar := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(700, 122),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		starter_accent,
		Vector4(24, 18, 24, 20),
		2
	)
	info_bar.name = "StarterInfoBar"
	starter_column.add_child(info_bar)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 14)
	info_bar.add_child(info_row)
	_add_starter_info_symbol(info_row, selected_starter_id, draft_night_selected)
	var info_copy := VBoxContainer.new()
	info_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_copy.add_theme_constant_override("separation", 1)
	info_row.add_child(info_copy)
	var info_title := Label.new()
	info_title.text = "%s Deck" % starter_title if not draft_night_selected else "Draft Night"
	info_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.62))
	info_title.add_theme_font_size_override("font_size", 22)
	info_title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	info_copy.add_child(info_title)
	var info_detail := Label.new()
	info_detail.text = "%s  •  %s" % [starter_summary, starter_detail.replace("\n", "  •  ")]
	info_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.12))
	info_detail.add_theme_font_size_override("font_size", 15)
	info_detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	info_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_copy.add_child(info_detail)
	var cycle_deck_button := SKETCH_UI_SCRIPT.make_button(
		"LIST",
		Vector2(88, 66),
		false,
		19,
		true
	)
	cycle_deck_button.name = "StarterDeckContentsButton"
	cycle_deck_button.tooltip_text = "View this deck's contents"
	_connect_pressed(cycle_deck_button, func() -> void: _show_starter_deck_preview(selected_starter_id))
	info_row.add_child(cycle_deck_button)

	var difficulty_column := VBoxContainer.new()
	difficulty_column.custom_minimum_size = Vector2(498, 0)
	difficulty_column.add_theme_constant_override("separation", 8)
	selection_row.add_child(difficulty_column)

	var difficulty_card := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(498, 438),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		Color(String(difficulty.get("accent", "#171717"))),
		Vector4(40, 30, 40, 34),
		season_setup_difficulty_index
	)
	difficulty_card.name = "SeasonBorderCard"
	difficulty_card.set_meta("difficulty_id", selected_difficulty_id)
	difficulty_column.add_child(difficulty_card)
	var difficulty_box := VBoxContainer.new()
	difficulty_box.add_theme_constant_override("separation", 8)
	difficulty_card.add_child(difficulty_box)

	var border_title := Label.new()
	border_title.text = "%s BORDER" % String(difficulty.get("name", "Black")).to_upper()
	border_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	border_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.78))
	border_title.add_theme_font_size_override("font_size", 30)
	border_title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	difficulty_box.add_child(border_title)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_row.add_theme_constant_override("separation", 18)
	difficulty_box.add_child(difficulty_row)

	var previous_difficulty := _make_sketch_arrow_button(-1, Vector2(64, 68))
	previous_difficulty.name = "PreviousBorderButton"
	_connect_pressed(previous_difficulty, func() -> void: _shift_season_setup_difficulty(-1))
	difficulty_row.add_child(previous_difficulty)

	var border_preview := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(210, 228),
		Color("#F7F2E6"),
		Color(String(difficulty.get("border_color", "#090909"))),
		Color(String(difficulty.get("accent", "#171717"))),
		Vector4(24, 24, 24, 26),
		season_setup_difficulty_index + 1
	)
	border_preview.name = "SeasonBorderPreview"
	var effect_label := Label.new()
	effect_label.text = String(difficulty.get("rules_text", "Base season rules."))
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.14))
	effect_label.add_theme_font_size_override("font_size", 17)
	effect_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	border_preview.add_child(effect_label)
	difficulty_row.add_child(border_preview)

	var next_difficulty := _make_sketch_arrow_button(1, Vector2(64, 68))
	next_difficulty.name = "NextBorderButton"
	_connect_pressed(next_difficulty, func() -> void: _shift_season_setup_difficulty(1))
	difficulty_row.add_child(next_difficulty)

	var border_stats := Label.new()
	border_stats.text = "Starting money $%d  •  %d season %s" % [
		run_state_service.starting_money_for_difficulty(selected_difficulty_id),
		1 if selected_difficulty_id == "silver" else 3,
		"life" if selected_difficulty_id == "silver" else "lives"
	]
	border_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	border_stats.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.14))
	border_stats.add_theme_font_size_override("font_size", 16)
	border_stats.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	difficulty_box.add_child(border_stats)

	var pips := HBoxContainer.new()
	pips.name = "SeasonBorderPagination"
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 6)
	difficulty_column.add_child(pips)
	for index in DIFFICULTY_ORDER.size():
		var pip := SKETCH_UI_SCRIPT.make_pip(
			index == season_setup_difficulty_index,
			Color(String(difficulty.get("accent", "#171717")))
		)
		pip.name = "SeasonBorderPip%d" % index
		pips.add_child(pip)

	var route_hint := Label.new()
	route_hint.text = "STARTS AT DRAFT NIGHT" if draft_night_selected else "STARTS AT THE CARD SHOP"
	route_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_hint.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
	route_hint.add_theme_font_size_override("font_size", 15)
	route_hint.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.ORANGE)
	difficulty_column.add_child(route_hint)

	var play_button := SKETCH_UI_SCRIPT.make_button(
		"START THE SEASON",
		Vector2(498, 98),
		true,
		32,
		false
	)
	play_button.name = "ConfirmSeasonStartButton"
	_connect_pressed(play_button, _confirm_season_run_setup)
	difficulty_column.add_child(play_button)


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

	var heading_panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 88),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.MUSTARD if signpost_step else SKETCH_UI_SCRIPT.TEAL,
		Vector4(28, 16, 28, 18),
		drafted_count
	)
	heading_panel.name = "DraftModePanel"
	heading_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(heading_panel)
	var heading := HBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 12)
	heading_panel.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	var title := Label.new()
	title.text = "PICK A CARD"
	title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.86))
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	heading_copy.add_child(title)
	var instruction := Label.new()
	instruction.text = (
		"Choose your opening dual-flavor Meal." if signpost_step
		else "Pick %d of %d  •  Click one card to add it to your deck." % [drafted_count + 1, DRAFT_DECK_SIZE]
	)
	instruction.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.14))
	instruction.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	heading_copy.add_child(instruction)
	var progress := Label.new()
	progress.text = "%02d / %02d" % [drafted_count, DRAFT_DECK_SIZE]
	progress.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.82))
	progress.add_theme_font_size_override("font_size", 24)
	progress.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
	heading.add_child(progress)

	var workspace := HBoxContainer.new()
	workspace.name = "DraftWorkspace"
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 12)
	content.add_child(workspace)

	var offer_row := HBoxContainer.new()
	offer_row.name = "DraftOfferRow"
	offer_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_row.add_theme_constant_override("separation", 12)
	workspace.add_child(offer_row)

	for card_id_value in draft_offer:
		var card_id := String(card_id_value)
		var card: Dictionary = cards_by_id[card_id]
		var card_accent := _affinity_color(_card_archetype(card))
		var choice_panel := SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2(218, 344),
			SKETCH_UI_SCRIPT.PAPER,
			SKETCH_UI_SCRIPT.INK,
			card_accent,
			Vector4(14, 14, 14, 16),
			draft_offer.find(card_id)
		)
		choice_panel.name = "DraftOffer_%s" % card_id
		choice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		offer_row.add_child(choice_panel)
		var choice := VBoxContainer.new()
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.add_theme_constant_override("separation", 6)
		choice.set_meta("light_surface", true)
		choice_panel.add_child(choice)
		choice_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		choice_panel.tooltip_text = "Pick " + _card_display_name(card)
		if _card_uses_authored_face(card):
			var face := _make_card_face(card, Vector2(188, 267), true)
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			choice.add_child(face)
		else:
			_add_body_text(choice, "%s • %s" % [String(card.get("rarity", "common")).capitalize(), _card_descriptor(card)])
			_add_body_text(choice, String(card.get("text", "")))
		var pick_label := Label.new()
		pick_label.name = "DraftPick_%s" % card_id
		pick_label.text = "PICK THIS CARD"
		pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick_label.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.48))
		pick_label.add_theme_font_size_override("font_size", 13)
		pick_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
		pick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice.add_child(pick_label)
		var selected_card_id := card_id
		choice_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_draft_pick(selected_card_id, choice_panel)
		)
		choice_panel.mouse_entered.connect(func() -> void:
			choice_panel.set("fill_color", Color("#FFF1C9"))
			choice_panel.queue_redraw()
		)
		choice_panel.mouse_exited.connect(func() -> void:
			choice_panel.set("fill_color", SKETCH_UI_SCRIPT.PAPER)
			choice_panel.queue_redraw()
		)

	_add_draft_deck_rail(workspace)
	_create_draft_hover_preview()
	_add_draft_distribution_charts(content)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var back_button := SKETCH_UI_SCRIPT.make_button(
		"ABANDON DRAFT",
		Vector2(0, 66),
		false,
		22,
		true
	)
	back_button.name = "AbandonDraftButton"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_pressed(back_button, _show_start)
	actions.add_child(back_button)


func _add_draft_deck_rail(parent: HBoxContainer) -> void:
	var rail_panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(292, 330),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(18, 16, 18, 18),
		1
	)
	rail_panel.name = "DraftDeckRail"
	rail_panel.custom_minimum_size = Vector2(292, 330)
	rail_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	rail_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(rail_panel)
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 6)
	rail_panel.add_child(rail)
	var heading := Label.new()
	heading.text = "YOUR DECK"
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.76))
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	rail.add_child(heading)
	var hint := Label.new()
	hint.text = "%d/%d cards  •  Hover to inspect" % [_draft_total(), DRAFT_DECK_SIZE]
	hint.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	rail.add_child(hint)

	var scroll_box := ScrollContainer.new()
	scroll_box.custom_minimum_size = Vector2(0, 244)
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
		var tile := SKETCH_UI_SCRIPT.make_rough_panel(
			Vector2(70, 116),
			SKETCH_UI_SCRIPT.PAPER,
			_affinity_color(_card_archetype(card)).darkened(0.28),
			Color.TRANSPARENT,
			Vector4(3, 3, 3, 3),
			entries.find(entry)
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
	draft_hover_preview = SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(326, 466),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL,
		Vector4(12, 12, 12, 12),
		1
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
		heading.text = "KEYWORDS"
		heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.66))
		heading.add_theme_font_size_override("font_size", 12)
		heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
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
	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2.ZERO,
		Color("#FFF5D9"),
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.MUSTARD,
		Vector4(12, 9, 12, 10),
		1
	)
	panel.name = "%s_%s" % [node_prefix, keyword_id]
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 4)
	panel.add_child(copy)
	var title := Label.new()
	title.text = String(tooltip.title)
	title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.68))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.ORANGE)
	copy.add_child(title)
	var body := Label.new()
	body.text = String(tooltip.body)
	body.custom_minimum_size = Vector2(214, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font())
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	copy.add_child(body)


func _hide_draft_hover_preview() -> void:
	draft_hover_request_id += 1
	if draft_hover_preview != null and is_instance_valid(draft_hover_preview):
		draft_hover_preview.visible = false


func _add_draft_distribution_charts(parent: VBoxContainer) -> void:
	var charts := HBoxContainer.new()
	charts.name = "DraftDistributionCharts"
	charts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charts.add_theme_constant_override("separation", 12)
	parent.add_child(charts)
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
	var chart_panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2.ZERO,
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.TEAL if "FLAVOR" in title else SKETCH_UI_SCRIPT.ORANGE,
		Vector4(18, 14, 18, 16),
		0 if "TYPE" in title else 1
	)
	chart_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(chart_panel)
	var chart := VBoxContainer.new()
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.add_theme_constant_override("separation", 6)
	chart_panel.add_child(chart)
	var chart_title := Label.new()
	chart_title.text = title
	chart_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	chart_title.add_theme_font_size_override("font_size", 19)
	chart_title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
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
		bar_track.custom_minimum_size = Vector2(38, 88)
		var track_style := StyleBoxFlat.new()
		track_style.bg_color = Color("#E4DAC4")
		track_style.border_color = SKETCH_UI_SCRIPT.INK
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
		label.tooltip_text = String(row[1])
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
		column.add_child(label)


func _draft_pick(card_id: String, source: Control = null) -> void:
	if draft_pick_animating or current_screen != "draft" or not draft_offer.has(card_id) or not cards_by_id.has(card_id):
		return
	var deck_limit := int(cards_by_id[card_id].get("deckLimit", 3))
	if int(draft_deck.get(card_id, 0)) >= deck_limit:
		return
	if source != null and is_instance_valid(source) and not _running_automated_test() and not _reduced_motion_enabled():
		draft_pick_animating = true
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var flying_card := _make_card_face(cards_by_id[card_id], Vector2(188, 267), false)
		flying_card.name = "DraftPickAnimation"
		flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flying_card.z_index = 1700
		flying_card.global_position = source.get_global_rect().get_center() - Vector2(94, 133)
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
		if card_id == "" or int(draft_deck.get(card_id, 0)) >= int(card.get("deckLimit", 3)):
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
	_generate_shop_inventory()
	match mode:
		"season":
			_set_footer("Season started with %s on %s Border." % [
				_starter_label(archetype_id),
				String(_difficulty_data(difficulty_id).get("name", "Black"))
			])
			_show_shop()
		_:
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
	_add_body_text(intro, "Starter: %s | Money: $%d | Main deck: %d cards | Legal range %d–%d" % [
		starter_name,
		int(run.get("money", 0)),
		_deck_total(run.get("deck", {})),
		MAIN_DECK_SIZE,
		MAX_MAIN_DECK_SIZE
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
				"summary": "Opponents upgrade their decks and decisions earlier.",
				"rules_text": "Rivals get a quality bump, swap weak starter cards sooner, and advance one AI skill tier earlier."
			}
		"yellow":
			return {
				"id": "yellow",
				"name": "Yellow",
				"accent": "#44391e",
				"border_color": "#f0c94a",
				"summary": "The season starts on a tighter budget.",
				"rules_text": "You start with less money, so every pack and single matters more."
			}
		"silver":
			return {
				"id": "silver",
				"name": "Silver",
				"accent": "#30343a",
				"border_color": "#cfd6df",
				"summary": "Tournament fields bring more refined decks.",
				"rules_text": "Rivals receive a modest deck-quality boost, but their AI tier does not advance as early as Blue."
			}
		"gold":
			return {
				"id": "gold",
				"name": "Gold",
				"accent": "#42351c",
				"border_color": "#e2b84c",
				"summary": "First player is no longer guaranteed.",
				"rules_text": "Each tournament round may change which chef takes the opening turn."
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
	theme = (
		workspace_ui_theme
		if _uses_workspace_interface()
		else sketch_ui_theme
		if _uses_sketch_interface()
		else base_ui_theme
	)
	var compact_duel := current_screen in ["kitchen_match", "tutorial"]
	var compact_deck := current_screen == "deck" and _run_mode() == "season"
	var title_flow := current_screen in ["start", "game_start", "season_setup"]
	var store_chrome := current_screen == "shop" and _run_mode() == "season"
	var hide_footer := title_flow or compact_duel or compact_deck or (current_screen == "shop" and _run_mode() == "season")
	if header_bar != null:
		header_bar.visible = not compact_duel and not title_flow and not store_chrome
	if nav != null:
		nav.visible = not compact_duel and not title_flow and not store_chrome
	footer_label.visible = not hide_footer
	footer_label.custom_minimum_size = Vector2(0, 0 if hide_footer else 78)
	var compact_margin := compact_duel or compact_deck
	root_margin.add_theme_constant_override("margin_left", 6 if compact_margin else (14 if store_chrome else (0 if title_flow else 18)))
	root_margin.add_theme_constant_override("margin_right", 6 if compact_margin else (14 if store_chrome else (0 if title_flow else 18)))
	root_margin.add_theme_constant_override("margin_top", 4 if compact_margin else (10 if store_chrome else (0 if title_flow else 14)))
	root_margin.add_theme_constant_override("margin_bottom", 4 if compact_margin else (10 if store_chrome else (0 if title_flow else 14)))
	shell.add_theme_constant_override("separation", 3 if compact_margin else (0 if title_flow or store_chrome else 10))
	content.add_theme_constant_override("separation", 4 if compact_margin else (0 if title_flow else 10))
	if scroll != null:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck or title_flow else ScrollContainer.SCROLL_MODE_AUTO
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck or title_flow else ScrollContainer.SCROLL_MODE_AUTO


func _uses_sketch_interface() -> bool:
	return current_screen in [
		"start",
		"game_start",
		"season_setup",
		"draft",
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
			"settings",
		]


func _uses_workspace_interface() -> bool:
	return current_screen in ["deck", "singles"]


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


func _show_season_run() -> void:
	season_hub_screen.show(self)


func _show_shop() -> void:
	# Leaving an untouched sealed pack keeps it available for later. Once the
	# wrapper has been opened, returning to the store finalizes the pack just as
	# the Done button does, including safely collecting any face-down cards.
	if current_screen == "packs" and bool(run.get("pack_opened", false)):
		shop_economy_service.reveal_all_cards(run, _current_primary_archetype())
		_finish_pack_state()
	if _run_mode() == "season":
		_show_shop_overworld()
	else:
		card_shop_screen.show(self)
		_play_card_shop_music()


func _show_shop_overworld() -> void:
	if _guard_run_over():
		return
	current_screen = "shop"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Your next round is waiting. Stock up, tune your deck, or talk to the clerk.")

	var shop_world := GREYBOX_CAMERA_DEMO_SCENE.instantiate() as Control
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
	content.add_child(shop_world)
	shop_world.call("configure_shop", _shop_overworld_context())
	_play_card_shop_music()


func _shop_overworld_context() -> Dictionary:
	var active: Dictionary = run.get("active_tournament", {})
	return {
		"money": int(run.get("money", 0)),
		"prize_packs": int(run.get("prize_packs", 0)),
		"event_name": String(_selected_season_event().get("name", "Weekly Locals")),
		"difficulty_name": String(_difficulty_data(_run_difficulty_id()).get("name", "Black")),
		"tournament_active": _season_tournament_active(),
		"tournament_round": int(active.get("round", 1)),
		"singles": _shop_overworld_single_entries(),
		"trade_entries": _shop_overworld_trade_entries(),
		"meta_entries": _shop_overworld_meta_entries(),
		"reports": run.get("reports", []).duplicate(true)
	}


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


func _buy_single_from_overworld(card_id: String) -> void:
	var result: Dictionary = shop_economy_service.buy_single(run, card_id)
	var message := String(result.get("message", "Could not buy that card."))
	_set_footer(message)
	_update_status()
	var shop_world := content.find_child("CardShopOverworld", true, false)
	if shop_world != null:
		shop_world.call("update_shop_context", _shop_overworld_context(), message)


func _shop_overworld_trade_entries() -> Array:
	var entries: Array = []
	for card_id_value in run.get("collection", {}).keys():
		var card_id := String(card_id_value)
		if not cards_by_id.has(card_id):
			continue
		var owned := _owned_count(card_id)
		var in_use := _deck_count(card_id) + _sideboard_count(card_id)
		var keep: int = max(_deck_limit(card_id), in_use)
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
		shop_world.call("update_shop_context", _shop_overworld_context(), message, "trade")


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
	_add_body_text(panel, "Two local players are comparing binders. They will buy copies beyond the safe deck limit without removing cards used by your deck or sideboard.")
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
	return String(_calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {})).primary)


func _strongest_pack_affinity() -> String:
	if run.is_empty():
		return String(PACK_AFFINITY_ORDER[0])
	return shop_economy_service.strongest_affinity_for_deck(run.get("deck", {}), PACK_AFFINITY_ORDER)


func _show_deckbuilder() -> void:
	if current_screen != "deck":
		deckbuilder_return_screen = current_screen
		deckbuilder_return_shop_view = ""
		if current_screen == "shop":
			var shop_world := content.find_child("CardShopOverworld", true, false)
			if shop_world != null and shop_world.has_method("current_menu_view"):
				deckbuilder_return_shop_view = String(shop_world.call("current_menu_view"))
	deckbuilder_screen.show(self)


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
		"game_start":
			_show_game_start()
		"new_game":
			_show_new_game_menu()
		"path_choice":
			_show_run_path_choice()
		"season":
			_show_season_run()
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
	var demo := GREYBOX_CAMERA_DEMO_SCENE.instantiate() as Control
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



func _start_debug_kitchen_match() -> void:
	if _guard_run_over():
		return
	var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
	var opponent_archetype := _predator_archetype(String(metrics.get("primary", ARCHETYPE_ORDER[0])))
	var opponent_deck := _opponent_deck_for_round(opponent_archetype, 1)
	_begin_kitchen_match(
		run.get("deck", {}),
		opponent_deck,
		"Practice %s Chef" % _archetype_label(opponent_archetype),
		false,
		rng.randi()
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


func _begin_kitchen_match(player_deck: Dictionary, opponent_deck: Dictionary, opponent_name: String, tournament_round: bool, seed_value: int, first_side: String = "player", ai_difficulty: String = "easy") -> void:
	_dismiss_round_result_popup()
	current_screen = "kitchen_match"
	_render_nav()
	_clear(content)
	_update_status()
	var metrics := _calculate_deck_metrics(player_deck, {})
	var player_name := String(archetypes_by_id.get(String(metrics.get("primary", ARCHETYPE_ORDER[0])), {}).get("name", "Your Kitchen"))
	var kitchen_game = TABLETOP_3D_PROTOTYPE_SCENE.instantiate()
	var active: Dictionary = run.get("active_tournament", {})
	var match_context := {
		"tournament_round": tournament_round,
		"event_id": String(active.get("event_id", "")) if tournament_round else "",
		"event_name": String(active.get("event_name", "Tournament")) if tournament_round else "Practice Match",
		"round": int(active.get("round", 0)) if tournament_round else 0,
		"rounds": int(active.get("rounds", 0)) if tournament_round else 0
	}
	kitchen_game.configure_match(
		player_deck,
		opponent_deck,
		player_name,
		opponent_name,
		seed_value,
		first_side,
		"Forfeit / Return to Tournament" if tournament_round else "Exit Practice Match",
		ai_difficulty,
		_run_difficulty_id(),
		match_context
	)
	kitchen_game.custom_minimum_size = Vector2(0, 820)
	kitchen_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kitchen_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kitchen_game.match_finished.connect(_on_kitchen_match_finished)
	kitchen_game.exit_requested.connect(_on_kitchen_exit_requested)
	run.kitchen_match = {
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
	run.kitchen_match_result = {"game_over": false}
	content.add_child(kitchen_game)


func _resume_kitchen_match() -> void:
	if _season_tournament_active():
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
	if _season_tournament_active():
		_set_footer("Kitchen match complete. Choose how to continue.")
		call_deferred("_show_season_round_result_popup", String(result.get("winner", "opponent")) == "player")
	else:
		_set_footer("Kitchen match complete. Return to the shop when ready.")


func _show_season_round_result_popup(won: bool) -> void:
	if not _season_tournament_active() or current_screen != "kitchen_match":
		return
	_dismiss_round_result_popup()

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
	earnings.add_theme_color_override("font_color", Color("#2D6F6A"))
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
	if _season_tournament_active():
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
		_add_body_text(panel, "Season mode uses live Kitchen Table matches for each round.")
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


func _start_season_tournament_round(reuse_current_opponent: bool = false, reuse_saved_setup: bool = false) -> void:
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
	_set_footer("%s round %d started. Win the Kitchen Table match to add a win to your record." % [
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
		ai_difficulty
	)


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
		void fragment() {
			vec2 point = (UV - vec2(0.5)) * vec2(1.78, 1.0);
			float edge = 1.0 - smoothstep(radius, radius + 0.035, length(point));
			COLOR = vec4(0.035, 0.045, 0.065, edge);
		}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("radius", 0.0)
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
	label.add_theme_color_override("font_color", Color("#f3efe4"))
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
	screen.add_theme_constant_override("separation", 10)
	content.add_child(screen)

	_add_tournament_result_hero(screen, result_summary, made_record, champion, run_over)
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
	var accent := SKETCH_UI_SCRIPT.MUSTARD if champion else (SKETCH_UI_SCRIPT.TEAL if made_record else SKETCH_UI_SCRIPT.ORANGE)
	var fill := Color("#FFF2CB") if champion else (Color("#EAF4EC") if made_record else Color("#F9E8DE"))
	var hero := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 166),
		fill,
		SKETCH_UI_SCRIPT.INK,
		accent,
		Vector4(38, 22, 38, 24),
		1
	)
	hero.name = "TournamentResultHero"
	parent.add_child(hero)

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
	outcome_label.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
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
	detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
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
	record.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	record_box.add_child(record)
	var record_caption := Label.new()
	record_caption.text = "FINAL RECORD"
	record_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_caption.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.42))
	record_caption.add_theme_font_size_override("font_size", 13)
	record_caption.add_theme_color_override("font_color", accent.darkened(0.18))
	record_box.add_child(record_caption)


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
	var heading := Label.new()
	heading.text = "ROUND RECAP"
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.7))
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	section.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	section.add_child(row)

	var round_results: Array = summary.get("round_results", [])
	if round_results.is_empty():
		var wins := int(summary.get("wins", 0))
		var losses := int(summary.get("losses", 0))
		for round_index in range(maxi(1, wins + losses)):
			_add_tournament_round_card(
				row,
				round_index + 1,
				{"won": round_index < wins}
			)
		return
	for round_value in round_results:
		_add_tournament_round_card(row, int(round_value.get("round", row.get_child_count() + 1)), round_value)


func _add_tournament_round_card(parent: Node, round_number: int, result: Dictionary) -> void:
	var won := bool(result.get("won", false))
	var accent := SKETCH_UI_SCRIPT.TEAL if won else SKETCH_UI_SCRIPT.ORANGE
	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 91),
		Color("#F7F1E6"),
		SKETCH_UI_SCRIPT.INK,
		accent,
		Vector4(15, 9, 15, 11),
		parent.get_child_count() % 2
	)
	panel.name = "TournamentResultRoundCard_%d" % round_number
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", -2)
	panel.add_child(copy)
	var top := Label.new()
	top.text = "ROUND %d   •   %s" % [round_number, "WIN" if won else "LOSS"]
	top.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.72))
	top.add_theme_font_size_override("font_size", 19)
	top.add_theme_color_override("font_color", accent.darkened(0.18))
	copy.add_child(top)
	var opponent_name := String(result.get("opponent_name", ""))
	var opponent_archetype := String(result.get("opponent_archetype", ""))
	var matchup := Label.new()
	matchup.text = (
		"vs %s  •  %s" % [opponent_name, opponent_archetype]
		if opponent_name != ""
		else ("Made the cut" if won else "Run ended")
	)
	matchup.clip_text = true
	matchup.add_theme_font_size_override("font_size", 13)
	matchup.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	copy.add_child(matchup)
	if result.has("turn") or result.has("cash"):
		var detail := Label.new()
		detail.text = "Turn %d  •  %d life  •  +$%d" % [
			int(result.get("turn", 0)),
			int(result.get("player_life", 0)),
			int(result.get("cash", 0)),
		]
		detail.add_theme_font_size_override("font_size", 12)
		detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
		copy.add_child(detail)


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
	_connect_pressed(button, callback)
	parent.add_child(button)
	return button


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
	finale.add_theme_constant_override("separation", 12)
	content.add_child(finale)

	var hero := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 238),
		Color("#FFF3CF"),
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.MUSTARD,
		Vector4(56, 34, 56, 38),
		1
	)
	hero.name = "FinaleHero"
	finale.add_child(hero)
	var hero_copy := VBoxContainer.new()
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", 3)
	hero.add_child(hero_copy)
	var eyebrow := Label.new()
	eyebrow.text = "SEASON COMPLETE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.5))
	eyebrow.add_theme_font_size_override("font_size", 17)
	eyebrow.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.TEAL)
	hero_copy.add_child(eyebrow)
	var champion_title := Label.new()
	champion_title.name = "FinaleChampionTitle"
	champion_title.text = "LEAGUE CUP CHAMPION"
	champion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	champion_title.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.94))
	champion_title.add_theme_font_size_override("font_size", 56)
	champion_title.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	hero_copy.add_child(champion_title)
	var hero_detail := Label.new()
	hero_detail.text = "You conquered the shop circuit. The national stage is next."
	hero_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.18))
	hero_detail.add_theme_font_size_override("font_size", 19)
	hero_detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	hero_copy.add_child(hero_detail)

	var achievement_row := HBoxContainer.new()
	achievement_row.name = "FinaleAchievementRow"
	achievement_row.add_theme_constant_override("separation", 10)
	finale.add_child(achievement_row)
	_add_finale_milestone(achievement_row, "✓", "WEEKLY LOCALS", "Cleared", SKETCH_UI_SCRIPT.TEAL)
	_add_finale_milestone(achievement_row, "★", "LEAGUE CUP", "Champion", SKETCH_UI_SCRIPT.MUSTARD)
	_add_finale_milestone(achievement_row, "→", "STATE CHAMPIONSHIP", "Up next", SKETCH_UI_SCRIPT.ORANGE)

	var road_ahead := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 144),
		Color("#FFF8E9"),
		SKETCH_UI_SCRIPT.INK,
		SKETCH_UI_SCRIPT.MUSTARD,
		Vector4(34, 20, 34, 22),
		0
	)
	road_ahead.name = "FinaleTeaser"
	finale.add_child(road_ahead)
	var road_copy := VBoxContainer.new()
	road_copy.add_theme_constant_override("separation", 5)
	road_ahead.add_child(road_copy)
	var road_heading := Label.new()
	road_heading.text = "THE ROAD AHEAD"
	road_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	road_heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.78))
	road_heading.add_theme_font_size_override("font_size", 25)
	road_heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	road_copy.add_child(road_heading)
	var road_detail := Label.new()
	road_detail.text = "New rivals. Bigger venues. Stronger cards. One seat at Worlds."
	road_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	road_detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.18))
	road_detail.add_theme_font_size_override("font_size", 15)
	road_detail.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	road_copy.add_child(road_detail)
	var teaser_row := HBoxContainer.new()
	teaser_row.add_theme_constant_override("separation", 8)
	road_copy.add_child(teaser_row)
	_add_finale_teaser(teaser_row, "STATE CHAMPS", "Prove you belong.")
	_add_finale_teaser(teaser_row, "NATIONALS", "Survive the spotlight.")
	_add_finale_teaser(teaser_row, "WORLDS", "Take your seat.")

	var summary := Label.new()
	summary.name = "FinaleRunSummary"
	summary.text = "%d/%d events cleared  •  %d cards collected  •  $%d remaining" % [
		_season_completed_count(),
		_season_calendar_ids().size(),
		_deck_total(run.get("collection", {})),
		int(run.get("money", 0)),
	]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.24))
	summary.add_theme_font_size_override("font_size", 16)
	summary.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.MUTED_INK)
	finale.add_child(summary)

	var actions := HBoxContainer.new()
	actions.name = "FinaleActions"
	actions.add_theme_constant_override("separation", 10)
	finale.add_child(actions)
	var deck_button := _make_button("Review Winning Deck")
	deck_button.name = "FinaleDeckButton"
	deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connect_pressed(deck_button, _show_deckbuilder)
	actions.add_child(deck_button)
	var title_button := _make_button("Return to Main Menu")
	title_button.name = "ThanksMainMenuButton"
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(title_button, "target")
	_connect_pressed(title_button, _show_start)
	actions.add_child(title_button)

	if not _reduced_motion_enabled() and not _running_automated_test():
		hero.modulate.a = 0.0
		road_ahead.modulate.a = 0.0
		var finale_tween := create_tween()
		finale_tween.tween_property(hero, "modulate:a", 1.0, 0.28)
		finale_tween.tween_property(road_ahead, "modulate:a", 1.0, 0.32)


func _add_finale_milestone(parent: Node, symbol: String, title: String, status: String, accent: Color) -> void:
	var panel := SKETCH_UI_SCRIPT.make_rough_panel(
		Vector2(0, 112),
		SKETCH_UI_SCRIPT.PAPER,
		SKETCH_UI_SCRIPT.INK,
		accent,
		Vector4(22, 14, 22, 16),
		parent.get_child_count() % 2
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(copy)
	var heading := Label.new()
	heading.text = "%s  %s" % [symbol, title]
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", SKETCH_UI_SCRIPT.display_font(0.76))
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", SKETCH_UI_SCRIPT.INK)
	copy.add_child(heading)
	var detail := Label.new()
	detail.text = status
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", SKETCH_UI_SCRIPT.body_font(0.32))
	detail.add_theme_font_size_override("font_size", 14)
	detail.add_theme_color_override("font_color", accent.darkened(0.2))
	copy.add_child(detail)


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
			return Color("#d95735")
		"hearty":
			return Color("#8a6b32")
		"sweet":
			return Color("#c75ba3")
		"neutral":
			return Color("#c7d0df")
		_:
			return Color("#ffe08a")


func _rarity_line_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#232b35")
		"uncommon":
			return Color("#1f3530")
		"rare":
			return Color("#3d321f")
		"mythic":
			return Color("#442334")
		_:
			return Color("#232b35")


func _rarity_text_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color("#d8dfec")
		"uncommon":
			return Color("#96e6c8")
		"rare":
			return Color("#ffd37a")
		"mythic":
			return Color("#ff9fc2")
		_:
			return Color("#d8dfec")


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
	var icon := _button_icon(button.text)
	if icon != null:
		button.icon = icon
		button.icon_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT
			if icon == ICON_CARET_RIGHT
			else HORIZONTAL_ALIGNMENT_LEFT
		)
	if not _uses_sketch_interface() and button.get_node_or_null("AudaciousButtonMotion") == null:
		var motion := BUTTON_MOTION_SCRIPT.new()
		motion.name = "AudaciousButtonMotion"
		button.add_child(motion)


func _style_cycle_button(button: Button, icon: Texture2D) -> void:
	button.text = ""
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.theme_type_variation = UI_THEME_SCRIPT.button_variation("default")
	button.add_theme_constant_override("icon_max_width", 24)


func _button_icon(label: String) -> Texture2D:
	var normalized := label.to_lower()
	if "close" in normalized:
		return ICON_CLOSE
	if "back" in normalized or "exit" in normalized or "return" in normalized:
		return ICON_CARET_LEFT
	if normalized.begins_with("start"):
		return ICON_CARET_RIGHT
	if "save" in normalized:
		return ICON_FOLDER
	if "calendar" in normalized or "season" in normalized or "event" in normalized:
		return ICON_CALENDAR
	if "buy" in normalized or "sell" in normalized or "wallet" in normalized or "$" in normalized:
		return ICON_ADD
	if "draft" in normalized or "deck" in normalized:
		return ICON_CUBE
	if "tutorial" in normalized or "how to play" in normalized or "kitchen" in normalized:
		return ICON_BOWL
	if "debug" in normalized or "menu" in normalized:
		return ICON_MENU
	if "continue" in normalized or "resume" in normalized:
		return ICON_CARET_RIGHT
	if "new run" in normalized or "worlds" in normalized:
		return ICON_STAR
	if (
		"start" in normalized
		or "open" in normalized
		or "next" in normalized
		or "play" in normalized
		or "register" in normalized
	):
		return ICON_CARET_RIGHT
	return null


func _update_status() -> void:
	if run.is_empty():
		match current_screen:
			"tutorial":
				status_label.text = "Learn to Play"
			"game_start":
				status_label.text = "Game Start"
			"season_setup":
				status_label.text = "New Season"
			"settings":
				status_label.text = "Settings"
			_:
				status_label.text = "Road to Worlds"
		return
	var main_count := _deck_total(run.deck)
	var difficulty := _difficulty_data(_run_difficulty_id())
	if _run_mode() == "season":
		var life_text := " | Lives %d/%d" % [
			int(run.get("season_lives", 0)),
			int(run.get("max_season_lives", 0))
		]
		status_label.text = "Week %d | $%d | %s Border%s | Main %d/%d" % [
			int(run.week),
			int(run.money),
			String(difficulty.get("name", "Black")),
			life_text,
			main_count,
			MAX_MAIN_DECK_SIZE
		]
		return
	var side_count := _deck_total(run.sideboard)
	status_label.text = "Week %d | $%d | %s Border | Main %d/%d | Side %d/%d" % [
		int(run.week),
		int(run.money),
		String(difficulty.get("name", "Black")),
		main_count,
		MAX_MAIN_DECK_SIZE,
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
	var result: Dictionary = _autosave_now(current_screen) if autosave_enabled else run_state_service.save_run(run, current_screen)
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


func _open_saved_collection() -> void:
	autosave_suspended = true
	var result: Dictionary = run_state_service.load_run()
	if not bool(result.get("ok", false)):
		autosave_suspended = false
		_show_start()
		return
	_prepare_loaded_run(result)
	_show_deckbuilder()
	_set_footer("Winning deck loaded.")
	call_deferred("_finish_autosave_resume")


func _quit_from_title() -> void:
	get_tree().quit()


func _continue_run_to_shop() -> void:
	autosave_suspended = true
	var result: Dictionary = run_state_service.load_run()
	if not bool(result.get("ok", false)):
		autosave_suspended = false
		_set_footer(String(result.get("message", "No valid saved run found.")))
		_show_game_start()
		return
	_prepare_loaded_run(result)
	_show_shop()
	_set_footer("Welcome back to the card shop.")
	call_deferred("_finish_autosave_resume")


func _prepare_loaded_run(result: Dictionary) -> void:
	run = result.run
	if String(run.get("run_mode", "season")) == "debug" and not _development_tools_enabled():
		run.run_mode = "season"
	if not run.has("kitchen_opponent"):
		var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
		run.kitchen_opponent = _predator_archetype(String(metrics.primary))
	if not run.has("shop") or not (run.shop is Array):
		_generate_shop_inventory()


func _resume_loaded_screen(saved_screen: String) -> void:
	if bool(run.get("run_over", false)):
		_show_tournament_result(run.get("last_result", ["The run is over."]), false)
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
	if not _season_tournament_active():
		_start_debug_kitchen_match()
		return
	var saved_match: Dictionary = run.get("kitchen_match", {}).duplicate(true)
	var saved_result: Dictionary = run.get("kitchen_match_result", {}).duplicate(true)
	_start_season_tournament_round(true, true)
	if bool(saved_result.get("game_over", false)):
		run.kitchen_match = saved_match
		run.kitchen_match_result = saved_result
		call_deferred("_show_season_round_result_popup", String(saved_result.get("winner", "opponent")) == "player")
	else:
		_set_footer("Round restored against the same opponent.")


func _finish_autosave_resume() -> void:
	last_autosave_fingerprint = _run_fingerprint()
	last_autosave_screen = current_screen
	autosave_poll_elapsed = 0.0
	autosave_suspended = false


func _migrate_legacy_run_archetypes() -> void:
	run_state_service.migrate_legacy_run_archetypes(run)
