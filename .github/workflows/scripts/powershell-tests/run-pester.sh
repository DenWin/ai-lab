#!/usr/bin/env bash

joined_paths="$1"

echo "Skipping Pester execution for: ${joined_paths}"
echo "Reason: workflow scripts run in bash-only mode."
