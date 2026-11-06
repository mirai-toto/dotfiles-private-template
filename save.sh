#!/bin/bash
# Save, commit, and push only this instance's managed files.

set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/scripts/profile.sh"

check_save_ready() {
  if [ ! -f "$CHEZMOI_CONFIG" ]; then
    echo "Missing $CHEZMOI_CONFIG; run ./install.sh first." >&2
    exit 1
  fi
  if ! git -C "$SCRIPT_DIR" diff --cached --quiet; then
    echo "Staged changes already exist; commit or unstage them before saving." >&2
    exit 1
  fi
  if ! git -C "$SCRIPT_DIR" rev-parse --verify '@{upstream}' >/dev/null 2>&1 ||
    [ "$(git -C "$SCRIPT_DIR" rev-list --count '@{upstream}..HEAD')" -ne 0 ]; then
    echo "No upstream branch or unpushed commits; resolve this before saving." >&2
    exit 1
  fi
}

CHEZMOI=(chezmoi --config "$CHEZMOI_CONFIG" --source "$SCRIPT_DIR")
save_managed() {
  local target="$1" source relative
  if source=$("${CHEZMOI[@]}" source-path -- "$target" 2>/dev/null); then
    relative="${target#"$HOME"/}"
    if [[ "$source" == *.tmpl || "$source" == *.tmpl.age ]] &&
      [ -f "$SCRIPT_DIR/template-paths" ] &&
      grep -Fxq -- "$relative" "$SCRIPT_DIR/template-paths"; then
      "$SCRIPT_DIR/scripts/save-template.sh" "$target" "$source" "$SCRIPT_DIR" "$CHEZMOI_CONFIG"
    else
      "${CHEZMOI[@]}" re-add -- "$target"
    fi
  else
    "${CHEZMOI[@]}" add --encrypt -- "$target"
  fi
}

save_targets() {
  local relative target path
  if [ $# -eq 0 ]; then
    "${CHEZMOI[@]}" re-add
    if [ -f "$SCRIPT_DIR/template-paths" ]; then
      while IFS= read -r relative; do
        [ -n "$relative" ] || continue
        target="$HOME/$relative"
        if [ -f "$target" ] && "${CHEZMOI[@]}" source-path -- "$target" >/dev/null 2>&1; then
          save_managed "$target"
        fi
      done < "$SCRIPT_DIR/template-paths"
    fi
  else
    for path in "$@"; do
      save_managed "$(realpath -m -- "$path")"
    done
  fi
}

stage_managed_files() {
  paths=$(mktemp)
  trap 'rm -f "$paths"' EXIT
  "${CHEZMOI[@]}" managed --include=files,symlinks --path-style=source-relative --nul-path-separator > "$paths"
  if [ ! -s "$paths" ]; then
    echo "No managed files to save."
    exit 0
  fi
  git -C "$SCRIPT_DIR" add -A --pathspec-from-file="$paths" --pathspec-file-nul
}

commit_managed_files() {
  if git -C "$SCRIPT_DIR" diff --cached --quiet; then
    echo "No managed changes to commit."
    return 0
  fi
  git -C "$SCRIPT_DIR" commit -m "chore(dotfiles): sync managed files"
  git -C "$SCRIPT_DIR" -c push.default=simple push
}

main() {
  check_save_ready
  save_targets "$@"
  stage_managed_files
  commit_managed_files
}

main "$@"
