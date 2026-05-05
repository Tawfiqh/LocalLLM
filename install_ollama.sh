#!/usr/bin/env bash
# Require Homebrew and run `brew bundle` in this repo (Ollama, etc. from Brewfile).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Checking if the brew command is available - otherwise exit with an error
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew not found (https://brew.sh/)" >&2
  exit 1
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Checking if the Brewfile is available - otherwise exit with an error
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if [[ ! -f "$ROOT/Brewfile" ]]; then
  echo "error: Brewfile not found in $ROOT" >&2
  exit 1
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Running the brew bundle command to install the dependencies
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
brew bundle


echo "✅ Done. Installed Ollama"