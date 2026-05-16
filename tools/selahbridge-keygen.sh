#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  selahbridge-keygen.sh — INTERNAL TOOL — Selah Technologies LLC
#  Generates a SelahBridge license key for a given machine ID.
#
#  DO NOT distribute this file. Keep it internal.
#
#  Usage:
#    bash selahbridge-keygen.sh <machine-id>
#    bash selahbridge-keygen.sh --interactive      (prompts for machine ID)
#
#  Customer workflow:
#    1. Customer runs:  sudo bash selahbridge-install-licensed.sh --machine-id
#    2. Customer emails the Machine ID to support@selahtechnologies.com
#    3. You run this tool to generate their key, email it back
#    4. Customer runs:  sudo bash selahbridge-install-licensed.sh --activate <KEY>
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

GOLD=$'\033[38;2;214;168;90m'
PARCH=$'\033[38;2;237;228;212m'
TEAL=$'\033[38;2;142;195;184m'
MUTED=$'\033[38;2;154;141;123m'
RED=$'\033[38;2;185;122;111m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Must match selahbridge-install-licensed.sh exactly
_P1="S3L4HT3" ; _P2="CH2026X" ; _P3="R7B3TA!"
_SECRET="${_P1}${_P2}${_P3}"

_keygen() {
    local mid="$1"
    local raw
    raw=$(printf '%s%s' "$mid" "$_SECRET" | sha256sum | cut -c1-16 | tr '[:lower:]' '[:upper:]')
    printf 'SELAH-%s-%s-%s-%s\n' \
        "${raw:0:4}" "${raw:4:4}" "${raw:8:4}" "${raw:12:4}"
}

# ── Interactive mode ──────────────────────────────────────────────────────────
if [[ "${1:-}" == "--interactive" || $# -eq 0 ]]; then
    printf '%s%s\n' "$GOLD" "$BOLD"
    printf '  SelahBridge License Key Generator\n'
    printf '  Selah Technologies LLC — INTERNAL USE ONLY\n'
    printf '%s\n' "$RESET"
    printf '  %sEnter customer Machine ID:%s ' "$MUTED" "$RESET"
    read -r MACHINE_ID
    MACHINE_ID=$(printf '%s' "$MACHINE_ID" | tr -d ' \t\r\n')
    [[ -z "$MACHINE_ID" ]] && { printf '%s✗  Machine ID cannot be empty%s\n' "$RED" "$RESET" >&2; exit 1; }

    KEY=$(_keygen "$MACHINE_ID")

    printf '\n  %sMachine ID:%s %s%s%s\n' "$MUTED" "$RESET" "$PARCH" "$MACHINE_ID" "$RESET"
    printf '  %sLicense Key:%s %s%s%s\n\n' "$MUTED" "$RESET" "$TEAL$BOLD" "$KEY" "$RESET"
    printf '  %sSend this key to the customer.%s\n' "$MUTED" "$RESET"
    exit 0
fi

# ── CLI mode ──────────────────────────────────────────────────────────────────
MACHINE_ID=$(printf '%s' "${1}" | tr -d ' \t\r\n')
[[ -z "$MACHINE_ID" ]] && {
    printf '%sUsage: bash selahbridge-keygen.sh <machine-id>%s\n' "$RED" "$RESET" >&2
    exit 1
}

KEY=$(_keygen "$MACHINE_ID")
printf '%s%s%s\n' "$TEAL$BOLD" "$KEY" "$RESET"
