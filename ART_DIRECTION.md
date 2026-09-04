# TOP CUT: Locals to Worlds — Visual Direction

This is the source of truth for UI, environment, character, card-frame, and promotional-art decisions. The game should feel like a finished, expressive card-game adventure: clear color blocking, readable silhouettes, tactile controls, lively locations, and deliberate graphic details. The world supports a journey from local matches to increasingly spectacular championships; no single venue or asset pack defines the game's identity.

Legacy shop scenes, warm pastel palettes, and licensed asset-pack names are implementation history, not art direction. Do not use them to infer the target look.

## UI color north star — Pokémon Black and White

For interface color design, the primary north star is the Nintendo DS-era UI language of **Pokémon Black and White**, especially the user-provided menu, options, and battle references. Borrow its color logic and confidence, not its protected assets or exact layouts.

The qualities to carry forward are:

- A near-black and cool-gray structural chassis that makes information feel crisp and intentional.
- Bright white text and keylines against dark surfaces, with cyan edge light used sparingly for focus.
- One strong saturated accent per control or category: electric blue, cyan, red, magenta, green, yellow, or violet.
- Immediate selected/unselected contrast. A selected control changes its fill, edge, and text hierarchy rather than receiving only a faint tint.
- Large, clean color blocks and decisive value steps instead of many similar pastels.
- Angular silhouettes, clipped corners, diagonal color cuts, and graphic inset shadows.
- Smooth modern rendering. Do **not** imitate DS pixelation, low resolution, bitmap stair-stepping, or copied Pokémon assets.

This reference governs UI color, contrast, hierarchy, and state language. TOP CUT: Locals to Worlds should still use its own typography, iconography, card art, characters, and worldbuilding.

## Target UI palette

| Role | Color | Use |
|---|---:|---|
| Carbon | `#12161C` | Deepest UI backing, outer silhouettes, modal dimming |
| Graphite | `#252B33` | Default buttons, panel headers, inactive controls |
| Steel | `#4A535F` | Secondary surfaces, dividers, disabled structures |
| Cool white | `#F3F6FA` | Primary text, light surfaces, high-contrast keylines |
| Electric cyan | `#26C7ED` | Focus edge, hover flash, player-side energy |
| Selection blue | `#168AC3` | Selected navigation, active tabs, primary cool actions |
| Signal red | `#EF3655` | Danger, attack, opponent pressure, destructive actions |
| Emerald | `#21C77A` | Confirmed choices, valid states, success |
| Signal yellow | `#F2D33D` | Rewards, warnings, scarce highlights |
| Interface violet | `#7258C7` | Special actions and occasional secondary-category emphasis |

Aim for roughly 75–85% neutral structure and 15–25% colored emphasis on a typical screen. Multiple accents may appear in a menu, but each control should have one dominant identity. Do not wash entire screens in one faction color.

`ART_DIRECTION.md` owns the target color logic. UI code should consume shared tokens from `scripts/ui/GamePalette.gd` rather than introducing isolated literals. When the existing palette conflicts with this target, migrate the shared palette deliberately; do not treat legacy warm constants as design authority.

The implementation contract for shared typography, spacing, components, and
screen migration is documented in `docs/visual-system-production.md`. That file
implements this direction and does not supersede it.

## Affinity and tag colors

| Identity | Color |
|---|---:|
| Spicy | `#EF3D56` |
| Hearty | `#45B96B` |
| Sweet | `#4E8FE8` |
| Fresh | `#F2D33D` |
| Funky | `#A85ED5` |
| Neutral / utility | `#89929F` |
| Spices tag | `#E36B3E` |
| Environments tag | `#24AFA7` |

Affinity colors identify cards, icons, status chips, and local accents. They should remain vivid and distinct without becoming broad competing backgrounds.

## Linework and geometry

- Use carbon for exterior silhouettes and important boundaries.
- Use steel or cool gray for interior structure and secondary divisions.
- Use cool white or cyan for the active edge, never around every object at once.
- Favor asymmetric clipped corners, shallow chamfers, diagonal wedges, inset frames, and offset graphic shadows.
- Keep vectors and curves smooth at native resolution; angular does not mean pixelated.
- Character and prop silhouettes should remain visible at gameplay camera distance, generally around 2–4 screen pixels.
- Avoid indiscriminate neon glow. Accent light should be a thin, controlled signal.

## UI language

- Default controls are graphite or cool gray with cool-white labels and strong dark silhouettes.
- Selected navigation uses a blue or cyan fill, bright keyline, and clear text-value shift.
- Confirm and valid states use emerald; danger and attack use red; warnings and rewards use yellow; special actions may use violet.
- Panels may mix dark structural headers with light content areas, echoing the high-contrast black/white rhythm of the reference UI.
- Use 2–3 px borders, clipped or 4–8 px corners, and a short hard-edged shadow. Avoid soft floating cards with large pill-shaped radii.
- Use diagonal overlays or a second tone within large buttons to create depth without glossy gradients.
- Keep card artwork saturated and readable. The surrounding interface should frame it with neutral structure and selective accent color.
- Color communicates action class, ownership, state, and hierarchy—not decoration on every element.
- Hover, pressed, focused, selected, disabled, and invalid states must remain distinguishable in both color and value.

### Angular does not mean futuristic

The interface should read as a bold handheld-era game menu before it reads as
technology. Pokémon Black and White's confident black/white blocking, large
plain symbols, simple category rails, and unmistakable selection states are the
closer reference. Angular cuts provide rhythm and hierarchy; they are not a
reason to add science-fiction decoration.

- Prefer solid carbon, graphite, cool-white, and pale-gray blocks over
  translucent glass or layered dark panels.
- Keep cyan mostly for the current selection, focus, or player-side action. A
  resting screen should not be ringed by cyan.
- Use one structural outline and one local accent mark. Avoid nested luminous
  keylines around every panel and button.
- Do not use decorative grids, scanlines, circuit patterns, holographic bloom,
  or neon perimeter glow in ordinary menus.
- Favor large readable labels and familiar symbols over dense dashboard copy,
  tiny telemetry labels, or technical ornament.
- Diagonal wedges should look printed or graphic, with flat value changes—not
  like reflective glass.

## Environments and lighting

- Stage scenes as readable daytime, evening, or indoor competitive spaces appropriate to the current stop on the journey.
- Favor location-specific architecture, street furniture, plants, match tables, spectators, signage, and card-game details.
- World color may be warmer and more illustrative than the UI, but HUD overlays should retain the cool neutral chassis and decisive accent system.
- Shadows should ground objects without swallowing silhouettes or tinting the entire scene purple.

## Character treatment

- Use simplified, readable shapes with bold local color and strong silhouettes.
- Favor limited cel-style shading over realistic gradients.
- Preserve readable faces and poses at the actual gameplay camera scale.
- Lighting should be neutral and flattering; do not place colored spotlights directly on characters.

## Guardrails

- Do not use the former warm/pastel palette as the default UI identity.
- Do not reduce the Pokémon reference to pixel art, Poké Ball motifs, copied icons, copied typography, or literal screen recreations.
- Do not turn the dark neutral chassis into generic sci-fi glass, cyberpunk neon, or an alpha-build developer dashboard.
- Do not cover the entire UI in affinity colors.
- Do not recolor finished card illustrations globally; update frames, accents, or individual assets intentionally.
- Reference outside artwork for high-level qualities such as palette logic, contrast, line weight, shape language, and energy. Do not copy another artist's characters, compositions, branded symbols, or protected interface assets.
