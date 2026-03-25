$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VM = "AhmadOS-Gentoo"

function Send-VMCommand {
    param([string]$cmd, [int]$waitSeconds = 3)
    Write-Host ">>> Sending: $cmd"
    & $VBM controlvm $VM keyboardputstring $cmd
    Start-Sleep -Milliseconds 300
    & $VBM controlvm $VM keyboardputscancode 1c 9c  # Enter
    Start-Sleep -Seconds $waitSeconds
}

Write-Host "============================================"
Write-Host " abdallahOS - Remote VM Installation Script"
Write-Host "============================================"

# Phase 3: Partitioning
Send-VMCommand "parted -s -a optimal /dev/sda mklabel gpt mkpart primary fat32 1MiB 513MiB name 1 boot set 1 esp on mkpart primary ext4 513MiB 100% name 2 root" 5

Send-VMCommand "mkfs.fat -F32 /dev/sda1" 3
Send-VMCommand "mkfs.ext4 -F /dev/sda2" 5

Send-VMCommand "mount /dev/sda2 /mnt/gentoo" 2
Send-VMCommand "mkdir -p /mnt/gentoo/boot" 1
Send-VMCommand "mount /dev/sda1 /mnt/gentoo/boot" 2

# Download stage3 from Gentoo mirrors
Write-Host ">>> Downloading stage3-desktop-openrc (this will take a while)..."
Send-VMCommand "cd /mnt/gentoo && wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz" 600

# Extract stage3
Write-Host ">>> Extracting stage3..."
Send-VMCommand "tar xpf /mnt/gentoo/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo" 300

# Phase 4: Chroot setup
Send-VMCommand "cp --dereference /etc/resolv.conf /mnt/gentoo/etc/" 2
Send-VMCommand "mount --types proc /proc /mnt/gentoo/proc" 2
Send-VMCommand "mount --rbind /sys /mnt/gentoo/sys" 2
Send-VMCommand "mount --make-rslave /mnt/gentoo/sys" 1
Send-VMCommand "mount --rbind /dev /mnt/gentoo/dev" 2
Send-VMCommand "mount --make-rslave /mnt/gentoo/dev" 1
Send-VMCommand "mount --bind /run /mnt/gentoo/run" 2
Send-VMCommand "mount --make-slave /mnt/gentoo/run" 1

Write-Host "============================================"
Write-Host " Phase 3-4 Complete! Now entering chroot..."
Write-Host "============================================"
