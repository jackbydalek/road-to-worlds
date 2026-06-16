# Road to Worlds Technical Architecture

This architecture is engine-agnostic and suitable for Unity or Godot. The project should be data-driven: cards, packs, archetypes, opponents, tournaments, and shop offers should live in content files rather than hardcoded logic.

## Architecture Goals

- Fast iteration on cards and balance.
- Deterministic seeded runs for replayability and debugging.
- Clear separation between static content and mutable run state.
- Small enough for a solo developer.
- Portable between Unity and Godot.

## Recommended Stack

### Unity

- Static content: ScriptableObjects or JSON imported into ScriptableObjects.
- Runtime state: plain C# classes.
- UI: Unity UI Toolkit or UGUI.
- Save: JSON with versioned schema.

### Godot

- Static content: Resources or JSON.
- Runtime state: GDScript/C# classes.
- UI: Control nodes.
- Save: JSON with versioned schema.

For a solo developer, start with JSON even in Unity. It makes balancing easier, supports quick external editing, and avoids early editor tooling work.

## Core Data Types

### CardDefinition

Static data for a card.

```json
{
  "id": "redline_spark_runner",
  "displayName": "Spark Runner",
  "setId": "base_01",
  "rarity": "common",
  "archetypeTags": ["redline_aggro"],
  "mechanicTags": ["threat", "burn"],
  "role": "threat",
  "cost": 1,
  "deckLimit": 3,
  "marketValue": 2,
  "stats": {
    "power": 2,
    "speed": 4,
    "consistency": 1,
    "interaction": 0,
    "resilience": 0,
    "cardAdvantage": 0
  },
  "matchupModifiers": [
    {
      "targetTag": "slow_setup",
      "value": 1
    }
  ],
  "rulesText": "Fast early threat.",
  "flavorText": "First to the table, first to the feature match."
}
```

### CollectionEntry

Mutable run data for owned cards.

```json
{
  "cardId": "redline_spark_runner",
  "owned": 2,
  "foilOwned": 0,
  "locked": false,
  "seenThisRun": true
}
```

### DeckList

```json
{
  "name": "Redline Locals",
  "main": [
    { "cardId": "redline_spark_runner", "count": 3 },
    { "cardId": "redline_last_point", "count": 2 }
  ],
  "sideboard": [
    { "cardId": "redline_shatter_charm", "count": 2 }
  ]
}
```

### ArchetypeDefinition

```json
{
  "id": "redline_aggro",
  "displayName": "Redline Aggro",
  "plan": "Pressure early and finish with reach.",
  "tags": ["aggro", "linear", "cheap"],
  "phaseWeights": {
    "early": 0.5,
    "mid": 0.35,
    "late": 0.15
  },
  "desiredRoles": {
    "threat": 16,
    "answer": 4,
    "engine": 2,
    "finisher": 4,
    "tech": 4
  },
  "matchups": {
    "lantern_control": -0.1,
    "gearworks_combo": 0.15,
    "verdant_midrange": -0.05
  },
  "starterCardPool": [
    "redline_spark_runner",
    "redline_last_point"
  ]
}
```

### BoosterDefinition

```json
{
  "id": "base_standard_pack",
  "displayName": "Base Set Booster",
  "setId": "base_01",
  "price": 5,
  "slots": [
    { "rarity": "common", "count": 4 },
    { "rarity": "uncommon", "count": 2 },
    { "rarity": "rare", "count": 1, "upgradeChance": 0.125, "upgradeRarity": "mythic" },
    { "slotType": "wildcard", "count": 1 }
  ],
  "tagWeights": {}
}
```

### MetaState

```json
{
  "week": 3,
  "archetypes": [
    {
      "archetypeId": "redline_aggro",
      "popularity": 0.28,
      "averageDeckQuality": 0.54,
      "recentWinRate": 0.51,
      "hype": 0.12,
      "techAgainst": {
        "lantern_control": 0.2
      }
    }
  ],
  "knownReports": [
    "Redline Aggro is still popular at locals.",
    "Lantern Control players are adding cheap sweepers."
  ]
}
```

