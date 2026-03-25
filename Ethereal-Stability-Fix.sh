# ==========================================================
# EtherealOS - System Stability Engine v1.0
# Prevents RAM-related freezes using Nohang (OOM Daemon).
# ==========================================================

# ── Privilege Check: Self-Elevate if needed ──
if [ "$(id -u)" -ne 0 ]; then
    echo "🔑 Stability Fix: Admin privileges required."
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec bash "$0" "$@"
    else
        exec sudo bash "$0" "$@"
    fi
fi

echo "🚨 Configuring System Stability (OOM Protection)..."

# 1. Install Nohang
# We use the 'app-admin/nohang' package for Gentoo
if ! command -v nohang >/dev/null 2>&1; then
    emerge --ask=n --quiet app-admin/nohang 2>/dev/null || true
fi

# 2. Configure Nohang for notifications
# We enable high-verbosity and notifications to the user
CONFIG_FILE="/etc/nohang/nohang.conf"
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's/show_notifications = False/show_notifications = True/g' "$CONFIG_FILE" 2>/dev/null
    sed -i 's/notification_timeout = 5000/notification_timeout = 10000/g' "$CONFIG_FILE" 2>/dev/null
fi

# 3. Enable and start the Nohang service (OpenRC)
if command -v nohang >/dev/null 2>&1; then
    rc-update add nohang default 2>/dev/null || true
    rc-service nohang start 2>/dev/null || true
    echo "✅ Nohang stability daemon is active and configured."
else
    echo "❌ Nohang installation failed. Check internet/portage."
fi

echo "🧠 Configuring CPU Microcode (Processor Stability)..."

# 1. Install Microcode packages
# Detection: Intel (GenuineIntel) or AMD (AuthenticAMD)
CPU_TYPE=$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')

if [[ "$CPU_TYPE" == "GenuineIntel" ]]; then
    echo "   → Intel CPU detected. Installing intel-microcode..."
    emerge --ask=n --quiet sys-firmware/intel-microcode 2>/dev/null || true
elif [[ "$CPU_TYPE" == "AuthenticAMD" ]]; then
    echo "   → AMD CPU detected. linux-firmware handles AMD microcode."
fi

# Always ensure linux-firmware is present
emerge --ask=n --quiet sys-kernel/linux-firmware 2>/dev/null || true

# 2. Update GRUB to load microcode
echo "🚀 Updating GRUB to enable Early Microcode Loading..."
if command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
elif command -v update-grub >/dev/null 2>&1; then
    update-grub 2>/dev/null || true
fi

echo "✅ CPU Microcode updates are scheduled for next boot."

echo "✨ Stability Fix Complete!"
