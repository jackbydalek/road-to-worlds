extends RefCounted
class_name SeasonHubScreen

const SKETCH_UI := preload("res://scripts/ui/SketchUIComponents.gd")
const NEXUS_UI := preload("res://scripts/ui/NexusMenuComponents.gd")
const ICON_SHOP := preload("res://assets/ui/audacious/currency-circle-dollar-bold.svg")
const ICON_DECK := preload("res://assets/ui/audacious/folder.svg")
const ICON_EVENTS := preload("res://assets/ui/audacious/calendar-blank-bold.svg")
const ICON_TROPHY := preload("res://assets/ui/audacious/crown-simple-bold.svg")
const ICON_SETTINGS := preload("res://assets/ui/audacious/dots-three-vertical-bold.svg")


func show(host) -> void:
	if host._guard_run_over():
		return
	host.current_screen = "season"
	host._render_nav()
	host._clear(host.content)
	host._update_status()

	host._normalize_season_calendar_state()
	var event: Dictionary = host._selected_season_event()
	var event_id := String(event.get("id", host._selected_season_event_id()))
	var legal: Dictionary = host._deck_is_legal()
	var metrics: Dictionary = host._calculate_deck_metrics(host.run.get("deck", {}), host.run.get("sideboard", {}))
	var difficulty: Dictionary = host._difficulty_data(host._run_difficulty_id())
	var compact_layout: bool = float(host.get_viewport_rect().size.y) <= 760.0

	var hub := VBoxContainer.new()
	hub.name = "SeasonCalendarMap"
	hub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub.add_theme_constant_override("separation", 12)
	host.content.add_child(hub)

	_add_nexus_header(host, hub, event, metrics, legal, difficulty, compact_layout)

	var body := HBoxContainer.new()
	body.name = "SeasonHubNexusBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	hub.add_child(body)

	_add_nexus_menu(host, body, legal)
	_add_nexus_event_workspace(host, body, event, event_id, legal, compact_layout)


func _add_nexus_header(host, parent: Node, event: Dictionary, metrics: Dictionary, legal: Dictionary, difficulty: Dictionary, compact_layout: bool) -> void:
	var header := NEXUS_UI.make_header_panel(Vector2(0, 78 if compact_layout else 92))
	header.name = "SeasonHubHeader"
	parent.add_child(header)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	header.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", -1)
	row.add_child(copy)
	var eyebrow := NEXUS_UI.make_section_label("ROAD TO WORLDS  •  SEASON CIRCUIT", NEXUS_UI.TEAL_DARK, 15)
	copy.add_child(eyebrow)
	var title := NEXUS_UI.make_section_label("EVENT CALENDAR", NEXUS_UI.INK, 34)
	copy.add_child(title)
	var next := NEXUS_UI.make_body_label(
		"Next: %s  •  %d rounds  •  Win %d" % [
			String(event.get("name", "Weekly Locals")),
			int(event.get("rounds", 3)),
			int(event.get("requiredWins", 3)),
		],
		NEXUS_UI.MUTED,
		14
	)
	copy.add_child(next)

	var badges := VBoxContainer.new()
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.add_theme_constant_override("separation", 5)
	row.add_child(badges)
	badges.add_child(NEXUS_UI.make_status_badge("WEEK %d  •  $%d  •  LIVES %d/%d" % [
		int(host.run.get("week", 1)),
		int(host.run.get("money", 0)),
		int(host.run.get("season_lives", 0)),
		int(host.run.get("max_season_lives", 0)),
	]))
	badges.add_child(NEXUS_UI.make_status_badge(
		"%s BORDER  •  DECK %s" % [
			String(difficulty.get("name", "Black")).to_upper(),
			"READY" if bool(legal.get("ok", false)) else "NEEDS WORK",
		],
		NEXUS_UI.TEAL if bool(legal.get("ok", false)) else NEXUS_UI.ORANGE
	))


