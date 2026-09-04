# AI-generated asset removal — August 27, 2026

The known generated and prompt-derived art identified by the shipping
provenance policy was removed from the project. The operation moved files to a
recoverable quarantine rather than irreversibly erasing them:

`/private/tmp/top-cut-ai-assets-quarantine-2026-08-27`

## Removed source families

- Generated concept artwork, icon concepts, style tiles, and shop concepts
  under `outputs/`.
- Generated Steam capsule masters, crops, prompt files, and other marketing
  experiments under `assets/marketing/`.
- Generated art-direction boards, character concepts, mascots, finale art,
  building concepts, and title experiments.
- The generated angular card-back concept.
- The generated or unverified legacy 3D clerk and legacy shopkeeper portraits.
- Godot `.import` sidecars and 97 exact compiled import-cache files belonging to
  those deleted sources.
- The obsolete runtime card-back concept capture script that depended on the
  deleted generated card back.

The three credited, user-supplied overworld source sheets were reviewed and
retained; they are not classified as known generated assets. The code-authored
greybox shop scene was also retained, but its removed clerk model was replaced
with the current supplied 2D shopkeeper asset.

## Ongoing enforcement

- `scripts/release/known_generated_asset_hashes.sha256` preserves hashes for
  the removed generated visual/model sources.
- `scripts/release/check_no_ai_assets.sh` checks shipping-eligible PNG, JPEG,
  WebP, SVG, and GLB assets against that denylist.
- Export exclusions remain in place even though the prohibited source folders
  are absent.
- Runtime content contains no references to the removed source paths.
- `scripts/release/check_no_ai_assets.sh --audit-known` verifies those three
  controls without bypassing or changing the separate owner attestation.

`OWNER_ATTESTATION` remains pending in `docs/shipping-asset-provenance.md`.
Deleting known generated sources does not prove the provenance of every other
custom production asset; the project owner must still confirm the remaining
card art, characters, logo, card back, route icons, backgrounds, packs, UI
icons, audio, and storefront deliverables before release.