### TournamentTier

```json
{
  "id": "monthly_regionals",
  "displayName": "Monthly Regionals",
  "rounds": 5,
  "requiredWins": 4,
  "entryFee": 10,
  "prizeTable": [
    { "minWins": 5, "money": 35, "packs": ["base_standard_pack", "base_standard_pack"] },
    { "minWins": 4, "money": 20, "packs": ["base_standard_pack"] }
  ],
  "bossOpponentId": "regional_grinder"
}
```

### RunState

```json
{
  "seed": 1849205,
  "seasonStep": 2,
  "money": 24,
  "reputation": 8,
  "selectedStarterArchetype": "redline_aggro",
  "collection": [],
  "activeDeck": {},
  "metaState": {},
  "rivalsDefeated": [],
  "losses": [],
  "unlockedShopTiers": ["local_shop"]
}
```

## Runtime Services

### ContentDatabase

Loads and validates static content.

Responsibilities:

- Load cards, archetypes, packs, tournaments, opponents, shop events.
- Validate card IDs, rarity tables, deck limits, and matchup references.
- Provide lookup APIs.

### RunManager

Owns the run lifecycle.

Responsibilities:

- Start run from seed.
- Advance season.
- Check loss conditions.
- Store current run state.
- Trigger save/load.

### CollectionService

Responsibilities:

- Add/remove card copies.
- Check ownership for deck legality.
- Calculate duplicate sell value.
- Track newly acquired and deck-relevant cards.

### DeckBuilderService

Responsibilities:

- Validate deck size, copy limits, ownership, and sideboard.
- Calculate deck metrics.
- Infer primary archetype from card tags.
- Suggest cuts and additions.

### BoosterService

Responsibilities:

- Generate pack contents from slots, rarity, set, and weighting.
- Apply rare upgrades, wildcard slots, foils, and pity tuning if used.
- Mark new cards and deck-relevant pulls.
- Return a reveal sequence for UI.

### ShopService

Responsibilities:

- Generate singles inventory.
- Generate trade offers.
- Price cards based on rarity, meta demand, and run economy.
- Refresh inventory by season tier.

### MetaSimulationService

Responsibilities:

- Simulate field results.
- Update archetype popularity.
- Add tech adoption against dominant decks.
- Generate player-facing reports.
- Produce opponent pairings.

### TournamentService

Responsibilities:

- Generate event field.
- Pair opponents by round and record.
- Insert boss or rival matches.
- Resolve standings and rewards.
- End run on failed record.

### MatchSimulator

Responsibilities:

- Resolve games and matches.
- Use deck metrics, archetype matchup matrix, tech cards, pilot skill, and variance.
- Produce readable match logs.
- Support deterministic results from run seed.

### SaveService

Responsibilities:

- Save current run with schema version.
- Load and migrate older saves.
- Keep content IDs stable.

## Suggested Scene/UI Structure

### Main Screens

- Run start
- Card shop
- Collection binder
- Deckbuilder
- Pack opening
- Metagame report
- Tournament bracket/rounds
- Match result
- Run summary

### Card Shop Layout

Panels:

- Current money and next event
- Packs
- Singles case
- Trade table
- Metagame board
- Current deck warnings

The shop should be the hub. Avoid making it feel like a menu list; make it feel like the place where runs pivot.

### Deckbuilder Layout

Panels:

- Collection/search
- Main deck
- Sideboard
- Curve and role chart
- Archetype density
- Matchup projection
- Legality warnings

## Match Simulation Formula

Start simple and tune with playtests.

```text
deckScore =
  archetypeFit
  + consistencyScore
  + phaseScore
  + roleBalanceScore
  + techScore
  + cardQualityScore
  + pilotSkill
  + variance

matchupScore =
  deckScore
  + archetypeMatchupModifier
  + sideboardModifier
  - opponentDeckScore
```

