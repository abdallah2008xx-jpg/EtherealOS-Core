@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "lsblk"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/test && mount /dev/sda1 /mnt/test && ls -la /mnt/test/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
