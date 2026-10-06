extends SceneTree

## Exercise real timing so saved upgrades cannot be doubled or interrupted while
## the selected card takes focus, becomes foil, then returns to the visible deck.
class AnimatedMain:
	extends "res://scripts/Main.gd"
	var animate_reveals := false
	func _running_automated_test() -> bool:
		return not animate_reveals

const CARD_ID := "spicy_jalapeno_panther"
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const EXPECTED_STAGES := ["focus", "white", "shine", "deck", "complete"]
const CAPTURE_DIR := "res://outputs/foil_reveal_2026-09-15"
var _failures: Array[String] = []
var _checks := 0
var _main: AnimatedMain
var _save_path := "/private/tmp/locals-foil-reveal-%d.json" % OS.get_process_id()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_main = AnimatedMain.new()
	_main.autosave_suspended = true
	root.add_child(_main)
	_main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(5)
	_main.autosave_enabled = false
	_main.run_state_service.save_path = _save_path
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900)]:
		for reduced_motion in [false, true]:
			await _exercise(viewport_size, reduced_motion, "paid" if viewport_size.x == 1440 else "vending")
	_main.autosave_enabled = false
	_main._release_audio_streams()
	_main.queue_free()
	await _frames(3)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save_path + suffix):
			DirAccess.remove_absolute(_save_path + suffix)
	for failure in _failures:
		push_error(failure)
	print("Foil upgrade reveal smoke test: %d checks, %d failures." % [_checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)


func _exercise(viewport_size: Vector2i, reduced_motion: bool, service: String) -> void:
	var fixture := "%dx%d_%s_%s" % [viewport_size.x, viewport_size.y, service, "reduced" if reduced_motion else "animated"]
	root.size = viewport_size
	_main.animate_reveals = false
	_main.autosave_enabled = false
	_main.player_settings.reduced_motion = reduced_motion
	_main.player_settings.text_scale = 1.25 if reduced_motion else 1.0
	for feedback in get_nodes_in_group("ui_feedback"):
		feedback.queue_free()
	var deck: Dictionary = _main._deck_entries_to_dict(_main.archetypes_by_id.spicy.starterDeck)
	deck[CARD_ID] = 2
	_main.run = _main.run_state_service.create_run("spicy", deck, "hearty", "season", "blue")
	_main.route_run_service.initialize_run(_main.run, 20260915)
	_main.run.card_upgrades = {CARD_ID: 1}
	_main.run.money = 25
	_main.run.life = 28
	_main._show_tournament_hub()
	if service == "paid":
		_main._open_hub_shop()
		_main._show_route_upgrade_card()
	else:
		_main._show_hub_break_upgrade()
	await _frames(6)
	_main._select_route_shop_service_card("upgrade" if service == "paid" else "break_upgrade", CARD_ID, 1)
	await _frames(4)
	var picker := _main.route_shop_service_overlay as Control
	var confirm := _main.find_child("RouteUpgradeConfirmButton", true, false) as Button
	_expect(picker != null and confirm != null and not confirm.disabled, fixture + ": upgrade picker did not select the eligible normal twin.")
	if confirm == null:
		return
	var initial_deck: Dictionary = _main.run.deck.duplicate(true)
	var initial_collection: Dictionary = _main.run.collection.duplicate(true)
	var initial_count: int = _main._deck_total(initial_deck)
	_main.autosave_suspended = false
	_main.autosave_enabled = true
	_main.animate_reveals = true
	confirm.pressed.emit()
	_expect(_main._card_upgrade_reveal_active, fixture + ": confirmation did not hold interaction during the reveal.")
	_expect(_main.route_run_service.upgrade_count(_main.run, CARD_ID) == 2, fixture + ": upgrade did not commit before its ceremony.")
	_expect(_main.run.deck == initial_deck and _main.run.collection == initial_collection, fixture + ": foiling created or removed a physical card copy.")
	var saved: Dictionary = _main.run_state_service.load_run()
	_expect(saved.get("ok", false) and _main.route_run_service.upgrade_count(saved.get("run", {}), CARD_ID) == 2, fixture + ": upgrade was not saved before playback.")
	_expect(saved.get("run", {}).get("deck", {}) == initial_deck, fixture + ": saved deck changed its physical card count.")
	var in_flight_screen: String = _main.current_screen
	var settings_button := _main.find_child("HubSettingsButton", true, false) as Button
	if settings_button != null:
		_click_at(settings_button.get_global_rect().get_center())
	var money_after: int = _main.run.money
	# Exercise real key routing and duplicate callbacks while the service is busy.
	_escape()
	if service == "paid":
		_main._route_upgrade_card(CARD_ID)
	else:
		_main._route_hub_upgrade_card(CARD_ID)
	await _frames(2)
	_expect(_main.current_screen == in_flight_screen and _main._card_upgrade_reveal_active, fixture + ": Escape, covered Settings, or a repeated confirmation interrupted the ceremony.")
	_expect(_main.run.money == money_after and _main.route_run_service.upgrade_count(_main.run, CARD_ID) == 2, fixture + ": a repeated confirmation charged or upgraded twice.")
	_expect(not is_instance_valid(picker) or not picker.is_visible_in_tree(), fixture + ": the old comparison picker stayed visible behind the spotlight.")

	var seen: Array[String] = []
	var inspected: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 6000
	var first_travel_distance := -1.0
	var last_travel_distance := -1.0
	var centered_position := Vector2.INF
	var stage_started_at := Time.get_ticks_msec()
	while _main._card_upgrade_reveal_active and Time.get_ticks_msec() < deadline:
		var overlay := _main.find_child("RouteCardUpgradeRevealOverlay", true, false) as Control
		if overlay != null:
			var stage := String(overlay.get_meta("upgrade_animation_stage", ""))
			var card := overlay.find_child("RouteUpgradeSpotlightCard", true, false) as Control
			var dimmer := overlay.find_child("RouteCardUpgradeRevealDimmer", true, false) as ColorRect
			var stack := overlay.find_child("RouteUpgradeDeckStack", true, false) as Control
			if stage != "" and not seen.has(stage):
				seen.append(stage)
				stage_started_at = Time.get_ticks_msec()
				print("Foil reveal %s: %s" % [fixture, stage])
			if stage in ["white", "shine"] and not inspected.has(stage):
				inspected[stage] = true
				_expect(card != null and card.is_visible_in_tree(), fixture + ": no visible card during " + stage)
				_expect(dimmer != null and dimmer.is_visible_in_tree() and dimmer.color.a * dimmer.modulate.a >= 0.5, fixture + ": background was not substantially dimmed during " + stage)
				if card != null:
					var rect := card.get_global_rect()
					_expect(rect.get_center().distance_to(root.get_visible_rect().get_center()) < 35.0, fixture + ": spotlight card is not centered during " + stage)
					_expect(rect.size.y >= viewport_size.y * 0.50 and root.get_visible_rect().encloses(rect), fixture + ": centered card is too small or clipped during " + stage)
					var displayed: Dictionary = card.get_meta("inspection_card", {})
					_expect(bool(displayed.get("upgraded", false)) == (stage == "shine"), fixture + ": foiled stats appeared at the wrong point in " + stage)
					for face in card.find_children("RuntimeCardFace", "Control", true, false):
						if face.is_visible_in_tree():
							_expect(face.get("card_border_color") == PALETTE.card_border_color("blue"), fixture + ": spotlight lost the original selected blue border.")
					if centered_position == Vector2.INF:
						centered_position = rect.get_center()
					elif reduced_motion:
						_expect(rect.get_center().distance_to(centered_position) < 1.0 and absf(card.rotation) < 0.001, fixture + ": Reduced Motion moved or tilted the reveal card.")
				await _capture(fixture + "_" + stage)
			if stage == "shine" and not inspected.has("shine_peak") and Time.get_ticks_msec() - stage_started_at >= (140 if reduced_motion else 320):
				inspected.shine_peak = true
				await _capture(fixture + "_shine_peak")
			if stage == "deck" and stack != null:
				if not inspected.has("deck"):
					inspected.deck = true
					_expect(stack.is_visible_in_tree() and root.get_visible_rect().encloses(stack.get_global_rect()), fixture + ": deck return has no visible unclipped destination.")
					_expect(int(stack.get("card_count")) == initial_count, fixture + ": destination deck count changed during a cosmetic upgrade.")
				if card != null and card.is_visible_in_tree() and not reduced_motion:
					var landing: Rect2 = stack.call("get_landing_rect_global")
					last_travel_distance = card.get_global_rect().get_center().distance_to(landing.get_center())
					if first_travel_distance < 0:
						first_travel_distance = last_travel_distance
					elif not inspected.has("travel_capture") and last_travel_distance < first_travel_distance * 0.6:
						inspected.travel_capture = true
						await _capture(fixture + "_deck")
		await _frames(1)
	_expect(not _main._card_upgrade_reveal_active, fixture + ": ceremony failed to complete within six seconds.")
	await _frames(4)
	_expect(_main.last_card_upgrade_animation_stages == EXPECTED_STAGES, fixture + ": stage sequence skipped focus, foil, deck arrival, or completion.")
	for stage in ["white", "shine", "deck"]:
		_expect(inspected.has(stage), fixture + ": live animation did not present its " + stage + " phase.")
	if not reduced_motion:
		_expect(first_travel_distance > 60 and last_travel_distance < first_travel_distance * 0.2, fixture + ": card did not travel into its deck.")
	_expect(_main.find_child("RouteCardUpgradeRevealOverlay", true, false) == null, fixture + ": cinematic overlay remained after returning to the shop.")
	_expect(_main.route_shop_service_overlay == null and _main.current_screen in ["route_shop", "route_hub"], fixture + ": picker remained or service did not return to the shop.")
	_expect(_main.run.deck == initial_deck and _main.run.collection == initial_collection and _main.route_run_service.upgrade_count(_main.run, CARD_ID) == 2, fixture + ": animation completion lost or duplicated the upgraded copy.")
	_expect(_main.run.money == (20 if service == "paid" else 25) and _main.run.life == 28, fixture + ": incorrect service payment or health change.")
	if service == "vending":
		_expect(_main.run.hub_break_used and _main.run.hub_break_choice == "upgrade", fixture + ": vending upgrade did not consume precisely its shared bye.")
	else:
		_expect(_main.run.hub_shop.upgrade_purchased and not _main.run.hub_break_used, fixture + ": paid upgrade consumed the wrong service allowance.")
	await _capture(fixture + "_complete")


func _frames(count: int) -> void:
	for unused in range(count):
		await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_cmdline_user_args().has("--capture"):
		return
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [CAPTURE_DIR, filename])) == OK, "Could not capture " + filename)


func _click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)


func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
