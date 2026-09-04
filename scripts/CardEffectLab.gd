extends RefCounted
class_name CardEffectLab

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

## Keep this lab intentionally small and high-signal. Broader rule coverage lives in
## the headless smoke tests; these scenarios give the in-game Debug Sandbox a quick
## way to exercise the riskiest effects from the canonical demo catalog.
const SCENARIOS := [
	{"id":"hot_honey_on_play", "card_id":"spicy_hot_honey_bee", "label":"Hot Honey Bee — on-play Chef damage", "archetype":"Spicy"},
	{"id":"gazelle_buff", "card_id":"hearty_gravy_gazelle", "label":"Gravy Gazelle — targeted +1/+1", "archetype":"Hearty"},
	{"id":"bison_attack", "card_id":"hearty_bison_burrito", "label":"Bison Burrito — discard Prep and grow", "archetype":"Hearty / Fresh"},
	{"id":"hydra_absorb", "card_id":"fresh_harvest_hydra", "label":"Harvest Hydra — sacrifice and absorb", "archetype":"Fresh"},
	{"id":"gardenrilla_prep", "card_id":"fresh_garden_gorilla", "label":"Spicy Gardenrilla — Fresh Prep scaling", "archetype":"Fresh"},
	{"id":"feta_mill", "card_id":"funky_fondue_ferret", "label":"Feta Ferret — mill and grow", "archetype":"Funky"},
	{"id":"beetle_cycle", "card_id":"funky_beat_beetle", "label":"Beet Beetle — discard one, draw one", "archetype":"Funky"},
	{"id":"chutney_trap", "card_id":"funky_chef_check_chinchilla", "label":"Chutney Chinchilla — Ingredient hand trap", "archetype":"Funky"},
	{"id":"tamari_trap", "card_id":"funky_toolbox_toad", "label":"Tamari Toad — Chef hand trap", "archetype":"Funky"},
	{"id":"cucorgi_response", "card_id":"fresh_comeback_corgi", "label":"Cucorgi — Chef-damage response", "archetype":"Fresh"},
	{"id":"yolke_bowl", "card_id":"fresh_spicy_yolke_bowl", "label":"Yolke Bowl — opposing board damage", "archetype":"Fresh / Spicy"},
	{"id":"fresh_environment", "card_id":"environment_fresh_greensweet", "label":"fresh greensweet — turn-start token", "archetype":"Fresh"}
]

var service: RefCounted
var selected_index := 0
var last_result: Dictionary = {}
var all_results: Array[Dictionary] = []


func show(host) -> void:
	_ensure_service()
	host.current_screen = "card_lab"
	host._render_nav()
	host._clear(host.content)
	host._update_status()
	host._set_footer("Run focused checks through the same rules service used by a Kitchen Match.")

	var header: VBoxContainer = host._add_panel(host.content, "Canonical Card Effect Lab", _hex(PALETTE.CORAL))
	header.name = "CardEffectLabHeader"
	host._add_body_text(header, "%d focused scenarios cover the demo catalog's highest-risk triggered, activated, and response effects." % SCENARIOS.size())

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	header.add_child(controls)
	var picker := OptionButton.new()
	picker.name = "CardEffectLabScenarioPicker"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for scenario in SCENARIOS:
		picker.add_item("[%s] %s" % [scenario.archetype, scenario.label])
	picker.select(selected_index)
	picker.item_selected.connect(func(index: int) -> void:
		selected_index = index
		last_result = {}
		show(host)
	, CONNECT_DEFERRED)
	controls.add_child(picker)
	var run_one: Button = host._make_button("Run Selected Test")
	run_one.name = "CardEffectLabRunSelected"
	host._style_button(run_one, "action")
	host._connect_pressed(run_one, func() -> void:
		last_result = run_scenario(String(SCENARIOS[selected_index].id))
		all_results = []
		show(host)
	)
	controls.add_child(run_one)
	var run_all: Button = host._make_button("Run All %d" % SCENARIOS.size())
	run_all.name = "CardEffectLabRunAll"
	host._connect_pressed(run_all, func() -> void:
		all_results = run_all_scenarios()
		last_result = {}
		show(host)
	)
	controls.add_child(run_all)

	_add_card_details(host)
	if not last_result.is_empty():
		_add_result_panel(host, last_result)
	elif not all_results.is_empty():
		_add_all_results(host)
	else:
		var guide: VBoxContainer = host._add_panel(host.content, "How to use this tab", _hex(PALETTE.PERIWINKLE))
		host._add_body_text(guide, "Choose a card and run its controlled setup. PASS means the production resolver produced the expected state change; the before/after snapshots and event log make failures inspectable.")


