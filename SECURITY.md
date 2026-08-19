# What this repo is allowed to contain

This tree is the **tool**. Notebooks stay in a **private** payload repo.

## Never commit

- Notebook files (`.nbk`, covers, `actions.log`, `live.svg`, personal `INDEX.md`)
- Deploy keys, OpenSSH keys, `authorized_keys`, dropbear host keys
- Device serials, Wi-Fi MACs, lab IPs, host aliases
- Jailbreak books, firmware images, UKS PEMs
- DRM tools

The notes remote must be **private**. A write deploy key on a public repo publishes every tap of Notes Sync.

## Pull requests

Rewrite scripts so they have no host paths and no payloads. Do not paste `notes-sync.log` from a real device.

## Scope

Right to repair on hardware you own. Amazon still boots the device. We do not attack Amazon infrastructure.
