$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "AhmadOS-Gentoo"
$isoPath = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\install-amd64-minimal-20260316T093103Z.iso"
$sharedFolder = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\shared-for-vm"
$diskPath = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\AhmadOS-Gentoo-disk.vdi"

Write-Host "Creating new VM with proper EFI settings..."

# Create VM with EFI firmware
& $VBoxManage createvm --name $vmName --ostype "Linux_64" --register --basefolder "c:\Users\abdal\Downloads\Gentoo-Custom-Project"

# Configure with EFI64 firmware (CRITICAL for GRUB)
& $VBoxManage modifyvm $vmName --memory 8192 --cpus 4 --vram 128 --graphicscontroller vmsvga --firmware efi64

# Create disk (if not exists)
if (-not (Test-Path $diskPath)) {
    & $VBoxManage createmedium disk --filename $diskPath --size 61440 --format VDI
}

# Add storage controllers
& $VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci --bootable on
& $VBoxManage storagectl $vmName --name "IDE" --add ide

# Attach disk and ISO
& $VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath
& $VBoxManage storageattach $vmName --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $isoPath

# Shared folder
& $VBoxManage sharedfolder add $vmName --name "gentoo-files" --hostpath $sharedFolder --automount

Write-Host "VM created successfully with EFI64 firmware!"
Write-Host "Start the VM and run the installation."
& $VBoxManage startvm $vmName --type gui
