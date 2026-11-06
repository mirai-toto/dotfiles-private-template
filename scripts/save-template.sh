#!/bin/bash
# Preserve home-directory substitutions when saving listed chezmoi templates.
set -euo pipefail
umask 077

target="$1"
source="$2"
source_dir="$3"
config="$4"
CHEZMOI=(chezmoi --config "$config" --source "$source_dir")

check_rendered_source() {
  # Fail closed if the current source cannot be decrypted or rendered.
  "${CHEZMOI[@]}" cat "$target" > "$temp_dir/rendered"
  if cmp -s -- "$temp_dir/rendered" "$target"; then
    exit 0
  fi
}

restore_home_placeholder() {
  python3 - "$target" "$temp_dir/template" "$HOME" <<'PY'
from pathlib import Path
import sys

target: Path = Path(sys.argv[1])
output: Path = Path(sys.argv[2])
home: str = sys.argv[3]
content: str = target.read_text()
output.write_text(content.replace(f"{home}/", "{{ .chezmoi.homeDir }}/"))
PY
}

write_source() {
  local output="$temp_dir/source"
  if [[ "$source" == *.age ]]; then
    "${CHEZMOI[@]}" encrypt --output "$output" "$temp_dir/template"
  else
    cp -- "$temp_dir/template" "$output"
  fi
  chmod --reference="$source" "$output"
  mv -- "$output" "$source"
}

main() {
  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-private-save.XXXXXX")
  trap 'rm -f -- "$temp_dir/rendered" "$temp_dir/template" "$temp_dir/source"; rmdir -- "$temp_dir"' EXIT
  check_rendered_source
  restore_home_placeholder
  write_source
}

main
