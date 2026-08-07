# Kitchen Table: Road to Worlds

Kitchen Table: Road to Worlds combines a competitive-season campaign with the Kitchen Table TCG match system. Build a Spicy, Hearty, or Sweet deck, buy cards and boosters, tune the list, and play live Kitchen Matches through a calendar that runs from Weekly Locals to Worlds.

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

The opening screen separates the two run starts into tabs:

- **Continue** — resume the latest autosave on its saved campaign screen. An interrupted Kitchen Match restarts the same round and opponent.
- **New Run** — choose a difficulty card frame and the Spicy, Hearty, or Sweet starter deck.
- **How to Play** — follow a seven-step visual walkthrough of recipes, zones, combat, and the turn sequence.
- **Draft Mode** — choose one of three dual-type signpost Meals, then draft one card from each random three-card offer until you have a 20-card starting deck. The drafted-deck menu can be sorted by name, card type, or affinity.

The title screen also keeps a direct **Debug Menu** entry for development access to the three starters and isolated test surfaces.

Runs autosave after progression changes and navigation, as well as before returning to the title or closing the game. Saves are versioned and retain a known-good backup for recovery.

## Season Loop

1. Choose the Spicy, Hearty, or Sweet 20-card starter and a difficulty-linked card frame, or draft a custom 20-card deck.
2. Select a difficulty border that changes money, opponent strength, or opening-player rules.
3. Explore the mouse-driven 3D card store and click the shopkeeper, trading table, metagame board, or deck box.
4. Browse and buy exact singles inside the 3D shop scene, or open five-card boosters.
5. Register through the shopkeeper and play three rounds on the angled 3D Living Table.
6. Win all three rounds to earn money and prize packs. One round loss ends the run.
7. Clear Weekly Locals and the League Cup, open the final prizes, and reach Thanks for Playing.

See [Season Loop](docs/season-loop.md) and [Kitchen Match Rules](docs/game-rules.md) for the full rules.

## Project Layout

- `scenes/Main.tscn` and `scripts/Main.gd` — season shell and debug menu
- `scenes/Tabletop3DPrototype.tscn` and `scripts/Tabletop3DPrototype.gd` — the sole campaign and debug-match presentation on the production 3D Living Table
- `scripts/cooking/CookingCombatService.gd` — Kitchen Table rules and AI
- `scripts/CardEffectLab.gd` — Debug Sandbox scenarios for the canonical catalog's highest-risk effects
- `scripts/ContentCatalog.gd` — kitchen-card-to-season metadata adapter
- `scripts/RunStateService.gd`, `SeasonFlowService.gd`, and `TournamentService.gd` — campaign progression
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

The artifact is written to `builds/kitchen-table-road-to-worlds-<version>-itch-web.zip`, with `index.html` at the ZIP root. Complete the [Chrome, Safari, and Firefox QA matrix](docs/browser-qa.md) against that exact artifact before publishing.

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
"$GODOT_BIN" --headless --path . --quit-after 3
```

Additional references:

- [Technical Architecture](docs/technical-architecture.md)
- [Card Data](docs/card-data.md)
- [Development Status](docs/development-status.md)