func _add_nexus_menu(host, parent: Node, legal: Dictionary) -> void:
	var rail := NEXUS_UI.make_panel(Vector2(248, 0), NEXUS_UI.TEAL_DEEP, NEXUS_UI.MUSTARD, Vector4(12, 13, 12, 13))
	rail.name = "SeasonHubMenuRail"
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(rail)

	var menu := VBoxContainer.new()
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 9)
	rail.add_child(menu)

	var menu_title := NEXUS_UI.make_section_label("MAIN MENU", NEXUS_UI.INK, 17)
	menu.add_child(menu_title)

	var shop_button := NEXUS_UI.make_menu_button("Card Shop", ICON_SHOP)
	shop_button.name = "ExitToCardStoreButton"
	host._connect_pressed(shop_button, host._show_shop)
	menu.add_child(shop_button)

	var deck_button := NEXUS_UI.make_menu_button("Deck Workshop", ICON_DECK)
	deck_button.name = "SeasonHubDeckbuilderButton"
	host._connect_pressed(deck_button, host._show_deckbuilder)
	menu.add_child(deck_button)

	var events_button := NEXUS_UI.make_menu_button("Season Events", ICON_EVENTS, true)
	events_button.name = "SeasonHubEventsButton"
	menu.add_child(events_button)

	var tournament_button := NEXUS_UI.make_menu_button("Tournament", ICON_TROPHY, false, true)
	tournament_button.name = "SeasonHubRegisterButton"
	tournament_button.disabled = not bool(legal.get("ok", false)) or not host._season_event_selectable(host._selected_season_event_id())
	host._connect_pressed(tournament_button, host._show_tournament)
	menu.add_child(tournament_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_child(spacer)

	var settings_button := NEXUS_UI.make_menu_button("Settings", ICON_SETTINGS)
	settings_button.name = "SeasonHubSettingsButton"
	host._connect_pressed(settings_button, host._show_settings)
	menu.add_child(settings_button)


func _add_nexus_event_workspace(host, parent: Node, event: Dictionary, event_id: String, legal: Dictionary, compact_layout: bool) -> void:
	var workspace := VBoxContainer.new()
	workspace.name = "SeasonHubEventWorkspace"
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 11)
	parent.add_child(workspace)

	_add_nexus_selected_event(host, workspace, event, event_id, legal, compact_layout)

	var calendar_panel := NEXUS_UI.make_panel(Vector2(0, 220 if compact_layout else 270), Color("#F5EEDF"), NEXUS_UI.TEAL, Vector4(16, 10 if compact_layout else 12, 16, 10 if compact_layout else 14))
	calendar_panel.name = "SeasonHubEventCalendar"
	calendar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(calendar_panel)
	var calendar := VBoxContainer.new()
	calendar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	calendar.add_theme_constant_override("separation", 9)
	calendar_panel.add_child(calendar)
	var calendar_heading := HBoxContainer.new()
	calendar.add_child(calendar_heading)
	calendar_heading.add_child(NEXUS_UI.make_section_label("CHAMPIONSHIP ROAD", NEXUS_UI.INK, 21))
	var heading_spacer := Control.new()
	heading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_heading.add_child(heading_spacer)
	calendar_heading.add_child(NEXUS_UI.make_status_badge("%d/%d CLEARED" % [host._season_completed_count(), host._season_calendar_ids().size()], NEXUS_UI.TEAL))

	var event_row := GridContainer.new()
	event_row.name = "SeasonHubCalendarRow"
	event_row.columns = max(1, min(5, host._season_calendar_ids().size()))
	event_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_row.add_theme_constant_override("h_separation", 12)
	event_row.add_theme_constant_override("v_separation", 8)
	calendar.add_child(event_row)

	var ids: Array = host._season_calendar_ids()
	for index in range(ids.size()):
		_add_nexus_event_card(host, event_row, String(ids[index]), event_id, index, compact_layout)

	var notice := String(host.run.get("season_notice", "Choose an event, tune your deck, then register when ready."))
	if notice == "":
		notice = "Choose an event, tune your deck, then register when ready."
	var notice_panel := NEXUS_UI.make_panel(Vector2(0, 58), NEXUS_UI.TEAL_DEEP, NEXUS_UI.ORANGE, Vector4(14, 8, 14, 8))
	notice_panel.name = "SeasonHubNotice"
	workspace.add_child(notice_panel)
	var notice_row := HBoxContainer.new()
	notice_row.add_theme_constant_override("separation", 12)
	notice_panel.add_child(notice_row)
	notice_row.add_child(NEXUS_UI.make_section_label("SHOP NOTE", NEXUS_UI.TEAL_DARK, 15))
	notice_row.add_child(NEXUS_UI.make_body_label(notice, NEXUS_UI.INK, 14))


