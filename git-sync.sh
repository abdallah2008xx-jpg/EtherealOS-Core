#!/bin/bash
# ==========================================================
# EtherealOS - GitHub Sync Utility v1.0
# Automatically adds, commits, and pushes all changes.
# ==========================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "🔄 Syncing EtherealOS to GitHub..."

# 1. Add all changes (including untracked)
git add .

# 2. Check if there are changes to commit
if git diff --cached --quiet; then
    echo "✅ No changes to sync."
else
    # 3. Commit with a timestamped message
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    git commit -m "EtherealOS Update: $TIMESTAMP"
    
    # 4. Push to main branch
    echo "🚀 Pushing to GitHub..."
    if git push origin main; then
        echo "✅ Successfully synced to GitHub."
    else
        echo "❌ Error: Failed to push to GitHub. Check your connection/permissions."
        exit 1
    fi
fi
