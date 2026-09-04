# Competitive gameplay trailer captures

Run `scripts/release/capture_trailer_clips.sh` to create twelve cursor-free,
1440×900, 30 fps high-quality H.264 `.mov` clips with game audio in
`builds/trailer-clips-competitive/`.

The helper requires Godot at `/Applications/Godot.app` and `ffmpeg` on the
shell path. On macOS, install the converter with `brew install ffmpeg`. To
recapture only one shot, pass the output directory and clip ID, for example:

```bash
scripts/release/capture_trailer_clips.sh builds/trailer-clips-competitive 10_upgrade_foil
```

## Numbered shot list

1. `01_combat_hook.mov` — immediate dotted attack targeting and a direct hit.
2. `02_title.mov` — current logo, title pattern, and swirling real game cards.
3. `03_choose_competitor.mov` — Spicy, Hearty, and Sweet competitor selection.
4. `04_route_decision.mov` — Starter City, full-map reveal, and route selection.
5. `05_rival_challenge.mov` — rival entrance, dialogue, Continue, and battle wipe.
6. `06_control_the_table.mov` — animated cyan switch arrow and a zone swap.
7. `07_battle_combo.mov` — activated ability, buff, unit attack, and direct hit.
8. `08_reward_pack.mov` — three finished cards, selection, and collection.
9. `09_shop_deckbuild.mov` — shop display, Sriracharrow selection, and purchase.
10. `10_upgrade_foil.mov` — picker, white flash, shake, and foil reveal.
11. `11_city_champion.mov` — champion entrance and final-city challenge.
12. `12_logo_end_card.mov` — centered clean logo and swirling game cards, without menus.

Each shot starts and ends on a short carbon fade, has no cursor, uses a fixed
seed, and does not reference the known generated concept/marketing folders.
The native 16:10 frame preserves the complete game UI. Edit in a 1920×1080
timeline and scale/reframe each shot rather than stretching it. A full-width
reframe crops about 45 source pixels from both the top and bottom.

## Recommended 58-second cut

| Timeline | Source | Use | On-screen copy |
| --- | --- | --- | --- |
| 00:00–00:03 | 01 | Arrow acquires the chef, release, impact | `A FULL TACTICAL CARD GAME` |
| 00:03–00:05 | 02 | Logo and card swirl | None |
| 00:05–00:09 | 03 | Cycle all three competitors | `CHOOSE YOUR PLAYER` |
| 00:09–00:14 | 04 | City view to map to selected route | `CHOOSE YOUR PATH` |
| 00:14–00:19 | 05 | Rival slide-in through battle wipe | `FACE NEW RIVALS` |
| 00:19–00:22 | 06 | Cyan target lock and zone swap | `CONTROL THE TABLE` |
| 00:22–00:32 | 07 | Ability, buff, unit attack, direct hit | `BUILD. POSITION. OUTPLAY.` |
| 00:32–00:37 | 08 | Pack reveal and card collection | `BUILD YOUR DECK` |
| 00:37–00:42 | 09 | Select and buy Sriracharrow | None |
| 00:42–00:46 | 10 | Use roughly 00:02.3–00:04.7 around the upgrade flash | `POWER UP KEY CARDS` |
| 00:46–00:50 | 11 | Champion entrance and challenge | `BECOME CITY CHAMPION` |
| 00:50–00:53 | 07 | Reuse only the final direct hit | None |
| 00:53–00:58 | 12 | Clean centered logo | `WISHLIST NOW` |

Cut on drum accents and use mostly hard cuts. Keep the rival's in-game wipe as
the one prominent transition. Let the battle sequence breathe longer than the
menus: it is the proof that the game is a complete tactical card game, not an
autobattler. Keep the copy large, brief, and below the logo-safe area.

Use competitive jazz-funk, breakbeat, or hip-hop instrumentation around
120–145 BPM. Start with a hit on the first attack release, thin the arrangement
under the map and rival dialogue, then bring the full beat back on the battle
wipe. Preserve the attack, placement, pack, purchase, and foil sounds; duck the
music by roughly 4–6 dB around major impacts.

Export a 1920×1080, 30 fps H.264 master at 20 Mbps or higher with AAC audio.
Also keep a high-quality mezzanine master if the editor supports ProRes.

The project-owner provenance attestation in
`docs/shipping-asset-provenance.md` must be confirmed before these clips are
published. Do not mix in any capsule or concept files from `assets/marketing/`
or `outputs/`.
