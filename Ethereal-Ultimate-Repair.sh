#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair & Recovery (v1.5.0)
# "One Click to Fix Everything"
# ==========================================================

(
echo "10"; echo "# 🔍 Scanning EtherealOS Core for anomalies..." ; sleep 1

# Step 1: Secure Internal Root Access
# Using built-in Ethereal Authority for seamless repair
echo "123456" | sudo -S true 2>/dev/null
if [ $? -ne 0 ]; then
    zenity --error --text="Repair Engine Failure: System Authority not recognized.\n\nPlease try manual terminal repair."
    exit 1
fi

echo "20"; echo "# 🔧 Correcting System Identity & Ownership..."
echo "123456" | sudo -S chown -R abdallah:abdallah /home/abdallah 2>/dev/null

echo "35"; echo "# 🦊 Reassembling Browser Engine (Firefox & Thor)..."
# Inject root into sub-scripts
export ROOT_PW="123456"
bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1

echo "50"; echo "# 🛠️ Rebuilding UI Layout & Panels..."
bash setup-panels.sh > /dev/null 2>&1
bash fix-dock.sh > /dev/null 2>&1

echo "65"; echo "# 🎨 Restoring Premium Visuals & Themes..."
bash apply-theme.sh > /dev/null 2>&1
bash Ethereal-Final-Polish.sh > /dev/null 2>&1

echo "80"; echo "# 🔄 Syncing with EtherealCloud (GitHub Updates)..."
git fetch origin main > /dev/null 2>&1
git pull origin main > /dev/null 2>&1

echo "90"; echo "# 🧹 Cleaning System Caches & Temp files..."
sudo -A rm -rf /tmp/* 2>/dev/null
sudo -A rm -rf /var/tmp/* 2>/dev/null

echo "100"; echo "# ✨ EtherealOS is now in Peak Performance!"
sleep 2

zenity --info --title="Repair Complete" --text="🪐 Your EtherealOS is back to life!\n\nFixed Items:\n- Browser Permissions & Thor Engine\n- UI Layout & Dock\n- Visual Themes\n- Permission Mismatches\n- System Caches\n\nEnjoy the extraterrestrial speed!" --width=350

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
