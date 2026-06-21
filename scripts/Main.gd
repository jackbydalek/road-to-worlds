extends Control

const MAIN_DECK_SIZE := 30
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SAVE_PATH := "user://road_to_worlds_run.json"
const SORT_NAME := "name"
const SORT_RARITY := "rarity"
const SORT_AFFINITY := "affinity"
const ARCHETYPE_ORDER := ["flightless_birds", "snake", "oxen", "glires", "insect"]
const DIFFICULTY_ORDER := ["white", "blue", "yellow", "silver", "gold"]
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const COMBAT_SERVICE_SCRIPT := preload("res://scripts/CombatService.gd")
const DECK_METRICS_SERVICE_SCRIPT := preload("res://scripts/DeckMetricsService.gd")
const RUN_STATE_SERVICE_SCRIPT := preload("res://scripts/RunStateService.gd")
const SHOP_ECONOMY_SERVICE_SCRIPT := preload("res://scripts/ShopEconomyService.gd")
const CARD_FRAME_FACTORY_SCRIPT := preload("res://scripts/CardFrameFactory.gd")
const DECKBUILDER_SCREEN_SCRIPT := preload("res://scripts/DeckbuilderScreen.gd")
const SEASON_FLOW_SERVICE_SCRIPT := preload("res://scripts/SeasonFlowService.gd")
const TOURNAMENT_SERVICE_SCRIPT := preload("res://scripts/TournamentService.gd")
const COMBAT_UI_SCREEN_SCRIPT := preload("res://scripts/CombatUIScreen.gd")
const MANUAL_COMBAT_UI_SCRIPT := preload("res://scripts/ManualCombatUI.gd")
const MANUAL_COMBAT_VFX_SCRIPT := preload("res://scripts/ManualCombatVFX.gd")
const MANUAL_COMBAT_INPUT_SCRIPT := preload("res://scripts/ManualCombatInput.gd")
const COMBAT_BOARD_SLOTS := 5
const COMBAT_ENGINE_SLOTS := 3
const MANUAL_PENDING_ACTION_COMMIT_DELAY := 1.0

var rng := RandomNumberGenerator.new()
var content_catalog: RefCounted
var combat_service: RefCounted
var deck_metrics_service: RefCounted
var run_state_service: RefCounted
var shop_economy_service: RefCounted
var card_frame_factory: RefCounted
var deckbuilder_screen: RefCounted
var season_flow_service: RefCounted
var tournament_service: RefCounted
var combat_ui_screen: RefCounted
var manual_combat_ui: RefCounted
var manual_combat_vfx: RefCounted
var manual_combat_input: RefCounted

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
var title_label: Label
var status_label: Label
var nav: HBoxContainer
var scroll: ScrollContainer
var content: VBoxContainer
var footer_label: RichTextLabel
var manual_inspect_art_panel: PanelContainer
var manual_inspect_name_label: Label
var manual_inspect_type_panel: PanelContainer
var manual_inspect_type_label: Label
var manual_inspect_meta_label: Label
var manual_inspect_stats_label: Label
var manual_inspect_zone_label: Label
var manual_inspect_effect_label: Label
var manual_inspect_text_label: Label
var manual_drag_candidate: Dictionary = {}
var manual_drag_state: Dictionary = {}
var manual_drag_ghost: Control
var manual_action_bubble_layer: Control


func _ready() -> void:
	rng.randomize()
	_load_content()
	combat_service = COMBAT_SERVICE_SCRIPT.new()
	combat_service.setup(cards_by_id, archetypes_by_id)
	deck_metrics_service = DECK_METRICS_SERVICE_SCRIPT.new()
	deck_metrics_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE)
	run_state_service = RUN_STATE_SERVICE_SCRIPT.new()
	run_state_service.setup(cards_by_id, archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE, SIDEBOARD_SIZE, STARTING_MONEY, SAVE_PATH)
	shop_economy_service = SHOP_ECONOMY_SERVICE_SCRIPT.new()
	shop_economy_service.setup(cards, cards_by_id, boosters_by_id, rng)
	card_frame_factory = CARD_FRAME_FACTORY_SCRIPT.new()
	deckbuilder_screen = DECKBUILDER_SCREEN_SCRIPT.new()
	season_flow_service = SEASON_FLOW_SERVICE_SCRIPT.new()
	season_flow_service.setup(run_state_service, tournaments_by_id)
	tournament_service = TOURNAMENT_SERVICE_SCRIPT.new()
	combat_ui_screen = COMBAT_UI_SCREEN_SCRIPT.new()
	manual_combat_ui = MANUAL_COMBAT_UI_SCRIPT.new()
	manual_combat_vfx = MANUAL_COMBAT_VFX_SCRIPT.new()
	manual_combat_input = MANUAL_COMBAT_INPUT_SCRIPT.new()
	_build_shell()
	_show_start()


func _input(event: InputEvent) -> void:
	if current_screen != "ui_combat":
		return
	if _manual_handle_hand_card_drag_input(event):
		return
	if run.get("manual_inspect", {}).is_empty() and _manual_selection().is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hovered := get_viewport().gui_get_hovered_control()
		if not _ui_combat_click_keeps_inspect(hovered):
			call_deferred("_manual_clear_ui_combat_context")


func _ui_combat_click_keeps_inspect(control: Control) -> bool:
	var node: Node = control
	while node != null:
		var node_name := String(node.name)
		if node_name.begins_with("CombatCardPanel"):
			return true
		if node_name.begins_with("ManualInspectPanelOverlay"):
			return true
		if node_name.begins_with("ManualCardActionBubble"):
			return true
		if node_name.begins_with("ManualOpponentFanHand") or node_name.begins_with("ManualFaceTargetAffordance"):
			return true
		if node_name.begins_with("ManualCardPlayButton") or node_name.begins_with("ManualCardSelectButton"):
			return true
		if node_name.begins_with("ManualAttackSelectButton") or node_name.begins_with("ManualUnitTargetButton"):
			return true
		if node_name.begins_with("ManualFaceTargetButton") or node_name.begins_with("ManualEndTurnButton"):
			return true
		node = node.get_parent()
	return false


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

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	shell.add_child(header)

	title_label = Label.new()
	title_label.text = "Road to Worlds"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("#f3efe4"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", Color("#c7d0df"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_label)

	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	shell.add_child(nav)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	current_screen = "start"
	run = {}
	season_setup_archetype_index = 0
	season_setup_difficulty_index = 0
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose how you want to start: the clean Season Run path or the full debug sandbox.")

	var intro := _add_panel(content, "Road to Worlds")
	_add_body_text(
		intro,
		"Start a competitive TCG season, tune a starter deck, and try to survive the climb from locals toward bigger events."
	)

	var mode_row := HBoxContainer.new()
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("separation", 10)
	content.add_child(mode_row)

	var season_panel := _add_panel(mode_row, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(season_panel, "The actual game path: choose a starter deck, choose a season border, then enter the shop-to-tournament loop.")
	var season_button := _make_button("Start Season Run")
	_style_button(season_button, "action")
	_connect_pressed(season_button, _show_season_run_setup)
	season_panel.add_child(season_button)

	var debug_panel := _add_panel(mode_row, "Debug Sandbox", "#2b2f44")
	debug_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(debug_panel, "The development menu: choose a deck, then open Shop, Packs, Deckbuilder, Combat Lab, UI Combat, Tournament, and Metagame.")
	var debug_button := _make_button("Open Debug Sandbox")
	_connect_pressed(debug_button, _show_debug_starter_selection)
	debug_panel.add_child(debug_button)

	var load_panel := _add_panel(content, "Continue")
	_add_body_text(load_panel, "Load your saved run if you already have one.")
	var load_button := _make_button("Load Run")
	_connect_pressed(load_button, _load_run_from_disk)
	load_panel.add_child(load_button)


func _show_debug_starter_selection() -> void:
	current_screen = "debug_starter"
	run = {}
	_apply_screen_chrome()
	_clear(nav)
	_clear(content)
	_update_status()
	_set_footer("Choose a starter deck for the debug sandbox.")

	var intro := _add_panel(content, "Choose Debug Starter")
	_add_body_text(intro, "Debug starts with the full prototype menu unlocked so we can test individual systems quickly.")

	var starter_grid := HBoxContainer.new()
	starter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starter_grid.add_theme_constant_override("separation", 10)
	intro.add_child(starter_grid)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var box := _add_panel(starter_grid, archetype.get("name", archetype_id), archetype.get("color", "#2d3442"))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_body_text(box, archetype.get("summary", ""))
		var metrics := _calculate_deck_metrics(_deck_entries_to_dict(archetype.get("starterDeck", [])), {})
		_add_body_text(box, _format_metrics_short(metrics))
		var button := _make_button("Start With " + archetype.get("name", archetype_id))
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

	var selected_archetype_id := String(ARCHETYPE_ORDER[season_setup_archetype_index])
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
		String(archetype.get("name", selected_archetype_id)),
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
		_archetype_label(_predator_archetype(selected_archetype_id))
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
		"%s Border" % String(difficulty.get("name", "White")),
		String(difficulty.get("accent", "#202734")),
		String(difficulty.get("border_color", "#f3efe4")),
		4
	)
	difficulty_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_card.custom_minimum_size = Vector2(420, 118)
	_add_body_text(difficulty_card, String(difficulty.get("summary", "")))
	_add_body_text(difficulty_card, String(difficulty.get("rules_text", "")))
	_add_body_text(difficulty_card, "Start: $%d | Lives: %d" % [
		run_state_service.starting_money_for_difficulty(selected_difficulty_id),
		run_state_service.starting_lives_for_difficulty(selected_difficulty_id)
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
	season_setup_archetype_index = posmod(season_setup_archetype_index + delta, ARCHETYPE_ORDER.size())
	_show_season_run_setup()


func _shift_season_setup_difficulty(delta: int) -> void:
	season_setup_difficulty_index = posmod(season_setup_difficulty_index + delta, DIFFICULTY_ORDER.size())
	_show_season_run_setup()


func _confirm_season_run_setup() -> void:
	var selected_archetype_id := String(ARCHETYPE_ORDER[season_setup_archetype_index])
	var selected_difficulty_id := String(DIFFICULTY_ORDER[season_setup_difficulty_index])
	_start_new_run_with_mode(selected_archetype_id, "season", selected_difficulty_id)


func _start_new_run(archetype_id: String) -> void:
	_manual_clear_hand_card_drag()
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id), "unselected", "white")
	run.run_mode = "unselected"

	_generate_shop_inventory()
	_set_footer("Starter chosen. Pick whether this run opens in the clean season path or the full debug sandbox.")
	_show_run_path_choice()


func _start_new_run_with_mode(archetype_id: String, mode: String, difficulty_id: String = "white") -> void:
	_manual_clear_hand_card_drag()
	var archetype: Dictionary = archetypes_by_id[archetype_id]
	var starter_deck := _deck_entries_to_dict(archetype.get("starterDeck", []))
	run = run_state_service.create_run(archetype_id, starter_deck, _predator_archetype(archetype_id), mode, difficulty_id)
	_generate_shop_inventory()
	match mode:
		"season":
			_set_footer("Season started with %s on %s Border." % [
				String(archetype.get("name", archetype_id)),
				String(_difficulty_data(difficulty_id).get("name", "White"))
			])
			_show_season_run()
		_:
			_set_footer("Debug Sandbox started with " + String(archetype.get("name", archetype_id)) + ".")
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
	var starter: Dictionary = archetypes_by_id.get(starter_id, {})
	var starter_name := String(starter.get("name", starter_id))
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
	_add_body_text(debug_panel, "Open the current full prototype menu with Combat Lab, UI Combat, Tournament, Metagame, and all test surfaces.")
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
			_set_footer("Debug Sandbox selected. All prototype tools are available.")
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
		_add_nav_button("Season", _show_season_run)
		_add_nav_button("Shop", _show_shop)
		_add_nav_button("Packs", _show_packs)
		_add_nav_button("Deckbuilder", _show_deckbuilder)
		_add_nav_button("Tournament", _show_tournament)
		_add_nav_button("Metagame", _show_meta)

		var season_spacer := Control.new()
		season_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(season_spacer)

		_add_nav_button("Save", _save_run)
		_add_nav_button("Load", _load_run_from_disk)
		_add_nav_button("New Run", _show_start)
		return

	_add_nav_button("Shop", _show_shop)
	_add_nav_button("Packs", _show_packs)
	_add_nav_button("Deckbuilder", _show_deckbuilder)
	_add_nav_button("Combat Lab", _show_combat_lab)
	_add_nav_button("UI Combat", _show_ui_combat)
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
				"summary": "Opponents upgrade into stronger cards earlier.",
				"rules_text": "Rivals get a quality bump and swap weak starter cards for better same-faction cards sooner."
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
				"summary": "You have fewer season lives.",
				"rules_text": "Missing a required event record costs a life. Silver starts with only one."
			}
		"gold":
			return {
				"id": "gold",
				"name": "Gold",
				"accent": "#42351c",
				"border_color": "#e2b84c",
				"summary": "First player is no longer guaranteed.",
				"rules_text": "Each tournament round flips for first or second before the duel starts."
			}
		_:
			return {
				"id": "white",
				"name": "White",
				"accent": "#29313b",
				"border_color": "#f3efe4",
				"summary": "Base season rules.",
				"rules_text": "Normal money, normal lives, starter-level opponents, and you begin each match."
			}


func _apply_screen_chrome() -> void:
	if footer_label == null:
		return
	var compact_duel := current_screen == "ui_combat"
	footer_label.visible = not compact_duel
	footer_label.custom_minimum_size = Vector2(0, 0 if compact_duel else 78)
	root_margin.add_theme_constant_override("margin_left", 10 if compact_duel else 18)
	root_margin.add_theme_constant_override("margin_right", 10 if compact_duel else 18)
	root_margin.add_theme_constant_override("margin_top", 8 if compact_duel else 14)
	root_margin.add_theme_constant_override("margin_bottom", 8 if compact_duel else 14)
	shell.add_theme_constant_override("separation", 6 if compact_duel else 10)


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
	_set_footer("Selected %s on the season calendar." % String(_season_event_by_id(event_id).get("name", event_id)))
	_show_season_run()


func _season_completed_count() -> int:
	return season_flow_service.completed_count(run)


func _season_event_is_final(event_id: String) -> bool:
	return season_flow_service.event_is_final(run, event_id)


func _season_mark_event_completed(event_id: String) -> void:
	season_flow_service.mark_event_completed(run, event_id)


func _set_calendar_prep_notice(event_id: String) -> void:
	season_flow_service.set_prep_notice(run, event_id)


func _add_season_calendar(parent: Node, selected_event_id: String) -> void:
	var calendar_panel := _add_panel(parent, "Season Calendar", "#17202c")
	_add_body_text(calendar_panel, "Win condition: %s" % String(run.get("season_goal", "Win Worlds before your season lives run out.")))
	_add_body_text(calendar_panel, "Progress: %d/%d events cleared. Select an unlocked event, then register when your deck is ready." % [
		_season_completed_count(),
		_season_calendar_ids().size()
	])

	var grid := GridContainer.new()
	grid.columns = max(1, min(5, _season_calendar_ids().size()))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	calendar_panel.add_child(grid)

	var ids := _season_calendar_ids()
	for index in range(ids.size()):
		var event_id := String(ids[index])
		var event := _season_event_by_id(event_id)
		var completed := _season_event_completed(event_id)
		var unlocked := _season_event_unlocked(event_id)
		var selected := event_id == selected_event_id
		var accent := "#253044"
		var border := "#3a4352"
		var status := "Locked"
		if completed:
			accent = "#1f3329"
			border = "#6f9f6d"
			status = "Cleared"
		elif selected:
			accent = "#2e3040"
			border = "#ffe08a"
			status = "Selected"
		elif unlocked:
			accent = "#202734"
			border = "#7da7ff"
			status = "Available"

		var event_box := _add_bordered_panel(grid, "%s: %s" % [status, String(event.get("name", event_id))], accent, border, 2)
		event_box.custom_minimum_size = Vector2(180, 170)
		_add_body_text(event_box, "Week %d | %d rounds | Need %d wins" % [
			int(event.get("calendarWeek", index + 1)),
			int(event.get("rounds", 0)),
			int(event.get("requiredWins", 0))
		])
		_add_body_text(event_box, "Entry $%d | %s" % [
			int(event.get("entryFee", 0)),
			String(event.get("stage", "Tournament"))
		])
		_add_body_text(event_box, String(event.get("summary", "")))
		var button_label := "Select Event"
		if completed:
			button_label = "Cleared"
		elif not unlocked:
			button_label = "Locked"
		elif selected:
			button_label = "Selected"
		var button := _make_button(button_label)
		button.disabled = completed or not unlocked or selected or _season_tournament_active()
		var selected_calendar_event_id := event_id
		_connect_pressed(button, func() -> void: _select_season_event(selected_calendar_event_id))
		event_box.add_child(button)


func _show_season_run() -> void:
	if _guard_run_over():
		return
	current_screen = "season"
	_render_nav()
	_clear(content)
	_update_status()

	_normalize_season_calendar_state()
	var event: Dictionary = _selected_season_event()
	var event_id := String(event.get("id", _selected_season_event_id()))
	var legal := _deck_is_legal()
	var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
	var primary_archetype: Dictionary = archetypes_by_id[String(metrics.primary)]
	var primary_name := String(primary_archetype.get("name", String(metrics.primary)))

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 10)
	content.add_child(top)

	var season_panel := _add_panel(top, "Season Run", "#1f3329")
	season_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var difficulty := _difficulty_data(_run_difficulty_id())
	_add_body_text(season_panel, "Week %d | $%d | Prize packs: %d" % [
		int(run.get("week", 1)),
		int(run.get("money", 0)),
		int(run.get("prize_packs", 0))
	])
	_add_body_text(season_panel, "%s Border | Lives %d/%d | %s" % [
		String(difficulty.get("name", "White")),
		int(run.get("season_lives", 0)),
		int(run.get("max_season_lives", 0)),
		String(difficulty.get("summary", ""))
	])
	_add_body_text(season_panel, "Goal: %s" % String(run.get("season_goal", "Win Worlds before your season lives run out.")))
	_add_body_text(season_panel, "Selected event: %s | %d rounds | Need %d wins | Entry $%d" % [
		String(event.get("name", event_id)),
		int(event.get("rounds", 0)),
		int(event.get("requiredWins", 0)),
		int(event.get("entryFee", 0))
	])
	_add_body_text(season_panel, String(event.get("winConditionText", "")))
	_add_body_text(season_panel, "Deck: %s | %s" % [
		primary_name,
		"Ready" if bool(legal.get("ok", false)) else String(legal.get("reason", "Not legal"))
	])

	var event_button := _make_button("Register: %s" % String(event.get("name", event_id)))
	event_button.disabled = not bool(legal.get("ok", false)) or int(run.get("money", 0)) < int(event.get("entryFee", 0)) or not _season_event_selectable(event_id)
	_connect_pressed(event_button, _show_tournament)
	season_panel.add_child(event_button)

	var deck_panel := _add_panel(top, "Deck Readiness", "#222936")
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(deck_panel, _format_metrics(metrics))
	var deck_button := _make_button("Tune Deck")
	_connect_pressed(deck_button, _show_deckbuilder)
	deck_panel.add_child(deck_button)

	var notice := String(run.get("season_notice", ""))
	if notice != "":
		var prep_panel := _add_panel(content, "Next Prep", "#263222")
		_add_body_text(prep_panel, notice)

	_add_season_calendar(content, event_id)

	var loop := _add_panel(content, "This Week")
	var actions := GridContainer.new()
	actions.columns = 4
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	loop.add_child(actions)
	_add_season_action(actions, "Card Shop", "Buy singles, sell extras, and decide whether packs are worth the cash.", _show_shop)
	_add_season_action(actions, "Open Packs", "Reveal boosters one card at a time and add them to the collection.", _show_packs)
	_add_season_action(actions, "Deckbuilder", "Convert the collection into the best legal 30-card list.", _show_deckbuilder)
	_add_season_action(actions, "Tournament", "Pay entry, play the event, and either advance the week or end the run.", _show_tournament)

	if run.get("last_result", []).size() > 0:
		var last := _add_panel(content, "Last Result")
		for line in run.last_result:
			_add_body_text(last, line)

	var meta := _add_panel(content, "Metagame Notes", "#202734")
	for line in run.get("reports", []):
		_add_body_text(meta, "• " + String(line))


