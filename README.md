# Kitchen Table: Road to Worlds

Kitchen Table: Road to Worlds combines a competitive-season campaign with the Kitchen Table TCG match system. Build a Spicy, Hearty, or Sweet deck, buy cards and boosters, tune the list, and play live Kitchen Matches through a calendar that runs from Weekly Locals to Worlds.

## Play

Open the project in Godot 4.6:

```sh
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --editor --path .
```

The opening screen has three options:

- **Continue** — resume the latest autosave on its saved campaign screen. An interrupted Kitchen Match restarts the same round and opponent.
- **New Run** — choose a difficulty card frame and the Spicy, Hearty, or Sweet starter deck.
- **How to Play** — follow a seven-step visual walkthrough of recipes, zones, combat, and the turn sequence.

The title screen also keeps a direct **Debug Menu** entry for development access to all five starters and isolated test surfaces.

Runs autosave after progression changes and navigation, as well as before returning to the title or closing the game. Saves are versioned and retain a known-good backup for recovery.

## Season Loop

1. Choose the Spicy, Hearty, or Sweet 30-card starter and a difficulty-linked card frame.
2. Select a difficulty border that changes money, opponent strength, or opening-player rules.
3. Explore the mouse-driven 3D card store and click the shopkeeper, trading table, metagame board, or deck box.
4. Browse and buy exact singles inside the 3D shop scene, or open six-card boosters.
5. Register through the shopkeeper and play three rounds on the angled 3D Living Table.
6. Win all three rounds to earn money and prize packs. One round loss ends the run.
7. Clear Weekly Locals and the League Cup, open the final prizes, and reach Thanks for Playing.

See [Season Loop](docs/season-loop.md) and [Kitchen Match Rules](docs/game-rules.md) for the full rules.

## Project Layout

- `scenes/Main.tscn` and `scripts/Main.gd` — season shell and debug menu
- `scenes/Tabletop3DPrototype.tscn` and `scripts/Tabletop3DPrototype.gd` — the sole campaign and debug-match presentation on the production 3D Living Table
- `scripts/cooking/CookingCombatService.gd` — Kitchen Table rules and AI
- `scripts/CardEffectLab.gd` — Debug Sandbox scenarios for the expansion card effects
- `scripts/ContentCatalog.gd` — kitchen-card-to-season metadata adapter
- `scripts/RunStateService.gd`, `SeasonFlowService.gd`, and `TournamentService.gd` — campaign progression
- `scripts/ShopEconomyService.gd` — packs, singles, prices, and collection rewards
- `scripts/CardShopScreen.gd`, `PackOpeningScreen.gd`, `DeckbuilderScreen.gd`, and `SeasonHubScreen.gd` — campaign screens
- `data/cards.json` — 89 Kitchen Table cards and five 30-card starter decks
- `data/content/boosters.json` and `tournaments.json` — campaign content

The old fish combat, fish card catalog, mana/threat renderer, and animal artwork are not part of the runtime.

## Validate

```sh
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . \
  --script res://scripts/cooking/KitchenGameSmokeTest.gd
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
"$GODOT_BIN" --headless --path . --quit-after 3
```

Additional references:

- [Technical Architecture](docs/technical-architecture.md)
- [Card Data](docs/card-data.md)
- [Development Status](docs/development-status.md)
