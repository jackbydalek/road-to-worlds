extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/cooking/CookingCombatService.gd")
const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const RUN_STATE_SCRIPT := preload("res://scripts/RunStateService.gd")

const EXPECTED_DECKS := {
	"spicy_test_kitchen": {
		"spicy_hot_honey_bee": 3,
		"spicy_jalapeno_jackal": 3,
		"spicy_jalapeno_panther": 2,
		"spicy_wasabi_wasp": 3,
		"spicy_sriracharrow": 2,
		"spicy_firecracker_shrimp": 1,
		"item_strainer": 1,
		"item_recipe_prep": 2,
		"chef_mary": 3,
	},
	"sweet_test_kitchen": {
		"sweet_caramel_camel": 3,
		"sweet_soft_serve_crab": 3,
		"sweet_jellyfish": 3,
		"sweet_sugar_glider": 2,
		"sweet_strawberry_sharkcake": 2,
		"sweet_cinnamon_snail": 1,
		"item_wooden_spoon": 1,
		"item_recipe_prep": 2,
		"chef_mary": 3,
	},
	"hearty_test_kitchen": {
		"hearty_french_bread_dog": 3,
		"hearty_macaroni_manatee": 3,
		"hearty_ramen_ram": 3,
		"hearty_bagver": 2,
		"hearty_gravy_gazelle": 2,
		"hearty_polar_pot_pie_bear": 1,
		"item_switchblade": 1,
		"item_recipe_prep": 2,
		"chef_mary": 3,
	},
	"fresh_test_kitchen": {
		"fresh_sprout_squirrel": 3,
		"fresh_salad_shield_skunk": 3,
		"fresh_crisp_capybara": 2,
		"fresh_spicy_mexican_sweet_corino": 3,
		"fresh_saladmander": 2,
		"fresh_harvest_hydra": 1,
		"item_fresh_shopping_list": 1,
		"item_recipe_prep": 2,
		"chef_mary": 3,
	},
}

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service: RefCounted = SERVICE_SCRIPT.new()
	_expect(service.load_content(), "The updated starter-deck content did not load.")
	if failed:
		quit(1)
		return

	for deck_id in EXPECTED_DECKS:
		var actual: Dictionary = service.decks.get(deck_id, {}).get("cards", {})
		_expect(_deck_matches(actual, EXPECTED_DECKS[deck_id]), "%s did not match the requested 20-card list." % deck_id)
		_expect(_deck_total(actual) == 20, "%s did not contain exactly 20 cards." % deck_id)

	var catalog: RefCounted = CONTENT_CATALOG_SCRIPT.new()
	_expect(catalog.load_all(), "The season content catalog did not load the updated starters.")
	var run_state: RefCounted = RUN_STATE_SCRIPT.new()
	run_state.setup(catalog.cards_by_id, catalog.archetypes_by_id, ["spicy", "hearty", "sweet", "fresh"], 1, 6, 20, "", 0)
	for archetype_id in ["spicy", "sweet", "hearty", "fresh"]:
		var season_deck := {}
		for entry in catalog.archetypes_by_id[archetype_id].get("starterDeck", []):
			season_deck[String(entry.get("cardId", ""))] = int(entry.get("count", 0))
		var deck_id := "%s_test_kitchen" % archetype_id
		_expect(_deck_matches(season_deck, EXPECTED_DECKS[deck_id]), "%s season starter did not match the source deck." % archetype_id)
		_expect(
			bool(run_state.deck_is_legal({"deck": season_deck, "collection": season_deck.duplicate(true), "sideboard": {}}).get("ok", false)),
			"%s starter was not a legal 20-card season deck." % archetype_id
		)

	var giada: Dictionary = service.card("chef_mary")
	_expect(
		String(giada.get("text", "")) == "Draw 3 cards."
		and giada.get("effects", []).size() == 1
		and int(giada.effects[0].get("amount", 0)) == 3,
		"Chef Giada's printed text and draw effect were not both updated to three cards."
	)
	var state: Dictionary = service.start_game("spicy_test_kitchen", "hearty_test_kitchen", 72901)
	state.player.hand = ["chef_mary"]
	state.player.deck = [
		"item_wooden_spoon",
		"spicy_hot_honey_bee",
		"hearty_bagver",
		"sweet_sugar_glider",
	]
	service.play_card(state, 0)
	_expect(
		state.player.hand.size() == 3 and state.player.deck.size() == 1,
		"Playing Chef Giada did not draw exactly three cards."
	)

	if failed:
		quit(1)
		return
	print("Starter deck update smoke test passed.")
	quit()


func _deck_total(deck: Dictionary) -> int:
	var total := 0
	for count in deck.values():
		total += int(count)
	return total


func _deck_matches(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for card_id in expected:
		if int(actual.get(card_id, -1)) != int(expected[card_id]):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
