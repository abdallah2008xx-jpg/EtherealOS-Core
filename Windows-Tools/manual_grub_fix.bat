@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo === Starting GRUB fix process ===
echo This will take several minutes...

echo.
echo Step 1: Starting VM from ISO...
%VBM% startvm %VM% --type gui

timeout /t 40 /nobreak >nul

echo.
echo Step 2: Booting ISO (pressing Enter)...
%VBM% controlvm %VM% keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo.
echo Step 3: Mounting partitions...
%VBM% controlvm %VM% keyboardputstring "mount /dev/sda2 /mnt/gentoo"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo.
echo Step 4: Checking EFI state...
%VBM% controlvm %VM% keyboardputstring "ls -laR /mnt/gentoo/boot/EFI/ 2>/dev/null | head -20"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo.
echo Step 5: Setting up chroot mounts...
%VBM% controlvm %VM% keyboardputstring "mount -t proc proc /mnt/gentoo/proc && mount -t sysfs sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo.
echo Step 6: Installing GRUB package...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge --ask=n sys-boot/grub"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 /nobreak >nul

echo.
echo Step 7: Installing GRUB to EFI...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --recheck --removable"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 15 /nobreak >nul

echo.
echo Step 8: Creating GRUB config...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 /nobreak >nul

echo.
echo Step 9: Creating fallback BOOT entry...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/BOOTX64.EFI"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo.
echo Step 10: Verifying installation...
%VBM% controlvm %VM% keyboardputstring "ls -la /mnt/gentoo/boot/EFI/abdallahOS/ && ls -la /mnt/gentoo/boot/grub/grub.cfg"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo.
echo Step 11: Unmounting and rebooting...
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo.
echo Step 12: Resetting boot order to hard disk...
%VBM% controlvm %VM% poweroff
timeout /t 3 /nobreak >nul
%VBM% modifyvm %VM% --boot1 disk --boot2 none
%VBM% startvm %VM% --type gui

echo.
echo === Done! GRUB should now be fixed ===
pause
