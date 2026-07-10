#!/usr/bin/env bash

base="$1"
head="$2"

mkdir -p reports
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.ps1')

targets=""
while IFS= read -r file; do
  [[ -z "${file}" ]] && continue
  policy=$(awk 'NR<=40 && $0 ~ /^#[[:space:]]*RuntimePolicy:[[:space:]]*/ {sub(/^#[[:space:]]*RuntimePolicy:[[:space:]]*/, ""); gsub(/[[:space:]]+$/, ""); print tolower($0); exit}' "${file}")
  if [[ "${policy}" == "core-first" || "${policy}" == "dual-runtime" ]]; then
    targets+="${file}"$'\n'
  fi
done <<< "${files}"

if [[ -z "${targets}" ]]; then
  echo "No pwsh-target files found." > reports/pwsh-syntax.txt
  exit 0
fi

cat > reports/pwsh-syntax.txt <<'EOF'
pwsh syntax parser check was skipped.
Reason: workflows are configured for bash-only execution with no PowerShell runtime involvement.
EOF

echo "::warning::Skipped pwsh syntax parser check because PowerShell execution is disabled for workflow scripts."
