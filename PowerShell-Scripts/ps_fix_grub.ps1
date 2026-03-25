# PowerShell script to fix GRUB in VM
$VBM = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$VM = 'AhmadOS-Gentoo'

function Send-VMKey($cmd, $wait = 2) {
    & $VBM controlvm $VM keyboardputstring "$cmd"
    Start-Sleep -Milliseconds 300
    & $VBM controlvm $VM keyboardputscancode 0x1c 0x9c
    Start-Sleep -Seconds $wait
}

# Wait for boot
Start-Sleep -Seconds 40

# Boot from ISO
& $VBM controlvm $VM keyboardputscancode 0x1c 0x9c
Start-Sleep -Seconds 30

# Mount partitions
Send-VMKey 'mount /dev/sda2 /mnt/gentoo' 2
Send-VMKey 'mkdir -p /mnt/gentoo/boot && mount /dev/sda1 /mnt/gentoo/boot' 2

# Mount virtual filesystems
Send-VMKey 'mount -t proc none /mnt/gentoo/proc && mount -o bind /sys /mnt/gentoo/sys && mount -o bind /dev /mnt/gentoo/dev' 3

# Reinstall GRUB
Send-VMKey 'chroot /mnt/gentoo emerge -n sys-boot/grub' 60
Send-VMKey 'chroot /mnt/gentoo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable' 15
Send-VMKey 'chroot /mnt/gentoo grub-mkconfig -o /boot/grub/grub.cfg' 10

# Create fallback
Send-VMKey 'mkdir -p /mnt/gentoo/boot/EFI/BOOT && cp /mnt/gentoo/boot/EFI/abdallahOS/grubx64.efi /mnt/gentoo/boot/EFI/BOOT/bootx64.efi' 2

# Reboot
Send-VMKey 'umount -R /mnt/gentoo && reboot' 2

Start-Sleep -Seconds 30

# Reset boot order
& $VBM controlvm $VM poweroff
Start-Sleep -Seconds 3
& $VBM modifyvm $VM --boot1 disk --boot2 none
& $VBM startvm $VM --type gui

Write-Host 'Done!'
