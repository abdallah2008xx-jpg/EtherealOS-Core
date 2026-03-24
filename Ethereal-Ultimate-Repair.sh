#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v1.8.0)
# "TERMINAL SECURE REPAIR"
# ==========================================================

echo "🪐 EtherealOS Recovery System [Running in Admin Mode]"
echo "----------------------------------------------------"
echo "🔧 Please enter the Root Password (123456) to begin repair:"

# Try to get root directly in terminal
if ! sudo -v; then
    echo "❌ Incorrect password. Access Denied."
    sleep 3
    exit 1
fi

echo ""
echo "✅ Authority Granted. Starting Full Repair..."
echo ""

(
    # Step 1: Permissions
    echo "10"; echo "# 🔧 Correcting System Ownership..."
    sudo chown -R abdallah:abdallah /home/abdallah 2>/dev/null
    sleep 1

    # Step 2: Browsers
    echo "30"; echo "# 🦊 Repairing Browsers (Firefox & Thor)..."
    export ROOT_PW="123456"
    bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1
    sleep 1

    # Step 3: Desktop UI
    echo "50"; echo "# 🛠️ Rebuilding UI & Desktop Dock..."
    bash setup-panels.sh > /dev/null 2>&1
    bash fix-dock.sh > /dev/null 2>&1
    sleep 1

    # Step 4: Visuals
    echo "70"; echo "# 🎨 Restoring Premium Themes..."
    bash apply-theme.sh > /dev/null 2>&1
    bash Ethereal-Final-Polish.sh > /dev/null 2>&1
    sleep 1

    # Step 5: Cloud Sync
    echo "90"; echo "# 🔄 Syncing with Ethereal GitHub..."
    git pull origin main > /dev/null 2>&1
    sleep 1

    echo "100"; echo "# ✨ SYSTEM REPAIRED SUCCESSFULLY!"
) | zenity --progress --title="EtherealOS Final Repair" --percentage=0 --auto-close --width=400

echo ""
echo "🏆 Repair Complete! You can close this window."
sleep 2

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