func _add_nexus_selected_event(host, parent: Node, event: Dictionary, event_id: String, legal: Dictionary, compact_layout: bool) -> void:
	var panel := NEXUS_UI.make_panel(Vector2(0, 140 if compact_layout else 168), NEXUS_UI.PAPER, NEXUS_UI.MUSTARD, Vector4(20, 10 if compact_layout else 14, 20, 10 if compact_layout else 14))
	panel.name = "SeasonHubSelectedEvent"
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	copy.add_child(NEXUS_UI.make_section_label("CURRENT DESTINATION", NEXUS_UI.TEAL, 15))
	copy.add_child(NEXUS_UI.make_section_label(String(event.get("name", event_id)), NEXUS_UI.INK, 29))
	copy.add_child(NEXUS_UI.make_body_label(String(event.get("summary", "Your next step on the road to Worlds.")), NEXUS_UI.MUTED, 14))
	copy.add_child(NEXUS_UI.make_body_label(
		"Week %d  •  %d rounds  •  Need %d wins  •  Free entry" % [
			int(event.get("calendarWeek", 1)),
			int(event.get("rounds", 3)),
			int(event.get("requiredWins", 3)),
		],
		NEXUS_UI.INK,
		14
	))

	var action_column := VBoxContainer.new()
	action_column.custom_minimum_size.x = 275
	action_column.alignment = BoxContainer.ALIGNMENT_CENTER
	action_column.add_theme_constant_override("separation", 8)
	row.add_child(action_column)
	action_column.add_child(NEXUS_UI.make_status_badge("DECK %s" % ("LEGAL" if bool(legal.get("ok", false)) else "NOT LEGAL"), NEXUS_UI.TEAL if bool(legal.get("ok", false)) else NEXUS_UI.ORANGE))
	var action := _make_nexus_primary_action(host, event, event_id, legal)
	action_column.add_child(action)


func _make_nexus_primary_action(host, event: Dictionary, event_id: String, legal: Dictionary) -> Button:
	var label := "REGISTER"
	var callback: Callable = host._show_tournament
	var active: Dictionary = host.run.get("active_tournament", {})
	if host._current_pack_needs_attention():
		label = "CONTINUE PACK"
		callback = host._show_packs
	elif int(host.run.get("prize_packs", 0)) > 0:
		label = "OPEN PRIZE PACKS"
		callback = host._open_reward_pack_flow
	elif not active.is_empty():
		label = "START ROUND %d" % int(active.get("round", 1))
		callback = host._start_season_tournament_round
	elif not bool(legal.get("ok", false)):
		label = "TUNE DECK"
		callback = host._show_deckbuilder
	elif not host._season_event_selectable(event_id):
		label = "EVENT LOCKED"

	var button := NEXUS_UI.make_menu_button(label, ICON_TROPHY, false, true)
	button.name = "SeasonHubNextStepButton"
	button.custom_minimum_size = Vector2(275, 58)
	button.disabled = label == "EVENT LOCKED"
	host._connect_pressed(button, callback)
	return button


