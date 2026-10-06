#!/usr/bin/env bash
set -euo pipefail

# Keep the existing release API. The September locals pivot explicitly permits
# registered, replaceable generated working art; this is a provenance audit.
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
require_no_generated=false
if [[ "${1:-}" == "--require-no-generated" ]]; then
  require_no_generated=true
  shift
fi

if [[ "$require_no_generated" == false ]]; then
  exec python3 "$project_dir/scripts/release/check_asset_provenance.py" "$@"
fi

# Opt-in zero-generated-content gate. Registration is permission for working
# art, not evidence that a package is free of generative content.
python3 "$project_dir/scripts/release/check_asset_provenance.py" "$@"
python3 - "$project_dir" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
assets = json.loads((root / "assets/generated/manifest.json").read_text())["assets"]
policy = (root / "docs/shipping-asset-provenance.md").read_text().splitlines()
failures = []
if assets:
    failures.append(f"{len(assets)} registered generated working-art asset(s) remain. Replace or remove them from shipping paths and retire their manifest entries; runtime fallback flags do not exclude packaged files.")
if "OWNER_ATTESTATION: CONFIRMED" not in policy:
    failures.append("Owner/source attestation for retained public visual, audio and written content is not confirmed. Resolve the source handoff before making a no-generative-AI claim.")
if failures:
    for failure in failures:
        print(f"Zero-generated-content gate failed: {failure}", file=sys.stderr)
    sys.exit(1)
print("Zero-generated-content gate passed: no registered generated media remain and the recorded owner/source attestation is confirmed.")
print("This checks recorded provenance and known hashes; it cannot independently prove the origin of unknown content.")
PY
