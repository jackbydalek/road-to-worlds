extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const SUPPORTED_LAYOUTS := [
	{"size": Vector2i(1280, 720), "text_scale": 1.0},
	{"size": Vector2i(1280, 720), "text_scale": 1.25},
	{"size": Vector2i(1440, 900), "text_scale": 1.25},
	{"size": Vector2i(1920, 1080), "text_scale": 1.25},
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_pack_and_finale_layouts()
	await _test_tutorial_inspector_layout()
	if failures.is_empty():
		print("Responsive layout smoke test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_pack_and_finale_layouts() -> void:
	for layout in SUPPORTED_LAYOUTS:
		var viewport_size: Vector2i = layout.size
		var text_scale := float(layout.text_scale)
		var context := "%dx%d at %d%% text" % [viewport_size.x, viewport_size.y, roundi(text_scale * 100.0)]
		root.size = viewport_size
		var main = MAIN_SCENE.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.player_settings.text_scale = text_scale
		main._apply_player_settings(false)
		main._start_new_run_with_mode("spicy", "debug", "white")

		var sealed_pack: Array = main._generate_pack("base_standard_pack")
		main._start_pack(sealed_pack)
		main._show_packs()
		await process_frame
		await process_frame
		var pack_frame := main.find_child("PackOpeningSceneFrame", true, false) as Control
		var pack_scroll := main.scroll as ScrollContainer
		_expect(pack_frame != null and pack_scroll != null, "The pack-opening layout did not render at %s." % context)
		if pack_frame != null and pack_scroll != null:
			_expect(not pack_scroll.get_v_scroll_bar().visible and not pack_scroll.get_h_scroll_bar().visible, "The pack-opening table requires scrolling at %s." % context)
			_expect(pack_scroll.get_global_rect().encloses(pack_frame.get_global_rect()), "The pack-opening frame extends beyond %s." % context)

		main._show_season_run()
		await process_frame
		await process_frame
		var season_next := main.find_child("SeasonHubNextStepButton", true, false) as Control
		var season_calendar := main.find_child("SeasonHubEventCalendar", true, false) as Control
		_expect(season_next != null and season_calendar != null, "The Season Calendar did not render at %s." % context)
		if season_next != null:
			_expect(main.scroll.get_global_rect().encloses(season_next.get_global_rect()), "The Season Calendar primary action is clipped at %s." % context)
		_expect(not main.scroll.get_h_scroll_bar().visible, "The Season Calendar requires horizontal scrolling at %s." % context)

		main._show_settings()
		await process_frame
		await process_frame
		var settings_columns := main.find_child("SettingsColumns", true, false) as Control
		_expect(settings_columns != null, "Settings did not render at %s." % context)
		_expect(not main.scroll.get_h_scroll_bar().visible, "Settings requires horizontal scrolling at %s." % context)

		main._show_thanks_for_playing()
		await process_frame
		await process_frame
		var finale_actions := main.find_child("FinaleActions", true, false) as Control
		var community_links := main.find_child("FinaleCommunityLinks", true, false) as Control
		_expect(finale_actions != null and community_links != null, "The season finale is missing its action rows at %s." % context)
		if finale_actions != null and community_links != null:
			var finale_viewport: Rect2 = main.scroll.get_global_rect()
			_expect(finale_viewport.encloses(community_links.get_global_rect()), "The community links are clipped at %s." % context)
			_expect(finale_viewport.encloses(finale_actions.get_global_rect()), "The finale actions are clipped at %s." % context)
		_expect(not main.scroll.get_h_scroll_bar().visible, "The finale requires horizontal scrolling at %s." % context)

		main._show_start()
		await process_frame
		var credits_button := main.find_child("CreditsPosterButton", true, false) as Button
		if credits_button != null:
			credits_button.emit_signal("pressed")
		await process_frame
		var credits_panel := main.find_child("CreditsPanel", true, false) as Control
		var discord_button := main.find_child("DiscordCommunityButton", true, false) as Control
		_expect(credits_panel != null and discord_button != null, "The credits/community panel did not render at %s." % context)
		if credits_panel != null:
			_expect(credits_panel.get_parent().get_global_rect().encloses(credits_panel.get_global_rect()), "The credits panel extends outside %s." % context)

		main._release_audio_streams()
		await create_timer(0.12).timeout
		main.queue_free()
		for unused_frame in range(4):
			await process_frame


func _test_tutorial_inspector_layout() -> void:
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		var tutorial = TABLE_SCENE.instantiate()
		tutorial.configure_tutorial()
		root.add_child(tutorial)
		await process_frame
		await process_frame
		tutorial.text_scale_index = 1
		tutorial._apply_text_scale()
		var hand_index := 0
		var card_id := String(tutorial.state.player.hand[hand_index])
		tutorial.selected_ref = {
			"kind": "hand",
			"side": "player",
			"zone": "hand",
			"card_id": card_id,
			"hand_index": hand_index,
			"instance_id": -1
		}
		tutorial._refresh_action_panel()
		await process_frame
		await process_frame
		var play_button := _find_button_with_text(tutorial.action_list, "Play Card")
		var complete_text := tutorial.action_list.find_child("LivingTableCompleteCardText", true, false) as Label
		var context := "%dx%d at 125%% battle text" % [viewport_size.x, viewport_size.y]
		_expect(play_button != null, "The tutorial inspector did not render its Play Card control at %s." % context)
		_expect(complete_text != null and complete_text.visible and complete_text.size.y > 0.0, "The tutorial inspector did not render the complete card text at %s." % context)
		if play_button != null:
			_expect(tutorial.action_scroll.get_global_rect().encloses(play_button.get_global_rect()), "The tutorial Play Card control starts below the visible inspector at %s." % context)
			_expect(tutorial.action_scroll.scroll_vertical == 0, "The tutorial inspector did not open at its primary action at %s." % context)
		tutorial.queue_free()
		for unused_frame in range(4):
			await process_frame


func _find_button_with_text(parent: Node, text_value: String) -> Button:
	for node in parent.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text_value:
			return button
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
