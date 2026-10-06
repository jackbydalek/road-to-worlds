extends SceneTree
## Real deckbox choices and copy-aware card rewards must survive interruption.
const SAVE_PATH := "/private/tmp/locals-deckbox-reward-ui-smoke.json"
const BEE := "spicy_hot_honey_bee"
const MEAL := "spicy_sriracharrow"
const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const REWARD_SCREEN := preload("res://scripts/ui/DeckboxCardRewardScreen.gd")
var main
var checks := 0
var baseline: Dictionary
var services_were_used := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	root.add_child(main)
	await _frames(3)
	main.run_state_service.save_path = SAVE_PATH
	main.autosave_enabled = true
	main.autosave_suspended = false
	main.player_settings.reduced_motion = true
	main.player_settings.text_scale = 1.0
	main._apply_player_settings(false)
	var starter: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", starter, "hearty", "season", "blue")
	main.route_run_service.initialize_run(main.run, 202609112)
	baseline = main.run.duplicate(true)
	await _verify_removals()
	await _verify_upgrades()
	await _verify_single_card_floor()
	print("Deckbox reward UI smoke test passed: %d checks." % checks)
	main.queue_free()
	await _frames(2)
	quit(0)

func _stage(deck: Dictionary, upgrades: Dictionary, prize: String, used_services: bool = false) -> void:
	main.run = baseline.duplicate(true)
	main.run.deck = deck.duplicate(true)
	main.run.collection = deck.duplicate(true)
	main.run.card_upgrades = upgrades.duplicate(true)
	main.run.week = 1
	main.run.week_transition = "deckbox"
	main.run.deckbox_offer = ["loyal_regular", "chefs_edge", "big_lunch"]
	main.run.deckbox = {}
	main.run.deckbox_reward = {}
	main.run.money = 17
	main.run.life = 23
	services_were_used = used_services
	main.run.hub_break_used = used_services
	main.run.hub_break_choice = "heal" if used_services else ""
	main.run.hub_shop = {"upgrade_purchased": used_services, "remove_purchased": used_services}
	main._show_week_transition()
	await _frames(4)
	var select := main.find_child("DeckboxChoice_" + prize, true, false) as Button
	_expect(select != null, "Deckbox Select button missing: " + prize)
	select.pressed.emit()
	var keep := main.find_child("WeeklyDemoContinue", true, false) as Button
	_expect(keep != null and not keep.disabled, "Selecting a box did not enable Keep.")
	keep.pressed.emit()
	await _frames(4)
	_expect(String(main.run.deckbox.id) == prize, "Keep did not equip the selected box.")

func _verify_removals() -> void:
	await _stage({BEE: 4, MEAL: 1}, {BEE: 2}, "loyal_regular", true)
	var screen = _screen()
	_expect(int(main.run.deckbox_reward.remaining) == 3, "Removal reward did not offer three choices.")
	_expect(screen.browser.entries.size() == 5, "Removal browser omitted copies.")
	_expect(screen.browser.displayed_entries.size() == 3, "Removal browser did not separate normal and upgraded copies.")
	await _select_copy(screen, BEE, true, 0)
	_expect(bool(screen.before_face._card.get("upgraded", false)), "Removal preview does not show the selected upgraded copy.")
	await _confirm_once(screen)
	_expect(int(main.run.deck[BEE]) == 3 and int(main.run.card_upgrades[BEE]) == 1, "Removing an upgraded copy did not remove exactly one upgrade.")
	_expect(int(main.run.deckbox_reward.remaining) == 2 and int(main.run.deckbox_reward.applied) == 1, "First removal consumed the wrong number of choices.")
	await _reload_pending("remove", 2, 1)
	screen = _screen()
	await _select_copy(screen, BEE, false, 1)
	_expect(not bool(screen.before_face._card.get("upgraded", false)), "Normal copy selection previewed an upgraded copy.")
	await _confirm_once(screen)
	_expect(int(main.run.deck[BEE]) == 2 and int(main.run.card_upgrades[BEE]) == 1, "Removing a normal copy discarded an upgrade.")
	screen = _screen()
	await _select_copy(screen, BEE, false, 1)
	await _confirm_once(screen)
	_expect(main.route_run_service.deck_total(main.run.deck) == 2 and int(main.run.deck[BEE]) == 1 and int(main.run.card_upgrades[BEE]) == 1, "Removal prize did not remove exactly three selected copies.")
	_expect(main.run.collection == main.run.deck, "Removed copies remain in the locked collection.")
	_expect(String(main.run.week_transition) == "week_intro" and int(main.run.deckbox_reward.applied) == 3 and int(main.run.deckbox_reward.remaining) == 0, "Completed removal receipt is incorrect.")
	_verify_resources()
	await _reload_complete(3)

