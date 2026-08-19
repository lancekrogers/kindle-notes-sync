#!/bin/sh
# GIT_SSH helper: Dropbear client + a write deploy key.
# OpenSSH PEM fails on dbclient with "String too long". Use dropbear format.
# See docs/guide.md.

KEY=${SCRIBE_DEPLOY_KEY:-/mnt/us/.ssh/id_scribe_notes}
if [ ! -f "$KEY" ]; then
  echo "git-ssh-scribe: missing $KEY" >&2
  exit 1
fi

if command -v dbclient >/dev/null 2>&1; then
  exec dbclient -i "$KEY" -y "$@"
fi

MULTI=/mnt/us/usbnetlite/bin/dropbearmulti
if [ -x "$MULTI" ]; then
  exec "$MULTI" dbclient -i "$KEY" -y "$@"
fi

echo "git-ssh-scribe: no dbclient" >&2
exit 1
