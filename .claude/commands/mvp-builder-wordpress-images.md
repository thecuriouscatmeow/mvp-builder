---
name: mvp-builder-wordpress-images
description: Drive stage 5 (image-prompts). Produces 05-image-prompts.md for the human to feed to their image generator. Manual generation — system does not call any image API.
---

# Images Command — Stage 5 (Image Prompts)

## When to Invoke
After stages 3–4 are complete and approved. Checkpoint markers `docs/checkpoints/stage-3.approved` and `docs/checkpoints/stage-4.approved` must exist.

## Action
The orchestrator runs:

1. **Stage 5 (Image Prompts Synthesis) — Orchestrator (Sonnet)**
   - Invokes the image-prompt-synthesizer agent in the orchestrator's context.
   - Agent reads `docs/04-design.md`, `docs/image-guidelines.md`, all `docs/02-wireframes/*.html`.
   - Produces `docs/05-image-prompts.md` with one section per image slot.
   - Prints summary: slot count, pages covered.

## After the User Generates Images
The user saves the resulting PNGs into `docs/06-images/` with names matching the `Path` fields in `05-image-prompts.md`. For example:
- `docs/06-images/home-hero.png`
- `docs/06-images/about-card-1.png`

No system action required. The validate stage later checks for presence of generated images.

