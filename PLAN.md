# mvp-builder — Draft Plan (v3)

> Status: **draft v3** — all open questions answered; ready for Codex re-review.
> After acceptance: `/saahilbasak-init` + `/saahilbasak-plan` produce the implementation plan.

---

## 1. Locked decisions

| # | Decision | Detail |
|---|---|---|
| 1 | **System name & repo** | `mvp-builder`. Lives locally at `~/mvp-builder/`. Public GitHub repo of the same name, kept in sync. |
| 2 | **V1 platform scope** | **WordPress, fresh-canvas only.** Shopify + existing-theme + Next/React + foreign adapters deferred. See §2. |
| 3 | **Skill naming** | All user-facing skills follow `mvp-builder-<platform>-<verb>`. V1 set: `mvp-builder-wordpress-setup`, `mvp-builder-wordpress-init`, `mvp-builder-wordpress-plan`, `mvp-builder-wordpress-build`, `mvp-builder-wordpress-images`, `mvp-builder-wordpress-validate`, `mvp-builder-wordpress-checkpoint`, `mvp-builder-wordpress-finalize`. |
| 4 | **Per-project workspace** | You handle it. Open the project folder you want, then invoke `mvp-builder-wordpress-init` there. System does not own a path convention. |
| 5 | **Image generation** | Manual. System produces `05-image-prompts.md` (path, slot id, prompt, dims, mood). You feed it to Antigravity (nano-banana). |
| 6 | **Agent runtime** | Orchestrator subagent style. Orchestrator (Sonnet) dispatches tickets to **parallel Haiku workers**. Disk-first state. Headless `claude -p` for long runs. |
| 7 | **Agent file shape** | Thin agents. Instructions broken into atomic tickets. Workers do not plan; they consume one ticket and exit. |
| 8 | **Model tier policy** | Opus/Sonnet **only** for: brand-voice, design strategy, image-prompt synthesis, plan generation, subplan decomposition. **Haiku for everything else.** Target: ≤5 Sonnet calls per project. |
| 9 | **Reviewer mode** | "Interview survival validator," not "senior engineer." Hard rules, hard stop, severity-weighted. No refactor suggestions. Haiku tier. |
| 10 | **Checkpoint cadence** | **Per page, not per component.** Wireframe + design stages gate per page; content + image-prompts get one bulk review each. |
| 11 | **Git discipline** | Standard practice. System repo: commit per logical change. Per-project: `git init` at `mvp-builder-wordpress-init`, commit at each stage completion so any stage is rollback-able, final commit at `mvp-builder-wordpress-finalize`. |

---

## 2. V1 scope freeze

**In scope:**
- Claude Code only
- WordPress only
- Fresh-canvas only
- Single execution path, single orchestrator
- Phase 0 WordPress dev environment setup (see §14)

**Explicitly deferred until 5–10 successful interview builds:**
- Adapter layer / multi-platform runtime support (Gemini/Codex/Cursor)
- Existing-theme branch (`file-map.md`, `impact-map.md`)
- Shopify templates + standards
- Fresh-canvas Next/React
- Design archetype library (§16)
- Headless resume protocol sophistication
- Generalized cross-runtime contracts

Build order, not permanent cut. Infrastructure procrastination is the real risk.

---

## 3. Mental model

```
intake → sitemap → wireframe → content → design → image-prompts → validator → finalize
```

Three load-bearing ideas:

1. **Disk is memory.** Agents read on entry, write on exit. Context windows are scratch space.
2. **Tickets, not tasks.** A ticket is the smallest unit a Haiku worker can complete without judgment. Orchestrator owns sequencing; worker owns execution.
3. **Human is judgment, not labor.** Per-page checkpoints, no per-component babysitting.

---

## 4. Folder structure (V1)

System layer:

```
~/mvp-builder/                       # public GitHub repo
  .claude/
    agents/
      00-intake.md
      01-sitemap.md
      02-wireframe.md
      03-content.md
      04-design.md
      05-image-prompts.md
      06-validator.md
      99-code-reviewer.md
      orchestrator.md
    commands/                         # the user-facing skills
      mvp-builder-wordpress-setup.md
      mvp-builder-wordpress-init.md
      mvp-builder-wordpress-plan.md
      mvp-builder-wordpress-build.md
      mvp-builder-wordpress-images.md
      mvp-builder-wordpress-validate.md
      mvp-builder-wordpress-checkpoint.md
      mvp-builder-wordpress-finalize.md
    settings.json
    hooks/
      lorem-check.sh
      changelog-guard.sh
  templates/
    wordpress/
      coding-standards.md
      known-issues.md
      requirements.template.md
      sitemap.template.md
      brand-voice.template.md
      design.template.md
      image-guidelines.template.md
  scripts/
    setup-wordpress-env.sh            # Phase 0 installer
  CLAUDE.md
  STATUS.md
  ROADMAP.md
  CHANGELOG.md
  README.md
```

