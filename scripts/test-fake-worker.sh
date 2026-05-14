#!/bin/bash
# test-fake-worker.sh — test helper; simulates a Haiku worker in DRYRUN mode
#
# Used by dispatch-worker.sh in DRYRUN mode. Sleeps briefly, writes a fake
# stream-json event to the log file, and exits cleanly. Only for testing.
#
# Env var FAKE_WORKER_LOG specifies the output file; if not set, writes to stdout.

set -euo pipefail

# Sleep a short time to simulate work
sleep 0.5

# Write fake stream-json event
fake_event='{"type":"message","role":"assistant","content":"test output"}'

if [[ -n "${FAKE_WORKER_LOG:-}" ]]; then
  echo "$fake_event" >> "$FAKE_WORKER_LOG"
else
  echo "$fake_event"
fi

exit 0
