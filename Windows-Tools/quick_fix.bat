@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo Waiting for ISO to boot...
timeout /t 35 /nobreak >nul

echo Pressing Enter...
%VBM% controlvm %VM% keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo Mounting root...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo && mount /dev/sda2 /mnt/gentoo"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Mounting boot...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo CRITICAL: Copying GRUB to fallback location EFI/BOOT/bootx64.efi
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 1 /nobreak >nul

%VBM% controlvm %VM% keyboardputstring "cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/bootx64.efi"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 1 /nobreak >nul

echo Verifying...
%VBM% controlvm %VM% keyboardputstring "ls -la /mnt/gentoo/boot/EFI/BOOT/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Unmounting and rebooting...
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo Resetting boot to hard disk...
%VBM% controlvm %VM% poweroff
timeout /t 3 /nobreak >nul
%VBM% modifyvm %VM% --boot1 disk --boot2 none
%VBM% startvm %VM% --type gui

echo DONE! VM restarted.
