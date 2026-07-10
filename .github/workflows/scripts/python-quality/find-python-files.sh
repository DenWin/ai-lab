#!/usr/bin/env bash

base="$1"
head="$2"

count=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.py' --output-count)
echo "count=${count}" >> "$GITHUB_OUTPUT"
