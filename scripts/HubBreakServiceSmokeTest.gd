extends SceneTree
## The two vending snacks share one weekly use, committed only on success.
const CATALOG := preload("res://scripts/ContentCatalog.gd")
const ROUTE := preload("res://scripts/RouteRunService.gd")
const CARD_ID := "spicy_hot_honey_bee"
var service = ROUTE.new()
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	var catalog = CATALOG.new()
	_expect(catalog.load_all(), "The real card catalog did not load.")
	service.setup(catalog.cards, catalog.cards_by_id)
	_test_heal_amount_and_cap()
	_test_shared_use_and_reload()
	_test_uncommitted_upgrade()
	_test_legacy_bonus()
	for failure in failures:
		push_error(failure)
	print("HubBreakServiceSmokeTest: %d checks, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _sample(life: int = 25, maximum: int = 40) -> Dictionary:
	var run := {"starter": "spicy", "deck": {CARD_ID: 2}, "money": 12}
	service.initialize_run(run, 915)
	run.life = life
	run.max_life = maximum
	return run

func _test_heal_amount_and_cap() -> void:
	for entry in [[25, 40, 5], [38, 40, 2], [44, 45, 1]]:
		var run := _sample(entry[0], entry[1])
		var before := run.duplicate(true)
		var result: Dictionary = service.use_hub_break_heal(run)
		_expect(result.ok and result.healed == entry[2] and run.life == entry[0] + entry[2], "Heart Bites did not heal five HP capped to the current maximum: %s." % str(entry))
		_expect(run.hub_break_used and run.hub_break_choice == "heal", "A successful heal did not consume the shared bye.")
		_expect(run.money == before.money and run.deck == before.deck and run.card_upgrades == before.card_upgrades and run.max_life == before.max_life, "Healing changed payment, deck upgrades or maximum life.")
		_expect(String(result.message).contains(str(entry[2])), "The heal result did not report the actual recovered HP.")
	var full := _sample(40)
	var before := full.duplicate(true)
	_expect(not service.use_hub_break_heal(full).ok and full == before, "A full-health heal request spent the bye or changed state.")
	_expect(service.use_hub_break_upgrade(full, CARD_ID).ok, "Rejecting a full-health heal prevented the alternative upgrade.")

func _test_shared_use_and_reload() -> void:
	for choice in ["heal", "upgrade"]:
		var run := _sample()
		var result: Dictionary = service.use_hub_break_heal(run) if choice == "heal" else service.use_hub_break_upgrade(run, CARD_ID)
		_expect(result.ok and run.hub_break_used and run.hub_break_choice == choice, "The chosen %s snack did not record its shared use." % choice)
		_expect(run.life == (30 if choice == "heal" else 25) and service.upgrade_count(run, CARD_ID) == (1 if choice == "upgrade" else 0), "The chosen snack applied the other snack's effect.")
		var restored: Dictionary = JSON.parse_string(JSON.stringify(run))
		service.normalize_run(restored)
		var before := restored.duplicate(true)
		_expect(not service.use_hub_break_heal(restored).ok and restored == before, "An already-used %s snack allowed healing after reload." % choice)
		_expect(not service.use_hub_break_upgrade(restored, CARD_ID).ok and restored == before, "An already-used %s snack allowed an upgrade after reload." % choice)
		_expect(restored.money == 12, "A free vending snack charged money.")

func _test_uncommitted_upgrade() -> void:
	var run := _sample()
	var before := run.duplicate(true)
	# Opening/cancelling a picker only reads choices. The service commit is separate.
	var candidates: Array = service.upgradeable_card_ids(run)
	_expect(candidates.has(CARD_ID) and run == before, "Inspecting upgrade candidates consumed or changed the bye.")
	_expect(not service.use_hub_break_upgrade(run, "not_a_card").ok and run == before, "An invalid upgrade spent the bye or changed state.")
	_expect(service.use_hub_break_heal(run).ok and run.life == 30, "Leaving an uncommitted upgrade prevented the five-HP heal.")
	var upgraded := _sample()
	upgraded.card_upgrades[CARD_ID] = int(upgraded.deck[CARD_ID])
	before = upgraded.duplicate(true)
	_expect(service.upgradeable_card_ids(upgraded).is_empty(), "Fully upgraded copies remain eligible for the snack.")
	_expect(not service.use_hub_break_upgrade(upgraded, CARD_ID).ok and upgraded == before, "Rejecting an exhausted upgrade consumed the bye.")
	_expect(service.use_hub_break_heal(upgraded).ok and upgraded.life == 30, "No upgrade candidates prevented the alternative heal.")

func _test_legacy_bonus() -> void:
	for entry in [[20, 7], [37, 3]]:
		var run := _sample(entry[0])
		run.deckbox = {"id": "saved_legacy_box", "effects": {"bye_heal": 2}}
		var restored: Dictionary = JSON.parse_string(JSON.stringify(run))
		service.normalize_run(restored)
		var result: Dictionary = service.use_hub_break_heal(restored)
		_expect(result.ok and result.healed == entry[1] and restored.life == entry[0] + entry[1], "The five-HP base dropped or uncapped a saved deckbox's heal bonus.")

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
