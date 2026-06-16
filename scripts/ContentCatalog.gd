extends RefCounted
class_name ContentCatalog

const CARDS_PATH := "res://data/content/cards.json"
const ARCHETYPES_PATH := "res://data/content/archetypes.json"
const BOOSTERS_PATH := "res://data/content/boosters.json"
const TOURNAMENTS_PATH := "res://data/content/tournaments.json"

var cards: Array = []
var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var boosters_by_id: Dictionary = {}
var tournaments_by_id: Dictionary = {}


func load_all() -> bool:
	cards = []
	cards_by_id = {}
	archetypes_by_id = {}
	boosters_by_id = {}
	tournaments_by_id = {}

	var card_data := _load_json(CARDS_PATH)
	var archetype_data := _load_json(ARCHETYPES_PATH)
	var booster_data := _load_json(BOOSTERS_PATH)
	var tournament_data := _load_json(TOURNAMENTS_PATH)

	cards = card_data.get("cards", [])
	for card in cards:
		cards_by_id[card.get("id", "")] = card

	for archetype in archetype_data.get("archetypes", []):
		archetypes_by_id[archetype.get("id", "")] = archetype

	for booster in booster_data.get("boosters", []):
		boosters_by_id[booster.get("id", "")] = booster

	for tournament in tournament_data.get("tournaments", []):
		tournaments_by_id[tournament.get("id", "")] = tournament

	return not (card_data.is_empty() or archetype_data.is_empty() or booster_data.is_empty() or tournament_data.is_empty())


func deck_entries_to_dict(entries: Array) -> Dictionary:
	var deck := {}
	for entry in entries:
		deck[entry.get("cardId", "")] = int(entry.get("count", 0))
	return deck


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