Convert score difference to win probability:

```text
winProbability = clamp(0.05, 0.95, 0.5 + scoreDifference * 0.08)
```

Best-of-three:

1. Game 1 uses main deck only.
2. Games 2 and 3 apply sideboard/known-opponent modifiers.
3. Bosses receive stronger sideboard modifiers.

## Metagame Update Formula

For each archetype:

```text
performanceDelta = recentWinRate - 0.5
accessibilityBoost = accessibility * earlySeasonWeight
counterPressure = sum(popularityOfPredators)
hypeDelta = performanceDelta + playerInfluence + randomNoise

newPopularity =
  oldPopularity
  + performanceDelta * 0.18
  + accessibilityBoost * 0.05
  + hypeDelta * 0.08
  - counterPressure * 0.10
```

Normalize all popularity values after update.

## Solo Developer MVP Milestones

Estimates assume one experienced solo developer with existing engine familiarity. Full-time estimates are in person-weeks; part-time calendar time may be two to three times longer.

| Milestone | Scope | Estimate |
| --- | --- | ---: |
| 0. Preproduction | Lock design, data schema, visual wireframes, content spreadsheet | 1-2 weeks |
| 1. Data Backbone | Content loading, cards, collection, decks, validation | 2-3 weeks |
| 2. Deckbuilder Prototype | Functional deck editing, metrics, warnings, save/load | 2-3 weeks |
| 3. Booster And Shop | Pack generation, reveal UI, singles, buy/sell/trade | 2-4 weeks |
| 4. Match Simulator | Abstract best-of-three, logs, opponent decks, tuning hooks | 2-3 weeks |
| 5. Tournament Season | Event ladder, required records, prizes, run end, bosses | 2-3 weeks |
| 6. Dynamic Meta | Meta state, updates, reports, opponent field generation | 2-4 weeks |
| 7. MVP Content | 80-120 cards, 4 archetypes, 5 bosses, first balance pass | 3-5 weeks |
| 8. UX And Polish | Pack juice, deckbuilder readability, run summary, audio pass | 3-5 weeks |
| 9. Playtest And Balance | Internal/external tests, economy tuning, bug fixing | 4-8 weeks |

Reasonable MVP total: 21-40 full-time weeks.

## Development Order

Build in this order:

1. Card database and collection.
2. Deck validation and deck metrics.
3. Match simulator using hand-authored opponent decks.
4. Tournament ladder with fail state.
5. Booster packs and rewards.
6. Shop economy.
7. Dynamic metagame.
8. Pack-opening polish.
9. More content and balance.

This order proves the core game before investing heavily in presentation.

## Risk Register

### Risk: Full TCG rules engine grows too large

Mitigation: Use the abstract duel model for MVP. Add richer match visuals only after deckbuilding is fun.

### Risk: Pack opening becomes optimal or useless

Mitigation: Make packs emotionally exciting but economically varied. Singles should be reliable; packs should be high-upside and sometimes strategically justified.

### Risk: Dynamic meta feels random

Mitigation: Show reports, recent results, and visible causes. Players should understand why the field changed even if they cannot predict it perfectly.

### Risk: Card content overwhelms development

Mitigation: Start with 4 archetypes and shared role templates. Add variants by recombining tags and modifiers.

### Risk: Deckbuilder is intimidating

Mitigation: Provide metrics, warnings, filters, starter upgrade suggestions, and "compare to current deck" views.

## First Playable Target

The first playable should contain:

- 40 cards
- 2 archetypes
- Collection and deck editing
- One booster pack type
- One shop screen
- One 3-round local tournament
- Abstract match results
- Run win/loss summary

Success criteria:

- The player can open packs and immediately care about at least one card.
- The player can improve a starter deck in more than one reasonable way.
- The player can lose because of deckbuilding choices, not only bad luck.
- The player wants to try another run with a different starter.

