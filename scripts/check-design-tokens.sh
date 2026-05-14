#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:?PROJECT_DIR required}"

DESIGN_FILE="$PROJECT_DIR/docs/04-design.md"

if [[ ! -f "$DESIGN_FILE" ]]; then
  echo "FAIL: Design file not found: $DESIGN_FILE"
  exit 1
fi

# Count hex codes
HEX_COUNT=$(grep -oE '#[0-9A-Fa-f]{6}' "$DESIGN_FILE" | wc -l)
if [[ $HEX_COUNT -lt 8 ]]; then
  echo "FAIL: Found $HEX_COUNT hex codes, need ≥8"
  exit 1
fi

# Count numeric px values
PX_COUNT=$(grep -oE '[0-9]+px' "$DESIGN_FILE" | wc -l)
if [[ $PX_COUNT -lt 15 ]]; then
  echo "FAIL: Found $PX_COUNT px values, need ≥15"
  exit 1
fi

# Check for ms durations
if ! grep -q 'ms\b' "$DESIGN_FILE"; then
  echo "FAIL: No motion durations (ms) found"
  exit 1
fi

# Check for breakpoints (numeric values)
if ! grep -qE '[0-9]{3,4}px' "$DESIGN_FILE"; then
  echo "FAIL: No breakpoints found"
  exit 1
fi

exit 0
