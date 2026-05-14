#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  export TEST_DIR
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "script exists and is executable" {
  [ -x "$HOME/mvp-builder/scripts/init-project.sh" ]
}

@test "init creates expected docs/ structure in target dir" {
  "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Test Project" \
    --theme "test-theme" \
    --yes \
    "$TEST_DIR"

  # Check docs directory and files exist
  [ -d "$TEST_DIR/docs" ]
  [ -f "$TEST_DIR/docs/00-requirements.md" ]
  [ -f "$TEST_DIR/docs/01-sitemap.md" ]
  [ -f "$TEST_DIR/docs/04-design.md" ]
  [ -f "$TEST_DIR/docs/brand-voice.md" ]
  [ -f "$TEST_DIR/docs/coding-standards.md" ]
  [ -f "$TEST_DIR/docs/image-guidelines.md" ]
  [ -f "$TEST_DIR/docs/99-known-issues.md" ]
  [ -f "$TEST_DIR/docs/05-image-prompts.md" ]
  [ -f "$TEST_DIR/docs/CHANGELOG.md" ]

  # Check subdirectories
  [ -d "$TEST_DIR/docs/02-wireframes" ]
  [ -d "$TEST_DIR/docs/03-content" ]
  [ -d "$TEST_DIR/docs/06-images" ]
  [ -d "$TEST_DIR/docs/checkpoints" ]
}

@test "init refuses if docs/ already exists" {
  # First run should succeed
  "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Test Project" \
    --yes \
    "$TEST_DIR"

  # Second run should fail
  ! "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Test Project" \
    --yes \
    "$TEST_DIR"
}

@test "init sanitizes theme slug" {
  "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Foo Bar Co!" \
    --yes \
    "$TEST_DIR"

  [ -d "$TEST_DIR/src/wp-content/themes/foo-bar-co" ]
}

@test "theme style.css has WordPress header" {
  "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Test Project" \
    --theme "test-theme" \
    --yes \
    "$TEST_DIR"

  grep -q "Theme Name:" "$TEST_DIR/src/wp-content/themes/test-theme/style.css"
}

@test "git init runs and creates .git in target" {
  "$HOME/mvp-builder/scripts/init-project.sh" \
    --name "Test Project" \
    --yes \
    "$TEST_DIR"

  [ -d "$TEST_DIR/.git" ]
}
