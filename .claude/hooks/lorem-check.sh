#!/bin/bash
set -euo pipefail

# lorem-check.sh - Validates lorem ipsum presence/absence per stage
# Usage: lorem-check.sh <project-dir> <expected-state>
# Stages: wireframe, content, final

PROJECT_DIR="${1:-.}"
EXPECTED_STATE="${2:-wireframe}"

case "$EXPECTED_STATE" in
  wireframe)
    # Wireframe stage: ALL files under docs/02-wireframes/ MUST contain lorem ipsum
    missing=0
    while IFS= read -r file; do
      if ! grep -qi "lorem ipsum" "$file" 2>/dev/null; then
        echo "$file"
        missing=1
      fi
    done < <(find "$PROJECT_DIR/docs/02-wireframes/" -name "*.html" 2>/dev/null || true)
    [ "$missing" -eq 0 ] && exit 0 || exit 1
    ;;
  content)
    # Content stage: NO lorem in docs/03-content/, docs/04-design.md, or src/wp-content/themes/
    found_lorem=0
    while IFS= read -r file; do
      if grep -qi "lorem ipsum" "$file" 2>/dev/null; then
        echo "$file"
        found_lorem=1
      fi
    done < <(find "$PROJECT_DIR/docs/03-content/" "$PROJECT_DIR/docs/04-design.md" "$PROJECT_DIR/src/wp-content/themes/" -type f 2>/dev/null || true)
    [ "$found_lorem" -eq 0 ] && exit 0 || exit 1
    ;;
  final)
    # Final stage: NO lorem + NO "undefined" literal (case-sensitive)
    found_issues=0
    while IFS= read -r file; do
      if grep -qi "lorem ipsum" "$file" 2>/dev/null; then
        echo "$file"
        found_issues=1
      fi
    done < <(find "$PROJECT_DIR/docs/03-content/" "$PROJECT_DIR/docs/04-design.md" "$PROJECT_DIR/src/wp-content/themes/" -type f 2>/dev/null || true)
    while IFS= read -r file; do
      if grep -q "undefined" "$file" 2>/dev/null; then
        echo "$file"
        found_issues=1
      fi
    done < <(find "$PROJECT_DIR/src/wp-content/themes/" -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) 2>/dev/null || true)
    [ "$found_issues" -eq 0 ] && exit 0 || exit 1
    ;;
  *)
    echo "Unknown stage: $EXPECTED_STATE" >&2
    exit 1
    ;;
esac

exit 0
