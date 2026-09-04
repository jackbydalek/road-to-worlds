extends SceneTree

const PRODUCTION_MAP_PREVIEW_PATH := "res://outputs/illustrated_vfx/tournament_hub_campaign.png"


func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.call_deferred("add_child", main)
	await process_frame
	await process_frame
	main.run_state_service.save_path = "/private/tmp/route_campaign_flow_smoke.json"
	main.autosave_enabled = true
	main._show_season_run_setup()
	await process_frame
	var setup = main.find_child("SeasonRegistration", true, false)
	_expect(setup != null, "New Run did not open the starter selection.")
	var spicy_player_art := main.find_child("SpicyPlayerArtwork", true, false) as TextureRect
	_expect(
		spicy_player_art != null
		and spicy_player_art.texture != null
		and spicy_player_art.texture.resource_path.ends_with("player_idle.png"),
		"Spicy character selection did not use the supplied idle sprite."
	)
	main._select_season_setup_archetype(1)
	await process_frame
	await process_frame
	setup = main.find_child("SeasonRegistration", true, false)
	var hearty_player_art := main.find_child("HeartyPlayerArtwork", true, false) as TextureRect
	_expect(
		hearty_player_art != null
		and hearty_player_art.texture != null
		and hearty_player_art.texture.resource_path.ends_with("hearty_player_idle.png"),
		"Hearty character selection did not use the supplied idle sprite."
	)
	if setup != null:
		_expect(not setup.get_node("%DraftNightButton").visible, "Legacy Draft Night remained in the public route setup.")
	var legacy_deck: Dictionary = main._deck_entries_to_dict(main.archetypes_by_id.spicy.starterDeck)
	var legacy_run: Dictionary = main.run_state_service.create_run("spicy", legacy_deck, "hearty", "season", "white")
	main._ensure_route_run(legacy_run)
	_expect(String(legacy_run.get("run_loop", "")) == "route" and main._deck_total(legacy_run.deck) == 15, "A legacy public save did not migrate into Starter City.")
	main._start_new_run_with_mode("hearty", "season", "white")
	await process_frame
	await process_frame
	_expect(String(main.run.get("run_loop", "")) == "route", "New public runs did not enter the route loop.")
	_expect(main._deck_total(main.run.deck) == 15, "New route run did not use a 15-card starter.")
	_expect(main.current_screen == "route_hub", "New route run did not open the Locals tournament hub.")
	_expect(
		main.find_child("TournamentHub", true, false) != null
		and main.find_child("ShopKiosk", true, false) != null
		and main.find_child("VendingMachine", true, false) != null
		and main.find_child("MatchTable", true, false) != null,
		"Production flow did not load the front-on parallax card-store hub."
	)
	_expect(
		main.find_child("HubRoundLabel", true, false) != null
		and main.find_child("HubLifeLabel", true, false) != null
		and main.find_child("HubFundsLabel", true, false) != null
		and main.find_child("HubDeckLabel", true, false) != null,
		"Tournament hub is missing its round, persistent-life, funds, or locked-deck status."
	)
	_expect(
		main.find_child("HubBackLayer", true, false) != null
		and main.find_child("HubMidLayer", true, false) != null
		and main.find_child("HubFrontLayer", true, false) != null,
		"Tournament hub did not preserve separate parallax depth layers."
	)
	var save_result: Dictionary = main._autosave_now("route_hub")
	_expect(bool(save_result.get("ok", false)), "Route run could not be serialized: %s" % String(save_result.get("message", "unknown")))
	for _frame in range(8):
		await process_frame
	if DisplayServer.get_name() != "headless":
		var production_map_image := root.get_viewport().get_texture().get_image()
		_expect(
			production_map_image != null
			and production_map_image.save_png(ProjectSettings.globalize_path(PRODUCTION_MAP_PREVIEW_PATH)) == OK,
			"Production tournament hub could not be captured."
		)
	var hub_shop_button := main.find_child("HubShopButton", true, false) as Button
	if hub_shop_button != null:
		hub_shop_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_expect(
		main.current_screen == "route_shop"
		and bool(main.run.pending_route_node.get("hub_shop", false)),
		"The hub kiosk did not open its persistent card-shop screen."
	)
	var hub_shop_services := main.find_child("RouteShopServicesPanel", true, false) as Control
	_expect(hub_shop_services != null and not hub_shop_services.visible, "The hub shop exposed services that belong to the one-use vending machine.")
	var hub_shop_back := main.find_child("RouteShopContinueButton", true, false) as Button
	if hub_shop_back != null:
		hub_shop_back.emit_signal("pressed")
	for _frame in range(6):
		await process_frame
	_expect(
		main.current_screen == "route_hub"
		and bool(main.run.get("hub_shop", {}).get("hub_shop", false)),
		"Leaving the kiosk did not return to the hub or remember its visit state."
	)
	main.run.pending_route_node = {"id": "smoke_enemy", "type": "enemy", "label": "Smoke Test Rival"}
	main._start_route_battle()
	await process_frame
	await process_frame
	var rival_intro_portrait := main.find_child("RouteRivalPortrait", true, false) as TextureRect
	_expect(
		main.current_screen == "route_encounter_intro"
		and main.find_child("TournamentHub", true, false) != null
		and main.find_child("RouteEncounterDimmer", true, false) != null
		and main.find_child("RouteRivalDialoguePanel", true, false) != null
		and main.find_child("BeginRouteEncounterButton", true, false) != null
		and rival_intro_portrait != null
		and rival_intro_portrait.texture != null
		and rival_intro_portrait.texture.resource_path.contains("route_rival_npc_"),
		"Enemy node did not stage the supplied rival over the darkened tournament hub."
	)
	_expect(
		String(main.run.route_battle.get("rival_portrait_id", "")) in ["npc1", "npc2"],
		"The route encounter did not persist its deterministic rival portrait."
	)
	main._begin_route_battle_from_intro()
	await process_frame
	await process_frame
	var tabletop = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "kitchen_match" and tabletop != null, "Enemy node did not launch the Living Table.")
	if tabletop != null:
		var hearty_profile := tabletop.find_child("PlayerProfileBadgePortrait", true, false) as TextureRect
		_expect(
			hearty_profile != null
			and hearty_profile.texture != null
			and hearty_profile.texture.resource_path.ends_with("hearty_player_portrait.png"),
			"The Living Table did not use the supplied Hearty portrait."
		)
		_expect(int(tabletop.state.player.life) == 40 and int(tabletop.state.opponent.life) == 12, "Route encounter life did not reach combat.")
		_expect(int(tabletop.state.run_rules.get("turn_hand_floor", 0)) == 3, "Route battle did not configure the three-card refill rule.")
	if tabletop != null:
		tabletop.state.game_over = true
		tabletop.state.winner = "player"
		tabletop.state.player.life = 31
		tabletop.state.opponent.life = 0
		tabletop._queue_outcome_sequence()
		await create_timer(0.9).timeout
		var end_quote := tabletop.find_child("RouteRivalEndQuotePanel", true, false)
		var rival_at_table_front := tabletop.find_child("RouteRivalEndPortrait", true, false) as TextureRect
		var next_button := tabletop.find_child("RouteRivalEndNextButton", true, false) as Button
		_expect(end_quote != null and rival_at_table_front != null and next_button != null, "The route win did not stage the rival's closing quote and Next action.")
		if next_button != null:
			next_button.emit_signal("pressed")
	await process_frame
	await process_frame
	var reward_hub := main.find_child("TournamentHub", true, false)
	_expect(reward_hub != null and main.find_child("RouteRewardDimmer", true, false) != null, "The victory reward did not stay over the live tournament hub.")
	_expect(int(main.run.life) == 31 and int(main.run.money) == 10 and main.run.reward_offer.size() == 3, "Victory did not preserve life, animate cash, and generate a three-card reward.")
	var regular_pack_button := main.find_child("RouteSealedPackButton", true, false) as TextureButton
	_expect(
		main.current_screen == "route_reward_pack"
		and regular_pack_button != null
		and regular_pack_button.texture_normal.resource_path.ends_with("route_regular_reward.png"),
		"The victory CTA did not present a clickable sealed pack."
	)
	_expect(main.find_child("RouteSealedPackPrompt", true, false) == null, "The wordless sealed-pack overlay still rendered instruction copy.")
	_expect(main.find_child("RouteSealedPackAngularSurface", true, false) != null, "The sealed-pack overlay did not use the dark reward-panel treatment.")
	var sealed_pack_panel := main.find_child("RouteSealedPackScreen", true, false)
	_expect(sealed_pack_panel != null and sealed_pack_panel.find_children("*", "Label", true, false).is_empty(), "The sealed-pack panel still contains visible words.")
	var saved_reward_node: Dictionary = main.run.pending_route_node.duplicate(true)
	for pack_case in [
		{"type": "enemy", "asset": "route_regular_reward.png"},
		{"type": "mini_boss", "asset": "route_miniboss_reward.png"},
		{"type": "final_boss", "asset": "route_floor_boss_reward.png"},
	]:
		main.run.pending_route_node.type = String(pack_case.type)
		var mapped_pack_art := main._route_reward_pack_art() as Texture2D
		_expect(
			mapped_pack_art != null and mapped_pack_art.resource_path.ends_with(String(pack_case.asset)),
			"The %s reward did not use its supplied pack artwork." % String(pack_case.type)
		)
	main.run.pending_route_node = saved_reward_node
	main._resolve_pending_route_node()
	await process_frame
	_expect(main.current_screen == "route_reward_pack", "A resumed sealed reward skipped the pack-opening step.")
	main._crack_route_victory_pack()
	await process_frame
	_expect(main.current_screen == "route_reward" and main.find_child("RouteRewardFan", true, false) != null, "Clicking the sealed pack did not organize the card reward.")
	_expect(
		main.find_child("RouteCardRewardHeaderAngularSurface", true, false) != null
		and main.find_child("RouteCardRewardTitle", true, false) != null,
		"The card-choice header did not use the current dark angular UI treatment."
	)
	var reward_ids: Array = main.run.reward_offer.duplicate()
	var deck_before_reward: int = main._deck_total(main.run.deck)
	var first_reward_id := String(reward_ids[0])
	var first_reward_choice := main.find_child("RouteReward_%s" % first_reward_id, true, false) as Control
	var first_add_button := main.find_child("RouteRewardAddButton_%s" % first_reward_id, true, false) as Button
	_expect(first_reward_choice != null and first_add_button != null and not first_add_button.visible, "Reward cards did not begin in the unselected state.")
	var second_reward_choice := main.find_child("RouteReward_%s" % String(reward_ids[1]), true, false) as Control
	_expect(
		first_reward_choice != null
		and second_reward_choice != null
		and absf(second_reward_choice.position.x - first_reward_choice.position.x) >= 270.0,
		"The regular three-card reward was not spread into a readable row."
	)
	main._select_route_reward_card(first_reward_id)
	var first_reward_base_position: Vector2 = first_reward_choice.get_meta("base_position", first_reward_choice.position) if first_reward_choice != null else Vector2.ZERO
	_expect(
		first_reward_choice != null
		and first_add_button != null
		and first_add_button.visible
		and first_reward_choice.position.y < first_reward_base_position.y,
		"Selecting a reward card did not lift it and reveal Add to Deck."
	)
	_expect(
		main.find_child("RouteRewardAddAllButton", true, false) != null
		and main.find_child("RouteRewardSkipButton", true, false) != null,
		"The reward screen did not expose Add All and Skip."
	)
	var continuous_reward_overlay := main.find_child("RouteRewardOverlay", true, false)
	var continuous_reward_dimmer := main.find_child("RouteRewardDimmer", true, false)
	main._pick_route_reward(first_reward_id)
	await process_frame
	_expect(
		main._deck_total(main.run.deck) == deck_before_reward + 1
		and main.run.reward_offer.size() == reward_ids.size() - 1
		and main.last_card_add_effect_context == "reward_pack",
		"Add to Deck did not add exactly the selected reward through the shared card-add effect."
	)
	_expect(
		main.find_child("RouteRewardOverlay", true, false) == continuous_reward_overlay
		and main.find_child("RouteRewardDimmer", true, false) == continuous_reward_dimmer
		and main.find_child("RouteReward_%s" % first_reward_id, true, false) == null,
		"Adding one reward card rebuilt the overlay instead of continuing within the same pack screen."
	)
	main._add_all_route_rewards()
	await process_frame
	_expect(main._deck_total(main.run.deck) == deck_before_reward + reward_ids.size(), "Add All did not add every remaining reward card.")

	var victory_run: Dictionary = main.run.duplicate(true)
	main._show_route_victory()
	await process_frame
	var victory_discord := main.find_child("RouteVictoryDiscordButton", true, false) as Button
	var victory_deck := main.find_child("RouteVictoryDeckButton", true, false) as Button
	var victory_again := main.find_child("RouteVictoryAgainButton", true, false) as Button
	var victory_title := main.find_child("RouteVictoryTitleButton", true, false) as Button
	_expect(
		victory_discord != null
		and not victory_discord.disabled
		and not victory_discord.get_signal_connection_list("pressed").is_empty(),
		"The route finale Discord action was not clickable."
	)
	_expect(main.find_child("RouteVictorySteamButton", true, false) == null, "The route finale showed a dead Steam action without a configured URL.")
	_expect(victory_deck != null and victory_again != null and victory_title != null, "The route finale was missing a navigation action.")
	if victory_deck != null:
		victory_deck.emit_signal("pressed")
		await process_frame
		_expect(main.current_screen == "deck", "Review Winning Deck did not open the deck view.")
		var deck_back := main.find_child("DeckbuilderBackButton", true, false) as Button
		if deck_back != null:
			deck_back.emit_signal("pressed")
			await process_frame
		_expect(main.current_screen == "route_victory", "The winning deck did not return to the route finale.")

	main.run = victory_run.duplicate(true)
	main._show_route_victory()
	await process_frame
	victory_again = main.find_child("RouteVictoryAgainButton", true, false) as Button
	if victory_again != null:
		victory_again.emit_signal("pressed")
		await process_frame
	_expect(main.current_screen == "season_setup", "Start Another Run did not open starter selection.")

	main.run = victory_run.duplicate(true)
	main._show_route_victory()
	await process_frame
	victory_title = main.find_child("RouteVictoryTitleButton", true, false) as Button
	if victory_title != null:
		victory_title.emit_signal("pressed")
		await process_frame
	_expect(main.current_screen == "start", "Return to Title did not open the title screen.")
	main.run_state_service.clear_saved_run()
	print("ROUTE_CAMPAIGN_FLOW_SMOKE_TEST_OK")
	quit(0 if _errors.is_empty() else 1)


var _errors: Array[String] = []


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error(message)
