#!/usr/bin/env bash

set -euo pipefail

base="$1"
head="$2"

mkdir -p reports
count=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.ps1' --include '*.psm1' --include '*.psd1' --output-count)

if [[ "${count}" == "0" ]]; then
  echo "No PowerShell files changed." > reports/powershell-syntax.txt
  exit 0
fi

cat > reports/powershell-syntax.txt <<'EOF'
PowerShell syntax validation was skipped.
Reason: workflows are configured for bash-only execution with no PowerShell runtime involvement.
EOF

echo "::warning::Skipped PowerShell syntax validation because PowerShell execution is disabled for workflow scripts."
