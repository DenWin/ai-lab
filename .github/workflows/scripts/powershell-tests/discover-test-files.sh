#!/usr/bin/env bash

base="$1"
head="$2"

files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.Tests.ps1' | awk 'NF')
count=$(printf "%s\n" "${files}" | sed '/^$/d' | wc -l | tr -d ' ')
joined=$(printf "%s\n" "${files}" | paste -sd, -)
{
  echo "count=${count}"
  echo "files=${joined}"
} >> "$GITHUB_OUTPUT"
