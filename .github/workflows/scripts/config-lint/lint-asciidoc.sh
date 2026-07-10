#!/usr/bin/env bash

base="$1"
head="$2"
repo_root="$(pwd)"
reports_dir="${REPORTS_DIR:-.temp/Reports}"

mkdir -p "$reports_dir"
files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --repo-root "${repo_root}" --include '*.adoc' --include '*.asciidoc')
if [ -n "${files}" ]; then
  # asciidoctor validates document structure/parsing
  set +e
  echo "$files" | xargs -I{} asciidoctor -o /dev/null "{}" 2>&1 | tee "$reports_dir/asciidoctor-parse.txt"
  parse_rc=${PIPESTATUS[1]}
  if [ "$parse_rc" -ne 0 ]; then
    echo "::error::asciidoctor parse validation failed (rc=$parse_rc). See $reports_dir/asciidoctor-parse.txt."
    exit "$parse_rc"
  fi
  cp "$reports_dir/asciidoctor-parse.txt" "$reports_dir/asciidoctor-lint.txt"
else
  echo "No AsciiDoc files found." > "$reports_dir/asciidoctor-lint.txt"
fi
