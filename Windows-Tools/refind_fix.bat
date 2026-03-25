@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo === Using rEFInd as bootloader ===

echo Step 1: Start VM from ISO...
%VBM% startvm %VM% --type gui
timeout /t 40 /nobreak >nul

echo Step 2: Boot ISO...
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo Step 3: Mount partitions...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo && mount /dev/sda2 /mnt/gentoo && mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo Step 4: Setup chroot...
%VBM% controlvm %VM% keyboardputstring "mount -t proc proc /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 /nobreak >nul

echo Step 5: Download rEFInd...
%VBM% controlvm %VM% keyboardputstring "cd /mnt/gentoo/boot && wget -O refind-cd.zip https://sourceforge.net/projects/refind/files/latest/download"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo Step 6: Extract and install rEFInd...
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge -n app-arch/unzip && unzip refind-cd.zip && mkdir -p EFI/BOOT && cp refind*/refind_x64.efi EFI/BOOT/bootx64.efi"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 20 /nobreak >nul

echo Step 7: Create rEFInd config...
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/refind && cp /mnt/gentoo/boot/refind*/refind_x64.efi /mnt/gentoo/boot/EFI/refind/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 /nobreak >nul

echo Step 8: Reboot...
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 30 /nobreak >nul

echo Step 9: Boot from hard disk...
%VBM% controlvm %VM% poweroff
timeout /t 3 /nobreak >nul
%VBM% modifyvm %VM% --boot1 disk --boot2 none
%VBM% startvm %VM% --type gui

echo Done!
