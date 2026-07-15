extends Control

signal match_finished(result: Dictionary)
signal exit_requested

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const FONT_PATH := "res://assets/fonts/ArchivoNarrow-Regular.ttf"

var service: RefCounted
var state: Dictionary = {}
var root_box: VBoxContainer
var card_font: FontFile
var player_deck_id := ""
var inspected_card: Dictionary = {}
var inspect_overlay: PanelContainer
var season_match := false
var configured_player_deck: Dictionary = {}
var configured_opponent_deck: Dictionary = {}
var configured_player_name := "Your Kitchen"
var configured_opponent_name := "Opponent Kitchen"
var configured_seed := 1
var configured_first_side := "player"
var configured_exit_label := "Return"
var result_emitted := false
var rendered_visual_snapshot: Dictionary = {}
var unit_visual_nodes: Dictionary = {}
var hand_visual_nodes: Dictionary = {}
var environment_visual_nodes: Dictionary = {}
var board_visual_nodes: Dictionary = {}
var drag_drop_targets: Array[Dictionary] = []
var drag_highlight_restore: Array[Dictionary] = []
var active_drag_payload: Dictionary = {}
var active_drag_source: Control
var drag_drop_accepted := false
var floating_feedback: PanelContainer


func configure_match(player_deck: Dictionary, opponent_deck: Dictionary, player_name: String, opponent_name: String, seed: int, first_side: String = "player", exit_label: String = "Return") -> void:
	season_match = true
	configured_player_deck = player_deck.duplicate(true)
	configured_opponent_deck = opponent_deck.duplicate(true)
	configured_player_name = player_name
	configured_opponent_name = opponent_name
	configured_seed = seed
	configured_first_side = first_side
	configured_exit_label = exit_label


func _ready() -> void:
	card_font = load(FONT_PATH)
	service = SERVICE_SCRIPT.new()
	if not service.load_content():
		push_error("Could not load the cooking card catalog.")
		return
	if season_match:
		service.decks["season_player"] = {"name": configured_player_name, "archetype": "", "cards": configured_player_deck}
		service.decks["season_opponent"] = {"name": configured_opponent_name, "archetype": "", "cards": configured_opponent_deck}
		player_deck_id = "season_player"
	_build_shell()
	_new_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not active_drag_payload.is_empty():
		call_deferred("_finish_drag_feedback")


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#f3efe5")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.name = "KitchenGameRoot"
	root_box.add_theme_constant_override("separation", 5)
	margin.add_child(root_box)


func _new_game(requested_deck_id: String = "") -> void:
	inspected_card = {}
	var deck_ids: Array[String] = service.available_deck_ids()
	if requested_deck_id != "":
		player_deck_id = requested_deck_id
	if player_deck_id == "" and not deck_ids.is_empty():
		player_deck_id = deck_ids[0]
	var player_deck := player_deck_id
	var player_index := deck_ids.find(player_deck)
	var opponent_deck := "season_opponent" if season_match else (deck_ids[(player_index + 1) % deck_ids.size()] if deck_ids.size() > 1 else player_deck)
	result_emitted = false
	state = service.start_game(player_deck, opponent_deck, configured_seed if season_match else Time.get_ticks_msec(), configured_first_side if season_match else "player")
	_refresh()


func _refresh() -> void:
	if root_box == null:
		return
	var visual_events := _collect_visual_events(rendered_visual_snapshot, _capture_visual_snapshot())
	_capture_removed_event_geometry(visual_events)
	if is_instance_valid(inspect_overlay):
		inspect_overlay.get_parent().remove_child(inspect_overlay)
		inspect_overlay.queue_free()
	inspect_overlay = null
	unit_visual_nodes.clear()
	hand_visual_nodes.clear()
	environment_visual_nodes.clear()
	board_visual_nodes.clear()
	drag_drop_targets.clear()
	drag_highlight_restore.clear()
	for child in root_box.get_children():
		child.queue_free()
	_build_header()
	_build_side("opponent")
	_build_message_strip()
	_build_side("player")
	_build_hand()
	_build_action_bar()
	_build_inspect_overlay()
	rendered_visual_snapshot = _capture_visual_snapshot()
	if not visual_events.is_empty():
		call_deferred("_play_visual_events", visual_events)
	call_deferred("_animate_status_attention")
	if bool(state.get("game_over", false)) and not result_emitted:
		result_emitted = true
		match_finished.emit({
			"winner": String(state.get("winner", "")),
			"turn": int(state.get("turn", 0)),
			"player_life": int(state.get("player", {}).get("life", 0)),
			"opponent_life": int(state.get("opponent", {}).get("life", 0))
		})


func _build_header() -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	row.add_theme_constant_override("separation", 8)
	root_box.add_child(row)
	var title := _label("KITCHEN TABLE — PREP & PLATED", 25, Color("#173e52"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var matchup := _label("%s  vs  %s" % [service.deck_name(String(state.player.deck_id)), service.deck_name(String(state.opponent.deck_id))], 16, Color("#4b5e66"))
	row.add_child(matchup)
	var turn_badge := _label("YOUR TURN • %d" % int(state.get("turn", 1)) if String(state.get("phase", "")) == "player_main" else "OPPONENT TURN • %d" % int(state.get("turn", 1)), 16, Color("#fff4df"))
	turn_badge.name = "CookingTurnOwnerBadge"
	turn_badge.add_theme_stylebox_override("normal", _panel_style(Color("#238052") if String(state.get("phase", "")) == "player_main" else Color("#8c4338"), Color("#ffe477"), 2, 5))
	turn_badge.add_theme_constant_override("outline_size", 6)
	row.add_child(turn_badge)
	if season_match:
		var leave := _button(configured_exit_label)
		leave.pressed.connect(func() -> void: exit_requested.emit(), CONNECT_DEFERRED)
		row.add_child(leave)
	else:
		for deck_id in service.available_deck_ids():
			var deck_button := _button(String(service.decks[deck_id].get("archetype", deck_id)).capitalize())
			var selected_deck_id := String(deck_id)
			deck_button.pressed.connect(func() -> void: _new_game(selected_deck_id), CONNECT_DEFERRED)
			row.add_child(deck_button)
		var restart := _button("Restart")
		restart.disabled = not service.has_playable_content()
		restart.pressed.connect(_new_game, CONNECT_DEFERRED)
		row.add_child(restart)


func _build_side(side: String) -> void:
	var combatant: Dictionary = state[side]
	var is_player := side == "player"
	var outer := PanelContainer.new()
	outer.name = "Cooking%sBoard" % ("Player" if is_player else "Opponent")
	outer.custom_minimum_size = Vector2(0, 220)
	var side_is_active := (is_player and String(state.get("phase", "")) == "player_main") or (not is_player and String(state.get("phase", "")) == "opponent_turn")
	outer.add_theme_stylebox_override("panel", _panel_style(Color("#fffaf0") if side_is_active else Color("#ebe8df"), Color("#ffd45c") if side_is_active else Color("#76909c"), 4 if side_is_active else 1, 6))
	root_box.add_child(outer)
	board_visual_nodes[side] = outer
	if not is_player:
		_wire_opponent_face_drop(outer)
		drag_drop_targets.append({"control": outer, "highlight_control": outer, "kind": "opponent_face"})
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	outer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var heading_text := ("YOUR BOARD • YOUR TURN" if side_is_active else "YOUR BOARD • WAITING") if is_player else ("OPPONENT BOARD • THEIR TURN" if side_is_active else "OPPONENT BOARD")
	var heading_label := _label("%s  •  %d LIFE" % [heading_text, int(combatant.life)], 17, Color("#183a49"))
	heading_label.name = "Cooking%sTurnStatus" % ("Player" if is_player else "Opponent")
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_label)
	heading.add_child(_label("Hand %d   Turn %d" % [combatant.hand.size(), combatant.turns_started], 14, Color("#617078")))

	var board_row := HBoxContainer.new()
	board_row.add_theme_constant_override("separation", 10)
	column.add_child(board_row)
	_build_environment(board_row, combatant, is_player)
	_build_combat_zones(board_row, combatant, is_player)
	_build_piles(board_row, combatant)


func _build_environment(parent: Node, combatant: Dictionary, is_player: bool) -> void:
	var panel := _zone_container(parent, "ENVIRONMENT", Vector2(160, 160), Color("#ec7130"))
	panel.name = "Cooking%sEnvironment" % ("Player" if is_player else "Opponent")
	if is_player:
		_wire_environment_drop(panel)
		drag_drop_targets.append({"control": panel, "highlight_control": panel.get_meta("zone_panel", panel), "kind": "environment"})
	if String(combatant.environment) == "":
		panel.add_child(_center_label("OPEN\nENVIRONMENT\nZONE", 14, Color("#77442d")))
	else:
		environment_visual_nodes["player" if is_player else "opponent"] = panel.get_meta("zone_panel", panel)
		var card_id := String(combatant.environment)
		var data: Dictionary = service.card(card_id)
		_add_inspect_header(panel, data, "player" if is_player else "opponent", "environment")
		var rules := _label(String(data.get("text", "")), 11, Color("#fff0d4"))
		rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(rules)


func _build_combat_zones(parent: Node, combatant: Dictionary, is_player: bool) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3)
	parent.add_child(column)
	var plated_heading := _label("PLATED — can attack and be attacked  (%d/%d)" % [combatant.plated.size(), service.PLATED_SLOTS], 13, Color("#174c63"))
	plated_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(plated_heading)
	var plated_row := HBoxContainer.new()
	plated_row.name = "Cooking%sPlatedZone" % ("Player" if is_player else "Opponent")
	plated_row.alignment = BoxContainer.ALIGNMENT_CENTER
	plated_row.add_theme_constant_override("separation", 6)
	column.add_child(plated_row)
	if is_player:
		_wire_unit_zone_drop(plated_row, "plated")
	for slot_index in range(service.PLATED_SLOTS):
		var unit: Dictionary = combatant.plated[slot_index] if slot_index < combatant.plated.size() else {}
		_add_unit_slot(plated_row, unit, "plated", is_player, slot_index)

	var prep_heading := _label("PREP — protected, cannot attack  (%d/%d)" % [combatant.prep.size(), service.PREP_SLOTS], 13, Color("#174c63"))
	prep_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prep_heading)
	var prep_row := HBoxContainer.new()
	prep_row.name = "Cooking%sPrepZone" % ("Player" if is_player else "Opponent")
	prep_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prep_row.add_theme_constant_override("separation", 5)
	column.add_child(prep_row)
	if is_player:
		_wire_unit_zone_drop(prep_row, "prep")
	for slot_index in range(service.PREP_SLOTS):
		var unit: Dictionary = combatant.prep[slot_index] if slot_index < combatant.prep.size() else {}
		_add_unit_slot(prep_row, unit, "prep", is_player, slot_index)


