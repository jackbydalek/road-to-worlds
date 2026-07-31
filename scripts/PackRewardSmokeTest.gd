extends SceneTree

const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const SHOP_ECONOMY_SERVICE_SCRIPT := preload("res://scripts/ShopEconomyService.gd")
const AFFINITY_ORDER := ["spicy", "hearty", "sweet", "fresh", "funky"]

var failed := false


func _init() -> void:
	var catalog: RefCounted = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "Pack reward test could not load the card catalog.")

	var rng := RandomNumberGenerator.new()
	rng.seed = 7252026
	var economy: RefCounted = SHOP_ECONOMY_SERVICE_SCRIPT.new()
	economy.setup(catalog.cards, catalog.cards_by_id, catalog.boosters_by_id, rng)

	for booster_id in ["base_standard_pack", "season_prize_pack"]:
		for pack_index in range(40):
			var pack: Array = economy.generate_pack(booster_id, "spicy")
			_expect(pack.size() == 5, "%s did not generate exactly five cards." % booster_id)

	for affinity in AFFINITY_ORDER:
		for pack_index in range(100):
			var prize_pack: Array = economy.generate_pack("season_prize_pack", affinity)
			for entry in prize_pack:
				var card_id := String((entry as Dictionary).get("cardId", ""))
				var card: Dictionary = catalog.cards_by_id.get(card_id, {})
				_expect(
					economy.card_is_affinity_reward_eligible(card, affinity),
					"%s prize pack generated ineligible card %s." % [String(affinity).capitalize(), card_id]
				)

	var funky_deck := {
		"funky_fondue_ferret": 3,
		"funky_eggplant_ant": 3,
		"spicy_ghost_pepper_python": 2,
		"fresh_sprout_squirrel": 2,
		"item_recipe_prep": 3,
	}
	_expect(
		economy.strongest_affinity_for_deck(funky_deck, AFFINITY_ORDER) == "funky",
		"Strongest-affinity calculation did not count Funky and dual-affinity cards."
	)

	var fresh_deck := {
		"fresh_sprout_squirrel": 3,
		"fresh_salad_shield_skunk": 3,
		"hearty_kale_whale": 2,
		"chef_mary": 3,
	}
	_expect(
		economy.strongest_affinity_for_deck(fresh_deck, AFFINITY_ORDER) == "fresh",
		"Strongest-affinity calculation did not support a Fresh-led draft deck."
	)

	_expect(
		economy.card_is_affinity_reward_eligible(catalog.cards_by_id["spicy_ghost_pepper_python"], "funky"),
		"Dual-affinity cards did not qualify through their secondary affinity."
	)
	_expect(
		economy.card_is_affinity_reward_eligible(catalog.cards_by_id["environment_slow_cooker"], "spicy"),
		"Off-affinity Environments were not retained in the tournament support pool."
	)
	_expect(
		economy.card_is_affinity_reward_eligible({"card_type": "spice", "archetype": "neutral"}, "sweet"),
		"Spices were not retained in the tournament support pool."
	)
	_expect(
		not economy.card_is_affinity_reward_eligible(catalog.cards_by_id["fresh_sprout_squirrel"], "sweet"),
		"Off-affinity units were allowed into the tournament reward pool."
	)

	if failed:
		quit(1)
	else:
		print("Five-card affinity prize pack smoke test passed.")
		quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
