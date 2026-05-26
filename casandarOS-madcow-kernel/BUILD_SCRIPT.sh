#!/usr/bin/env bash
# =============================================================================
# CasandarOS Madcow Gaming Kernel — BUILD_SCRIPT.sh
# Target: linux-casandarOS-madcow-gaming-kernel (linux-6.18.33)
# Target OS: CachyOS (Arch Linux)
# =============================================================================
# USAGE:
#   bash BUILD_SCRIPT.sh [phase]
#   phases: all, config, build, package
#   Default: all
#
# REQUIREMENTS:
#   - Run as NON-ROOT user on the build machine
#   - Arch Linux with: base-devel, pahole, python, xmlto, kmod, inetutils
#   - Run: yay -S base-devel pahole xmlto kmod inetutils
#
# NEVER auto-installs the kernel. Output is a .pkg.tar.zst.
# =============================================================================

set -euo pipefail

KERNEL_VERSION="6.18.33"
PKG_NAME="linux-casandarOS-madcow-gaming-kernel"
LOCALVERSION="-casandarOS-madcow-gaming-kernel"
LAB="$HOME/casandar_kernel_lab"
SRCDIR="$LAB/kernels/linux-${KERNEL_VERSION}"
CFGDIR="$LAB/configs"
PATCHDIR="$LAB/patches"
ARTDIR="$LAB/artifacts"
LOGDIR="$LAB/logs"
JOBS=$(nproc)

log()  { echo "[$(date '+%H:%M:%S')] [INFO]  $*"; }
warn() { echo "[$(date '+%H:%M:%S')] [WARN]  $*"; }
fail() { echo "[$(date '+%H:%M:%S')] [FAIL]  $*"; exit 1; }
pass() { echo "[$(date '+%H:%M:%S')] [PASS]  $*"; }

# ---- Guard: never run as root ------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  fail "HARD RULE: Never run kernel builds as root. Switch to a regular user."
fi

# ---- Verify source tree exists -----------------------------------------------
verify_source() {
  log "Verifying kernel source tree..."
  [ -f "$SRCDIR/Makefile" ] || fail "Kernel source not found at $SRCDIR"
  local ver; ver=$(grep -E '^VERSION|^PATCHLEVEL|^SUBLEVEL' "$SRCDIR/Makefile" | awk -F= '{print $2}' | tr -d ' ' | paste -sd'.' -)
  [ "$ver" = "$KERNEL_VERSION" ] || fail "Source version mismatch: expected $KERNEL_VERSION, got $ver"
  pass "Source tree: linux-${KERNEL_VERSION}"
}

