# mvp-builder — Implementation Plan

> Derived from `PLAN.md` v3. Phasewise build sequence with subplans, milestones, acceptance criteria, model tiers, and verification gates.
> Status: **draft, pending user approval**. No code written until subplans are approved.

---

## Overview

| Phase | Goal | Gate to advance |
|---|---|---|
| **Phase 0** | Working local WordPress dev environment, scripted + idempotent | `mvp-builder-wordpress-setup` spins up clean WP < 60s |
| **Phase 1** | System skeleton + end-to-end pipeline (orchestrator, agents, skills, hooks) | One synthetic brief produces a finalized WP site |
| **Phase 2** | Reviewer/validator discipline + token-economy proof | ≤5 Sonnet calls/project held over 2 runs; CRITICAL/HIGH catch rate tuned |
| **Post-V1** | Real interview-style task (not in plan) | Reference-site rebuild in 1–2h |

Single execution lane: complete each phase fully before starting the next. No parallel phase work.

---

## Phase 0 — WordPress Dev Environment

**Why first:** the build pipeline writes into `src/wp-content/themes/<theme>/` and expects a running WP. Without Phase 0, every later phase blocks on env errors.

### Subplan 0.1 — Repo bootstrap

| | |
|---|---|
| Acceptance | `~/mvp-builder/` exists as a git repo with §4 skeleton; public GitHub repo `mvp-builder` connected; CLAUDE.md present |
| Model tier | Haiku (mechanical) |
| Risk | LOW |

Milestones:
1. `mkdir ~/mvp-builder && git init`; create directory tree per PLAN.md §4 (empty placeholder files where needed).
2. Write minimal `CLAUDE.md`, `README.md`, `STATUS.md`, `ROADMAP.md`, `CHANGELOG.md` stubs.
3. Run `/saahilbasak-init` inside `~/mvp-builder/` → produces `decisions/`, `graphify-out/`, appends CLAUDE.md section.
4. Create public GitHub repo `mvp-builder` (**ask user before push**). First commit: `chore: skeleton`.

Verification gate: `tree -L 3 ~/mvp-builder` matches §4; `git log` shows one commit; remote configured.

### Subplan 0.2 — `setup-wordpress-env.sh`

| | |
|---|---|
| Acceptance | Script idempotently installs/verifies WP-CLI, wp-env, PHP 8.x, Node, Composer; brings up a clean WP at `http://localhost:8888` with theme unit test data; WP_DEBUG on |
| Model tier | Haiku implementer |
| Risk | MEDIUM (host-machine variance) |

Milestones:
1. **RED**: write `tests/setup-wordpress-env.bats` (or shell harness) — asserts each tool returns version, wp-env runs, `curl localhost:8888` returns 200, theme unit test XML importable.
2. **GREEN**: write `scripts/setup-wordpress-env.sh` — detect existing installs, `brew install` / `npm i -g` missing ones, `wp-env start`, import `themeunittestdata.wordpress.xml`.
3. **REFACTOR**: idempotency pass — re-run should be no-op. Verify with second invocation.
4. Commit: `feat(phase-0): wordpress env bootstrapper`.

Verification gate: fresh shell → run script twice → second run reports "all present" in <5s; `wp-env start` from cold <60s.

### Subplan 0.3 — `mvp-builder-wordpress-setup` skill

| | |
|---|---|
| Acceptance | Slash command wraps `setup-wordpress-env.sh` with confirmation prompts, version check, teardown option |
| Model tier | Haiku |
| Risk | LOW |

Milestones:
1. Author `.claude/commands/mvp-builder-wordpress-setup.md` — frontmatter, args (`--check`, `--reset`), invokes script.
2. Test: `--check` reports state without changes; bare invocation prompts before installs; `--reset` tears down and recreates.
3. Commit: `feat(phase-0): setup skill`.

**Phase 0 exit gate (user single-gate approval):** fresh machine simulation passes; commit `phase-0-complete` tag.

---

## Phase 1 — System Skeleton + Pipeline End-to-End

Built as 6 subplans tracking the §5 stage pipeline + orchestrator + hooks. Subplans 1.1 → 1.2 are sequential (orchestrator needs templates). 1.3 → 1.6 each add one stage worker and can be developed serially with the synthetic brief evolving alongside.

### Subplan 1.1 — Templates + per-project init

| | |
|---|---|
| Acceptance | `templates/wordpress/*.md` populated; `mvp-builder-wordpress-init` in current dir produces full `<project>/` skeleton per §4 |
| Model tier | Haiku implementer; Sonnet for `brand-voice.template.md` + `design.template.md` content |
| Risk | LOW |

