#!/usr/bin/env bash

base="$1"
head="$2"

set +e
mkdir -p reports

# 1) Block obvious hardcoded secrets in tracked repo files.
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*')
list_rc=$?
if [ "$list_rc" -ne 0 ]; then
  echo "::error::Failed to list tracked files for guardrails (rc=$list_rc)."
  exit "$list_rc"
fi
if [ -n "${files}" ]; then
  secret_matches=$(echo "${files}" | xargs -d '\n' grep -IInE "(api[_-]?key|secret|token|password)\s*[:=]\s*['\"][^'\"]+['\"]" || true)
  if [ -n "${secret_matches}" ]; then
    echo "${secret_matches}"
    echo "Potential hardcoded secret detected."
    exit 1
  fi
fi

# 2) Ensure PowerShell scripts use strict mode, excluding scratch artifacts.
ps_files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.ps1' --include '*.psm1')
ps_list_rc=$?
if [ "$ps_list_rc" -ne 0 ]; then
  echo "::error::Failed to enumerate PowerShell files for guardrails (rc=$ps_list_rc)."
  exit "$ps_list_rc"
fi
if [ -n "${ps_files}" ]; then
  missing=$(echo "${ps_files}" | xargs -I{} sh -c "grep -q 'Set-StrictMode' '{}' || echo '{}'")
  if [ -n "${missing}" ]; then
    echo "Missing Set-StrictMode in:"
    echo "${missing}"
    exit 1
  fi
fi

echo "Policy checks passed." > reports/policy-check.txt
