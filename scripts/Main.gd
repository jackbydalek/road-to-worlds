extends Control

const MAIN_DECK_SIZE := 30
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SAVE_PATH := "user://kitchen_table_season_run.json"
const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"
const ARCHETYPE_ORDER := ["spicy", "hearty", "sweet", "fresh", "funky"]
const DEMO_STARTER_ORDER := ["spicy", "hearty", "sweet"]
const DIFFICULTY_ORDER := ["white", "blue", "yellow", "silver", "gold"]
const BASE_BOOSTER_ID := "base_standard_pack"
const PRIZE_BOOSTER_ID := "season_prize_pack"
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
var autosave_enabled := true
var autosave_suspended := false
var autosave_poll_elapsed := 0.0
var last_autosave_fingerprint := ""
var last_autosave_screen := ""


func _ready() -> void:
	var app_theme := Theme.new()
	app_theme.default_font = AFFINITY_VISUALS.default_ui_font_with_symbols()
	theme = app_theme
	autosave_enabled = not _running_automated_test()
	get_tree().auto_accept_quit = false
	rng.randomize()
	_load_content()
	deck_metrics_service = DECK_METRICS_SERVICE_SCRIPT.new()
	deck_metrics_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE)
	run_state_service = RUN_STATE_SERVICE_SCRIPT.new()
	run_state_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE, SIDEBOARD_SIZE, STARTING_MONEY, SAVE_PATH)
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and current_screen == "kitchen_match":
		if is_instance_valid(round_result_popup):
			return
		call_deferred("_on_kitchen_exit_requested")


func _running_automated_test() -> bool:
	for argument in OS.get_cmdline_args():
		if "SmokeTest.gd" in String(argument):
			return true
	return false


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
	autosave_label.text = "Autosaving..."
	autosave_label.modulate = Color(1, 1, 1, 0.45)
	autosave_label.add_theme_color_override("font_color", Color("#8ed9ff"))
	autosave_tween = create_tween()
	autosave_tween.tween_property(autosave_label, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.5, 0.16).set_trans(Tween.TRANS_SINE)
	autosave_tween.tween_property(autosave_label, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	autosave_tween.tween_callback(func() -> void: autosave_label.text = "Saved")
	autosave_tween.tween_interval(0.45)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.35)
	autosave_tween.tween_callback(func() -> void: autosave_label.visible = false)


