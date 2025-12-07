# 0sync

Lightweight repo sync utilities and automation for monitoring and syncing this folder to GitHub.

Contains:
- `sync_repo.bat` - Windows continuous sync (runs every minute)
- `sync_repo.sh` - POSIX/WSL continuous sync (runs every minute)
- `pr.bat` - commit and push helper (uses absolute path)

Requirements
- `git` installed and available on PATH
- Optional: GitHub CLI `gh` (for creating repositories from CLI)

Usage
- Windows: `0sync\sync_repo.bat [repo-path] [remote-spec]`
- POSIX: `./sync_repo.sh [repo-path] [remote-spec]`
- To commit & push project files: run `pr.bat` from this folder
