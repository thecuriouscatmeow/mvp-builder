---
name: mvp-builder-wordpress-finalize
description: Stage 7 — final validation, CHANGELOG entry, final commit. Exits the orchestrator. After this, the project is interview-ready.
---

# Finalize Project Command

## Preconditions
- All per-page checkpoints for stages 2 and 4 approved
- `05-image-prompts.md` generated
- Images in `docs/06-images/` preferred but not required (HIGH, not CRITICAL)

## Action
- Call `~/mvp-builder/scripts/finalize-project.sh $PWD`
- On exit 0: congratulate user, surface localhost URL, exit orchestrator
- On exit 1: print report, suggest offending checks to fix

## Success outputs
- Project path
- Page count from sitemap
- Final commit SHA
- Local URL: http://localhost:8888
