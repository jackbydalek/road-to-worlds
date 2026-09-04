# Development Status

## Playable Now

- Mouse-driven seeded Starter City route run and direct Debug Menu entry paths
- Spicy, Hearty, and Sweet compact 15-card run starters
- Persistent 40-life run health and encounter-specific rival life
- Branching Enemy, Shop, Event, mandatory Miniboss, and Floor Boss nodes
- Saved route graph, seed, position, visited/resolved nodes, pending encounter, deck, life, and currency
- Three/five/eight-card reward reveals that allow taking any or all offered cards
- Route shops with healing, card removal, and direct-to-deck purchases; authored event choices
- Escalating 3/5/7 reshuffle-pressure damage and three-card later-turn refill in route battles
- Easy, Medium, Hard, and two-ply Expert AI with progressively upgraded legal decks from Locals through later championships
- Save and load for the active route run, including interrupted matches
- Clickable 3D card-store overworld with in-scene singles, trade-binder, and meta-analysis overlays plus a persistent top-right wallet/calendar/deck/settings HUD
- Five-card boosters, affinity-focused tournament prize packs, individual reveals, and collection updates
- Collection-aware deckbuilder with sideboard functionality retained in Debug mode
- One-screen Season deck editor with internally scrolling collection and main-deck lists; sideboard UI is hidden for the demo
- Metagame reports and weighted rival archetypes
- Living Table as the sole runtime combat renderer for route encounters, resumed battles, legacy Debug tournaments, and practice
- Quick tournament simulation in Debug mode
- Sudden-death three-round tournament entry, records, rewards, prize flow, and calendar unlocks
- Circle-wipe round introductions, 3D tournament combat, game-over, and Thanks for Playing screens
- Complete Prep/Plated match rules, AI, effects, selection, inspection, and drag-and-drop
- Deterministic combat animation-event queue for draws, plays, zone moves, searches, sacrifices, healing, buffs, destruction, attacks, and grouped multi-hit effects
- Cached card-face textures with redraw-on-change viewports, so static faces render once and animated artwork redraws only at its authored frame rate
- Collapsible battle history, full-card deck-search/discard trays, and 3D deck, shared discard, Environment, and Spice attachment presentation on the Living Table
- Debug Card Effect Lab with controlled before/after scenarios for all 19 expansion effects

## Content

The public Kitchen demo catalog contains 87 collectible cards:

- 30 Ingredients
- 23 Meals
- 15 Tools
- 5 Spices
- 5 Environments
- 9 Chefs

Campaign rarity is derived from card type and the existing rare flag so boosters and singles work without maintaining a second card catalog.

## Next Product Work

1. Playtest full Starter City runs and tune persistent health, rival life, reshuffle pressure, and route length.
2. Give regular rivals, the local champion, and city champion more distinct authored identities and telegraphed modifiers.
3. Promote more authored city blocks, landmarks, and decorations into the overworld scene.
4. Polish reward-pack reveals and battle-to-map transitions.
5. Tune the three 15-card starter lists and reward weighting.
6. Add route, persistent-health, and reshuffle-pressure onboarding.

The current codebase keeps the reusable campaign scaffold while excluding the former fish card content and combat implementation.
