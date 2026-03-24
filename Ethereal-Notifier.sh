#!/bin/bash
# ==========================================================
# EtherealOS - Update Notifier v2.0.0 (Lightweight)
# Quick check - NO downloads, NO heavy operations
# ==========================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit 0

# Don't run if no git
[ ! -d ".git" ] && exit 0

# Quick silent check (timeout 10 seconds max)
timeout 10 git fetch origin main > /dev/null 2>&1 || exit 0

NEW_COMMITS=$(git rev-list HEAD..origin/main --count 2>/dev/null)

if [ "$NEW_COMMITS" -gt 0 ]; then
    notify-send "🪐 EtherealOS" "$NEW_COMMITS update(s) available" 2>/dev/null || \
    zenity --notification --text="🪐 $NEW_COMMITS update(s) available" 2>/dev/null &
fi
