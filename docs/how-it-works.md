# How it works

Each private repo created from this template is a separate **profile**. `profile-id` contains its name (lowercase letters, digits, and hyphens, starting with a letter). It is ordinary Git-tracked metadata, not a secret.

## Profile setup

Only `install.sh` prompts for a missing `profile-id`. It checks for an existing `~/.secrets/<profile>/` folder, chezmoi config, or age key before reserving the name. `apply.sh`, `save.sh`, and `init-age-key.sh` require the file to exist and never prompt. Profile names need to be distinct on each machine.

The scripts use these per-profile paths:

| What | Path |
| --- | --- |
| Shell secrets | `~/.secrets/<profile>/env.sh` |
| Age identity | `~/.config/chezmoi/keys/<profile>.txt` |
| Chezmoi config | `~/.config/chezmoi/profiles/<profile>.toml` |

`~/.secrets` must be a directory, not a file. The installer will not move or overwrite an existing file. The profile folder is created with mode `0700`; use mode `0600` for `env.sh`.

On install, this repo registers itself as `~/.config/dotfiles/profiles.d/<profile>`: a symlink to its checkout. Public `dotfiles-sync` scans those links without reading private chezmoi configs. Reinstalling is safe; the installer refuses to replace another checkout's registration.

## Encryption and saving

`init-age-key.sh` generates an age identity locally without printing the secret. Back it up securely with a method chosen by this repository. If `scripts/restore-age-key.sh` exists, `install.sh` runs it and captures its stdout in a private temporary file; the script should output only the `AGE-SECRET-KEY` line and fail without printing secrets on errors. The installer validates the retrieved key and refuses to overwrite a different local key. Without a restore script, a valid local identity must already exist. It then writes the per-profile chezmoi config and applies this repo. Neither chezmoi nor age depends on a particular key backup provider.

Add live secrets with `chezmoi add --encrypt` using this repo's `--source` and `--config` (see the README). For a private `env.sh`, the source should be an encrypted `.age` file under `private_dot_secrets/private_<profile>/` (for example `encrypted_private_env.sh.age`), never a plaintext copy. The `private_` prefix on the parent directory keeps `~/.secrets` at `0700` on apply; the file prefix keeps `env.sh` at `0600`. Only source shell-formatted environment files; other credentials need not be sourced.

`save.sh` re-adds and stages **only chezmoi-managed files**, then commits and pushes without force. New paths passed explicitly are added encrypted. If your instance manages templates whose rendered home paths need to survive saving, list their paths relative to `$HOME` (one per line) in a tracked `template-paths` file; the common helper then restores `{{ .chezmoi.homeDir }}` before saving. It does not include `profile-id`, scripts, or docs, so commit those separately. `apply.sh` pulls with `--ff-only` before applying; a pull conflict stops the script.

This template does not install a global shell loader or scheduler. Decide which profiles a shell needs before sourcing their env files; sourcing every profile can expose secrets or overwrite variables with the same name.

## Optional public dotfiles integration

Public `dotfiles` loads readable `*.zsh` files in `~/.config/dotfiles/private-shell.d/` in filename order. Put each profile's shell loading policy in a **chezmoi-managed hook** there; do not source all profiles automatically. A hook can set `DOTFILES_SKIP_TMUX_AUTOATTACH=1` when launching a child shell that must not attach to tmux.

If a private instance manages a Git identity, its owner decides where to deploy that file. The public `dotfiles` Git config can include specific identity files directly; this template does not generate shared Git configuration.
