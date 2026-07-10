#!/usr/bin/env bash

base="$1"
head="$2"

mkdir -p reports
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.sh')
set +e
echo "$files" | xargs -I{} shellcheck "{}" 2>&1 | tee reports/shellcheck.txt
rc=${PIPESTATUS[1]}
if [ "$rc" -ne 0 ]; then
  echo "::error::shellcheck failed (rc=$rc). See reports/shellcheck.txt."
  exit "$rc"
fi
