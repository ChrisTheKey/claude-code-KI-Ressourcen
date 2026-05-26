#!/usr/bin/env bash
# =============================================================================
# CasandarOS Madcow Gaming Kernel — CachyOS Install Script
# Run this ON YOUR CACHYOS MACHINE (NOT in the build container)
# =============================================================================
# USAGE:
#   1. Copy the artifacts/ and pkgbuild/ directories to your CachyOS machine
#   2. Run: bash install-on-cachyos.sh
#
# NEVER run as root. Uses sudo only where required.
# =============================================================================

set -euo pipefail

PKG_NAME="linux-casandarOS-madcow-gaming-kernel"
KVER="6.18.33"
LOCALVERSION="-casandarOS-madcow-gaming-kernel"
FULL_VER="${KVER}${LOCALVERSION}"

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { echo "[FAIL] $*"; exit 1; }
pass() { echo "[PASS] $*"; }

# Guard: never install as root
[ "$(id -u)" -eq 0 ] && fail "Do NOT run as root."

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "=== CasandarOS Madcow Gaming Kernel — CachyOS Installer ==="
log "Target: ${FULL_VER}"

# --- Option A: Install from build artifacts (manual) -------------------------
install_manual() {
  log "[Method: Manual artifact copy]"
  
  ARTDIR="$SCRIPT_DIR/artifacts"
  [ -d "$ARTDIR" ] || fail "artifacts/ directory not found at $ARTDIR"
  [ -f "$ARTDIR/boot/vmlinuz-${PKG_NAME}" ] || fail "bzImage not found in artifacts/boot/"

  # Copy vmlinuz
  log "Installing kernel image..."
  sudo install -Dm644 "$ARTDIR/boot/vmlinuz-${PKG_NAME}" "/boot/vmlinuz-${PKG_NAME}"
  pass "Kernel image installed"

  # Copy config
  sudo install -Dm644 "$ARTDIR/boot/config-${FULL_VER}" "/boot/config-${FULL_VER}"

  # Copy System.map
  sudo install -Dm644 "$ARTDIR/boot/System.map-${FULL_VER}" "/boot/System.map-${FULL_VER}"

  # Install modules
  if [ -d "$ARTDIR/modules_staging/lib/modules/" ]; then
    log "Installing modules..."
    sudo cp -r "$ARTDIR/modules_staging/lib/modules/${FULL_VER}"* /lib/modules/ 2>/dev/null || true
    sudo depmod "${FULL_VER}"
    pass "Modules installed"
  else
    log "NOTE: No staged modules found. Modules are built-in (normal for embedded config)."
  fi

  # Generate initramfs
  log "Generating initramfs..."
  sudo mkinitcpio -k "${FULL_VER}" -g "/boot/initramfs-${PKG_NAME}.img"
  pass "initramfs generated"

  # Regenerate bootloader
  detect_and_update_bootloader
}

# --- Option B: Use makepkg (preferred for Arch) ------------------------------
install_pkgbuild() {
  log "[Method: makepkg PKGBUILD]"
  
  PKGDIR="$SCRIPT_DIR/pkgbuild"
  [ -f "$PKGDIR/PKGBUILD" ] || fail "PKGBUILD not found at $PKGDIR/PKGBUILD"

  cd "$PKGDIR"
  
  # Check build deps
  log "Checking build dependencies..."
  pacman -Qi pahole &>/dev/null || { log "Installing pahole..."; sudo pacman -S --noconfirm pahole; }
  
  log "Running makepkg (this will rebuild from source)..."
  makepkg -si --noconfirm

  pass "makepkg install complete"
}

detect_and_update_bootloader() {
  log "Detecting bootloader..."
  
  if [ -d /boot/loader/entries ]; then
    log "systemd-boot detected"
    # Create boot entry
    cat > "/tmp/madcow-entry.conf" << ENTRY
title   CasandarOS Madcow Gaming Kernel
linux   /vmlinuz-${PKG_NAME}
initrd  /initramfs-${PKG_NAME}.img
options root=LABEL=root rw quiet loglevel=3 nowatchdog nmi_watchdog=0 mitigations=auto
ENTRY
    sudo install -Dm644 "/tmp/madcow-entry.conf" "/boot/loader/entries/madcow-gaming.conf"
    pass "systemd-boot entry created: /boot/loader/entries/madcow-gaming.conf"
    log "To set as default: edit /boot/loader/loader.conf and set default madcow-gaming"
    
  elif command -v grub-mkconfig &>/dev/null; then
    log "GRUB detected"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    pass "GRUB config updated"
    
  else
    log "WARNING: Could not auto-detect bootloader. Update manually."
    log "  Kernel: /boot/vmlinuz-${PKG_NAME}"
    log "  initrd: /boot/initramfs-${PKG_NAME}.img"
  fi
}

post_install_sysctl() {
  log "Installing gaming sysctl preset..."
  sudo install -Dm644 "$SCRIPT_DIR/sysctl-gaming.conf" /etc/sysctl.d/99-madcow-gaming.conf
  sudo sysctl -p /etc/sysctl.d/99-madcow-gaming.conf
  pass "sysctl gaming preset applied"
}

# --- Main ---
echo ""
echo "Choose install method:"
echo "  1) Manual (from pre-built artifacts)    [fast, uses already-built bzImage]"
echo "  2) makepkg (rebuild from PKGBUILD)      [slower, proper Arch packaging]"
echo ""
read -rp "Method [1/2]: " METHOD

case "$METHOD" in
  1) install_manual ;;
  2) install_pkgbuild ;;
  *) fail "Invalid choice." ;;
esac

# Apply gaming sysctl if preset exists
[ -f "$SCRIPT_DIR/sysctl-gaming.conf" ] && post_install_sysctl

log ""
log "=== INSTALL COMPLETE ==="
log ""
log "IMPORTANT: Before rebooting, verify:"
log "  1. ls /boot/vmlinuz-${PKG_NAME}         ← kernel present"
log "  2. ls /boot/initramfs-${PKG_NAME}.img   ← initramfs present"
log "  3. Bootloader entry configured          ← see above"
log ""
log "Reboot command (when ready):"
log "  sudo reboot"
log ""
log "After reboot, run validation:"
log "  bash validate-after-boot.sh"
log ""
log "ROLLBACK: See ROLLBACK_GUIDE.md"
