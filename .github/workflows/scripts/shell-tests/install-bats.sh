#!/usr/bin/env bash

set +e
sudo apt-get update
apt_update_rc=$?
if [ "$apt_update_rc" -ne 0 ]; then
  echo "::error::apt-get update failed (rc=$apt_update_rc)."
  exit "$apt_update_rc"
fi
sudo apt-get install -y bats
install_rc=$?
if [ "$install_rc" -ne 0 ]; then
  echo "::error::bats installation failed (rc=$install_rc)."
  exit "$install_rc"
fi
