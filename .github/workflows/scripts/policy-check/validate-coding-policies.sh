#!/usr/bin/env bash

set +e
python -m pip install --upgrade pip
pip_up_rc=$?
if [ "$pip_up_rc" -ne 0 ]; then
  echo "::error::pip upgrade failed (rc=$pip_up_rc)."
  exit "$pip_up_rc"
fi
pip install pyyaml
pyyaml_rc=$?
if [ "$pyyaml_rc" -ne 0 ]; then
  echo "::error::pyyaml installation failed (rc=$pyyaml_rc)."
  exit "$pyyaml_rc"
fi
python .github/workflows/scripts/validate-coding-policies.py
policy_rc=$?
if [ "$policy_rc" -ne 0 ]; then
  echo "::error::coding policy validation failed (rc=$policy_rc)."
  exit "$policy_rc"
fi

python .github/workflows/scripts/validate-powershell-runtime.py
ps_runtime_rc=$?
if [ "$ps_runtime_rc" -ne 0 ]; then
  echo "::error::PowerShell runtime policy validation failed (rc=$ps_runtime_rc)."
  exit "$ps_runtime_rc"
fi
