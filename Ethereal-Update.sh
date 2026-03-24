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

# Deploy browser autostart (fixes browser on every boot!)
mkdir -p /home/abdallah/.config/autostart
cp Ethereal-Browser-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null
cp Ethereal-Notifier-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null

# Also fix browser profile RIGHT NOW (for this session)
mkdir -p /home/abdallah/.mozilla/firefox/ethereal.default-release
if [ ! -f /home/abdallah/.mozilla/firefox/profiles.ini ]; then
    cat > /home/abdallah/.mozilla/firefox/profiles.ini << 'PROF'
[Install4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1

[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default-release
IsRelative=1
Path=ethereal.default-release
Default=1
PROF
fi

echo "80"; echo "# 🎨 Applying Theme Updates..."
# Only copy CSS files - NO downloads, NO wget, NO emerge
bash apply-theme.sh > /dev/null 2>&1

echo "100"; echo "# ✨ Update Complete!"
sleep 1
) | zenity --progress --title="🪐 EtherealOS Update" \
           --text="Checking for updates..." \
           --percentage=0 --auto-close --auto-kill --width=400 2>/dev/null

zenity --info --title="Update Complete" --text="✅ EtherealOS Updated!\n\nAll patches applied." --width=300 2>/dev/null &
