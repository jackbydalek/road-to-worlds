# Development Status

## Playable Now

- Mouse-driven demo Season Run and direct Debug Menu entry paths
- Spicy, Hearty, Sweet, Fresh, and Funky 30-card constructed starters
- Two-event public demo calendar: Weekly Locals and League Cup
- Five difficulty borders with economy, life, opponent, or opening-turn modifiers
- Easy, Medium, and Hard tactical AI that ramps from Locals through the League Cup and later championships
- Save and load for the active season
- Clickable 3D card-store overworld with in-scene singles, trade-binder, and meta-analysis overlays plus a persistent top-right wallet/calendar/deck/settings HUD
- Six-card boosters, prize packs, individual reveals, and collection updates
- Collection-aware deckbuilder with sideboard functionality retained in Debug mode
- One-screen Season deck editor with internally scrolling collection and main-deck lists; sideboard UI is hidden for the demo
- Metagame reports and weighted rival archetypes
- Live Kitchen Table matches for every Season tournament round
- Quick tournament simulation in Debug mode
- Sudden-death three-round tournament entry, records, rewards, prize flow, and calendar unlocks
- Circle-wipe round introductions, 3D tournament combat, game-over, and Thanks for Playing screens
- Complete Prep/Plated match rules, AI, effects, selection, inspection, and drag-and-drop
- Debug Card Effect Lab with controlled before/after scenarios for all 19 expansion effects

## Content

The Kitchen catalog contains 88 collectible cards:

- 36 Ingredients
- 28 Meals
- 14 Tools
- 3 Spices
- 3 Environments
- 4 Chefs

Campaign rarity is derived from card type and the existing rare flag so boosters and singles work without maintaining a second card catalog.

## Next Product Work

1. Playtest the complete shop-to-tournament loop and tune income, pack price, entry fees, and reward pacing.
2. Playtest and tune all five constructed starter lists and finalize copy limits.
3. Improve card and board art while preserving the current readable inspectors.
4. Add stronger transition feedback between a Kitchen Match, its tournament slip, and the next calendar event.
5. Tune AI deck selection and higher-event opponent upgrades.
6. Add onboarding for both the season economy and Prep/Plated rules.

The current codebase keeps the reusable campaign scaffold while excluding the former fish card content and combat implementation.
