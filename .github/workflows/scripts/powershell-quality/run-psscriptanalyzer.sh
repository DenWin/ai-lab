#!/usr/bin/env bash

base="$1"
head="$2"

mkdir -p reports
count=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.ps1' --include '*.psm1' --include '*.psd1' --output-count)

if [[ "${count}" == "0" ]]; then
  echo "No PowerShell files changed." > reports/psscriptanalyzer.txt
  exit 0
fi

cat > reports/psscriptanalyzer.txt <<'EOF'
PSScriptAnalyzer execution was skipped.
Reason: workflows are configured for bash-only execution with no PowerShell runtime involvement.
EOF

echo "::warning::Skipped PSScriptAnalyzer because PowerShell execution is disabled for workflow scripts."
