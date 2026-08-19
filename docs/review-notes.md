# Review notes (keep this file until the repo is public)

Private on purpose. README is written as if this will be public (hero, topics, profile links). Flip visibility when you are done reading. Do not merge into kindle-userspace by accident.

## Why this is a separate repo

kindle-userspace is already public. One commit there is live. This tree is the review gate.

## Still rough

- Proven on **one** first-gen Scribe, 5.19.5. No other firmware in CI.
- No automatic push (close / timer / boot).
- No on-device PDF.
- `push-to-device.sh` assumes an SSH host alias and musl git already installed.
- `setup-remote.sh` cannot convert to dropbear unless `dropbearconvert` is on the computer.
- Folder names with odd Unicode are only as safe as `tr` / FAT.

## Must not be in a public tree

- Anything from a real `scribe-notes` payload (`.nbk`, covers, personal titles)
- `/mnt/us/.ssh/id_scribe_notes` and the matching pubkey write-up
- Lab IPs, serials, `ssh scribe` aliases that identify a house network
- Explore workitem dumps (Véra books, UKS, crash tarballs)

This `docs/review-notes.md` can stay (no secrets) or be deleted at publish time.

## Publish options after review

1. Make **this** repo public. Keep payload repos private.
2. Copy `scripts/` + a short doc into kindle-userspace and archive this repo.
3. Stay private and treat it as a personal tool.

Do not vendor notebooks into kindle-userspace either way.
