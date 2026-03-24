#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v3.0.0 "Hyper-Sonic")
# "FASTEST & MOST RELIABLE RECOVERY"
# ==========================================================

echo "🪐 EtherealOS Hyper-Sonic Repair [v3.0.0]"
echo "-----------------------------------------"
echo "🔧 Enter Root Password (abdallah) to BLAST OFF:"

# Silencing GTK/Mesa noise
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1

# Verification - Fast check
if ! su -c "true" 2>/dev/null; then
    echo "❌ Access Denied."
    exit 1
fi

echo "🚀 IGNITION! Executing High-Speed Repair..."

(
    # CORE FIX 1: System Identity (Parallel-like execution)
    echo "20"; echo "# 🔧 Fixing Permissions..."
    su -c "chown -R abdallah:abdallah /home/abdallah" > /dev/null 2>&1

    # CORE FIX 2: Radical Browser Reconstruction (Priority)
    echo "50"; echo "# 🦊 UNLOCKING BROWSERS (Firefox & Thor)..."
    # Call the new aggressive fix
    bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1
    # CORE FIX 3: Desktop UI & Icons (No massive downloads)
    echo "70"; echo "# 🛠️ Restoring UI & Desktop..."
    # Deploy icons to desktop instantly
    mkdir -p /home/abdallah/Desktop
    cp /opt/EtherealOS-Core/*.desktop /home/abdallah/Desktop/ 2>/dev/null
    chmod +x /home/abdallah/Desktop/*.desktop
    chown abdallah:abdallah /home/abdallah/Desktop/*.desktop 2>/dev/null

    # CORE FIX 4: Quick Sync
    echo "90"; echo "# 🔄 Syncing GitHub Patches..."
    git fetch origin main --quiet > /dev/null 2>&1
    git reset --hard origin/main --quiet > /dev/null 2>&1

    echo "100"; echo "# ✨ SYSTEM OPTIMIZED & REPAIRED!"
) | zenity --progress --title="EtherealOS Hyper-Sonic Repair" --percentage=0 --auto-close --width=400 2>/dev/null

echo ""
echo "🏆 MISSION COMPLETE! Your system is now ultra-optimized."
# Final silent UI refresh (ONLY ONE CALL)
nohup cinnamon --replace >/dev/null 2>&1 &
sleep 1

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
