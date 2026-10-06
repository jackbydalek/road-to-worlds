# Warm sketch UI — September 7, 2026

The owner's follow-up extends the Peach Soda battle direction across the
interface. This pass needs no additional supplied assets and generates no new
raster art. It uses the existing illustrations, licensed font and editable
Godot drawing.

The subsequent [Behance reference](https://www.behance.net/gallery/25367489/Hand-Drawn-Vector-UI-Kit)
refines the controls toward soft pen curves, rounded uneven corners, small
pencil shadows and drawn selection marks. The implementation uses original
procedural geometry and SVGs; none of the kit's assets are included. Buttons
resize with their native Godot controls, so each label/state/size does not need
an individually drawn image.

## The implemented treatment

- Cream paper, dark ink, deep teal primary actions, peach table accents and mint
  hover/selection highlights. Life, danger and affiliation colors keep their
  existing meanings.
- Shared ink outlines have small deterministic variations and short contact
  shadows. Text, control bounds and hit targets remain steady.
- The title uses oversized cream lettering on a teal mat, a compact menu,
  an asymmetric fan of original cards and native tabletop props.
- Starter selection, rival dialogue, hub HUD, shop price/service slips,
  settings, deck browsing, inspection, rewards and results share the same
  paper surfaces and button states.
- Soft Print is now the common card frame. Original illustration PNGs,
  affiliation bands, card information and overall card layout remain intact.
  Input card dictionaries are copied before adding presentation metadata.
- Menu utility backgrounds now use the native Peach Soda room drawing. The
  old generated room bitmap is retired into excluded development outputs.

## Editing points

| What to change | Source |
| --- | --- |
| Color roles | `scripts/ui/GamePalette.gd`, `PEACH_*` |
| Ink contour shape/pressure | `scripts/ui/WarmSketch.gd` |
| Panels and buttons | `scripts/ui/BattleAngularSurface.gd`, `BattleAngularButtonFace.gd`, `TopdeckUIComponents.gd` |
| Inputs, tabs, tooltips and theme | `scripts/ui/KitchenGlassTheme.gd` |
| Drawn checkboxes, toggles, radio marks, chevrons and slider knob | `assets/ui/sketch_controls/` |
| Title composition and lettering | `scripts/ui/TitleMenu.gd`, `TitleBackgroundPattern.gd`, `LocalsWordmark.gd` |
| Starter sheets and introductions | `scripts/ui/SeasonSetupMenu.gd`, `StarterSelectionSurface.gd`, `RouteRivalIntro.gd` |
| Shop HUD and prices | `scripts/ui/TournamentHubScreen.gd`, `HubCounterShopView.gd`, `HubRoundProgress.gd` |
| Cards, deck and inspection | `scripts/ui/RuntimeAngularCard.gd`, `scripts/CardFace.gd`, `scripts/DeckbuilderScreen.gd`, `scripts/ui/CardInspectionContent.gd` |
| Utility screens and native room placement | `scripts/Main.gd`, `scripts/ui/PeachSodaBattleBackdrop.gd` |

The historical Angular/Glass class names remain to preserve existing APIs;
they now draw the warm paper presentation. Contours use no random-number calls
and do not affect gameplay seeds. Font, keyboard navigation, focus restoration,
button variants, disabled-state readability and reduced-motion behavior remain.

## AI artwork

The eight previously generated opponent portraits are still clearly registered
under `assets/generated/peach_soda_opponents/`. Set
`PeachSodaCast.GENERATED_ART_ENABLED := false` to disable them across battle and
introductions, or replace them using the
[generated-art register](generated-art-register.md).

The former generated menu-room PNG and its import/manifest record are now in
`outputs/locals_pivot/superseded/warm-sketch-ui/`, excluded from shipping. The
active audit contains eight generated images. This does not attest the origin
of older supplied art. Sketch contours, frames, controls, wordmark and room
geometry are AI-assisted editable code, not generated bitmap textures.

## Screenshots and verification

[Hand-drawn controls review](../outputs/hand_drawn_ui/README.md) shows the
subsequent Behance-inspired refinement: a native control sampler and actual
title, display, audio and accessibility screens at 1440×900 and 1280×720.
The sampler includes hover, keyboard focus, selected and disabled states;
controls retain their original input targets. The battle, settings and global
button-style smoke checks pass. A geometry check confirms stable curved paths
without consuming gameplay randomness.

[Native screenshot gallery](../outputs/warm_sketch_ui/README.md): eleven screens
at 1440×900 and 1280×720, rendered directly by Godot with deterministic review
fixtures, captured before the subsequent control refinement. Screenshots are
not image-generated concepts and do not represent the owner's saved run.

Relevant existing checks pass for title/starter/intro navigation, global button
styling, battle settings, hub and shop services, card inspection, deck layout
and return behavior, reward selection/layout, and results. Card-face auditing
passes all 87 cards. The generated-art provenance audit passes with eight
registered assets; `git diff --check` is clean.

To refresh the gallery:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --log-file /tmp/warm-ui-capture.log --script res://scripts/WarmSketchUiCapture.gd
```

To refresh the focused control review:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --log-file /tmp/hand-drawn-ui-capture.log --script res://scripts/HandDrawnControlsCapture.gd
```