func _add_unit_slot(parent: Node, unit: Dictionary, zone_name: String, is_player: bool, slot_index: int) -> void:
	var panel := PanelContainer.new()
	var side_label := "Player" if is_player else "Opponent"
	var zone_label := "Plated" if zone_name == "plated" else "Prep"
	panel.name = "Cooking%s%sSlot_%d" % [side_label, zone_label, slot_index]
	panel.custom_minimum_size = Vector2(154 if zone_name == "plated" else 142, 72)
	var zone_color := Color("#ec7130")
	var choice_targets: Array[int] = service.choice_target_ids(state)
	var selected: bool = not unit.is_empty() and (
		state.get("selected_ingredients", []).has(int(unit.instance_id))
		or int(state.get("selected_attacker", -1)) == int(unit.instance_id)
		or int(state.get("selected_spice_target", -1)) == int(unit.instance_id)
		or choice_targets.has(int(unit.instance_id))
	)
	var legal_target := _is_obvious_legal_target(unit, zone_name, is_player)
	var ready_to_attack := _unit_is_visibly_ready(unit, zone_name, is_player)
	var border_color := Color("#ffe477") if selected or legal_target else (Color("#58e08b") if ready_to_attack else Color("#113e52"))
	var border_width := 4 if legal_target else (3 if selected or ready_to_attack else 1)
	panel.add_theme_stylebox_override("panel", _panel_style(zone_color if unit.is_empty() else _card_type_color(String(unit.card_type)), border_color, border_width, 3))
	parent.add_child(panel)
	_wire_unit_slot_drag_and_drop(panel, unit, zone_name, is_player)
	drag_drop_targets.append({"control": panel, "highlight_control": panel, "kind": "unit_slot", "unit": unit, "zone": zone_name, "is_player": is_player})
	if unit.is_empty():
		panel.add_child(_center_label("%s %d" % [zone_label.to_upper(), slot_index + 1], 13, Color("#fff4e8")))
		return
	unit_visual_nodes[int(unit.instance_id)] = panel
	_bind_card_panel_inspection(panel, String(unit.card_id), "player" if is_player else "opponent", zone_name, int(unit.instance_id))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	var data: Dictionary = service.card(String(unit.card_id))
	_add_inspect_header(box, data, "player" if is_player else "opponent", zone_name, int(unit.instance_id))
	var meta := "%s  •  %d/%d" % [String(unit.card_type).to_upper(), int(unit.attack), int(unit.health)]
	if String(unit.card_type) == "ingredient":
		meta += "  •  " + service.ingredient_recipe_status(state.player if is_player else state.opponent, unit)
	box.add_child(_label(meta, 10, Color("#fff2cf")))
	if not unit.get("spices", []).is_empty():
		box.add_child(_label("Spice: " + String(service.card(String(unit.spices[0])).get("name", unit.spices[0])), 10, Color("#ffe58a")))
	if legal_target:
		var target_badge := _label("◆ LEGAL TARGET", 11, Color("#fff3a3"))
		target_badge.name = "CookingLegalTarget_%d" % int(unit.instance_id)
		box.add_child(target_badge)
	elif int(state.get("selected_attacker", -1)) == int(unit.instance_id):
		box.add_child(_label("◆ ATTACKER SELECTED", 11, Color("#fff3a3")))
	elif ready_to_attack:
		var ready_badge := _label("● READY TO ATTACK", 11, Color("#a9ffbd"))
		ready_badge.name = "CookingReadyBadge_%d" % int(unit.instance_id)
		box.add_child(ready_badge)
	elif is_player and zone_name == "plated":
		box.add_child(_label("○ SPENT / NOT READY", 10, Color("#d7c7b5")))
	_build_unit_actions(box, unit, zone_name, is_player)