func _add_season_action(parent: Node, title: String, description: String, callback: Callable) -> void:
	var panel := _add_panel(parent, title, "#202734")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(panel, description)
	var button := _make_button(title)
	_connect_pressed(button, callback)
	panel.add_child(button)


func _show_shop() -> void:
	if _guard_run_over():
		return
	current_screen = "shop"
	_render_nav()
	_clear(content)
	_update_status()

	var event: Dictionary = _selected_tournament_event()
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 10)
	content.add_child(top)

	var event_panel := _add_panel(top, "Card Shop", "#1e2630")
	event_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(
		event_panel,
		"Next event: %s, %d rounds, need %d wins. Entry fee: $%d."
		% [
			String(event.get("name", "Weekly Locals")),
			int(event.get("rounds", 3)),
			int(event.get("requiredWins", 2)),
			int(event.get("entryFee", 0))
		]
	)
	_add_body_text(event_panel, "Money: $%d | Prize packs waiting: %d" % [run.money, run.prize_packs])

	var pack_button := _make_button("Buy & Open Base Booster ($5)")
	pack_button.disabled = run.money < boosters_by_id["base_standard_pack"].price
	_connect_pressed(pack_button, _buy_and_open_pack)
	event_panel.add_child(pack_button)

	var prize_button := _make_button("Open Prize Pack")
	prize_button.disabled = run.prize_packs <= 0
	_connect_pressed(prize_button, _open_prize_pack)
	event_panel.add_child(prize_button)

	var sell_button := _make_button("Sell Extra Copies")
	_connect_pressed(sell_button, _sell_extra_copies)
	event_panel.add_child(sell_button)

	var deck_panel := _add_panel(top, "Current Deck", "#222936")
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_body_text(deck_panel, _format_metrics(metrics))
	var deck_button := _make_button("Tune Deck")
	_connect_pressed(deck_button, _show_deckbuilder)
	deck_panel.add_child(deck_button)

	var singles := _add_panel(content, "Singles Case")
	_add_body_text(singles, "Singles are reliable. Packs are tempting. Your wallet is not large enough for both every week.")

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	singles.add_child(grid)

	for card_id in run.shop:
		var card: Dictionary = cards_by_id[card_id]
		var price := _card_price(card_id)
		var row := _add_card_panel(grid, card_id, "Buy for $%d" % price)
		var button := _make_button("Buy")
		button.disabled = run.money < price
		var selected_id: String = String(card_id)
		_connect_pressed(button, func() -> void: _buy_single(selected_id))
		row.add_child(button)
		_add_body_text(row, card.text)

	var report := _add_panel(content, "Shop Talk")
	for line in run.reports:
		_add_body_text(report, "• " + line)


func _show_packs() -> void:
	if _guard_run_over():
		return
	current_screen = "packs"
	_render_nav()
	_clear(content)
	_update_status()

	var panel := _add_panel(content, "Pack Opening")
	if run.current_pack.is_empty():
		_add_body_text(panel, "No pack is currently open. Buy a booster from the shop or earn prize packs at locals.")
		var buy_button := _make_button("Buy & Open Base Booster ($5)")
		buy_button.disabled = run.money < boosters_by_id["base_standard_pack"].price
		_connect_pressed(buy_button, _buy_and_open_pack)
		panel.add_child(buy_button)
		return

	_add_body_text(panel, "Reveal the pack one card at a time. New cards and deck-relevant cards are highlighted.")

	var reveal_grid := GridContainer.new()
	reveal_grid.columns = 4
	reveal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reveal_grid.add_theme_constant_override("h_separation", 8)
	reveal_grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(reveal_grid)

	for entry in run.revealed_pack:
		_add_card_panel(reveal_grid, entry.cardId, entry.note)

	var remaining: int = run.current_pack.size() - int(run.pack_index)
	if remaining > 0:
		var next_button := _make_button("Reveal Next Card (%d left)" % remaining)
		_connect_pressed(next_button, _reveal_next_card)
		panel.add_child(next_button)

		var all_button := _make_button("Reveal All")
		_connect_pressed(all_button, _reveal_all_cards)
		panel.add_child(all_button)
	else:
		_add_body_text(panel, "Pack complete. Check the deckbuilder to see what changed.")
		var deck_button := _make_button("Open Deckbuilder")
		_connect_pressed(deck_button, _show_deckbuilder)
		panel.add_child(deck_button)


func _buy_and_open_pack() -> void:
	var result: Dictionary = shop_economy_service.buy_and_open_pack(run, "base_standard_pack", _current_primary_archetype())
	if not result.ok:
		_set_footer(result.message)
		return
	_set_footer(result.message)
	_show_packs()


func _open_prize_pack() -> void:
	var result: Dictionary = shop_economy_service.open_prize_pack(run, "base_standard_pack", _current_primary_archetype())
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
	_generate_shop_inventory()
	_show_shop()


func _sell_extra_copies() -> void:
	var total: int = run_state_service.sell_extra_copies(run)
	if total > 0:
		_set_footer("Sold extra copies for $%d." % total)
	else:
		_set_footer("No safe extra copies to sell.")
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


func _card_frame_data(card_id: String, overrides: Dictionary = {}) -> Dictionary:
	var card: Dictionary = cards_by_id.get(card_id, {})
	var combat: Dictionary = card.get("combat", {})
	var animal_type := _card_animal_type(card) if not card.is_empty() else "neutral"
	var kind := String(combat.get("kind", _combat_card_type(card) if not card.is_empty() else "card")).capitalize()
	var attack := -1
	var health := -1
	if String(combat.get("kind", "")) == "unit":
		attack = int(combat.get("attack", -1))
		health = int(combat.get("health", -1))

	var data := {
		"card_id": card_id,
		"title": String(card.get("name", card_id)),
		"cost": int(card.get("cost", -1)),
		"rarity": String(card.get("rarity", "")),
		"type_line": _combat_card_type_line(card) if not card.is_empty() else "",
		"meta_line": "%s | %s | Limit %d" % [
			String(card.get("rarity", "common")).capitalize(),
			kind,
			_deck_limit(card_id) if cards_by_id.has(card_id) else 0
		],
		"combat_stats": _manual_inspect_stats(card, "") if not card.is_empty() else "",
		"deck_stats": _deckbuilder_stats_line(card) if not card.is_empty() else "",
		"effect_text": _combat_effect_summary(card) if not card.is_empty() else "",
		"rules_text": String(card.get("text", "")),
		"attack": attack,
		"health": health,
		"max_health": health,
		"show_attack_health": attack >= 0 and health >= 0,
		"area_text": String(card.get("role", "card")).capitalize(),
		"art_text": "Picture\nplaceholder",
		"animal_color": _affinity_color(animal_type),
			"frame_color": _rarity_line_color(String(card.get("rarity", "common"))),
			"art_color": _combat_placeholder_color(card_id),
			"border_color": _affinity_color(animal_type).lightened(0.12),
			"border_width": 1,
			"frame_id": _card_frame_template_id(card),
			"border_id": _run_difficulty_id()
		}

	for key in overrides.keys():
		data[key] = overrides[key]
	return data


func _card_frame_template_id(card: Dictionary) -> String:
	if card.is_empty():
		return "action_engine_generic"
	var frame_kind := "threat" if _combat_card_type(card) == "threat" else "action_engine"
	return "%s_%s" % [frame_kind, _card_frame_archetype_id(card)]


func _card_frame_archetype_id(card: Dictionary) -> String:
	match _card_animal_type(card):
		"flightless_birds":
			return "aggro"
		"snake":
			return "control"
		"oxen":
			return "ramp"
		"glires":
			return "prop"
		"insect":
			return "revive"
		_:
			return "generic"


func _deckbuilder_stats_line(card: Dictionary) -> String:
	var stats: Dictionary = card.get("stats", {})
	if stats.is_empty():
		return ""
	return "Speed %d | Power %d | Interaction %d\nResilience %d | Advantage %d | Consistency %d" % [
		int(stats.get("speed", 0)),
		int(stats.get("power", 0)),
		int(stats.get("interaction", 0)),
		int(stats.get("resilience", 0)),
		int(stats.get("advantage", 0)),
		int(stats.get("consistency", 0))
	]


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


func _show_combat_lab() -> void:
	if _guard_run_over():
		return
	current_screen = "combat_lab"
	_render_nav()
	_clear(content)
	_update_status()

	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype: String = String(metrics.primary)
	var opponent_archetype: String = _combat_lab_opponent_for(player_archetype)
	var legal := _deck_is_legal()

	var panel := _add_panel(content, "Combat Lab")
	_add_body_text(panel, "This is the workbench for the simplified TCG duel system. It auto-plays a seeded duel using your current deck, then shows the final game state and combat log.")
	_add_body_text(panel, "Your deck: %s | Test opponent: %s" % [archetypes_by_id[player_archetype].name, archetypes_by_id[opponent_archetype].name])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var opponent_row := HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 6)
	panel.add_child(opponent_row)

	var opponent_label := Label.new()
	opponent_label.text = "Opponent:"
	opponent_label.add_theme_color_override("font_color", Color("#c7d0df"))
	opponent_row.add_child(opponent_label)

	for archetype_id in ARCHETYPE_ORDER:
		var archetype: Dictionary = archetypes_by_id[archetype_id]
		var opponent_button := _make_button(archetype.get("name", archetype_id))
		opponent_button.disabled = String(archetype_id) == opponent_archetype
		var selected_id: String = String(archetype_id)
		_connect_pressed(opponent_button, func() -> void: _set_combat_lab_opponent(selected_id))
		opponent_row.add_child(opponent_button)

	var run_button := _make_button("Run Auto Duel")
	run_button.disabled = not legal.ok
	_connect_pressed(run_button, _run_combat_lab_duel)
	panel.add_child(run_button)

	var manual_button := _make_button("Start Manual Battle")
	manual_button.disabled = not legal.ok
	_connect_pressed(manual_button, _start_manual_combat_lab_battle)
	panel.add_child(manual_button)

	if not run.get("manual_combat", {}).is_empty():
		_add_manual_combat_lab(content, run.manual_combat)

	if run.get("last_combat", {}).is_empty():
		return

	var result: Dictionary = run.last_combat
	var summary := _add_panel(content, "Last Combat Test", "#253044" if result.get("winner", "") == "player" else "#442525")
	_add_body_text(summary, "Winner: %s | Seed: %d | Opponent: %s" % [
		String(result.get("winner", "")).capitalize(),
		int(result.get("seed", 0)),
		archetypes_by_id[String(result.get("opponent_archetype", opponent_archetype))].name
	])
	_add_body_text(summary, "Final life: You %d, Opponent %d | Turns: %d" % [
		int(result.get("player_life", 0)),
		int(result.get("opponent_life", 0)),
		int(result.get("turns", 0))
	])

	var snapshots := HBoxContainer.new()
	snapshots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	snapshots.add_theme_constant_override("separation", 10)
	content.add_child(snapshots)
	_add_combatant_snapshot(snapshots, "You", result.get("player_state", {}))
	_add_combatant_snapshot(snapshots, "Opponent", result.get("opponent_state", {}))

	var log_panel := _add_panel(content, "Combat Log")
	for line in result.get("log", []):
		_add_body_text(log_panel, "• " + String(line))


func _show_ui_combat() -> void:
	combat_ui_screen.show(self)


func _show_active_combat_screen() -> void:
	if current_screen == "ui_combat":
		_show_ui_combat()
	else:
		_show_combat_lab()


func _reset_manual_runtime_state(clear_combat: bool = true) -> void:
	if clear_combat:
		run.manual_combat = {}
	run.manual_selection = {}
	run.manual_inspect = {}
	run.manual_battle_log_open = false
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_pending_action = {}
	run.manual_opponent_pending_state = {}


func _combat_lab_opponent_for(player_archetype: String) -> String:
	if not run.has("combat_lab_opponent") or not archetypes_by_id.has(String(run.get("combat_lab_opponent", ""))):
		run.combat_lab_opponent = _predator_archetype(player_archetype)
	return String(run.combat_lab_opponent)


func _set_combat_lab_opponent(archetype_id: String) -> void:
	_manual_clear_hand_card_drag()
	run.combat_lab_opponent = archetype_id
	run.last_combat = {}
	_reset_manual_runtime_state()
	_set_footer("Combat Lab opponent set to " + archetypes_by_id[archetype_id].name + ".")
	_show_active_combat_screen()


func _run_combat_lab_duel() -> void:
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype := String(metrics.primary)
	var opponent_archetype := _combat_lab_opponent_for(player_archetype)
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var seed_value := rng.randi()
	var state: Dictionary = combat_service.auto_play_game(run.deck, player_archetype, opponent_deck, opponent_archetype, seed_value)

	run.last_combat = {
		"seed": seed_value,
		"winner": state.get("winner", ""),
		"player_archetype": player_archetype,
		"opponent_archetype": opponent_archetype,
		"turns": int(state.get("turn", 0)),
		"player_life": int(state.get("player", {}).get("life", 0)),
		"opponent_life": int(state.get("opponent", {}).get("life", 0)),
		"player_board": state.get("player", {}).get("board", []).size(),
		"opponent_board": state.get("opponent", {}).get("board", []).size(),
		"player_state": _summarize_combatant(state.get("player", {})),
		"opponent_state": _summarize_combatant(state.get("opponent", {})),
		"log": state.get("log", [])
	}
	_set_footer("Combat Lab auto-duel complete.")
	_show_combat_lab()


func _start_manual_combat_lab_battle() -> void:
	_manual_clear_hand_card_drag()
	var metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var player_archetype := String(metrics.primary)
	var opponent_archetype := _combat_lab_opponent_for(player_archetype)
	var opponent_deck := _deck_entries_to_dict(archetypes_by_id[opponent_archetype].get("starterDeck", []))
	var seed_value := rng.randi()
	run.manual_combat = combat_service.start_manual_game(run.deck, player_archetype, opponent_deck, opponent_archetype, seed_value)
	_reset_manual_runtime_state(false)
	run.last_combat = {}
	_set_footer("Manual battle started.")
	_show_active_combat_screen()


func _manual_play_card(card_id: String) -> void:
	_manual_play_card_to_slot(card_id, -1)


