extends SceneTree

## Deterministic, cursor-free promotional capture. Run with Godot's Movie Maker
## mode so only the game viewport is recorded:
##   godot --path . --script res://scripts/ShowcaseRunCapture.gd \
##     --write-movie /tmp/topdeck-showcase.avi --fixed-fps 30

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const CAPTURE_SIZE := Vector2i(1280, 720)
const TRANSITION_COLOR := Color("#29365F")

var main
var curtain: ColorRect


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	root.set_meta("reduced_motion", false)
	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle(8)
	_create_curtain()
	await _fade_from_dark(0.65)
	print("SHOWCASE title")

	# Main menu and season setup.
	await _hold(2.4)
	await _transition(func() -> void:
		main.season_setup_archetype_index = 1
		main.season_setup_difficulty_index = 0
		main._show_season_run_setup()
	)
	await _hold(2.35)
	print("SHOWCASE starter setup")
	main._show_starter_deck_preview("hearty")
	await _hold(2.3)
	main._close_starter_deck_preview()
	await _hold(0.45)
	print("SHOWCASE starter preview closed")

	# A real Hearty/Black season starts at $8 and enters the 3D card shop.
	await _transition(func() -> void:
		main._start_new_run_with_mode("hearty", "season", "white")
	)
	await _hold(2.8)
	print("SHOWCASE shop screen=", main.current_screen)
	var shop_world: Node = main.find_child("CardShopOverworld", true, false)
	if shop_world != null:
		shop_world.call("_show_menu")
	await _hold(2.7)

	# Buy the $5 booster, crack it, and flip every card in sequence.
	main._show_packs()
	await _hold(1.25)
	print("SHOWCASE pack table screen=", main.current_screen)
	main.pack_opening_screen._on_pack_pressed(main)
	await _hold(1.05)
	for card_index in range(5):
		main.pack_opening_screen._on_card_slot_pressed(main, card_index)
		await _hold(0.5)
	await _hold(1.1)
	main.pack_opening_screen._finish_in_shop_overlay(main)
	await _hold(0.65)

	# Show the deck workshop before the match.
	await _transition(func() -> void:
		main._show_deckbuilder()
	)
	await _hold(2.4)
	print("SHOWCASE deck workshop screen=", main.current_screen)

	# Start an authentic Hearty match, then stage a deterministic mid-game board
	# using the same production rules and animation pipeline as normal play.
	await _transition(func() -> void:
		var opponent_archetype: String = String(main._predator_archetype("hearty"))
		var opponent_deck: Dictionary = main._opponent_deck_for_round(opponent_archetype, 1)
		main._begin_kitchen_match(
			main.run.get("deck", {}),
			opponent_deck,
			"Local Rival — %s" % main._archetype_label(opponent_archetype),
			false,
			20260807,
			"player",
			"easy"
		)
	)
	await _hold(2.35)
	print("SHOWCASE battle screen=", main.current_screen)
	var tabletop: Node = main.find_child("Tabletop3DPrototype", true, false)
	if tabletop != null:
		_stage_hearty_showcase(tabletop)
		await _hold(1.4)
		var gazelle_id := int(tabletop.get_meta("showcase_gazelle_id", -1))
		var lasagnama_id := int(tabletop.get_meta("showcase_lasagnama_id", -1))
		var defender_id := int(tabletop.get_meta("showcase_defender_id", -1))
		await tabletop._activate_ability(gazelle_id, "gravy_gazelle_buff")
		await _hold(0.55)
		await tabletop._choose_ability_target_animated(lasagnama_id)
		await _hold(0.8)
		tabletop._select_attacker(lasagnama_id)
		await _hold(0.45)
		await tabletop._perform_attack(defender_id)
		await _hold(0.8)
		await tabletop._perform_attack(-1, gazelle_id)
		await _hold(1.7)

	# End on the demo's final card so the long cut has a natural sign-off.
	await _transition(func() -> void:
		main._show_thanks_for_playing()
	)
	await _hold(3.2)
	print("SHOWCASE finale screen=", main.current_screen)
	await _fade_to_dark(0.75)
	quit()


