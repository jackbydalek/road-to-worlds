# Combat Implementation Progress

This file is the handoff point for multi-session combat work. Update it whenever a combat slice lands.

## Target

Build a simplified TCG duel system for Road to Worlds without replacing the existing shop, pack, deckbuilder, and tournament loop until combat is stable.

## Current Strategy

1. Keep the Combat Lab as the safest test bench for combat changes.
2. Add a separate Combat Lab screen for testing.
3. Build a reusable combat engine in `scripts/CombatService.gd`.
4. Use explicit card combat data for all current content.
5. Use auto-combat best-of-three matches in Weekly Locals while manual combat remains in Combat Lab.

## Implemented

- Design spec for simplified TCG duel exists in chat context.
- Current prototype supports three archetypes: Redline Aggro, Lantern Control, Verdant Midrange.
- `scripts/CombatService.gd`
  - Combat state model
  - Deck/hand/discard/board/engine zones
  - Life totals and fatigue
  - Focus resources
  - Auto-resolved threat/action/engine turns
  - Manual combat lifecycle APIs
  - Manual play-card, attack, and end-turn actions
  - Explicit manual action and attack target APIs
  - Explicit combat fields for all 103 prototype cards
  - Reusable effect resolver for damage, draw, heal, token creation, buffs, debuffs, destroy, exhaust, keyword grants, discard, recover, and focus gain
  - Wave 2 trigger hooks for `start_turn`, `end_turn`, `on_death`, `on_damage_player`, `opponent_draw`, and `on_card_played`
  - Wave 2 trigger support for `oncePerTurn`, trigger-level conditions, dynamic effect amounts, source-unit targeting, and temporary end-turn stat effects
  - Wave 2 activated unit abilities with focus costs, once-per-turn tracking, optional attack prevention, Combat Lab buttons, and simple auto-combat use
  - Archetype-restricted temporary focus pools for stipend tools; matching cards spend restricted focus before normal focus
  - Ready tokens from start-turn engines can attack
  - Basic threat combat, stun handling, and death cleanup
  - Improved AI scoring, removal targeting, lethal burn targeting, and attack targeting
  - Seeded auto-duel support