func _manual_play_card_to_slot(card_id: String, desired_slot_index: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var after_state: Dictionary = combat_service.manual_play_card(before_state.duplicate(true), card_id)
	var destination_anchor := _manual_play_destination_anchor(before_state, after_state, card_id, "auto", current_screen == "ui_combat")
	if cards_by_id.has(card_id):
		match _combat_card_type(cards_by_id[card_id]):
			"threat":
				var placed_slot_index := _manual_assign_new_unit_board_slot(before_state, after_state, "player", card_id, desired_slot_index)
				destination_anchor = _manual_play_destination_anchor(before_state, after_state, card_id, "auto", current_screen == "ui_combat", placed_slot_index)
			"engine":
				var placed_engine_slot := _manual_assign_new_engine_slot(before_state, after_state, "player", card_id, desired_slot_index)
				if current_screen == "ui_combat" and placed_engine_slot >= 0:
					destination_anchor = _manual_engine_slot_anchor(true, placed_engine_slot)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": card_id,
		"source_zone": "Your Hand",
		"target_zone": _manual_play_destination_zone(card_id, "auto"),
		"destination_zone": _manual_play_destination_zone(card_id, "auto"),
		"source_anchor": _manual_hand_card_anchor(card_id),
		"target_anchor": destination_anchor,
		"destination_anchor": destination_anchor,
		"verb": "Play",
		"desired_slot_index": desired_slot_index
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_play_card_target(card_id: String, target_type: String, target_instance_id: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var after_state: Dictionary = combat_service.manual_play_card_with_target(before_state.duplicate(true), card_id, target_type, target_instance_id)
	var target_anchor := _manual_target_anchor(before_state, target_type, target_instance_id, false)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": card_id,
		"source_zone": "Your Hand",
		"target_zone": _manual_target_zone_label(before_state, target_type, target_instance_id),
		"destination_zone": _manual_play_destination_zone(card_id, target_type),
		"source_anchor": _manual_hand_card_anchor(card_id),
		"target_anchor": target_anchor,
		"destination_anchor": _manual_play_destination_anchor(before_state, after_state, card_id, target_type, current_screen == "ui_combat"),
		"verb": "Cast"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_attack(instance_id: int, target_mode: String) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var attacker := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var target_anchor := _manual_target_anchor(before_state, target_mode, -1, false)
	var after_state: Dictionary = combat_service.manual_attack(before_state.duplicate(true), instance_id, target_mode)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(attacker.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": "Best Legal Target",
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": target_anchor if target_anchor != "" else "ManualOpponentPanel",
		"destination_anchor": source_anchor,
		"verb": "Attack"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_attack_target(instance_id: int, target_type: String, target_instance_id: int = -1) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var attacker := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var after_state: Dictionary = combat_service.manual_attack_target(before_state.duplicate(true), instance_id, target_type, target_instance_id)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(attacker.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": _manual_target_zone_label(before_state, target_type, target_instance_id),
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": _manual_target_anchor(before_state, target_type, target_instance_id, false),
		"destination_anchor": source_anchor,
		"verb": "Attack"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_activate_unit_ability(instance_id: int, ability_index: int) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var unit := _manual_find_player_unit(before_state, instance_id)
	var source_anchor := _manual_unit_anchor(before_state, "player", instance_id)
	var after_state: Dictionary = combat_service.manual_activate_unit_ability(before_state.duplicate(true), instance_id, ability_index)
	_manual_stage_or_commit_player_action(before_state, after_state, {
		"card_id": String(unit.get("card_id", "")),
		"source_zone": "Your Board",
		"target_zone": "Ability",
		"destination_zone": "Your Board",
		"source_anchor": source_anchor,
		"target_anchor": source_anchor,
		"destination_anchor": source_anchor,
		"verb": "Activate"
	}, log_start)
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_end_turn() -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action() or _manual_has_pending_opponent_turn():
		return
	_manual_clear_hand_card_drag()
	var before_state: Dictionary = run.manual_combat.duplicate(true)
	var log_start: int = before_state.get("log", []).size()
	var after_state: Dictionary = combat_service.manual_end_player_turn(before_state.duplicate(true))
	var animations := _manual_build_opponent_turn_animation_queue(before_state, after_state, log_start)
	if current_screen == "ui_combat" and not animations.is_empty():
		run.manual_combat = _manual_visible_opponent_turn_animation_state(before_state, after_state)
		run.manual_opponent_pending_state = after_state
		_manual_set_animation_queue(animations)
	else:
		run.manual_combat = after_state
		run.manual_opponent_pending_state = {}
		_manual_set_animation_queue(animations)
	run.manual_selection = {}
	_show_active_combat_screen()


func _clear_manual_battle() -> void:
	if _season_tournament_active():
		_season_forfeit_current_round()
		return
	_manual_clear_hand_card_drag()
	_reset_manual_runtime_state()
	_set_footer("Manual battle cleared.")
	_show_active_combat_screen()


func _toggle_manual_battle_log() -> void:
	if run.is_empty():
		return
	run.manual_battle_log_open = not bool(run.get("manual_battle_log_open", false))
	_show_active_combat_screen()


func _manual_clear_inspect_overlay() -> void:
	if run.is_empty():
		return
	if run.get("manual_inspect", {}).is_empty():
		return
	run.manual_inspect = {}
	if current_screen == "ui_combat":
		_show_active_combat_screen()
	else:
		_refresh_manual_inspect_panel()


func _manual_clear_ui_combat_context() -> void:
	if run.is_empty():
		return
	run.manual_inspect = {}
	run.manual_selection = {}
	_show_active_combat_screen()


func _manual_select_card(card_id: String) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	run.manual_selection = { "kind": "card", "card_id": card_id }
	_manual_set_inspect_card(card_id, "Hand", "", true)
	_set_footer("Selected " + cards_by_id[card_id].get("name", card_id) + ". Choose a highlighted target.")
	_show_active_combat_screen()


func _manual_select_attacker(instance_id: int) -> void:
	if run.get("manual_combat", {}).is_empty() or _manual_has_pending_action():
		return
	run.manual_selection = { "kind": "attacker", "instance_id": instance_id }
	var attacker := _manual_find_player_unit(run.manual_combat, instance_id)
	if not attacker.is_empty():
		_manual_set_inspect_card(String(attacker.get("card_id", "")), "Your Board", _manual_current_unit_summary(attacker), true)
	_set_footer("Selected attacker. Choose a highlighted target.")
	_show_active_combat_screen()


func _manual_clear_selection() -> void:
	run.manual_selection = {}
	_set_footer("Selection cleared.")
	_show_active_combat_screen()


func _manual_target_face() -> void:
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			_manual_play_card_target(String(selection.get("card_id", "")), "face", -1)
		"attacker":
			_manual_attack_target(int(selection.get("instance_id", -1)), "face", -1)


func _manual_target_unit(instance_id: int) -> void:
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			_manual_play_card_target(String(selection.get("card_id", "")), "unit", instance_id)
		"attacker":
			_manual_attack_target(int(selection.get("instance_id", -1)), "unit", instance_id)


func _manual_commit_action_animation(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int) -> void:
	var animation := _manual_build_action_animation(before_state, after_state, descriptor, log_start)
	if animation.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
		return
	run.manual_animation = animation
	run.manual_animation_queue = []


func _manual_stage_or_commit_player_action(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int) -> void:
	var animation := _manual_build_action_animation(before_state, after_state, descriptor, log_start)
	if current_screen == "ui_combat" and _manual_card_action_commits_immediately(descriptor):
		run.manual_combat = after_state
		run.manual_pending_action = {}
		if animation.is_empty():
			run.manual_animation = {}
			run.manual_animation_queue = []
		else:
			animation["board_vfx_started"] = true
			run.manual_animation = animation
			run.manual_animation_queue = []
		return
	if current_screen == "ui_combat" and not animation.is_empty():
		_manual_stage_pending_action(after_state, animation)
		return

	run.manual_combat = after_state
	if animation.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
	else:
		run.manual_animation = animation
		run.manual_animation_queue = []


func _manual_card_action_commits_immediately(descriptor: Dictionary) -> bool:
	if String(descriptor.get("source_zone", "")) != "Your Hand":
		return false
	var card_id := String(descriptor.get("card_id", ""))
	if card_id == "" or not cards_by_id.has(card_id):
		return false
	match _combat_card_type(cards_by_id[card_id]):
		"threat":
			return true
		"engine":
			return int(descriptor.get("desired_slot_index", -1)) >= 0
	return false


func _manual_stage_pending_action(after_state: Dictionary, animation: Dictionary) -> void:
	animation["pending_commit"] = true
	run.manual_animation = animation
	run.manual_animation_queue = []
	run.manual_pending_action = {
		"after_state": after_state,
		"commit_scheduled": false
	}
	call_deferred("_manual_schedule_pending_action_commit")


func _manual_has_pending_action() -> bool:
	return not run.get("manual_pending_action", {}).is_empty()


func _manual_schedule_pending_action_commit() -> void:
	if run.is_empty():
		return
	var pending: Dictionary = run.get("manual_pending_action", {})
	if pending.is_empty():
		return
	if bool(pending.get("commit_scheduled", false)):
		return
	pending["commit_scheduled"] = true
	run.manual_pending_action = pending
	var timer := get_tree().create_timer(MANUAL_PENDING_ACTION_COMMIT_DELAY)
	timer.timeout.connect(Callable(self, "_manual_commit_pending_action"))


func _manual_commit_pending_action() -> void:
	if run.is_empty():
		return
	var pending: Dictionary = run.get("manual_pending_action", {})
	if pending.is_empty():
		return
	var after_state: Dictionary = pending.get("after_state", {})
	if not after_state.is_empty():
		run.manual_combat = after_state
	var animation: Dictionary = run.get("manual_animation", {})
	if not animation.is_empty():
		animation["board_vfx_started"] = true
		animation.erase("pending_commit")
		run.manual_animation = animation
	run.manual_pending_action = {}
	run.manual_selection = {}
	if current_screen == "ui_combat":
		_show_active_combat_screen()


func _manual_build_action_animation(before_state: Dictionary, after_state: Dictionary, descriptor: Dictionary, log_start: int, log_end: int = -1) -> Dictionary:
	var log_lines: Array = after_state.get("log", [])
	var new_lines: Array = []
	var end_index: int = log_lines.size() if log_end < 0 else int(min(log_end, log_lines.size()))
	for i in range(log_start, end_index):
		new_lines.append(String(log_lines[i]))

	if new_lines.is_empty() or not _manual_log_has_animation_event(new_lines):
		return {}

	var card_id := String(descriptor.get("card_id", ""))
	var card_name := String(descriptor.get("card_name", ""))
	if card_name == "" and cards_by_id.has(card_id):
		card_name = String(cards_by_id[card_id].get("name", card_id))
	if card_name == "":
		card_name = String(descriptor.get("verb", "Action"))

	return {
		"card_id": card_id,
		"card_name": card_name,
		"source_zone": String(descriptor.get("source_zone", "Source")),
		"target_zone": String(descriptor.get("target_zone", "Target")),
		"destination_zone": String(descriptor.get("destination_zone", "Destination")),
		"source_anchor": String(descriptor.get("source_anchor", "")),
		"target_anchor": String(descriptor.get("target_anchor", "")),
		"destination_anchor": String(descriptor.get("destination_anchor", "")),
		"source_global_point": _manual_capture_anchor_global_point(String(descriptor.get("source_anchor", ""))),
		"target_global_point": _manual_capture_anchor_global_point(String(descriptor.get("target_anchor", ""))),
		"destination_global_point": _manual_capture_anchor_global_point(String(descriptor.get("destination_anchor", ""))),
		"verb": String(descriptor.get("verb", "Action")),
		"summary": new_lines.slice(max(0, new_lines.size() - 4), new_lines.size()),
		"badges": _manual_impact_badges_from_log(new_lines)
	}


func _manual_set_animation_queue(animations: Array) -> void:
	if animations.is_empty():
		run.manual_animation = {}
		run.manual_animation_queue = []
		return
	run.manual_animation = animations[0]
	run.manual_animation_queue = animations.slice(1, animations.size()) if animations.size() > 1 else []


func _manual_visible_opponent_turn_animation_state(before_state: Dictionary, after_state: Dictionary) -> Dictionary:
	var visible := before_state.duplicate(true)
	visible["active_side"] = "opponent"
	visible["phase"] = "opponent_animating"
	visible["game_over"] = false
	visible["winner"] = ""
	visible["log"] = after_state.get("log", []).duplicate(true)
	return visible


func _manual_has_pending_opponent_turn() -> bool:
	return not run.get("manual_opponent_pending_state", {}).is_empty()


func _manual_schedule_pending_opponent_turn_commit(animation: Dictionary) -> void:
	if not _manual_has_pending_opponent_turn():
		return
	if bool(animation.get("opponent_commit_scheduled", false)):
		return
	animation["opponent_commit_scheduled"] = true
	run.manual_animation = animation
	var timer := get_tree().create_timer(1.12)
	timer.timeout.connect(Callable(self, "_manual_commit_pending_opponent_turn"))


func _manual_commit_pending_opponent_turn() -> void:
	if run.is_empty():
		return
	var pending: Dictionary = run.get("manual_opponent_pending_state", {})
	if pending.is_empty():
		return
	run.manual_combat = pending
	run.manual_opponent_pending_state = {}
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_selection = {}
	if current_screen == "ui_combat":
		_show_active_combat_screen()


func _manual_apply_completed_opponent_play_animation(animation: Dictionary) -> void:
	if animation.is_empty() or not _manual_has_pending_opponent_turn():
		return
	if String(animation.get("verb", "")) != "Play" or String(animation.get("source_zone", "")) != "Opponent Hand":
		return
	var card_id := String(animation.get("card_id", ""))
	if card_id == "":
		return
	var visible: Dictionary = run.get("manual_combat", {})
	var pending: Dictionary = run.get("manual_opponent_pending_state", {})
	if visible.is_empty() or pending.is_empty() or String(visible.get("phase", "")) != "opponent_animating":
		return
	var revealed := false
	match String(animation.get("destination_zone", "")):
		"Opponent Board":
			revealed = _manual_reveal_pending_opponent_unit(visible, pending, card_id)
		"Opponent Engine Zone":
			revealed = _manual_reveal_pending_opponent_engine(visible, pending, card_id)
	if revealed:
		_manual_remove_visible_opponent_hand_card(visible, card_id)
		run.manual_combat = visible


func _manual_reveal_pending_opponent_unit(visible: Dictionary, pending: Dictionary, card_id: String) -> bool:
	var visible_opponent: Dictionary = visible.get("opponent", {})
	var pending_opponent: Dictionary = pending.get("opponent", {})
	var visible_ids := {}
	for visible_unit in visible_opponent.get("board", []):
		visible_ids[int(visible_unit.get("instance_id", -1))] = true
	for pending_unit in pending_opponent.get("board", []):
		if String(pending_unit.get("card_id", "")) != card_id:
			continue
		var instance_id := int(pending_unit.get("instance_id", -1))
		if visible_ids.has(instance_id):
			continue
		var visible_board: Array = visible_opponent.get("board", [])
		visible_board.append(pending_unit.duplicate(true))
		visible_opponent["board"] = visible_board
		visible["opponent"] = visible_opponent
		return true
	return false


func _manual_reveal_pending_opponent_engine(visible: Dictionary, pending: Dictionary, card_id: String) -> bool:
	var visible_opponent: Dictionary = visible.get("opponent", {})
	var pending_opponent: Dictionary = pending.get("opponent", {})
	var visible_engines: Array = visible_opponent.get("engines", [])
	var pending_engines: Array = pending_opponent.get("engines", [])
	var visible_count := 0
	for visible_engine in visible_engines:
		if String(visible_engine.get("card_id", "")) == card_id:
			visible_count += 1
	var matching_pending_seen := 0
	for pending_engine in pending_engines:
		if String(pending_engine.get("card_id", "")) != card_id:
			continue
		if matching_pending_seen < visible_count:
			matching_pending_seen += 1
			continue
		visible_engines.append(pending_engine.duplicate(true))
		visible_opponent["engines"] = visible_engines
		visible["opponent"] = visible_opponent
		return true
	return false


func _manual_remove_visible_opponent_hand_card(visible: Dictionary, card_id: String) -> void:
	var visible_opponent: Dictionary = visible.get("opponent", {})
	var hand: Array = visible_opponent.get("hand", [])
	var hand_index := hand.find(card_id)
	if hand_index < 0:
		return
	hand.remove_at(hand_index)
	visible_opponent["hand"] = hand
	visible["opponent"] = visible_opponent


func _manual_build_opponent_turn_animation_queue(before_state: Dictionary, after_state: Dictionary, log_start: int) -> Array:
	var animations: Array = []
	var log_lines: Array = after_state.get("log", [])
	var used_new_units := {}
	var used_action_counts := {}
	var in_opponent_turn := false
	for i in range(log_start, log_lines.size()):
		var line := String(log_lines[i])
		if line.begins_with("Opponent turn"):
			in_opponent_turn = true
			continue
		if in_opponent_turn and line.begins_with("You turn"):
			break
		if not in_opponent_turn:
			continue

		var descriptor := _manual_opponent_animation_descriptor_for_line(line, before_state, after_state, used_new_units, used_action_counts)
		if descriptor.is_empty():
			continue
		var animation := _manual_build_action_animation(before_state, after_state, descriptor, i, i + 1)
		if not animation.is_empty():
			animations.append(animation)
	return animations


func _manual_opponent_animation_descriptor_for_line(line: String, before_state: Dictionary, after_state: Dictionary, used_new_units: Dictionary, used_action_counts: Dictionary) -> Dictionary:
	if line.begins_with("Opponent plays engine "):
		var engine_name := _manual_trim_sentence_end(_manual_text_after(line, "Opponent plays engine "))
		var engine_id := _manual_card_id_for_name(engine_name, before_state, after_state)
		return {
			"card_id": engine_id,
			"card_name": engine_name,
			"source_zone": "Opponent Hand",
			"target_zone": "Opponent Engine Zone",
			"destination_zone": "Opponent Engine Zone",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": "ManualZone_OpponentEngine",
			"destination_anchor": "ManualZone_OpponentEngine",
			"verb": "Play"
		}

	if line.begins_with("Opponent plays "):
		var unit_name := _manual_text_between(line, "Opponent plays ", " as a ")
		if unit_name == "":
			return {}
		var unit_card_id := _manual_card_id_for_name(unit_name, before_state, after_state)
		var unit_anchor := _manual_new_unit_anchor_for_event(before_state, after_state, "opponent", unit_card_id, used_new_units)
		if unit_anchor == "":
			unit_anchor = "ManualZone_OpponentBoard"
		return {
			"card_id": unit_card_id,
			"card_name": unit_name,
			"source_zone": "Opponent Hand",
			"target_zone": "Opponent Board",
			"destination_zone": "Opponent Board",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": unit_anchor,
			"destination_anchor": unit_anchor,
			"verb": "Play"
		}

	if line.begins_with("Opponent casts "):
		var cast_name := _manual_cast_card_name_from_line(line)
		if cast_name == "":
			return {}
		var cast_has_target := line.contains(" to ")
		var cast_target_name: String = _manual_trim_sentence_end(_manual_text_after(line, " to ")) if cast_has_target else ""
		var cast_target_anchor: String = _manual_target_anchor_for_opponent_log_name(before_state, after_state, cast_target_name) if cast_has_target else "ManualZone_OpponentBoard"
		return {
			"card_id": _manual_card_id_for_name(cast_name, before_state, after_state),
			"card_name": cast_name,
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(cast_target_name) if cast_has_target else "Action",
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": cast_target_anchor,
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	if line.begins_with("Opponent fires finisher "):
		var finisher_name := _manual_text_between(line, "Opponent fires finisher ", " at ")
		if finisher_name == "":
			return {}
		var finisher_target_name := _manual_trim_sentence_end(_manual_text_after(line, " at "))
		return {
			"card_id": _manual_card_id_for_name(finisher_name, before_state, after_state),
			"card_name": finisher_name,
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(finisher_target_name),
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": _manual_target_anchor_for_opponent_log_name(before_state, after_state, finisher_target_name),
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	var effect_action_id := _manual_opponent_action_card_id_from_effect_line(line, before_state, after_state, used_action_counts)
	if effect_action_id != "":
		used_action_counts[effect_action_id] = int(used_action_counts.get(effect_action_id, 0)) + 1
		var effect_target_name := _manual_effect_target_name_from_line(line)
		var has_effect_target := effect_target_name != ""
		return {
			"card_id": effect_action_id,
			"card_name": String(cards_by_id[effect_action_id].get("name", effect_action_id)),
			"source_zone": "Opponent Hand",
			"target_zone": _manual_target_zone_for_opponent_log_name(effect_target_name) if has_effect_target else "Action",
			"destination_zone": "Opponent Discard",
			"source_anchor": "ManualOpponentFanHand",
			"target_anchor": _manual_target_anchor_for_opponent_log_name(before_state, after_state, effect_target_name) if has_effect_target else "ManualZone_OpponentBoard",
			"destination_anchor": "ManualZone_OpponentDiscard",
			"verb": "Cast"
		}

	if line.contains(" attacks You for "):
		var attacker_name := _manual_text_between(line, "", " attacks You for ")
		var source_anchor := _manual_unit_anchor_by_name(before_state, after_state, "opponent", attacker_name)
		return {
			"card_id": _manual_unit_card_id_by_name(before_state, after_state, "opponent", attacker_name),
			"card_name": attacker_name,
			"source_zone": "Opponent Board",
			"target_zone": "Your Face",
			"destination_zone": "Opponent Board",
			"source_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"target_anchor": _manual_face_anchor_for_side("player"),
			"destination_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"verb": "Attack"
		}

	if line.contains(" trades with "):
		var attacker_name := _manual_text_between(line, "", " trades with ")
		var target_name := _manual_trim_sentence_end(_manual_text_after(line, " trades with "))
		var source_anchor := _manual_unit_anchor_by_name(before_state, after_state, "opponent", attacker_name)
		var target_anchor := _manual_unit_anchor_by_name(before_state, after_state, "player", target_name)
		return {
			"card_id": _manual_unit_card_id_by_name(before_state, after_state, "opponent", attacker_name),
			"card_name": attacker_name,
			"source_zone": "Opponent Board",
			"target_zone": "Your Board",
			"destination_zone": "Opponent Board",
			"source_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"target_anchor": target_anchor if target_anchor != "" else "ManualZone_PlayerBoard",
			"destination_anchor": source_anchor if source_anchor != "" else "ManualZone_OpponentBoard",
			"verb": "Attack"
		}

	return {}


func _manual_cast_card_name_from_line(line: String) -> String:
	var card_name := _manual_text_between(line, "Opponent casts ", " for ")
	if card_name != "":
		return card_name
	card_name = _manual_text_between(line, "Opponent casts ", " and draws")
	if card_name != "":
		return card_name
	return _manual_text_between(line, "Opponent casts ", " for tempo")


func _manual_opponent_action_card_id_from_effect_line(line: String, before_state: Dictionary, after_state: Dictionary, used_action_counts: Dictionary) -> String:
	var available_counts := _manual_new_opponent_discarded_action_counts(before_state, after_state)
	for card_id_value in available_counts.keys():
		var card_id := String(card_id_value)
		if int(used_action_counts.get(card_id, 0)) >= int(available_counts.get(card_id, 0)):
			continue
		if not cards_by_id.has(card_id):
			continue
		var card_name := String(cards_by_id[card_id].get("name", card_id))
		if line.begins_with(card_name + " ") or line.begins_with(card_name + "'s "):
			return card_id
	return ""


func _manual_new_opponent_discarded_action_counts(before_state: Dictionary, after_state: Dictionary) -> Dictionary:
	var before_counts := _manual_card_count_map(before_state.get("opponent", {}).get("discard", []))
	var after_counts := _manual_card_count_map(after_state.get("opponent", {}).get("discard", []))
	var counts := {}
	for card_id_value in after_counts.keys():
		var card_id := String(card_id_value)
		var delta := int(after_counts.get(card_id, 0)) - int(before_counts.get(card_id, 0))
		if delta <= 0 or not cards_by_id.has(card_id):
			continue
		if _combat_card_type(cards_by_id[card_id]) == "action":
			counts[card_id] = delta
	return counts


func _manual_card_count_map(card_ids: Array) -> Dictionary:
	var counts := {}
	for card_id_value in card_ids:
		var card_id := String(card_id_value)
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	return counts


func _manual_effect_target_name_from_line(line: String) -> String:
	return _manual_trim_sentence_end(_manual_text_after(line, " to "))


func _manual_target_anchor_for_opponent_log_name(before_state: Dictionary, after_state: Dictionary, target_name: String) -> String:
	if target_name == "" or target_name == "You":
		return _manual_face_anchor_for_side("player")
	if target_name == "Opponent":
		return _manual_face_anchor_for_side("opponent")
	var player_unit_anchor := _manual_unit_anchor_by_name(before_state, after_state, "player", target_name)
	if player_unit_anchor != "":
		return player_unit_anchor
	return "ManualZone_PlayerBoard"


func _manual_target_zone_for_opponent_log_name(target_name: String) -> String:
	if target_name == "" or target_name == "You":
		return "Your Face"
	if target_name == "Opponent":
		return "Opponent Face"
	return "Your Board"


func _manual_face_anchor_for_side(side: String) -> String:
	if current_screen == "ui_combat":
		return "ManualFanHand" if side == "player" else "ManualOpponentFanHand"
	return "ManualPlayerPanel" if side == "player" else "ManualOpponentPanel"


func _manual_new_unit_anchor_for_event(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, used_new_units: Dictionary) -> String:
	var before_ids := {}
	var before_combatant: Dictionary = before_state.get(side, {})
	for unit in before_combatant.get("board", []):
		before_ids[int(unit.get("instance_id", -1))] = true
	var after_combatant: Dictionary = after_state.get(side, {})
	for unit in after_combatant.get("board", []):
		var instance_id := int(unit.get("instance_id", -1))
		if before_ids.has(instance_id) or used_new_units.has(instance_id):
			continue
		if card_id != "" and String(unit.get("card_id", "")) != card_id:
			continue
		used_new_units[instance_id] = true
		return _manual_unit_card_anchor(side == "player", instance_id)
	return ""


func _manual_unit_anchor_by_name(before_state: Dictionary, after_state: Dictionary, side: String, unit_name: String) -> String:
	var before_anchor := _manual_unit_anchor_by_name_in_state(before_state, side, unit_name)
	if before_anchor != "":
		return before_anchor
	return _manual_unit_anchor_by_name_in_state(after_state, side, unit_name)


func _manual_unit_anchor_by_name_in_state(state: Dictionary, side: String, unit_name: String) -> String:
	var combatant: Dictionary = state.get(side, {})
	for unit in combatant.get("board", []):
		if String(unit.get("name", "")) == unit_name:
			return _manual_unit_card_anchor(side == "player", int(unit.get("instance_id", -1)))
	return ""


func _manual_unit_card_id_by_name(before_state: Dictionary, after_state: Dictionary, side: String, unit_name: String) -> String:
	var before_id := _manual_unit_card_id_by_name_in_state(before_state, side, unit_name)
	if before_id != "":
		return before_id
	return _manual_unit_card_id_by_name_in_state(after_state, side, unit_name)


func _manual_unit_card_id_by_name_in_state(state: Dictionary, side: String, unit_name: String) -> String:
	var combatant: Dictionary = state.get(side, {})
	for unit in combatant.get("board", []):
		if String(unit.get("name", "")) == unit_name:
			return String(unit.get("card_id", ""))
	return ""


func _manual_card_id_for_name(card_name: String, before_state: Dictionary, after_state: Dictionary) -> String:
	var candidates: Array = []
	_manual_append_opponent_card_candidates(candidates, before_state)
	_manual_append_opponent_card_candidates(candidates, after_state)
	for card_id_value in candidates:
		var card_id := String(card_id_value)
		if cards_by_id.has(card_id) and String(cards_by_id[card_id].get("name", card_id)) == card_name:
			return card_id
	for card_id_value in cards_by_id.keys():
		var card_id := String(card_id_value)
		if String(cards_by_id[card_id].get("name", card_id)) == card_name:
			return card_id
	return ""


func _manual_append_opponent_card_candidates(candidates: Array, state: Dictionary) -> void:
	var opponent: Dictionary = state.get("opponent", {})
	for card_id in opponent.get("hand", []):
		candidates.append(String(card_id))
	for card_id in opponent.get("discard", []):
		candidates.append(String(card_id))
	for unit in opponent.get("board", []):
		candidates.append(String(unit.get("card_id", "")))
	for engine in opponent.get("engines", []):
		candidates.append(String(engine.get("card_id", "")))


func _manual_text_between(text: String, prefix: String, suffix: String) -> String:
	var start := 0
	if prefix != "":
		start = text.find(prefix)
		if start < 0:
			return ""
		start += prefix.length()
	var end := text.find(suffix, start)
	if end < 0:
		return ""
	return text.substr(start, end - start).strip_edges()


func _manual_text_after(text: String, prefix: String) -> String:
	var start := text.find(prefix)
	if start < 0:
		return ""
	start += prefix.length()
	return text.substr(start).strip_edges()


func _manual_trim_sentence_end(text: String) -> String:
	var trimmed := text.strip_edges()
	while trimmed.ends_with("."):
		trimmed = trimmed.substr(0, trimmed.length() - 1).strip_edges()
	return trimmed


func _manual_log_has_animation_event(lines: Array) -> bool:
	for line_value in lines:
		var lower := String(line_value).to_lower()
		if lower.contains("plays") or lower.contains("casts") or lower.contains("attacks") or lower.contains("deals"):
			return true
		if lower.contains("damage") or lower.contains("trades") or lower.contains("dies") or lower.contains("destroy"):
			return true
		if lower.contains("restore") or lower.contains("heal") or lower.contains("draw") or lower.contains("creates"):
			return true
		if lower.contains("activates") or lower.contains("exhausts") or lower.contains("gains"):
			return true
	return false


func _manual_impact_badges_from_log(lines: Array) -> Array:
	var badges: Array = []
	for line_value in lines:
		var line := String(line_value)
		var lower := line.to_lower()
		var amount := _manual_first_int_in_text(line)
		if lower.contains("damage") or lower.contains("deals") or lower.contains("attacks") or lower.contains("takes"):
			badges.append({
				"kind": "damage",
				"text": "-%d" % max(1, amount),
				"line": line
			})
		elif lower.contains("restore") or lower.contains("heal"):
			badges.append({
				"kind": "heal",
				"text": "+%d" % max(0, amount),
				"line": line
			})
		elif lower.contains("draw"):
			badges.append({
				"kind": "draw",
				"text": "DRAW %d" % max(1, amount),
				"line": line
			})
		elif lower.contains("creates") or lower.contains("plays") or lower.contains("casts"):
			badges.append({
				"kind": "play",
				"text": "PLAY",
				"line": line
			})
		elif lower.contains("dies") or lower.contains("destroy"):
			badges.append({
				"kind": "ko",
				"text": "KO",
				"line": line
			})
		elif lower.contains("gains") and lower.contains("focus"):
			badges.append({
				"kind": "focus",
				"text": "+%d FOCUS" % max(1, amount),
				"line": line
			})
	if badges.size() > 5:
		return badges.slice(0, 5)
	return badges


func _manual_first_int_in_text(text: String) -> int:
	var digits := ""
	for i in range(text.length()):
		var character := text.substr(i, 1)
		if character >= "0" and character <= "9":
			digits += character
		elif digits != "":
			break
	if digits == "":
		return 0
	return int(digits)


func _manual_play_destination_zone(card_id: String, target_type: String) -> String:
	if not cards_by_id.has(card_id):
		return "Destination"
	var card: Dictionary = cards_by_id[card_id]
	match _combat_card_type(card):
		"threat":
			return "Your Board"
		"engine":
			return "Your Engine Zone"
		"action":
			if target_type == "face":
				return "Opponent Face, then Discard"
			if target_type == "unit":
				return "Opponent Board, then Discard"
			return "Discard Zone"
	return "Destination"


func _manual_target_zone_label(state: Dictionary, target_type: String, target_instance_id: int) -> String:
	match target_type:
		"face":
			return "Opponent Face"
		"unit":
			var opponent: Dictionary = state.get("opponent", {})
			for unit in opponent.get("board", []):
				if int(unit.get("instance_id", -1)) == target_instance_id:
					return "Opponent Board: " + String(unit.get("name", "Unit"))
			return "Opponent Board"
		"auto":
			return "Auto Target"
		_:
			return "Target"


func _manual_play_destination_anchor(before_state: Dictionary, after_state: Dictionary, card_id: String, target_type: String, prefer_slot_anchor: bool = false, preferred_slot_index: int = -1) -> String:
	if not cards_by_id.has(card_id):
		return "ManualZone_PlayerDiscard"
	var card: Dictionary = cards_by_id[card_id]
	match _combat_card_type(card):
		"threat":
			if prefer_slot_anchor:
				if preferred_slot_index >= 0:
					return _manual_board_slot_anchor(true, preferred_slot_index)
				var slot_anchor := _manual_new_unit_slot_anchor(before_state, after_state, "player", card_id)
				if slot_anchor != "":
					return slot_anchor
			var new_unit_anchor := _manual_new_unit_anchor(before_state, after_state, "player", card_id)
			return new_unit_anchor if new_unit_anchor != "" else "ManualZone_PlayerBoard"
		"engine":
			return "ManualZone_PlayerEngine"
		"action":
			if target_type == "face" or target_type == "unit":
				return "ManualZone_PlayerDiscard"
			return "ManualZone_PlayerDiscard"
	return "ManualZone_PlayerDiscard"


func _manual_new_unit_slot_anchor(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String) -> String:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))
	var after_board: Array = after_combatant.get("board", [])
	var slotted_units := _manual_units_by_board_slot(after_board)
	for slot_index in range(slotted_units.size()):
		var unit: Dictionary = slotted_units[slot_index]
		if unit.is_empty():
			continue
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			return _manual_board_slot_anchor(side == "player", slot_index)
	return ""


func _manual_target_anchor(state: Dictionary, target_type: String, target_instance_id: int, prefer_face_affordance: bool) -> String:
	match target_type:
		"face":
			if current_screen == "ui_combat":
				return "ManualFaceTargetAffordance" if prefer_face_affordance else "ManualOpponentFanHand"
			return "ManualFaceTargetAffordance" if prefer_face_affordance else "ManualOpponentPanel"
		"unit":
			return _manual_unit_anchor(state, "opponent", target_instance_id)
		"player":
			return "ManualPlayerPanel"
		"auto":
			return "ManualOpponentPanel"
		_:
			return ""


func _manual_unit_anchor(state: Dictionary, side: String, instance_id: int) -> String:
	var combatant: Dictionary = state.get("player" if side == "player" else "opponent", {})
	var slot_index := _manual_unit_slot_index(combatant, instance_id)
	if slot_index >= 0:
		return _manual_unit_card_anchor(side == "player", instance_id)
	return "ManualZone_PlayerBoard" if side == "player" else "ManualZone_OpponentBoard"


func _manual_new_unit_anchor(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String) -> String:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))
	for unit_index in range(after_combatant.get("board", []).size()):
		var unit: Dictionary = after_combatant.get("board", [])[unit_index]
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			return _manual_unit_card_anchor(side == "player", int(unit.get("instance_id", -1)))
	return ""


func _manual_unit_slot_index(combatant: Dictionary, instance_id: int) -> int:
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	for unit_index in range(slotted_units.size()):
		var unit: Dictionary = slotted_units[unit_index]
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit_index
	return -1


func _manual_assign_new_unit_board_slot(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, desired_slot_index: int) -> int:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var before_ids: Array = []
	for unit in before_combatant.get("board", []):
		before_ids.append(int(unit.get("instance_id", -1)))

	var slot_index := desired_slot_index
	if not _manual_board_slot_is_open(before_combatant, slot_index):
		slot_index = _manual_first_open_board_slot(before_combatant)
	if slot_index < 0:
		return -1

	var after_board: Array = after_combatant.get("board", [])
	for unit in after_board:
		if String(unit.get("card_id", "")) == card_id and not before_ids.has(int(unit.get("instance_id", -1))):
			unit["board_slot"] = slot_index
			return slot_index
	return -1


func _manual_board_slot_is_open(combatant: Dictionary, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= COMBAT_BOARD_SLOTS:
		return false
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	return slot_index < slotted_units.size() and slotted_units[slot_index].is_empty()


func _manual_first_open_board_slot(combatant: Dictionary) -> int:
	var slotted_units := _manual_units_by_board_slot(combatant.get("board", []))
	for slot_index in range(slotted_units.size()):
		if slotted_units[slot_index].is_empty():
			return slot_index
	return -1


func _manual_units_by_board_slot(units: Array) -> Array:
	var slotted_units: Array = []
	for i in range(COMBAT_BOARD_SLOTS):
		slotted_units.append({})

	var deferred_units: Array = []
	for unit_value in units:
		var unit: Dictionary = unit_value
		var desired_slot := int(unit.get("board_slot", -1))
		if desired_slot >= 0 and desired_slot < COMBAT_BOARD_SLOTS and slotted_units[desired_slot].is_empty():
			slotted_units[desired_slot] = unit
		else:
			deferred_units.append(unit)

	for unit in deferred_units:
		for slot_index in range(COMBAT_BOARD_SLOTS):
			if slotted_units[slot_index].is_empty():
				slotted_units[slot_index] = unit
				break
	return slotted_units


func _manual_assign_new_engine_slot(before_state: Dictionary, after_state: Dictionary, side: String, card_id: String, desired_slot_index: int) -> int:
	var before_combatant: Dictionary = before_state.get("player" if side == "player" else "opponent", {})
	var after_combatant: Dictionary = after_state.get("player" if side == "player" else "opponent", {})
	var slot_index := desired_slot_index
	if not _manual_engine_slot_is_open(before_combatant, slot_index):
		slot_index = _manual_first_open_engine_slot(before_combatant)
	if slot_index < 0:
		return -1

	var remaining_existing := 0
	for engine in before_combatant.get("engines", []):
		if String(engine.get("card_id", "")) == card_id:
			remaining_existing += 1

	for engine in after_combatant.get("engines", []):
		if String(engine.get("card_id", "")) != card_id:
			continue
		if remaining_existing > 0:
			remaining_existing -= 1
			continue
		engine["engine_slot"] = slot_index
		return slot_index
	return -1


func _manual_engine_slot_is_open(combatant: Dictionary, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= COMBAT_ENGINE_SLOTS:
		return false
	var slotted_engines := _manual_engines_by_slot(combatant.get("engines", []))
	return slot_index < slotted_engines.size() and slotted_engines[slot_index].is_empty()


func _manual_first_open_engine_slot(combatant: Dictionary) -> int:
	var slotted_engines := _manual_engines_by_slot(combatant.get("engines", []))
	for slot_index in range(slotted_engines.size()):
		if slotted_engines[slot_index].is_empty():
			return slot_index
	return -1


func _manual_engines_by_slot(engines: Array) -> Array:
	var slotted_engines: Array = []
	for i in range(COMBAT_ENGINE_SLOTS):
		slotted_engines.append({})

	var deferred_engines: Array = []
	for engine_value in engines:
		var engine: Dictionary = engine_value
		var desired_slot := int(engine.get("engine_slot", -1))
		if desired_slot >= 0 and desired_slot < COMBAT_ENGINE_SLOTS and slotted_engines[desired_slot].is_empty():
			slotted_engines[desired_slot] = engine
		else:
			deferred_engines.append(engine)

	for engine in deferred_engines:
		for slot_index in range(COMBAT_ENGINE_SLOTS):
			if slotted_engines[slot_index].is_empty():
				slotted_engines[slot_index] = engine
				break
	return slotted_engines


func _manual_engine_slot_anchor(is_player: bool, slot_index: int) -> String:
	return "ManualEngineSlot_%s_%d" % ["Player" if is_player else "Opponent", slot_index + 1]


func _manual_board_slot_anchor(is_player: bool, slot_index: int) -> String:
	return "ManualBoardSlot_%s_%d" % ["Player" if is_player else "Opponent", slot_index + 1]


func _manual_hand_card_anchor(card_id: String, hand_index: int = -1) -> String:
	var base := "CombatCardPanel_Hand_%s" % _manual_anchor_token(card_id)
	return base if hand_index < 0 else "%s_%d" % [base, hand_index]


func _manual_unit_card_anchor(is_player: bool, instance_id: int) -> String:
	return "CombatCardPanel_%sUnit_%d" % ["Player" if is_player else "Opponent", instance_id]


func _manual_anchor_token(value: String) -> String:
	var token := ""
	for i in range(value.length()):
		var character := value.substr(i, 1)
		if (character >= "a" and character <= "z") or (character >= "A" and character <= "Z") or (character >= "0" and character <= "9") or character == "_":
			token += character
		else:
			token += "_"
	return token


func _add_manual_combat_lab(parent: Node, state: Dictionary) -> void:
	combat_ui_screen.add_manual_combat_lab(self, parent, state)


func _add_manual_action_bubble_layer(parent: Control) -> Control:
	return manual_combat_ui.add_action_bubble_layer(self, parent)


func _manual_action_bubble_layer() -> Control:
	if manual_action_bubble_layer != null and is_instance_valid(manual_action_bubble_layer) and not manual_action_bubble_layer.is_queued_for_deletion():
		return manual_action_bubble_layer
	var layer := _find_descendant_by_prefix(self, "ManualActionBubbleLayer")
	if layer != null and layer.is_queued_for_deletion():
		return null
	return layer as Control if layer is Control else null


func _add_ui_context_selection_actions(parent: Node, state: Dictionary) -> void:
	var selection := _manual_selection()
	if selection.is_empty():
		var hint := Label.new()
		hint.name = "ManualContextHint"
		hint.text = "Select a card or ready unit."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", Color("#9aa7b7"))
		parent.add_child(hint)
		return

	match String(selection.get("kind", "")):
		"card":
			if _manual_selected_can_target_face(state):
				var face_button := _make_button("Cast Face")
				face_button.name = "ManualContextFaceButton"
				_style_button(face_button, "target")
				_connect_pressed(face_button, _manual_target_face)
				parent.add_child(face_button)
			var hint := Label.new()
			hint.name = "ManualContextHint"
			hint.text = "Choose a highlighted target."
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_color_override("font_color", Color("#ffe08a"))
			parent.add_child(hint)
		"attacker":
			if _manual_selected_can_target_face(state):
				var attack_face := _make_button("Attack Face")
				attack_face.name = "ManualContextFaceButton"
				_style_button(attack_face, "target")
				_connect_pressed(attack_face, _manual_target_face)
				parent.add_child(attack_face)
			var hint := Label.new()
			hint.name = "ManualContextHint"
			hint.text = "Attack a highlighted unit or face."
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_color_override("font_color", Color("#ffe08a"))
			parent.add_child(hint)


func _add_manual_recent_events(parent: Node, state: Dictionary) -> void:
	manual_combat_vfx.add_recent_events(self, parent, state)


func _add_manual_action_animation(parent: Node) -> void:
	manual_combat_vfx.add_action_animation(self, parent)


func _add_manual_action_summary(parent: Node) -> void:
	manual_combat_vfx.add_action_summary(self, parent)


func _refresh_manual_board_arc_layer(layer: Node2D) -> void:
	manual_combat_vfx.refresh_board_arc_layer(self, layer)


func _add_manual_selection_preview_arcs(layer: Node2D, root: Node, state: Dictionary) -> void:
	manual_combat_vfx.add_selection_preview_arcs(self, layer, root, state)


func _add_manual_drag_preview_arc(layer: Node2D, root: Node, state: Dictionary) -> void:
	manual_combat_vfx.add_drag_preview_arc(self, layer, root, state)


func _add_manual_attack_drag_preview_arc(layer: Node2D, root: Node) -> void:
	manual_combat_vfx.add_attack_drag_preview_arc(self, layer, root)


func _add_manual_committed_board_arc(layer: Node2D, root: Node) -> void:
	manual_combat_vfx.add_committed_board_arc(self, layer, root)


func _manual_draw_board_arc(layer: Node2D, root: Node, source_anchor: String, target_anchor: String, line_name: String, arrow_name: String, color: Color, width: float, preview: bool, lifetime: float = 0.0, source_global_data: Variant = [], target_global_data: Variant = []) -> bool:
	return manual_combat_vfx.draw_board_arc(self, layer, root, source_anchor, target_anchor, line_name, arrow_name, color, width, preview, lifetime, source_global_data, target_global_data)


func _manual_animation_should_draw_target_arrow(animation: Dictionary, target_anchor: String, destination_anchor: String) -> bool:
	return manual_combat_vfx.animation_should_draw_target_arrow(animation, target_anchor, destination_anchor)


func _manual_visible_anchor_or_fallback(root: Node, anchor: String, fallback_anchor: String) -> String:
	return manual_combat_vfx.visible_anchor_or_fallback(root, anchor, fallback_anchor)


func _manual_ui_combat_vfx_fallback_anchor(animation: Dictionary) -> String:
	return manual_combat_vfx.ui_combat_vfx_fallback_anchor(animation)


func _manual_ui_combat_vfx_source_fallback_anchor(animation: Dictionary) -> String:
	return manual_combat_vfx.ui_combat_vfx_source_fallback_anchor(animation)


func _manual_schedule_animation_queue_advance(animation: Dictionary) -> void:
	if bool(animation.get("advance_scheduled", false)):
		return
	animation["advance_scheduled"] = true
	run.manual_animation = animation
	var timer := get_tree().create_timer(1.12)
	timer.timeout.connect(Callable(self, "_manual_advance_manual_animation_queue"))


func _manual_advance_manual_animation_queue() -> void:
	if run.is_empty():
		return
	var queue: Array = run.get("manual_animation_queue", [])
	if queue.is_empty():
		return
	_manual_apply_completed_opponent_play_animation(run.get("manual_animation", {}))
	run.manual_animation = queue[0]
	run.manual_animation_queue = queue.slice(1, queue.size()) if queue.size() > 1 else []
	if current_screen == "ui_combat":
		_show_active_combat_screen()


func _add_manual_board_card_travel(layer: Node2D, root: Node, animation: Dictionary, source_anchor: String, target_anchor: String, destination_anchor: String) -> bool:
	return manual_combat_vfx.add_board_card_travel(self, layer, root, animation, source_anchor, target_anchor, destination_anchor)


func _create_manual_board_action_ghost(animation: Dictionary) -> PanelContainer:
	return manual_combat_vfx.create_board_action_ghost(self, animation)


func _pulse_manual_anchor(root: Node, anchor: String, color: Color) -> void:
	manual_combat_vfx.pulse_anchor(self, root, anchor, color)


func _add_manual_board_impact_badges(layer: Node2D, root: Node, animation: Dictionary, target_anchor: String) -> void:
	manual_combat_vfx.add_board_impact_badges(self, layer, root, animation, target_anchor)


func _create_manual_board_impact_badge(badge: Dictionary) -> PanelContainer:
	return manual_combat_vfx.create_board_impact_badge(badge)


func _animate_manual_board_impact_badge(badge: Control) -> void:
	manual_combat_vfx.animate_board_impact_badge(self, badge)


func _manual_board_arc_control_point(source: Vector2, target: Vector2) -> Vector2:
	return manual_combat_vfx.board_arc_control_point(source, target)


func _manual_node_center_in_layer(layer: Node2D, node: Node) -> Vector2:
	return manual_combat_vfx.node_center_in_layer(layer, node)


func _manual_capture_anchor_global_point(anchor: String) -> Array:
	return manual_combat_vfx.capture_anchor_global_point(self, anchor)


func _manual_anchor_or_stored_point_in_layer(layer: Node2D, root: Node, anchor: String, global_data: Variant) -> Dictionary:
	return manual_combat_vfx.anchor_or_stored_point_in_layer(layer, root, anchor, global_data)


func _manual_global_point_from_data(global_data: Variant) -> Dictionary:
	return manual_combat_vfx.global_point_from_data(global_data)


func _manual_node_global_center(node: Node) -> Vector2:
	return manual_combat_vfx.node_global_center(node)


func _find_descendant_by_prefix(root: Node, target_prefix: String) -> Node:
	return manual_combat_vfx.find_descendant_by_prefix(root, target_prefix)


func _add_manual_target_arc(parent: Node, animation: Dictionary) -> void:
	manual_combat_vfx.add_target_arc(self, parent, animation)


func _manual_arc_color(verb: String) -> Color:
	return manual_combat_vfx.arc_color(verb)


func _add_manual_arc_marker(parent: Node, node_name: String, position: Vector2, short_text: String, tooltip: String, color: Color) -> void:
	manual_combat_vfx.add_arc_marker(parent, node_name, position, short_text, tooltip, color)


func _create_manual_animation_ghost(animation: Dictionary) -> PanelContainer:
	return manual_combat_vfx.create_animation_ghost(self, animation)


func _animate_manual_ghost(ghost: Control) -> void:
	manual_combat_vfx.animate_ghost(self, ghost)


func _add_manual_impact_badge(parent: Node, badge: Dictionary) -> void:
	manual_combat_vfx.add_impact_badge(self, parent, badge)


func _manual_impact_badge_colors(kind: String) -> Dictionary:
	return manual_combat_vfx.impact_badge_colors(kind)


func _animate_manual_impact_badge(badge: Control) -> void:
	manual_combat_vfx.animate_impact_badge(self, badge)


func _add_manual_battlefield(parent: Node) -> Control:
	return manual_combat_ui.add_battlefield(self, parent)


func _add_manual_inspect_panel(parent: Node, state: Dictionary) -> void:
	var compact_duel := current_screen == "ui_combat"
	if compact_duel:
		var stored_inspect: Dictionary = run.get("manual_inspect", {})
		var stored_card := String(stored_inspect.get("card_id", ""))
		if not bool(stored_inspect.get("pinned", false)) or not cards_by_id.has(stored_card):
			return

	var inspect := PanelContainer.new()
	inspect.name = "ManualInspectPanelOverlay" if compact_duel else "ManualInspectPanel"
	inspect.set_meta("ui_combat_overlay", compact_duel)
	inspect.custom_minimum_size = Vector2(224 if compact_duel else 310, 0)
	inspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect.mouse_filter = Control.MOUSE_FILTER_PASS
	if compact_duel:
		inspect.z_index = 180
		inspect.anchor_left = 0.0
		inspect.anchor_top = 0.0
		inspect.anchor_right = 0.0
		inspect.anchor_bottom = 1.0
		inspect.offset_left = 14.0
		inspect.offset_top = 10.0
		inspect.offset_right = 232.0
		inspect.offset_bottom = -10.0
	var style := StyleBoxFlat.new()
	var inspect_bg := Color("#101722")
	var inspect_border := Color("#52617a")
	if compact_duel:
		inspect_bg.a = 0.84
		inspect_border.a = 0.72
	style.bg_color = inspect_bg
	style.border_color = inspect_border
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	inspect.add_theme_stylebox_override("panel", style)
	parent.add_child(inspect)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_right", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_top", 9 if compact_duel else 10)
	margin.add_theme_constant_override("margin_bottom", 9 if compact_duel else 10)
	inspect.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7 if compact_duel else 8)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = "CARD INSPECT"
	heading.add_theme_font_size_override("font_size", 14 if compact_duel else 18)
	heading.add_theme_color_override("font_color", Color("#f3efe4"))
	box.add_child(heading)

	manual_inspect_art_panel = PanelContainer.new()
	manual_inspect_art_panel.name = "ManualInspectArt"
	manual_inspect_art_panel.custom_minimum_size = Vector2(0, 100 if compact_duel else 168)
	box.add_child(manual_inspect_art_panel)

	var art_margin := MarginContainer.new()
	art_margin.add_theme_constant_override("margin_left", 10)
	art_margin.add_theme_constant_override("margin_right", 10)
	art_margin.add_theme_constant_override("margin_top", 10)
	art_margin.add_theme_constant_override("margin_bottom", 10)
	manual_inspect_art_panel.add_child(art_margin)

	var art_label := Label.new()
	art_label.name = "ManualInspectArtLabel"
	art_label.text = "PLACEHOLDER ART"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_color_override("font_color", Color("#f3efe4"))
	art_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_margin.add_child(art_label)

	manual_inspect_name_label = Label.new()
	manual_inspect_name_label.name = "ManualInspectName"
	manual_inspect_name_label.add_theme_font_size_override("font_size", 16 if compact_duel else 20)
	manual_inspect_name_label.add_theme_color_override("font_color", Color("#f3efe4"))
	manual_inspect_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_name_label)

	manual_inspect_type_panel = PanelContainer.new()
	manual_inspect_type_panel.name = "ManualInspectTypeStrip"
	manual_inspect_type_panel.custom_minimum_size = Vector2(0, 18 if compact_duel else 24)
	box.add_child(manual_inspect_type_panel)

	var type_margin := MarginContainer.new()
	type_margin.add_theme_constant_override("margin_left", 6)
	type_margin.add_theme_constant_override("margin_right", 6)
	type_margin.add_theme_constant_override("margin_top", 1)
	type_margin.add_theme_constant_override("margin_bottom", 1)
	manual_inspect_type_panel.add_child(type_margin)

	manual_inspect_type_label = Label.new()
	manual_inspect_type_label.name = "ManualInspectTypeLabel"
	manual_inspect_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_inspect_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	manual_inspect_type_label.clip_text = true
	manual_inspect_type_label.add_theme_font_size_override("font_size", 9 if compact_duel else 12)
	type_margin.add_child(manual_inspect_type_label)

	manual_inspect_meta_label = Label.new()
	manual_inspect_meta_label.name = "ManualInspectMeta"
	manual_inspect_meta_label.add_theme_color_override("font_color", Color("#c7d0df"))
	manual_inspect_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_meta_label)

	manual_inspect_stats_label = Label.new()
	manual_inspect_stats_label.name = "ManualInspectStats"
	manual_inspect_stats_label.add_theme_font_size_override("font_size", 13 if compact_duel else 16)
	manual_inspect_stats_label.add_theme_color_override("font_color", Color("#ffe08a"))
	manual_inspect_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_stats_label)

	manual_inspect_zone_label = Label.new()
	manual_inspect_zone_label.name = "ManualInspectZone"
	manual_inspect_zone_label.add_theme_color_override("font_color", Color("#a9c7ff"))
	manual_inspect_zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_zone_label)

	var rules_heading := Label.new()
	rules_heading.text = "EFFECT"
	rules_heading.add_theme_font_size_override("font_size", 12)
	rules_heading.add_theme_color_override("font_color", Color("#9ee66e"))
	box.add_child(rules_heading)

	manual_inspect_effect_label = Label.new()
	manual_inspect_effect_label.name = "ManualInspectEffect"
	manual_inspect_effect_label.add_theme_color_override("font_color", Color("#d8dfec"))
	manual_inspect_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_effect_label)

	var text_heading := Label.new()
	text_heading.text = "TEXT"
	text_heading.add_theme_font_size_override("font_size", 12)
	text_heading.add_theme_color_override("font_color", Color("#9ee66e"))
	box.add_child(text_heading)

	manual_inspect_text_label = Label.new()
	manual_inspect_text_label.name = "ManualInspectText"
	manual_inspect_text_label.add_theme_color_override("font_color", Color("#c7d0df"))
	manual_inspect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(manual_inspect_text_label)

	var inspect_data := _manual_inspect_data_for_state(state)
	if cards_by_id.has(String(inspect_data.get("card_id", ""))):
		_manual_set_inspect_card(
			String(inspect_data.get("card_id", "")),
			String(inspect_data.get("zone", "Inspect")),
			String(inspect_data.get("current", "")),
			true
		)
	else:
		_refresh_manual_inspect_panel()


