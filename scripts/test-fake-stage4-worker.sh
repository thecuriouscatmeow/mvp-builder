#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:?PROJECT_DIR required}"
PAGE_SLUG="${2:?PAGE_SLUG required}"

WIREFRAME="$PROJECT_DIR/docs/02-wireframes/$PAGE_SLUG.html"

# Ensure wireframe exists
if [[ ! -f "$WIREFRAME" ]]; then
  echo "ERROR: Wireframe not found: $WIREFRAME" >&2
  exit 1
fi

# Create a styled version with design tokens and real copy
# Extract content from content JSON if it exists
CONTENT_JSON="$PROJECT_DIR/docs/03-content/$PAGE_SLUG.json"
CONTENT_COPY=""

if [[ -f "$CONTENT_JSON" ]]; then
  CONTENT_COPY=$(cat "$CONTENT_JSON" | jq -r '.h1 // "Test Heading"')
fi

# Inject inline styles with design tokens
STYLED_HTML="<html>
<head>
<style>
:root {
  --color-primary: #0066CC;
  --color-secondary: #FF6B35;
  --spacing-base: 16px;
  --type-base: 16px;
  --type-lg: 18px;
}
body {
  font-size: var(--type-base);
  padding: var(--spacing-base);
}
</style>
</head>
<body>
<h1>$CONTENT_COPY</h1>
$(cat "$WIREFRAME" | tail -n +2)
</body>
</html>"

echo "$STYLED_HTML" > "$WIREFRAME"

# Verify no lorem in output
if grep -qi "lorem ipsum" "$WIREFRAME"; then
  echo "ERROR: Lorem ipsum found in wireframe" >&2
  exit 1
fi

exit 0
