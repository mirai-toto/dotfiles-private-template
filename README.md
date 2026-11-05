# dotfiles-private-template

A [chezmoi](https://chezmoi.io) starter for a **private** dotfiles repository. Secrets are encrypted with [age](https://age-encryption.org); each repository chooses how to back up its age key.

## Get started

1. On GitHub, select **Use this template → Create a new repository** and choose **Private**.
2. Run `./install.sh` to choose a profile name. For an existing profile, restore its age identity securely to `~/.config/chezmoi/keys/<profile>.txt` first, or implement `scripts/restore-age-key.sh` in your repository to retrieve it. The script must write only the `AGE-SECRET-KEY` line to stdout and return nonzero on failure; the installer also compares it with any existing local key.
3. For a **new** profile with no existing key or backup, run `./init-age-key.sh`, back up the generated identity securely using your chosen method, then run `./install.sh` again. Never generate a replacement key for an existing encrypted profile.
4. Commit and push the generated `profile-id` in your private repo. Create `~/.secrets/<profile>/env.sh` from `secrets.example`, replace the placeholder, and encrypt it:

   ```bash
   profile=$(cat profile-id)
   chezmoi --config "$HOME/.config/chezmoi/profiles/$profile.toml" \
     --source "$PWD" add --encrypt "$HOME/.secrets/$profile/env.sh"
   ```

If `~/.secrets` is already a file, move its contents safely before creating the directory. Keep the directory private (`0700`) and `env.sh` readable only by you (`0600`).

For existing personal and work dotfiles repositories sharing `~/.secrets`, follow the [migration checklist](docs/migrate-existing.md) before replacing their legacy scripts or applying the public shell loader.

## Daily use

- `./save.sh` — save managed files, commit, and push. Review secrets before running it.
- `./apply.sh` — pull and apply this repo's files.

See [how it works](docs/how-it-works.md) for profile IDs, key storage, and what the scripts manage.
