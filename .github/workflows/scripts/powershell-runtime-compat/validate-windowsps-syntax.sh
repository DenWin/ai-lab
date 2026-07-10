#!/usr/bin/env bash

set -euo pipefail

base="$1"
head="$2"

mkdir -p reports
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.ps1')

targets=""
while IFS= read -r file; do
  [[ -z "${file}" ]] && continue
  policy=$(awk 'NR<=40 && $0 ~ /^#[[:space:]]*RuntimePolicy:[[:space:]]*/ {sub(/^#[[:space:]]*RuntimePolicy:[[:space:]]*/, ""); gsub(/[[:space:]]+$/, ""); print tolower($0); exit}' "${file}")
  if [[ "${policy}" == "dual-runtime" || "${policy}" == "desktop-only" ]]; then
    targets+="${file}"$'\n'
  fi
done <<< "${files}"

if [[ -z "${targets}" ]]; then
  echo "No Windows PowerShell target files found." > reports/windowsps-syntax.txt
  exit 0
fi

cat > reports/windowsps-syntax.txt <<'EOF'
Windows PowerShell syntax parser check was skipped.
Reason: workflows are configured for bash-only execution with no PowerShell runtime involvement.
EOF

echo "::warning::Skipped Windows PowerShell syntax parser check because PowerShell execution is disabled for workflow scripts."
