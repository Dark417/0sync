#!/usr/bin/env bash
# Sync script: POSIX shell
# Usage: ./sync_repo.sh [repo-path] [remote-spec]
# remote-spec default: mygithub/lc (will use https://github.com/mygithub/lc.git)

set -euo pipefail
REPO_DIR="${1:-$(pwd)}"
REMOTE_SPEC="${2:-mygithub/lc}"
REMOTE_NAME=origin
REMOTE_URL="https://github.com/${REMOTE_SPEC}.git"
LOGFILE="$REPO_DIR/0sync.log"

cd "$REPO_DIR"

while true; do
  if [ ! -d .git ]; then
    git init >> "$LOGFILE" 2>&1 || true
  fi

  if ! git remote | grep -q "^${REMOTE_NAME}$"; then
    if command -v gh >/dev/null 2>&1; then
      gh repo create "$REMOTE_SPEC" --public --source=. --remote="$REMOTE_NAME" --push >> "$LOGFILE" 2>&1 || true
    else
      git remote add "$REMOTE_NAME" "$REMOTE_URL" >> "$LOGFILE" 2>&1 || true
    fi
  fi

  git fetch "$REMOTE_NAME" --quiet >> "$LOGFILE" 2>&1 || true

  BRANCH=main
  if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    git checkout -b "$BRANCH" >> "$LOGFILE" 2>&1 || true
  else
    git checkout "$BRANCH" >> "$LOGFILE" 2>&1 || true
  fi

  if git pull "$REMOTE_NAME" "$BRANCH" --quiet >> "$LOGFILE" 2>&1; then
    echo "$(date --iso-8601=seconds): pull ok" >> "$LOGFILE"
  else
    echo "$(date --iso-8601=seconds): pull failed" >> "$LOGFILE"
  fi

  if [ -n "$(git status --porcelain)" ]; then
    git add -A >> "$LOGFILE" 2>&1 || true
    git commit -m "Sync commit" >> "$LOGFILE" 2>&1 || true
  fi

  if ! git ls-remote --exit-code "$REMOTE_NAME" >/dev/null 2>&1; then
    if command -v gh >/dev/null 2>&1; then
      gh repo create "$REMOTE_SPEC" --public --source=. --remote="$REMOTE_NAME" --push >> "$LOGFILE" 2>&1 || true
    else
      git push -u "$REMOTE_NAME" "$BRANCH" >> "$LOGFILE" 2>&1 || true
    fi
  else
    git push "$REMOTE_NAME" "$BRANCH" --quiet >> "$LOGFILE" 2>&1 || true
  fi

  sleep 60
done