func _add_nexus_event_card(host, parent: Node, event_id: String, selected_event_id: String, index: int, compact_layout: bool) -> void:
	var event: Dictionary = host._season_event_by_id(event_id)
	var completed := bool(host._season_event_completed(event_id))
	var unlocked := bool(host._season_event_unlocked(event_id))
	var selected := event_id == selected_event_id
	var border := NEXUS_UI.MUSTARD if selected else (NEXUS_UI.TEAL if unlocked else Color("#918571"))
	var fill := Color("#FFF9EC") if selected else (Color("#EBF1E8") if completed else NEXUS_UI.PAPER_DIM if not unlocked else NEXUS_UI.PAPER)
	var card := NEXUS_UI.make_panel(Vector2(0, 142 if compact_layout else 175), fill, border, Vector4(14, 8 if compact_layout else 11, 14, 8 if compact_layout else 12))
	card.name = "SeasonHubCalendarEvent_%s" % event_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var status := "CLEARED" if completed else ("SELECTED" if selected else "AVAILABLE" if unlocked else "LOCKED")
	top.add_child(NEXUS_UI.make_status_badge(status, border))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(NEXUS_UI.make_section_label("WEEK %d" % int(event.get("calendarWeek", index + 1)), NEXUS_UI.MUTED, 14))
	box.add_child(NEXUS_UI.make_section_label(String(event.get("name", event_id)), NEXUS_UI.INK, 22))
	box.add_child(NEXUS_UI.make_body_label("%d rounds  •  Need %d wins" % [int(event.get("rounds", 3)), int(event.get("requiredWins", 3))], NEXUS_UI.MUTED, 13))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)
	var button := NEXUS_UI.make_event_button(selected, completed, unlocked)
	button.text = "CLEARED" if completed else ("CURRENT EVENT" if selected else "SELECT EVENT" if unlocked else "LOCKED")
	button.name = "SeasonHubCalendarButton_%s" % event_id
	button.disabled = completed or not unlocked or host._season_tournament_active()
	var selected_calendar_event_id := event_id
	host._connect_pressed(button, func() -> void: host._select_season_event(selected_calendar_event_id))
	box.add_child(button)


func _add_header(host, parent: Node, event: Dictionary, event_id: String, metrics: Dictionary, legal: Dictionary, difficulty: Dictionary) -> void:
	var header: VBoxContainer = host._add_bordered_panel(parent, "Season Calendar", "#18212b", String(difficulty.get("border_color", "#f3efe4")), 3)
	header.name = "SeasonHubHeader"
	header.custom_minimum_size = Vector2(0, 116)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)

	var season_summary := VBoxContainer.new()
	season_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	season_summary.add_theme_constant_override("separation", 4)
	row.add_child(season_summary)
	host._add_body_text(season_summary, "Week %d | $%d | Prize packs %d | Lives %d/%d" % [
		int(host.run.get("week", 1)),
		int(host.run.get("money", 0)),
		int(host.run.get("prize_packs", 0)),
		int(host.run.get("season_lives", 0)),
		int(host.run.get("max_season_lives", 0))
	])
	host._add_body_text(season_summary, "%s Border: %s" % [
		String(difficulty.get("name", "Black")),
		String(difficulty.get("summary", "Base season rules."))
	])
	host._add_body_text(season_summary, "Next event: %s | %d rounds | Need %d wins | Free entry" % [
		String(event.get("name", event_id)),
		int(event.get("rounds", 0)),
		int(event.get("requiredWins", 0))
	])
	host._add_body_text(season_summary, "Choose your next event when your deck is ready.")

	var deck_summary := VBoxContainer.new()
	deck_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_summary.add_theme_constant_override("separation", 4)
	row.add_child(deck_summary)
	host._add_body_text(deck_summary, "Deck: %s" % host._format_metrics_short(metrics))
	host._add_body_text(deck_summary, "Legality: %s" % ("Ready for registration" if bool(legal.get("ok", false)) else String(legal.get("reason", "Not legal"))))
	host._add_body_text(deck_summary, String(event.get("winConditionText", "")))


