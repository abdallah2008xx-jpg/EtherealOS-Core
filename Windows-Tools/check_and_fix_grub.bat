@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
timeout /t 30 /nobreak >nul

echo === Check EFI partition ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo /mnt/boot && mount /dev/sda2 /mnt/gentoo && mount /dev/sda1 /mnt/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Check if GRUB files exist ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/boot/EFI/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/boot/EFI/abdallahOS/ 2>/dev/null || echo 'abdallahOS folder not found'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/boot/EFI/boot/ 2>/dev/null || echo 'boot folder not found'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Check grub.cfg ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/boot/grub/grub.cfg 2>/dev/null || echo 'grub.cfg not found'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Fix GRUB properly ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --types proc /proc /mnt/gentoo/proc && mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys && mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Reinstall GRUB with force ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --removable --force"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 15 >nul

echo === Create grub.cfg ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Verify installation ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls -la /mnt/boot/EFI/abdallahOS/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Copy to fallback location ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/boot/EFI/boot && cp /mnt/boot/EFI/abdallahOS/grubx64.efi /mnt/boot/EFI/boot/bootx64.efi 2>/dev/null || cp /mnt/boot/EFI/gentoo/grubx64.efi /mnt/boot/EFI/boot/bootx64.efi 2>/dev/null || echo 'Copy attempted'"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Reboot ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "umount -R /mnt/gentoo /mnt/boot 2>/dev/null; reboot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

echo Done! VM should reboot soon.
