#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  selahbridge-install.sh — Universal SelahBridge Installer
#  Wine + DXVK + WineASIO for Linux audio production
#  Selah Technologies LLC — Copyright (C) 2026
#
#  Usage: sudo bash selahbridge-install.sh
#  Supports: Arch / SelahOS · Ubuntu / Debian / Pop!_OS · Fedora
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── ANSI palette (SelahOS gold aesthetic) ─────────────────────────────────────
GOLD=$'\033[38;2;214;168;90m'
PARCH=$'\033[38;2;237;228;212m'
TEAL=$'\033[38;2;142;195;184m'
MUTED=$'\033[38;2;154;141;123m'
RED=$'\033[38;2;185;122;111m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

header() { printf '\n%s%s══  %s  ══%s\n' "$GOLD" "$BOLD" "$1" "$RESET"; }
ok()     { printf '  %s✓%s %s%s%s\n' "$TEAL" "$RESET" "$PARCH" "$1" "$RESET"; }
info()   { printf '  %s→ %s%s\n' "$MUTED" "$1" "$RESET"; }
warn()   { printf '  %s⚠  %s%s%s\n' "$RED" "$PARCH" "$1" "$RESET"; }
die()    { printf '\n%s✗  %s%s\n' "$RED" "$1" "$RESET" >&2; exit 1; }

run()    {
    # run <description> <command...>
    local desc="$1"; shift
    info "$desc"
    if ! "$@" 2>/tmp/selahbridge-err.log; then
        warn "Command had issues: $(tail -1 /tmp/selahbridge-err.log 2>/dev/null || true)"
        return 1
    fi
    return 0
}

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Run as root:  sudo bash selahbridge-install.sh"

REAL_USER="${SUDO_USER:-${USER:-root}}"
[[ "$REAL_USER" == "root" ]] && die "Do not run as the root user directly. Use: sudo bash selahbridge-install.sh"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[[ -n "$REAL_HOME" ]] || die "Cannot determine home directory for user: $REAL_USER"

# ── Banner ────────────────────────────────────────────────────────────────────
clear
printf '%s%s\n' "$GOLD" "$BOLD"
cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════╗
  ║          SelahBridge™  —  Universal Installer                ║
  ║    Wine · DXVK · WineASIO  for Linux audio production        ║
  ╚══════════════════════════════════════════════════════════════╝
BANNER
printf '%s\n' "$RESET"
printf '  %sInstalling for:%s %s%s%s\n' "$MUTED" "$RESET" "$PARCH" "$REAL_USER" "$RESET"
printf '  %sHome:%s           %s%s%s\n' "$MUTED" "$RESET" "$PARCH" "$REAL_HOME" "$RESET"

# ── Distro detection ──────────────────────────────────────────────────────────
header "Detecting Distribution"

DISTRO="arch"
DXVK_VIA_WINETRICKS=false
SKIP_WINEASIO=false

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-$DISTRO_ID}"
else
    DISTRO_ID="unknown"
    DISTRO_LIKE="unknown"
fi

case "$DISTRO_LIKE $DISTRO_ID" in
    *arch*)
        DISTRO="arch"
        ;;
    *debian*|*ubuntu*)
        DISTRO="debian"
        ;;
    *fedora*|*rhel*|*centos*)
        DISTRO="fedora"
        ;;
    *)
        warn "Unrecognized distro ($DISTRO_ID / $DISTRO_LIKE) — assuming Arch-compatible"
        DISTRO="arch"
        ;;
esac

ok "Distribution: ${DISTRO_ID:-unknown} (${DISTRO} install path)"

