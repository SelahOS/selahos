#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  selahbridge-install-licensed.sh — SelahBridge Installer (Licensed Edition)
#  14-day free trial · License key required after trial period
#  Selah Technologies LLC — Copyright (C) 2026
#
#  Usage:  sudo bash selahbridge-install-licensed.sh
#          sudo bash selahbridge-install-licensed.sh --activate <KEY>
#          sudo bash selahbridge-install-licensed.sh --machine-id
#
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
RESET=$'\033[0m'

header() { printf '\n%s%s══  %s  ══%s\n' "$GOLD" "$BOLD" "$1" "$RESET"; }
ok()     { printf '  %s✓%s %s%s%s\n' "$TEAL" "$RESET" "$PARCH" "$1" "$RESET"; }
info()   { printf '  %s→ %s%s\n' "$MUTED" "$1" "$RESET"; }
warn()   { printf '  %s⚠  %s%s%s\n' "$RED" "$RESET" "$PARCH" "$1" "$RESET"; }
die()    { printf '\n%s✗  %s%s\n' "$RED" "$1" "$RESET" >&2; exit 1; }

run()    {
    local desc="$1"; shift
    info "$desc"
    if ! "$@" 2>/tmp/selahbridge-err.log; then
        warn "Command had issues: $(tail -1 /tmp/selahbridge-err.log 2>/dev/null || true)"
        return 1
    fi
    return 0
}

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Run as root:  sudo bash selahbridge-install-licensed.sh"

REAL_USER="${SUDO_USER:-${USER:-root}}"
[[ "$REAL_USER" == "root" ]] && die "Do not run as the root user directly. Use: sudo bash selahbridge-install-licensed.sh"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[[ -n "$REAL_HOME" ]] || die "Cannot determine home directory for user: $REAL_USER"

# ═══════════════════════════════════════════════════════════════════════════════
#  LICENSE / TRIAL SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════
# Key derivation: sha256( machine_id || SECRET ) → first 16 hex chars (uppercase)
# formatted as SELAH-XXXX-XXXX-XXXX-XXXX
#
# To generate a key for a customer:
#   Ask for their Machine ID (sudo bash selahbridge-install-licensed.sh --machine-id)
#   Run selahbridge-keygen.sh <machine-id>   [internal Selah Technologies tool]
# ─────────────────────────────────────────────────────────────────────────────

_SB_LIC_DIR="/etc/selahbridge"
_SB_TRIAL_FILE="${_SB_LIC_DIR}/trial.conf"
_SB_LIC_FILE="${_SB_LIC_DIR}/license"
_SB_TRIAL_DAYS=14
_SB_SUPPORT="support@selahtechnologies.com"

# Key secret — split to reduce casual readability
_P1="S3L4HT3" ; _P2="CH2026X" ; _P3="R7B3TA!"
_SB_SECRET="${_P1}${_P2}${_P3}"

_sb_machine_id() {
    cat /etc/machine-id 2>/dev/null \
        || cat /var/lib/dbus/machine-id 2>/dev/null \
        || (hostname | sha256sum | cut -c1-32)
}

_sb_expected_key() {
    local mid="$1"
    local raw
    raw=$(printf '%s%s' "$mid" "$_SB_SECRET" | sha256sum | cut -c1-16 | tr '[:lower:]' '[:upper:]')
    printf 'SELAH-%s-%s-%s-%s' \
        "${raw:0:4}" "${raw:4:4}" "${raw:8:4}" "${raw:12:4}"
}

_sb_normalize_key() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]' | tr -d ' \t\r\n'
}

_sb_validate_stored_license() {
    [[ -f "$_SB_LIC_FILE" ]] || return 1
    local stored_key mid
    stored_key=$(grep '^key=' "$_SB_LIC_FILE" 2>/dev/null | cut -d= -f2)
    mid=$(_sb_machine_id)
    [[ "$stored_key" == "$(_sb_expected_key "$mid")" ]]
}

