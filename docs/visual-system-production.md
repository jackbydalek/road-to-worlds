# TOP CUT: Locals to Worlds — Production Visual System

This is the implementation companion to `ART_DIRECTION.md`. If the two files
conflict, `ART_DIRECTION.md` wins. The purpose of this document is to prevent
individual screens from developing their own palettes, geometry, typography,
or interaction states while the run campaign is migrated.

## Locked identity

TOP CUT: Locals to Worlds uses a **graphic-chibi card-game adventure** style:

- Smooth illustrated characters with bold silhouettes and limited cel shading.
- Bright, cozy 2.5D locations framed by a cool, high-contrast interface.
- Carbon and graphite structural UI with cool-white copy.
- One semantic accent per control or section.
- Clipped corners, diagonal planes, inset keylines, and short hard shadows.
- Crisp, shape-led effects without bitmap stair-stepping or indiscriminate glow.

Pixel art is an exploration and animation reference, not the production render
mode for UI, characters, cards, or environments.

## Anti-cyberpunk checkpoint

Every migrated screen should pass this quick read: if the characters and card
art were hidden, the interface should still resemble a confident, playful
handheld game menu rather than a spaceship console.

- Large surfaces are solid neutral blocks, often alternating dark chassis with
  cool-white content areas.
- Angular geometry comes from silhouettes, tabs, and printed diagonal wedges.
- Static cyan borders, decorative grids, scanlines, glass blur, and ambient
  glow are not part of the production system.
- Accent color identifies the selected category or current action; it does not
  trace every container.
- Material Symbols Sharp icons are used as familiar navigation/action glyphs,
  while affinity and route icons remain authored TOP CUT symbols.

## Production tokens

All player-facing interface color comes from `scripts/ui/GamePalette.gd`.
Layout code should use the semantic roles below instead of color literals:

- `SURFACE_ROOT`, `SURFACE_RAISED`, `SURFACE_SECONDARY`
- `TEXT_PRIMARY`, `TEXT_SECONDARY`, `TEXT_DISABLED`
- `FOCUS_EDGE`
- `ACTION_PRIMARY`, `ACTION_CONFIRM`, `ACTION_DANGER`, `ACTION_SPECIAL`
- `STATE_REWARD`
- Affinity tokens for card and character identity only

Typical screens should remain 75–85% neutral. Affinity colors identify local
content; they do not replace the structural interface palette.

## Type, geometry, and spacing

- Oxanium SemiBold: display titles, section headings, counters, and short interface labels.
- Atkinson Hyperlegible Next: body copy, controls, stats, and instructions.
- Player-facing controls are at least 46 px tall.
- Structural borders are 2–4 px at 1440×900.
- Panels use clipped geometry and 18–30 px internal margins.
- Controls use visible hover, focus, pressed, disabled, selected, confirm, and
  danger states. Color-only changes are insufficient for important selection.

## Shared implementation

New run-facing screens use `scripts/ui/TopdeckUIComponents.gd`. The legacy
Sketch, Nexus, and Workspace component libraries remain migration shims and
must not be used for new route, encounter, reward, shop, or event work.

The shared production primitives currently include:

- Route/status HUD bars and stat chips
- Encounter shells and content sections
- Reward headers and modal framing
- Semantic action buttons
- Shared heading and body-copy roles

### Material Symbols Sharp map

Generic actions use the curated local subset in
`assets/ui/material_symbols_sharp/` through
`scripts/ui/MaterialSymbolsSharp.gd`:

- Navigation: `back`, `forward`, `close`, `play`
- System controls: `settings`, `save`, `restart`, `history`, `info`
- Deck actions: `cards`, `add`, `remove`, `upgrade`, `sort`, `view_grid`
- Economy and shops: `money`, `store`
- Battle actions: `swords`, `swap`, `speed`
- Access and display: `accessibility`, `volume`, `display`

These symbols may explain or reinforce a text label, but they do not replace
TOP CUT's affinity marks, route-node art, card classifications, recipe symbols,
or character emblems.

## Rendering contracts

### Characters and cards

- Carbon or navy exterior contour with quieter interior lines.
- Two primary shade levels per material; avoid realistic gradients.
- Preserve readable expressions and poses at runtime size.
- Use affinity color as a local identity accent, not a full-screen wash.

### Environments

- Cream masonry and paving, lavender-grey roofs and roads, restrained sage
  plants, and a single readable light direction.
- Character, building, route, and prop silhouettes must remain legible at the
  gameplay camera distance.
- Route overlays remain subordinate to the illustrated city.

### VFX

- Use one clear silhouette, one semantic color, and one secondary highlight.
- Damage is red, healing/valid resolution is emerald, rewards are yellow, and
  focus/player energy is cyan.
- Effects may use stepped timing and chunky clusters, but retain smooth native
  rendering.

## Migration rule

Migrate complete player journeys rather than isolated screenshots. The current
golden path is title → starter selection → route map → encounter → battle →
reward → shop/event → route map. A migrated screen must use shared tokens and
components, preserve all interaction states, and pass its existing smoke tests.
