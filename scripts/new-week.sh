#!/usr/bin/env bash
# Usage: ./scripts/new-week.sh 01 logging-hardcoded-creds "insecure-logging" "hardcoded-credentials"
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <week-number> <week-slug> <vuln-1-slug> <vuln-2-slug>"
  exit 1
fi

WEEK="$1"; SLUG="$2"; V1="$3"; V2="$4"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/weeks/week-$WEEK-$SLUG"

for V in "$V1" "$V2"; do
  mkdir -p "$BASE/$V/artifacts" "$BASE/$V/evidence"
  cp "$ROOT/templates/writeup-template.md" "$BASE/$V/writeup.md"
  touch "$BASE/$V/artifacts/.gitkeep" "$BASE/$V/evidence/.gitkeep"
done

cat > "$BASE/README.md" <<EOT
# Week $WEEK: $SLUG

| # | Vulnerability | Write-up | Artifacts |
|---|---|---|---|
| 1 | $V1 | [writeup]($V1/writeup.md) | [artifacts]($V1/artifacts/) |
| 2 | $V2 | [writeup]($V2/writeup.md) | [artifacts]($V2/artifacts/) |

## Links
- LinkedIn:
- Medium:

## Weekly notes
EOT

echo "Created $BASE"
