@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe
set VM=AhmadOS-Gentoo

echo === Creating root partition ===
%VBM% controlvm %VM% keyboardputstring "parted -s /dev/sda mkpart primary ext4 513MiB 100%"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Format root ===
%VBM% controlvm %VM% keyboardputstring "mkfs.ext4 -F /dev/sda2"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 5 >nul

echo === Mount ===
%VBM% controlvm %VM% keyboardputstring "mount /dev/sda2 /mnt/gentoo && mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Download Stage3 ===
%VBM% controlvm %VM% keyboardputstring "wget -O /mnt/gentoo/stage3.tar.xz https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20250316T093102Z/stage3-amd64-openrc-20250316T093102Z.tar.xz 2>&1 | tail -5"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 180 >nul

echo === Extract Stage3 ===
%VBM% controlvm %VM% keyboardputstring "cd /mnt/gentoo && tar xpf stage3.tar.xz --xattrs-include='*.*' --numeric-owner && rm stage3.tar.xz"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 120 >nul

echo === Prepare chroot ===
%VBM% controlvm %VM% keyboardputstring "cp -L /etc/resolv.conf /mnt/gentoo/etc/ && mount -t proc proc /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Install GRUB ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub 2>&1 | tail -3"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 >nul

echo === Install to EFI ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable 2>&1 | tail -3"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Create GRUB config ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -3"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Create fallback ===
%VBM% controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/bootx64.efi 2>/dev/null; ls /mnt/gentoo/boot/EFI/BOOT/"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Configure hostname ===
%VBM% controlvm %VM% keyboardputstring "echo 'abdallahOS' > /mnt/gentoo/etc/hostname"
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 1 >nul

echo === Set root password ===
%VBM% controlvm %VM% keyboardputstring "chroot /mnt/gentoo /bin/bash -c \"echo 'root:123456' | chpasswd\""
%VBM% controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Reboot ===
%VBM% controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
%VBM% controlvm %VM% keyboardputscancode 1c 9c

echo === Waiting for reboot ===
timeout /t 30 >nul

%VBM% controlvm %VM% poweroff 2>nul
timeout /t 3 >nul
%VBM% modifyvm %VM% --boot1 disk --boot2 none
echo === Starting from hard disk ===
%VBM% startvm %VM% --type gui

echo === DONE ===