# ---- Apply patches -----------------------------------------------------------
apply_patches() {
  log "Applying patches to linux-${KERNEL_VERSION}..."
  
  # Reset to clean state (preserve applied marker)
  cd "$SRCDIR"
  if [ -f "$SRCDIR/.patches_applied" ]; then
    log "Patches already applied — skipping. Delete .patches_applied to re-apply."
    return 0
  fi

  local applied=0
  local failed=0

  for patch in "$PATCHDIR"/*.patch "$PATCHDIR"/*.diff; do
    [ -f "$patch" ] || continue
    pname=$(basename "$patch")
    log "Applying: $pname"
    if patch -p1 --dry-run < "$patch" &>/dev/null; then
      patch -p1 < "$patch" | tee -a "$LOGDIR/patch_apply.log"
      pass "Applied: $pname"
      applied=$((applied+1))
    else
      warn "PATCH FAILED (dry-run): $pname — check $LOGDIR/patch_apply.log"
      patch -p1 < "$patch" 2>&1 | tee -a "$LOGDIR/patch_apply.log" || true
      failed=$((failed+1))
    fi
  done

  if [ "$failed" -gt 0 ]; then
    fail "$failed patch(es) failed. Fix .rej files before continuing."
  fi

  # Stamp
  echo "patches_applied=$(date)" > "$SRCDIR/.patches_applied"
  pass "All $applied patches applied successfully"
}

# ---- Configure kernel --------------------------------------------------------
configure_kernel() {
  log "Configuring linux-${KERNEL_VERSION}..."
  cd "$SRCDIR"

  if [ -f "$CFGDIR/madcow-gaming.config" ]; then
    log "Using saved config: $CFGDIR/madcow-gaming.config"
    cp "$CFGDIR/madcow-gaming.config" .config
    make olddefconfig
  else
    log "No saved config found — generating from defconfig + gaming overrides"
    make defconfig
    
    # --- Gaming critical settings ---
    # Scheduler
    scripts/config --enable CONFIG_HZ_1000
    scripts/config --disable CONFIG_HZ_250
    scripts/config --set-val CONFIG_HZ 1000
    
    # Preemption
    scripts/config --enable CONFIG_PREEMPT
    scripts/config --disable CONFIG_PREEMPT_VOLUNTARY
    scripts/config --disable CONFIG_PREEMPT_NONE
    
    # BORE scheduler (if patch applied)
    scripts/config --enable CONFIG_SCHED_BORE 2>/dev/null || warn "CONFIG_SCHED_BORE not available (BORE patch missing?)"
    
    # Tickless
    scripts/config --enable CONFIG_NO_HZ_IDLE
    scripts/config --disable CONFIG_NO_HZ_FULL
    
    # Memory
    scripts/config --enable CONFIG_LRU_GEN
    scripts/config --enable CONFIG_LRU_GEN_ENABLED
    scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE
    scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE_MADVISE
    scripts/config --disable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS
    
    # Scheduling groups
    scripts/config --enable CONFIG_CGROUP_SCHED
    scripts/config --enable CONFIG_FAIR_GROUP_SCHED
    
    # I/O schedulers
    scripts/config --enable CONFIG_IOSCHED_BFQ
    scripts/config --enable CONFIG_MQ_IOSCHED_DEADLINE
    
    # Network: BBR
    scripts/config --enable CONFIG_TCP_CONG_BBR
    scripts/config --set-str CONFIG_DEFAULT_TCP_CONG "bbr"
    
    # NTSync (Wine/Proton) — available 6.14+
    scripts/config --enable CONFIG_NTSYNC 2>/dev/null || warn "CONFIG_NTSYNC not available"
    
    # ZRAM
    scripts/config --enable CONFIG_ZRAM
    scripts/config --enable CONFIG_ZRAM_WRITEBACK
    
    # Disable debug overhead
    scripts/config --disable CONFIG_DEBUG_KERNEL
    scripts/config --disable CONFIG_KASAN
    scripts/config --disable CONFIG_UBSAN
    scripts/config --disable CONFIG_KCSAN
    scripts/config --disable CONFIG_SLUB_DEBUG
    scripts/config --disable CONFIG_DEBUG_LIST
    scripts/config --disable CONFIG_DEBUG_SG
    scripts/config --disable CONFIG_SCHED_DEBUG
    scripts/config --disable CONFIG_DEBUG_SPINLOCK
    scripts/config --disable CONFIG_LOCKDEP
    scripts/config --disable CONFIG_LOCK_STAT
    scripts/config --disable CONFIG_FTRACE
    scripts/config --disable CONFIG_FRAME_POINTER
    
    # LOCALVERSION
    scripts/config --set-str CONFIG_LOCALVERSION "$LOCALVERSION"
    
    make olddefconfig
    
    # Save for future use
    cp .config "$CFGDIR/madcow-gaming.config"
    pass "Config generated and saved to $CFGDIR/madcow-gaming.config"
  fi
}

# ---- Build -------------------------------------------------------------------
build_kernel() {
  log "Building linux-${KERNEL_VERSION} with -j${JOBS}..."
  log "Estimated time: 30-90 minutes depending on hardware"
  cd "$SRCDIR"
  
  local start; start=$(date +%s)
  
  # Build with gaming-optimized flags
  make -j"${JOBS}" \
    LOCALVERSION="$LOCALVERSION" \
    KCFLAGS="-O2 -pipe" \
    2>&1 | tee "$LOGDIR/build.log"
  
  local end; end=$(date +%s)
  local dur=$(( (end - start) / 60 ))
  
  pass "Build complete in ${dur} minutes"
  
  # Verify output
  [ -f "arch/x86/boot/bzImage" ] || fail "bzImage not found after build"
  pass "bzImage: arch/x86/boot/bzImage"
}

# ---- Package (Arch Linux PKGBUILD style) ------------------------------------
install_modules_and_package() {
  log "Installing modules and packaging..."
  cd "$SRCDIR"
  
  local INSTALL_MOD_PATH="$ARTDIR/modules_staging"
  rm -rf "$INSTALL_MOD_PATH"
  mkdir -p "$INSTALL_MOD_PATH"
  
  make INSTALL_MOD_PATH="$INSTALL_MOD_PATH" modules_install
  
  # Copy kernel image
  local BOOT_DIR="$ARTDIR/boot"
  mkdir -p "$BOOT_DIR"
  cp arch/x86/boot/bzImage "$BOOT_DIR/vmlinuz-${PKG_NAME}"
  cp .config "$BOOT_DIR/config-${KERNEL_VERSION}${LOCALVERSION}"
  
  # Generate module dependency info
  depmod -b "$INSTALL_MOD_PATH" "${KERNEL_VERSION}${LOCALVERSION}" || warn "depmod failed — run manually on target"
  
  pass "Artifacts in $ARTDIR"
  log "To install on CachyOS:"
  log "  sudo cp $BOOT_DIR/vmlinuz-${PKG_NAME} /boot/"
  log "  sudo cp -r $INSTALL_MOD_PATH/lib/modules/${KERNEL_VERSION}${LOCALVERSION} /lib/modules/"
  log "  sudo mkinitcpio -k ${KERNEL_VERSION}${LOCALVERSION} -g /boot/initramfs-${PKG_NAME}.img"
  log "  sudo grub-mkconfig -o /boot/grub/grub.cfg  (or bootctl update for systemd-boot)"
  log ""
  warn "NEVER auto-install. Review artifacts in $ARTDIR before deploying."
}

# ---- Main --------------------------------------------------------------------
PHASE="${1:-all}"
mkdir -p "$LOGDIR" "$ARTDIR" "$CFGDIR" "$PATCHDIR"

log "=== CasandarOS Madcow Gaming Kernel Build ==="
log "Kernel: linux-${KERNEL_VERSION}${LOCALVERSION}"
log "Phase: $PHASE | Jobs: $JOBS"

case "$PHASE" in
  all)
    verify_source
    apply_patches
    configure_kernel
    build_kernel
    install_modules_and_package
    ;;
  patches)
    verify_source
    apply_patches
    ;;
  config)
    verify_source
    configure_kernel
    ;;
  build)
    verify_source
    build_kernel
    ;;
  package)
    install_modules_and_package
    ;;
  *)
    echo "Usage: $0 [all|patches|config|build|package]"
    exit 1
    ;;
esac

log "=== DONE ==="
