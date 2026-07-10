#!/usr/bin/env bash

set +e
{
  echo "## shell-quality summary"
  echo "- Shell files found: $1"
  echo "- ShellCheck report: reports/shellcheck.txt"
} >> "$GITHUB_STEP_SUMMARY"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::Failed to write shell-quality job summary (rc=$rc)."
  exit "$rc"
fi
