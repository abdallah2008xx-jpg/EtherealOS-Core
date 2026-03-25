@echo off
set VBM=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe
set VM=AhmadOS-Gentoo

echo === Step 1: Partition ===
"%VBM%" controlvm %VM% keyboardputstring "parted -s /dev/sda mklabel gpt"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "parted -s /dev/sda mkpart primary fat32 1MiB 513MiB"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "parted -s /dev/sda set 1 esp on"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "parted -s /dev/sda mkpart primary ext4 513MiB 100%"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Step 2: Format ===
"%VBM%" controlvm %VM% keyboardputstring "mkfs.fat -F32 /dev/sda1"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

"%VBM%" controlvm %VM% keyboardputstring "mkfs.btrfs -f /dev/sda2"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 3 >nul

echo === Step 3: Mount (Btrfs Subvolumes) ===
"%VBM%" controlvm %VM% keyboardputstring "mount /dev/sda2 /mnt"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "btrfs subvolume create /mnt/@ && btrfs subvolume create /mnt/@home"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "umount /mnt && mount -o subvol=@ /dev/sda2 /mnt/gentoo"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/home && mount -o subvol=@home /dev/sda2 /mnt/gentoo/home"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

"%VBM%" controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Step 4: Download Stage3 ===
"%VBM%" controlvm %VM% keyboardputstring "wget -O /tmp/stage3.tar.xz https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20250316T093102Z/stage3-amd64-openrc-20250316T093102Z.tar.xz"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 120 >nul

echo === Step 5: Extract ===
"%VBM%" controlvm %VM% keyboardputstring "tar xpf /tmp/stage3.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 >nul

echo === Step 6: Prepare chroot ===
"%VBM%" controlvm %VM% keyboardputstring "cp -L /etc/resolv.conf /mnt/gentoo/etc/"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 1 >nul

"%VBM%" controlvm %VM% keyboardputstring "mount -t proc proc /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Step 7: Install GRUB ===
"%VBM%" controlvm %VM% keyboardputstring "chroot /mnt/gentoo emerge -n sys-boot/grub"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 60 >nul

"%VBM%" controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 15 >nul

"%VBM%" controlvm %VM% keyboardputstring "chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 10 >nul

echo === Step 8: Create fallback ===
"%VBM%" controlvm %VM% keyboardputstring "mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/bootx64.efi"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c
timeout /t 2 >nul

echo === Step 9: Reboot ===
"%VBM%" controlvm %VM% keyboardputstring "umount -R /mnt/gentoo && reboot"
"%VBM%" controlvm %VM% keyboardputscancode 1c 9c

echo Done! Waiting for reboot...
timeout /t 30 >nul

"%VBM%" controlvm %VM% poweroff 2>nul
timeout /t 3 >nul
"%VBM%" modifyvm %VM% --boot1 disk --boot2 none
"%VBM%" startvm %VM% --type gui

echo All done!
