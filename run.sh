#!/usr/bin/env bash

# Run the FastAPI dev server (uses .venv next to this script).
# After .env: curls ${OLLAMA_HOST}/api/tags; if Ollama is down, runs ./Ollama.sh --ollama-only.
# Runs ./install.sh if .venv is missing.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "🚀 Loading environment variables"
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if [[ -f .env ]]; then
  echo "🔑 Loading .env"
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "🚀 Checking for dependencies and setting up Ollama"
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
"$SCRIPT_DIR/install_ollama.sh"
echo "✅ Ollama setup complete"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "🚀 Checking if the ollama server is running" 
#  - OTHERWISE RUNS IT via Ollama.sh (and starts the Open WebUI)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
OLLAMA_HOST="${OLLAMA_HOST%/}"
if ! curl -sf "${OLLAMA_HOST}/api/tags" &>/dev/null; then
  echo "🦙 Ollama not responding at ${OLLAMA_HOST}; running ./Ollama.sh --ollama-only to start the ollama server"
  "$SCRIPT_DIR/Ollama.sh" #--ollama-only
fi
echo "✅ Ollama server ready"
