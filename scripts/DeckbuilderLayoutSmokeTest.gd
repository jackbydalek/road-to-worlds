extends SceneTree
const MAIN := preload("res://scenes/Main.tscn")
const BODYGUARD := "sweet_soft_serve_crab"
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = MAIN.instantiate()
	root.add_child(main)
	await settle()
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main.run = main.run_state_service.create_run("sweet", {BODYGUARD: 3, "chef_mary": 2, "spicy_wasabi_wasp": 2}, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 1635)
	main.run.deck = {BODYGUARD: 3, "chef_mary": 2, "spicy_wasabi_wasp": 2}
	main.run.card_upgrades = {BODYGUARD: 1}
	var original: Dictionary = main.run.deck.duplicate(true)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for scale in [1.0, 1.25]:
			main.player_settings.text_scale = scale
			main._show_deckbuilder()
			await settle()
			var browser = main.find_child("DeckBrowser", true, false)
			expect(browser != null, "No shared deck browser")
			if browser == null:
				continue
			expect(browser.displayed_entries.size() == 4, "Upgraded and normal copies were not grouped separately")
			expect(browser.count.text == "7 cards", "Grouped total lost physical copies")
			expect(not browser.allow_remove, "Locked run deck exposes editing")
			expect(root.get_visible_rect().encloses(browser.scroll.get_global_rect()), "Deck scroll clips at %s/%s" % [viewport_size, scale])
			expect(not browser.scroll.get_h_scroll_bar().visible, "Deck requires horizontal scrolling")
			var back := main.find_child("DeckbuilderBackButton", true, false) as Control
			expect(back != null and root.get_visible_rect().encloses(back.get_global_rect()), "Back clips")
			browser.search.text = "bodyguard"
			browser.search.text_changed.emit("bodyguard")
			expect(browser.displayed_entries.size() == 2 and browser.count.text == "3 / 7 cards", "Search did not match keywords/copy totals")
			browser.grouped = false
			browser._render()
			expect(browser.displayed_entries.size() == 3, "Ungrouping lost physical copies")
			browser.query = ""
			browser.type_filter = "chef"
			browser._render()
			expect(browser.displayed_entries.size() == 2, "Type filter failed")
			browser.type_filter = ""
			browser.keyword_filter = "stalwart"
			browser._render()
			expect(browser.displayed_entries.size() == 2, "Keyword filter failed")
			browser.keyword_filter = ""
			browser.sort_mode = "health"
			browser._render()
			expect(bool(browser.displayed_entries[0].card.get("upgraded", false)), "Health sort ignored upgraded stats")
			browser.query = "zzzz-no-card"
			browser._render()
			expect(browser.displayed_entries.is_empty(), "Empty-search state failed")
	expect(main.run.deck == original, "Browsing changed the locked deck")
	main._release_audio_streams()
	main.queue_free()
	await settle()
	for error in errors:
		push_error(error)
	print("Deck browser smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func settle() -> void:
	for unused in range(8):
		await process_frame

func expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