func _add_next_step(host, parent: Node, event: Dictionary, event_id: String, legal: Dictionary) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Next Step", "#20262f", "#ffe08a", 2)
	panel.name = "SeasonHubNextStep"
	panel.custom_minimum_size = Vector2(0, 92)

	var message := ""
	var button_text := ""
	var callback: Callable
	var active: Dictionary = host.run.get("active_tournament", {})
	if bool(host.run.get("run_over", false)):
		message = "This season is complete." if bool(host.run.get("season_champion", false)) else "This season is over."
		button_text = "Start New Run"
		callback = host._show_start
	elif host._current_pack_needs_attention():
		message = "Finish the pack on the table before moving on."
		button_text = "Continue Pack"
		callback = host._show_packs
	elif int(host.run.get("prize_packs", 0)) > 0:
		message = "Your prize packs are ready."
		button_text = "Open Prize Packs"
		callback = host._open_reward_pack_flow
	elif not active.is_empty():
		message = "%s is in progress. Finish or record the current round." % String(active.get("event_name", "Tournament"))
		var match_result: Dictionary = host.run.get("kitchen_match_result", {})
		if not match_result.is_empty() and bool(match_result.get("game_over", false)):
			button_text = "Record Round Result"
			callback = host._season_record_current_round_result
		elif not match_result.is_empty():
			button_text = "Restart Current Kitchen Match"
			callback = host._resume_kitchen_match
		else:
			button_text = "Start Round %d" % int(active.get("round", 1))
			callback = host._start_season_tournament_round
	elif not bool(legal.get("ok", false)):
		message = "Tune your deck before registration: %s" % String(legal.get("reason", "deck is not legal"))
		button_text = "Tune Deck"
		callback = host._show_deckbuilder
	elif not host._season_event_selectable(event_id):
		message = "Choose an available calendar event before registering."
		button_text = "View Calendar"
		callback = host._show_season_run
	else:
		message = "Your deck is ready for %s." % String(event.get("name", event_id))
		button_text = "Register"
		callback = host._show_tournament

	host._add_body_text(panel, message)
	var button: Button = host._make_button(button_text)
	button.name = "SeasonHubNextStepButton"
	host._style_button(button, "action")
	host._connect_pressed(button, callback)
	panel.add_child(button)


func _add_shop_floor(host, parent: Node, event: Dictionary, event_id: String, metrics: Dictionary, legal: Dictionary) -> void:
	var floor := GridContainer.new()
	floor.name = "SeasonHubShopFloor"
	floor.columns = 3
	floor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor.add_theme_constant_override("h_separation", 10)
	floor.add_theme_constant_override("v_separation", 10)
	parent.add_child(floor)

	_add_pack_wall(host, floor)
	_add_singles_case(host, floor)
	_add_register_desk(host, floor, event, event_id, legal)
	_add_deckbuilder_table(host, floor, metrics, legal)
	_add_shop_talk(host, floor)
	_add_menu_board(host, floor)


func _add_pack_wall(host, parent: Node) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Pack Wall", "#1e2b34", "#6ec6d9", 2)
	panel.name = "SeasonHubPackWall"
	panel.custom_minimum_size = Vector2(300, 228)

	var pack_row := HBoxContainer.new()
	pack_row.name = "SeasonHubPackDisplay"
	pack_row.add_theme_constant_override("separation", 6)
	panel.add_child(pack_row)
	for index in range(5):
		var pack := SKETCH_UI.make_rough_panel(
			Vector2(34, 72),
			Color("#FFF4D6").lerp(SKETCH_UI.MUSTARD, float(index) * 0.08),
			SKETCH_UI.INK,
			SKETCH_UI.TEAL if index % 2 == 0 else SKETCH_UI.ORANGE,
			Vector4(3, 3, 3, 3),
			index % 2
		)
		pack.name = "SeasonHubBoosterPack_%d" % index
		pack_row.add_child(pack)

	host._add_body_text(panel, "Prize packs waiting: %d" % int(host.run.get("prize_packs", 0)))
	var open_button: Button = host._make_button("Continue Pack" if not host.run.get("current_pack", []).is_empty() else "Open Packs")
	open_button.name = "SeasonHubPackButton"
	host._connect_pressed(open_button, host._show_packs)
	panel.add_child(open_button)

	var buy_button: Button = host._make_button("Buy Booster ($5)")
	buy_button.name = "SeasonHubBuyPackButton"
	buy_button.disabled = int(host.run.get("money", 0)) < int(host.boosters_by_id["base_standard_pack"].price)
	host._connect_pressed(buy_button, host._buy_and_open_pack)
	panel.add_child(buy_button)


