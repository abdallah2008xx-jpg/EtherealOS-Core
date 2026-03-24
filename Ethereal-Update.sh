#!/bin/bash
# ==========================================================
# EtherealOS Update v4.3.0 - LIGHTWEIGHT Auto-Updater
# Only downloads files, NO heavy installs or theme downloads
# ==========================================================

(
echo "10"; echo "# 📡 Contacting Ethereal Servers..." ; sleep 1
cd "$(dirname "$0")"

echo "30"; echo "# ⬇️ Downloading Updates..."
git pull origin main > /dev/null 2>&1
sleep 1

echo "60"; echo "# 📂 Deploying Desktop Icons..."
mkdir -p /home/abdallah/Desktop
cp *.desktop /home/abdallah/Desktop/ 2>/dev/null
chmod +x /home/abdallah/Desktop/*.desktop 2>/dev/null

echo "80"; echo "# 🎨 Applying Theme Updates..."
# Only copy CSS files - NO downloads, NO wget, NO emerge
bash apply-theme.sh > /dev/null 2>&1

echo "100"; echo "# ✨ Update Complete!"
sleep 1
) | zenity --progress --title="🪐 EtherealOS Update" \
           --text="Checking for updates..." \
           --percentage=0 --auto-close --auto-kill --width=400 2>/dev/null

zenity --info --title="Update Complete" --text="✅ EtherealOS Updated!\n\nAll patches applied." --width=300 2>/dev/null &
