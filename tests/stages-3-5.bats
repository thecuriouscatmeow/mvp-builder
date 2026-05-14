#!/usr/bin/env bats

setup() {
  export TMPDIR="${TMPDIR:-/tmp}"
  export TEST_PROJECT_DIR="$TMPDIR/mvp-test-$RANDOM"
  mkdir -p "$TEST_PROJECT_DIR/docs/02-wireframes"
  mkdir -p "$TEST_PROJECT_DIR/docs/03-content"
  mkdir -p "$TEST_PROJECT_DIR/docs/checkpoints"
}

teardown() {
  rm -rf "$TEST_PROJECT_DIR"
}

@test "design-strategy fake produces 04-design.md with hex codes" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-design-strategy.sh" "$TEST_PROJECT_DIR"
  test -f "$TEST_PROJECT_DIR/docs/04-design.md"
  grep -q '#0066CC' "$TEST_PROJECT_DIR/docs/04-design.md"
}

@test "design-strategy has spacing scale" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-design-strategy.sh" "$TEST_PROJECT_DIR"
  grep -q '32px' "$TEST_PROJECT_DIR/docs/04-design.md"
}

@test "design-strategy has motion durations" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-design-strategy.sh" "$TEST_PROJECT_DIR"
  grep -q 'ms\b' "$TEST_PROJECT_DIR/docs/04-design.md"
}

@test "design-strategy has breakpoints" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-design-strategy.sh" "$TEST_PROJECT_DIR"
  grep -q '1024px' "$TEST_PROJECT_DIR/docs/04-design.md"
}

@test "stage 3 worker creates content JSON" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-stage3-worker.sh" "$TEST_PROJECT_DIR" "home"
  test -f "$TEST_PROJECT_DIR/docs/03-content/home.json"
}

@test "stage 3 worker output has no lorem ipsum" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-stage3-worker.sh" "$TEST_PROJECT_DIR" "home"
  ! grep -qi "lorem ipsum" "$TEST_PROJECT_DIR/docs/03-content/home.json"
}

@test "stage 4 worker modifies wireframe" {
  echo "<html><body><h1>Test</h1></body></html>" > "$TEST_PROJECT_DIR/docs/02-wireframes/home.html"
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-stage3-worker.sh" "$TEST_PROJECT_DIR" "home"
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-stage4-worker.sh" "$TEST_PROJECT_DIR" "home"
  grep -q 'var(--' "$TEST_PROJECT_DIR/docs/02-wireframes/home.html"
}

@test "check-design-tokens accepts valid design.md" {
  bash "$BATS_TEST_DIRNAME/../scripts/test-fake-design-strategy.sh" "$TEST_PROJECT_DIR"
  bash "$BATS_TEST_DIRNAME/../scripts/check-design-tokens.sh" "$TEST_PROJECT_DIR"
}

@test "check-design-tokens rejects bad design.md" {
  echo "# Design - only one hex #0066CC" > "$TEST_PROJECT_DIR/docs/04-design.md"
  ! bash "$BATS_TEST_DIRNAME/../scripts/check-design-tokens.sh" "$TEST_PROJECT_DIR"
}
