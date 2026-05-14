#!/bin/bash

# setup-wordpress-env.sh
# Phase 0 Subplan 0.2 — mvp-builder
# Install and configure WordPress development environment using wp-env

set -euo pipefail

# Color helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

green() { echo -e "${GREEN}✓${NC} $1"; }
red() { echo -e "${RED}✗${NC} $1"; }
yellow() { echo -e "${YELLOW}⚠${NC} $1"; }

# Script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Flags
CHECK_ONLY=false
RESET_ENV=false
SKIP_CONFIRMATION=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --reset) RESET_ENV=true; shift ;;
    --yes) SKIP_CONFIRMATION=true; shift ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# Check if tool is installed
has_tool() {
  command -v "$1" >/dev/null 2>&1
}

# Get version string for tool (graceful fallback to "present")
get_version() {
  case "$1" in
    bats) bats --version 2>/dev/null | awk '{print $2}' || echo "present" ;;
    wp) wp --version 2>/dev/null | awk '{print $1}' || echo "present" ;;
    wp-env) wp-env --version 2>/dev/null || echo "present" ;;
    php) php -r "echo phpversion();" 2>/dev/null || echo "present" ;;
    composer) composer --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "present" ;;
    docker) docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//' || echo "present" ;;
    *) echo "unknown" ;;
  esac
}

# Check tool and print status
check_tool() {
  local tool="$1"
  if has_tool "$tool"; then
    local version=$(get_version "$tool")
    printf "%-15s %-15s %s\n" "$tool" "✓ present" "$version"
    return 0
  else
    printf "%-15s %-15s\n" "$tool" "✗ missing"
    return 1
  fi
}

# Install tool via brew
install_via_brew() {
  local tool="$1"
  local brew_name="${2:-$tool}"

  if has_tool "$tool"; then
    green "$tool already installed"
    return 0
  fi

  if [ "$SKIP_CONFIRMATION" = false ]; then
    echo "Install $tool via brew? (y/n)"
    read -r response
    [[ "$response" != "y" ]] && return 1
  fi

  echo "Installing $tool..."
  brew install "$brew_name"
}

# Install tool via npm globally
install_via_npm() {
  local npm_package="$1"
  local tool_name="${2:-$npm_package}"

  if has_tool "$tool_name"; then
    green "$tool_name already installed"
    return 0
  fi

  if [ "$SKIP_CONFIRMATION" = false ]; then
    echo "Install $npm_package globally? (y/n)"
    read -r response
    [[ "$response" != "y" ]] && return 1
  fi

  echo "Installing $npm_package..."
  npm install -g "$npm_package"
}

# Check PHP major version
check_php_version() {
  local major_version=$(php -r "echo PHP_MAJOR_VERSION;" 2>/dev/null)
  if [ "$major_version" = "8" ]; then
    return 0
  else
    return 1
  fi
}

# Main check function
do_check() {
  echo ""
  echo "Tool         Status          Version"
  echo "=====================================";

  local all_present=true

  check_tool "bats" || all_present=false
  check_tool "wp" || all_present=false
  check_tool "wp-env" || all_present=false
  check_tool "php" || all_present=false
  check_tool "composer" || all_present=false
  check_tool "docker" || all_present=false

  echo ""

  if [ "$all_present" = true ]; then
    # Verify PHP is 8.x
    if ! check_php_version; then
      red "PHP version must be 8.x"
      return 1
    fi

    # Verify docker daemon
    if ! docker info >/dev/null 2>&1; then
      red "Docker daemon not running. Open Docker Desktop and re-run."
      return 1
    fi

    green "all present"
    return 0
  else
    red "missing tools"
    return 1
  fi
}

