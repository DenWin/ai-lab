#!/usr/bin/env bash

base="$1"
head="$2"
repo_root="$(pwd)"
reports_dir="${REPORTS_DIR:-.temp/Reports}"

if command -v python >/dev/null 2>&1; then
  python_cmd="python"
elif command -v python3 >/dev/null 2>&1; then
  python_cmd="python3"
else
  echo "::error::python/python3 is required for JSON validation."
  exit 127
fi

mkdir -p "$reports_dir"
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --repo-root "${repo_root}" --include '*.json')
if [ -n "${files}" ]; then
  set +e
  echo "$files" | xargs -I{} "$python_cmd" -m json.tool "{}" > /dev/null
  rc=${PIPESTATUS[1]}
  if [ "$rc" -ne 0 ]; then
    echo "::error::JSON syntax validation failed (rc=$rc)."
    exit "$rc"
  fi
  printf "Validated %s JSON files.\n" "$(echo "$files" | wc -l | tr -d ' ')" > "$reports_dir/jsonlint.txt"
else
  echo "No JSON files found." > "$reports_dir/jsonlint.txt"
fi
