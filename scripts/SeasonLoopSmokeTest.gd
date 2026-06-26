extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	main._show_season_run_setup()
	await process_frame
	main._confirm_season_run_setup()
	await process_frame
	await process_frame

	if main.current_screen != "season":
		_fail("Season loop smoke did not start on the season hub.")
		return

	var next_step := _find_node_by_name(main, "SeasonHubNextStepButton") as Button
	if next_step == null or next_step.text != "Register":
		_fail("Season loop smoke did not point the first hub next step at registration.")
		return
	next_step.emit_signal("pressed")
	await process_frame

	if main.current_screen != "tournament":
		_fail("Season loop smoke did not open tournament registration from the hub CTA.")
		return
	var enter := _find_button_with_prefix(main, "Enter Weekly Locals")
	if enter == null or enter.disabled:
		_fail("Season loop smoke could not enter Weekly Locals.")
		return
	enter.emit_signal("pressed")
	await process_frame

	for round_index in range(3):
		if main.current_screen != "ui_combat":
			_fail("Season loop smoke did not reach UI Combat for round %d." % (round_index + 1))
			return
		_force_live_round_result(main, true)
		main._season_record_current_round_result()
		await process_frame
		if round_index < 2:
			if main.current_screen != "tournament":
				_fail("Season loop smoke did not return to tournament progress after round %d." % (round_index + 1))
				return
			main._start_season_tournament_round()
			await process_frame

	if main.current_screen != "result":
		_fail("Season loop smoke did not show the event result after Weekly Locals.")
		return
	if int(main.run.get("prize_packs", 0)) != 1:
		_fail("Season loop smoke did not award exactly one prize pack for a 3-0 Weekly Locals.")
		return
	var primary := _find_node_by_name(main, "SeasonResultPrimaryAction") as Button
	if primary == null or not String(primary.text).begins_with("Open Prize Packs"):
		_fail("Season loop smoke did not make prize packs the result primary action.")
		return
	primary.emit_signal("pressed")
	await process_frame
	await process_frame

	if main.current_screen != "packs":
		_fail("Season loop smoke did not enter the pack opening screen from rewards.")
		return
	if main.run.current_pack.size() != 3:
		_fail("Season loop smoke did not start a 3-card prize pack.")
		return

	var pack_button := _find_node_by_name(main, "PackButton") as TextureButton
	if pack_button == null:
		_fail("Season loop smoke did not render the reward pack button.")
		return
	pack_button.emit_signal("pressed")
	await create_timer(0.45).timeout

	var reveal_all := _find_node_by_name(main, "RevealAllButton") as Button
	if reveal_all == null:
		_fail("Season loop smoke did not render Reveal All for the prize pack.")
		return
	reveal_all.emit_signal("pressed")
	await process_frame
	await process_frame

	if int(main.run.get("pack_index", 0)) != 3:
		_fail("Season loop smoke did not reveal all three prize cards.")
		return

	var done := _find_node_by_name(main, "DoneButton") as Button
	if done == null or not done.visible:
		_fail("Season loop smoke did not show Done after the prize pack.")
		return
	done.emit_signal("pressed")
	await process_frame
	await process_frame

	if main.current_screen != "shop":
		_fail("Season loop smoke did not return to the card shop after finishing the pack.")
		return
	if not main.run.get("current_pack", []).is_empty():
		_fail("Season loop smoke did not clear completed pack state.")
		return

	var deck_box := _find_node_by_name(main, "DeckBoxButton") as Button
	if deck_box == null:
		_fail("Season loop smoke did not render the deck box from the shop.")
		return
	main._show_deckbuilder()
	await process_frame
	await process_frame
	if main.current_screen != "deck":
		_fail("Season loop smoke did not enter the deckbuilder from the shop.")
		return

	main._show_season_run()
	await process_frame
	if String(main.run.get("selected_event_id", "")) != "monthly_regionals":
		_fail("Season loop smoke did not advance to Monthly Regionals after clearing Weekly Locals.")
		return
	if int(main.run.get("calendar_unlocked_index", 0)) < 1:
		_fail("Season loop smoke did not unlock the next calendar event.")
		return
	var final_next_step := _find_node_by_name(main, "SeasonHubNextStepButton") as Button
	if final_next_step == null or final_next_step.text != "Register":
		_fail("Season loop smoke did not point the post-pack hub next step at the next registration.")
		return
	main.run.money = 0
	main._show_season_run()
	await process_frame
	var work_step := _find_node_by_name(main, "SeasonHubNextStepButton") as Button
	if work_step == null or work_step.text != "Work Shop Shift":
		_fail("Season loop smoke did not offer a shop shift when the next entry fee was unaffordable.")
		return
	work_step.emit_signal("pressed")
	await process_frame
	await process_frame
	var regional_entry: int = int(main._selected_season_event().get("entryFee", 0))
	if int(main.run.get("money", 0)) != regional_entry:
		_fail("Season loop smoke shop shift did not grant exactly the missing entry fee.")
		return
	var register_after_work := _find_node_by_name(main, "SeasonHubNextStepButton") as Button
	if register_after_work == null or register_after_work.text != "Register":
		_fail("Season loop smoke did not return to Register after the shop shift covered entry.")
		return

	print("Season loop smoke covered hub CTA, tournament, result rewards, prize pack, deckbuilder, and next event unlock.")
	quit(0)


func _force_live_round_result(main, player_won: bool) -> void:
	main.run.manual_combat["game_over"] = true
	main.run.manual_combat["winner"] = "player" if player_won else "opponent"
	main.run.manual_combat["phase"] = "game_over"
	main.run.manual_combat["turn"] = max(1, int(main.run.manual_combat.get("turn", 1)))
	main.run.manual_combat["player"]["life"] = 12 if player_won else 0
	main.run.manual_combat["opponent"]["life"] = 0 if player_won else 12


func _find_button_with_prefix(node: Node, text_prefix: String) -> Button:
	if node is Button and String((node as Button).text).begins_with(text_prefix):
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_prefix(child, text_prefix)
		if found != null:
			return found
	return null


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
