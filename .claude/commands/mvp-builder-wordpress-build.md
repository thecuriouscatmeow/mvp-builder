---
name: mvp-builder-wordpress-build
description: Drive stages 3-4 (content + design) via the orchestrator. Run after mvp-builder-wordpress-plan has produced approved wireframes.
---

# Build Command — Stages 3–4 (Content + Design)

## When to Invoke
After stage 2 wireframes are all checkpoint-approved. Every page slug in `01-sitemap.md` must have a checkpoint marker `docs/checkpoints/<page>.2.approved`.

## Preconditions
- `docs/01-sitemap.md` exists and lists all pages.
- Every page slug has `docs/checkpoints/<page>.2.approved`.
- `docs/02-wireframes/<page>.html` exists for every page.

## Action
The orchestrator runs:

1. **Stage 3 (Content) — Parallel dispatch**
   - For each page slug in sitemap, dispatch a content-worker agent with `{{PROJECT_DIR}}` and `{{PAGE_SLUG}}`.
   - Each worker produces `docs/03-content/<page>.json`.
   - Bulk checkpoint: wait for all; assert no `lorem ipsum` in any JSON (case-insensitive).
   - Create `docs/checkpoints/stage-3.approved` on success.

2. **Stage 4a (Design Strategy) — Orchestrator (Sonnet)**
   - Orchestrator reads `templates/wordpress/design.template.md`.
   - Fills every field with concrete values: hex codes, px, ms, breakpoints, component specs.
   - Writes `docs/04-design.md`.
   - Validates using `scripts/check-design-tokens.sh <PROJECT_DIR>`; exit 1 on failure.

3. **Stage 4b (Design Application) — Parallel per-page dispatch**
   - For each page slug, dispatch a design-apply worker (Haiku).
   - Each worker re-styles the wireframe and produces a WordPress template part.
   - Per-page checkpoint: `docs/checkpoints/<page>.4.approved`.

## Failure Modes
- **Lorem in content JSON** → lorem-check script exits 1, surface error, stop.
- **Missing hex codes in design.md** → `check-design-tokens.sh` exits 1, surface error, stop.
- **Wireframe without matching content JSON** → assert failure, surface, stop.