func _verify_upgrades() -> void:
	await _stage({BEE: 3, MEAL: 1}, {BEE: 1}, "chefs_edge")
	var screen = _screen()
	_expect(int(main.run.deckbox_reward.remaining) == 2, "Upgrade reward did not offer two choices.")
	for entry in screen.browser.entries:
		_expect(not bool(entry.card.get("upgraded", false)), "Upgrade browser included an already upgraded copy.")
	await _select_copy(screen, BEE, false, 1)
	var previews: Array = screen.find_child("DeckboxRewardPreview", true, false).find_children("InspectedCardFace", "", true, false)
	_expect(previews.size() == 2, "Upgrade reward has no before/after card preview.")
	_expect(not bool(previews[0]._card.get("upgraded", false)) and bool(previews[1]._card.get("upgraded", false)), "Upgrade comparison does not show the permanent stat change.")
	_expect(int(previews[1]._card.attack) > int(previews[0]._card.attack), "Upgrade comparison did not increase the printed attack.")
	for face in previews:
		_expect(face._runtime_face.card_border_color.is_equal_approx(PALETTE.card_border_color("blue")), "Upgrade comparison lost the selected Blue border.")
	await _confirm_once(screen)
	_expect(int(main.run.card_upgrades[BEE]) == 2 and int(main.run.deckbox_reward.remaining) == 1, "First upgrade did not upgrade exactly one normal copy.")
	await _reload_pending("upgrade", 1, 1)
	screen = _screen()
	await _select_copy(screen, BEE, false, 2)
	await _confirm_once(screen)
	_expect(int(main.run.card_upgrades[BEE]) == 3 and int(main.run.deck[BEE]) == 3, "Second upgrade did not select a separate copy of the same card.")
	_expect(main.route_run_service.deck_total(main.run.deck) == 4, "Upgrade prize changed deck size.")
	_expect(String(main.run.week_transition) == "week_intro" and int(main.run.deckbox_reward.applied) == 2 and int(main.run.deckbox_reward.remaining) == 0, "Completed upgrade receipt is incorrect.")
	_verify_resources()
	await _reload_complete(2)

func _verify_single_card_floor() -> void:
	await _stage({BEE: 1}, {}, "loyal_regular")
	_expect(String(main.run.week_transition) == "week_intro" and int(main.run.deckbox_reward.applied) == 0, "A one-card deck was forced into impossible removal choices.")
	_expect(main.route_run_service.deck_total(main.run.deck) == 1, "Removal prize discarded the last card.")
	_verify_resources()

func _select_copy(screen, id: String, upgraded: bool, expected_index: int) -> void:
	var selected: Dictionary = {}
	for entry in screen.browser.displayed_entries:
		if String(entry.id) == id and bool(entry.card.get("upgraded", false)) == upgraded:
			selected = entry
			break
	_expect(not selected.is_empty() and int(selected.copy_index) == expected_index, "Grouped browser selected the wrong copy index.")
	var tile := screen.browser.grid.find_child("DeckboxRewardCard_%s_%d" % [id, expected_index], false, false) as Control
	_expect(tile != null, "Selectable card tile missing.")
	screen.browser.scroll.ensure_control_visible(tile)
	await _frames(2)
	var face := tile.get_child(0) as Control
	_click(face)
	await _frames(2)
	_expect(not screen._selection.is_empty() and int(screen._selection.copy_index) == expected_index and bool(screen._selection.card.get("upgraded", false)) == upgraded, "Pointer selection did not reach the requested card copy.")
	_expect(not screen.find_child("DeckboxRewardConfirm", true, false).disabled, "Selected card cannot be confirmed.")

func _confirm_once(screen) -> void:
	var entry: Dictionary = screen._selection.duplicate(true)
	var confirm := screen.find_child("DeckboxRewardConfirm", true, false) as Button
	confirm.pressed.emit()
	var after: Dictionary = main.run.duplicate(true)
	# Queueing twice on the outgoing screen must never apply another copy.
	confirm.pressed.emit()
	screen.card_confirmed.emit(entry)
	_expect(main.run == after, "Outgoing screen accepted a duplicate card confirmation.")
	await _frames(5)

func _reload_pending(kind: String, remaining: int, applied: int) -> void:
	var screen = _screen()
	screen.find_child("DeckboxRewardSave", true, false).pressed.emit()
	main._load_run_from_disk()
	await _frames(5)
	_expect(String(main.run.week_transition) == "deckbox_reward" and main.current_screen == "week_transition", "Reload skipped unfinished deckbox choices.")
	_expect(String(main.run.deckbox_reward.kind) == kind and int(main.run.deckbox_reward.remaining) == remaining and int(main.run.deckbox_reward.applied) == applied, "Reload duplicated or lost a claimed card reward.")
	_expect(_screen().find_child("DeckboxRewardProgress", true, false).text.begins_with("%d remaining" % remaining), "Reloaded screen shows the wrong remaining reward count.")
	var before: Dictionary = main.run.duplicate(true)
	main._start_demo_week_two()
	_expect(main.run == before and int(main.run.week) == 1, "Week two started before finishing deckbox card choices.")
	_verify_resources()

func _reload_complete(applied: int) -> void:
	main._save_run()
	main._load_run_from_disk()
	await _frames(5)
	_expect(String(main.run.week_transition) == "week_intro" and int(main.run.deckbox_reward.applied) == applied and int(main.run.deckbox_reward.remaining) == 0, "Reload reopened a completed deckbox reward.")
	_expect(_find_screen() == null, "Completed card choice screen remained mounted.")

func _verify_resources() -> void:
	_expect(int(main.run.money) == 17 and int(main.run.life) == 23, "Free card prize changed money or life.")
	_expect(bool(main.run.hub_break_used) == services_were_used and String(main.run.hub_break_choice) == ("heal" if services_were_used else ""), "Deckbox prize reset or consumed the weekly bye.")
	_expect(main.run.hub_shop == {"upgrade_purchased": services_were_used, "remove_purchased": services_were_used}, "Deckbox prize changed the paid shop services.")

func _screen():
	var screen = _find_screen()
	_expect(screen != null, "Deckbox card reward screen is missing.")
	return screen

func _find_screen():
	for child in main.content.get_children():
		if child.get_script() == REWARD_SCREEN and not child.is_queued_for_deletion():
			return child
	return null

func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _frames(count: int) -> void:
	for unused in range(count):
		await process_frame

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