func _manual_inspect_data_for_state(state: Dictionary) -> Dictionary:
	var stored: Dictionary = run.get("manual_inspect", {})
	var stored_card := String(stored.get("card_id", ""))
	if cards_by_id.has(stored_card):
		return stored

	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			var selected_card := String(selection.get("card_id", ""))
			if cards_by_id.has(selected_card):
				return { "card_id": selected_card, "zone": "Hand", "current": "" }
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			if not attacker.is_empty():
				return {
					"card_id": String(attacker.get("card_id", "")),
					"zone": "Your Board",
					"current": _manual_current_unit_summary(attacker)
				}

	if current_screen == "ui_combat":
		return { "card_id": "", "zone": "Inspect", "current": "" }

	var player: Dictionary = state.get("player", {})
	for card_id in player.get("hand", []):
		if cards_by_id.has(String(card_id)):
			return { "card_id": String(card_id), "zone": "Hand", "current": "" }
	for unit in player.get("board", []):
		if cards_by_id.has(String(unit.get("card_id", ""))):
			return {
				"card_id": String(unit.get("card_id", "")),
				"zone": "Your Board",
				"current": _manual_current_unit_summary(unit)
			}

	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		if cards_by_id.has(String(unit.get("card_id", ""))):
			return {
				"card_id": String(unit.get("card_id", "")),
				"zone": "Opponent Board",
				"current": _manual_current_unit_summary(unit)
			}

	return { "card_id": "", "zone": "Inspect", "current": "" }