func _show_autosave_failure() -> void:
	if autosave_label == null:
		return
	if autosave_tween != null and autosave_tween.is_valid():
		autosave_tween.kill()
	autosave_label.visible = true
	autosave_label.text = "Autosave failed"
	autosave_label.modulate = Color.WHITE
	autosave_label.add_theme_color_override("font_color", Color("#ff9b92"))
	autosave_tween = create_tween()
	autosave_tween.tween_interval(1.4)
	autosave_tween.tween_property(autosave_label, "modulate:a", 0.0, 0.4)
	autosave_tween.tween_callback(func() -> void: autosave_label.visible = false)


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#11141a")
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
	title_label.add_theme_color_override("font_color", Color("#f3efe4"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", Color("#c7d0df"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(status_label)

	autosave_label = Label.new()
	autosave_label.name = "AutosaveIndicator"
	autosave_label.text = "Autosaving..."
	autosave_label.visible = false
	autosave_label.custom_minimum_size = Vector2(112, 0)
	autosave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	autosave_label.add_theme_font_size_override("font_size", 14)
	autosave_label.add_theme_color_override("font_color", Color("#8ed9ff"))
	autosave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	autosave_label.offset_left = -158
	autosave_label.offset_top = 16
	autosave_label.offset_right = -18
	autosave_label.offset_bottom = 44
	autosave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	autosave_label.z_index = 2000
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
	footer_label.add_theme_color_override("default_color", Color("#c7d0df"))
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
	for child in node.get_children():
		# Screen rebuilds are often triggered by button signals; queue deletion so the
		# emitting button is not freed while Godot is still dispatching its signal.
		child.queue_free()


func _connect_pressed(button: Button, callback: Callable) -> void:
	button.pressed.connect(callback, CONNECT_DEFERRED)


func _show_start() -> void:
	if not run.is_empty():
		_autosave_now(current_screen)
	current_screen = "start"
	run = {}
	season_setup_archetype_index = 0
	season_setup_difficulty_index = 0
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Continue your autosaved run, start a new game, or learn the basics.")

	var intro := _add_panel(content, "Kitchen Table: Road to Worlds")
	_add_body_text(
		intro,
		"Build a Kitchen Table deck, shop for new recipes, and survive the tournament calendar from locals to Worlds."
	)

	var mode_row := HBoxContainer.new()
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("separation", 10)
	content.add_child(mode_row)

	var continue_panel := _add_panel(mode_row, "Continue", "#1f3329")
	continue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(continue_panel, "Return to the latest autosave. Interrupted tournament matches restart at the same round and opponent.")
	var continue_button := _make_button("Continue")
	continue_button.name = "ContinueRunButton"
	continue_button.disabled = not run_state_service.has_saved_run()
	_style_button(continue_button, "target")
	_connect_pressed(continue_button, _load_run_from_disk)
	continue_panel.add_child(continue_button)

	var new_game_panel := _add_panel(mode_row, "New Run", "#2b2f44")
	new_game_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(new_game_panel, "Choose a difficulty card frame and one of three starter decks. Your previous autosave remains until the new run begins.")
	var new_game_button := _make_button("New Run")
	new_game_button.name = "NewGameButton"
	_style_button(new_game_button, "action")
	_connect_pressed(new_game_button, _show_season_run_setup)
	new_game_panel.add_child(new_game_button)

	var tutorial_panel := _add_panel(mode_row, "How to Play", "#173447")
	tutorial_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(tutorial_panel, "Play a guided practice table with fixed hands, highlighted cards, recipes, zones, support cards, and combat.")
	var tutorial_button := _make_button("How to Play")
	tutorial_button.name = "StartTutorialButton"
	_style_button(tutorial_button, "action")
	_connect_pressed(tutorial_button, _show_tutorial)
	tutorial_panel.add_child(tutorial_button)

	var debug_link := _make_button("Open Debug Menu")
	debug_link.name = "OpenDebugMenuButton"
	_connect_pressed(debug_link, _show_debug_starter_selection)
	content.add_child(debug_link)

	_set_footer("Continue your autosaved run, start a new run, or learn how to play.")


func _show_new_game_menu() -> void:
	current_screen = "new_game"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose the Season Run for the demo path or the Debug Sandbox for development tools.")

	var intro := _add_panel(content, "New Game")
	_add_body_text(intro, "Starting a deck creates a new autosave. You can return now without replacing the previous run.")

	var mode_row := HBoxContainer.new()
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("separation", 10)
	content.add_child(mode_row)

	var season_panel := _add_panel(mode_row, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(season_panel, "Choose a starter deck and season border, then play the shop-to-tournament progression loop.")
	var season_button := _make_button("Start Season Run")
	season_button.name = "NewSeasonRunButton"
	_style_button(season_button, "action")
	_connect_pressed(season_button, _show_season_run_setup)
	season_panel.add_child(season_button)

	var debug_panel := _add_panel(mode_row, "Debug Sandbox", "#2b2f44")
	debug_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(debug_panel, "Choose a kitchen and open every Shop, Pack, Deckbuilder, Match, Tournament, and testing surface.")
	var debug_button := _make_button("Open Debug Sandbox")
	debug_button.name = "NewDebugRunButton"
	_connect_pressed(debug_button, _show_debug_starter_selection)
	debug_panel.add_child(debug_button)

	var back_button := _make_button("Back")
	_connect_pressed(back_button, _show_start)
	content.add_child(back_button)


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
	_set_footer("Choose a starter deck and season border. Borders are difficulty modifiers for the run.")

	var selected_archetype_id := String(DEMO_STARTER_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	var archetype: Dictionary = archetypes_by_id[selected_archetype_id]
	var difficulty := _difficulty_data(selected_difficulty_id)
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	var metrics := _calculate_deck_metrics(starter_deck, {})

	var panel := _add_panel(content, "Season Registration", "#17202c")
	_add_body_text(panel, "Pick your deck shell, then pick the border that defines the run's difficulty modifier.")

	var deck_row := HBoxContainer.new()
	deck_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_row.add_theme_constant_override("separation", 10)
	panel.add_child(deck_row)

	var previous_deck := _make_button("<")
	previous_deck.custom_minimum_size = Vector2(48, 150)
	_connect_pressed(previous_deck, func() -> void: _shift_season_setup_archetype(-1))
	deck_row.add_child(previous_deck)

	var deck_card := _add_bordered_panel(
		deck_row,
		_starter_label(selected_archetype_id),
		String(archetype.get("color", "#2d3442")),
		String(difficulty.get("border_color", "#f3efe4")),
		3
	)
	deck_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_card.custom_minimum_size = Vector2(420, 150)
	_add_body_text(deck_card, String(archetype.get("summary", "")))
	_add_body_text(deck_card, _format_metrics_short(metrics))
	_add_body_text(deck_card, "Starter deck: %d cards | Predator matchup: %s" % [
		_deck_total(starter_deck),
		_affinity_label(_predator_archetype(selected_archetype_id))
	])

	var next_deck := _make_button(">")
	next_deck.custom_minimum_size = Vector2(48, 150)
	_connect_pressed(next_deck, func() -> void: _shift_season_setup_archetype(1))
	deck_row.add_child(next_deck)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_row.add_theme_constant_override("separation", 10)
	panel.add_child(difficulty_row)

	var previous_difficulty := _make_button("<")
	previous_difficulty.custom_minimum_size = Vector2(48, 118)
	_connect_pressed(previous_difficulty, func() -> void: _shift_season_setup_difficulty(-1))
	difficulty_row.add_child(previous_difficulty)

	var difficulty_card := _add_bordered_panel(
		difficulty_row,
		"%s Border" % String(difficulty.get("name", "Black")),
		String(difficulty.get("accent", "#202734")),
		String(difficulty.get("border_color", "#f3efe4")),
		4
	)
	difficulty_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_card.custom_minimum_size = Vector2(420, 118)
	_add_body_text(difficulty_card, String(difficulty.get("summary", "")))
	_add_body_text(difficulty_card, String(difficulty.get("rules_text", "")))
	_add_body_text(difficulty_card, "Start: $%d | Sudden death: one match loss ends the run" % [
		run_state_service.starting_money_for_difficulty(selected_difficulty_id)
	])

	var next_difficulty := _make_button(">")
	next_difficulty.custom_minimum_size = Vector2(48, 118)
	_connect_pressed(next_difficulty, func() -> void: _shift_season_setup_difficulty(1))
	difficulty_row.add_child(next_difficulty)

	var action_row := HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 10)
	panel.add_child(action_row)

	var play_button := _make_button("Start Season")
	_style_button(play_button, "action")
	_connect_pressed(play_button, _confirm_season_run_setup)
	action_row.add_child(play_button)

	var back_button := _make_button("Back")
	_connect_pressed(back_button, _show_start)
	action_row.add_child(back_button)


func _shift_season_setup_archetype(delta: int) -> void:
	season_setup_archetype_index = posmod(season_setup_archetype_index + delta, DEMO_STARTER_ORDER.size())
	_show_season_run_setup()


func _shift_season_setup_difficulty(delta: int) -> void:
	season_setup_difficulty_index = posmod(season_setup_difficulty_index + delta, DIFFICULTY_ORDER.size())
	_show_season_run_setup()


func _confirm_season_run_setup() -> void:
	var selected_archetype_id := String(DEMO_STARTER_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	_start_new_run_with_mode(selected_archetype_id, "season", selected_difficulty_id)


func _start_new_run(archetype_id: String) -> void:
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id), "unselected", "white")
	run.run_mode = "unselected"

	_generate_shop_inventory()
	_set_footer("Starter chosen. Pick whether this run opens in the clean season path or the full debug sandbox.")
	_show_run_path_choice()


func _start_new_run_with_mode(archetype_id: String, mode: String, difficulty_id: String = "white") -> void:
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
	_add_body_text(intro, "Starter: %s | Money: $%d | Main deck: %d/%d" % [
		starter_name,
		int(run.get("money", 0)),
		_deck_total(run.get("deck", {})),
		MAIN_DECK_SIZE
	])
	_add_body_text(intro, _format_metrics_short(metrics))

	var options := HBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 10)
	content.add_child(options)

	var season_panel := _add_panel(options, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(season_panel, "Play the actual roguelike path: shop, packs, deck tuning, tournament entry, rewards, and run failure.")
	_add_body_text(season_panel, "This is the route we will keep tightening into the vertical slice.")
	var season_button := _make_button("Start Season Run")
	_connect_pressed(season_button, func() -> void: _choose_run_path("season"))
	season_panel.add_child(season_button)

	var debug_panel := _add_panel(options, "Debug Sandbox", "#2b2f44")
	debug_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(debug_panel, "Open the full development menu with Kitchen Match, Tournament, Metagame, and every season system.")
	_add_body_text(debug_panel, "Use this when we are building or debugging specific systems.")
	var debug_button := _make_button("Open Debug Menu")
	_connect_pressed(debug_button, func() -> void: _choose_run_path("debug"))
	debug_panel.add_child(debug_button)


func _choose_run_path(mode: String) -> void:
	if run.is_empty():
		_show_start()
		return
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
		return "debug"
	return String(run.get("run_mode", "debug"))


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
				"rules_text": "You start with less money, so every pack, single, and entry fee matters more."
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
	var compact_duel := current_screen in ["kitchen_match", "tutorial"]
	var compact_deck := current_screen == "deck" and _run_mode() == "season"
	var hide_footer := compact_duel or compact_deck or (current_screen == "shop" and _run_mode() == "season")
	if header_bar != null:
		header_bar.visible = not compact_duel
	if nav != null:
		nav.visible = not compact_duel
	footer_label.visible = not hide_footer
	footer_label.custom_minimum_size = Vector2(0, 0 if hide_footer else 78)
	var compact_margin := compact_duel or compact_deck
	root_margin.add_theme_constant_override("margin_left", 6 if compact_margin else 18)
	root_margin.add_theme_constant_override("margin_right", 6 if compact_margin else 18)
	root_margin.add_theme_constant_override("margin_top", 4 if compact_margin else 14)
	root_margin.add_theme_constant_override("margin_bottom", 4 if compact_margin else 14)
	shell.add_theme_constant_override("separation", 3 if compact_margin else 10)
	content.add_theme_constant_override("separation", 4 if compact_margin else 10)
	if scroll != null:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck else ScrollContainer.SCROLL_MODE_AUTO
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if compact_deck else ScrollContainer.SCROLL_MODE_AUTO


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


func _show_shop_overworld() -> void:
	if _guard_run_over():
		return
	current_screen = "shop"
	_render_nav()
	_clear(content)
	_update_status()
	_set_footer("Click the shopkeeper, trading table, metagame board, or deck box. Every menu has an Exit to Card Store button.")

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
	shop_world.connect("exit_requested", _show_start)
	content.add_child(shop_world)
	shop_world.call("configure_shop", _shop_overworld_context())


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
	pack_opening_screen.show(self)


func _buy_and_open_pack() -> void:
	var result: Dictionary = shop_economy_service.buy_and_open_pack(run, BASE_BOOSTER_ID, _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _open_prize_pack() -> void:
	var result: Dictionary = shop_economy_service.open_prize_pack(run, PRIZE_BOOSTER_ID, _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _start_pack(pack: Array) -> void:
	shop_economy_service.start_pack(run, pack)


func _generate_pack(booster_id: String) -> Array:
	return shop_economy_service.generate_pack(booster_id, _current_primary_archetype())


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


func _show_deckbuilder() -> void:
	deckbuilder_screen.show(self)


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
	var accent := Color("#80d98b") if won else Color("#ef8e86")

	var overlay := Control.new()
	overlay.name = "SeasonRoundResultPopup"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1000
	add_child(overlay)
	round_result_popup = overlay

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.02, 0.025, 0.035, 0.82)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#1d2430")
	panel_style.border_color = accent
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", panel_style)
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
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", accent)
	box.add_child(heading)

	var detail := Label.new()
	detail.text = (
		"Round %d is complete. Lock in the win and view your tournament results." % round_number
		if won and final_round
		else "Round %d is complete. Continue now, or return to the shop to buy cards and edit your deck." % round_number
		if won
		else "Round %d was lost. This sudden-death demo run ends here." % round_number
	)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", Color("#d8dfec"))
	box.add_child(detail)

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
		match_state.opponent_life = 25
		run.kitchen_match = match_state
		run.kitchen_match_result = {
			"game_over": true,
			"winner": "opponent",
			"turn": 0,
			"player": {"life": 0},
			"opponent": {"life": 25}
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
	_add_body_text(panel, "Entry fee: $%d | Current money: $%d" % [int(event.get("entryFee", 0)), int(run.get("money", 0))])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))
	if _run_mode() == "season" and bool(legal.get("ok", false)) and _season_event_selectable(event_id) and _season_entry_fee_missing(event) > 0:
		_add_body_text(panel, "Short on entry by $%d. Work one shop shift to cover the missing fee." % _season_entry_fee_missing(event))

	var enter := _make_button("Enter %s" % String(event.get("name", event_id)))
	enter.disabled = not legal.ok or int(run.get("money", 0)) < int(event.get("entryFee", 0)) or (_run_mode() == "season" and not _season_event_selectable(event_id))
	if _run_mode() == "season":
		_connect_pressed(enter, _start_season_tournament)
	else:
		_connect_pressed(enter, _run_tournament)
	panel.add_child(enter)

	if _run_mode() == "season" and enter.disabled and bool(legal.get("ok", false)) and _season_event_selectable(event_id) and _season_entry_fee_missing(event) > 0:
		var work_button := _make_button("Work Shop Shift")
		work_button.name = "TournamentWorkShiftButton"
		_connect_pressed(work_button, _season_work_shop_shift)
		panel.add_child(work_button)

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
	if int(run.get("money", 0)) < int(event.get("entryFee", 0)):
		_set_footer("You cannot afford the entry fee.")
		return

	run.money = int(run.money) - int(event.get("entryFee", 0))
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
	if _running_automated_test():
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
	var player_life := int(state.get("player", {}).get("life", 0))
	var opponent_life := int(state.get("opponent", {}).get("life", 0))
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
		logs.append("Record: %d-%d. One loss ends the demo run." % [wins, losses])

	_update_meta_after_event(String(active.get("deck_primary", _current_primary_archetype())), wins, max(1, wins + losses))
	run.last_result = logs
	run.last_event_result = _build_event_result_summary(
		event,
		wins,
		losses,
		required,
		made_record,
		reward_money,
		reward_packs,
		lives_lost,
		run_continues
	)
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
	state["opponent"] = {"life": 25}
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
	if run.money < int(event.entryFee):
		_set_footer("You cannot afford the entry fee.")
		return

	run.money -= int(event.entryFee)

	var logs := []
	var wins := 0
	var losses := 0
	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)

	logs.append("Entered %s with %s. Entry paid: $%d." % [event.name, archetypes_by_id[deck_metrics.primary].name, event.entryFee])

	for round_number in range(1, int(event.rounds) + 1):
		var opponent := _generate_opponent(round_number, deck_metrics, event)
		var result := _simulate_combat_match(opponent, deck_metrics)
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
	var made_record := bool(result_summary.get("made_record", survived))
	var panel_title := "League Cup Champion" if champion else ("Game Over" if bool(run.get("run_over", false)) else "Tournament Result")
	var panel_accent := "#2c3a25" if champion else ("#253044" if survived and made_record else ("#3f3222" if survived else "#442525"))
	var panel := _add_panel(content, panel_title, panel_accent)
	if champion:
		_add_body_text(panel, "You survived every round and cleared the League Cup. Open your prize packs to finish the demo.")
	_add_event_result_summary(panel)
	for line in logs:
		_add_body_text(panel, line)

	if champion:
		var champion_button := _make_button("Open Prize Packs (%d)" % int(run.get("prize_packs", 0)) if int(run.get("prize_packs", 0)) > 0 else "Continue")
		_style_button(champion_button, "action")
		_connect_pressed(champion_button, _open_reward_pack_flow if int(run.get("prize_packs", 0)) > 0 else _show_thanks_for_playing)
		panel.add_child(champion_button)
	elif survived:
		if _run_mode() == "season":
			_add_season_result_action_buttons(panel)
		else:
			var continue_button := _make_button("Return to Card Shop")
			_connect_pressed(continue_button, _show_shop)
			panel.add_child(continue_button)
	else:
		var restart_button := _make_button("Start New Run")
		_connect_pressed(restart_button, _show_start)
		panel.add_child(restart_button)


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
	var seen_labels: Dictionary = {}
	if not primary_action.is_empty():
		seen_labels[String(primary_action.get("text", ""))] = true

	if not made_record and not bool(summary.get("run_over", false)):
		var event_id := String(summary.get("event_id", _selected_season_event_id()))
		var event := _season_event_by_id(event_id)
		_add_season_result_secondary_button(
			secondary,
			"Retry %s" % String(event.get("name", event_id)),
			_show_tournament,
			seen_labels,
			not _deck_is_legal().ok or int(run.get("money", 0)) < int(event.get("entryFee", 0))
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
		if _season_entry_fee_missing(event) > 0:
			return {
				"text": "Work Shop Shift",
				"callback": _season_work_shop_shift
			}
		return {
			"text": "Retry %s" % String(event.get("name", event_id)),
			"callback": _show_tournament,
			"disabled": not _deck_is_legal().ok or int(run.get("money", 0)) < int(event.get("entryFee", 0))
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
	_set_footer("Thank you for playing Kitchen Table: Road to Worlds.")
	var panel := _add_bordered_panel(content, "THANKS FOR PLAYING", "#172a38", "#e2b84c", 4)
	panel.custom_minimum_size = Vector2(0, 360)
	_add_body_text(panel, "You cleared Weekly Locals, won the League Cup, and completed the Road to Worlds demo.")
	_add_body_text(panel, "The full journey continues through State Championships, Nationals, and Worlds.")
	var title_button := _make_button("Return to Main Menu")
	title_button.name = "ThanksMainMenuButton"
	_style_button(title_button, "target")
	_connect_pressed(title_button, _show_start)
	panel.add_child(title_button)


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


func _season_entry_fee_missing(event: Dictionary = {}) -> int:
	if _run_mode() != "season":
		return 0
	var target_event := event if not event.is_empty() else _selected_season_event()
	return max(0, int(target_event.get("entryFee", 0)) - int(run.get("money", 0)))


func _season_work_shop_shift() -> void:
	if _guard_run_over():
		return
	if _run_mode() != "season" or _season_tournament_active():
		_set_footer("Shop shifts are only available between season events.")
		return
	var event := _selected_season_event()
	var missing := _season_entry_fee_missing(event)
	if missing <= 0:
		_set_footer("You already have enough for the selected entry fee.")
		_show_season_run()
		return
	run.money = int(run.get("money", 0)) + missing
	run.season_notice = "You worked a shop shift for $%d, just enough to cover %s entry." % [
		missing,
		String(event.get("name", _selected_season_event_id()))
	]
	_set_footer("Worked a shop shift for $%d." % missing)
	_show_season_run()


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
	if made_record:
		_add_body_text(parent, "Rewards: $%d | Prize packs: %d" % [
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
			reports.append("Hearty chefs are adding healing and Bodyguard Ingredients to survive the early heat.")
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
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent)
	style.border_color = Color("#3a4352")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
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
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title
		label.add_theme_font_size_override("font_size", 14 if compact_duel else 18)
		label.add_theme_color_override("font_color", Color("#f3efe4"))
		box.add_child(label)

	return box


func _add_bordered_panel(parent: Node, title: String, accent: String, border: String, border_width: int = 2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent)
	style.border_color = Color(border)
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
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
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#f3efe4"))
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
	label.add_theme_color_override("font_color", Color("#d8dfec"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 30)
	_style_button(button, "default")
	return button


func _style_button(button: Button, variant: String = "default") -> void:
	var normal_color := Color("#2f3947")
	var hover_color := Color("#3d4a5b")
	var pressed_color := Color("#232b35")
	var border_color := Color("#5d6a7a")
	var text_color := Color("#eef3ff")

	match variant:
		"target":
			normal_color = Color("#24482c")
			hover_color = Color("#2f633a")
			pressed_color = Color("#1b3521")
			border_color = Color("#9ee66e")
			text_color = Color("#f1ffe8")
		"selected":
			normal_color = Color("#4a3b1b")
			hover_color = Color("#604e24")
			pressed_color = Color("#332914")
			border_color = Color("#ffe08a")
			text_color = Color("#fff4c2")
		"action":
			normal_color = Color("#273c58")
			hover_color = Color("#345174")
			pressed_color = Color("#1f3046")
			border_color = Color("#7fb8ff")
			text_color = Color("#eef7ff")
		"danger":
			normal_color = Color("#4a2727")
			hover_color = Color("#613333")
			pressed_color = Color("#331c1c")
			border_color = Color("#d8a0a0")
			text_color = Color("#ffe1df")

	button.add_theme_stylebox_override("normal", _button_stylebox(normal_color, border_color))
	button.add_theme_stylebox_override("hover", _button_stylebox(hover_color, border_color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_stylebox(pressed_color, border_color))
	button.add_theme_stylebox_override("disabled", _button_stylebox(Color("#242a33"), Color("#3a4352")))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("#7e8794"))


func _button_stylebox(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _update_status() -> void:
	if run.is_empty():
		status_label.text = "Learn to Play" if current_screen == "tutorial" else "Season + Debug"
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
			MAIN_DECK_SIZE
		]
		return
	var side_count := _deck_total(run.sideboard)
	status_label.text = "Week %d | $%d | %s Border | Main %d/%d | Side %d/%d" % [
		int(run.week),
		int(run.money),
		String(difficulty.get("name", "Black")),
		main_count,
		MAIN_DECK_SIZE,
		side_count,
		SIDEBOARD_SIZE
	]


func _set_footer(text: String) -> void:
	if footer_label == null:
		return
	footer_label.text = "[color=#c7d0df]" + text + "[/color]"


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
	run = result.run
	if not run.has("kitchen_opponent"):
		var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
		run.kitchen_opponent = _predator_archetype(String(metrics.primary))
	if not run.has("shop") or not (run.shop is Array):
		_generate_shop_inventory()
	_resume_loaded_screen(String(result.get("resume_screen", "")))
	_set_footer(result.message)
	call_deferred("_finish_autosave_resume")


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
			_show_run_path_choice()
		"card_lab":
			_show_card_effect_lab()
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
		_set_footer("Autosave restored. Restarted the current round against the same opponent.")


func _finish_autosave_resume() -> void:
	last_autosave_fingerprint = _run_fingerprint()
	last_autosave_screen = current_screen
	autosave_poll_elapsed = 0.0
	autosave_suspended = false


func _migrate_legacy_run_archetypes() -> void:
	run_state_service.migrate_legacy_run_archetypes(run)
