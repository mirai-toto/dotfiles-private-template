#!/bin/bash
# Shared instance paths for install/save/apply; source after setting SCRIPT_DIR.

if [ ! -f "$SCRIPT_DIR/profile-id" ]; then
  echo "Missing profile-id. Run ./install.sh to choose one." >&2
  exit 1
fi

IFS= read -r PROFILE_ID < "$SCRIPT_DIR/profile-id"
if [[ ! "$PROFILE_ID" =~ ^[a-z][a-z0-9-]*$ ]] || [ "$PROFILE_ID" = my-profile ]; then
  echo "Invalid profile-id: use lowercase letters, digits, and hyphens; not my-profile." >&2
  exit 1
fi

AGE_IDENTITY="$HOME/.config/chezmoi/keys/$PROFILE_ID.txt"
CHEZMOI_CONFIG="$HOME/.config/chezmoi/profiles/$PROFILE_ID.toml"
