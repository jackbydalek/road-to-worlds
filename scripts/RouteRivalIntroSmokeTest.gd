extends SceneTree

const CAST := preload("res://scripts/ui/PeachSodaCast.gd")

var _errors: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	for _frame in range(4):
		await process_frame
	main.autosave_enabled = false
	main.run_state_service.save_path = "/private/tmp/route_rival_intro_smoke.json"
	main.player_settings.reduced_motion = true
	main._start_new_run_with_mode("spicy", "season", "white")
	for _frame in range(6):
		await process_frame

	# Current run flow calls the next table from the tournament hub. The old
	# roaming-NPC fixture predates the hub described in CONCEPT_DIRECTION.
	var hub := main.find_child("TournamentHub", true, false) as Control
	var next_round := main.find_child("HubNextRoundButton", true, false) as Button
	_expect(main.current_screen == "route_hub" and hub != null, "New run did not enter the tournament hub.")
	_expect(next_round != null and not next_round.disabled, "The hub has no usable Next Round action.")
	if hub == null or next_round == null:
		await _finish(main)
		return
	var deck_before: Dictionary = main.run.deck.duplicate(true)
	var life_before := int(main.run.life)
	var round_before := int(main.run.hub_round)
	next_round.emit_signal("pressed")
	for _frame in range(4):
		await process_frame

	var portrait := main.find_child("RouteRivalPortrait", true, false) as TextureRect
	var dialogue := main.find_child("RouteRivalDialogueText", true, false) as Label
	var speaker := main.find_child("RouteRivalSpeaker", true, false) as Label
	var continue_button := main.find_child("BeginRouteEncounterButton", true, false) as Button
	var battle: Dictionary = main.run.get("route_battle", {})
	var pending: Dictionary = main.run.get("pending_route_node", {})
	var presentation: Dictionary = main._route_rival_presentation(battle)
	var cast_id := String(presentation.id)
	_expect(main.current_screen == "route_encounter_intro", "Next Round did not open the route-rival intro.")
	_expect(main.find_child("TournamentHub", true, false) == hub, "The rival intro replaced the hub instead of overlaying it.")
	_expect(main.find_child("RouteEncounterDimmer", true, false) != null, "The tournament hub was not dimmed behind the rival.")
	_expect(
		portrait != null and portrait.texture == CAST.texture_for(cast_id),
		"The route intro did not use the called encounter's registry portrait."
	)
	_expect(dialogue != null and not dialogue.text.is_empty(), "The route rival has no dialogue.")
	_expect(speaker != null and speaker.text == CAST.name_for(cast_id), "The introduction name disagrees with its portrait.")
	_expect(continue_button != null and not continue_button.disabled, "The route rival intro has no usable Continue action.")
	_expect(
		String(battle.get("node_id", "")) == String(pending.get("id", ""))
		and bool(pending.get("hub_round_node", false))
		and int(pending.get("hub_round", 0)) == round_before,
		"The introduction does not belong to the round called from the hub."
	)
	_expect(
		String(battle.get("rival_portrait_id", "")) == main._route_rival_portrait_id(String(battle.get("node_type", "enemy")), int(battle.get("seed", 0))),
		"The visual cast mapping rewrote the saved encounter identity."
	)
	_expect(main._route_rival_portrait_id("mini_boss", 1) == "npc2", "The local champion did not keep its legacy NPC 2 identity.")
	_expect(main._route_rival_portrait_id("final_boss", 1) == "npc1", "The city champion did not keep its legacy NPC 1 identity.")
	_expect(main.run.deck == deck_before and int(main.run.life) == life_before and int(main.run.hub_round) == round_before, "Opening the rival introduction changed run progress.")
	if dialogue != null:
		var expected_line: String = main._route_rival_intro_line(String(battle.get("opponent_affinity", "neutral")), String(battle.get("node_type", "enemy")), String(battle.get("rival_portrait_id", "npc1")))
		_expect(dialogue.text == "“%s”" % expected_line, "Cast presentation changed the encounter's dialogue.")
	if continue_button == null or portrait == null:
		await _finish(main)
		return
	var intro_texture := portrait.texture
	_check_authored_portrait(portrait, "rival introduction")

	continue_button.emit_signal("pressed")
	for _frame in range(5):
		await process_frame
	var tabletop = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "kitchen_match" and tabletop != null, "Continue did not launch the route battle.")
	if tabletop == null:
		await _finish(main)
		return
	var opponent_profile := main.find_child("OpponentProfileBadgePortrait", true, false) as TextureRect
	var profile_atlas := opponent_profile.texture as AtlasTexture if opponent_profile != null else null
	_check_authored_portrait(tabletop.rival_at_table, "introduced rival's battle")
	_expect(opponent_profile != null and opponent_profile.material == null, "Portrait styling changed the battle HUD avatar.")
	_expect(
		String(tabletop.configured_match_context.get("rival_portrait_id", "")) == String(main.run.route_battle.get("rival_portrait_id", "")),
		"The legacy route rival portrait ID did not reach the Living Table."
	)
	_expect(
		String(tabletop.configured_match_context.get("rival_cast_id", "")) == cast_id
		and tabletop.opponent_profile_name.text == CAST.name_for(cast_id),
		"The live battle changed the cast introduced at the hub."
	)
	if CAST.has_generated_art(cast_id):
		_expect(profile_atlas != null and profile_atlas.atlas == intro_texture, "The battle profile icon did not use the rival shown in the encounter intro.")
		_expect(tabletop.rival_at_table.texture == intro_texture, "The seated battle illustration disagrees with the intro portrait.")
	else:
		_expect(opponent_profile != null and opponent_profile.texture == CAST.FALLBACK and intro_texture == CAST.FALLBACK, "Art removal fallback disagrees between intro and battle.")
	_expect(main.run.deck == deck_before and int(main.run.life) == life_before and int(main.run.hub_round) == round_before, "Entering the live battle changed persistent run progress before a result.")
	await _test_mina_hub_encounter(main)
	await _finish(main)


