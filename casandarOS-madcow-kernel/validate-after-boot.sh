#!/usr/bin/env bash
# =============================================================================
# CasandarOS Madcow Gaming Kernel — Post-Boot Validation Script
# Run AFTER first boot into the new kernel
# =============================================================================

PASS=0; FAIL=0; WARN=0
pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

echo "=== POST-BOOT VALIDATION — CasandarOS Madcow Gaming Kernel ==="
echo "Kernel: $(uname -r)"
echo ""

# 1. Kernel version
if uname -r | grep -q "casandarOS-madcow-gaming-kernel"; then
  pass "Kernel version: $(uname -r)"
else
  fail "Wrong kernel running: $(uname -r)"
fi

# 2. BORE scheduler
if sysctl -n kernel.sched_bore 2>/dev/null | grep -q "1"; then
  pass "BORE scheduler: ACTIVE (sysctl kernel.sched_bore=1)"
else
  fail "BORE scheduler: NOT ACTIVE"
fi

# 3. HZ=1000
if grep -q "CONFIG_HZ=1000" /boot/config-$(uname -r) 2>/dev/null; then
  pass "HZ=1000: VERIFIED"
else
  warn "HZ=1000: could not verify (check /boot/config-$(uname -r))"
fi

# 4. Full preemption
if grep -q "^CONFIG_PREEMPT=y" /boot/config-$(uname -r) 2>/dev/null; then
  pass "PREEMPT_FULL: VERIFIED"
else
  warn "PREEMPT_FULL: could not verify"
fi

# 5. NTSync
if [ -c /dev/ntsync ]; then
  pass "NTSync: /dev/ntsync EXISTS (Wine/Proton ready)"
elif grep -q "CONFIG_NTSYNC=y" /boot/config-$(uname -r) 2>/dev/null; then
  warn "NTSync: compiled but /dev/ntsync missing (load module: modprobe ntsync)"
else
  fail "NTSync: NOT available"
fi

# 6. BBR TCP
BBR=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
if [ "$BBR" = "bbr" ]; then
  pass "TCP BBR: ACTIVE"
else
  warn "TCP BBR: using $BBR (expected bbr)"
fi

# 7. THP=madvise
THP=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null)
if echo "$THP" | grep -q "\[madvise\]"; then
  pass "THP: madvise (no background compaction)"
elif echo "$THP" | grep -q "\[never\]"; then
  warn "THP: disabled (set to madvise for gaming: echo madvise > /sys/kernel/mm/transparent_hugepage/enabled)"
else
  warn "THP: $THP"
fi

# 8. LRU_GEN
LRUGEN=$(cat /sys/kernel/mm/lru_gen/enabled 2>/dev/null)
if [ -n "$LRUGEN" ] && [ "$LRUGEN" != "0x0000" ]; then
  pass "LRU_GEN (MGLRU): ENABLED ($LRUGEN)"
else
  warn "LRU_GEN: not found or disabled"
fi

# 9. BFQ I/O
for disk in $(lsblk -d -o NAME -n | head -3); do
  SCHED=$(cat /sys/block/$disk/queue/scheduler 2>/dev/null | grep -o '\[.*\]' | tr -d '[]')
  if [ "$SCHED" = "bfq" ]; then
    pass "I/O scheduler ($disk): bfq"
  else
    warn "I/O scheduler ($disk): $SCHED (not bfq)"
  fi
done

# 10. ZRAM
if lsblk | grep -q zram; then
  pass "ZRAM: active"
else
  warn "ZRAM: not active (enable with: modprobe zram; zramctl)"
fi

# 11. sched_bore sysctl values
BORE_VAL=$(sysctl -n kernel.sched_bore 2>/dev/null)
BURST_CACHE=$(sysctl -n kernel.sched_burst_cache_lifetime 2>/dev/null)
if [ -n "$BORE_VAL" ]; then
  pass "BORE sysctl: bore=$BORE_VAL burst_cache=${BURST_CACHE}ns"
fi

echo ""
echo "=== VALIDATION SUMMARY ==="
echo "PASS: $PASS | FAIL: $FAIL | WARN: $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "╔══════════════════════════════════════════╗"
  echo "║  [RESULT] PASS                           ║"
  echo "║  Kernel validated. Begin benchmarking.   ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "Next: install MangoHud and run frametime comparison"
  echo "  yay -S mangohud lib32-mangohud"
  echo "  Add to Steam launch: MANGOHUD=1 %command%"
else
  echo "╔══════════════════════════════════════════╗"
  echo "║  [RESULT] FAIL — $FAIL check(s) failed   ║"
  echo "║  Investigate before gaming use           ║"
  echo "╚══════════════════════════════════════════╝"
fi

echo ""
echo "Scheduler latency test (needs cyclictest):"
echo "  sudo pacman -S rt-tests"
echo "  sudo cyclictest -t1 -p80 -n -i10000 -l10000"
