#!/usr/bin/env bash

set +e
if {
  echo "## policy-check summary"
  echo "- Guardrail log: reports/policy-check.txt"
  echo "- Coding policy log: reports/coding-policy-check.txt"
  echo "- PowerShell runtime log: reports/powershell-runtime-check.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write policy-check job summary."
  exit 1
fi
