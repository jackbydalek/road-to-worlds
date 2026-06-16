# Combat Card Schema

All prototype cards now support an explicit `combat` object in `data/content/cards.json`.
The combat service still has role/stat fallback behavior for future prototype cards, but current content should use `combat`.

## Unit

```json
"combat": {
  "kind": "unit",
  "attack": 3,
  "health": 2,
  "ready": true,
  "keywords": ["fast"],
  "onPlay": [{ "type": "damage", "amount": 1, "target": "best_enemy_unit" }],
  "triggers": [
    {
      "timing": "on_damage_player",
      "effects": [{ "type": "buff", "amount_attack": 1, "amount_health": 1, "target": "source_unit" }]
    }
  ],
  "abilities": [
    {
      "id": "sample_heal",
      "label": "Gain Life",
      "cost": 1,
      "effects": [{ "type": "heal", "amount": 1, "target": "self_player" }]
    }
  ]
}
```

- `ready`: optional. If true, the unit can attack the turn it is played.
- `keywords`: currently useful values include `fast`, `guard`, and `invincible`.
- `onPlay`: optional effect list resolved after the unit enters the board.
- `triggers`: optional Wave 2 triggered effects.
- `abilities`: optional activated abilities that can be used from the board.

Unit trigger timings:

- `start_turn`: fires at the start of its controller's turn.
- `end_turn`: fires at the end of its controller's turn.
- `on_death`: fires when the unit dies.
- `on_damage_player`: fires when the unit deals combat damage to the opposing player.
- `opponent_draw`: fires when the opposing player draws after opening hands.
- `on_card_played`: fires when its controller plays a card.

Activated ability fields:

- `id`: stable ability id for once-per-turn tracking.
- `label`: short UI label.
- `cost`: focus cost.
- `effects`: effect list to resolve.
- `oncePerTurn`: optional; prevents repeated use during the same turn.
- `preventAttack`: optional; makes the source unit not ready after activation.
- `requiresReady`: optional; requires the source unit to be ready.
- `targetMode`: currently only `none` is supported for activated abilities.

## Action

```json
"combat": {
  "kind": "action",
  "targetMode": "any_enemy",
  "effects": [{ "type": "damage", "amount": 2, "target": "selected" }]
}
```

Target modes:

- `none`: no target button; uses the Play button.
- `enemy_player`: Face button only.
- `enemy_unit`: opposing unit buttons only.
- `any_enemy`: Face and opposing unit buttons.

Effect targets:

- `selected`: chosen face or unit.
- `enemy_player`: opposing player.
- `self_player`: your player.
- `all_enemy_units`: every opposing unit.
- `all_friendly_units`: every friendly unit.
- `source_unit`: the unit that owns the trigger or just entered from `onPlay`.
- `best_enemy_unit`: engine/AI chooses the highest-value opposing unit.
- `best_friendly_unit`: engine/AI chooses the highest-value friendly unit.
- `weakest_enemy_unit`: engine/AI chooses the lowest-value opposing unit.
- `weakest_friendly_unit`: engine/AI chooses the lowest-value friendly unit.

## Engine

```json
"combat": {
  "kind": "engine",
  "triggers": [
    {
      "timing": "start_turn",
      "effects": [{ "type": "draw", "amount": 1 }]
    }
  ]
}
```

Engine trigger timings use the same `triggers` shape as units. Engines can use `oncePerTurn: true` and trigger-level conditions for effects like "once each turn, when you play a 1-cost card."

Supported effect types:

- `damage`
- `draw`
- `heal`
- `summon`
- `buff`
- `debuff`
- `destroy`
- `exhaust`
- `grant_keyword`
- `discard`
- `recover`
- `gain_focus`

Effects can include `"condition": "relevant_tech"` to fire only when the card's matchup modifier matches the opponent archetype tags.

`gain_focus` adds temporary focus to the active player for the current turn. Wave 1 tool cards use this as the playable approximation for archetype-restricted focus.

`gain_focus` can include `restrictedTo` with an archetype id. Restricted focus is temporary and can only pay for cards or abilities from that archetype. When a matching card spends focus, restricted focus is spent before normal focus.

Wave 2 condition values:

- `controls_tool`: true if the active player controls an engine or unit tagged `tool` or `artifact`.
- `enemy_hand_at_least`: compare enemy hand size with `conditionAmount`.
- `enemy_discard_at_least`: compare enemy discard size with `conditionAmount`.
- `played_card_cost`: compare the triggering played card's cost with `conditionAmount`.
- `played_card_archetype`: compare the triggering played card's archetype with `conditionValue`.

Wave 2 dynamic amounts:

- `amountSource: "source_attack"` uses the source unit's current attack.
- `amountSource: "enemy_hand_size"` uses opposing hand size.
- `amountSource: "enemy_discard_size"` uses opposing discard size.
- `amountSource: "own_discard_size"` uses active player's discard size.
- `amountSource: "current_focus"` uses active player's current focus.
- `amountSource: "played_card_cost"` uses the triggering played card's cost.

Stat effects can include `"duration": "end_turn"` to expire their attack/health changes at end of turn.

## Placeholder UI

- Change placeholder card style in `scripts/Main.gd` at `_add_combat_placeholder_card`.
- Change placeholder colors in `_combat_placeholder_color`.
- Change displayed effect text in `_combat_effect_summary` and `_effect_list_summary`.
- Add new effect behavior in `scripts/CombatService.gd` at `_resolve_effects` and the `_resolve_*_effect` helpers.
