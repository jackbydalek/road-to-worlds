extends SceneTree

var _failures: Array[String] = []
var _all_offers: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.autosave_enabled = false
	main.run_state_service.save_path = "/private/tmp/locals-reward-layout-save.json"
	main.player_settings.reduced_motion = true
	_all_offers = main.route_run_service.generate_reward_offer("spicy", "final_boss", 13579)
	for card in main.cards:
		if _all_offers.size() >= 12:
			break
		if not _all_offers.has(String(card.id)) and main.shop_economy_service.card_is_starter_eligible(card, "spicy"):
			_all_offers.append(String(card.id))
	for viewport_size in [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(1728, 1117)]:
		root.size = viewport_size
		for count in [3, 5, 8, 12]:
			_prepare(main, count)
			await _settle()
			_check_actions(main, "%d cards at %s" % [count, viewport_size])
			if count in [3, 5, 8] and viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
				var initial_scroll := main.find_child("RouteRewardCardScroll", true, false) as ScrollContainer
				_expect(initial_scroll.scroll_vertical == 0, "A fresh reward pack opened scrolled past its first row.")
				await _capture("reward_initial_%d_%dx%d" % [count, viewport_size.x, viewport_size.y])
			var scroll := main.find_child("RouteRewardCardScroll", true, false) as ScrollContainer
			var last_id := String(main.run.reward_offer.back())
			var select := main.find_child("RouteRewardCardButton_%s" % last_id, true, false) as Button
			scroll.ensure_control_visible(select)
			await _settle()
			_click(select)
			await _settle()
			var add := main.find_child("RouteRewardAddButton_%s" % last_id, true, false) as Button
			_expect(add.visible and scroll.get_global_rect().encloses(add.get_global_rect()), "The last card's Add to Deck is clipped with %d cards at %s." % [count, viewport_size])
			_check_actions(main, "scrolled %d-card pack" % count)
			if count == 8:
				await _capture("reward_layout_8_%dx%d" % [viewport_size.x, viewport_size.y])
			elif count in [3, 5] and viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
				await _capture("reward_layout_%d_%dx%d" % [count, viewport_size.x, viewport_size.y])
			elif count == 12 and viewport_size == Vector2i(1280, 720):
				await _capture("reward_layout_12_1280x720")
			# Tabbing from Skip must return to a card in this modal and scroll to it.
			var skip := main.find_child("RouteRewardSkipButton", true, false) as Button
			skip.grab_focus()
			var tab := InputEventKey.new()
			tab.keycode = KEY_TAB
			tab.pressed = true
			root.push_input(tab, true)
			await _settle()
			var focused := root.gui_get_focus_owner()
			_expect(focused != null and String(focused.name).begins_with("RouteRewardCardButton_") and scroll.get_global_rect().encloses(focused.get_global_rect()), "Keyboard focus escaped the reward or stayed outside its scroll viewport.")

	# Reproduce the screenshot: an eight-card boss pack reduced to five.
	root.size = Vector2i(1728, 1117)
	_prepare(main, 8)
	await _settle()
	var overlay := main.find_child("RouteRewardOverlay", true, false)
	var fan := main.find_child("RouteRewardFan", true, false) as Control
	var starting_deck: int = main._deck_total(main.run.deck)
	for unused in range(3):
		var card_id := String(main.run.reward_offer.back())
		var select := main.find_child("RouteRewardCardButton_%s" % card_id, true, false) as Button
		var scroll := main.find_child("RouteRewardCardScroll", true, false) as ScrollContainer
		scroll.ensure_control_visible(select)
		await _settle()
		_click(select)
		await _settle()
		_click(main.find_child("RouteRewardAddButton_%s" % card_id, true, false))
		await _settle()
		_check_actions(main, "after taking one card")
	_expect(main.run.reward_offer.size() == 5 and main._deck_total(main.run.deck) == starting_deck + 3, "Individual Add to Deck clicks did not collect exactly three cards.")
	_expect(main.find_child("RouteRewardOverlay", true, false) == overlay and main.find_child("RouteRewardFan", true, false) == fan, "Picking cards rebuilt the live reward overlay.")
	for claimed_id in main.run.reward_selected:
		var claimed_choice := main.find_child("RouteReward_%s" % claimed_id, true, false) as Control
		var claimed_add := main.find_child("RouteRewardAddButton_%s" % claimed_id, true, false) as Button
		_expect(claimed_choice == null or not claimed_choice.is_visible_in_tree(), "A collected card remained on the reward cloth after entering the deck.")
		_expect(claimed_add == null or claimed_add.disabled, "A collected card can be added twice.")
		main._pick_route_reward(String(claimed_id))
	_expect(main._deck_total(main.run.deck) == starting_deck + 3, "A duplicate claim added another copy.")
	_expect((main.find_child("RouteRewardDeckCount", true, false) as Label).text == "%d → %d cards" % [starting_deck, starting_deck + 3], "The receipt did not show the pack's actual deck growth.")
	var saved: Dictionary = main.run_state_service.save_run(main.run, "route_reward")
	_expect(bool(saved.get("ok", false)), "Could not save a partial reward pack.")
	var restored: Dictionary = main.run_state_service.load_run()
	_expect(bool(restored.get("ok", false)), "Could not reload a partial reward pack.")
	main.run = restored.run
	main._show_route_card_reward()
	await _settle()
	for claimed_id in main.run.reward_selected:
		var restored_choice := main.find_child("RouteReward_%s" % claimed_id, true, false) as Control
		_expect(restored_choice == null or not restored_choice.is_visible_in_tree(), "Reopening a partial pack returned a collected card to the reward cloth.")
	await _capture("reward_layout_8_to_5")
	_click(main.find_child("RouteRewardAddAllButton", true, false))
	await _settle()
	_expect(main._deck_total(main.run.deck) == starting_deck + 8 and main.run.reward_offer.is_empty(), "Add All could not collect the remaining cards.")
	_prepare(main, 12)
	await _settle()
	starting_deck = main._deck_total(main.run.deck)
	_click(main.find_child("RouteRewardSkipButton", true, false))
	await _settle()
	_expect(main.run.reward_offer.is_empty() and main._deck_total(main.run.deck) == starting_deck, "Skip could not dismiss an oversized pack without adding cards.")
	root.size = Vector2i(1280, 720)
	for text_scale in [1.25, 1.5]:
		main.player_settings.text_scale = text_scale
		for count in [3, 5, 8]:
			_prepare(main, count)
			await _settle()
			_check_actions(main, "%d%% text, %d cards" % [roundi(text_scale * 100), count])
			var scroll := main.find_child("RouteRewardCardScroll", true, false) as ScrollContainer
			var last_id := String(main.run.reward_offer.back())
			main._select_route_reward_card(last_id)
			await _settle()
			var add := main.find_child("RouteRewardAddButton_%s" % last_id, true, false) as Button
			_expect(scroll.get_global_rect().encloses(add.get_global_rect()), "Large text clipped the selected card action.")
			await _capture("reward_large_text_%d_%d_1280x720" % [roundi(text_scale * 100), count])
	_prepare(main, 3)
	await _settle()
	main._pick_route_reward(String(main.run.reward_offer.front()))
	await _settle()
	await _capture("reward_claimed_3_1280x720")
	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Route reward layout smoke test passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _prepare(main: Node, count: int) -> void:
	var deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	main.run = main.run_state_service.create_run("spicy", deck, "hearty", "season", "white")
	main.route_run_service.initialize_run(main.run, 13579)
	main.run.life = 18
	main.run.hub_round = 4
	main.run.pending_route_node = main._hub_round_node(4)
	main.run.reward_offer = _all_offers.slice(0, count)
	main.run.reward_picks_remaining = count
	main.run.reward_selected = []
	main.selected_route_reward_card_id = ""
	main._show_route_card_reward()


