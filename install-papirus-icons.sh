#!/bin/bash
# ==========================================================
# Install Papirus Icon Theme - Complete Icon Pack
# ==========================================================

set -e

echo "🎨 Installing Papirus Icon Theme..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download latest Papirus icon theme
echo "⬇️ Downloading Papirus icons..."
wget -q https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/releases/download/20240201/Papirus-icon-theme-20240201.tar.gz -O papirus.tar.gz

# Extract
echo "📦 Extracting..."
tar -xzf papirus.tar.gz

# Install to user directory
echo "🚀 Installing to ~/.icons..."
mkdir -p ~/.icons
cp -r Papirus* ~/.icons/ 2>/dev/null || true

# Also install to system if possible
if [ -d /usr/share/icons ]; then
    echo "🔧 Installing system-wide (requires sudo)..."
    sudo cp -r Papirus* /usr/share/icons/ 2>/dev/null || echo "Skipping system install (no sudo)"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo "✅ Papirus Icon Theme installed!"
echo ""
echo "Available themes: Papirus, Papirus-Dark, Papirus-Light"
echo "To apply: Right-click desktop → Change Desktop Background → Icons"
