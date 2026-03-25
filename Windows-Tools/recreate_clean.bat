@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
set VBM=VBoxManage.exe

REM Delete old VM
%VBM% unregistervm AhmadOS-Gentoo --delete 2>nul
timeout /t 2 >nul

REM Create new VM
%VBM% createvm --name AhmadOS-Gentoo --ostype Linux_64 --register --basefolder "c:\Users\abdal\Downloads\Gentoo-Custom-Project"

REM Configure with EFI
%VBM% modifyvm AhmadOS-Gentoo --memory 8192 --cpus 4 --vram 128 --graphicscontroller vmsvga --firmware efi64

REM Create disk
%VBM% createmedium disk --filename "c:\Users\abdal\Downloads\Gentoo-Custom-Project\AhmadOS-Gentoo-disk.vdi" --size 61440 --format VDI

REM Add storage
%VBM% storagectl AhmadOS-Gentoo --name SATA --add sata --controller IntelAhci --bootable on
%VBM% storagectl AhmadOS-Gentoo --name IDE --add ide
%VBM% storageattach AhmadOS-Gentoo --storagectl SATA --port 0 --device 0 --type hdd --medium "c:\Users\abdal\Downloads\Gentoo-Custom-Project\AhmadOS-Gentoo-disk.vdi"
%VBM% storageattach AhmadOS-Gentoo --storagectl IDE --port 0 --device 0 --type dvddrive --medium "c:\Users\abdal\Downloads\Gentoo-Custom-Project\install-amd64-minimal-20260316T093103Z.iso"

REM Shared folder
%VBM% sharedfolder add AhmadOS-Gentoo --name gentoo-files --hostpath "c:\Users\abdal\Downloads\Gentoo-Custom-Project\shared-for-vm" --automount

echo VM recreated! Starting...
%VBM% startvm AhmadOS-Gentoo --type gui
