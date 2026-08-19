# FAQ

## Does drawing push to GitHub by itself?

No. Close the notebook, tap **Notes Sync**, Wi-Fi on. Amazon may WhisperSync to Amazon. That is not this tool.

## Do I need the computer on?

Not for the push. You need it later to `git pull`. There is no LaunchAgent in this repo.

## Why is my old notebook `MISSING`?

The library DB still has the title. The `.nbk` is not under `/mnt/us/.notebooks/<uuid>/`. Open that notebook on the Scribe so Amazon downloads it, close it, tap Notes Sync again.

## Can this pull every notebook from Amazon's cloud?

No. `SyncNotebooks` over LIPC was rejected on 5.19.5. We do not call Amazon's notebook APIs.

## Can I read `.nbk` on a computer?

Not with stock SQLite. Community tools (Calibre KFX Input / kfxlib) can render some notebooks to PDF on a computer. That is out of scope here.

## Is this kindle-userspace?

No. kindle-userspace is SSH / git / vim. This repo is the notebook export. Fold them later if you want one public landing page.

## Will this publish my notes?

Only if the remote is public or the deploy key is on a public repo. Use a private payload repo.
