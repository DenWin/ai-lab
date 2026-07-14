#!/usr/bin/env bash

base="$1"
head="$2"
full_scan="${3:-}"
repo_root="$(pwd)"
reports_dir="${REPORTS_DIR:-.temp/Reports}"
scan_args=()

if [[ "$full_scan" == "--full-scan" ]]; then
  scan_args+=(--full-scan)
fi

mkdir -p "$reports_dir"
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --repo-root "${repo_root}" --include '*.js' "${scan_args[@]}")
if [ -n "${files}" ]; then
  set +e
  echo "$files" | xargs -I{} node --check "{}" 2>&1 | tee "$reports_dir/js-syntax.txt"
  rc=${PIPESTATUS[1]}
  if [ "$rc" -ne 0 ]; then
    echo "::error::JavaScript syntax validation failed (rc=$rc). See $reports_dir/js-syntax.txt."
    exit "$rc"
  fi
else
  echo "No JavaScript files found." > "$reports_dir/js-syntax.txt"
fi
