#!/bin/sh
# Install notes-sync onto this Scribe. Run on the device after the
# toolkit directory has been copied (see push-to-device.sh).
set -e

HERE=$(dirname "$0")
BIN=/mnt/us/bin
DOCS=/mnt/us/documents

mkdir -p "$BIN" "$DOCS" /mnt/us/.ssh /mnt/us/notes

cp "$HERE/notes-sync.sh" "$BIN/notes-sync"
cp "$HERE/git-ssh-scribe.sh" "$BIN/git-ssh-scribe"
cp "$HERE/scriptlet-Notes-Sync.sh" "$DOCS/Notes-Sync.sh"
chmod 755 "$BIN/notes-sync" "$BIN/git-ssh-scribe" "$DOCS/Notes-Sync.sh"

if [ ! -f /mnt/us/notes-sync.conf ]; then
  cp "$HERE/notes-sync.conf.example" /mnt/us/notes-sync.conf
fi

echo "installed Notes Sync scriptlet + /mnt/us/bin/notes-sync"
sh "$BIN/notes-sync" selfcheck || true