- `scripts/Main.gd`
  - Combat Lab nav entry
  - Auto Duel button using current player deck
  - Start Manual Battle button using current player deck
  - Placeholder card-table UI for hand and board cards
  - Selection-based manual target controls for action cards, face attacks, and attacks into specific opposing units
  - Legal-target border highlights and compact selected-source display
  - Latest-action panel with colored recent combat log lines
  - First manual-combat UX polish slice: playmat wrapper, feedback chips for recent events, hover/press card motion, styled buttons, selected/ready/legal-target badges, and clearer face/unit target affordances
  - Left-side card inspect panel in Combat Lab that updates from hover/press/selection and shows placeholder art, card metadata, stats, implemented effect text, and design text
  - Manual combat layout now starts using explicit zone panels for board, engine, hand, and discard areas, with empty board/engine slots and opponent card backs
  - Lightweight action animation layer for manual combat that shows a moving card ghost, source/target/destination route text, and pulsing impact badges for damage, healing, draw, play, KO, and focus feedback
  - Board zones now render explicit numbered player/opponent slot wrappers, and action animation includes a curved target arc, arrow head, and source/target/destination markers
  - Separate UI Combat tab for the visual manual battle view, with live target-preview arcs and committed action arcs drawn against the actual rendered board slots/face panels
  - UI Combat committed-action VFX now self-expire, animate a board-layer card ghost between actual board/zone anchors, pulse the involved source/target/destination nodes, and spawn board-position impact badges instead of relying on the debug action-track window
  - UI Combat target arrows are now reserved for real attacks/targeted casts; selected hand cards and non-target finisher plays use card movement/pulses instead of drawing stray board arrows
  - UI Combat card movement now uses exact hand/unit card-panel anchors and captures pre-rebuild source/target screen positions, so the moving card starts from the actual card panel instead of from a broad hand/discard zone
  - UI Combat now has a first compact 16:9-oriented duel layout pass: footer hidden in this tab, tighter playmat/card/slot sizing, opponent hand above board, player hand below board, card inspect on the left, and a middle-right contextual action rail with End Turn
  - UI Combat inspect behavior now treats hover as temporary and click/selection as pinned, so unclicked hover details clear on mouse exit
  - UI Combat player hand now renders as a fanned, overlapping real-life-style hand; End Turn and contextual actions now sit inside a board control strip between the two play areas instead of in an outside side rail
  - UI Combat now hides the debug-style battle log/action summary behind a top-left Battle Log toggle, uses more compact uniform card faces, spreads the hand fan wider, tightens board/engine/opponent-hand spacing, and keeps non-target action feedback visible through board-position fallback VFX
  - UI Combat battlefield now uses a canvas-style arena so the play area fills the board, while card inspect floats as a translucent left-side overlay instead of consuming layout space
  - UI Combat board order now matches the latest concept: opponent fanned hidden hand, opponent engines, opponent threats, player threats, player engines, player fanned hand, with side life/focus overlays and a smaller floating End Turn button
  - UI Combat inspect overlay is now click/selection-only instead of persistent or hover-driven, so it stays off the board until a card is explicitly pinned
  - UI Combat hand fan now sits higher in the player hand band, and clicking the battlefield outside cards dismisses the pinned inspect overlay
  - UI Combat inspect dismissal now uses a root-level click-away check so empty board/zone panels cannot swallow clicks and leave the overlay stuck
  - UI Combat opponent hand band is now shorter, opponent hand backs are fanned and index-named to show hand count, and the reclaimed height is reserved for a more stable player hand band
  - UI Combat board, engine, and hand bands now use compressed fixed heights with smaller board cards/slots so the player hand remains visible even when both boards have active threats
  - End Turn button that advances opponent AI and returns to player turn
  - Weekly Locals tournament rounds use combat-backed best-of-three auto matches
  - Selectable Combat Lab opponent
  - Debug output for winner, seed, final life, board count, and combat log
  - Final-state panels for both players: board, engines, hand, discard highlights, deck count, focus, fatigue
- `scripts/UISmokeTest.gd`
  - Headless UI smoke test for UI Combat startup, exact hand/unit card anchors, fanned player hand, board-embedded contextual controls, middle-right End Turn button, hover-inspect clearing, board arc layer rendering, selection-preview arcs, committed board-position target arcs, self-expiring board VFX, no stray finisher-play arrows, card inspect panel, zone layout, motion feedback, and damage/heal feedback
- `scripts/CombatSmokeTest.gd`
  - Headless smoke test for seeded combat simulation, all-card combat data, ready token attacks, and targeted manual combat actions
- `scripts/TournamentSmokeTest.gd`
  - Headless smoke test for combat-backed Weekly Locals
- `scripts/Wave1SmokeTest.gd`
  - Headless smoke test that exercises all 47 `wave1` cards once with dummy combat targets and checks for unsupported combat logs
- `scripts/Wave2SmokeTest.gd`
  - Headless smoke test for death triggers, combat-damage triggers, end-turn self-destruction, opponent-draw triggers, tool conditions, dynamic hand-size damage, once-per-turn card-play triggers, restricted focus payment, and activated abilities

## Not Started

- Sideboarding between combat games
- Combat animations and card art
- Exact rules support for remaining Wave 1 advanced mechanics: top-deck choices, copying, silencing, countering, broader temporary effects, and cost modifiers

## Next Good Tasks