Milestones:
1. **RED**: integration test — invoke `mvp-builder-wordpress-init` in a tmp dir; assert `docs/`, `src/wp-content/themes/`, `docs/checkpoints/`, `99-known-issues.md`, `CHANGELOG.md` exist with expected headings.
2. Author 6 templates (`coding-standards`, `known-issues`, `requirements.template`, `sitemap.template`, `brand-voice.template`, `design.template`, `image-guidelines.template`).
3. Author `mvp-builder-wordpress-init.md` skill — copies templates, runs `git init`, first commit `stage-0: init`.
4. Verify test passes; commit `feat(phase-1): templates + init`.

### Subplan 1.2 — Orchestrator agent

| | |
|---|---|
| Acceptance | `agents/orchestrator.md` exists; sequences stages 0→7; reads filenames only; persists `STATUS.md` after each transition; dispatches via headless `claude -p` |
| Model tier | Sonnet (orchestrator runs as Sonnet); authoring is Sonnet judgment |
| Risk | HIGH (load-bearing for whole system) |

Milestones:
1. **RED**: smoke test — orchestrator dispatched with empty `<project>/`, mock workers (echo files), asserts: stages run in order, `STATUS.md` updates, `git commit` per stage, checkpoint files unblock advance, 2-retry on worker failure.
2. Author orchestrator: stage table, dispatch helper, checkpoint poll loop, parallel fan-out helper, headless-resume preamble.
3. Add token-budget tracker (logged, not enforced in V1).
4. Verify smoke test green; commit `feat(phase-1): orchestrator`.

### Subplan 1.3 — Hooks + reviewer

| | |
|---|---|
| Acceptance | `hooks/lorem-check.sh` + `hooks/changelog-guard.sh` block on rules; `agents/99-code-reviewer.md` runs one pass, returns issue list, never loops |
| Model tier | Haiku reviewer; Haiku for hook authoring |
| Risk | MEDIUM |

Milestones:
1. **RED**: hook unit tests — lorem present in wireframe = pass, lorem in content = fail; changelog missing entry on stage commit = fail.
2. Author hooks; wire via `.claude/settings.json`.
3. Author reviewer agent with §9 hard rules; test with a known-broken wireframe fixture → expects 3 specific issues, exits.
4. Commit `feat(phase-1): hooks + reviewer`.

### Subplan 1.4 — Stages 0–2 (intake → sitemap → wireframe)

| | |
|---|---|
| Acceptance | Synthetic brief → `00-requirements.md`, `01-sitemap.md`, `02-wireframes/*.html` produced; parallel wireframe dispatch works for 3 pages; per-page checkpoint gates fire |
| Model tier | Sonnet for 00 + 01 agents; Haiku for 02 worker |
| Risk | MEDIUM |

Milestones:
1. **RED**: end-to-end test — feed canned brief, assert all three artifacts on disk, lorem present in wireframes, checkpoint files block correctly.
2. Author `00-intake.md`, `01-sitemap.md`, `02-wireframe.md` agents + matching `mvp-builder-wordpress-init` / `mvp-builder-wordpress-plan` skill wiring.
3. Add `mvp-builder-wordpress-checkpoint` skill (`approve`/`reject` writers).
4. Wire chrome-devtools MCP screenshot post in orchestrator's gate step.
5. Commit `feat(phase-1): stages 0-2`.

### Subplan 1.5 — Stages 3–5 (content → design → image prompts)

| | |
|---|---|
| Acceptance | Wireframes become themed pages with real content; `04-design.md` has concrete tokens (hex/scale, per §11); `05-image-prompts.md` written |
| Model tier | Sonnet for design strategy + image-prompt synthesis; Haiku for content fill + design application |
| Risk | HIGH (design open-endedness; §11 mitigation) |

Milestones:
1. **RED**: assertion test — `04-design.md` must contain palette hex codes, type scale, spacing scale (regex/structure check). Lorem must be absent from `03-content/*.json` and theme output.
2. Author `03-content.md`, `04-design.md`, `05-image-prompts.md` agents + `mvp-builder-wordpress-build`, `mvp-builder-wordpress-images` skills.
3. Per-page parallel dispatch for stages 3 and 4.
4. Commit `feat(phase-1): stages 3-5`.

### Subplan 1.6 — Stages 6–7 (validate → finalize)

| | |
|---|---|
| Acceptance | `mvp-builder-wordpress-validate` outputs severity report per §10; `mvp-builder-wordpress-finalize` produces final commit + CHANGELOG; orchestrator exits cleanly |
| Model tier | Haiku validator |
| Risk | LOW |

Milestones:
1. **RED**: feed deliberately-broken project → validator must flag CRITICAL on broken render, HIGH on duplicate H1, MEDIUM on spacing; stop on CRITICAL.
2. Author `06-validator.md` + skill; severity table baked in.
3. Author `mvp-builder-wordpress-finalize` skill — runs validator, final commit, CHANGELOG entry, exits orchestrator.
4. Commit `feat(phase-1): stages 6-7`.

