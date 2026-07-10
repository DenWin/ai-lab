#!/usr/bin/env bash

base="$1"
head="$2"
repo_root="$(pwd)"
reports_dir="${REPORTS_DIR:-.temp/Reports}"

mkdir -p "$reports_dir"
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --repo-root "${repo_root}" --include '*.sh')
if [ -n "${files}" ]; then
  set +e
  echo "$files" | xargs -I{} shellcheck "{}" 2>&1 | tee "$reports_dir/shellcheck.txt"
  rc=${PIPESTATUS[1]}
  if [ "$rc" -ne 0 ]; then
    echo "::error::shellcheck failed (rc=$rc). See $reports_dir/shellcheck.txt."
    exit "$rc"
  fi
else
  echo "No shell scripts found." > "$reports_dir/shellcheck.txt"
fi
