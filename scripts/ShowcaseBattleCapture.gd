extends SceneTree

const TABLETOP_SCENE := preload("res://scenes/Tabletop3DPrototype.tscn")
const CAPTURE_SIZE := Vector2i(1440, 900)

var tabletop
var curtain: ColorRect


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	tabletop = TABLETOP_SCENE.instantiate()
	tabletop.configure_match(
		_hearty_deck(),
		_fresh_deck(),
		"Hearty Starter",
		"Local Rival — Fresh",
		20260807,
		"player",
		"Return",
		"easy",
		"white"
	)
	tabletop.configure_battle_preferences("fast", 1.0)
	root.add_child(tabletop)
	await _settle(12)
	_create_curtain()
	await _fade(0.0, 0.6)
	await create_timer(1.7).timeout

	_stage_hearty_board()
	await _settle(5)
	await create_timer(1.4).timeout
	var gazelle_id := int(tabletop.get_meta("showcase_gazelle_id", -1))
	var lasagnama_id := int(tabletop.get_meta("showcase_lasagnama_id", -1))
	var defender_id := int(tabletop.get_meta("showcase_defender_id", -1))
	await tabletop._activate_ability(gazelle_id, "gravy_gazelle_buff")
	await create_timer(0.6).timeout
	await tabletop._choose_ability_target_animated(lasagnama_id)
	await create_timer(0.9).timeout
	tabletop._select_attacker(lasagnama_id)
	await create_timer(0.45).timeout
	await tabletop._perform_attack(defender_id)
	await create_timer(0.9).timeout
	await tabletop._perform_attack(-1, gazelle_id)
	await create_timer(1.8).timeout
	await _fade(1.0, 0.7)
	quit()


func _stage_hearty_board() -> void:
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

	var gazelle := _add_unit("player", "hearty_gravy_gazelle", "plated", 0, true)
	var lasagnama := _add_unit("player", "hearty_lasagnama", "plated", 1, true)
	_add_unit("player", "hearty_bagver", "prep", 1, false)
	var defender := _add_unit("opponent", "fresh_saladmander", "plated", 0, true)
	tabletop.set_meta("showcase_gazelle_id", int(gazelle.instance_id))
	tabletop.set_meta("showcase_lasagnama_id", int(lasagnama.instance_id))
	tabletop.set_meta("showcase_defender_id", int(defender.instance_id))
	tabletop.service.clear_animation_events(state)
	tabletop.selected_ref = {}
	tabletop.animation_busy = false
	tabletop._render_match()


func _add_unit(side: String, card_id: String, zone: String, slot: int, ready: bool) -> Dictionary:
	var combatant: Dictionary = tabletop.state[side]
	var unit: Dictionary = tabletop.service._make_unit(
		tabletop.state,
		combatant,
		tabletop.service.card(card_id),
		zone,
		side
	)
	unit.table_slot = slot
	unit.ready = ready
	combatant[zone].append(unit)
	return unit


func _hearty_deck() -> Dictionary:
	return {
		"chef_mary": 3,
		"hearty_bagver": 2,
		"hearty_french_bread_dog": 3,
		"hearty_macaroni_manatee": 3,
		"hearty_ramen_ram": 3,
		"hearty_gravy_gazelle": 2,
		"hearty_polar_pot_pie_bear": 1,
		"item_recipe_prep": 2,
		"item_switchblade": 1,
	}


func _fresh_deck() -> Dictionary:
	return {
		"chef_rachel": 3,
		"fresh_sprout_squirrel": 3,
		"fresh_salad_shield_skunk": 3,
		"fresh_crisp_capybara": 2,
		"fresh_saladmander": 3,
		"fresh_garden_gorilla": 2,
		"item_recipe_prep": 2,
		"item_wooden_spoon": 2,
	}


func _create_curtain() -> void:
	curtain = ColorRect.new()
	curtain.position = Vector2.ZERO
	curtain.size = Vector2(CAPTURE_SIZE)
	curtain.color = Color("#29365F")
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.z_index = 4095
	root.add_child(curtain)


func _fade(alpha: float, duration: float) -> void:
	curtain.visible = true
	var tween := curtain.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(curtain, "color:a", alpha, duration)
	await tween.finished
	if alpha <= 0.0:
		curtain.visible = false


func _settle(frames: int) -> void:
	for unused in range(frames):
		await process_frame
