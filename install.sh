#!/bin/bash
# Restore this instance's age key if needed, then configure and apply chezmoi.

set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
umask 077

if [ -e "$HOME/.secrets" ] && [ ! -d "$HOME/.secrets" ]; then
  echo "~/.secrets is a file; move its contents safely before installing a profile." >&2
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/profile-id" ]; then
  while true; do
    if ! read -r -p "Profile ID (lowercase letters, digits, hyphens): " candidate; then
      echo "No profile ID provided." >&2
      exit 1
    fi
    if [[ ! "$candidate" =~ ^[a-z][a-z0-9-]*$ ]] || [ "$candidate" = my-profile ]; then
      echo "Invalid profile ID; try another." >&2
      continue
    fi
    if [ -e "$HOME/.secrets/$candidate" ] || [ -L "$HOME/.secrets/$candidate" ] ||
      [ -e "$HOME/.config/chezmoi/keys/$candidate.txt" ] ||
      [ -e "$HOME/.config/chezmoi/profiles/$candidate.toml" ] ||
      [ -e "$HOME/.config/dotfiles/profiles.d/$candidate" ] ||
      [ -L "$HOME/.config/dotfiles/profiles.d/$candidate" ]; then
      echo "Profile $candidate is already in use on this machine; choose another." >&2
      continue
    fi

    mkdir -p -m 700 "$HOME/.secrets"
    mkdir -m 700 "$HOME/.secrets/$candidate"
    printf '%s\n' "$candidate" > "$SCRIPT_DIR/profile-id"
    echo "Created profile-id ($candidate). Track it in your private repository."
    break
  done
fi

source "$SCRIPT_DIR/scripts/profile.sh"
if [ -L "$HOME/.secrets/$PROFILE_ID" ]; then
  echo "Profile secrets directory cannot be a symlink: $HOME/.secrets/$PROFILE_ID" >&2
  exit 1
fi
mkdir -p -m 700 "$HOME/.secrets/$PROFILE_ID"

mkdir -p "$(dirname "$AGE_IDENTITY")" "$(dirname "$CHEZMOI_CONFIG")"
restore="$SCRIPT_DIR/scripts/restore-age-key.sh"
if [ -f "$restore" ]; then
  key=$(mktemp "${AGE_IDENTITY}.tmp.XXXXXX")
  trap 'rm -f "$key"' EXIT
  if ! bash "$restore" > "$key"; then
    echo "Could not retrieve the age identity; check $restore." >&2
    exit 1
  fi
  if ! grep -q '^AGE-SECRET-KEY-' "$key"; then
    echo "Retrieved data does not contain an age identity." >&2
    exit 1
  fi
  if [ -f "$AGE_IDENTITY" ]; then
    if ! grep '^AGE-SECRET-KEY-' "$AGE_IDENTITY" | cmp -s - "$key"; then
      echo "Local age identity differs from the retrieved key; refusing to overwrite it." >&2
      exit 1
    fi
  else
    mv "$key" "$AGE_IDENTITY"
  fi
elif [ ! -f "$AGE_IDENTITY" ]; then
  echo "Missing age identity: $AGE_IDENTITY. Restore it securely or provide $restore; use ./init-age-key.sh only for a new profile." >&2
  exit 1
fi
if ! grep -q '^AGE-SECRET-KEY-' "$AGE_IDENTITY"; then
  echo "Local age identity is invalid: $AGE_IDENTITY" >&2
  exit 1
fi
chmod 600 "$AGE_IDENTITY"

recipient=$(chezmoi age-keygen -y "$AGE_IDENTITY")
cat > "$CHEZMOI_CONFIG" <<EOF
encryption = "age"

[age]
identity = "$AGE_IDENTITY"
recipient = "$recipient"
EOF
chmod 600 "$CHEZMOI_CONFIG"
bash "$SCRIPT_DIR/scripts/register-profile.sh" "$SCRIPT_DIR"
bash "$SCRIPT_DIR/apply.sh"
