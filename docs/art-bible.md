# Road to Worlds Tiny Art Bible

## North Star

Road to Worlds should look and feel like a competitive local card shop season brought to life: glass singles cases, booster displays, trade binders, event slips, deck boxes, sleeves, and a bright store table where animal-themed cards become the focus.

The game should feel cute enough to invite attachment, but grounded enough to preserve the competitive TCG fantasy. The player is not a fantasy spellcaster. The player is a TCG grinder trying to survive locals, regionals, nationals, and Worlds.

## Visual Pillars

1. **Cozy Competitive**
   The shop should feel welcoming, bright, and tactile, but the tournament flow should still feel like records, pairings, pressure, and clean decisions.

2. **Physical Card Culture**
   Menus should borrow from real card-shop objects: binders, booster boxes, singles cases, match slips, card sleeves, deck boxes, price stickers, event calendars, and prize packs.

3. **Animal Faction Identity**
   The game should not read as generic fantasy. Each deck is a recognizable animal faction with its own shape language, colors, and play pattern.

4. **Readable Real TCG Cards**
   Cards should feel like physical cards first and video game UI second. The frame should be clean, scannable, and believable as a printed TCG product.

5. **Cute, Not Silly**
   Animal art can be charming and expressive, but avoid parody, mascot overload, mobile-game exaggeration, and overly goofy proportions.

## What To Avoid

- Too anime.
- Too high fantasy.
- Too silly or meme-like.
- Too glossy/mobile-game.
- Too dark, grim, or muddy.
- Generic fantasy card battler presentation.
- UI that looks like a flat web dashboard instead of a card-shop experience.

## Season Hub Direction

The Season Run menu should become an illustrated local game store hub. Instead of normal menu cards, the shop scene itself contains clickable hotspots.

Primary hotspots:

- **Singles Case**: buy singles.
- **Trade Binders**: collection, trades, and duplicate management.
- **Booster Display**: buy and open packs.
- **Counter / Judge Station**: register for tournament.
- **Event Calendar**: season path, upcoming events, and records.
- **Deck Box**: deckbuilder.
- **Wallet / Register Area**: money and finances.
- **Clipboard Menu**: settings, save/load, and debug tools.
- **Accessory Shelf**: sleeves, playmats, deck boxes, and cosmetics later.

The first implementation can use placeholder illustrated panels and transparent click regions. Final art can replace the background without changing the interaction model.

## Card Frame Direction

Card frames should combine MTG-style structural clarity with Pokemon-style ability separation.

Use MTG-like structure:

- Strong title bar at top.
- Focus cost in the top-right.
- Large art box.
- Clear type line.
- Rules/effect text box.
- Attack and health in bottom corners for threats.
- Small footer for rarity, set, and collector details.

Use Pokemon-like ability treatment:

- Abilities are visually separated from one another.
- Each ability has a short name.
- Focus pips/costs sit directly beside the ability name.
- Passive abilities have a clearly marked passive tag.
- Attacks, activated abilities, and passive text should not collapse into one paragraph.

Example unit layout:

```text
PACK LEADER                                      3

[Animal art]

CANINE | THREAT

[1 Focus] Rally Bite
Give another Canine +1 attack this turn.

[Passive] Pack Tactics
When this attacks, if you control another Canine, draw 1.

ATK 3                                      HP 2
```

## Card Data Needs

The visual card component should support:

- `title`
- `focus_cost`
- `art`
- `animal_type`
- `card_class`
- `rarity`
- `attack`
- `health`
- `ability_blocks`
- `flavor_text`
- `set_code`

Ability block fields:

- `cost`
- `label`
- `kind`
- `text`

Example:

```json
{
  "cost": 1,
  "label": "Rally Bite",
  "kind": "activated",
  "text": "Give another Canine +1 attack this turn."
}
```

## Faction Identity

### Canine Midrange

Role: sturdy board presence, pack bonuses, efficient threats.

Feel: loyal, practical, tactical, reliable.

Visual cues:

- Rounded shield-like frame accents.
- Warm tan, collar red, deep navy, brass.
- Paw, collar tag, and pack-chevron motifs.

### Glires Propagate

Role: small units, token swarms, growth, multiplying resources.

Feel: busy, clever, cozy, overwhelming through numbers.

Visual cues:

- Seed, burrow, notebook, and crumb-trail motifs.
- Soft green, warm cream, seed brown, mint.
- Small repeating shapes and clustered iconography.

### Flightless Birds Aggro

Role: fast threats, early damage, tempo, reckless pressure.

Feel: scrappy, energetic, loud, determined.

Visual cues:

- Beak, feather, sprint mark, and track-lane motifs.
- Rust red, golden yellow, charcoal, bright sky accent.
- Sharp diagonals and forward-leaning card accents.

### Snake Control

Role: removal, delay, debuffs, counterplay, inevitability.

Feel: patient, precise, dangerous, calculating.

Visual cues:

- Coil, scale, fang, and hourglass motifs.
- Deep teal, muted violet, bone white, venom green.
- Thin curved lines and constricting frame elements.

### Insect Revive

Role: graveyard recursion, sacrifice, death triggers, attrition.

Feel: eerie but not horror, industrious, resilient, cyclical.

Visual cues:

- Wing, carapace, hive cell, molting shell motifs.
- Amber, black-brown, moss, pale green.
- Hex patterns and layered shell frame details.

## Palette Candidates

### Palette A: Local Shop Classic

Best for the main shop hub and default UI.

- Charcoal shelf: `#171B22`
- Counter navy: `#213044`
- Paper cream: `#F0E7D2`
- Glass blue: `#8FC7D8`
- Prize red: `#C84E3A`
- Foil gold: `#E2B84C`
- Text ink: `#10141A`

### Palette B: Cozy League Night

Best for warmer season screens and reward moments.

- Deep green table felt: `#1F3B2C`
- Warm wood: `#8B5E3C`
- Receipt paper: `#F6EEDB`
- Sleeve blue: `#355C8A`
- Stamp red: `#B83E3E`
- Soft highlight: `#F4C86A`
- Charcoal text: `#222222`

### Palette C: Glass Case Foil

Best for packs, card reveals, rare pulls, and shop inventory.

- Near black: `#0E1218`
- Case gray: `#2A3038`
- Fluorescent white: `#F2F5EF`
- Foil cyan: `#6EC6D9`
- Foil magenta: `#C75BA3`
- Foil gold: `#E8C15A`
- Sticker orange: `#E46F3C`

Recommended default: use Palette A for the broad UI, Palette B for friendly season moments, and Palette C only for pack/reward excitement.

## Motion And Feedback

- Cards should move like physical objects: slide, slap, flip, fan, and settle.
- Rewards should feel handled: packs slide onto the counter, cards move into a binder, result slips get stamped.
- Combat should remain readable: target lines, card movement, and damage/heal feedback should support decision clarity before spectacle.
- Avoid excessive particle effects unless they represent foil, pack opening, or a rare pull.

## First Implementation Targets

1. Create a Season Hub screen using a placeholder card shop illustration layout.
2. Add clickable hotspot regions for packs, singles, tournament registration, deckbuilder, event calendar, and menu.
3. Restyle event result flow as match slips with win/loss stamps.
4. Build a reusable card frame component that supports ability blocks.
5. Apply faction labels and colors consistently across cards, deckbuilder, opponent intros, and rewards.
