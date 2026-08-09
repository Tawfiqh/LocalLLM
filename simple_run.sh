#!/usr/bin/env bash
echo "🚀 Installing Ollama via Brew"
brew bundle

echo "🚀 Loading environment variables"
. ./.env

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Starting the ollama server (& Helpers)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
OLLAMA_PID=""
cleanup() {
  if [[ -n "${OLLAMA_PID:-}" ]] && kill -0 "$OLLAMA_PID" 2>/dev/null; then
    kill "$OLLAMA_PID" 2>/dev/null || true
  fi
  OLLAMA_PID=""
}
echo "🦙 Starting Ollama"
# capturing PID so that it can run in the background and we can run OpenWEBUI
ollama serve >>"./.ollama-serve.log" 2>&1 &
      OLLAMA_PID=$!
      trap cleanup EXIT INT TERM
echo "✅🦙 Started Ollama (PID: $OLLAMA_PID)"
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Install a good model (if not already installed)
# ollama pull llama3.2:8b

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Starting the Open WebUI (uses PythonVersion 3.11 from .python-version)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "🌐 Starting Open WebUI — http://127.0.0.1:8080/"
uv run --with open-webui --with greenlet open-webui serve