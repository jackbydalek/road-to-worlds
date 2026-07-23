extends RefCounted
class_name CardEffectLab

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")

const SCENARIOS := [
	{"id":"parfait_draw", "card_id":"sweet_parfait_parrot", "label":"Parfait Parrot — Plated end-turn draw", "archetype":"Sweet"},
	{"id":"gazelle_buff", "card_id":"hearty_gravy_gazelle", "label":"Gravy Gazelle — targeted +1/+1", "archetype":"Hearty"},
	{"id":"cicada_ko", "card_id":"spicy_chili_cicada", "label":"Chili Cicada — KO damage", "archetype":"Spicy"},
	{"id":"hydra_absorb", "card_id":"fresh_harvest_hydra", "label":"Harvest Hydra — Meal sacrifice and absorb", "archetype":"Fresh"},
	{"id":"gorilla_prep", "card_id":"fresh_garden_gorilla", "label":"Garden Gorilla — Fresh Prep scaling", "archetype":"Fresh"},
	{"id":"pike_ping", "card_id":"spicy_pepper_pike", "label":"Pepper Pike — once-per-turn Meal damage", "archetype":"Spicy"},
	{"id":"mole_ko_heal", "card_id":"hearty_meatloaf_mole", "label":"Meatloaf Mole — heal after KO", "archetype":"Hearty"},
	{"id":"buffalo_heal", "card_id":"hearty_broth_buffalo", "label":"Broth Buffalo — targeted heal", "archetype":"Hearty"},
	{"id":"raccoon_copy", "card_id":"funky_remix_raccoon", "label":"Relish Raccoon — copy Prep ability", "archetype":"Funky"},
	{"id":"beetle_mill", "card_id":"funky_beat_beetle", "label":"Beet Beetle — mill and +3/+3", "archetype":"Funky"},
	{"id":"tern_refill", "card_id":"sweet_bottomless_trifle_tern", "label":"Bottomless Trifle Tern — attack refill", "archetype":"Sweet"},
	{"id":"skunk_shield", "card_id":"fresh_salad_shield_skunk", "label":"Salad Shield Skunk — Prep protection", "archetype":"Fresh"},
	{"id":"puma_prep_attack", "card_id":"sweet_pudding_puma", "label":"Pudding Puma — attack from Prep", "archetype":"Sweet"},
	{"id":"chef_trap", "card_id":"funky_chef_check_chinchilla", "label":"Chutney Chinchilla — negate Chef", "archetype":"Funky"},
	{"id":"ingredient_trap", "card_id":"spicy_pantry_pouncer", "label":"Pantry Pouncer — destroy Ingredient", "archetype":"Spicy"},
	{"id":"tool_trap", "card_id":"funky_toolbox_toad", "label":"Tamari Toad — negate Tool", "archetype":"Funky"},
	{"id":"ability_trap", "card_id":"sweet_ability_axolotl", "label":"Ability Axolotl — negate ability", "archetype":"Sweet"},
	{"id":"corgi_comeback", "card_id":"fresh_comeback_corgi", "label":"Comeback Cucumber Corgi — damage response", "archetype":"Fresh"},
	{"id":"tapir_guard", "card_id":"funky_trap_jam_tapir", "label":"Tempeh Tapir — negate Hand Trap", "archetype":"Funky"}
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
	host._set_footer("Choose a controlled scenario, then run it through the production combat service.")

	var header: VBoxContainer = host._add_panel(host.content, "Card Effect Lab", "#202c3e")
	header.name = "CardEffectLabHeader"
	host._add_body_text(header, "One-click regression setups for the 19 newly implemented effects. Every test uses the same rules service as a real Kitchen Match.")

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
	var run_all: Button = host._make_button("Run All 19")
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
		var guide: VBoxContainer = host._add_panel(host.content, "How to use this tab", "#252b35")
		host._add_body_text(guide, "Pick a card, run its setup, and compare the captured state before and after the action. PASS means the exact expected rules change occurred; the event log below it shows the production resolver path.")


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
		"parfait_draw":
			_add_unit(state, "player", "sweet_parfait_parrot", "plated")
			state.player.deck = ["item_wooden_spoon"]
			expected = "The Plated Meal draws Wooden Spoon at end of turn."
			before = _snapshot(state)
			service._resolve_end_turn_triggers(state, "player")
			passed = state.player.hand == ["item_wooden_spoon"]
		"gazelle_buff":
			var gazelle := _add_unit(state, "player", "hearty_gravy_gazelle", "plated")
			expected = "Gravy Gazelle becomes 4/6 and records its once-per-turn use."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(gazelle.instance_id), service.card("hearty_gravy_gazelle").abilities[0], int(gazelle.instance_id))
			passed = int(gazelle.attack) == 4 and int(gazelle.health) == 6 and gazelle.used_abilities.has("gravy_gazelle_buff")
		"cicada_ko":
			var cicada := _add_unit(state, "player", "spicy_chili_cicada", "prep")
			var target := _add_unit(state, "opponent", "hearty_stewoose", "plated")
			cicada.health = 0
			expected = "Chili Cicada is discarded and Stewoose takes 3 damage."
			before = _snapshot(state)
			service._remove_defeated(state, "player")
			service.choose_effect_target(state, int(target.instance_id))
			passed = state.player.discard.has("spicy_chili_cicada") and int(target.health) == 5
		"hydra_absorb":
			var hydra := _add_unit(state, "player", "fresh_harvest_hydra", "plated")
			hydra.served_sacrifice_attack = 4
			hydra.served_sacrifice_health = 5
			_add_unit(state, "player", "fresh_crisp_capybara", "prep")
			_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
			expected = "Hydra absorbs its serving sacrifices and all other units, ending at 9/12."
			before = _snapshot(state)
			service._resolve_effects(state, "player", service.card("fresh_harvest_hydra").on_play, hydra)
			passed = state.player.prep.is_empty() and int(hydra.attack) == 9 and int(hydra.health) == 12
		"gorilla_prep":
			var gorilla := _add_unit(state, "player", "fresh_garden_gorilla", "plated")
			_add_unit(state, "player", "fresh_crisp_capybara", "prep")
			_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
			expected = "Two other Fresh Prep units raise Garden Gorilla from 3 to 7 Attack."
			before = _snapshot(state)
			service._refresh_stat_auras(state)
			passed = int(gorilla.attack) == 7
		"pike_ping":
			var pike := _add_unit(state, "player", "spicy_pepper_pike", "plated")
			var meal := _add_unit(state, "opponent", "hearty_stewoose", "plated")
			expected = "Pepper Pike marks its ability used and lowers Stewoose to 7 Health."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(meal.instance_id))
			passed = int(meal.health) == 7 and pike.used_abilities.has("pepper_pike_ping")
		"mole_ko_heal":
			var mole := _add_unit(state, "player", "hearty_meatloaf_mole", "plated")
			mole.health = 3
			var victim := _add_unit(state, "opponent", "spicy_hot_honey_bee", "plated")
			victim.attack = 0
			expected = "Meatloaf Mole KOs the defender and heals from 3 to 5."
			before = _snapshot(state)
			service._resolve_unit_battle(state, "player", mole, victim)
			passed = int(mole.health) == 5 and state.opponent.plated.is_empty()
		"buffalo_heal":
			var buffalo := _add_unit(state, "player", "hearty_broth_buffalo", "plated")
			var patient := _add_unit(state, "player", "hearty_macaroni_manatee", "prep")
			patient.health = 1
			expected = "Broth Buffalo heals Macaronatee from 1 to 3 Health."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(buffalo.instance_id), service.card("hearty_broth_buffalo").abilities[0], int(patient.instance_id))
			passed = int(patient.health) == 3
		"raccoon_copy":
			var raccoon := _add_unit(state, "player", "funky_remix_raccoon", "plated")
			var copied := _add_unit(state, "player", "hearty_gravy_gazelle", "prep")
			expected = "Relish Raccoon copies Gravy Gazelle and buffs itself to 5/7."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(raccoon.instance_id), service.card("funky_remix_raccoon").abilities[0], int(copied.instance_id))
			service.choose_effect_target(state, int(raccoon.instance_id))
			passed = int(raccoon.attack) == 5 and int(raccoon.health) == 7
		"beetle_mill":
			state.player.deck = ["fresh_crisp_capybara"]
			var beetle := _add_unit(state, "player", "funky_beat_beetle", "prep")
			expected = "Beet Beetle mills a unit and grows from 1/1 to 4/4."
			before = _snapshot(state)
			service._resolve_effects(state, "player", service.card("funky_beat_beetle").on_play, beetle)
			passed = int(beetle.attack) == 4 and int(beetle.health) == 4 and state.player.discard.has("fresh_crisp_capybara")
		"tern_refill":
			var tern := _add_unit(state, "player", "sweet_bottomless_trifle_tern", "plated")
			tern.ready = true
			state.player.deck = ["item_wooden_spoon", "item_recipe_prep", "chef_mary", "fresh_crisp_capybara", "funky_fondue_ferret", "spicy_hot_honey_bee"]
			expected = "Tern attacks the Chef and draws until its controller has six cards."
			before = _snapshot(state)
			service.select_attacker(state, int(tern.instance_id))
			service.attack(state, -1)
			passed = state.player.hand.size() == 6 and int(state.opponent.life) == 21
		"skunk_shield":
			_add_unit(state, "player", "fresh_salad_shield_skunk", "prep")
			var protected := _add_unit(state, "player", "fresh_crisp_capybara", "prep")
			expected = "The other Prep unit ignores 3 opposing effect damage."
			before = _snapshot(state)
			service._deal_effect_damage_to_unit(state, "opponent", "player", protected, 3)
			passed = int(protected.health) == 3
		"puma_prep_attack":
			var puma := _add_unit(state, "player", "sweet_pudding_puma", "prep")
			puma.ready = true
			expected = "Pudding Puma attacks from Prep and deals 3 to the opposing Chef."
			before = _snapshot(state)
			service.select_attacker(state, int(puma.instance_id))
			service.attack(state, -1)
			passed = int(state.opponent.life) == 22 and not bool(puma.ready)
		"chef_trap":
			state.player.hand = ["funky_chef_check_chinchilla"]
			state.opponent.hand = ["chef_mary"]
			expected = "The response window consumes Chinchilla and negates Chef Mary."
			before = _snapshot(state)
			service._play_chef(state, "opponent", 0)
			service.resolve_reaction(state, 0)
			passed = state.player.discard.has("funky_chef_check_chinchilla") and state.opponent.discard.has("chef_mary")
		"ingredient_trap":
			state.player.hand = ["spicy_pantry_pouncer"]
			state.opponent.hand = ["hearty_macaroni_manatee"]
			expected = "Pantry Pouncer resolves after the Ingredient's on-play timing and destroys it."
			before = _snapshot(state)
			service._play_ingredient(state, "opponent", 0, "prep")
			service.resolve_reaction(state, 0)
			passed = state.opponent.prep.is_empty() and state.opponent.discard.has("hearty_macaroni_manatee")
		"tool_trap":
			state.player.hand = ["funky_toolbox_toad"]
			state.opponent.hand = ["item_wooden_spoon"]
			expected = "Tamari Toad negates Wooden Spoon before it draws."
			before = _snapshot(state)
			service._play_tool(state, "opponent", 0)
			service.resolve_reaction(state, 0)
			passed = state.opponent.discard.has("item_wooden_spoon") and state.opponent.hand.is_empty()
		"ability_trap":
			state.player.hand = ["sweet_ability_axolotl"]
			var enemy_pike := _add_unit(state, "opponent", "spicy_pepper_pike", "plated")
			enemy_pike.ready = false
			var friendly_meal := _add_unit(state, "player", "hearty_stewoose", "plated")
			expected = "Ability Axolotl negates Pepper Pike; Stewoose remains at 8 Health."
			before = _snapshot(state)
			service._resolve_activated_ability_for_side(state, "opponent", int(enemy_pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(friendly_meal.instance_id), true)
			service.resolve_reaction(state, 0)
			passed = int(friendly_meal.health) == 8 and state.player.discard.has("sweet_ability_axolotl")
		"corgi_comeback":
			state.player.hand = ["fresh_comeback_corgi"]
			expected = "After 2 Chef damage, Corgi enters Plated and creates a 1/1 Fresh token in Prep."
			before = _snapshot(state)
			service._deal_chef_damage(state, "player", 2, "opponent", false)
			service.resolve_reaction(state, 0)
			passed = _has_card(state.player.plated, "fresh_comeback_corgi") and _has_card(state.player.prep, "token_fresh_ingredient")
		"tapir_guard":
			var tapir := _add_unit(state, "player", "funky_trap_jam_tapir", "plated")
			var guarded_pike := _add_unit(state, "player", "spicy_pepper_pike", "plated")
			var guarded_target := _add_unit(state, "opponent", "hearty_stewoose", "plated")
			state.opponent.hand = ["sweet_ability_axolotl"]
			expected = "Tapir negates Ability Axolotl, so Pepper Pike still deals 1 damage."
			before = _snapshot(state)
			service._resolve_activated_ability(state, int(guarded_pike.instance_id), service.card("spicy_pepper_pike").abilities[0], int(guarded_target.instance_id))
			passed = int(guarded_target.health) == 7 and tapir.used_abilities.has("hand_trap_guard")
		_:
			expected = "Known scenario id."
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
	var details: VBoxContainer = host._add_panel(host.content, String(data.get("name", scenario.label)), "#263342")
	details.name = "CardEffectLabCardDetails"
	var stats: String = host._card_descriptor(data)
	if data.has("attack"):
		stats += " • %d/%d" % [int(data.attack), int(data.health)]
	if not data.get("recipe", []).is_empty():
		stats += " • Recipe: %s" % host._format_affinity_requirements(data.recipe)
	if String(data.get("required_meal_archetype", "")) != "":
		stats += " + %s Meal" % host._affinity_label(String(data.required_meal_archetype))
	host._add_body_text(details, stats)
	host._add_body_text(details, String(data.get("text", "No rules text.")))


func _add_result_panel(host, result: Dictionary) -> void:
	var accent := "#1f4933" if bool(result.passed) else "#542b2b"
	var panel: VBoxContainer = host._add_panel(host.content, "%s — %s" % ["PASS" if bool(result.passed) else "FAIL", result.label], accent)
	panel.name = "CardEffectLabResult"
	host._add_body_text(panel, "Expected: " + String(result.expected))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	panel.add_child(columns)
	_add_snapshot_column(host, columns, "Before", String(result.before))
	_add_snapshot_column(host, columns, "After", String(result.after))
	var log_panel: VBoxContainer = host._add_panel(panel, "Production event log", "#202734")
	var log_text := "No log entries."
	if not result.log.is_empty():
		log_text = "\n".join(result.log)
	host._add_body_text(log_panel, log_text)


func _add_snapshot_column(host, parent: Node, title: String, snapshot: String) -> void:
	var box: VBoxContainer = host._add_panel(parent, title, "#1b222c")
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._add_body_text(box, snapshot)


func _add_all_results(host) -> void:
	var passed_count := 0
	for result in all_results:
		if bool(result.passed):
			passed_count += 1
	var panel: VBoxContainer = host._add_panel(host.content, "All-card regression: %d/%d passed" % [passed_count, all_results.size()], "#1f4933" if passed_count == all_results.size() else "#542b2b")
	panel.name = "CardEffectLabAllResults"
	for result in all_results:
		var line: Label = host._add_body_text(panel, "%s  %s" % ["PASS" if bool(result.passed) else "FAIL", result.label])
		line.add_theme_color_override("font_color", Color("#9ee6ad") if bool(result.passed) else Color("#ffaaa0"))


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
		state[side].life = 25
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
