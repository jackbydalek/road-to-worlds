# Technical Architecture

The project has two layers: a persistent season shell and the Kitchen Table match engine.

## Season Shell

`scenes/Main.tscn` loads `scripts/Main.gd`. The controller owns navigation, shared presentation helpers, the active run, and the bridge into a Kitchen Match. Focused services and screens keep the campaign features separate:

- `ContentCatalog.gd` loads `data/cards.json`, derives season-facing rarity, value, roles, stats, archetypes, and starter decks, then loads booster and tournament definitions.
- `RunStateService.gd` owns collection, deck legality, versioned save envelopes, backup recovery, money, season lives, and normalized metagame state.
- `ShopEconomyService.gd` generates boosters and singles, handles purchases and reveals, and awards cards to the collection.
- `SeasonFlowService.gd` owns calendar unlock and completion rules.
- `TournamentService.gd` creates opponents, upgrades later lists, calculates quick debug results, and evaluates event records.
- The shop, pack opening, deckbuilder, and season hub are independent screen scripts that render against the host controller.

The season deck size is 30 cards. The public demo exposes Spicy, Hearty, and Sweet starters; Fresh and Funky remain available in the Debug Menu. Sideboard data and editing remain implemented for debug/campaign experimentation, but the sideboard is hidden from the public demo flow.

The public Season Run uses a two-event calendar and the 3D card-store overworld as its navigation hub. Singles purchases, the trade binder, and Meta Analysis all render directly inside that overworld, so wallet, collection, field-share, and report changes update without replacing the store instance. A persistent top-right utility strip exposes wallet, calendar, deck editing, and settings/save; world hotspots continue to handle the shopkeeper, trading, metagame, and tournament interactions. Each routed menu returns through an explicit Exit to Card Store action.

Season Deck Edit is a fixed-height workspace rather than a scrolling page. Collection and Main Deck own independent vertical scrollers around a persistent card preview, so the complete demo editor and its Exit to Card Store action remain visible at once.

`Main.gd` checkpoints changed run data and screen navigation through autosave. Shop, pack, deck, calendar, tournament, metagame, and result screens resume directly. Live combat remains a checkpoint boundary: loading rebuilds the same tournament round, opponent, seed, opening side, and AI tier rather than serializing an animation or partially resolved action.

## Kitchen Match

`scenes/KitchenGame.tscn` loads `KitchenGame.gd`, which owns board presentation, drag-and-drop, selection panels, and card inspection. `CookingCombatService.gd` owns match state, legal actions, effects, combat, and AI.

For a tournament round, the shell:

1. Builds the player deck from the active run.
2. Builds an opponent deck from the selected archetype and event difficulty.
3. Configures the authored 3D Kitchen Game instance before adding it to the scene tree.
4. Passes the seed, opening side, and event-scaled Easy/Medium/Hard AI tier.
5. Receives a `match_finished` result containing winner, turn, and remaining life.
6. Records that result into the active tournament and advances or finishes the event.

The same bridge launches practice matches from the Debug Sandbox.

## Content Boundary

`data/cards.json` remains authoritative for printed Kitchen Table rules. The season catalog decorates copies of those definitions at load time with campaign-only properties such as rarity, shop value, deck limit, role, and abstract deck-quality stats. Those extra properties are not duplicated into the match catalog.

## Validation

- `KitchenGameSmokeTest.gd` covers match rules, effects, selection workflows, inspection, and drag-and-drop.
- `SeasonShellSmokeTest.gd` covers content adaptation, debug navigation, shop generation, booster collection updates, deckbuilder, metagame, calendar, live Kitchen Match launch, tournament records, and event unlocking.
- `AutosaveSmokeTest.gd` covers versioned checkpoints, the animated indicator, backup recovery, resume-screen metadata, and interrupted-match reconstruction.
- `StarterBalanceSimulation.gd` runs every ordered pairing of the five starters through the production AI, including response windows and expansion mechanics, and reports seat-neutral matchups plus balance flags. Pass `--ai=easy`, `--ai=medium`, or `--ai=hard` to validate a particular policy. Automated defenders use the first eligible response whenever a Hand Trap or damage-response window opens; results are a consistent tuning baseline, not a substitute for skilled human play.

The retired fish combat service, old manual-combat UI, and mana/threat card renderer are intentionally absent.
