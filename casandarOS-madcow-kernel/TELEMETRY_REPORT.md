# Telemetry Report — CasandarOS Madcow Gaming Kernel

**Status:** PRE-BOOT (to be collected after first boot)

## Scheduler Telemetry Commands

### After First Boot
```bash
# 1. Verify BORE active
sysctl -a | grep sched_bore

# 2. Scheduler latency baseline
sudo cyclictest -t$(nproc) -p80 -n -i10000 -l10000 -D 60 --histfile=/tmp/bore_latency.hist

# 3. Context switch analysis
perf stat -e context-switches,migrations,cpu-migrations -a -I 1000 -- sleep 30

# 4. Scheduler debug info
cat /sys/kernel/debug/sched/debug

# 5. BORE burst stats (after running workload)
cat /proc/sched_debug | grep -A3 bore
```

## Memory Telemetry
```bash
# LRU_GEN status
cat /sys/kernel/mm/lru_gen/enabled
cat /sys/kernel/mm/lru_gen/min_ttl_ms

# THP status
cat /sys/kernel/mm/transparent_hugepage/enabled

# Reclaim stats (during gaming)
watch -n 1 'cat /proc/vmstat | grep -E "pgscan|pgsteal|pgfault|pgmajfault"'
```

## PSI (Pressure Stall Information) — Gaming Session
```bash
# Monitor CPU/memory/IO pressure during gaming
watch -n 0.5 'cat /proc/pressure/cpu; cat /proc/pressure/memory; cat /proc/pressure/io'
```

## Thermal Telemetry
```bash
# Monitor CPU temps during gaming
watch -n 1 'sensors | grep -E "Core|Tctl|temp"'
```

## Collection Schedule
- [ ] Boot verification (immediate post-install)
- [ ] 30-minute idle baseline
- [ ] 60-minute gaming session telemetry
- [ ] 4-hour long-session stability test
- [ ] Thermal sustainability verification

## Output Location
All telemetry saved to: ~/casandar_kernel_lab/telemetry/
