extends SceneTree

# Keep normal automated setup quiet, but exercise the real frame-driven flight
# for claims. This catches timing and interruption bugs that instant tests miss.
class AnimatedMain:
	extends "res://scripts/Main.gd"
	var animate_claims := false
	func _running_automated_test() -> bool:
		return not animate_claims

var _failures: Array[String] = []
var _main: AnimatedMain
var _offers: Array[String] = []
var _save_path := "/private/tmp/locals-reward-deck-flight-%d.json" % OS.get_process_id()
const CAPTURE_DIR := "res://outputs/reward_deck_flight_2026-09-11"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_main = AnimatedMain.new()
	root.add_child(_main)
	_main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(4)
	_main.run_state_service.save_path = _save_path
	_offers = _main.route_run_service.generate_reward_offer("spicy", "final_boss", 13579)

	await _prepare(3)
	var initial_count: int = _main._deck_total(_main.run.deck)
	var first_id := String(_main.run.reward_offer.front())
	var stack := _stack()
	_expect(stack != null and stack.is_visible_in_tree(), "The pack has no visible destination deck.")
	if stack == null:
		_finish()
		return
	_expect(int(stack.get("card_count")) == initial_count, "Visible deck count does not match the run before claiming.")
	_expect(root.get_visible_rect().encloses(stack.get_global_rect()), "Visible destination deck is clipped at 1280×720.")
	await _capture("01_pack_with_deck")
	_main.animate_claims = true
	_main._pick_route_reward(first_id)
	_expect(_main.route_reward_collecting and _main.current_screen == "route_reward", "A claim did not keep the pack open during travel.")
	_expect(_main._deck_total(_main.run.deck) == initial_count + 1, "A claim did not commit exactly one card before travel.")
	var saved: Dictionary = _main.run_state_service.load_run()
	_expect(bool(saved.get("ok", false)) and _main._deck_total(saved.get("run", {}).get("deck", {})) == initial_count + 1, "The new card was not saved before its animation.")
	_expect(not saved.get("run", {}).get("reward_offer", []).has(first_id), "The saved pack can re-award the card in flight.")
	_main._pick_route_reward(first_id)
	_main._add_all_route_rewards()
	_main._finish_route_reward()
	_expect(_main._deck_total(_main.run.deck) == initial_count + 1 and _main.run.reward_offer.size() == 2 and _main.current_screen == "route_reward", "Direct duplicate, Add All or Continue callbacks changed state during a flight.")
	for name in ["RouteRewardAddAllButton", "RouteRewardSkipButton"]:
		var button := _main.find_child(name, true, false) as Button
		_expect(button != null and button.disabled, "A reward action can interrupt a card in flight.")
	await create_timer(0.20).timeout
	var flight := _main.find_child("RewardCardFlight_%s" % first_id, true, false) as Control
	_expect(flight != null and flight.is_visible_in_tree(), "No actual card face travels into the deck.")
	_expect(int(stack.get("card_count")) == initial_count, "The visible deck counted the new card before it arrived.")
	if flight != null:
		_expect(String(flight.get_parent().name) == "RouteRewardCollectionLayer", "The flight remains clipped inside the card scroll region.")
		_expect(String(flight.get_meta("card_id", "")) == first_id, "The flight displays a different card from the selected reward.")
		var landing: Rect2 = stack.call("get_landing_rect_global")
		var initial_distance := flight.get_global_rect().get_center().distance_to(landing.get_center())
		await _capture("02_card_in_flight")
		await create_timer(0.13).timeout
		if is_instance_valid(flight):
			var remaining_distance := flight.get_global_rect().get_center().distance_to(landing.get_center())
			_expect(remaining_distance < initial_distance, "The selected face is not moving toward the visible deck.")
		var sleeve_deadline := Time.get_ticks_msec() + 800
		while is_instance_valid(flight) and not (flight.get_node("SleevedCardBack") as Control).visible and Time.get_ticks_msec() < sleeve_deadline:
			await process_frame
		await create_timer(0.045).timeout
		if is_instance_valid(flight):
			await _capture("03_card_turns_to_sleeve")
	await _wait_for_collection()
	_expect(_main.current_screen == "route_reward" and _main.run.reward_offer.size() == 2, "Taking one card incorrectly completed the pack.")
	_expect(_main.find_child("RewardCardFlight_%s" % first_id, true, false) == null, "A flight face remained after arrival.")
	_check_collected_absent(first_id)
	_expect(int(stack.get("card_count")) == initial_count + 1, "The destination deck did not receive the new card.")
	_expect(_main.find_child("RewardClaimedStamp", true, false) == null, "The old IN YOUR DECK stamp remains on the pack screen.")
	await _capture("04_card_received")

	# Add remaining must commit once, then hold the screen until every face lands.
	_main._add_all_route_rewards()
	_expect(_main.route_reward_collecting and _main.current_screen == "route_reward", "Add remaining left before cards could travel.")
	_expect(_main._deck_total(_main.run.deck) == initial_count + 3 and _main.run.reward_offer.is_empty(), "Add remaining did not commit the whole remaining pack exactly once.")
	await create_timer(0.16).timeout
	_expect(_main.current_screen == "route_reward", "Add remaining advanced while cards were still in flight.")
	await _capture("05_add_remaining_flight")
	await _wait_for_collection()
	_expect(_main.current_screen == "route_hub" and _main.run.pending_route_node.is_empty(), "Add remaining did not complete the reward after all arrivals.")

	# A scrolled boss pack exercises offscreen origins and a longer cascade.
	await _prepare(8)
	var scroll := _main.find_child("RouteRewardCardScroll", true, false) as ScrollContainer
	var last_button := _main.find_child("RouteRewardCardButton_%s" % String(_main.run.reward_offer.back()), true, false) as Button
	scroll.ensure_control_visible(last_button)
	await _frames(4)
	_expect(scroll.scroll_vertical > 0, "The eight-card fixture did not exercise a scrolled pack.")
	await _capture("07_eight_card_pack_scrolled")
	initial_count = _main._deck_total(_main.run.deck)
	_main.animate_claims = true
	_main._add_all_route_rewards()
	var collection_layer := _main.find_child("RouteRewardCollectionLayer", true, false) as Control
	_expect(collection_layer != null and collection_layer.get_child_count() == 8, "Add All did not create one flight for each card in a scrolled boss pack.")
	_expect(_main._deck_total(_main.run.deck) == initial_count + 8, "The eight-card cascade did not commit exactly eight cards.")
	await create_timer(0.26).timeout
	_expect(_main.current_screen == "route_reward" and _main.route_reward_collecting, "The eight-card pack closed before its offscreen cards arrived.")
	if is_instance_valid(collection_layer):
		for moving_card in collection_layer.get_children():
			if moving_card.is_visible_in_tree():
				_expect(root.get_visible_rect().has_point(moving_card.get_global_rect().get_center()), "A boss-pack card travelled outside the window instead of emerging from the visible pack.")
	await _capture("08_eight_card_add_all_flight")
	await _wait_for_collection()
	_expect(_main.current_screen == "route_hub" and _main._deck_total(_main.run.deck) == initial_count + 8, "The scrolled boss-pack cascade failed to complete exactly once.")

	# Rebuilding/reloading during travel must cancel only visuals, not the save.
	await _prepare(3)
	initial_count = _main._deck_total(_main.run.deck)
	first_id = String(_main.run.reward_offer.front())
	_main.animate_claims = true
	_main._pick_route_reward(first_id)
	await create_timer(0.08).timeout
	var old_generation: int = _main.route_reward_collection_generation
	_main.animate_claims = false
	_main._load_run_from_disk()
	await _frames(6)
	_expect(_main.route_reward_collection_generation != old_generation and not _main.route_reward_collecting, "Reload did not invalidate the interrupted collection.")
	_expect(_main._deck_total(_main.run.deck) == initial_count + 1 and _main.run.reward_offer.size() == 2, "Reload lost or duplicated a card that was in flight.")
	_check_collected_absent(first_id)
	await create_timer(0.7).timeout
	_expect(_main.current_screen == "route_reward" and _main.run.reward_offer.size() == 2, "An old animation completed or changed the reloaded pack.")
	_expect(int(_stack().get("card_count")) == initial_count + 1, "Reload did not restore the visible deck count.")

	# An exhausted pack saved during the last flight resumes at its destination.
	await _prepare(1)
	initial_count = _main._deck_total(_main.run.deck)
	first_id = String(_main.run.reward_offer.front())
	_main.animate_claims = true
	_main._pick_route_reward(first_id)
	_expect(_main.route_reward_collecting and _main.current_screen == "route_reward", "The final individual card skipped its flight.")
	await create_timer(0.08).timeout
	_main.animate_claims = false
	_main._load_run_from_disk()
	await _frames(6)
	_expect(_main.current_screen == "route_hub" and _main.run.pending_route_node.is_empty(), "Reloading an exhausted pack stranded the run at an empty reward.")
	_expect(_main._deck_total(_main.run.deck) == initial_count + 1, "Reloading the final in-flight card changed the saved deck.")
	await create_timer(0.7).timeout
	_expect(int(_main.run.hub_round) == 2, "An interrupted last-card flight completed the round twice.")

	# Reduced Motion keeps the same destination and count with no travel delay.
	await _prepare(3)
	_main.player_settings.reduced_motion = true
	_main.animate_claims = true
	initial_count = _main._deck_total(_main.run.deck)
	first_id = String(_main.run.reward_offer.front())
	_main._pick_route_reward(first_id)
	await _frames(3)
	_expect(not _main.route_reward_collecting and _main.current_screen == "route_reward", "Reduced Motion introduced a travel wait or skipped the remaining pack.")
	_expect(int(_stack().get("card_count")) == initial_count + 1, "Reduced Motion did not update the visible deck.")
	_check_collected_absent(first_id)
	await _capture("06_reduced_motion_received")
	_finish()


