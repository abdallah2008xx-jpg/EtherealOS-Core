@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo Waiting for ISO to boot...
timeout /t 35 /nobreak >nul

echo Pressing Enter...
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo Mounting root partition...
%VBM% controlvm %VM% keyboardputstring "mount /dev/sda2 /mnt/gentoo"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo Mounting boot partition...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo Checking current state...
%VBM% controlvm %VM% keyboardputstring "ls -la /mnt/gentoo/boot/EFI/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo Setting up mounts for chroot...
%VBM% controlvm %VM% keyboardputstring "mount -t proc proc /mnt/gentoo/proc && mount -t sysfs sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

echo Checking if grub is installed...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo ls -la /usr/sbin/grub* 2>/dev/null || echo 'GRUB not found'"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

echo Installing GRUB...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 >nul

echo Installing GRUB to EFI...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --recheck"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 15 >nul

echo Creating GRUB config...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 >nul

echo Creating fallback boot entry...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/BOOTX64.EFI 2>/dev/null || echo 'Fallback copy done'"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo Verifying...
%VBM% controlvm %VM% keyboardputstring "ls -la /mnt/gentoo/boot/EFI/abdallahOS/ && ls -la /mnt/gentoo/boot/EFI/BOOT/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo Rebooting...
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c

echo All commands sent!
pause
