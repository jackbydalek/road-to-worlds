extends SceneTree

const COMBAT_SERVICE_SCRIPT := preload("res://scripts/CombatService.gd")
const ARCHETYPE_ORDER := ["flightless_birds", "snake", "oxen", "glires", "insect"]
const GAMES_PER_SEAT := 100
const OUTPUT_DIR := "res://outputs/balance"
const MARKDOWN_PATH := "res://outputs/balance/starter_balance_matrix.md"
const JSON_PATH := "res://outputs/balance/starter_balance_matrix.json"

var cards_by_id := {}
var archetypes_by_id := {}
var combat_service: RefCounted


func _init() -> void:
	var card_data := _load_json("res://data/content/cards.json")
	for card in card_data.get("cards", []):
		cards_by_id[card.get("id", "")] = card

	var archetype_data := _load_json("res://data/content/archetypes.json")
	for archetype in archetype_data.get("archetypes", []):
		archetypes_by_id[archetype.get("id", "")] = archetype

	combat_service = COMBAT_SERVICE_SCRIPT.new()
	combat_service.setup(cards_by_id, archetypes_by_id)

	for archetype_id in ARCHETYPE_ORDER:
		if not archetypes_by_id.has(archetype_id):
			push_error("Missing archetype for balance matrix: " + archetype_id)
			quit(1)
			return
		var deck := _starter_deck(archetype_id)
		if _deck_total(deck) != 30:
			push_error("%s starter has %d cards, expected 30." % [_archetype_name(archetype_id), _deck_total(deck)])
			quit(1)
			return

	var report := _run_matrix()
	_write_report(report)
	_print_summary(report)
	quit(0)


func _run_matrix() -> Dictionary:
	var pairings := []
	var matrix := {}
	for row_id in ARCHETYPE_ORDER:
		matrix[row_id] = {}
		for col_id in ARCHETYPE_ORDER:
			matrix[row_id][col_id] = null

	for left_index in range(ARCHETYPE_ORDER.size()):
		for right_index in range(left_index + 1, ARCHETYPE_ORDER.size()):
			var left_id := String(ARCHETYPE_ORDER[left_index])
			var right_id := String(ARCHETYPE_ORDER[right_index])
			var pairing := _run_pairing(left_id, right_id, left_index, right_index)
			pairings.append(pairing)
			matrix[left_id][right_id] = _win_rate(pairing, left_id)
			matrix[right_id][left_id] = _win_rate(pairing, right_id)

	return {
		"generatedAt": Time.get_datetime_string_from_system(false, true),
		"gamesPerSeat": GAMES_PER_SEAT,
		"gamesPerPairing": GAMES_PER_SEAT * 2,
		"archetypes": ARCHETYPE_ORDER.map(func(archetype_id): return {
			"id": archetype_id,
			"name": _archetype_name(String(archetype_id))
		}),
		"matrix": matrix,
		"pairings": pairings
	}


func _run_pairing(left_id: String, right_id: String, left_index: int, right_index: int) -> Dictionary:
	var stats := {
		"left": left_id,
		"right": right_id,
		"games": 0,
		"draws": 0,
		"wins": {
			left_id: 0,
			right_id: 0
		},
		"seatBreakdown": []
	}

	_run_direction(stats, left_id, right_id, _seed_base(left_index, right_index, 0))
	_run_direction(stats, right_id, left_id, _seed_base(left_index, right_index, 1))
	return stats


func _run_direction(stats: Dictionary, player_id: String, opponent_id: String, seed_base: int) -> void:
	var player_deck := _starter_deck(player_id)
	var opponent_deck := _starter_deck(opponent_id)
	var player_wins := 0
	var opponent_wins := 0
	var draws := 0

	for game_index in range(GAMES_PER_SEAT):
		var seed_value := seed_base + game_index
		var state: Dictionary = combat_service.auto_play_game(player_deck, player_id, opponent_deck, opponent_id, seed_value)
		match String(state.get("winner", "")):
			"player":
				player_wins += 1
				stats.wins[player_id] = int(stats.wins[player_id]) + 1
			"opponent":
				opponent_wins += 1
				stats.wins[opponent_id] = int(stats.wins[opponent_id]) + 1
			_:
				draws += 1
				stats.draws = int(stats.draws) + 1
		stats.games = int(stats.games) + 1

	stats.seatBreakdown.append({
		"player": player_id,
		"opponent": opponent_id,
		"playerWins": player_wins,
		"opponentWins": opponent_wins,
		"draws": draws,
		"games": GAMES_PER_SEAT
	})


