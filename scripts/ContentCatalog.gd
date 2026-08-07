extends RefCounted
class_name ContentCatalog

const CARDS_PATH := "res://data/cards.json"
const BOOSTERS_PATH := "res://data/content/boosters.json"
const TOURNAMENTS_PATH := "res://data/content/tournaments.json"

const ARCHETYPE_DATA := {
	"spicy": {
		"name": "Spicy Starter",
		"strategy": "pressure",
		"summary": "Fast damage, direct pressure, and explosive plated attackers.",
		"tags": ["spicy", "pressure", "damage"],
		"color": "#d95735",
		"phaseWeights": {"speed": 0.34, "power": 0.26, "interaction": 0.20, "resilience": 0.08, "advantage": 0.12},
		"matchups": {"hearty": -0.06, "sweet": 0.06}
	},
	"hearty": {
		"name": "Hearty Starter",
		"strategy": "resilience",
		"summary": "Durable boards, healing, and Meals that grow into sturdy threats.",
		"tags": ["hearty", "resilience", "healing"],
		"color": "#8a6b32",
		"phaseWeights": {"speed": 0.08, "power": 0.25, "interaction": 0.12, "resilience": 0.35, "advantage": 0.20},
		"matchups": {"spicy": 0.06, "sweet": -0.06}
	},
	"sweet": {
		"name": "Sweet Starter",
		"strategy": "advantage",
		"summary": "Card draw, flexible disruption, and Prep-based support effects.",
		"tags": ["sweet", "advantage", "tempo"],
		"color": "#c75ba3",
		"phaseWeights": {"speed": 0.15, "power": 0.12, "interaction": 0.23, "resilience": 0.15, "advantage": 0.35},
		"matchups": {"spicy": -0.04, "hearty": 0.04, "fresh": -0.04}
	},
	"fresh": {
		"name": "Fresh Starter",
		"strategy": "swarm",
		"summary": "Flood Prep with Ingredients and tokens, then consolidate them into explosive Meals.",
		"tags": ["fresh", "swarm", "sacrifice"],
		"color": "#52a86b",
		"phaseWeights": {"speed": 0.22, "power": 0.24, "interaction": 0.10, "resilience": 0.20, "advantage": 0.24},
		"matchups": {"spicy": -0.08, "sweet": 0.04}
	},
	"funky": {
		"name": "Funky Starter",
		"strategy": "trickery",
		"summary": "Turn discards into setup, copy abilities, and answer opposing actions from hand.",
		"tags": ["funky", "discard", "trickery"],
		"color": "#7458b8",
		"phaseWeights": {"speed": 0.12, "power": 0.15, "interaction": 0.35, "resilience": 0.13, "advantage": 0.25},
		"matchups": {"fresh": 0.02}
	}
}

var cards: Array = []
var cards_by_id: Dictionary = {}
var expansions: Array = []
var expansions_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var tournaments_by_id: Dictionary = {}


func load_all() -> bool:
	cards = []
	cards_by_id = {}
	expansions = []
	expansions_by_id = {}
	archetypes_by_id = {}
	boosters_by_id = {}
	tournaments_by_id = {}

	var card_data := _load_json(CARDS_PATH)
	var booster_data := _load_json(BOOSTERS_PATH)
	var tournament_data := _load_json(TOURNAMENTS_PATH)
	if card_data.is_empty() or booster_data.is_empty() or tournament_data.is_empty():
		return false

	var default_expansion_id := String(card_data.get("default_expansion_id", "core"))
	for source_expansion in card_data.get("expansions", []):
		var expansion: Dictionary = source_expansion.duplicate(true)
		var expansion_id := String(expansion.get("id", ""))
		if expansion_id.is_empty():
			continue
		expansions.append(expansion)
		expansions_by_id[expansion_id] = expansion
	if expansions.is_empty():
		var fallback_expansion := {
			"id": default_expansion_id,
			"name": "Core Set",
			"code": "CORE",
			"release_order": 0,
		}
		expansions.append(fallback_expansion)
		expansions_by_id[default_expansion_id] = fallback_expansion
	expansions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_order := int(a.get("release_order", 0))
		var b_order := int(b.get("release_order", 0))
		if a_order == b_order:
			return String(a.get("name", "")) < String(b.get("name", ""))
		return a_order < b_order
	)

	for source_card in card_data.get("cards", []):
		var card: Dictionary = source_card.duplicate(true)
		_decorate_card(card, default_expansion_id)
		cards.append(card)
		cards_by_id[String(card.get("id", ""))] = card

	_build_archetypes(card_data.get("decks", {}))

	for booster in booster_data.get("boosters", []):
		boosters_by_id[String(booster.get("id", ""))] = booster
	for tournament in tournament_data.get("tournaments", []):
		tournaments_by_id[String(tournament.get("id", ""))] = tournament

	return cards.size() > 0 and not archetypes_by_id.is_empty()


