#!/usr/bin/env bash

base="$1"
head="$2"
repo_root="$(pwd)"
reports_dir="${REPORTS_DIR:-.temp/Reports}"

mkdir -p "$reports_dir"
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --repo-root "${repo_root}" --include '*.md')
if [ -n "${files}" ]; then
  set +e
  echo "$files" | xargs -I{} markdownlint "{}" --config .markdownlint.json 2>&1 | tee "$reports_dir/markdownlint.txt"
  rc=${PIPESTATUS[1]}
  if [ "$rc" -ne 0 ]; then
    echo "::error::markdownlint failed (rc=$rc). See $reports_dir/markdownlint.txt."
    exit "$rc"
  fi
else
  echo "No Markdown files found." > "$reports_dir/markdownlint.txt"
fi
