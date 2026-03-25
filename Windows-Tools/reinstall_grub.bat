@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"

echo === Mount partitions ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda2 /mnt/gentoo"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 1 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda1 /mnt/gentoo/boot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Bind mounts ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --types proc /proc /mnt/gentoo/proc"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Fix GRUB ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --removable"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 >nul

VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Reboot ===
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "umount -R /mnt/gentoo && reboot"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c

echo Done!