_sb_prompt_for_key() {
    local mid expected entered
    mid=$(_sb_machine_id)
    expected=$(_sb_expected_key "$mid")

    printf '\n%s%s  Trial period expired.%s\n\n' "$RED" "$BOLD" "$RESET"
    printf '  %sPurchase a license at:%s %s%shttps://selahtechnologies.com/selahbridge%s\n' \
        "$MUTED" "$RESET" "$BOLD" "$GOLD" "$RESET"
    printf '  %sThen email your Machine ID to:%s %s%s%s\n\n' \
        "$MUTED" "$RESET" "$GOLD" "$_SB_SUPPORT" "$RESET"
    printf '  %sMachine ID:%s %s%s%s\n\n' "$MUTED" "$RESET" "$PARCH" "$mid" "$RESET"
    printf '  Enter license key %s(SELAH-XXXX-XXXX-XXXX-XXXX)%s: ' "$MUTED" "$RESET"

    read -r entered
    entered=$(_sb_normalize_key "$entered")

    if [[ "$entered" == "$expected" ]]; then
        mkdir -p "$_SB_LIC_DIR"
        printf 'key=%s\nmachine_id=%s\nactivated=%d\n' \
            "$entered" "$mid" "$(date +%s)" > "$_SB_LIC_FILE"
        chmod 600 "$_SB_LIC_FILE"
        printf '\n'
        ok "License activated — thank you for supporting SelahOS."
    else
        printf '\n'
        die "Invalid license key. Contact ${_SB_SUPPORT} if you believe this is an error."
    fi
}

_sb_check_license() {
    # Already licensed
    if _sb_validate_stored_license; then
        local activated
        activated=$(grep '^activated=' "$_SB_LIC_FILE" 2>/dev/null | cut -d= -f2 || echo "")
        if [[ -n "$activated" ]]; then
            local act_date
            act_date=$(date -d "@${activated}" '+%Y-%m-%d' 2>/dev/null \
                    || date -r "$activated" '+%Y-%m-%d' 2>/dev/null \
                    || echo "unknown")
            ok "Licensed — activated ${act_date}"
        else
            ok "Licensed"
        fi
        return 0
    fi

    # Stale license file (machine changed, etc.) — remove it
    [[ -f "$_SB_LIC_FILE" ]] && rm -f "$_SB_LIC_FILE"

    # Init trial on first run
    mkdir -p "$_SB_LIC_DIR"
    if [[ ! -f "$_SB_TRIAL_FILE" ]]; then
        printf 'trial_start=%d\nmachine_id=%s\n' \
            "$(date +%s)" "$(_sb_machine_id)" > "$_SB_TRIAL_FILE"
        chmod 644 "$_SB_TRIAL_FILE"
        printf '\n  %s%sFree trial started — %d days remaining.%s\n' \
            "$GOLD" "$BOLD" "$_SB_TRIAL_DAYS" "$RESET"
        info "Purchase a license at: selahtechnologies.com/selahbridge"
        return 0
    fi

    # Check days remaining
    local trial_start now elapsed days_elapsed days_remaining
    trial_start=$(grep '^trial_start=' "$_SB_TRIAL_FILE" | cut -d= -f2)
    now=$(date +%s)
    elapsed=$(( now - trial_start ))
    days_elapsed=$(( elapsed / 86400 ))
    days_remaining=$(( _SB_TRIAL_DAYS - days_elapsed ))

    if [[ $days_remaining -gt 0 ]]; then
        printf '\n  %s%sTrial: %d of %d days used  (%d remaining).%s\n' \
            "$GOLD" "$BOLD" "$days_elapsed" "$_SB_TRIAL_DAYS" "$days_remaining" "$RESET"
        return 0
    fi

    # Trial expired — prompt for key
    _sb_prompt_for_key
}

