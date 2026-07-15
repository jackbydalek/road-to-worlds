# Kitchen Table: Road to Worlds

Kitchen Table: Road to Worlds combines a competitive-season campaign with the Kitchen Table TCG match system. Build a Spicy, Hearty, or Sweet deck, buy cards and boosters, tune the list, and play live Kitchen Matches through a calendar that runs from Weekly Locals to Worlds.

## Play

Open the project in Godot 4.6:

```sh
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --editor --path .
```

The opening screen has two routes:

- **Season Run** — choose a starter kitchen and difficulty border, then progress through the calendar, shop, packs, deckbuilder, and tournaments.
- **Debug Sandbox** — immediately access the shop, authored shop scene, packs, deckbuilder, Kitchen Match, tournament simulator, and metagame screens.

## Season Loop

1. Choose the Spicy, Hearty, or Sweet 30-card starter.
2. Select a difficulty border that changes money, lives, opponent strength, or opening-player rules.
3. Prepare for the selected calendar event in the shop and deckbuilder.
4. Buy six-card boosters or exact singles and manage the collection.
5. Register for the tournament and play each round as a live Kitchen Table match.
6. Record the result, earn money and prize packs, and unlock the next event—or lose a season life and retry.
7. Clear Worlds to complete the run.

See [Season Loop](docs/season-loop.md) and [Kitchen Match Rules](docs/game-rules.md) for the full rules.

## Project Layout

- `scenes/Main.tscn` and `scripts/Main.gd` — season shell and debug menu
- `scenes/KitchenGame.tscn` and `scripts/cooking/KitchenGame.gd` — live match UI
- `scripts/cooking/CookingCombatService.gd` — Kitchen Table rules and AI
- `scripts/ContentCatalog.gd` — kitchen-card-to-season metadata adapter
- `scripts/RunStateService.gd`, `SeasonFlowService.gd`, and `TournamentService.gd` — campaign progression
- `scripts/ShopEconomyService.gd` — packs, singles, prices, and collection rewards
- `scripts/CardShopScreen.gd`, `PackOpeningScreen.gd`, `DeckbuilderScreen.gd`, and `SeasonHubScreen.gd` — campaign screens
- `data/cards.json` — 61 Kitchen Table cards and three starter decks
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
"$GODOT_BIN" --headless --path . --quit-after 3
```

Additional references:

- [Technical Architecture](docs/technical-architecture.md)
- [Card Data](docs/card-data.md)
- [Development Status](docs/development-status.md)
