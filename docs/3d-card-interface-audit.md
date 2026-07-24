# 3D Card Interface Audit — 2026-07-22

## Outcome

All 89 playable cards build as physical 3D cards and have a functional rules/presentation route. The repeatable audit runner passes every catalog, renderer, recipe, activated-ability, target-selection, search, discard, reaction, and complex-effect check.

- 89/89 playable cards pass the 3D compatibility audit.
- 83 cards use authored frames; 6 use the valid fallback face.
- 36 distinct effect operations are recognized by the production rules service.
- 28/28 Meals open and complete the Ingredient-selection recipe flow.
- 12 search cards route to the full-card deck tray.
- 4 discard-pile choice cards route to the full-card discard tray.
- 7 discard-cost Items use physical hand-card selection.
- 14 board-target cards expose legal highlighted 3D targets.
- 8 activated abilities resolve or expose legal highlighted targets.
- 5 reaction cards resolve through the reaction window.
- The existing 19 complex-card production scenarios all pass.

## Findings

1. **No gameplay blockers found.** Every authored card has a legal 3D play and resolution path.
2. **Six cards use fallback faces.** These are the Spices and Environments; they remain fully playable, but need supplied frame families to match the authored card presentation.
3. **Reaction windows are functional but still generic.** The five reaction cards appear in a centered Use/Pass overlay rather than using the physical hand directly.
4. **Tongs is functional but still generic.** Its opponent-hand choice uses card-name buttons rather than full card faces.
5. **One schema-maintenance risk remains.** `hand_trap_guard_zone` is authored on Tempeh Tapir, while the resolver currently enforces the present Plated behavior structurally rather than reading that field generically. The current card works; a future guard with a different zone would need resolver work.

## Interaction coverage

| Interaction | Cards | 3D presentation | Result |
|---|---:|---|---|
| Meals / recipes | 28 | Physical Ingredient highlighting, Confirm/Cancel status controls | Pass |
| Deck searches | 12 | Full-card deck tray | Pass |
| Discard-pile choices | 4 | Full-card discard tray | Pass |
| Discard costs | 7 | Physical hand selection | Pass |
| Board target effects | 13 | Highlighted physical cards with bottom instructions | Pass |
| Activated abilities | 8 | Immediate resolution or highlighted target selection | Pass |
| Reactions | 5 | Centered Use/Pass overlay | Pass; presentation follow-up |
| Opponent-hand selection | 1 | Centered card-name overlay | Pass; presentation follow-up |

## Card-by-card matrix

