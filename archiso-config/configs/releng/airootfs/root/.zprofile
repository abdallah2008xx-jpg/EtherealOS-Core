# ~/.zprofile — User shell profile
# NOTE: تشغيل Hyprland يتم تلقائياً عبر SDDM (autologin على hyprland-sw session).
#       هذا الملف لا يشغّل Hyprland مباشرة لتجنب التعارض مع SDDM ومسار rescue shell.
#
# إذا احتجت لجلسة طارئة (emergency shell على tty2 مثلاً)، استخدم:
#   sudo systemctl restart sddm
# أو شغّل Hyprland يدوياً:
#   /usr/local/bin/hyprland-sw.sh
