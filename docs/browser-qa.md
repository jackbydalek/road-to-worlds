# Browser QA Matrix

Test the versioned itch Web build, not an editor run. Unpack the ZIP so `index.html` is at the directory root, then serve it over HTTP with `scripts/release/serve_web.sh /path/to/unpacked-build`. Do not test from a `file://` URL.

## Required browsers and sizes

| Browser | Desktop viewport | Browser zoom | Release requirement |
| --- | --- | --- | --- |
| Current Chrome | 1280×720, 1440×900, 1920×1080 | 100%, 125% | Required |
| Current Safari | 1280×720, 1440×900, 1920×1080 | 100%, 125% | Required |
| Current Firefox | 1280×720, 1440×900, 1920×1080 | 100%, 125% | Required |

The automated `ResponsiveLayoutSmokeTest` covers those viewport and text-scale combinations inside Godot. The browser pass verifies the exported Web runtime, input, audio, and browser-specific rendering.

## Pass checklist

- [ ] Loading screen uses the illustrated game background; no black flash or browser console error.
- [ ] Title, New Run, How to Play, Settings, and Credits fit without clipped text or horizontal scrolling.
- [ ] Credits show asset/audio attribution and the Discord button opens `https://discord.gg/EK6AmYgnPZ` in a new tab.
- [ ] All seven tutorial steps remain readable at 125% zoom.
- [ ] Start a run with $5 on the intended lower-income tiers and verify earned money is added after play.
- [ ] Store navigation accepts mouse and keyboard input; the shopkeeper zoom, heart, and particle transitions finish cleanly.
- [ ] Singles and boosters can reveal any canonical card; dedicated and fallback artwork both remain inside the viewport.
- [ ] In a match, open the card inspector and verify the full rules text is visible at every supported size.
- [ ] Complete a round and finale; buttons remain visible and community link works.
- [ ] Music, UI sounds, combat sounds, healing/buff sound, mute, and volume settings behave correctly.
- [ ] Reloading the page restores the autosave and does not repeat a completed reward.
- [ ] Browser console stays free of uncaught exceptions, WebGL errors, and missing-resource responses.

Record browser version, OS version, viewport, result, and any issue link. A release is not browser-signed-off until every required browser has a recorded pass or a documented, owner-approved exception.

## Local environment status (2026-08-06)

- Safari 26.5 and `safaridriver` are installed, but Safari **Settings → Developer → Allow remote automation** is disabled, so an automated Safari session could not be created from this task.
- Chrome is installed, but the Codex browser connection is not enabled, so interactive Chrome QA could not be recorded from this task.
- Firefox is not installed, so Firefox QA could not be recorded from this task.
- The exported artifact passed the browser-independent HTTP transport probe: `index.html`, `index.js`, `index.pck`, and `index.wasm` all returned HTTP 200 with correct MIME types.

To finish the outstanding pass, enable/install the ChatGPT browser extension under Codex **Settings → Computer use**, enable Safari remote automation, and install a current Firefox build. These are release-signoff items, not automated-gate passes.
