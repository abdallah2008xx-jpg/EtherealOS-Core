#!/bin/bash
# ==========================================================
# EtherealOS Update v4.13 - LIGHTWEIGHT Auto-Updater
# ==========================================================

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# ═══════════════════════════════════════════
# STEP 1: Fix Browser FIRST (outside zenity pipe!)
# ═══════════════════════════════════════════
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

# Deploy autostart for future boots
mkdir -p /home/abdallah/.config/autostart
cp Ethereal-Browser-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null
cp Ethereal-Notifier-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null

# ═══════════════════════════════════════════
# STEP 2: Update & Deploy (inside zenity for UI)
# ═══════════════════════════════════════════
(
echo "5"; echo "# 📶 Checking Internet Connection..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Error: No internet connection. Update aborted." >&2
    exit 1
fi

echo "10"; echo "# 📡 Contacting Ethereal Servers..." ; sleep 1

echo "25"; echo "# 📸 Creating Safety Snapshot..."
sudo timeshift --create --comments "Auto-Snapshot before Update" --tags O > /dev/null 2>&1
sleep 1

echo "35"; echo "# ⬇️ Downloading Updates..."
if ! git pull origin main 2>&1; then
    echo "Error: Failed to pull updates from GitHub." >&2
    exit 1
fi
sleep 1

echo "45"; echo "# 🏥 System Health Check..."
# Ensure Flatpak is configured
if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null
fi
# Ensure Snapd is running
if command -v snap >/dev/null 2>&1; then
    sudo rc-service snapd start 2>/dev/null || true
fi

echo "45"; echo "# 🧹 Cleaning old desktop icons..."
# Remove ALL old .desktop files from Desktop, then re-copy fresh ones
# This ensures deleted icons (like TaskMgr) get removed properly
rm -f /home/abdallah/Desktop/*.desktop 2>/dev/null

echo "55"; echo "# 📂 Deploying Desktop Icons..."
mkdir -p /home/abdallah/Desktop
# Copy all .desktop files from repo EXCEPT internal Autostart ones
find "$REPO_DIR" -maxdepth 1 -name "*.desktop" ! -name "*-Autostart.desktop" -exec cp {} /home/abdallah/Desktop/ \;
chmod +x /home/abdallah/Desktop/*.desktop 2>/dev/null

# Mark desktop files as trusted (Cinnamon/Nemo requirement)
echo "58"; echo "# 🔐 Marking launchers as trusted..."
for file in /home/abdallah/Desktop/*.desktop; do
    [ -f "$file" ] && gio set "$file" metadata::trusted true 2>/dev/null || true
done

# Update icons
echo "60"; echo "# 🎨 Updating App Icons..."
mkdir -p /home/abdallah/.local/share/icons/ethereal
cp "$REPO_DIR"/icons/*.svg /home/abdallah/.local/share/icons/ethereal/ 2>/dev/null

# Update Papirus icon theme
echo "65"; echo "# 📦 Updating Papirus Icon Theme..."
bash "$REPO_DIR"/install-papirus-icons.sh 2>/dev/null || true

echo "80"; echo "# 🎨 Applying Theme..."
bash apply-theme.sh > /dev/null 2>&1

echo "100"; echo "# ✨ Update Complete!"
sleep 1
) | zenity --progress --title="🪐 EtherealOS Update" \
           --text="Checking for updates..." \
           --percentage=0 --auto-close --auto-kill --width=400 2>/dev/null

VERSION=$(cat "$REPO_DIR/version.txt" 2>/dev/null || echo "latest")
zenity --info --title="Update Complete" --text="✅ EtherealOS v${VERSION} Updated!\n\n🦊 Firefox is ready.\n🖱️ Right-click taskbar → Task Manager" --width=300 2>/dev/null &
