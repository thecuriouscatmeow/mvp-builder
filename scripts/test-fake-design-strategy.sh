#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:?PROJECT_DIR required}"

mkdir -p "$PROJECT_DIR/docs"

cat > "$PROJECT_DIR/docs/04-design.md" << 'DESIGN'
# Design Tokens — Stage 4

## Palette
- Primary: #0066CC
- Secondary: #FF6B35
- Dark: #1A1A1A
- Light: #F5F5F5
- Muted: #E0E0E0
- Gray: #999999
- Success: #22C55E
- Warning: #F59E0B
- Error: #EF4444

## Type Scale
- xs: 12px, line-height: 1.3
- sm: 14px, line-height: 1.4
- base: 16px, line-height: 1.5
- lg: 18px, line-height: 1.6
- xl: 24px, line-height: 1.4
- 2xl: 32px, line-height: 1.3
- 3xl: 48px, line-height: 1.2

## Spacing Scale
0, 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px, 96px

## Border Radius
- sm: 4px
- md: 8px
- lg: 16px
- full: 9999px

## Shadows
- sm: 0 1px 2px rgba(0,0,0,0.05)
- md: 0 4px 8px rgba(0,0,0,0.1)
- lg: 0 12px 24px rgba(0,0,0,0.15)

## Motion
- fast: 150ms
- base: 250ms
- slow: 400ms
- easing: cubic-bezier(0.4,0,0.2,1)

## Breakpoints
- sm: 640px
- md: 768px
- lg: 1024px
- xl: 1280px

## Component Specs
### Button
- padding: 12px 24px
- border-radius: 8px
- font-size: 14px

### Card
- padding: 24px
- border-radius: 16px
- box-shadow: 0 4px 8px rgba(0,0,0,0.1)

DESIGN

exit 0
