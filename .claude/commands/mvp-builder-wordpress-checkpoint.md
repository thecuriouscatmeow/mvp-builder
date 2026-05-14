---
name: mvp-builder-wordpress-checkpoint
description: Approve or reject a per-page checkpoint marker. Usage: /mvp-builder-wordpress-checkpoint approve <page> <stage> | reject <page> <stage> "<feedback>"
---

# /mvp-builder-wordpress-checkpoint

## Signature

```
/mvp-builder-wordpress-checkpoint approve <page> <stage>
/mvp-builder-wordpress-checkpoint reject <page> <stage> "<feedback>"
```

## Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `approve` | command | Approve a checkpoint for a page at a given stage. |
| `<page>` | string | Page slug (e.g., `home`, `about`). |
| `<stage>` | integer | Stage number (e.g., `2` for wireframes). |
| `reject` | command | Reject a checkpoint and provide feedback. |
| `<feedback>` | string | Freeform feedback text (must be quoted). |

## Action

- **Approve**: Write `docs/checkpoints/<page>.<stage>.approved` (empty marker file). Create `docs/checkpoints/` if absent.
- **Reject**: Write `docs/checkpoints/<page>.<stage>.feedback.md` with the feedback as the markdown body.
- Print confirmation to stdout.
- Do NOT invoke the orchestrator. The orchestrator polls via `checkpoint-wait.sh` and will pick the marker file up.

## Failure Modes

- If both `<page>.<stage>.approved` and a `.feedback.md` file exist: refuse (race condition). User must manually resolve.
- If `<page>` or `<stage>` are invalid: print usage and exit 1.

## Examples

```bash
/mvp-builder-wordpress-checkpoint approve home 2
/mvp-builder-wordpress-checkpoint reject about 2 "Hero image needs better alt text; features grid is too wide"
```
