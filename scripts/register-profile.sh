#!/bin/bash
# Register this checkout for the public dotfiles sync and private Git includes.
set -euo pipefail
SCRIPT_DIR=$(realpath "${1:?Usage: register-profile.sh REPO}")
source "$SCRIPT_DIR/scripts/profile.sh"

registrations="$HOME/.config/dotfiles/profiles.d"
registration="$registrations/$PROFILE_ID"
mkdir -p -m 700 "$registrations"

if [ -L "$registration" ] && [ -d "$registration" ] &&
  [ "$(realpath "$registration")" = "$SCRIPT_DIR" ]; then
  exit 0
fi
if [ -e "$registration" ] || [ -L "$registration" ]; then
  echo "Profile registration already in use: $registration" >&2
  exit 1
fi
ln -s "$SCRIPT_DIR" "$registration"
