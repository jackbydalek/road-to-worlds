# Shipping asset provenance

OWNER_ATTESTATION: PENDING

This record is a release control for **TOP CUT: Locals to Worlds**. The release
scripts must fail while the attestation is pending. Visual similarity and file
metadata are not reliable proof of how an asset was made, so undocumented art
is not silently treated as non-AI.

## Project-owner attestation required

Before changing the status above to `CONFIRMED`, the project owner must confirm
this statement:

> Every custom visual or audio asset intended for the game build, Steam store
> page, trailer, screenshots, press kit, or other public release was created
> without generative AI, or is a normal non-generative edit/derivative of a
> source that was itself created without generative AI. All third-party assets
> have documented licenses and non-AI provenance to the best of the owner's
> knowledge.

The confirmation must cover the original sources behind these production
families, not only the exported PNGs:

- Card illustrations under `assets/cards/art/`.
- The Sweet protagonist illustration at
  `assets/characters/protagonists/sweet_player_neutral.png`.
- The live shopkeeper art at
  `assets/characters/shopkeeper/route_shopkeeper_card_pose.png`.
- The route-rival illustrations under `assets/characters/rivals/`.
- The logo, card back, route icons, player-character art, battle backgrounds,
  park props, card-pack art, card frames, custom UI icons, and season-setup art.
- Every capsule, screenshot, trailer frame, and other asset uploaded to Steam.

## Prohibited from release

These paths contained known generated artwork, prompt-driven experiments, or
unverified concepts. The known generated sources were removed from the project
on August 27, 2026. Their exclusions remain in every configured game export as
defense in depth; do not restore or upload them to a storefront:

- `outputs/`
- `assets/marketing/`
- `assets/art_direction/`
- `assets/characters/concepts/`
- `assets/characters/mascots/`
- `assets/finale/`
- `assets/overworld/buildings/concepts/`
- `assets/overworld/buildings/shop_concept/`
- `assets/title/`
- `assets/cards/card_backs/angular_card_back_concept.svg`
- Legacy/unverified shopkeeper models and portraits other than the live route
  shopkeeper image.

The capsule masters under `assets/marketing/steam/` are especially important:
their adjacent prompt files explicitly document built-in image generation.
None of those masters or crops qualify for a no-generative-AI Steam page.

The removed source hashes remain in
`scripts/release/known_generated_asset_hashes.sha256`, allowing the release gate
to reject byte-identical copies even though the original generated files are no
longer present. See `docs/ai-asset-removal-2026-08-27.md` for the removal record.

## Accepted non-generative sources

- Code-drawn UI, shaders, procedural geometry, and ordinary crops, recolors,
  animation-frame extraction, compression, or layout work whose source art is
  covered by the owner attestation.
- Material Symbols Sharp, Kenney assets, Quaternius buildings, the Pandazole
  storefront, and the other third-party packages recorded in `CREDITS.md` and
  their preserved license/source files.

## Enforcement

`scripts/release/check_no_ai_assets.sh` verifies that:

1. every export preset retains the prohibited-path exclusions;
2. shipping runtime code does not reference prohibited assets;
3. byte-identical copies of known generated images have not been moved into a
   shipping-eligible directory;
4. this attestation is confirmed; and
5. the exporter did not store any prohibited files in the final package.

This check is part of both the demo gate and the final itch build. Future Steam
build scripts must call the same check before and after export.
