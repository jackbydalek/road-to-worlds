# Peach Soda battle overhaul — September 7, 2026

The playable battle now follows the owner's flat Peach Soda concepts: cream
paper, dark ink, teal mats, peach table and restrained mint. These are native
Godot scenes and controls, with the existing board perspective and gameplay.

## What changed

- A code-drawn card-shop room with windows, binders, a plant and noticeboard,
  a peach tabletop and two separately bound teal cloth mats, with a visible
  tabletop gap. Camera and all ten battle slots are preserved; the opponent's
  Environment and Discard piles sit slightly farther back to fit their mat.
- Eight seated rivals from the requested concept cast: Pip, Otis, Ines, Sana,
  Milo, Bea, Kit and Ellis. Introductions and battles use the same cast identity.
- Paper scorecards, readable turn slips, quiet borders, cream/teal buttons,
  native line icons and a printed sleeve design.
- An opt-in Soft Print card frame for battle and inspection. Original card
  illustrations, affiliation colors, information and general layout remain.
- White silhouettes around hovering card art, live opponent hand counts,
  and character-based attack targeting with the normal blockers and rules.

Regular encounters select among six rivals deterministically. Mina's stronger
encounter now uses the owner's supplied `IMG_0450.GIF`, replacing its interim
Bea presentation; Ellis remains the final champion. Presentation does not
consume combat randomness or rewrite saved encounter identities, decks or runs.

Mina's battle layer, introduction and profile use the supplied source colors
and six 70 ms frames. `SeatedRivalPortrait.gd` plays each view independently and
holds frame zero with Reduced Motion. Her tight 701×628 canvas has a dedicated
table anchor so the mat does not hide her resting hand. The source GIF, PNGs
and lossless preparation record are under `assets/characters/mina/`.

Her free hand now holds the actual count of concealed sleeve backs. Draw events
fly from the deck or discard pile into her hand; plays withdraw a back from her
fingers before the public card arrives on the table. Discards also remove a
held back. The fan clears completely at zero and compresses for large hands.
`RivalHeldCards.gd` layers existing finger pixels over the cards, following each
supplied animation frame without altering any source images. Reduced Motion
snaps these updates. Reconciliation after each event batch prevents stale cards.

## AI art and how to remove it

**The eight opponent PNGs are AI-generated working art.** They live only in
`assets/generated/peach_soda_opponents/` and have exact hashes, original prompts,
source references and extraction records. Each has one relaxed expression;
their painted held cards are decorative. Hand counts and changing game state
are rendered separately by the game.

Set `GENERATED_ART_ENABLED := false` in
[`PeachSodaCast.gd`](../scripts/ui/PeachSodaCast.gd) to disable all eight portraits
in both battles and introductions. Native card-club artwork supplies the
fallback, and the battle displays real opponent card backs. Missing portrait
files also fall back safely. A battle instance can additionally set
`use_generated_opponent_art = false`.

These generated-art switches leave supplied Mina visible. Her integration
creates no new AI images and is recorded separately from the eight generated
working portraits.

For artist replacements, preserve a 1448×1200 RGBA canvas and the y=1000
resting-arm baseline. Place final assets outside `assets/generated/` and update
`PeachSodaCast.ART_ROOT` or its mapping. Review the profile crop if the face
position changes. Retire the old files and manifest entries together.

The room, mat, frames, buttons, icons and sleeve are editable AI-assisted code
or SVGs, not generated raster illustrations. No new card-face illustrations
were generated or substituted. No Aqua Studio brushes were used.

The subsequent warm sketch UI pass also replaces the former Main.gd generated
menu-room bitmap with native room geometry. Only the eight rival images remain
in the active registered inventory. See the [generated-art register](generated-art-register.md).

## Main editing points

| Element | File |
| --- | --- |
| Palette | `scripts/ui/GamePalette.gd`, `PEACH_*` roles |
| Room and table | `scripts/ui/PeachSodaBattleBackdrop.gd` |
| Mat, staging, targeting and live HUD | `scripts/Tabletop3DPrototype.gd` |
| Mat printing | `scripts/ui/TournamentPlaymatPrint.gd` |
| Rival mapping, art switch and portrait crops | `scripts/ui/PeachSodaCast.gd` |
| Supplied animation and reduced motion | `scripts/ui/SeatedRivalPortrait.gd`, `assets/characters/mina/` |
| Mina's live concealed hand and finger overlay | `scripts/ui/RivalHeldCards.gd` |
| Card frames | `scripts/ui/RuntimeAngularCard.gd`, `peach_soda_frame` opt-in |
| Paper panels and buttons | `scripts/ui/BattleAngularSurface.gd`, `scripts/ui/BattleAngularButtonFace.gd` |
| Scorecards and turn slips | `scripts/ui/BattleMatchHudSurface.gd`, `scripts/ui/TurnChangeGraphic.gd` |
| Action icons | `assets/ui/peach_soda_actions/` |
| Card backs | `assets/cards/card_backs/peach_soda_sleeve.svg` |

## Validation and screenshots

The [two-mat/live-hand gallery](../outputs/split_mats_live_hand/README.md) records
the current battle at 1440×900 and 1280×720, including actual draw and play
transitions. Its smoke test covers mat separation and card/pile containment,
concealed hand counts, event synchronization, Reduced Motion and targeting.

The [supplied Mina gallery](../outputs/supplied_mina/README.md) shows the earlier
playable battle at 1440×900 and 1280×720, including animation and Reduced Motion
states. Supplied-art checks cover frame timing, transparency, face cropping,
generated-art independence, hand visibility and live attack targeting. The
route intro check also reaches Mina through the real third-round hub button.

[`outputs/peach_soda_battle/`](../outputs/peach_soda_battle/) contains real Godot
renders at 1280×720, 1440×900 and 1920×1080. Each resolution includes a sparse
opening, populated board, legal placement and card inspection. The adjacent
`layout_report.json` records the checks. These are native screenshots, not
image-generated mockups.

`PeachSodaBattleSmokeTest.gd` checks cast routing, art fallback, projected slots,
original card art and affiliation colors, frame isolation, contrast and live
attack targeting. Existing layout, opponent-hand attack, settings, action
preview, inspection, button style, campaign and rival-intro tests cover the
affected flows. `scripts/release/check_no_ai_assets.sh --audit-known` verifies
the eight registered generated assets and excluded source-art directories.

Capture command (run from the project directory with a graphical display):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --log-file /tmp/peach-soda-capture.log --script res://scripts/PeachSodaBattleCapture.gd
```
