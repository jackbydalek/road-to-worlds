extends RefCounted

# Simulation-only starter variants. Production cards, rewards, and rival lists
# retain their stats. Each proposal has five names and an affinity on its basics.
const PARTS := {
	"spicy": ["spicy_hot_honey_bee", "spicy_wasabi_wasp", "spicy_sriracharrow", "stalwart", 2, 1, 5, 4],
	"sweet": ["sweet_caramel_camel", "sweet_soft_serve_crab", "sweet_mothchi", "bodyguard", 1, 2, 4, 5],
	"hearty": ["hearty_bagver", "hearty_french_bread_dog", "hearty_lasagnama", "taunt", 1, 2, 5, 5],
}

static func build(starter: String, database: Dictionary, size: int = 15) -> Dictionary:
	assert(size in [12, 15])
	var spec: Array = PARTS[starter]
	var result := {"deck": {}, "cards": {}}
	var basic_id := "proposal_%s_basic" % starter
	result.cards[basic_id] = {
		"id": basic_id, "name": "Basic %s Ingredient" % starter.capitalize(),
		"card_type": "ingredient", "archetype": starter, "ingredient_types": [starter],
		"attack": 2, "health": 2, "text": "", "rare": false,
	}
	result.deck[basic_id] = 6 if size == 15 else 3
	for role_index in range(3):
		var source_id := String(spec[role_index])
		var definition: Dictionary = database[source_id].duplicate(true)
		var id := "proposal_%s" % source_id
		definition.id = id
		definition.base_card_id = source_id
		if role_index == 0:
			definition.attack = 1
			definition.health = 1
		elif role_index == 1:
			definition.attack = int(spec[4])
			definition.health = int(spec[5])
		else:
			definition.attack = int(spec[6])
			definition.health = int(spec[7])
			definition.recipe = [starter]
		result.cards[id] = definition
		result.deck[id] = 3 if role_index == 0 else 2
	result.deck.chef_mary = 2
	return result
