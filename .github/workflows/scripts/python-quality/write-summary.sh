#!/usr/bin/env bash

set +e
{
  echo "## python-quality summary"
  echo "- Python files found: $1"
  echo "- Ruff check report: reports/ruff-check.txt"
  echo "- Ruff format report: reports/ruff-format-check.txt"
} >> "$GITHUB_STEP_SUMMARY"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::Failed to write python-quality job summary (rc=$rc)."
  exit "$rc"
fi