func _build_unit_actions(parent: Node, unit: Dictionary, zone_name: String, is_player: bool) -> void:
	if not state.get("pending_discard", {}).is_empty():
		return
	if not state.get("pending_search", {}).is_empty():
		return
	var pending_choice: Dictionary = state.get("pending_choice", {})
	if not pending_choice.is_empty():
		if service.choice_target_ids(state).has(int(unit.instance_id)):
			var choose_effect_target := _button("Choose Target", true)
			choose_effect_target.name = "CookingEffectTarget_%d" % int(unit.instance_id)
			var effect_target_id := int(unit.instance_id)
			choose_effect_target.pressed.connect(func() -> void:
				service.choose_effect_target(state, effect_target_id)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			parent.add_child(choose_effect_target)
		return
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not is_player:
		if not pending_ability.is_empty():
			var required_target_zone := String(pending_ability.get("target_zone", ""))
			if required_target_zone != "" and zone_name != required_target_zone:
				return
			var choose_target := _button("Choose Target", true)
			choose_target.name = "CookingAbilityTarget_%d" % int(unit.instance_id)
			var ability_target_id := int(unit.instance_id)
			choose_target.pressed.connect(func() -> void:
				service.choose_ability_target(state, ability_target_id)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			parent.add_child(choose_target)
			return
		if zone_name == "plated" and int(state.get("selected_attacker", -1)) >= 0:
			var battle := _button("Battle", true)
			var target_id := int(unit.instance_id)
			battle.pressed.connect(func() -> void:
				service.attack(state, target_id)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			parent.add_child(battle)
		return
	if not pending_ability.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	parent.add_child(row)
	for ability in service.card(String(unit.card_id)).get("abilities", []):
		if String(ability.get("timing", "")) != "activated":
			continue
		var ability_id := String(ability.get("id", "activated"))
		var ability_used: bool = bool(ability.get("once_per_turn", false)) and unit.get("used_abilities", []).has(ability_id)
		var active_zone := String(ability.get("active_zone", ""))
		var wrong_zone := active_zone != "" and active_zone != zone_name
		var ability_label := "Used" if ability_used else ("Plate to Use" if wrong_zone and active_zone == "plated" else "Activate")
		var activate := _button(ability_label, true)
		activate.name = "CookingActivateAbility_%d_%s" % [int(unit.instance_id), ability_id]
		activate.disabled = ability_used or wrong_zone
		var source_instance_id := int(unit.instance_id)
		var selected_ability_id := ability_id
		activate.pressed.connect(func() -> void:
			service.activate_ability(state, source_instance_id, selected_ability_id)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(activate)
	if String(unit.card_type) == "ingredient":
		var recipe := _button("Recipe", true)
		recipe.disabled = service.ingredient_recipe_status(state.player, unit) != "RECIPE READY"
		var ingredient_id := int(unit.instance_id)
		recipe.pressed.connect(func() -> void:
			service.toggle_ingredient_selection(state, ingredient_id)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(recipe)
	if zone_name == "plated":
		var attack := _button("Attack" if bool(unit.ready) else "Spent", true)
		attack.disabled = not bool(unit.ready) or String(state.phase) != "player_main"
		var attacker_id := int(unit.instance_id)
		attack.pressed.connect(func() -> void:
			service.select_attacker(state, attacker_id)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(attack)
	var season := _button("Season", true)
	season.disabled = not unit.get("spices", []).is_empty()
	var target_id := int(unit.instance_id)
	season.pressed.connect(func() -> void:
		service.select_spice_target(state, target_id)
		call_deferred("_refresh")
	, CONNECT_DEFERRED)
	row.add_child(season)
	var destination := "prep" if zone_name == "plated" else "plated"
	var move := _button("Move " + destination.capitalize(), true)
	move.disabled = bool(state.player.zone_move_used) or state.player[destination].size() >= (service.PREP_SLOTS if destination == "prep" else service.PLATED_SLOTS)
	var moving_id := int(unit.instance_id)
	var selected_destination := destination
	move.pressed.connect(func() -> void:
		service.move_unit(state, moving_id, selected_destination)
		call_deferred("_refresh")
	, CONNECT_DEFERRED)
	row.add_child(move)


func _build_piles(parent: Node, combatant: Dictionary) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(145, 0)
	column.add_theme_constant_override("separation", 7)
	parent.add_child(column)
	var discard := _zone_container(column, "DISCARD", Vector2(145, 72), Color("#ec7130"))
	discard.add_child(_center_label(str(combatant.discard.size()), 22, Color.WHITE))
	var deck := _zone_container(column, "DECK", Vector2(145, 72), Color("#ec7130"))
	deck.add_child(_center_label(str(combatant.deck.size()), 22, Color.WHITE))


func _build_message_strip() -> void:
	var panel := PanelContainer.new()
	panel.name = "CookingMessagePanel"
	panel.custom_minimum_size = Vector2(0, 55)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#173e52"), Color("#0c2d3b"), 1, 4))
	root_box.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var message := _label(String(state.message), 15, Color("#fff4df"))
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(message)
	var recent := _label("  •  ".join(state.log.slice(maxi(0, state.log.size() - 2))), 11, Color("#bbd4df"))
	recent.custom_minimum_size.x = 420
	recent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(recent)


func _build_hand() -> void:
	var panel := PanelContainer.new()
	panel.name = "CookingPlayerHand"
	panel.custom_minimum_size = Vector2(0, 135)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#e7e0cf"), Color("#9b8e72"), 1, 4))
	root_box.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var pending: Dictionary = state.get("pending_discard", {})
	var pending_search: Dictionary = state.get("pending_search", {})
	var pending_choice: Dictionary = state.get("pending_choice", {})
	var hand_heading := "YOUR HAND — drag units to Prep/Plated • drag Spices onto cards • drag Environments to their zone"
	if not pending.is_empty():
		hand_heading = "SELECT DISCARD COST — %d/%d selected" % [pending.get("selected_indices", []).size(), int(pending.get("required", 0))]
	elif String(pending_choice.get("choice_kind", "")) == "discard":
		hand_heading = "CHOOSE FROM YOUR DISCARD — %d/%d selected" % [pending_choice.get("selected_indices", []).size(), int(pending_choice.get("required", 0))]
	elif String(pending_choice.get("choice_kind", "")) == "opponent_hand":
		hand_heading = "OPPONENT'S REVEALED HAND — choose a unit"
	elif not pending_search.is_empty():
		hand_heading = ("REVEALED FROM THE TOP OF YOUR DECK — " if pending_search.has("revealed_cards") else "SEARCH YOUR DECK — ") + String(pending_search.get("prompt", "Choose a card."))
	column.add_child(_label(hand_heading, 14, Color("#30454d")))
	if String(pending_choice.get("choice_kind", "")) == "discard":
		_build_discard_choice_cards(column)
		return
	if String(pending_choice.get("choice_kind", "")) == "opponent_hand":
		_build_opponent_hand_choices(column)
		return
	if not pending_search.is_empty():
		_build_search_choices(column)
		return
	if state.player.hand.is_empty():
		var empty_text := "No cards are available. Check data/cards.json." if not service.has_playable_content() else "Your hand is empty."
		column.add_child(_center_label(empty_text, 16, Color("#756d5c")))
		return
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	for hand_index in range(state.player.hand.size()):
		_add_hand_card(row, hand_index, String(state.player.hand[hand_index]))


func _build_discard_choice_cards(parent: Node) -> void:
	var pending: Dictionary = state.get("pending_choice", {})
	var eligible: Array[int] = service.discard_choice_indices(state)
	var selected: Array = pending.get("selected_indices", [])
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	for discard_index in eligible:
		var card_id := String(state.player.discard[discard_index])
		var data: Dictionary = service.card(card_id)
		var panel := PanelContainer.new()
		panel.name = "CookingDiscardPileChoice_%d" % discard_index
		panel.custom_minimum_size = Vector2(190, 92)
		panel.add_theme_stylebox_override("panel", _panel_style(_card_type_color(String(data.card_type)), Color("#ffe477") if selected.has(discard_index) else Color("#173e52"), 2 if selected.has(discard_index) else 1, 3))
		row.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_bottom", 3)
		panel.add_child(margin)
		var box := VBoxContainer.new()
		margin.add_child(box)
		_add_inspect_header(box, data, "player", "discard")
		box.add_child(_label(String(data.get("card_type", "card")).capitalize(), 10, Color("#fff0d4")))
		var select := _button("Selected" if selected.has(discard_index) else "Select", true)
		select.name = "CookingSelectDiscardPile_%d" % discard_index
		var selected_discard_index := discard_index
		select.pressed.connect(func() -> void:
			service.toggle_discard_choice(state, selected_discard_index)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		box.add_child(select)


func _build_opponent_hand_choices(parent: Node) -> void:
	var eligible: Array[int] = service.opponent_hand_choice_indices(state)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	for hand_index in range(state.opponent.hand.size()):
		var card_id := String(state.opponent.hand[hand_index])
		var data: Dictionary = service.card(card_id)
		var can_choose := eligible.has(hand_index)
		var panel := PanelContainer.new()
		panel.name = "CookingOpponentHandChoice_%d" % hand_index
		panel.custom_minimum_size = Vector2(190, 92)
		panel.add_theme_stylebox_override("panel", _panel_style(_card_type_color(String(data.card_type)), Color("#ffe477") if can_choose else Color("#68736c"), 2 if can_choose else 1, 3))
		row.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_bottom", 3)
		panel.add_child(margin)
		var box := VBoxContainer.new()
		margin.add_child(box)
		_add_inspect_header(box, data, "opponent", "revealed_hand")
		box.add_child(_label(String(data.get("card_type", "card")).capitalize(), 10, Color("#fff0d4")))
		var choose := _button("Put on Field" if can_choose else "Not a Unit", true)
		choose.name = "CookingChooseOpponentHand_%d" % hand_index
		choose.disabled = not can_choose
		var selected_hand_index := hand_index
		choose.pressed.connect(func() -> void:
			service.choose_opponent_hand_card(state, selected_hand_index)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		box.add_child(choose)


func _build_search_choices(parent: Node) -> void:
	var display_cards: Array[String] = service.search_display_cards(state)
	var candidates: Array[String] = service.search_candidates(state)
	if display_cards.is_empty():
		parent.add_child(_center_label("No matching cards remain in your deck.", 16, Color("#756d5c")))
		return
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	var is_top_reveal: bool = state.get("pending_search", {}).has("revealed_cards")
	for reveal_index in range(display_cards.size()):
		var card_id := String(display_cards[reveal_index])
		_add_search_choice(row, card_id, candidates.has(card_id), reveal_index if is_top_reveal else -1, display_cards.size())


func _add_search_choice(parent: Node, card_id: String, can_take: bool = true, reveal_index: int = -1, reveal_count: int = 0) -> void:
	var data: Dictionary = service.card(card_id)
	var panel := PanelContainer.new()
	panel.name = "CookingSearchChoice_%s" % card_id
	panel.custom_minimum_size = Vector2(190, 92)
	panel.add_theme_stylebox_override("panel", _panel_style(_card_type_color(String(data.card_type)), Color("#ffe477"), 2, 3))
	parent.add_child(panel)
	_bind_card_panel_inspection(panel, card_id, "player", "search")
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	_add_inspect_header(box, data, "player", "search")
	var copies: int = state.player.deck.count(card_id)
	var meta := "%s • %s • %d cop%s" % [String(data.get("archetype", "neutral")).capitalize(), String(data.card_type).capitalize(), copies, "y" if copies == 1 else "ies"]
	if reveal_index >= 0:
		meta = "Top card %d of %d • %s" % [reveal_index + 1, reveal_count, String(data.card_type).capitalize()]
	box.add_child(_label(meta, 10, Color("#fff0d4")))
	var take := _button("Add to Hand" if can_take else "Not a Tool", true)
	take.name = "CookingTakeSearchCard_%s" % card_id
	take.disabled = not can_take
	var selected_card_id := card_id
	take.pressed.connect(func() -> void:
		service.select_search_card(state, selected_card_id)
		call_deferred("_refresh")
	, CONNECT_DEFERRED)
	box.add_child(take)


func _add_hand_card(parent: Node, hand_index: int, card_id: String) -> void:
	var data: Dictionary = service.card(card_id)
	var pending: Dictionary = state.get("pending_discard", {})
	var selected_for_discard: bool = not pending.is_empty() and pending.get("selected_indices", []).has(hand_index)
	var panel := PanelContainer.new()
	panel.name = "CookingHandCard_%d" % hand_index
	panel.custom_minimum_size = Vector2(175, 92)
	panel.add_theme_stylebox_override("panel", _panel_style(
		_card_type_color(String(data.card_type)),
		Color("#ffe477") if selected_for_discard else Color("#173e52"),
		3 if selected_for_discard else 1,
		3
	))
	parent.add_child(panel)
	hand_visual_nodes[hand_index] = panel
	_wire_hand_card_drag(panel, hand_index, card_id)
	_bind_card_panel_inspection(panel, card_id, "player", "hand")
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	_add_inspect_header(box, data, "player", "hand")
	if bool(data.get("rare", false)):
		box.add_child(_label("RARE", 9, Color("#ffe477")))
	var rules := String(data.get("text", ""))
	if String(data.card_type) == "meal":
		rules = service.recipe_status(state, card_id)
	box.add_child(_label(rules, 10, Color("#fff0d4")))
	var row := HBoxContainer.new()
	box.add_child(row)
	if not state.get("pending_choice", {}).is_empty():
		return
	if not pending.is_empty():
		if hand_index == int(pending.get("hand_index", -1)):
			var pending_item := _button("Item Pending", true)
			pending_item.name = "CookingPendingDiscardItem"
			pending_item.disabled = true
			row.add_child(pending_item)
		else:
			var discard_choice := _button("Selected" if selected_for_discard else "Select Discard", true)
			discard_choice.name = "CookingDiscardChoice_%d" % hand_index
			var selected_hand_index := hand_index
			discard_choice.pressed.connect(func() -> void:
				service.toggle_discard_card(state, selected_hand_index)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			row.add_child(discard_choice)
		return
	if String(data.card_type) == "ingredient":
		for destination in ["prep", "plated"]:
			var play := _button("Play " + destination.capitalize(), true)
			var selected_destination := String(destination)
			play.pressed.connect(func() -> void:
				service.play_card(state, hand_index, selected_destination)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			row.add_child(play)
	elif String(data.card_type) == "meal":
		for destination in ["prep", "plated"]:
			var serve := _button("Serve " + destination.capitalize(), true)
			serve.disabled = bool(state.player.get("meal_served", false))
			var selected_destination := String(destination)
			serve.pressed.connect(func() -> void:
				service.play_card(state, hand_index, selected_destination)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			row.add_child(serve)
	else:
		var play := _button(_hand_action_label(String(data.card_type)), true)
		play.name = "CookingPlayHandCard_%d_%s" % [hand_index, card_id]
		play.pressed.connect(func() -> void:
			service.play_card(state, hand_index)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(play)


func _build_action_bar() -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 34)
	row.add_theme_constant_override("separation", 7)
	root_box.add_child(row)
	var pending: Dictionary = state.get("pending_discard", {})
	if not pending.is_empty():
		var selected_count: int = pending.get("selected_indices", []).size()
		var required_count := int(pending.get("required", 0))
		var item_name := String(service.card(String(pending.get("card_id", ""))).get("name", "Item"))
		var discard_status := _label("Discard payment for %s: %d/%d selected" % [item_name, selected_count, required_count], 14, Color("#30454d"))
		discard_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(discard_status)
		var cancel := _button("Cancel")
		cancel.name = "CookingCancelDiscardButton"
		cancel.pressed.connect(func() -> void:
			service.cancel_discard_cost(state)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(cancel)
		var confirm := _button("Discard & Use Item")
		confirm.name = "CookingConfirmDiscardButton"
		confirm.disabled = selected_count != required_count
		confirm.pressed.connect(func() -> void:
			service.confirm_discard_cost(state)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(confirm)
		return
	var pending_choice: Dictionary = state.get("pending_choice", {})
	if not pending_choice.is_empty():
		var choice_text := String(pending_choice.get("prompt", "Choose a highlighted card."))
		if String(pending_choice.get("choice_kind", "")) == "discard":
			choice_text += "  %d/%d selected" % [pending_choice.get("selected_indices", []).size(), int(pending_choice.get("required", 0))]
		var choice_status := _label(choice_text, 14, Color("#30454d"))
		choice_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(choice_status)
		if String(pending_choice.get("choice_kind", "")) == "discard":
			var confirm_choice := _button("Confirm Selection")
			confirm_choice.name = "CookingConfirmDiscardPileButton"
			confirm_choice.disabled = pending_choice.get("selected_indices", []).size() != int(pending_choice.get("required", 0))
			confirm_choice.pressed.connect(func() -> void:
				service.confirm_discard_choice(state)
				call_deferred("_refresh")
			, CONNECT_DEFERRED)
			row.add_child(confirm_choice)
		var skip_effect := _button("Skip Effect")
		skip_effect.name = "CookingSkipEffectButton"
		skip_effect.pressed.connect(func() -> void:
			service.skip_effect_choice(state)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(skip_effect)
		return
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not pending_ability.is_empty():
		var source: Dictionary = service._find_unit(state.player, int(pending_ability.get("source_instance_id", -1)))
		var source_name := String(source.get("name", "Card"))
		var target_zone := String(pending_ability.get("target_zone", ""))
		var target_description := target_zone.capitalize() if target_zone != "" else "Prep or Plated"
		var ability_status := _label("Choose an opposing %s target for %s" % [target_description, source_name], 14, Color("#30454d"))
		ability_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ability_status)
		var cancel_ability := _button("Cancel Ability")
		cancel_ability.name = "CookingCancelAbilityButton"
		cancel_ability.pressed.connect(func() -> void:
			service.cancel_ability_target(state)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(cancel_ability)
		return
	var pending_search: Dictionary = state.get("pending_search", {})
	if not pending_search.is_empty():
		var queued_searches: int = state.get("search_queue", []).size()
		var search_status_text := String(pending_search.get("prompt", "Choose a card from your deck."))
		if queued_searches > 0:
			search_status_text += "  •  %d more search%s after this" % [queued_searches, "" if queued_searches == 1 else "es"]
		var search_status := _label(search_status_text, 14, Color("#30454d"))
		search_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(search_status)
		var skip_label := "Take No Tool" if pending_search.has("revealed_cards") and not service.search_candidates(state).is_empty() else ("Continue" if pending_search.has("revealed_cards") else "Skip Search")
		var skip := _button(skip_label)
		skip.name = "CookingSkipSearchButton"
		skip.pressed.connect(func() -> void:
			service.skip_search(state)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(skip)
		return
	var status_text := "Awaiting your card list" if String(state.phase) == "awaiting_cards" else "Selected ingredients: %d" % state.selected_ingredients.size()
	var status := _label(status_text, 14, Color("#30454d"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)
	if int(state.get("selected_attacker", -1)) >= 0:
		var attacker: Dictionary = service._find_unit_in_zone(state.player, "plated", int(state.selected_attacker))
		var has_stalwart: bool = not attacker.is_empty() and service.card(String(attacker.card_id)).get("keywords", []).has("stalwart")
		var blocked: bool = not service.can_attack_opposing_chef(state)
		var face_label := "Clear Plated Cards First" if blocked else ("Attack Opposing Chef — Stalwart" if has_stalwart and not state.opponent.plated.is_empty() else "Attack Opposing Chef")
		var face := _button(face_label)
		face.name = "CookingAttackChefButton"
		face.disabled = blocked
		face.pressed.connect(func() -> void:
			service.attack(state, -1)
			call_deferred("_refresh")
		, CONNECT_DEFERRED)
		row.add_child(face)
	var end_turn := _button("End Turn")
	end_turn.name = "CookingEndTurnButton"
	end_turn.disabled = String(state.phase) != "player_main"
	end_turn.pressed.connect(func() -> void:
		service.end_player_turn(state)
		call_deferred("_refresh")
	, CONNECT_DEFERRED)
	row.add_child(end_turn)


func _wire_hand_card_drag(control: Control, hand_index: int, card_id: String) -> void:
	control.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			if not _dragging_allowed():
				return null
			var data: Dictionary = service.card(card_id)
			if String(data.get("card_type", "")) not in ["ingredient", "meal", "spice", "environment"]:
				return null
			var payload: Dictionary = {"kind": "hand_card", "hand_index": hand_index, "card_id": card_id}
			_begin_drag_feedback(payload, control)
			control.set_drag_preview(_make_drag_preview(card_id, "From your hand"))
			return payload,
		func(_at_position: Vector2, _data: Variant) -> bool:
			return false,
		func(_at_position: Vector2, _data: Variant) -> void:
			pass
	)


func _wire_unit_slot_drag_and_drop(control: Control, unit: Dictionary, zone_name: String, is_player: bool) -> void:
	control.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			if not is_player or unit.is_empty() or not _dragging_allowed():
				return null
			var payload: Dictionary = {
				"kind": "unit",
				"instance_id": int(unit.instance_id),
				"card_id": String(unit.card_id),
				"from_zone": zone_name
			}
			_begin_drag_feedback(payload, control)
			control.set_drag_preview(_make_drag_preview(String(unit.card_id), "From %s" % zone_name.capitalize()))
			return payload,
		func(_at_position: Vector2, data: Variant) -> bool:
			return _can_drop_on_unit_slot(data, unit, zone_name, is_player),
		func(_at_position: Vector2, data: Variant) -> void:
			_drop_on_unit_slot(data, unit, zone_name, is_player)
	)
	if unit.is_empty():
		control.tooltip_text = "Drop a unit here"
	elif is_player:
		control.tooltip_text = "Drag to the other zone, or drag a Spice onto this card"
	elif zone_name == "plated":
		control.tooltip_text = "Drag a ready Plated attacker here to battle"


func _wire_unit_zone_drop(control: Control, zone_name: String) -> void:
	control.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			return null,
		func(_at_position: Vector2, data: Variant) -> bool:
			return _can_drop_on_unit_slot(data, {}, zone_name, true),
		func(_at_position: Vector2, data: Variant) -> void:
			_drop_on_unit_slot(data, {}, zone_name, true)
	)
	control.tooltip_text = "Drop an Ingredient or Meal here"


func _wire_environment_drop(control: Control) -> void:
	control.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			return null,
		func(_at_position: Vector2, data: Variant) -> bool:
			return _can_drop_environment(data),
		func(_at_position: Vector2, data: Variant) -> void:
			_drop_environment(data)
	)
	control.tooltip_text = "Drop an Environment card here"


func _wire_opponent_face_drop(control: Control) -> void:
	control.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			return null,
		func(_at_position: Vector2, data: Variant) -> bool:
			return _can_drop_on_opponent_face(data),
		func(_at_position: Vector2, data: Variant) -> void:
			_drop_on_opponent_face(data)
	)
	control.tooltip_text = "Drop a ready Plated attacker here to attack the opposing chef"


func _can_drop_on_unit_slot(data: Variant, target_unit: Dictionary, zone_name: String, is_player: bool) -> bool:
	if not _dragging_allowed() or typeof(data) != TYPE_DICTIONARY:
		return false
	match String(data.get("kind", "")):
		"hand_card":
			if not is_player:
				return false
			var hand_index := _resolve_drag_hand_index(data)
			if hand_index < 0:
				return false
			var card_type := String(service.card(String(state.player.hand[hand_index])).get("card_type", ""))
			if card_type == "spice":
				return not target_unit.is_empty() and target_unit.get("spices", []).is_empty()
			if card_type == "ingredient":
				return state.player[zone_name].size() < (service.PREP_SLOTS if zone_name == "prep" else service.PLATED_SLOTS)
			if card_type == "meal":
				if bool(state.player.get("meal_served", false)):
					return false
				var meal_data: Dictionary = service.card(String(state.player.hand[hand_index]))
				var recipe: Array = service._effective_recipe(state, "player", meal_data)
				var chosen: Array = state.get("selected_ingredients", []).duplicate()
				if chosen.is_empty():
					chosen = service._find_recipe_ingredients(state.player, recipe)
				if not service._selection_satisfies(state.player, chosen, recipe):
					return false
				var ingredients_in_destination := 0
				for instance_id in chosen:
					if not service._find_unit_in_zone(state.player, zone_name, int(instance_id)).is_empty():
						ingredients_in_destination += 1
				var capacity: int = service.PREP_SLOTS if zone_name == "prep" else service.PLATED_SLOTS
				return state.player[zone_name].size() - ingredients_in_destination + 1 <= capacity
		"unit":
			var source_id := int(data.get("instance_id", -1))
			var from_zone := String(data.get("from_zone", ""))
			var source: Dictionary = service._find_unit_in_zone(state.player, from_zone, source_id)
			if source.is_empty():
				return false
			if is_player:
				return from_zone != zone_name and state.player[zone_name].size() < (service.PREP_SLOTS if zone_name == "prep" else service.PLATED_SLOTS) and not bool(state.player.get("zone_move_used", false))
			if zone_name != "plated" or target_unit.is_empty() or from_zone != "plated" or not bool(source.get("ready", false)) or service._opening_attack_lock(state, "player"):
				return false
			var taunt_unit: Dictionary = service._first_plated_with_keyword(state.opponent, "taunt")
			return taunt_unit.is_empty() or int(taunt_unit.instance_id) == int(target_unit.instance_id)
	return false


func _drop_on_unit_slot(data: Variant, target_unit: Dictionary, zone_name: String, is_player: bool) -> void:
	if not _can_drop_on_unit_slot(data, target_unit, zone_name, is_player):
		return
	drag_drop_accepted = true
	if String(data.get("kind", "")) == "hand_card":
		var hand_index := _resolve_drag_hand_index(data)
		var card_type := String(service.card(String(state.player.hand[hand_index])).get("card_type", ""))
		if card_type == "spice":
			service.select_spice_target(state, int(target_unit.instance_id))
			service.play_card(state, hand_index)
		else:
			service.play_card(state, hand_index, zone_name)
	else:
		var source_id := int(data.get("instance_id", -1))
		if is_player:
			service.move_unit(state, source_id, zone_name)
		else:
			service.select_attacker(state, source_id)
			service.attack(state, int(target_unit.instance_id))
	call_deferred("_refresh")


func _can_drop_environment(data: Variant) -> bool:
	if not _dragging_allowed() or typeof(data) != TYPE_DICTIONARY or String(data.get("kind", "")) != "hand_card":
		return false
	var hand_index := _resolve_drag_hand_index(data)
	return hand_index >= 0 and String(service.card(String(state.player.hand[hand_index])).get("card_type", "")) == "environment"


func _drop_environment(data: Variant) -> void:
	if not _can_drop_environment(data):
		return
	drag_drop_accepted = true
	service.play_card(state, _resolve_drag_hand_index(data))
	call_deferred("_refresh")


func _can_drop_on_opponent_face(data: Variant) -> bool:
	if not _dragging_allowed() or typeof(data) != TYPE_DICTIONARY or String(data.get("kind", "")) != "unit" or String(data.get("from_zone", "")) != "plated":
		return false
	var attacker_id := int(data.get("instance_id", -1))
	var attacker: Dictionary = service._find_unit_in_zone(state.player, "plated", attacker_id)
	return not attacker.is_empty() and bool(attacker.get("ready", false)) and not service._opening_attack_lock(state, "player") and service.can_attack_opposing_chef(state, attacker_id)


func _drop_on_opponent_face(data: Variant) -> void:
	if not _can_drop_on_opponent_face(data):
		return
	drag_drop_accepted = true
	var attacker_id := int(data.get("instance_id", -1))
	service.select_attacker(state, attacker_id)
	service.attack(state, -1)
	call_deferred("_refresh")


func _resolve_drag_hand_index(data: Dictionary) -> int:
	var expected_card_id := String(data.get("card_id", ""))
	var hand_index := int(data.get("hand_index", -1))
	if hand_index >= 0 and hand_index < state.player.hand.size() and String(state.player.hand[hand_index]) == expected_card_id:
		return hand_index
	return state.player.hand.find(expected_card_id)


func _dragging_allowed() -> bool:
	return String(state.get("phase", "")) == "player_main" and not bool(state.get("game_over", false)) and state.get("pending_discard", {}).is_empty() and state.get("pending_ability", {}).is_empty() and state.get("pending_search", {}).is_empty() and state.get("pending_choice", {}).is_empty()


func _unit_is_visibly_ready(unit: Dictionary, zone_name: String, is_player: bool) -> bool:
	return is_player and not unit.is_empty() and zone_name == "plated" and bool(unit.get("ready", false)) and String(state.get("phase", "")) == "player_main" and not service._opening_attack_lock(state, "player") and state.get("pending_discard", {}).is_empty() and state.get("pending_ability", {}).is_empty() and state.get("pending_search", {}).is_empty() and state.get("pending_choice", {}).is_empty()


func _is_obvious_legal_target(unit: Dictionary, zone_name: String, is_player: bool) -> bool:
	if unit.is_empty():
		return false
	var instance_id := int(unit.get("instance_id", -1))
	if service.choice_target_ids(state).has(instance_id):
		return true
	var pending_ability: Dictionary = state.get("pending_ability", {})
	if not is_player and not pending_ability.is_empty():
		var target_zone := String(pending_ability.get("target_zone", ""))
		return target_zone == "" or target_zone == zone_name
	if is_player or zone_name != "plated" or int(state.get("selected_attacker", -1)) < 0:
		return false
	var attacker_id := int(state.get("selected_attacker", -1))
	var attacker: Dictionary = service._find_unit_in_zone(state.player, "plated", attacker_id)
	if attacker.is_empty() or not bool(attacker.get("ready", false)):
		return false
	var taunt_unit: Dictionary = service._first_plated_with_keyword(state.opponent, "taunt")
	return taunt_unit.is_empty() or int(taunt_unit.instance_id) == instance_id


func _capture_visual_snapshot() -> Dictionary:
	if state.is_empty():
		return {}
	var snapshot := {
		"turn": int(state.get("turn", 0)),
		"phase": String(state.get("phase", "")),
		"selected_ingredients": state.get("selected_ingredients", []).duplicate(),
		"player": _capture_side_visual_snapshot("player"),
		"opponent": _capture_side_visual_snapshot("opponent")
	}
	return snapshot


func _capture_side_visual_snapshot(side: String) -> Dictionary:
	var combatant: Dictionary = state.get(side, {})
	var units: Dictionary = {}
	for zone_name in ["prep", "plated"]:
		for unit in combatant.get(zone_name, []):
			var instance_id := int(unit.get("instance_id", -1))
			units[instance_id] = {
				"instance_id": instance_id,
				"card_id": String(unit.get("card_id", "")),
				"name": String(unit.get("name", "Card")),
				"card_type": String(unit.get("card_type", "")),
				"zone": zone_name,
				"health": int(unit.get("health", 0)),
				"attack": int(unit.get("attack", 0))
			}
	return {
		"life": int(combatant.get("life", 0)),
		"hand": combatant.get("hand", []).duplicate(),
		"environment": String(combatant.get("environment", "")),
		"units": units
	}


func _collect_visual_events(previous: Dictionary, current: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if previous.is_empty() or current.is_empty():
		return events
	if int(previous.get("turn", 0)) != int(current.get("turn", 0)) or String(previous.get("phase", "")) != String(current.get("phase", "")):
		events.append({"type": "turn", "phase": String(current.get("phase", "")), "turn": int(current.get("turn", 0))})
	for side in ["player", "opponent"]:
		var old_side: Dictionary = previous.get(side, {})
		var new_side: Dictionary = current.get(side, {})
		var old_units: Dictionary = old_side.get("units", {})
		var new_units: Dictionary = new_side.get("units", {})
		var meal_entered := false
		for instance_id in new_units.keys():
			if not old_units.has(instance_id):
				var entered: Dictionary = new_units[instance_id]
				events.append({"type": "enter", "side": side, "instance_id": instance_id, "unit": entered})
				meal_entered = meal_entered or String(entered.get("card_type", "")) == "meal"
			elif int(new_units[instance_id].get("health", 0)) < int(old_units[instance_id].get("health", 0)):
				events.append({
					"type": "damage",
					"side": side,
					"instance_id": instance_id,
					"amount": int(old_units[instance_id].get("health", 0)) - int(new_units[instance_id].get("health", 0))
				})
		for instance_id in old_units.keys():
			if new_units.has(instance_id):
				continue
			var removed: Dictionary = old_units[instance_id]
			events.append({
				"type": "sacrifice" if meal_entered and String(removed.get("card_type", "")) == "ingredient" else "destroy",
				"side": side,
				"instance_id": instance_id,
				"unit": removed
			})
		var old_life := int(old_side.get("life", 0))
		var new_life := int(new_side.get("life", 0))
		if new_life < old_life:
			events.append({"type": "life_damage", "side": side, "amount": old_life - new_life})
		if String(old_side.get("environment", "")) != String(new_side.get("environment", "")) and String(new_side.get("environment", "")) != "":
			events.append({"type": "environment", "side": side})
	var old_hand: Array = previous.get("player", {}).get("hand", [])
	var new_hand: Array = current.get("player", {}).get("hand", [])
	var unmatched_old_hand := old_hand.duplicate()
	var added_card_count := 0
	for card_id in new_hand:
		var old_match_index := unmatched_old_hand.find(card_id)
		if old_match_index >= 0:
			unmatched_old_hand.remove_at(old_match_index)
		else:
			added_card_count += 1
	if added_card_count > 0:
		for hand_index in range(maxi(0, new_hand.size() - added_card_count), new_hand.size()):
			events.append({"type": "draw", "hand_index": hand_index})
	return events


func _capture_removed_event_geometry(events: Array[Dictionary]) -> void:
	for event in events:
		if String(event.get("type", "")) not in ["destroy", "sacrifice"]:
			continue
		var control: Control = unit_visual_nodes.get(int(event.get("instance_id", -1)))
		if is_instance_valid(control):
			event.rect = Rect2(control.global_position, control.size)


func _play_visual_events(events: Array[Dictionary]) -> void:
	for event in events:
		match String(event.get("type", "")):
			"enter":
				_animate_card_entry(unit_visual_nodes.get(int(event.get("instance_id", -1))))
			"draw":
				_animate_card_draw(hand_visual_nodes.get(int(event.get("hand_index", -1))))
			"damage":
				_animate_damage(unit_visual_nodes.get(int(event.get("instance_id", -1))), int(event.get("amount", 0)))
			"life_damage":
				_animate_life_damage(board_visual_nodes.get(String(event.get("side", ""))), int(event.get("amount", 0)))
			"destroy", "sacrifice":
				_animate_removed_card(event)
			"environment":
				_animate_card_entry(environment_visual_nodes.get(String(event.get("side", ""))))
			"turn":
				var player_turn := String(event.get("phase", "")) == "player_main"
				_show_floating_feedback("YOUR TURN • TURN %d" % int(event.get("turn", 0)) if player_turn else "OPPONENT'S TURN", Color("#238052") if player_turn else Color("#8c4338"), 1.2)


func _animate_card_entry(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.72, 0.72)
	control.modulate.a = 0.2
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.32)
	tween.tween_property(control, "modulate:a", 1.0, 0.2)


func _animate_card_draw(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.82, 0.82)
	control.modulate = Color(1.25, 1.2, 0.75, 0.15)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.38)
	tween.tween_property(control, "modulate", Color.WHITE, 0.3)


func _animate_damage(control: Control, amount: int) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "rotation", -0.05, 0.05)
	tween.parallel().tween_property(control, "modulate", Color(1.5, 0.42, 0.35, 1.0), 0.05)
	tween.tween_property(control, "rotation", 0.045, 0.06)
	tween.tween_property(control, "rotation", 0.0, 0.08)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.16)
	_spawn_floating_number(control.global_position + control.size * 0.5, "-%d" % amount, Color("#ff5a47"))


func _animate_life_damage(control: Control, amount: int) -> void:
	if not is_instance_valid(control):
		return
	var original_modulate := control.modulate
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color(1.35, 0.45, 0.4, 1.0), 0.08)
	tween.tween_property(control, "modulate", original_modulate, 0.28)
	_spawn_floating_number(control.global_position + Vector2(control.size.x * 0.5, 28), "-%d LIFE" % amount, Color("#d92f27"))


func _animate_removed_card(event: Dictionary) -> void:
	if not event.has("rect"):
		return
	var rect: Rect2 = event.rect
	var unit: Dictionary = event.get("unit", {})
	var ghost := PanelContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 260
	ghost.position = rect.position - global_position
	ghost.size = rect.size
	ghost.pivot_offset = ghost.size * 0.5
	ghost.add_theme_stylebox_override("panel", _panel_style(_card_type_color(String(unit.get("card_type", ""))), Color("#ffec82"), 3, 4))
	var text := "%s\n%s" % [String(unit.get("name", "Card")), "SACRIFICED" if String(event.get("type", "")) == "sacrifice" else "DESTROYED"]
	var label := _center_label(text, 14, Color.WHITE)
	ghost.add_child(label)
	add_child(ghost)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "scale", Vector2(0.45, 0.45), 0.45)
	tween.tween_property(ghost, "rotation", 0.1 if String(event.get("type", "")) == "sacrifice" else -0.14, 0.45)
	tween.tween_property(ghost, "position:y", ghost.position.y - (55.0 if String(event.get("type", "")) == "sacrifice" else 20.0), 0.45)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.45).set_delay(0.12)
	tween.chain().tween_callback(ghost.queue_free)


func _spawn_floating_number(global_at: Vector2, text: String, color: Color) -> void:
	var number := _label(text, 24, color)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.z_index = 310
	number.position = global_at - global_position - Vector2(45, 14)
	number.custom_minimum_size = Vector2(90, 30)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_constant_override("outline_size", 5)
	number.add_theme_color_override("font_outline_color", Color("#27120f"))
	add_child(number)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - 52.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.65).set_delay(0.2)
	tween.chain().tween_callback(number.queue_free)


func _animate_status_attention() -> void:
	for instance_id in unit_visual_nodes.keys():
		var control: Control = unit_visual_nodes[instance_id]
		var unit: Dictionary = service._find_unit(state.player, int(instance_id))
		if unit.is_empty():
			unit = service._find_unit(state.opponent, int(instance_id))
		var zone_name: String = service._unit_zone(state.player, int(instance_id))
		var is_player: bool = zone_name != ""
		if not is_player:
			zone_name = service._unit_zone(state.opponent, int(instance_id))
		if _is_obvious_legal_target(unit, zone_name, is_player):
			var tween := create_tween()
			tween.tween_property(control, "modulate", Color(1.18, 1.12, 0.72, 1.0), 0.18)
			tween.tween_property(control, "modulate", Color.WHITE, 0.22)


func _begin_drag_feedback(payload: Dictionary, source: Control) -> void:
	_clear_drag_highlights()
	active_drag_payload = payload.duplicate(true)
	active_drag_source = source
	drag_drop_accepted = false
	for target in drag_drop_targets:
		var target_control: Control = target.get("highlight_control", target.get("control"))
		if not is_instance_valid(target_control):
			continue
		var legal := false
		if String(target.get("kind", "")) == "environment":
			legal = _can_drop_environment(payload)
		elif String(target.get("kind", "")) == "opponent_face":
			legal = _can_drop_on_opponent_face(payload)
		else:
			legal = _can_drop_on_unit_slot(payload, target.get("unit", {}), String(target.get("zone", "")), bool(target.get("is_player", false)))
		var restore := {"control": target_control, "modulate": target_control.modulate}
		if target_control is PanelContainer:
			restore.style = target_control.get_theme_stylebox("panel")
		drag_highlight_restore.append(restore)
		target_control.modulate = Color(1.16, 1.16, 1.05, 1.0) if legal else Color(0.48, 0.48, 0.48, 0.72)
		if legal and target_control is PanelContainer:
			var base_style: StyleBox = target_control.get_theme_stylebox("panel")
			if base_style is StyleBoxFlat:
				var highlight_style: StyleBoxFlat = base_style.duplicate()
				highlight_style.border_color = Color("#fff06a")
				highlight_style.border_width_left = 5
				highlight_style.border_width_right = 5
				highlight_style.border_width_top = 5
				highlight_style.border_width_bottom = 5
				target_control.add_theme_stylebox_override("panel", highlight_style)
	_show_drag_hint(payload)


func _finish_drag_feedback() -> void:
	_clear_drag_highlights()
	if not drag_drop_accepted:
		_animate_snap_back(active_drag_source)
		_show_floating_feedback(_invalid_drop_message(active_drag_payload), Color("#b84135"))
	active_drag_payload = {}
	active_drag_source = null
	drag_drop_accepted = false


func _clear_drag_highlights() -> void:
	for restore in drag_highlight_restore:
		var control: Control = restore.get("control")
		if not is_instance_valid(control):
			continue
		control.modulate = restore.get("modulate", Color.WHITE)
		if control is PanelContainer and restore.has("style"):
			control.add_theme_stylebox_override("panel", restore.style)
	drag_highlight_restore.clear()


func _show_drag_hint(payload: Dictionary) -> void:
	var card_type := "unit"
	if String(payload.get("kind", "")) == "hand_card":
		card_type = String(service.card(String(payload.get("card_id", ""))).get("card_type", "card"))
	var hint := "Highlighted zones are legal drops."
	match card_type:
		"environment":
			hint = "Drop this Environment into your highlighted Environment zone."
		"spice":
			hint = "Drop this Spice onto a highlighted friendly unit."
		"ingredient", "meal":
			hint = "Drop this card into a highlighted Prep or Plated slot."
	_show_floating_feedback(hint, Color("#286b87"), 1.0)


func _invalid_drop_message(payload: Dictionary) -> String:
	if String(payload.get("kind", "")) == "unit":
		return "That move or attack is not legal. The card returned to its zone."
	var card_type := String(service.card(String(payload.get("card_id", ""))).get("card_type", "card"))
	match card_type:
		"environment":
			return "Environments must be dropped into your Environment zone."
		"spice":
			return "Spices must be dropped onto an unseasoned friendly unit."
		"ingredient", "meal":
			return "That unit cannot be played there. Check the highlighted zones and available slots."
	return "That card cannot be dropped there."


func _animate_snap_back(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(0.9, 0.9), 0.06)
	tween.parallel().tween_property(control, "rotation", -0.045, 0.06)
	tween.tween_property(control, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(control, "rotation", 0.0, 0.2)


func _show_floating_feedback(text: String, color: Color, lifetime: float = 1.6) -> void:
	if is_instance_valid(floating_feedback):
		floating_feedback.queue_free()
	var feedback := PanelContainer.new()
	feedback.name = "CookingFloatingFeedback"
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.z_index = 300
	feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	feedback.position = Vector2(-230, 58)
	feedback.custom_minimum_size = Vector2(460, 44)
	feedback.add_theme_stylebox_override("panel", _panel_style(Color(color, 0.96), Color("#fff0aa"), 2, 7))
	var label := _label(text, 15, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_child(label)
	add_child(feedback)
	floating_feedback = feedback
	var tween := create_tween()
	tween.tween_interval(lifetime)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		if is_instance_valid(feedback):
			feedback.queue_free()
		if floating_feedback == feedback:
			floating_feedback = null
	)


func _make_drag_preview(card_id: String, location: String) -> Control:
	var data: Dictionary = service.card(card_id)
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(175, 78)
	preview.modulate = Color(1, 1, 1, 0.94)
	preview.add_theme_stylebox_override("panel", _panel_style(_card_type_color(String(data.get("card_type", ""))), Color("#ffe477"), 2, 5))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	preview.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	box.add_child(_label(String(data.get("name", card_id)), 16, Color.WHITE))
	box.add_child(_label("%s • %s" % [String(data.get("card_type", "card")).capitalize(), location], 11, Color("#fff0d4")))
	return preview


func _add_inspect_header(parent: Node, data: Dictionary, side: String, zone_name: String, instance_id: int = -1) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	var name_label := _label(String(data.get("name", "Unknown Card")), 14, Color.WHITE)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	var inspect := _button("i", true)
	inspect.name = "CookingInspectCard_%s_%s_%d" % [side.capitalize(), zone_name.capitalize(), instance_id]
	inspect.custom_minimum_size = Vector2(22, 21)
	inspect.tooltip_text = "Inspect card and zone effects"
	var card_id := String(data.get("id", ""))
	inspect.pressed.connect(func() -> void:
		_open_card_inspector(card_id, side, zone_name, instance_id)
	, CONNECT_DEFERRED)
	row.add_child(inspect)


func _bind_card_panel_inspection(panel: Control, card_id: String, side: String, zone_name: String, instance_id: int = -1) -> void:
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.tooltip_text = "Drag to play or move • click to inspect card and zone effects" if zone_name in ["hand", "prep", "plated"] else "Click to inspect card and zone effects"
	var click_state := {"tracking": false, "origin": Vector2.ZERO}
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				click_state.tracking = true
				click_state.origin = event.position
			elif bool(click_state.tracking):
				click_state.tracking = false
				if event.position.distance_to(Vector2(click_state.origin)) <= 8.0:
					_open_card_inspector(card_id, side, zone_name, instance_id)
					panel.accept_event()
		elif event is InputEventMouseMotion and bool(click_state.tracking) and event.position.distance_to(Vector2(click_state.origin)) > 8.0:
			# Let Godot's drag forwarding own the gesture once the pointer moves.
			click_state.tracking = false
	)


func _open_card_inspector(card_id: String, side: String, zone_name: String, instance_id: int = -1) -> void:
	inspected_card = {
		"card_id": card_id,
		"side": side,
		"zone": zone_name,
		"instance_id": instance_id
	}
	call_deferred("_refresh")


func _build_inspect_overlay() -> void:
	if inspected_card.is_empty():
		return
	var context := _resolve_inspected_context()
	if context.is_empty():
		inspected_card = {}
		return
	var data: Dictionary = context.data
	var unit: Dictionary = context.get("unit", {})
	var zone_name := String(context.zone)
	var side := String(context.side)

	inspect_overlay = PanelContainer.new()
	inspect_overlay.name = "CookingInspectPanel"
	inspect_overlay.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	inspect_overlay.position = Vector2.ZERO
	inspect_overlay.offset_left = -348
	inspect_overlay.offset_right = -14
	inspect_overlay.offset_top = -310
	inspect_overlay.offset_bottom = 310
	inspect_overlay.z_index = 180
	inspect_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	inspect_overlay.add_theme_stylebox_override("panel", _inspect_panel_style())
	add_child(inspect_overlay)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 14)
	outer_margin.add_theme_constant_override("margin_right", 14)
	outer_margin.add_theme_constant_override("margin_top", 12)
	outer_margin.add_theme_constant_override("margin_bottom", 12)
	inspect_overlay.add_child(outer_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	outer_margin.add_child(column)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	column.add_child(top_row)
	var heading := _label("CARD INSPECT", 13, Color("#92b8ca"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(heading)
	var close := _button("Close", true)
	close.name = "CookingInspectCloseButton"
	close.pressed.connect(func() -> void:
		inspected_card = {}
		call_deferred("_refresh")
	, CONNECT_DEFERRED)
	top_row.add_child(close)

	var name_label := _label(String(data.get("name", "Unknown Card")), 25, Color("#fff4df"))
	name_label.name = "CookingInspectName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	var subtitle := String(data.get("subtitle", ""))
	if subtitle != "":
		column.add_child(_label(subtitle, 14, Color("#bac8ce")))

	var type_text := String(data.get("card_type", "card")).capitalize()
	var archetype := String(data.get("archetype", "neutral")).capitalize()
	var rarity := "Rare" if bool(data.get("rare", false)) else "Common"
	var type_strip := _label("%s  •  %s  •  %s" % [type_text, archetype, rarity], 14, Color("#ffe29a"))
	type_strip.name = "CookingInspectType"
	column.add_child(type_strip)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 292
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 8)
	scroll.add_child(details)

	_add_inspect_section(details, "CURRENT ZONE", _inspect_zone_summary(zone_name, side, unit), "CookingInspectZoneStatus")
	if not unit.is_empty():
		var printed_stats := "%d/%d printed" % [int(data.get("attack", 0)), int(data.get("health", 0))]
		var live_stats := "%d Attack / %d Health" % [int(unit.get("attack", 0)), int(unit.get("health", 0))]
		var modifiers: Array[String] = []
		if int(unit.get("aura_attack_bonus", 0)) != 0 or int(unit.get("aura_health_bonus", 0)) != 0:
			modifiers.append("Aura %+d/%+d" % [int(unit.get("aura_attack_bonus", 0)), int(unit.get("aura_health_bonus", 0))])
		if int(unit.get("temporary_attack", 0)) != 0:
			modifiers.append("%+d temporary Attack" % int(unit.get("temporary_attack", 0)))
		var stats_text := "%s\n%s" % [live_stats, printed_stats]
		if not modifiers.is_empty():
			stats_text += "\n" + " • ".join(modifiers)
		_add_inspect_section(details, "CURRENT STATS", stats_text, "CookingInspectStats")
	elif data.has("attack"):
		_add_inspect_section(details, "PRINTED STATS", "%d Attack / %d Health" % [int(data.get("attack", 0)), int(data.get("health", 0))])

	if String(data.get("card_type", "")) == "meal":
		var printed_recipe: Array = data.get("recipe", [])
		var effective_recipe: Array = service._effective_recipe(state, side, data)
		var recipe_text := _format_recipe(printed_recipe)
		if effective_recipe != printed_recipe:
			recipe_text += "\nCurrently required: " + _format_recipe(effective_recipe) + " (modified)"
		_add_inspect_section(details, "RECIPE", recipe_text, "CookingInspectRecipe")
	elif String(data.get("card_type", "")) == "ingredient":
		var ingredient_types: Array = data.get("ingredient_types", [])
		var ingredient_text := "Provides: " + _format_recipe(ingredient_types)
		if not unit.is_empty():
			ingredient_text += "\n" + service.ingredient_recipe_status(state[side], unit)
		_add_inspect_section(details, "INGREDIENT", ingredient_text, "CookingInspectRecipe")

	var rules_text := String(data.get("text", "")).strip_edges()
	if rules_text == "":
		rules_text = "No printed ability."
	_add_inspect_section(details, "CARD TEXT", rules_text, "CookingInspectRules")
	_add_inspect_section(details, "ZONE EFFECTS", "\n".join(_inspect_zone_effects(data, zone_name, unit, side)), "CookingInspectZoneEffects")

	if not unit.is_empty() and not unit.get("spices", []).is_empty():
		var spice_names: Array[String] = []
		for spice_id in unit.get("spices", []):
			spice_names.append(String(service.card(String(spice_id)).get("name", spice_id)))
		_add_inspect_section(details, "ATTACHED SPICES", "\n".join(spice_names), "CookingInspectSpices")


func _resolve_inspected_context() -> Dictionary:
	var card_id := String(inspected_card.get("card_id", ""))
	if card_id == "" or service.card(card_id).is_empty():
		return {}
	var side := String(inspected_card.get("side", "player"))
	var zone_name := String(inspected_card.get("zone", "hand"))
	var instance_id := int(inspected_card.get("instance_id", -1))
	var unit: Dictionary = {}
	if instance_id >= 0:
		for live_zone in ["prep", "plated"]:
			unit = service._find_unit_in_zone(state[side], live_zone, instance_id)
			if not unit.is_empty():
				zone_name = live_zone
				break
		if unit.is_empty():
			return {}
	elif zone_name == "hand" and (side != "player" or not state.player.hand.has(card_id)):
		return {}
	elif zone_name == "environment" and String(state[side].environment) != card_id:
		return {}
	elif zone_name == "search" and not service.search_display_cards(state).has(card_id):
		return {}
	elif zone_name == "discard" and not state[side].discard.has(card_id):
		return {}
	elif zone_name == "revealed_hand" and not state[side].hand.has(card_id):
		return {}
	inspected_card.zone = zone_name
	return {
		"card_id": card_id,
		"side": side,
		"zone": zone_name,
		"unit": unit,
		"data": service.card(card_id)
	}


func _inspect_zone_summary(zone_name: String, side: String, unit: Dictionary) -> String:
	var owner := "Your" if side == "player" else "Opponent's"
	match zone_name:
		"plated":
			var readiness := "Ready to attack" if bool(unit.get("ready", false)) else "Cannot attack now"
			return "%s Plated zone\nCan attack and be attacked • protects the chef\n%s" % [owner, readiness]
		"prep":
			return "%s Prep zone\nProtected from attacks • cannot attack" % owner
		"hand":
			return "Your hand\nNot in play; zone abilities are inactive"
		"environment":
			return "%s Environment zone\nPersistent Environment effects apply here" % owner
		"search":
			return "Deck search choice\nNot in play; choose it to add it to your hand"
		"discard":
			return "%s discard pile\nNot in play; currently eligible for this effect" % owner
		"revealed_hand":
			return "Opponent's revealed hand\nNot in play; Tongs may put an eligible unit onto their field"
	return zone_name.capitalize()


func _inspect_zone_effects(data: Dictionary, zone_name: String, unit: Dictionary, side: String) -> Array[String]:
	var lines: Array[String] = []
	var in_play := zone_name == "prep" or zone_name == "plated" or zone_name == "environment"
	for aura in data.get("auras", []):
		var required_zone := String(aura.get("active_zone", ""))
		var active := in_play and (required_zone == "" or required_zone == zone_name)
		var status := "ACTIVE" if active else _inactive_zone_status(required_zone, zone_name)
		lines.append("%s — %s" % [status, String(data.get("text", "Persistent effect."))])
	for ability in data.get("abilities", []):
		var required_zone := String(ability.get("active_zone", ""))
		var active := in_play and (required_zone == "" or required_zone == zone_name)
		var status := "ACTIVE — CAN ACTIVATE" if active else _inactive_zone_status(required_zone, zone_name)
		var ability_id := String(ability.get("id", "activated"))
		if active and bool(ability.get("once_per_turn", false)) and unit.get("used_abilities", []).has(ability_id):
			status = "USED THIS TURN"
		lines.append("%s — Activated ability" % status)
	if not data.get("on_move_to_plated", []).is_empty():
		var already_triggered := false
		for effect in data.get("on_move_to_plated", []):
			if bool(effect.get("first_time_only", false)) and unit.get("triggered_effects", []).has(String(effect.get("type", ""))):
				already_triggered = true
		var movement_status := "ALREADY TRIGGERED" if already_triggered else ("READY — MOVE TO PLATED" if zone_name == "prep" else "TRIGGERS ON PREP → PLATED")
		lines.append("%s — Movement effect" % movement_status)
	if not data.get("on_attack", []).is_empty():
		lines.append("%s — Triggers when this card attacks" % ("ACTIVE IN PLATED" if zone_name == "plated" else "INACTIVE — REQUIRES PLATED"))
	if not data.get("on_combat_damage_to_chef", []).is_empty():
		lines.append("%s — Triggers after dealing combat damage to the opposing chef" % ("ACTIVE IN PLATED" if zone_name == "plated" else "INACTIVE — REQUIRES PLATED"))
	if not data.get("on_play", []).is_empty():
		lines.append("%s — On-play effect" % ("TRIGGERS WHEN PLAYED" if not in_play else "RESOLVED WHEN PLAYED"))
	if not data.get("on_sacrifice", []).is_empty():
		lines.append("%s — Triggers when used in a recipe or otherwise sacrificed" % ("AVAILABLE WHILE IN PLAY" if in_play else "INACTIVE — PLAY THIS CARD FIRST"))
	if not data.get("on_damaged", []).is_empty():
		lines.append("%s — Triggers whenever this card is dealt damage" % ("ACTIVE WHILE IN PLAY" if in_play else "INACTIVE — PLAY THIS CARD FIRST"))
	for keyword in data.get("keywords", []):
		var keyword_name := String(keyword).capitalize()
		var keyword_description := keyword_name
		if String(keyword) == "stalwart":
			keyword_description += ": can attack the opposing chef even while they control Plated cards"
		lines.append("%s — %s" % ["ACTIVE IN PLATED" if zone_name == "plated" else "INACTIVE — REQUIRES PLATED", keyword_description])
	if String(data.get("card_type", "")) == "environment":
		lines.append("%s — %s" % ["ACTIVE" if zone_name == "environment" else "INACTIVE — PLAY TO ENVIRONMENT", String(data.get("text", "Environment effect."))])
	if String(data.get("card_type", "")) == "ingredient" and not unit.is_empty():
		lines.append("%s — Recipe timing" % service.ingredient_recipe_status(state[side], unit))
	if lines.is_empty():
		lines.append("No zone-dependent effect. This card only uses its printed rules and normal zone rules.")
	return lines


func _inactive_zone_status(required_zone: String, current_zone: String) -> String:
	if current_zone == "hand" or current_zone == "search":
		return "INACTIVE — PLAY THIS CARD"
	if required_zone != "":
		return "INACTIVE — REQUIRES %s" % required_zone.to_upper()
	return "INACTIVE"


func _add_inspect_section(parent: Node, title: String, body: String, node_name: String = "") -> void:
	parent.add_child(_label(title, 12, Color("#92b8ca")))
	var body_label := _label(body, 14, Color("#f0eee7"))
	if node_name != "":
		body_label.name = node_name
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(body_label)


func _format_recipe(requirements: Array) -> String:
	if requirements.is_empty():
		return "No ingredients required"
	var formatted: Array[String] = []
	for requirement in requirements:
		formatted.append(String(requirement).capitalize())
	return " + ".join(formatted)


func _inspect_panel_style() -> StyleBoxFlat:
	var style := _panel_style(Color("#101722eF"), Color("#52617a"), 2, 8)
	style.shadow_color = Color("#00000088")
	style.shadow_size = 10
	style.shadow_offset = Vector2(-3, 4)
	return style


func _zone_container(parent: Node, title: String, minimum_size: Vector2, color: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _panel_style(color, Color("#173e52"), 2, 3))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.set_meta("zone_panel", panel)
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var heading := _label(title, 12, Color.WHITE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	return box


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", card_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _center_label(text: String, size: int, color: Color) -> Label:
	var label := _label(text, size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, compact: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 21 if compact else 28)
	button.add_theme_font_override("font", card_font)
	button.add_theme_font_size_override("font_size", 10 if compact else 13)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#255c70"), Color("#123b4b"), 1, 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#3181a1"), Color("#f3c765"), 1, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#173e52"), Color("#f3c765"), 1, 3))
	return button


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _card_type_color(card_type: String) -> Color:
	match card_type:
		"ingredient":
			return Color("#4f7a4d")
		"meal":
			return Color("#a34f32")
		"tool":
			return Color("#507b8f")
		"spice":
			return Color("#a86b28")
		"environment":
			return Color("#6a5b87")
	return Color("#68736c")


func _hand_action_label(card_type: String) -> String:
	match card_type:
		"meal":
			return "Plate Meal"
		"tool":
			return "Use Tool"
		"spice":
			return "Attach Spice"
		"environment":
			return "Set Environment"
		"chef":
			return "Use Chef"
	return "Play"
