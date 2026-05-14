#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:?PROJECT_DIR required}"
PAGE_SLUG="${2:?PAGE_SLUG required}"

mkdir -p "$PROJECT_DIR/docs/03-content"

cat > "$PROJECT_DIR/docs/03-content/$PAGE_SLUG.json" << CONTENT
{
  "page": "$PAGE_SLUG",
  "title": "Test Page for $PAGE_SLUG",
  "meta_description": "Test description for $PAGE_SLUG page.",
  "h1": "Real Headline for $PAGE_SLUG",
  "blocks": [
    {
      "type": "hero",
      "id": "hero",
      "heading": "Real Heading",
      "subheading": "Real subheading copy.",
      "body": "Real body copy with actual content.",
      "cta": {
        "label": "Get Started",
        "href": "/contact"
      },
      "image_slot": "hero"
    }
  ]
}
CONTENT

exit 0
