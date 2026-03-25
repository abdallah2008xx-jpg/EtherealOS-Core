@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputstring "p"
VBoxManage.exe controlvm AhmadOS-Gentoo keyboardputscancode 1c 9c
