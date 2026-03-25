@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"

echo Mounting shared folder...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "modprobe vboxsf"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/shared"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 1 /nobreak >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount -t vboxsf gentoo-files /mnt/shared"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Listing files...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls /mnt/shared/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Copying install script...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "cp /mnt/shared/auto_install.sh /tmp/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 1 /nobreak >nul

echo Running install...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chmod +x /tmp/auto_install.sh && bash /tmp/auto_install.sh"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

echo Done! Installation started.
