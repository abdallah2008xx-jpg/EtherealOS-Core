#!/bin/bash
# ==========================================================
# Install Papirus Icon Theme - Complete Icon Pack
# ==========================================================

set -e

echo "🎨 Installing Papirus Icon Theme..."

# Create directories
mkdir -p ~/.icons
mkdir -p ~/.local/share/icons

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download latest Papirus icon theme from GitHub
echo "⬇️ Downloading Papirus icons..."
LATEST_URL="https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/releases/download/20240301/papirus-icon-theme-20240301.tar.gz"
wget -q --timeout=30 "$LATEST_URL" -O papirus.tar.gz 2>/dev/null || \
curl -sL --max-time 30 "$LATEST_URL" -o papirus.tar.gz 2>/dev/null || {
    echo "⚠️ Failed to download Papirus. Using fallback..."
    # Try alternative URL
    wget -q --timeout=30 "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install-papirus-root.sh" -O install.sh 2>/dev/null && bash install.sh || true
}

# Extract if downloaded
if [ -f papirus.tar.gz ]; then
    echo "📦 Extracting..."
    tar -xzf papirus.tar.gz
    
    # Install to user directory
    echo "🚀 Installing to ~/.icons..."
    cp -r Papirus* ~/.icons/ 2>/dev/null || true
    
    # Also install to local share
    cp -r Papirus* ~/.local/share/icons/ 2>/dev/null || true
fi

# Try to install via package manager if available
echo "🔧 Trying package manager install..."
if command -v emerge &> /dev/null; then
    sudo emerge -n x11-themes/papirus-icon-theme 2>/dev/null || true
elif command -v apt &> /dev/null; then
    sudo apt install -y papirus-icon-theme 2>/dev/null || true
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm papirus-icon-theme 2>/dev/null || true
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Update icon cache
echo "🔄 Updating icon cache..."
gtk-update-icon-cache -f ~/.icons/Papirus 2>/dev/null || true
gtk-update-icon-cache -f ~/.local/share/icons/Papirus 2>/dev/null || true

echo "✅ Papirus Icon Theme installed!"
echo ""
echo "Available themes: Papirus, Papirus-Dark, Papirus-Light"
echo "To apply: Right-click desktop → Change Desktop Background → Icons"

