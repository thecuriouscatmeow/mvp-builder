#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:-.}"
STAGE="${2:-final}"

# Helper: emit hand-rolled JSON.
# Args: verdict, stopped_on ("CRITICAL" or "null" string).
# Uses globals: PROJECT_DIR, STAGE, ISSUES[], CRITICAL_COUNT, HIGH_COUNT, MEDIUM_COUNT, LOW_COUNT.
emit_json() {
  local verdict="$1" stopped_on_raw="$2"
  local stopped_on_json
  if [[ "$stopped_on_raw" == "null" || -z "$stopped_on_raw" ]]; then
    stopped_on_json="null"
  else
    stopped_on_json="\"$stopped_on_raw\""
  fi
  local issues_csv=""
  if [[ ${#ISSUES[@]} -gt 0 ]]; then
    issues_csv=$(IFS=,; echo "${ISSUES[*]}")
  fi
  printf '{"project":"%s","stage":"%s","verdict":"%s","stopped_on":%s,"issues":[%s],"summary":{"CRITICAL":%d,"HIGH":%d,"MEDIUM":%d,"LOW":%d}}\n' \
    "$PROJECT_DIR" "$STAGE" "$verdict" "$stopped_on_json" "$issues_csv" \
    "$CRITICAL_COUNT" "$HIGH_COUNT" "$MEDIUM_COUNT" "$LOW_COUNT"
}

ISSUES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# Check 1: lorem in final stage
if [[ "$STAGE" == "final" ]]; then
  if bash "$(dirname "$0")/../.claude/hooks/lorem-check.sh" "$PROJECT_DIR" final >/dev/null 2>&1; then
    :
  else
    # Extract offending files from lorem-check output
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      ISSUES+=("{\"severity\":\"CRITICAL\",\"check\":\"lorem-final\",\"location\":\"$line\",\"message\":\"lorem ipsum present\"}")
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    done < <(bash "$(dirname "$0")/../.claude/hooks/lorem-check.sh" "$PROJECT_DIR" final 2>&1 | grep -v '^$' || true)
    [[ $CRITICAL_COUNT -gt 0 ]] && {
      emit_json "block" "CRITICAL"
      exit 1
    }
  fi
fi

# Check 2: Missing wireframe/content files
if [[ -f "$PROJECT_DIR/docs/01-sitemap.md" ]]; then
  while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    wf="$PROJECT_DIR/docs/02-wireframes/${page}.html"
    cf="$PROJECT_DIR/docs/03-content/${page}.json"
    if [[ ! -f "$wf" ]]; then
      ISSUES+=("{\"severity\":\"CRITICAL\",\"check\":\"missing-wireframe\",\"location\":\"$wf\",\"message\":\"wireframe missing\"}")
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
      emit_json "block" "CRITICAL"
      exit 1
    fi
    if [[ ! -f "$cf" ]]; then
      ISSUES+=("{\"severity\":\"CRITICAL\",\"check\":\"missing-content\",\"location\":\"$cf\",\"message\":\"content missing\"}")
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
      emit_json "block" "CRITICAL"
      exit 1
    fi
  done < <(grep -E '^\|' "$PROJECT_DIR/docs/01-sitemap.md" | tail -n +3 | awk '{print $2}' | tr -d '`' | grep -v '^$')
fi

# Check 3: H1 count validation
if [[ -f "$PROJECT_DIR/docs/01-sitemap.md" ]]; then
  while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    wf="$PROJECT_DIR/docs/02-wireframes/${page}.html"
    h1_count=$(grep -c '<h1' "$wf" || true)
    if [[ "$h1_count" -ne 1 ]]; then
      ISSUES+=("{\"severity\":\"CRITICAL\",\"check\":\"h1-count\",\"location\":\"$wf\",\"message\":\"expected 1 h1, found $h1_count\"}")
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
      emit_json "block" "CRITICAL"
      exit 1
    fi
  done < <(grep -E '^\|' "$PROJECT_DIR/docs/01-sitemap.md" | tail -n +3 | awk '{print $2}' | tr -d '`' | grep -v '^$')
fi

# Check 4: Empty img src
if [[ -f "$PROJECT_DIR/docs/01-sitemap.md" ]]; then
  while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    wf="$PROJECT_DIR/docs/02-wireframes/${page}.html"
    if grep -q 'src=""' "$wf" 2>/dev/null; then
      ISSUES+=("{\"severity\":\"CRITICAL\",\"check\":\"empty-img-src\",\"location\":\"$wf\",\"message\":\"empty src attribute\"}")
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
      emit_json "block" "CRITICAL"
      exit 1
    fi
  done < <(grep -E '^\|' "$PROJECT_DIR/docs/01-sitemap.md" | tail -n +3 | awk '{print $2}' | tr -d '`' | grep -v '^$')
fi

# Check 5: Design tokens
if bash "$(dirname "$0")/check-design-tokens.sh" "$PROJECT_DIR" >/dev/null 2>&1; then
  :
else
  ISSUES+=("{\"severity\":\"HIGH\",\"check\":\"design-tokens\",\"location\":\"$PROJECT_DIR/docs/04-design.md\",\"message\":\"missing concrete tokens\"}")
  HIGH_COUNT=$((HIGH_COUNT + 1))
fi

# Check 6: Missing alt on images
if [[ -f "$PROJECT_DIR/docs/01-sitemap.md" ]]; then
  while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    wf="$PROJECT_DIR/docs/02-wireframes/${page}.html"
    if grep -q '<img[^>]*>' "$wf" 2>/dev/null && grep '<img[^>]*>' "$wf" | grep -qv 'alt='; then
      ISSUES+=("{\"severity\":\"HIGH\",\"check\":\"missing-alt\",\"location\":\"$wf\",\"message\":\"image missing alt attribute\"}")
      HIGH_COUNT=$((HIGH_COUNT + 1))
    fi
  done < <(grep -E '^\|' "$PROJECT_DIR/docs/01-sitemap.md" | tail -n +3 | awk '{print $2}' | tr -d '`' | grep -v '^$')
fi

# Check 7: Image files exist
if [[ -f "$PROJECT_DIR/docs/05-image-prompts.md" ]]; then
  while IFS= read -r slot; do
    [[ -z "$slot" ]] && continue
    imgfile="$PROJECT_DIR/docs/06-images/$slot"
    if [[ ! -f "$imgfile" ]]; then
      ISSUES+=("{\"severity\":\"HIGH\",\"check\":\"missing-image\",\"location\":\"$imgfile\",\"message\":\"image file not found\"}")
      HIGH_COUNT=$((HIGH_COUNT + 1))
    fi
  done < <(grep -oE '\[.*\]' "$PROJECT_DIR/docs/05-image-prompts.md" | tr -d '[]' | grep -v '^$')
fi

# Build summary
SUMMARY="{\"CRITICAL\":$CRITICAL_COUNT,\"HIGH\":$HIGH_COUNT,\"MEDIUM\":0,\"LOW\":0}"

# Emit final JSON
if [[ $CRITICAL_COUNT -gt 0 ]]; then
  verdict="block"
  exit_code=1
elif [[ $HIGH_COUNT -gt 0 ]]; then
  verdict="warn"
  exit_code=2
else
  verdict="pass"
  exit_code=0
fi

printf '{"project":"%s","stage":"%s","verdict":"%s","stopped_on":null,"issues":[' "$PROJECT_DIR" "$STAGE" "$verdict"
[[ ${#ISSUES[@]} -gt 0 ]] && printf '%s' "$(IFS=,; echo "${ISSUES[*]}")"
printf '],"summary":%s}\n' "$SUMMARY"

exit "$exit_code"
