# Authored Asset Needs

This is the remaining art handoff after the code-only production UI pass. None
of these items blocks the shop services, route events, battle UI, settings, or
Deck Workshop from functioning. They replace the few deliberate placeholders
that code-native geometry and licensed generic icons should not impersonate.

## Priority 0 — visible in the current starter experience

### Sweet starter character set

The Sweet starter still uses a procedural placeholder. Please supply:

- `sweet_player_idle.png` — 592 × 941, transparent background
- `sweet_player_walk.png` — 592 × 941, transparent background
- `sweet_player_victory.png` — 592 × 941, transparent background
- `sweet_player_portrait.png` — 512 × 512, transparent or simple pale ground

Match the supplied Spicy and Hearty pose framing: bold exterior contour,
limited cel shading, expressive face, readable hands, and a small Sweet-blue
identity accent. Keep the rendering graphic and handheld-game-like rather than
glossy anime, neon, or futuristic.

### Switchblade card art

`item_switchblade` appears in the current Hearty starter and has no authored
art. A single 512 × 384 PNG is enough; six same-size frames are welcome if the
motion is intentionally authored.

## Priority 1 — route rewards and deck discovery

The following cards currently fall back to `art_pending.png`. For each card,
the minimum handoff is one 512 × 384 PNG with the subject centered in the safe
middle 80%. The runtime can also accept six `frame_00.png`–`frame_05.png`
images for a short idle loop.

### Creatures and meals

- `funky_fondue_ferret` — Feta Ferret
- `spicy_funky_jambaye_aye` — Jambaye-aye
- `spicy_funky_relishoon` — Relishoon
- `funky_sweet_pika_le` — Pika-le
- `sweet_pudding_puma` — Pudding Puma
- `fresh_spicy_yolke_bowl` — Yolke Bowl
- `spicy_funky_arrabbeta` — Arrabbeta
- `spicy_hot_sauchuar` — Hot Sauchuar

### Tools, Chefs, environments, and Spices

- `chef_gusteau`, `chef_brown`, `chef_duff`, `chef_emril`
- `item_fresh_shopping_list`, `item_funky_shopping_list`, `item_blow_torch`
- `environment_spicy_taqueria`, `environment_hearty_diner`
- `environment_sweet_bakery`, `environment_funky_pickle_stand`
- `environment_fresh_greensweet`
- `spice_cayenne_crunch`, `spice_savory_gravy`, `spice_sugar_glaze`
- `spice_funky_brine`, `spice_fresh_balsamic`

For non-creature cards, favor one iconic object or place silhouette over a
busy scene. The card frame already supplies the angular system and affinity
color, so the illustration does not need neon edge lighting or interface-like
details.

## Priority 2 — authored encounter identity

### Route-event vignettes

The seven event outcomes currently share the authored `!` route symbol. Seven
portrait-oriented 768 × 1024 vignettes would give each event its own identity:

- Restorative snack / heal
- Veteran routine / maximum-life increase
- Side-event organizer fee / gain money
- Distracted crowd / lose money
- Deck check / forced card removal
- Risky tune-up / card upgrade with damage
- Friendly trader / one-for-one card exchange

Use one character interaction and one clear prop in each vignette. A pale,
printed background is preferable to a fully rendered cinematic scene.

### Route shop portrait

Supply one 768 × 1024 proprietor-at-the-counter portrait for the route shop.
The existing proprietor concepts are more rendered than the current card and
character language, so the production portrait should use the same bold line,
two-shade treatment as the starter cast and avoid holographic cards, glowing
screens, or sci-fi retail details.

### Rival cast

The battle HUD currently reuses starter portraits for some opponents. For each
recurring rival, the useful minimum set is one 512 × 512 portrait and one
592 × 941 transparent full-body pose. A later polish set can add victory and
defeat poses.

### Location backdrops

Park battle art already exists. Matching 2160 × 1620 background plates for the
Starter City sidewalk and waterfront would let battles reflect route location
without relying on color-only environment swaps.

## Delivery notes

- PNG, sRGB, no baked UI frame or text.
- Transparent backgrounds for isolated characters and card subjects.
- Keep important silhouettes away from the outer 10% crop area.
- Preserve carbon/navy outlines and limited cel shading from `ART_DIRECTION.md`.
- Angularity belongs in pose, framing, clothing cuts, props, and panel shapes;
  avoid circuitry, scanlines, neon rim light, holograms, and glossy glass.
