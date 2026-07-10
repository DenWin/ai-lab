#!/usr/bin/env bash

set +e
{
  echo "## powershell-quality summary"
  echo "- PowerShell files found: $1"
  echo "- Analyzer report: reports/psscriptanalyzer.txt"
  echo "- Syntax report: reports/powershell-syntax.txt"
} >> "$GITHUB_STEP_SUMMARY"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::Failed to write powershell-quality job summary (rc=$rc)."
  exit "$rc"
fi
