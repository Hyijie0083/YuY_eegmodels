#!/usr/bin/env bash
#
# Pull all Ollama models required by the llm-conductor and ensemble-designer skills.
# Reads the model list from models.json in the same directory.
#
# Usage:
#   ./pull-models.sh          # pull all Ollama models
#   ./pull-models.sh --check  # check which models are already available
#   ./pull-models.sh --pip    # also install pip dependencies for verification scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/models.json"

if [ ! -f "$MANIFEST" ]; then
  echo "Error: models.json not found at $MANIFEST" >&2
  exit 1
fi

if ! command -v ollama &>/dev/null; then
  echo "Error: ollama is not installed or not in PATH" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required to parse models.json" >&2
  exit 1
fi

# Read Ollama models from manifest
MODELS=$(jq -r '.ollama[].model' "$MANIFEST")

check_models() {
  local available
  available=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')

  echo "=== Ollama model status ==="
  while IFS= read -r model; do
    local profiles tier
    profiles=$(jq -r --arg m "$model" '.ollama[] | select(.model == $m) | .profiles | join(", ")' "$MANIFEST")
    tier=$(jq -r --arg m "$model" '.ollama[] | select(.model == $m) | "tier \(.tier)"' "$MANIFEST")

    if echo "$available" | grep -q "^${model}$"; then
      echo "  [ok]      $model  ($profiles; $tier)"
    else
      echo "  [missing] $model  ($profiles; $tier)"
    fi
  done <<< "$MODELS"
}

pull_models() {
  echo "=== Pulling Ollama models ==="
  while IFS= read -r model; do
    echo "--- $model ---"
    ollama pull "$model"
  done <<< "$MODELS"
  echo "=== Done ==="
}

install_pip() {
  local deps
  deps=$(jq -r '.verification.pip_dependencies[]' "$MANIFEST")

  echo "=== Installing pip dependencies for verification scripts ==="
  while IFS= read -r pkg; do
    echo "--- $pkg ---"
    pip install "$pkg"
  done <<< "$deps"
  echo "=== Done ==="
}

case "${1:-}" in
  --check)
    check_models
    ;;
  --pip)
    pull_models
    install_pip
    ;;
  *)
    pull_models
    ;;
esac
