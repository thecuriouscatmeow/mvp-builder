---
name: mvp-builder-wordpress-validate
description: Run stage 6 validator on the current project and surface the severity report. Stops on first CRITICAL.
---

# Validate Project Command

## When to invoke
Any time you want a health check. Always run before `mvp-builder-wordpress-finalize`.

## Action
- Call `~/mvp-builder/scripts/validate-project.sh $PWD`
- Parse JSON output
- Print human-readable summary (counts by severity, top 3 issues)
- Echo full JSON to log file `logs/validate-<timestamp>.json`

## Outputs
- On `verdict: block` — surface the CRITICAL issue and refuse to proceed
- On `verdict: warn` — print the HIGH list and ask whether to continue
- On `verdict: pass` — congratulate the user
