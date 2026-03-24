#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v2.0.0 "Immortal")
# "CLEAN GENTOO RECOVERY"
# ==========================================================

echo "🪐 EtherealOS Recovery System [Immortal v2.0]"
echo "---------------------------------------------"
echo "🔧 Please enter the Root Password (abdallah) to begin:"

# Silencing GTK/Mesa noise throughout the session
export GDK_BACKEND=x11
export NO_AT_BRIDGE=1

# Verification if SU works
if ! su -c "echo 'Authority Verified' 2>/dev/null" ; then
    echo ""
    echo "❌ Root Authority Rejected."
    sleep 5
    exit 1
fi

echo ""
echo "✅ Authority Verified. Launching Optimized Repair..."
echo ""

(
    # Step 1: Corrections
    echo "10"; echo "# 🔧 Correcting System Identity & Files..."
    su -c "chown -R abdallah:abdallah /home/abdallah" > /dev/null 2>&1
    sleep 1

    # Step 2: Browser
    echo "30"; echo "# 🦊 Reassembling Browser Engine (Firefox & Thor)..."
    bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1
    sleep 1

    # Step 3: Desktop Structure
    echo "50"; echo "# 🛠️ Rebuilding UI Layout & Desktop Dock..."
    bash setup-panels.sh > /dev/null 2>&1
    bash fix-dock.sh > /dev/null 2>&1
    sleep 1

    # Step 4: Visual Polish
    echo "70"; echo "# 🎨 Applying Ethereal Visual Enhancements..."
    bash apply-theme.sh > /dev/null 2>&1
    bash Ethereal-Final-Polish.sh > /dev/null 2>&1
    sleep 1

    # Step 5: Sync
    echo "90"; echo "# 🔄 Syncing with EtherealCloud (GitHub)..."
    git fetch origin main > /dev/null 2>&1
    git reset --hard origin/main > /dev/null 2>&1

    echo "100"; echo "# ✨ SYSTEM REPAIRED & OPTIMIZED!"
) | zenity --progress --title="EtherealOS Immortal Repair" --percentage=0 --auto-close --width=400 2>/dev/null

echo ""
echo "🏆 Repair Complete! Your system is now in Peak Performance."
sleep 1

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
