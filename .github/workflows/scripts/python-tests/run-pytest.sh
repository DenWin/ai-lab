#!/usr/bin/env bash

files="$1"

set -euo pipefail
echo "${files}" | xargs -I{} python -m pytest "{}" -q
