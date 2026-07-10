#!/usr/bin/env bash

files="$1"

echo "${files}" | xargs -I{} python -m pytest "{}" -q
