#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:-.}"

# Run validator. Exit codes: 0=pass, 1=block (CRITICAL), 2=warn (HIGH only).
# We tolerate exit 2 here and parse the verdict from the JSON.
set +e
VALIDATE_OUT=$(bash "$(dirname "$0")/validate-project.sh" "$PROJECT_DIR" final)
set -e
VERDICT=$(echo "$VALIDATE_OUT" | grep -o '"verdict":"[^"]*"' | cut -d'"' -f4)

# Check verdict
if [[ "$VERDICT" != "pass" && "$VERDICT" != "warn" ]]; then
  echo "$VALIDATE_OUT" >&2
  exit 1
fi

# Count pages
PAGE_COUNT=0
if [[ -f "$PROJECT_DIR/docs/01-sitemap.md" ]]; then
  PAGE_COUNT=$(grep -E '^\|' "$PROJECT_DIR/docs/01-sitemap.md" | tail -n +3 | wc -l)
fi

# Append CHANGELOG
CHANGELOG="$PROJECT_DIR/docs/CHANGELOG.md"
if [[ -f "$CHANGELOG" ]]; then
  echo "" >> "$CHANGELOG"
  echo "## Finalized $(date +%Y-%m-%d)" >> "$CHANGELOG"
  echo "" >> "$CHANGELOG"
  echo "- Completed 7 stages, $PAGE_COUNT pages" >> "$CHANGELOG"
fi

# Commit
cd "$PROJECT_DIR" || exit 1
git add -A || true
COMMIT_SHA=$(git commit -m "stage-7: finalize" --allow-empty 2>&1 | grep -o '[a-f0-9]\{7\}' | head -1 || echo "unknown")

# Print summary
echo "Project: $PROJECT_DIR"
echo "Pages: $PAGE_COUNT"
echo "Commit: $COMMIT_SHA"
echo "URL: http://localhost:8888"