func run_all_scenarios() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for scenario in SCENARIOS:
		results.append(run_scenario(String(scenario.id)))
	return results


func run_scenario(scenario_id: String) -> Dictionary:
	_ensure_service()
	var state := _fresh_state()
	var expected := ""
	var passed := false
	var before := ""
	match scenario_id:
		"hot_honey_on_play":
			state.player.hand = ["spicy_hot_honey_bee"]
			expected = "Hot Honey Bee enters Prep and deals 1 damage to the opposing Chef."
			before = _snapshot(state)
			service.play_card(state, 0, "prep")
			passed = _has_card(state.player.prep, "spicy_hot_honey_bee") and int(state.opponent.life) == 19
		"gazelle_buff":
			var gazelle := _add_unit(state, "player", "hearty_gravy_gazelle", "plated")
			var target := _add_unit(state, "player", "spicy_jalapeno_jackal", "plated")
			expected = "Gravy Gazelle gives the friendly Jakapeno +1/+1 and records its once-per-turn use."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(gazelle.instance_id), service.card("hearty_gravy_gazelle").abilities[0], int(target.instance_id))
			passed = int(target.attack) == 4 and int(target.health) == 3 and gazelle.used_abilities.has("gravy_gazelle_buff")
		"bison_attack":
			var bison := _add_unit(state, "player", "hearty_bison_burrito", "plated")
			_add_unit(state, "player", "hearty_bagver", "prep")
			_add_unit(state, "player", "hearty_ramen_ram", "prep")
			expected = "Bison Burrito discards both friendly Prep units and grows from 4/5 to 6/7."
			before = _snapshot(state)
			service._resolve_effects(state, "player", service.card("hearty_bison_burrito").on_attack, bison)
			passed = state.player.prep.is_empty() and int(bison.attack) == 6 and int(bison.health) == 7
		"hydra_absorb":
			var hydra := _add_unit(state, "player", "fresh_harvest_hydra", "plated")
			hydra.served_sacrifice_attack = 4
			hydra.served_sacrifice_health = 5
			_add_unit(state, "player", "fresh_crisp_capybara", "prep")
			_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
			expected = "Harvest Hydra absorbs its serving cards and every other friendly unit, ending at 8/11."
			before = _snapshot(state)
			service._resolve_effects(state, "player", service.card("fresh_harvest_hydra").on_play, hydra)
			passed = state.player.prep.is_empty() and int(hydra.attack) == 8 and int(hydra.health) == 11
		"gardenrilla_prep":
			var gardenrilla := _add_unit(state, "player", "fresh_garden_gorilla", "plated")
			_add_unit(state, "player", "fresh_crisp_capybara", "prep")
			_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
			expected = "Two other Fresh Prep units raise Spicy Gardenrilla from 2 to 6 Attack."
			before = _snapshot(state)
			service._refresh_stat_auras(state)
			passed = int(gardenrilla.attack) == 6
		"feta_mill":
			var ferret := _add_unit(state, "player", "funky_fondue_ferret", "prep")
			state.player.deck = ["fresh_crisp_capybara"]
			expected = "Feta Ferret discards a unit from the deck and gains +1/+1 once this turn."
			before = _snapshot(state)
			service.activate_ability(state, int(ferret.instance_id), "feta_ferret_mill")
			passed = int(ferret.attack) == 2 and int(ferret.health) == 2 and state.player.discard == ["fresh_crisp_capybara"]
		"beetle_cycle":
			state.player.hand = ["funky_beat_beetle", "hearty_bagver"]
			state.player.deck = ["item_wooden_spoon"]
			expected = "Beet Beetle discards one chosen hand card, draws one, and enters Prep."
			before = _snapshot(state)
			service.play_card(state, 0, "prep")
			service.toggle_discard_card(state, 1)
			service.confirm_discard_cost(state)
			passed = _has_card(state.player.prep, "funky_beat_beetle") and state.player.hand == ["item_wooden_spoon"] and state.player.discard.has("hearty_bagver")
		"chutney_trap":
			state.player.hand = ["funky_chef_check_chinchilla"]
			state.opponent.hand = ["hearty_macaroni_manatee"]
			expected = "Chutney Chinchilla resolves after the Ingredient's on-play timing and destroys it."
			before = _snapshot(state)
			service._play_ingredient(state, "opponent", 0, "prep")
			service.resolve_reaction(state, 0)
			passed = state.opponent.prep.is_empty() and state.opponent.discard.has("hearty_macaroni_manatee") and state.player.discard.has("funky_chef_check_chinchilla")
		"tamari_trap":
			state.player.hand = ["funky_toolbox_toad"]
			state.opponent.hand = ["chef_mary"]
			expected = "Tamari Toad is discarded to negate the opposing Chef."
			before = _snapshot(state)
			service._play_chef(state, "opponent", 0)
			service.resolve_reaction(state, 0)
			passed = state.opponent.discard.has("chef_mary") and state.player.discard.has("funky_toolbox_toad")
		"cucorgi_response":
			state.player.hand = ["fresh_comeback_corgi"]
			expected = "After Chef damage, Cucorgi enters Plated and creates a Fresh token in Prep."
			before = _snapshot(state)
			service._deal_chef_damage(state, "player", 2, "opponent", false)
			service.resolve_reaction(state, 0)
			passed = _has_card(state.player.plated, "fresh_comeback_corgi") and _has_card(state.player.prep, "token_fresh_ingredient")
		"yolke_bowl":
			var yolke := _add_unit(state, "player", "fresh_spicy_yolke_bowl", "plated")
			_add_unit(state, "opponent", "hearty_bagver", "prep")
			_add_unit(state, "opponent", "hearty_lasagnama", "plated")
			expected = "Yolke Bowl deals 2 damage to every opposing unit and the opposing Chef."
			before = _snapshot(state)
			service._resolve_effects(state, "player", service.card("fresh_spicy_yolke_bowl").on_play, yolke)
			passed = state.opponent.prep.is_empty() and int(state.opponent.plated[0].health) == 3 and int(state.opponent.life) == 18
		"fresh_environment":
			state.player.environment = "environment_fresh_greensweet"
			expected = "fresh greensweet creates a 1/1 Fresh Ingredient token at turn start."
			before = _snapshot(state)
			service._start_turn(state, "player", false)
			passed = _has_card(state.player.prep, "token_fresh_ingredient")
		_:
			expected = "A registered canonical scenario id."
			before = _snapshot(state)
	return {
		"id": scenario_id,
		"label": _scenario_label(scenario_id),
		"passed": passed,
		"expected": expected,
		"before": before,
		"after": _snapshot(state),
		"log": state.get("log", []).duplicate()
	}


