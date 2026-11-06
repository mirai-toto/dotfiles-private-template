#!/bin/bash
# First machine only: create a unique age identity for this private instance.

set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/scripts/profile.sh"

create_age_identity() {
  if [ -e "$AGE_IDENTITY" ]; then
    echo "Age identity already exists: $AGE_IDENTITY" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$AGE_IDENTITY")"
  chezmoi age-keygen -o "$AGE_IDENTITY"
  chmod 600 "$AGE_IDENTITY"
  echo "Back up $AGE_IDENTITY securely using this repository's chosen method before running ./install.sh on another machine."
  echo "Never commit or paste the age identity in a terminal command or a chat."
}

umask 077
create_age_identity
