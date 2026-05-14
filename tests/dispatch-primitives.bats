#!/usr/bin/env bats
# dispatch-primitives.bats — test suite for dispatch-worker, checkpoint-wait, stage-commit

setup() {
  export TMPDIR="${BATS_TEST_TMPDIR:-/tmp}"
  test_temp=$(mktemp -d)
  export TEST_TEMP="$test_temp"
  export SCRIPTS_DIR="$(cd "$BATS_TEST_DIRNAME/../scripts" && pwd)"
}

teardown() {
  if [[ -n "${TEST_TEMP:-}" && -d "$TEST_TEMP" ]]; then
    rm -rf "$TEST_TEMP"
  fi
}

# ============================================================================
# dispatch-worker.sh tests
# ============================================================================

@test "dispatch-worker: rejects missing prompt-file early" {
  run "$SCRIPTS_DIR/dispatch-worker.sh" "test" "/nonexistent/file" "$TEST_TEMP/logs"
  [[ $status -ne 0 ]]
}

@test "dispatch-worker: rejects missing args" {
  run "$SCRIPTS_DIR/dispatch-worker.sh"
  [[ $status -ne 0 ]]
}

@test "dispatch-worker: in DRYRUN mode, creates pid file and log file" {
  mkdir -p "$TEST_TEMP/logs"
  echo "test prompt" > "$TEST_TEMP/prompt.txt"

  export CLAUDE_DISPATCH_DRYRUN=1
  run "$SCRIPTS_DIR/dispatch-worker.sh" "test-ticket-1" "$TEST_TEMP/prompt.txt" "$TEST_TEMP/logs"
  [[ $status -eq 0 ]]

  # Wait for fake worker to complete
  sleep 1

  # Check that .pid file exists
  [[ -f "$TEST_TEMP/logs/test-ticket-1.pid" ]]

  # Check that .jsonl file exists
  [[ -f "$TEST_TEMP/logs/test-ticket-1.jsonl" ]]

  # Check that .err file exists (even if empty)
  [[ -f "$TEST_TEMP/logs/test-ticket-1.err" ]]
}

@test "dispatch-worker: writes a numeric PID to .pid file" {
  mkdir -p "$TEST_TEMP/logs"
  echo "test prompt" > "$TEST_TEMP/prompt.txt"

  export CLAUDE_DISPATCH_DRYRUN=1
  output=$("$SCRIPTS_DIR/dispatch-worker.sh" "test-ticket-2" "$TEST_TEMP/prompt.txt" "$TEST_TEMP/logs")
  sleep 1

  pid_content=$(cat "$TEST_TEMP/logs/test-ticket-2.pid")

  # Verify it's a number
  [[ "$pid_content" =~ ^[0-9]+$ ]]

  # Verify it matches the output
  [[ "$output" == "$pid_content" ]]
}

# ============================================================================
# checkpoint-wait.sh tests
# ============================================================================

@test "checkpoint-wait: returns APPROVED when marker exists" {
  mkdir -p "$TEST_TEMP/project/docs/checkpoints"

  # Create the approval marker
  touch "$TEST_TEMP/project/docs/checkpoints/home.2.approved"

  export CHECKPOINT_WAIT_NO_POLL=1
  run "$SCRIPTS_DIR/checkpoint-wait.sh" "$TEST_TEMP/project" "home" "2"
  [[ $status -eq 0 ]]
  [[ "$output" == "APPROVED" ]]
}

@test "checkpoint-wait: returns REJECTED when feedback file exists" {
  mkdir -p "$TEST_TEMP/project/docs/checkpoints"

  # Create the feedback file
  echo "Feedback here" > "$TEST_TEMP/project/docs/checkpoints/shop.3.feedback.md"

  export CHECKPOINT_WAIT_NO_POLL=1
  run "$SCRIPTS_DIR/checkpoint-wait.sh" "$TEST_TEMP/project" "shop" "3"
  [[ $status -eq 2 ]]
  [[ "$output" == *"REJECTED"* ]]
  [[ "$output" == *"shop.3.feedback.md" ]]
}

@test "checkpoint-wait: returns TIMEOUT when neither exists" {
  mkdir -p "$TEST_TEMP/project/docs/checkpoints"

  # Timeout after 1 second for testing
  run "$SCRIPTS_DIR/checkpoint-wait.sh" "$TEST_TEMP/project" "product" "4" --timeout 1

  # Should exit with code 3 (timeout)
  [[ $status -eq 3 ]]
  [[ "$output" == "TIMEOUT" ]]
}

# ============================================================================
# stage-commit.sh tests
# ============================================================================

@test "stage-commit: rejects when target dir is not a git repo" {
  mkdir -p "$TEST_TEMP/not-a-repo"

  run "$SCRIPTS_DIR/stage-commit.sh" "$TEST_TEMP/not-a-repo" "1" "intake"
  [[ $status -ne 0 ]]
}

@test "stage-commit: prints NO_CHANGES on clean repo" {
  mkdir -p "$TEST_TEMP/clean-repo"
  cd "$TEST_TEMP/clean-repo"
  git init

  run "$SCRIPTS_DIR/stage-commit.sh" "$TEST_TEMP/clean-repo" "1" "intake"
  [[ $status -eq 0 ]]
  [[ "$output" == "NO_CHANGES" ]]
}

@test "stage-commit: commits with proper message on dirty repo" {
  mkdir -p "$TEST_TEMP/dirty-repo"
  cd "$TEST_TEMP/dirty-repo"
  git init
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create a file
  echo "test content" > test.txt

  run "$SCRIPTS_DIR/stage-commit.sh" "$TEST_TEMP/dirty-repo" "3" "content"
  [[ $status -eq 0 ]]

  # Verify commit was created
  cd "$TEST_TEMP/dirty-repo"
  commit_subject=$(git log -1 --pretty=%s)
  [[ "$commit_subject" == "stage-3: content" ]]
}
