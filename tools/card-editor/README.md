# Card Studio

Local card library and editor for **See You at Locals**. Open `Start Card Studio.command`
at the project root, or run `npm start` in this directory. The app opens at
http://127.0.0.1:4317. Keep the launcher terminal running while editing.
Requires Node.js 18 or newer; no packages need installing.

## Editing

- Browse all 95 collectible cards and the Fresh token, including the eight
  Second Helpings Meals. Search names, printed effects, keywords, or rule fields;
  filter by type, affinity, set, artwork, or saved draft.
- Select a card. **Details** edits names, stats, text, keywords, recipes,
  affinities, existing passive rules, and art. **Effects** edits the actual ordered
  effects and activated abilities. **Advanced** exposes the complete JSON.
- **Printed text does not implement a mechanic.** Change Effects too, or save
  a request for Codex. Existing non-effect rule fields (Spice bonuses, auras,
  Special Serve conditions, hand traps) are exposed under additional/passive rules.
- **Save draft** (Command/Ctrl+S) persists locally without changing the game.
  **Review & apply** shows the difference and writes that single card to its
  original game file. Relaunch the running game to reload definitions. Re-export
  previously built releases to include edits. Existing in-progress combat snapshots
  may retain their original stats until a new battle/run.
- The preview uses the original artwork, shared palette, and live draft fields;
  it is an editing preview, not a pixel-identical Godot card render. Cards without
  original art use the same art-pending image as the game. Refresh the library to
  pick up new art and card edits made elsewhere in the project.
- Animated artwork can be played in the selected preview. Reduced Motion holds
  the first frame. PNG replacement writes a new content-addressed asset and updates
  the draft; it never overwrites original images. GIF frame lists remain editable.
- **Request** saves a note in `change-requests.json`. Tell Codex **“Implement my
  card change requests.”** The app does not run an AI agent automatically.
  Codex should implement pending notes, align mechanics and printed text, verify
  them in the game, then mark completed entries `"status": "done"` with a summary.

## Data and recovery

Game sources are `data/cards.json`, `data/content/second_helpings.json`, and
`data/content/tokens.json`. The last file supplies service-only tokens; it is not
added to collectible pools. Card IDs and token status are fixed to preserve references.
No game balance or card artwork is changed simply by launching the editor.

Each apply writes only the selected object, preserving surrounding bytes and
unrelated cards/decks. Per-card revisions reject stale source writes. Draft
versions also prevent two browser tabs from overwriting one another's drafts.
Conflicted drafts can be saved; use **Compare with current game** to review a
conflict and explicitly choose the editing base, or Reset to discard the draft.

`.local/drafts.json` stores drafts. `.local/history.json` records before/after
definitions. `.local/backups/` contains complete source-file backups made before
each apply. **Undo last apply** restores the previous card only if the current
definition still matches that history record. Other cards remain unchanged.
These local files are ignored by Git. `change-requests.json` is intentionally
reviewable project content. Discarded uploaded images remain available on disk.

The editor binds only to loopback and checks Host, Origin, and a session token
on writes. It serves only its own UI and allowed artwork/font assets. It is a
local tool, not an internet-hosted editor. `CARD_STUDIO_PORT` overrides port 4317.
`.gdignore` keeps the editor out of Godot's resource import tree.

`reference-schema.json` retains supported field shapes and existing effect
examples, so deleting the last use of an effect does not remove it from the
editor. Add new fields/effect definitions there when implementing new mechanics.
Validation checks known structure and references; it cannot prove every combination
of effects is sensible. Playtest balance and new combinations in Godot.

## Checks

Run `npm test`. The suite uses isolated temporary copies to verify drafts,
conflicts, exact single-card writes, backups/undo, expansion and token routing,
request persistence, and HTTP write protection. If Godot is installed at the
standard macOS path, it also loads a card edited through the actual apply code
and resolves its changed stats and damage in combat. No real card data or saves
are modified by the tests.
