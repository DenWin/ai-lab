#!/usr/bin/env bash

warn() {
	echo "[config-lint install] $*" >&2
}

if command -v python >/dev/null 2>&1; then
	python -m pip install --upgrade pip
	python -m pip install yamllint
elif command -v python3 >/dev/null 2>&1; then
	python3 -m pip install --upgrade pip
	python3 -m pip install yamllint
else
	warn "python/python3 is not available; skipping pip/yamllint install."
fi

if command -v npm >/dev/null 2>&1; then
	npm install -g markdownlint-cli --no-fund --no-audit
else
	warn "npm is not available; skipping markdownlint-cli install."
fi

if command -v gem >/dev/null 2>&1; then
	gem install asciidoctor
else
	warn "gem is not available; skipping asciidoctor install."
fi

if ! command -v shellcheck >/dev/null 2>&1; then
	if command -v apt-get >/dev/null 2>&1; then
		if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
			sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
			sudo DEBIAN_FRONTEND=noninteractive apt-get install -y shellcheck
		else
			warn "shellcheck is missing and apt-get requires interactive sudo; skipping apt install to avoid hangs."
		fi
	else
		warn "shellcheck is missing and apt-get is unavailable; skipping shellcheck install."
	fi
fi