# ── Handle CLI flags ──────────────────────────────────────────────────────────
case "${1:-}" in
    --machine-id)
        printf '%s\n' "$(_sb_machine_id)"
        exit 0
        ;;
    --activate)
        KEY="${2:-}"
        [[ -z "$KEY" ]] && die "Usage: sudo bash selahbridge-install-licensed.sh --activate <KEY>"
        KEY=$(_sb_normalize_key "$KEY")
        EXPECTED=$(_sb_expected_key "$(_sb_machine_id)")
        if [[ "$KEY" == "$EXPECTED" ]]; then
            mkdir -p "$_SB_LIC_DIR"
            printf 'key=%s\nmachine_id=%s\nactivated=%d\n' \
                "$KEY" "$(_sb_machine_id)" "$(date +%s)" > "$_SB_LIC_FILE"
            chmod 600 "$_SB_LIC_FILE"
            ok "License key accepted. SelahBridge is now fully licensed."
            printf '\n  %sPause. Reflect. Create.%s\n\n' "$GOLD" "$RESET"
        else
            die "Invalid license key. Contact ${_SB_SUPPORT}"
        fi
        exit 0
        ;;
    --status)
        if _sb_validate_stored_license; then
            ok "Licensed"
        elif [[ -f "$_SB_TRIAL_FILE" ]]; then
            trial_start=$(grep '^trial_start=' "$_SB_TRIAL_FILE" | cut -d= -f2)
            elapsed=$(( $(date +%s) - trial_start ))
            days_elapsed=$(( elapsed / 86400 ))
            days_remaining=$(( _SB_TRIAL_DAYS - days_elapsed ))
            if [[ $days_remaining -gt 0 ]]; then
                info "Trial: ${days_remaining} days remaining"
            else
                warn "Trial expired — license required"
                info "Machine ID: $(_sb_machine_id)"
            fi
        else
            info "Not installed (no trial record)"
        fi
        exit 0
        ;;
esac

# ── Banner ────────────────────────────────────────────────────────────────────
clear
printf '%s%s\n' "$GOLD" "$BOLD"
cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════╗
  ║     SelahBridge™  —  Licensed Installer  (14-day trial)     ║
  ║    Wine · DXVK · WineASIO  for Linux audio production        ║
  ╚══════════════════════════════════════════════════════════════╝
BANNER
printf '%s\n' "$RESET"
printf '  %sInstalling for:%s %s%s%s\n' "$MUTED" "$RESET" "$PARCH" "$REAL_USER" "$RESET"
printf '  %sHome:%s           %s%s%s\n' "$MUTED" "$RESET" "$PARCH" "$REAL_HOME" "$RESET"

# ── License / trial check ─────────────────────────────────────────────────────
header "License Check"
_sb_check_license