### Subplan 1.7 — Synthetic end-to-end run

| | |
|---|---|
| Acceptance | One self-invented brief drives the whole pipeline from `mvp-builder-wordpress-init` to `mvp-builder-wordpress-finalize` without manual intervention beyond checkpoint approvals; final WP site renders in browser |
| Model tier | Sonnet (orchestrator); whatever each stage uses |
| Risk | This is the integration moment |

Milestones:
1. Author synthetic brief (`fixtures/synthetic-brief.md`) — small portfolio site, 4 pages.
2. Run full pipeline; log every stage transition + model call.
3. Capture token-spend report; verify Sonnet call count.
4. If failures: file fixes into appropriate subplan, re-run.
5. Commit `feat(phase-1): synthetic e2e green`.

**Phase 1 exit gate (multi-gate, user approval per subplan + final):** synthetic brief produces a viewable WP site; STATUS.md / ROADMAP.md / CHANGELOG.md current; tag `phase-1-complete`.

---

## Phase 2 — Reviewer Discipline + Token Economy

Tuning phase. Uses Phase 1 evidence to tighten without adding scope.

### Subplan 2.1 — Reviewer false-positive/negative pass

| | |
|---|---|
| Acceptance | From Phase 1 logs: every reviewer flag classified true/false; reviewer prompt updated; regression fixture set added |
| Model tier | Sonnet (judgment) for tuning; Haiku reviewer at runtime |
| Risk | MEDIUM |

Milestones:
1. Mine Phase 1 logs → label each reviewer issue (true positive / false / missed).
2. Add 5 fixture pages exercising true negatives + the misses.
3. Edit `99-code-reviewer.md`; re-run fixtures → expect 100% correct labels.
4. Commit `chore(phase-2): reviewer tuning`.

### Subplan 2.2 — Validator severity tuning

| | |
|---|---|
| Acceptance | Severity table calibrated against Phase 1 evidence; new fixtures for each severity band; HIGH 2-attempt downgrade verified |
| Model tier | Sonnet tuning, Haiku validator |
| Risk | LOW |

Milestones:
1. Bucket Phase 1 issues by severity; reassign if wrong.
2. Update `06-validator.md` + §10 in PLAN.md mirror file.
3. Fixture run; commit `chore(phase-2): validator tuning`.

### Subplan 2.3 — Token-economy proof

| | |
|---|---|
| Acceptance | Two consecutive synthetic runs show ≤5 Sonnet calls each, fully logged |
| Model tier | Haiku for the auditor script |
| Risk | LOW |

Milestones:
1. Add `scripts/audit-tokens.sh` parsing orchestrator JSONL logs.
2. Run twice with different briefs; show report.
3. If overrun: surface and decide (downgrade an agent or accept). Commit `chore(phase-2): token audit`.

### Subplan 2.4 — DocOps hygiene

| | |
|---|---|
| Acceptance | `STATUS.md`, `ROADMAP.md`, `CHANGELOG.md` reflect current state; `/saahilbasak-doc-doctor` clean |
| Model tier | Haiku |
| Risk | LOW |

Milestones:
1. Run doctor; fix flagged drift.
2. Update ROADMAP with Phase 3+ deferred items per §16.
3. Commit `docs(phase-2): hygiene pass`.

**Phase 2 exit gate (single-gate):** doctor clean; both audit runs ≤5 Sonnet; tag `v1.0.0`.

---

## Cross-cutting rules (apply to every subplan)

- **TDD iron law:** no production code without a failing test first. Tests live alongside the agent/skill they exercise.
- **Verification gate:** every milestone's "done" claim shows full test output before commit.
- **Single gate per milestone, multi-gate per subplan boundary.** User approves subplan completion before next subplan starts.
- **Worktree per phase:** `git worktree add .worktrees/phase-N` to isolate; merge to main at phase exit gate.
- **Headless workers:** `claude -p` only; workers write progress before exit; orchestrator can `--resume` on death.
- **State on disk:** every stage transition writes `STATUS.md`. No in-memory continuity between sessions.

---

## Open items requiring user decision before Phase 0 starts

1. **Confirm GitHub repo creation** is OK to do via `gh repo create mvp-builder --public` — or do you want to create it manually first?
2. **Confirm `~/mvp-builder/` path** vs. an alternative (e.g. `~/code/mvp-builder/`).
3. **Test runner choice** for shell + agent tests: `bats` (preferred for shell) + a thin Python harness for agent integration? Or all-`bats`?
4. **WP local stack**: PLAN.md §14 lists wp-env as primary with LocalWP/Lando alternates — lock to **wp-env** for V1, treat others as user-installable later?

Answer these four and Phase 0 Subplan 0.1 can start.
