#!/bin/bash
# Pull and deploy only this instance's managed files.

set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/scripts/profile.sh"

if [ ! -f "$CHEZMOI_CONFIG" ]; then
  echo "Missing $CHEZMOI_CONFIG; run ./install.sh first." >&2
  exit 1
fi

git -C "$SCRIPT_DIR" pull --ff-only
chezmoi --config "$CHEZMOI_CONFIG" --source "$SCRIPT_DIR" apply "$@"