func _add_card_details(host) -> void:
	var scenario: Dictionary = SCENARIOS[selected_index]
	var data: Dictionary = service.card(String(scenario.card_id))
	var details: VBoxContainer = host._add_panel(host.content, String(data.get("name", scenario.label)), _hex(PALETTE.TEAL))
	details.name = "CardEffectLabCardDetails"
	var stats: String = host._card_descriptor(data)
	if data.has("attack"):
		stats += " • %d/%d" % [int(data.attack), int(data.health)]
	if not data.get("recipe", []).is_empty():
		stats += " • Recipe: %s" % host._format_affinity_requirements(data.recipe)
	host._add_body_text(details, stats)
	host._add_body_text(details, String(data.get("text", "No rules text.")))


func _add_result_panel(host, result: Dictionary) -> void:
	var accent := _hex(PALETTE.TEAL) if bool(result.passed) else _hex(PALETTE.BRICK)
	var panel: VBoxContainer = host._add_panel(host.content, "%s — %s" % ["PASS" if bool(result.passed) else "FAIL", result.label], accent)
	panel.name = "CardEffectLabResult"
	host._add_body_text(panel, "Expected: " + String(result.expected))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	panel.add_child(columns)
	_add_snapshot_column(host, columns, "Before", String(result.before))
	_add_snapshot_column(host, columns, "After", String(result.after))
	var log_panel: VBoxContainer = host._add_panel(panel, "Production event log", _hex(PALETTE.LAVENDER))
	var log_text := "No log entries."
	if not result.log.is_empty():
		log_text = "\n".join(result.log)
	host._add_body_text(log_panel, log_text)


