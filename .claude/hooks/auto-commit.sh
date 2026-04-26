#!/usr/bin/env bash
# Auto-commit and push at end of each work turn (Stop hook)

git rev-parse --git-dir > /dev/null 2>&1 || exit 0

git add -A 2>/dev/null || true

if [ -z "$(git diff --cached --name-only 2>/dev/null)" ]; then
  exit 0
fi

COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
FILES=$(git diff --cached --name-only | head -6 | tr '\n' ' ' | sed 's/ $//')
DATE=$(date '+%Y-%m-%d %H:%M')

if [ "$COUNT" -gt 6 ]; then
  MSG="Checkpoint [${DATE}]: ${COUNT} files updated"
else
  MSG="Checkpoint [${DATE}]: ${FILES}"
fi

git commit -m "$MSG" 2>/dev/null && git push 2>/dev/null || true
