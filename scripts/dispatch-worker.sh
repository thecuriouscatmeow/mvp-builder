#!/bin/bash
# dispatch-worker.sh — spawn a Haiku worker via claude -p in background
#
# Usage: dispatch-worker.sh <ticket-id> <prompt-file> <log-dir>
#
# Validates args, composes claude command, redirects output to log files,
# writes PID to tracking file. In DRYRUN mode (CLAUDE_DISPATCH_DRYRUN=1),
# uses fake worker instead of real claude invocation.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: dispatch-worker.sh <ticket-id> <prompt-file> <log-dir>" >&2
  exit 1
fi

ticket_id="$1"
prompt_file="$2"
log_dir="$3"

# Validate ticket-id is non-empty
if [[ -z "$ticket_id" ]]; then
  echo "Error: ticket-id cannot be empty" >&2
  exit 1
fi

# Validate prompt-file exists
if [[ ! -f "$prompt_file" ]]; then
  echo "Error: prompt file does not exist: $prompt_file" >&2
  exit 1
fi

# Create log-dir if it doesn't exist
if [[ ! -d "$log_dir" ]]; then
  mkdir -p "$log_dir"
fi

log_file="${log_dir}/${ticket_id}.jsonl"
err_file="${log_dir}/${ticket_id}.err"
pid_file="${log_dir}/${ticket_id}.pid"

# Read the prompt
prompt_content="$(cat "$prompt_file")"

if [[ "${CLAUDE_DISPATCH_DRYRUN:-}" == "1" ]]; then
  # DRYRUN mode: use fake worker if available, else just sleep
  : > "$err_file"
  if [[ "${STAGE2_FAKE:-}" == "1" ]]; then
    # Stage 2 fake worker: extract PROJECT_DIR and PAGE_SLUG from prompt file
    fake_stage2="${log_dir}/../../../scripts/test-fake-stage2-worker.sh"
    if [[ ! -f "$fake_stage2" ]]; then
      fake_stage2="$HOME/mvp-builder/scripts/test-fake-stage2-worker.sh"
    fi
    project_dir=$(awk -F= '/^PROJECT_DIR=/{print $2}' "$prompt_file")
    page_slug=$(awk -F= '/^PAGE_SLUG=/{print $2}' "$prompt_file")
    bash "$fake_stage2" "$project_dir" "$page_slug" >> "$log_file" 2>> "$err_file" &
    dispatch_pid=$!
  elif [[ "${STAGE3_FAKE:-}" == "1" ]]; then
    # Stage 3 fake worker: content-worker
    fake_stage3="${log_dir}/../../../scripts/test-fake-stage3-worker.sh"
    if [[ ! -f "$fake_stage3" ]]; then
      fake_stage3="$HOME/mvp-builder/scripts/test-fake-stage3-worker.sh"
    fi
    project_dir=$(awk -F= '/^PROJECT_DIR=/{print $2}' "$prompt_file")
    page_slug=$(awk -F= '/^PAGE_SLUG=/{print $2}' "$prompt_file")
    bash "$fake_stage3" "$project_dir" "$page_slug" >> "$log_file" 2>> "$err_file" &
    dispatch_pid=$!
  elif [[ "${STAGE4_FAKE:-}" == "1" ]]; then
    # Stage 4 fake worker: design-apply worker
    fake_stage4="${log_dir}/../../../scripts/test-fake-stage4-worker.sh"
    if [[ ! -f "$fake_stage4" ]]; then
      fake_stage4="$HOME/mvp-builder/scripts/test-fake-stage4-worker.sh"
    fi
    project_dir=$(awk -F= '/^PROJECT_DIR=/{print $2}' "$prompt_file")
    page_slug=$(awk -F= '/^PAGE_SLUG=/{print $2}' "$prompt_file")
    bash "$fake_stage4" "$project_dir" "$page_slug" >> "$log_file" 2>> "$err_file" &
    dispatch_pid=$!
  else
    # Generic fake worker for other stages
    fake_worker_script="${log_dir}/../scripts/test-fake-worker.sh"
    if [[ -f "$fake_worker_script" ]]; then
      FAKE_WORKER_LOG="$log_file" bash "$fake_worker_script" 2>> "$err_file" &
    else
      (sleep 1 && echo '{"type":"test-event"}' > "$log_file") 2>> "$err_file" &
    fi
    dispatch_pid=$!
  fi
else
  # Real mode: invoke claude -p
  claude -p "$prompt_content" --model haiku --output-format stream-json --permission-mode bypassPermissions \
    > "$log_file" 2> "$err_file" &
  dispatch_pid=$!
fi

# Write PID to tracking file
echo "$dispatch_pid" > "$pid_file"

# Output the PID
echo "$dispatch_pid"
exit 0
