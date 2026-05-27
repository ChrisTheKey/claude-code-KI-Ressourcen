#!/usr/bin/env bash
# =============================================================================
# CasandarOS Madcow Gaming Kernel — CachyOS Bootstrap
# Run this ONE COMMAND on your CachyOS machine:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/ChrisTheKey/claude-code-KI-Ressourcen/claude/exciting-fermat-7JJyc/casandarOS-madcow-kernel/bootstrap-cachyos.sh)
#
# What it does:
#   1. Installs build dependencies (pacman)
#   2. Clones this repo
#   3. Downloads Linux 6.18.33 source
#   4. Applies BORE + gaming patches
#   5. Applies gaming .config
#   6. Builds the kernel (-jN auto)
#   7. Tells you exactly how to install it
#
# Does NOT auto-install. You confirm before anything touches /boot.
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/ChrisTheKey/claude-code-KI-Ressourcen"
BRANCH="claude/exciting-fermat-7JJyc"
LAB="$HOME/casandar_kernel_lab"
KVER="6.18.33"
JOBS=$(nproc)

log()  { echo ""; echo ">>> $*"; }
info() { echo "    $*"; }
fail() { echo ""; echo "[FAIL] $*"; exit 1; }
pass() { echo "    [OK] $*"; }

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  CasandarOS Madcow Gaming Kernel — CachyOS Bootstrap     ║"
echo "║  linux-${KVER}-casandarOS-madcow-gaming-kernel          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Guard: never run as root
[ "$(id -u)" -eq 0 ] && fail "Do NOT run as root. Switch to your normal user."

# Guard: confirm before starting
echo "This will:"
echo "  - Install build tools via pacman (~100MB)"
echo "  - Download Linux ${KVER} source (~1.5GB)"
echo "  - Build the kernel (~20 min on your machine)"
echo "  - Stage artifacts in: $LAB/artifacts/"
echo ""
read -rp "Continue? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ---- Step 1: Build dependencies ---------------------------------------------
log "Step 1/6 — Installing build dependencies..."
sudo pacman -S --needed --noconfirm \
  base-devel pahole python xmlto kmod bc libelf cpio zstd \
  git curl rsync 2>&1 | grep -E "^(installing|upgrading|warning)" || true
pass "Build deps installed"

# ---- Step 2: Clone the repo -------------------------------------------------
log "Step 2/6 — Cloning kernel scripts repo..."
REPODIR="$HOME/claude-code-KI-Ressourcen"
if [ -d "$REPODIR/.git" ]; then
  info "Repo already exists at $REPODIR — pulling latest..."
  git -C "$REPODIR" fetch origin
  git -C "$REPODIR" checkout "$BRANCH"
  git -C "$REPODIR" pull origin "$BRANCH"
else
  git clone --depth=1 --branch "$BRANCH" --single-branch "$REPO_URL" "$REPODIR"
fi
pass "Repo ready: $REPODIR"

# ---- Step 3: Workspace setup ------------------------------------------------
log "Step 3/6 — Setting up kernel lab workspace..."
mkdir -p "$LAB"/{kernels,patches,configs,logs,artifacts/boot,benchmarks,telemetry}
cp -r "$REPODIR/casandarOS-madcow-kernel/patches/"*.patch "$LAB/patches/" 2>/dev/null || true
cp "$REPODIR/casandarOS-madcow-kernel/configs/madcow-gaming.config" "$LAB/configs/"
pass "Workspace: $LAB"

# ---- Step 4: Download kernel source -----------------------------------------
SRCDIR="$LAB/kernels/linux-${KVER}"
if [ -f "$SRCDIR/Makefile" ]; then
  log "Step 4/6 — Kernel source already present, skipping download"
  pass "Source exists: $SRCDIR"
