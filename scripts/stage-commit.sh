#!/bin/bash
# stage-commit.sh — stage all changes in a project dir and commit with standard message
#
# Usage: stage-commit.sh <project-dir> <stage-num> <stage-name>
#
# Validates git repo, stages all changes, commits with "stage-<num>: <name>" message.
# Outputs NO_CHANGES if nothing to commit, or the commit SHA if successful.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: stage-commit.sh <project-dir> <stage-num> <stage-name>" >&2
  exit 1
fi

project_dir="$1"
stage_num="$2"
stage_name="$3"

# Validate target is a git repo
if [[ ! -d "${project_dir}/.git" ]]; then
  echo "Error: not a git repository: $project_dir" >&2
  exit 1
fi

# Change into the project directory
cd "$project_dir"

# Stage all changes
git add -A

# Check if there are staged changes
if git diff --cached --quiet; then
  echo "NO_CHANGES"
  exit 0
fi

# Commit with standardized message
commit_msg="stage-${stage_num}: ${stage_name}"
commit_sha=$(git commit -m "$commit_msg" | grep -oE '\b[0-9a-f]{7,}\b' | head -1 || echo "unknown")

echo "$commit_sha"
exit 0