func _seed_base(left_index: int, right_index: int, direction: int) -> int:
	return 100000 + left_index * 10000 + right_index * 1000 + direction * 100


func _win_rate(pairing: Dictionary, archetype_id: String) -> float:
	var games := int(pairing.get("games", 0))
	if games <= 0:
		return 0.0
	var wins: Dictionary = pairing.get("wins", {})
	var draws := int(pairing.get("draws", 0))
	return (float(wins.get(archetype_id, 0)) + float(draws) * 0.5) / float(games)


func _write_report(report: Dictionary) -> void:
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)

	var json_file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if json_file == null:
		push_error("Could not write " + JSON_PATH)
		quit(1)
		return
	json_file.store_string(JSON.stringify(report, "\t"))

	var markdown_file := FileAccess.open(MARKDOWN_PATH, FileAccess.WRITE)
	if markdown_file == null:
		push_error("Could not write " + MARKDOWN_PATH)
		quit(1)
		return
	markdown_file.store_string(_markdown_report(report))


func _markdown_report(report: Dictionary) -> String:
	var lines := [
		"# Starter Balance Matrix",
		"",
		"Generated: %s" % String(report.generatedAt),
		"Games per seat order: %d" % int(report.gamesPerSeat),
		"Games per pairing: %d" % int(report.gamesPerPairing),
		"",
		"Cells show row deck win rate against column deck, combining both play/draw seat orders. Draws count as half a win.",
		"",
	]

	var header := ["Deck"]
	for archetype_id in ARCHETYPE_ORDER:
		header.append(_archetype_name(String(archetype_id)))
	lines.append("| " + " | ".join(header) + " |")
	lines.append("|" + "---|".repeat(header.size()))

	var matrix: Dictionary = report.matrix
	for row_id in ARCHETYPE_ORDER:
		var row := [_archetype_name(String(row_id))]
		for col_id in ARCHETYPE_ORDER:
			if row_id == col_id:
				row.append("-")
			else:
				row.append(_format_percent(float(matrix[row_id][col_id])))
		lines.append("| " + " | ".join(row) + " |")

	lines.append("")
	lines.append("## Pair Details")
	lines.append("")
	lines.append("| Pairing | Left wins | Right wins | Draws | Seat-order notes |")
	lines.append("|---|---:|---:|---:|---|")
	for pairing in report.pairings:
		var left_id := String(pairing.left)
		var right_id := String(pairing.right)
		var notes := []
		for seat in pairing.seatBreakdown:
			notes.append("%s as player: %d-%d-%d" % [
				_archetype_name(String(seat.player)),
				int(seat.playerWins),
				int(seat.opponentWins),
				int(seat.draws)
			])
		lines.append("| %s vs %s | %d | %d | %d | %s |" % [
			_archetype_name(left_id),
			_archetype_name(right_id),
			int(pairing.wins[left_id]),
			int(pairing.wins[right_id]),
			int(pairing.draws),
			"; ".join(notes)
		])

	lines.append("")
	return "\n".join(lines)


func _print_summary(report: Dictionary) -> void:
	print("Starter balance matrix complete: %d games per pairing." % int(report.gamesPerPairing))
	var matrix: Dictionary = report.matrix
	for row_id in ARCHETYPE_ORDER:
		var pieces := []
		for col_id in ARCHETYPE_ORDER:
			if row_id == col_id:
				continue
			pieces.append("%s %s" % [_archetype_name(String(col_id)), _format_percent(float(matrix[row_id][col_id]))])
		print("%s: %s" % [_archetype_name(String(row_id)), ", ".join(pieces)])
	print("Wrote %s" % ProjectSettings.globalize_path(MARKDOWN_PATH))


func _format_percent(value: float) -> String:
	return "%.1f%%" % (value * 100.0)


func _starter_deck(archetype_id: String) -> Dictionary:
	return _deck_entries_to_dict(archetypes_by_id[archetype_id].get("starterDeck", []))


func _deck_entries_to_dict(entries: Array) -> Dictionary:
	var result := {}
	for entry in entries:
		result[entry.get("cardId", "")] = int(entry.get("count", 0))
	return result


func _deck_total(deck: Dictionary) -> int:
	var total := 0
	for card_id in deck.keys():
		total += int(deck[card_id])
	return total


func _archetype_name(archetype_id: String) -> String:
	if archetypes_by_id.has(archetype_id):
		return String(archetypes_by_id[archetype_id].get("name", archetype_id))
	return archetype_id


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not load " + path)
		quit(1)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON at " + path)
		quit(1)
		return {}
	return parsed
