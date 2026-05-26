#!/usr/bin/env bash
# =============================================================================
# CasandarOS Madcow Gaming Kernel — Frametime Benchmark Script
# Run on CachyOS after boot validation passes
# =============================================================================
# Measures scheduler latency as a proxy for gaming frametime consistency.
# For real frametime testing, use MangoHud during gameplay.
# =============================================================================

OUTDIR="$HOME/casandar_kernel_lab/telemetry/$(date +%Y%m%d_%H%M%S)_$(uname -r | tr '/' '-')"
mkdir -p "$OUTDIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$OUTDIR/bench.log"; }
pass() { echo "  [PASS] $1" | tee -a "$OUTDIR/bench.log"; }

log "=== Frametime Benchmark — $(uname -r) ==="
log "Output: $OUTDIR"

# --- Test 1: cyclictest (scheduler wake latency) -----------------------------
if command -v cyclictest &>/dev/null; then
  log "Test 1: cyclictest (scheduler latency, 60s)"
  sudo cyclictest \
    -t$(nproc) \
    -p80 -n \
    -i10000 \
    -D 60 \
    --histfile="$OUTDIR/latency_hist.dat" \
    2>&1 | tee "$OUTDIR/cyclictest_raw.txt"
  
  # Parse results
  AVG=$(grep -E "^T:[0-9]+ \( " "$OUTDIR/cyclictest_raw.txt" | awk '{sum+=$8; n++} END{if(n>0) printf "%.1f", sum/n; else print "N/A"}')
  MAX=$(grep -E "^T:[0-9]+ \( " "$OUTDIR/cyclictest_raw.txt" | awk 'BEGIN{max=0}{if($10>max) max=$10} END{print max}')
  log "cyclictest results: avg=${AVG}µs max=${MAX}µs"
  echo "{\"avg_latency_us\": $AVG, \"max_latency_us\": $MAX, \"kernel\": \"$(uname -r)\"}" > "$OUTDIR/latency_result.json"
  pass "cyclictest complete → $OUTDIR/latency_result.json"
else
  log "cyclictest not found. Install: sudo pacman -S rt-tests"
fi

# --- Test 2: perf scheduler stats --------------------------------------------
log "Test 2: perf scheduler analysis (10s)"
sudo perf sched record -a -- sleep 10 2>/dev/null
sudo perf sched latency --sort max 2>/dev/null | head -30 | tee "$OUTDIR/perf_sched.txt"
pass "perf sched → $OUTDIR/perf_sched.txt"

# --- Test 3: context switches and migrations ---------------------------------
log "Test 3: scheduler migrations (30s idle baseline)"
perf stat -e context-switches,cpu-migrations,migrations \
  -a -I 5000 -- sleep 30 2>&1 | tee "$OUTDIR/migrations.txt"
pass "migrations → $OUTDIR/migrations.txt"

# --- Test 4: BORE burst stats (if available) ---------------------------------
if sysctl -n kernel.sched_bore 2>/dev/null | grep -q "1"; then
  log "Test 4: BORE sysctl snapshot"
  sysctl -a 2>/dev/null | grep sched_b | tee "$OUTDIR/bore_sysctl.txt"
  pass "BORE sysctl → $OUTDIR/bore_sysctl.txt"
fi

# --- Test 5: Memory pressure baseline ----------------------------------------
log "Test 5: memory pressure snapshot"
cat /proc/vmstat | grep -E "pgscan|pgsteal|pgfault|pgmajfault|thp" > "$OUTDIR/vmstat_baseline.txt"
cat /proc/meminfo > "$OUTDIR/meminfo_baseline.txt"
pass "memory baseline → $OUTDIR/"

log ""
log "=== BENCHMARK COMPLETE ==="
log "Results: $OUTDIR/"
log ""
log "Compare against stock kernel:"
log "  Boot stock → run this script → save results"
log "  Boot madcow → run this script → save results"
log "  Diff latency_result.json between runs"
