# SelahOS Project Context

## What this is
SelahOS is a creator-first Arch Linux distribution built by
Selah Technologies LLC (Dane-Brandon Noble, founder).
Base: Arch Linux + linux-zen kernel + KDE Plasma 6 + PipeWire

## Current status
- ISO boots successfully to KDE live desktop
- liveuser autologin works
- Custom PyQt6 installer UI (selahos-installer) launches correctly
- Installation backend (archinstall) fails due to mirror/keyring issues
- All fixes applied in latest tarball

## Critical rules
- NEVER add intel-ucode.img or amd-ucode.img to GRUB initrd lines
- NEVER add copytoram or archisodevice to boot params
- NEVER run wine as root
- NEVER use Ventoy — always burn with dd

## Key files
- ISO profile: ~/SelahOS-Dev/selahos-iso-v2.0-beta/
- Installer UI: airootfs/usr/local/bin/selahos-installer
- Boot config: grub/grub.cfg
- mkinitcpio: airootfs/etc/mkinitcpio.conf
- Customize script: airootfs/root/customize_airootfs.sh

## Build machine
2017 MacBook Pro running SelahOS
User: dbnoble
Build command:
sudo mkarchiso -v \
    -w /home/dbnoble/selahos-build \
    -o /home/dbnoble/selahos-iso-output \
    /home/dbnoble/selahos-iso-v2.0-beta

## What Claude Code should focus on
Fix the archinstall backend in selahos-installer so installation
completes. The UI works. The ISO boots. The failure is in the
archinstall JSON config call and mirror configuration.
