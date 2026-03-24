#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate Browser Fixer (v3.0.0)
# SIMPLE & RELIABLE - No fancy UI, just fixes
# ==========================================================

echo "🦊 Browser Fix Engine v3.0..."

# We just call the main rescue script as root
# If already root, run directly. If not, use su.
if [ "$(id -u)" -eq 0 ]; then
    bash "$(dirname "$0")/Ethereal-Browser-Rescue.sh"
else
    echo "Elevating to root..."
    su -c "bash $(pwd)/Ethereal-Browser-Rescue.sh"
fi
