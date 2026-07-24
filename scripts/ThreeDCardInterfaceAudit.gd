extends SceneTree

const TABLE_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CARD_FACE_SCRIPT := preload("res://scripts/CardFace.gd")
const EFFECT_LAB_SCRIPT := preload("res://scripts/CardEffectLab.gd")

const EFFECT_ARRAY_KEYS := [
	"effects", "on_play", "on_attack", "on_combat_damage_to_chef", "on_damaged",
	"on_end_turn", "on_ko", "on_ko_enemy", "on_move_to_plated", "on_sacrifice"
]
const SUPPORTED_EFFECT_TYPES := [
	"absorb_all_friendly_units", "buff_friendly_plated", "buff_friendly_unit", "buff_self",
	"conditional_draw", "copy_prep_activated_ability", "create_token", "damage_all_enemy_plated",
	"damage_all_enemy_units", "damage_all_plated_units", "damage_enemy_plated", "damage_enemy_player",
	"damage_enemy_prep", "damage_enemy_unit", "deploy_enemy_hand_unit", "destroy_enemy_unit",
	"disable_enemy_chefs_next_turn", "disable_enemy_items_next_turn", "discard_hand",
	"discard_hand_then_draw_if_any", "discard_top_then_buff_if_unit", "draw",
	"draw_for_friendly_archetype", "draw_to_hand_size", "heal_all_friendly_units", "heal_player",
	"heal_self", "heal_unit", "look_and_take", "move_friendly_to_prep", "recover", "recycle",
	"remove_enemy_spice", "return_enemy_ingredient", "search", "swap_attack_health",
	"switch_friendly_zones"
]
const BOARD_CHOICE_EFFECTS := [
	"buff_friendly_unit", "buff_friendly_plated", "heal_unit", "damage_enemy_unit",
	"damage_enemy_plated", "damage_enemy_prep", "return_enemy_ingredient",
	"move_friendly_to_prep", "switch_friendly_zones", "destroy_enemy_unit",
	"swap_attack_health", "remove_enemy_spice"
]
const EXPECTED_CATEGORY_COUNTS := {
	"cards": 89,
	"recipes": 28,
	"searches": 12,
	"discard_choices": 4,
	"board_choices": 14,
	"reactions": 5,
	"abilities": 8,
	"discard_costs": 7
}

var failed := false
var failures: Array[String] = []
var table
var service
var authored_face_count := 0
var fallback_face_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	table = TABLE_SCENE.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	service = table.service

	_audit_inventory_and_3d_faces()
	_audit_category_counts()
	_audit_every_recipe_prompt()
	_audit_every_activated_ability_route()
	_audit_unusual_board_target_routes()
	_audit_search_discard_and_reaction_presentations()
	_audit_effect_lab_regressions()

	if failed:
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("3D card interface audit passed: 89/89 playable cards (%d authored faces, %d fallback faces); 36 effect operations; 28 recipes; 12 searches; 4 discard choices; 14 board-target cards; 8 activated abilities; 5 reactions; 7 discard-cost Items." % [authored_face_count, fallback_face_count])
	quit()


func _audit_inventory_and_3d_faces() -> void:
	var playable_ids := _playable_card_ids()
	_expect(playable_ids.size() == int(EXPECTED_CATEGORY_COUNTS.cards), "Catalog did not contain exactly 89 playable cards in addition to internal tokens.")
	for card_id_value in playable_ids:
		var card_id := String(card_id_value)
		var data: Dictionary = service.card(card_id)
		_expect(String(data.get("card_type", "")) in ["ingredient", "meal", "tool", "chef", "spice", "environment"], "%s has no supported 3D play route." % card_id)
		if CARD_FACE_SCRIPT.supports_card(data):
			authored_face_count += 1
		else:
			fallback_face_count += 1
		var physical_card := table._make_card(card_id, true) as Node3D
		var body := physical_card.find_child("CardBody", true, false) as MeshInstance3D
		var face := physical_card.find_child("CardFace", true, false) as MeshInstance3D
		var face_material := face.material_override as StandardMaterial3D if face != null else null
		_expect(body != null and face_material != null and face_material.albedo_texture != null, "%s could not build a complete physical 3D card." % card_id)
		physical_card.free()
		for effect in _card_effects(data):
			var effect_type := String(effect.get("type", ""))
			_expect(effect_type in SUPPORTED_EFFECT_TYPES, "%s uses unsupported effect operation '%s'." % [card_id, effect_type])