func _stage_hearty_showcase(tabletop) -> void:
	var state: Dictionary = tabletop.state
	state.turn = 4
	state.phase = "player_main"
	state.first_player = "opponent"
	state.game_over = false
	state.winner = ""
	state.selected_attacker = -1
	state.selected_ingredients = []
	state.pending_meal = {}
	state.pending_discard = {}
	state.pending_ability = {}
	state.pending_search = {}
	state.pending_choice = {}
	state.pending_resume = {}
	state.pending_reaction = {}
	state.animation_events = []
	state.player.life = 16
	state.opponent.life = 12
	state.player.hand = [
		"hearty_ramen_ram",
		"spice_savory_gravy",
		"item_wooden_spoon",
		"hearty_polar_pot_pie_bear",
	]
	state.player.deck = ["hearty_bagver", "hearty_french_bread_dog", "hearty_kale_whale"]
	state.player.prep = []
	state.player.plated = []
	state.player.discard = ["hearty_macaroni_manatee"]
	state.player.environment = "environment_hearty_diner"
	state.player.meal_served = false
	state.player.zone_move_used = false
	state.player.chef_used = false
	state.opponent.hand = []
	state.opponent.deck = ["fresh_sprout_squirrel", "fresh_crisp_capybara"]
	state.opponent.prep = []
	state.opponent.plated = []
	state.opponent.discard = []
	state.opponent.environment = ""

	var gazelle: Dictionary = tabletop.service._make_unit(
		state, state.player, tabletop.service.card("hearty_gravy_gazelle"), "plated", "player"
	)
	gazelle.table_slot = 0
	gazelle.ready = true
	state.player.plated.append(gazelle)
	var lasagnama: Dictionary = tabletop.service._make_unit(
		state, state.player, tabletop.service.card("hearty_lasagnama"), "plated", "player"
	)
	lasagnama.table_slot = 1
	lasagnama.ready = true
	state.player.plated.append(lasagnama)
	var bagver: Dictionary = tabletop.service._make_unit(
		state, state.player, tabletop.service.card("hearty_bagver"), "prep", "player"
	)
	bagver.table_slot = 1
	bagver.ready = false
	state.player.prep.append(bagver)
	var defender: Dictionary = tabletop.service._make_unit(
		state, state.opponent, tabletop.service.card("fresh_saladmander"), "plated", "opponent"
	)
	defender.table_slot = 0
	defender.ready = true
	state.opponent.plated.append(defender)

	tabletop.set_meta("showcase_gazelle_id", int(gazelle.instance_id))
	tabletop.set_meta("showcase_lasagnama_id", int(lasagnama.instance_id))
	tabletop.set_meta("showcase_defender_id", int(defender.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _create_curtain() -> void:
	curtain = ColorRect.new()
	curtain.name = "ShowcaseCurtain"
	curtain.position = Vector2.ZERO
	curtain.size = Vector2(CAPTURE_SIZE)
	curtain.color = TRANSITION_COLOR
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.z_index = 4095
	root.add_child(curtain)


func _transition(change_screen: Callable) -> void:
	await _fade_to_dark(0.34)
	change_screen.call()
	await _settle(5)
	await _fade_from_dark(0.42)


func _fade_to_dark(duration: float) -> void:
	curtain.visible = true
	var tween := curtain.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(curtain, "color:a", 1.0, duration)
	await tween.finished


func _fade_from_dark(duration: float) -> void:
	curtain.visible = true
	var tween := curtain.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(curtain, "color:a", 0.0, duration)
	await tween.finished
	curtain.visible = false


func _hold(seconds: float) -> void:
	await create_timer(seconds).timeout


func _settle(frames: int = 3) -> void:
	for unused in range(frames):
		await process_frame
