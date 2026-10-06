extends SceneTree

class ObservedTable:
	extends "res://scripts/Tabletop3DPrototype.gd"
	var presentation_order: Array[String] = []

	func _show_reshuffle_banner(event: Dictionary) -> void:
		presentation_order.append("reshuffle_start")
		await super._show_reshuffle_banner(event)
		presentation_order.append("reshuffle_end")

	func _start_damage_event_animation(event: Dictionary) -> float:
		presentation_order.append("damage")
		return super._start_damage_event_animation(event)

	func _start_card_transfer_event_animation(event: Dictionary) -> float:
		presentation_order.append("draw")
		return super._start_card_transfer_event_animation(event)


var _failures: Array[String] = []
var _drain_done := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1440, 900)
	var table := (load("res://scenes/Tabletop3DPrototype.tscn") as PackedScene).instantiate()
	table.set_script(ObservedTable)
	root.add_child(table)
	await create_timer(1.15).timeout
	var rules := {"player_life": 40, "opponent_life": 40, "reshuffle_pressure": true, "reshuffle_damage": [3, 5, 7]}
	var state: Dictionary = table.service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 87, "player", true, "easy", rules)
	for expected_damage in [3, 5, 7, 7]:
		state.player.deck = []
		state.player.hand = []
		state.player.discard = ["spicy_hot_honey_bee"]
		table.service.clear_animation_events(state)
		table.service._draw(state, "player")
		var events: Array[Dictionary] = table.service.take_animation_events(state)
		_expect(_event_types(events) == ["reshuffle", "damage", "draw"], "Reshuffle was not queued before damage and draw.")
		_expect(events[0].side == "player" and events[0].pressure_damage == expected_damage and events[0].card_count == 1, "Reshuffle announcement has incorrect ownership, damage, or card count.")
	state.player.deck = ["spicy_hot_honey_bee"]
	table.service._draw(state, "player")
	_expect(_event_types(table.service.take_animation_events(state)) == ["draw"], "An ordinary draw announced a reshuffle.")
	state.player.deck = []
	state.player.discard = []
	table.service._draw(state, "player")
	_expect(table.service.take_animation_events(state).is_empty(), "An empty discard pile announced a reshuffle.")
	state.opponent.deck = []
	state.opponent.discard = ["hearty_bagver"]
	state.opponent.life = 2
	table.service._draw(state, "opponent")
	var lethal_events: Array[Dictionary] = table.service.take_animation_events(state)
	_expect(_event_types(lethal_events) == ["reshuffle", "damage"] and lethal_events[0].side == "opponent", "A lethal opponent reshuffle lost its announcement or drew after defeat.")
	_verify_deckbox_pressure(table.service, rules)

	# A real multi-draw Chef effect puts the reshuffle inside an action group.
	var protected_rules: Dictionary = rules.duplicate(true)
	protected_rules.deckbox_effects = {"reshuffle_damage_reduction": 2}
	table.state = table.service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 88, "player", true, "easy", protected_rules)
	table.state.player.deck = []
	table.state.player.discard = ["spicy_hot_honey_bee", "spicy_jalapeno_panther", "spicy_jalapeno_jackal"]
	table.state.player.hand = ["chef_mary"]
	table.service.clear_animation_events(table.state)
	table.animation_busy = true
	table._render_match()
	table.service.play_card(table.state, 0)
	table.presentation_order.clear()
	_drain(table)
	await _wait_for_reshuffle(table)
	await create_timer(0.32).timeout
	_expect(table.turn_banner_panel.visible and table.turn_banner_title.text == "RESHUFFLE", "The live reshuffle banner did not appear.")
	_expect(table.turn_banner_subtitle.text == "YOUR DECK  ·  1 DAMAGE", "Player reshuffle subtitle did not show the deckbox-reduced damage.")
	_expect(int(table.state.player.life) == 39, "Player lost more life than the deckbox-reduced banner announced.")
	_expect(is_instance_valid(table.turn_banner_graphic) and table.turn_banner_graphic.is_visible_in_tree() and table.turn_banner_graphic.accent_color.is_equal_approx(table.PALETTE.PEACH_TEAL), "Player reshuffle does not show the player color on its paper stamp.")
	_expect(table.turn_banner_title.get_theme_color("font_color").is_equal_approx(table.PALETTE.PEACH_INK), "The reshuffle headline does not use the shared ink color.")
	_expect(not table.presentation_order.has("draw") and not table.presentation_order.has("damage"), "Damage or draw animation ran before the banner finished.")
	await _capture("reshuffle_banner_player")
	await _wait_for_drain()
	_expect(table.presentation_order == ["reshuffle_start", "reshuffle_end", "damage", "draw", "draw", "draw"], "Grouped Chef draws did not preserve reshuffle presentation order.")
	_expect(not table.turn_banner_panel.visible and not table.match_banner_active, "Reshuffle left the banner onscreen.")

	# Reduced motion holds the same graphic in the center without sweeping it.
	table.reduced_motion = true
	table.state.opponent.deck = []
	table.state.opponent.hand = []
	table.state.opponent.discard = ["hearty_bagver", "hearty_macaroni_manatee"]
	table.service.clear_animation_events(table.state)
	table.service._draw(table.state, "opponent")
	table.presentation_order.clear()
	_drain(table)
	await _wait_for_reshuffle(table)
	await create_timer(0.12).timeout
	_expect(table.turn_banner_subtitle.text == "OPPONENT DECK  ·  3 DAMAGE", "Opponent reshuffle subtitle is incorrect.")
	_expect(is_instance_valid(table.turn_banner_graphic) and table.turn_banner_graphic.is_visible_in_tree() and table.turn_banner_graphic.accent_color.is_equal_approx(table.PALETTE.SIGNAL_RED), "Opponent reshuffle does not show the rival color on its paper stamp.")
	var center: Vector2 = (table.effect_layer.size - table.turn_banner_panel.size) * 0.5
	_expect(table.turn_banner_panel.position.is_equal_approx(center), "Reduced-motion reshuffle still sweeps across the screen.")
	await _capture("reshuffle_banner_opponent")
	await _wait_for_drain()
	_expect(table.presentation_order == ["reshuffle_start", "reshuffle_end", "damage", "draw"], "Opponent refill animation order is incorrect.")

	# A nonblocking turn announcement must finish before reshuffle replaces it.
	table._show_turn_banner("opponent_turn")
	table._show_reshuffle_banner({"side": "player", "pressure_damage": 5})
	await create_timer(0.12).timeout
	_expect(table.turn_banner_title.text == "OPPONENT TURN", "Reshuffle overwrote an active turn announcement.")
	await create_timer(0.58).timeout
	_expect(table.turn_banner_title.text == "RESHUFFLE" and table.turn_banner_subtitle.text == "YOUR DECK  ·  5 DAMAGE", "Queued reshuffle did not follow the turn announcement.")
	await create_timer(0.65).timeout
	table.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Reshuffle banner smoke test passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _verify_deckbox_pressure(service: RefCounted, rules: Dictionary) -> void:
	var protected_rules := rules.duplicate(true)
	protected_rules.deckbox_effects = {"reshuffle_damage_reduction": 2}
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 91, "player", true, "easy", protected_rules)
	for expected_damage in [1, 3, 5, 5]:
		# JSON round trips mirror a saved match; combatant effects and the pressure
		# count must remain authoritative after restoring its snapshot.
		state = JSON.parse_string(JSON.stringify(state))
		state.player.deck = []
		state.player.hand = []
		state.player.discard = ["spicy_hot_honey_bee"]
		var previous_life := int(state.player.life)
		service.clear_animation_events(state)
		service._draw(state, "player")
		var events: Array[Dictionary] = service.take_animation_events(state)
		_expect(_event_types(events) == ["reshuffle", "damage", "draw"], "Protected reshuffle lost its announcement, damage, or drawn card.")
		_expect(int(events[0].pressure_damage) == expected_damage and int(events[1].amount) == expected_damage, "Deckbox reshuffle and damage events disagree with the reduced curve.")
		_expect(previous_life - int(state.player.life) == expected_damage, "Restored match did not preserve reduced reshuffle damage.")
	for expected_damage in [3, 5, 7]:
		state.opponent.deck = []
		state.opponent.hand = []
		state.opponent.discard = ["hearty_bagver"]
		var previous_life := int(state.opponent.life)
		service.clear_animation_events(state)
		service._draw(state, "opponent")
		var events: Array[Dictionary] = service.take_animation_events(state)
		_expect(int(events[0].pressure_damage) == expected_damage and previous_life - int(state.opponent.life) == expected_damage, "Player's deckbox reduced the rival's reshuffle damage.")
	state.run_rules.reshuffle_damage = [1]
	state.player.deck = []
	state.player.discard = ["spicy_hot_honey_bee"]
	state.player.life = 1
	service.clear_animation_events(state)
	service._draw(state, "player")
	var events: Array[Dictionary] = service.take_animation_events(state)
	_expect(_event_types(events) == ["reshuffle", "draw"] and int(events[0].pressure_damage) == 0, "Fully prevented reshuffle queued damage or blocked its draw.")
	_expect(int(state.player.life) == 1 and not bool(state.game_over), "Reduced reshuffle damage healed the player or ended the match.")
	# The passive changes reshuffles only; ordinary incoming damage stays intact.
	state.player.life = 10
	service._deal_chef_damage(state, "player", 4, "opponent", true)
	_expect(int(state.player.life) == 6, "Reshuffle deckbox reduced ordinary attack damage.")


func _drain(table: Node) -> void:
	_drain_done = false
	await table._drain_animation_event_queue()
	_drain_done = true


func _wait_for_reshuffle(table: Node) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while not (table.turn_banner_panel.visible and table.turn_banner_title.text == "RESHUFFLE") and Time.get_ticks_msec() < deadline:
		await process_frame


func _wait_for_drain() -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while not _drain_done and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(_drain_done, "Animation queue did not finish.")


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for event in events:
		result.append(String(event.type))
	return result


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/%s.png" % filename)) == OK, "Could not capture reshuffle banner.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
