extends RefCounted
## Data and durable between-week decisions for the two-tournament demo.
const CONFIG_PATH := "res://data/content/demo_progression.json"
const CARDS_PATH := "res://data/content/second_helpings.json"
var config: Dictionary = read_json(CONFIG_PATH)

static func read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func is_weekly_run(run: Dictionary) -> bool:
	return String(run.get("run_loop", "")) == "route" and String(run.get("campaign_presentation", "")) == "tournament_hub" and run.has("demo_weeks")

static func card_available(card: Dictionary, run: Dictionary) -> bool:
	if bool(card.get("is_token", false)):
		return false
	if not is_weekly_run(run):
		return true
	var unlock_week := maxi(int(card.get("unlock_week", 1)), 2 if String(card.get("card_type", "")) == "spice" else 1)
	return int(run.get("week", 1)) >= unlock_week

func deckbox(id: String) -> Dictionary:
	for entry in config.get("deckboxes", []):
		if String(entry.get("id", "")) == id:
			return entry.duplicate(true)
	return {}

static func bonus(run: Dictionary, effect: String) -> int:
	return int(run.get("deckbox", {}).get("effects", {}).get(effect, 0))

func prepare_deckbox_choice(run: Dictionary) -> void:
	if not run.get("deckbox", {}).is_empty():
		return
	normalize_deckbox_offers(run)
	run.week_transition = "deckbox"

func normalize_deckbox_offers(run: Dictionary) -> void:
	# Preserve valid saved choices and their order. Obsolete prototype IDs are
	# replaced from the same seeded pool once, so an old prize can still be claimed.
	if not run.get("deckbox", {}).is_empty():
		return
	var ids: Array = []
	for entry in config.get("deckboxes", []):
		ids.append(String(entry.id))
	var count := mini(int(config.get("deckbox_offer_count", 3)), ids.size())
	var offers: Array = []
	for id_value in run.get("deckbox_offer", []):
		var id := String(id_value)
		if ids.has(id) and not offers.has(id) and offers.size() < count:
			offers.append(id)
	var random := RandomNumberGenerator.new()
	random.seed = int(run.get("route_seed", 1)) ^ hash("week_one_deckboxes")
	while offers.size() < count and not ids.is_empty():
		var index := random.randi_range(0, ids.size() - 1)
		var id := String(ids.pop_at(index))
		if not offers.has(id):
			offers.append(id)
	run.deckbox_offer = offers

func choose_deckbox(run: Dictionary, id: String) -> bool:
	if String(run.get("week_transition", "")) != "deckbox" or not run.get("deckbox", {}).is_empty() or not run.get("deckbox_offer", []).has(id):
		return false
	var selected := deckbox(id)
	if selected.is_empty():
		return false
	# Snapshot the chosen effect so content edits cannot change an existing save.
	run.deckbox = selected
	var life_bonus := bonus(run, "max_life")
	run.max_life = int(run.get("max_life", 40)) + life_bonus
	run.life = mini(int(run.max_life), int(run.get("life", 0)) + life_bonus)
	run.week_transition = "week_intro"
	run.deckbox_reward = {}
	for reward in [["remove", "remove_cards"], ["upgrade", "upgrade_cards"]]:
		var amount := bonus(run, String(reward[1]))
		if amount > 0:
			run.deckbox_reward = {"kind": String(reward[0]), "remaining": amount, "applied": 0}
			run.week_transition = "deckbox_reward"
			break
	return true

func week_health_recovery(run: Dictionary) -> Dictionary:
	# The Black border retains the saved difficulty ID "white".
	var full_heal_difficulties: Array = config.get("between_week_full_heal_difficulties", ["white", "blue"])
	return {
		"full_heal": full_heal_difficulties.has(String(run.get("difficulty", "white"))),
		"amount": maxi(0, int(config.get("between_week_heal", 20))),
	}

func start_next_week(run: Dictionary) -> bool:
	if String(run.get("week_transition", "")) != "week_intro" or run.get("deckbox", {}).is_empty() or int(run.get("week", 1)) >= int(run.get("demo_weeks", 2)):
		return false
	run.week = int(run.get("week", 1)) + 1
	run.hub_round = 1
	run.hub_break_used = false
	run.hub_break_choice = ""
	run.hub_shop = {}
	run.pending_route_node = {}
	run.route_battle = {}
	run.kitchen_match = {}
	run.kitchen_match_result = {}
	var recovery := week_health_recovery(run)
	run.life = int(run.max_life) if bool(recovery.full_heal) else mini(int(run.max_life), int(run.life) + int(recovery.amount))
	run.week_transition = "new_pack"
	run.hub_notice = "Week %d • Second Helpings has arrived." % int(run.week)
	return true

func make_intro_pack(run: Dictionary, cards: Array, eligibility: Callable) -> Array:
	var specials: Array = []
	var spices: Array = []
	var other: Array = []
	for card in cards:
		if not card_available(card, run) or not eligibility.call(card, String(run.get("starter", "spicy"))):
			continue
		if card.has("special_serve"):
			specials.append(String(card.id))
		elif String(card.get("card_type", "")) == "spice":
			spices.append(String(card.id))
		else:
			other.append(String(card.id))
	var random := RandomNumberGenerator.new()
	random.seed = int(run.get("route_seed", 1)) ^ hash("second_helpings")
	var result: Array = []
	var pack: Dictionary = config.get("week_two_pack", {})
	for entry in [[specials, int(pack.get("guaranteed_special_serves", 2))], [spices, int(pack.get("guaranteed_spices", 1))], [other, int(pack.get("size", 5))]]:
		var pool: Array = entry[0]
		for unused in range(int(entry[1])):
			if pool.is_empty() or result.size() >= int(pack.get("size", 5)):
				break
			result.append(pool.pop_at(random.randi_range(0, pool.size() - 1)))
	return result
