# Topdeck Gameplay Rules

These are the rules used by every live match in Season Run and by the Debug Sandbox's Kitchen Match. Campaign collection, shop, deckbuilding, and tournament progression are described in [Season Loop](season-loop.md).

## Objective and Setup

Reduce the opposing Chef from 20 life to zero.

Each player chooses a deck, shuffles, and draws five cards. The first player begins but skips the draw at the start of their first turn. The second player draws normally on their first turn. On later turns, the active player draws one card; if they then have fewer than two cards in hand, they continue drawing until they have two or their deck is empty. Players also ready their units, reset once-per-turn abilities, and make newly matured Ingredients recipe-ready.

Each side of the table has:

- Three Prep slots
- Two Plated slots
- One Environment slot
- A deck, hand, and discard pile

Ingredients and Meals are both units and share the Prep and Plated slots.

## The Two Unit Zones

Prep is the protected development area. Units in Prep cannot attack and cannot be attacked. Their Prep effects and auras can still operate when their rules text says so.

Plated is the combat line. Only Plated units can attack or be attacked. If a defending player controls a Plated unit, attacks must target a legal Plated defender instead of that player's Chef. Taunt can further restrict which Plated unit must be attacked.

A player may move one friendly unit between Prep and Plated per turn, provided the destination has room. A unit entering Plated can attack that turn. The only exception is that the first player cannot attack during their first turn.

## Playing Cards

Ingredients can be played directly into an open Prep or Plated slot.

Meals require a recipe. To serve a Meal, sacrifice recipe-ready Ingredients that supply every required archetype, then put the Meal into an open unit slot. An Ingredient played this turn does not become recipe-ready until the start of its controller's next turn. Ingredients mature in either unit zone.

Only one Meal may normally be served each turn; Pup Tart raises that limit to two while it remains on the field. There is no general limit on Ingredients or Tools beyond cards, legal targets, and available slots. Only one Chef card may be used each turn.

Dual-type Ingredients may satisfy either of their printed affinities, but one Ingredient can satisfy only one recipe requirement. An either/or recipe requirement likewise needs only one Ingredient of either listed type.

When a card asks for a choice, the game pauses that effect and presents only legal choices. This applies to discard costs, deck searches, discard-pile recovery, board targets, opponent-hand choices, and multi-step effects.

Playing a Meal first opens recipe selection. Choose the highlighted recipe-ready Ingredients on the table, then confirm to sacrifice them and serve the Meal; cancelling leaves the Meal in hand. A Meal may be served into an otherwise full Prep or Plated zone when its recipe sacrifices an Ingredient in that zone. On the Living Table, the Meal occupies the exact slot vacated by the selected Ingredient.

After an effect searches a deck or looks at cards in a deck, that deck is shuffled when the effect finishes. It is shuffled even if no matching card is found or the player chooses not to take a card.

## Combat

Each ready Plated unit may attack once.

1. Choose a ready Plated attacker.
2. Choose a legal opposing Plated defender. If there are none, attack the opposing Chef.
3. The attacker deals its Attack to the defender. The defender simultaneously deals its Attack to the attacker.
4. A unit with damage equal to or greater than its Health is discarded with its attachments.
5. A Plated unit that did not attack on its controller's most recent turn is **Defending**. It stops excess combat damage unless the attacker has Piercing. A unit that attacked is exposed: when it is attacked, damage beyond its remaining Health reaches its Chef using the normal overflow calculation.

**Piercing** cards deal excess combat damage through a Defending unit. **Stalwart** cards may attack the opposing Chef even while opposing Plated units are present. Effects that trigger on combat damage to a Chef require actual combat damage, not effect damage.

## Card Types

- **Ingredient** — a smaller unit that develops a strategy and can later be sacrificed for a Meal.
- **Meal** — a stronger unit served by paying a recipe of mature Ingredients.
- **Tool** — a one-use action card. Some Tools require selected discards, targets, searches, or multiple choices.
- **Spice** — an attachment played onto a friendly unit. Its bonuses and text remain with that unit until removed or the unit leaves play.
- **Environment** — a persistent engine in the Environment slot. Playing another replaces the current one.
- **Chef** — a powerful action card. A player may use one Chef each turn.

Tokens are temporary units rather than collectible cards. If a token would leave Prep or Plated for a hand or discard pile—including by return, sacrifice, destruction, or combat defeat—it evaporates and ceases to exist. Real cards attached to that token still move to their normal destination.

## Common Keywords and Timing

- **Defending** — a Plated unit that did not attack on its controller's last turn. It stops excess combat damage unless hit by Piercing.
- **Piercing** — excess combat damage reaches the opposing Chef when this card overpowers a Defending unit.
- **Stalwart** — this card may attack the opposing Chef through Plated defenders.
- **Taunt** — while Plated, this unit must be attacked before other legal Plated units.
- **On play** — resolves after the card enters play normally. A card put into play by another effect may explicitly skip it.
- **On sacrifice** — resolves when the card is sacrificed, including as a Meal ingredient.
- **While in Prep / while Plated** — operates only in the named zone.
- **Once per turn** — refreshes at the start of that card's controller's turn.
- **This turn** — expires at the end of the current turn.

## Current Card Pool

The public demo data catalog contains 87 collectible cards:

- 30 Ingredients
- 23 Meals
- 15 Tools
- 5 Spices
- 5 Environments
- 9 Chefs

Spicy, Hearty, and Sweet each have a deliberate 20-card starter deck. Fresh and Funky remain represented in the draft-ready card pool through mono- and dual-affinity cards.

## Controls

Cards expose buttons for every legal action. Drag-and-drop is also supported:

- Drag an Ingredient or Meal from hand to Prep or Plated.
- Drag a friendly unit between Prep and Plated.
- Drag a Spice from hand onto a friendly unit.
- Drag an Environment into the Environment slot.
- Drag a Plated attacker onto a defender or onto the opposing board for a legal Chef attack.

While dragging, legal destinations brighten and unavailable destinations dim. An invalid drop returns the card to its source and displays the relevant placement reminder. Ready attackers use green status treatment, selected attackers and legal targets use gold treatment, and the active board and turn owner are called out at the top of the match.

Inspect controls open a card popout with live stats, recipe requirements, attachments, and whether its zone-dependent effects are active.