func deck_entries_to_dict(entries: Array) -> Dictionary:
	var deck := {}
	for entry in entries:
		deck[String(entry.get("cardId", ""))] = int(entry.get("count", 0))
	return deck


func _build_archetypes(deck_data: Dictionary) -> void:
	for deck_id in deck_data:
		var source: Dictionary = deck_data[deck_id]
		var archetype_id := String(source.get("archetype", ""))
		if not ARCHETYPE_DATA.has(archetype_id):
			continue
		var archetype: Dictionary = ARCHETYPE_DATA[archetype_id].duplicate(true)
		archetype["id"] = archetype_id
		archetype["animalType"] = archetype_id
		archetype["desiredRoles"] = {"threat": 8, "finisher": 5, "answer": 10, "engine": 2, "filter": 4}
		var starter: Array = []
		for card_id in source.get("cards", {}):
			starter.append({"cardId": String(card_id), "count": int(source.cards[card_id])})
		archetype["starterDeck"] = starter
		archetypes_by_id[archetype_id] = archetype


func _decorate_card(card: Dictionary, default_expansion_id: String = "core") -> void:
	var card_type := String(card.get("card_type", "tool"))
	var rarity := "common"
	if card_type == "chef":
		rarity = "mythic"
	elif bool(card.get("rare", false)):
		rarity = "rare"
	elif card_type in ["meal", "spice", "environment"]:
		rarity = "uncommon"
	card["rarity"] = rarity
	card["expansion_id"] = String(card.get("expansion_id", default_expansion_id))
	card["deckLimit"] = 3
	card["cost"] = card.get("recipe", []).size() if card_type == "meal" else int(card.get("discard_cost", 0))
	card["value"] = {"common": 2, "uncommon": 4, "rare": 7, "mythic": 10}.get(rarity, 2)
	card["animalType"] = String(card.get("archetype", "neutral"))
	card["role"] = _role_for_type(card_type)
	card["stats"] = _season_stats(card)
	card["tags"] = _card_tags(card)


func _role_for_type(card_type: String) -> String:
	match card_type:
		"ingredient":
			return "threat"
		"meal":
			return "finisher"
		"spice", "environment":
			return "engine"
		"chef":
			return "filter"
		_:
			return "answer"


func _season_stats(card: Dictionary) -> Dictionary:
	var card_type := String(card.get("card_type", "tool"))
	var archetype := String(card.get("archetype", "neutral"))
	var text := String(card.get("text", "")).to_lower()
	var attack := int(card.get("attack", 0))
	var health := int(card.get("health", 0))
	return {
		"speed": 3 if archetype == "spicy" else (2 if card_type == "ingredient" else 1),
		"power": clamp(attack / 2, 1, 5) if attack > 0 else (2 if "damage" in text or "destroy" in text else 1),
		"interaction": 4 if card_type == "tool" else (3 if "return" in text or "cannot" in text else 1),
		"resilience": clamp(health / 2, 1, 5) if health > 0 else (3 if "heal" in text else 1),
		"advantage": 4 if "draw" in text or "search" in text else (2 if card_type in ["chef", "environment"] else 1),
		"consistency": 3 if "draw" in text or "search" in text else 1
	}


func _card_tags(card: Dictionary) -> Array:
	var tags: Array = [String(card.get("card_type", "card"))]
	var archetype := String(card.get("archetype", "neutral"))
	if archetype != "neutral":
		tags.append(archetype)
	for secondary_archetype in card.get("archetypes", []):
		if not tags.has(String(secondary_archetype)):
			tags.append(String(secondary_archetype))
	for keyword in card.get("keywords", []):
		tags.append(String(keyword))
	return tags


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not load " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON at " + path)
		return {}
	return parsed
