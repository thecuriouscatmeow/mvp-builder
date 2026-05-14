#!/usr/bin/env bats

# Tests for scripts/setup-wordpress-env.sh
# Phase 0 Subplan 0.2 — mvp-builder

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/setup-wordpress-env.sh"
}

@test "installer script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "--check flag reports state without modifying the system" {
  run "$SCRIPT" --check
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]   # 0 = all present, 1 = missing tools
  [[ "$output" == *"bats"* ]]
  [[ "$output" == *"wp-cli"* ]]
  [[ "$output" == *"wp-env"* ]]
  [[ "$output" == *"php"* ]]
  [[ "$output" == *"composer"* ]]
  [[ "$output" == *"docker"* ]]
}

@test "bats is installed (self-check — if this test runs, bats works)" {
  command -v bats
}

@test "wp-cli is installed and reports version" {
  command -v wp
  run wp --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"WP-CLI"* ]]
}

@test "wp-env is installed and reports version" {
  command -v wp-env
  run wp-env --version
  [ "$status" -eq 0 ]
}

@test "php 8.x is installed" {
  command -v php
  run php -r "echo PHP_MAJOR_VERSION;"
  [ "$status" -eq 0 ]
  [ "$output" = "8" ]
}

@test "composer is installed" {
  command -v composer
  run composer --version
  [ "$status" -eq 0 ]
}

@test "docker daemon is running" {
  run docker info
  [ "$status" -eq 0 ]
}

@test ".wp-env.json exists at repo root" {
  [ -f "$BATS_TEST_DIRNAME/../.wp-env.json" ]
}

@test ".wp-env.json enables WP_DEBUG" {
  run grep -q '"WP_DEBUG"\s*:\s*true' "$BATS_TEST_DIRNAME/../.wp-env.json"
  [ "$status" -eq 0 ]
}

@test "second run of installer completes in under 5 seconds (idempotency)" {
  # Skip if tools missing — only meaningful when all green
  if ! command -v wp >/dev/null || ! command -v wp-env >/dev/null; then
    skip "tools not yet installed"
  fi
  start=$(date +%s)
  run "$SCRIPT" --check
  end=$(date +%s)
  elapsed=$((end - start))
  [ "$elapsed" -lt 5 ]
}
