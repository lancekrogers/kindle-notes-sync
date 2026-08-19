#!/bin/sh
# Copy this toolkit onto a Scribe over SSH and run the installer.
# The host alias must already work (start-ssh + a userstore key).
set -e

HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
HOST=${1:-kindle}
STAGE=/mnt/us/notes-sync-stage

ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST" "mkdir -p $STAGE"
scp -o ConnectTimeout=8 \
  "$HERE/notes-sync.sh" \
  "$HERE/git-ssh-scribe.sh" \
  "$HERE/scriptlet-Notes-Sync.sh" \
  "$HERE/install-notes-sync.sh" \
  "$HERE/notes-sync.conf.example" \
  "$HOST:$STAGE/"
ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST" "sh $STAGE/install-notes-sync.sh"
echo "device updated from $HERE"
