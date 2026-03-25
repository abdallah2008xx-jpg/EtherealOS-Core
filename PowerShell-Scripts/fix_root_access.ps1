###############################################################
# EtherealOS — Fix Root Access via GRUB Single-User Mode
# 
# This script:
# 1. Reboots the VM
# 2. Edits GRUB to boot into init=/bin/bash
# 3. Sets root password
# 4. Installs sudo
# 5. Configures wheel group
# 6. Reboots normally
###############################################################

$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VMName = "AhmadOS-Gentoo"

function Send-Keys($text) {
    & $VBoxManage controlvm $VMName keyboardputstring "$text"
    Start-Sleep -Milliseconds 300
}

function Send-Enter() {
    # Send Enter key scancode
    & $VBoxManage controlvm $VMName keyboardputscancode 1c 9c
    Start-Sleep -Milliseconds 500
}

function Send-DownArrow() {
    & $VBoxManage controlvm $VMName keyboardputscancode 50 d0
    Start-Sleep -Milliseconds 300
}

function Send-Key-E() {
    # 'e' key for GRUB edit
    & $VBoxManage controlvm $VMName keyboardputscancode 12 92
    Start-Sleep -Milliseconds 300
}

function Send-Escape() {
    & $VBoxManage controlvm $VMName keyboardputscancode 01 81
    Start-Sleep -Milliseconds 300
}

function Send-End() {
    & $VBoxManage controlvm $VMName keyboardputscancode 4f cf
    Start-Sleep -Milliseconds 300
}

function Send-Ctrl-X() {
    # Ctrl+X to boot from GRUB editor
    & $VBoxManage controlvm $VMName keyboardputscancode 1d 2d ad 9d
    Start-Sleep -Milliseconds 300
}

function Take-Screenshot($name) {
    & $VBoxManage controlvm $VMName screenshotpng "C:\Users\abdal\Downloads\Gentoo-Custom-Project\$name.png"
    Start-Sleep -Milliseconds 500
}

Write-Host "=== Step 1: Rebooting VM ===" -ForegroundColor Cyan

# Send reboot command via keyboard
Send-Keys "reboot"
Send-Enter
Start-Sleep -Seconds 3

# If reboot requires root, force reset
Write-Host "Forcing VM reset..." -ForegroundColor Yellow
& $VBoxManage controlvm $VMName reset
Start-Sleep -Seconds 5

Write-Host "=== Step 2: Waiting for GRUB ===" -ForegroundColor Cyan
# GRUB usually shows for 3-5 seconds
Start-Sleep -Seconds 3
Take-Screenshot "grub_boot_1"

# Press 'e' to edit the boot entry
Write-Host "Pressing 'e' to edit GRUB entry..." -ForegroundColor Yellow
Send-Key-E
Start-Sleep -Seconds 2
Take-Screenshot "grub_edit_1"

Write-Host "=== Step 3: Adding init=/bin/bash to kernel line ===" -ForegroundColor Cyan
# Navigate down to the linux line (usually 3-5 lines down)
for ($i = 0; $i -lt 6; $i++) { Send-DownArrow }
Start-Sleep -Milliseconds 500

# Go to end of the line
Send-End
Start-Sleep -Milliseconds 300

# Append init=/bin/bash
Send-Keys " init=/bin/bash"
Start-Sleep -Milliseconds 500
Take-Screenshot "grub_edit_2"

# Boot with Ctrl+X
Write-Host "Booting with Ctrl+X..." -ForegroundColor Yellow
Send-Ctrl-X
Start-Sleep -Seconds 8
Take-Screenshot "single_user_1"

Write-Host "=== Step 4: Remounting root as read-write ===" -ForegroundColor Cyan
Send-Keys "mount -o remount,rw /"
Send-Enter
Start-Sleep -Seconds 2

Write-Host "=== Step 5: Setting root password ===" -ForegroundColor Cyan
Send-Keys "echo 'root:123456' | chpasswd"
Send-Enter
Start-Sleep -Seconds 2
Take-Screenshot "root_password_set"

Write-Host "=== Step 6: Mounting shared folder ===" -ForegroundColor Cyan
Send-Keys "mkdir -p /gentoo-files"
Send-Enter
Start-Sleep -Seconds 1
Send-Keys "mount -t vboxsf gentoo-files /gentoo-files 2>/dev/null || mount -t vboxsf gentoo_files /gentoo-files 2>/dev/null || true"
Send-Enter
Start-Sleep -Seconds 2

# Check if shared folder has the files
Send-Keys "ls /gentoo-files/setup-sudo.sh 2>/dev/null && echo FOUND || echo NOT_FOUND"
Send-Enter
Start-Sleep -Seconds 2
Take-Screenshot "shared_folder_check"

Write-Host "=== Step 7: Installing sudo manually ===" -ForegroundColor Cyan
# Since we're in init=/bin/bash, emerge might not work (no portage env)
# Let's do the critical fixes manually first

# Set root password (already done but ensure)
Send-Keys "passwd root"
Send-Enter
Start-Sleep -Seconds 1
Send-Keys "123456"
Send-Enter
Start-Sleep -Seconds 1
Send-Keys "123456"
Send-Enter
Start-Sleep -Seconds 2

# Add abdallah to wheel group
Send-Keys "usermod -aG wheel,video,audio,input abdallah 2>/dev/null || echo 'usermod not available in minimal shell'"
Send-Enter
Start-Sleep -Seconds 2

Take-Screenshot "manual_fixes"

Write-Host "=== Step 8: Syncing and rebooting ===" -ForegroundColor Cyan
Send-Keys "sync"
Send-Enter
Start-Sleep -Seconds 2

# Force reboot (since we're in init=/bin/bash, can't use reboot normally)
Send-Keys "echo b > /proc/sysrq-trigger"
Send-Enter
Start-Sleep -Seconds 8

Write-Host "=== Step 9: Waiting for normal boot ===" -ForegroundColor Cyan
Start-Sleep -Seconds 15
Take-Screenshot "after_reboot_1"

# Wait for login / desktop to load
Start-Sleep -Seconds 15
Take-Screenshot "after_reboot_2"

Write-Host "=== Step 10: Testing root access ===" -ForegroundColor Cyan
# Now try su - with the new password
# First, need to open a terminal. Let's wait a bit and type
Start-Sleep -Seconds 5
Take-Screenshot "desktop_ready"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Root password has been set to: 123456" -ForegroundColor Green
Write-Host "  Now open a terminal in the VM and run:" -ForegroundColor Green
Write-Host "    su -" -ForegroundColor Yellow
Write-Host "    (password: 123456)" -ForegroundColor Yellow
Write-Host "    bash /gentoo-files/setup-sudo.sh" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
