# ==========================================================
# EtherealOS Final Polish
# Fills in the missing visual gaps: Window Borders, Cursors, 
# and a glorious Terminal Welcome Screen.
# ==========================================================

# ── Privilege Check: Self-Elevate if needed ──
# This ensures the user is prompted only ONCE for the entire script.
if [ "$(id -u)" -ne 0 ]; then
    echo "🔑 EtherealOS: Admin privileges required. Please authenticate once."
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec bash "$0" "$@"
    else
        exec sudo bash "$0" "$@"
    fi
fi

# Determine the original user to keep home directory operations correct
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "1. Installing Premium Window Borders (WhiteSur Theme for Metacity/GTK)..."
mkdir -p "$REAL_HOME/.themes"
# Run the theme installer as the real user to avoid root-owned files in home
su - "$REAL_USER" -c "wget -qO- https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/install.sh | bash -s -- -d $REAL_HOME/.themes -t all -N glassy"

echo "2. Applying the Window Borders & GTK UI..."
su - "$REAL_USER" -c "gsettings set org.cinnamon.desktop.wm.preferences theme 'WhiteSur-Dark'"
su - "$REAL_USER" -c "gsettings set org.cinnamon.desktop.interface gtk-theme 'WhiteSur-Dark'"

echo "3. Installing Official EtherealOS Premium Icon Engine (Papirus)..."
mkdir -p "$REAL_HOME/.icons"
su - "$REAL_USER" -c "wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | DESTDIR=\"$REAL_HOME/.icons\" sh 2>/dev/null || true"
su - "$REAL_USER" -c "gsettings set org.cinnamon.desktop.interface icon-theme 'Papirus-Dark'"

echo "4. Configuring Ultra-Premium Navigation Animations..."
# Enable 3D Coverflow for Alt-Tab Window Navigation! (Like macOS / Compiz)
gsettings set org.cinnamon alttab-switcher-style 'coverflow'
# Enable Expo/Scale animations for workspaces
gsettings set org.cinnamon desktop-effects-workspace 'scale'
gsettings set org.cinnamon.muffin wobbly-windows true
gsettings set org.cinnamon.muffin desktop-effects true

echo "3. Installing Premium Mouse Cursor (Capitaine/Mac Style)..."
mkdir -p "$REAL_HOME/.icons"
if [ ! -d "$REAL_HOME/.icons/capitaine-cursors" ]; then
    su - "$REAL_USER" -c "wget -qO- https://github.com/keeferrourke/capitaine-cursors/releases/latest/download/capitaine-cursors-linux.tar.gz | tar -xz -C $REAL_HOME/.icons/"
fi
su - "$REAL_USER" -c "gsettings set org.cinnamon.desktop.interface cursor-theme 'capitaine-cursors'"

# Ensure Cursor Consistency (Inheritance for X11/GTK apps)
mkdir -p "$REAL_HOME/.icons/default"
echo "[Icon Theme]
Inherits=capitaine-cursors" > "$REAL_HOME/.icons/default/index.theme"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.icons/default"

# Also set for X11 specifically
echo "Xcursor.theme: capitaine-cursors" >> "$REAL_HOME/.Xresources"
su - "$REAL_USER" -c "xrdb -merge $REAL_HOME/.Xresources" 2>/dev/null || true

echo "4. Injecting EtherealOS Logo into Terminal (Neofetch)..."
# Create a custom ascii logo for EtherealOS
mkdir -p "$REAL_HOME/.config/neofetch"
cat << 'EOF' > "$REAL_HOME/.config/neofetch/ethereal.txt"
${c1}
    . . .    
  .       .  
 .         . 
.   ${c2}ETHEREAL${c1} .
 .         . 
  .       .  
    . . .    
EOF
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/neofetch"

# Only add neofetch if it's not already in .bashrc
if ! grep -q "neofetch --source $REAL_HOME/.config/neofetch/ethereal.txt" "$REAL_HOME/.bashrc" 2>/dev/null; then
    echo "command -v neofetch >/dev/null 2>&1 && neofetch --source $REAL_HOME/.config/neofetch/ethereal.txt --ascii_colors 6 4" >> "$REAL_HOME/.bashrc"
fi

echo "5. Adding Windows+Shift+S for Snip/Area Screenshot..."
gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot "['<Shift><Super>s']" 2>/dev/null
# Add a custom keybinding fallback just in case the media-keys binding defaults are wonky
CUSTOM_LIST=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null | grep -v 'custom-snip')
if [ -n "$CUSTOM_LIST" ] && [ "$CUSTOM_LIST" != "@as []" ]; then
    NEW_LIST=$(echo "$CUSTOM_LIST" | sed "s/\]/, 'custom-snip'\]/")