# Create .wp-env.json
setup_wp_env_config() {
  local config_file="$REPO_ROOT/.wp-env.json"

  if [ -f "$config_file" ] && [ "$RESET_ENV" = false ]; then
    green ".wp-env.json already exists"
    return 0
  fi

  echo "Writing .wp-env.json..."
  cat > "$config_file" << 'EOF'
{
  "phpVersion": "8.2",
  "testsEnvironment": false,
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true,
    "WP_DEBUG_DISPLAY": false,
    "SCRIPT_DEBUG": true
  },
  "mappings": {
    "wp-content/themes": "./src/wp-content/themes"
  }
}
EOF
  green ".wp-env.json created"
}

# Create theme directories
setup_theme_dirs() {
  local theme_dir="$REPO_ROOT/src/wp-content/themes"

  if [ ! -d "$theme_dir" ]; then
    echo "Creating theme directory structure..."
    mkdir -p "$theme_dir"
    touch "$theme_dir/.gitkeep"
    green "theme directories created"
  else
    green "theme directories already present"
  fi
}

# Create tmp directory
setup_tmp_dir() {
  local tmp_dir="$REPO_ROOT/tmp"

  if [ ! -d "$tmp_dir" ]; then
    echo "Creating tmp directory..."
    mkdir -p "$tmp_dir"
    touch "$tmp_dir/.gitkeep"
    green "tmp directory created"
  else
    green "tmp directory already present"
  fi
}

# Download theme unit test data
download_theme_data() {
  local data_file="$REPO_ROOT/tmp/themeunittestdata.wordpress.xml"

  if [ -f "$data_file" ]; then
    green "theme unit test data already present"
    return 0
  fi

  echo "Downloading theme unit test data..."
  mkdir -p "$REPO_ROOT/tmp"
  curl -sSL "https://raw.githubusercontent.com/WPTT/theme-unit-test/master/themeunittestdata.wordpress.xml" \
    -o "$data_file" 2>/dev/null && green "theme unit test data downloaded" || red "failed to download theme data"
}

# Import theme unit test data
import_theme_data() {
  local data_file="$REPO_ROOT/tmp/themeunittestdata.wordpress.xml"

  if [ ! -f "$data_file" ]; then
    yellow "theme unit test data not found, skipping import"
    return 0
  fi

  echo "Importing theme unit test data..."
  wp-env run cli wp import /var/www/html/wp-content/themeunittestdata.wordpress.xml --authors=create 2>/dev/null && \
    green "theme unit test data imported" || \
    yellow "theme unit test data import skipped or failed"
}

# Main installation flow
do_install() {
  echo ""
  echo "WordPress Development Environment Setup"
  echo "========================================"
  echo ""

  # Install tools (does not require Docker)
  install_via_brew "bats" "bats-core"
  install_via_brew "wp" "wp-cli"
  install_via_npm "@wordpress/env" "wp-env"
  install_via_brew "php"
  install_via_brew "composer"

  # Verify PHP version
  if ! check_php_version; then
    red "PHP version must be 8.x. Current: $(php -r 'echo PHP_MAJOR_VERSION;')"
    exit 1
  fi

  # Setup config and directories
  setup_wp_env_config
  setup_theme_dirs
  setup_tmp_dir
  download_theme_data

  # Docker is only required for wp-env runtime
  if ! docker info >/dev/null 2>&1; then
    yellow "Docker daemon not running — tools installed but skipping wp-env start."
    yellow "Open Docker Desktop and re-run \`$0\` (no --yes needed; idempotent)."
    return 0
  fi

  # Reset environment if requested
  if [ "$RESET_ENV" = true ]; then
    echo ""
    echo "Resetting wp-env..."
    wp-env destroy || true
  fi

  # Start wp-env
  echo ""
  echo "Starting WordPress environment..."
  wp-env start

  # Import theme data if env is running
  import_theme_data

  echo ""
  green "WordPress environment ready!"
  echo "Access at: http://localhost:8888"
  echo ""
}

# Main logic
if [ "$CHECK_ONLY" = true ]; then
  do_check
  exit $?
else
  do_check || true
  do_install
fi
