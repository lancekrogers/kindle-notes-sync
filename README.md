# kindle-notes-sync

Export Kindle Scribe notebooks to a **git remote you control**, from the Scribe itself.

Write in the stock Notebook tab. Close it. Tap **Notes Sync**. The device commits and pushes. No computer has to be on for the push.

This is **not** a replacement notes app. Amazon still draws the notebook and still owns the `.nbk` format. We copy what is already on disk.

Tested on a first-gen Scribe, firmware 5.19.5, after a public jailbreak (Véra) plus [kindle-userspace](https://github.com/lancekrogers/kindle-userspace) (Wi-Fi SSH, musl git).

**This repo is private until review.** Do not open-source it with notebooks, keys, or lab notes in the tree.

## What you get

```text
Scribe Notebook tab
        │  Amazon saves
        ▼
/mnt/us/.notebooks/<uuid>/nbk      ink, if it is on disk
/var/local/ksdk.content.db         titles + folders
        │  notes-sync
        ▼
/mnt/us/notes/notebooks/<Folder>/<Title>/
        │  git + dropbear dbclient
        ▼
your private GitHub (or other) remote
```

On the computer you only `git pull`.

## You still do not control

Amazon boots the device. Secure boot, signed firmware, the Notebook UI, WhisperSync, and the `.nbk` format stay theirs. This tool is L1 userspace: we read local files and push copies.

## Needs

- Jailbroken **kindlehf** Scribe (Véra covers 5.17.1–5.19.6)
- [USBNetLite](https://github.com/notmarek/kindle-usbnetlite) khf (`dbclient`)
- musl git on `/mnt/us` — [kindle-userspace](https://github.com/lancekrogers/kindle-userspace)
- Wi-Fi that can reach GitHub
- A **private** git remote and a **write** deploy key

Do not tap Toggle USBNet. Start dropbear with the userspace `start-ssh` script if you need a shell.

## Install

```bash
# 1. Device already has start-ssh + git. From this repo:
just push kindle                 # or: ./scripts/push-to-device.sh kindle

# 2. Deploy key (dropbear format — OpenSSH PEM fails on dbclient)
just setup-remote                # prints the pubkey
# GitHub → repo Settings → Deploy keys → allow write
# scp the .dropbear key to /mnt/us/.ssh/id_scribe_notes

# 3. On the Scribe
cd /mnt/us/notes
git init
git remote add origin git@github.com:YOU/PRIVATE-NOTES.git

# 4. Proof
ssh kindle sh /mnt/us/bin/notes-sync selfcheck
```

Then: close a notebook → tap **Notes Sync** → `git pull` on the computer.

## Commands on the device

```sh
notes-sync            # export + commit + push
notes-sync export     # write notebooks/ only
notes-sync push       # commit + push
notes-sync selfcheck
```

Config: `/mnt/us/notes-sync.conf` (see `scripts/notes-sync.conf.example`).

## Honest limits

| Limit | Why |
|-------|-----|
| Not automatic | No watcher. Draw does not push. Tap **Notes Sync**. |
| `MISSING` notebooks | Amazon left the title in the library DB but no `.nbk` on disk. Open it once. |
| `.nbk` is Amazon's | Stock `sqlite3` will not open it. Covers are PNG. PDF conversion is a computer-side job. |
| Start SSH ≠ GitHub | `start-ssh` is a dropbear **server**. Push uses `dbclient` **out**. |

## Docs

- [Guide](docs/guide.md) — mechanism, reinstall, gotchas
- [FAQ](docs/faq.md)
- [Review notes](docs/review-notes.md) — what to decide before this is public
- [Security](SECURITY.md)

## License

MIT
