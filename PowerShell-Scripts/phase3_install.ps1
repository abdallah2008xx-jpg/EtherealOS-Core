$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VM = "AhmadOS-Gentoo"

function Send-Cmd {
    param([string]$cmd, [int]$waitSec = 3)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] >>> $cmd"
    & $VBM controlvm $VM keyboardputstring $cmd
    Start-Sleep -Milliseconds 400
    & $VBM controlvm $VM keyboardputscancode 1c 9c  # Enter
    Start-Sleep -Seconds $waitSec
}

Write-Host "=============================================="
Write-Host " abdallahOS Phase 3: Base System Installation"
Write-Host "=============================================="

# Partitioning
Send-Cmd "parted -s -a optimal /dev/sda mklabel gpt" 3
Send-Cmd "parted -s -a optimal /dev/sda mkpart primary fat32 1MiB 513MiB" 2
Send-Cmd "parted -s -a optimal /dev/sda name 1 boot" 2
Send-Cmd "parted -s -a optimal /dev/sda set 1 esp on" 2
Send-Cmd "parted -s -a optimal /dev/sda mkpart primary ext4 513MiB 100pct" 2
Send-Cmd "parted -s -a optimal /dev/sda name 2 root" 2

# Format
Send-Cmd "mkfs.fat -F32 /dev/sda1" 5
Send-Cmd "mkfs.ext4 -F /dev/sda2" 8

# Mount
Send-Cmd "mount /dev/sda2 /mnt/gentoo" 2
Send-Cmd "mkdir -p /mnt/gentoo/boot" 1
Send-Cmd "mount /dev/sda1 /mnt/gentoo/boot" 2

Write-Host "=============================================="
Write-Host " Downloading stage3 from Gentoo mirrors..."
Write-Host " This will take 10-30 minutes depending on speed"
Write-Host "=============================================="

Send-Cmd "cd /mnt/gentoo" 1
Send-Cmd "wget -q https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz -O /mnt/gentoo/stage3.tar.xz" 1

Write-Host "Stage3 download started. Use vm_monitor.ps1 to track progress."
Write-Host "=============================================="
