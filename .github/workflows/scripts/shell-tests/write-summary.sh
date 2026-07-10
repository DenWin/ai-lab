#!/usr/bin/env bash

set +e
if {
  echo "## shell-tests summary"
  echo "- Shell test files found: $1"
  echo "- bats report: reports/bats.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write shell-tests job summary."
  exit 1
fi
