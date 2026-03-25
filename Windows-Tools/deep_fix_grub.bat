@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
timeout /t 30 /nobreak >nul

echo === Mount and check ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda2 /mnt/gentoo && mount /dev/sda1 /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Check EFI structure ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "find /mnt/gentoo/boot -name '*.efi' -type f 2>/dev/null"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Check grub files ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/gentoo/boot/grub/ 2>/dev/null || echo 'No grub dir'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Check if grub-install exists ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo which grub-install"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Check EFI vars ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls /sys/firmware/efi/efivars/ 2>/dev/null | head -5 || echo 'No EFI vars'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Full reinstall ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount -t proc none /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Install GRUB package if missing ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub 2>&1 | tail -5"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 30 >nul

echo === Reinstall GRUB to EFI ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable --no-nvram"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 15 >nul

echo === Create grub config ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Verify ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/gentoo/boot/EFI/abdallahOS/ 2>/dev/null && ls -la /mnt/gentoo/boot/EFI/boot/ 2>/dev/null"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Reboot ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "umount -R /mnt/gentoo; reboot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

echo Done!
