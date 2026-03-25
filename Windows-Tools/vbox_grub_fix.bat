@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo === STEP 1: Power off VM ===
%VBM% controlvm %VM% poweroff 2>nul
timeout /t 2 /nobreak >nul

echo === STEP 2: Set boot from DVD ===
%VBM% modifyvm %VM% --boot1 dvd --boot2 disk

echo === STEP 3: Start VM ===
%VBM% startvm %VM% --type gui

timeout /t 40 /nobreak >nul

echo === STEP 4: Boot ISO ===
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo === STEP 5: Mount partitions ===
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo && mount /dev/sda2 /mnt/gentoo && mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo === STEP 6: Setup chroot mounts ===
%VBM% controlvm %VM% keyboardputstring "mount -t proc proc /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo === STEP 7: Install GRUB if missing ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub 2>&1 | tail -3"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 /nobreak >nul

echo === STEP 8: Install GRUB to EFI with force ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --recheck --removable"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 15 /nobreak >nul

echo === STEP 9: Create GRUB config ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 /nobreak >nul

echo === STEP 10: CRITICAL - Copy to fallback BOOT location ===
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/bootx64.efi"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo === STEP 11: Create startup.nsh for UEFI shell fallback ===
%VBM% controlvm %VM% keyboardputstring "echo '\\EFI\\BOOT\\bootx64.efi' > /mnt/gentoo/boot/startup.nsh"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo === STEP 12: Verify installation ===
%VBM% controlvm %VM% keyboardputstring "ls -la /mnt/gentoo/boot/EFI/BOOT/ && ls -la /mnt/gentoo/boot/EFI/abdallahOS/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo === STEP 13: Reboot ===
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c

timeout /t 30 /nobreak >nul

echo === STEP 14: Switch to hard disk boot ===
%VBM% controlvm %VM% poweroff
timeout /t 3 /nobreak >nul
%VBM% modifyvm %VM% --boot1 disk --boot2 none
%VBM% startvm %VM% --type gui

echo === DONE! GRUB should now boot from fallback location ===
