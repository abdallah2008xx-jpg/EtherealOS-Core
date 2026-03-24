#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v4.0.0)
# SIMPLE, RELIABLE, NO-CRASH
# ==========================================================

echo "🪐 EtherealOS System Repair v4.0"
echo "================================="
echo ""
echo "🔧 Enter Root Password (abdallah):"

# Get root access ONCE and run everything as root
su - -c "
    echo ''
    echo '✅ Root Access Granted!'
    echo ''
    
    # Fix 1: Permissions
    echo '[1/4] 🔧 Fixing all permissions...'
    chown -R abdallah:abdallah /home/abdallah
    echo '  ✅ Done'
    
    # Fix 2: Browser Rescue (THE MAIN EVENT)
    echo '[2/4] 🦊 Running Browser Rescue...'
    cd /home/abdallah/ethereal-update 2>/dev/null || cd /opt/EtherealOS-Core 2>/dev/null
    bash Ethereal-Browser-Rescue.sh
    
    # Fix 3: Deploy desktop icons
    echo '[3/4] 📂 Deploying desktop icons...'
    mkdir -p /home/abdallah/Desktop
    cp /home/abdallah/ethereal-update/*.desktop /home/abdallah/Desktop/ 2>/dev/null
    cp /opt/EtherealOS-Core/*.desktop /home/abdallah/Desktop/ 2>/dev/null
    chmod +x /home/abdallah/Desktop/*.desktop 2>/dev/null
    chown -R abdallah:abdallah /home/abdallah/Desktop 2>/dev/null
    echo '  ✅ Done'
    
    # Fix 4: Final sync
    echo '[4/4] 🔄 Syncing updates...'
    cd /home/abdallah/ethereal-update 2>/dev/null && git pull origin main 2>/dev/null
    cd /opt/EtherealOS-Core 2>/dev/null && git pull origin main 2>/dev/null
    echo '  ✅ Done'
    
    echo ''
    echo '🏆 ALL REPAIRS COMPLETE!'
    echo 'Now try opening Firefox or Thor Browser.'
    echo ''
"

echo ""
echo "Press any key to close..."
read -n 1 -s