func _audit_category_counts() -> void:
	var counts := {
		"recipes": 0,
		"searches": 0,
		"discard_choices": 0,
		"board_choices": 0,
		"reactions": 0,
		"abilities": 0,
		"discard_costs": 0
	}
	for card_id_value in _playable_card_ids():
		var data: Dictionary = service.card(String(card_id_value))
		if String(data.get("card_type", "")) == "meal":
			counts.recipes += 1
		if not data.get("abilities", []).is_empty():
			counts.abilities += 1
		if data.has("hand_trap") or data.has("hand_trigger"):
			counts.reactions += 1
		if int(data.get("discard_cost", 0)) > 0:
			counts.discard_costs += 1
		var has_search := false
		var has_discard_choice := false
		var has_board_choice := false
		for effect in _card_effects(data):
			var effect_type := String(effect.get("type", ""))
			has_search = has_search or effect_type in ["search", "look_and_take"]
			has_discard_choice = has_discard_choice or effect_type in ["recover", "recycle"]
			has_board_choice = has_board_choice or (effect_type in BOARD_CHOICE_EFFECTS and not (effect_type == "damage_enemy_prep" and String(effect.get("target", "")) == "random"))
		if has_search:
			counts.searches += 1
		if has_discard_choice:
			counts.discard_choices += 1
		if has_board_choice:
			counts.board_choices += 1
	for category in counts:
		_expect(int(counts[category]) == int(EXPECTED_CATEGORY_COUNTS[category]), "Audit inventory changed for %s: expected %d, found %d." % [category, int(EXPECTED_CATEGORY_COUNTS[category]), int(counts[category])])


func _audit_every_recipe_prompt() -> void:
	for card_id_value in _playable_card_ids():
		var meal_id := String(card_id_value)
		var meal_data: Dictionary = service.card(meal_id)
		if String(meal_data.get("card_type", "")) != "meal":
			continue
		var state := _fresh_state()
		state.player.hand = [meal_id]
		var ingredient_ids: Array[int] = []
		for requirement in service._effective_recipe(state, "player", meal_data):
			var ingredient_card_id := _ingredient_for_requirement(String(requirement))
			var ingredient := _add_unit(state, "player", ingredient_card_id, "prep")
			ingredient.recipe_ready_on_turn = 0
			ingredient.table_slot = ingredient_ids.size()
			ingredient_ids.append(int(ingredient.instance_id))
		var required_meal_archetype := String(meal_data.get("required_meal_archetype", ""))
		if required_meal_archetype != "":
			var required_meal_id := _meal_for_archetype(required_meal_archetype, meal_id)
			var required_meal := _add_unit(state, "player", required_meal_id, "plated")
			required_meal.table_slot = 0
		service.begin_meal_play(state, 0, "plated", 1)
		_expect(not state.pending_meal.is_empty(), "%s did not open ingredient selection when played." % meal_id)
		_expect(service.meal_selectable_ingredient_ids(state).size() >= ingredient_ids.size(), "%s did not expose enough selectable recipe Ingredients." % meal_id)
		for ingredient_id in ingredient_ids:
			service.toggle_ingredient_selection(state, ingredient_id)
		_expect(service.meal_selection_is_ready(state), "%s could not satisfy its authored recipe through the selection prompt." % meal_id)
		service.cancel_meal_play(state)
		_expect(state.pending_meal.is_empty() and state.player.hand == [meal_id], "%s did not cancel recipe selection safely." % meal_id)


