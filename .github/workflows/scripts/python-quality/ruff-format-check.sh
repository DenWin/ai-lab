#!/usr/bin/env bash

base="$1"
head="$2"

mkdir -p reports
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.py')
set +e
echo "$files" | xargs -I{} ruff format --check "{}" 2>&1 | tee reports/ruff-format-check.txt
rc=${PIPESTATUS[1]}
if [ "$rc" -ne 0 ]; then
  echo "::error::ruff format check failed (rc=$rc). See reports/ruff-format-check.txt."
  exit "$rc"
fi
