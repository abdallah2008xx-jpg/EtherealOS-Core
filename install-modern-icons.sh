#!/bin/bash
# ==========================================================
# Install Modern Icon Theme (Windows 11 Style)
# ==========================================================

set -e

echo "🎨 Installing Modern Icon Theme..."

# Create directories
mkdir -p ~/.icons
mkdir -p ~/.local/share/icons

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "⬇️ Downloading Colloid Icon Theme (Modern Windows 11 style)..."

# Try to download Colloid icon theme (modern Windows 11 style)
RELEASE_URL="https://github.com/vinceliuice/Colloid-icon-theme/releases/download/2024-01-01/01.Colloid-icon-theme-2024-01-01.tar.xz"

wget -q --timeout=60 "$RELEASE_URL" -O colloid.tar.xz 2>/dev/null || \
curl -sL --max-time 60 "$RELEASE_URL" -o colloid.tar.xz 2>/dev/null || {
    echo "⚠️ Download failed, trying alternative method..."
}

if [ -f colloid.tar.xz ]; then
    echo "📦 Extracting Colloid icons..."
    tar -xf colloid.tar.xz
    
    # Install Colloid-Dark (most modern look)
    if [ -d "Colloid-Dark" ]; then
        echo "🚀 Installing Colloid-Dark icons..."
        cp -r Colloid-Dark ~/.icons/
        cp -r Colloid-Dark ~/.local/share/icons/
    fi
    
    # Also install regular Colloid
    if [ -d "Colloid" ]; then
        cp -r Colloid ~/.icons/
        cp -r Colloid ~/.local/share/icons/
    fi
fi

# Try to download Fluent icon theme (Windows 11 official style)
echo "⬇️ Trying Fluent Icon Theme..."
FLUENT_URL="https://github.com/vinceliuice/Fluent-icon-theme/releases/download/2024-02-01/Fluent-icon-theme-2024-02-01.tar.xz"

wget -q --timeout=60 "$FLUENT_URL" -O fluent.tar.xz 2>/dev/null || \
curl -sL --max-time 60 "$FLUENT_URL" -o fluent.tar.xz 2>/dev/null || true

if [ -f fluent.tar.xz ]; then
    echo "📦 Extracting Fluent icons..."
    tar -xf fluent.tar.xz
    
    if [ -d "Fluent" ]; then
        echo "🚀 Installing Fluent icons..."
        cp -r Fluent ~/.icons/
        cp -r Fluent ~/.local/share/icons/
    fi
    
    if [ -d "Fluent-dark" ]; then
        cp -r Fluent-dark ~/.icons/
        cp -r Fluent-dark ~/.local/share/icons/
    fi
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Update icon cache for all installed themes
echo "🔄 Updating icon cache..."
for theme_dir in ~/.icons/* ~/.local/share/icons/*; do
    if [ -d "$theme_dir" ]; then
        gtk-update-icon-cache -f "$theme_dir" 2>/dev/null || true
    fi
done

echo "✅ Modern Icon Themes installed!"
echo ""
echo "Available themes: Colloid, Colloid-Dark, Fluent, Fluent-dark"
echo "To apply: Settings → Themes → Icons"
