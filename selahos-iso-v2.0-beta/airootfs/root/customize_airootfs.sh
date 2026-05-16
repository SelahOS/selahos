#!/usr/bin/env bash
# ============================================================
# customize_airootfs.sh
# Runs INSIDE the airootfs chroot during mkarchiso build.
# Copyright (C) 2026 Selah Technologies LLC
# ============================================================

set -e

# ── Live user ──────────────────────────────────────────────
# Pre-create groups that may not exist yet
# IMPORTANT: do NOT groupadd liveuser — useradd creates it automatically
# and groupadd-ing it first causes "group exists" error with set -e
groupadd -r autologin 2>/dev/null || true
groupadd -r bluetooth 2>/dev/null || true
groupadd -r realtime 2>/dev/null || true
groupadd -r storage 2>/dev/null || true

# Create liveuser — useradd auto-creates the liveuser primary group
useradd -m \
    -G wheel,audio,video,network,input,sys,lp,autologin \
    -s /bin/bash \
    liveuser

# Add optional groups separately so failures don't break everything
usermod -aG bluetooth liveuser 2>/dev/null || true
usermod -aG realtime liveuser 2>/dev/null || true
usermod -aG storage liveuser 2>/dev/null || true

echo "liveuser:liveuser" | chpasswd

# Passwordless sudo for live session
echo "liveuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/liveuser
chmod 440 /etc/sudoers.d/liveuser

# Copy skel to liveuser home
cp -r /etc/skel/. /home/liveuser/
chown -R liveuser:liveuser /home/liveuser

# Desktop shortcut for installer
mkdir -p /home/liveuser/Desktop
cp /usr/share/applications/selahos-install.desktop /home/liveuser/Desktop/ 2>/dev/null || true
chmod +x /home/liveuser/Desktop/selahos-install.desktop 2>/dev/null || true
chown -R liveuser:liveuser /home/liveuser/Desktop

# ── Locale ────────────────────────────────────────────────
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

# ── Services ──────────────────────────────────────────────
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm
systemctl enable bolt 2>/dev/null || true
systemctl enable acpid 2>/dev/null || true

# ── zram ──────────────────────────────────────────────────
cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# ── Creator sysctl ────────────────────────────────────────
cat > /etc/sysctl.d/99-selahos-creator.conf << 'EOF'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
fs.inotify.max_user_watches = 524288
EOF

# ── FireWire modules ──────────────────────────────────────
cat > /etc/modules-load.d/selahos-firewire.conf << 'EOF'
firewire-core
firewire-ohci
EOF

# ── Selah theme wiring ────────────────────────────────────────
# Skel already has kdeglobals, plasmarc, Kvantum/kvantum.kvconfig.
# The cp -r /etc/skel above copies them into liveuser home.
# Here we fix ownership (liveuser was just created) and write
# system-level overrides that survive for any future users too.

# Ensure Kvantum config lands in liveuser home even if skel copy
# already ran above — idempotent because skel is canonical.
if [ -d /home/liveuser ]; then
    mkdir -p /home/liveuser/.config/Kvantum
    cp /etc/skel/.config/Kvantum/kvantum.kvconfig \
       /home/liveuser/.config/Kvantum/kvantum.kvconfig
    cp /etc/skel/.config/kdeglobals \
       /home/liveuser/.config/kdeglobals
    cp /etc/skel/.config/plasmarc \
       /home/liveuser/.config/plasmarc
    chown -R liveuser:liveuser /home/liveuser/.config
fi

# gtk3 / gtk4: keep GTK apps dark and consistent via environment
# (Kvantum can render GTK apps if qt5ct/qt6ct is also set up,
#  but for pure GTK apps we set a matching dark theme preference)
mkdir -p /etc/skel/.config/gtk-3.0
cat > /etc/skel/.config/gtk-3.0/settings.ini << 'GTKEOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=breeze-dark
GTKEOF

if [ -d /home/liveuser ]; then
    mkdir -p /home/liveuser/.config/gtk-3.0
    cp /etc/skel/.config/gtk-3.0/settings.ini \
       /home/liveuser/.config/gtk-3.0/settings.ini
    chown -R liveuser:liveuser /home/liveuser/.config/gtk-3.0
fi

echo "✓ Selah theme applied"

echo "customize_airootfs.sh complete"

# ── Pacman keyring initialization ─────────────────────────────
# Initialize keyring at build time so live environment doesn't need to
echo "Initializing pacman keyring..."
pacman-key --init
pacman-key --populate archlinux
echo "✓ Keyring initialized"

# ── Mirrorlist verification ───────────────────────────────────
if [ ! -f /etc/pacman.d/mirrorlist ]; then
    echo "WARNING: mirrorlist missing — creating fallback"
    echo "Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
fi
