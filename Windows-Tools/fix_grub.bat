@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"

:: Wait for ISO to boot
timeout /t 10 /nobreak >nul

:: Press Enter to select default boot option
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

:: Type commands to fix GRUB
echo Sending: mkdir -p /mnt/gentoo
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: mount /dev/sda2 /mnt/gentoo
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda2 /mnt/gentoo"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: mkdir -p /mnt/gentoo/boot
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 1 /nobreak >nul

echo Sending: mount /dev/sda1 /mnt/gentoo/boot
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda1 /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: mount --types proc /proc /mnt/gentoo/proc
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --types proc /proc /mnt/gentoo/proc"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: mount --rbind /sys /mnt/gentoo/sys
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --rbind /sys /mnt/gentoo/sys"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: mount --rbind /dev /mnt/gentoo/dev
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --rbind /dev /mnt/gentoo/dev"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Sending: chroot and reinstall GRUB
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo /bin/bash -c 'source /etc/profile && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --removable'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 /nobreak >nul

echo Sending: grub-mkconfig
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo /bin/bash -c 'source /etc/profile && grub-mkconfig -o /boot/grub/grub.cfg'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 /nobreak >nul

echo Sending: unmount and reboot
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "umount -R /mnt/gentoo && reboot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

echo Commands sent! Waiting for reboot...
timeout /t 30 /nobreak >nul

:: Reset boot order back to hard disk
VBoxManage.exe controlvm AhmadOS-Gentoo poweroff
timeout /t 3 /nobreak >nul
VBoxManage.exe modifyvm AhmadOS-Gentoo --boot1 disk --boot2 none
VBoxManage.exe storageattach AhmadOS-Gentoo --storagectl SATA --port 1 --device 0 --type dvddrive --medium none
VBoxManage.exe startvm AhmadOS-Gentoo --type gui

echo GRUB Fixed! VM restarted.
