# Development Status

## Playable Now

- Season Run and Debug Sandbox entry paths
- Spicy, Hearty, and Sweet 30-card constructed starters
- Five-event calendar from Weekly Locals through Worlds
- Five difficulty borders with economy, life, opponent, or opening-turn modifiers
- Save and load for the active season
- Singles shop and authored shop scene
- Six-card boosters, prize packs, individual reveals, and collection updates
- Collection-aware deckbuilder and sideboard
- Metagame reports and weighted rival archetypes
- Live Kitchen Table matches for every Season tournament round
- Quick tournament simulation in Debug mode
- Tournament entry fees, records, rewards, season lives, retries, and calendar unlocks
- Complete Prep/Plated match rules, AI, effects, selection, inspection, and drag-and-drop

## Content

The Kitchen catalog contains 61 cards:

- 24 Ingredients
- 15 Meals
- 12 Tools
- 3 Spices
- 3 Environments
- 4 Chefs

Campaign rarity is derived from card type and the existing rare flag so boosters and singles work without maintaining a second card catalog.

## Next Product Work

1. Playtest the complete shop-to-tournament loop and tune income, pack price, entry fees, and reward pacing.
2. Playtest and tune the constructed starter lists and finalize copy limits.
3. Improve card and board art while preserving the current readable inspectors.
4. Add stronger transition feedback between a Kitchen Match, its tournament slip, and the next calendar event.
5. Tune AI deck selection and higher-event opponent upgrades.
6. Add onboarding for both the season economy and Prep/Plated rules.

The current codebase keeps the reusable campaign scaffold while excluding the former fish card content and combat implementation.