func _add_singles_case(host, parent: Node) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Singles Case", "#20242c", "#cfd6df", 2)
	panel.name = "SeasonHubSinglesCase"
	panel.custom_minimum_size = Vector2(300, 228)

	var case_grid := GridContainer.new()
	case_grid.name = "SeasonHubSinglesPreview"
	case_grid.columns = 3
	case_grid.add_theme_constant_override("h_separation", 5)
	case_grid.add_theme_constant_override("v_separation", 5)
	panel.add_child(case_grid)
	var preview_count: int = min(6, host.run.get("shop", []).size())
	for index in range(preview_count):
		var card_id := String(host.run.shop[index])
		var card: Dictionary = host.cards_by_id.get(card_id, {})
		var tile := PanelContainer.new()
		tile.name = "SeasonHubSingleTile"
		tile.custom_minimum_size = Vector2(78, 54)
		var rarity_fill := SKETCH_UI.PAPER.lerp(
			host._rarity_line_color(String(card.get("rarity", "common"))),
			0.16
		)
		tile.add_theme_stylebox_override(
			"panel",
			SKETCH_UI.texture_style(
				SKETCH_UI.BUTTON_PAPER_B if index % 2 else SKETCH_UI.BUTTON_PAPER_A,
				rarity_fill,
				Vector4(24, 22, 24, 22),
				Vector4(7, 6, 7, 7)
			)
		)
		case_grid.add_child(tile)

		var label := Label.new()
		label.text = String(card.get("name", card_id))
		label.clip_text = true
		label.add_theme_font_override("font", SKETCH_UI.body_font(0.22))
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", SKETCH_UI.INK)
		tile.add_child(label)

	if preview_count == 0:
		host._add_body_text(panel, "The singles case is sold out. New cards arrive after the next tournament round.")
	var button: Button = host._make_button("Browse Singles")
	button.name = "SeasonHubSinglesButton"
	host._connect_pressed(button, host._show_shop)
	panel.add_child(button)


func _add_register_desk(host, parent: Node, event: Dictionary, event_id: String, legal: Dictionary) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Register Desk", "#2a2229", "#c75ba3", 2)
	panel.name = "SeasonHubRegisterDesk"
	panel.custom_minimum_size = Vector2(300, 228)
	host._add_body_text(panel, "%s | %s" % [
		String(event.get("name", event_id)),
		String(event.get("stage", "Tournament"))
	])
	host._add_body_text(panel, "%d rounds | Need %d wins | Free entry" % [
		int(event.get("rounds", 0)),
		int(event.get("requiredWins", 0))
	])
	host._add_body_text(panel, String(event.get("summary", "")))
	var button: Button = host._make_button("Register")
	button.name = "SeasonHubRegisterButton"
	button.disabled = not bool(legal.get("ok", false)) or not host._season_event_selectable(event_id)
	host._style_button(button, "action")
	host._connect_pressed(button, host._show_tournament)
	panel.add_child(button)

func _add_deckbuilder_table(host, parent: Node, metrics: Dictionary, legal: Dictionary) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Deckbuilder Table", "#1f2b24", "#9ee66e", 2)
	panel.name = "SeasonHubDeckbuilderTable"
	panel.custom_minimum_size = Vector2(300, 228)
	host._add_body_text(panel, host._format_metrics(metrics))
	host._add_body_text(panel, "Status: %s" % ("Legal" if bool(legal.get("ok", false)) else String(legal.get("reason", "Needs work"))))
	var button: Button = host._make_button("Tune Deck")
	button.name = "SeasonHubDeckbuilderButton"
	host._connect_pressed(button, host._show_deckbuilder)
	panel.add_child(button)


func _add_shop_talk(host, parent: Node) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Shop Talk", "#202734", "#7fb8ff", 2)
	panel.name = "SeasonHubShopTalk"
	panel.custom_minimum_size = Vector2(300, 228)
	var reports: Array = host.run.get("reports", [])
	if reports.is_empty():
		host._add_body_text(panel, "No metagame notes yet.")
	for index in range(min(3, reports.size())):
		host._add_body_text(panel, String(reports[index]))
	var button: Button = host._make_button("Open Metagame")
	button.name = "SeasonHubMetagameButton"
	host._connect_pressed(button, host._show_meta)
	panel.add_child(button)