# ═══════════════════════════════════════════════════════════════════════════════
#  DISTRO DETECTION
# ═══════════════════════════════════════════════════════════════════════════════
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
    *arch*)                           DISTRO="arch"   ;;
    *debian*|*ubuntu*)                DISTRO="debian" ;;
    *fedora*|*rhel*|*centos*)         DISTRO="fedora" ;;
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

    header "Multilib Repository"
    PACMAN_CONF="/etc/pacman.conf"
    if grep -q '^\[multilib\]' "$PACMAN_CONF"; then
        ok "multilib already enabled"
    else
        sed -i \
            -e '/^#\[multilib\]/{s/^#//}' \
            -e '/^\[multilib\]/{n; s/^#Include/Include/}' \
            "$PACMAN_CONF"
        if ! grep -q '^\[multilib\]' "$PACMAN_CONF"; then
            printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$PACMAN_CONF"
        fi
        ok "multilib enabled"
    fi

    header "Chaotic-AUR"
    if grep -q '^\[chaotic-aur\]' "$PACMAN_CONF"; then
        ok "Chaotic-AUR already configured"
    else
        info "Importing signing key..."
        pacman-key --recv-key 3056513887B78AEB \
            --keyserver keyserver.ubuntu.com 2>/dev/null || \
            warn "Key import issue — continuing"
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

    header "Syncing Databases"
    pacman -Sy --noconfirm
    ok "package databases synced"

    header "Wine Staging"
    pacman -S --noconfirm --needed wine-staging wine-mono wine-gecko winetricks || \
        die "Wine installation failed — check your internet connection"
    ok "wine-staging, wine-mono, wine-gecko, winetricks"

    header "DXVK  (DirectX → Vulkan)"
    if pacman -S --noconfirm --needed dxvk-async-git 2>/dev/null; then
        ok "dxvk-async-git (Chaotic-AUR)"
    else
        warn "dxvk-async-git not found — falling back to stable dxvk"
        pacman -S --noconfirm --needed dxvk 2>/dev/null || warn "dxvk unavailable — skipping"
        ok "dxvk (stable)"
    fi

    header "WineASIO"
    if pacman -S --noconfirm --needed wineasio 2>/dev/null; then
        ok "wineasio installed"
    else
        warn "wineasio not found — registration step will be skipped"
        SKIP_WINEASIO=true
    fi

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
        case "$DISTRIB_ID" in
            pop|elementary|linuxmint|zorin) DISTRIB_ID="ubuntu" ;;
        esac
        mkdir -p /etc/apt/keyrings
        wget -qO /etc/apt/keyrings/winehq-archive.key \
            "https://dl.winehq.org/wine-builds/winehq.key" || \
            die "Cannot download WineHQ signing key"
        printf 'deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/%s/ %s main\n' \
            "$DISTRIB_ID" "$CODENAME" > /etc/apt/sources.list.d/winehq.list
        apt-get update -qq
        ok "WineHQ repo added (${DISTRIB_ID}/${CODENAME})"
    else
        ok "WineHQ repo already configured"
    fi

    header "Wine Staging"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --install-recommends winehq-staging 2>/dev/null || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y wine wine64 wine32 || \
        die "Wine installation failed"
    if ! command -v winetricks &>/dev/null; then
        wget -qO /usr/local/bin/winetricks \
            "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
        chmod +x /usr/local/bin/winetricks
    fi
    ok "Wine Staging + winetricks"

    header "DXVK"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y dxvk 2>/dev/null; then
        ok "dxvk via apt"
    else
        info "dxvk not in repos — will install via winetricks after prefix init"
        DXVK_VIA_WINETRICKS=true
    fi

    header "WineASIO"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y wineasio 2>/dev/null; then
        ok "wineasio installed"
    else
        warn "wineasio not in apt repos — skipping (see github.com/wineasio/wineasio)"
        SKIP_WINEASIO=true
    fi

    header "32-bit Libraries"
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libvulkan1:i386 mesa-vulkan-drivers:i386 \
        libpulse0:i386 libasound2:i386 libasound2-plugins:i386 \
        pipewire-jack rtkit 2>/dev/null || \
        warn "Some 32-bit packages could not be installed"
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
            warn "RPM Fusion had issues — some packages may be unavailable"
        ok "RPM Fusion (free + nonfree)"
    else
        ok "RPM Fusion already configured"
    fi

    header "Wine"
    dnf install -y wine wine-staging 2>/dev/null || dnf install -y wine || \
        die "Wine installation failed"
    if ! command -v winetricks &>/dev/null; then
        wget -qO /usr/local/bin/winetricks \
            "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
        chmod +x /usr/local/bin/winetricks
    fi
    ok "Wine + winetricks"

    header "DXVK"
    if dnf install -y dxvk 2>/dev/null; then
        ok "dxvk installed"
    else
        info "dxvk not in repos — will install via winetricks after prefix init"
        DXVK_VIA_WINETRICKS=true
    fi

    header "WineASIO"
    warn "wineasio not packaged for Fedora — skipping"
    SKIP_WINEASIO=true

    header "32-bit Libraries"
    dnf install -y \
        vulkan-loader.i686 mesa-vulkan-drivers.i686 \
        pulseaudio-libs.i686 alsa-lib.i686 alsa-plugins.i686 \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit.i686 \
        rtkit 2>/dev/null || warn "Some 32-bit packages could not be installed"
    ok "32-bit Vulkan, PulseAudio, ALSA, PipeWire-JACK, rtkit"

