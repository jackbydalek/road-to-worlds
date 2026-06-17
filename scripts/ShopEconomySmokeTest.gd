extends SceneTree

const CONTENT_CATALOG_SCRIPT := preload("res://scripts/ContentCatalog.gd")
const RUN_STATE_SERVICE_SCRIPT := preload("res://scripts/RunStateService.gd")
const SHOP_ECONOMY_SERVICE_SCRIPT := preload("res://scripts/ShopEconomyService.gd")

const ARCHETYPE_ORDER := ["flightless_birds", "snake", "oxen", "glires", "insect"]
const MAIN_DECK_SIZE := 30
const SIDEBOARD_SIZE := 6
const STARTING_MONEY := 20
const SMOKE_SAVE_PATH := "user://road_to_worlds_shop_economy_smoke.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = CONTENT_CATALOG_SCRIPT.new()
	if not catalog.load_all():
		_fail("Shop economy smoke could not load content.")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 424242

	var run_state = RUN_STATE_SERVICE_SCRIPT.new()
	run_state.setup(catalog.cards_by_id, catalog.archetypes_by_id, ARCHETYPE_ORDER, MAIN_DECK_SIZE, SIDEBOARD_SIZE, STARTING_MONEY, SMOKE_SAVE_PATH)

	var economy = SHOP_ECONOMY_SERVICE_SCRIPT.new()
	economy.setup(catalog.cards, catalog.cards_by_id, catalog.boosters_by_id, rng)

	var starter_deck: Dictionary = catalog.deck_entries_to_dict(catalog.archetypes_by_id["oxen"].starterDeck)
	var run: Dictionary = run_state.create_run("oxen", starter_deck, run_state.predator_archetype("oxen"))
	var primary := "oxen"

	economy.generate_shop_inventory(run, primary)
	if run.shop.size() != 8:
		_fail("Shop economy smoke generated wrong shop size.")
		return

	var starting_money := int(run.money)
	var pack_result: Dictionary = economy.buy_and_open_pack(run, "base_standard_pack", primary)
	if not bool(pack_result.get("ok", false)):
		_fail("Shop economy smoke could not buy pack: " + String(pack_result.get("message", "")))
		return
	if int(run.money) != starting_money - int(catalog.boosters_by_id["base_standard_pack"].price):
		_fail("Shop economy smoke did not subtract booster price.")
		return
	if run.current_pack.size() != 8 or run.revealed_pack.size() != 0 or int(run.pack_index) != 0:
		_fail("Shop economy smoke did not start pack state correctly.")
		return

	var first_card_id := String(run.current_pack[0].cardId)
	var owned_before := int(run.collection.get(first_card_id, 0))
	economy.reveal_next_card(run, primary)
	if int(run.pack_index) != 1 or run.revealed_pack.size() != 1:
		_fail("Shop economy smoke did not reveal exactly one card.")
		return
	if int(run.collection.get(first_card_id, 0)) != owned_before + 1:
		_fail("Shop economy smoke did not add revealed card to collection.")
		return
	if String(run.revealed_pack[0].get("note", "")) == "":
		_fail("Shop economy smoke did not generate reveal note.")
		return

	economy.reveal_all_cards(run, primary)
	if int(run.pack_index) != run.current_pack.size():
		_fail("Shop economy smoke did not reveal all cards.")
		return

	run.prize_packs = 1
	var prize_result: Dictionary = economy.open_prize_pack(run, "base_standard_pack", primary)
	if not bool(prize_result.get("ok", false)) or int(run.prize_packs) != 0:
		_fail("Shop economy smoke did not open prize pack.")
		return

	var single_id := String(run.shop[0])
	run.money = 100
	var price := economy.card_price(run, single_id)
	var single_owned_before := int(run.collection.get(single_id, 0))
	var buy_result: Dictionary = economy.buy_single(run, single_id)
	if not bool(buy_result.get("ok", false)):
		_fail("Shop economy smoke could not buy single: " + String(buy_result.get("message", "")))
		return
	if int(run.money) != 100 - price:
		_fail("Shop economy smoke did not subtract single price.")
		return
	if int(run.collection.get(single_id, 0)) != single_owned_before + 1:
		_fail("Shop economy smoke did not add bought single to collection.")
		return

	run.money = 0
	var denied_result: Dictionary = economy.buy_single(run, single_id)
	if bool(denied_result.get("ok", false)):
		_fail("Shop economy smoke allowed unaffordable single.")
		return

	print("Shop economy smoke covered inventory, packs, reveals, prizes, pricing, and singles.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
