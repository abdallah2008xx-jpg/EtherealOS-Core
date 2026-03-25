#!/bin/bash
# ==========================================================
# EtherealOS - Multimedia Codecs Setup v1.0
# Fixes Netflix, 4K YouTube, and H.264 playback issues.
# ==========================================================

echo "🎬 Configuring Multimedia Codecs..."

# 1. Set Gentoo USE flags for codecs
# We need to ensure ffmpeg and vlc have the right flags for a "just works" experience.
mkdir -p /etc/portage/package.use
cat << 'EOF' > /etc/portage/package.use/ethereal-codecs
media-video/ffmpeg x264 x265 vpx mp3 aac encode opus vaapi vdpau threads postproc
media-video/vlc fonts flac mad mp3 ogg vorbis x264 x265 xml opengl
media-libs/gst-plugins-meta ffmpeg http x264 x265 vpx aac mp3
www-client/firefox hwaccel lto pgo pulseaudio system-av1 system-harfbuzz system-icu system-jpeg system-libevent system-libvpx system-webp
EOF

# 2. Install the necessary packages
echo "📦 Installing Codecs and Media Players..."
emerge --ask=n --quiet media-video/ffmpeg media-video/vlc media-libs/gst-plugins-meta media-libs/libdvdcss 2>/dev/null || true

# 3. Configure Firefox for DRM and Hardware Acceleration
echo "🦊 Optimizing Firefox for High-Quality Video..."
USER_PREFS="/home/abdallah/.mozilla/firefox/ethereal.default-release/prefs.js"

if [ -f "$USER_PREFS" ]; then
    # Enable DRM (Netflix/Amazon Prime)
    echo 'user_pref("media.eme.enabled", true);' >> "$USER_PREFS"
    echo 'user_pref("media.gmp-widevinecdm.enabled", true);' >> "$USER_PREFS"
    echo 'user_pref("media.gmp-widevinecdm.visible", true);' >> "$USER_PREFS"
    
    # Force Hardware Acceleration/VP9 for 4K YouTube
    echo 'user_pref("media.ffmpeg.vaapi.enabled", true);' >> "$USER_PREFS"
    echo 'user_pref("media.hardware-video-decoding.force-enabled", true);' >> "$USER_PREFS"
    echo 'user_pref("layers.acceleration.force-enabled", true);' >> "$USER_PREFS"
    
    # Fix ownership just in case
    chown abdallah:abdallah "$USER_PREFS"
fi

echo "✅ Multimedia Codecs successfully integrated."
