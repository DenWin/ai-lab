#!/usr/bin/env bash

set +e
{
  echo "## shell-tests summary"
  echo "- Shell test files found: $1"
  echo "- bats report: reports/bats.txt"
} >> "$GITHUB_STEP_SUMMARY"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::Failed to write shell-tests job summary (rc=$rc)."
  exit "$rc"
fi
