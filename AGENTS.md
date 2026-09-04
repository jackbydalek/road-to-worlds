# Project guidance

For any campaign, progression, overworld, route-map, encounter, reward,
deck-growth, persistent-health, or marketing-positioning task, read
`CONCEPT_DIRECTION.md` before making changes. It is the source of truth for the
target Slay-the-Spire-like run-loop pivot. The README and `docs/season-loop.md`
still describe much of the released demo's legacy loop, so do not use them to
silently reverse the pivot.

For any visual, UI, environment, character, card-frame, or image-generation task, read `ART_DIRECTION.md` before making changes. Pokémon Black and White is the explicit north star for UI color logic, contrast, hierarchy, and state language; it is a reference, not a license to copy protected assets or layouts. UI implementation should use shared tokens from `scripts/ui/GamePalette.gd`, migrating legacy warm tokens when needed to match `ART_DIRECTION.md`. Do not infer the game's visual identity from legacy shop assets or licensed asset-pack names.
