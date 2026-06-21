extends RefCounted
class_name SeasonHubScreen


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

	var hub := VBoxContainer.new()
	hub.name = "SeasonHubCardShop"
	hub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub.add_theme_constant_override("separation", 10)
	host.content.add_child(hub)

	_add_header(host, hub, event, event_id, metrics, legal, difficulty)
	_add_shop_floor(host, hub, event, event_id, metrics, legal)
	_add_event_calendar(host, hub, event_id)
	_add_notice_and_results(host, hub)


func _add_header(host, parent: Node, event: Dictionary, event_id: String, metrics: Dictionary, legal: Dictionary, difficulty: Dictionary) -> void:
	var header: VBoxContainer = host._add_bordered_panel(parent, "Roadside Card Shop", "#18212b", String(difficulty.get("border_color", "#f3efe4")), 3)
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
		String(difficulty.get("name", "White")),
		String(difficulty.get("summary", "Base season rules."))
	])
	host._add_body_text(season_summary, "Next event: %s | %d rounds | Need %d wins | Entry $%d" % [
		String(event.get("name", event_id)),
		int(event.get("rounds", 0)),
		int(event.get("requiredWins", 0)),
		int(event.get("entryFee", 0))
	])

	var deck_summary := VBoxContainer.new()
	deck_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_summary.add_theme_constant_override("separation", 4)
	row.add_child(deck_summary)
	host._add_body_text(deck_summary, "Deck: %s" % host._format_metrics_short(metrics))
	host._add_body_text(deck_summary, "Legality: %s" % ("Ready for registration" if bool(legal.get("ok", false)) else String(legal.get("reason", "Not legal"))))
	host._add_body_text(deck_summary, String(event.get("winConditionText", "")))


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
		var pack := ColorRect.new()
		pack.name = "SeasonHubBoosterPack_%d" % index
		pack.color = Color("#25384a").lerp(Color("#6ec6d9"), float(index) * 0.08)
		pack.custom_minimum_size = Vector2(34, 72)
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
		var style := StyleBoxFlat.new()
		style.bg_color = host._rarity_line_color(String(card.get("rarity", "common")))
		style.border_color = host._rarity_text_color(String(card.get("rarity", "common"))).darkened(0.18)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		tile.add_theme_stylebox_override("panel", style)
		case_grid.add_child(tile)

		var label := Label.new()
		label.text = String(card.get("name", card_id))
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color("#eef3ff"))
		tile.add_child(label)

	if preview_count == 0:
		host._add_body_text(panel, "The singles case is being restocked.")
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
	host._add_body_text(panel, "%d rounds | Need %d wins | Entry $%d" % [
		int(event.get("rounds", 0)),
		int(event.get("requiredWins", 0)),
		int(event.get("entryFee", 0))
	])
	host._add_body_text(panel, String(event.get("summary", "")))
	var button: Button = host._make_button("Register")
	button.name = "SeasonHubRegisterButton"
	button.disabled = not bool(legal.get("ok", false)) or int(host.run.get("money", 0)) < int(event.get("entryFee", 0)) or not host._season_event_selectable(event_id)
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
		host._add_body_text(event_box, "%s\nWeek %d | $%d" % [
			String(event.get("name", event_id)),
			int(event.get("calendarWeek", index + 1)),
			int(event.get("entryFee", 0))
		])
		host._add_body_text(event_box, "Need %d/%d" % [
			int(event.get("requiredWins", 0)),
			int(event.get("rounds", 0))
		])
		var button: Button = host._make_button("Select")
		button.name = "SeasonHubCalendarButton_%s" % event_id
		button.disabled = completed or not unlocked or selected or host._season_tournament_active()
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
