#!/bin/bash
# hyprland-sw.sh — Stunning OS Environment-Aware Launcher
# Part of the Black Screen Fix Architecture (Epic: a7caa323)

LOG_FILE="/tmp/hyprland-sw.log"
GPU_TYPE="unknown"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "[${BLUE}${timestamp}${NC}] $*" | tee -a "$LOG_FILE"
}

diagnostic_error() {
    clear
    echo -e "${RED}========================================================${NC}"
    echo -e "${RED}         STUNNING OS — CRITICAL LAUNCH ERROR            ${NC}"
    echo -e "${RED}========================================================${NC}"
    echo ""
    echo -e "Hyprland failed to initialize the graphical session."
    echo -e "Detected VGA: ${YELLOW}${VGA:-Unknown}${NC}"
    echo -e "Virtualization: ${YELLOW}${VIRT:-None}${NC}"
    echo ""
    echo -e "Troubleshooting Steps:"
    echo -e " 1. Check ${BLUE}${LOG_FILE}${NC} for specific error messages."
    echo -e " 2. If on a VM, try disabling/enabling 3D acceleration."
    echo -e " 3. Verify kernel parameters (e.g., nvidia-drm.modeset=1)."
    echo ""
    echo -e "Entering ${GREEN}Rescue Shell${NC}. Type 'exit' to return to SDDM login."
    echo -e "${RED}--------------------------------------------------------${NC}"
    /bin/bash
}

log "=== Stunning OS Environment Detection ==="

# 1. Virtualization Detection
VIRT=$(systemd-detect-virt)
if [ "$VIRT" != "none" ]; then
    log "Virtual environment detected: ${YELLOW}$VIRT${NC}. Forcing software rendering."
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    export LIBGL_ALWAYS_SOFTWARE=1
    export WLR_NO_HARDWARE_CURSORS=1
    export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
else
    log "Running on bare metal. Detecting GPU..."
    
    # 2. Hardware Detection using lspci
    if command -v lspci &>/dev/null; then
        VGA=$(lspci | grep -i 'VGA\|3D\|Display')
        log "LSPCI VGA Identification: ${BLUE}$VGA${NC}"
        
        if echo "$VGA" | grep -qi "nvidia"; then
            log "NVIDIA GPU detected. Setting optimized hardware variables."
            export WLR_NO_HARDWARE_CURSORS=1
            export LIBVA_DRIVER_NAME=nvidia
            export GBM_BACKEND=nvidia-drm
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
        elif echo "$VGA" | grep -qi "intel"; then
            log "Intel GPU detected. Using modern 'iris' MESA driver."
            export MESA_LOADER_DRIVER_OVERRIDE=iris
        elif echo "$VGA" | grep -qi "amd\|ati"; then
            log "AMD/ATI GPU detected. Initializing Hardware Path."
            GPU_TYPE="amd"
        else
            log "${YELLOW}Unknown GPU or detection failed.${NC} Falling back to software rendering."
            export WLR_RENDERER_ALLOW_SOFTWARE=1
            export LIBGL_ALWAYS_SOFTWARE=1
            export WLR_NO_HARDWARE_CURSORS=1
            export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
        fi
    else
        log "${RED}lspci not found.${NC} Falling back to software rendering."
        export WLR_RENDERER_ALLOW_SOFTWARE=1
        export LIBGL_ALWAYS_SOFTWARE=1
        export WLR_NO_HARDWARE_CURSORS=1
        export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
    fi
fi

# 3. Launch Hyprland
log "Attempting to launch Hyprland..."
Hyprland >> "$LOG_FILE" 2>&1
RET=$?

# 4. Fallback/Error Handling
if [ $RET -ne 0 ]; then
    log "Hyprland exited with code $RET."
    
    # AMD Hardware Fallback
    if [ "$GPU_TYPE" = "amd" ]; then
        log "${YELLOW}AMD hardware rendering failed.${NC} Retrying with software fallback..."
        export WLR_RENDERER_ALLOW_SOFTWARE=1
        export LIBGL_ALWAYS_SOFTWARE=1
        export WLR_NO_HARDWARE_CURSORS=1
        export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
        Hyprland >> "$LOG_FILE" 2>&1
        RET=$?
    fi
    
    if [ $RET -ne 0 ]; then
        diagnostic_error
    fi
fi