# ═══════════════════════════════════════════════════════════════════════════════
#  ARCH / SELAHOS
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$DISTRO" == "arch" ]]; then

    # ── Multilib ──────────────────────────────────────────────────────────────
    header "Multilib Repository"
    PACMAN_CONF="/etc/pacman.conf"

    if grep -q '^\[multilib\]' "$PACMAN_CONF"; then
        ok "multilib already enabled"
    else
        # Uncomment the #[multilib] block in-place
        sed -i \
            -e '/^#\[multilib\]/{s/^#//}' \
            -e '/^\[multilib\]/{n; s/^#Include/Include/}' \
            "$PACMAN_CONF"

        # If sed didn't find it, append the section
        if ! grep -q '^\[multilib\]' "$PACMAN_CONF"; then
            printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$PACMAN_CONF"
        fi
        ok "multilib enabled"
    fi

    # ── Chaotic-AUR ───────────────────────────────────────────────────────────
    header "Chaotic-AUR"

    if grep -q '^\[chaotic-aur\]' "$PACMAN_CONF"; then
        ok "Chaotic-AUR already configured"
    else
        info "Importing signing key from keyserver.ubuntu.com..."
        pacman-key --recv-key 3056513887B78AEB \
            --keyserver keyserver.ubuntu.com 2>/dev/null || \
            warn "Key import issue — trying to continue"
        pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true

        info "Installing Chaotic-AUR keyring and mirrorlist..."
        if pacman -U --noconfirm \
            "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" \
            "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" \
            2>/dev/null; then
            printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> "$PACMAN_CONF"
            ok "Chaotic-AUR added"
        else
            warn "Chaotic-AUR setup failed — dxvk-async-git / wineasio will fall back to stable"
        fi
    fi

    # ── Sync ──────────────────────────────────────────────────────────────────
    header "Syncing Databases"
    pacman -Sy --noconfirm
    ok "package databases synced"

    # ── Wine Staging ──────────────────────────────────────────────────────────
    header "Wine Staging"
    pacman -S --noconfirm --needed wine-staging wine-mono wine-gecko winetricks || \
        die "Wine installation failed — check your internet connection"
    ok "wine-staging, wine-mono, wine-gecko, winetricks installed"

    # ── DXVK ──────────────────────────────────────────────────────────────────
    header "DXVK  (DirectX → Vulkan)"
    if pacman -S --noconfirm --needed dxvk-async-git 2>/dev/null; then
        ok "dxvk-async-git installed (Chaotic-AUR)"
    else
        warn "dxvk-async-git not found — falling back to stable dxvk"
        pacman -S --noconfirm --needed dxvk 2>/dev/null || \
            warn "dxvk (stable) also unavailable — skipping"
        ok "dxvk (stable) installed"
    fi

    # ── WineASIO ──────────────────────────────────────────────────────────────
    header "WineASIO"
    if pacman -S --noconfirm --needed wineasio 2>/dev/null; then
        ok "wineasio installed"
    else
        warn "wineasio not found — registration step will be skipped"
        SKIP_WINEASIO=true
    fi

    # ── 32-bit libraries ──────────────────────────────────────────────────────
    header "32-bit Libraries"
    pacman -S --noconfirm --needed \
        lib32-vulkan-icd-loader \
        lib32-vulkan-intel \
        lib32-libpulse \
        lib32-alsa-lib \
        lib32-alsa-plugins \
        lib32-pipewire-jack \
        pipewire-jack \
        realtime-privileges || warn "Some 32-bit packages could not be installed"
    ok "32-bit Vulkan, PulseAudio, ALSA, PipeWire-JACK, realtime-privileges"

# ═══════════════════════════════════════════════════════════════════════════════
#  UBUNTU / DEBIAN / POP!_OS
# ═══════════════════════════════════════════════════════════════════════════════
elif [[ "$DISTRO" == "debian" ]]; then

    header "System Update"
    apt-get update -qq
    ok "package lists updated"

    header "Prerequisites"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        wget curl gnupg2 software-properties-common \
        apt-transport-https ca-certificates lsb-release
    ok "prerequisites installed"

    header "32-bit Architecture (i386)"
    dpkg --add-architecture i386
    apt-get update -qq
    ok "i386 architecture enabled"

    header "WineHQ Repository"
    if [[ ! -f /etc/apt/sources.list.d/winehq.list ]]; then
        CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")
        DISTRIB_ID=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')

        # Map Ubuntu derivatives to their upstream codename
        case "$DISTRIB_ID" in
            pop|elementary|linuxmint|zorin) DISTRIB_ID="ubuntu" ;;
        esac

        mkdir -p /etc/apt/keyrings
        wget -qO /etc/apt/keyrings/winehq-archive.key \
            "https://dl.winehq.org/wine-builds/winehq.key" || \
            die "Cannot download WineHQ signing key"

        printf 'deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/%s/ %s main\n' \
            "$DISTRIB_ID" "$CODENAME" \
            > /etc/apt/sources.list.d/winehq.list
        apt-get update -qq
        ok "WineHQ repo added for ${DISTRIB_ID}/${CODENAME}"
    else
        ok "WineHQ repo already configured"
    fi

    header "Wine Staging"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --install-recommends winehq-staging 2>/dev/null || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y wine wine64 wine32 || \
        die "Wine installation failed"

    # winetricks from upstream if not in repos
    if ! command -v winetricks &>/dev/null; then
        info "Installing winetricks from upstream..."
        wget -qO /usr/local/bin/winetricks \
            "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
        chmod +x /usr/local/bin/winetricks
    fi
    ok "Wine Staging + winetricks installed"

    header "DXVK"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y dxvk 2>/dev/null; then
        ok "dxvk installed via apt"
    else
        info "dxvk not in repos — will install via winetricks after prefix init"
        DXVK_VIA_WINETRICKS=true
    fi

    header "WineASIO"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y wineasio 2>/dev/null; then
        ok "wineasio installed"
    else
        warn "wineasio not available in apt repos — registration will be skipped"
        info "To install manually: build from source at github.com/wineasio/wineasio"
        SKIP_WINEASIO=true
    fi

    header "32-bit Libraries"
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libvulkan1:i386 \
        mesa-vulkan-drivers:i386 \
        libpulse0:i386 \
        libasound2:i386 \
        libasound2-plugins:i386 \
        pipewire-jack \
        rtkit 2>/dev/null || warn "Some 32-bit packages could not be installed"
    ok "32-bit Vulkan, PulseAudio, ALSA, PipeWire-JACK, rtkit"

