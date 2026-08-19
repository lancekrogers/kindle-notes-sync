#!/bin/sh
# Pull the notes payload repo onto this computer.
#   NOTES_REPO=/path/to/clone ./pull-notes.sh
set -e

REPO=${NOTES_REPO:-$HOME/Notes/scribe}
if [ ! -d "$REPO/.git" ]; then
  echo "not a git repo: $REPO" >&2
  echo "clone your private notes remote there, or set NOTES_REPO" >&2
  exit 1
fi
cd "$REPO"
git pull
echo "pulled -> $REPO"
ls -lt | head -12
