extends SceneTree
## Committed game actions, rather than playback helpers, select the cozy cues.

class CueSpy extends Node:
	var calls: Array[String] = []
	func play_transition() -> void: calls.append("transition")
	func play_popup() -> void: calls.append("popup")
	func play_popup_close() -> void: calls.append("popup_close")
	func play_confirm() -> void: calls.append("confirm")
	func play_cancel() -> void: calls.append("cancel")
	func play_success() -> void: calls.append("success")
	func play_error() -> void: calls.append("error")
	func play_purchase() -> void: calls.append("purchase")
	func play_remove() -> void: calls.append("remove")
	func play_upgrade() -> void: calls.append("upgrade")
	func play_heal() -> void: calls.append("heal")
	func play_result(won: bool) -> void: calls.append("win" if won else "loss")
	func play_shop_focus(view: String) -> void: calls.append("focus:" + view)
	func play_shop_bell() -> void: calls.append("bell")
	func count(cue: String) -> int: return calls.count(cue)

var errors: Array[String] = []
var main
var spy: CueSpy


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	main.autosave_suspended = true
	main.autosave_enabled = false
	root.add_child(main)
	await _settle()
	main.autosave_enabled = false
	main.run_state_service.save_path = "/private/tmp/locals-cozy-audio-flow-%d.json" % OS.get_process_id()
	main.player_settings.reduced_motion = true
	main.ui_sound_controller.enabled = false
	spy = CueSpy.new()
	spy.name = "CommittedAudioCueSpy"
	main.add_child(spy)
	main.ui_sound_controller = spy
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 20260908)
	main.run.money = 100
	main.run.life = 28

	main._show_tournament_hub()
	await _settle()
	_expect(spy.count("bell") == 1, "Entering the shop from the title did not ring the original bell exactly once.")
	main._show_tournament_hub()
	_expect(spy.count("bell") == 1, "Redrawing the same shop rang its entry bell again.")
	for view in ["counter", "seller", "machine"]:
		main._open_hub_view(view)
		_expect(spy.count("focus:" + view) == 1, "Opening %s did not select its focus cue exactly once." % view)
		main._open_hub_view(view)
		main._show_route_shop()
		_expect(spy.count("focus:" + view) == 1, "Redrawing %s replayed a focus cue." % view)
		_expect(spy.count("bell") == 1, "Focusing %s incorrectly replayed the shop door bell." % view)
	await _settings_round_trip()
	_expect(main.current_screen == "route_shop" and main.run.pending_route_node.hub_view == "machine", "Settings did not restore the focused machine.")
	_expect(spy.count("bell") == 1 and spy.count("focus:machine") == 1, "Settings return replayed the shop entry or focus cue.")
	main._leave_hub_shop()
	_expect(spy.count("popup_close") == 1 and spy.count("bell") == 1, "Back did not close quietly without another entry bell.")
	main._leave_hub_shop()
	_expect(spy.count("popup_close") == 1, "A second Back after leaving the close-up replayed its cue.")
	await _settings_round_trip()
	_expect(main.current_screen == "route_hub" and spy.count("bell") == 1, "Returning from overview settings rang the door bell again.")

	main._open_hub_view("counter")
	var card_id := String(main.run.pending_route_node.inventory[0])
	var starting_money: int = main.run.money
	var starting_count: int = main.run.deck.get(card_id, 0)
	await main._route_shop_buy_card(card_id)
	_expect(spy.count("purchase") == 1 and int(main.run.deck.get(card_id, 0)) == starting_count + 1 and int(main.run.money) < starting_money, "A committed card purchase did not emit exactly one purchase cue.")
	await main._route_shop_buy_card(card_id)
	_expect(spy.count("purchase") == 1, "Buying an already-sold card emitted a success cue.")
	var unaffordable_id := String(main.run.pending_route_node.inventory[0])
	main.run.money = 0
	await main._route_shop_buy_card(unaffordable_id)
	_expect(spy.count("purchase") == 1, "An unaffordable purchase emitted a success cue.")
	main.run.money = 100

	main._open_hub_view("machine")
	main.find_child("TournamentHub", true, false)._snack_view.select_snack("upgrade")
	main._show_hub_break_upgrade()
	await _settle()
	main._close_route_shop_service_overlay()
	_expect(spy.count("upgrade") == 0 and spy.count("heal") == 0 and not main.run.hub_break_used, "Cancelling the machine picker emitted success or spent its use.")
	main.find_child("TournamentHub", true, false)._snack_view.select_snack("heal")
	main._use_hub_break_heal()
	_expect(main.run.life == 33 and main.run.hub_break_used and spy.count("heal") == 1, "The successful machine heal did not emit exactly one heal cue.")
	main._use_hub_break_heal()
	_expect(main.run.life == 33 and spy.count("heal") == 1, "The spent machine emitted another heal cue.")

	main._open_hub_view("seller")
	var upgrade_id := String(main.route_run_service.upgradeable_card_ids(main.run)[0])
	main._show_route_upgrade_card()
	await _settle()
	main._select_route_shop_service_card("upgrade", upgrade_id)
	_expect(spy.count("upgrade") == 0, "Selecting an upgrade emitted success before committing it.")
	main._close_route_shop_service_overlay()
	_expect(spy.count("upgrade") == 0 and main.route_run_service.upgrade_count(main.run, upgrade_id) == 0, "Cancelling an upgrade emitted success or upgraded the card.")
	main._show_route_upgrade_card()
	await _settle()
	main._select_route_shop_service_card("upgrade", upgrade_id)
	starting_money = main.run.money
	await main._route_upgrade_card(upgrade_id)
	await _settle()
	_expect(spy.count("upgrade") == 1 and main.run.money == starting_money - main.route_run_service.SHOP_UPGRADE_COST and main.route_run_service.upgrade_count(main.run, upgrade_id) == 1, "The paid upgrade did not commit once with one upgrade cue.")
	await main._route_upgrade_card(upgrade_id)
	_expect(spy.count("upgrade") == 1, "An already-spent paid upgrade emitted another success cue.")

	var remove_id := String(main.run.deck.keys()[1])
	starting_count = main.run.deck.get(remove_id, 0)
	main._show_route_remove_card()
	await _settle()
	main._select_route_shop_service_card("remove", remove_id)
	_expect(spy.count("remove") == 0, "Selecting a removal emitted success before committing it.")
	main._close_route_shop_service_overlay()
	_expect(spy.count("remove") == 0 and int(main.run.deck.get(remove_id, 0)) == starting_count, "Cancelling removal emitted success or removed a card.")
	main._show_route_remove_card()
	await _settle()
	main._select_route_shop_service_card("remove", remove_id)
	starting_money = main.run.money
	main._route_remove_card(remove_id)
	_expect(spy.count("remove") == 1 and main.run.money == starting_money - main.route_run_service.SHOP_REMOVE_COST and int(main.run.deck.get(remove_id, 0)) == starting_count - 1, "The paid removal did not commit once with one removal cue.")
	main._route_remove_card(remove_id)
	_expect(spy.count("remove") == 1, "An already-spent removal emitted another success cue.")
	_expect(spy.count("bell") == 1, "A purchase, service, picker, or redraw rang the entry bell again.")

	main.run.pending_route_node = {}
	main.current_screen = "kitchen_match"
	main._show_tournament_hub(false)
	_expect(spy.count("bell") == 1, "Building the reward backdrop rang the shop entry bell.")
	main.current_screen = "kitchen_match"
	main.run.route_battle = _battle_fixture()
	main._finish_route_battle(true, 30)
	main._finish_route_battle(true, 30)
	_expect(spy.count("win") == 1 and main.run.route_round_results.size() == 1, "A completed battle emitted duplicate win cues or results.")
	_expect(spy.count("bell") == 1, "Winning rang the shop door while constructing the reward screen.")
	# Prevent the deferred reward presentation from continuing into the next fixture.
	main.current_screen = "kitchen_match"
	main.run.reward_offer = []
	main.run.route_battle = _battle_fixture()
	main._finish_route_battle(false, 0)
	main._finish_route_battle(false, 0)
	_expect(spy.count("loss") == 1 and main.run.route_round_results.size() == 2 and main.run.run_over, "A completed defeat emitted duplicate loss cues or results.")
	await _settle()
	_expect(not FileAccess.file_exists(main.run_state_service.save_path), "The audio flow test wrote an autosave.")
	main._release_audio_streams()
	main.queue_free()
	await _settle()
	for message in errors: push_error(message)
	print("Cozy audio flow smoke test: %d failures (shop entry/focus, settings, committed purchases/services, and guarded results)." % errors.size())
	quit(0 if errors.is_empty() else 1)


func _battle_fixture() -> Dictionary:
	return {"active": true, "node_id": "cozy_audio_test", "node_type": "enemy", "label": "Practice Rival", "opponent_affinity": "hearty", "seed": 904}


func _settings_round_trip() -> void:
	main._show_settings()
	await _settle()
	var back := main.find_child("SettingsBackButton", true, false) as Button
	_expect(back != null, "Settings did not supply its actual Back button.")
	if back != null:
		back.pressed.emit()
	await _settle()


func _settle() -> void:
	for frame in range(4):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		print("FAILED: ", message)