func _manual_set_inspect_card(card_id: String, zone: String, current_summary: String = "", pinned: bool = true) -> void:
	if run.is_empty():
		return
	if not cards_by_id.has(card_id):
		run.manual_inspect = {}
		_refresh_manual_inspect_panel()
		return
	run.manual_inspect = {
		"card_id": card_id,
		"zone": zone,
		"current": current_summary,
		"pinned": pinned
	}
	_refresh_manual_inspect_panel()


func _manual_clear_hover_inspect(card_id: String, zone: String, current_summary: String = "") -> void:
	if run.is_empty():
		return
	var inspect_data: Dictionary = run.get("manual_inspect", {})
	if bool(inspect_data.get("pinned", false)):
		return
	if String(inspect_data.get("card_id", "")) != card_id:
		return
	if String(inspect_data.get("zone", "")) != zone:
		return
	if String(inspect_data.get("current", "")) != current_summary:
		return
	run.manual_inspect = {}
	_refresh_manual_inspect_panel()


func _refresh_manual_inspect_panel() -> void:
	if manual_inspect_name_label == null or not is_instance_valid(manual_inspect_name_label):
		return
	var inspect_data: Dictionary = run.get("manual_inspect", {})
	var card_id := String(inspect_data.get("card_id", ""))
	if not cards_by_id.has(card_id):
		manual_inspect_name_label.text = "Inspect"
		if manual_inspect_type_panel != null and is_instance_valid(manual_inspect_type_panel):
			manual_inspect_type_panel.visible = false
		if manual_inspect_type_label != null and is_instance_valid(manual_inspect_type_label):
			manual_inspect_type_label.text = ""
		manual_inspect_meta_label.text = "Hover for a quick look. Click a card to pin it."
		manual_inspect_stats_label.text = ""
		manual_inspect_zone_label.text = ""
		manual_inspect_effect_label.text = ""
		manual_inspect_text_label.text = ""
		_set_manual_inspect_art_color(Color("#1f2732"))
		return

	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = card.get("combat", {})
	var kind := String(combat.get("kind", _combat_card_type(card))).capitalize()
	manual_inspect_name_label.text = String(card.get("name", card_id))
	if manual_inspect_type_panel != null and is_instance_valid(manual_inspect_type_panel):
		manual_inspect_type_panel.visible = true
		_style_card_type_strip(manual_inspect_type_panel, _card_animal_type(card), current_screen == "ui_combat")
	if manual_inspect_type_label != null and is_instance_valid(manual_inspect_type_label):
		manual_inspect_type_label.text = _combat_card_type_line(card)
		manual_inspect_type_label.add_theme_color_override("font_color", _affinity_color(_card_animal_type(card)).lightened(0.68))
	manual_inspect_meta_label.text = "%s | %s | Cost %d" % [
		String(card.get("rarity", "common")).capitalize(),
		kind,
		int(card.get("cost", 0))
	]
	manual_inspect_stats_label.text = _manual_inspect_stats(card, String(inspect_data.get("current", "")))
	manual_inspect_zone_label.text = "Zone: " + String(inspect_data.get("zone", "Inspect"))
	manual_inspect_effect_label.text = _combat_effect_summary(card)
	manual_inspect_text_label.text = String(card.get("text", ""))
	_set_manual_inspect_art_color(_combat_placeholder_color(card_id))


func _manual_inspect_stats(card: Dictionary, current_summary: String) -> String:
	if current_summary != "":
		return current_summary
	var combat: Dictionary = card.get("combat", {})
	match String(combat.get("kind", "")):
		"unit":
			return "Base %d/%d%s" % [
				int(combat.get("attack", 0)),
				int(combat.get("health", 0)),
				" | " + ", ".join(PackedStringArray(combat.get("keywords", []))) if not combat.get("keywords", []).is_empty() else ""
			]
		"action":
			return _manual_target_mode_label(card)
		"engine":
			return "Engine"
		_:
			return String(card.get("role", "Card")).capitalize()


func _manual_current_unit_summary(unit: Dictionary) -> String:
	return "Current %d/%d%s" % [
		int(unit.get("attack", 0)),
		int(unit.get("health", 0)),
		" | Ready" if bool(unit.get("ready", false)) else ""
	]


func _set_manual_inspect_art_color(color: Color) -> void:
	if manual_inspect_art_panel == null or not is_instance_valid(manual_inspect_art_panel):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.25)
	style.border_color = color.lightened(0.25)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	manual_inspect_art_panel.add_theme_stylebox_override("panel", style)


func _add_manual_feedback_chip(parent: Node, line: String) -> void:
	manual_combat_vfx.add_feedback_chip(self, parent, line)


func _manual_feedback_data(line: String) -> Dictionary:
	return manual_combat_vfx.feedback_data(line)


func _manual_log_line_color(line: String) -> Color:
	return manual_combat_vfx.log_line_color(line)


func _add_manual_combatant_panel(parent: Node, label: String, combatant: Dictionary, is_player: bool, state: Dictionary) -> void:
	var panel := _add_panel(parent, label, "#1f3140" if is_player else "#34232d")
	panel.name = "ManualPlayerPanel" if is_player else "ManualOpponentPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if current_screen == "ui_combat" else Control.SIZE_SHRINK_BEGIN
	if combatant.is_empty():
		_add_body_text(panel, "No combatant data.")
		return

	_add_body_text(panel, "Life %d | Focus %d/%d%s | Deck %d | Hand %d | Discard %d | Fatigue %d" % [
		int(combatant.get("life", 0)),
		int(combatant.get("focus", 0)),
		int(combatant.get("max_focus", 0)),
		_manual_restricted_focus_text(combatant),
		combatant.get("deck", []).size(),
		combatant.get("hand", []).size(),
		combatant.get("discard", []).size(),
		int(combatant.get("fatigue", 0))
	])

	if current_screen == "ui_combat":
		if is_player:
			_add_manual_board(panel, combatant.get("board", []), is_player, state)
			_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
			_add_manual_hand(panel, combatant, state)
		else:
			_add_manual_hidden_hand_zone(panel, combatant.get("hand", []).size())
			_add_manual_face_target(panel, state)
			_add_manual_board(panel, combatant.get("board", []), is_player, state)
			_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
		return

	if not is_player:
		_add_manual_face_target(panel, state)

	_add_manual_board(panel, combatant.get("board", []), is_player, state)

	_add_manual_engine_zone(panel, combatant.get("engines", []), is_player)
	if is_player:
		_add_manual_hand(panel, combatant, state)
	else:
		_add_manual_hidden_hand_zone(panel, combatant.get("hand", []).size())
	_add_manual_summary_zone(
		panel,
		"Discard Zone",
		_summarize_card_ids(combatant.get("discard", [])).slice(0, 8),
		"PlayerDiscard" if is_player else "OpponentDiscard",
		0,
		"#211d24"
	)


