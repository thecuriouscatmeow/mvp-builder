# CLAUDE.md — mvp-builder

System for building interview-style MVP websites. WordPress-only V1, fresh-canvas only.

## Truth order
PLAN.md (locked spec) > IMPLEMENTATION_PLAN.md > code > STATUS.md > ROADMAP.md > CHANGELOG.md.

## Model tier policy
Sonnet/Opus only for: brand-voice, design strategy, image-prompt synthesis, plan generation, subplan decomposition. Target ≤5 Sonnet calls per project. Haiku for everything else.

## Orchestration
Single long-running orchestrator (Sonnet). Workers are stateless Haiku, dispatched headless via `claude -p`. Disk is memory; agents read on entry and write on exit.

## Invariant: zero external API keys
Nothing in this system may require an API key, secret, or paid third-party credential to run. Everything is a Claude Code skill, agent, MCP integration, or local CLI (`wp-cli`, `wp-env`, `gh`, `git`, `node`, `php`, `composer`). Headless workers use `claude -p` which inherits the user's Claude Code session — no separate Anthropic API key. Image generation stays manual via the user's Antigravity workflow. If a feature seems to need a key, redesign it as a skill or drop it.

## saahilbasak

### Session Start
Read: STATUS.md (always)
Read: graphify-out/GRAPH_REPORT.md quick index (always, if exists)
If Graphify installed: `graphify hook status` — note stale, don't block work
If Graphify not installed: continue normally, read GRAPH_REPORT.md as static reference

### Before Touching Existing Code
If Graphify available:
  1. `graphify explain "ModuleName"` (--budget 600)
  2. `graphify path "A" "B"` if impact unclear
  3. `graphify query "what uses X?" --budget 800` for broader context
If Graphify unavailable:
  Read GRAPH_REPORT.md named section for that module. If absent, read source file directly.

### Truth Order
PLAN.md > IMPLEMENTATION_PLAN.md > Code/tests > Git > Graphify graph > Docs > Memory summaries
Docs conflict with code → fix docs

### Approval Tiers
AUTO: doc sync, graph refresh, comment edits, CHANGELOG rotation, test-only
SINGLE GATE: bug fix, milestone completion, small feature done
MULTI-GATE: schema migration, auth/security/payment, architecture, new roadmap phase

### Escalation (auto-promote small → medium)
>3 files | HIGH_RISK module (auth/payment/schema/security/db-migration)
| test fails twice | LOW/STALE graph confidence on a needed dependency

### Milestone Hook (fires per milestone, never per micro-step)
1. Run test command → show full output
2. Only if tests PASS: output "✓ Milestone N complete — [what] [files] | Tests: [N]/[N]"
3. Ask: "Commit and continue? (y/n)" — WAIT
4. On Y: git commit → sync hook
If tests FAIL: stop, show failures, do not ask for approval

### Session End
/saahilbasak-sync before ending any session with dev work

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
