# 3D Card Interface Audit

## Current release status

The playable demo is locked to the supplied 87-card catalog: 30 Ingredients, 23 Meals, 9 Chefs, 15 Tools, 5 Environments, and 5 Spices. The internal 1/1 Fresh Ingredient token is tested separately and is not collectible.

The automated 3D interface audit instantiates every canonical card as a physical table card and verifies that each one has a rendered face and a supported play route. It also exercises the interaction families that are most vulnerable to input regressions:

- all 23 Meal recipe selectors;
- all 12 deck-search routes;
- all 5 discard-pile choice routes;
- all 9 board-target routes;
- all 6 activated-ability routes;
- all 3 reaction windows;
- all 8 discard-cost routes; and
- all 12 high-risk canonical effect-lab scenarios.

The exact catalog membership and type counts are independently enforced by `CanonicalCatalogSmokeTest.gd`. Together, these checks prevent a retired card from silently returning and prevent a canonical card from losing its 3D interaction path.

## Remaining presentation work

Most cards currently use the shared generated card-face renderer over available artwork. Cards without a dedicated art asset remain readable and playable through that renderer, but final bespoke illustrations are still a content-polish task rather than a gameplay blocker.

Reaction choices and hidden-opponent-hand choices use centered accessible overlays. They are fully functional, though a future physical-hand treatment could make those moments feel more tactile.

## Repeatable verification

Run the complete demo gate:

```bash
./scripts/release/check_demo.sh
```

Or run only the 3D interface audit:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --audio-driver Dummy --rendering-method gl_compatibility -s res://scripts/ThreeDCardInterfaceAudit.gd
```

The complete gate also validates the canonical manifest, gameplay rules, mouse input routing, responsive layouts, card text fit, public-facing UI, autosave, season flow, and the browser export budget.