> Platform-neutral naming so we can extract an adapter layer later without renaming. **Not building** that abstraction in V1.

Per-project workspace (created by `mvp-builder-wordpress-init` wherever you invoke it):

```
<project>/
  docs/
    00-requirements.md
    01-sitemap.md
    02-wireframes/             # standalone HTML, openable in browser
    03-content/                # JSON per page
    04-design.md
    05-image-prompts.md
    06-images/                 # populated manually via Antigravity
    99-known-issues.md
    CHANGELOG.md
    checkpoints/               # marker files: <page>.<stage>.approved
  src/wp-content/themes/<theme>/
  .claude/
```

---

## 5. Stage pipeline

| Stage | Skill | Reads | Writes | Model | Parallel? | Checkpoint |
|---|---|---|---|---|---|---|
| 0 intake | `mvp-builder-wordpress-init` | raw prompt | `00-requirements.md` | Sonnet | no | none |
| 1 sitemap | `mvp-builder-wordpress-plan` | requirements | `01-sitemap.md` (pages, H-hierarchy, loading strategy) | Sonnet | no | none |
| 2 wireframe | `mvp-builder-wordpress-plan` | sitemap | `02-wireframes/<page>.html` | Haiku × N pages | **yes** | **per page** |
| 3 content | `mvp-builder-wordpress-build` | sitemap, brand-voice, wireframes | `03-content/<page>.json` | Haiku × N pages | **yes** | one bulk |
| 4 design | `mvp-builder-wordpress-build` | design.md, content, wireframes | merges into wireframes / writes theme CSS | Haiku × N pages | **yes** | **per page** |
| 5 image-prompts | `mvp-builder-wordpress-images` | design, image-guidelines, wireframes | `05-image-prompts.md` | Haiku | no | one bulk |
| 6 validator | `mvp-builder-wordpress-validate` | everything | validation report | Haiku | no | one bulk |
| 7 finalize | `mvp-builder-wordpress-finalize` | everything | git commit, CHANGELOG, close worktree | orchestrator | no | none |

**Hard handoff rule:** every worker reads inputs from disk on startup. Nothing passed by argument except `{project_root, target_page, ticket_id}`.

**Git rule:** orchestrator commits after each stage completes (`stage-N: <name>` message). Any stage is rollback-able via `git reset`.

---

## 6. Model strategy & token economy

**Sonnet/Opus allowed in (≤5 calls/project):**
- Intake normalization
- Brand-voice synthesis
- Design strategy
- Image-prompt synthesis
- Plan + subplan generation

**Haiku does everything else:** wireframe scaffolding, content fill, design application, validation, reviewer, file edits.

**Why this works:** tickets are atomic and inputs are on disk → Haiku is doing transformation, not reasoning. Sonnet did the thinking once and wrote it down; Haiku reads it.

**Parallelism rule:** stages marked "parallel" in §5 dispatch one worker per page simultaneously. 5 pages = 5 concurrent Haiku workers.

**Context hygiene rule:** orchestrator never reads page artifacts into its context unless gating a checkpoint. Workers never read other pages' artifacts. Cross-page deps live in `01-sitemap.md` and `04-design.md` only.

---

## 7. Orchestrator subagent pattern

The orchestrator is the only long-running thing. Responsibilities:

1. **Sequence stages** — dispatch, never execute.
2. **Parallel fan-out** — for parallelizable stages, launch N workers (one per page) and wait.
3. **Checkpoint gating** — block on file markers in `docs/checkpoints/`.
4. **Context hygiene** — read filenames, not contents, except when gating.
5. **Failure handling** — worker dies → re-dispatch same ticket. After 2 retries, surface.
6. **Token budget** — track per-stage; flag overruns.
7. **Cold resume** — persists state to `STATUS.md` after every stage transition.

```
orchestrator
  ├── dispatch(stage=2, page=home) → worker (Haiku, headless)
  ├── dispatch(stage=2, page=shop) → worker (Haiku, headless)
  ├── dispatch(stage=2, page=product) → worker (Haiku, headless)
  ├── wait for {home,shop,product}.html on disk
  ├── for each page: dispatch(99-code-reviewer, page) → verdict
  ├── on all clean: prompt human "review home/shop/product"
  ├── git commit -m "stage-2: wireframes"
  └── on all approved: advance to stage 3
```

