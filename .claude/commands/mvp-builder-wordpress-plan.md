---
name: mvp-builder-wordpress-plan
description: Drive stages 1-2 (sitemap + wireframes) for an mvp-builder project. Invokes the orchestrator agent. Run inside the project directory after running mvp-builder-wordpress-init.
---

# /mvp-builder-wordpress-plan

## When to Invoke

After `/mvp-builder-wordpress-init` has created the project workspace and the user has filled (or the intake stage has populated) `docs/00-requirements.md`.

## Preconditions

- `docs/00-requirements.md` exists and is non-empty.
- `docs/01-sitemap.md` exists (may be just the template stub initially).
- You are running inside the project directory (or pass `--project <path>`).

## Action

1. Read `~/.claude/agents/orchestrator.md` (your playbook).
2. Set the active project context to `cwd` (or the passed project path).
3. Read `STATUS.md` and determine the next pending stage.
4. If stage 1 is pending: run stage 1 (sitemap) in your own context using the `01-sitemap` agent.
5. If stage 2 is pending: dispatch parallel wireframe workers (one per page in the sitemap) via `scripts/dispatch-worker.sh`. For each page:
   - Create a worker prompt file with `{{PROJECT_DIR}}` and `{{PAGE_SLUG}}` substituted.
   - Dispatch it to the background.
   - Track the PID.
6. Wait for all stage-2 worker PIDs to complete.
7. For each completed wireframe, run the reviewer (per-page checkpoint) via `mvp-builder-wordpress-checkpoint`.
8. Prompt the user for per-page approval checkpoint.
9. Update `STATUS.md` and commit via `scripts/stage-commit.sh`.

## Resume Semantics

If invoked again on an existing project:
- Read `STATUS.md`.
- Pick up at the next pending stage.
- Do not re-run completed stages.

## Failure Modes

- **If `00-requirements.md` is empty**: ask the user to fill it before re-running.
- **If stage 1 (sitemap) fails twice**: surface the error and stop. Do not proceed to stage 2.
- **If a stage-2 worker fails**: log the error, capture the page slug, and ask the user whether to retry or skip.
- **If Docker is off**: this is fine. Stage 2 is stateless and does not require the theme runtime.

## Outputs

- `docs/01-sitemap.md` (stage 1).
- `docs/02-wireframes/<page>.html` for each page (stage 2).
- `docs/checkpoints/<page>.2.approved` for each approved page (stage 2).
- Git commits per stage: `"stage-1: sitemap"` and `"stage-2: wireframe"`.
