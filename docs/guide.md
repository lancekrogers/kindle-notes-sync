# Guide

Amazon still boots. After a public jailbreak you can run this on `/mnt/us` and push **your** copies of **your** notebooks to a git remote you own.

## How it works

1. The Notebook tab writes `/mnt/us/.notebooks/<uuid>/nbk` (KDF/SQLite Amazon will not let stock `sqlite3` open).
2. Titles and folders live in `/var/local/ksdk.content.db` (`Nodes`, `NodeRelations`). `download_state=1` does **not** mean the `.nbk` is on disk.
3. `notes-sync` asks `com.lab126.notebookappmanager` `SaveAndSync` for each local uuid, then `sqlite3 .backup` of the library DB, then copies ink + thumbnails into `/mnt/us/notes` using the folder tree.
4. `GIT_SSH=/mnt/us/bin/git-ssh-scribe` runs **dbclient** (Dropbear client) with a dropbear-format deploy key. That is outbound to GitHub. It is not `start-ssh`.

Book / PDF pen marks are stored as `/mnt/us/.notebooks/<ASIN>!!<CDETYPE>!!notebook/` and copied under `annotations/`.

## Layout on the device

| Path | Role |
|------|------|
| `/mnt/us/documents/Notes-Sync.sh` | Scriptlet (`# Name: Notes Sync`) |
| `/mnt/us/bin/notes-sync` | Export / push / selfcheck |
| `/mnt/us/bin/git-ssh-scribe` | `GIT_SSH` helper |
| `/mnt/us/notes-sync.conf` | Optional overrides |
| `/mnt/us/.ssh/id_scribe_notes` | Dropbear deploy key |
| `/mnt/us/notes` | Git working copy that gets pushed |
| `/mnt/us/notes-sync.log` | Last run |

## Reinstall after a userstore wipe

`/mnt/us` is FAT. A bad `rm` or factory-adjacent wipe deletes the tool. From a computer that can `ssh` the Scribe:

```bash
just push kindle
# restore the dropbear key, git remote, notes-sync.conf
ssh kindle sh /mnt/us/bin/notes-sync selfcheck
```

Prereqs (not this repo): Véra, USBNetLite khf, musl git from kindle-userspace, `start-ssh`.

## Dropbear key

`dbclient` rejects OpenSSH PEM (`String too long`). Convert:

```sh
dropbearconvert openssh dropbear id_scribe_notes id_scribe_notes.dropbear
scp id_scribe_notes.dropbear kindle:/mnt/us/.ssh/id_scribe_notes
```

If this computer has no `dropbearconvert`, copy the OpenSSH key to the Scribe and convert there (USBNetLite ships it as part of `dropbearmulti` on some builds; otherwise convert on any Linux with dropbear).

Auth test (GitHub prints `Invalid command` — that means the key worked):

```sh
ssh kindle 'dbclient -i /mnt/us/.ssh/id_scribe_notes -y git@github.com "echo ok"'
```

`Failed to set raw TTY` on a bare `dbclient git@github.com` with no command is noise.

## Scriptlets

KPM lists `# Name:`, not the filename. Both lines are required:

```sh
# Name: Notes Sync
# Author: kindle-notes-sync
```

Do not keep `Notes-Sync.sh` and `notes-sync.sh` in the same folder on a case-insensitive Mac disk. This repo uses `scriptlet-Notes-Sync.sh` as the local name.

## Gotchas

| Symptom | Cause | Fix |
|---------|--------|-----|
| `String too long` | OpenSSH PEM | dropbear key |
| `git: not found` | musl git not on PATH | kindle-userspace git wrapper |
| Scriptlet missing | No `# Name:` | See above |
| `Everything up-to-date` | Nothing new on disk | Open the notebook, or you only have catalog rows |
| FAT, no `ln -s` | `/mnt/us` is `fsp` | Call `dbclient` or `dropbearmulti dbclient` |
