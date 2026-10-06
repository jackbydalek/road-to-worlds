extends SceneTree
## Persistent deckbox inspection must not claim the prize again or replace an
## action notice. The same paper slip follows real weekly run state.
var errors: Array[String] = []
var main
const CAPTURE_DIR := "res://outputs/tournament_kit_2026-09-11"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_compact_slip()
	main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.player_settings.reduced_motion = true
	main.player_settings.text_scale = 1.0
	main._apply_player_settings(false)
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260911)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/demo_progression.json"))
	var chosen: Dictionary = {}
	for box in config.deckboxes:
		if box.id == "big_lunch":
			chosen = box.duplicate(true)
	main.run.week = 2
	main.run.hub_round = 2
	main.run.deckbox = chosen
	main.run.max_life = 45
	main.run.life = 28
	main.run.money = 12
	main.run.hub_notice = "Sriracharrow added to your deck."
	main._show_tournament_hub()
	await process_frame
	var hub = main.find_child("TournamentHub", true, false)
	_expect(hub._notice_label.text == main.run.hub_notice, "The deckbox replaced the current shop action notice.")
	_expect(hub._tournament_slip.week == 2 and hub._tournament_slip.round_number == 2, "The match slip lost week/round state.")
	_expect(hub._deckbox_button.visible and hub._deckbox_art.get_meta("deckbox_id") == "big_lunch", "The owned box is missing from the persistent status rail.")
	_expect(hub._deckbox_effect.text == "+5 maximum life", "The persistent summary implies that on-choice healing repeats.")
	_expect(hub.find_child("HubNextEyebrow", true, false).text == "Table 3", "The receipt confused the current round with its actual table assignment.")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for frame in range(5):
			await process_frame
		for control in [hub._tournament_slip, hub._deckbox_button, hub._next_round_button, hub.find_child("HubSaveButton", true, false), hub.find_child("HubSettingsButton", true, false)]:
			_expect(root.get_visible_rect().encloses(control.get_global_rect()), "Tournament kit control clipped at %s: %s" % [viewport_size, control.name])
		await _capture("shop_%dx%d" % [viewport_size.x, viewport_size.y])
	root.size = Vector2i(1280, 720)
	main.player_settings.text_scale = 1.25
	main._apply_player_settings(false)
	for frame in range(5):
		await process_frame
	_expect(hub._deckbox_name.get_visible_line_count() == 1, "Large text hides the owned deckbox's name.")
	_expect(hub._tournament_slip._stamps.position.y >= hub._tournament_slip._round_label.position.y + hub._tournament_slip._round_label.size.y, "Large text overlaps the round stamps.")
	_expect(hub._table_receipt.get_global_rect().encloses(hub._notice_label.get_global_rect().grow(4)), "The large-text action notice has no breathing room inside the receipt.")
	await _capture("shop_1280x720_large_text")
	hub._deckbox_button.grab_focus()
	hub._deckbox_button.pressed.emit()
	await process_frame
	var inspection: Node = hub.find_child("HubDeckboxInspection", true, false)
	_expect(inspection != null, "Clicking the owned deckbox did not open inspection.")
	_expect(hub.find_child("HubDeckboxExactEffect", true, false).text == chosen.description, "Inspection did not use the saved deckbox's exact effect.")
	await _capture("shop_deckbox_inspection")
	_escape()
	for frame in range(4):
		await process_frame
	_expect(main.run.life == 28 and main.run.max_life == 45 and main.run.money == 12 and main.run.deckbox == chosen, "Inspecting the deckbox claimed its effect again or changed run state.")
	_expect(root.gui_get_focus_owner() == hub._deckbox_button, "Closing deckbox inspection lost keyboard focus.")
	main._open_hub_view("machine")
	for frame in range(4):
		await process_frame
	_expect(not hub._table_receipt.visible, "The next-table receipt covers close-up service navigation.")
	hub._snack_view.select_snack("heal")
	main._use_hub_break_heal()
	for frame in range(4):
		await process_frame
	_expect(main.run.life == 33 and main.run.hub_break_used, "The real bye no longer heals once and records its use.")
	_expect(hub._vending_status.text == "Your free bye is used for this week.", "Week two used-bye copy promises an unimplemented third week.")
	await _capture("shop_used_bye")
	main._leave_hub_shop()
	for frame in range(4):
		await process_frame
	var snapshot: Dictionary = main._tournament_hub_snapshot()
	snapshot.deckbox = {}
	snapshot.week = 1
	hub.configure(snapshot, true)
	_expect(not hub._deckbox_button.visible, "An unowned deckbox remains inspectable before the week-one prize.")
	main._release_audio_streams()
	main.queue_free()
	await process_frame
	for message in errors:
		push_error(message)
	print("Hub tournament kit smoke test: %d failures" % errors.size())
	quit(0 if errors.is_empty() else 1)

func _test_compact_slip() -> void:
	var slip := preload("res://scripts/ui/TournamentSlip.gd").new()
	slip.compact = true
	slip.size = Vector2(226, 82)
	root.add_child(slip)
	slip.configure(2, 2, 4)
	# The battle's 115% base typography plus its largest 150% preference.
	slip._venue_label.add_theme_font_size_override("font_size", roundi(16 * 1.15 * 1.5))
	slip._round_label.add_theme_font_size_override("font_size", roundi(12 * 1.15 * 1.5))
	slip._layout()
	_expect(slip._stamps.position.y >= slip._round_label.position.y + slip._round_label.size.y + 4, "Compact battle stamps overlap at 150% text.")
	_expect(Rect2(Vector2.ZERO, slip.size).encloses(Rect2(slip._stamps.position, slip._stamps.size)), "Compact battle stamps escape their expanded slip.")
	_expect(slip.size.y > 82 and slip.get_combined_minimum_size().y == slip.size.y, "The compact slip does not expose its large-text height to the battle layout.")
	slip.free()

func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in range(10):
		await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [CAPTURE_DIR, label]))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		print("FAILED: ", message)