else
    NEW_LIST="['custom-snip']"
fi
gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_LIST" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ name "Ethereal Snipping Tool" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ command "gnome-screenshot -a" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ binding "['<Shift><Super>s']" 2>/dev/null

echo "6. Enabling Flatpak & Snap Support (Binary Apps)..."
# This allows users to install apps without waiting for long compile times.
if ! command -v flatpak >/dev/null 2>&1; then
    echo "   → Installing Flatpak..."
    emerge --ask=n --quiet sys-apps/flatpak 2>/dev/null || true
fi
if command -v flatpak >/dev/null 2>&1; then
    echo "   → Adding Flathub Repository..."
    su - "$REAL_USER" -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
fi

if ! command -v snap >/dev/null 2>&1; then
    echo "   → Installing Snapd..."
    emerge --ask=n --quiet app-containers/snapd 2>/dev/null || true
fi
if command -v snap >/dev/null 2>&1; then
    echo "   → Enabling Snap Service..."
    rc-update add snapd default 2>/dev/null || true
    rc-service snapd start 2>/dev/null || true
    # Create the /snap symlink if it doesn't exist
    [ ! -L /snap ] && ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
fi

echo "7. Enhancing Hardware (Battery, Printing, Bluetooth)..."
# A. Power Management (TLP)
if ! command -v tlp >/dev/null 2>&1; then
    echo "   → Installing TLP Power Management..."
    emerge --ask=n --quiet sys-power/tlp 2>/dev/null || true
fi
if command -v tlp >/dev/null 2>&1; then
    rc-update add tlp default 2>/dev/null || true
    rc-service tlp start 2>/dev/null || true
fi

# B. Printing Support (CUPS & Drivers)
if ! command -v cupsd >/dev/null 2>&1; then
    echo "   → Installing CUPS & Printer Drivers..."
    emerge --ask=n --quiet net-print/cups net-print/foomatic-db net-print/foomatic-db-engine net-print/gutenprint 2>/dev/null || true
fi
if command -v cupsd >/dev/null 2>&1; then
    rc-update add cupsd default 2>/dev/null || true
    rc-service cupsd start 2>/dev/null || true
fi

# C. Bluetooth Support (Bluez & Blueman)
if ! command -v bluetoothd >/dev/null 2>&1; then
    echo "   → Installing Bluetooth Stack..."
    emerge --ask=n --quiet net-wireless/bluez net-wireless/blueman 2>/dev/null || true
fi
if command -v bluetoothd >/dev/null 2>&1; then
    rc-update add bluetooth default 2>/dev/null || true
    rc-service bluetooth start 2>/dev/null || true
    # Fix: Enable Bluetooth Auto-Connect
    if [ -f /etc/bluetooth/main.conf ]; then
        sed -i 's/^#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
        sed -i 's/^AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
    fi
fi

# D. Thermal Management (thermald)
if ! command -v thermald >/dev/null 2>&1; then
    echo "   → Installing Thermal Management (CPU Protection)..."
    emerge --ask=n --quiet sys-apps/thermald 2>/dev/null || true
fi
if command -v thermald >/dev/null 2>&1; then
    rc-update add thermald default 2>/dev/null || true
    rc-service thermald start 2>/dev/null || true
fi

# E. Auto-Mount Support (gvfs & udisks)
echo "   → Configuring Auto-Mount for External Drives..."
emerge --ask=n --quiet gnome-base/gvfs sys-apps/udisks 2>/dev/null || true
rc-update add udisks2 default 2>/dev/null || true
rc-service udisks2 start 2>/dev/null || true

# Configure Cinnamon to auto-mount when a drive is plugged in
gsettings set org.cinnamon.desktop.media-handling automount true 2>/dev/null
gsettings set org.cinnamon.desktop.media-handling automount-open true 2>/dev/null

echo "8. Integrating Multimedia Codecs (Video Fix)..."
# Call the codec setup script (as root)
if [ -f "$(dirname "$0")/Ethereal-Codecs-Setup.sh" ]; then
    sudo bash "$(dirname "$0")/Ethereal-Codecs-Setup.sh"
fi

echo "9. Deploying Glassmorphism Notification System (Dunst)..."
# Ensure dunst is installed
if ! command -v dunst >/dev/null 2>&1; then
    emerge --ask=n --quiet x11-misc/dunst 2>/dev/null || true