func _add_snapshot_column(host, parent: Node, title: String, snapshot: String) -> void:
	var box: VBoxContainer = host._add_panel(parent, title, _hex(PALETTE.PERIWINKLE))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._add_body_text(box, snapshot)


func _add_all_results(host) -> void:
	var passed_count := 0
	for result in all_results:
		if bool(result.passed):
			passed_count += 1
	var all_passed := passed_count == all_results.size()
	var panel: VBoxContainer = host._add_panel(host.content, "Canonical regression: %d/%d passed" % [passed_count, all_results.size()], _hex(PALETTE.TEAL if all_passed else PALETTE.BRICK))
	panel.name = "CardEffectLabAllResults"
	for result in all_results:
		var line: Label = host._add_body_text(panel, "%s  %s" % ["PASS" if bool(result.passed) else "FAIL", result.label])
		line.add_theme_color_override("font_color", PALETTE.TEAL_DARK if bool(result.passed) else PALETTE.BRICK_DARK)


func _ensure_service() -> void:
	if service != null:
		return
	service = SERVICE_SCRIPT.new()
	service.load_content()


func _fresh_state() -> Dictionary:
	var state: Dictionary = service.start_game("fresh_test_kitchen", "funky_test_kitchen", 19019, "player")
	for side in ["player", "opponent"]:
		state[side].hand = []
		state[side].deck = []
		state[side].discard = []
		state[side].prep = []
		state[side].plated = []
		state[side].life = service.STARTING_LIFE
		state[side].fatigue = 0
		state[side].turns_started = 3
		state[side].chef_used = false
		state[side].meal_served = false
		state[side].hand_trap_used = false
	state.phase = "player_main"
	state.first_player = "opponent"
	state.pending_choice = {}
	state.pending_ability = {}
	state.pending_reaction = {}
	state.game_over = false
	state.winner = ""
	state.log = []
	return state


func _add_unit(state: Dictionary, side: String, card_id: String, zone: String) -> Dictionary:
	var unit: Dictionary = service._make_unit(state, state[side], service.card(card_id), zone, side)
	state[side][zone].append(unit)
	return unit


func _snapshot(state: Dictionary) -> String:
	return "Player — Life %d | Hand: %s\nPrep: %s\nPlated: %s\nDiscard: %s\n\nOpponent — Life %d | Hand: %s\nPrep: %s\nPlated: %s\nDiscard: %s" % [
		int(state.player.life), _card_names(state.player.hand), _unit_names(state.player.prep), _unit_names(state.player.plated), _card_names(state.player.discard),
		int(state.opponent.life), _card_names(state.opponent.hand), _unit_names(state.opponent.prep), _unit_names(state.opponent.plated), _card_names(state.opponent.discard)
	]


func _unit_names(units: Array) -> String:
	if units.is_empty():
		return "—"
	var names: Array[String] = []
	for unit in units:
		names.append("%s %d/%d" % [unit.name, int(unit.attack), int(unit.health)])
	return ", ".join(names)


func _card_names(card_ids: Array) -> String:
	if card_ids.is_empty():
		return "—"
	var names: Array[String] = []
	for card_id in card_ids:
		names.append(String(service.card(String(card_id)).get("name", card_id)))
	return ", ".join(names)


func _has_card(units: Array, card_id: String) -> bool:
	for unit in units:
		if String(unit.get("card_id", "")) == card_id:
			return true
	return false


func _scenario_label(scenario_id: String) -> String:
	for scenario in SCENARIOS:
		if String(scenario.id) == scenario_id:
			return String(scenario.label)
	return scenario_id


func _hex(color: Color) -> String:
	return "#" + color.to_html(false)
