#!/usr/bin/env bash

set +e
if {
  echo "## powershell-quality summary"
  echo "- PowerShell files found: $1"
  echo "- Analyzer report: reports/psscriptanalyzer.txt"
  echo "- Syntax report: reports/powershell-syntax.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write powershell-quality job summary."
  exit 1
fi
