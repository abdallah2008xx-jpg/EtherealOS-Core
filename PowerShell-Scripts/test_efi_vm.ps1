$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "Test-EFI"
$isoPath = "c:\Users\abdal\Downloads\Gentoo-Custom-Project\install-amd64-minimal-20260316T093103Z.iso"

Write-Host "Creating test VM..."
& $VBoxManage createvm --name $vmName --ostype "Linux_64" --register --basefolder "c:\Users\abdal\Downloads\Gentoo-Custom-Project"

& $VBoxManage modifyvm $vmName --memory 4096 --cpus 2 --firmware efi64

& $VBoxManage createmedium disk --filename "c:\Users\abdal\Downloads\Gentoo-Custom-Project\$vmName-test.vdi" --size 10240 --format VDI

& $VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci --bootable on
& $VBoxManage storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "c:\Users\abdal\Downloads\Gentoo-Custom-Project\$vmName-test.vdi"
& $VBoxManage storageattach $vmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $isoPath

& $VBoxManage startvm $vmName --type gui

Write-Host "Test VM created. Check if ISO boots properly with EFI."
