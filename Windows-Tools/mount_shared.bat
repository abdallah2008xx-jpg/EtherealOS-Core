cd /d "C:\Program Files\Oracle\VirtualBox"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount /dev/sda2 /mnt/gentoo"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mkdir -p /mnt/gentoo/gentoo-files"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "mount -t vboxsf gentoo-files /mnt/gentoo/gentoo-files"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "ls /mnt/gentoo/gentoo-files/"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
