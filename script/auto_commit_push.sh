#!/bin/bash
# Auto commit and push script for Claude Code hook
# Usage: Called automatically after Edit/Write tool use

cd "$(git rev-parse --show-toplevel)" || exit 0

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet; then
  exit 0
fi

# Stage all changes
git add -A

# Create commit message with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "Auto-commit: ${TIMESTAMP}

🤖 Generated with Claude Code" --no-verify

# Push to origin
git push origin main 2>/dev/null || git push 2>/dev/null || true
