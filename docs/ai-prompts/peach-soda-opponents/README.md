# Peach Soda battle character assets

All eight character illustrations are **AI-generated working art**. Their
original opaque sources remain unchanged in
`outputs/locals_opponents/peach_soda_cast_v1/`. This preparation removes the
background and table from those exact images; it does not redraw or recolor
the cast. No proprietary brush assets were used.

Final assets: `assets/generated/peach_soda_opponents/{pip,otis,ines,sana,milo,bea,kit,ellis}.png`.
Each is **1448 × 1200 RGBA**, with a common **y=1000 resting-arm baseline**.
Hands can hang below that baseline; Kit's full hand remains visible. Keep the
full canvas when replacing art, or deliberately update the runtime placement.

The user's previous authorization for code-based background removal is
recorded in `docs/generated-art-register.md`, under the staged seated-opponent
expression pack. `extract_portraits.py` applies that method to this new cast:
closed-ink exterior flood, visually checked interior background seeds, table
rule removal, and translation to the common canvas. The source RGB pixels
inside each retained silhouette remain unchanged. Alpha is real, with no
painted checkerboard. The mask uses the existing dark contour; normal game
texture filtering supplies display antialiasing.

Exact original generation prompts are retained as `*-original-generation.txt`.
`assets/generated/peach_soda_opponents/provenance.json` records source paths,
references, original generation destinations, SHA-256 hashes, canvas geometry,
cleanup steps and output hashes. `extraction-review.png` is a development-only
review composite. These records and rejected attempts are not game textures.

Two initial built-in image-generation extraction attempts for Pip returned
RGB images with baked checkerboards. They are retained here with their exact
prompts, clearly named `pip-rejected-*.png`; **neither is consumed by runtime**.
All eight final assets instead use the unmodified original concept drawings.

Only one relaxed expression exists per character. The held card backs are
decorative static illustrations and cannot represent a changing live hand
count. Existing authored card-face art and affinity colors are independent.

To remove the AI art later, replace the eight clearly isolated PNGs with
artist-authored transparent drawings on the same canvas/baseline, then update
the central generated-asset manifest and attribution records. Extraction does
not change their AI origin.