1. Continue UI Combat presentation polish: tune the 16:9 board proportions with visual QA, add stronger summon/discard zone transitions, improve duplicate-card hand selection, and replace placeholder art frames with real asset hooks.
2. Add best-of-three Combat Lab match mode.
3. Add sideboarding between combat games.
4. Tune combat balance using tournament smoke/autoplay batches.
5. Start replacing placeholder card visuals with inspectable card assets.
6. Upgrade Wave 1 approximation cards into exact mechanics once their designs are approved.

## Validation

- 2026-06-12: JSON validation passed.
- 2026-06-12: Godot 4.6.3 headless project boot passed.
- 2026-06-12: `scripts/CombatSmokeTest.gd` passed with seeded Aggro vs Midrange auto-duel.
- 2026-06-12: Combat Lab upgraded with opponent selection and readable final-state panels.
- 2026-06-12: Manual Combat Lab controls added; smoke test now covers manual start, play-card, and end-turn flow.
- 2026-06-12: Manual Combat Lab targeting added for damage actions, face attacks, and specific opposing units; targeted combat smoke coverage passed.
- 2026-06-12: Starter-deck `combat` fields, reusable effect resolver, and placeholder card-table UI added; combat and UI smoke coverage passed.
- 2026-06-12: Manual Combat Lab usability pass added selected-source state, legal-target highlights, larger buttons, and latest-action feedback; combat and UI smoke coverage passed.
- 2026-06-12: All cards converted to explicit combat data; effect system expanded; token attacks fixed; AI targeting improved; Weekly Locals now uses combat-backed best-of-three auto matches; combat, UI, and tournament smoke coverage passed.
- 2026-06-13: Wave 1 card idea batch added as 47 playable approximation cards tagged `wave1`; card pool is now 103 cards. Added `gain_focus` effect for prototype focus tools. JSON, Wave 1, combat, UI, and tournament smoke coverage passed.
- 2026-06-13: Wave 2 started. Added generic trigger hooks, dynamic effect amounts, source-unit effect targets, trigger conditions, once-per-turn triggers, basic invincible prevention, and temporary end-turn stat expiration. Upgraded 12 Wave 1 cards with `wave2` tags: Last-Word Brawler, Ravenous Baloth, Toolfed Scrapper, Refund Beast, Growing Duelist, Grip Punisher, Curiosity Harness, Glass-Cannon Sprinter, Draw Punisher, Impact Mauler, One-Drop Reactor, and Graveyard Coward. JSON, Wave 1, Wave 2, combat, UI, and tournament smoke coverage passed.
- 2026-06-13: Added the next Wave 2 slice: activated unit abilities and archetype-restricted focus. Converted Lifebloom Glider, Gravepath Guide, Focus Page, Grove Stipend, Lattice Stipend, and Redline Stipend to exact-ish Wave 2 mechanics. Combat Lab now shows ability buttons and restricted focus labels. JSON, Wave 1, Wave 2, combat, UI, and tournament smoke coverage passed.
- 2026-06-15: First manual-combat UX polish slice landed. Combat Lab now has a playmat-style manual battlefield, feedback chips, clearer face/unit target affordances, selected/ready/legal-target badges, styled hover/press buttons, and hover/press motion on placeholder combat cards. JSON, UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Added left-side card inspect panel and the first explicit zone layout pass. Hover/press/selection can update inspected card details, and manual combat now renders board, engine, hand, and discard as named zones with slots/card backs. JSON, UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Added the first manual action animation layer. Manual card plays, targeted casts, attacks, and activated abilities now infer source/target/destination routes, animate a moving card ghost, and show pulsing impact badges for damage/heal/draw/play/focus/KO feedback. UI smoke now verifies movement, damage, and healing feedback. JSON, UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Started board slot positioning and target-line VFX. Manual board zones now render named numbered player/opponent slot wrappers, and the action animation track draws a curved target arc with an arrow head plus source/target/destination markers. UI smoke now verifies board slots and target arc VFX. JSON, UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Added the separate UI Combat tab and board-space target line slice. UI Combat now renders a board arc layer over the manual battlefield, draws live preview arcs from selected attackers/cards to legal targets, and draws committed action arcs to actual board slot/face anchors after attacks or casts. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Fixed lingering UI Combat committed arrows and moved action feedback onto the battlefield. Committed board arrows now fade/queue-free, UI Combat shows a compact Last Action summary instead of the debug action animation track, board-layer card ghosts travel from source to target/destination anchors, and board impact badges self-expire. UI smoke now verifies VFX cleanup. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Fixed stray UI Combat arrows for finisher/non-target plays. Hand-card selection no longer draws long preview arrows across the scrolled combat area, and non-target finisher plays animate card travel without creating a target arrow. UI smoke now covers both regressions. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Moved UI Combat card travel from broad zone anchors to exact card-panel anchors. Hand and board card panels now get stable `CombatCardPanel_*` anchor names, manual actions capture source/target/destination screen positions before the UI rebuild, and board-layer card ghosts use those saved positions when the original card node disappears. UI smoke now verifies exact hand/unit anchors and finisher movement from rendered hand cards. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Started the Master Duel-style UI Combat layout pass from the paper sketch. UI Combat now uses a compact duel-specific path with hidden footer chrome, smaller board/card slots, left inspect panel, centered arena, opponent hand above the board, player hand below the board, and a middle-right contextual rail containing End Turn and selection actions. Hover inspect now clears unless the card was clicked/pinned. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-15: Added fanned player hand layout and moved End Turn into the board area. UI Combat now overlaps/rotates hand cards in a real-life-style fan, tightens the playmat/card/slot sizes further for one-screen 16:9 comfort, and renders End Turn/contextual actions in a board control strip between opponent and player fields. UI smoke now verifies fanned hand and board-embedded controls. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-16: Hid UI Combat battle feedback behind a top-left Battle Log toggle, compacted the card face content to reduce clutter, widened/uniformed the hand fan, tightened zone/card-back/slot sizing for 16:9 fit, and added UI-only board VFX fallbacks so hidden discard destinations still show heal/draw feedback on the battlefield. Active JSON parse checks plus UI, combat, tournament, Wave 1, and Wave 2 smoke coverage passed.
- 2026-06-16: Started the next concept-art UI slice. UI Combat now anchors the arena inside a canvas-style battlefield and renders card inspect as a translucent left overlay on top of the board, preserving the play area width while keeping hover/click inspect behavior intact. UI and combat smoke coverage passed.
- 2026-06-16: Corrected the concept-art UI Combat layout. Active UI battles now use a compact setup bar, render the board bands in the requested top-to-bottom order, show opponent/player life and focus as side overlays, move End Turn into a smaller middle-right floating control, and keep inspect hidden until a card is clicked/selected. UI smoke, combat smoke, and JSON parse passed.
- 2026-06-16: Polished the near-final UI Combat layout. Lifted the player hand fan upward so cards are less clipped at the bottom, added battlefield background-click dismissal for the pinned inspect overlay, and made card clicks consume input so the overlay does not immediately close. UI smoke, combat smoke, and JSON parse passed.
- 2026-06-16: Tightened UI Combat inspect dismissal and hand placement. Added root-level click-away handling that protects card/inspect/button clicks but clears pinned inspect on empty board clicks, and lifted the player hand fan further inside the play area. UI smoke, combat smoke, and JSON parse passed.
- 2026-06-16: Tuned UI Combat hand proportions. Reduced the opponent hand band height, rendered opponent hand backs in a tighter fan with stable indexed node names for hand-count visibility, and gave the player hand band a fixed taller slot so the fan does not drift downward after actions. UI smoke, combat smoke, and JSON parse passed.
- 2026-06-16: Compressed UI Combat fixed-band sizing for full-board states. Reduced playmat target height, tightened UI-only zone padding, board slots, placeholder cards, and empty slots, and expanded smoke setup to include multiple threats on both boards before rendering. UI smoke, combat smoke, and JSON parse passed.