fi

# ═══════════════════════════════════════════════════════════════════════════════
#  COMMON SETUP
# ═══════════════════════════════════════════════════════════════════════════════

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

header "User Groups"
getent group realtime &>/dev/null || groupadd realtime
getent group audio    &>/dev/null || groupadd audio
usermod -aG audio,realtime "$REAL_USER"
ok "Added ${REAL_USER} to: audio, realtime"

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

# All wine commands run as the real user — NEVER as root
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

header "Wine Prefix  (win64)"
info "Initializing prefix — this may take a minute..."
_wine wineboot -i 2>/dev/null || _wine wineboot 2>/dev/null || \
    warn "wineboot exited non-zero — Wine may still work"
ok "Wine prefix initialized at ${REAL_HOME}/.wine"

if [[ "$DXVK_VIA_WINETRICKS" == true ]]; then
    header "DXVK  (via winetricks)"
    info "Installing dxvk — this may take several minutes..."
    _wine winetricks -q dxvk 2>/dev/null && ok "dxvk installed via winetricks" || \
        warn "dxvk via winetricks failed — DirectX→Vulkan unavailable"
fi

header "Wine Settings"
info "Windows 10 compatibility mode..."
_wine wine reg add \
    'HKEY_CURRENT_USER\Software\Wine' \
    /v Version /t REG_SZ /d win10 /f 2>/dev/null || true
info "96 DPI..."
_wine wine reg add \
    'HKEY_CURRENT_USER\Control Panel\Desktop' \
    /v LogPixels /t REG_DWORD /d 96 /f 2>/dev/null || true
ok "Wine: Windows 10 mode · 96 DPI"

header "Firefox  (Windows — for app authorization)"
info "Installing Firefox via winetricks (iLok, inMusic, Pace, etc.)..."
_wine winetricks -q firefox 2>/dev/null && \
    ok "Firefox for Windows installed" || \
    warn "Firefox install failed — run: winetricks firefox"

header "Wine Browser Defaults"
for PROTO in http https; do
    _wine wine reg add \
        "HKEY_CURRENT_USER\\Software\\Classes\\${PROTO}\\shell\\open\\command" \
        /ve /t REG_SZ \
        /d '"C:\Program Files\Mozilla Firefox\firefox.exe" "%1"' \
        /f 2>/dev/null || true
done
_wine wine reg add \
    'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge' \
    /v HideFirstRunExperience /t REG_DWORD /d 1 /f 2>/dev/null || true
ok "Firefox registered as default browser (http + https)"

if [[ "$SKIP_WINEASIO" == false ]]; then
    header "WineASIO Registration"
    if command -v wineasio-register &>/dev/null; then
        info "Running wineasio-register..."
        sudo -u "$REAL_USER" \
            HOME="$REAL_HOME" \
            WINEPREFIX="${REAL_HOME}/.wine" \
            wineasio-register 2>/dev/null && \
            ok "WineASIO registered via wineasio-register" || \
            warn "wineasio-register failed — falling back to regsvr32"
    fi
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

# Show license status / purchase reminder
if ! _sb_validate_stored_license 2>/dev/null; then
    trial_start=$(grep '^trial_start=' "$_SB_TRIAL_FILE" 2>/dev/null | cut -d= -f2 || echo "0")
    days_elapsed=$(( ( $(date +%s) - trial_start ) / 86400 ))
    days_remaining=$(( _SB_TRIAL_DAYS - days_elapsed ))
    printf '\n  %s%sTrial: %d days remaining.%s  Purchase: %sselahtechnologies.com/selahbridge%s\n' \
        "$GOLD" "$BOLD" "$days_remaining" "$RESET" "$GOLD" "$RESET"
fi

printf '\n'
printf '  %s%sPause. Reflect. Create.%s\n' "$GOLD" "$BOLD" "$RESET"
printf '\n'
