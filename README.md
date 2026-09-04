# TOP CUT: Locals to Worlds

TOP CUT: Locals to Worlds is a cozy roguelike deckbuilder about starting at tiny neighborhood card-game locals and choosing a path toward a championship in the stars. The current public run promotes the illustrated Starter City overworld into a branching map while retaining the tactical Kitchen Match card game.

Current demo version: `0.1.0-demo.1`. The production catalog is locked to the 87 cards in `data/cards.json`; the rules service also creates one non-collectible Fresh Ingredient token at runtime.

## Play

Open the project in Godot 4.6:

```sh
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --editor --path .
```

Development-only menus are hidden during normal play. Launch with `--dev` (after
Godot's `--` separator) when you need the Debug Sandbox:

```sh
"$GODOT_BIN" --path . -- --dev
```

The centered opening screen keeps the run actions directly beneath the logo:

- **Continue** — shown when an unfinished save exists; resume the exact saved route, pending encounter, reward, shop, event, or interrupted Kitchen Match.
- **New Game** — choose a Spicy, Hearty, or Sweet 15-card starter and enter Starter City.
- **How to Play** — follow a seven-step visual walkthrough of recipes, zones, combat, and the turn sequence.

The title screen also keeps a direct **Debug Menu** entry for development access to the three starters and isolated test surfaces.

Runs autosave after progression changes and navigation, as well as before returning to the title or closing the game. Saves are versioned and retain a known-good backup for recovery.

## Starter City Run

1. Choose a Spicy, Hearty, or Sweet 15-card starter with 40 persistent life.
2. Choose a connected Enemy, Shop, or Event stop on the seeded Starter City route.
3. Win Kitchen Matches against 12-life regular rivals, the 18-life local champion, and the 28-life city champion.
4. Grow the deck through reveal-and-take rewards: regular, miniboss, and boss packs contain 3, 5, and 8 cards, and you may take any or all of them.
5. Use shops and events for cards, removal, healing, currency, and route tradeoffs.
6. Carry life, deck, currency, visited nodes, and route seed forward. Losing all life ends the run.
7. Defeat the city champion to reveal the Cloud City teaser.

See [Season Loop](docs/season-loop.md) and [Kitchen Match Rules](docs/game-rules.md) for the full rules.

## Project Layout

- `scenes/Main.tscn` and `scripts/Main.gd` — route-run shell and debug menu
- `scenes/OverworldStageTest.tscn` and `scripts/overworld/OverworldRouteGraph.gd` — production Starter City route map (the filename remains from its prototype origin)
- `scripts/RouteRunService.gd` — route-run setup, encounter balance, starter compaction, and reward generation
- `scenes/Tabletop3DPrototype.tscn` and `scripts/Tabletop3DPrototype.gd` — the sole campaign and debug-match presentation on the production 3D Living Table
- `scripts/cooking/CookingCombatService.gd` — match rules and AI
- `scripts/CardEffectLab.gd` — Debug Sandbox scenarios for the canonical catalog's highest-risk effects
- `scripts/ContentCatalog.gd` — kitchen-card-to-season metadata adapter
- `scripts/RunStateService.gd` — versioned run saves and deck legality; legacy season services remain available to Debug tools
- `scripts/ShopEconomyService.gd` — packs, singles, prices, and collection rewards
- `scripts/CardShopScreen.gd`, `PackOpeningScreen.gd`, `DeckbuilderScreen.gd`, and `SeasonHubScreen.gd` — campaign screens
- `data/cards.json` — the canonical 87-card demo catalog and three 20-card starter decks
- `data/content/boosters.json` and `tournaments.json` — campaign content

The old fish combat, fish card catalog, mana/threat renderer, and animal artwork are not part of the runtime.

## Validate

Run the release gate (canonical catalog, gameplay/input, responsive UI, shell integration, and a clean Web export):

```sh
scripts/release/check_demo.sh
```

Build the versioned, itch-ready Web ZIP (this runs the release gate first):

```sh
scripts/release/build_itch_release.sh
```

The artifact is written to `builds/top-cut-locals-to-worlds-<version>-itch-web.zip`, with `index.html` at the ZIP root. Complete the [Chrome, Safari, and Firefox QA matrix](docs/browser-qa.md) against that exact artifact before publishing.

Pull requests and pushes to `main` or `codex/**` run the same gate in GitHub Actions and retain the versioned itch ZIP for 14 days.

Individual checks can also be run directly:

```sh
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/KitchenGameSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/RebalancedCardPoolSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/DraftModeSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/DualCardFrameSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/PackRewardSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/SeasonShellSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/AutosaveSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/CardFaceSmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/StarterBalanceSimulation.gd -- --games=500
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/StarterBalanceSimulation.gd -- --games=100 --ai=expert
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/AiPolicySmokeTest.gd
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/FaceRaceBaselineSimulation.gd -- --games=250 --ai=hard
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/RouteCampaignSimulation.gd -- --runs=25 --player-ai=hard --policy=survival
# Optional CI gate: exits 3 when any starter or the overall result is outside the range.
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/RouteCampaignSimulation.gd -- --runs=100 --min-win-rate=20 --max-win-rate=70
"$GODOT_BIN" --headless --path . --quit-after 3
```

Additional references:

- [Technical Architecture](docs/technical-architecture.md)
- [Card Data](docs/card-data.md)
- [Development Status](docs/development-status.md)