fi
# Deploy Dunst config
mkdir -p "$REAL_HOME/.config/dunst"
if [ -f "$(dirname "$0")/dunstrc" ]; then
    cp "$(dirname "$0")/dunstrc" "$REAL_HOME/.config/dunst/dunstrc"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/dunst"
fi

echo "10. Integrating Privacy Portals (Flatpak/XDG)..."
# Install XDG Desktop Portals for camera/mic permission prompts
emerge --ask=n --quiet sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk sys-apps/xdg-desktop-portal-xapp 2>/dev/null || true

echo "11. Enabling Fractional Scaling (HiDPI Support)..."
# Enable experimental fractional scaling in Cinnamon
gsettings set org.cinnamon.muffin experimental-features "['scale-monitor-framebuffer']" 2>/dev/null

echo "12. Enabling Eye Comfort (Night Light)..."
# Enable Cinnamon's native Night Light with an automatic schedule
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2>/dev/null
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null

echo "13. Deploying Automated Maintenance (Trash & Tmp Cleaning)..."
# Create a cleanup script that removes files older than 30 days
CLEAN_SCRIPT="/usr/local/bin/ethereal-cleanup.sh"
cat << 'EOF' > "$CLEAN_SCRIPT"
#!/bin/bash
# EtherealOS Maintenance - Clean Trash and Tmp (>30 days)
# Identify the user's home
REAL_USER="abdallah"
REAL_HOME="/home/$REAL_USER"
find "$REAL_HOME/.local/share/Trash/files/"* -mtime +30 -exec rm -rf {} + 2>/dev/null
find /tmp -type f -atime +30 -delete 2>/dev/null
EOF
chmod +x "$CLEAN_SCRIPT"

# Add to crontab for the root user
(crontab -l 2>/dev/null | grep -v "$CLEAN_SCRIPT"; echo "0 0 * * 0 $CLEAN_SCRIPT") | crontab - 2>/dev/null || true

echo "14. Installing Office & PDF Suite (BTEC Ready)..."
# A. Okular (Premium PDF with Signing/Annotations)
if ! command -v okular >/dev/null 2>&1; then
    echo "   → Installing Okular (PDF Reader)..."
    emerge --ask=n --quiet kde-apps/okular 2>/dev/null || true
fi

# B. OnlyOffice (Microsoft Office Alternative via Flatpak)
if command -v flatpak >/dev/null 2>&1; then
    echo "   → Installing OnlyOffice Desktop Editors..."
    su - "$REAL_USER" -c "flatpak install --noninteractive flathub org.onlyoffice.desktopeditors" 2>/dev/null || true
fi

echo "15. Dynamic Swap Management (Swapspace)..."
if ! command -v swapspace >/dev/null 2>&1; then
    echo "   → Installing Dynamic Swap Manager (Swapspace)..."
    emerge --ask=n --quiet sys-apps/swapspace 2>/dev/null || true
fi
if command -v swapspace >/dev/null 2>&1; then
    echo "   → Enabling Dynamic Swap Service..."
    # Ensure the config exists and points to /var/lib/swapspace
    mkdir -p /var/lib/swapspace
    rc-update add swapspace default 2>/dev/null || true
    rc-service swapspace start 2>/dev/null || true
fi

echo "16. Optimizing System Core (Pro Gaming Kernel)..."
# Add XanMod/Liquorix logic (using Gentoo overlays or binary sources)
if ! uname -r | grep -qiE "xanmod|liquorix"; then
    echo "   → Note: High-Performance Kernel (XanMod/Liquorix) is recommended."
    echo "   → Instructions added to Ethereal-ToolKit.sh for kernel switching."
    # We add the command to the Toolkit for the user to trigger when ready
    echo "   # To upgrade to XanMod (Optimized for Gaming):" >> Ethereal-ToolKit.sh
    echo "   # sudo emerge --ask sys-kernel/xanmod-kernel-bin" >> Ethereal-ToolKit.sh
fi

echo "17. Optimizing Storage (Btrfs Zstd)..."
if [ -f "$(dirname "$0")/Ethereal-Optimize-Storage.sh" ]; then
    bash "$(dirname "$0")/Ethereal-Optimize-Storage.sh"
fi

echo "18. Enhancing System Stability (OOM Protection)..."
if [ -f "$(dirname "$0")/Ethereal-Stability-Fix.sh" ]; then
    bash "$(dirname "$0")/Ethereal-Stability-Fix.sh"
fi

echo "19. Securing System (Firewall Setup)..."
if [ -f "$(dirname "$0")/Ethereal-Security-Setup.sh" ]; then
    bash "$(dirname "$0")/Ethereal-Security-Setup.sh"
fi

echo "EtherealOS Final Polish Complete!"
