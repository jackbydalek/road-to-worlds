# Card Data

All cards and development decks live in `data/cards.json`. Card IDs are stable lowercase identifiers used by decks and runtime instances.

The season shell reads this same catalog and derives campaign-only rarity, value, deck-limit, role, and deck-quality fields at runtime. Printed match rules remain single-source.

## Top-Level Shape

```json
{
  "schema_version": 2,
  "cards": [],
  "decks": {
    "deck_id": {
      "name": "Deck Name",
      "cards": {
        "card_id": 1
      }
    }
  }
}
```

Supported `card_type` values are `ingredient`, `meal`, `tool`, `spice`, `environment`, and `chef`.

## Units

Ingredients define combat stats and one or more ingredient types:

```json
{
  "id": "example_ingredient",
  "name": "Example Ingredient",
  "card_type": "ingredient",
  "archetype": "spicy",
  "ingredient_types": ["spicy"],
  "attack": 2,
  "health": 2,
  "text": "When sacrificed, draw 1.",
  "on_sacrifice": [
    {"type": "draw", "amount": 1}
  ]
}
```

Meals replace `ingredient_types` with a recipe:

```json
{
  "id": "example_meal",
  "name": "Example Meal",
  "card_type": "meal",
  "archetype": "spicy",
  "recipe": ["spicy", "spicy"],
  "attack": 6,
  "health": 5,
  "text": "When served, deal 1 damage to all opposing units.",
  "on_play": [
    {"type": "damage_all_enemy_units", "amount": 1}
  ]
}
```

A Meal may also define `required_meal_archetype`. Serving it sacrifices one matching Meal in addition to the listed Ingredients. `can_attack_from_prep` permits the unit to attack from Prep.

Optional responses use `hand_trap` with an opposing-action trigger or `hand_trigger` with a friendly-event trigger. The combat service opens a response window and enforces the once-per-turn Hand Trap limit.

## Other Card Types

Tools and Chefs resolve their `effects` and then go to the discard pile. Spices attach to friendly units and commonly define `attack_bonus` and `health_bonus`. Environments remain in their zone and define persistent or turn-based behavior.

```json
[
  {
    "id": "example_tool",
    "name": "Example Tool",
    "card_type": "tool",
    "text": "Draw 1.",
    "effects": [{"type": "draw", "amount": 1}]
  },
  {
    "id": "example_spice",
    "name": "Example Spice",
    "card_type": "spice",
    "text": "Attached unit gets +1/+1.",
    "attack_bonus": 1,
    "health_bonus": 1
  },
  {
    "id": "example_environment",
    "name": "Example Environment",
    "card_type": "environment",
    "text": "Your archetype engine remains active here."
  }
]
```

Use explicit rules text in `text`, but treat the structured fields as authoritative. A new structured effect also needs a matching resolver path and regression test.