func _audit_every_activated_ability_route() -> void:
	for card_id_value in _playable_card_ids():
		var card_id := String(card_id_value)
		var data: Dictionary = service.card(card_id)
		for ability in data.get("abilities", []):
			var state := _fresh_state()
			state.player.deck = ["spicy_hot_honey_bee", "hearty_bagver", "item_wooden_spoon"]
			var source_zone := String(ability.get("active_zone", "plated"))
			if source_zone == "":
				source_zone = "plated"
			var source := _add_unit(state, "player", card_id, source_zone)
			var target_id := -1
			var target_spec: Dictionary = ability.get("target", {})
			if not target_spec.is_empty():
				target_id = _add_ability_target(state, source, target_spec)
			service.activate_ability(state, int(source.instance_id), String(ability.get("id", "")))
			if target_spec.is_empty():
				_expect(state.pending_ability.is_empty(), "%s's targetless ability opened an unexpected target prompt." % card_id)
				if _ability_has_effect(ability, "search"):
					_expect(not state.pending_search.is_empty(), "%s's search ability did not enter the deck-search presentation state." % card_id)
			else:
				_expect(not state.pending_ability.is_empty() and service._ability_target_is_valid(state, "player", source, target_id, target_spec), "%s did not expose its legal activated-ability target." % card_id)
				table.state = state
				table._render_match()
				_expect(not table.prompt_panel.visible and table.cancel_choice_button.visible and not table.highlighted_bodies.is_empty(), "%s's activated target was not represented on the 3D table." % card_id)


func _audit_unusual_board_target_routes() -> void:
	for effect_type in BOARD_CHOICE_EFFECTS:
		var state := _fresh_state()
		var friendly := _add_unit(state, "player", "hearty_bagver", "plated")
		_add_unit(state, "player", "spicy_hot_honey_bee", "prep")
		var enemy_ingredient := _add_unit(state, "opponent", "spicy_hot_honey_bee", "prep")
		var enemy_meal := _add_unit(state, "opponent", "spicy_sriracharrow", "plated")
		friendly.health = 1
		enemy_meal.spices = ["spice_cayenne_crunch"]
		var effect := {"type": effect_type, "amount": 1, "attack": 1, "health": 1, "target": "selected"}
		if effect_type == "move_friendly_to_prep":
			effect.archetype = "hearty"
		service._resolve_effects(state, "player", [effect], friendly)
		_expect(String(state.get("pending_choice", {}).get("choice_kind", "")) == "board" and not service.choice_target_ids(state).is_empty(), "Board-choice operation '%s' did not create legal targets." % effect_type)
		table.state = state
		table._render_match()
		_expect(not table.prompt_panel.visible and table.cancel_choice_button.visible and not table.highlighted_bodies.is_empty(), "Board-choice operation '%s' was not clickable on the 3D table." % effect_type)


func _audit_search_discard_and_reaction_presentations() -> void:
	var search_state := _fresh_state()
	search_state.player.deck = ["spicy_hot_honey_bee", "item_wooden_spoon"]
	search_state.pending_search = {"effect": {"type": "search", "card_type": "ingredient"}, "prompt": "Choose an Ingredient."}
	table.state = search_state
	table._render_match()
	_expect(table.card_tray_overlay.visible and table.card_tray_cards.get_child_count() == 1 and table.card_tray_cards.get_child(0).find_child("FullCardFace", true, false) != null, "Deck searches did not use a selectable full-card tray.")

	var discard_state := _fresh_state()
	discard_state.player.discard = ["spicy_hot_honey_bee", "spicy_sriracharrow"]
	discard_state.pending_choice = {"choice_kind": "discard", "side": "player", "effect": {"type": "recover", "card_type": "ingredient"}, "selected_indices": [], "required": 1, "prompt": "Choose from discard."}
	table.state = discard_state
	table._render_match()
	_expect(table.card_tray_overlay.visible and table.card_tray_cards.get_child_count() == 1, "Discard-pile choices did not use the full-card tray.")

	var hand_choice_state := _fresh_state()
	hand_choice_state.opponent.hand = ["spicy_hot_honey_bee", "item_wooden_spoon"]
	hand_choice_state.pending_choice = {"choice_kind": "opponent_hand", "side": "player", "effect": {"type": "deploy_enemy_hand_unit"}, "prompt": "Choose an opposing unit."}
	table.state = hand_choice_state
	table._render_match()
	_expect(table.prompt_panel.visible and table.prompt_content.get_child_count() >= 3, "Opponent-hand choices did not expose a usable 3D overlay.")

	var reaction_state := _fresh_state()
	reaction_state.player.hand = ["funky_chef_check_chinchilla"]
	reaction_state.pending_reaction = {"reaction_kind": "hand_trap", "eligible_indices": [0], "acting_side": "opponent", "action_kind": ""}
	table.state = reaction_state
	table._render_match()
	_expect(table.prompt_panel.visible and table.prompt_content.get_child_count() >= 4, "Reaction windows did not expose the timer, Use, and Pass controls in the 3D interface.")
	_expect(table.reaction_countdown_active and is_equal_approx(table.reaction_countdown_remaining, table.REACTION_WINDOW_SECONDS), "Hand Trap reaction windows did not start a five-second countdown.")
	table._update_reaction_countdown(table.REACTION_WINDOW_SECONDS + 0.01)
	_expect(reaction_state.pending_reaction.is_empty() and reaction_state.player.hand == ["funky_chef_check_chinchilla"], "An expired Hand Trap reaction did not auto-pass without using the card.")


