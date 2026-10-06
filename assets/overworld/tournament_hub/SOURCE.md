# Tournament room scenery

`club_room.svg`, `club_table.svg`, and `club_plant.svg` are code-drawn vector
scenery added for the tournament-room production pass. Their geometry is stored
in the SVG source: no image-generation model or external artwork was used for
these additions. They follow the environment colors in `ART_DIRECTION.md` and
`GamePalette.gd`.

The SVGs retain logical scene coordinates in their viewBox and declare intrinsic
pixel dimensions at twice that size. This gives crisp 1080p rendering with Godot's default import
settings; it does not depend on the project's ignored `.import` files.

The desk and vending-machine PNGs already existed in this workspace. The scene
also reuses the existing shopkeeper and Living Table card back. The two route
rivals were removed from the back-right table at the user’s request.
Those source illustrations were not modified by this pass. Their provenance is
covered by the project's existing shipping-asset review, not attested here.

The club sign uses a centered card emblem with no lettering. Tournament progress,
action copy, and stock are live scene nodes.
The scene remains editable at `scenes/ui/TournamentHubScreen.tscn`.
