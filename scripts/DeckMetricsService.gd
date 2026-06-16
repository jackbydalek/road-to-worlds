extends RefCounted
class_name DeckMetricsService

var cards_by_id: Dictionary = {}
var archetypes_by_id: Dictionary = {}
var archetype_order: Array = []
var main_deck_size := 30


func setup(card_database: Dictionary, archetype_database: Dictionary, ordered_archetypes: Array, main_size: int) -> void:
	cards_by_id = card_database
	archetypes_by_id = archetype_database
	archetype_order = ordered_archetypes
	main_deck_size = main_size


func calculate(deck: Dictionary, _sideboard: Dictionary) -> Dictionary:
	var total := _deck_total(deck)
	if total <= 0:
		return {
			"primary": String(archetype_order[0]),
			"fit": 0.0,
			"score": 0.0,
			"speed": 0.0,
			"power": 0.0,
			"interaction": 0.0,
			"resilience": 0.0,
			"advantage": 0.0,
			"consistency": 0.0,
			"role_score": 0.0,
			"curve_warning": "No deck."
		}

	var archetype_counts := {}
	for archetype_id in archetype_order:
		archetype_counts[archetype_id] = 0
	var role_counts := {}
	var stat_totals := { "speed": 0.0, "power": 0.0, "interaction": 0.0, "resilience": 0.0, "advantage": 0.0, "consistency": 0.0 }
	var low_cost := 0
	var high_cost := 0
	var card_quality := 0.0

	for card_id in deck.keys():
		var count := int(deck[card_id])
		var card: Dictionary = cards_by_id[card_id]
		var archetype := String(card.get("archetype", "neutral"))
		if archetype_counts.has(archetype):
			archetype_counts[archetype] = int(archetype_counts[archetype]) + count

		var role := String(card.get("role", "threat"))
		role_counts[role] = int(role_counts.get(role, 0)) + count

		var stats: Dictionary = card.get("stats", {})
		for key in stat_totals.keys():
			stat_totals[key] = float(stat_totals[key]) + float(stats.get(key, 0)) * count

		if int(card.get("cost", 0)) <= 2:
			low_cost += count
		if int(card.get("cost", 0)) >= 4:
			high_cost += count

		card_quality += sqrt(float(card.get("value", 1))) * count

	var primary := String(archetype_order[0])
	var primary_count := int(archetype_counts.get(primary, 0))
	for archetype_id in archetype_order:
		var archetype_count := int(archetype_counts.get(archetype_id, 0))
		if archetype_count > primary_count:
			primary = archetype_id
			primary_count = archetype_count

	var archetype: Dictionary = archetypes_by_id[primary]
	var fit := float(archetype_counts[primary]) / float(total)
	var desired: Dictionary = archetype.get("desiredRoles", {})
	var role_error := 0.0
	for role in desired.keys():
		role_error += abs(float(role_counts.get(role, 0)) - float(desired[role]))
	var role_score: float = clamp(1.0 - (role_error / float(main_deck_size * 1.4)), 0.0, 1.0)

	var averages := {}
	for key in stat_totals.keys():
		averages[key] = float(stat_totals[key]) / float(total)

	var weights: Dictionary = archetype.get("phaseWeights", {})
	var weighted_stats := 0.0
	weighted_stats += float(averages.speed) * float(weights.get("speed", 0.2))
	weighted_stats += float(averages.power) * float(weights.get("power", 0.2))
	weighted_stats += float(averages.interaction) * float(weights.get("interaction", 0.2))
	weighted_stats += float(averages.resilience) * float(weights.get("resilience", 0.2))
	weighted_stats += float(averages.advantage) * float(weights.get("advantage", 0.2))

	var curve_warning := "Curve looks playable."
	var curve_bonus := 0.0
	if primary == "flightless_birds":
		if low_cost < 20:
			curve_warning = "Aggro deck is light on cheap cards."
			curve_bonus -= 3.0
		if high_cost > 4:
			curve_warning = "Aggro deck may be too clunky."
			curve_bonus -= 3.0
	elif primary == "snake":
		if low_cost < 14:
			curve_warning = "Control deck may not survive early turns."
			curve_bonus -= 3.0
		if high_cost > 8:
			curve_warning = "Control deck has a heavy top end."
			curve_bonus -= 1.5
	elif primary == "oxen":
		if low_cost < 14:
			curve_warning = "Oxen Ramp needs early setup before its top end."
			curve_bonus -= 2.5
		if high_cost < 6:
			curve_warning = "Oxen Ramp needs more big payoffs."
			curve_bonus -= 2.0
		if high_cost > 14:
			curve_warning = "Oxen Ramp is overloaded with expensive cards."
			curve_bonus -= 1.5
	elif primary == "glires":
		if low_cost < 18:
			curve_warning = "Glires deck wants more cheap bodies to propagate."
			curve_bonus -= 2.0
		if high_cost > 6:
			curve_warning = "Glires deck may be too top-heavy for a wide plan."
			curve_bonus -= 1.5
	elif primary == "insect":
		if low_cost < 15:
			curve_warning = "Insect deck needs early bodies to fuel revive lines."
			curve_bonus -= 2.0
		if high_cost > 8:
			curve_warning = "Insect deck has a heavy revive top end."
			curve_bonus -= 1.5
	else:
		if low_cost < 16:
			curve_warning = "Midrange deck may stumble before stabilizing."
			curve_bonus -= 2.0
		if high_cost > 7:
			curve_warning = "Midrange deck is leaning too top-heavy."
			curve_bonus -= 2.0

	var consistency_score: float = float(averages.consistency) + fit * 3.0 + role_score * 2.0
	var score: float = 28.0 + fit * 16.0 + role_score * 8.0 + weighted_stats * 5.8 + consistency_score * 1.6 + card_quality * 0.16 + curve_bonus

	return {
		"primary": primary,
		"fit": fit,
		"score": score,
		"speed": averages.speed,
		"power": averages.power,
		"interaction": averages.interaction,
		"resilience": averages.resilience,
		"advantage": averages.advantage,
		"consistency": consistency_score,
		"role_score": role_score,
		"curve_warning": curve_warning
	}


func _deck_total(deck: Dictionary) -> int:
	var total := 0
	for card_id in deck.keys():
		total += int(deck[card_id])
	return total
