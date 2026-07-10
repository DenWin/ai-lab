#!/usr/bin/env bash

set +e
if {
  echo "## config-lint summary"
  echo "- YAML: see reports/yamllint.txt"
  echo "- JSON: see reports/jsonlint.txt"
  echo "- Markdown: see reports/markdownlint.txt"
  echo "- AsciiDoc: see reports/asciidoctor-lint.txt"
  echo "- Shell: see reports/shellcheck.txt"
  echo "- JavaScript syntax: see reports/js-syntax.txt"
} >> "$GITHUB_STEP_SUMMARY"; then
  :
else
  echo "::error::Failed to write config-lint job summary."
  exit 1
fi
