#!/usr/bin/env bash

base="$1"
head="$2"

files=$(bash .github/workflows/scripts/ci/get-changed-files.sh --base "${base}" --head "${head}" --include '*.bats')
BATS_FILES="$files" bash .github/workflows/scripts/shell/run-shell-tests.sh