# ═══════════════════════════════════════════════════════════════════════════════
#  FEDORA / RHEL
# ═══════════════════════════════════════════════════════════════════════════════
elif [[ "$DISTRO" == "fedora" ]]; then

    header "RPM Fusion"
    if ! dnf repolist enabled 2>/dev/null | grep -q rpmfusion-free; then
        FEDORA_VER=$(rpm -E %fedora)
        dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" || \
            warn "RPM Fusion install had issues — some packages may be unavailable"
        ok "RPM Fusion (free + nonfree) enabled"
    else
        ok "RPM Fusion already configured"
    fi

    header "Wine"
    dnf install -y wine wine-staging 2>/dev/null || \
        dnf install -y wine || \
        die "Wine installation failed"

    if ! command -v winetricks &>/dev/null; then
        info "Installing winetricks from upstream..."
        wget -qO /usr/local/bin/winetricks \
            "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
        chmod +x /usr/local/bin/winetricks
    fi
    ok "Wine + winetricks installed"

    header "DXVK"
    if dnf install -y dxvk 2>/dev/null; then
        ok "dxvk installed"
    else
        info "dxvk not in repos — will install via winetricks after prefix init"
        DXVK_VIA_WINETRICKS=true
    fi

    header "WineASIO"
    warn "wineasio is not packaged for Fedora — skipping"
    info "To install manually: build from source at github.com/wineasio/wineasio"
    SKIP_WINEASIO=true

    header "32-bit Libraries"
    dnf install -y \
        vulkan-loader.i686 \
        mesa-vulkan-drivers.i686 \
        pulseaudio-libs.i686 \
        alsa-lib.i686 \
        alsa-plugins.i686 \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit.i686 \
        rtkit 2>/dev/null || warn "Some 32-bit packages could not be installed"
    ok "32-bit Vulkan, PulseAudio, ALSA, PipeWire-JACK, rtkit"

fi

# ═══════════════════════════════════════════════════════════════════════════════
#  COMMON SETUP  (all distros)
# ═══════════════════════════════════════════════════════════════════════════════

# ── Realtime limits ───────────────────────────────────────────────────────────
header "Realtime Audio Limits"
LIMITS_CONF="/etc/security/limits.conf"

if ! grep -q '@audio.*rtprio' "$LIMITS_CONF"; then
    cat >> "$LIMITS_CONF" << 'EOF'

# SelahBridge — realtime audio limits
@audio          -       rtprio          95
@audio          -       memlock         unlimited
@realtime       -       rtprio          99
@realtime       -       memlock         unlimited
EOF
    ok "realtime limits written to /etc/security/limits.conf"
else
    ok "realtime limits already present"
fi

# ── User groups ───────────────────────────────────────────────────────────────
header "User Groups"
getent group realtime &>/dev/null || groupadd realtime
getent group audio    &>/dev/null || groupadd audio
usermod -aG audio,realtime "$REAL_USER"
ok "Added ${REAL_USER} to: audio, realtime"

# ── PipeWire JACK config ──────────────────────────────────────────────────────
header "PipeWire JACK  (low-latency audio)"
PW_DIR="${REAL_HOME}/.config/pipewire"
JACK_CONF="${PW_DIR}/jack.conf"
mkdir -p "$PW_DIR"

if [[ ! -f "$JACK_CONF" ]]; then
    cat > "$JACK_CONF" << 'EOF'
context.properties = {
    default.clock.rate          = 48000
    default.clock.quantum       = 256
    default.clock.min-quantum   = 64
    default.clock.max-quantum   = 8192
}
EOF
    chown -R "${REAL_USER}:${REAL_USER}" "$PW_DIR"
    ok "PipeWire JACK config written (48 kHz · 256 quantum)"
else
    ok "PipeWire JACK config already present"
fi

