#!/usr/bin/env bats

setup() {
  export TMPDIR="${TMPDIR:-/tmp}"
  export TEST_FIXTURES="$BATS_TEST_DIRNAME/fixtures"
  export VALIDATE="$BATS_TEST_DIRNAME/../scripts/validate-project.sh"
  export FINALIZE="$BATS_TEST_DIRNAME/../scripts/finalize-project.sh"
}

@test "validator blocks on broken-project: emits CRITICAL" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/broken-project" "$tmpdir/test-broken"

  run bash "$VALIDATE" "$tmpdir/test-broken"
  [ "$status" -eq 1 ]
  [[ "$output" == *'"verdict":"block"'* ]]
  [[ "$output" == *'"CRITICAL"'* ]]

  rm -rf "$tmpdir"
}

@test "validator stops on first CRITICAL" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/broken-project" "$tmpdir/test-broken"

  run bash "$VALIDATE" "$tmpdir/test-broken"
  count=$(echo "$output" | grep -o '"severity":"CRITICAL"' | wc -l | tr -d ' ')
  [ "$count" -le 1 ]

  rm -rf "$tmpdir"
}

@test "validator on clean-project passes or warns" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-clean"

  run bash "$VALIDATE" "$tmpdir/test-clean"
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
  [[ "$output" == *'"verdict":"pass"'* || "$output" == *'"verdict":"warn"'* ]]

  rm -rf "$tmpdir"
}

@test "validator catches lorem in final stage" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-lorem"

  cat > "$tmpdir/test-lorem/docs/03-content/home.json" << 'EOF'
{"title":"Home","content":"Lorem ipsum dolor sit amet"}
EOF

  run bash "$VALIDATE" "$tmpdir/test-lorem" final
  [ "$status" -eq 1 ]
  [[ "$output" == *'"verdict":"block"'* ]]

  rm -rf "$tmpdir"
}

@test "validator catches missing concrete design tokens" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-tokens"

  cat > "$tmpdir/test-tokens/docs/04-design.md" << 'EOF'
# Design
Colors: primary, secondary
EOF

  run bash "$VALIDATE" "$tmpdir/test-tokens"
  [[ "$output" == *'"severity":"HIGH"'* || "$output" == *'"verdict":"warn"'* ]]

  rm -rf "$tmpdir"
}

@test "validator catches missing alt on image" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-alt"

  # Replace the wireframe with an alt-less image so the validator's check 6 catches it
  cat > "$tmpdir/test-alt/docs/02-wireframes/home.html" << 'EOF'
<!doctype html><html><body><h1>Home</h1><img src="hero.jpg"><p>Content</p></body></html>
EOF

  run bash "$VALIDATE" "$tmpdir/test-alt"
  [[ "$output" == *'"severity":"HIGH"'* ]]

  rm -rf "$tmpdir"
}

@test "finalize fails on broken project" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/broken-project" "$tmpdir/test-broken"
  cd "$tmpdir/test-broken"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  cd - >/dev/null

  run bash "$FINALIZE" "$tmpdir/test-broken"
  [ "$status" -eq 1 ]

  rm -rf "$tmpdir"
}

@test "finalize succeeds on clean project" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-clean"
  cd "$tmpdir/test-clean"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  cd - >/dev/null

  run bash "$FINALIZE" "$tmpdir/test-clean"
  [ "$status" -eq 0 ]

  rm -rf "$tmpdir"
}

@test "finalize appends CHANGELOG line" {
  tmpdir=$(mktemp -d)
  cp -r "$TEST_FIXTURES/clean-project" "$tmpdir/test-clean"
  cd "$tmpdir/test-clean"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  cd - >/dev/null

  run bash "$FINALIZE" "$tmpdir/test-clean"
  [ -f "$tmpdir/test-clean/docs/CHANGELOG.md" ]
  grep -q "Finalized" "$tmpdir/test-clean/docs/CHANGELOG.md"

  rm -rf "$tmpdir"
}
