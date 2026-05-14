---
name: mvp-builder-wordpress-setup
description: Bootstrap the local WordPress dev environment for mvp-builder. Idempotent. Use at machine setup or when wp-env is broken. Wraps `scripts/setup-wordpress-env.sh` with confirmation prompts.
---

# mvp-builder-wordpress-setup

User-facing slash command for Phase 0 environment setup. Thin wrapper around `scripts/setup-wordpress-env.sh`.

## When to invoke

- First-time machine setup before any project build.
- After upgrading macOS / Homebrew if anything broke.
- When `wp-env start` fails and you want to reset.

**Do NOT invoke** inside a project workspace — this is a system-level skill. Run it from `~/mvp-builder/` or any directory; it operates on the host, not the cwd.

## Arguments

| Arg | Behavior |
|-----|----------|
| (none) | Confirm with user, then full install + `wp-env start` |
| `--check` | Verify presence of all tools without modifying anything. Exit 0 if green, 1 if missing. |
| `--reset` | `wp-env destroy` then `wp-env start` from scratch. Confirm with user first. |
| `--yes` | Skip the interactive confirmation prompt (useful when invoked from another skill). |

Args pass through to the script unchanged.

## Execution

1. **Locate the script.** It lives at `~/mvp-builder/scripts/setup-wordpress-env.sh`. If absent, tell the user the mvp-builder system isn't installed and stop.
2. **For bare or `--reset` invocations:** state plainly what will happen (brew/npm installs, Docker requirement, `wp-env start`) and confirm with the user before running. Skip the confirmation if `--yes` was passed.
3. **Run the script with the passed args.** Use a Bash tool call with a long enough timeout (`600000` ms) — the first run may take 5–15 minutes for brew + Docker image pulls.
4. **On exit code 0:** report the final state — tool versions, WordPress URL (`http://localhost:8888`), whether the env is running. Do not re-run anything.
5. **On non-zero exit:** show the last 30 lines of output verbatim. Common failures:
   - Docker daemon not running → tell user to launch Docker Desktop and re-invoke. Do not try to start it.
   - PHP version not 8.x → tell user to `brew unlink php@<other> && brew link php`. Do not auto-resolve.
   - `wp-env start` git/network error → suggest `--reset` and re-run.

## Constraints (inherited from CLAUDE.md)

- No API keys. No secrets. No `sudo`. Public package managers only.
- Idempotent. Re-running on a clean machine must short-circuit each step.
- Confirmation gate before any system modification (overridable with `--yes`).

## Verification

After running, you may call `bats ~/mvp-builder/tests/setup-wordpress-env.bats` — all 11 assertions should pass when the env is healthy.