func _test_mina_hub_encounter(main) -> void:
	# Exercise the real Top Cut route entry. A portrait-only fixture would miss
	# the former presentation override that silently replaced saved Mina with Bea.
	main._start_new_run_with_mode("spicy", "season", "white")
	main.run.hub_round = 3
	main._show_run_map(false)
	for _frame in range(4):
		await process_frame
	var next_round := main.find_child("HubNextRoundButton", true, false) as Button
	_expect(next_round != null and not next_round.disabled, "Top Cut has no usable hub entry.")
	if next_round == null:
		return
	next_round.emit_signal("pressed")
	for _frame in range(4):
		await process_frame
	var battle: Dictionary = main.run.get("route_battle", {})
	var portrait := main.find_child("RouteRivalPortrait", true, false) as TextureRect
	var speaker := main.find_child("RouteRivalSpeaker", true, false) as Label
	var continue_button := main.find_child("BeginRouteEncounterButton", true, false) as Button
	_expect(String(battle.get("node_type", "")) == "mini_boss" and String(battle.get("label", "")) == "Local Champion Mina", "Top Cut lost Mina's saved encounter identity.")
	_expect(main._route_rival_presentation(battle).id == "mina", "Mina is still replaced by a different presentation character.")
	_expect(speaker != null and speaker.text == "Mina", "Top Cut introduces the wrong visible character name.")
	_expect(portrait != null and portrait.has_method("set_reduced_motion"), "Mina's intro cannot play the supplied character animation.")
	_expect(continue_button != null and not continue_button.disabled, "Mina's introduction blocks the Continue action.")
	if portrait == null or continue_button == null:
		return
	var first_frame := CAST.texture_for("mina")
	_check_authored_portrait(portrait, "supplied Mina introduction")
	_expect(first_frame != CAST.FALLBACK and portrait.texture == first_frame, "The Top Cut intro did not load the supplied Mina artwork.")
	await create_timer(0.25).timeout
	_expect(portrait.texture == first_frame, "Reduced motion did not keep Mina's introduction on a still frame.")
	portrait.call("configure", "mina", false, true)
	_expect(portrait.texture == first_frame, "Disabling generated placeholders also disabled the supplied Mina artwork.")
	portrait.call("set_reduced_motion", false)
	await create_timer(0.12).timeout
	_expect(portrait.texture != first_frame, "Mina's supplied GIF does not advance when motion is enabled.")
	portrait.call("set_reduced_motion", true)
	_expect(portrait.texture == first_frame, "Restoring reduced motion did not return Mina to her still frame.")
	continue_button.emit_signal("pressed")
	for _frame in range(5):
		await process_frame
	var tabletop = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "kitchen_match" and tabletop != null, "Mina's Continue action did not reach a playable battle.")
	if tabletop == null:
		return
	_expect(String(tabletop.configured_match_context.get("rival_cast_id", "")) == "mina" and tabletop.opponent_profile_name.text == "Mina", "The live Top Cut battle replaced the Mina introduced at the hub.")
	_expect(tabletop.rival_at_table.texture == first_frame, "Intro and live battle use different Mina characters.")
	_check_authored_portrait(tabletop.rival_at_table, "supplied Mina battle")
	_expect(String(main.run.route_battle.get("rival_portrait_id", "")) == "npc2" and String(main.run.route_battle.get("label", "")) == "Local Champion Mina", "The supplied artwork required rewriting legacy save identity.")
	_expect(main._route_rival_presentation({"node_type": "final_boss", "seed": 1}).id == "ellis", "Replacing Mina changed the final-boss cast mapping.")


func _check_authored_portrait(portrait: TextureRect, context: String) -> void:
	_expect(portrait.material == null, "%s adds a silhouette effect instead of retaining the authored navy contour." % context)


func _finish(main: Node) -> void:
	for audio in main.find_children("*", "AudioStreamPlayer", true, false):
		var player := audio as AudioStreamPlayer
		player.stop()
		player.stream = null
	await create_timer(0.15).timeout
	main.queue_free()
	await process_frame
	await process_frame
	if _errors.is_empty():
		print("ROUTE_RIVAL_INTRO_SMOKE_TEST_OK")
		quit(0)
	else:
		print("ROUTE_RIVAL_INTRO_SMOKE_TEST_FAILED: %d checks" % _errors.size())
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error(message)
