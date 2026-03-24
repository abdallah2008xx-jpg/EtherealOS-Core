#!/bin/bash
# ==========================================================
# EtherealOS - BROWSER RESCUE v4.0
# This script MUST be run as root:
#   su -
#   cd ~/ethereal-update && bash Ethereal-Browser-Rescue.sh
# ==========================================================

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  ❌ This script MUST be run as ROOT!            ║"
    echo "║                                                  ║"
    echo "║  Do this:                                        ║"
    echo "║  1. Type: su -       (password: abdallah)        ║"
    echo "║  2. Then run:                                    ║"
    echo "║     cd /home/abdallah/ethereal-update            ║"
    echo "║     bash Ethereal-Browser-Rescue.sh              ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

echo ""
echo "🦊 EtherealOS Browser Rescue v4.0"
echo "=================================="
echo ""

# ── Step 1: Kill any stuck browser processes ──
echo "[1/6] 🔪 Killing stuck browser processes..."
pkill -9 -f firefox 2>/dev/null
pkill -9 -f firefox-bin 2>/dev/null
pkill -9 -f epiphany 2>/dev/null
echo "  ✅ Done"

# ── Step 2: Fix ALL home directory permissions ──
echo "[2/6] 🔧 Fixing home directory permissions..."
chown -R abdallah:abdallah /home/abdallah
chmod 755 /home/abdallah
echo "  ✅ Done"

# ── Step 3: Completely rebuild Firefox profile ──
echo "[3/6] 🦊 Rebuilding Firefox profile from scratch..."

# Remove everything mozilla-related
rm -rf /home/abdallah/.mozilla
rm -rf /home/abdallah/.cache/mozilla
rm -rf /home/abdallah/snap/firefox 2>/dev/null

# Create fresh profile directory structure
mkdir -p /home/abdallah/.mozilla/firefox/ethereal.default-release

# Create profiles.ini - THIS IS THE KEY FILE
cat > /home/abdallah/.mozilla/firefox/profiles.ini << 'PROFILES'
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
PROFILES

# Create installs.ini
cat > /home/abdallah/.mozilla/firefox/installs.ini << 'INSTALLS'
[4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1
INSTALLS

# Set correct ownership
chown -R abdallah:abdallah /home/abdallah/.mozilla
echo "  ✅ Firefox profile rebuilt"

# ── Step 4: Check which Firefox binary exists ──
echo "[4/6] 🔍 Checking Firefox installation..."
FIREFOX_BIN=""
if [ -x /usr/bin/firefox ]; then
    FIREFOX_BIN="/usr/bin/firefox"
    echo "  ✅ Found: /usr/bin/firefox"
elif [ -x /usr/bin/firefox-bin ]; then
    FIREFOX_BIN="/usr/bin/firefox-bin"
    echo "  ✅ Found: /usr/bin/firefox-bin"
    # Create symlink so 'firefox' command works
    ln -sf /usr/bin/firefox-bin /usr/bin/firefox
    echo "  ✅ Created symlink: firefox -> firefox-bin"
elif [ -x /opt/firefox/firefox ]; then
    FIREFOX_BIN="/opt/firefox/firefox"
    ln -sf /opt/firefox/firefox /usr/bin/firefox
    echo "  ✅ Found: /opt/firefox/firefox (linked)"
else
    echo "  ⚠️  Firefox NOT found! Will try to install..."
    emerge --ask=n www-client/firefox-bin > /dev/null 2>&1
    if [ -x /usr/bin/firefox-bin ]; then
        ln -sf /usr/bin/firefox-bin /usr/bin/firefox
        FIREFOX_BIN="/usr/bin/firefox-bin"
        echo "  ✅ Firefox-bin installed and linked"
    else
        echo "  ❌ Firefox install failed (no internet?)"
    fi
fi

# ── Step 5: Setup Thor (Epiphany) as backup browser ──
echo "[5/6] ⚡ Setting up Thor Browser (backup)..."
THOR_OK=false
if command -v epiphany >/dev/null 2>&1; then
    ln -sf "$(which epiphany)" /usr/bin/thor
    THOR_OK=true
    echo "  ✅ Thor Browser ready (epiphany engine)"
elif command -v epiphany-browser >/dev/null 2>&1; then
    ln -sf "$(which epiphany-browser)" /usr/bin/thor
    THOR_OK=true
    echo "  ✅ Thor Browser ready"
else
    echo "  ⚠️  Epiphany not found. Trying to install..."
    emerge --ask=n net-libs/webkit-gtk gnome-base/gnome-keyring > /dev/null 2>&1
    emerge --ask=n www-client/epiphany > /dev/null 2>&1
    if command -v epiphany >/dev/null 2>&1; then
        ln -sf "$(which epiphany)" /usr/bin/thor
        THOR_OK=true
        echo "  ✅ Thor Browser installed"
    else
        echo "  ❌ Thor install failed"
    fi
fi

# Create Thor desktop entry
if [ "$THOR_OK" = true ]; then
    cat > /home/abdallah/Desktop/Thor_Browser.desktop << 'THOR'
[Desktop Entry]
Type=Application
Name=⚡ Thor Browser
Comment=Ultra-fast EtherealOS Browser
Exec=thor %u
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;
THOR
    chmod +x /home/abdallah/Desktop/Thor_Browser.desktop
    chown abdallah:abdallah /home/abdallah/Desktop/Thor_Browser.desktop
fi

# ── Step 6: Final permission sweep ──
echo "[6/6] 🔒 Final permission cleanup..."
chown -R abdallah:abdallah /home/abdallah
echo "  ✅ All permissions corrected"

# ── Summary ──
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  🏆 BROWSER RESCUE COMPLETE!                    ║"
echo "╠══════════════════════════════════════════════════╣"
if [ -n "$FIREFOX_BIN" ]; then
echo "║  🦊 Firefox: READY  ($FIREFOX_BIN)"
else
echo "║  🦊 Firefox: NOT INSTALLED                      ║"
fi
if [ "$THOR_OK" = true ]; then
echo "║  ⚡ Thor:    READY  (/usr/bin/thor)              ║"
else
echo "║  ⚡ Thor:    NOT INSTALLED                       ║"
fi
echo "╠══════════════════════════════════════════════════╣"
echo "║  Now try opening Firefox or Thor!               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