func _add_manual_zone(parent: Node, title: String, zone_name: String, accent: String) -> VBoxContainer:
	return manual_combat_ui.add_zone(self, parent, title, zone_name, accent)


func _ui_combat_zone_height(zone_name: String) -> float:
	return manual_combat_ui.ui_combat_zone_height(zone_name)


func _add_manual_summary_zone(parent: Node, title: String, entries: Array, zone_name: String, slot_count: int, accent: String) -> void:
	var zone := _add_manual_zone(parent, title, zone_name, accent)
	var columns: int = max(1, slot_count if slot_count > 0 else min(4, max(1, entries.size())))
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)

	for entry in entries:
		var card_id := String(entry.get("card_id", ""))
		var summary := "%s x%d" % [
			String(entry.get("name", "Unknown")),
			int(entry.get("count", 1))
		]
		if entry.has("cost"):
			summary += " | cost %d" % int(entry.get("cost", 0))
		_add_manual_zone_item(grid, summary, card_id, title)

	if entries.is_empty() and slot_count <= 0:
		_add_manual_empty_zone_slot(grid, "No Cards")
		return

	for i in range(max(0, slot_count - entries.size())):
		_add_manual_empty_zone_slot(grid, "Open Slot")


func _add_manual_engine_zone(parent: Node, engines: Array, is_player: bool) -> void:
	var zone_name := "PlayerEngine" if is_player else "OpponentEngine"
	var zone := _add_manual_zone(parent, "Engine Zone", zone_name, "#18232d")
	var grid := GridContainer.new()
	grid.columns = COMBAT_ENGINE_SLOTS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)

	var slotted_engines := _manual_engines_by_slot(engines)
	for slot_index in range(COMBAT_ENGINE_SLOTS):
		var slot := _add_manual_engine_slot(grid, is_player, slot_index)
		var engine: Dictionary = slotted_engines[slot_index]
		if engine.is_empty():
			_add_manual_empty_zone_slot(slot, "Open Slot")
			continue

		var card_id := String(engine.get("card_id", ""))
		var summary := "Unknown Engine"
		if cards_by_id.has(card_id):
			var card: Dictionary = cards_by_id[card_id]
			summary = String(card.get("name", card_id))
			if card.has("cost"):
				summary += " | cost %d" % int(card.get("cost", 0))
		_add_manual_zone_item(slot, summary, card_id, "Engine Zone")


func _add_manual_engine_slot(parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	return manual_combat_ui.add_engine_slot(self, parent, is_player, slot_index)


func _add_manual_hidden_hand_zone(parent: Node, hand_count: int) -> void:
	var zone := _add_manual_zone(parent, "Hand Zone", "OpponentHand", "#261f32")
	var grid := GridContainer.new()
	grid.columns = max(1, min(5, hand_count))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 6)
	grid.add_theme_constant_override("v_separation", 4 if current_screen == "ui_combat" else 6)
	zone.add_child(grid)
	for i in range(hand_count):
		_add_manual_card_back_slot(grid, "Hidden Card")
	if hand_count <= 0:
		_add_manual_empty_zone_slot(grid, "Empty Hand")


func _add_manual_zone_item(parent: Node, text: String, card_id: String = "", zone_label: String = "") -> void:
	var compact_duel := current_screen == "ui_combat"
	var item := PanelContainer.new()
	item.name = "ManualZoneItem"
	item.custom_minimum_size = Vector2(96, 24) if compact_duel else Vector2(132, 44)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = _combat_placeholder_color(card_id).darkened(0.2) if cards_by_id.has(card_id) else Color("#252d38")
	style.border_color = Color("#465060")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	item.add_theme_stylebox_override("panel", style)
	parent.add_child(item)
	if card_id != "":
		_apply_combat_card_motion(item, card_id, zone_label, "")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_right", 4 if compact_duel else 6)
	margin.add_theme_constant_override("margin_top", 3 if compact_duel else 5)
	margin.add_theme_constant_override("margin_bottom", 3 if compact_duel else 5)
	item.add_child(margin)

	var label := Label.new()
	label.text = text
	if compact_duel:
		label.add_theme_font_size_override("font_size", 8)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#d8dfec"))
	margin.add_child(label)


func _add_manual_empty_zone_slot(parent: Node, text: String) -> void:
	manual_combat_ui.add_empty_zone_slot(self, parent, text)


func _add_manual_card_back_slot(parent: Node, text: String) -> void:
	manual_combat_ui.add_card_back_slot(self, parent, text)


func _add_manual_board_slot(parent: Node, is_player: bool, slot_index: int) -> VBoxContainer:
	return manual_combat_ui.add_board_slot(self, parent, is_player, slot_index)


func _add_manual_board(parent: VBoxContainer, units: Array, is_player: bool, state: Dictionary) -> void:
	var zone := _add_manual_zone(parent, "Board Zone", "PlayerBoard" if is_player else "OpponentBoard", "#1c2a24" if is_player else "#2b2026")

	var grid := GridContainer.new()
	grid.columns = COMBAT_BOARD_SLOTS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4 if current_screen == "ui_combat" else 8)
	grid.add_theme_constant_override("v_separation", 2 if current_screen == "ui_combat" else 8)
	zone.add_child(grid)

	var slotted_units := _manual_units_by_board_slot(units)
	for slot_index in range(COMBAT_BOARD_SLOTS):
		var slot := _add_manual_board_slot(grid, is_player, slot_index)
		var unit: Dictionary = slotted_units[slot_index]
		if unit.is_empty():
			_add_manual_empty_zone_slot(slot, "Open Board Slot")
			continue

		var border_color := Color("#465060")
		var border_width := 1
		var selected_attacker := is_player and _manual_selection_is_attacker(unit)
		var legal_target := not is_player and _manual_selected_can_target_unit(state, unit)
		if selected_attacker:
			border_color = Color("#ffe08a")
			border_width = 3
		elif legal_target:
			border_color = Color("#9ee66e")
			border_width = 4

		var card_box := _add_combat_placeholder_card(
			slot,
			String(unit.get("name", "Unknown")),
			"%d/%d%s" % [
				int(unit.get("attack", 0)),
				int(unit.get("health", 0)),
				" Ready" if bool(unit.get("ready", false)) else ""
			],
			_manual_unit_keyword_text(unit),
			_combat_placeholder_color(unit.get("card_id", "")),
			border_color,
			border_width,
				String(unit.get("card_id", "")),
				"Your Board" if is_player else "Opponent Board",
				_manual_current_unit_summary(unit),
				_manual_unit_card_anchor(is_player, int(unit.get("instance_id", -1))),
				_unit_card_type_line(unit),
				_unit_animal_type(unit),
				int(unit.get("max_health", unit.get("health", 0)))
			)
		var unit_card_panel := _manual_card_panel_from_contents(card_box)
		if unit_card_panel != null and selected_attacker and current_screen == "ui_combat":
			unit_card_panel.z_index = 120

		if current_screen != "ui_combat":
			if selected_attacker:
				_add_manual_card_badge(card_box, "ATTACKER SELECTED", Color("#ffe08a"))
			elif is_player and bool(unit.get("ready", false)):
				_add_manual_card_badge(card_box, "READY", Color("#a9c7ff"))
			elif legal_target:
				_add_manual_card_badge(card_box, "LEGAL TARGET", Color("#9ee66e"))

		if is_player and _manual_combat_accepts_input(state) and bool(unit.get("ready", false)):
			var instance_id := int(unit.get("instance_id", -1))
			if current_screen == "ui_combat":
				_add_manual_selected_unit_action_bubbles(card_box, unit, state)
			else:
				var attack_button := _make_button("Selected" if _manual_selection_is_attacker(unit) else "Select Attack")
				attack_button.name = "ManualAttackSelectButton"
				_style_button(attack_button, "selected" if _manual_selection_is_attacker(unit) else "action")
				_compact_manual_card_button(attack_button)
				if _manual_selection_is_attacker(unit):
					_connect_pressed(attack_button, _manual_clear_selection)
				else:
					_connect_pressed(attack_button, func() -> void: _manual_select_attacker(instance_id))
				card_box.add_child(attack_button)
		elif legal_target and current_screen != "ui_combat":
			var target_instance_id := int(unit.get("instance_id", -1))
			var target_button := _make_button("Target" if current_screen == "ui_combat" else _manual_target_action_label() + " Target")
			target_button.name = "ManualUnitTargetButton"
			_style_button(target_button, "target")
			_compact_manual_card_button(target_button)
			_connect_pressed(target_button, func() -> void: _manual_target_unit(target_instance_id))
			card_box.add_child(target_button)
		elif is_player and current_screen == "ui_combat" and _manual_combat_accepts_input(state):
			_add_manual_selected_unit_action_bubbles(card_box, unit, state)

		if is_player and _manual_combat_accepts_input(state):
			_add_manual_ability_buttons(card_box, unit, state)


func _add_manual_hand(parent: VBoxContainer, combatant: Dictionary, state: Dictionary) -> void:
	var zone := _add_manual_zone(parent, "Hand Zone", "PlayerHand", "#182537")
	if current_screen == "ui_combat":
		zone.custom_minimum_size = Vector2(0, _ui_combat_zone_height("PlayerHand"))
		zone.size_flags_vertical = Control.SIZE_SHRINK_END

	var hand: Array = combatant.get("hand", [])
	if hand.is_empty():
		_add_manual_empty_zone_slot(zone, "Empty Hand")
		return
	if current_screen == "ui_combat":
		_add_manual_fanned_hand(zone, hand, state)
		return

	var grid := GridContainer.new()
	grid.columns = min(5, max(1, hand.size()))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	zone.add_child(grid)

	for hand_index in range(hand.size()):
		var card_id := String(hand[hand_index])
		var card: Dictionary = cards_by_id[card_id]
		var selected := _manual_selection_is_card(card_id)
		var border_color := Color("#465060")
		var border_width := 1
		if selected:
			border_color = Color("#ffe08a")
			border_width = 3
		var card_box := _add_combat_placeholder_card(
			grid,
			String(card.get("name", card_id)),
			"Cost %d" % int(card.get("cost", 0)),
			_combat_effect_summary(card),
			_combat_placeholder_color(card_id),
			border_color,
			border_width,
			card_id,
			"Hand",
			"",
			_manual_hand_card_anchor(card_id, hand_index)
		)
		card_box.tooltip_text = card.get("text", "")
		if selected and current_screen != "ui_combat":
			_add_manual_card_badge(card_box, "SELECTED", Color("#ffe08a"))

		var selected_card_id := card_id
		var can_play := _manual_can_play_card(state, card_id)
		if current_screen == "ui_combat":
			if selected and can_play:
				if _manual_card_needs_target(card):
					_add_manual_action_bubble(card_box, "Target", _manual_show_target_hint)
				else:
					_add_manual_action_bubble(card_box, "Play", func() -> void: _manual_play_card(selected_card_id))
		else:
			if _manual_card_needs_target(card):
				var select_button := _make_button("Selected" if selected else "Select")
				select_button.name = "ManualCardSelectButton"
				_style_button(select_button, "selected" if selected else "action")
				_compact_manual_card_button(select_button)
				select_button.disabled = not can_play and not selected
				if selected:
					_connect_pressed(select_button, _manual_clear_selection)
				else:
					_connect_pressed(select_button, func() -> void: _manual_select_card(selected_card_id))
				card_box.add_child(select_button)
			else:
				var play_button := _make_button("Play")
				play_button.name = "ManualCardPlayButton"
				_style_button(play_button, "action")
				_compact_manual_card_button(play_button)
				play_button.disabled = not can_play
				_connect_pressed(play_button, func() -> void: _manual_play_card(selected_card_id))
				card_box.add_child(play_button)


func _add_manual_fanned_hand(parent: VBoxContainer, hand: Array, state: Dictionary) -> void:
	var fan := Control.new()
	fan.name = "ManualFanHand"
	fan.custom_minimum_size = Vector2(0, 216)
	fan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(fan)

	for hand_index in range(hand.size()):
		var card_id := String(hand[hand_index])
		var card: Dictionary = cards_by_id[card_id]
		var selected := _manual_selection_is_card(card_id)
		var border_color := Color("#465060")
		var border_width := 1
		if selected:
			border_color = Color("#ffe08a")
			border_width = 3
		var card_box := _add_combat_placeholder_card(
			fan,
			String(card.get("name", card_id)),
			"Cost %d" % int(card.get("cost", 0)),
			_combat_effect_summary(card),
			_combat_placeholder_color(card_id),
			border_color,
			border_width,
			card_id,
			"Hand",
			"",
			_manual_hand_card_anchor(card_id, hand_index)
		)
		var card_panel := _manual_card_panel_from_contents(card_box)
		if card_panel != null:
			card_panel.size = card_panel.custom_minimum_size
			card_panel.position = Vector2(16 + hand_index * 52, 12)
			card_panel.z_index = hand_index
			if selected:
				card_panel.z_index += 100
		card_box.tooltip_text = card.get("text", "")
		if selected and current_screen != "ui_combat":
			_add_manual_card_badge(card_box, "SELECTED", Color("#ffe08a"))

		var selected_card_id := card_id
		var can_play := _manual_can_play_card(state, card_id)
		if current_screen == "ui_combat":
			if selected and can_play:
				if _manual_card_needs_target(card):
					_add_manual_action_bubble(card_box, "Target", _manual_show_target_hint)
				else:
					_add_manual_action_bubble(card_box, "Play", func() -> void: _manual_play_card(selected_card_id))
		else:
			if _manual_card_needs_target(card):
				var select_button := _make_button("Selected" if selected else "Select")
				select_button.name = "ManualCardSelectButton"
				_style_button(select_button, "selected" if selected else "action")
				_compact_manual_card_button(select_button)
				select_button.disabled = not can_play and not selected
				if selected:
					_connect_pressed(select_button, _manual_clear_selection)
				else:
					_connect_pressed(select_button, func() -> void: _manual_select_card(selected_card_id))
				card_box.add_child(select_button)
			else:
				var play_button := _make_button("Play")
				play_button.name = "ManualCardPlayButton"
				_style_button(play_button, "action")
				_compact_manual_card_button(play_button)
				play_button.disabled = not can_play
				_connect_pressed(play_button, func() -> void: _manual_play_card(selected_card_id))
				card_box.add_child(play_button)

	call_deferred("_layout_manual_fanned_hand", fan)


func _layout_manual_fanned_hand(fan: Control) -> void:
	manual_combat_ui.layout_fanned_hand(self, fan)


func _manual_hand_card_id_from_panel(card_panel: Control) -> String:
	return manual_combat_ui.hand_card_id_from_panel(card_panel)


func _add_manual_action_bubble(card_box: Node, label: String, callback: Callable, stack_index: int = 0) -> void:
	manual_combat_ui.add_action_bubble(self, card_box, label, callback, stack_index)


func _manual_show_target_hint() -> void:
	_set_footer("Choose a highlighted target or drag the card onto one.")


func _manual_show_attack_target_hint() -> void:
	_set_footer("Double-click a highlighted target, double-click the opponent hand, or drag the attacker.")


func _position_manual_action_bubbles_for_card(card_panel: Control) -> void:
	manual_combat_ui.position_action_bubbles_for_card(self, card_panel)


func _position_manual_action_bubble(bubble: Button, card_panel: Control) -> void:
	manual_combat_ui.position_action_bubble(bubble, card_panel)


func _place_manual_action_bubble(bubble: Button, global_position: Vector2) -> void:
	manual_combat_ui.place_action_bubble(bubble, global_position)


func _style_manual_action_bubble(button: Button) -> void:
	manual_combat_ui.style_action_bubble(button)


