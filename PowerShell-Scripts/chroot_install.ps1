$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VM = "AhmadOS-Gentoo"

function Send-Cmd {
    param([string]$cmd, [int]$waitSec=3)
    & $VBM controlvm $VM keyboardputstring $cmd
    Start-Sleep -Milliseconds 400
    & $VBM controlvm $VM keyboardputscancode 1c 9c
    Start-Sleep -Seconds $waitSec
}

# 1. Prepare mounts
Send-Cmd "cp --dereference /etc/resolv.conf /mnt/gentoo/etc/" 1
Send-Cmd "mount --types proc /proc /mnt/gentoo/proc" 1
Send-Cmd "mount --rbind /sys /mnt/gentoo/sys" 1
Send-Cmd "mount --make-rslave /mnt/gentoo/sys" 1
Send-Cmd "mount --rbind /dev /mnt/gentoo/dev" 1
Send-Cmd "mount --make-rslave /mnt/gentoo/dev" 1
Send-Cmd "mount --bind /run /mnt/gentoo/run" 1
Send-Cmd "mount --make-slave /mnt/gentoo/run" 1

# 2. Enter chroot
Send-Cmd "chroot /mnt/gentoo /bin/bash" 2
Send-Cmd "env-update && source /etc/profile" 2
Send-Cmd "export PS1='(chroot) ${PS1}'" 1
Send-Cmd "echo nameserver 8.8.8.8 > /etc/resolv.conf" 1

# 3. Setup portage & packages
Write-Host "Running webrsync..."
Send-Cmd "emerge-webrsync -q" 120

# We need basic configuration for faster emerge
Send-Cmd "echo 'MAKEOPTS=`"-j4`"' >> /etc/portage/make.conf" 1
Send-Cmd "mkdir -p /etc/portage/package.accept_keywords" 1

# Trust binary packages (crucial)
Send-Cmd "getuto" 15

# 4. Emerge kernel, grub, and snapshot tools
Write-Host "Emerging kernel, grub, linux-firmware, networkmanager, and timeshift..."
Send-Cmd "emerge -q sys-kernel/gentoo-kernel-bin sys-boot/grub networkmanager sys-kernel/linux-firmware app-backup/timeshift sys-fs/btrfs-progs" 400

# 5. Bootloader and fstab setup (Btrfs Layout)
Write-Host "Setting up GRUB & Fstab (Btrfs)..."
Send-Cmd "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=AbdallahOS --removable --recheck" 15
Send-Cmd "grub-mkconfig -o /boot/grub/grub.cfg" 20
Send-Cmd "echo '/dev/sda1 /boot vfat defaults 0 2' > /etc/fstab" 1
Send-Cmd "echo '/dev/sda2 / btrfs subvol=@,noatime,compress=zstd 0 0' >> /etc/fstab" 1
Send-Cmd "echo '/dev/sda2 /home btrfs subvol=@home,noatime,compress=zstd 0 0' >> /etc/fstab" 1

# 6. Users & Passwords
Write-Host "Setting passwords..."
Send-Cmd "echo 'root:abdallah' | chpasswd" 1
Send-Cmd "useradd -m -G users,wheel,audio,video,usb,cdrom abdallah" 1
Send-Cmd "echo 'abdallah:abdallah' | chpasswd" 1

# 7. Services
Send-Cmd "rc-update add NetworkManager default" 1

# 8. Exit and reboot (Poweroff to safely remove ISO)
Send-Cmd "exit" 3
Send-Cmd "cd / && umount -l /mnt/gentoo/dev{/shm,/pts,} && umount -R /mnt/gentoo" 5
Send-Cmd "poweroff" 5

Write-Host "DONE! System should power off."
