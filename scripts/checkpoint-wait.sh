#!/bin/bash
# checkpoint-wait.sh — poll checkpoints directory for approval or rejection
#
# Usage: checkpoint-wait.sh <project-dir> <page> <stage> [--timeout <seconds>]
#
# Polls for <project-dir>/docs/checkpoints/<page>.<stage>.approved (exit 0)
# or <project-dir>/docs/checkpoints/<page>.<stage>.feedback.md (exit 2).
# Returns exit 3 on timeout. In NO_POLL mode, checks once and returns immediately.

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: checkpoint-wait.sh <project-dir> <page> <stage> [--timeout <seconds>]" >&2
  exit 1
fi

project_dir="$1"
page="$2"
stage="$3"
timeout_seconds=7200

# Parse optional --timeout
if [[ $# -gt 3 ]] && [[ "$4" == "--timeout" ]]; then
  if [[ -z "${5:-}" ]]; then
    echo "Error: --timeout requires an argument" >&2
    exit 1
  fi
  timeout_seconds="$5"
fi

checkpoints_dir="${project_dir}/docs/checkpoints"
approved_marker="${checkpoints_dir}/${page}.${stage}.approved"
feedback_file="${checkpoints_dir}/${page}.${stage}.feedback.md"

# If CHECKPOINT_WAIT_NO_POLL is set, check once and return immediately
if [[ "${CHECKPOINT_WAIT_NO_POLL:-}" == "1" ]]; then
  if [[ -f "$approved_marker" ]]; then
    echo "APPROVED"
    exit 0
  fi
  if [[ -f "$feedback_file" ]]; then
    echo "REJECTED $feedback_file"
    exit 2
  fi
  # Neither exists in NO_POLL mode
  echo "WAITING"
  exit 1
fi

# Normal polling mode
elapsed=0
poll_interval=5

while [[ $elapsed -lt $timeout_seconds ]]; do
  if [[ -f "$approved_marker" ]]; then
    echo "APPROVED"
    exit 0
  fi
  if [[ -f "$feedback_file" ]]; then
    echo "REJECTED $feedback_file"
    exit 2
  fi

  sleep "$poll_interval"
  elapsed=$((elapsed + poll_interval))
done

# Timeout reached
echo "TIMEOUT"
exit 3