func _add_menu_board(host, parent: Node) -> void:
	var panel: VBoxContainer = host._add_bordered_panel(parent, "Menu Board", "#29262c", "#e8c15a", 2)
	panel.name = "SeasonHubMenuBoard"
	panel.custom_minimum_size = Vector2(300, 228)
	host._add_body_text(panel, "Save the run, load a run, or return to setup.")

	var save_button: Button = host._make_button("Save")
	save_button.name = "SeasonHubSaveButton"
	host._connect_pressed(save_button, host._save_run)
	panel.add_child(save_button)

	var load_button: Button = host._make_button("Load")
	load_button.name = "SeasonHubLoadButton"
	host._connect_pressed(load_button, host._load_run_from_disk)
	panel.add_child(load_button)

	var new_button: Button = host._make_button("New Run")
	new_button.name = "SeasonHubNewRunButton"
	host._connect_pressed(new_button, host._show_start)
	panel.add_child(new_button)


func _add_event_calendar(host, parent: Node, selected_event_id: String) -> void:
	var calendar: VBoxContainer = host._add_bordered_panel(parent, "Event Calendar", "#17202c", "#7da7ff", 2)
	calendar.name = "SeasonHubEventCalendar"
	host._add_body_text(calendar, "Progress: %d/%d events cleared. Goal: %s" % [
		host._season_completed_count(),
		host._season_calendar_ids().size(),
		String(host.run.get("season_goal", "Win Worlds before your season lives run out."))
	])

	var row := GridContainer.new()
	row.name = "SeasonHubCalendarRow"
	row.columns = max(1, min(5, host._season_calendar_ids().size()))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	calendar.add_child(row)

	var ids: Array = host._season_calendar_ids()
	for index in range(ids.size()):
		var event_id := String(ids[index])
		var event: Dictionary = host._season_event_by_id(event_id)
		var completed := bool(host._season_event_completed(event_id))
		var unlocked := bool(host._season_event_unlocked(event_id))
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

		var event_box: VBoxContainer = host._add_bordered_panel(row, "%s" % status, accent, border, 2)
		event_box.name = "SeasonHubCalendarEvent_%s" % event_id
		event_box.custom_minimum_size = Vector2(176, 136)
		host._add_body_text(event_box, "%s\nWeek %d | Free entry" % [
			String(event.get("name", event_id)),
			int(event.get("calendarWeek", index + 1))
		])
		host._add_body_text(event_box, "Need %d/%d" % [
			int(event.get("requiredWins", 0)),
			int(event.get("rounds", 0))
		])
		var button_text := "Prep"
		if completed:
			button_text = "Cleared"
		elif not unlocked:
			button_text = "Locked"
		elif not selected:
			button_text = "Select"
		var button: Button = host._make_button(button_text)
		button.name = "SeasonHubCalendarButton_%s" % event_id
		button.disabled = completed or not unlocked or host._season_tournament_active()
		var selected_calendar_event_id := event_id
		host._connect_pressed(button, func() -> void: host._select_season_event(selected_calendar_event_id))
		event_box.add_child(button)


func _add_notice_and_results(host, parent: Node) -> void:
	var notice := String(host.run.get("season_notice", ""))
	if notice != "":
		var notice_panel: VBoxContainer = host._add_bordered_panel(parent, "Counter Note", "#263222", "#9ee66e", 2)
		notice_panel.name = "SeasonHubNotice"
		host._add_body_text(notice_panel, notice)

	if host.run.get("last_result", []).size() > 0:
		var last: VBoxContainer = host._add_bordered_panel(parent, "Last Match Slip", "#241f25", "#e8c15a", 2)
		last.name = "SeasonHubLastResult"
		for line in host.run.last_result:
			host._add_body_text(last, String(line))