func _audit_effect_lab_regressions() -> void:
	var lab = EFFECT_LAB_SCRIPT.new()
	var results: Array[Dictionary] = lab.run_all_scenarios()
	_expect(results.size() == 19 and results.all(func(result: Dictionary) -> bool: return bool(result.get("passed", false))), "One or more of the 19 complex-card production scenarios failed.")


func _fresh_state() -> Dictionary:
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 8800, "player")
	for side in ["player", "opponent"]:
		state[side].hand = []
		state[side].deck = []
		state[side].discard = []
		state[side].prep = []
		state[side].plated = []
		state[side].turns_started = 3
		state[side].meal_served = false
	state.phase = "player_main"
	state.first_player = "opponent"
	state.pending_meal = {}
	state.pending_discard = {}
	state.pending_ability = {}
	state.pending_search = {}
	state.pending_choice = {}
	state.pending_reaction = {}
	state.animation_events = []
	return state


func _add_unit(state: Dictionary, side: String, card_id: String, zone: String) -> Dictionary:
	var unit: Dictionary = service._make_unit(state, state[side], service.card(card_id), zone, side)
	unit.recipe_ready_on_turn = 0
	unit.table_slot = state[side][zone].size()
	state[side][zone].append(unit)
	return unit


func _add_ability_target(state: Dictionary, source: Dictionary, target_spec: Dictionary) -> int:
	var target_side := "player" if String(target_spec.get("side", "enemy")) == "friendly" else "opponent"
	var target_zone := String(target_spec.get("zone", "plated"))
	if target_zone == "":
		target_zone = "plated"
	var target_card_id := "hearty_stewoose" if String(target_spec.get("card_type", "")) == "meal" else "hearty_bagver"
	if bool(target_spec.get("has_activated_ability", false)):
		target_card_id = "hearty_gravy_gazelle"
	var target := _add_unit(state, target_side, target_card_id, target_zone)
	if bool(target_spec.get("damaged_only", false)):
		target.health = maxi(1, int(target.max_health) - 1)
	if bool(target_spec.get("exclude_self", false)) and int(target.instance_id) == int(source.instance_id):
		return -1
	return int(target.instance_id)


func _ingredient_for_requirement(requirement: String) -> String:
	for card_id_value in service.cards_by_id:
		var card_id := String(card_id_value)
		var data: Dictionary = service.card(card_id)
		if String(data.get("card_type", "")) == "ingredient" and (requirement == "any" or data.get("ingredient_types", []).has(requirement)):
			return card_id
	return "spicy_hot_honey_bee"


func _meal_for_archetype(archetype: String, excluded_id: String) -> String:
	for card_id_value in service.cards_by_id:
		var card_id := String(card_id_value)
		var data: Dictionary = service.card(card_id)
		if card_id != excluded_id and String(data.get("card_type", "")) == "meal" and String(data.get("archetype", "")) == archetype:
			return card_id
	return excluded_id


func _playable_card_ids() -> Array[String]:
	var result: Array[String] = []
	for card_id_value in service.cards_by_id:
		var card_id := String(card_id_value)
		if not card_id.begins_with("token_"):
			result.append(card_id)
	return result


func _card_effects(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in EFFECT_ARRAY_KEYS:
		for effect in data.get(key, []):
			result.append(effect)
	for ability in data.get("abilities", []):
		for effect in ability.get("effects", []):
			result.append(effect)
	return result


func _ability_has_effect(ability: Dictionary, effect_type: String) -> bool:
	for effect in ability.get("effects", []):
		if String(effect.get("type", "")) == effect_type:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	failures.append(message)
