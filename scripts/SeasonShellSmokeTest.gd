extends SceneTree

const MAIN_SCENE := preload("res://scenes/Main.tscn")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.cards_by_id.size() == 87, "Season shell did not load the canonical 87-card demo catalog.")
	_expect(main.archetypes_by_id.size() == 4 and main.archetypes_by_id.has("fresh"), "Season shell did not load the Fresh opponent archetype.")
	_expect(main.boosters_by_id.size() == 2, "Season shell did not load both booster definitions.")
	_expect(main.tournaments_by_id.size() == 5, "Season shell did not load the tournament calendar.")
	_expect(main.current_screen == "start", "The demo did not open on the title screen.")
	_expect(main.find_child("GameStartButton", true, false) != null, "The title screen is missing Game Start.")
	_expect(main.find_child("TitleHowToPlayButton", true, false) != null, "The title screen is missing How to Play.")

	main._show_game_start()
	await process_frame
	_expect(main.find_child("ContinueRunButton", true, false) != null, "Game Start is missing Continue.")
	_expect(main.find_child("NewGameButton", true, false) != null, "Game Start is missing New Run.")

	main._show_season_run_setup()
	await process_frame
	_expect(main.current_screen == "season_setup", "New Run did not reach season setup.")
	_expect(main.DEMO_STARTER_ORDER == ["spicy", "hearty", "sweet", "draft_night"], "Season setup does not expose the intended three starters and Draft Night.")

	main._show_tutorial()
	await process_frame
	await process_frame
	var tutorial = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "tutorial" and tutorial != null and bool(tutorial.tutorial_mode), "How to Play did not open the guided Living Table tutorial.")
	_expect(main.find_child("GuidedTutorialPanel", true, false) != null, "The guided tutorial is missing its lesson panel.")
	_expect(main.run.is_empty(), "Opening the tutorial unexpectedly created a season run.")

	main._start_new_run_with_mode("spicy", "debug", "white")
	await process_frame
	await process_frame
	_expect(main.current_screen == "shop", "A new run did not enter the card shop.")
	_expect(main._deck_total(main.run.get("deck", {})) == main.MAIN_DECK_SIZE, "The starter deck is not the required 20 cards.")
	_expect(main.run.get("shop", []).size() == 8, "The card shop did not generate eight singles.")
	_expect(main.find_child("CardShopSceneFrame", true, false) != null, "The debug card-shop scene did not render.")

	var collection_before: int = main._deck_total(main.run.get("collection", {}))
	var pack: Array = main._generate_pack("base_standard_pack")
	_expect(pack.size() == 5, "The base booster did not generate five cards.")
	main._start_pack(pack)
	main._show_packs()
	await process_frame
	await process_frame
	_expect(main.current_screen == "packs", "The pack-opening screen did not open.")
	_expect(main.find_child("PackButton", true, false) != null, "The sealed pack is missing from the pack-opening screen.")
	main.shop_economy_service.reveal_all_cards(main.run, main._current_primary_archetype())
	_expect(main._deck_total(main.run.get("collection", {})) == collection_before + pack.size(), "Revealed pack cards did not enter the collection.")

	main._show_deckbuilder()
	await process_frame
	_expect(main.current_screen == "deck" and main.find_child("DeckbuilderSideboardPanel", true, false) != null, "The deckbuilder did not open with sideboard controls.")

	main._show_meta()
	await process_frame
	_expect(main.current_screen == "meta", "The metagame screen did not open.")

	main._show_card_effect_lab()
	await process_frame
	_expect(main.current_screen == "card_lab", "The canonical Card Effect Lab did not open.")
	_expect(main.find_child("CardEffectLabScenarioPicker", true, false) != null, "The Card Effect Lab is missing its scenario picker.")
	var lab_results: Array[Dictionary] = main.card_effect_lab.run_all_scenarios()
	_expect(lab_results.size() == main.card_effect_lab.SCENARIOS.size(), "The Card Effect Lab skipped a registered scenario.")
	for result in lab_results:
		_expect(bool(result.get("passed", false)), "Card Effect Lab failed: %s" % String(result.get("label", result.get("id", "unknown"))))

	main._start_debug_kitchen_match()
	await process_frame
	await process_frame
	var tabletop = main.find_child("Tabletop3DPrototype", true, false)
	_expect(main.current_screen == "kitchen_match" and tabletop != null, "The shell did not launch the production Living Table match.")
	if tabletop != null:
		_expect(bool(tabletop.production_match), "The launched Living Table was not configured as a production match.")
		_expect(tabletop.configured_player_deck == main.run.deck, "The Living Table did not receive the active run deck.")
		_expect(main.find_child("KitchenGameRoot", true, false) == null, "The retired classic match renderer was instantiated.")

	# Let the opening presentation coroutine settle before replacing the match
	# screen; otherwise Godot reports its intentionally interrupted Tween as a
	# teardown leak even though the runtime transition is safe.
	await create_timer(1.15).timeout
	main._show_thanks_for_playing()
	await process_frame
	_expect(main.current_screen == "thanks", "The demo finale did not render.")
	_expect(main.find_child("FinaleCommunityLinks", true, false) != null, "The finale is missing its community-link area.")
	_expect(main.find_child("ThanksMainMenuButton", true, false) != null, "The finale is missing Return to Main Menu.")

	main._release_audio_streams()
	_kill_active_tweens()
	await create_timer(0.12).timeout
	main.queue_free()
	await create_timer(0.2).timeout
	await process_frame
	if failed:
		quit(1)
	else:
		print("Canonical season shell smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _kill_active_tweens() -> void:
	for active_tween in get_processed_tweens():
		active_tween.kill()