Workers and reviewer are stateless. Only orchestrator survives across stages.

---

## 8. Checkpoint protocol

1. All workers for a stage finish; artifacts on disk.
2. `lorem-check` hook fires (must have lorem in wireframe stage; must NOT have lorem in content/design).
3. Orchestrator dispatches `99-code-reviewer` per page.
4. On clean reviewer pass, orchestrator opens each page via chrome-devtools MCP, screenshots, posts: `Review home — screenshot attached, devtools open.`
5. Orchestrator blocks on `checkpoints/<page>.<stage>.approved`.
6. You approve via `mvp-builder-wordpress-checkpoint` slash command, or reject by writing `<page>.<stage>.feedback.md`.
7. On rejection, orchestrator dispatches a fix ticket reading the feedback file.

**Checkpoint count per project:** ~5 pages × 2 gated stages + 2 bulk reviews ≈ **12 human-glance moments** across a 2–3 hour build.

---

## 9. Reviewer agent constraints

`99-code-reviewer.md` operates under hard rules.

**Reviewer MUST flag:**
- Broken render (`undefined`, missing data, broken image src)
- Missing required sections from sitemap
- Heading hierarchy violations (multiple H1, skipped levels)
- Mobile layout breakage
- CSS override chains (>1 override of the same rule)
- Lorem ipsum leaking past wireframe stage

**Reviewer MUST NOT:**
- Suggest refactors
- Comment on architecture, abstraction quality, scalability
- Complain about minor visual inconsistencies (use §10 severity instead)
- Recommend additional features
- Run more than one pass per component

**Hard stop:** one pass. Returns issue list and exits. Orchestrator decides whether to dispatch a fix; reviewer never loops.

**Model:** Haiku. Strong models become perfectionism machines.

---

## 10. Validator severity model

| Severity | Examples | Action |
|---|---|---|
| **CRITICAL** | Broken mobile nav, `undefined` rendering, missing required page | **Block.** Fix before next stage. |
| **HIGH** | Duplicate H1, missing alt text on hero, broken image src, CSS override chain | **Fix.** Immediate fix ticket dispatched. |
| **MEDIUM** | Inconsistent spacing on a single page, slightly off button radius | **Note & continue.** Logged to `99-known-issues.md`. |
| **LOW** | Subtle shadow variance, hover state slightly off-spec | **Ignore in V1.** Logged for future. |
| **IGNORE** | Code style preferences, comment density, abstraction opportunities | **Never raise.** Out of scope. |

Time budget: validator stops on first CRITICAL. HIGH issues get max 2 fix attempts before downgrade to MEDIUM and noted.

---

## 11. Open-design risk note

Codex correctly flagged that open-ended design is a speed killer. V2 will introduce a reusable archetype library (see §16). For V1 we accept the risk because:

- The first real test scenario (a "build this site similar" interview task) starts from an existing reference site, so design space is naturally constrained.
- Adding the archetype library now would delay V1 ship without proving the pipeline.

Mitigation in V1: the design strategy stage (Sonnet) must produce a `04-design.md` with concrete values (palette hex codes, type scale, spacing scale, card/button specs) before stage 4 dispatches workers. No "vibe" descriptions allowed.

---

## 12. Headless runtime (minimal V1)

From `subagent_config.md`: in-session subagents die at the 5-hour wall.

- Parallel workers launch as `claude -p "<ticket>" --output-format stream-json > logs/<ticket>.jsonl`
- Each worker prompt ends with: "write progress to `<path>` before exiting; assume you may be killed."
- Tiny tickets → death-cost is small.
- Resume: `claude --resume <session-id>` if a worker died mid-flight.

V1 uses the primitive in its simplest form. Sophistication is deferred (§16).

---

## 13. Lifecycle commands

| Skill | Phase | Action |
|---|---|---|
| `mvp-builder-wordpress-setup` | 0 | Installs/verifies WP-CLI, wp-env, PHP, Node, Composer; bootstraps a clean local WP instance with sample data. One-time per machine. |
| `mvp-builder-wordpress-init` | 0/1 | Bootstraps `<project>/` in the current dir, copies WordPress templates, runs intake stage |
| `mvp-builder-wordpress-plan` | 1–2 | Runs sitemap + wireframe stages, gates per-page checkpoints |
| `mvp-builder-wordpress-build` | 3–4 | Runs content + design stages, gates per-page checkpoints |
| `mvp-builder-wordpress-images` | 5 | Generates `05-image-prompts.md`, one bulk review |
| `mvp-builder-wordpress-validate` | 6 | Runs validator pass, surfaces CRITICAL/HIGH report |
| `mvp-builder-wordpress-checkpoint` | any | `approve <page> <stage>` or `reject <page> <stage> "<feedback>"` |
| `mvp-builder-wordpress-finalize` | 7 | Validator, final commit, CHANGELOG, close worktree, orchestrator exits |

