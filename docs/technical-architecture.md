# Technical Architecture

The project has two layers: a persistent season shell and the Kitchen Table match engine.

## Season Shell

`scenes/Main.tscn` loads `scripts/Main.gd`. The controller owns navigation, shared presentation helpers, the active run, and the bridge into a Kitchen Match. Focused services and screens keep the campaign features separate:

- `ContentCatalog.gd` loads `data/cards.json`, derives season-facing rarity, value, roles, stats, archetypes, and starter decks, then loads booster and tournament definitions.
- `RunStateService.gd` owns collection, deck legality, save/load, money, season lives, and normalized metagame state.
- `ShopEconomyService.gd` generates boosters and singles, handles purchases and reveals, and awards cards to the collection.
- `SeasonFlowService.gd` owns calendar unlock and completion rules.
- `TournamentService.gd` creates opponents, upgrades later lists, calculates quick debug results, and evaluates event records.
- The shop, pack opening, deckbuilder, and season hub are independent screen scripts that render against the host controller.

The season deck size is 30 cards. Each archetype has a deliberate constructed starter list, and the sideboard remains available for campaign experimentation.

## Kitchen Match

`scenes/KitchenGame.tscn` loads `KitchenGame.gd`, which owns board presentation, drag-and-drop, selection panels, and card inspection. `CookingCombatService.gd` owns match state, legal actions, effects, combat, and AI.

For a tournament round, the shell:

1. Builds the player deck from the active run.
2. Builds an opponent deck from the selected archetype and event difficulty.
3. Configures a Kitchen Game instance before adding it to the scene tree.
4. Passes the seed and opening side.
5. Receives a `match_finished` result containing winner, turn, and remaining life.
6. Records that result into the active tournament and advances or finishes the event.

The same bridge launches practice matches from the Debug Sandbox.

## Content Boundary

`data/cards.json` remains authoritative for printed Kitchen Table rules. The season catalog decorates copies of those definitions at load time with campaign-only properties such as rarity, shop value, deck limit, role, and abstract deck-quality stats. Those extra properties are not duplicated into the match catalog.

## Validation

- `KitchenGameSmokeTest.gd` covers match rules, effects, selection workflows, inspection, and drag-and-drop.
- `SeasonShellSmokeTest.gd` covers content adaptation, debug navigation, shop generation, booster collection updates, deckbuilder, metagame, calendar, live Kitchen Match launch, tournament records, and event unlocking.

The retired fish combat service, old manual-combat UI, and mana/threat card renderer are intentionally absent.
