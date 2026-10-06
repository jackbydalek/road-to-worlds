# dobo_ui Cozy UI — September 9, 2026

Source: [Cozy UI by dobo_ui](https://dobo-ui.itch.io/cozy-ui).
The project owner supplied `DEMO_Cozy_UI_Pack_doboui.zip` and requested palette
adjustment and modular resizing. Eleven original demo PNGs are selected for
runtime use. The requested battle health bars also use two original PNGs
from the owner's full pack at
`/Users/jack.bydalek/Desktop/Game/Game 8:5/Cozy_UI_Pack_doboui/` (with its ZIP
alongside it). Exact sources and SHA-256 values are in `source-manifest.json`;
both included developer notes are preserved unchanged.

## Source and usage record

The creator's product page permits commercial project use and modification,
and prohibits redistribution/resale of the asset pack and generative-AI uses.
This is a summary of the creator's published terms, not a replacement license
or a CC0 declaration. The supplied demo note does not contain a separate
complete license. Keep the creator's terms and attribution with this integration;
do not distribute the source folder as a standalone UI pack.

The creator describes the artwork as handmade without AI. That is an external
source statement, not an independent authorship certification. This integration
uses no image generation, model-based editing, training or generated artwork.
All source PNGs here remain byte-identical to the owner's supplied pack files.

## Adaptation

`scripts/ui/CozyPackAssets.gd` maps the source paint colors through shared
`GamePalette.gd` tokens into cached Godot textures. Brown contours become dark
blue ink; paper becomes Peach paper; actions use teal; destructive actions keep
the existing red state language. It preserves source alpha and maps the
antialiased transitions between paint colors. Check marks use cream on teal.

Square and rounded blank buttons and one plain panel use nine-slice drawing.
The center stretches while the corners retain their dimensions. Full-resolution
button and panel sources remain available during rendering. Labels, icons,
focus indicators and hit areas stay native controls, separate from the bitmap.

Current consumers are `BattleAngularButtonFace.gd`, `SketchPanelContainer.gd`
and the checkbox/popup marks in `KitchenGlassTheme.gd`. The composition pass
also shares panel contours with `BattleAngularSurface.gd` and
`BattleMatchHudSurface.gd`, uses the supplied perforated note in `TitleMenuNote.gd`,
and repeats a small supplied heart in shop and battle life displays. Four recolored arrow
textures are available through the helper; existing live dropdown chevrons
remain in place. The demo does not include the full preview's notebook panels,
ribbons or switches. Existing radios, sliders and switches remain in use.

Card illustrations, affiliation colors, card ribbons and starter-deck packaging
were not changed by this integration. Review images and the original extracted
demo are under the export-excluded `outputs/dobo_cozy_ui_v1/` directory.
Updated in-game review captures are indexed by `outputs/cozy_cohesion_v2/README.md`.

## Full-pack battle health bars

The user requested the kit's health bar in place of the player/opponent health
cards. The full pack contains purpose-made continuous progress-bar art:

- `health_track.png` is unchanged `ProgressBars/ProgressBar/ProgressBarBackground.png`,
  494 × 69 pixels, with a paper center and the pack's rounded ink contour.
- `health_fill.png` is unchanged `ProgressBars/ProgressBar/ProgressBar10.png`,
  478 × 52 pixels, the borderless rounded fill that nests inside the track.

The existing conventional palette mapper converts the brown contour to shared
blue ink and the gold fill to the game's semantic health colors. Native drawing
and proportional fill geometry control the live life ratio; the label and numbers remain native
text. Source art has not been redrawn, generated, cropped from a store preview,
or recolored on disk. The additional full-pack developer note is
`developerNote-full-pack-dobo-ui.txt`.
