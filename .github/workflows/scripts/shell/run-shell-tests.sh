#!/usr/bin/env bash

reports_dir="${REPORTS_DIR:-.temp/Reports}"
mkdir -p "$reports_dir"

if [ -z "${BATS_FILES:-}" ]; then
  echo "No bats files found."
  echo "No bats files found." > "$reports_dir/bats.txt"
  exit 0
fi

set +e
echo "$BATS_FILES" | sed '/^$/d' | xargs -I{} bats "{}" 2>&1 | tee "$reports_dir/bats.txt"
rc=${PIPESTATUS[1]}
if [ "$rc" -ne 0 ]; then
  echo "::error::bats failed (rc=$rc). See $reports_dir/bats.txt."
  exit "$rc"
fi

exit 0
