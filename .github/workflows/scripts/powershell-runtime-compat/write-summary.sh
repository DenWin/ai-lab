#!/usr/bin/env bash

cat <<'EOF' >> "$GITHUB_STEP_SUMMARY"
## powershell-runtime-compat summary
- pwsh syntax report: reports/pwsh-syntax.txt
- Windows PowerShell syntax report: reports/windowsps-syntax.txt
EOF