| # | Card | Type | 3D interaction path | Result |
|---:|---|---|---|---|
| 1 | Sriracharrow | Meal | Recipe selector | Pass |
| 2 | Firecracker Shrimp | Meal | Recipe selector, Highlighted board target | Pass |
| 3 | Vindaloo Beluga | Meal | Recipe selector, Highlighted board target, Activated target | Pass |
| 4 | Hot Pot Panda | Meal | Recipe selector | Pass |
| 5 | Buffalo Wings | Meal | Recipe selector | Pass |
| 6 | Dumpling-Backed Tortoise | Meal | Recipe selector | Pass |
| 7 | Stewoose | Meal | Recipe selector | Pass |
| 8 | Bison Burrito | Meal | Recipe selector | Pass |
| 9 | Mastiff Potato | Meal | Recipe selector | Pass |
| 10 | Polar Pot Pie Bear | Meal | Recipe selector, Activated action | Pass |
| 11 | Pup Tart | Meal | Recipe selector | Pass |
| 12 | Strawberry Sharkcake | Meal | Recipe selector | Pass |
| 13 | Donutphin | Meal | Recipe selector | Pass |
| 14 | Pandacake | Meal | Recipe selector | Pass |
| 15 | Cinnamon Snail | Meal | Recipe selector | Pass |
| 16 | Parfait Parrot | Meal | Recipe selector | Pass |
| 17 | Gravy Gazelle | Meal | Recipe selector, Highlighted board target, Activated target | Pass |
| 18 | Harvest Hydra | Meal | Recipe selector | Pass (fallback face) |
| 19 | Garden Gorilla | Meal | Recipe selector | Pass (fallback face) |
| 20 | Saladmander | Meal | Recipe selector | Pass (fallback face) |
| 21 | Pepper Pike | Meal | Recipe selector, Highlighted board target, Activated target | Pass |
| 22 | Meatloaf Mole | Meal | Recipe selector | Pass |
| 23 | Broth Buffalo | Meal | Recipe selector, Highlighted board target, Activated target | Pass |
| 24 | Relish Raccoon | Meal | Recipe selector, Activated target | Pass (fallback face) |
| 25 | Limburger Lynx | Meal | Recipe selector, Discard tray | Pass (fallback face) |
| 26 | Bottomless Trifle Tern | Meal | Recipe selector | Pass |
| 27 | Pudding Puma | Meal | Recipe selector | Pass |
| 28 | Tempeh Tapir | Meal | Recipe selector | Pass (fallback face) |
| 29 | Hot Honey Bee | Ingredient | Automatic / triggered effect | Pass |
| 30 | Jalapeño Panther | Ingredient | Direct / passive play | Pass |
| 31 | Red Pepper Panda | Ingredient | Direct / passive play | Pass |
| 32 | Wastabi | Ingredient | Automatic / triggered effect | Pass |
| 33 | Jakapeno | Ingredient | Deck-search tray, Activated action | Pass |
| 34 | Peppercupine | Ingredient | Deck-search tray | Pass |
| 35 | Harebanero | Ingredient | Automatic / triggered effect | Pass |
| 36 | Ghost Pepython | Ingredient | Automatic / triggered effect | Pass |
| 37 | Chili Cicada | Ingredient | Highlighted board target | Pass |
| 38 | Beet Beetle | Ingredient | Automatic / triggered effect | Pass (fallback face) |
| 39 | Salad Shield Skunk | Ingredient | Direct / passive play | Pass (fallback face) |
| 40 | Chutney Chinchilla | Ingredient | Reaction window | Pass (fallback face; generic reaction overlay) |
| 41 | Pantry Pouncer | Ingredient | Reaction window | Pass (generic reaction overlay) |
| 42 | Tamari Toad | Ingredient | Reaction window | Pass (fallback face; generic reaction overlay) |
| 43 | Ability Axolotl | Ingredient | Reaction window | Pass (generic reaction overlay) |
| 44 | Comeback Cucumber Corgi | Ingredient | Reaction window | Pass (fallback face; generic reaction overlay) |
| 45 | Crisp Capybara | Ingredient | Direct / passive play | Pass (fallback face) |
| 46 | Sprout Squirrel | Ingredient | Automatic / triggered effect | Pass (fallback face) |
| 47 | Feta Ferret | Ingredient | Direct / passive play | Pass (fallback face) |
| 48 | Pickled Turnip Turtle | Ingredient | Activated action | Pass (fallback face) |
| 49 | Bagver | Ingredient | Automatic / triggered effect | Pass |
| 50 | French Bread Dog | Ingredient | Direct / passive play | Pass |
| 51 | Macaronatee | Ingredient | Direct / passive play | Pass |
| 52 | Ramen | Ingredient | Highlighted board target | Pass |
| 53 | Baked Potangolin | Ingredient | Highlighted board target | Pass |
| 54 | Lentils | Ingredient | Deck-search tray | Pass |
| 55 | Bacon | Ingredient | Highlighted board target | Pass |
| 56 | Kwhale | Ingredient | Automatic / triggered effect | Pass |
| 57 | Sugar Glider | Ingredient | Automatic / triggered effect | Pass |
| 58 | Marshmallow Swallows | Ingredient | Direct / passive play | Pass |
| 59 | Choco Bat | Ingredient | Automatic / triggered effect | Pass |
| 60 | Toffee Collie | Ingredient | Automatic / triggered effect | Pass |
| 61 | Nutmeg | Ingredient | Direct / passive play | Pass |
| 62 | Vanilla Extract Gorilla | Ingredient | Automatic / triggered effect | Pass |
| 63 | Soft Serve Crab | Ingredient | Deck-search tray | Pass |
| 64 | Jellyfish | Ingredient | Highlighted board target | Pass |
| 65 | Spicy Shopping List | Tool | Hand discard cost, Deck-search tray | Pass |
| 66 | Sweet Shopping List | Tool | Hand discard cost, Deck-search tray | Pass |
| 67 | Hearty Shopping List | Tool | Hand discard cost, Deck-search tray | Pass |
| 68 | Fresh Shopping List | Tool | Hand discard cost, Deck-search tray | Pass |
| 69 | Funky Shopping List | Tool | Hand discard cost, Deck-search tray | Pass |
| 70 | Recipe Prep | Tool | Hand discard cost, Deck-search tray | Pass |
| 71 | Blow Torch | Tool | Highlighted board target | Pass |
| 72 | Tool Drawer | Tool | Deck-search tray | Pass |
| 73 | Tongs | Tool | Opponent-hand choice | Pass (generic opponent-hand overlay) |
| 74 | Strainer | Tool | Discard tray | Pass |
| 75 | Hand Mixer | Tool | Highlighted board target | Pass |
| 76 | Switchblade | Tool | Two highlighted board targets | Pass |
| 77 | Grater | Tool | Highlighted board target | Pass |
| 78 | Measuring Cup | Tool | Hand discard cost, Discard tray | Pass |
| 79 | Wooden Spoon | Tool | Automatic / triggered effect | Pass |
| 80 | Cayenne Crunch | Spice | Field-card Spice target | Pass (fallback face) |
| 81 | Savory Gravy | Spice | Field-card Spice target | Pass (fallback face) |
| 82 | Sugar Glaze | Spice | Field-card Spice target | Pass (fallback face) |
| 83 | Blazing Wok | Environment | Environment zone | Pass (fallback face) |
| 84 | Slow Cooker | Environment | Environment zone | Pass (fallback face) |
| 85 | Dessert Display | Environment | Environment zone | Pass (fallback face) |
| 86 | Chef Carmy | Chef | Direct Chef action | Pass |
| 87 | Chef Rachel | Chef | Deck-search tray, Direct Chef action | Pass |
| 88 | Chef Ramsey | Chef | Discard tray, Direct Chef action | Pass |
| 89 | Chef Giada | Chef | Direct Chef action | Pass |

## Repeatable verification

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --audio-driver Dummy --rendering-method gl_compatibility -s res://scripts/ThreeDCardInterfaceAudit.gd
```

The audit fails on catalog-count drift, unsupported effect operations, broken physical 3D faces, unsatisfiable recipe prompts, invalid activated-ability targets, missing board-choice highlights, broken trays/overlays, or a regression in the 19 complex-card scenarios.