func _prepare(count: int) -> void:
	_main.animate_claims = false
	_main.autosave_enabled = false
	# Each fixture starts after the previous match's brief shop toast has ended.
	for feedback in get_nodes_in_group("ui_feedback"):
		feedback.queue_free()
	_main.player_settings.reduced_motion = false
	_main.player_settings.text_scale = 1.0
	var deck: Dictionary = _main._deck_entries_to_dict(_main.archetypes_by_id.spicy.starterDeck)
	_main.run = _main.run_state_service.create_run("spicy", deck, "hearty", "season", "blue")
	_main.route_run_service.initialize_run(_main.run, 13579)
	_main.run.pending_route_node = _main._hub_round_node(1)
	_main.run.reward_offer = _offers.slice(0, count)
	_main.run.reward_picks_remaining = count
	_main.run.reward_selected = []
	_main.run.route_pack_presented = true
	_main.run.route_pack_opened = true
	_main._show_route_card_reward()
	await _frames(6)
	_main.autosave_enabled = true


func _stack() -> Control:
	return _main.find_child("RouteRewardDeckStack", true, false) as Control


func _check_collected_absent(card_id: String) -> void:
	var choice := _main.find_child("RouteReward_%s" % card_id, true, false) as Control
	_expect(choice == null or not choice.is_visible_in_tree(), "A collected card remains on the cloth: %s." % card_id)


func _wait_for_collection() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while _main.route_reward_collecting and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not _main.route_reward_collecting, "Card collection did not finish within three seconds.")
	await _frames(3)


func _frames(count: int) -> void:
	for unused in range(count):
		await process_frame
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [CAPTURE_DIR, filename])) == OK, "Could not capture %s." % filename)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	_main.autosave_enabled = false
	_main.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save_path + suffix):
			DirAccess.remove_absolute(_save_path + suffix)
	if _failures.is_empty():
		print("Reward deck flight smoke test passed: saved claims, real travel, Add All, interruption, exhausted reload and Reduced Motion.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
