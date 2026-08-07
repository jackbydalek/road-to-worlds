# Demo Release Checklist

Version: `0.1.0-demo.1`

## Automated gate

- Run `scripts/release/check_demo.sh` from the project root.
- Require every canonical catalog, gameplay/input, responsive-layout, visual-shell, save-flow, and integration smoke test to pass.
- Require the release Web export to produce non-empty `index.html` and `index.pck` files.
- Keep the complete Web bundle at or below the automated 180 MiB ceiling; investigate any increase rather than raising the limit casually.
- Do not ship new or renamed cards unless the locked 87-card manifest in `CanonicalCatalogSmokeTest.gd` is intentionally updated from the project owner's source list.

## Manual browser pass

- Test 1280×720, 1440×900, and 1920×1080 in Chrome and Firefox.
- Test browser zoom at 100% and 125%; no primary action may require hidden scrolling.
- Complete the tutorial using mouse input only.
- Complete one match using both click and drag interactions: play a card, move Prep to Plated, activate an ability, attach a Spice, attack a unit, attack the opposing Chef, and end the turn.
- Confirm the card inspector shows complete rules text and its primary action without scrolling to discover it.
- Confirm pause/settings, reduced motion, text scaling, music, and SFX controls persist after reload.
- Confirm a season autosave resumes at the correct shop/tournament state.
- Open a booster, reveal all five cards, return to the shop, and confirm all cards entered the collection exactly once.
- Complete the demo and confirm the finale fits the viewport. The live Discord action must work; destinations without a real public URL must remain hidden.

## Distribution and provenance

- Export with the `Web (itch.io)` release preset; do not upload a debug export.
- Serve the build over HTTPS and verify browser audio starts after the first user gesture.
- Check `CREDITS.md` against all third-party and project-owner-supplied assets included in the build.
- Confirm direct project-owner assets remain documented as CC0.
- Verify the configured Discord invite (`https://discord.gg/EK6AmYgnPZ`) opens from the finale in the uploaded browser build.
- Add the Steam URL to `STEAM_STORE_URL` only after the store page is public.
- Capture the final version, build date, exported bundle size, and known issues in release notes.

## Known pre-publish dependencies

- Public Discord invite: configured and covered by the public-UI smoke test.
- Public Steam page URL: not configured.
- Store-page screenshots/capsules and platform-specific upload steps remain a manual publishing task.
- Seven Meals did not include stats in the supplied source list. Confirm the current inherited values before balance lock: Relishoon 4/5, Sauerkrat 2/3, Cinnamon Snail 5/6, Pandacake 4/5, Gravy Gazelle 2/4, Polar Pot Pie Bear 3/6, and Bison Burrito 4/5.
- Dedicated art is present for 61 of 87 canonical cards. Public boosters and singles are automatically constrained to those 61 finished cards. The remaining 26 stay playable in the canonical catalog but should receive final art before calling the full visual content complete:
  - Ingredients: Feta Ferret, Arrabbeta.
  - Meals: Jambaye-aye, Relishoon, Pika-le, Pudding Puma, Yolke Bowl, Hot Sauchuar.
  - Chefs: Chef Gusteau, Chef Brown, Chef Duff, Chef Emril.
  - Tools: Switchblade, Fresh Shopping List, Funky Shopping List, Blow Torch.
  - Environments: spicy taquería, hearty diner, sweet bakery, Funky Pickle Stand, fresh greensweet.
  - Spices: Cayenne Crunch, Savory Gravy, Sugar Glaze, Funky Brine, Fresh Balsamic.
