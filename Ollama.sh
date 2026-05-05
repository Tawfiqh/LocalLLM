#!/usr/bin/env bash


# Run Ollama and start the Open WebUI on :8080. Default: Open WebUI on :8080.
# --ollama-only = exit after starting ollama server -- doesn't run the Open WebUI
# (used by ./run.sh).
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Expects Ollama to be installed via Homebrew and the Brewfile -- run run.sh to run and install everything

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Checking if the ollama-only flag is set
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
ollama_only=0
[[ "${1:-}" == "--ollama-only" ]] && { ollama_only=1; shift; }

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Loading the environment variables from the .env file
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Starting the ollama server
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
OLLAMA_PID=""
cleanup() {
  if [[ -n "${OLLAMA_PID:-}" ]] && kill -0 "$OLLAMA_PID" 2>/dev/null; then
    kill "$OLLAMA_PID" 2>/dev/null || true
  fi
  OLLAMA_PID=""
}


# Checking if the ollama server is ready
ollama_ready() { curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; }
wait_ollama() { for ((i = 0; i < 60; i++)); do ollama_ready && return 0; sleep 1; done; return 1; }

# If the ollama server is not ready, start it
if ! ollama_ready; then
  if command -v ollama >/dev/null 2>&1; then
    if [[ "$ollama_only" -eq 1 ]]; then
      echo "🦙 Starting ollama serve (detached) — log: $ROOT/.ollama-serve.log"
      nohup ollama serve >>"$ROOT/.ollama-serve.log" 2>&1 &
      disown 2>/dev/null || true
    else
      ollama serve >>"$ROOT/.ollama-serve.log" 2>&1 &
      OLLAMA_PID=$!
      trap cleanup EXIT INT TERM
    fi
    if ! wait_ollama; then
      [[ -n "${OLLAMA_PID:-}" ]] && { cleanup; trap - EXIT INT TERM 2>/dev/null || true; }
      echo "error: Ollama did not become ready on http://127.0.0.1:11434" >&2
      exit 1
    fi
  elif [[ "$(uname -s)" == Darwin ]]; then
    open -a Ollama 2>/dev/null || true
    if ! wait_ollama; then
      cat <<'EOF' >&2
error: Ollama is not responding on http://127.0.0.1:11434

  Install: https://ollama.com/download
  macOS Homebrew: brew bundle (see Brewfile)
EOF
      exit 1
    fi
  else
    cat <<'EOF' >&2
error: ollama CLI not found and nothing is listening on http://127.0.0.1:11434

  Install: https://ollama.com/download
EOF
    exit 1
  fi
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# If the ollama-only flag is set, exit after starting the ollama server - do not start the Open WebUI
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
if [[ "$ollama_only" -eq 1 ]]; then
  echo "✅ Ollama is up — http://127.0.0.1:11434"
  exit 0
fi

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Checking if the uv command is available - otherwise exit with an error
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
command -v uv >/dev/null 2>&1 || { echo "error: uv is not installed. See https://docs.astral.sh/uv/" >&2; exit 1; }

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Starting the Open WebUI
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "🌐 Starting Open WebUI — http://127.0.0.1:8080/"
export DATA_DIR="${DATA_DIR:-$HOME/.open-webui}"

# Ensure DATA_DIR exists and is writable before launching.
if ! mkdir -p "$DATA_DIR" 2>/dev/null; then
  echo "error: Could not create DATA_DIR at '$DATA_DIR'" >&2
  exit 1
fi
if [[ ! -w "$DATA_DIR" ]]; then
  echo "error: DATA_DIR is not writable: '$DATA_DIR'" >&2
  exit 1
fi

# uv run uses a managed environment, but still needs a working Python toolchain.
if ! command -v python3 >/dev/null 2>&1; then
  cat <<'EOF' >&2
error: python3 is required to run Open WebUI with uv.

Try:
  - macOS: brew install python
  - then rerun: ./Ollama.sh
EOF
  exit 1
fi

if ! uv run --with open-webui --with greenlet open-webui serve; then
  cat <<'EOF' >&2
error: Failed to start Open WebUI via uv.

Common fixes:
  1) Ensure uv can manage Python:
       uv python list
       uv python install 3.11
  2) Retry launch:
       ./Ollama.sh
  3) If it still fails, run with verbose output:
       UV_LOG=debug uv run --with open-webui --with greenlet open-webui serve
EOF
  exit 1
fi