---

## 14. Build phases

**Phase 0 — WordPress dev environment setup.**
Before any build pipeline runs, the host machine needs:
- WP-CLI installed and on PATH
- `@wordpress/env` (Docker-based local server) or equivalent (LocalWP, Lando)
- PHP 8.x + Composer
- Node + npm (for block theme tooling, `@wordpress/scripts`)
- MySQL (via wp-env's containerized DB)
- A scripted way to spin up a fresh local WP, upload theme unit test data, and tear down
- WP_DEBUG enabled by default in the local env

Deliverable: `scripts/setup-wordpress-env.sh` that idempotently sets all of this up and verifies it works. Plus `mvp-builder-wordpress-setup` skill that wraps it with confirmation prompts.

**Phase 1 — System skeleton + pipeline end-to-end.**
- Repo created on GitHub (public)
- Folder structure per §4
- All agent files + skill files authored (thin, ticket-shaped)
- Orchestrator agent with parallel dispatch
- Lorem-check hook + chrome-devtools MCP wired
- Git commits at every stage transition
- One synthetic test brief run end-to-end (system-invented, not real)

**Phase 2 — Reviewer discipline & polish from Phase 1 misses.**
- Tighten `99-code-reviewer` based on Phase 1 false positives/negatives
- Tune validator severity table from Phase 1 evidence
- Confirm token economy (≤5 Sonnet calls/project actually held)
- STATUS.md / ROADMAP.md / CHANGELOG.md hygiene

**Post-V1 validation (not part of the build plan, but the success gate):**
A real interview-style task — given a reference site, build something similar in WordPress. Time-boxed to 1–2 hours. If the system passes this, V1 is done. If not, identified gaps feed into V2.

**Phases 3+: deferred.** Existing-theme, Shopify, fresh-canvas Next, adapter layer, archetype library — see §16.

---

## 15. Non-goals

- Production-grade code quality
- Autonomous end-to-end
- Universal-anything
- Image generation inside the system
- Anything not moving "ship one good interview build in 2–3 hours" forward

---

## 16. Deferred (will emerge from real use)

Each unlocks when 5–10 V1 builds prove the system.

- **Design archetype library** — `archetypes/premium-fitness.md`, `modern-saas.md`, `boutique-wellness.md` etc., each predefining palette / type / spacing / card / button / image direction / animation. Graduates from successful V1 builds.
- **Existing-theme branch** — `file-map.md` + `impact-map.md` (component → cross-page effects). Gates on first existing-theme interview.
- **Shopify support** — `mvp-builder-shopify-*` skill set + Shopify templates. Gates on first Shopify interview after V1 stabilizes.
- **Fresh-canvas Next/React** — `mvp-builder-next-*`. Gates on first frontend-framework interview.
- **Adapter layer** — Gemini/Codex/Cursor. Gates on actually wanting to use another runtime.
- **Headless resume sophistication** — only if the 5-hour wall bites in practice.
- **Cross-platform `coding-standards.md` curation** — incremental.

---

## 17. Open questions

**All answered:**

1. System path → `~/mvp-builder/` + fresh public GitHub repo `mvp-builder`.
2. Per-project workspace → user-managed; skill runs in current directory.
3. Git discipline → standard practice; commit at every stage completion for rollback.
4. Archetypes → deferred to V2 (see §11, §16).
5. Test brief → not part of build plan; real interview-style task runs as post-V1 validation gate. Phase 0 added to plan to set up WordPress dev environment first.

---

## 18. After acceptance

I will:
1. Create the **public GitHub repo** `mvp-builder` (asking before push).
2. Run `/saahilbasak-init` inside `~/mvp-builder/` — creates STATUS.md, ROADMAP.md, CHANGELOG.md, `decisions/`, `graphify-out/`, appends CLAUDE.md section.
3. Run `/saahilbasak-plan` against this draft — produces classified plan (SMALL/MEDIUM/LARGE) with TDD steps and subagent dispatch wiring, split across Phase 0 and Phase 1.
4. Surface the plan for your review before any code is written.
