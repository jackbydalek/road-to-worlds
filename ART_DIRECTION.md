# Topdeck to Worlds — Visual Direction

This is the reference for UI, environment, character, card-frame, and promotional-art decisions. The target is a bright, welcoming illustrated card café: soft pastel color blocking, expressive navy linework, warm daylight, glassy paper-like controls, and small playful details. It should feel cozy and contemporary, never like a dark arcade or a closed shop.

## Core palette

| Role | Color | Use |
|---|---:|---|
| Primary ink | `#29365F` | Character silhouettes, panel borders, important text, icons |
| Secondary ink | `#53628A` | Interior lines and secondary copy |
| Cream | `#FFF7F1` | Primary screen and panel surface |
| Lavender glass | `#E8E3F5` | Secondary controls and quiet panels |
| Coral | `#EF7E76` | Primary actions and warm emphasis |
| Blush | `#F2A4B8` | Friendly highlights and opponent/warm zones |
| Periwinkle | `#8EA9E6` | Navigation, selection, and cool panels |
| Sky | `#68C5E8` | Hover, focus, and player-side highlights |
| Soft yellow | `#D8B35F` | Fresh cards, stickers, and small warm accents |

Use `scripts/ui/GamePalette.gd` as the code-level source of truth. Avoid pure black and pure white when a palette color can do the job.

## Affinity and tag colors

| Identity | Color |
|---|---:|
| Spicy | `#C96C60` |
| Hearty | `#82966F` |
| Sweet | `#8299D0` |
| Fresh | `#D8B35F` |
| Funky | `#9A6EAE` |
| Neutral / utility | `#A69AB7` |
| Spices tag | `#B56B5A` |
| Environments tag | `#4F777C` |

Affinity colors identify cards and small accents. They should not become large competing UI backgrounds.

## Linework

- Use `#29365F` for exterior silhouettes and important boundaries.
- Use `#53628A` for interior details.
- Use periwinkle for faint decorative rules.
- Character and prop silhouettes should remain visible at gameplay camera distance, generally around 2–4 screen pixels.
- Avoid pure-black outlines and neon glows.

## UI language

- Primary surfaces are cream; secondary work areas may use very pale lavender or blush.
- Utility workspaces use the responsive pastel background shader rather than the paper texture: cream center with very soft lavender, blush, and sky edge fields.
- Panels use a 2 px navy border, 12–16 px corner radius, and a restrained soft shadow.
- Primary actions are coral with navy text and border.
- Secondary actions are translucent lavender with periwinkle or navy borders.
- Selected states use sky or periwinkle, not dark fills.
- Keep card artwork saturated and readable; surrounding UI should be quieter.
- Use color for hierarchy, not decoration on every element.

## Environments and lighting

- Stage scenes as welcoming daytime or warmly lit indoor spaces.
- Favor cream walls, pale wood, lavender/blush textiles, plants, and small café details.
- Shadows should ground objects without turning the room purple or black.
- Reserve deep navy for linework, small structural elements, and readable contrast—not broad ambient darkness.

## Character treatment

- Simplified, readable shapes with pastel blocks and navy silhouettes.
- Use limited cel-style shading rather than realistic gradients.
- Preserve readable faces and poses at the actual gameplay camera scale.
- Lighting should be neutral and flattering; do not place colored spotlights directly on characters.

## Guardrails

- Do not return to the former dark-purple/nighttime presentation.
- Do not cover the entire UI in faction colors.
- Do not recolor finished card illustrations globally; update frames, accents, or individual assets intentionally.
- Reference the user-supplied artwork for high-level qualities such as palette, line weight, shape language, and softness. Do not copy another artist's characters or compositions.
