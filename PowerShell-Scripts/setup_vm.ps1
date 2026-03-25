$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "AhmadOS-Gentoo"
$isoPath = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\install-amd64-minimal-20260316T093103Z.iso"
$sharedFolder = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\shared-for-vm"
$diskPath = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\$vmName" + "-disk.vdi"

Write-Host "Creating Virtual Machine: $vmName..."
& $VBoxManage createvm --name $vmName --ostype "Linux_64" --register --basefolder "c:\Users\abdal\Downloads\Gentoo-Custom-Project"

Write-Host "Configuring RAM, VRAM, and CPUs..."
& $VBoxManage modifyvm $vmName --memory 8192 --cpus 4 --vram 128 --graphicscontroller vmsvga --firmware efi64

Write-Host "Creating 60GB Hard Disk..."
& $VBoxManage createmedium disk --filename $diskPath --size 61440 --format VDI

Write-Host "Adding Storage Controllers..."
& $VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci --bootable on
& $VBoxManage storagectl $vmName --name "IDE" --add ide

Write-Host "Attaching Hard Disk and ISO..."
& $VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath
& $VBoxManage storageattach $vmName --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $isoPath

Write-Host "Configuring Shared Folder..."
& $VBoxManage sharedfolder add $vmName --name "gentoo-files" --hostpath $sharedFolder --automount --auto-mount-point "/gentoo-files"

Write-Host "Starting Virtual Machine..."
& $VBoxManage startvm $vmName --type gui
Write-Host "Virtual Machine Started Successfully!"