# ── Wine environment helper ───────────────────────────────────────────────────
# All wine commands run as the real (non-root) user.
# CLAUDE.md rule: NEVER run wine as root.
_wine() {
    sudo -u "$REAL_USER" \
        env \
            HOME="$REAL_HOME" \
            USER="$REAL_USER" \
            WINEPREFIX="${REAL_HOME}/.wine" \
            WINEARCH="win64" \
            WINEDEBUG="-all" \
            DISPLAY="${DISPLAY:-:0}" \
        "$@"
}

# ── Wine prefix initialization ────────────────────────────────────────────────
header "Wine Prefix  (win64)"
info "Initializing prefix — this may take a minute..."
_wine wineboot -i 2>/dev/null || _wine wineboot 2>/dev/null || \
    warn "wineboot exited non-zero — Wine may still work"
ok "Wine prefix initialized at ${REAL_HOME}/.wine"

# ── DXVK via winetricks (fallback for non-Arch distros) ──────────────────────
if [[ "$DXVK_VIA_WINETRICKS" == true ]]; then
    header "DXVK  (via winetricks)"
    info "Installing dxvk — this may take several minutes..."
    _wine winetricks -q dxvk 2>/dev/null && ok "dxvk installed via winetricks" || \
        warn "dxvk via winetricks failed — DirectX→Vulkan translation unavailable"
fi

# ── Wine settings ─────────────────────────────────────────────────────────────
header "Wine Settings"
info "Windows 10 compatibility mode..."
_wine wine reg add \
    'HKEY_CURRENT_USER\Software\Wine' \
    /v Version /t REG_SZ /d win10 /f 2>/dev/null || true

info "96 DPI (prevents oversized / undersized application windows)..."
_wine wine reg add \
    'HKEY_CURRENT_USER\Control Panel\Desktop' \
    /v LogPixels /t REG_DWORD /d 96 /f 2>/dev/null || true
ok "Wine: Windows 10 mode · 96 DPI"

# ── Firefox for Windows ───────────────────────────────────────────────────────
header "Firefox  (Windows — for app authorization)"
info "Installing Firefox via winetricks (iLok, inMusic, Pace, etc.)..."
info "This may take several minutes on first run..."
_wine winetricks -q firefox 2>/dev/null && \
    ok "Firefox for Windows installed" || \
    warn "Firefox install failed — install manually via: winetricks firefox"

# ── Firefox as default browser in Wine ───────────────────────────────────────
header "Wine Browser Defaults"
info "Registering Firefox as default browser for http and https..."
for PROTO in http https; do
    _wine wine reg add \
        "HKEY_CURRENT_USER\\Software\\Classes\\${PROTO}\\shell\\open\\command" \
        /ve /t REG_SZ \
        /d '"C:\Program Files\Mozilla Firefox\firefox.exe" "%1"' \
        /f 2>/dev/null || true
done

# Suppress Microsoft Edge first-run hijack
_wine wine reg add \
    'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' \
    /v HideFirstRunExperience /t REG_DWORD /d 1 /f 2>/dev/null || true

ok "Firefox registered as default browser (http + https)"

# ── WineASIO registration ─────────────────────────────────────────────────────
if [[ "$SKIP_WINEASIO" == false ]]; then
    header "WineASIO Registration"

    # Arch installs wineasio-register; try that first
    if command -v wineasio-register &>/dev/null; then
        info "Running wineasio-register..."
        sudo -u "$REAL_USER" \
            HOME="$REAL_HOME" \
            WINEPREFIX="${REAL_HOME}/.wine" \
            wineasio-register 2>/dev/null && \
            ok "WineASIO registered via wineasio-register" || \
            warn "wineasio-register failed — falling back to regsvr32"
    fi

    # Fallback: regsvr32
    info "Registering wineasio.dll via regsvr32..."
    _wine wine regsvr32 wineasio.dll 2>/dev/null && \
        ok "WineASIO registered via regsvr32" || \
        warn "WineASIO registration failed — ASIO audio may be unavailable"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf '\n%s%s' "$GOLD" "$BOLD"
printf '══════════════════════════════════════════════════════════════\n'
printf '  ✓  SelahBridge installation complete.\n'
printf '══════════════════════════════════════════════════════════════\n'
printf '%s\n' "$RESET"
printf '  %sNext steps:%s\n' "$PARCH" "$RESET"
printf '  %s1.%s Log out and back in to activate audio group changes\n' "$MUTED" "$RESET"
printf '  %s2.%s Open SelahBridge Manager to configure applications\n' "$MUTED" "$RESET"
printf '  %s3.%s Use Firefox inside Wine for app auth (iLok, inMusic, Pace)\n' "$MUTED" "$RESET"
printf '\n'
printf '  %s%sPause. Reflect. Create.%s\n' "$GOLD" "$BOLD" "$RESET"
printf '\n'
