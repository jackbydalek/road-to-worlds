# Technical Architecture

The project has two layers: a persistent route-run shell and the card-match engine. The legacy season services remain available to development tools while the public flow uses the route loop.

## Route-Run Shell

`scenes/Main.tscn` loads `scripts/Main.gd`. The controller owns navigation, shared presentation helpers, the active run, and the bridge into a Kitchen Match. Focused services and screens keep the campaign features separate:

- `ContentCatalog.gd` loads `data/cards.json`, derives season-facing rarity, value, roles, stats, archetypes, and starter decks, then loads booster and tournament definitions.
- `RunStateService.gd` owns collection, deck legality, versioned save envelopes, backup recovery, money, season lives, and normalized metagame state.
- `RouteRunService.gd` owns route-run defaults, 15-card starter compaction, encounter life/AI targets, and affinity-weighted card reward offers.
- `OverworldRouteGraph.gd` generates or restores the seeded route graph, renders its routes and stops, and reports committed node arrivals to `Main.gd`.
- `ShopEconomyService.gd` generates boosters and singles, handles purchases and reveals, and awards cards to the collection.
- `SeasonFlowService.gd` owns calendar unlock and completion rules.
- `TournamentService.gd` creates opponents, upgrades later lists, calculates quick debug results, and evaluates event records.
- The shop, pack opening, deckbuilder, and season hub are independent screen scripts that render against the host controller.

Legal decks contain at least 1 card with no maximum deck size or per-card copy limit. Public route starters are still compacted to 15 cards, and rewards or shops add cards directly to the run deck. The public deck view is read-only except at explicit card-removal services. Legacy constructed collection and sideboard editing remain available in Debug mode.

The public run uses `OverworldStageTest.tscn` as the production Starter City map. `Main.gd` embeds it in the campaign shell, saves its graph snapshot, locks route choices after arrival, and requires the pending encounter to resolve before the next destination becomes available. Enemy nodes launch the Living Table, shops and events open run-specific screens, and victories open controlled card rewards.

Season Deck Edit is a fixed-height workspace rather than a scrolling page. Collection and Main Deck own independent vertical scrollers around a persistent card preview, so the complete demo editor and its Exit to Card Store action remain visible at once.

`Main.gd` checkpoints changed run data and screen navigation through autosave. Shop, pack, deck, calendar, tournament, metagame, and result screens resume directly. Live combat remains a checkpoint boundary: loading rebuilds the same tournament round, opponent, seed, opening side, and AI tier rather than serializing an animation or partially resolved action.

## Kitchen Match

`scenes/Tabletop3DPrototype.tscn` loads `Tabletop3DPrototype.gd` as the sole runtime match presentation for tournaments, resumed rounds, and Debug Sandbox practice. It owns the angled board, physical card interaction, animated artwork, selection panels, full-card deck-search and discard trays, card inspection, and the collapsible battle log. Item discard costs are paid directly from the physical hand: hand-card clicks toggle highlighted selections while Confirm and Cancel remain in the bottom status bar. Decks, discard piles, Environments, and attached Spices are rendered from live combat state as physical table objects. Chef and Item cards use the shared discard pile after resolving instead of occupying dedicated table bays. The retired classic scene is no longer referenced by the campaign controller. `CookingCombatService.gd` remains the sole owner of match state, legal actions, effects, combat, and AI.

For a tournament round, the shell:

1. Builds the player deck from the active run.
2. Builds an opponent deck from the selected archetype, then applies Medium/Hard/Expert card upgrades while preserving size and card-type ratios.
3. Configures the Living Table instance before adding it to the scene tree, including the two exact deck dictionaries.
4. Passes the seed, opening side, event name, round number, run border, and event-scaled Easy/Medium/Hard/Expert AI tier.
5. Receives a `match_finished` result containing winner, turn, and remaining life.
6. Records that result into the active tournament, then advances the round or finishes the event and awards its money and packs.

The same bridge launches practice matches from the Debug Sandbox; it has no renderer-selection flag or classic fallback.

### Combat animation events

`CookingCombatService.gd` writes presentation-neutral events to `state.animation_events` as rules mutations occur. Draws, plays, moves, defense-position changes, sacrifices, searches, healing, buffs, damage, attacks, and destruction carry stable card or instance IDs plus their source, target, amount, and destination. Related events share a positive `group_id`; this lets area damage, simultaneous combat damage, grouped card rotations, recipe sacrifices, and play-triggered effects animate together without reconstructing changes from old and new state snapshots. The Living Table drains and presents these events in order.

Physical card faces are cached once per unique card in a match. Their SubViewports use `UPDATE_ONCE`; static cards stop rendering after their first frame, while animated artwork emits a change signal at its authored frame rate to request one additional redraw. Multiple physical copies share the same material and viewport texture.

## Content Boundary

`data/cards.json` remains authoritative for printed card rules. The season catalog decorates copies of those definitions at load time with campaign-only properties such as rarity, shop value, role, and abstract deck-quality stats. A `deckLimit` value of `0` is retained as a compatibility sentinel for unlimited copies. Those extra properties are not duplicated into the match catalog.

## Validation

- `KitchenGameSmokeTest.gd` covers match rules, effects, selection workflows, inspection, and drag-and-drop.
- `RebalancedCardPoolSmokeTest.gd` validates the canonical 87-card demo catalog, three exact 20-card starters, dual recipes, discard deployment, direct-to-Prep tutoring, Pup Tart's Meal limit, and Chef Soup's reset. `DeckSizeRangeSmokeTest.gd` verifies the minimum size while allowing decks above 30 cards and more than three copies of one card.
- `SeasonShellSmokeTest.gd` covers content adaptation, debug navigation, shop generation, booster collection updates, deckbuilder, metagame, calendar, live Kitchen Match launch, tournament records, and event unlocking.
- `AutosaveSmokeTest.gd` covers versioned checkpoints, the animated indicator, backup recovery, resume-screen metadata, and interrupted-match reconstruction.
- `StarterBalanceSimulation.gd` runs every ordered pairing of the three starters through the production AI, including response windows, and reports seat-neutral matchups plus balance flags. Pass `--ai=easy`, `--ai=medium`, `--ai=hard`, or `--ai=expert` to validate a particular policy. Expert AI searches two plays ahead, evaluates passing, uses known opposing hand and upcoming-deck information, preserves low-value reactions, and chooses higher-value search and discard options. Automated player-side defenders in the simulator still use the first eligible response whenever a Hand Trap or damage-response window opens; results are a consistent tuning baseline, not a substitute for skilled human play.
- Each combatant carries its own deck-derived AI profile: Spicy uses pressure, Hearty uses defense, and Sweet uses patient value. `FaceRaceBaselineSimulation.gd` pits a deliberately simple Spicy face-race policy against the production policy with both seating orders, while `AiPolicySmokeTest.gd` covers profile swapping, direct-damage priority, blocker targeting, and defensive lethal recognition.

The retired fish combat service, old manual-combat UI, and mana/threat card renderer are intentionally absent.
