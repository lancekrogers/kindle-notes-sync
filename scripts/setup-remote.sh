#!/bin/sh
# Create a dropbear deploy key and print the GitHub step.
# Does not create a repo and does not upload the private key.
#
#   ./setup-remote.sh [key-stem]
#
# Add KEY.pub as a write-enabled deploy key on a *private* repo.

set -e

STEM=${1:-$HOME/.ssh/id_scribe_notes}
PUB=$STEM.pub
OPENSSH=$STEM.openssh
DROPBEAR=$STEM.dropbear

if [ ! -f "$STEM" ]; then
  ssh-keygen -t ed25519 -f "$STEM" -N "" -C "scribe-notes-deploy"
fi

# dbclient on the Kindle cannot read OpenSSH PEM ("String too long").
if command -v dropbearconvert >/dev/null 2>&1; then
  cp "$STEM" "$OPENSSH"
  dropbearconvert openssh dropbear "$STEM" "$DROPBEAR"
  echo "dropbear key: $DROPBEAR"
  echo "scp $DROPBEAR kindle:/mnt/us/.ssh/id_scribe_notes"
else
  echo "No dropbearconvert on this computer."
  echo "Copy the OpenSSH key to the Scribe and convert there:"
  echo "  scp $STEM kindle:/mnt/us/.ssh/id_scribe_notes.openssh"
  echo "  ssh kindle dropbearconvert openssh dropbear /mnt/us/.ssh/id_scribe_notes.openssh /mnt/us/.ssh/id_scribe_notes"
fi

echo
echo "Add this public key as a write deploy key on a private GitHub repo:"
echo
cat "$PUB"
echo
echo "On the Scribe (after install-notes-sync.sh):"
echo "  cd /mnt/us/notes"
echo "  git init"
echo "  git -c user.email=scribe@local -c user.name=scribe commit --allow-empty -m init || true"
echo "  git remote add origin git@github.com:YOU/PRIVATE-REPO.git"
echo "  # then: notes-sync"
