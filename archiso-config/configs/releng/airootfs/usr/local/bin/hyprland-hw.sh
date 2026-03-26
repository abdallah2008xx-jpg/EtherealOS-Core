#!/bin/bash
# hyprland-hw.sh — Stunning OS Hardware-Forced Launcher
# Part of the Black Screen Fix Architecture (Epic: a7caa323)

LOG_FILE="/tmp/hyprland-hw.log"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "[${GREEN}${timestamp}${NC}] $*" | tee -a "$LOG_FILE"
}

diagnostic_error() {
    clear
    echo -e "${RED}========================================================${NC}"
    echo -e "${RED}       STUNNING OS — HARDWARE LAUNCH FAILURE            ${NC}"
    echo -e "${RED}========================================================${NC}"
    echo ""
    echo -e "Hardware-forced Hyprland session failed to start."
    echo -e "Detected VGA: ${YELLOW}${VGA:-Unknown}${NC}"
    echo ""
    echo -e "Recommendation:"
    echo -e " 1. Use ${BLUE}Stunning OS (Auto-Detect)${NC} at login for fallback."
    echo -e " 2. Ensure proprietary drivers (NVIDIA) are loaded."
    echo ""
    echo -e "Entering ${GREEN}Rescue Shell${NC}. Type 'exit' to return to SDDM."
    echo -e "${RED}--------------------------------------------------------${NC}"
    /bin/bash
}

log "=== Stunning OS Hardware Forced Mode ==="

if command -v lspci &>/dev/null; then
    VGA=$(lspci | grep -i 'VGA\|3D\|Display')
    log "LSPCI VGA Identification: ${BLUE}$VGA${NC}"

    if echo "$VGA" | grep -qi "nvidia"; then
        log "NVIDIA detected. Setting hardware env vars."
        export WLR_NO_HARDWARE_CURSORS=1
        export LIBVA_DRIVER_NAME=nvidia
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
    elif echo "$VGA" | grep -qi "intel"; then
        log "Intel detected. Using 'iris' driver."
        export MESA_LOADER_DRIVER_OVERRIDE=iris
    else
        log "Assuming standard hardware drivers for: ${YELLOW}$VGA${NC}"
    fi
else
    log "${YELLOW}lspci not found.${NC} Continuing with default hardware settings."
fi

log "Launching Hyprland..."
Hyprland >> "$LOG_FILE" 2>&1 || diagnostic_error
