#!/bin/bash

# Auto-start Hyprland disabled in favor of SDDM session management.
# This prevents infinite login loops and ensures proper environment detection.
# Detection logic is now centralized in /usr/local/bin/hyprland-sw.sh

if [ "$(tty)" = "/dev/tty1" ]; then
    echo -e "\033[0;32m========================================================\033[0m"
    echo -e "       Welcome to \033[1;36mStunning OS\033[0m Rescue Shell"
    echo -e "\033[0;32m========================================================\033[0m"
    echo ""
    echo "The graphical environment is managed by SDDM."
    echo "Login via the GUI to start your session."
    echo ""
    echo "Troubleshooting:"
    echo " - Check /tmp/hyprland-sw.log if the GUI fails."
    echo " - To test manually, run: /usr/local/bin/hyprland-sw.sh"
    echo ""
    echo -e "\033[0;32m--------------------------------------------------------\033[0m"
fi
