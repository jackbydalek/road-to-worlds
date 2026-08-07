# Premium Polish Checklist

This checklist tracks the player-facing polish pass started on 2026-07-30.

## Current Pass

- [x] Hide player-facing debug entry points unless the game is launched with `--dev` or `--debug-menu`.
- [x] Replace exposed programmer-facing copy with short player-facing copy.
- [x] Replace the large “Saving…” toast with a small animated save-status glyph.
- [x] Replace the abrupt completion panel with a composed League Cup finale and championship teaser.
- [x] Add a persistent Settings screen.
  - [x] Fullscreen toggle.
  - [x] Window resolution selector.
  - [x] Master volume.
  - [x] Music volume.
  - [x] Sound-effects volume.
  - [x] Text-size selector.
  - [x] High-contrast text.
  - [x] Reduced menu motion.
  - [x] Restore-defaults action.
- [x] Pass the targeted smoke tests and graphical preview review.

## Tournament Result TLC

- [x] Replace the raw tournament log with a composed result ceremony.
- [x] Lead with the event outcome and final record.
- [x] Separate table earnings from the event prize.
- [x] Add a player-facing round recap without seeds or simulation odds.
- [x] Tease the next event—or give defeat a deliberate ending.
- [x] Make the primary reward/restart action unmistakable.
- [x] Give secondary actions equal, usable button space.
- [x] Keep technical match details behind the development flag.
- [x] Review both victory and defeat captures at 1440×900.
- [x] Pass the dedicated result-screen smoke test.

## Battle UI — First Polish Pass

- [x] Replace prototype/AI-facing header copy with event and round context.
- [x] Make turn ownership the visual center of the match HUD.
- [x] Present both life totals as distinct player and rival badges.
- [x] Make End Turn the unmistakable primary battle action.
- [x] Move the match log out of the battlefield and into the header.
- [x] Collapse rival-speed and text-size controls behind Match Options.
- [x] Add concise Prep and Plated lane labels.
- [x] Hide lane labels, pile names, and pile counts behind a compact table-information control.
- [x] Remove Chef names from the attack pucks while retaining their life totals.
- [x] Remove the duplicate life/name readouts from the top HUD.
- [x] Add action context to the instruction strip.
- [x] Move the instruction strip below the hand so cards remain visible and clickable.
- [x] Hide the bottom strip during ordinary play; show it only for rule errors or required decisions.
- [x] Reuse the bottom strip as a contextual action bar for required Confirm/Cancel decisions.
- [x] Give every dark battle-menu button high-contrast text across normal, hover, pressed, and disabled states.
- [x] Match Meal ingredient selection auras to the pulsing ability-aura treatment.
- [x] Keep general turn guidance available inside the Match Log.
- [ ] Complete the deeper battlefield art pass: chef markers, table materials, lane dressing, and ambient presentation.

## Storefront CTA

- [x] Promote Start Round into a high-contrast mustard tournament action with a larger silhouette.
- [x] Add strong hover, pressed, focus, disabled, and reduced-motion-aware attention states.

## Notes

- Settings are stored separately from season saves in `user://topdeck_to_worlds_settings.json`.
- The Music and SFX buses are created automatically so the controls are ready for future audio assets.
- Reduced menu motion currently removes button bounce, save-glyph rotation, draft flourishes, the round wipe, booster spreading/flipping flourishes, rare-card shake, the finale fade, and the shopkeeper arrow bob.
- Verified with public and `--dev` UI audits, game-start flow, storefront UI, autosave/resume, public startup, and 1440×900 graphical captures.
