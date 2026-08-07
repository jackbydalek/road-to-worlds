extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")

const EXPECTED_BY_TYPE := {
	"ingredient": [
		"spicy_hot_honey_bee", "spicy_jalapeno_jackal", "spicy_jalapeno_panther", "spicy_wasabi_wasp",
		"spicy_ghost_pepper_python", "spicy_funky_arrabbeta", "funky_chef_check_chinchilla", "funky_toolbox_toad",
		"funky_fondue_ferret", "funky_eggplant_ant", "funky_beat_beetle", "funky_sweet_bread_puddppy",
		"sweet_caramel_camel", "sweet_soft_serve_crab", "sweet_jellyfish", "sweet_sugar_glider",
		"sweet_toffee_collie", "sweet_hearty_chia_chilla_pudding", "hearty_french_bread_dog",
		"hearty_macaroni_manatee", "hearty_ramen_ram", "hearty_bagver", "hearty_fresh_lemon_herb_chicken",
		"hearty_kale_whale", "fresh_comeback_corgi", "fresh_sprout_squirrel", "fresh_salad_shield_skunk",
		"fresh_crisp_capybara", "spicy_habanero_hare", "fresh_spicy_mexican_sweet_corino"
	],
	"meal": [
		"spicy_sriracharrow", "spicy_firecracker_shrimp", "spicy_hot_sauchuar", "spicy_funky_jambaye_aye",
		"spicy_funky_relishoon", "funky_sauerkrat", "funky_bibimbear", "funky_sweet_pika_le",
		"sweet_pudding_puma", "sweet_strawberry_sharkcake", "sweet_cinnamon_snail", "sweet_mothchi",
		"sweet_pup_tart", "sweet_pandacake", "hearty_gravy_gazelle", "hearty_polar_pot_pie_bear",
		"hearty_lasagnama", "hearty_dumpling_tortoise", "hearty_bison_burrito", "fresh_saladmander",
		"fresh_harvest_hydra", "fresh_garden_gorilla", "fresh_spicy_yolke_bowl"
	],
	"chef": [
		"chef_john", "chef_bill", "chef_gusteau", "chef_mary", "chef_soup", "chef_brown", "chef_duff",
		"chef_emril", "chef_carl"
	],
	"tool": [
		"item_spicy_shopping_list", "item_sweet_shopping_list", "item_hearty_shopping_list",
		"item_fresh_shopping_list", "item_funky_shopping_list", "item_recipe_prep", "item_blow_torch",
		"item_tool_drawer", "item_tongs", "item_strainer", "item_hand_mixer", "item_switchblade",
		"item_grater", "item_measuring_cup", "item_wooden_spoon"
	],
	"environment": [
		"environment_spicy_taqueria", "environment_hearty_diner", "environment_sweet_bakery",
		"environment_funky_pickle_stand", "environment_fresh_greensweet"
	],
	"spice": [
		"spice_cayenne_crunch", "spice_savory_gravy", "spice_sugar_glaze", "spice_funky_brine",
		"spice_fresh_balsamic"
	]
}


func _init() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	if not service.load_content():
		_fail("Could not load data/cards.json.")
		return

	var expected_ids: Array[String] = []
	for card_type in EXPECTED_BY_TYPE:
		for card_id in EXPECTED_BY_TYPE[card_type]:
			if expected_ids.has(card_id):
				_fail("Canonical catalog repeats id %s." % card_id)
				return
			expected_ids.append(card_id)
			var data: Dictionary = service.card(card_id)
			if data.is_empty():
				_fail("Canonical card %s is missing." % card_id)
				return
			if String(data.get("card_type", "")) != String(card_type):
				_fail("Canonical card %s is registered as %s instead of %s." % [card_id, data.get("card_type", "missing"), card_type])
				return

	if expected_ids.size() != 87:
		_fail("The locked demo manifest contains %d ids instead of 87." % expected_ids.size())
		return
	for card_id in service.cards_by_id:
		if card_id == "token_fresh_ingredient":
			continue
		if not expected_ids.has(String(card_id)):
			_fail("Noncanonical collectible %s is still in the production catalog." % card_id)
			return
	if service.cards_by_id.size() != 88:
		_fail("Expected 87 canonical collectibles plus the service-only Fresh token; loaded %d cards." % service.cards_by_id.size())
		return

	print("Canonical catalog smoke test passed: 87 collectibles plus the Fresh token.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