func _check_actions(main: Node, context: String) -> void:
	var viewport_rect := root.get_visible_rect()
	for button in main.route_reward_overlay.find_children("RouteRewardAddButton_*", "Button", true, false):
		var card_id := String(button.get_parent().get_meta("card_id", ""))
		var selected: bool = card_id == main.selected_route_reward_card_id
		_expect(button.visible == selected and button.disabled != selected, "An individual Add action was available without its card being selected: %s." % context)
	var deck := main.find_child("RouteRewardDeckStack", true, false) as Control
	_expect(deck != null and deck.is_visible_in_tree() and viewport_rect.encloses(deck.get_global_rect()), "The destination deck is missing or clipped: %s." % context)
	for name in ["RouteRewardAddAllButton", "RouteRewardSkipButton"]:
		var button := main.find_child(name, true, false) as Button
		_expect(button != null and button.is_visible_in_tree() and not button.disabled and viewport_rect.encloses(button.get_global_rect()), "%s is clipped or disabled: %s." % [name, context])
		_expect(button.get_global_rect().size.y * root.size.y / viewport_rect.size.y >= 44.0, "%s is too small: %s." % [name, context])
		var scroll := main.find_child("RouteRewardCardScroll", true, false) as Control
		_expect(button.get_global_rect().position.y >= scroll.get_global_rect().end.y, "The reward actions overlap the scrolling cards.")
		if deck != null:
			_expect(not deck.get_global_rect().intersects(button.get_global_rect()), "The destination deck overlaps %s: %s." % [name, context])


func _click(control: Control) -> void:
	if control == null:
		_failures.append("Missing click target.")
		return
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func _settle() -> void:
	for unused in range(8):
		await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)
	var capture_dir := "res://outputs/reward_deck_flight_2026-09-11/layout"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [capture_dir, filename])) == OK, "Could not save reward layout capture.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
