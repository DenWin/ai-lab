#!/usr/bin/env bash

base="$1"
head="$2"

files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include 'ai-artifacts/**/tests/test_*.py')
{
  echo "files<<EOF"
  echo "$files"
  echo "EOF"
  echo "count=$(printf "%s\n" "$files" | sed '/^$/d' | wc -l | tr -d ' ')"
} >> "$GITHUB_OUTPUT"
