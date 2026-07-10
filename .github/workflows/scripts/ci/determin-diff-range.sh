#!/usr/bin/env bash

set -euo pipefail

base="${1:-}"
head="${2:-}"
before="${3:-}"
sha="${4:-}"

if [[ -z "${base}" ]]; then
  base="${before}"
fi

if [[ -z "${head}" ]]; then
  head="${sha}"
fi

if [[ -z "${head}" ]]; then
  echo "Head SHA is empty. Pass head or sha." >&2
  exit 1
fi

if [[ -z "${base}" || "${base}" == "0000000000000000000000000000000000000000" ]]; then
  base="$(git rev-list --max-parents=0 "${head}" | tail -n 1)"
  if [[ -z "${base}" ]]; then
    echo "Failed to resolve fallback base commit from head '${head}'." >&2
    exit 1
  fi
fi

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "GITHUB_OUTPUT is not set; cannot write workflow outputs." >&2
  exit 1
fi

echo "base=${base}" >> "${GITHUB_OUTPUT}"
echo "head=${head}" >> "${GITHUB_OUTPUT}"
