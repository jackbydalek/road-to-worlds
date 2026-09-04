# Starter City Run Loop

## Starting a Run

Choose a compact 15-card **Spicy**, **Hearty**, or **Sweet** starter. The run begins at the local card shop landmark with 40 persistent life and a saved route seed.

- **Spicy** — pressure, direct damage, and aggressive Plated units
- **Hearty** — durable units, healing, and resilient Meals
- **Sweet** — draw, disruption, and Prep-based support

The public flow is now the branching Starter City run. The older calendar, repeated card-store hub, border difficulties, and three-round tournaments remain only as reusable legacy/debug systems.

## Choosing a Route

The illustrated 2.5D map is generated from a saved seed. Choose only among connected destinations and do not return to completed stops. The run saves the graph, current stop, visited and resolved stops, pending encounter, life, deck, currency, and rewards.

Starter City contains:

- **Enemy** — a normal Kitchen Match against a 12-life rival using Medium AI
- **Shop** — buy a card directly into the run deck, heal 9 life, or remove a card
- **Event** — choose between an immediate recovery or economy benefit
- **Miniboss** — the mandatory 18-life local champion using Hard AI
- **Floor boss** — the mandatory 28-life city champion using Expert AI

Arriving commits the player to that stop. The next route choices remain locked until its encounter or reward is resolved.

## Persistent Health and Battles

The player enters each match with their current run life, up to a maximum of 40. Remaining life after a victory carries back to the route. Reaching zero life or forfeiting ends the run.

Route battles retain the existing Kitchen Match rules with two run-specific changes:

- At the start of later turns, draw one card and then refill to three when below three.
- When an empty deck has a discard pile, reshuffle it and take 3 damage on the first reshuffle, 5 on the second, and 7 on later reshuffles. This counter resets each match.

## Deck Growth and Rewards

Route decks must contain at least 1 card, with no maximum size and no per-card copy limit. Cards enter the deck through rewards and shop purchases; the ordinary deck view does not allow free removal or collection swapping.

- Regular enemy: reveal 3; take any or all
- Miniboss: reveal 5 with better rarity weighting; take any or all
- Floor boss: reveal 8 with rare/high-impact weighting; take any or all

Offers strongly favor the chosen starter affinity, while neutral and occasional off-affinity cards preserve discovery. The player may skip a reward. Shops provide the explicit opportunity to remove a card, and never allow the deck below 1.

## Demo Endpoint

Defeating the Starter City champion completes the run and reveals Cloud City as the next destination. Cloud City and Celestial City remain future acts.
