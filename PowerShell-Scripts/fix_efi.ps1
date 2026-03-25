$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "AhmadOS-Gentoo"

Write-Host "Stopping VM if running..."
& $VBoxManage controlvm $vmName poweroff 2>$null
Start-Sleep -Seconds 2

Write-Host "Changing firmware to EFI64..."
& $VBoxManage modifyvm $vmName --firmware efi64

Write-Host "Starting VM with EFI mode..."
& $VBoxManage startvm $vmName --type gui

Write-Host "Done! VM now uses UEFI/EFI mode for GRUB."
