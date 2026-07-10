#!/usr/bin/env bash

base="$1"
head="$2"

mkdir -p reports
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.py')
set +e
echo "$files" | xargs -I{} ruff check "{}" 2>&1 | tee reports/ruff-check.txt
rc=${PIPESTATUS[1]}
if [ "$rc" -ne 0 ]; then
  echo "::error::ruff check failed (rc=$rc). See reports/ruff-check.txt."
  exit "$rc"
fi
