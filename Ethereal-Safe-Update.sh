#!/bin/bash
# ==========================================================
# EtherealOS - Safe Update System v1.1
# "Absolute Security" - Auto-Snapshot before Emerge
# ==========================================================

# ── Privilege Check: Self-Elevate if needed ──
if [ "$(id -u)" -ne 0 ]; then
    echo "🔑 EtherealOS: Admin privileges required for system update."
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec bash "$0" "$@"
    else
        exec sudo bash "$0" "$@"
    fi
fi

echo "🛡️ Initializing Safe Update..."

# 1. Ensure Timeshift is installed
if ! command -v timeshift >/dev/null 2>&1; then
    echo "📦 Installing Timeshift..."
    emerge --ask=n --quiet app-backup/timeshift 2>/dev/null || true
fi

# 2. Check for Btrfs
IS_BTRFS=$(findmnt -n -o FSTYPE /)
if [ "$IS_BTRFS" == "btrfs" ]; then
    echo "💎 Btrfs detected. Snapshots will be instantaneous."
else
    echo "📂 RSYNC mode will be used for snapshots."
fi

# 3. Take a Mandatory Snapshot
echo "📸 Creating Pre-Update System Snapshot..."
SN_COMMENT="Pre-Update-$(date +%Y%m%d-%H%M)"
timeshift --create --comments "$SN_COMMENT" --tags D

if [ $? -eq 0 ]; then
    echo "✅ Snapshot created: $SN_COMMENT"
else
    echo "❌ FAILED to create snapshot. Aborting update for your safety."
    exit 1
fi

# 4. Proceed with System Update
echo "🚀 Starting EtherealOS System Update..."
emaint sync -a
emerge --update --deep --newuse @world

echo "✨ Update complete. Your system is safe."
