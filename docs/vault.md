[← README](../README.md)

# Keep the manifest in a vault

The manifest holds no secrets (paths, public URLs, names, emails, public signing keys), so it can
live wherever you keep the rest of your machine setup. It is the source of truth: save it back
every time you add or change a project.

The default location is `~/.config/git-projects/projects.yml`. To use a file somewhere else (a
synced folder, a private dotfiles repo), set `GIT_PROJECTS_FILE` to its path or pass `--file`.

## 1Password
```sh
# first time
op document create ~/.config/git-projects/projects.yml --title projects.yml
# after a change
op document edit projects.yml ~/.config/git-projects/projects.yml
# on a new machine
op document get projects.yml --out-file ~/.config/git-projects/projects.yml
```

## Bitwarden
Attach the file to an item (a secure note works). Bitwarden attachments cannot be replaced in
place: delete the old one and upload the new one after a change.
```sh
bw create attachment --file ~/.config/git-projects/projects.yml --itemid <item-id>
bw get attachment projects.yml --itemid <item-id> --output ~/.config/git-projects/projects.yml
```

## age
An encrypted file you can keep anywhere, even in a public dotfiles repo.
```sh
age -p -o projects.yml.age ~/.config/git-projects/projects.yml     # encrypt with a passphrase
age -d -o ~/.config/git-projects/projects.yml projects.yml.age     # decrypt on the new machine
```
With a key pair, use `age -r <recipient>` to encrypt and `age -d -i <key file>` to decrypt.

## A private dotfiles repo
Keep `projects.yml` in your dotfiles and point the tool at it from your shell rc:
```sh
export GIT_PROJECTS_FILE=~/dotfiles/git-projects/projects.yml
```
