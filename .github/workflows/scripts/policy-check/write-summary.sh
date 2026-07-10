#!/usr/bin/env bash

set +e
{
  echo "## policy-check summary"
  echo "- Guardrail log: reports/policy-check.txt"
  echo "- Coding policy log: reports/coding-policy-check.txt"
  echo "- PowerShell runtime log: reports/powershell-runtime-check.txt"
} >> "$GITHUB_STEP_SUMMARY"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "::error::Failed to write policy-check job summary (rc=$rc)."
  exit "$rc"
fi
