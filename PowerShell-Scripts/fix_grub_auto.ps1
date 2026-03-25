$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VM = "AhmadOS-Gentoo"

function Send-Cmd {
    param([string]$cmd, [int]$waitSec = 3)
    Write-Host ">>> $cmd"
    & $VBM controlvm $VM keyboardputstring $cmd
    Start-Sleep -Milliseconds 400
    & $VBM controlvm $VM keyboardputscancode 1c 9c
    Start-Sleep -Seconds $waitSec
}

Write-Host "=============================================="
Write-Host " Fix GRUB - Booting from Gentoo ISO"
Write-Host "=============================================="

# Wait for ISO to boot
Start-Sleep -Seconds 15

# Default Gentoo ISO boot
Send-Cmd "" 3

# Wait for boot
Start-Sleep -Seconds 30

Write-Host "=============================================="
Write-Host " Mounting partitions and fixing GRUB"
Write-Host "=============================================="

# Mount the installed system
Send-Cmd "mkdir -p /mnt/gentoo" 2
Send-Cmd "mount /dev/sda2 /mnt/gentoo" 3
Send-Cmd "mkdir -p /mnt/gentoo/boot" 1
Send-Cmd "mount /dev/sda1 /mnt/gentoo/boot" 2

# Bind mounts for chroot
Send-Cmd "mount --types proc /proc /mnt/gentoo/proc" 2
Send-Cmd "mount --rbind /sys /mnt/gentoo/sys" 2
Send-Cmd "mount --make-rslave /mnt/gentoo/sys" 1
Send-Cmd "mount --rbind /dev /mnt/gentoo/dev" 2
Send-Cmd "mount --make-rslave /mnt/gentoo/dev" 1

Write-Host "=============================================="
Write-Host " Re-installing GRUB in chroot"
Write-Host "=============================================="

# Enter chroot and fix GRUB
Send-Cmd "chroot /mnt/gentoo /bin/bash -c 'source /etc/profile && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --removable'" 10
Send-Cmd "chroot /mnt/gentoo /bin/bash -c 'source /etc/profile && grub-mkconfig -o /boot/grub/grub.cfg'" 10

# Unmount and reboot
Send-Cmd "umount -l /mnt/gentoo/dev{/shm,/pts,} 2>/dev/null; umount -R /mnt/gentoo" 3
Send-Cmd "reboot" 2

Write-Host "=============================================="
Write-Host " GRUB Fixed! VM will reboot to hard disk"
Write-Host "=============================================="

# Change boot order back to disk
Start-Sleep -Seconds 5
& $VBM controlvm $VM poweroff 2>$null
Start-Sleep -Seconds 2
& $VBM modifyvm $VM --boot1 disk --boot2 none
& $VBM storageattach $VM --storagectl SATA --port 1 --device 0 --type dvddrive --medium none
& $VBM startvm $VM --type gui
