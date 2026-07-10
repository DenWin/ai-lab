#!/usr/bin/env bash

set +e
if {
  echo "## python-quality summary"
  echo "- Python files found: $1"
  echo "- Ruff check report: reports/ruff-check.txt"
  echo "- Ruff format report: reports/ruff-format-check.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write python-quality job summary."
  exit 1
fi
