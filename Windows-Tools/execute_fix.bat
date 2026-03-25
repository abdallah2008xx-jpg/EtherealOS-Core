@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
setlocal EnableDelayedExpansion

echo === Booting ISO to fix GRUB ===
timeout /t 35 /nobreak >nul

echo Sending Enter...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo Sending commands from shared folder...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo && mount /dev/sda2 /mnt/gentoo && mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo Mounting virtual filesystems...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount -t proc none /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo Installing GRUB...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 60 /nobreak >nul

echo Installing GRUB to EFI...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 15 /nobreak >nul

echo Creating GRUB config...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 /nobreak >nul

echo Creating fallback boot...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/BOOTX64.EFI"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo Rebooting...
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "umount -R /mnt/gentoo && reboot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo === Resetting boot order ===
VBoxManage.exe controlvm AhmadOS-Gentoo poweroff
timeout /t 3 /nobreak >nul
VBoxManage.exe modifyvm AhmadOS-Gentoo --boot1 disk --boot2 none
VBoxManage.exe startvm AhmadOS-Gentoo --type gui

echo === Done! ===