else
  log "Step 4/6 — Downloading Linux ${KVER} source (~1.5GB)..."
  info "This is the largest step. Grab a coffee ☕"
  git clone --depth=1 --branch "v${KVER}" --single-branch \
    https://github.com/gregkh/linux.git \
    "$SRCDIR"
  pass "Source downloaded: $SRCDIR"
fi

# ---- Step 5: Apply patches --------------------------------------------------
log "Step 5/6 — Applying gaming patches..."
cd "$SRCDIR"

if [ ! -f ".patches_applied" ]; then
  # BORE scheduler
  BORE_PATCH="$LAB/patches/0001-bore-scheduler.patch"
  if [ -f "$BORE_PATCH" ]; then
    if patch -p1 --dry-run --quiet < "$BORE_PATCH" 2>/dev/null; then
      patch -p1 < "$BORE_PATCH" | tail -3
      pass "BORE scheduler applied"
    else
      echo "    [WARN] BORE patch has conflicts — check manually"
    fi
  fi

  # Handheld/device patch
  HH_PATCH="$LAB/patches/0003-handheld.patch"
  if [ -f "$HH_PATCH" ]; then
    patch -p1 -l < "$HH_PATCH" 2>&1 | tail -2
    pass "Handheld patch applied"
  fi

  echo "patches_applied=$(date)" > .patches_applied
else
  pass "Patches already applied (delete .patches_applied to re-apply)"
fi

# ---- Step 6: Configure + Build ----------------------------------------------
log "Step 6/6 — Configuring and building (-j${JOBS})..."
cd "$SRCDIR"

# Apply gaming config
cp "$LAB/configs/madcow-gaming.config" .config
make olddefconfig 2>&1 | tail -3

# Verify critical gaming options
BAD=0
for opt in "CONFIG_SCHED_BORE=y" "CONFIG_HZ=1000" "CONFIG_PREEMPT=y" "CONFIG_NTSYNC=y"; do
  grep -q "^$opt" .config || { echo "    [WARN] $opt not set"; BAD=$((BAD+1)); }
done
[ "$BAD" -gt 0 ] && echo "    [WARN] Some options missing — olddefconfig may have reset them"

echo ""
echo "    Building linux-${KVER}-casandarOS-madcow-gaming-kernel"
echo "    Jobs: $JOBS | Est. time: ~15-30 min"
echo ""

START=$(date +%s)
make -j"$JOBS" KCFLAGS="-O2 -pipe" 2>&1 | tee "$LAB/logs/build.log" | \
  grep --line-buffered -E "^\s+(CC|LD|AR|Kernel:|Error|error:)" | \
  grep --line-buffered -v "^$" || true

END=$(date +%s)
DUR=$(( (END - START) / 60 ))

# Check result
[ -f "arch/x86/boot/bzImage" ] || fail "Build failed. Check: $LAB/logs/build.log"

# Stage artifacts
cp arch/x86/boot/bzImage "$LAB/artifacts/boot/vmlinuz-casandarOS-madcow-gaming-kernel"
cp .config "$LAB/artifacts/boot/config-${KVER}-casandarOS-madcow-gaming-kernel"
cp System.map "$LAB/artifacts/boot/System.map-${KVER}-casandarOS-madcow-gaming-kernel"

# ---- Done -------------------------------------------------------------------
BSIZE=$(ls -lh arch/x86/boot/bzImage | awk '{print $5}')
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  BUILD COMPLETE                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Kernel:   linux-${KVER}-casandarOS-madcow-gaming-kernel"
echo "  bzImage:  $BSIZE (${DUR} min)"
echo "  Artifacts: $LAB/artifacts/boot/"
echo ""
echo "NEXT STEP — Install the kernel:"
echo ""
echo "  bash $REPODIR/casandarOS-madcow-kernel/install-on-cachyos.sh"
echo ""
echo "After reboot, validate:"
echo ""
echo "  bash $REPODIR/casandarOS-madcow-kernel/validate-after-boot.sh"
echo ""
