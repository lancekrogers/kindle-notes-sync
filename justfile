# kindle-notes-sync — install helpers

set dotenv-load := false

[private]
default:
    @just --list --justfile {{ source_file() }}

# Copy scripts onto a Scribe over SSH and run the installer
push HOST="kindle":
    ./scripts/push-to-device.sh {{ HOST }}

# Create a deploy key on this computer and print the GitHub step
setup-remote STEM="":
    #!/usr/bin/env sh
    if [ -n "{{ STEM }}" ]; then
      ./scripts/setup-remote.sh "{{ STEM }}"
    else
      ./scripts/setup-remote.sh
    fi

# Pull the notes payload repo (set NOTES_REPO)
pull:
    ./scripts/pull-notes.sh

# Syntax-check every shell script
check:
    #!/usr/bin/env sh
    set -e
    for f in scripts/*.sh; do
      sh -n "$f"
    done
    test -f .gitignore
    test -f SECURITY.md
    grep -q '\.nbk' .gitignore
    echo ok
