# SelahOS Beta 2.0.1 — Release Notes

**Release date:** 2026-09-09
**Architecture:** x86_64
**SHA-256:** `5378216432c4747b442e3a9e4aa97161d6b46f12eaf83c66eb4a23dc187254b3`

This is Beta 2.0.1, our initial public build on this track. Beta 2.0.2
is planned in roughly six weeks and will fold in feedback and testing
data from this release.

## What's in this build

- ISO boots to a KDE Plasma 6 live desktop
- SelahBridge — Windows app compatibility layer
- Full creator software stack (Ardour, Blender, GIMP, OBS, and more)
- Custom SelahOS graphical installer, now works fully offline from a
  bundled package repository
- PipeWire audio — low latency, JACK compatible
- New: per-machine hardware profile reapplied automatically at boot,
  so Wi-Fi and kernel settings are re-tuned correctly if a drive is
  moved to different hardware

## Known issues

- **Active:** Wi-Fi may not reconnect reliably after sleep on some
  Broadcom chipsets. A manual reconnect or reboot resolves it when it
  happens. This is the top item we're tracking toward Beta 2.0.2.
- **Minor:** NVIDIA proprietary drivers are not pre-installed; Nouveau
  is active by default.
- **Known:** Secure Boot must be disabled — SelahOS does not yet ship
  signed bootloader keys.
- **Known:** Ventoy is not supported for this image. Flash with `dd`.

## Compatibility

Verified on:

- MacBook Pro 14,1 (2017, 13") — primary development machine
- MacBook 10,1 (2017, 12") — boots and installs; Wi-Fi sleep/reconnect
  and speaker output are still being verified on this model

**Not yet tested:** MacBook Pro 9,2 (2012), other Intel Mac models, and
generic PC/UEFI hardware. Community testing is welcome — please report
results either way to beta@selahos.io.

SelahOS is an independent project and is not affiliated with or
endorsed by Apple Inc.
