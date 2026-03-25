@echo off
cd /d "C:\Program Files\Oracle\VirtualBox"

echo === Manual UEFI Fix ===
echo Starting VM...
VBoxManage.exe startvm AhmadOS-Gentoo --type gui

timeout /t 20 /nobreak >nul

echo.
echo When UEFI shell appears, type these commands MANUALLY:
echo.
echo   fs0:
echo   cd EFI
echo   mkdir BOOT
echo   cp abdallahOS\grubx64.efi BOOT\bootx64.efi
echo   exit

echo.
echo Or if you see Boot Manager:
echo 1. Select 'Boot Manager'
echo 2. Look for your disk
echo 3. Navigate to EFI
echo 4. Select bootx64.efi if available

echo.
pause
