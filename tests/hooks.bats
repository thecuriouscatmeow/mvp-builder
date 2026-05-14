#!/usr/bin/env bats

# hooks.bats - Test suite for lorem-check.sh and changelog-guard.sh

setup() {
  HOOKS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.claude/hooks" && pwd)"
  TMPDIR="$(mktemp -d)"
  export TMPDIR
}

teardown() {
  [ -d "$TMPDIR" ] && rm -rf "$TMPDIR"
}

# ============================================================================
# lorem-check.sh wireframe stage
# ============================================================================

@test "lorem-check wireframe passes when lorem in wireframe" {
  mkdir -p "$TMPDIR/docs/02-wireframes"
  cat > "$TMPDIR/docs/02-wireframes/home.html" <<EOF
<html>
  <body>
    <p>Lorem ipsum dolor sit amet</p>
  </body>
</html>
EOF
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "wireframe"
  [ "$status" -eq 0 ]
}

@test "lorem-check wireframe fails when lorem absent" {
  mkdir -p "$TMPDIR/docs/02-wireframes"
  cat > "$TMPDIR/docs/02-wireframes/home.html" <<EOF
<html>
  <body>
    <p>This is just content</p>
  </body>
</html>
EOF
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "wireframe"
  [ "$status" -eq 1 ]
  [[ "$output" == *"home.html"* ]]
}

# ============================================================================
# lorem-check.sh content stage
# ============================================================================

@test "lorem-check content passes when no lorem" {
  mkdir -p "$TMPDIR/docs/03-content"
  echo '{"title": "Home"}' > "$TMPDIR/docs/03-content/home.json"
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "content"
  [ "$status" -eq 0 ]
}

@test "lorem-check content fails when lorem in json" {
  mkdir -p "$TMPDIR/docs/03-content"
  cat > "$TMPDIR/docs/03-content/home.json" <<EOF
{"title": "Home", "description": "Lorem ipsum dolor sit amet"}
EOF
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "content"
  [ "$status" -eq 1 ]
  [[ "$output" == *"home.json"* ]]
}

@test "lorem-check content fails when lorem in design.md" {
  mkdir -p "$TMPDIR/docs"
  echo "# Design\n\nLorem ipsum dolor sit amet" > "$TMPDIR/docs/04-design.md"
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "content"
  [ "$status" -eq 1 ]
  [[ "$output" == *"design.md"* ]]
}

# ============================================================================
# lorem-check.sh final stage
# ============================================================================

@test "lorem-check final fails on undefined literal in CSS" {
  mkdir -p "$TMPDIR/src/wp-content/themes/mytheme"
  echo "body { color: undefined; }" > "$TMPDIR/src/wp-content/themes/mytheme/style.css"
  run "$HOOKS_DIR/lorem-check.sh" "$TMPDIR" "final"
  [ "$status" -eq 1 ]
  [[ "$output" == *"style.css"* ]]
}

# ============================================================================
# changelog-guard.sh
# ============================================================================

@test "changelog-guard passes when CHANGELOG.md and tracked file both staged" {
  cd "$TMPDIR"
  git init --quiet
  mkdir -p docs src/wp-content/themes/mytheme
  echo "# Changelog" > docs/CHANGELOG.md
  echo "# Sitemap" > docs/01-sitemap.md
  git add docs/CHANGELOG.md docs/01-sitemap.md
  run "$HOOKS_DIR/changelog-guard.sh" "$TMPDIR"
  [ "$status" -eq 0 ]
}

@test "changelog-guard fails when tracked file staged without CHANGELOG.md" {
  cd "$TMPDIR"
  git init --quiet
  mkdir -p docs src/wp-content/themes/mytheme
  echo "# Sitemap" > docs/01-sitemap.md
  git add docs/01-sitemap.md
  run "$HOOKS_DIR/changelog-guard.sh" "$TMPDIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"01-sitemap.md"* ]]
}

@test "changelog-guard passes when only unrelated files staged" {
  cd "$TMPDIR"
  git init --quiet
  echo "*.log" > .gitignore
  git add .gitignore
  run "$HOOKS_DIR/changelog-guard.sh" "$TMPDIR"
  [ "$status" -eq 0 ]
}