func _manual_action_bubble_stylebox(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	return manual_combat_ui.action_bubble_stylebox(background, border, border_width)


func _manual_card_panel_from_contents(contents: Node) -> Control:
	return manual_combat_ui.card_panel_from_contents(contents)


func _manual_handle_hand_card_drag_input(event: InputEvent) -> bool:
	return manual_combat_input.handle_hand_card_drag_input(self, event)


func _manual_try_begin_hand_card_drag(card_id: String, source_panel: Control) -> bool:
	return manual_combat_input.try_begin_hand_card_drag(self, card_id, source_panel)


func _manual_try_begin_unit_attack_drag(source_panel: Control) -> bool:
	return manual_combat_input.try_begin_unit_attack_drag(self, source_panel)


func _manual_player_unit_instance_id_from_panel(source_panel: Control) -> int:
	return manual_combat_input.player_unit_instance_id_from_panel(source_panel)


func _manual_opponent_unit_instance_id_from_panel(source_panel: Control) -> int:
	return manual_combat_input.opponent_unit_instance_id_from_panel(source_panel)


func _manual_can_drag_attack_unit(instance_id: int) -> bool:
	return manual_combat_input.can_drag_attack_unit(self, instance_id)


func _manual_can_drag_hand_card(card_id: String) -> bool:
	return manual_combat_input.can_drag_hand_card(self, card_id)


func _manual_update_hand_card_drag(global_position: Vector2) -> void:
	manual_combat_input.update_hand_card_drag(self, global_position)


func _manual_start_hand_card_drag() -> void:
	manual_combat_input.start_hand_card_drag(self)


func _manual_finish_hand_card_drag(global_position: Vector2) -> void:
	manual_combat_input.finish_hand_card_drag(self, global_position)


func _manual_clear_hand_card_drag() -> void:
	manual_combat_input.clear_hand_card_drag(self)


func _manual_free_orphan_hand_drag_ghosts() -> void:
	manual_combat_input.free_orphan_hand_drag_ghosts(self)


func _manual_free_descendants_by_prefix(root: Node, target_prefix: String) -> void:
	manual_combat_input.free_descendants_by_prefix(self, root, target_prefix)


func _manual_snap_back_hand_drag_ghost(source_global: Vector2) -> void:
	manual_combat_input.snap_back_hand_drag_ghost(self, source_global)


func _manual_position_hand_drag_ghost(global_position: Vector2) -> void:
	manual_combat_input.position_hand_drag_ghost(self, global_position)


func _manual_set_hand_drag_visual_state(valid_drop: bool) -> void:
	manual_combat_input.set_hand_drag_visual_state(self, valid_drop)


func _manual_set_drag_board_highlight(active: bool) -> void:
	manual_combat_input.set_drag_board_highlight(self, active)


func _manual_refresh_drag_preview_layer() -> void:
	manual_combat_input.refresh_drag_preview_layer(self)


func _manual_hand_card_drag_drop_is_valid(card_id: String, global_position: Vector2) -> bool:
	return manual_combat_input.hand_card_drag_drop_is_valid(self, card_id, global_position)


func _manual_hand_card_drag_target(card_id: String, global_position: Vector2) -> Dictionary:
	return manual_combat_input.hand_card_drag_target(self, card_id, global_position)


func _manual_hand_card_drag_target_slot(global_position: Vector2) -> int:
	return manual_combat_input.hand_card_drag_target_slot(self, global_position)


func _manual_hand_card_drag_engine_target_slot(global_position: Vector2) -> int:
	return manual_combat_input.hand_card_drag_engine_target_slot(self, global_position)


func _manual_hand_card_drag_action_target(card_id: String, global_position: Vector2) -> Dictionary:
	return manual_combat_input.hand_card_drag_action_target(self, card_id, global_position)


func _manual_attack_drag_target(instance_id: int, global_position: Vector2) -> Dictionary:
	return manual_combat_input.attack_drag_target(self, instance_id, global_position)


func _manual_attack_drag_can_target_face(state: Dictionary, instance_id: int) -> bool:
	return manual_combat_input.attack_drag_can_target_face(self, state, instance_id)


func _manual_attack_drag_target_anchor(drop_target: Dictionary) -> String:
	return manual_combat_input.attack_drag_target_anchor(self, drop_target)


func _manual_global_point_hits_anchor(anchor: String, global_position: Vector2) -> bool:
	return manual_combat_input.global_point_hits_anchor(self, anchor, global_position)


func _manual_reset_drag_highlights() -> void:
	manual_combat_input.reset_drag_highlights(self)


func _manual_apply_drag_zone_highlight(card_id: String, valid_drop: bool, active: bool) -> void:
	manual_combat_input.apply_drag_zone_highlight(self, card_id, valid_drop, active)


func _manual_apply_attack_drag_highlight(instance_id: int, valid_drop: bool, active: bool) -> void:
	manual_combat_input.apply_attack_drag_highlight(self, instance_id, valid_drop, active)


func _manual_drag_footer_text(card_id: String) -> String:
	return manual_combat_input.drag_footer_text(self, card_id)


func _manual_attack_drag_footer_text(unit: Dictionary) -> String:
	return manual_combat_input.attack_drag_footer_text(self, unit)


func _create_manual_hand_drag_ghost(card_id: String) -> Control:
	return manual_combat_input.create_hand_drag_ghost(self, card_id)


func _create_manual_attack_drag_ghost(unit: Dictionary) -> Control:
	return manual_combat_input.create_attack_drag_ghost(self, unit)


func _add_manual_selected_unit_action_bubbles(card_box: VBoxContainer, unit: Dictionary, state: Dictionary) -> void:
	if current_screen != "ui_combat":
		return
	if not _manual_selection_is_attacker(unit):
		return
	var stack_index := 0
	var instance_id := int(unit.get("instance_id", -1))
	if bool(unit.get("ready", false)):
		_add_manual_action_bubble(card_box, "Attack", _manual_show_attack_target_hint, stack_index)
		stack_index += 1
	for ability_data in _manual_available_unit_abilities(state, unit):
		var ability_index := int(ability_data.get("index", -1))
		var label := "Use\nAbility"
		_add_manual_action_bubble(card_box, label, func() -> void: _manual_activate_unit_ability(instance_id, ability_index), stack_index)
		stack_index += 1


func _manual_available_unit_abilities(state: Dictionary, unit: Dictionary) -> Array:
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return []
	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = card.get("combat", {})
	var abilities: Array = combat.get("abilities", [])
	var available: Array = []
	for index in range(abilities.size()):
		var ability: Dictionary = abilities[index]
		if _manual_can_activate_ability(state, unit, ability, index):
			available.append({
				"index": index,
				"label": String(ability.get("label", "Use"))
			})
	return available


func _manual_unit_has_action_bubbles(state: Dictionary, unit: Dictionary) -> bool:
	if unit.is_empty() or not _manual_combat_accepts_input(state):
		return false
	return bool(unit.get("ready", false)) or not _manual_available_unit_abilities(state, unit).is_empty()


func _add_manual_ability_buttons(card_box: VBoxContainer, unit: Dictionary, state: Dictionary) -> void:
	if current_screen == "ui_combat":
		return
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return
	var card: Dictionary = cards_by_id[card_id]
	var combat: Dictionary = card.get("combat", {})
	var abilities: Array = combat.get("abilities", [])
	for index in range(abilities.size()):
		var ability: Dictionary = abilities[index]
		var instance_id := int(unit.get("instance_id", -1))
		var ability_index := index
		var label := String(ability.get("label", "Ability"))
		var cost := int(ability.get("cost", 0))
		var button := _make_button("Use [%d]" % cost if current_screen == "ui_combat" else "%s [%d]" % [label, cost])
		button.name = "ManualAbilityButton"
		_style_button(button, "action")
		_compact_manual_card_button(button)
		button.disabled = not _manual_can_activate_ability(state, unit, ability, index)
		_connect_pressed(button, func() -> void: _manual_activate_unit_ability(instance_id, ability_index))
		card_box.add_child(button)


func _add_manual_card_badge(parent: Node, text: String, color: Color) -> void:
	manual_combat_ui.add_card_badge(self, parent, text, color)


func _add_combat_placeholder_card(parent: Node, title: String, subtitle: String, body: String, accent: Color, border_color: Color = Color("#465060"), border_width: int = 1, inspect_card_id: String = "", inspect_zone: String = "", inspect_current: String = "", node_anchor: String = "", printed_type: String = "", printed_animal_type: String = "", printed_max_health: int = -1) -> VBoxContainer:
	var compact_duel := current_screen == "ui_combat"
	var type_text := printed_type
	var animal_type := printed_animal_type if printed_animal_type != "" else "neutral"
	if inspect_card_id != "" and cards_by_id.has(inspect_card_id):
		var inspect_card: Dictionary = cards_by_id[inspect_card_id]
		type_text = _combat_card_type_line(inspect_card) if type_text == "" else type_text
		animal_type = _card_animal_type(inspect_card) if printed_animal_type == "" else printed_animal_type
	elif type_text == "":
		animal_type = "neutral"

	var frame_data := _card_frame_data(inspect_card_id, {
		"title": title,
		"type_line": type_text,
		"animal_color": _affinity_color(animal_type),
		"frame_color": accent,
		"border_color": border_color,
		"border_width": border_width,
		"combat_stats": inspect_current if inspect_current != "" else subtitle,
		"effect_text": _combat_effect_summary(cards_by_id[inspect_card_id]) if inspect_card_id != "" and cards_by_id.has(inspect_card_id) else body,
		"rules_text": String(cards_by_id[inspect_card_id].get("text", "")) if inspect_card_id != "" and cards_by_id.has(inspect_card_id) else body,
		"art_text": "",
		"area_text": ""
	})
	var current_stats := _attack_health_from_text(inspect_current if inspect_current != "" else subtitle)
	if not current_stats.is_empty():
		frame_data.attack = int(current_stats.attack)
		frame_data.health = int(current_stats.health)
		frame_data.max_health = printed_max_health if printed_max_health >= 0 else int(current_stats.health)
		frame_data.show_attack_health = true

	var box: VBoxContainer = card_frame_factory.add_frame(
		parent,
		frame_data,
		{
			"panel_name": node_anchor if node_anchor != "" else "CombatCardPanel",
			"contents_name": "CombatCardContents",
			"name_prefix": "CombatCardFrame",
			"compact": compact_duel,
			"min_size": Vector2(96, 164) if compact_duel else Vector2(176, 236),
			"size_flags_horizontal": Control.SIZE_SHRINK_CENTER if compact_duel else Control.SIZE_EXPAND_FILL,
			"border_color": border_color,
			"border_width": border_width,
			"show_deck_stats": false,
			"show_rules_text": not compact_duel
		}
	)
	var panel := _manual_card_panel_from_contents(box)
	if panel != null:
		_apply_combat_card_motion(panel, inspect_card_id, inspect_zone, inspect_current)
	return box


func _attack_health_from_text(text: String) -> Dictionary:
	var slash_index := text.find("/")
	if slash_index < 0:
		return {}

	var attack_start := slash_index - 1
	while attack_start >= 0 and _is_digit(text.substr(attack_start, 1)):
		attack_start -= 1
	attack_start += 1

	var health_end := slash_index + 1
	while health_end < text.length() and _is_digit(text.substr(health_end, 1)):
		health_end += 1

	if attack_start >= slash_index or health_end <= slash_index + 1:
		return {}

	return {
		"attack": int(text.substr(attack_start, slash_index - attack_start)),
		"health": int(text.substr(slash_index + 1, health_end - slash_index - 1))
	}


func _is_digit(character: String) -> bool:
	return character >= "0" and character <= "9"


func _apply_combat_card_motion(card_panel: Control, inspect_card_id: String = "", inspect_zone: String = "", inspect_current: String = "") -> void:
	manual_combat_input.apply_combat_card_motion(self, card_panel, inspect_card_id, inspect_zone, inspect_current)


func _manual_handle_card_double_click(card_panel: Control, inspect_zone: String) -> bool:
	return manual_combat_input.handle_card_double_click(self, card_panel, inspect_zone)


func _tween_control_feedback(control: Control, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	manual_combat_input.tween_control_feedback(self, control, target_scale, target_modulate, duration)


func _add_manual_face_target(parent: VBoxContainer, state: Dictionary) -> void:
	if not _manual_selection_can_try_face(state):
		return

	var selected_can_face := _manual_selected_can_target_face(state)
	var target_panel := PanelContainer.new()
	target_panel.name = "ManualFaceTargetAffordance"
	target_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#203421") if selected_can_face else Color("#372323")
	style.border_color = Color("#9ee66e") if selected_can_face else Color("#d8a0a0")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	target_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(target_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	target_panel.add_child(margin)

	var face_row := HBoxContainer.new()
	face_row.add_theme_constant_override("separation", 6)
	margin.add_child(face_row)

	var face_label := Label.new()
	face_label.text = "OPPONENT FACE"
	face_label.add_theme_color_override("font_color", Color("#9ee66e") if selected_can_face else Color("#d8a0a0"))
	face_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	face_row.add_child(face_label)

	var face_button := _make_button(_manual_target_action_label() + " Face")
	face_button.name = "ManualFaceTargetButton"
	_style_button(face_button, "target" if selected_can_face else "danger")
	face_button.disabled = not selected_can_face
	if not selected_can_face:
		face_button.tooltip_text = _manual_face_block_reason(state)
	_connect_pressed(face_button, _manual_target_face)
	face_row.add_child(face_button)


func _manual_target_action_label() -> String:
	match String(_manual_selection().get("kind", "")):
		"attacker":
			return "Attack"
		"card":
			return "Cast At"
		_:
			return "Target"


func _manual_selection() -> Dictionary:
	if run.is_empty():
		return {}
	if not run.has("manual_selection"):
		run.manual_selection = {}
	return run.manual_selection


func _manual_selection_label(state: Dictionary) -> String:
	if _manual_has_pending_action():
		var animation: Dictionary = run.get("manual_animation", {})
		if not animation.is_empty():
			return "Resolving %s..." % String(animation.get("card_name", "action"))
		return "Resolving action..."
	var selection := _manual_selection()
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			if cards_by_id.has(card_id):
				var card: Dictionary = cards_by_id[card_id]
				return "Selected card: %s | %s" % [card.get("name", card_id), _manual_target_mode_label(card)]
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			if not attacker.is_empty():
				return "Selected attacker: %s %d/%d" % [
					attacker.get("name", "Threat"),
					int(attacker.get("attack", 0)),
					int(attacker.get("health", 0))
				]
	return "Select a playable card or ready attacker."


func _manual_selection_is_card(card_id: String) -> bool:
	var selection := _manual_selection()
	return String(selection.get("kind", "")) == "card" and String(selection.get("card_id", "")) == card_id


func _manual_selection_is_attacker(unit: Dictionary) -> bool:
	var selection := _manual_selection()
	return String(selection.get("kind", "")) == "attacker" and int(selection.get("instance_id", -1)) == int(unit.get("instance_id", -2))


func _manual_selection_can_try_face(state: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_card_can_target_face(cards_by_id[card_id])
		"attacker":
			return not _manual_find_player_unit(state, int(selection.get("instance_id", -1))).is_empty()
	return false


func _manual_selected_can_target_face(state: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_can_play_card(state, card_id) and _manual_card_can_target_face(cards_by_id[card_id])
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			return not attacker.is_empty() and bool(attacker.get("ready", false)) and _manual_guard_unit(state).is_empty()
	return false


func _manual_selected_can_target_unit(state: Dictionary, unit: Dictionary) -> bool:
	var selection := _manual_selection()
	if selection.is_empty() or not _manual_combat_accepts_input(state):
		return false
	if unit.is_empty():
		return false
	match String(selection.get("kind", "")):
		"card":
			var card_id := String(selection.get("card_id", ""))
			return cards_by_id.has(card_id) and _manual_can_play_card(state, card_id) and _manual_card_can_target_units(cards_by_id[card_id])
		"attacker":
			var attacker := _manual_find_player_unit(state, int(selection.get("instance_id", -1)))
			return not attacker.is_empty() and bool(attacker.get("ready", false))
	return false


func _manual_find_player_unit(state: Dictionary, instance_id: int) -> Dictionary:
	var player: Dictionary = state.get("player", {})
	for unit in player.get("board", []):
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit
	return {}


func _manual_find_opponent_unit(state: Dictionary, instance_id: int) -> Dictionary:
	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		if int(unit.get("instance_id", -1)) == instance_id:
			return unit
	return {}


func _manual_face_block_reason(state: Dictionary) -> String:
	var guard_unit := _manual_guard_unit(state)
	if not guard_unit.is_empty():
		return "%s is blocking face attacks." % guard_unit.get("name", "A guard")
	return "Face is not a legal target for the current selection."


func _manual_target_mode_label(card: Dictionary) -> String:
	match _manual_action_target_mode(card):
		"none":
			return "No target"
		"enemy_player":
			return "Targets face"
		"enemy_unit":
			return "Targets units"
		"any_enemy":
			return "Targets face or units"
		_:
			return "Unknown target mode"


func _combat_placeholder_color(card_id: String) -> Color:
	if not cards_by_id.has(String(card_id)):
		return Color("#28313d")
	var card: Dictionary = cards_by_id[String(card_id)]
	var base := _affinity_color(_card_animal_type(card))
	match String(card.get("rarity", "common")):
		"uncommon":
			return base.darkened(0.42)
		"rare":
			return base.darkened(0.32)
		"mythic":
			return base.darkened(0.22)
		_:
			return base.darkened(0.55)


func _combat_effect_summary(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	if combat.is_empty():
		return String(card.get("text", ""))

	match String(combat.get("kind", "")):
		"unit":
			var keywords: Array = combat.get("keywords", [])
			var pieces: Array = []
			if not keywords.is_empty():
				var keyword_pieces: Array = []
				for keyword in keywords:
					keyword_pieces.append(String(keyword).capitalize())
				pieces.append(", ".join(PackedStringArray(keyword_pieces)))
			if not combat.get("onPlay", []).is_empty():
				pieces.append("On play: " + _effect_list_summary(combat.get("onPlay", [])))
			if not combat.get("triggers", []).is_empty():
				var trigger_pieces: Array = []
				for trigger in combat.get("triggers", []):
					trigger_pieces.append("%s: %s" % [
						String(trigger.get("timing", "trigger")).replace("_", " ").capitalize(),
						_effect_list_summary(trigger.get("effects", []))
					])
				pieces.append(" | ".join(PackedStringArray(trigger_pieces)))
			if not combat.get("abilities", []).is_empty():
				var ability_pieces: Array = []
				for ability in combat.get("abilities", []):
					ability_pieces.append("%s [%d]: %s" % [
						String(ability.get("label", "Ability")),
						int(ability.get("cost", 0)),
						_effect_list_summary(ability.get("effects", []))
					])
				pieces.append(" | ".join(PackedStringArray(ability_pieces)))
			return " | ".join(PackedStringArray(pieces))
		"action":
			return _effect_list_summary(combat.get("effects", []))
		"engine":
			var pieces: Array = []
			for trigger in combat.get("triggers", []):
				pieces.append("%s: %s" % [
					String(trigger.get("timing", "start")).replace("_", " ").capitalize(),
					_effect_list_summary(trigger.get("effects", []))
				])
			return " | ".join(PackedStringArray(pieces))
		_:
			return String(card.get("text", ""))


func _effect_list_summary(effects: Array) -> String:
	var pieces: Array = []
	for effect in effects:
		var amount := int(effect.get("amount", 1))
		var amount_text := _effect_amount_summary(effect, amount)
		match String(effect.get("type", "")):
			"damage":
				pieces.append("%s damage" % amount_text)
			"draw":
				pieces.append("Draw %s" % amount_text)
			"heal":
				pieces.append("Heal %s" % amount_text)
			"summon":
				pieces.append("Create %s %d/%d" % [
					String(effect.get("name", "Token")),
					int(effect.get("attack", 1)),
					int(effect.get("health", 1))
				])
			"buff":
				pieces.append("+%d/+%d" % [
					int(effect.get("amount_attack", effect.get("amount", 0))),
					int(effect.get("amount_health", effect.get("amount", 0)))
				])
			"debuff":
				pieces.append("-%d/-%d" % [
					int(effect.get("amount_attack", effect.get("amount", 0))),
					int(effect.get("amount_health", effect.get("amount", 0)))
				])
			"destroy":
				pieces.append("Destroy")
			"exhaust":
				pieces.append("Exhaust")
			"grant_keyword":
				pieces.append("Grant " + String(effect.get("keyword", "")))
			"discard":
				pieces.append("Discard %s" % amount_text)
			"recover":
				pieces.append("Recover %s" % amount_text)
			"gain_focus":
				var restriction := String(effect.get("restrictedTo", ""))
				if restriction == "":
					pieces.append("+%s focus" % amount_text)
				else:
					pieces.append("+%s %s focus" % [amount_text, _archetype_label(restriction)])
	return " | ".join(PackedStringArray(pieces))


func _effect_amount_summary(effect: Dictionary, fallback: int) -> String:
	match String(effect.get("amountSource", "")):
		"source_attack":
			return "source attack"
		"enemy_hand_size":
			return "enemy hand"
		"enemy_discard_size":
			return "enemy discard"
		"own_discard_size":
			return "discard"
		"current_focus":
			return "focus"
		"played_card_cost":
			return "played cost"
		"friendly_animal_type_count":
			return "your " + _affinity_label(String(effect.get("animalType", effect.get("conditionValue", ""))))
		"enemy_animal_type_count":
			return "enemy " + _affinity_label(String(effect.get("animalType", effect.get("conditionValue", ""))))
		_:
			return str(fallback)


func _manual_unit_keyword_text(unit: Dictionary) -> String:
	var pieces: Array = []
	if bool(unit.get("ready", false)):
		pieces.append("Ready")
	var tags: Array = unit.get("tags", [])
	if tags.has("guard") or tags.has("stabilizer"):
		pieces.append("Guard")
	if tags.has("fast"):
		pieces.append("Fast")
	if tags.has("token"):
		pieces.append("Token")
	return " | ".join(PackedStringArray(pieces))


func _manual_card_needs_target(card: Dictionary) -> bool:
	if _combat_card_type(card) != "action":
		return false
	return _manual_action_target_mode(card) != "none"


func _manual_card_can_target_face(card: Dictionary) -> bool:
	var mode := _manual_action_target_mode(card)
	return mode == "enemy_player" or mode == "any_enemy"


func _manual_card_can_target_units(card: Dictionary) -> bool:
	var mode := _manual_action_target_mode(card)
	return mode == "enemy_unit" or mode == "any_enemy"


func _manual_action_target_mode(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	if combat.has("targetMode"):
		return String(combat.get("targetMode", "none"))
	var role := String(card.get("role", "answer"))
	match role:
		"answer", "tech":
			return "any_enemy"
		"filter":
			return "none"
		_:
			return "enemy_player"


func _manual_guard_unit(state: Dictionary) -> Dictionary:
	var opponent: Dictionary = state.get("opponent", {})
	for unit in opponent.get("board", []):
		var tags: Array = unit.get("tags", [])
		if tags.has("guard") or tags.has("stabilizer"):
			return unit
	return {}


func _manual_combat_accepts_input(state: Dictionary) -> bool:
	return not _manual_has_pending_action() and not bool(state.get("game_over", false)) and String(state.get("phase", "")) == "player_main"


func _manual_can_play_card(state: Dictionary, card_id: String) -> bool:
	if not _manual_combat_accepts_input(state):
		return false
	var player: Dictionary = state.get("player", {})
	if not player.get("hand", []).has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	if int(card.get("cost", 0)) > _manual_available_focus_for_card(player, card):
		return false
	var combat_type := _combat_card_type(card)
	if combat_type == "threat" and player.get("board", []).size() >= 5:
		return false
	if combat_type == "engine" and player.get("engines", []).size() >= 3:
		return false
	if combat_type == "action" and _manual_action_target_mode(card) == "enemy_unit":
		var opponent: Dictionary = state.get("opponent", {})
		if opponent.get("board", []).is_empty():
			return false
	return true


func _manual_can_activate_ability(state: Dictionary, unit: Dictionary, ability: Dictionary, ability_index: int) -> bool:
	if not _manual_combat_accepts_input(state):
		return false
	var card_id := String(unit.get("card_id", ""))
	if not cards_by_id.has(card_id):
		return false
	var card: Dictionary = cards_by_id[card_id]
	var player: Dictionary = state.get("player", {})
	if bool(ability.get("requiresReady", false)) and not bool(unit.get("ready", false)):
		return false
	if bool(ability.get("oncePerTurn", false)):
		var used: Dictionary = unit.get("used_abilities", {})
		var key := "%s:%d" % [String(ability.get("id", "ability_%d" % ability_index)), int(player.get("turns_taken", 0))]
		if used.has(key):
			return false
	if int(ability.get("cost", 0)) > _manual_available_focus_for_card(player, card):
		return false
	return String(ability.get("targetMode", "none")) == "none"


func _manual_available_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	return int(combatant.get("focus", 0)) + _manual_restricted_focus_for_card(combatant, card)


func _manual_restricted_focus_for_card(combatant: Dictionary, card: Dictionary) -> int:
	var archetype := String(card.get("archetype", ""))
	if archetype == "" or archetype == "neutral":
		return 0
	var restricted: Dictionary = combatant.get("restricted_focus", {})
	return int(restricted.get(archetype, 0))


func _manual_restricted_focus_text(combatant: Dictionary) -> String:
	var restricted: Dictionary = combatant.get("restricted_focus", {})
	if restricted.is_empty():
		return ""
	var pieces: Array = []
	for archetype in restricted.keys():
		var amount := int(restricted[archetype])
		if amount <= 0:
			continue
		pieces.append("+%d %s" % [amount, _archetype_label(String(archetype))])
	if pieces.is_empty():
		return ""
	return " (%s)" % ", ".join(PackedStringArray(pieces))


func _combat_card_type(card: Dictionary) -> String:
	var combat: Dictionary = card.get("combat", {})
	match String(combat.get("kind", "")):
		"unit":
			return "threat"
		"action":
			return "action"
		"engine":
			return "engine"

	var role := String(card.get("role", "threat"))
	match role:
		"threat", "finisher":
			return "threat"
		"engine":
			return "engine"
		_:
			return "action"


func _summarize_combatant(combatant: Dictionary) -> Dictionary:
	return {
		"life": int(combatant.get("life", 0)),
		"focus": int(combatant.get("focus", 0)),
		"max_focus": int(combatant.get("max_focus", 0)),
		"restricted_focus": combatant.get("restricted_focus", {}),
		"deck_count": combatant.get("deck", []).size(),
		"discard_count": combatant.get("discard", []).size(),
		"fatigue": int(combatant.get("fatigue", 0)),
		"hand": _summarize_card_ids(combatant.get("hand", [])),
		"discard": _summarize_card_ids(combatant.get("discard", [])),
		"engines": _summarize_engines(combatant.get("engines", [])),
		"board": _summarize_units(combatant.get("board", []))
	}


func _summarize_card_ids(card_ids: Array) -> Array:
	var counts := {}
	for card_id in card_ids:
		counts[String(card_id)] = int(counts.get(String(card_id), 0)) + 1

	var summaries: Array = []
	for card_id in counts.keys():
		var card: Dictionary = cards_by_id[String(card_id)]
		summaries.append({
			"card_id": String(card_id),
			"name": card.get("name", card_id),
			"count": int(counts[card_id]),
			"rarity": card.get("rarity", "common"),
			"role": card.get("role", "threat"),
			"cost": int(card.get("cost", 0))
		})
	summaries.sort_custom(func(a, b) -> bool:
		if int(a["cost"]) != int(b["cost"]):
			return int(a["cost"]) < int(b["cost"])
		return String(a["name"]) < String(b["name"])
	)
	return summaries


func _summarize_engines(engines: Array) -> Array:
	var card_ids: Array = []
	for engine in engines:
		card_ids.append(String(engine.get("card_id", "")))
	return _summarize_card_ids(card_ids)


func _summarize_units(units: Array) -> Array:
	var summaries: Array = []
	for unit in units:
		summaries.append({
			"name": unit.get("name", "Unknown"),
			"card_id": unit.get("card_id", ""),
			"attack": int(unit.get("attack", 0)),
			"health": int(unit.get("health", 0)),
			"max_health": int(unit.get("max_health", 0)),
			"ready": bool(unit.get("ready", false))
		})
	summaries.sort_custom(func(a, b) -> bool:
		var power_a := int(a["attack"]) + int(a["health"])
		var power_b := int(b["attack"]) + int(b["health"])
		if power_a != power_b:
			return power_a > power_b
		return String(a["name"]) < String(b["name"])
	)
	return summaries


func _add_combatant_snapshot(parent: Node, label: String, snapshot: Dictionary) -> void:
	var panel := _add_panel(parent, label)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if snapshot.is_empty():
		_add_body_text(panel, "No combat snapshot yet.")
		return

	_add_body_text(panel, "Life %d | Focus %d/%d%s | Deck %d | Discard %d | Fatigue %d" % [
		int(snapshot.get("life", 0)),
		int(snapshot.get("focus", 0)),
		int(snapshot.get("max_focus", 0)),
		_manual_restricted_focus_text(snapshot),
		int(snapshot.get("deck_count", 0)),
		int(snapshot.get("discard_count", 0)),
		int(snapshot.get("fatigue", 0))
	])
	_add_combat_zone(panel, "Board", snapshot.get("board", []), true)
	_add_combat_zone(panel, "Engines", snapshot.get("engines", []), false)
	_add_combat_zone(panel, "Hand", snapshot.get("hand", []), false)
	_add_combat_zone(panel, "Discard Highlights", snapshot.get("discard", []).slice(0, 8), false)


func _add_combat_zone(parent: VBoxContainer, title: String, entries: Array, is_board: bool) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color", Color("#f3efe4"))
	parent.add_child(heading)

	if entries.is_empty():
		_add_body_text(parent, "None")
		return

	for entry in entries:
		if is_board:
			_add_body_text(parent, "%s %d/%d%s" % [
				String(entry.get("name", "Unknown")),
				int(entry.get("attack", 0)),
				int(entry.get("health", 0)),
				" ready" if bool(entry.get("ready", false)) else ""
			])
		else:
			_add_body_text(parent, "%s x%d | %s | cost %d" % [
				String(entry.get("name", "Unknown")),
				int(entry.get("count", 1)),
				String(entry.get("role", "card")).capitalize(),
				int(entry.get("cost", 0))
			])


func _show_tournament() -> void:
	if _guard_run_over():
		return
	current_screen = "tournament"
	_render_nav()
	_clear(content)
	_update_status()

	if _run_mode() == "season" and _season_tournament_active():
		_add_season_tournament_progress(content)
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
			String(difficulty.get("name", "White")),
			String(difficulty.get("rules_text", ""))
		])
	if _run_mode() == "season":
		_add_body_text(panel, "Season mode uses live UI Combat duels for each round.")
	else:
		_add_body_text(panel, "Debug mode auto-resolves the full event for quick testing.")
	_add_body_text(panel, "Entry fee: $%d | Current money: $%d" % [int(event.get("entryFee", 0)), int(run.get("money", 0))])
	_add_body_text(panel, "Deck status: " + ("Ready" if legal.ok else legal.reason))

	var enter := _make_button("Enter %s" % String(event.get("name", event_id)))
	enter.disabled = not legal.ok or int(run.get("money", 0)) < int(event.get("entryFee", 0)) or (_run_mode() == "season" and not _season_event_selectable(event_id))
	if _run_mode() == "season":
		_connect_pressed(enter, _start_season_tournament)
	else:
		_connect_pressed(enter, _run_tournament)
	panel.add_child(enter)

	if run.last_result.size() > 0:
		var last := _add_panel(content, "Last Tournament")
		for line in run.last_result:
			_add_body_text(last, line)


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
		String(difficulty.get("name", "White")),
		int(run.get("season_lives", 0)),
		int(run.get("max_season_lives", 0))
	])

	var current: Dictionary = run.get("manual_combat", {})
	if not current.is_empty() and not bool(current.get("game_over", false)):
		var current_button := _make_button("Return to Current Duel")
		_connect_pressed(current_button, _show_ui_combat)
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


func _start_season_tournament_round() -> void:
	if not _season_tournament_active():
		_show_tournament()
		return
	_manual_clear_hand_card_drag()
	var active: Dictionary = run.get("active_tournament", {})
	var round_number := int(active.get("round", 1))
	var event := _season_event_by_id(String(active.get("event_id", "weekly_locals")))
	var deck_metrics := _calculate_deck_metrics(run.deck, run.sideboard)
	var opponent := _generate_opponent(round_number, deck_metrics, event)
	var opponent_archetype := String(opponent.get("archetype", _predator_archetype(String(deck_metrics.primary))))
	var opponent_deck := _opponent_deck_for_round(opponent_archetype, round_number, event)
	var seed_value := rng.randi()
	var first_side := _season_round_first_side()

	run.manual_combat = combat_service.start_manual_game(run.deck, String(deck_metrics.primary), opponent_deck, opponent_archetype, seed_value, first_side)
	_reset_manual_runtime_state(false)

	active["current_opponent"] = opponent
	active["current_seed"] = seed_value
	active["current_first_side"] = first_side
	active["round_result_recorded"] = false
	run.active_tournament = active
	_set_footer("%s round %d started. %s Win the duel to add a match win to your record." % [
		String(active.get("event_name", "Tournament")),
		round_number,
		"You start." if first_side == "player" else "Opponent starts."
	])
	_show_ui_combat()


func _season_record_current_round_result() -> void:
	if not _season_tournament_active():
		return
	var state: Dictionary = run.get("manual_combat", {})
	if state.is_empty() or not bool(state.get("game_over", false)):
		_set_footer("Finish the current duel before recording the result.")
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

	if _season_tournament_should_finish(active):
		_finish_season_tournament()
		return

	active["round"] = round_number + 1
	active["current_opponent"] = {}
	active["current_seed"] = 0
	active["round_result_recorded"] = false
	run.active_tournament = active
	_reset_manual_runtime_state()
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
			run.run_over = true
			run_continues = false
			logs.append("Record: %d-%d. Win condition achieved: you won Worlds. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
		else:
			logs.append("Record: %d-%d. Calendar advanced. Prize: $%d and %d pack(s)." % [wins, losses, reward_money, reward_packs])
	else:
		lives_lost = 1
		run.season_lives = max(0, int(run.get("season_lives", 1)) - 1)
		if int(run.get("season_lives", 0)) > 0:
			run_continues = true
			run.week = int(run.week) + 1
			run.selected_event_id = event_id
			run.season_notice = "%s missed. You lost a season life, but the run is still alive. Tune your deck, then retry the same calendar event." % String(event.get("name", event_id))
			logs.append("Record: %d-%d. Required record missed. You lose a season life (%d/%d remaining) and continue with no prize." % [
				wins,
				losses,
				int(run.get("season_lives", 0)),
				int(run.get("max_season_lives", 0))
			])
		else:
			run.run_over = true
			run.season_notice = "%s missed. No season lives remain." % String(event.get("name", event_id))
			logs.append("Record: %d-%d. Required record missed and no season lives remain. The season ends here." % [wins, losses])

	_update_meta_after_event(String(active.get("deck_primary", _current_primary_archetype())), wins, max(1, wins + losses))
	_generate_shop_inventory()
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
	_reset_manual_runtime_state()
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
	var state: Dictionary = run.get("manual_combat", {})
	if state.is_empty():
		_show_tournament()
		return
	state["game_over"] = true
	state["winner"] = "opponent"
	state["phase"] = "game_over"
	var log_lines: Array = state.get("log", [])
	log_lines.append("You forfeited the round.")
	state["log"] = log_lines
	run.manual_combat = state
	run.manual_selection = {}
	run.manual_animation = {}
	run.manual_animation_queue = []
	run.manual_pending_action = {}
	run.manual_opponent_pending_state = {}
	_set_footer("Round forfeited. Record the result to continue.")
	_show_ui_combat()


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
	var panel_title := "Season Champion" if champion else "Tournament Result"
	var panel_accent := "#2c3a25" if champion else ("#253044" if survived and made_record else ("#3f3222" if survived else "#442525"))
	var panel := _add_panel(content, panel_title, panel_accent)
	if champion:
		_add_body_text(panel, "Win condition achieved: Worlds cleared. This run is complete.")
	_add_event_result_summary(panel)
	for line in logs:
		_add_body_text(panel, line)

	if champion:
		var restart_button := _make_button("Start New Season")
		_connect_pressed(restart_button, _show_start)
		panel.add_child(restart_button)
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
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	parent.add_child(actions)

	var summary: Dictionary = run.get("last_event_result", {})
	var made_record := bool(summary.get("made_record", true))
	if not made_record:
		var event_id := String(summary.get("event_id", _selected_season_event_id()))
		var event := _season_event_by_id(event_id)
		var retry_button := _make_button("Retry %s" % String(event.get("name", event_id)))
		retry_button.disabled = not _deck_is_legal().ok or int(run.get("money", 0)) < int(event.get("entryFee", 0))
		_style_button(retry_button, "action")
		_connect_pressed(retry_button, _show_tournament)
		actions.add_child(retry_button)

	var current_pack: Array = run.get("current_pack", [])
	if int(run.get("prize_packs", 0)) > 0 or not current_pack.is_empty():
		var pack_button := _make_button("Open Prize Packs (%d)" % int(run.get("prize_packs", 0)))
		_style_button(pack_button, "action")
		_connect_pressed(pack_button, _open_reward_pack_flow)
		actions.add_child(pack_button)

	var shop_button := _make_button("Visit Card Shop")
	_connect_pressed(shop_button, _show_shop)
	actions.add_child(shop_button)

	var calendar_button := _make_button("View Calendar")
	_connect_pressed(calendar_button, _show_season_run)
	actions.add_child(calendar_button)


func _open_reward_pack_flow() -> void:
	var current_pack: Array = run.get("current_pack", [])
	if not current_pack.is_empty():
		_show_packs()
		return
	if int(run.get("prize_packs", 0)) > 0:
		_open_prize_pack()
		return
	_show_packs()


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


func _generate_opponent(round_number: int, deck_metrics: Dictionary, event: Dictionary = {}) -> Dictionary:
	return tournament_service.generate_opponent(self, round_number, deck_metrics, event)


func _difficulty_opponent_quality_bonus() -> float:
	return tournament_service.difficulty_opponent_quality_bonus(self)


func _season_round_first_side() -> String:
	return tournament_service.season_round_first_side(self)


func _opponent_deck_for_round(opponent_archetype: String, round_number: int, event: Dictionary = {}) -> Dictionary:
	return tournament_service.opponent_deck_for_round(self, opponent_archetype, round_number, event)


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
		"flightless_birds":
			reports.append("Snake pilots are buying time and sweepers for the bird rush.")
		"snake":
			reports.append("Oxen players are trying to ramp past one-for-one answers.")
		"oxen":
			reports.append("Bird pilots are cutting clunky cards and trying to finish before the pasture turns on.")
		"glires":
			reports.append("Insect pilots are leaning on revive loops to outlast the warren.")
		"insect":
			reports.append("Bird pilots are cutting clunky cards and trying to finish before the hive turns on.")

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
	var compact_duel := current_screen == "ui_combat"
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

	var box := _add_panel(parent, card.name, accent)
	box.custom_minimum_size = Vector2(240, 0)

	var meta := "%s | %s | %s | cost %d | $%d" % [
		card.rarity.capitalize(),
		_affinity_label(_card_animal_type(card)),
		card.role.capitalize(),
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


func _card_animal_type(card: Dictionary) -> String:
	return String(card.get("animalType", card.get("archetype", "neutral")))


func _unit_animal_type(unit: Dictionary) -> String:
	var card_id := String(unit.get("card_id", ""))
	if cards_by_id.has(card_id):
		return _card_animal_type(cards_by_id[card_id])
	var tags: Array = unit.get("tags", [])
	for archetype_id in ARCHETYPE_ORDER:
		if tags.has(archetype_id):
			return String(archetype_id)
	return "neutral"


func _combat_card_type_line(card: Dictionary) -> String:
	var animal := _affinity_label(_card_animal_type(card))
	var printed_role := String(card.get("role", _combat_card_type(card))).capitalize()
	match String(card.get("role", "")):
		"threat":
			printed_role = "Threat"
		"answer":
			printed_role = "Answer"
		"filter":
			printed_role = "Filter"
		"engine":
			printed_role = "Engine"
		"finisher":
			printed_role = "Finisher"
		"tech":
			printed_role = "Tech"
	return "%s | %s" % [animal, printed_role]


func _unit_card_type_line(unit: Dictionary) -> String:
	var animal_type := _unit_animal_type(unit)
	return "%s | Threat" % _affinity_label(animal_type)


func _style_card_type_strip(panel: PanelContainer, animal_type: String, compact_duel: bool) -> void:
	var color := _affinity_color(animal_type)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#121a24")
	style.bg_color.a = 0.78 if compact_duel else 0.86
	style.border_color = color.lightened(0.35)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)


func _affinity_label(archetype_id: String) -> String:
	match archetype_id:
		"flightless_birds":
			return "Flightless Birds"
		"snake":
			return "Snake"
		"oxen":
			return "Oxen"
		"glires":
			return "Glires"
		"insect":
			return "Insect"
		"neutral":
			return "Universal"
		_:
			return _archetype_label(archetype_id)


func _affinity_color(archetype_id: String) -> Color:
	match archetype_id:
		"flightless_birds":
			return Color("#e45a3c")
		"snake":
			return Color("#4cc9b0")
		"oxen":
			return Color("#8f9b4a")
		"glires":
			return Color("#d8a74b")
		"insect":
			return Color("#9b7bd5")
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
	if current_screen == "ui_combat":
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


func _compact_manual_card_button(button: Button) -> void:
	if current_screen != "ui_combat":
		return
	button.custom_minimum_size = Vector2(0, 22)
	button.add_theme_font_size_override("font_size", 10)


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
		status_label.text = "Prototype"
		return
	var main_count := _deck_total(run.deck)
	var side_count := _deck_total(run.sideboard)
	var difficulty := _difficulty_data(_run_difficulty_id())
	var life_text := ""
	if _run_mode() == "season":
		life_text = " | Lives %d/%d" % [
			int(run.get("season_lives", 0)),
			int(run.get("max_season_lives", 0))
		]
	status_label.text = "Week %d | $%d | %s Border%s | Main %d/%d | Side %d/%d" % [
		int(run.week),
		int(run.money),
		String(difficulty.get("name", "White")),
		life_text,
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
	var result: Dictionary = run_state_service.save_run(run)
	_set_footer(result.message)


func _load_run_from_disk() -> void:
	_manual_clear_hand_card_drag()
	var result: Dictionary = run_state_service.load_run()
	if not result.ok:
		_set_footer(result.message)
		return
	run = result.run
	if not run.has("combat_lab_opponent"):
		var metrics := _calculate_deck_metrics(run.get("deck", {}), run.get("sideboard", {}))
		run.combat_lab_opponent = _predator_archetype(String(metrics.primary))
	_generate_shop_inventory()
	_set_footer(result.message)
	match _run_mode():
		"season":
			_show_season_run()
		"unselected":
			_show_run_path_choice()
		_:
			_show_shop()


func _migrate_legacy_run_archetypes() -> void:
	run_state_service.migrate_legacy_run_archetypes(run)
