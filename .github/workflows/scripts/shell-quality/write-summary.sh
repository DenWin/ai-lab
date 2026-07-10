#!/usr/bin/env bash

set +e
if {
  echo "## shell-quality summary"
  echo "- Shell files found: $1"
  echo "- ShellCheck report: reports/shellcheck.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write shell-quality job summary."
  exit 1
fi
