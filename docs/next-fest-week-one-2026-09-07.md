# Next Fest — week one handoff, September 7–13

September 7 asset-audit update: the owner now wants the final demo to contain
no generative-AI assets. The [detailed asset checklist](no-gen-ai-asset-checklist-2026-09-07.md)
and [current-screen comparison](../outputs/next_fest_asset_audit_2026-09-07/visual-review.html)
replace the earlier provisional art inventory. Existing working-art permission
does not establish approval to retain it in that final release. The audit and
captures are complete; camera templates and production replacements are still
unchecked work below.

Weekly target: a playable shop → battle → reward → hub sequence using the
approved visual direction, a first Windows release build, and a precise art
replacement queue. This is the work breakdown; the unchecked implementation
tasks below have not been completed by writing this document.

October registration is confirmed by the owner. Review submission target:
September 28. The wider schedule and audit are in
[the production plan](next-fest-production-plan-2026-09-07.md).

## What Jack supplies

| Due | Deliverable | What to send / why it matters |
| --- | --- | --- |
| Tuesday, September 8 | Steam details | Public store URL, base-game App ID, demo App ID if created, and whether demo store/build review is already approved, submitted or not started. Codex uses these to prepare correct links and packaging. |
| Tuesday, September 8 | Art production capacity | Who is drawing the replacement art and roughly how much time they have this week and before September 28. Identify any generated assets that must be replaced before the demo ships. Existing authorization to use clearly flagged working art remains in effect. |
| Tuesday, September 8 | Existing editable artwork, if available | Paths to layered source files or finished replacements beyond the supplied assets already in the project. Mina, her GIF, the approved room reference and original card art are already available. |
| Thursday, September 10 | One finished room sample, if doing the redraw | Draw one small counter/case corner or shelf section from Codex's template. This establishes the actual blue-pen edge, flat fills and detail level before a full room redraw. Include the editable source and transparent PNG export. |
| Friday, September 11 | Focused visual review | Review an in-game capture/build and list the three most important problems: composition, readability or mismatch with the approved style. This is feedback on implementation, not another concept-selection round. |
| By the weekend | Windows tester and first-run feedback | Arrange one person with a Windows PC to install and run the desktop build. Aim for two or three unfamiliar players for an initial session; a larger playtest follows next week. Jack also plays a complete run and reports confusing or broken steps. |

If drawing capacity is limited, the room sample can move while implementation
continues using registered working art. The art delivery schedule still needs
to identify what can realistically be replaced before submission.

## What Codex delivers

- [ ] **Tuesday: drawing handoff.** Prepare an annotated in-engine room layout,
  a named layer list, UI safe areas and a small sample template. Inventory
  reachable missing card art and generated assets, and prioritize replacements.
  Each requested asset gets dimensions, placement and a consumer/replacement path.
- [ ] **Tuesday–Wednesday: desktop build foundation.** Add a Windows release
  export and prepare repeatable packaging. Use supplied App IDs for Steam
  configuration. Produce a first test ZIP early, with concise installation and
  reporting instructions for the Windows tester.
- [ ] **Tuesday–Thursday: release blocker investigation.** Resolve the failing
  Expert Sweet opponent-deck test against intended gameplay. Run relevant tests
  and report any further failures distinctly from stale assertions. Establish
  the release candidate's actual test status.
- [ ] **Wednesday–Friday: interactive shop/hub.** Implement the approved room's
  composition in layers, with real offered cards in the glass case, usable
  seller/bye interactions, readable run status and Next Round. Record any
  generated pixels introduced to runtime with paths, hashes and prompts.
- [ ] **Friday–Sunday: playable visual pass.** Carry the room language into the
  existing battle presentation and basic title controls. Preserve supplied Mina,
  live concealed hand cards, two mats, ribbon frames, original card artwork and
  affiliation identities. Check the complete shop → battle → reward → hub path.
- [ ] **Weekend: validation and review package.** Exercise current save/resume
  and purchase/reward boundaries, capture the three key screens, collect Windows
  launch evidence from the tester, and summarize the highest-priority gameplay,
  balance and visual issues for week two. Provide the build, captures, test
  results and updated asset replacement list together.

Codex owns button/panel drawing, live card display, prices, layout, interaction
regions, animations, import/cropping and integration. Artist work focuses on
illustration. First-session tutorial integration and deeper balance tuning are
week-two priorities after the existing flows and release baseline are established.

## Art handoff contract

Use the approved blue-pen room and `ART_DIRECTION.md` for the drawing language.
Codex supplies camera placement and export dimensions before a full redraw.
Environment exports share one canvas and retain their original layer positions;
isolated layers use transparent RGBA PNGs in sRGB. Include the editable source
from the drawing app. Keep cards, price labels, machine text and buttons live
in the game instead of painting them into the scene.

Mina's existing animation already anchors the character style and needs no
replacement for this milestone. For later rival replacements, Codex supplies
an alignment guide based on the current 1448×1200 canvas and y=1000 arm baseline.
Start with one seated neutral pose; aligned smile/hurt expressions and selective
line-boil drawings follow after it is approved. Avoid painted-in hand cards so
the game can drive the held backs from real draws and plays.

## Sunday acceptance

- [ ] Jack can enter the redesigned hub, buy a real card from the case, play a
  match, collect a reward and return to the hub with the correct run state.
- [ ] The actual gameplay scene visibly follows the approved composition and
  drawing language; unfinished art is listed and clearly attributable.
- [ ] A Windows release ZIP exists, with a recorded native launch result from
  a Windows tester. Export success alone is not recorded as a launch pass.
- [ ] Test results distinguish confirmed passes, failures and untested areas.
- [ ] Jack has a short, prioritized art list with templates and a week-two fix
  list derived from real play, rather than additional speculative concepts.

No Steam upload, public release, or outreach was performed in this planning
pass. Schedule feasibility will be reassessed using the first build and actual
art capacity. This checklist does not schedule unattended work.
