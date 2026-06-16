# Road to Worlds

Road to Worlds is a roguelike deckbuilding game about climbing a competitive trading card game season from locals to Worlds.

## Prototype

This repo now includes a Godot 4 vertical slice.

To run it:

1. Open Godot 4.x.
2. Click **Import**.
3. Select this folder: `/Users/jack.bydalek/Documents/Road to Worlds`.
4. Open the imported project.
5. Press **Play**.

Playable loop:

- Choose Redline Aggro, Lantern Control, or Verdant Midrange.
- Visit the card shop.
- Buy and reveal booster packs.
- Buy singles.
- Tune a 30-card main deck and 6-card sideboard.
- Run a seeded auto-duel in the Combat Lab.
- Choose a Combat Lab opponent and inspect final board, hand, engines, discard, and combat log.
- Start a manual Combat Lab battle, select cards or attackers, use highlighted legal targets, and end turn into the opponent AI.
- Enter a three-round Weekly Locals event backed by auto-resolved best-of-three combat matches.
- Survive with a 2-1 or better record, or the run ends.
- Watch the local metagame shift after tournaments.

The prototype now uses the combat engine for Weekly Locals matches. Deck metrics still help explain deck quality, archetype fit, curve, role balance, and sideboard tech.

Start here:

- [Game Design](docs/game-design.md): core loop, collection, tournaments, metagame, boosters, archetypes, bosses, and MVP scope.
- [Technical Architecture](docs/technical-architecture.md): Unity/Godot-friendly data structures, services, match simulation, metagame simulation, and milestones.
- [Godot script](scripts/Main.gd): current single-file prototype implementation.
- [Combat engine](scripts/CombatService.gd): simplified TCG duel foundation.
- [Combat progress](docs/combat-implementation-progress.md): current combat roadmap and handoff notes.
- [Combat card schema](docs/combat-card-schema.md): explicit `combat` fields and placeholder UI customization notes.
- [Prototype card data](data/content/cards.json): 56-card starter set.
- [Prototype archetypes](data/content/archetypes.json): Redline Aggro, Lantern Control, and Verdant Midrange starter decks.
- [Example Card Data](data/cards.example.json): sample card schema and starter cards.
- [Example Archetype Data](data/archetypes.example.json): sample archetype schema and matchup data.
- [Example Booster Data](data/boosters.example.json): sample pack slot definitions.
- [Example Season Data](data/season.example.json): sample tournament tier definitions.

The recommended MVP path is to build a data-driven prototype first: collection, deckbuilder, abstract match simulator, tournament ladder, boosters, shop, and then dynamic metagame updates.

## Validation Commands

When Godot is available from the downloaded zip used during development:

```sh
env HOME=/private/tmp/rtw-godot-home /private/tmp/rtw-godot/Godot.app/Contents/MacOS/Godot --headless --path "/Users/jack.bydalek/Documents/Road to Worlds" --quit-after 2
env HOME=/private/tmp/rtw-godot-home /private/tmp/rtw-godot/Godot.app/Contents/MacOS/Godot --headless --path "/Users/jack.bydalek/Documents/Road to Worlds" --script res://scripts/CombatSmokeTest.gd
env HOME=/private/tmp/rtw-godot-home /private/tmp/rtw-godot/Godot.app/Contents/MacOS/Godot --headless --path "/Users/jack.bydalek/Documents/Road to Worlds" --script res://scripts/UISmokeTest.gd
env HOME=/private/tmp/rtw-godot-home /private/tmp/rtw-godot/Godot.app/Contents/MacOS/Godot --headless --path "/Users/jack.bydalek/Documents/Road to Worlds" --script res://scripts/TournamentSmokeTest.gd
```
